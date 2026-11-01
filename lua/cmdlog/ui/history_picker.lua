---@module 'cmdlog.ui.history_picker'
--- Picker showing Neovim command-line history and favorites, duplicates included.

local sources = require("cmdlog.ui.history_sources")

local M = {}

--- Loads and shows a picker with favorites followed by the full (non-deduplicated)
--- Neovim `:` command-line history.
--- Supports Telescope and fzf as picker backends.
M.show_history_picker =
  sources.single({ source = "nvim", unique = false, title = ":history (all)" })

return M
