-- Live check: favorites, toggled, tagged, undone, reordered, exported and imported (task
-- cmdlog.nvim/testblatt-bindings-checkliste; section 2 of ALL/manual-test-checklists/cmdlog.md).
local function tab(text, cmd, note)
  return {
    { input = text },
    { wait = ([[_G.sel() == %q]]):format(cmd) },
    { input = "<Tab>" },
    {
      wait = ([[vim.tbl_contains(_G.json("data/favorites.json") or {}, %q) ]]):format(cmd),
      note = note,
    },
    { wait = [[_G.ready() and _G.line() == ""]], note = "the picker came back, its prompt empty" },
  }
end

local steps = {
  {
    lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
    _G.line = function() return require("telescope.actions.state").get_current_line() end
    _G.boot({}, { "git status", "dir /b", "ls -la" })]],
    note = "a shell history of three commands",
  },
  { input = ":Cmdlog shell<CR>" },
  { wait = "_G.ready()" },
}
local function add(list)
  for i = 1, #list do
    steps[#steps + 1] = list[i]
  end
end

add(tab("git st", "git status", "<Tab> in :Cmdlog shell favorites the entry"))
add({
  { input = "<C-c>" },
  { wait = "not _G.P()" },

  -- the tag
  { lua = [[_G.answer = "vcs"]] },
  { input = ":Cmdlog favorites<CR>" },
  { wait = "_G.ready()" },
  {
    expect = [[_G.row("git status"):find("★ git status", 1, true) ~= nil]],
    note = "marked with a star",
  },
  { input = "<C-t>" },
  {
    wait = [[_G.ready() and _G.row("git status"):find("[vcs]", 1, true) ~= nil]],
    note = "the tag is shown",
  },
  { expect = [[_G.asked[1] == "Add tag: "]], note = "<C-t> asks for a free-form tag" },
  { input = "<C-c>" },
  { wait = "not _G.P()" },
  { input = ":Cmdlog favorites<CR>" },
  { wait = "_G.ready()" },
  {
    expect = [[_G.row("git status"):find("[vcs]", 1, true) ~= nil]],
    note = "the tag survives reopening",
  },
  { expect = [[_G.same(_G.json("data/favorite_tags.json"), { ["git status"] = { "vcs" } })]] },
  { input = "<C-c>" },
  { wait = "not _G.P()" },

  -- <C-z> undoes one toggle, the last one
  { input = ":Cmdlog shell<CR>" },
  { wait = "_G.ready()" },
})
add(tab("dir", "dir /b", "the first of two toggles"))
add(tab("ls", "ls -la", "the second of two toggles"))
add({
  { expect = [[_G.same(_G.json("data/favorites.json"), { "git status", "dir /b", "ls -la" })]] },
  { input = "<C-z>" },
  {
    wait = [[_G.same(_G.json("data/favorites.json"), { "git status", "dir /b" })]],
    note = "<C-z> undoes the second toggle only",
  },
  { wait = "_G.ready()" },
  { input = "<C-z>" },
  { settle = 200 },
  {
    expect = [[_G.noted("Nothing to undo")]],
    note = "single level: a second <C-z> has nothing to undo",
  },
  {
    expect = [[_G.same(_G.json("data/favorites.json"), { "git status", "dir /b" })]],
    note = "and changes nothing",
  },
  { input = "<C-c>" },
  { wait = "not _G.P()" },

  -- the persisted order
  { input = ":Cmdlog favorites<CR>" },
  { wait = "_G.ready()" },
  { expect = [[_G.sel() == "git status"]], note = "display order is the persisted order" },
  { input = "<C-Down>" },
  {
    wait = [[_G.same(_G.json("data/favorites.json"), { "dir /b", "git status" })]],
    note = "<C-Down> moves the entry down in the file",
  },
  { wait = "_G.ready()" },
  { expect = [[_G.rows()[1]:find("dir /b", 1, true) ~= nil]], note = "and in the picker" },
  { input = "<C-p>" },
  { wait = [[_G.sel() == "git status"]] },
  { input = "<C-Up>" },
  {
    wait = [[_G.same(_G.json("data/favorites.json"), { "git status", "dir /b" })]],
    note = "<C-Up> moves it back up",
  },
  { wait = "_G.ready()" },
  { input = "<C-Down>" },
  { wait = [[_G.same(_G.json("data/favorites.json"), { "dir /b", "git status" })]] },
  { wait = "_G.ready()" },
  { input = "<C-c>" },
  { wait = "not _G.P()" },
  { input = ":Cmdlog favorites<CR>" },
  { wait = "_G.ready()" },
  {
    expect = [[_G.rows()[1]:find("dir /b", 1, true) ~= nil]],
    note = "the order survives reopening",
  },
  { input = "<C-c>" },
  { wait = "not _G.P()" },

  -- export without a path, then import
  { keys = ":Cmdlog export<CR>" },
  {
    expect = [[_G.same(_G.json("data/favorites.export.json"), { "dir /b", "git status" })]],
    note = "export writes real JSON beside the favorites file",
  },
  { expect = [[_G.noted("Exported 2 favorite(s)")]] },
  { input = ":Cmdlog shell<CR>" },
  { wait = "_G.ready()" },
})
add(tab("ls", "ls -la", "one more favorite after the export"))
add({
  { input = "<C-c>" },
  { wait = "not _G.P()" },
  { keys = ":Cmdlog import data/favorites.export.json<CR>" },
  {
    expect = [[_G.same(_G.json("data/favorites.json"), { "dir /b", "git status", "ls -la" })]],
    note = "the import keeps what is there and adds no duplicates",
  },
  { lua = [[_G.put("data/more.json", vim.json.encode({ "git status", "from elsewhere" }))]] },
  { keys = ":Cmdlog import data/more.json<CR>" },
  {
    expect = [[_G.same(_G.json("data/favorites.json"), { "dir /b", "git status", "ls -la", "from elsewhere" })]],
    note = "what is new is appended",
  },
  { expect = [[_G.noted("(4 total)")]] },
})

return {
  id = "cmdlog.favorites",
  feature = "cmdlog.favorites",
  title = "cmdlog.nvim: favorites toggled, tagged, undone, reordered, exported and imported",
  task = "cmdlog.nvim/manual-checklist-run",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = steps,
}
