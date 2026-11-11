-- Live check: `<C-g>` in the project picker with and without gitsuite.nvim, and in the other pickers (task
-- cmdlog.nvim/testblatt-bindings-checkliste; section 10 of ALL/manual-test-checklists/cmdlog.md). gitsuite.nvim is
-- no dependency of the suite: its absence is real, its presence a recording stand-in for
-- `gitsuite.features.ui` (the float and the lazygit binary stay for a person).
return {
  id = "cmdlog.lazygit",
  feature = "cmdlog.lazygit",
  title = "cmdlog.nvim: <C-g> opens lazygit for the repo root, only in the project picker, a notify without gitsuite",
  task = "cmdlog.nvim/manual-checklist-run",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.boot()
      vim.fn.mkdir(_G.p("repo/.git"), "p")
      vim.fn.mkdir(_G.p("repo/sub"), "p")]],
      note = "a repository with a subdirectory; gitsuite.nvim is not on the runtimepath",
    },
    { keys = ":checkhealth cmdlog<CR>" },
    {
      wait = [[_G.buftext():find("gitsuite.nvim not installed: the project picker's lazygit mapping is unavailable", 1, true)]],
      note = "health says the mapping is unavailable",
    },
    { lua = [[vim.cmd("bwipeout!")]] },

    -- without gitsuite.nvim
    { keys = ":cd repo/sub<CR>" },
    { keys = ":let g:here = 1<CR>" },
    { settle = 300 },
    { input = ":Cmdlog project<CR>" },
    { wait = "_G.ready()" },
    { input = "here" },
    { wait = [[_G.sel() == "let g:here = 1"]] },
    { input = "<C-g>" },
    {
      wait = [[_G.noted('install "WKDSteve/gitsuite.nvim"')]],
      note = "a notify naming the plugin",
    },
    { expect = [[vim.v.errmsg == ""]], note = "no Lua error" },
    { expect = "_G.P() ~= nil", note = "the picker stays" },
    { input = "<Tab>" },
    {
      wait = [[_G.same(_G.json("data/favorites.json"), { "let g:here = 1" })]],
      note = "and <Tab> still works",
    },
    { wait = "_G.ready()" },
    { input = "<CR>" },
    { wait = [[vim.fn.mode() == "c"]], note = "and <CR> too" },
    { input = "<Esc>" },
    { wait = [[vim.fn.mode() == "n"]] },

    -- with gitsuite.nvim
    {
      lua = [[_G.opened = {}
      package.loaded["gitsuite.features.ui"] = { lazygit = function(dir) _G.opened[#_G.opened + 1] = dir end }]],
      note = "the recording stand-in",
    },
    { input = ":Cmdlog project<CR>" },
    { wait = "_G.ready()" },
    { input = "<C-g>" },
    { wait = "#_G.opened == 1", note = "<C-g> opens lazygit" },
    { expect = [[_G.opened[1] == _G.p("repo")]], note = "for the repository root, not the cwd" },
    { wait = "not _G.P()", note = "the picker closes for it" },

    -- not in the other pickers
    { input = ":Cmdlog nvim<CR>" },
    { wait = "_G.ready()" },
    { input = "<C-g><Esc>" },
    { settle = 200 },
    { expect = "#_G.opened == 1", note = ":Cmdlog nvim has no <C-g>" },
    { lua = [[require("telescope.actions").close(vim.api.nvim_get_current_buf())]] },
    { wait = "not _G.P()" },
    { input = ":Cmdlog favorites<CR>" },
    { wait = "_G.ready()" },
    { input = "<C-g><Esc>" },
    { settle = 200 },
    { expect = "#_G.opened == 1", note = ":Cmdlog favorites has no <C-g>" },
    { lua = [[require("telescope.actions").close(vim.api.nvim_get_current_buf())]] },
    { wait = "not _G.P()" },
  },
  manual = {
    "With gitsuite.nvim installed: :Cmdlog project, <C-g>: the lazygit float really opens for the repo root; close it, Neovim is back in a sane state",
  },
}
