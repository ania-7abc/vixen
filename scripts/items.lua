require("scripts.util")

local options = require("scripts.options")

local itemsExtra = {
    "minecraft:emerald",
    "minecraft:feather",
    "minecraft:egg",
    "minecraft:totem_of_undying",
    "minecraft:shears",
    "minecraft:flint_and_steel",
    "minecraft:redstone",
    "minecraft:milk_bucket",
    "minecraft:book",
    -- ADD YOUR ITEMS HERE
}

local toolsExtra = {
    "minecraft:trident",
    "minecraft:mace",
    "minecraft:fishing_rod",
    "minecraft:bone",
    "minecraft:stick",
    "minecraft:bow",
    -- ADD YOUR TOOLS HERE
}

local drinkExtra = {
    "minecraft:potion",
    "minecraft:milk_bucket",
}

local function isMouthTool(item)
    if item:isTool() then return true end
    if item.id:find("_sword") then return true end
    return contains(toolsExtra, item.id)
end

local function isMouthItem(item)
    if item:isFood() then return true end
    return contains(itemsExtra, item.id)
end

local function isMouthDrink(item)
    return contains(drinkExtra, item.id)
end

local function hasItem(item)
    return item and item.id ~= "minecraft:air"
end

-- with the setting on, a lone item in either hand goes to the mouth while sprinting
local function singleMouthOffhand(sprinting)
    if not options.allInMouth or not sprinting then return nil end
    local main = hasItem(player:getHeldItem())
    local off = hasItem(player:getHeldItem(true))
    if main and not off then return false end
    if off and not main then return true end
    return nil
end

local function mouthActions(item, sprinting, force)
    local drink = isMouthDrink(item)
    if force then
        return {
            drink = drink,
            item = not drink and not isMouthTool(item),
            tool = not drink and isMouthTool(item),
        }
    end
    return {
        drink = drink,
        item = isMouthItem(item) and not drink,
        tool = isMouthTool(item) and sprinting,
    }
end

local mouthIP = models.model.root.Head.MouthIPivot
local mouthTP = models.model.root.Head.MouthTPivot
local mouthDP = models.model.root.Head.MouthDPivot
local rightIP = models.model.root.RightArm.RightItemPivot
local leftIP = models.model.root.LeftArm.LeftItemPivot

local function setParentIfChanged(part, parent)
    if part:getParentType() ~= parent then
        part:setParentType(parent)
    end
end

local function isHandBusy(heldItem, sprinting, offhand)
    if offhand ~= nil and singleMouthOffhand(sprinting) == offhand then return true end
    return isMouthItem(heldItem) or isMouthDrink(heldItem) or (isMouthTool(heldItem) and sprinting)
end

function events.render()
    local leftHanded = player:isLeftHanded()
    local mainHandItem = player:getHeldItem()
    local offHandItem = player:getHeldItem(true)

    local sprinting = player:isSprinting()
    local single = singleMouthOffhand(sprinting)
    local mainMouth = mouthActions(mainHandItem, sprinting, single == false)
    local offMouth = mouthActions(offHandItem, sprinting, single == true)
    local mainHandPivot = leftHanded and "LeftItemPivot" or "RightItemPivot"
    local offHandPivot = leftHanded and "RightItemPivot" or "LeftItemPivot"

    local mainBusy = isHandBusy(mainHandItem, sprinting, false)
    local offBusy = isHandBusy(offHandItem, sprinting, true)
    local rightBusy = leftHanded and offBusy or mainBusy
    local leftBusy = leftHanded and mainBusy or offBusy
    setParentIfChanged(rightIP, rightBusy and "None" or "RightItemPivot")
    setParentIfChanged(leftIP, leftBusy and "None" or "LeftItemPivot")

    -- prefer the main hand, then the off hand; drinks win over food and tools
    local function mouthPivot(action)
        if mainMouth[action] then return mainHandPivot end
        if offMouth[action] then return offHandPivot end
        return "None"
    end
    local drinkParent = mouthPivot("drink")
    local itemParent = drinkParent == "None" and mouthPivot("item") or "None"
    local toolParent = drinkParent == "None" and itemParent == "None" and mouthPivot("tool") or "None"

    setParentIfChanged(mouthDP, drinkParent)
    setParentIfChanged(mouthIP, itemParent)
    setParentIfChanged(mouthTP, toolParent)
end

return {
    isHandBusy = isHandBusy,
}
