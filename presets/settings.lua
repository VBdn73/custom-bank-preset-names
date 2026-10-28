-- Bank display preferences are device-wide, like the editor position.
local settings = {}
local hidePredefinedDropdownKey = "presetSettings.v1.hidePredefinedDropdown"
local compactBackgroundKey = "presetSettings.v1.showCompactBackgrounds"

function settings.showCompactBackgrounds()
    return PersistentDB:GetString(compactBackgroundKey) ~= "false"
end

function settings.setShowCompactBackgrounds(shown)
    local value = shown and "true" or "false"
    local result = PersistentDB:SetString(compactBackgroundKey, value)
    return result ~= false and PersistentDB:GetString(compactBackgroundKey) == value
end

function settings.hidePredefinedDropdown()
    return PersistentDB:GetString(hidePredefinedDropdownKey) == "true"
end

function settings.setHidePredefinedDropdown(hidden)
    local value = hidden and "true" or "false"
    local result = PersistentDB:SetString(hidePredefinedDropdownKey, value)
    return result ~= false and PersistentDB:GetString(hidePredefinedDropdownKey) == value
end

return settings
