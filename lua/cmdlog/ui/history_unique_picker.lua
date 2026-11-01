---@module 'cmdlog.ui.history_unique_picker'
--- Picker showing deduplicated Neovim command-line history and favorites.

local sources = require("cmdlog.ui.history_sources")

local M = {}

--- Loads and shows a picker displaying unique command history entries.
--- Commands are deduplicated to show each command only once.
--- Favorites are highlighted but not prioritized at the top.
--- Supports Telescope and fzf as picker backends.
--- `initial_text` pre-fills the prompt; used by `mappings.cycle_source`.
--- Supports Telescope and fzf as picker backends.
M.show_history_unique_picker = sources.single({
  source = "nvim",
  unique = true,
  title = ":history (unique)",
  cycle_name = "nvim",
})

return M
