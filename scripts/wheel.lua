require("scripts.util")

local anim = require("scripts.anim")
local skins = require("scripts.skins")
local sleep = require("scripts.sleep")
local sounds = require("scripts.sounds")
local options = require("scripts.options")

-- page history for backing
local history = {}
local function back()
    local last = history[#history]
    if last then
        action_wheel:setPage(last)
        table.remove(history, #history)
    end
end
local function openPage(page)
    table.insert(history, action_wheel:getCurrentPage())
    action_wheel:setPage(page)
end

-- go back with rmb
function events.mouse_press(button, action, modifier)
    if button == 1 and action == 1 and action_wheel:isEnabled() then
        back()
    end
end

-- pages
local mainPage = action_wheel:newPage("Main")
local posePage = action_wheel:newPage("Poses")
local skinPage = action_wheel:newPage("Skins")
local soundPage = action_wheel:newPage("Sounds")
local settingsPage = action_wheel:newPage("Settings")
action_wheel:setPage(mainPage)

local function addPageLink(title, item, page)
    mainPage:newAction()
    :setTitle(title)
    :setItem(item)
    :onLeftClick(function (_)
        openPage(page)
    end)
end

-- main page
addPageLink("Poses", "minecraft:armor_stand", posePage)
addPageLink("Skins", "minecraft:rabbit_hide", skinPage)
addPageLink("Sounds", "minecraft:note_block", soundPage)
addPageLink("Settings", "minecraft:totem_of_undying", settingsPage)

-- poses: the sleep pose also plays the fox sleep call
local poseActions = {}
local wagAction
poseActions.wSleep = posePage:newAction()
:setTitle("Sleep")
:setItem("minecraft:red_bed")
:onLeftClick(function (_)
    if anim.activePose() == "wSleep" then
        anim.stop()
    else
        wagAction:setToggled(false)
        anim.wag(false)
        anim.sleep()
        sounds.play("sleep")
    end
end)
poseActions.wSit = posePage:newAction()
:setTitle("Sit (tucked)")
:setItem("minecraft:spruce_stairs")
:onLeftClick(function (_)
    if anim.activePose() == "wSit" then anim.stop() else anim.pose("wSit") end
end)
poseActions.wSitAlt = posePage:newAction()
:setTitle("Sit (legs out)")
:setItem("minecraft:oak_stairs")
:onLeftClick(function (_)
    if anim.activePose() == "wSitAlt" then anim.stop() else anim.pose("wSitAlt") end
end)

-- highlight the currently playing pose
local activePose = nil
function events.tick()
    local current = anim.activePose()
    if current == activePose then return end
    activePose = current
    for name, action in pairs(poseActions) do
        action:setColor(name == current and vec(0, 1, 0) or nil)
    end
end

wagAction = posePage:newAction()
:setTitle("Wag tail")
:setToggleTitle("Wagging")
:setItem("minecraft:feather")
:setToggleItem("minecraft:sugar")
:onToggle(function (state, _)
    if state and sleep.isSleeping() then
        wagAction:setToggled(false)
        return
    end
    anim.wag(state)
end)

-- skins
for _, key in ipairs(skins.order) do
    local entry = skins.entries[key]
    skinPage:newAction()
    :setTitle(entry.title)
    :setItem(entry.icon)
    :onLeftClick(function (_)
        skins.select(key)
    end)
end
skinPage:newAction()
:setTitle("Auto (by biome)")
:setItem("minecraft:command_block")
:onLeftClick(function (_)
    skins.setAuto(true)
end)

-- sounds
local soundOrder = { "chirp", "bite", "eat", "growl", "screech", "sniff", "spit" }
for _, key in ipairs(soundOrder) do
    local entry = sounds.entries[key]
    soundPage:newAction()
    :setTitle(entry.title)
    :setItem(entry.icon)
    :onLeftClick(function (_)
        sounds.play(key)
    end)
end

-- settings
local function addToggle(key, title, item, toggleItem, ping)
    local action = settingsPage:newAction()
    :setTitle(title)
    :setToggleTitle(title .. ": on")
    :setItem(item)
    :setToggleItem(toggleItem)
    :onToggle(function (state, _)
        ping(state)
    end)
    options.setAction(key, action)
end

addToggle("blinking", "Blinking", "minecraft:ender_eye", "minecraft:ender_pearl", pings.setBlinking)
addToggle("foxSounds", "Fox SFX", "minecraft:sweet_berries", "minecraft:note_block", pings.setFoxSounds)
addToggle("snoring", "Snoring", "minecraft:hay_block", "minecraft:red_bed", pings.setSnoring)
addToggle("tailWag", "Auto tail sway", "minecraft:feather", "minecraft:sugar", pings.setTailWag)

return {
    mainPage = mainPage,
    posePage = posePage,
    skinPage = skinPage,
    soundPage = soundPage,
    settingsPage = settingsPage,
}
