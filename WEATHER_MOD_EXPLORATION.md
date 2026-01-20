# BAR Weather Mod - Repository Exploration Summary

## Overview
This is the Beyond All Reason (BAR) repository - an open-source RTS game built on the Recoil RTS Engine. You can create weather effects that are both cosmetic (visual) and functional (affecting gameplay).

## Repository Structure

### Core Directories
- **`luarules/`** - Server-side (synced) Lua code
  - `gadgets/` - Game mechanics gadgets (482+ files for various systems)
  - `main.lua` - Entry point for LuaRules

- **`luaui/`** - Client-side (unsynced) Lua code for UI and rendering
  - `gadgets/` - UI gadgets and drawing code
  - `Widgets/` - Widget system for UI

- **`effects/`** - Particle effect definitions (atmospherics.lua, explosions, etc.)
  
- **`gamedata/`** - Game configuration
  - `unitdefs.lua` - Unit definitions
  - `weapondefs.lua` - Weapon definitions
  - `modrules.lua` - Game rule settings
  - `resources.lua` - Resource definitions

- **`common/`** - Shared Lua utilities and libraries
  - `wind_functions.lua` - Wind calculation functions
  - Various utility files (math, string, table functions)

### Key Files
- `modinfo.lua` - Mod metadata (name, version, description)
- `modoptions.lua` - Game options players can configure
- `init.lua` - Shared initialization included by all Lua environments

---

## Existing Systems You Can Leverage

### 1. **Wind System** (`common/wind_functions.lua`)
- Already has wind min/max from `Game.windMin` and `Game.windMax`
- Functions: `getAverageWind()`, `isGoodWind()`, `isWindDisabled()`, `getWindRisk()`
- This is prime material for weather system integration

### 2. **Effect System** (`effects/atmospherics.lua` - 1539 lines!)
- Uses particle effects via `CSimpleParticleSystem`
- Defines visual effects with configurable parameters:
  - Color maps
  - Particle counts, lifespans, sizes, speeds
  - Gravity, drag, rotation
  - Air, ground, water, and underwater effects
- **Perfect for rain, snow, fog, dust storm visuals**

### 3. **Gadget System** (`luarules/gadgets/`)
- Server-side gadgets for game logic (synced code)
- Client-side gadgets for rendering (unsynced code)
- Examples to learn from:
  - `map_lava.lua` - Environmental effects
  - `map_sun_handler.lua` - Visual atmosphere handling
  - `map_custom_map_tidal.lua` - Tidal mechanics (similar to weather)
  - `unit_waterspeedmultiplier.lua` - Water affecting units
  - `unit_water_depth_damage.lua` - Water affecting gameplay

### 4. **Mod Options** (`modoptions.lua` - 2490 lines)
- Allows players to configure game settings
- Can add weather intensity, type, etc.
- Format: key, name, description, type, default value, min/max, items

### 5. **Unit/Weapon Systems** (`gamedata/`)
- Units have customizable parameters (speed, damage, range, etc.)
- Can modify unit behavior based on weather via gadgets
- Resource costs and production rates can be affected

---

## Weather Mod Implementation Ideas

### **Cosmetic (Visual) Components:**
1. **Particle effects** for:
   - Rain/snow (downward particles)
   - Fog/mist (floating clouds)
   - Dust storms
   - Lightning/thunder effects
   - Aurora/atmospheric glows

2. **Atmospheric changes:**
   - Adjust lighting/shadows
   - Modify water appearance
   - Sky/skybox effects
   - Ground/terrain visual effects

3. **Unit visual effects:**
   - Add weather-specific appearance (wet, snowy, dusty units)
   - Trail effects in storms

### **Functional (Gameplay) Components:**
1. **Unit mechanics:**
   - Reduce ground unit speed in rain/mud
   - Reduce air unit vision/radar in fog
   - Increase air unit speed in strong winds
   - Damage or slow movement in extreme weather

2. **Resource gathering:**
   - Reduce metal extraction in bad weather
   - Affect energy production (wind generators better in storms, solar worse)
   - Slow construction rates

3. **Map attributes:**
   - Increase/decrease water levels with rain
   - Create slippery terrain
   - Affect pathfinding difficulty
   - Change traversability

4. **Combat effects:**
   - Reduce weapon accuracy in bad visibility
   - Wind affecting projectile trajectories
   - Lightning strikes as random events
   - Fog providing hiding spots

---

## Key Technologies

### **Lua Environments (Different Execution Contexts):**
- `LuaRules` - Server-side, synced (affects gameplay)
- `LuaUI` - Client-side, unsynced (rendering/visuals)
- Both available in gadgets

### **Spring Engine APIs:**
- `Game.*` - Game state (windMin, windMax, mapSizeX/Z, etc.)
- `Spring.*` - Engine functions (GetUnits, AddUnit, SetUnitVelocity, etc.)
- `gl.*` - OpenGL rendering functions (textures, shaders, effects)
- `UnitDefs[unitDefID]` - Unit definition data

### **Effect Definition Format:**
Effects are defined as Lua tables with particle system configurations. Multiple emitter types available (CEGs).

---

## Architecture for Your Weather Mod

### Suggested Structure:
```
luarules/gadgets/
  └── weather_system.lua          # Main synced logic
  └── weather_effects.lua         # Particle effect triggers
  
luaui/gadgets/
  └── weather_ui.lua              # Weather UI (optional)
  └── weather_visual_fx.lua       # Client-side rendering
  
effects/
  └── weather_effects_*.lua       # New effect definitions

gamedata/
  └── (Optional) weather_modrules.lua

common/
  └── weather_functions.lua       # Shared utility functions

modoptions.lua (extend)           # Add weather options
```

---

## Next Steps for Implementation

1. **Choose weather types:** Rain, snow, fog, dust storms, wind gusts, etc.
2. **Define effect files:** Create CEG particle effect definitions
3. **Create main gadget:** Server-side logic for weather progression
4. **Add client gadget:** Visual rendering tied to weather state
5. **Modify unit behavior:** Adjust speeds, production, etc. per weather
6. **Add mod options:** Let players configure weather intensity
7. **Test and balance:** Ensure gameplay remains fair and fun

---

## Existing Similar Systems to Reference:
- `map_lava.lua` - Environmental hazard
- `map_waterlevel.lua` - Dynamic water mechanics
- `map_custom_map_tidal.lua` - Time-based environmental changes
- `gaia_critters.lua` - Spawning entities
- `fx_atmosphere.lua` - Atmospheric effects

These are excellent reference implementations for weather system architecture!
