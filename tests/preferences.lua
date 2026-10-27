local test = require("tests.test_helper")
local preferences = require("editor/preferences")

test.case("Ribbon shows only the dropdown preference and keeps it synchronized", function()
    local previousUI, previousID = ui, id
    local note = { SetPos = function() end, SetSize = function() end }
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
        test.equal(note.content, "To customise presets, right-click a preset in the bank and choose Customize preset.")
        test.equal(note.font, 11)
        test.equal(root.width, 254)
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
        canSave = false
        change(nil, nil, nil, true)
        test.equal(selected, false, "Failed saves restore the stored preference")
    end)
    ui = previousUI
    id = previousID
    assert(ok, message)
end)
