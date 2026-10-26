local bankLabels = {}
-- Keyed by binding index, with both the game's text and our last replacement.
local labelStates = {}

local function resolveComponent(binding)
    if binding.categoryID ~= nil and binding.dynamicID ~= nil then
        return ui.Interfaces:GetComponent(
            binding.interfaceID, binding.staticID, binding.categoryID, binding.dynamicID
        )
    end
    return ui.Interfaces:GetComponent(binding.interfaceID, binding.staticID)
end

local function isEditableLabel(component)
    return component and component.type == ui.ComponentType.LABEL and not component.isRestricted
end

-- The predefined name belongs to the preset too. Move the cached fallback
-- before a newly uncustomised slot is painted, rather than showing the old
-- slot's predefined name until the game's next label rebuild.
function bankLabels.swapOriginals(bindings, first, second)
    local firstState, secondState
    for index, binding in ipairs(bindings) do
        local state = labelStates[index]
        if state and resolveComponent(binding) == state.component then
            if binding.slot == first then firstState = state end
            if binding.slot == second then secondState = state end
        end
    end
    if firstState and secondState then
        firstState.originalText, secondState.originalText = secondState.originalText, firstState.originalText
    end
end

function bankLabels.update(bindings, names)
    for index, binding in ipairs(bindings) do
        local component = resolveComponent(binding)
        if isEditableLabel(component) then
            local state = labelStates[index]
            if not state or state.component ~= component then
                state = { component = component, originalText = component.content }
                labelStates[index] = state
            elseif component.content ~= state.appliedText then
                -- Preserve new predefined names supplied by the game while overridden.
                state.originalText = component.content
            end
            local desiredText = names.get(binding.slot) or state.originalText
            if component.content ~= desiredText then
                component.content = desiredText
            end
            state.appliedText = desiredText
        else
            labelStates[index] = nil
        end
    end
end

function bankLabels.visual(bindings, slot)
    for _, binding in ipairs(bindings or {}) do
        if binding.slot == slot then
            local component = resolveComponent(binding)
            if isEditableLabel(component) then
                return { font = component.font, shadowRGBA = component.shadowRGBA,
                    isShadowed = component.isShadowed }
            end
        end
    end
end

function bankLabels.original(bindings, slot)
    for index, binding in ipairs(bindings or {}) do
        if binding.slot == slot then
            local state = labelStates[index]
            local component = resolveComponent(binding)
            if isEditableLabel(component) then
                if state and state.component == component then return state.originalText end
                return component.content
            end
        end
    end
end

function bankLabels.restore(bindings)
    for index, binding in ipairs(bindings) do
        local state = labelStates[index]
        local component = resolveComponent(binding)
        -- Only undo our own latest write, never a newer change from the game.
        if state and isEditableLabel(component) and component == state.component
            and component.content == state.appliedText then
            component.content = state.originalText
        end
    end
    labelStates = {}
end

return bankLabels
