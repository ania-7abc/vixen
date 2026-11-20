local util = {}

---@param tbl table
---@param x any
---@return boolean
function util.contains(tbl, x)
    for _, v in pairs(tbl) do
        if v == x then return true end
    end
    return false
end

---@param anim Animation
function util.forceStartAnim(anim)
    if anim:isPlaying() then
        anim:stop()
    end
    anim:play()
end

---@param sound Minecraft.soundID
function pings.playerSound(sound)
    sounds:playSound(sound, player:getPos())
end

return util
