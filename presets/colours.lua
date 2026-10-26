local names = require("presets/names")
local colourValue = require("presets/colour_value")
local colours = {}
local cache, context = {}, nil
local function key(slot, kind)
    local current = names.getContext()
    if current ~= context then cache, context = {}, current end
    if not context then return nil end
    -- Keep the original storage key so existing saved colours remain available.
    return "presetColour.v1.displayName." .. context .. "." .. slot .. "." .. kind
end
local function valid(slot, kind)
    return type(slot) == "number" and slot % 1 == 0 and slot >= 1 and slot <= 18
        and (kind == "background" or kind == "text")
end
function colours.get(slot, kind)
    if not valid(slot, kind) then return "" end
    local storageKey = key(slot, kind)
    if not storageKey then return "" end
    if cache[storageKey] == nil then
        local value = PersistentDB:GetString(storageKey)
        cache[storageKey] = colourValue.normalize(value) or ""
    end
    return cache[storageKey]
end
function colours.rgba(slot, kind)
    return colourValue.rgba(colours.get(slot, kind))
end
function colours.save(slot, kind, value)
    value = colourValue.normalize(value) or value
    if not valid(slot, kind) or (value ~= "" and not colourValue.normalize(value)) then
        return false, "Invalid colour selection."
    end
    local storageKey = key(slot, kind)
    if not storageKey then return false, "Log in before choosing colours." end
    local result = PersistentDB:SetString(storageKey, value)
    if result == false or PersistentDB:GetString(storageKey) ~= value then
        return false, "Colour storage verification failed."
    end
    cache[storageKey] = value
    return true, "Colour saved."
end
return colours
