# Weather System - Implementation Guide

## Overview

The weather system provides a global, synchronized weather event trigger with both cosmetic and functional effects. Weather events occur at random intervals between 2-15 minutes after the first event. The first weather event is triggered at a configurable delay from game start (default: 60 seconds / 1 minute).

## System Architecture

### Core Components

#### 1. **Weather System** (`luarules/gadgets/weather_system.lua`)
**Synced Code** - Manages the global weather trigger and timing

- **Responsibility:**
  - Track and trigger weather events at random intervals
  - Select random weather type when triggered
  - Broadcast global weather state to other gadgets via GameRulesParams
  - Manage synced weather state visible to all players

- **Key Functions:**
  ```lua
  GetWeatherState()           -- Get full current weather state (gadget API)
  GetCurrentWeather()         -- Get current weather type (gadget API)
  GetWeatherIntensity()       -- Get intensity 0.0-1.0 (gadget API)
  GetTimeUntilNextEvent()     -- Seconds until next weather event (gadget API)
  GetAvailableWeatherEvents() -- List of possible weather types (gadget API)
  
  -- State is also broadcast via GameRulesParams:
  -- Spring.GetGameRulesParam("weather_current")   -- Current weather type
  -- Spring.GetGameRulesParam("weather_intensity") -- Current intensity (0.0-1.0)
  -- Spring.GetGameRulesParam("weather_frame")     -- Frame of last event
  ```

- **Weather Event Types:**
  - `light_rain` - Minimal effects
  - `heavy_rain` - Major vision and speed reduction
  - `fog` - Vision and radar penalty
  - `dust_storm` - Visibility and damage effects
  - `wind_gust` - Air unit boost, projectile deviation
  - `clear_skies` - No effects

#### 2. **Weather Utilities** (`common/weather_utils.lua`)
**Shared Code** - Available to all Lua environments

- **Responsibility:**
  - Define weather types and their properties
  - Provide modifiers for units, resources, and gameplay
  - Utility functions for weather calculations

- **Weather Type Properties:**
  ```lua
  name           -- Display name
  description    -- UI description
  intensity      -- 0.0-1.0 severity level
  effects        -- Modifiers table (unitSpeedMult, visionMult, etc.)
  visual         -- Visual parameters (particleIntensity, fogDensity)
  ```

- **Key Functions:**
  ```lua
  ApplyWeatherModifier(value, weatherType, modifierKey)
  GetWeatherData(weatherType)
  IsSevereWeather(weatherType)
  AffectsVision(weatherType)
  AffectsMovement(weatherType)
  AffectsProduction(weatherType)
  ```
Query weather state from GameRulesParams (broadcast by weather system)
  - Apply modifiers to units, resources, and terrain
  - Calculate and apply environmental damage
  - Coordinate effects across all players

- **Integration Method:**
  - Reads `weather_current`, `weather_intensity`, and `weather_frame` from GameRulesParams
  - No direct dependency on weather system gadget (decoupled via GameRulesParams)
- **Responsibility:**
  - Monitor weather state from weather system
  - Apply modifiers to units, resources, and terrain
  - Calculate and apply environmental damage
  - Coordinate effects across all players

- **Effects Applied:**
  - Unit movement speed modifiers
  - Visionweather state from GameRulesParams (broadcast by weather system)
  - Render particle effects locally
  - Apply visual overlays and color tints
  - Handle weather-specific animations

- **Integration Method:**
  - Reads `weather_current` and `weather_intensity` from GameRulesParams
  - No direct dependency on weather system gadget (decoupled via GameRulesParams)

#### 4. **Weather Visual Effects** (`luaui/gadgets/weather_visual_effects.lua`)
**Unsynced Code** - Client-side cosmetic rendering

- **Responsibility:**
  - Query synced weather state
  - Render particle effects locally
  - Apply visual overlays and color tints
  - Handle weather-specific animations

- **Visual Elements:**
  - Particle effects (rain, snow, dust, fog)
  - Color tints and lighting adjustments
  - Screen overlays and post-processing
  - Weather duration UI feedback

## Timing System

### Event Trigger Logic

```
Game Start (Frame 0)
    ↓
Initialize: Next Event = Frame 0 + random(120-900 seconds)
    ↓
Wait until current frame >= next event frame
    ↓
Trigger Weather Event:
  1. Select random weather type
  2. Set weather intensity (0.5-1.0)
  3. Calculate next event time (random 120-900 seconds from now)
  4. Notify all systems
    ↓
(Cycle repeats)
```

### Timing Constants

- **MIN_INTERVAL:** 120 seconds (2 minutes) - minimum between weather events
- **MAX_INTERVAL:** 900 seconds (15 minutes) - maximum between weather events
- **INITIAL_DELAY:** 60 seconds (1 minute) - initial delay at game start
- **GAME_SPEED:** Default 30 frames/second
- **UPDATE_INTERVAL:** Check every 10 frames (0.33 seconds)

### Frame-Based Calculation

Times are tracked in **frames** for deterministic behavior across all players:

```lua
-- Convert seconds to frames
local frames = seconds * gameSpeed

-- At 30 FPS:
-- 2 minutes  = 120 seconds = 3,600 frames
-- 15 minutes = 900 seconds = 27,000 frames

-- Event triggers when: currentFrame >= nextEventFrame
```

## Weather Event Data Structure

When a weather event occurs:

```lua
weatherState.eventData = {
  type = "heavy_rain",              -- Weather type
  startFrame = 15000,               -- Frame when event triggered
  weatherIntensity = 0.75,          -- Intensity 0.0-1.0
}
```

**Intensity** varies each event:
- Provides flavor for repeated weather types
- Affects magnitude of all modifiers
- Used for visual intensity scaling
- Random 0.5-1.0 on each trigger

## Modifier System

Weather effects are applied as multipliers to base values:

```lua
-- Example: Heavy rain affects unit speed
baseSpeed = unitDef.maxVelocity  -- e.g., 5 units/frame

weatherMult = weatherData.effects.unitSpeedMult  -- 0.85
actualSpeed = baseSpeed * weatherMult  -- 4.25 units/frame

-- Multiple modifiers can stack:
finalSpeed = baseSpeed * speedMult * intensityMult
```

### Available Modifiers

- `unitSpeedMult` - Ground unit movement speed
- `airUnitSpeedMult` - Air unit movement speed
- `visionMult` - Line-of-sight range
- `radarMult` - Radar range
- `metalIncMult` - Metal extraction rate
- `energyIncMult` - Energy production rate
- `windEnergyBoost` - Wind generator bonus
- `projectileDeviationMult` - Projectile spread
- `unitDamageTaken` - Incoming damage multiplier

## Integration Points

### For Other Gadgets

Query weather state via GameRulesParams (decoupled, no gadgetHandler required):
```lua
local currentWeather = Spring.GetGameRulesParam("weather_current") or "clear_skies"
local intensity = Spring.GetGameRulesParam("weather_intensity") or 0
local weatherFrame = Spring.GetGameRulesParam("weather_frame") or 0
```

Or use the gadget API if you have a reference:
```lua
local weatherSystem = gadgetHandler:FindGadget("Weather System")
local state = weatherSystem:GetWeatherState()
```

### For Unit Behavior

Modify unit behavior based on weather:
```lua
local weatherData = weatherUtils.GetWeatherData(currentWeather)
local speedMult = weatherData.effects.unitSpeedMult or 1.0
local newSpeed = baseSpeed * speedMult
```

### For UI

Display weather information:
```lua
local timeUntilNext = weatherSystem:GetTimeUntilNextEvent()
local weatherTypes = weatherSystem:GetAvailableWeatherEvents()
```

## Configuration

### Enable/Disable Gadgets

Edit `luarules/gadgets.lua` to enable/disable individual gadgets:
```lua
{"weather_system.lua", {active = true}},
{"weather_effects.lua", {active = true}},
```

### Adjust Timing

Modify `CONFIG` in `weather_system.lua`:
```lua
local CONFIG = {
  INITIAL_DELAY = 60,    -- Seconds until first weather event
  MIN_INTERVAL = 120,    -- Minimum seconds between events
  MAX_INTERVAL = 900,    -- Maximum seconds between events
  GAME_SPEED = 30,       -- Frames per second
}
```

### Adjust Weather Types

Add or modify weather types in `common/weather_utils.lua`:
```lua
weatherUtils.WEATHER_TYPES = {
  new_weather = {
    name = "New Weather",
    description = "Description here",
    intensity = 0.5,
    effects = {
      unitSpeedMult = 0.95,
      visionMult = 0.98,
      -- ... other effects
    },
    visual = {
      particleIntensity = 0.3,
      fogDensity = 0.1,
    },
  },
  -- ...
}
```

## Debugging

### Enable Debug Logging

Set `CONFIG.EFFECT_DEBUG = true` in `weather_effects.lua`:
```lua
local CONFIG = {
  EFFECT_DEBUG = true,  -- Log all effect applications
}
```

### Console Output

The system logs to Spring console:
```
[Weather] System initialized. First weather event in ~180 seconds
[Weather] Event triggered: heavy_rain (Intensity: 0.82) | Next event in ~450 seconds
[Weather Effects] Applied effects for: heavy_rain (Intensity: 0.82)
```

### Query System State

In console:
```lua
local ws = gadgetHandler:FindGadget("Weather System")
Spring.Echo("Current weather: " .. ws:GetCurrentWeather())
Spring.Echo("Intensity: " .. ws:GetWeatherIntensity())
Spring.Echo("Next event in: " .. ws:GetTimeUntilNextEvent() .. " seconds")
```

## Extension Points

### Adding New Weather Types

1. Define in `weather_utils.lua` WEATHER_TYPES
2. Add to gadget's WEATHER_EVENTS table
3. Implement effects in `weather_effects.lua`
4. Add visual effects in `weather_visual_effects.lua`

### Adding Custom Effects

Create a new gadget that queries weather state:
```lua
local weatherSystem = gadgetHandler:FindGadget("Weather System")
local weather = weatherSystem:GetCurrentWeather()
-- Apply your custom logic
```

### Performance Considerations

- Weather checks every 10 frames (~0.33 seconds)
- Effects applied every 10 frames (can be adjusted)
- Minimal overhead: only queries synced state
- Scales with unit count for effect application

## Known Limitations & Future Work

- Unit speed/vision modifiers need integration with unit script system
- CEG particle effects not yet integrated (hooks prepared)
- Environmental damage not yet implemented
- Terrain modification (water levels, traversability) requires map integration
- Client prediction for weather effects

## Testing Checklist

- [ ] Weather system initializes at game start
- [ ] First event occurs within 2-15 minutes
- [ ] Events trigger at random intervals
- [ ] All weather types can be selected
- [ ] Weather state is synced across players
- [ ] Effects are applied and removed correctly
- [ ] No desync between clients
- [ ] Console logging works correctly
- [ ] Performance is acceptable
