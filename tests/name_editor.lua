-- Minimal API mock exercising the native dropdown's selection event contract.
local controls = {}
local function createMockControl(kind)
    local item = { kind = kind, entries = {}, hooks = {} }
    function item:SetPos(x, y, parentX, parentY, selfX, selfY)
        self.x, self.y = x, y
        self.parentX, self.parentY, self.selfX, self.selfY = parentX, parentY, selfX, selfY
    end
    function item:SetSize(width, height)
        self.width, self.height = width, height
    end
    function item:Setup() end
    function item:Subscribe(hook, reference, callback)
        self.hooks[hook] = callback or reference
    end
    function item:Add(label, entryID)
        self.entries[entryID] = label
    end
    function item:SetEntrySelected(entryID, selected, triggerEvents)
        assert(selected and not triggerEvents)
        self.selectedID = entryID
    end
    controls[#controls + 1] = item
    return item
end
ui = {
    Text = { new = function() return createMockControl("text") end },
    Button = { new = function() return createMockControl("button") end },
    InputField = { new = function() return createMockControl("input") end },
    List = { new = function() return createMockControl("list") end },
    Hook = { ONBUTTONPRESSED = 1, ONCONTENTCHANGED = 2, ONSELECTIONCHANGED = 3, ONRESIZE = 4 },
    SelectionChangeEvent = { SELECTED = 1, DESELECTED = 0 },
    TextContentVisibilityMode = { VISIBLE = 0 },
    InputFieldFilterMode = { NONE = 0 },
    InputFieldActionResult = { SUBMIT = 1 },
}
id = {
    Font = { MUSEO_SANS_15PT_REGULAR = 1, MUSEO_SANS_11PT_REGULAR = 2 },
    StyleSheet = { DROPDOWN_DEFAULT = 1, INPUT_DEFAULT = 2, BUTTON_DEFAULT = 3 },
}
local stored = { [18] = "Last preset" }
local context = "101"
local names = {
    getContext = function() return context end,
    get = function(slot) return stored[slot] end,
    save = function(slot, value)
        stored[slot] = value
        return true, "Name saved."
    end,
}

-- Layout stays inside the supplied parent without resizing either host layer.
local host = createMockControl("host")
host.type, host.width, host.height = 42, 600, 400
local parent = createMockControl("parent")
parent.parent, parent.width, parent.height = host, 580, 360
local refreshCharacter = dofile("name_editor.lua").build(parent, names, { presetCount = 18, labels = { {} } })
assert(parent.width == 580 and parent.height == 360)
assert(host.width == 600 and host.height == 400)
local content = controls[3] -- First label, positioned directly on the host layer.
assert(content.kind == "text")
assert(content.x == 130 and content.y == 61)
assert(content.parentX == nil and content.selfX == nil)
parent.width, parent.height = 640, 400
parent.hooks[ui.Hook.ONRESIZE]()
assert(content.x == 160 and content.y == 81)
parent.width, parent.height = 300, 200
parent.hooks[ui.Hook.ONRESIZE]()
assert(content.x == 8 and content.y == 8)
-- Find controls by purpose rather than relying on their creation order.
local selector, input, save, reset
for _, item in ipairs(controls) do
    if item.kind == "list" then
        selector = item
    elseif item.kind == "input" then
        input = item
    elseif item.label == "Save" then
        save = item
    elseif item.label == "Reset" then
        reset = item
    end
    assert(item.label ~= "<" and item.label ~= ">")
    if item.content == "Stored on this device, per character name." then
        assert(item.font == 2 and item.width == 320 and item.height == 18)
    end
end
assert(selector.entries[0] == "Preset 1" and selector.entries[17] == "Preset 18")
assert(selector.entries[18] == nil)
assert(selector.selectedID == 0 and input.content == "")
-- Selection IDs are zero-based; deselection must not change the edited slot.
selector.hooks[ui.Hook.ONSELECTIONCHANGED](selector, 17, ui.SelectionChangeEvent.SELECTED)
assert(input.content == "Last preset")
input.content = "Edited last preset"
selector.hooks[ui.Hook.ONSELECTIONCHANGED](selector, 0, ui.SelectionChangeEvent.DESELECTED)
assert(input.content == "Edited last preset")
save.hooks[ui.Hook.ONBUTTONPRESSED]()
assert(stored[18] == "Edited last preset" and stored[1] == nil)
reset.hooks[ui.Hook.ONBUTTONPRESSED]()
assert(stored[18] == "" and input.content == "")
selector.hooks[ui.Hook.ONSELECTIONCHANGED](selector, 0, ui.SelectionChangeEvent.SELECTED)
input.content = "First preset"
save.hooks[ui.Hook.ONBUTTONPRESSED]()
assert(stored[1] == "First preset")
-- A character switch discards stale edits instead of saving to the new context.
input.content = "Unsaved previous character"
context = "202"
stored = { [1] = "Other character" }
save.hooks[ui.Hook.ONBUTTONPRESSED]()
assert(stored[1] == "Other character" and input.content == "Other character")
context = "101"
stored = { [1] = "First preset" }
refreshCharacter()
assert(input.content == "First preset")
-- Reopening after choosing a different slot always starts at preset 1,
-- showing its saved name without overwriting any stored settings.
selector.hooks[ui.Hook.ONSELECTIONCHANGED](selector, 17, ui.SelectionChangeEvent.SELECTED)
local start = #controls
dofile("name_editor.lua").build(parent, names, { presetCount = 18, labels = { {} } })
local reopenedSelector, reopenedInput
for index = start + 1, #controls do
    local item = controls[index]
    if item.kind == "list" then
        reopenedSelector = item
    elseif item.kind == "input" then
        reopenedInput = item
    end
end
assert(reopenedSelector.selectedID == 0)
assert(reopenedInput.content == "First preset")
