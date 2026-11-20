local wheel = require("scripts.wheel")

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

-- sleeping
local isSleeping = false
local wheelSleeping = false
local appliedSleeping = nil
local function updateSkinSleepingTexture()
    local sleeping = isSleeping or wheelSleeping
    if appliedSleeping == sleeping then return end
    appliedSleeping = sleeping
    models.model.root.Head:setPrimaryTexture("CUSTOM", textures[sleeping and (currentSkin.texture .. "_sleep") or currentSkin.texture])
end
local function setSkinSleeping(enabled)
    isSleeping = enabled
    updateSkinSleepingTexture()
end
function pings.setSkinSleeping(enabled)
    wheelSleeping = enabled
    updateSkinSleepingTexture()
end
local function setSkin(skin)
    if currentSkin == skin then return end
    currentSkin = skin
    models.model.root:setPrimaryTexture("CUSTOM", textures[skin.texture])
    appliedSleeping = nil
    updateSkinSleepingTexture()
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
    if host:isHost() then
        overridePlayerName = safeConfigLoad("overridePlayerName", overridePlayerName)
        pings.setNamePlate(overridePlayerName)
        setAutoSkin(safeConfigLoad("autoSkinEnabled", autoSkinEnabled))
        pings.setSkin(safeConfigLoad("currentSkin", currentSkin.key))
    end
end

function events.tick()
    setSkinSleeping(player:getPose() == "SLEEPING")

    if not autoSkinEnabled then return end
    if skinUpdateTimer < skinUpdateInterval then
        skinUpdateTimer = skinUpdateTimer + 1
        return
    else
        skinUpdateTimer = 0
    end

    updateAutoSkin()
end