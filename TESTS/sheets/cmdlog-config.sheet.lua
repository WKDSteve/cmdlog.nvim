-- Live check: what `setup()` does with unknown keys and bad values (task
-- cmdlog.nvim/testblatt-bindings-checkliste; section 11 of ALL/manual-test-checklists/cmdlog.md).
local function cr_inserts(note)
  return {
    { input = ":Cmdlog nvim<CR>" },
    { wait = "_G.ready()" },
    { input = "<CR>" },
    { wait = [[vim.fn.mode() == "c"]], note = note },
    { expect = [[vim.fn.getcmdline() == "Cmdlog nvim"]], note = note },
    { input = "<Esc>" },
    { wait = [[vim.fn.mode() == "n"]] },
  }
end

local steps = {
  { lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")]] },

  -- a top-level typo
  { lua = [[_G.boot({ pikcer = "fzf" })]] },
  {
    wait = [[_G.noted("pikcer") and _G.noted("picker")]],
    note = "the dropped key, with a did-you-mean hint",
  },
  {
    expect = [[#vim.tbl_filter(function(n) return n:find("pikcer", 1, true) end, _G.notes) == 1]],
    note = "in one notify",
  },
  {
    expect = [[require("cmdlog.config").options.picker == "telescope"]],
    note = "the default stays",
  },
  { keys = ":checkhealth cmdlog<CR>" },
  {
    wait = [[_G.buftext():find("pikcer", 1, true) ~= nil]],
    note = "checkhealth warns about the same key",
  },
  { lua = [[vim.cmd("bwipeout!")]] },

  -- a typo inside mappings
  { lua = [[_G.notes = {}; _G.boot({ mappings = { slect = "<C-s>" } })]] },
  {
    wait = [[_G.noted("unknown option 'mappings.slect' (did you mean 'mappings.select'?)")]],
    note = "named with its path",
  },
}
local function add(list)
  for i = 1, #list do
    steps[#steps + 1] = list[i]
  end
end
add(cr_inserts("<CR> still inserts: the default mapping stays in force"))

-- an invalid value
add({
  { lua = [[_G.notes = {}; _G.boot({ picker = "sublime" })]] },
  { wait = [[_G.noted("sublime")]], note = "an invalid picker is reported" },
  { expect = [[require("cmdlog.config").options.picker == "telescope"]], note = "and falls back" },
  { input = ":Cmdlog<CR>" },
  { wait = "_G.ready()", note = ":Cmdlog still opens a working picker" },
  { input = "<C-c>" },
  { wait = "not _G.P()" },
})

-- a non-table value for a table option
add({
  { lua = [[_G.notes = {}; _G.boot({ mappings = false })]] },
  { wait = [[_G.noted("mappings")]], note = "reported" },
  {
    expect = [[require("cmdlog.config").options.mappings.select == "<CR>"]],
    note = "the default mappings stay",
  },
})
add(cr_inserts("<CR> still inserts: not all keys gone"))

-- a malformed redact pattern: everything counts as a match
add({
  {
    lua = [[_G.notes = {}; vim.v.errmsg = ""; _G.boot({ redact_patterns = { "[unclosed" } })
    vim.fn.mkdir(_G.p("repo/.git"), "p")]],
    note = "no error at setup()",
  },
  { keys = ":cd repo<CR>" },
  { keys = ":let g:after = 1<CR>", note = "no error on the next command" },
  { settle = 300 },
  { expect = [[vim.g.after == 1]], note = "the command itself ran" },
  { expect = [[_G.get("data/stats.json") == nil]], note = "nothing reached the stats" },
  {
    expect = [[_G.get("data/project_history.json") == nil]],
    note = "nothing reached the project history",
  },
  { expect = [[vim.v.errmsg == ""]] },
})

return {
  id = "cmdlog.config",
  title = "cmdlog.nvim: unknown keys and bad values are reported once and the defaults stay",
  task = "cmdlog.nvim/testblatt-bindings-checkliste",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = steps,
}
