-- Live check: `preview_execute = true` renders help and Lua, and still refuses a risky entry and an argument
-- with a `|` (task cmdlog.nvim/testblatt-bindings-checkliste; section 7 of
-- ALL/manual-test-checklists/cmdlog.md). The risky entry would delete a real directory of the sandbox.
local function at(value)
  return {
    { input = "<C-p>" },
    { wait = ([[_G.sel() == %q]]):format(value) },
  }
end

local steps = {
  {
    lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
    _G.boot({ preview_execute = true })
    vim.fn.mkdir(_G.p("build"), "p")
    _G.seed("help nvim_buf_get_lines", "lua 40 + 2", "!rm -rf build", "help x | let g:injected = 1")]],
    note = "newest first: an argument with a bar, a risky entry, Lua, help",
  },
  { input = ":Cmdlog nvim<CR>" },
  { wait = "_G.ready()" },
}
local list = {
  at("help x | let g:injected = 1"),
  {
    {
      wait = [[_G.preview():find("Not previewed: the argument contains", 1, true) ~= nil]],
      note = "a bar in a help argument is refused",
    },
  },
  at("!rm -rf build"),
  {
    {
      wait = [[_G.preview():find("Not previewed: matches risky_patterns.", 1, true) ~= nil]],
      note = "a risky entry is refused",
    },
    { expect = [[vim.fn.isdirectory(_G.p("build")) == 1]], note = "and did not run" },
  },
  at("lua 40 + 2"),
  { { wait = [[_G.preview() == "42"]], note = ":lua shows its result" } },
  at("help nvim_buf_get_lines"),
  {
    {
      wait = [[_G.preview():find("*nvim_buf_get_lines()*", 1, true) ~= nil]],
      timeout = 5000,
      note = ":help renders the real page, in a headless Neovim",
    },
    { expect = [[vim.g.injected == nil]], note = "nothing was injected" },
    { input = "<C-c>" },
    { wait = "not _G.P()" },
  },
}
for l = 1, #list do
  for i = 1, #list[l] do
    steps[#steps + 1] = list[l][i]
  end
end

return {
  id = "cmdlog.preview-execute",
  title = "cmdlog.nvim: preview_execute renders help and Lua, a risky entry and a bar stay refused",
  task = "cmdlog.nvim/manual-checklist-run",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = steps,
}
