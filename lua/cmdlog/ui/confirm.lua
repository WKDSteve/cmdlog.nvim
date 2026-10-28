---@module 'cmdlog.ui.confirm'
--- Yes/no question for the delete confirmations, asked through lib.nvim's shared dialog
--- (`lib.nvim.ui.dialog.yesno`): "No" is the first and focused button, `n`/`y` are keys, it waits for
--- a dialog that is already open instead of replacing it (which would drop that dialog's answer), and
--- anything that is not an explicit yes -- no answer in ten minutes, a dialog that cannot open and is
--- dismissed -- is a "no", so a delete never goes ahead by accident. When the float cannot open at
--- all, the dialog asks through `vim.ui.select`.
---
--- Contract: `{ question, on_answer(yes: boolean) }`, `on_answer` at most once.

local M = {}

---@param opts { question: string, on_answer: fun(yes: boolean) }
---@return nil
function M.ask(opts)
  require("lib.nvim.ui.dialog").yesno(opts.question, "delete", opts.on_answer, {
    unprompted = true,
    kind = "danger",
  })
end

return M
