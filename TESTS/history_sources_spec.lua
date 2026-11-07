-- TESTS/history_sources_spec.lua — the single-source pickers: `unique` also drops what the
-- favorites block on top or the extra files already hold; the full picker filters nothing.

return function(H)
  local favorites = require("cmdlog.core.favorites")
  local history = require("cmdlog.core.history")
  local extra_files = require("cmdlog.core.extra_files")
  local picker_utils = require("cmdlog.ui.picker_utils")
  local sources = require("cmdlog.ui.history_sources")

  local real = {
    load = favorites.load,
    raw = history.get_command_history,
    extras = extra_files.get_history,
    open = picker_utils.open_picker,
  }
  local shown
  favorites.load = function()
    return { "fav", "other fav" }
  end
  history.get_command_history = function()
    return { "older", "fav", "newer" }
  end
  extra_files.get_history = function()
    return { "newer", "from file", "from file" }
  end
  picker_utils.open_picker = function(entries)
    shown = table.concat(entries, ",")
  end

  sources.single({ source = "nvim", unique = true, title = "unique" })()
  H.eq(shown, "fav,other fav,newer,older,from file", "unique: every command once, favorites first")

  sources.single({ source = "nvim", unique = false, title = "full" })()
  H.eq(
    shown,
    "fav,other fav,newer,fav,older,newer,from file,from file",
    "full: nothing is filtered"
  )

  favorites.load = real.load
  history.get_command_history = real.raw
  extra_files.get_history = real.extras
  picker_utils.open_picker = real.open
end
