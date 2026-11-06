-- Live check: the deduplicated pickers against their `full` variants (task
-- cmdlog.nvim/testblatt-bindings-checkliste; section 4 of ALL/manual-test-checklists/cmdlog.md).
local function view(cmd, text, n, note)
  return {
    { input = ":" .. cmd .. "<CR>" },
    { wait = "_G.ready()" },
    { expect = ("_G.count(%q) == %d"):format(text, n), note = ":" .. cmd .. ": " .. note },
    { input = "<C-c>" },
    { wait = "not _G.P()" },
  }
end

local steps = {
  {
    lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
    _G.boot({}, { "echo shell", "echo shell", "echo shell" })]],
    note = "one shell command three times in the history file",
  },
  { keys = ":let g:typed = 1<CR>" },
  { keys = ":let g:typed = 1<CR>" },
  { keys = ":let g:typed = 1<CR>" },
  {
    expect = [[#vim.tbl_filter(function(c) return c == "let g:typed = 1" end, _G.history()) == 1]],
    note = "Neovim's own `:` history keeps a command typed three times once, so nvim-full has nothing more to show",
  },
}
local views = {
  view("Cmdlog nvim", "let g:typed = 1", 1, "once"),
  view("Cmdlog nvim-full", "let g:typed = 1", 1, "once as well, see above"),
  view("Cmdlog shell", "echo shell", 1, "once"),
  view("Cmdlog shell-full", "echo shell", 3, "three times"),
  view("Cmdlog", "echo shell", 1, "once"),
  view("Cmdlog full", "echo shell", 3, "three times"),
}
for v = 1, #views do
  for i = 1, #views[v] do
    steps[#steps + 1] = views[v][i]
  end
end

return {
  id = "cmdlog.full",
  title = "cmdlog.nvim: nvim, shell and bare :Cmdlog dedup, their full variants keep duplicates",
  task = "cmdlog.nvim/testblatt-bindings-checkliste",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = steps,
}
