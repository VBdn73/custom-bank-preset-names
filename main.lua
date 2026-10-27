-- Retain the dependency export for editor instances created by later events.
local prettyUILibrary = prettyui
local bankBindings = require("bank/bindings")
local presetNames = require("presets/names")
local bankLabels = require("bank/labels")
local nameEditor = require("editor/view")
local presetMenu = require("bank/menu")
local editorPopup = require("editor/popup")
local bankAppearance = require("bank/appearance")
local presetColours = require("presets/colours")
local bankReorder = require("bank/reorder")
local bankDropdown = require("bank/dropdown")
local settings = require("presets/settings")
local preferences = require("editor/preferences")
bankBindings.colours = presetColours

-- Each open editor supplies a callback that follows character changes.
local editorRefreshCallbacks = {}
local destroyContentView
local destroySettingsView

Event.MiniMenuReady.Subscribe("presetNames.menu", function(event)
    presetMenu.add(event.miniMenu, bankBindings.labels, function(slot)
        editorPopup.open(slot, presetNames, bankBindings, prettyUILibrary)
    end)
end)

Event.MiniMenuEntrySelected.Subscribe("presetNames.selection", function(event)
    editorPopup.select(presetMenu.selectedSlot(event.entry, bankBindings.labels))
end)

Event.SettingsLayerReady.Subscribe("presetNames.settings", function(event)
    if destroySettingsView then pcall(destroySettingsView) end
    local refresh, _, destroy = nameEditor.build(event.component, presetNames, bankBindings,
        nil, { hideTitle = true, settings = settings, prettyui = prettyUILibrary })
    editorRefreshCallbacks.settings, destroySettingsView = refresh, destroy
end)

Event.ContentLayerReady.Subscribe("presetNames.content", function(event)
    if destroyContentView then pcall(destroyContentView) end
    editorRefreshCallbacks.content, destroyContentView = nil, nil
    local ok, refresh, _, destroy = pcall(preferences.build, event.component, settings, prettyUILibrary)
    if ok then
        editorRefreshCallbacks.content, destroyContentView = refresh, destroy
    else
        print("[Preset names] Ribbon settings error: " .. tostring(refresh))
        for index, text in ipairs({ "Could not open settings.",
            "See the client console for the error." }) do
            local message = ui.Text.new(event.component)
            message:SetPos(8, 8 + (index - 1) * 24)
            message:SetSize(math.max(1, event.component.width - 16), 24)
            message.font = id.Font.MUSEO_SANS_11PT_REGULAR
            message.content = text
        end
    end
end)

-- Reacquire components each tick: bank interfaces can close or rebuild at any time.
Event.Logic.Subscribe("presetNames.labels", function()
    bankReorder.update(bankBindings)
    bankDropdown.update(settings.hidePredefinedDropdown())
    editorPopup.update()
    for layer, refresh in pairs(editorRefreshCallbacks) do
        -- A closed host may already have disposed its controls.
        if not pcall(refresh) then
            editorRefreshCallbacks[layer] = nil
            if layer == "settings" and destroySettingsView then
                pcall(destroySettingsView)
                destroySettingsView = nil
            elseif layer == "content" and destroyContentView then
                pcall(destroyContentView)
                destroyContentView = nil
            end
        end
    end
    bankLabels.update(bankBindings.labels, presetNames)
end)

-- Bank scripts can reset label text after Logic (for example on selection).
-- Apply again at the render boundary so the predefined text is not drawn for
-- one frame before the next logic tick restores the custom name.
Event.Draw.Subscribe("presetNames.labels", function()
    bankDropdown.update(settings.hidePredefinedDropdown())
    bankAppearance.update(bankBindings.appearance, presetColours)
    bankLabels.update(bankBindings.labels, presetNames)
end)

function PluginShutdown()
    bankDropdown.restore()
    bankReorder.clear()
    if destroyContentView then pcall(destroyContentView) end
    destroyContentView = nil
    if destroySettingsView then pcall(destroySettingsView) end
    destroySettingsView = nil
    bankAppearance.restore(bankBindings.appearance)
    Event.MiniMenuReady.Unsubscribe("presetNames.menu")
    Event.MiniMenuEntrySelected.Unsubscribe("presetNames.selection")
    editorPopup.close()
    Event.Logic.Unsubscribe("presetNames.labels")
    Event.Draw.Unsubscribe("presetNames.labels")
    Event.SettingsLayerReady.Unsubscribe("presetNames.settings")
    Event.ContentLayerReady.Unsubscribe("presetNames.content")
    bankLabels.restore(bankBindings.labels)
end
