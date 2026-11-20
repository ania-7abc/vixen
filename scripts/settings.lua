local wheel = require("scripts.wheel")
local options = require("scripts.options")

local function addToggle(key, title, item, toggleItem, ping)
    local action = wheel.settingsPage:newAction()
    :setTitle(title)
    :setToggleTitle(title .. " (on)")
    :setItem(item)
    :setToggleItem(toggleItem)
    :onToggle(function (state, _)
        ping(state)
    end)
    options.setAction(key, action)
end

addToggle("blinking", "blinking", "minecraft:ender_eye", "minecraft:ender_pearl", pings.setBlinking)
addToggle("foxSounds", "fox sounds", "minecraft:sweet_berries", "minecraft:note_block", pings.setFoxSounds)
addToggle("snoring", "snoring", "minecraft:hay_block", "minecraft:red_bed", pings.setSnoring)
addToggle("tailWag", "tail wag", "minecraft:feather", "minecraft:sugar", pings.setTailWag)
