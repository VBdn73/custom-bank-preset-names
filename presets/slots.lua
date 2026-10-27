local slots = { count = 18, bob = 19 }

-- BoB has its own saved entry, but is never a numbered/swappable preset.
function slots.customisable(slot, count)
    return slots.valid(slot, count) or (count == nil and slot == slots.bob)
end

function slots.title(slot)
    return slot == slots.bob and "Beast of Burden" or "Preset " .. slot
end

function slots.valid(slot, count)
    return type(slot) == "number" and slot % 1 == 0
        and slot >= 1 and slot <= (count or slots.count)
end

return slots
