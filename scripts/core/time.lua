-- Shared timing helpers.
-- Gameplay timers are counted in ticks; animation envelopes use system time.

local time = {}

---@param min integer
---@param max integer
---@return integer
function time.randomDelay(min, max)
    return math.random(min, max)
end

--- A countdown timer with an optional counting-up mode (used by the snore timer).
local Timer = {}
Timer.__index = Timer

---@param min integer
---@param max integer
---@param value integer?
---@return table
function time.newTimer(min, max, value)
    return setmetatable({
        min = min,
        max = max,
        value = value or math.random(min, max),
    }, Timer)
end

--- Fixed-interval counting timer, starting at zero.
---@param interval integer
---@return table
function time.newInterval(interval)
    return setmetatable({ min = interval, max = interval, value = 0 }, Timer)
end

--- Decrement only; call sites reset at the same point as the original code
--- so the shared RNG stream is consumed in the original order.
---@return boolean true when the delay elapsed
function Timer:down()
    self.value = self.value - 1
    return self.value <= 0
end

---@param interval integer?
---@return boolean true when the interval elapsed
function Timer:up(interval)
    self.max = interval or self.max
    if self.value < self.max then
        self.value = self.value + 1
        return false
    end
    self.value = 0
    return true
end

function Timer:reset()
    self.value = math.random(self.min, self.max)
end

function Timer:clear()
    self.value = 0
end

--- Make the timer elapse on the next tick (used when auto skin is enabled).
function Timer:fill()
    self.value = self.max
end

---@return number seconds since system start
function time.now()
    return client:getSystemTime() / 1000
end

---@param t number
---@param duration number
---@return number
function time.envelope(t, duration)
    local phase = math.clamp(t / duration, 0, 1)
    return math.sin(phase * math.pi) ^ 2
end

return time
