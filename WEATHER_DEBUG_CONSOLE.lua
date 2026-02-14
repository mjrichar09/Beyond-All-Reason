-- Weather Visual Effects Debugging Script
-- Run this in the Spring Engine console (Ctrl+Enter)
-- Copy and paste each section to diagnose issues

---============================================================================
--- DIAGNOSTIC 1: Check if gadgets are loaded
---============================================================================

-- Look for these messages in console:
-- [Weather Visuals] Client-side weather visualization initialized
-- [Weather System] Initialized. First weather event in ~10 seconds

Spring.Echo("=== DIAGNOSTIC 1: Checking Gadget Status ===")
Spring.Echo("Time to wait for gadgets: ~2-3 seconds after game loads")


---============================================================================
--- DIAGNOSTIC 2: Check current weather state
---============================================================================

-- Run this to see what weather system reports
Spring.Echo("=== DIAGNOSTIC 2: Current Weather State ===")

local weather = Spring.GetGameRulesParam("weather_current") or "NOT SET"
local intensity = Spring.GetGameRulesParam("weather_intensity") or "NOT SET"
local weatherFrame = Spring.GetGameRulesParam("weather_frame") or "NOT SET"
local gameFrame = Spring.GetGameFrame()

Spring.Echo("Current Weather: " .. tostring(weather))
Spring.Echo("Weather Intensity: " .. tostring(intensity))
Spring.Echo("Last Weather Frame: " .. tostring(weatherFrame))
Spring.Echo("Current Game Frame: " .. tostring(gameFrame))
Spring.Echo("Game Speed: " .. tostring(Game.gameSpeed or 30) .. " FPS")

if weather == "clear_skies" or weather == "NOT SET" then
	Spring.Echo("WARNING: Still in clear_skies or weather not initialized")
	Spring.Echo("Wait ~10-15 seconds for first weather event to trigger")
end


---============================================================================
--- DIAGNOSTIC 3: Force trigger a weather event
---============================================================================

-- Run this to manually set weather and see if visuals appear
Spring.Echo("=== DIAGNOSTIC 3: Force Weather Event ===")

Spring.SetGameRulesParam("weather_current", "heavy_rain")
Spring.SetGameRulesParam("weather_intensity", 0.8)
Spring.SetGameRulesParam("weather_frame", Spring.GetGameFrame())

Spring.Echo("Forced weather to: heavy_rain (intensity: 0.8)")
Spring.Echo("Check for visual overlay and particle effects")


---============================================================================
--- DIAGNOSTIC 4: Check weather data validity
---============================================================================

-- Verify that weather_utils.lua loaded correctly
Spring.Echo("=== DIAGNOSTIC 4: Weather Data Validation ===")

-- Note: This checks if the data exists in the client gadget
-- The gadget would need to expose this, so this is for manual verification
Spring.Echo("Weather types should include:")
Spring.Echo("- light_rain")
Spring.Echo("- heavy_rain")
Spring.Echo("- fog")
Spring.Echo("- dust_storm")
Spring.Echo("- wind_gust")
Spring.Echo("- clear_skies")


---============================================================================
--- DIAGNOSTIC 5: Check game map size (affects particle spawn area)
---============================================================================

Spring.Echo("=== DIAGNOSTIC 5: Map Configuration ===")

local mapSizeX = Game.mapSizeX
local mapSizeZ = Game.mapSizeZ

Spring.Echo("Map Size: " .. mapSizeX .. " x " .. mapSizeZ)
Spring.Echo("Particle spawn area should use these boundaries")
Spring.Echo("If very small, particles may spawn outside visible area")


---============================================================================
--- DIAGNOSTIC 6: Test cycle through weather types
---============================================================================

-- Change weather every 3 seconds to test all types
-- Run this and watch console for messages
Spring.Echo("=== DIAGNOSTIC 6: Weather Cycle Test ===")
Spring.Echo("Open LuaUI gadget console to see detailed debug output")
Spring.Echo("Visual effects should transition between:")

local weatherTypes = {
	"light_rain",
	"heavy_rain",
	"fog",
	"dust_storm",
	"wind_gust",
	"clear_skies",
}

local currentIndex = 1
local lastCycleFrame = Spring.GetGameFrame()

-- Schedule weather changes (would need to be in a timer or gadget)
-- For now, manually set each one:
for i, weather in ipairs(weatherTypes) do
	Spring.Echo(i .. ": " .. weather)
end

Spring.Echo("To cycle manually, run each command below at 3-second intervals:")
for i, weather in ipairs(weatherTypes) do
	Spring.Echo('Spring.SetGameRulesParam("weather_current", "' .. weather .. '"); Spring.SetGameRulesParam("weather_intensity", 0.7);')
end


---============================================================================
--- DIAGNOSTIC 7: Check for GL/rendering issues
---============================================================================

Spring.Echo("=== DIAGNOSTIC 7: GPU/Rendering Diagnostics ===")

-- Check if drawing should be happening
Spring.Echo("DrawWorld() should be called every frame")
Spring.Echo("DrawScreen() should be called every frame when overlay active")
Spring.Echo("Check LuaUI gadget debug console for:")
Spring.Echo("  [Weather Visuals DEBUG] DrawWorld called...")
Spring.Echo("  [Weather Visuals DEBUG] DrawScreen called...")


---============================================================================
--- DIAGNOSTIC 8: Manually trigger visual systems
---============================================================================

Spring.Echo("=== DIAGNOSTIC 8: Manual Visual Test ===")

Spring.Echo("If particles still don't show, try:")
Spring.Echo("1. Check if LuaUI gadgets are enabled (options -> interface)")
Spring.Echo("2. Verify 'weather_visual_effects' gadget is active")
Spring.Echo("3. Check for any Lua errors in Spring console")
Spring.Echo("4. Look for OpenGL errors (might indicate GPU incompatibility)")


---============================================================================
--- SUMMARY
---============================================================================

Spring.Echo("=== SUMMARY ===")
Spring.Echo("Expected sequence:")
Spring.Echo("1. Game loads, gadgets initialize (~2-3 sec)")
Spring.Echo("2. Weather system waits 10 seconds, then triggers first event")
Spring.Echo("3. weather_current game rule is set")
Spring.Echo("4. Visual gadget reads the rule and updates visuals")
Spring.Echo("5. Particles spawn/overlay appears in 3D view")
Spring.Echo("")
Spring.Echo("If stuck at any step, check the corresponding diagnostic above")

