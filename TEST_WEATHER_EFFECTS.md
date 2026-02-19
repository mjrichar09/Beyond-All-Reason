# Weather Effects Testing Guide

## ✅ Setup Complete

I've implemented the first 2 steps of the debugging checklist:

**STEP 1:** Prepared debugging files
**STEP 2:** Enabled fast weather cycling in `luarules/gadgets/weather_system.lua`:
- `INITIAL_DELAY = 2` seconds
- `MIN_INTERVAL = 3` seconds  
- `MAX_INTERVAL = 5` seconds
- `DEBUG = true` (verbose logging)

**Added Verification:** Game now logs `[Weather System VERIFY]` messages showing what weather was set and what was read back from game rules.

**Added Test Red Square:** DrawWorld() now draws a red square at map center (when DEBUG=true) to verify rendering works.

---

## 🎮 How to Test

### Start a Game:
1. Launch Spring Engine / BAR
2. Start a new game (any map, singleplayer)  
3. **Open console:** Ctrl+Enter

### Expected Console Messages (in order):

**~Frame 0-1:**
```
[Weather Visuals] Client-side weather visualization initialized
Initial weather from game rules: clear_skies | intensity: 0
[Weather System] Initialized. First weather event in ~2 seconds
```

**~2-3 seconds in:**
```
[Weather System] Event triggered: light_rain (Intensity: 0.75) | Next event in ~5 seconds
[Weather System VERIFY] Set: light_rain (0.75) | Read back: light_rain (0.75)
[Weather Visuals] Weather: light_rain | Intensity: 0.75 | Particles: 0/112
[Weather Visuals DEBUG] UpdateWeatherVisuals: light_rain particleIntensity=0.3 weatherIntensity=0.75 calculated=112 final=112
[Weather Visuals DEBUG] GenerateWeatherParticles: Generating particles, target=112, current=0
[Weather Visuals DEBUG] Spawning 23 particles (frame 0, total=0)
[Weather Visuals DrawScreen DEBUG] Called. Overlay A=0.1125
[Weather Visuals TEST] Drew red square at map center
[Weather Visuals DEBUG] Drawing overlay: RGBA(0.80, 0.85, 1.00, 0.11)
[Weather Visuals DEBUG] Attempting to spawn CEG: mistycloud at camera pos (9234, 500, 8127)
[Weather Visuals DEBUG] Drawing 23 particles
```

Then repeats every 3-5 seconds with different weather types.

**Key Indicators:**
- `[Weather System VERIFY]` shows game rules being set and read back
- `particleIntensity=` shows visual strength of effect
- `Particles: X/Y` shows X active particles out of Y target
- `[Weather Visuals TEST]` shows red square test rendering
- `[Weather Visuals DEBUG] Attempting to spawn CEG` shows atmospheric effect spawning
- `[Weather Visuals DEBUG] Drawing X particles` shows particles being rendered

---

## 🔍 Diagnostic Results

### If you see the Red Square ✅
- **Rendering works!** 
- Effects not showing means particle generation or CEG spawning is broken
- Check for CEG messages in console

### If you DON'T see Red Square ❌
- GPU/rendering is broken or gadget not loading
- Check: Are LuaUI Gadgets enabled? (Options → Interface → LuaUI Gadgets)
- Restart Spring

### If you see NO console messages ❌
- Check: Are LuaUI Gadgets enabled? (Options → Interface → LuaUI Gadgets)
- Verify files exist:
  - `luaui/gadgets/weather_visual_effects.lua`
  - `luarules/gadgets/weather_system.lua`

---

## 📊 Expected Visual Effects

When weather triggers, you should see:

| Weather Type | Visual Effect |
|---|---|
| `light_rain` | Blue/misty color tint + particles |
| `heavy_rain` | Strong blue tint + many particles |
| `fog` | Brownish fog-like overlay |
| `dust_storm` | Orange/brown dust clouds |
| `wind_gust` | Light purple mist |

---

## Manual Test (if auto-trigger not working)

Paste into console:
```lua
Spring.SetGameRulesParam("weather_current", "heavy_rain")
Spring.SetGameRulesParam("weather_intensity", 0.9)
```

Should see:
```
[Weather Visuals] Weather: heavy_rain | Intensity: 0.90 | Particles: ...
[Weather Visuals TEST] Drew red square at map center
RED SQUARE SHOULD APPEAR at map center
Slight BLUE tint overlay on screen
```

---

## After Testing: Reset to Normal Intervals

When effects are confirmed working, edit `luarules/gadgets/weather_system.lua`:

```lua
local CONFIG = {
    MIN_INTERVAL = 120,           -- Back to 2 minutes
    MAX_INTERVAL = 900,           -- Back to 15 minutes
    INITIAL_DELAY = 10,           -- Back to 10 seconds
    DEBUG = false,                -- Turn off spam logging
}
```

Then remove the test red square from `luaui/gadgets/weather_visual_effects.lua` DrawWorld().

---

## Troubleshooting

### No particles showing even with red square visible?
- Check CONFIG.MAX_PARTICLES value in weather_visual_effects.lua (should be 5000)
- Check GenerateWeatherParticles() is being called
- Verify visualState.particleCount > 0 in debug messages

### CEG effects not visible?
- Check GetWeatherCEGPath() returns valid effect names
- Verify atmospherics.lua has those effects defined
- Try forcing a CEG: `Spring.SpawnCEG("mistycloud", 5000, 500, 5000)`

### Game stutters a lot?
- Reduce MAX_PARTICLES to 2000
- Increase UPDATE_INTERVAL to 10 frames
- Disable DEBUG logging
