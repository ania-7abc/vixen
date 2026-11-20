require("scripts.util")

local anim = require("scripts.anim")
local skins = require("scripts.skins")
local accessories = require("scripts.accessories")
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
local accessoryPage = action_wheel:newPage("Accessories")
local soundPage = action_wheel:newPage("Sounds")
local settingsPage = action_wheel:newPage("Settings")
local visualSettingsPage = action_wheel:newPage("Visual settings")
local audioSettingsPage = action_wheel:newPage("Audio settings")
local itemSettingsPage = action_wheel:newPage("Item settings")
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
addPageLink("Accessories", "minecraft:leather", accessoryPage)
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

local extraPoses = {
    { name = "wCurious", title = "Curious tilt", item = "minecraft:compass" },
    { name = "wCurl", title = "Curl up", item = "minecraft:hay_block" },
}
for _, pose in ipairs(extraPoses) do
    local name = pose.name
    poseActions[name] = posePage:newAction()
    :setTitle(pose.title)
    :setItem(pose.item)
    :onLeftClick(function (_)
        if anim.activePose() == name then anim.stop() else anim.pose(name) end
    end)
end

-- highlight the currently playing pose and selected skin
local skinActions = {}
local autoSkinAction
local activePose = nil
local activeSkin = nil
local autoSkin = nil
function events.tick()
    local current = anim.activePose()
    if current ~= activePose then
        activePose = current
        for name, action in pairs(poseActions) do
            action:setColor(name == current and vec(0, 1, 0) or nil)
        end
    end

    local skin = skins.activeKey()
    local auto = skins.isAuto()
    if skin == activeSkin and auto == autoSkin then return end
    activeSkin = skin
    autoSkin = auto
    for key, action in pairs(skinActions) do
        action:setColor(key == skin and not auto and vec(0, 1, 0) or nil)
    end
    autoSkinAction:setColor(auto and vec(0, 1, 0) or nil)
end

wagAction = posePage:newAction()
:setTitle("Wag tail")
:setToggleTitle("Wagging")
:setItem("minecraft:feather")
:setToggleItem("minecraft:sugar")
:onToggle(function (state, _)
    if state and anim.activePose() == "wSleep" then anim.stop() end
    anim.wag(state)
end)

-- skins
for _, key in ipairs(skins.order) do
    local entry = skins.entries[key]
    skinActions[key] = skinPage:newAction()
    :setTitle(entry.title)
    :setItem(entry.icon)
    :onLeftClick(function (_)
        skins.select(key)
    end)
end
autoSkinAction = skinPage:newAction()
:setTitle("Auto (by biome)")
:setItem("minecraft:command_block")
:onLeftClick(function (_)
    skins.setAuto(true)
end)

-- accessories
local accessoryEntries = {
    { key = "collar", title = "Collar", item = "minecraft:lead", toggleItem = "minecraft:iron_ingot" },
    { key = "scarf", title = "Scarf", item = "minecraft:white_wool", toggleItem = "minecraft:red_wool" },
    { key = "bowTie", title = "Bow tie", item = "minecraft:paper", toggleItem = "minecraft:purple_dye" },
}
for _, entry in ipairs(accessoryEntries) do
    local key = entry.key
    local action = accessoryPage:newAction()
    :setTitle(entry.title)
    :setToggleTitle(entry.title .. ": on")
    :setItem(entry.item)
    :setToggleItem(entry.toggleItem)
    :onToggle(function (state, _)
        accessories.set(key, state)
    end)
    accessories.setAction(key, action)
end

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

-- settings, split into groups so the page stays readable
local function addSettingsLink(title, item, page)
    settingsPage:newAction()
    :setTitle(title)
    :setItem(item)
    :onLeftClick(function (_)
        openPage(page)
    end)
end

addSettingsLink("Visual", "minecraft:ender_eye", visualSettingsPage)
addSettingsLink("Audio", "minecraft:note_block", audioSettingsPage)
addSettingsLink("Items", "minecraft:chest", itemSettingsPage)

local function addToggle(page, key, title, item, toggleItem, ping)
    local action = page:newAction()
    :setTitle(title)
    :setToggleTitle(title .. ": on")
    :setItem(item)
    :setToggleItem(toggleItem)
    :onToggle(function (state, _)
        ping(state)
    end)
    options.setAction(key, action)
end

addToggle(visualSettingsPage, "blinking", "Blinking", "minecraft:ender_eye", "minecraft:ender_pearl", pings.setBlinking)
addToggle(visualSettingsPage, "earTwitch", "Ear twitch", "minecraft:rabbit_foot", "minecraft:rabbit_hide", pings.setEarTwitch)
addToggle(visualSettingsPage, "earPhysics", "Ear physics", "minecraft:feather", "minecraft:blaze_rod", pings.setEarPhysics)
addToggle(visualSettingsPage, "tailWag", "Auto tail sway", "minecraft:feather", "minecraft:sugar", pings.setTailWag)
addToggle(audioSettingsPage, "foxSounds", "Fox SFX", "minecraft:sweet_berries", "minecraft:note_block", pings.setFoxSounds)
addToggle(audioSettingsPage, "snoring", "Snoring", "minecraft:hay_block", "minecraft:red_bed", pings.setSnoring)
addToggle(itemSettingsPage, "allInMouth", "All in mouth", "minecraft:chest", "minecraft:cooked_chicken", pings.setAllInMouth)

return {
    mainPage = mainPage,
    posePage = posePage,
    skinPage = skinPage,
    accessoryPage = accessoryPage,
    soundPage = soundPage,
    settingsPage = settingsPage,
    visualSettingsPage = visualSettingsPage,
    audioSettingsPage = audioSettingsPage,
    itemSettingsPage = itemSettingsPage,
}
