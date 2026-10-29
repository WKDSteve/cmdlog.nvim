---@module 'cmdlog.bindings.picker_mappings'
--- Descriptive catalog of the in-picker keymaps implemented in
--- lua/cmdlog/ui/mappings.lua. This file registers nothing itself — it exists
--- so docs/BINDINGS.md and `:checkhealth`/introspection tooling have a single
--- place to read the current set of picker keys from `config.options.mappings`.

local M = {}

---@type table<string, {config_key: string, desc: string}>
M.catalog = {
  select = {
    config_key = "mappings.select",
    desc = "Insert the selected command into the cmdline (no execution)",
  },
  toggle_favorite = {
    config_key = "mappings.toggle_favorite",
    desc = "Toggle favorite status for the selected command",
  },
  refresh = { config_key = "mappings.refresh", desc = "Refresh the current picker" },
  delete = {
    config_key = "mappings.delete",
    desc = "Delete the selected entry (or every marked one) from its underlying history",
  },
  toggle_selection = {
    config_key = "mappings.toggle_selection",
    desc = "Mark/unmark an entry for a batch delete, then move down",
  },
  tag = {
    config_key = "mappings.tag",
    desc = "Tag the selected favorite (favorites picker only)",
  },
  cycle_source = {
    config_key = "mappings.cycle_source",
    desc = "Rotate to the next picker, keeping the prompt text (Telescope only)",
  },
  undo_favorite = {
    config_key = "mappings.undo_favorite",
    desc = "Undo the most recent favorite toggle",
  },
  move_favorite_up = {
    config_key = "mappings.move_favorite_up",
    desc = "Move the selected favorite up one slot (favorites picker only)",
  },
  move_favorite_down = {
    config_key = "mappings.move_favorite_down",
    desc = "Move the selected favorite down one slot (favorites picker only)",
  },
  lazygit = {
    config_key = "mappings.lazygit",
    desc = "Open lazygit for the project root (project picker only, needs gitsuite.nvim)",
  },
}

--- Returns the catalog with each entry's currently configured key merged in.
--- @return table<string, {config_key: string, desc: string, key: string|false}>
function M.resolved()
  local mappings = require("cmdlog.config").options.mappings
  local out = {}
  for name, entry in pairs(M.catalog) do
    out[name] = vim.tbl_extend("force", entry, { key = mappings[name] })
  end
  return out
end

return M
