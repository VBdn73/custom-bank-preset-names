local bindings = require("bank_bindings")
local names = require("preset_names")
local bank = require("bank_labels")
local editor = require("name_editor")

Event.SettingsLayerReady.Subscribe("presetNames.settings", function(event)
    editor.build(event.component, names, bindings)
end)

Event.ContentLayerReady.Subscribe("presetNames.content", function(event)
    editor.build(event.component, names, bindings)
end)

-- Reacquire components each tick: bank interfaces can close or rebuild at any time.
Event.Logic.Subscribe("presetNames.labels", function()
    bank.update(bindings.labels, names)
end)

function PluginShutdown()
    Event.Logic.Unsubscribe("presetNames.labels")
    Event.SettingsLayerReady.Unsubscribe("presetNames.settings")
    Event.ContentLayerReady.Unsubscribe("presetNames.content")
    bank.restore(bindings.labels)
end

if #bindings.labels == 0 then
    print("Custom bank preset names: bank label bindings are missing. See README.md.")
end
