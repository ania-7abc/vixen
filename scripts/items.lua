require("scripts.util")

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

local function mouthActions(item, sprinting)
    local drink = isMouthDrink(item)
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

local function isHandBusy(heldItem, sprinting)
    return isMouthItem(heldItem) or isMouthDrink(heldItem) or (isMouthTool(heldItem) and sprinting)
end

function events.render()
    local leftHanded = player:isLeftHanded()
    local mainHandItem = player:getHeldItem()
    local offHandItem = player:getHeldItem(true)
    local rightHandItem = leftHanded and offHandItem or mainHandItem
    local leftHandItem = leftHanded and mainHandItem or offHandItem

    local sprinting = player:isSprinting()
    local mainMouth = mouthActions(mainHandItem, sprinting)
    local offMouth = mouthActions(offHandItem, sprinting)
    local mainHandPivot = leftHanded and "LeftItemPivot" or "RightItemPivot"
    local offHandPivot = leftHanded and "RightItemPivot" or "LeftItemPivot"

    setParentIfChanged(rightIP, isHandBusy(rightHandItem, sprinting) and "None" or "RightItemPivot")
    setParentIfChanged(leftIP, isHandBusy(leftHandItem, sprinting) and "None" or "LeftItemPivot")

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
