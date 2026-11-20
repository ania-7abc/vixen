require("scripts.util")

local wheel = require("scripts.wheel")
local sleep = require("scripts.sleep")

local skinEntries = {
    Rebecca = {
        texture = "assets.skin_rebecca",
        icon = "minecraft:redstone",
        name = [=[[{"text":"Rebecca","color":"gold"}]]=],
    },
    Mira = {
        texture = "assets.skin_mira",
        icon = "minecraft:target",
        name = [=[[{"text":"Mira","color":"red"}]]=],
    },
    Eva = {
        texture = "assets.skin_eva",
        icon = "minecraft:crimson_nylium",
        name = [=[[{"text":"Eva","color":"dark_red"}]]=],
    },
    Rue = {
        texture = "assets.skin_rue",
        icon = "minecraft:red_sand",
        name = [=[[{"text":"Rue","color":"gold"}]]=],
    },
    Kaya = {
        texture = "assets.skin_kaya",
        icon = "minecraft:snow_block",
        name = [=[[{"text":"Kaya","color":"white"}]]=],
    },
    Thea = {
        texture = "assets.skin_thea",
        icon = "minecraft:coal_block",
        name = [=[[{"text":"Thea","color":"dark_gray"}]]=],
    },
}
-- generate keys
for key, value in pairs(skinEntries) do
    value["key"] = key
end

local function validateSkinEntries()
    for key, skin in pairs(skinEntries) do
        if not skin.icon or not skin.name then
            log("[vixen] skin " .. key .. " is missing its icon or name")
        end
        if not skin.texture then
            log("[vixen] skin " .. key .. " is missing its texture")
        else
            if not textures[skin.texture] then
                log("[vixen] skin " .. key .. " is missing texture " .. skin.texture)
            end
            if not textures[skin.texture .. "_sleep"] then
                log("[vixen] skin " .. key .. " is missing sleeping texture " .. skin.texture .. "_sleep")
            end
        end
    end
end
validateSkinEntries()

local currentSkin = skinEntries.Rebecca

-- automatic skin updated based on the biome
local autoSkinEnabled = false
local skinUpdateInterval = 80
local skinUpdateTimer = 0
local function setAutoSkin(enabled)
    autoSkinEnabled = enabled
    config:save("autoSkinEnabled", enabled)
end

-- nameplate overriding
local overridePlayerName = true
function pings.setNamePlate(override)
    overridePlayerName = override
    nameplate.ALL:setText(override and currentSkin.name or "${name}")
    if host:isHost() then
        config:save("overridePlayerName", override)
    end
end

-- sleeping and blinking
local blinkMinDelay = 60
local blinkMaxDelay = 140
local blinkDuration = 3

local appliedClosed = nil
local blinkTimer = math.random(blinkMinDelay, blinkMaxDelay)
local blinkTicks = 0
local function updateHeadTexture()
    local closed = sleep.isSleeping() or blinkTicks > 0
    if appliedClosed == closed then return end
    appliedClosed = closed
    models.model.root.Head:setPrimaryTexture("CUSTOM", textures[closed and (currentSkin.texture .. "_sleep") or currentSkin.texture])
end
sleep.onChange(updateHeadTexture)

local function tickBlink()
    if blinkTicks > 0 then
        blinkTicks = blinkTicks - 1
        if blinkTicks == 0 then updateHeadTexture() end
    elseif not sleep.isSleeping() then
        blinkTimer = blinkTimer - 1
        if blinkTimer <= 0 then
            blinkTicks = blinkDuration
            blinkTimer = math.random(blinkMinDelay, blinkMaxDelay)
            updateHeadTexture()
        end
    end
end

local function setSkin(skin)
    if currentSkin == skin then return end
    currentSkin = skin
    models.model.root:setPrimaryTexture("CUSTOM", textures[skin.texture])
    appliedClosed = nil
    updateHeadTexture()
    pings.setNamePlate(overridePlayerName)
    if host:isHost() then
        config:save("currentSkin", skin.key)
    end
end
function pings.setSkin(skinKey)
    setSkin(skinEntries[skinKey] or currentSkin)
end

-- skin entries
for key, value in pairs(skinEntries) do
    wheel.skinPage:newAction()
    :setTitle(key)
    :setItem(value.icon)
    :onLeftClick(function (_)
        setAutoSkin(false)
        pings.setSkin(value.key)
    end)
end
wheel.skinPage:newAction()
:setTitle("auto")
:setItem("minecraft:command_block")
:onLeftClick(function (_)
    setAutoSkin(true)
    skinUpdateTimer = skinUpdateInterval
end)


local function updateAutoSkin()
    -- eva in nether
    local dimension = world.getDimension()
    if dimension == "minecraft:the_nether" then
        setSkin(skinEntries.Eva)
        return
    end
    -- mira in end
    if dimension == "minecraft:the_end" then
        setSkin(skinEntries.Mira)
        return
    end

    local biome = world.getBiome(player:getPos())
    local temperature = biome:getTemperature()
    
    -- kaya in cold 
    if temperature <= 0.25 then
        setSkin(skinEntries.Kaya)
        return
    end

    -- eva in dark forests
    if biome.id == "minecraft:dark_forest" then
        setSkin(skinEntries.Eva)
        return
    end

    setSkin(skinEntries.Rue)
end


function events.entity_init()
    -- load config
    migrateConfig()
    if host:isHost() then
        overridePlayerName = safeConfigLoad("overridePlayerName", overridePlayerName)
        pings.setNamePlate(overridePlayerName)
        setAutoSkin(safeConfigLoad("autoSkinEnabled", autoSkinEnabled))
        pings.setSkin(safeConfigLoad("currentSkin", currentSkin.key))
    end
end

function events.tick()
    sleep.setInBed(player:getPose() == "SLEEPING")
    tickBlink()

    if not autoSkinEnabled then return end
    if skinUpdateTimer < skinUpdateInterval then
        skinUpdateTimer = skinUpdateTimer + 1
        return
    else
        skinUpdateTimer = 0
    end

    updateAutoSkin()
end