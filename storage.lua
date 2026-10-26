local storage = {}

-- Let host errors propagate so callers retain their own error handling.
function storage.writeVerified(key, value)
    local result = PersistentDB:SetString(key, value)
    local stored = PersistentDB:GetString(key)
    return result ~= false and stored == value
end

return storage
