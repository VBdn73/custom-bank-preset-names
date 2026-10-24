local validation = {}

-- Count Unicode code points without Lua's optional utf8 library, which is not
-- exposed by the RuneScape sandbox. Reject malformed and non-scalar encodings.
function validation.length(value)
    local index, count = 1, 0
    while index <= #value do
        local first = value:byte(index)
        local size, minimum, codepoint
        if first < 0x80 then
            size, minimum, codepoint = 1, 0, first
        elseif first >= 0xC2 and first <= 0xDF then
            size, minimum, codepoint = 2, 0x80, first - 0xC0
        elseif first >= 0xE0 and first <= 0xEF then
            size, minimum, codepoint = 3, 0x800, first - 0xE0
        elseif first >= 0xF0 and first <= 0xF4 then
            size, minimum, codepoint = 4, 0x10000, first - 0xF0
        else
            return nil
        end
        for offset = 1, size - 1 do
            local byte = value:byte(index + offset)
            if not byte or byte < 0x80 or byte > 0xBF then return nil end
            codepoint = codepoint * 64 + byte - 0x80
        end
        if codepoint < minimum or codepoint > 0x10FFFF
            or (codepoint >= 0xD800 and codepoint <= 0xDFFF) then
            return nil
        end
        index = index + size
        count = count + 1
    end
    return count
end

return validation
