local menu = {}
local customizePresetText = "Customize preset"

-- Match identity, not displayed names (which can be duplicated or localised).
local function slotForEntries(entries, bindings)
    if #bindings == 0 then return end
    local slot
    for _, entry in ipairs(entries) do
        local component = entry.componentData and entry.componentData.component
        if component and not component.isRestricted and component.visibleGlobal then
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
        for _, entry in ipairs(entries) do
            local component = entry.componentData and entry.componentData.component
            if component and not component.isRestricted
                and component.interfaceID == bindings[1].interfaceID then
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
    return slot
end

function menu.selectedSlot(entry, bindings)
    if not entry or entry.verbText ~= "Select" then return end
    local slot = slotForEntries({ entry }, bindings)
    if slot then return slot end
    -- Selection can arrive after the pointer has left the row.
    return require("bank/reorder").slotOf(
        entry.componentData and entry.componentData.component, #bindings)
end

function menu.add(miniMenu, bindings, openEditor)
    local slot = slotForEntries(miniMenu.entries, bindings)
    if not slot then return end

    -- Capture the old count too: some clients expose a pre-Add snapshot.
    local cancelIndex
    local count = #miniMenu.entries
    for index, entry in ipairs(miniMenu.entries) do
        if entry.actionType == MiniMenuActionType.CANCEL or entry.verbText == "Cancel" then
            cancelIndex = index
            break
        end
    end
    miniMenu:Add(customizePresetText, openEditor, slot)
    -- Read fresh entries rather than assuming Add inserted at index 1. Move
    -- only our action through the low-priority end, preserving native order.
    local entries = miniMenu.entries
    local editIndex, currentCancel, resetIndex
    for index, entry in ipairs(entries) do
        if entry.overrideText == customizePresetText or entry.verbText == customizePresetText
            or entry.label == customizePresetText then
            editIndex = index
        end
        if entry.actionType == MiniMenuActionType.CANCEL or entry.verbText == "Cancel" then
            currentCancel = index
        end
        if entry.verbText == "Reset" and entry.componentData
            and entry.componentData.component
            and entry.componentData.component.interfaceID == bindings[1].interfaceID then
            resetIndex = index
        end
    end
    if editIndex and (resetIndex or currentCancel) then
        local destination = resetIndex and (resetIndex - (editIndex < resetIndex and 1 or 0))
            or currentCancel + (editIndex > currentCancel and 1 or 0)
        -- Never promote a plugin action above the native left-click action.
        if destination < #entries then
            while editIndex < destination do
                miniMenu:Swap(editIndex, editIndex + 1)
                editIndex = editIndex + 1
            end
            while editIndex > destination do
                miniMenu:Swap(editIndex - 1, editIndex)
                editIndex = editIndex - 1
            end
        end
    elseif #entries == count and cancelIndex == 1 then
        -- Snapshot unchanged: native insertion puts our action below Cancel.
        miniMenu:Swap(1, 2)
    end
end

return menu
