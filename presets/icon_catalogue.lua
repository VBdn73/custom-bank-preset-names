-- Add a category module here to expose another tab; picker and storage need no changes.
local catalogue = { categories = {
    (require("presets/icon_categories/skills")),
} }
local byKey, categoryKeys = {}, {}
for _, category in ipairs(catalogue.categories) do
    assert(not categoryKeys[category.key], "Duplicate icon category: " .. category.key)
    categoryKeys[category.key] = true
    for _, entry in ipairs(category.entries) do
        assert(not byKey[entry.key], "Duplicate icon key: " .. entry.key)
        assert(entry.category == category.key, "Icon category mismatch: " .. entry.key)
        byKey[entry.key] = entry
    end
end

-- Metadata lookup is independent of the client API and resource availability.
-- An empty key means the native number; unknown keys have the same fallback.
function catalogue.get(key)
    if type(key) ~= "string" then return nil end
    return byKey[key]
end

-- Resolve at use time, not module load: IDs may change between client versions.
-- nil means retain the number. Renderers must still handle sprite setup failure.
-- Optional sprites argument allows API-free tests and other catalogue consumers.
function catalogue.resolve(key, sprites)
    local entry = catalogue.get(key)
    if not entry then return nil end
    sprites = sprites or (id and id.Sprite)
    if not sprites then return nil end
    local spriteID = sprites[entry.sprite]
    if type(spriteID) ~= "number" or spriteID < 0 or spriteID % 1 ~= 0 then return nil end
    return spriteID, entry
end

return catalogue
