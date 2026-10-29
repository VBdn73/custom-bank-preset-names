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
    test.equal(#catalogue.categories, 4)
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

test.case("Weapons have unique stable keys, valid item IDs and alphabetical ordering", function()
    local category = catalogue.categories[2]
    test.equal(category.key, "weapons90")
    test.equal(category.name, "Weapons")
    local previous, seen = "", {}
    for _, entry in ipairs(category.entries) do
        test.equal(entry.category, "weapons90")
        test.equal(seen[entry.key], nil)
        seen[entry.key] = true
        test.equal(entry.name:lower() >= previous, true)
        previous = entry.name:lower()
        test.equal(entry.objectID > 0 and entry.objectID % 1 == 0, true)
        test.equal(catalogue.resolve(entry.key, {}), entry.objectID)
        test.equal(entry.width, 36)
        test.equal(entry.height, 32)
    end
    test.equal(catalogue.get("weapons90:malachis-tooth").objectID, 64341,
        "Beta client uses 64341 for the crossbow; 64191 is a cure potion")
    test.equal(catalogue.get("weapons90:elder-crossbow").objectID, 63579,
        "Beta client uses 63579 for Elder crossbow; 63315 is a trophy")
end)

test.case("Holiday tab exposes unique seasonal item artwork and named sprites", function()
    local category = catalogue.categories[3]
    test.equal(category.key, "holidays")
    test.equal(category.name, "Holidays")
    test.equal(#category.entries, 44)
    local seen, seenItems = {}, {}
    for _, entry in ipairs(category.entries) do
        test.equal(entry.category, category.key)
        test.equal(seen[entry.key], nil)
        seen[entry.key] = true
        test.equal(catalogue.get(entry.key), entry)
        if entry.objectID then
            test.equal(seenItems[entry.objectID], nil)
            seenItems[entry.objectID] = true
            test.equal(entry.objectID > 0 and entry.objectID % 1 == 0, true)
            test.equal(catalogue.resolve(entry.key, {}), entry.objectID)
        else
            test.equal(catalogue.resolve(entry.key, {}), nil)
            test.equal(catalogue.resolve(entry.key, { [entry.sprite] = 123 }), 123)
        end
    end
    test.equal(catalogue.get("holidays:pumpkin").objectID, 1959)
    test.equal(catalogue.get("holidays:easter-egg").objectID, 1961)
    test.equal(catalogue.get("holidays:christmas-tree-hat").objectID, 26493)
    local expected = {
        ["christmas-cracker"] = 962, ["bunny-ears"] = 1037,
        ["rubber-chicken"] = 4566, ["easter-basket"] = 54618,
        ["yo-yo"] = 4079, ["reindeer-hat"] = 10507,
        ["scythe"] = 1419,
        ["christmas-scythe"] = 33625, ["festive-scythe"] = 52757,
        ["red-partyhat"] = 1038, ["yellow-partyhat"] = 1040,
        ["blue-partyhat"] = 1042, ["green-partyhat"] = 1044,
        ["purple-partyhat"] = 1046, ["white-partyhat"] = 1048,
        ["pink-partyhat"] = 37590, ["golden-partyhat"] = 52664,
        ["black-partyhat"] = 56161, ["chromatic-partyhat"] = 34358,
        ["santa-hat"] = 1050, ["black-santa-hat"] = 30412,
        ["green-santa-hat"] = 52748, ["purple-santa-hat"] = 56222,
        ["pink-santa-hat"] = 57941, ["aurora-santa-hat"] = 58273,
        ["yellow-santa-hat"] = 60016, ["blue-santa-hat"] = 60020,
        ["festive-aurora-santa-hat"] = 60115,
        ["green-halloween-mask"] = 1053, ["blue-halloween-mask"] = 1055,
        ["red-halloween-mask"] = 1057, ["purple-halloween-mask"] = 53982,
        ["orange-halloween-mask"] = 55968, ["yellow-halloween-mask"] = 59820,
        ["soul-halloween-mask"] = 59823, ["pink-halloween-mask"] = 63952,
    }
    for key, objectID in pairs(expected) do
        test.equal(catalogue.get("holidays:" .. key).objectID, objectID, key)
    end
    for _, colour in ipairs({ "light-blue", "dark-blue", "white", "purple", "red", "green", "pink" }) do
        test.equal(catalogue.get("holidays:" .. colour .. "-easter-egg"), nil,
            "Retired coloured eggs must not expose placeholder artwork")
    end
    for objectID = 4558, 4564 do test.equal(seenItems[objectID], nil) end
end)

test.case("Misc tab exposes coin variants, achievements, clues and utility artwork", function()
    local category = catalogue.categories[4]
    test.equal(category.key, "misc")
    test.equal(category.name, "Misc")
    test.equal(#category.entries, 37)
    local seen = {}
    for _, entry in ipairs(category.entries) do
        test.equal(entry.category, "misc")
        test.equal(seen[entry.key], nil)
        seen[entry.key] = true
        test.equal(catalogue.get(entry.key), entry)
        if entry.objectID then
            test.equal(catalogue.resolve(entry.key, {}), entry.objectID)
        else
            test.equal(catalogue.resolve(entry.key, {}), nil)
            test.equal(catalogue.resolve(entry.key, { [entry.sprite] = 123 }), 123)
        end
    end
    for index, amount in ipairs({ 1, 2, 3, 4, 5, 25, 100, 250, 1000, 10000 }) do
        test.equal(catalogue.get("misc:coins-" .. amount).objectID, 994 + index)
    end
    for index, tier in ipairs({ "easy", "medium", "hard", "elite", "master" }) do
        test.equal(catalogue.get("misc:clue-scroll-" .. tier).objectID, 42005 + index)
        test.equal(catalogue.get("misc:casket-" .. tier).objectID, 42000 + index)
    end
    test.equal(catalogue.get("misc:max-cape").objectID, 20767)
    test.equal(catalogue.get("misc:quests").sprite, "RS3_ICON_QUEST_LIST")
    test.equal(catalogue.get("misc:runescore").sprite, "ACHIEVEMENT_ICON_RUNESCORE")
    test.equal(catalogue.get("misc:skills").sprite, "RS3_ICON_TAB_SKILLS")
    local utilitySprites = {
        ["combat-level"] = "AIF_COMBAT_ICON",
        ["world-map"] = "NAVIGATION_ICON_WORLDMAP_ON",
        calendar = "BTN_MOBILE_CALENDAR",
        ["run-energy"] = "NAVIGATION_ICON_ENERGY_ON",
        rest = "NAVIGATION_ICON_ENERGY_REST",
        ["life-points"] = "RS3_HUD_COMBAT_BAR_ICON_HEALTH",
        bank = "RS3_ICON_WORLDMAP_KEY_BANK",
        ["grand-exchange"] = "RS3_ICON_PATH_GRAND_EXCHANGE",
    }
    for key, resource in pairs(utilitySprites) do
        test.equal(catalogue.get("misc:" .. key).sprite, resource)
    end
    test.equal(catalogue.get("misc:home-teleport"), nil)
    test.equal(catalogue.get("misc:lodestone"), nil)
end)

test.case("Native item assignment hides quantities and clears when returning to skills", function()
    local oldUI = ui
    ui = { ObjectQuantityDisplayMode = { NEVER = 0 } }
    local sprite = setmetatable({}, { __index = function(self, key)
        if key == "spriteID" then return self.sprite end
    end })
    function sprite:SetAssociatedObject(objectID, quantity)
        test.equal(quantity, nil, "Icon assignment must omit the optional native Uint64 quantity")
        self.associatedObjectID, self.associatedObjectQuantity = objectID, quantity
    end
    local asset, entry = catalogue.resolve("weapons90:noxious-scythe")
    catalogue.apply(sprite, asset, entry)
    test.equal(sprite.associatedObjectID, 31725)
    test.equal(sprite.associatedObjectQuantityMode, 0)
    catalogue.apply(sprite, 123, catalogue.get("skills:attack"))
    test.equal(sprite.associatedObjectID, -1)
    test.equal(sprite.spriteID, 123)
    ui = oldUI
end)

test.case("T90–95 tab includes finished weapons with valid tiers, sorted unique item artwork", function()
    local category = catalogue.categories[2]
    test.equal(category.key, "weapons90")
    local previous, seen = "", {}
    for _, entry in ipairs(category.entries) do
        test.equal(entry.category, category.key)
        test.equal(catalogue.get(entry.key), entry)
        test.equal(catalogue.resolve(entry.key), entry.objectID)
        test.equal(entry.tier >= 90 and entry.tier <= 95, true)
        test.equal(entry.objectID > 0 and entry.objectID % 1 == 0, true)
        test.equal(seen[entry.objectID], nil)
        seen[entry.objectID] = true
        test.equal(entry.name:lower() >= previous, true)
        previous = entry.name:lower()
        test.equal(entry.name:lower():find("dormant", 1, true), nil)
    end
    for _, key in ipairs({ "eldritch-crossbow", "fractured-staff-of-armadyl",
        "bow-of-the-last-guardian", "abyssal-scourge", "masterwork-spear-of-annihilation",
        "death-guard-tier-90-" }) do
        test.equal(catalogue.get("weapons90:" .. key) ~= nil, true, key)
    end
    test.equal(catalogue.get("weapons90:dragon-2h-sword"), nil)
    test.equal(#category.entries, 40)
    for _, entry in ipairs(category.entries) do
        for _, family in ipairs({ "promethium", "grave creeper", "spiritbloom", "empowered catalytic" }) do
            test.equal(entry.name:lower():find(family, 1, true), nil,
                "Daemonheim-only weapons must not appear in the picker")
        end
    end
    test.equal(catalogue.get("weapons90:ruinous-rapier").objectID, 61452,
        "Surface-usable Dungeoneering rewards remain available")
    test.equal(catalogue.get("weapons:dragon-2h-sword"), nil,
        "The old Weapons category is no longer registered")
end)

test.case("Weapon tabs keep main-hand and two-handed icons without paired off-hands", function()
    local offhands = { 52045, 52057, 25672, 25895, 34855, 37080, 40600,
        64195, 26591, 26599, 26583, 28441, 40659, 25664, 39579,
        55482, 57158, 42774, 28621, 61454, 58213, 63337, 61462, 55542, 61466 }
    for index = 2, 2 do
        local present = {}
        for _, entry in ipairs(catalogue.categories[index].entries) do
            present[entry.objectID] = true
            test.equal(entry.name:lower():find("off-hand", 1, true), nil)
        end
        for _, objectID in ipairs(offhands) do test.equal(present[objectID], nil) end
        test.equal(present[26587], true, "Main-hand drygore remains")
        test.equal(present[31725], true, "Two-handed noxious scythe remains")
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
