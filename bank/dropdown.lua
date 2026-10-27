local bankIds = require("bank/ids")
local dropdown = {}
local presetLayout = require("bank/preset_layout")
local state

local function resolve()
    -- BANK__PRESET_DROPDOWN; hide the parent, including its build/click children.
    return ui.Interfaces:GetComponent(bankIds.interface, bankIds.predefinedNameDropdown)
end

function dropdown.restore()
    presetLayout.restore()
    local component = resolve()
    if state and component == state.component and not component.isRestricted
        and component.hidden == true then
        component.hidden = state.original
    end
    state = nil
end

function dropdown.update(hidden)
    if not hidden then
        dropdown.restore()
        return
    end
    local component = resolve()
    presetLayout.update(true, component)
    if not component or component.isRestricted then
        state = nil
        return
    end
    if not state or state.component ~= component then
        state = { component = component, original = component.hidden }
    elseif component.hidden ~= true then
        state.original = component.hidden
    end
    component.hidden = true
end

return dropdown
