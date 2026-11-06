-- Live check: with the defaults a preview reads and runs nothing (task
-- cmdlog.nvim/testblatt-bindings-checkliste; section 7 of ALL/manual-test-checklists/cmdlog.md). The window is
-- wide enough for Telescope to show its preview pane.
local NOT_RUN = "Preview would run this command. Execution previews are off."

local function at(value, shows, note)
  return {
    { input = "<C-p>" },
    { wait = ([[_G.sel() == %q]]):format(value) },
    { wait = ([[_G.preview():find(%q, 1, true) ~= nil]]):format(shows), note = note },
  }
end

local steps = {
  {
    lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
    _G.boot()
    _G.put("sample.txt", "first line of the sample\n")
    _G.seed("e +10 sample.txt", "vsp sample.txt", "vs sample.txt", "sp sample.txt", "e sample.txt", "edit sample.txt",
      "help api", "lua vim.g.previewed = 1", "!echo previewed > marker.txt")]],
    note = "newest first: a shell command, Lua, help, the five file forms, a file with two arguments",
  },
  { input = ":Cmdlog nvim<CR>" },
  { wait = "_G.ready()" },
  {
    wait = [[_G.preview():find("No preview available.", 1, true) ~= nil]],
    note = ":Cmdlog nvim itself",
  },
}
local list = {
  at("!echo previewed > marker.txt", NOT_RUN, ":! shows the note"),
  {
    {
      expect = [[_G.preview():find("!echo previewed > marker.txt", 1, true) == 1]],
      note = "under the command",
    },
  },
  at("lua vim.g.previewed = 1", NOT_RUN, ":lua shows the note"),
  {
    {
      expect = [[_G.preview():find("lua vim.g.previewed = 1", 1, true) == 1]],
      note = "under the command",
    },
  },
  at("help api", NOT_RUN, ":help shows the note, no help page"),
  { { expect = [[_G.preview():find("help api", 1, true) == 1]], note = "under the command" } },
  at("edit sample.txt", "first line of the sample", ":edit shows the file"),
  at("e sample.txt", "first line of the sample", ":e shows the file"),
  at("sp sample.txt", "first line of the sample", ":sp shows the file"),
  at("vs sample.txt", "first line of the sample", ":vs shows the file"),
  at("vsp sample.txt", "first line of the sample", ":vsp shows the file"),
  at("e +10 sample.txt", "No preview available.", "two arguments: no file preview"),
  {
    {
      expect = [[not _G.preview():find("first line of the sample", 1, true)]],
      note = "not the file",
    },
    { expect = [[vim.g.previewed == nil]], note = "the Lua entry did not run" },
    { expect = [[_G.get("marker.txt") == nil]], note = "the shell entry did not run" },
    {
      expect = [[not vim.fn.execute("messages"):find("previewed", 1, true)]],
      note = "no trace in :messages",
    },
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
  id = "cmdlog.preview",
  title = "cmdlog.nvim: previews show files and run nothing (preview_execute off, the default)",
  task = "cmdlog.nvim/testblatt-bindings-checkliste",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = steps,
  manual = {
    "The preview pane reads well: a file, and the note under a command that was not run",
    "picker = 'fzf' (scratch config, 'fzf-lua' accepted as an alias): on Windows previews are not available rather than broken; <CR> inserts into the cmdline and does not execute. fzf-lua is no dependency of the suite",
  },
}
