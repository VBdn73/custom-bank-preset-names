-- Run from the repository root: lua tests/run.lua
-- Match the client sandbox, where the optional standard utf8 library is absent.
utf8 = nil
local test = require("tests.test_helper")
print("\ncolours")
dofile("tests/colours.lua")

for _, suite in ipairs({ "text_validation", "preset_names", "bank_labels", "editor_style", "name_editor", "preset_menu", "editor_popup", }) do
    print("\n" .. suite)
    dofile("tests/" .. suite .. ".lua")
end

print(string.format("\n%d passed, %d failed.", test.passed, test.failed))
if test.failed > 0 then os.exit(1) end
