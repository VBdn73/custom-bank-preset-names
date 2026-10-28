-- Native assets verified against the in-client gallery and Skills interface.
-- Challenge resource suffixes are NOT skill IDs. Keep this mapping explicit.
local category = { key = "skills", name = "Skills", entries = {} }
local entries = category.entries

local function skill(key, name, sprite, size)
    local entry = {
        key = "skills:" .. key, category = "skills", name = name,
        sprite = sprite, width = size, height = size,
    }
    entries[#entries + 1] = entry
end

-- Row-major order of the native three-column Skills interface, not skill IDs
-- or Challenge-family resource order. The combined Challenge icon 26 is omitted.
skill("attack", "Attack", "CHALLENGE_SKILL_ICONS_35PX_0", 35)
skill("constitution", "Constitution", "CHALLENGE_SKILL_ICONS_35PX_6", 35)
skill("mining", "Mining", "CHALLENGE_SKILL_ICONS_35PX_5", 35)
skill("strength", "Strength", "CHALLENGE_SKILL_ICONS_35PX_1", 35)
skill("agility", "Agility", "CHALLENGE_SKILL_ICONS_35PX_24", 35)
skill("smithing", "Smithing", "CHALLENGE_SKILL_ICONS_35PX_15", 35)
skill("defence", "Defence", "CHALLENGE_SKILL_ICONS_35PX_2", 35)
skill("herblore", "Herblore", "CHALLENGE_SKILL_ICONS_35PX_17", 35)
skill("fishing", "Fishing", "CHALLENGE_SKILL_ICONS_35PX_18", 35)
skill("ranged", "Ranged", "CHALLENGE_SKILL_ICONS_35PX_3", 35)
skill("thieving", "Thieving", "CHALLENGE_SKILL_ICONS_35PX_8", 35)
skill("cooking", "Cooking", "CHALLENGE_SKILL_ICONS_35PX_19", 35)
skill("prayer", "Prayer", "CHALLENGE_SKILL_ICONS_35PX_4", 35)
skill("crafting", "Crafting", "CHALLENGE_SKILL_ICONS_35PX_10", 35)
skill("firemaking", "Firemaking", "CHALLENGE_SKILL_ICONS_35PX_7", 35)
skill("magic", "Magic", "CHALLENGE_SKILL_ICONS_35PX_12", 35)
skill("fletching", "Fletching", "CHALLENGE_SKILL_ICONS_35PX_11", 35)
skill("woodcutting", "Woodcutting", "CHALLENGE_SKILL_ICONS_35PX_14", 35)
skill("runecrafting", "Runecrafting", "CHALLENGE_SKILL_ICONS_35PX_13", 35)
skill("slayer", "Slayer", "CHALLENGE_SKILL_ICONS_35PX_21", 35)
skill("farming", "Farming", "CHALLENGE_SKILL_ICONS_35PX_20", 35)
skill("construction", "Construction", "CHALLENGE_SKILL_ICONS_35PX_16", 35)
skill("hunter", "Hunter", "CHALLENGE_SKILL_ICONS_35PX_9", 35)
skill("summoning", "Summoning", "CHALLENGE_SKILL_ICONS_35PX_23", 35)
skill("dungeoneering", "Dungeoneering", "CHALLENGE_SKILL_ICONS_35PX_22", 35)
skill("divination", "Divination", "CHALLENGE_SKILL_ICONS_35PX_25", 35)
skill("invention", "Invention", "CHALLENGE_SKILL_ICONS_35PX_28", 35)
skill("archaeology", "Archaeology", "CHALLENGE_SKILL_ICONS_35PX_27", 35)
skill("necromancy", "Necromancy", "SKILL_ICON_NECROMANCY_52PX_0", 52)

return category
