local names = require("presets/names")
local colours = require("presets/colours")
local icons = require("presets/icons")
local service = require("presets/customisations").new(names, colours, icons)
return { apply = service.swap }
