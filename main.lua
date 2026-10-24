local bankBindings = require("bank/bindings")
local presetNames = require("presets/names")
local bankLabels = require("bank/labels")
local nameEditor = require("editor/view")
local presetMenu = require("bank/menu")
local editorPopup = require("editor/popup")

-- Each open editor supplies a callback that follows character changes.
local editorRefreshCallbacks = {}

Event.MiniMenuReady.Subscribe("presetNames.menu", function(event)
    presetMenu.add(event.miniMenu, bankBindings.labels, function(slot)
        editorPopup.open(slot, presetNames, bankBindings)
    end)
end)

Event.SettingsLayerReady.Subscribe("presetNames.settings", function(event)
    editorRefreshCallbacks.settings = nameEditor.build(event.component, presetNames, bankBindings,
        nil, { hideTitle = true })
end)

Event.ContentLayerReady.Subscribe("presetNames.content", function(event)
    editorRefreshCallbacks.content = nameEditor.build(event.component, presetNames, bankBindings)
end)

-- Reacquire components each tick: bank interfaces can close or rebuild at any time.
Event.Logic.Subscribe("presetNames.labels", function()
    editorPopup.update()
    for layer, refresh in pairs(editorRefreshCallbacks) do
        -- A closed host may already have disposed its controls.
        if not pcall(refresh) then
            editorRefreshCallbacks[layer] = nil
        end
    end
    bankLabels.update(bankBindings.labels, presetNames)
end)

-- Bank scripts can reset label text after Logic (for example on selection).
-- Apply again at the render boundary so the predefined text is not drawn for
-- one frame before the next logic tick restores the custom name.
Event.Draw.Subscribe("presetNames.labels", function()
    bankLabels.update(bankBindings.labels, presetNames)
end)

function PluginShutdown()
    Event.MiniMenuReady.Unsubscribe("presetNames.menu")
    editorPopup.close()
    Event.Logic.Unsubscribe("presetNames.labels")
    Event.Draw.Unsubscribe("presetNames.labels")
    Event.SettingsLayerReady.Unsubscribe("presetNames.settings")
    Event.ContentLayerReady.Unsubscribe("presetNames.content")
    bankLabels.restore(bankBindings.labels)
end
