---@module 'cmdlog.ui.all_unique_picker'
--- Picker showing every history entry (favorites, Neovim, and shell), deduplicated.

local sources = require("cmdlog.ui.history_sources")

local M = {}

--- Loads and shows a picker combining favorites and unique history entries from both Nvim and shell.
--- Combined list: Favorites first, then Nvim history, then Shell history.
--- Supports Telescope and fzf as picker backends.
M.show_all_unique_picker = sources.all({ unique = true, title = ":history & favorites (unique)" })

return M
