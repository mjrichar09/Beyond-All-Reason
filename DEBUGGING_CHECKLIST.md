# Visual Effects Debugging - Step-by-Step Checklist

## STEP 1: Prepare for Testing
- [ ] Open [DEBUG_VISUAL_EFFECTS.md](DEBUG_VISUAL_EFFECTS.md) in your editor
- [ ] Open [VISUAL_EFFECTS_FIXES.md](VISUAL_EFFECTS_FIXES.md) in your editor
- [ ] Have Spring Engine open and ready to start a game
- [ ] Have Spring console open during testing (Ctrl+Enter to toggle)

---

## STEP 2: Enable Fast Weather Cycling (for quick testing)

Edit [luarules/gadgets/weather_system.lua](luarules/gadgets/weather_system.lua#L40):

```lua
-- CHANGE FROM:
local CONFIG = {
    MIN_INTERVAL = 120,           
    MAX_INTERVAL = 900,           
    INITIAL_DELAY = 10,           
    DEBUG = false,
}

-- CHANGE TO:
local CONFIG = {
    MIN_INTERVAL = 3,             -- Quick testing
    MAX_INTERVAL = 5,             -- Quick testing
    INITIAL_DELAY = 2,            -- Quick testing
    DEBUG = true,
}
```

**Save the file.**

---

## STEP 3: Start a Test Game

1. Launch Spring Engine / BAR
2. Start a new game (any map, singleplayer)
3. Open chat (press **Enter** to see messages, prefix commands with `/`)
4. Let game load for ~2-3 seconds

---

## STEP 4: Watch for Initialization Messages

**Expected in console:**
```
[Weather Visuals] Client-side weather visualization initialized
[Weather System] Initialized. First weather event in ~2 seconds
```

**What to do if you see these:** ✅ Continue to STEP 5

**What to do if you DON'T see these:** ❌ Go to TROUBLESHOOTING: "Gadgets Not Loading"

---

## STEP 5: Wait for First Weather Event

Wait ~2-3 seconds then look for:
```
[Weather System] Event triggered: light_rain (Intensity: 0.75) | Next event in ~4 seconds
[Weather Visuals] Weather: light_rain | Intensity: 0.75 | Particles: ...
```

**What to do if you see these:** ✅ Continue to STEP 6

**What to do if you DON'T see these:** ❌ Go to TROUBLESHOOTING: "No Weather Events"

---

## STEP 6: Look for Visual Effects

Watch the 3D game view and look for:

- ✅ **Color overlay** - Slight tint (blue for rain, brown for dust, etc.)
- ✅ **Particles** - Small fading elements floating in the air
- ✅ **Weather transitions** - Effects changing every 3-5 seconds

**What to do if you see effects:** 🎉 PROBLEM SOLVED - See CLEANUP section

**What to do if you DON'T see effects:** ❌ Continue to STEP 7

---

## STEP 7: Manual Console Testing

Copy and paste into Spring console:

```lua
Spring.SetGameRulesParam("weather_current", "heavy_rain")
Spring.SetGameRulesParam("weather_intensity", 0.9)
```

**Check console for:**
```
[Weather System VERIFY] Set: heavy_rain (0.90) | Read back: heavy_rain (0.90)
[Weather Visuals] Weather: heavy_rain | Intensity: 0.90 | Particles: ...
```

**What to do if console accepts the command:** ✅ Continue to STEP 8

**What to do if you get errors:** ❌ Go to TROUBLESHOOTING: "Lua Errors"

---

## STEP 8: Check for Rendering

From [VISUAL_EFFECTS_FIXES.md](VISUAL_EFFECTS_FIXES.md#issue-4-verify-drawworld-is-actually-rendering), 
add a test red square to DrawWorld().

**Expected result:**
- If you see a red square at the map center: ✅ Rendering works, particles logic broken
- If no red square appears: ❌ Rendering is broken or gadget not loading

---

## STEP 9: Apply Further Diagnostics

If still not working, apply these debug additions:
- [ ] Add particle debug logging (Issue #3 in FIXES)
- [ ] Add game rule verification (Issue #5 in FIXES)
- [ ] Add weather_utils load check (Issue #6 in FIXES)

Re-test after each change.

---

## TROUBLESHOOTING

### ❌ Gadgets Not Loading

**Symptoms:** No `[Weather Visuals]` or `[Weather System]` messages

**Checks:**
1. [ ] Are LuaUI Gadgets enabled? (Options → Interface → LuaUI Gadgets)
2. [ ] Check for gadget load errors in console (search for `[ERROR]`)
3. [ ] Verify files exist:
   - [ ] [luaui/gadgets/weather_visual_effects.lua](luaui/gadgets/weather_visual_effects.lua)
   - [ ] [luarules/gadgets/weather_system.lua](luarules/gadgets/weather_system.lua)

**Fix:**
- If gadgets folder has permission issues, verify folder ownership
- Try fresh Spring restart
- Check for syntax errors: run `luac -p weather_visual_effects.lua`

---

### ❌ No Weather Events

**Symptoms:** `[Weather System]` shows initialization but no event triggers

**Checks:**
1. [ ] Did you change INITIAL_DELAY to 2 seconds?
2. [ ] Check current frame: `Spring.Echo(Spring.GetGameFrame())`
3. [ ] Check next event frame: Should be low initially

**Fix:**
- If game is paused, unpause it (weather events don't trigger while paused)
- Verify CONFIG changes were saved to weather_system.lua
- Try forcing: `Spring.SetGameRulesParam("weather_current", "light_rain")`

---

### ❌ Rendering Issues

**Symptoms:** Weather changes show in console but nothing visible in game

**Checks:**
1. [ ] Did red square test (Step 8) show a square? 
   - YES: Rendering works, particles problem
   - NO: Rendering broken

**If rendering broken:**
- [ ] Check GPU driver version (may be outdated)
- [ ] Check for GL errors in console
- [ ] Try simpler map (some maps may have rendering issues)

**If rendering works but no particles:**
- [ ] Check `visualState.particleCount` - should be > 0
- [ ] Check `#visualState.activeParticles` - should be increasing
- [ ] Verify particle generation logic in GenerateWeatherParticles()

---

### ❌ Lua Errors

**Symptoms:** Console shows error messages when setting weather

**Check:**
- Copy full error message from console
- Look for file path and line number
- Common issues:
  - `attempt to index nil` - weather_utils not loaded
  - `attempt to call field` - missing Spring API function
  - Syntax errors - check file encoding (should be UTF-8 without BOM)

---

### ❌ Low Performance

**Symptoms:** Game stutters when weather active

**Fixes:**
1. Reduce MAX_PARTICLES in weather_visual_effects.lua:
   ```lua
   MAX_PARTICLES = 2000,  -- Was: 5000
   ```

2. Reduce particle intensity in weather_utils.lua:
   ```lua
   light_rain = {
       visual = {
           particleIntensity = 0.15,  -- Was: 0.3
       }
   }
   ```

3. Increase UPDATE_INTERVAL in weather_visual_effects.lua:
   ```lua
   UPDATE_INTERVAL = 10,  -- Was: 5
   ```

---

## CLEANUP - After Confirming it Works

Change [luarules/gadgets/weather_system.lua](luarules/gadgets/weather_system.lua#L40) back:

```lua
local CONFIG = {
    MIN_INTERVAL = 120,           -- Restore
    MAX_INTERVAL = 900,           -- Restore  
    INITIAL_DELAY = 10,           -- Restore
    DEBUG = false,                -- Restore
}
```

Remove any test code you added (like red square test).

---

## Success Confirmation

After cleanup, do final test:
1. [ ] Start game
2. [ ] Wait ~12-15 seconds
3. [ ] Visuals should appear
4. [ ] Weather should change every 10-15 minutes (normal interval)
5. [ ] No console errors

If all ✅, visual effects are working!

---

## Still Not Working?

Create a game test session with:
1. [ ] Screenshot of console with all messages
2. [ ] Spring_latest.log file (in Spring folder)
3. [ ] List of changes you made
4. [ ] GPU/Driver info
5. [ ] System specs

Then post in: [WEATHER_MOD_EXPLORATION.md](WEATHER_MOD_EXPLORATION.md) issues section

