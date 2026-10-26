local names = require("presets/names")
local colours = require("presets/colours")
local slots = require("presets/slots")
local swap = {}

function swap.apply(first, second)
    for _, slot in ipairs({ first, second }) do
        if not slots.valid(slot) then
            return false, "Invalid preset slot."
        end
    end
    if first == second then return true end
    if not names.getContext() then return false, "Log in before swapping customisations." end
    local writes = {}
    local function pair(get, save)
        local a, b = get(first), get(second)
        writes[#writes + 1] = { save = save, slot = first, old = a, value = b }
        writes[#writes + 1] = { save = save, slot = second, old = b, value = a }
    end
    pair(function(slot) return names.get(slot) or "" end, names.save)
    for _, kind in ipairs({ "background", "text" }) do
        pair(function(slot) return colours.get(slot, kind) end,
            function(slot, value) return colours.save(slot, kind, value) end)
    end
    for index, write in ipairs(writes) do
        local ok, message = write.save(write.slot, write.value)
        if not ok then
            -- Restore both destinations, including a setter that wrote but failed verification.
            for rollback = index, 1, -1 do
                local previous = writes[rollback]
                previous.save(previous.slot, previous.old)
            end
            return false, message
        end
    end
    return true
end

return swap
