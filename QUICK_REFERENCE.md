# Visual Effects Debugging - Quick Reference

## 🚀 Quick Start (30 seconds)

1. Edit [luarules/gadgets/weather_system.lua](luarules/gadgets/weather_system.lua#L40)
2. Change `INITIAL_DELAY = 10` to `INITIAL_DELAY = 2`
3. Change `MIN_INTERVAL = 120` to `MIN_INTERVAL = 3`
4. Change `DEBUG = false` to `DEBUG = true`
5. Save and start game
6. Open console (Ctrl+Enter)
7. Look for `[Weather System]` and `[Weather Visuals]` messages

---

## 📊 Data Flow

```
Synced (LuaRules)          Broadcast          Unsynced (LuaUI)
─────────────────────────────────────────────────────────────
weather_system.lua    ──→  SetGameRulesParam  ──→  weather_visual_effects.lua
  (Triggers events)        (weather_current)       (Renders effects)
                           (weather_intensity)
                ↓
          Common Utilities (weather_utils.lua)
```

---

## 🔍 Key Files

| File | Purpose | Line |
|------|---------|------|
| [luarules/gadgets/weather_system.lua](luarules/gadgets/weather_system.lua) | Triggers weather events | Line 40 (CONFIG) |
| [luaui/gadgets/weather_visual_effects.lua](luaui/gadgets/weather_visual_effects.lua) | Renders particles/overlay | Line 33 (CONFIG) |
| [common/weather_utils.lua](common/weather_utils.lua) | Shared weather data | Line 11+ (WEATHER_TYPES) |

---

## 🎯 Console Commands

```lua
-- Check current weather
Spring.GetGameRulesParam("weather_current")

-- Force weather
Spring.SetGameRulesParam("weather_current", "heavy_rain")
Spring.SetGameRulesParam("weather_intensity", 0.9)

-- Check game time
Spring.GetGameFrame() / 30  -- seconds (at 30 FPS)

-- Check game speed
Game.gameSpeed
```

---

## 📝 Expected Console Output

| What | Where | Message |
|-----|-------|---------|
| **Load** | 0-2s | `[Weather Visuals] Client-side weather visualization initialized` |
| **Init** | 1-2s | `[Weather System] Initialized. First weather event in ~2 seconds` |
| **Event** | ~2-3s | `[Weather System] Event triggered: light_rain (Intensity: 0.75)` |
| **Visual** | ~3-4s | `[Weather Visuals] Weather: light_rain \| Intensity: 0.75 \| Particles: 150/3750` |

---

## ❌ Common Problems

| Problem | Cause | Fix |
|---------|-------|-----|
| No messages | Gadgets not loading | Enable LuaUI gadgets in options |
| No weather | Event not triggering | Check INITIAL_DELAY, wait 10+ sec |
| No visuals | Particles not rendering | Check DrawWorld() - add red square test |
| Lag/stutter | Too many particles | Reduce MAX_PARTICLES or particleIntensity |
| Errors | Code issue | Check Spring_latest.log for details |

---

## 🧪 Quick Diagnostics

```lua
-- Test 1: Is gadget loaded?
-- Look in console for [Weather Visuals] message

-- Test 2: Is weather changing?
Spring.Echo(Spring.GetGameRulesParam("weather_current"))
-- Should change every 3-5 sec (if using test config)

-- Test 3: Is rendering working?
-- Add red square to DrawWorld() - if visible, rendering works

-- Test 4: Force weather manually
Spring.SetGameRulesParam("weather_current", "heavy_rain")
Spring.SetGameRulesParam("weather_intensity", 0.9)
-- Check if overlay/particles appear
```

---

## 📋 Full Debugging Guide

For complete step-by-step guide, see:
- [DEBUGGING_CHECKLIST.md](DEBUGGING_CHECKLIST.md) - Follow-along checklist
- [DEBUG_VISUAL_EFFECTS.md](DEBUG_VISUAL_EFFECTS.md) - Detailed diagnostics
- [VISUAL_EFFECTS_FIXES.md](VISUAL_EFFECTS_FIXES.md) - Code changes to try

---

## 💡 Pro Tips

**Tip 1:** DEBUG = true generates A LOT of console spam. Use if needed, then turn off.

**Tip 2:** Weather events are deterministic across all players (synced code). Visual effects are per-client (unsynced), so each player might see slightly different particles.

**Tip 3:** If stuck in "clear_skies", weather event hasn't triggered yet. Wait or force with console command.

**Tip 4:** Particles are 3D quads. They move with camera but fade based on age, not distance.

**Tip 5:** Overlay color is very subtle (max 15% opacity). If testing, temporarily increase opacity in GetWeatherColorOverlay().

---

## 🎬 Testing Workflow

```
1. Edit CONFIG (INITIAL_DELAY=2, DEBUG=true)
   ↓
2. Start game, open console
   ↓
3. Wait 2-3 seconds for first weather event
   ↓
4. Look for [Weather System] message
   ↓
5. Look for visual effects (overlay + particles)
   ↓
   ✅ YES → Problem solved, clean up CONFIG
   ❌ NO → Continue to diagnostic step 2
   ↓
6. Check weather in console manually
   ↓
7. Check game rules param "weather_current"
   ↓
   ✅ Changing → Problem in visual rendering, add red square test
   ❌ Not changing → Problem in weather system, check weather_system.lua
```

---

## 🛠️ Minimal Fix Checklist

- [ ] Change INITIAL_DELAY to 2
- [ ] Change MIN_INTERVAL to 3
- [ ] Change DEBUG to true
- [ ] Start game
- [ ] Look for console messages
- [ ] Wait 2-3 seconds for first event
- [ ] Look for visuals in 3D view

That's it. If this doesn't work, use the detailed guides.

---

## 📞 When to Ask for Help

Before posting issues, collect:
- [ ] Screenshot of Spring console showing all messages
- [ ] Spring_latest.log file
- [ ] System specs (GPU, driver version)
- [ ] Steps you've tried from [DEBUGGING_CHECKLIST.md](DEBUGGING_CHECKLIST.md)
- [ ] Any error messages (full text, not truncated)

