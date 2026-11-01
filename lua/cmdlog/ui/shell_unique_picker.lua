---@module 'cmdlog.ui.shell_unique_picker'
--- Picker showing deduplicated shell history and favorites.

local sources = require("cmdlog.ui.history_sources")

local M = {}

--- Loads and shows a picker displaying unique shell history commands combined with favorites.
--- `initial_text` pre-fills the prompt; used by `mappings.cycle_source`.
--- Supports Telescope and fzf as picker backends.
M.show_shell_unique_picker = sources.single({
  source = "shell",
  unique = true,
  title = ":shell & favorites (unique)",
  cycle_name = "shell",
})

return M
