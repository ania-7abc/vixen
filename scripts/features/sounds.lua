local state = require("scripts.core.state")
local settings = require("scripts.core.settings")
local events = require("scripts.core.events")
local time = require("scripts.core.time")
require("scripts.core.util") -- defines pings.playerSound

-- soundboard sounds
local soundboardEntries = {
    chirp = {
        title = "Chirp",
        icon = "minecraft:sweet_berries",
        sound = "minecraft:entity.fox.ambient",
    },
    bite = {
        title = "Bite",
        icon = "minecraft:chicken",
        sound = "minecraft:entity.fox.bite",
    },
    eat = {
        title = "Eat",
        icon = "minecraft:cooked_chicken",
        sound = "minecraft:entity.fox.eat",
    },
    growl = {
        title = "Growl",
        icon = "minecraft:pufferfish",
        sound = "minecraft:entity.fox.aggro",
    },
    screech = {
        title = "Screech",
        icon = "minecraft:music_disc_11",
        sound = "minecraft:entity.fox.screech",
    },
    sniff = {
        title = "Sniff",
        icon = "minecraft:feather",
        sound = "minecraft:entity.fox.sniff",
    },
    spit = {
        title = "Spit",
        icon = "minecraft:arrow",
        sound = "minecraft:entity.fox.spit",
    },
    sleep = {
        title = "Sleep",
        icon = "minecraft:red_bed",
        sound = "minecraft:entity.fox.sleep",
    },
}
-- replace player sfx with the vanilla fox sfx
local soundLUT = {
    ["minecraft:entity.player.hurt"] = "minecraft:entity.fox.hurt",
    ["minecraft:entity.generic.eat"] = "minecraft:entity.fox.eat",
    ["minecraft:entity.player.burp"] = "minecraft:entity.fox.bite",
}

events.on("on_play_sound", function (id, pos, vol, pitch, loop, category)
    -- only replace sounds emitted by the player
    if not player:isLoaded() then return end
    if category ~= "PLAYERS" then return end
    if not ((pos - player:getPos()):length() < 0.1) then return end
    if not settings.foxSounds then return end

    if soundLUT[id] then
        sounds:playSound(soundLUT[id], pos, vol, pitch, loop)
        return true
    end
end)

-- snoring
local snoringTimer = time.newInterval(60)
settings.onChange("snoring", function (enabled)
    if not enabled then snoringTimer:clear() end
end)
events.on("tick", function ()
    if not settings.snoring then return end
    if not state.isSleeping() then return end

    if snoringTimer:up() then
        sounds:playSound("minecraft:entity.fox.sleep", player:getPos())
    end
end)

return {
    entries = soundboardEntries,
    play = function (key)
        local entry = soundboardEntries[key]
        if entry then pings.playerSound(entry.sound) end
    end,
}
