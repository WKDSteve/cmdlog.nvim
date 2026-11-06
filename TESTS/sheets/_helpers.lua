-- TESTS/sheets/_helpers.lua -- what every cmdlog test sheet needs in its child editor. Not a sheet
-- (`testing.sheet` only reads *.sheet.lua); a sheet's first step runs it with `dofile`, the child's cwd is
-- the project root. The directory is in the spec's @cache-inputs, so a change here re-runs the sheets.
--
-- Nothing is stubbed here but the one prompt the child would answer with "cancelled" (`vim.ui.input`).
-- Every state file, the shell history and the cwd live in a throwaway directory: the real
-- stdpath("data")/cmdlog and the real PSReadLine file are never touched.

local uv = vim.uv or vim.loop

vim.opt.shortmess:append("I")
vim.o.swapfile = false

-- Every notification, for the steps that look at the wording.
_G.notes = {}
vim.notify = function(msg)
  _G.notes[#_G.notes + 1] = tostring(msg)
end

---Whether a notification so far holds `text` (plain).
---@param text string
---@return boolean
function _G.noted(text)
  for _, n in ipairs(_G.notes) do
    if n:find(text, 1, true) then return true end
  end
  return false
end

-- The answer of the tag prompt (the child answers every real prompt with "cancelled").
_G.answer = nil
_G.asked = {}
vim.ui.input = function(opts, on_confirm)
  _G.asked[#_G.asked + 1] = opts.prompt
  on_confirm(_G.answer)
end

---A fresh, resolved directory.
---@return string
local function fresh()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  return vim.fs.normalize(uv.fs_realpath(dir) or dir)
end

---@param rel string  Path below the sandbox.
---@return string
function _G.p(rel)
  return _G.root .. "/" .. rel
end

---Write a file below the sandbox, parents included. A list is written line by line.
---@param rel string
---@param text? string|string[]
function _G.put(rel, text)
  local path = _G.p(rel)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local f = assert(io.open(path, "wb"))
  if type(text) == "table" then text = #text > 0 and (table.concat(text, "\n") .. "\n") or "" end
  f:write(text or "")
  f:close()
end

---The content of a file below the sandbox, nil when it does not exist.
---@param rel string
---@return string|nil
function _G.get(rel)
  local f = io.open(_G.p(rel), "rb")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

---The decoded JSON of a file below the sandbox, nil when it does not exist.
---@param rel string
---@return any
function _G.json(rel)
  local s = _G.get(rel)
  return s and vim.json.decode(s) or nil
end

---The lines of a file below the sandbox.
---@param rel string
---@return string[]
function _G.lines(rel)
  return vim.split((_G.get(rel) or ""):gsub("\r", ""), "\n", { trimempty = true })
end

---Whether a value equals another one, deeply.
---@param got any
---@param want any
---@return boolean
function _G.same(got, want)
  return vim.deep_equal(got, want)
end

---A throwaway sandbox with cmdlog set up over it: the state files below `data/`, the shell history in
---`shell_history.txt` (one command per line, the PSReadLine format, whatever the runner's shell is), the cwd
---at the sandbox, which is no Git repository. `opts` go over these into `setup()`.
---@param opts? table
---@param shell_lines? string[]
function _G.boot(opts, shell_lines)
  _G.root = fresh()
  vim.env.SHELL = "pwsh"
  _G.put("shell_history.txt", shell_lines or {})
  vim.api.nvim_set_current_dir(_G.root)
  require("cmdlog").setup(vim.tbl_deep_extend("force", {
    favorites_path = _G.p("data/favorites.json"),
    favorite_tags_path = _G.p("data/favorite_tags.json"),
    project_history_path = _G.p("data/project_history.json"),
    stats_path = _G.p("data/stats.json"),
    errors_path = _G.p("data/errors.json"),
    shell_history_path = _G.p("shell_history.txt"),
  }, opts or {}))
end

---Seed the `:` history, oldest first, without running anything.
---@param ... string
function _G.seed(...)
  for _, cmd in ipairs({ ... }) do
    vim.fn.histadd(":", cmd)
  end
end

---The `:` history, as `:history` holds it.
---@return string[]
function _G.history()
  local out = {}
  for i = 1, vim.fn.histnr(":") do
    local cmd = vim.fn.histget(":", i)
    if cmd ~= "" then out[#out + 1] = cmd end
  end
  return out
end

---The entries of the `:` history holding `let g:mark`, for the batch delete.
---@return string[]
function _G.marks()
  return vim.tbl_filter(function(cmd)
    return cmd:find("let g:mark", 1, true) ~= nil
  end, _G.history())
end

---The text of the current buffer (a health report).
---@return string
function _G.buftext()
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

---The open Telescope picker, nil when the current buffer is not its prompt.
---@return table|nil
function _G.P()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= "TelescopePrompt" then return nil end
  return require("telescope.actions.state").get_current_picker(buf)
end

---The picker is open, takes input, and every result of its finder stands in the result window.
---@return boolean
function _G.ready()
  local picker = _G.P()
  return picker ~= nil
    and picker.manager -- false while the picker closes
    and vim.fn.mode() == "i"
    and require("telescope.actions.state").get_selected_entry() ~= nil
    and #_G.rows() == picker.manager:num_results()
end

---The value under the picker's cursor.
---@return string|false|nil
function _G.sel()
  local entry = require("telescope.actions.state").get_selected_entry()
  return entry and entry.value
end

---The rows of the picker's result window, best match first, blanks left out.
---@return string[]
function _G.rows()
  local picker = _G.P()
  if not picker then return {} end
  local all = vim.api.nvim_buf_get_lines(picker.results_bufnr, 0, -1, false)
  local out = {}
  for i = #all, 1, -1 do
    if vim.trim(all[i]) ~= "" then out[#out + 1] = all[i] end
  end
  return out
end

---How many result rows hold `text` (plain).
---@param text string
---@return integer
function _G.count(text)
  local n = 0
  for _, row in ipairs(_G.rows()) do
    if row:find(text, 1, true) then n = n + 1 end
  end
  return n
end

---The result row holding `text`, nil when there is none.
---@param text string
---@return string|nil
function _G.row(text)
  for _, row in ipairs(_G.rows()) do
    if row:find(text, 1, true) then return row end
  end
end

---The highlight groups on the result row holding `text`.
---@param text string
---@return table<string, boolean>
function _G.groups(text)
  local picker = _G.P()
  local out = {}
  if not picker then return out end
  local all = vim.api.nvim_buf_get_lines(picker.results_bufnr, 0, -1, false)
  for i, line in ipairs(all) do
    if line:find(text, 1, true) then
      local marks = vim.api.nvim_buf_get_extmarks(
        picker.results_bufnr,
        -1,
        { i - 1, 0 },
        { i - 1, -1 },
        { details = true }
      )
      for _, mark in ipairs(marks) do
        if mark[4].hl_group then out[mark[4].hl_group] = true end
      end
    end
  end
  return out
end

---The text of the preview window.
---@return string
function _G.preview()
  local picker = _G.P()
  local win = picker and picker.preview_win
  if not win or not vim.api.nvim_win_is_valid(win) then return "" end
  local buf = vim.api.nvim_win_get_buf(win)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
end
