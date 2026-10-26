-- Shared colour conversion for storage, swatches and the picker. No client API needed.
local value = {}
function value.normalize(hex)
    if type(hex) ~= "string" then return nil end
    if hex:match("^#%x%x%x%x%x%x$") then return hex:upper() end
end
function value.rgba(hex)
    hex = value.normalize(hex)
    return hex and tonumber(hex:sub(2), 16) * 256 + 255 or nil
end
function value.vector(hex)
    local rgba = value.rgba(hex)
    if not rgba then return nil end
    return { ((rgba >> 24) & 255) / 255, ((rgba >> 16) & 255) / 255,
        ((rgba >> 8) & 255) / 255, 1 }
end
function value.fromHSV(h, s, v)
    local sector = (h % 1) * 6
    local x = v * s * (1 - math.abs(sector % 2 - 1))
    local c, m = v * s, v * (1 - s)
    local channels = { { c, x, 0 }, { x, c, 0 }, { 0, c, x },
        { 0, x, c }, { x, 0, c }, { c, 0, x } }
    local rgb = channels[math.floor(sector) + 1]
    return string.format("#%02X%02X%02X", math.floor((rgb[1] + m) * 255 + 0.5),
        math.floor((rgb[2] + m) * 255 + 0.5), math.floor((rgb[3] + m) * 255 + 0.5))
end
function value.toHSV(hex)
    local rgb = value.vector(hex) or { 1, 1, 1 }
    local r, g, b = rgb[1], rgb[2], rgb[3]
    local high, low = math.max(r, g, b), math.min(r, g, b)
    local d, h = high - low, 0
    if d > 0 then
        if high == r then h = ((g - b) / d) % 6
        elseif high == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
    end
    return h / 6, high == 0 and 0 or d / high, high
end
return value
