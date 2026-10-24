local menu = {}

-- Match identity, not displayed names (which can be duplicated or localised).
function menu.add(miniMenu, bindings, openEditor)
    if #bindings == 0 then return end
    local slot
    for _, entry in ipairs(miniMenu.entries) do
        local component = entry.componentData and entry.componentData.component
        if component and not component.isRestricted then
            for _, binding in ipairs(bindings) do
                if component.interfaceID == binding.interfaceID
                    and component.staticID == binding.staticID
                    and component.categoryID == binding.categoryID
                    and component.dynamicID == binding.dynamicID then
                    slot = binding.slot
                    break
                end
            end
        end
        if slot then break end
    end
    if not slot then
        -- The bank's native actions can originate from the row's hit target,
        -- not the text label. Resolve the hovered label instead of assuming
        -- the action component shares its dynamic ID.
        local bankAction = false
        for _, entry in ipairs(miniMenu.entries) do
            local component = entry.componentData and entry.componentData.component
            if component and component.interfaceID == bindings[1].interfaceID then
                bankAction = true
                break
            end
        end
        if bankAction then
            for _, binding in ipairs(bindings) do
                local label = ui.Interfaces:GetComponent(binding.interfaceID, binding.staticID,
                    binding.categoryID, binding.dynamicID)
                if label and not label.isRestricted and label.visibleGlobal and label.isMouseOver then
                    slot = binding.slot
                    break
                end
            end
        end
    end
    if not slot then return end

    -- Capture Cancel's index BEFORE adding: the exposed entries/count need
    -- not refresh after Add. Plugin actions are inserted at the low-priority
    -- end (index 1), shifting the existing entries up by one.
    local cancelIndex
    for index, entry in ipairs(miniMenu.entries) do
        if entry.actionType == MiniMenuActionType.CANCEL then
            cancelIndex = index
            break
        end
    end
    miniMenu:Add("Edit name", openEditor, slot)
    -- In the API's reversed display order, index 2 is directly above Cancel
    -- when Cancel was originally index 1. Swap only these bottom two entries;
    -- never rotate through Select/Load/Reset or change their priority.
    if cancelIndex == 1 then
        miniMenu:Swap(1, 2)
    end
end

return menu
