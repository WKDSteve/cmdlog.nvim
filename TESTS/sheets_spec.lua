-- TESTS/sheets_spec.lua — the live checks of TESTS/sheets/*.sheet.lua (testing.sheet), run by the
-- RPC klicker in a child editor. Busted style on purpose: each sheet is its own case named
-- `sheet:<id>`, the name `testing sheets report` finds the result by.
-- @cache-inputs TESTS/sheets/ TESTS/__snapshots__/
---@diagnostic disable: undefined-global
-- luacheck: read globals describe it

local sheet = require("testing.sheet")
local this = vim.fs.normalize(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p"))
local root = vim.fs.dirname(vim.fs.dirname(this))

describe("test sheets", function()
  for _, path in ipairs(sheet.files(root .. "/TESTS/sheets")) do
    local s, err = sheet.load(path)
    it(s and sheet.spec_name(s) or path, function()
      assert(s, err)
      sheet.check(s, { root = root })
    end)
  end
end)
