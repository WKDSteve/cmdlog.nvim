---@module 'cmdlog.ui.all_picker'
--- Picker showing every history entry (favorites, Neovim, and shell), duplicates included.

local sources = require("cmdlog.ui.history_sources")

local M = {}

--- Loads and shows a picker combining all history entries and favorites.
--- Combined list: Favorites first, then Nvim history, then Shell history.
--- Supports Telescope and fzf as picker backends.
M.show_all_picker = sources.all({ unique = false, title = ":history & favorites" })

return M
