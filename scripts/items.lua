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

local mouthIP = models.model.root.Head.MouthIPivot
local mouthTP = models.model.root.Head.MouthTPivot
local mouthDP = models.model.root.Head.MouthDPivot
local rightIP = models.model.root.RightArm.RightItemPivot
local leftIP = models.model.root.LeftArm.LeftItemPivot
local enderIP = models.model.root.Body.EnderPivot.EnderItemPivot

local function setParentIfChanged(part, parent)
    if part:getParentType() ~= parent then
        part:setParentType(parent)
    end
end

local function isHandBusy(heldItem, sprinting)
    return isMouthItem(heldItem) or isMouthDrink(heldItem) or heldItem:isBlockItem() or (isMouthTool(heldItem) and sprinting)
end

function events.tick()
    local leftHanded = player:isLeftHanded()
    local mainHandItem = player:getHeldItem()
    local offHandItem = player:getHeldItem(true)
    local rightHandItem = leftHanded and offHandItem or mainHandItem
    local leftHandItem = leftHanded and mainHandItem or offHandItem

    local item = isMouthItem(mainHandItem)
    local tool = isMouthTool(mainHandItem)
    local drink = isMouthDrink(mainHandItem)
    local block = mainHandItem:isBlockItem() or offHandItem:isBlockItem()
    local sprinting = player:isSprinting()
    local mainHandPivot = leftHanded and "LeftItemPivot" or "RightItemPivot"
    local offHandPivot = leftHanded and "RightItemPivot" or "LeftItemPivot"

    local blockHand = mainHandItem:isBlockItem() and mainHandPivot or (offHandItem:isBlockItem() and offHandPivot or "None")
    enderIP:setParentType(blockHand)

    setParentIfChanged(rightIP, isHandBusy(rightHandItem, sprinting) and "None" or "RightItemPivot")
    setParentIfChanged(leftIP, isHandBusy(leftHandItem, sprinting) and "None" or "LeftItemPivot")

    mouthDP:setParentType(drink and mainHandPivot or "None")
    mouthIP:setParentType(item and not drink and mainHandPivot or "None")
    mouthTP:setParentType(tool and sprinting and mainHandPivot or "None")
end