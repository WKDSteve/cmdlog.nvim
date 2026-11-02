-- luacheck configuration for cmdlog.nvim
std = "luajit"
read_globals = { "vim" }

-- Neovim Lua conventions favor readability over a hard line-length cap;
-- don't fail CI on line length alone.
max_line_length = false

-- Specs stub vim.notify, vim.env.* and vim.fn.feedkeys on purpose (and restore them).
files["TESTS"] = { globals = { "vim" } }
