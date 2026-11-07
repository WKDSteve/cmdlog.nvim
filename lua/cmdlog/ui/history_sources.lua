---@module 'cmdlog.ui.history_sources'
--- Builders for the history pickers. The six pickers (`history`, `shell`, `all`,
--- each plain and `_unique`) differ only in their sources, the title, whether
--- duplicates are dropped and whether the prompt cycles on to the next source;
--- everything else (favorites first, delete adapter, open) is shared here.

local favorites = require("cmdlog.core.favorites")
local history_mod = require("cmdlog.core.history")
local shell_mod = require("cmdlog.core.shell")
local extra_files = require("cmdlog.core.extra_files")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")
local cycle = require("cmdlog.ui.cycle")

local M = {}

--- Adapts synchronous `history.delete_entry` (returns a boolean) to the async
--- `(cmd, on_done, opts)` contract the picker mappings call. Nothing to
--- confirm (`:history` is in-memory, no file rewritten), so `opts` is ignored.
---@param cmd string
---@param on_done fun(ok: boolean, err: string|nil)
---@return nil
local function delete_from_nvim_history(cmd, on_done)
  on_done(history_mod.delete_entry(cmd) == true, nil)
end

--- Swaps argument order: `shell.delete_entry` takes `(cmd, opts, on_done)`,
--- the picker mappings call `(cmd, on_done, opts)`.
---@param cmd string
---@param on_done fun(ok: boolean, err: string|nil)
---@param opts? { skip_confirm?: boolean }
---@return nil
local function delete_from_shell_history(cmd, on_done, opts)
  shell_mod.delete_entry(cmd, opts, on_done)
end

---@internal
--- Best-effort delete across both underlying history sources: a combined-view
--- entry might originate from Neovim's `:` history, the shell history file, or
--- both. Neither call prompts/errors when `cmd` isn't found in that source.
---@param cmd string
---@param on_done fun(ok: boolean, err: string|nil)
---@param opts? { skip_confirm?: boolean }  forwarded to the shell half, which
---       is the only one that rewrites a file and therefore confirms
local function delete_from_any_history(cmd, on_done, opts)
  local nvim_ok = history_mod.delete_entry(cmd)
  shell_mod.delete_entry(cmd, opts, function(shell_ok, shell_err)
    if nvim_ok or shell_ok then
      on_done(true)
    else
      on_done(false, shell_err)
    end
  end)
end

---@class Cmdlog.HistorySource
---@field raw fun(): string[]            # the unprocessed entries
---@field extras? fun(): string[]        # file-based entries appended after them
---@field delete fun(cmd: string, on_done: fun(ok: boolean, err: string|nil), opts?: table)

---@type table<string, Cmdlog.HistorySource>
local SOURCES = {
  nvim = {
    -- looked up per call, so a replaced module function is picked up
    raw = function()
      return history_mod.get_command_history()
    end,
    extras = function()
      return extra_files.get_history()
    end,
    delete = delete_from_nvim_history,
  },
  shell = {
    raw = function()
      return shell_mod.get_shell_history()
    end,
    delete = delete_from_shell_history,
  },
}

---@class Cmdlog.HistoryPickerSpec
---@field source "nvim"|"shell"
---@field unique boolean
---@field title string
---@field cycle_name? string   # attach `mappings.cycle_source` under this name (unique pickers)

--- A picker over one history source, favorites first. Returns the `show` function.
---@param spec Cmdlog.HistoryPickerSpec
---@return fun(initial_text?: string)
function M.single(spec)
  local source = SOURCES[spec.source]
  local show
  show = function(initial_text)
    local favs = favorites.load()
    local entries = process_list(source.raw(), { unique = spec.unique })

    local combined = vim.list_extend(vim.deepcopy(favs), entries)
    if source.extras then combined = vim.list_extend(combined, source.extras()) end
    -- A favorite sits in its own block on top: `unique` means it does not come
    -- back further down, and neither does an extra-file entry the history holds.
    if spec.unique then
      local seen, kept = {}, {}
      for _, entry in ipairs(combined) do
        if not seen[entry] then
          seen[entry] = true
          kept[#kept + 1] = entry
        end
      end
      combined = kept
    end

    local mappings = require("cmdlog.ui.mappings")(show, source.delete)
    picker_utils.open_picker(combined, favs, {
      prompt_title = spec.title,
      fzf_prompt = spec.title .. "> ",
      default_text = spec.cycle_name and initial_text or nil,
      attach_mappings = spec.cycle_name and function(prompt_bufnr, map)
        cycle.attach(prompt_bufnr, map, spec.cycle_name)
        return mappings(prompt_bufnr, map)
      end or mappings,
    })
  end
  return show
end

--- A picker over every source: favorites, Neovim history, shell history, extra
--- files, each block labelled with its origin. With `unique`, an entry that an
--- earlier block already holds is dropped from the later ones.
---@param spec { unique: boolean, title: string }
---@return fun()
function M.all(spec)
  local show
  show = function()
    local favs = favorites.load()
    local blocks = {
      {
        origin = "nvim",
        label = "nvim history",
        entries = process_list(history_mod.get_command_history(), { unique = spec.unique }),
      },
      {
        origin = "shell",
        label = "shell history",
        entries = process_list(shell_mod.get_shell_history(), { unique = spec.unique }),
      },
      {
        origin = "extra",
        label = "extra files",
        -- a fresh list: `list_extend` would otherwise grow a table the module may cache
        entries = vim.list_extend(
          vim.list_extend({}, extra_files.get_history()),
          extra_files.get_all()
        ),
      },
    }

    local combined = {}
    local set = {}
    -- Tracks which non-favorite source an entry came from, for the picker's
    -- origin label (opts.label below); first occurrence wins.
    local source_of = {}
    local sections = { { label = "favorites", count = #favs } }

    for _, f in ipairs(favs) do
      table.insert(combined, f)
      set[f] = true
    end
    for _, block in ipairs(blocks) do
      -- Actual per-block insertion count (after cross-source dedup), for the
      -- section dividers: dedup may drop entries an earlier block already holds.
      local count = 0
      for _, entry in ipairs(block.entries) do
        if not (spec.unique and set[entry]) then
          table.insert(combined, entry)
          set[entry] = true
          if source_of[entry] == nil or spec.unique then source_of[entry] = block.origin end
          count = count + 1
        end
      end
      sections[#sections + 1] = { label = block.label, count = count }
    end

    picker_utils.open_picker(combined, favs, {
      prompt_title = spec.title,
      fzf_prompt = spec.title .. "> ",
      -- Distinguishes nvim/shell/extra-file origin for entries that aren't
      -- favorites (favorites already carry the ★ marker).
      label = function(cmd)
        return source_of[cmd]
      end,
      -- "── nvim history ──" / "── shell history ──" divider rows at each
      -- block boundary (Telescope only, and only while the prompt is empty —
      -- see picker_utils' module doc), on top of the per-entry origin label.
      sections = picker_utils.section_dividers(sections),
      attach_mappings = require("cmdlog.ui.mappings")(show, delete_from_any_history),
    })
  end
  return show
end

return M
