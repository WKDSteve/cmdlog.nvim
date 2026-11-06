-- Live check: `:checkhealth cmdlog` with the defaults (task cmdlog.nvim/testblatt-bindings-checkliste; the setup
-- section of ALL/manual-test-checklists/cmdlog.md). Which real history file a Windows machine reports stays for a
-- person: here the file is the sandbox's, named through `shell_history_path`.
return {
  id = "cmdlog.health",
  title = "cmdlog.nvim: :checkhealth names Neovim, lib.nvim, the picker, the options and the shell history",
  task = "cmdlog.nvim/testblatt-bindings-checkliste",
  sizes = { { rows = 40, cols = 160 } },
  requires = {
    { lua = [[pcall(require, "telescope")]], reason = "telescope.nvim is not on the runtimepath" },
  },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.boot({}, { "git status" })]],
    },
    { keys = ":checkhealth cmdlog<CR>" },
    { wait = [[_G.buftext():find("Neovim version >= 0.9", 1, true)]], note = "the Neovim version" },
    { expect = [[_G.buftext():find("lib.nvim found", 1, true)]], note = "lib.nvim" },
    {
      expect = [[_G.buftext():find("picker = 'telescope' and telescope.nvim found", 1, true)]],
      note = "the configured picker",
    },
    {
      expect = [[_G.buftext():find("every setup() option was recognised", 1, true)]],
      note = "the options",
    },
    { expect = [[_G.buftext():find("Detected shell: powershell", 1, true)]], note = "the shell" },
    {
      expect = [[_G.buftext():find("Shell history file found: ", 1, true)
        and _G.buftext():find("shell_history.txt", 1, true)]],
      note = "its history file",
    },
    { expect = [[_G.buftext():find("gitsuite.nvim", 1, true)]], note = "and gitsuite.nvim" },
  },
  manual = {
    "On a Windows machine with SHELL unset: :checkhealth cmdlog reports the real PSReadLine file below %APPDATA%, not a POSIX shell",
  },
}
