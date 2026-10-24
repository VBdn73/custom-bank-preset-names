-- Plain RGBA values keep this module independent of the client UI API.
local theme = {
    background = { 0.14, 0.13, 0.11, 1 },
    border = { 0.58, 0.48, 0.28, 1 },
    titleBar = { 0.20, 0.18, 0.14, 1 },
    titleText = { 0.88, 0.72, 0.43, 1 },
    success = { 0.35, 0.85, 0.35, 1 },
    error = { 1, 0.35, 0.35, 1 },
}

function theme.colour(rgba)
    return Vector4.new(rgba[1], rgba[2], rgba[3], rgba[4])
end

return theme
