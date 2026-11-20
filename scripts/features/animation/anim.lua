-- Public animation facade. The driver, graph and pose control live in
-- driver.lua / tree.lua / poses.lua.

local lib = require("scripts.lib.aurianims")
local constants = require("scripts.features.animation.constants")
local driver = require("scripts.features.animation.driver")
local tree = require("scripts.features.animation.tree")
local poses = require("scripts.features.animation.poses")
local events = require("scripts.core.events")

local controller = lib.new()

driver.setup(controller)
local refs = tree.setup(controller)
local api = poses.setup(controller, refs.wheelSwapNode, refs.modelAnims)

events.on("entity_init", function ()
    animations.model.sprint:setSpeed(constants.sprintAnimSpeedMult)
end)

return api
