local validation = {}

-- Count Unicode code points without Lua's optional utf8 library, which is not
-- exposed by the RuneScape sandbox. Reject malformed and non-scalar encodings.
function validation.length(value)
    local byteIndex, characterCount = 1, 0
    while byteIndex <= #value do
        local leadingByte = value:byte(byteIndex)
        local sequenceLength, minimumCodePoint, codePoint

        -- The leading byte determines how many continuation bytes to read.
        if leadingByte < 0x80 then
            sequenceLength, minimumCodePoint, codePoint = 1, 0, leadingByte
        elseif leadingByte >= 0xC2 and leadingByte <= 0xDF then
            sequenceLength, minimumCodePoint, codePoint = 2, 0x80, leadingByte - 0xC0
        elseif leadingByte >= 0xE0 and leadingByte <= 0xEF then
            sequenceLength, minimumCodePoint, codePoint = 3, 0x800, leadingByte - 0xE0
        elseif leadingByte >= 0xF0 and leadingByte <= 0xF4 then
            sequenceLength, minimumCodePoint, codePoint = 4, 0x10000, leadingByte - 0xF0
        else
            return nil
        end
        for offset = 1, sequenceLength - 1 do
            local continuationByte = value:byte(byteIndex + offset)
            if not continuationByte or continuationByte < 0x80 or continuationByte > 0xBF then
                return nil
            end
            codePoint = codePoint * 64 + continuationByte - 0x80
        end

        -- Reject overlong encodings, values outside Unicode, and UTF-16 surrogates.
        if codePoint < minimumCodePoint or codePoint > 0x10FFFF
            or (codePoint >= 0xD800 and codePoint <= 0xDFFF) then
            return nil
        end
        byteIndex = byteIndex + sequenceLength
        characterCount = characterCount + 1
    end
    return characterCount
end

return validation
