local test = require("tests.test_helper")
local validation = dofile("presets/text_validation.lua")

-- Byte escapes make boundary values explicit and independent of editor encoding.
local validTextCases = {
    { "empty text", "", 0 },
    { "ASCII text", "test", 4 },
    { "accented text", "Équipement", 10 },
    { "emoji", "\240\159\152\128", 1 },
    { "largest ASCII code point", "\127", 1 },
    { "smallest two-byte code point", "\194\128", 1 },
    { "largest two-byte code point", "\223\191", 1 },
    { "smallest three-byte code point", "\224\160\128", 1 },
    { "code point before surrogates", "\237\159\191", 1 },
    { "code point after surrogates", "\238\128\128", 1 },
    { "largest three-byte code point", "\239\191\191", 1 },
    { "smallest four-byte code point", "\240\144\128\128", 1 },
    { "largest Unicode code point", "\244\143\191\191", 1 },
    { "mixed byte lengths", "Aé\226\130\172\240\159\152\128", 4 },
    { "combining mark counts separately", "e\204\129", 2 },
}
for _, example in ipairs(validTextCases) do
    test.case("UTF-8 counts " .. example[1], function()
        test.equal(validation.length(example[2]), example[3], "Code point count")
    end)
end

local invalidTextCases = {
    { "orphan continuation byte", "\128" },
    { "overlong two-byte sequence", "\192\128" },
    { "overlong three-byte sequence", "\224\128\128" },
    { "overlong four-byte sequence", "\240\128\128\128" },
    { "truncated two-byte sequence", "\194" },
    { "truncated three-byte sequence", "\226\130" },
    { "truncated four-byte sequence", "\240\159\152" },
    { "ASCII continuation byte", "\194A" },
    { "leading byte used as continuation", "\226\194\128" },
    { "first surrogate", "\237\160\128" },
    { "last surrogate", "\237\191\191" },
    { "value above Unicode maximum", "\244\144\128\128" },
    { "invalid leading byte", "\245\128\128\128" },
    { "0xFF byte", "\255" },
    { "invalid byte after valid text", "valid\128" },
}
for _, example in ipairs(invalidTextCases) do
    test.case("UTF-8 rejects " .. example[1], function()
        test.equal(validation.length(example[2]), nil, "Malformed text must be rejected")
    end)
end
