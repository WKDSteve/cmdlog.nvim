-- TESTS/sheets/features.lua -- the functionalities of cmdlog.nvim as its user meets them; `testing sheets report`
-- says which ones have a feature sheet (`feature = "<id>"`) and in which state, and K16 warns about a sheet that names
-- an id not listed here. Data: read with an empty environment like a sheet (testing.nvim docs/SHEETS.md).
-- The list follows docs/FEATURES/ (README.md and its five pages) and ALL/manual-test-checklists/cmdlog.md.
return {
  {
    id = "cmdlog.combined",
    title = "Bare :Cmdlog shows favorites, Neovim and shell history in one deduplicated picker; <CR> inserts, never runs",
    surface = { "command:Cmdlog", "binding:<CR>", "binding:<C-r>" },
    docs = "docs/FEATURES/HISTORY.md",
  },
  {
    id = "cmdlog.full",
    title = "The full variants (:Cmdlog full, nvim-full, shell-full) keep every duplicate in its place",
    surface = { "command:Cmdlog full", "command:Cmdlog nvim-full", "command:Cmdlog shell-full" },
    docs = "docs/FEATURES/COMPOSER.md",
  },
  {
    id = "cmdlog.favorites",
    title = "<Tab> marks a favorite; favorites are tagged, undone, reordered, exported and imported",
    surface = {
      "command:Cmdlog favorites",
      "command:Cmdlog export",
      "command:Cmdlog import",
      "binding:<Tab>",
      "binding:<C-t>",
      "binding:<C-z>",
    },
    docs = "docs/FEATURES/FAVORITES.md",
  },
  {
    id = "cmdlog.derived",
    title = ":Cmdlog project shows what was typed in this repository, stats the most used commands, lua the Lua ones",
    surface = {
      "command:Cmdlog project",
      "command:Cmdlog stats",
      "command:Cmdlog lua",
      "config:track_commands",
    },
    docs = "docs/FEATURES/HISTORY.md",
  },
  {
    id = "cmdlog.opt-in-files",
    title = "extra_files fold your own history files in as read-only rows, and favorites can be kept per project",
    surface = { "config:extra_files", "config:project_scoped" },
    docs = "docs/FEATURES/FAVORITES.md",
  },
  {
    id = "cmdlog.cycle",
    title = "<C-s> rotates the open picker through the sources and keeps what was typed in the prompt",
    surface = { "binding:<C-s>", "config:mappings.cycle_source" },
    docs = "docs/FEATURES/HISTORY.md",
  },
  {
    id = "cmdlog.preview",
    title = "The preview shows what a command would open without running it, unless preview_execute allows it",
    surface = { "config:preview_execute" },
    docs = "docs/FEATURES/PICKER.md",
  },
  {
    id = "cmdlog.delete",
    title = "<C-x> deletes an entry from the Neovim or the shell history, one at a time or marked in a batch",
    surface = { "binding:<C-x>", "binding:<C-Space>" },
    docs = "docs/FEATURES/PICKER.md",
  },
  {
    id = "cmdlog.errors",
    title = "A typed command that failed is marked in the picker",
    docs = "docs/FEATURES/PICKER.md",
  },
  {
    id = "cmdlog.safety",
    title = "Risky commands are flagged, and secrets matched by redact_patterns never reach cmdlog's own stores",
    surface = { "command:Cmdlog risky test", "config:risky_patterns", "config:redact_patterns" },
    docs = "docs/FEATURES/SAFETY.md",
  },
  {
    id = "cmdlog.lazygit",
    title = "<C-g> in the project picker opens lazygit for the repository root",
    surface = { "binding:<C-g>", "config:mappings.lazygit" },
    docs = "docs/configuration.md",
  },
  {
    id = "cmdlog.config-check",
    title = "Unknown option keys and bad values are reported once, and the defaults stay in force",
    docs = "docs/configuration.md",
  },
  {
    id = "cmdlog.state-recovery",
    title = "A corrupt favorites, stats or errors file is backed up once as .corrupt and nothing breaks",
    docs = "docs/FEATURES/FAVORITES.md",
  },
  {
    id = "cmdlog.fzf",
    title = 'With picker = "fzf" every picker runs on fzf-lua instead of Telescope',
    surface = { "config:picker" },
    docs = "docs/FEATURES/PICKER.md",
  },
  {
    id = "cmdlog.keymaps",
    title = "keymaps maps a :Cmdlog subcommand to a key of your own, which which-key picks up",
    surface = { "config:keymaps" },
    docs = "docs/FEATURES/PICKER.md",
  },
  {
    id = "cmdlog.picker-mappings",
    title = "Every picker key is remappable or switched off, and the prompt title shows the active ones",
    surface = { "config:mappings" },
    docs = "docs/FEATURES/PICKER.md",
  },
}
