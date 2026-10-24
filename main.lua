local bankBindings = require("bank_bindings")
local presetNames = require("preset_names")
local bankLabels = require("bank_labels")
local nameEditor = require("name_editor")

-- Each open editor supplies a callback that follows character changes.
local editorRefreshCallbacks = {}

Event.SettingsLayerReady.Subscribe("presetNames.settings", function(event)
    editorRefreshCallbacks.settings = nameEditor.build(event.component, presetNames, bankBindings)
end)

Event.ContentLayerReady.Subscribe("presetNames.content", function(event)
    editorRefreshCallbacks.content = nameEditor.build(event.component, presetNames, bankBindings)
end)

-- Reacquire components each tick: bank interfaces can close or rebuild at any time.
Event.Logic.Subscribe("presetNames.labels", function()
    for layer, refresh in pairs(editorRefreshCallbacks) do
        -- A closed host may already have disposed its controls.
        if not pcall(refresh) then
            editorRefreshCallbacks[layer] = nil
        end
    end
    bankLabels.update(bankBindings.labels, presetNames)
end)

function PluginShutdown()
    Event.Logic.Unsubscribe("presetNames.labels")
    Event.SettingsLayerReady.Unsubscribe("presetNames.settings")
    Event.ContentLayerReady.Unsubscribe("presetNames.content")
    bankLabels.restore(bankBindings.labels)
end
