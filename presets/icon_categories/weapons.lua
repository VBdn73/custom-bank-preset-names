local category = { key = "weapons90", name = "Weapons", entries = {} }
local function weapon(name, objectID, tier)
    category.entries[#category.entries + 1] = {
        key = "weapons90:" .. name:lower():gsub("'", ""):gsub("[^%w]+", "-"),
        category = category.key, name = name, objectID = objectID, tier = tier,
        width = 36, height = 32,
    }
end

-- Melee: direct drops, assembled weapons, crafted weapons.
weapon("Drygore longsword", 26587, 90)
weapon("Drygore mace", 26595, 90)
weapon("Drygore rapier", 26579, 90)
weapon("Noxious scythe", 31725, 90)
weapon("Spear of Annihilation", 49965, 90)
weapon("Varanus's Mercy", 59921, 90)
weapon("Ruinous maul", 61456, 90)
weapon("Ruinous rapier", 61452, 90)
weapon("Primal 2h sword + 5", 57429, 90)
weapon("Primal warhammer + 5", 58182, 90)
weapon("Khopesh of Tumeken", 40655, 92)
weapon("Masterwork Spear of Annihilation", 49970, 92)
weapon("Zaros godsword", 37640, 92)
weapon("Abyssal scourge", 52931, 92)
weapon("Dark Shard of Leng", 52053, 95)
weapon("Ek-ZekKil", 52511, 95)
weapon("Tumeken's Light", 59350, 95)

-- Ranged: main-hand and two-handed complete weapons.
weapon("Ascension crossbow", 28437, 90)
weapon("Noxious longbow", 31733, 90)
weapon("Gloomfire bow", 59943, 90)
weapon("Elder longbow", 29611, 90)
-- Local pan-obj: XBOWS_CROSSBOW_ELDER; 63315 is a trophy in this beta.
weapon("Elder crossbow", 63579, 90)
weapon("Ruinous crossbow", 61460, 90)
weapon("Blightbound crossbow", 42770, 92)
weapon("Eldritch crossbow", 47470, 92)
weapon("Seren godbow", 37632, 92)
weapon("Bow of the Last Guardian", 53338, 95)
-- Local pan-obj: RANGED_GHRAZI_CROSSBOW_T95 (wiki ID differs in this beta).
weapon("Malachi's tooth", 64341, 95)

-- Magic.
weapon("Seismic wand", 28617, 90)
weapon("Noxious staff", 31729, 90)
weapon("Legatus's Emberstaff", 59917, 90)
weapon("Ruinous staff", 61458, 90)
weapon("Wand of the praesul", 39574, 92)
weapon("Staff of Sliske", 37636, 92)
weapon("Fractured Staff of Armadyl", 51772, 95)
weapon("Roar of Awakening", 57162, 95)

-- Necromancy, including Kili's crafted tier-90 weapons.
weapon("Death guard (tier 90)", 55540, 90)
weapon("Ruinous guard", 61464, 90)
weapon("Omni guard", 55480, 95)
weapon("Devourer's Guard", 59354, 95)

table.sort(category.entries, function(a, b) return a.name:lower() < b.name:lower() end)
return category
