-- Match the RuneScape sandbox: the standard utf8 library is unavailable.
utf8 = nil
local validation = dofile("text_validation.lua")
assert(validation.length("") == 0)
assert(validation.length("test") == 4)
assert(validation.length("Équipement") == 10)
assert(validation.length("\240\159\152\128") == 1)
for _, invalid in ipairs({ "\128", "\192\128", "\226\130", "\237\160\128",
    "\244\144\128\128", "\245\128\128\128" }) do
    assert(validation.length(invalid) == nil)
end
local data = {}
local displayName = "First Character"
local entityValid = true
local entityMissing = false
local available = true
Player = {
    IsAvailable = function() return available end,
    GetEntity = function()
        if entityMissing then return nil end
        return { isValid = entityValid, displayName = displayName }
    end,
}
PersistentDB = {
    GetString = function(_, key) return data[key] end,
    SetString = function(_, key, value) data[key] = value; return true end,
}
local names = dofile("preset_names.lua")
assert(names.get(1) == nil)
assert(names.save(1, "  Bossing  "))
assert(names.get(1) == "Bossing")
assert(not names.save(1, "<col=ff0000>Bad"))
assert(not names.save(1, string.rep("x", 41)))
assert(not names.save(1, "line\nbreak"))
assert(names.save(4, string.rep("é", 40)))
assert(not names.save(4, string.rep("é", 41)))
assert(not names.save(4, "\237\160\128"))
assert(names.save(2, "Équipement"))
assert(dofile("preset_names.lua").get(2) == "Équipement")
local realSet = PersistentDB.SetString
PersistentDB.SetString = function() return true end
assert(not names.save(2, "Not actually stored"))
assert(names.get(2) == "Équipement")
PersistentDB.SetString = function(_, key, value)
    data[key] = value -- Some host bindings may omit a success return.
end
assert(names.save(3, "Verified by read-back"))
assert(dofile("preset_names.lua").get(3) == "Verified by read-back")
PersistentDB.SetString = realSet

-- Character isolation, reload persistence, logout, and unavailable names/entities.
data["presetName.v1.1"] = "Legacy shared name"
displayName = "Second Character"
assert(names.get(1) == nil)
assert(names.save(1, "Second character"))
assert(dofile("preset_names.lua").get(1) == "Second character")
displayName = "  FIRST CHARACTER  "
assert(names.get(1) == "Bossing")
available = false
assert(names.get(1) == nil)
assert(not names.save(1, "Logged out"))
available = true
displayName = nil
assert(names.get(1) == nil)
assert(not names.save(1, "No name"))
displayName = ""
assert(names.get(1) == nil)
assert(not names.save(1, "Empty name"))
displayName = "First Character"
entityValid = false
assert(names.get(1) == nil)
assert(not names.save(1, "Invalid entity"))
entityValid = true
entityMissing = true
assert(names.get(1) == nil)
assert(not names.save(1, "Missing entity"))
entityMissing = false
displayName = "Renamed Character"
assert(names.get(1) == nil)
displayName = "Second Character"
assert(names.get(1) == "Second character")
assert(names.save(1, ""))
assert(names.get(1) == nil)
displayName = "First Character"
assert(names.get(1) == "Bossing")
assert(data["presetName.v1.1"] == "Legacy shared name")

local label = { type = 1, content = "Combat" }
ui = {
    ComponentType = { LABEL = 1 },
    Interfaces = { GetComponent = function() return label end },
}
local bank = dofile("bank_labels.lua")
local bindings = { { slot = 1, interfaceID = 1, staticID = 2 } }
bank.update(bindings, names)
assert(label.content == "Bossing")
bank.update(bindings, names)
assert(names.save(1, ""))
bank.update(bindings, names)
assert(label.content == "Combat")
assert(names.save(1, "Skilling"))
bank.update(bindings, names)
label.content = "New predefined"
bank.update(bindings, names)
assert(label.content == "Skilling")
bank.restore(bindings)
assert(label.content == "New predefined")
bank.update(bindings, names)
label = nil
bank.update(bindings, names)
label = { type = 1, content = "Reopened" }
bank.update(bindings, names)
assert(label.content == "Skilling")
bank.restore(bindings)
assert(label.content == "Reopened")
label = { type = 99, content = "Not a label" }
bank.update(bindings, names)
assert(label.content == "Not a label")
-- All preset slots resolve independently and restore their own predefined text.
local allBindings = dofile("bank_bindings.lua")
assert(#allBindings.labels == 18)
assert(allBindings.labels[6].dynamicID == 16)
assert(allBindings.labels[7].dynamicID == 19)
assert(allBindings.labels[8].dynamicID == 22)
assert(allBindings.labels[9].dynamicID == 25)
local allLabels = {}
for slot, binding in ipairs(allBindings.labels) do
    assert(binding.slot == slot)
    allLabels[binding.dynamicID] = { type = 1, content = "Predefined " .. slot }
    assert(names.save(slot, "Custom " .. slot))
end
ui.Interfaces.GetComponent = function(_, interfaceID, staticID, categoryID, dynamicID)
    assert(interfaceID == 517 and staticID == 266 and categoryID == 0)
    return allLabels[dynamicID]
end
bank.update(allBindings.labels, names)
for slot, binding in ipairs(allBindings.labels) do
    assert(allLabels[binding.dynamicID].content == "Custom " .. slot)
end
assert(names.save(18, ""))
bank.update(allBindings.labels, names)
assert(allLabels[52].content == "Predefined 18")
assert(allLabels[49].content == "Custom 17")
bank.restore(allBindings.labels)
for slot, binding in ipairs(allBindings.labels) do
    assert(allLabels[binding.dynamicID].content == "Predefined " .. slot)
end

dofile("tests/name_editor.lua")
print("All preset name and editor regression tests passed.")
