local bankIds = require("bank/ids")
local swap = require("presets/swap")
local names = require("presets/names")
local bankLabels = require("bank/labels")
local reorder = {}
local watched = {}
local hookID = "presetNames.reorder"

local function componentKey(component)
    return ("%s:%s:%s:%s"):format(tostring(component.interfaceID), tostring(component.staticID),
        tostring(component.categoryID), tostring(component.dynamicID))
end

local function slotOf(component, count)
    if not component or component.isRestricted or not component.visibleGlobal
        or component.interfaceID ~= bankIds.interface or component.categoryID ~= bankIds.category then return nil end
    local slot
    if component.staticID == bankIds.presetBackground then
        slot = component.dynamicID
    elseif component.staticID == bankIds.presetLabel then
        slot = math.floor(component.dynamicID / bankIds.labelsPerPreset) + 1
    elseif component.staticID == bankIds.presetHitTarget then
        -- Hit-target IDs are not assumed to use the background's numbering.
        -- Resolve their row by its on-screen position against the known labels.
        local position = component.xyGlobal
        if position and component.height then
            local centre = position.y + component.height / 2
            for candidate = 1, count do
                local label = ui.Interfaces:GetComponent(bankIds.interface, bankIds.presetLabel,
                    bankIds.category, (candidate - 1) * bankIds.labelsPerPreset + bankIds.nameLabelOffset)
                if label and not label.isRestricted and label.visibleGlobal and label.xyGlobal
                    and centre >= label.xyGlobal.y and centre < label.xyGlobal.y + label.height then
                    return candidate
                end
            end
        end
    end
    if slot and slot >= 1 and slot <= count then return slot end
end

-- Shared by native menu selection so hit targets resolve identically.
reorder.slotOf = slotOf

function reorder.clear()
    for _, component in pairs(watched) do
        pcall(function() component:Unsubscribe(ui.Hook.ONDRAGCOMPLETE, hookID) end)
    end
    watched = {}
end

function reorder.update(bindings)
    local active = {}
    local context = names.getContext()
    local function watch(component)
        if component and not component.isRestricted and component.visibleGlobal
            and component.interfaceID == bankIds.interface then
            -- Client lookups can return fresh Lua wrappers for the same native
            -- component. Table keys use wrapper identity, not native identity.
            local key = componentKey(component)
            if active[key] then return end
            active[key] = true
            if context then
                -- Replacing our named listener also handles rebuilt native rows.
                -- Do not unsubscribe an old wrapper after this registration:
                -- it may refer to this exact same native component.
                component:Subscribe(ui.Hook.ONDRAGCOMPLETE, hookID, function(source, destination)
                    local first = slotOf(source, bindings.presetCount)
                    local second = slotOf(destination, bindings.presetCount)
                    if names.getContext() == context and first and second and first ~= second then
                        local ok, message = swap.apply(first, second)
                        if ok then
                            bankLabels.swapOriginals(bindings.labels, first, second)
                            bankLabels.update(bindings.labels, names)
                        else
                            print("[Preset names] Could not swap customisations: " .. tostring(message))
                        end
                    end
                    return true -- Preserve the native preset swap.
                end)
                watched[key] = component
            end
            -- A row's containing layer can own the drag instead of its visual children.
            watch(component.parent)
        end
    end
    for slot = 1, bindings.presetCount do
        watch(ui.Interfaces:GetComponent(bankIds.interface, bankIds.presetBackground, bankIds.category, slot))
        for offset = bankIds.numberLabelOffset, bankIds.labelsPerPreset - 1 do
            watch(ui.Interfaces:GetComponent(bankIds.interface, bankIds.presetLabel,
                bankIds.category, (slot - 1) * bankIds.labelsPerPreset + offset))
        end
    end
    for dynamicID = 0, bindings.presetCount do
        watch(ui.Interfaces:GetComponent(bankIds.interface, bankIds.presetHitTarget, bankIds.category, dynamicID))
    end
    for key, component in pairs(watched) do
        if not active[key] or not context then
            pcall(function() component:Unsubscribe(ui.Hook.ONDRAGCOMPLETE, hookID) end)
            watched[key] = nil
        end
    end
end

return reorder
