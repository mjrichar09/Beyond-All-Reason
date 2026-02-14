# Visual Effects Debugging - Quick Fixes

## Issue #1: Enable Full Debug Output

**File:** [luaui/gadgets/weather_visual_effects.lua](luaui/gadgets/weather_visual_effects.lua#L33)

**Change this:**
```lua
local CONFIG = {
    UPDATE_INTERVAL = 5,           -- Update weather effects every N frames
    PARTICLE_SCALE = 1.0,          -- Scale factor for all particle effects
    MAX_PARTICLES = 5000,          -- Maximum concurrent particles
    DEBUG = true,                  -- Enable debug logging  <-- ALREADY TRUE, keep it
}
```

This will output detailed debug messages to Spring console.

---

## Issue #2: Force Immediate Weather Testing

**File:** [luarules/gadgets/weather_system.lua](luarules/gadgets/weather_system.lua#L40)

**Current:**
```lua
local CONFIG = {
    GAME_SPEED = 30,              -- Default game speed (frames per second)
    MIN_INTERVAL = 120,           -- Minimum seconds between weather events
    MAX_INTERVAL = 900,           -- Maximum seconds between weather events (15 minutes)
    INITIAL_DELAY = 10,           -- Initial delay at game start (10 seconds)
    UPDATE_INTERVAL = 10,         -- Check for weather trigger every N frames
    DEBUG = false,                -- Log weather transitions
}
```

**For testing, change to:**
```lua
local CONFIG = {
    GAME_SPEED = 30,              -- Default game speed (frames per second)
    MIN_INTERVAL = 3,             -- Minimum seconds between weather events (WAS: 120)
    MAX_INTERVAL = 5,             -- Maximum seconds between weather events (WAS: 900)
    INITIAL_DELAY = 2,            -- Initial delay at game start (WAS: 10)
    UPDATE_INTERVAL = 5,          -- Check for weather trigger every N frames (WAS: 10)
    DEBUG = true,                 -- Log weather transitions (WAS: false)
}
```

This makes weather change every 3-5 seconds so you can test quickly.

**IMPORTANT:** Change back before release!

---

## Issue #3: Add Enhanced Particle Debug Logging

**File:** [luaui/gadgets/weather_visual_effects.lua](luaui/gadgets/weather_visual_effects.lua#L176)

**Add this at the beginning of GenerateWeatherParticles():**

```lua
local function GenerateWeatherParticles()
    if visualState.particleCount == 0 then
        if CONFIG.DEBUG then
            Spring.Echo("[Weather Visuals DEBUG] GenerateWeatherParticles: particleCount is 0, returning")
        end
        return
    end
    
    -- ADD THIS SECTION:
    Spring.Echo(string.format(
        "[PARTICLE DEBUG] Frame %d | Target: %d particles | Current: %d | Weather: %s | Intensity: %.2f",
        Spring.GetGameFrame(),
        visualState.particleCount,
        #visualState.activeParticles,
        visualState.currentWeather,
        visualState.weatherIntensity
    ))
    -- END ADDITION
    
    local weatherData = weatherUtils.GetWeatherData(visualState.currentWeather)
    -- ... rest of function
```

---

## Issue #4: Verify DrawWorld is Actually Rendering

**File:** [luaui/gadgets/weather_visual_effects.lua](luaui/gadgets/weather_visual_effects.lua#L280)

**Current DrawWorld function:**
```lua
function gadget:DrawWorld()
    if CONFIG.DEBUG then
        Spring.Echo("[Weather Visuals DEBUG] DrawWorld called. Weather=" .. visualState.currentWeather .. " Particles=" .. #visualState.activeParticles)
    end
    -- ...
```

**Add color output to verify rendering:**
```lua
function gadget:DrawWorld()
    if CONFIG.DEBUG then
        Spring.Echo("[Weather Visuals DEBUG] DrawWorld called. Weather=" .. visualState.currentWeather .. " Particles=" .. #visualState.activeParticles)
    end
    
    if visualState.currentWeather == "clear_skies" or #visualState.activeParticles == 0 then
        if CONFIG.DEBUG and #visualState.activeParticles > 0 then
            Spring.Echo("[Weather Visuals DEBUG] Not drawing: clear_skies or no particles")
        end
        return
    end
    
    if CONFIG.DEBUG then
        Spring.Echo("[Weather Visuals DEBUG] Drawing " .. #visualState.activeParticles .. " particles")
    end
    
    -- ADD THIS - draw test quad to verify rendering works at all
    gl.PushMatrix()
    gl.Translate(Game.mapSizeX / 2, 500, Game.mapSizeZ / 2)
    gl.Color(1, 0, 0, 0.5)  -- Red semi-transparent
    gl.Begin(gl.QUADS)
    gl.Vertex(-100, -100, 0)
    gl.Vertex(100, -100, 0)
    gl.Vertex(100, 100, 0)
    gl.Vertex(-100, 100, 0)
    gl.End()
    gl.PopMatrix()
    -- END TEST CODE - Remove after verification
    
    -- ... rest of rendering code
```

**If you see a red square at map center:**
- ✅ DrawWorld() is being called
- ✅ OpenGL rendering works
- ✅ Issue is with particle logic or the actual particle rendering

**If no red square:**
- ❌ DrawWorld() not being called at all, OR
- ❌ Gadget not loaded, OR
- ❌ GPU/OpenGL issue

---

## Issue #5: Verify Game Rules are Being Set

**File:** [luarules/gadgets/weather_system.lua](luarules/gadgets/weather_system.lua#L127)

**In TriggerWeatherEvent(), add verification:**

```lua
local function TriggerWeatherEvent()
    local currentFrame = GetCurrentFrame()
    
    local allWeatherTypes = weatherUtils.GetAllWeatherTypes()
    local newWeather = allWeatherTypes[math.random(1, #allWeatherTypes)]
    
    weatherState.currentWeather = newWeather
    weatherState.lastEventFrame = currentFrame
    weatherState.nextEventFrame = CalculateNextEventTime()
    weatherState.isWeatherActive = true
    
    weatherState.eventData = {
        type = newWeather,
        startFrame = currentFrame,
        weatherIntensity = 0.5 + math.random() * 0.5,
    }
    
    -- Set game rules
    weatherUtils.SetCurrentWeather(newWeather, weatherState.eventData.weatherIntensity)
    Spring.SetGameRulesParam("weather_frame", currentFrame)
    
    -- ADD VERIFICATION:
    local verifyWeather = Spring.GetGameRulesParam("weather_current")
    local verifyIntensity = Spring.GetGameRulesParam("weather_intensity")
    
    Spring.Echo(string.format(
        "[Weather System VERIFY] Set: %s (%.2f) | Read back: %s (%.2f)",
        newWeather,
        weatherState.eventData.weatherIntensity,
        tostring(verifyWeather),
        tostring(verifyIntensity)
    ))
    
    if verifyWeather ~= newWeather then
        Spring.Echo("[ERROR] Game rule set but read-back mismatch!")
    end
    -- END VERIFICATION
    
    -- ... rest of function
```

---

## Issue #6: Check if weather_utils.lua is Loading

**Add to top of [weather_visual_effects.lua](luaui/gadgets/weather_visual_effects.lua#L24):**

```lua
local gadget = gadget ---@type Gadget

-- ADD THIS DEBUG:
do
    local success, weatherUtils = pcall(function()
        return VFS.Include('common/weather_utils.lua')
    end)
    if not success then
        Spring.Echo("[ERROR] Failed to load weather_utils.lua: " .. tostring(weatherUtils))
        return false
    else
        Spring.Echo("[OK] weather_utils.lua loaded successfully")
    end
end
-- END DEBUG

local weatherUtils = VFS.Include('common/weather_utils.lua')
```

---

## Testing Workflow

1. **Apply Issue #2 changes** (fast weather cycling)
2. **Apply Issue #1** (enable debug - should already be true)
3. **Start a test game**
4. **Open chat** (press **Enter**) and look for `[Weather System]` and `[Weather Visuals]` messages
5. **Run commands** with `/` prefix to test:
   - `/setgamerule weather_current heavy_rain`
   - `/setgamerule weather_intensity 0.9`
6. **With Issue #2 changes, weather should change every 3-5 seconds**
6. **If still no particles:**
   - Apply Issue #4 changes (red square test)
   - Look for the red square at map center
   - This tells you if rendering works at all

---

## Console Command Reference

Run these in Spring console (Ctrl+Enter) anytime:

```lua
-- Check current weather
Spring.Echo(Spring.GetGameRulesParam("weather_current"))

-- Force a weather type
Spring.SetGameRulesParam("weather_current", "heavy_rain")
Spring.SetGameRulesParam("weather_intensity", 0.9)

-- Check game frame
Spring.Echo(Spring.GetGameFrame())

-- Check game speed
Spring.Echo(Game.gameSpeed)

-- List all weather types
local types = {"light_rain", "heavy_rain", "fog", "dust_storm", "wind_gust", "clear_skies"}
for _, t in ipairs(types) do Spring.Echo(t) end
```

---

## Expected Console Output

**First 2-3 seconds (gadget loading):**
```
[Weather Visuals] Client-side weather visualization initialized
[Weather System] Initialized. First weather event in ~2 seconds
```

**After initial delay (weather trigger):**
```
[Weather System] Event triggered: heavy_rain (Intensity: 0.75) | Next event in ~4 seconds
[Weather Visuals] Weather: heavy_rain | Intensity: 0.75 | Particles: 15/3750
```

**Every frame (if DEBUG enabled, lots of output):**
```
[Weather Visuals DEBUG] DrawWorld called. Weather=heavy_rain Particles=156
[Weather Visuals DEBUG] Drawing 156 particles
[Weather Visuals DEBUG] DrawScreen called
[Weather Visuals DEBUG] Drawing overlay: A=0.11
```

---

## If Still Not Working

After applying the above, check:

1. **Spring console for errors** - Look for `[ERROR]` or Lua stack traces
2. **Game options** - Make sure "LuaUI Gadgets" are enabled
3. **Fresh game load** - Sometimes cached code causes issues
4. **Map compatibility** - Try a different, simpler map
5. **GPU driver** - Update graphics drivers

