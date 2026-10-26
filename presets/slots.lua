local slots = { count = 18 }

function slots.valid(slot, count)
    return type(slot) == "number" and slot % 1 == 0
        and slot >= 1 and slot <= (count or slots.count)
end

return slots
