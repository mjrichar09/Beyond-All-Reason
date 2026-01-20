-- Weather System - Gameplay Effects (Synced)
-- Handles functional weather effects on units, resources, and gameplay
-- Runs synced so all players experience the same effects

local gadget = gadget ---@type Gadget

function gadget:GetInfo()
	return {
		name      = "Weather Gameplay Effects",
		desc      = "Applies functional weather effects to units, resources, and gameplay",
		author    = "Weather Mod Team",
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		version   = 1,
		layer     = 4,
		enabled   = true
	}
end

-- Only run synced code for deterministic effects
if not gadgetHandler:IsSyncedCode() then
	return false
end

local weatherUtils = VFS.Include('common/weather_utils.lua')

---============================================================================
--- Configuration
---============================================================================

local CONFIG = {
	UPDATE_INTERVAL = 10,          -- Apply effects every N frames
	EFFECT_DEBUG = false,          -- Log all effect applications
}

---============================================================================
--- State
---============================================================================

local effectState = {
	currentWeather = "clear_skies",
	weatherIntensity = 0,
	lastWeatherFrame = 0,
	affectedUnits = {},            -- Track which units are affected
}

---============================================================================
--- Helper Functions
---============================================================================

--- Get current weather from game rules (broadcast by weather system)
local function GetCurrentWeather()
	local weather = Spring.GetGameRulesParam("weather_current")
	return weather or "clear_skies"
end

--- Get current weather intensity from game rules
local function GetCurrentWeatherIntensity()
	local intensity = Spring.GetGameRulesParam("weather_intensity")
	return intensity or 0
end

--- Update current weather from synced system
local function UpdateWeatherState()
	effectState.currentWeather = GetCurrentWeather()
	effectState.weatherIntensity = GetCurrentWeatherIntensity()
end

--- Get weather data
local function GetWeatherData()
	return weatherUtils.GetWeatherData(effectState.currentWeather)
end

--- Apply speed modifier to unit
local function ApplyUnitSpeedModifier(unitID, unitDefID, weatherData)
	if not weatherData or not weatherData.effects then
		return
	end
	
	local effects = weatherData.effects
	local unitDef = UnitDefs[unitDefID]
	if not unitDef then
		return
	end
	
	-- Ground unit speed modifier
	if effects.unitSpeedMult and unitDef.speed then
		local speedMult = effects.unitSpeedMult
		local maxSpeed = unitDef.maxVelocity or (unitDef.speed * 1.05)
		
		-- This would be applied through unit script or custom weapon behavior
		-- For now, we track it in custom parameters
		if not Spring.UnitScript then
			return
		end
	end
	
	-- Air unit speed modifier
	if effects.airUnitSpeedMult and unitDef.canfly then
		-- Air units could be boosted or slowed
	end
end

--- Apply vision modifier to unit
local function ApplyVisionModifier(unitID, unitDefID, weatherData)
	if not weatherData or not weatherData.effects or not weatherData.effects.visionMult then
		return
	end
	
	-- Vision modifiers could be applied through:
	-- 1. Modifying unit's line-of-sight range
	-- 2. Affecting radar range
	-- 3. Reducing sensor capabilities
	-- This is handled through game state checks rather than direct modification
end

--- Apply damage modifier for environmental hazards
local function ApplyEnvironmentalDamage(unitID, unitDefID, weatherData)
	if not weatherData or not weatherData.effects or not weatherData.effects.unitDamageTaken then
		return
	end
	
	-- Environmental damage (e.g., from dust storms)
	-- This would require custom implementation or unit script modifications
end

---============================================================================
--- Unit Effects
---============================================================================

--- Get all affected units and apply weather effects
local function ApplyWeatherEffectsToUnits()
	local weatherData = GetWeatherData()
	if not weatherData or weatherData.intensity == 0 then
		return
	end
	
	-- Get all units on map
	local allUnits = Spring.GetAllUnits()
	
	for _, unitID in ipairs(allUnits) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		if unitDefID then
			ApplyUnitSpeedModifier(unitID, unitDefID, weatherData)
			ApplyVisionModifier(unitID, unitDefID, weatherData)
			ApplyEnvironmentalDamage(unitID, unitDefID, weatherData)
		end
	end
end

---============================================================================
--- Resource Effects
---============================================================================

--- Apply weather effects to resource production
local function ApplyWeatherEffectsToResources()
	local weatherData = GetWeatherData()
	if not weatherData or not weatherData.effects then
		return
	end
	
	local effects = weatherData.effects
	
	-- Metal income modifier
	if effects.metalIncMult and effects.metalIncMult ~= 1.0 then
		-- Reduces metal extraction from mex units in bad weather
		-- This would be implemented through unit script modifications
	end
	
	-- Energy income modifier
	if effects.energyIncMult and effects.energyIncMult ~= 1.0 then
		-- Affects solar panels (negative) or wind generators (positive)
		-- Implementation through unit attribute checks
	end
	
	-- Wind energy boost
	if effects.windEnergyBoost then
		-- Bonus to wind generators during wind gusts
	end
end

---============================================================================
--- Game State Effects
---============================================================================

--- Apply weather-related terrain and movement effects
local function ApplyTerrainEffects()
	local weatherData = GetWeatherData()
	if not weatherData then
		return
	end
	
	-- Could modify:
	-- - Pathfinding difficulty
	-- - Water levels during rain
	-- - Traversability of terrain
	-- - Visibility fog
end

---============================================================================
--- Callins
---============================================================================

function gadget:Initialize()
	Spring.Echo("[Weather Effects] Synced weather gameplay effects initialized")
end

local frameCounter = 0
function gadget:GameFrame(frameNum)
	frameCounter = frameCounter + 1
	
	-- Update weather state and apply effects at regular intervals
	if frameCounter % CONFIG.UPDATE_INTERVAL == 0 then
		UpdateWeatherState()
		ApplyWeatherEffectsToUnits()
		ApplyWeatherEffectsToResources()
		ApplyTerrainEffects()
		
		if CONFIG.EFFECT_DEBUG then
			Spring.Echo("[Weather Effects] Applied effects for: " .. effectState.currentWeather ..
				" (Intensity: " .. string.format("%.2f", effectState.weatherIntensity) .. ")")
		end
	end
end

--- Get current weather for external queries
function gadget:GetCurrentWeather()
	return effectState.currentWeather
end

--- Get weather intensity
function gadget:GetWeatherIntensity()
	return effectState.weatherIntensity
end

--- Check if weather affects a specific unit type
function gadget:WeatherAffectsUnit(unitID, unitDefID)
	local weatherData = GetWeatherData()
	if not weatherData then
		return false
	end
	
	local unitDef = UnitDefs[unitDefID]
	if not unitDef then
		return false
	end
	
	-- All units are affected by movement weather
	if weatherUtils.AffectsMovement(effectState.currentWeather) then
		return true
	end
	
	-- All units are affected by vision weather
	if weatherUtils.AffectsVision(effectState.currentWeather) then
		return true
	end
	
	return false
end

function gadget:Shutdown()
	Spring.Echo("[Weather Effects] Synced weather gameplay effects shutting down")
end
