-- Live check: a corrupt state file is kept once as `<path>.corrupt` (task
-- cmdlog.nvim/testblatt-bindings-checkliste; section 12 of ALL/manual-test-checklists/cmdlog.md).
return {
  id = "cmdlog.corrupt",
  title = "cmdlog.nvim: corrupt favorites, stats and errors are backed up once and nothing breaks",
  task = "cmdlog.nvim/manual-checklist-run",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.boot({}, { "git status" })
      _G.put("data/favorites.json", "{not json")
      _G.put("data/stats.json", "42")
      _G.put("data/errors.json", "{broken again")
      _G.put("data/errors.json.corrupt", "the first original")]],
      note = "garbage favorites, stats of the wrong shape, errors corrupt with a backup already there",
    },

    -- favorites: garbage
    { keys = ":Cmdlog favorites<CR>" },
    { wait = [[_G.noted("is corrupt; original kept at")]], note = "an error notify" },
    {
      expect = [[_G.noted("favorites.json") and _G.noted("favorites.json.corrupt")]],
      note = "naming the file and the backup",
    },
    {
      wait = [[_G.noted("No favorites found")]],
      note = "an empty list says so, no picker opens on nothing",
    },
    { expect = [[vim.v.errmsg == ""]], note = "no error" },
    {
      expect = [[_G.get("data/favorites.json.corrupt") == "{not json"]],
      note = "the backup is there",
    },

    -- stats: the wrong shape
    {
      wait = [[_G.noted("unexpected shape; original kept at")]],
      note = "the tracker's load reports the shape",
    },
    {
      expect = [[_G.get("data/stats.json.corrupt") == "42"]],
      note = "stats.json.corrupt holds the original",
    },
    { settle = 200 },
    { input = ":Cmdlog stats<CR>" },
    { wait = "_G.ready()", note = ":Cmdlog stats works, started empty" },
    { expect = [[_G.count("Cmdlog favorites") == 1]], note = "and holds what ran since" },
    {
      expect = [[type(_G.json("data/stats.json")) == "table"]],
      note = "stats.json is valid again",
    },
    { input = "<C-c>" },
    { wait = "not _G.P()" },

    -- errors: corrupt again, with a backup present (stats opened the picker, which reads the error log)
    { expect = [[_G.noted("errors.json")]], note = "the corrupt error log is reported" },
    {
      expect = [[_G.get("data/errors.json.corrupt") == "the first original"]],
      note = "the existing backup is not overwritten",
    },

    -- favorites: <Tab> after the corrupt load
    { input = ":Cmdlog shell<CR>" },
    { wait = "_G.ready()" },
    { input = "git" },
    { wait = [[_G.sel() == "git status"]] },
    { input = "<Tab>" },
    {
      wait = [[_G.same(_G.json("data/favorites.json"), { "git status" })]],
      note = "favorites.json is valid JSON with that one entry",
    },
    {
      expect = [[_G.get("data/favorites.json.corrupt") == "{not json"]],
      note = "the backup still holds the garbage",
    },
    { wait = "_G.ready()" },
    { input = "<C-c>" },
    { wait = "not _G.P()" },

    -- favorites: corrupt again, with a backup present (a new path is what a new session reads afresh)
    {
      lua = [[_G.notes = {}; _G.boot()
      _G.put("data/favorites.json", "{second garbage")
      _G.put("data/favorites.json.corrupt", "the first original")]],
    },
    { keys = ":Cmdlog favorites<CR>" },
    { wait = [[_G.noted("is corrupt; original kept at")]] },
    {
      expect = [[_G.get("data/favorites.json.corrupt") == "the first original"]],
      note = "the first backup stays",
    },
  },
}
