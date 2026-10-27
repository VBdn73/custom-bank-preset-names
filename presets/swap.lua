local names = require("presets/names")
local colours = require("presets/colours")
local service = require("presets/customisations").new(names, colours)
return { apply = service.swap }
