-- Live check: `<C-x>` on a `:` entry, on a line of the shell history file with its question, and on several
-- marked entries (task cmdlog.nvim/testblatt-bindings-checkliste; section 6 of
-- ALL/manual-test-checklists/cmdlog.md). The history file is a throwaway one in the format of a PSReadLine file
-- on Windows, CRLF included. The dialog's hotkeys ignore the first moments of a question nobody asked for, so
-- the steps answer with <CR> and the arrow keys, which do not wait.
local KEPT =
  [[_G.same(_G.lines("shell_history.txt"), { "dir /b", "git status", "dir /b", "ls -la" })]]

local function open_on_dir()
  return {
    { input = ":Cmdlog shell<CR>" },
    { wait = "_G.ready()" },
    { input = "dir" },
    { wait = [[_G.sel() == "dir /b"]] },
    { input = "<C-x>" },
    { wait = "_G.dialog()", note = "a question before a file is rewritten" },
  }
end

local steps = {
  {
    lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
    _G.boot()
    _G.put("shell_history.txt", "dir /b\r\ngit status\r\ndir /b\r\nls -la\r\n")
    _G.seed("let g:keep = 1", "let g:gone = 1", "let g:mark1 = 1", "let g:mark2 = 1", "let g:mark3 = 1")
    _G.dialog = function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local text = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false), "\n")
        if vim.api.nvim_win_get_config(win).relative ~= "" and text:find("[ No ]", 1, true) then return text end
      end
    end]],
    note = "`:` entries and a shell history with one command twice",
  },

  -- `:` history: no question
  { input = ":Cmdlog nvim<CR>" },
  { wait = "_G.ready()" },
  { input = "gone" },
  { wait = [[_G.sel() == "let g:gone = 1"]] },
  { input = "<C-x>" },
  { wait = [[not vim.tbl_contains(_G.history(), "let g:gone = 1")]], note = "histdel took it" },
  { expect = "not _G.dialog()", note = "without a question" },
  { wait = [[_G.ready() and _G.count("let g:keep = 1") == 1]], note = "the picker came back" },
  { expect = [[_G.count("let g:gone = 1") == 0]], note = "without the entry" },

  -- several marked entries
  { input = "mark" },
  { wait = [[#_G.rows() == 3]] },
  { input = "<C-Space>" },
  { wait = "#_G.P():get_multi_selection() == 1", note = "<C-Space> marks" },
  { input = "<C-Space>" },
  { wait = "#_G.P():get_multi_selection() == 2", note = "and moves on to the next entry" },
  { input = "<C-x>" },
  { wait = "_G.dialog()", note = "a batch is confirmed as a whole" },
  { expect = [[_G.dialog():find("Delete 2 selected entries", 1, true) ~= nil]] },
  { input = "<CR>" },
  { wait = "not _G.dialog()", note = "No has the focus" },
  { expect = [[#_G.marks() == 3]], note = "no leaves all three" },
  { input = ":Cmdlog nvim<CR>" },
  { wait = "_G.ready()" },
  { input = "mark" },
  { wait = [[#_G.rows() == 3]] },
  { input = "<C-Space>" },
  { wait = "#_G.P():get_multi_selection() == 1" },
  { input = "<C-Space>" },
  { wait = "#_G.P():get_multi_selection() == 2" },
  { input = "<C-x>" },
  { wait = "_G.dialog()" },
  { input = "<Right><CR>", note = "Yes, delete" },
  {
    wait = [[_G.same(_G.marks(), { "let g:mark1 = 1" })]],
    note = "every marked entry went in one pass, the unmarked one stayed",
  },
  { wait = "_G.ready()", note = "the picker came back" },
  { input = "<C-c>" },
  { wait = "not _G.P()" },
}

local function add(list)
  for i = 1, #list do
    steps[#steps + 1] = list[i]
  end
end

-- the shell history file
add(open_on_dir())
add({
  {
    expect = [[_G.dialog():find("Delete 2 occurrence(s) of 'dir /b' from shell history file?", 1, true) ~= nil]],
    note = "names how many and what",
  },
  { expect = [[_G.dialog():find("shell_history.txt", 1, true) ~= nil]], note = "and the file" },
  { input = "<CR>" },
  { wait = "not _G.dialog()", note = "No has the focus" },
  { expect = KEPT, note = "declining leaves the file untouched" },
  { expect = [[_G.get("shell_history.txt"):find("\r\n", 1, true) ~= nil]], note = "to the byte" },
})
add(open_on_dir())
add({
  { input = "<Esc>" },
  { wait = "not _G.dialog()" },
  { expect = KEPT, note = "<Esc> is a no as well" },
})
add(open_on_dir())
add({
  { input = "<Right><CR>", note = "Yes, delete" },
  {
    wait = [[_G.same(_G.lines("shell_history.txt"), { "git status", "ls -la" })]],
    note = "every occurrence is gone, the other lines are kept",
  },
  { wait = [[_G.ready() and _G.count("git status") == 1]], note = "the picker came back" },
  { expect = [[_G.count("dir /b") == 0]], note = "without the entry" },
  { input = "<C-c>" },
  { wait = "not _G.P()" },
})

return {
  id = "cmdlog.delete",
  title = "cmdlog.nvim: <C-x> deletes from `:` history, from the shell history after asking, and in a batch",
  task = "cmdlog.nvim/testblatt-bindings-checkliste",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = steps,
  manual = {
    "<C-x> on a real PSReadLine file of a Windows machine, on a copy or with a backup: the entry is gone, a running PowerShell keeps working",
  },
}
