local names = require("presets/names")
local catalogue = require("presets/icon_catalogue")
local slots = require("presets/slots")
local storage = require("storage")
local icons = {}
local cache, context = {}, nil

local function key(slot)
    local current = names.getContext()
    if current ~= context then cache, context = {}, current end
    if not context then return nil end
    return "presetIcon.v1.displayName." .. context .. "." .. slot
end

-- Validate identity, not current resource availability. A temporarily missing
-- sprite must not invalidate an otherwise supported saved selection.
function icons.normalize(value)
    if value == "" or catalogue.get(value) then return value end
    return nil, "Invalid icon selection."
end

function icons.get(slot)
    if not slots.valid(slot) then return "" end
    local storageKey = key(slot)
    if not storageKey then return "" end
    if cache[storageKey] == nil then
        cache[storageKey] = icons.normalize(PersistentDB:GetString(storageKey)) or ""
    end
    return cache[storageKey]
end

function icons.save(slot, value)
    local normalized, message = icons.normalize(value)
    if not slots.valid(slot) or normalized == nil then
        return false, message or "Invalid preset for icon selection."
    end
    local storageKey = key(slot)
    if not storageKey then return false, "Log in before choosing icons." end
    if not storage.writeVerified(storageKey, normalized) then
        return false, "Icon storage verification failed."
    end
    cache[storageKey] = normalized
    return true, normalized == "" and "Using the preset number." or "Icon saved."
end

return icons
