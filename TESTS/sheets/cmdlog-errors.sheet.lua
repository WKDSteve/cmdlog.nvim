-- Live check: a command that really failed is flagged in the pickers (task
-- cmdlog.nvim/testblatt-bindings-checkliste; section 8 of ALL/manual-test-checklists/cmdlog.md).
return {
  id = "cmdlog.errors",
  title = "cmdlog.nvim: a typed command that failed is marked with a cross",
  task = "cmdlog.nvim/testblatt-bindings-checkliste",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.boot()]],
    },
    { keys = ":let g:fine = 1<CR>" },
    { keys = ":NoSuchCommandAtAll<CR>", ignore_errmsg = true, note = "a typo'd command" },
    { settle = 300 },
    {
      expect = [[(_G.json("data/errors.json") or {}).NoSuchCommandAtAll:find("E492", 1, true) ~= nil]],
      note = "the deferred v:errmsg check caught it",
    },
    { input = ":Cmdlog nvim<CR>" },
    { wait = "_G.ready()" },
    {
      expect = [[_G.row("NoSuchCommandAtAll"):find("✗ NoSuchCommandAtAll", 1, true) ~= nil]],
      note = "the marker",
    },
    { expect = [[_G.groups("NoSuchCommandAtAll").ErrorMsg]], note = "the highlight" },
    {
      expect = [[not _G.row("let g:fine = 1"):find("✗", 1, true)]],
      note = "not on a command that worked",
    },
    { expect = [[not _G.groups("let g:fine = 1").ErrorMsg]] },
    { input = "<C-c>" },
    { wait = "not _G.P()" },
  },
}
