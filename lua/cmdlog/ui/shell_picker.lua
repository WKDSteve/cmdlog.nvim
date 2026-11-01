---@module 'cmdlog.ui.shell_picker'
--- Picker showing shell history and favorites, duplicates included.

local sources = require("cmdlog.ui.history_sources")

local M = {}

--- Loads and shows a picker displaying shell history commands and favorites.
--- Shell history commands are shown without deduplication; duplicates are allowed.
--- Favorites are always displayed at the top.
--- Supports Telescope and fzf as picker backends.
M.show_shell_picker =
  sources.single({ source = "shell", unique = false, title = ":shell & favorites (all)" })

return M
