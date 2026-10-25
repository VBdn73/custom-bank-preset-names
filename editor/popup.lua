local nameEditor = require("editor/view")
local constants = require("constants")
local layout = require("editor/layout")
local icons = require("editor/icon")
local popup = {}
local window, refresh, bankIsOpen, updateInfo, infoButton

function popup.close()
    local previous = window
    local previousInfo = infoButton
    window, refresh, bankIsOpen, updateInfo = nil, nil, nil, nil
    infoButton = nil
    if previousInfo then
        if previous then previous:_UnregisterOverlay(previousInfo) end
        pcall(function() previousInfo:Destroy() end)
    end
    -- The bank may already have disposed the window's interface.
    if previous then pcall(function() previous:Destroy() end) end
end

function popup.open(slot, names, bindings, prettyui)
    local binding = bindings.labels[slot]
    if not binding then return end
    local source = ui.Interfaces:GetComponent(binding.interfaceID, binding.staticID,
        binding.categoryID, binding.dynamicID)
    if not source or source.isRestricted or not source.visibleGlobal then return end
    -- The bank itself is a constrained popover. Keep the window in the outer UI.
    local parent = source.parent
    while parent and parent.parent and not parent.parent.isRestricted do
        parent = parent.parent
    end
    if not parent or parent.isRestricted then return end
    assert(prettyui and prettyui.Window, "PrettyUI Window is required for the bank editor.")

    popup.close()
    bankIsOpen = function()
        local current = ui.Interfaces:GetComponent(binding.interfaceID, binding.staticID,
            binding.categoryID, binding.dynamicID)
        return current == source and not current.isRestricted and current.visibleGlobal
    end
    local bodyHeight = layout.compactBodyHeight + (bindings.colours and layout.colourHeight or 0)
    -- PrettyUI chrome uses a 32px title and 8px bottom/side borders.
    local width, height = layout.width + 16, bodyHeight + 32 + 8
    local ok, message = pcall(function()
        window = prettyui.Window.new(parent, {
            title = constants.editorTitle, width = width, height = height,
            x = math.max(0, math.floor((parent.width - width) / 2)),
            y = math.max(0, math.floor((parent.height - height) / 2)),
            scrollable = false, onClose = popup.close,
        })
        local toggleInfo
        refresh, toggleInfo = nameEditor.build(window.content, names, bindings, slot, {
            hideTitle = true, externalInfoButton = true, infoParent = window.root,
            contentHost = window, formHeight = bodyHeight,
        })
        -- The drag handle is a sibling above the window, so the header icon
        -- must also be an overlay rather than a child underneath that handle.
        infoButton, updateInfo = icons.new(parent, id.Sprite.RS3_BUTTON_INFO_PARENT_0,
            id.Sprite.RS3_BUTTON_INFO_PARENT_1, id.Sprite.RS3_BUTTON_INFO_PARENT_2, toggleInfo)
        window.titleText:SetSize(-80, 28, 1, 0)
        window:_RegisterOverlay(infoButton, nil, function()
            infoButton:SetPos(window.root.x + window.root.width - 28 - 4 - layout.popupCloseSize,
                window.root.y + 6)
        end)
        window:_SyncOverlays(false)
    end)
    if not ok then
        popup.close()
        print("[Preset names] Bank editor error: " .. tostring(message))
    end
end

function popup.update()
    if not window then return end
    local ok = pcall(function()
        if not bankIsOpen() then popup.close(); return end
        window:_SyncOverlays(window.root.hidden == true)
        updateInfo()
        refresh()
    end)
    if not ok then popup.close() end
end

return popup
