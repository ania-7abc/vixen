local sleep = require("scripts.sleep")
local options = require("scripts.options")

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
function events.on_play_sound(id, pos, vol, pitch, loop, category)
    -- only replace sounds emitted by the player
    if not player:isLoaded() then return end
    if category ~= "PLAYERS" then return end
    if not ((pos - player:getPos()):length() < 0.1) then return end
    if not options.foxSounds then return end

    if soundLUT[id] then
        sounds:playSound(soundLUT[id], pos, vol, pitch, loop)
        return true
    end
end

-- snoring
local snoringInterval = 60
local snoringTimer = 0
options.onChange("snoring", function (enabled)
    if not enabled then snoringTimer = 0 end
end)
function events.tick()
    if not options.snoring then return end
    if not sleep.isSleeping() then return end

    if snoringTimer < snoringInterval then 
        snoringTimer = snoringTimer + 1
    else
        snoringTimer = 0
        sounds:playSound("minecraft:entity.fox.sleep", player:getPos())
    end
end


return {
    entries = soundboardEntries,
    play = function (key)
        local entry = soundboardEntries[key]
        if entry then pings.playerSound(entry.sound) end
    end,
}