-- Live check: bare `:Cmdlog`, the everyday entry point (task cmdlog.nvim/testblatt-bindings-checkliste;
-- section 1 of ALL/manual-test-checklists/cmdlog.md). Real Telescope, real keys.
return {
  id = "cmdlog.combined",
  title = "cmdlog.nvim: bare :Cmdlog dedups, <CR> inserts without running, <Tab>, <C-r>, origins and dividers",
  task = "cmdlog.nvim/manual-checklist-run",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.boot({}, {})
      _G.seed("let g:old = 1", "let g:ran = 1", "let g:old = 1")]],
      note = "an empty shell history, three `:` entries of which one twice",
    },

    -- one origin: nothing to divide
    { input = ":Cmdlog<CR>" },
    { wait = "_G.ready()" },
    { expect = [[_G.count("──") == 0]], note = "a single origin has no divider rows" },
    { expect = [[_G.count("let g:old = 1") == 1]], note = "deduplicated" },
    {
      expect = [[_G.rows()[2]:find("let g:old = 1", 1, true) ~= nil
        and _G.rows()[3]:find("let g:ran = 1", 1, true) ~= nil]],
      note = "the most recent occurrence decides the place",
    },
    { expect = [[_G.row("let g:ran = 1"):find("[nvim]", 1, true) ~= nil]], note = "labelled nvim" },

    -- <C-r>: what happened meanwhile, and a second origin
    {
      lua = [[_G.seed("let g:meanwhile = 1"); _G.put("shell_history.txt", { "git status", "git status" })]],
      note = "a new `:` entry and a shell history while the picker is open",
    },
    { expect = [[_G.count("let g:meanwhile = 1") == 0]] },
    { input = "<C-r>" },
    {
      wait = [[_G.ready() and _G.count("let g:meanwhile = 1") == 1]],
      note = "<C-r> refreshes in place",
    },
    { expect = [[_G.count("git status") == 1]], note = "the shell block is deduplicated too" },
    { expect = [[_G.row("git status"):find("[shell]", 1, true) ~= nil]], note = "labelled shell" },
    { expect = [[_G.count("── nvim history") == 1]], note = "a divider before the nvim block" },
    {
      expect = [[_G.count("── shell history") == 1]],
      note = "a divider before the shell block",
    },

    -- typing hides the dividers
    { input = "ran" },
    { wait = [[_G.sel() == "let g:ran = 1"]], note = "the prompt filters" },
    { wait = [[_G.count("──") == 0]], note = "the divider rows are gone while filtering" },

    -- <CR> inserts, nothing runs
    { input = "<CR>" },
    { wait = [[vim.fn.mode() == "c"]], note = "<CR> leaves the picker for the command line" },
    {
      expect = [[vim.fn.getcmdline() == "let g:ran = 1"]],
      note = "the entry stands on the command line",
    },
    { expect = [[vim.g.ran == nil]], note = "and it did not run" },
    { input = "<Esc>" },
    { wait = [[vim.fn.mode() == "n"]] },
    { expect = [[vim.g.ran == nil]], note = "aborting the command line runs nothing either" },
    { settle = 200 },
    {
      expect = [[(_G.json("data/stats.json") or {})["let g:ran = 1"] == nil]],
      note = "and an aborted command line is not counted as executed",
    },

    -- <Tab> favorites, :Cmdlog favorites shows it
    { input = ":Cmdlog<CR>" },
    { wait = "_G.ready()" },
    { input = "git" },
    { wait = [[_G.sel() == "git status"]] },
    { input = "<Tab>" },
    {
      wait = [[_G.same(_G.json("data/favorites.json"), { "git status" })]],
      note = "<Tab> favorites",
    },
    {
      wait = [[_G.ready() and _G.count("── favorites") == 1]],
      note = "the picker came back with a favorites block",
    },
    { input = "<C-c>" },
    { wait = "not _G.P()" },
    { input = ":Cmdlog favorites<CR>" },
    { wait = "_G.ready()" },
    {
      expect = [[_G.row("git status"):find("★ git status", 1, true) ~= nil]],
      note = "marked with a star",
    },
    { input = "<C-c>" },
    { wait = "not _G.P()" },
  },
}
