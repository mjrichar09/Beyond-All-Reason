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
	
	-- Calculate the speed modifier based on unit type
	local speedMult = 1.0
	if unitDef.canfly then
		speedMult = effects.airUnitSpeedMult or 1.0
	else
		speedMult = effects.unitSpeedMult or 1.0
	end
	
	-- Apply modifier through game rules param
	if speedMult ~= 1.0 then
		weatherUtils.SetUnitWeatherModifier(unitID, "unitSpeedMult", speedMult)
	end
end

--- Apply vision modifier to unit
local function ApplyVisionModifier(unitID, unitDefID, weatherData)
	if not weatherData or not weatherData.effects or not weatherData.effects.visionMult then
		return
	end
	
	local visionMult = weatherData.effects.visionMult
	if visionMult ~= 1.0 then
		weatherUtils.SetUnitWeatherModifier(unitID, "visionMult", visionMult)
	end
end

--- Apply damage modifier for environmental hazards
local function ApplyEnvironmentalDamage(unitID, unitDefID, weatherData)
	if not weatherData or not weatherData.effects or not weatherData.effects.unitDamageTaken then
		return
	end
	
	local damageMult = weatherData.effects.unitDamageTaken
	if damageMult ~= 1.0 then
		weatherUtils.SetUnitWeatherModifier(unitID, "unitDamageTaken", damageMult)
	end
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
	local intensityFactor = effectState.weatherIntensity
	
	-- Store resource modifiers in game rules params for economy system to read
	if effects.metalIncMult and effects.metalIncMult ~= 1.0 then
		Spring.SetGameRulesParam("weather_metalIncMult", effects.metalIncMult)
	end
	
	if effects.energyIncMult and effects.energyIncMult ~= 1.0 then
		Spring.SetGameRulesParam("weather_energyIncMult", effects.energyIncMult)
	end
	
	-- Solar energy modifier (affects energy buildings)
	if effects.solarEnergyMult and effects.solarEnergyMult ~= 1.0 then
		Spring.SetGameRulesParam("weather_solarEnergyMult", effects.solarEnergyMult)
	end
	
	-- Wind energy boost (affects wind generators)
	if effects.windEnergyBoost and effects.windEnergyBoost ~= 1.0 then
		Spring.SetGameRulesParam("weather_windEnergyBoost", effects.windEnergyBoost)
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
	
	-- Store terrain modifiers in game rules for pathfinding/movement systems
	if weatherData.effects.unitSpeedMult then
		Spring.SetGameRulesParam("weather_terrainMovementMult", weatherData.effects.unitSpeedMult)
	end
	
	-- Radar effects (dust storms disable radar)
	if weatherData.effects.radarMult then
		Spring.SetGameRulesParam("weather_radarMult", weatherData.effects.radarMult)
	end
	
	-- Projectile deviation (wind affects accuracy)
	if weatherData.effects.projectileDeviationMult then
		Spring.SetGameRulesParam("weather_projectileDeviationMult", weatherData.effects.projectileDeviationMult)
	end
end

---============================================================================
--- Weather Damage System
---============================================================================

--- Apply weather-based damage to units
local function ApplyWeatherDamage()
	if effectState.currentWeather ~= "dust_storm" then
		return
	end
	
	-- Dust storm causes periodic damage to exposed units
	local allUnits = Spring.GetAllUnits()
	local damagePerFrame = 0.01 * effectState.weatherIntensity  -- Very small per-frame damage
	
	for _, unitID in ipairs(allUnits) do
		if Spring.GetUnitCurrentBuildPower(unitID) == 0 then  -- Skip units being constructed
			local currentHealth = Spring.GetUnitHealth(unitID)
			if currentHealth and currentHealth > 0 then
				local newHealth = currentHealth - damagePerFrame
				if newHealth <= 0 then
					Spring.DestroyUnit(unitID, false, false)
				end
			end
		end
	end
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
		
		-- Apply all weather effects
		ApplyWeatherEffectsToUnits()
		ApplyWeatherEffectsToResources()
		ApplyTerrainEffects()
		ApplyWeatherDamage()
		
		if CONFIG.EFFECT_DEBUG then
			Spring.Echo("[Weather Effects] Applied effects for: " .. effectState.currentWeather ..
				" (Intensity: " .. string.format("%.2f", effectState.weatherIntensity) .. ")")
		end
	end
end

--- Called when a unit is created
function gadget:UnitCreated(unitID, unitDefID, teamID)
	local weatherData = GetWeatherData()
	if weatherData and weatherData.intensity > 0 then
		-- Apply current weather effects to newly created units
		ApplyUnitSpeedModifier(unitID, unitDefID, weatherData)
		ApplyVisionModifier(unitID, unitDefID, weatherData)
		ApplyEnvironmentalDamage(unitID, unitDefID, weatherData)
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
	
	-- Check if any weather effects apply to this unit
	if weatherUtils.AffectsMovement(effectState.currentWeather) then
		return true
	end
	
	if weatherUtils.AffectsVision(effectState.currentWeather) then
		return true
	end
	
	if weatherData.effects.unitDamageTaken and weatherData.effects.unitDamageTaken > 1.0 then
		return true
	end
	
	return false
end

--- Get weather impact analysis for a unit type
function gadget:GetWeatherImpactForUnit(unitDefID)
	return weatherUtils.AnalyzeWeatherImpact(unitDefID)
end

function gadget:Shutdown()
	Spring.Echo("[Weather Effects] Synced weather gameplay effects shutting down")
end
