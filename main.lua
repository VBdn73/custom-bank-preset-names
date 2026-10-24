local bindings = require("bank_bindings")
local names = require("preset_names")
local bank = require("bank_labels")
local editor = require("name_editor")
local refreshEditors = {}

Event.SettingsLayerReady.Subscribe("presetNames.settings", function(event)
    refreshEditors.settings = editor.build(event.component, names, bindings)
end)

Event.ContentLayerReady.Subscribe("presetNames.content", function(event)
    refreshEditors.content = editor.build(event.component, names, bindings)
end)

-- Reacquire components each tick: bank interfaces can close or rebuild at any time.
Event.Logic.Subscribe("presetNames.labels", function()
    for layer, refresh in pairs(refreshEditors) do
        -- A closed host may already have disposed its controls.
        if not pcall(refresh) then refreshEditors[layer] = nil end
    end
    bank.update(bindings.labels, names)
end)

function PluginShutdown()
    Event.Logic.Unsubscribe("presetNames.labels")
    Event.SettingsLayerReady.Unsubscribe("presetNames.settings")
    Event.ContentLayerReady.Unsubscribe("presetNames.content")
    bank.restore(bindings.labels)
end
