-- Live check: the opt-in sources, `extra_files` and `project_scoped` (task
-- cmdlog.nvim/testblatt-bindings-checkliste; section 9 of ALL/manual-test-checklists/cmdlog.md).
local SOURCE = [[_G.get("extra.txt") == "from extra\nalso extra\n"]]

return {
  id = "cmdlog.optin",
  feature = "cmdlog.opt-in-files",
  title = "cmdlog.nvim: extra_files are read-only rows, project_scoped falls back to the global file",
  task = "cmdlog.nvim/manual-checklist-run",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.boot({ extra_files = { all = { "extra.txt" } } }, { "git status" })
      _G.put("extra.txt", "from extra\nalso extra\n")]],
      note = "extra_files.all, relative to the sandbox",
    },
    { input = ":Cmdlog<CR>" },
    { wait = "_G.ready()" },
    { expect = [[_G.row("from extra"):find("[extra]", 1, true) ~= nil]], note = "labelled extra" },
    { expect = [[_G.count("── extra files") == 1]], note = "under a divider of their own" },
    { input = "from extra" },
    { wait = [[_G.sel() == "from extra"]] },
    { input = "<C-x>" },
    {
      wait = [[_G.noted("Could not delete 1 of 1 entry")]],
      note = "<C-x> on an extra row says it cannot",
    },
    { expect = SOURCE, note = "and leaves the source file" },
    { input = "<Tab>" },
    {
      wait = [[_G.same(_G.json("data/favorites.json"), { "from extra" })]],
      note = "<Tab> favorites the text, as on any row",
    },
    { expect = SOURCE, note = "and leaves the source file" },
    { wait = "_G.ready()" },
    { input = "<C-c>" },
    { wait = "not _G.P()" },
    { input = ":Cmdlog nvim<CR>" },
    { wait = "_G.ready()" },
    {
      expect = [[_G.count("also extra") == 0]],
      note = "extra_files.all stays out of the single pickers",
    },
    { input = "<C-c>" },
    { wait = "not _G.P()" },

    -- project_scoped
    {
      lua = [[_G.boot({ project_scoped = { enabled = true } }, { "in the repo" })
      _G.put("data/favorites.json", vim.json.encode({ "global favorite" }))
      vim.fn.mkdir(_G.p("repo/.git"), "p")]],
      note = "a global favorites file and a repository",
    },
    { keys = ":cd repo<CR>" },
    { input = ":Cmdlog shell<CR>" },
    { wait = "_G.ready()" },
    { input = "in the repo" },
    { wait = [[_G.sel() == "in the repo"]] },
    { input = "<Tab>" },
    {
      wait = [[#vim.fn.glob(_G.p("data/projects/repo-*.json"), true, true) == 1]],
      note = "the favorite goes into a file of this project",
    },
    {
      expect = [[_G.same(_G.json("data/favorites.json"), { "global favorite" })]],
      note = "not into the global one",
    },
    { wait = "_G.ready()" },
    { input = "<C-c>" },
    { wait = "not _G.P()" },
    { input = ":Cmdlog favorites<CR>" },
    { wait = "_G.ready()" },
    { expect = [[_G.count("in the repo") == 1]], note = "inside: the project's favorite" },
    { expect = [[_G.count("global favorite") == 0]], note = "inside: not the global one" },
    { input = "<C-c>" },
    { wait = "not _G.P()" },
    { keys = ":cd ..<CR>" },
    { input = ":Cmdlog favorites<CR>" },
    { wait = "_G.ready()" },
    {
      expect = [[_G.count("global favorite") == 1]],
      note = "outside: the global file, not an empty one",
    },
    { expect = [[_G.count("in the repo") == 0]], note = "outside: not the project's" },
    { input = "<C-c>" },
    { wait = "not _G.P()" },
  },
}
