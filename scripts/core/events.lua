-- Single dispatcher for Figura events.
-- Features register callbacks with events.on(name, fn); this file is the only
-- place that assigns handlers to Figura's global events API.

local callbacks = {}

local function dispatch(name, ...)
    local result
    for _, func in ipairs(callbacks[name] or {}) do
        local value = func(...)
        -- cancellable events (mouse_press, on_play_sound, ...) chain like vanilla
        if value ~= nil then result = value end
    end
    return result
end

local bus = {}

---@param name string
---@param func function
function bus.on(name, func)
    if not callbacks[name] then callbacks[name] = {} end
    table.insert(callbacks[name], func)
end

-- These assignments target the global Figura `events` API on purpose.
function events.entity_init(...) return dispatch("entity_init", ...) end
function events.tick(...) return dispatch("tick", ...) end
function events.render(...) return dispatch("render", ...) end
function events.mouse_press(...) return dispatch("mouse_press", ...) end
function events.on_play_sound(...) return dispatch("on_play_sound", ...) end

return bus
