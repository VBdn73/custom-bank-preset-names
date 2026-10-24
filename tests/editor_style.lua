local test = require("tests.test_helper")

test.case("Editor layout derives control and popup sizes from shared dimensions", function()
    local layout = dofile("editor/layout.lua")
    test.equal(layout.controlWidth + layout.padding * 2, layout.width)
    test.equal(layout.buttonWidth * 2 + layout.buttonGap, layout.controlWidth)
    test.equal(layout.resetX + layout.buttonWidth, layout.width - layout.padding)
    test.equal(layout.bodyHeight + layout.titleHeight, layout.height)
    test.equal(layout.popupWidth, layout.width + layout.popupPadding * 2)
    test.equal(layout.popupHeight,
        layout.popupHeaderHeight + layout.bodyHeight + layout.popupBottomPadding)
end)

test.case("Editor theme loads without the client API and creates colours on demand", function()
    local previous = Vector4
    Vector4 = nil
    local theme = dofile("editor/theme.lua")
    Vector4 = previous
    for _, name in ipairs({ "background", "border", "titleBar", "titleText", "success", "error" }) do
        test.equal(#theme[name], 4)
        for _, channel in ipairs(theme[name]) do
            test.equal(channel >= 0 and channel <= 1, true)
        end
    end
    Vector4 = { new = function(...) return { ... } end }
    local colour = theme.colour(theme.success)
    Vector4 = previous
    for index = 1, 4 do test.equal(colour[index], theme.success[index]) end
end)
