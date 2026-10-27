local test = require("tests.test_helper")
local preferences = require("editor/preferences")

test.case("Preferences show only the dropdown option and bank-only editing guidance", function()
    local previousUI, previousID = ui, id
    local note = { SetPos = function(self, x, y) self.x, self.y = x, y end,
        SetSize = function() end }
    ui = { Hook = { ONRESIZE = "resize" }, AlignMode = { TOPLEFT = "topLeft" },
        Text = { new = function() return note end } }
    id = { Font = { MUSEO_SANS_11PT_REGULAR = 11 } }
    local ok, message = pcall(function()
        local hidden, canSave = false, true
        local parent = { width = 270, Subscribe = function(self, _, _, callback)
            self.resize = callback
        end }
        local root = { height = 28, SetPos = function(self, x, y) self.x, self.y = x, y end,
            SetSize = function(self, width, height) self.width, self.height = width, height end }
        local change, selected, count
        local refresh = preferences.build(parent, {
            hidePredefinedDropdown = function() return hidden end,
            setHidePredefinedDropdown = function(value)
                if not canSave then return false end
                hidden = value
                return true
            end,
        }, { CheckboxButton = { new = function(_, entries, options)
            count = #entries
            test.equal(entries[1].selected, false)
            change = options.onChange
            return { root = root, items = { { label = {
                SetSize = function() end,
            }, box = { SetPos = function() end },
                row = { SetSize = function() end } } }, SetSelected = function(_, key, value, notify)
                test.equal(key, "hideDropdown")
                test.equal(notify, false)
                selected = value
            end }
        end } })
        test.equal(count, 1)
        test.equal(note.content, "Presets can only be customised in the bank UI: right-click a preset and choose Customize preset.")
        test.equal(note.font, 11)
        test.equal(root.width, 254)
        test.equal(root.height, 36)
        test.equal(note.y, 52, "Wrapped checkbox has a small gap before guidance")
        change(nil, nil, nil, true)
        test.equal(hidden, true)
        refresh()
        test.equal(selected, true)
        hidden = false
        refresh()
        test.equal(selected, false, "Changes from main settings are reflected")
        parent.width = 200
        parent.resize()
        test.equal(root.width, 184)
        test.equal(root.height, 54)
        parent.width = 700
        parent.resize()
        test.equal(root.height, 20)
        test.equal(note.y, 36, "Wide settings do not reserve unused checkbox lines")
        canSave = false
        change(nil, nil, nil, true)
        test.equal(selected, false, "Failed saves restore the stored preference")
    end)
    ui = previousUI
    id = previousID
    assert(ok, message)
end)
