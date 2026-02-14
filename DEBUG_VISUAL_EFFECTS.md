# Visual Effects Debugging Guide

## Quick Diagnosis Checklist

### 1. **Verify Gadgets Are Loading**
Check the Spring Engine console log for gadget initialization messages:
```
[Weather Visuals] Client-side weather visualization initialized
[Weather System] Initialized. First weather event in ~10 seconds
```

**If missing:**
- Check that gadgets folder has proper permissions
- Verify `weather_visual_effects.lua` is in `luaui/gadgets/`
- Verify `weather_system.lua` is in `luarules/gadgets/`

---

### 2. **Check Weather System is Broadcasting Data**
Look for these debug messages in console (search for "[Weather"):
```
[Weather System] Event triggered: light_rain (Intensity: 0.75)
[Weather Visuals] Weather: light_rain | Intensity: 0.75 | Particles: ...
```

**If not seeing weather events:**
- Game may still be in "clear_skies" - wait ~10+ seconds after game start
- Check `weather_system.lua` line ~120 to verify `TriggerWeatherEvent()` is being called
- Check if `CONFIG.UPDATE_INTERVAL` in `weather_system.lua` is too high

---

### 3. **Enable Full Debug Logging**
Edit [weather_visual_effects.lua](luaui/gadgets/weather_visual_effects.lua#L33) and set:
```lua
local CONFIG = {
    DEBUG = true,  -- Change from false to true
    -- ... other settings
}
```

This will output:
- `[Weather Visuals DEBUG] DrawWorld called...`
- `[Weather Visuals DEBUG] DrawScreen called...`
- `[Weather Visuals DEBUG] Drawing X particles`

---

### 4. **Check Game Rules Parameters**
In the Spring Engine console, run:
```
/weatherinfo
```

Or check directly in Lua console:
```lua
Spring.Echo(Spring.GetGameRulesParam("weather_current"))
Spring.Echo(Spring.GetGameRulesParam("weather_intensity"))
```

Expected output: `light_rain`, `0.75` (or similar values)

---

### 5. **Verify Color Tint is Set Correctly**
Check [weather_utils.lua](common/weather_utils.lua#L205-L213):
```lua
function weatherUtils.GetWeatherColorTint(weatherType)
    local colorTints = {
        light_rain = {0.8, 0.85, 1.0, 1.0},
        heavy_rain = {0.7, 0.75, 0.95, 1.0},
        -- ...
    }
```

If colors look wrong, these RGB values can be adjusted.

---

## Common Issues & Fixes

### **Issue: "clear_skies" Weather Never Changes**
**Cause:** Weather event not being triggered  
**Fix:** 
1. Check `CONFIG.INITIAL_DELAY` in [weather_system.lua](luarules/gadgets/weather_system.lua#L38-L39)
2. Current value: 10 seconds - you should see first weather around 10s into game
3. If still not triggering, check if `gameSpeed` is set too high (may skip frames)

---

### **Issue: Particles Spawning But Not Visible**
**Possible causes:**

1. **Rendering is disabled**
   - Check console for `DrawWorld()` being called
   - Enable DEBUG = true to verify

2. **Particles have zero opacity**
   - Line 301 in `weather_visual_effects.lua`: `opacity = 1.0 - (particle.age / particle.life)`
   - Add debug: `Spring.Echo("Opacity: " .. opacity)`

3. **Particles outside visible map area**
   - Check GetMapBounds() returns correct values
   - Line 177: `x1 = 0, z1 = 0, x2 = Game.mapSizeX, z2 = Game.mapSizeZ`

4. **GL state not properly set**
   - Line 293: `gl.Blending(GL.SRC_ALPHA, GL.ONE)` - additive blend required
   - Check if your GPU supports this blend mode

---

### **Issue: Overlay Color Not Showing**
**Check:**
1. Is overlay opacity > 0?
   - Line 238 in `weather_visual_effects.lua`: `visualState.overlay.a > 0`
2. Is weather intensity > 0?
   - Overlay opacity = `intensity * 0.15` (max 15%)
3. Is `DrawScreen()` being called?
   - Enable DEBUG = true to verify

---

### **Issue: Gadget Not Loading At All**
**Check:**
1. Look for gadget loading errors in console starting with `[ERROR]`
2. Verify Lua syntax with: `luac -p weather_visual_effects.lua`
3. Check if `weather_utils.lua` is being found:
   - `VFS.Include('common/weather_utils.lua')` on line 24

---

## Manual Testing Steps

### Test 1: Force Weather Change in Console
Open Spring console (Ctrl+Enter) and run:
```lua
-- Trigger heavy rain manually
Spring.SetGameRulesParam("weather_current", "heavy_rain")
Spring.SetGameRulesParam("weather_intensity", 0.9)
```

Then wait a few frames. You should see:
- Visual overlay appears (slight blue tint)
- Particles spawn if `particleIntensity` > 0

---

### Test 2: Check Particle Generation
Add this temporary debug code to `GenerateWeatherParticles()`:
```lua
local function GenerateWeatherParticles()
    Spring.Echo("[DEBUG] Called GenerateWeatherParticles")
    Spring.Echo("[DEBUG] particleCount = " .. visualState.particleCount)
    Spring.Echo("[DEBUG] activeParticles = " .. #visualState.activeParticles)
    -- ... rest of function
```

---

### Test 3: Verify Drawing Functions Are Called
Add at start of `DrawWorld()`:
```lua
function gadget:DrawWorld()
    Spring.Echo("[CALLED] DrawWorld at frame " .. Spring.GetGameFrame())
    -- ... rest of function
```

Check console - should see this printed every frame if weather is active.

---

## Data Flow Diagram

```
[weather_system.lua - SYNCED]
    |
    v
Spring.SetGameRulesParam("weather_current", type)
Spring.SetGameRulesParam("weather_intensity", value)
    |
    v
[weather_visual_effects.lua - UNSYNCED]
    |
    +---> UpdateWeatherInfo() - reads game rules
    |
    +---> GetWeatherColorTint() - fetches from weather_utils.lua
    |
    +---> GenerateWeatherParticles() - creates particle objects
    |
    +---> DrawScreen() - draws color overlay
    |
    +---> DrawWorld() - renders particles as quads
```

---

## Performance Considerations

If you see stuttering or lag:

1. **Too many particles:**
   - Reduce `CONFIG.MAX_PARTICLES` in [weather_visual_effects.lua](luaui/gadgets/weather_visual_effects.lua#L34)
   - Current: 5000 - try reducing to 2000

2. **Draw calls too expensive:**
   - Each particle = 1 draw call (gl.QUADS)
   - With 5000 particles = 5000 draw calls
   - Reduce `particleIntensity` in [weather_utils.lua](common/weather_utils.lua#L22, #L38)

3. **UpdateWeatherInfo called too often:**
   - Increase `CONFIG.UPDATE_INTERVAL` in [weather_visual_effects.lua](luaui/gadgets/weather_visual_effects.lua#L33)
   - Currently every 5 frames, could be every 10

---

## Files Involved

- **Synced (LuaRules):**
  - [luarules/gadgets/weather_system.lua](luarules/gadgets/weather_system.lua) - Triggers weather events
  - [luarules/gadgets/weather_effects.lua](luarules/gadgets/weather_effects.lua) - Game rule modifiers

- **Unsynced (LuaUI):**
  - [luaui/gadgets/weather_visual_effects.lua](luaui/gadgets/weather_visual_effects.lua) - Rendering
  - [common/weather_utils.lua](common/weather_utils.lua) - Shared utilities

---

## Next Steps

1. **Enable DEBUG = true** and run a test game
2. **Check console** for messages from both weather systems
3. **Look for specific error messages** - they usually point to root cause
4. **Run the manual tests** above to isolate which part is failing
5. **Post error messages** from console when asking for help

