-- Single entry point. Load order is fixed by avatar.json's autoScripts.

-- core
require("scripts.core.events")
require("scripts.core.util")
require("scripts.core.config")
require("scripts.core.settings")
require("scripts.core.state")
require("scripts.core.parts")
require("scripts.core.time")

-- lib
require("scripts.lib.aurianims")

-- features
require("scripts.features.animation.anim")
require("scripts.features.tail")
require("scripts.features.ears")
require("scripts.features.idle")
require("scripts.features.skins")
require("scripts.features.accessories")
require("scripts.features.sounds")
require("scripts.features.items")

-- ui
require("scripts.ui.wheel")

local events = require("scripts.core.events")

-- vanilla overrides
vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(false)
vanilla_model.HELMET_ITEM:setVisible(true)
vanilla_model.HELMET:setVisible(true)
vanilla_model.CAPE:setVisible(false)

-- loading notification
events.on("entity_init", function ()
    sounds:playSound("minecraft:entity.fox.ambient", player:getPos())
end)
