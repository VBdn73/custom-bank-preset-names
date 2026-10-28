local test = require("tests.test_helper")
local catalogue = require("presets/icon_catalogue")

test.case("Skill catalogue has 29 unique keys in native skill-list order", function()
    local expected = {
        "attack", "constitution", "mining", "strength", "agility", "smithing",
        "defence", "herblore", "fishing", "ranged", "thieving", "cooking",
        "prayer", "crafting", "firemaking", "magic", "fletching", "woodcutting",
        "runecrafting", "slayer", "farming", "construction", "hunter", "summoning",
        "dungeoneering", "divination", "invention", "archaeology", "necromancy",
    }
    test.equal(#catalogue.categories, 1)
    local category = catalogue.categories[1]
    test.equal(category.key, "skills")
    test.equal(category.name, "Skills")
    test.equal(#category.entries, #expected)
    local seen = {}
    for index, key in ipairs(expected) do
        local entry = category.entries[index]
        test.equal(entry.key, "skills:" .. key)
        test.equal(seen[entry.key], nil)
        seen[entry.key] = true
        test.equal(entry.category, category.key)
        test.equal(type(entry.name), "string")
        test.equal(catalogue.get(entry.key), entry)
    end
end)

test.case("Catalogue preserves the visually confirmed Challenge mapping and chosen Necromancy", function()
    local suffixes = {
        attack = 0, strength = 1, defence = 2, ranged = 3, prayer = 4, mining = 5,
        constitution = 6, firemaking = 7, thieving = 8, hunter = 9, crafting = 10,
        fletching = 11, magic = 12, runecrafting = 13, woodcutting = 14, smithing = 15,
        construction = 16, herblore = 17, fishing = 18, cooking = 19, farming = 20,
        slayer = 21, dungeoneering = 22, summoning = 23, agility = 24, divination = 25,
        archaeology = 27, invention = 28,
    }
    for key, suffix in pairs(suffixes) do
        local entry = catalogue.get("skills:" .. key)
        test.equal(entry.sprite, "CHALLENGE_SKILL_ICONS_35PX_" .. suffix)
        test.equal(entry.width, 35)
        test.equal(entry.height, 35)
    end
    local necromancy = catalogue.get("skills:necromancy")
    test.equal(necromancy.sprite, "SKILL_ICON_NECROMANCY_52PX_0")
    test.equal(necromancy.width, 52)
    test.equal(necromancy.height, 52)
end)

test.case("Catalogue safely falls back for defaults, unknown keys and missing resources", function()
    for _, key in ipairs({ "", "skills:unknown", "items:farming", "skills:Farming", 1, false, {} }) do
        test.equal(catalogue.get(key), nil)
        test.equal(catalogue.resolve(key, {}), nil)
    end
    test.equal(catalogue.get(nil), nil)
    test.equal(catalogue.resolve(nil, {}), nil)
    test.equal(catalogue.resolve("skills:farming", {}), nil)
    local entry = catalogue.get("skills:farming")
    for _, value in ipairs({ -1, "123", false, 1.5, math.huge }) do
        test.equal(catalogue.resolve(entry.key, { [entry.sprite] = value }), nil)
    end
    local spriteID, resolved = catalogue.resolve(entry.key, { [entry.sprite] = 123 })
    test.equal(spriteID, 123)
    test.equal(resolved, entry)
    test.equal(catalogue.resolve(entry.key, { [entry.sprite] = 456 }), 456,
        "Resource IDs are resolved afresh rather than cached or persisted")
end)
