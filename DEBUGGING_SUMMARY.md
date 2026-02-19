# Weather Effects - Debugging Implementation Summary

## What's Been Done

Following the DEBUGGING_CHECKLIST.md, I've implemented **STEP 2** (Fast Weather Cycling) with enhanced diagnostics:

### Changes Made:

1. **Enabled Fast Weather Cycles** (`luarules/gadgets/weather_system.lua`):
   - `INITIAL_DELAY = 2` seconds (vs 10 normal)
   - `MIN_INTERVAL = 3` seconds (vs 120 normal)
   - `MAX_INTERVAL = 5` seconds (vs 900 normal)
   - `DEBUG = true`

2. **Added Verification Logging**:
   - Weather system now logs what it SET and what it READ BACK from game rules
   - Use to verify game rules communication works

3. **Added Test Red Square** (DrawWorld):
   - Draws red square at map center every frame
   - Proves rendering pipeline works if you see it
   - Located in `luaui/gadgets/weather_visual_effects.lua`

4. **Enhanced Particle Diagnostics**:
   - Logs particle count calculations
   - Logs spawning attempts with current total
   - Shows CEG effect names being used
   - Shows color overlay RGBA values

5. **Enhanced CEG Spawning Diagnostics**:
   - Logs CEG effect name and camera position when spawning
   - Shows which effect it's trying to use

---

## How to Test (Following Checklist Steps 3-8)

### STEP 3: Launch Game
1. Start Spring Engine / BAR
2. Start a new game (any map, singleplayer)
3. Open console: **Ctrl+Enter**

### STEP 4: Verify Initialization
**Look for:**
```
[Weather Visuals] Client-side weather visualization initialized
[Weather System] Initialized. First weather event in ~2 seconds
```

**Then see:**
```
Initial weather from game rules: clear_skies | intensity: 0
```

✅ **If you see these:** Gadgets are loading. Continue to STEP 5.
❌ **If you DON'T see these:** Check Options → Interface → LuaUI Gadgets is ON, then restart.

---

### STEP 5: Wait for First Event (~2-3 seconds)
**Look for:**
```
[Weather System] Event triggered: light_rain (Intensity: 0.75) | Next event in ~5 seconds
[Weather System VERIFY] Set: light_rain (0.75) | Read back: light_rain (0.75)
```

✅ **If you see VERIFY message:** Game rules communication works! Continue to STEP 6.
❌ **If no VERIFY message:** Game rules aren't being set properly. See TROUBLESHOOTING.

---

### STEP 6: Look for Visual Effects in Game View
Look at the 3D game area for:
- ✅ **A RED SQUARE at map center** - This appears every frame
- ✅ **Slight color tint** - Blue for rain, brown for dust, etc.
- ✅ **Particles floating** - Small point-like elements

**What you should see:**
```
[Weather Visuals TEST] Drew red square at map center
[Weather Visuals DEBUG] Drawing overlay: RGBA(0.80, 0.85, 1.00, 0.11)
[Weather Visuals DEBUG] Drawing 50 particles
```

---

### STEP 7: Diagnostic Test - Can You See the Red Square?

**YES, I see the red square:**
- ✅ Rendering pipeline works!
- ❌ But particles not showing?
  - Check console for: `Particles: X/Y` - If Y=0, particle calculation broken
  - Check: `UpdateWeatherVisuals: light_rain particleIntensity=...` - Shows calculated count
  - See TROUBLESHOOTING: "Particles spawning but not rendering"

**NO, I don't see the red square:**
- ❌ GPU/rendering is broken
- Check: Is LuaUI Gadgets enabled? Restart Spring?
- Try different map
- Check Spring_latest.log for GL errors

**NO console messages at all:**
- ❌ Gadgets not loading
- Options → Interface → check "LuaUI Gadgets" is ON
- Restart Spring

---

### STEP 8: Manual Console Test

Paste into Spring console:
```lua
Spring.SetGameRulesParam("weather_current", "heavy_rain")
Spring.SetGameRulesParam("weather_intensity", 0.9)
```

**Expect to see in console:**
```
[Weather Visuals] Weather: heavy_rain | Intensity: 0.90
[Weather Visuals DEBUG] UpdateWeatherVisuals: heavy_rain particleIntensity=0.8 ...
[Weather Visuals DEBUG] Drawing overlay: RGBA(0.70, 0.75, 0.95, 0.135)
[Weather Visuals DEBUG] Drawing X particles
[Weather Visuals TEST] Drew red square at map center
```

**And in game:**
- RED SQUARE visible at map center
- BLUE-tinted overlay on screen
- Particles should start appearing

---

## Diagnostic Flowchart

```
Do you see console messages?
├─ NO → Check: Options → Interface → LuaUI Gadgets = ON? → Restart Spring
└─ YES ↓
   Do you see [Weather System VERIFY]?
   ├─ NO → Game rules communication broken → See TROUBLESHOOTING: "Game Rules"
   └─ YES ↓
      Do you see RED SQUARE at map center?
      ├─ NO → Rendering broken or gadget doesn't run DrawWorld()
      │       Try: Different map, update GPU drivers
      └─ YES ↓
         Do you see color tint overlay?
         ├─ NO → DrawScreen() not working → DEBUG flag broken?
         │       Check: visualState.overlay.a value
         └─ YES ✅ Effects should be visible!
```

---

## Debugging Output Reference

| Message | Meaning | What to Check |
|---------|---------|---------------|
| `[Weather System VERIFY]` | Game rules set and read | Communication working ✅ |
| `Particles: 0/0` | No particles | particleIntensity broken ❌ |
| `Particles: 50/100` | Spawning particles | Rendering pipeline |
| `Drew red square` | Rendering works | If no square, GPU broken |
| `Drawing overlay: RGBA(...)` | Color tint being applied | Check A (alpha) > 0 |
| `Attempting to spawn CEG: X` | CEG effect being used | Check effect name valid |
| `No CEG mapping for weather` | Effect name wrong | GetWeatherCEGPath() broken |

---

## Common Issues & Fixes

### Red Square Not Visible
**Possible causes:**
1. LuaUI Gadgets disabled → Enable in Options
2. Gadget crashing → Check for Lua errors in console
3. GPU driver issue → Update drivers or try different map

**Test:** Paste in console:
```lua
Spring.Echo("RED SQUARE TEST")
```
If you see message but no square, rendering is broken.

### Particles Show in Console But Not in Game
**Check:**
- `Particles: X/Y` shows X > 0?
- `Drawing X particles` shows numbers increasing?
- RED SQUARE visible?

**If red square visible but no particles:**
- Particles exist but DrawWorld() particle rendering code broken
- Check gl.* rendering calls aren't erroring

### No Color Tint
**Check:**
- Does `visualState.overlay.a` value > 0?
- ShowDrawScreen() being called?

**Fix:** Paste in console:
```lua
Spring.SetGameRulesParam("weather_intensity", 0.9)
```
Should instantly apply tint if working.

---

## After Confirming It Works

**ONLY do this after you see effects working!**

Edit `luarules/gadgets/weather_system.lua`:

```lua
local CONFIG = {
    MIN_INTERVAL = 120,           -- Back to 2 minutes
    MAX_INTERVAL = 900,           -- Back to 15 minutes  
    INITIAL_DELAY = 10,           -- Back to 10 seconds
    DEBUG = false,                -- Turn off spam
}
```

Then remove the test red square code from `luaui/gadgets/weather_visual_effects.lua` DrawWorld().

---

## Need More Help?

Check these files for context:
- [DEBUGGING_CHECKLIST.md](DEBUGGING_CHECKLIST.md) - Full official checklist
- [VISUAL_EFFECTS_FIXES.md](VISUAL_EFFECTS_FIXES.md) - Known issues & fixes
- [DEBUG_VISUAL_EFFECTS.md](DEBUG_VISUAL_EFFECTS.md) - Debug techniques
