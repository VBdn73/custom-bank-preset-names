local names = require("presets/names")
local colours = require("presets/colours")
local icons = require("presets/icons")
local service = require("presets/customisations").new(names, colours, icons, require("presets/icon_text"))
return { apply = service.swap }
