local names = require("presets/names")
local colours = {}
colours.palette = {
    { name = "Default", value = "" },
    { name = "Red", value = "red", rgba = 0xFF0000FF },
    { name = "Green", value = "green", rgba = 0x008000FF },
    { name = "Blue", value = "blue", rgba = 0x0080FFFF },
    { name = "White", value = "white", rgba = 0xFFFFFFFF },
    { name = "Black", value = "black", rgba = 0x000000FF },
    { name = "Purple", value = "purple", rgba = 0x800080FF },
    { name = "Cyan", value = "cyan", rgba = 0x00FFFFFF },
    { name = "Yellow", value = "yellow", rgba = 0xFFFF00FF },
    { name = "Orange", value = "orange", rgba = 0xFFA500FF },
    { name = "Pink", value = "pink", rgba = 0xFFC0CBFF },
    { name = "Magenta", value = "magenta", rgba = 0xFF00FFFF },
    { name = "Lime", value = "lime", rgba = 0x00FF00FF },
    { name = "Grey", value = "grey", rgba = 0x808080FF },
}
local cache, context = {}, nil
local function key(slot, kind)
    local current = names.getContext()
    if current ~= context then cache, context = {}, current end
    if not context then return nil end
    return "presetColour.v1.displayName." .. context .. "." .. slot .. "." .. kind
end
local function valid(slot, kind)
    return type(slot) == "number" and slot % 1 == 0 and slot >= 1 and slot <= 18
        and (kind == "background" or kind == "text")
end
local function entry(value)
    for _, item in ipairs(colours.palette) do
        if item.value == value then return item end
    end
end
function colours.get(slot, kind)
    if not valid(slot, kind) then return "" end
    local storageKey = key(slot, kind)
    if not storageKey then return "" end
    if cache[storageKey] == nil then
        local value = PersistentDB:GetString(storageKey)
        cache[storageKey] = entry(value) and value or ""
    end
    return cache[storageKey]
end
function colours.rgba(slot, kind)
    return entry(colours.get(slot, kind)).rgba
end
function colours.save(slot, kind, value)
    if not valid(slot, kind) or not entry(value) then return false, "Invalid colour selection." end
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
