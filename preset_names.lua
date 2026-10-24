local names = {}
local textValidation = require("text_validation")
local prefix = "presetName.v1."
local cache = {}

function names.normalize(value)
    if type(value) ~= "string" then
        return nil, "Enter a name."
    end
    local clean = value:match("^%s*(.-)%s*$")
    if clean:find("[%c<>]") then
        return nil, "Names cannot contain control characters or < >."
    end
    local length = textValidation.length(clean)
    if not length or length > 40 then
        return nil, "Use at most 40 characters of valid text."
    end
    return clean
end

function names.get(slot)
    if cache[slot] == nil then
        local stored = PersistentDB:GetString(prefix .. slot)
        local clean = stored and names.normalize(stored)
        cache[slot] = clean or ""
    end
    return cache[slot] ~= "" and cache[slot] or nil
end

function names.save(slot, value)
    local clean, message = names.normalize(value)
    if not clean then
        return false, message
    end
    -- Store an empty string for reset, so a missing key is not a deletion error.
    local key = prefix .. slot
    local result = PersistentDB:SetString(key, clean)
    -- Verify the stored value directly, rather than trusting the setter alone.
    -- This also distinguishes a storage failure from a bank-label display issue.
    local stored = PersistentDB:GetString(key)
    if result == false or stored ~= clean then
        return false, "Storage verification failed. See the client console."
    end
    cache[slot] = clean
    return true, clean == "" and "Using the game's predefined name." or "Name saved."
end

return names
