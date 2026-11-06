-- Live check: the views the tracker feeds, `:Cmdlog project`, `stats` and `lua` (task
-- cmdlog.nvim/testblatt-bindings-checkliste; section 3 of ALL/manual-test-checklists/cmdlog.md). The
-- commands are really typed, so what the pickers show went through the CmdlineLeave tracker.
return {
  id = "cmdlog.derived",
  title = "cmdlog.nvim: :Cmdlog project is per repository, stats counts, lua filters",
  task = "cmdlog.nvim/testblatt-bindings-checkliste",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.boot()
      vim.fn.mkdir(_G.p("repo_a/.git"), "p")
      vim.fn.mkdir(_G.p("repo_b/.git"), "p")]],
      note = "two repositories below a directory that is none",
    },

    -- outside any repository
    { input = ":Cmdlog project<CR>" },
    {
      wait = [[_G.noted("Not inside a Git repository")]],
      note = "a clear notify outside a repository",
    },
    { expect = "not _G.P()", note = "and no picker" },

    -- the first repository
    { keys = ":cd repo_a<CR>" },
    { keys = ":let g:in_a = 1<CR>" },
    { keys = ":let g:in_a = 1<CR>" },
    { settle = 500 },
    { input = ":Cmdlog project<CR>" },
    { wait = "_G.ready()" },
    {
      expect = [[_G.count("let g:in_a = 1") == 1]],
      note = "the commands of this repository, deduplicated",
    },
    { input = "<C-c>" },
    { wait = "not _G.P()" },

    -- the second repository
    { keys = ":cd ../repo_b<CR>" },
    { keys = ":let g:in_b = 1<CR>" },
    { settle = 500 },
    { input = ":Cmdlog project<CR>" },
    { wait = "_G.ready()" },
    { expect = [[_G.count("let g:in_b = 1") == 1]], note = "the second repository's own commands" },
    { expect = [[_G.count("let g:in_a = 1") == 0]], note = "and not those of the first" },
    { input = "<C-c>" },
    { wait = "not _G.P()" },

    -- stats: counted and sorted
    -- four times: `:Cmdlog project` has already run three times, and a tie is decided by a clock in seconds
    { keys = ":let g:often = 1<CR>" },
    { keys = ":let g:often = 1<CR>" },
    { keys = ":let g:often = 1<CR>" },
    { keys = ":let g:often = 1<CR>" },
    { settle = 500 },
    { input = ":Cmdlog stats<CR>" },
    { wait = "_G.ready()" },
    {
      expect = [[_G.rows()[1]:find("let g:often = 1  %[used 4x, last %d%d%d%d%-%d%d%-%d%d %d%d:%d%d%]") ~= nil]],
      note = "the most used command on top, with count and date",
    },
    { input = "<C-c>" },
    { wait = "not _G.P()" },
    { keys = ":let g:often = 1<CR>" },
    { settle = 500 },
    { input = ":Cmdlog stats<CR>" },
    { wait = "_G.ready()" },
    {
      expect = [[_G.row("let g:often = 1"):find("used 5x", 1, true) ~= nil]],
      note = "the count went up",
    },
    { input = "<C-c>" },
    { wait = "not _G.P()" },

    -- lua: nothing else
    { keys = ":lua vim.g.from_lua = 1<CR>" },
    { keys = ":lua= 1 + 1<CR>" },
    { keys = ":= 2 + 2<CR>" },
    { input = ":Cmdlog lua<CR>" },
    { wait = "_G.ready()" },
    { expect = "#_G.rows() == 3", note = "exactly the three Lua commands" },
    { expect = [[_G.count("lua vim.g.from_lua = 1") == 1]], note = ":lua" },
    { expect = [[_G.count("lua= 1 + 1") == 1]], note = ":lua=" },
    { expect = [[_G.count("= 2 + 2") == 1]], note = ":=" },
    { input = "<C-c>" },
    { wait = "not _G.P()" },
  },
}
