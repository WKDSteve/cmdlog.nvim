-- Live check: `<C-s>` rotates nvim -> shell -> favorites -> project -> nvim and keeps the typed text (task
-- cmdlog.nvim/testblatt-bindings-checkliste; section 7 of ALL/manual-test-checklists/cmdlog.md).
local function hop(title, value)
  return {
    { input = "<C-s>" },
    {
      wait = ([[_G.ready() and _G.P().prompt_title:find(%q, 1, true) == 1]]):format(title),
      note = "on to " .. title,
    },
    { wait = ([[_G.count(%q) == 1]]):format(value), note = title .. ": the entry" },
    { expect = [[_G.line() == "git"]], note = title .. ": the typed text survives" },
  }
end

local steps = {
  {
    lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
    _G.line = function() return require("telescope.actions.state").get_current_line() end
    _G.boot({}, { "git log" })
    _G.put("data/favorites.json", vim.json.encode({ "git fav" }))
    vim.fn.mkdir(_G.p("repo/.git"), "p")]],
    note = "one entry with `git` in it for every stop of the rotation",
  },
  { keys = ":cd repo<CR>" },
  { keys = ":let g:git_cmd = 1<CR>" },
  { settle = 300 },
  { input = ":Cmdlog nvim<CR>" },
  { wait = "_G.ready()" },
  { input = "git" },
  { wait = [[_G.count("let g:git_cmd = 1") == 1 and _G.line() == "git"]] },
}
local hops = {
  hop(":shell & favorites (unique)", "git log"),
  hop(":history (Favorites)", "git fav"),
  hop(":history (current project)", "let g:git_cmd = 1"),
  hop(":history (unique)", "let g:git_cmd = 1"),
}
for h = 1, #hops do
  for i = 1, #hops[h] do
    steps[#steps + 1] = hops[h][i]
  end
end
steps[#steps + 1] = { input = "<C-c>" }
steps[#steps + 1] = { wait = "not _G.P()" }

return {
  id = "cmdlog.cycle",
  feature = "cmdlog.cycle",
  title = "cmdlog.nvim: <C-s> rotates through the four pickers and keeps the prompt text",
  task = "cmdlog.nvim/manual-checklist-run",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = steps,
}
