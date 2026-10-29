-- Assets listed in dev_plugins/pan-files/pan-obj.txt and pan-sprite.txt.
-- Item artwork supplies familiar seasonal objects without large event backgrounds.
local category = { key = "holidays", name = "Holidays", entries = {} }

local function item(key, name, objectID)
    category.entries[#category.entries + 1] = {
        key = "holidays:" .. key, category = category.key, name = name,
        objectID = objectID, width = 36, height = 32,
    }
end

local function sprite(key, name, resource)
    category.entries[#category.entries + 1] = {
        key = "holidays:" .. key, category = category.key, name = name,
        sprite = resource, width = 32, height = 32,
    }
end

item("christmas-tree-hat", "Christmas tree hat", 26493)
sprite("christmas-present", "Christmas present", "XMAS2019_ADVENT_PRESENT_ICON")
item("easter-egg", "Easter egg", 1961)
sprite("golden-easter-egg", "Golden Easter egg", "EASTER24_EGG_HUNT_GOLDEN_EGG_SMALL")
item("red-partyhat", "Red partyhat", 1038)
item("yellow-partyhat", "Yellow partyhat", 1040)
item("blue-partyhat", "Blue partyhat", 1042)
item("green-partyhat", "Green partyhat", 1044)
item("purple-partyhat", "Purple partyhat", 1046)
item("white-partyhat", "White partyhat", 1048)
item("pink-partyhat", "Pink partyhat", 37590)
item("golden-partyhat", "Golden partyhat", 52664)
item("black-partyhat", "Black partyhat", 56161)
item("chromatic-partyhat", "Chromatic partyhat", 34358)
item("green-halloween-mask", "Green Halloween mask", 1053)
item("blue-halloween-mask", "Blue Halloween mask", 1055)
item("red-halloween-mask", "Red Halloween mask", 1057)
item("purple-halloween-mask", "Purple Halloween mask", 53982)
item("orange-halloween-mask", "Orange Halloween mask", 55968)
item("yellow-halloween-mask", "Yellow Halloween mask", 59820)
item("soul-halloween-mask", "Soul Halloween mask", 59823)
item("pink-halloween-mask", "Pink Halloween mask", 63952)
item("pumpkin", "Pumpkin", 1959)
item("pumpkin-head", "Pumpkin head", 9920)
item("santa-hat", "Red Santa hat", 1050)
item("black-santa-hat", "Black Santa hat", 30412)
item("green-santa-hat", "Green Santa hat", 52748)
item("purple-santa-hat", "Purple Santa hat", 56222)
item("pink-santa-hat", "Pink Santa hat", 57941)
item("aurora-santa-hat", "Aurora Santa hat", 58273)
item("yellow-santa-hat", "Yellow Santa hat", 60016)
item("blue-santa-hat", "Blue Santa hat", 60020)
item("festive-aurora-santa-hat", "Festive aurora Santa hat", 60115)
item("snow-globe", "Snow globe", 11950)
sprite("snowflake", "Snowflake", "XMAS_SNOWFLAKE")

item("christmas-cracker", "Christmas cracker", 962)
item("bunny-ears", "Bunny ears", 1037)
item("rubber-chicken", "Rubber chicken", 4566)
item("easter-basket", "Full Easter egg basket", 54618)
item("yo-yo", "Yo-yo", 4079)
item("reindeer-hat", "Reindeer hat", 10507)
item("scythe", "Scythe", 1419)
item("christmas-scythe", "Christmas scythe", 33625)
item("festive-scythe", "Festive scythe", 52757)

return category
