-- Live check: risky-command highlighting, `:Cmdlog risky test`, and the redact filter (task
-- cmdlog.nvim/testblatt-bindings-checkliste; section 5 of ALL/manual-test-checklists/cmdlog.md). The secret
-- goes through `:let` instead of the checklist's `:!curl`: what is tested is the tracker, nothing leaves the
-- machine.
local SECRET = [[let g:header = "Authorization: Bearer sk-fake-test-token"]]
local CLEAN = [[(function()
  local out = {}
  for _, name in ipairs({ "stats", "project_history", "errors" }) do
    out[#out + 1] = _G.get("data/" .. name .. ".json") or ""
  end
  return not table.concat(out):find("sk-fake", 1, true)
end)()]]

return {
  id = "cmdlog.safety",
  title = "cmdlog.nvim: risky commands are flagged, secrets never reach cmdlog's own stores",
  task = "cmdlog.nvim/testblatt-bindings-checkliste",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.boot()
      _G.seed("let g:plain = 1", "!git reset --hard", "!rm -rf build", "qa!")
      vim.fn.mkdir(_G.p("repo/.git"), "p")]],
      note = "three risky entries and an ordinary one, in history only",
    },

    -- the highlight
    { input = ":Cmdlog nvim<CR>" },
    { wait = "_G.ready()" },
    {
      expect = [[_G.groups("git reset --hard").CmdlogRiskyCommand]],
      note = "git reset --hard is flagged",
    },
    { expect = [[_G.groups("rm -rf build").CmdlogRiskyCommand]], note = "rm -rf is flagged" },
    { expect = [[_G.groups("qa!").CmdlogRiskyCommand]], note = "qa! is flagged" },
    {
      expect = [[not _G.groups("let g:plain = 1").CmdlogRiskyCommand]],
      note = "an ordinary entry is not",
    },
    { expect = [[vim.fn.hlexists("CmdlogRiskyCommand") == 1]], note = "the group is defined" },
    { input = "<C-c>" },
    { wait = "not _G.P()" },

    -- risky test: with the highlight on
    { keys = ":Cmdlog risky test git reset --hard HEAD~3<CR>" },
    {
      expect = [[_G.noted("Matched 1 of 10 pattern(s):\n  git%s+reset%s+%-%-hard")]],
      note = "names the pattern",
    },
    { expect = [[not _G.noted("highlight_risky is off")]], note = "the highlight is on" },
    { keys = ":Cmdlog risky test git status<CR>" },
    {
      expect = [[_G.noted("No match (10 pattern(s) checked).")]],
      note = "an ordinary command matches nothing",
    },

    -- risky test: with the highlight off
    {
      lua = [[_G.notes = {}; require("cmdlog").setup(vim.tbl_extend("force", require("cmdlog.config").options, {
        highlight_risky = false,
      }))]],
      note = "highlight_risky = false",
    },
    { keys = ":Cmdlog risky test git reset --hard HEAD~3<CR>" },
    { expect = [[_G.noted("Matched 1 of 10")]], note = "the test evaluates all the same" },
    {
      expect = [[_G.noted("highlight_risky is off")]],
      note = "and says that pickers will not show it",
    },
    { input = ":Cmdlog nvim<CR>" },
    { wait = "_G.ready()" },
    {
      expect = [[not _G.groups("git reset --hard").CmdlogRiskyCommand]],
      note = "the picker does not flag it",
    },
    { input = "<C-c>" },
    { wait = "not _G.P()" },

    -- redact: inside a repository, so that all three stores would take it
    { keys = ":cd repo<CR>" },
    { keys = ":let g:ordinary = 1<CR>" },
    { keys = ":" .. SECRET .. "<CR>" },
    { keys = ":NoSuchCommand --token=sk-fake-test-token<CR>", ignore_errmsg = true },
    { settle = 500 },
    {
      expect = [[(_G.get("data/stats.json") or ""):find("let g:ordinary", 1, true) ~= nil]],
      note = "tracking runs",
    },
    {
      expect = [[(_G.get("data/project_history.json") or ""):find("let g:ordinary", 1, true) ~= nil]],
      note = "project history as well",
    },
    { expect = CLEAN, note = "the secret is in no store" },
    {
      expect = [[vim.tbl_contains(_G.history(), ]] .. ("%q"):format(SECRET) .. [[)]],
      note = "but in plain `:` history",
    },
    { input = ":Cmdlog stats<CR>" },
    { wait = "_G.ready()" },
    { expect = [[_G.count("sk-fake") == 0]], note = ":Cmdlog stats does not show it" },
    { input = "<C-c>" },
    { wait = "not _G.P()" },
  },
}
