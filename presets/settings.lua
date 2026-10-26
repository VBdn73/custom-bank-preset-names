-- Bank display preferences are device-wide, like the editor position.
local settings = {}
local key = "presetSettings.v1.hidePredefinedDropdown"

function settings.hidePredefinedDropdown()
    return PersistentDB:GetString(key) == "true"
end

function settings.setHidePredefinedDropdown(hidden)
    local value = hidden and "true" or "false"
    local result = PersistentDB:SetString(key, value)
    return result ~= false and PersistentDB:GetString(key) == value
end

return settings
