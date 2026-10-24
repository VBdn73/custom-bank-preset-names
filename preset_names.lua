local names = {}
local textValidation = require("text_validation")
local constants = require("constants")
local storageKeyPrefix = "presetName.v3.displayName."
-- nil means not loaded; an empty string means no custom name for this slot.
local cachedNames = {}
local currentContext

local function getCharacterContext()
    if Player.IsAvailable() then
        local player = Player.GetEntity()
        if player and player.isValid then
            local displayName = player.displayName
            if type(displayName) == "string" then
                displayName = displayName:match("^%s*(.-)%s*$"):lower()
                if displayName ~= "" then
                    return displayName
                end
            end
        end
    end
    return nil
end

local function storageKey(context, slot)
    return storageKeyPrefix .. context .. "." .. slot
end

function names.getContext()
    local context = getCharacterContext()
    -- Never reuse another character's cached names, including after logout.
    if context ~= currentContext then
        cachedNames = {}
        currentContext = context
    end
    return context
end

function names.normalize(value)
    if type(value) ~= "string" then
        return nil, "Enter a name."
    end
    local trimmedName = value:match("^%s*(.-)%s*$")
    if trimmedName:find("[%c<>]") then
        return nil, "Names cannot contain control characters or < >."
    end
    local characterCount = textValidation.length(trimmedName)
    if not characterCount or characterCount > constants.maximumNameLength then
        return nil, ("Use at most %d characters of valid text."):format(constants.maximumNameLength)
    end
    return trimmedName
end

function names.get(slot)
    local context = names.getContext()
    if not context then
        return nil
    end
    if cachedNames[slot] == nil then
        local storedName = PersistentDB:GetString(storageKey(context, slot))
        local validName = storedName and names.normalize(storedName)
        cachedNames[slot] = validName or ""
    end
    if cachedNames[slot] == "" then
        return nil
    end
    return cachedNames[slot]
end

function names.save(slot, value)
    local context = names.getContext()
    if not context then
        return false, "Log in and wait for your character name before saving."
    end
    local normalizedName, message = names.normalize(value)
    if not normalizedName then
        return false, message
    end
    -- Store an empty string for reset, so a missing key is not a deletion error.
    local key = storageKey(context, slot)
    local writeResult = PersistentDB:SetString(key, normalizedName)
    -- Verify the stored value directly, rather than trusting the setter alone.
    -- This also distinguishes a storage failure from a bank-label display issue.
    local storedName = PersistentDB:GetString(key)
    if writeResult == false or storedName ~= normalizedName then
        return false, "Storage verification failed. See the client console."
    end
    cachedNames[slot] = normalizedName
    if normalizedName == "" then
        return true, "Using the game's predefined name."
    end
    return true, "Name saved."
end

return names
