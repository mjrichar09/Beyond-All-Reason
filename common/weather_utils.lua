-- Weather System - Shared utilities
-- Common functions and constants for weather system
-- Available to all Lua environments (LuaRules, LuaUI, LuaParser, etc.)

VFS.Include('common/numberfunctions.lua')

local weatherUtils = {}

---============================================================================
--- Weather Event Type Definitions
---============================================================================

weatherUtils.WEATHER_TYPES = {
	light_rain = {
		name = "Light Rain",
		description = "Light precipitation - slightly reduces unit speed and vision",
		intensity = 0.3,
		effects = {
			unitSpeedMult = 0.95,
			visionMult = 0.95,
			metalIncMult = 0.95,
			solarEnergyMult = 0.8,
		},
		visual = {
			particleIntensity = 0.3,
			fogDensity = 0.1,
		},
	},
	heavy_rain = {
		name = "Heavy Rain",
		description = "Heavy precipitation - significantly reduces unit speed, vision, radar and production",
		intensity = 0.8,
		effects = {
			unitSpeedMult = 0.85,
			visionMult = 0.80,
			radarMult = 0.85,
			metalIncMult = 0.85,
			solarEnergyMult = 0.4,
		},
		visual = {
			particleIntensity = 0.8,
			fogDensity = 0.3,
		},
	},
	fog = {
		name = "Fog",
		description = "Dense fog - reduces vision and radar significantly",
		intensity = 0.6,
		effects = {
			visionMult = 0.70,
			radarMult = 0.75,
			unitSpeedMult = 0.98,
			solarEnergyMult = 0.2,
		},
		visual = {
			particleIntensity = 0.2,
			fogDensity = 0.5,
		},
	},
	dust_storm = {
		name = "Dust Storm",
		description = "Severe dust storm - disables radar, reduces vision and increases unit damage",
		intensity = 0.7,
		effects = {
			visionMult = 0.75,
			radarMult = 0.00,
			unitDamageTaken = 1.05,
			unitSpeedMult = 0.90,
			solarEnergyMult = 0.2,
		},
		visual = {
			particleIntensity = 0.85,
			fogDensity = 0.2,
		},
	},
	wind_gust = {
		name = "Wind Gust",
		description = "Strong wind - affects air units and projectiles, boosts wind generators",
		intensity = 0.5,
		effects = {
			airUnitSpeedMult = 1.10,
			projectileDeviationMult = 1.3,
			windEnergyBoost = 1.5,
		},
		visual = {
			particleIntensity = 0.3,
			fogDensity = 0.05,
		},
	},
	clear_skies = {
		name = "Clear Skies",
		description = "Clear weather - no weather effects",
		intensity = 0.0,
		effects = {
			unitSpeedMult = 1.0,
			visionMult = 1.0,
			metalIncMult = 1.0,
			energyIncMult = 1.0,
		},
		visual = {
			particleIntensity = 0.0,
			fogDensity = 0.0,
		},
	},
}

---============================================================================
--- Weather Modifier Functions
---============================================================================

--- Apply weather modifiers to a value based on weather type and intensity
-- @param value: The base value to modify
-- @param weatherType: The type of weather (from WEATHER_TYPES)
-- @param modifierKey: The modifier key to apply (e.g., "unitSpeedMult")
-- @return Modified value
function weatherUtils.ApplyWeatherModifier(value, weatherType, modifierKey)
	if not weatherUtils.WEATHER_TYPES[weatherType] then
		return value
	end
	
	local weatherData = weatherUtils.WEATHER_TYPES[weatherType]
	if not weatherData.effects or not weatherData.effects[modifierKey] then
		return value
	end
	
	local modifier = weatherData.effects[modifierKey]
	return value * modifier
end

--- Get weather data by type
function weatherUtils.GetWeatherData(weatherType)
	return weatherUtils.WEATHER_TYPES[weatherType]
end

--- Get list of all weather types
function weatherUtils.GetAllWeatherTypes()
	local types = {}
	for weatherType, _ in pairs(weatherUtils.WEATHER_TYPES) do
		table.insert(types, weatherType)
	end
	return types
end

--- Check if weather is severe (intensity >= 0.6)
function weatherUtils.IsSevereWeather(weatherType)
	local data = weatherUtils.GetWeatherData(weatherType)
	if data then
		return data.intensity >= 0.6
	end
	return false
end

--- Check if weather affects visibility
function weatherUtils.AffectsVision(weatherType)
	local data = weatherUtils.GetWeatherData(weatherType)
	if data and data.effects then
		return data.effects.visionMult ~= nil
	end
	return false
end

--- Check if weather affects movement
function weatherUtils.AffectsMovement(weatherType)
	local data = weatherUtils.GetWeatherData(weatherType)
	if data and data.effects then
		return data.effects.unitSpeedMult ~= nil or data.effects.airUnitSpeedMult ~= nil
	end
	return false
end

--- Check if weather affects production
function weatherUtils.AffectsProduction(weatherType)
	local data = weatherUtils.GetWeatherData(weatherType)
	if data and data.effects then
		return (data.effects.metalIncMult ~= nil or data.effects.energyIncMult ~= nil or data.effects.solarEnergyMult ~= nil or data.effects.windEnergyBoost ~= nil)
	end
	return false
end

---============================================================================
--- Time Utility Functions
---============================================================================

--- Convert game frames to seconds using game speed
-- @param frames: Number of frames
-- @param gameSpeed: Game speed (frames per second), defaults to 30
function weatherUtils.FramesToSeconds(frames, gameSpeed)
	gameSpeed = gameSpeed or 30
	return frames / gameSpeed
end

--- Convert seconds to game frames using game speed
-- @param seconds: Number of seconds
-- @param gameSpeed: Game speed (frames per second), defaults to 30
function weatherUtils.SecondsToFrames(seconds, gameSpeed)
	gameSpeed = gameSpeed or 30
	return math.floor(seconds * gameSpeed)
end

---============================================================================
--- Color Utilities for Weather Visualization
---============================================================================

--- Get color tint for weather visual effects (RGBA)
function weatherUtils.GetWeatherColorTint(weatherType)
	local colorTints = {
		light_rain = {0.8, 0.85, 1.0, 1.0},      -- Slight blue tint
		heavy_rain = {0.7, 0.75, 0.95, 1.0},     -- More blue
		fog = {0.85, 0.85, 0.9, 1.0},            -- Neutral
		dust_storm = {0.95, 0.88, 0.7, 1.0},     -- Brown/dust tint
		wind_gust = {0.9, 0.92, 0.95, 1.0},      -- Slightly blue
		clear_skies = {1.0, 1.0, 1.0, 1.0},      -- No tint
	}
	return colorTints[weatherType] or colorTints.clear_skies
end

---============================================================================
--- Unit State Management (Spring Integration)
---============================================================================

--- Store unit weather modifiers in custom parameters
-- @param unitID: The unit to modify
-- @param modifierKey: The effect type (e.g., "unitSpeedMult")
-- @param value: The modifier value
function weatherUtils.SetUnitWeatherModifier(unitID, modifierKey, value)
	if not Spring or not Spring.SetUnitMetalStorage then
		return false
	end
	
	local unitDefID = Spring.GetUnitDefID(unitID)
	if not unitDefID then
		return false
	end
	
	-- Store modifier in Spring's custom unit parameters
	local paramKey = "weather_" .. modifierKey
	Spring.SetGameRulesParam(unitID .. "_" .. paramKey, value)
	return true
end

--- Get unit weather modifier from custom parameters
-- @param unitID: The unit to query
-- @param modifierKey: The effect type to check
-- @return The modifier value, or 1.0 if not set
function weatherUtils.GetUnitWeatherModifier(unitID, modifierKey)
	if not Spring then
		return 1.0
	end
	
	local paramKey = unitID .. "_weather_" .. modifierKey
	local value = Spring.GetGameRulesParam(paramKey)
	return value or 1.0
end

---============================================================================
--- Game Rules Parameter Management
---============================================================================

--- Set current weather in game rules (for all gadgets to read)
-- @param weatherType: The weather type to set
-- @param intensity: Optional intensity value (0.0-1.0)
function weatherUtils.SetCurrentWeather(weatherType, intensity)
	if not Spring or not Spring.SetGameRulesParam then
		return false
	end
	
	if not weatherUtils.WEATHER_TYPES[weatherType] then
		return false
	end
	
	intensity = math.clamp(intensity or 0.5, 0, 1)
	Spring.SetGameRulesParam("weather_current", weatherType)
	Spring.SetGameRulesParam("weather_intensity", intensity)
	Spring.SetGameRulesParam("weather_frame", Spring.GetGameFrame())
	return true
end

--- Get current weather from game rules
-- @return weatherType, intensity
function weatherUtils.GetCurrentWeather()
	if not Spring or not Spring.GetGameRulesParam then
		return "clear_skies", 0
	end
	
	local weather = Spring.GetGameRulesParam("weather_current") or "clear_skies"
	local intensity = Spring.GetGameRulesParam("weather_intensity") or 0
	return weather, intensity
end

---============================================================================
--- Effect Calculation Functions (Actual Application)
---============================================================================

--- Calculate modifier for a specific unit attribute
-- @param unitID: The unit to calculate for
-- @param attribute: The attribute type (e.g., "speed", "vision", "damage")
-- @param baseValue: The base value before modifiers
-- @return Modified value based on current weather
function weatherUtils.CalculateModifiedAttribute(unitID, attribute, baseValue)
	if not Spring then
		return baseValue
	end
	
	local currentWeather, intensity = weatherUtils.GetCurrentWeather()
	local weatherData = weatherUtils.WEATHER_TYPES[currentWeather]
	
	if not weatherData or not weatherData.effects then
		return baseValue
	end
	
	local unitDefID = Spring.GetUnitDefID(unitID)
	if not unitDefID then
		return baseValue
	end
	
	local unitDef = UnitDefs[unitDefID]
	if not unitDef then
		return baseValue
	end
	
	local modifier = 1.0
	local effects = weatherData.effects
	
	-- Map attribute names to effect keys
	if attribute == "speed" then
		if unitDef.canfly then
			modifier = effects.airUnitSpeedMult or 1.0
		else
			modifier = effects.unitSpeedMult or 1.0
		end
	elseif attribute == "vision" then
		modifier = effects.visionMult or 1.0
	elseif attribute == "radar" then
		modifier = effects.radarMult or 1.0
	elseif attribute == "metalInc" then
		modifier = effects.metalIncMult or 1.0
	elseif attribute == "energyInc" then
		modifier = effects.energyIncMult or 1.0
	elseif attribute == "solarEnergy" then
		modifier = effects.solarEnergyMult or 1.0
	elseif attribute == "windEnergy" then
		modifier = effects.windEnergyBoost or 1.0
	elseif attribute == "damage" then
		modifier = effects.unitDamageTaken or 1.0
	elseif attribute == "projectileDeviation" then
		modifier = effects.projectileDeviationMult or 1.0
	end
	
	-- Apply intensity scaling (0.0 to 1.0)
	-- Effects smoothly transition based on intensity
	local intensityScale = intensity
	return baseValue * (1 + (modifier - 1) * intensityScale)
end

--- Get all active modifiers for a unit
-- @param unitID: The unit to query
-- @return Table of all applicable modifiers
function weatherUtils.GetUnitModifiers(unitID)
	if not Spring then
		return {}
	end
	
	local currentWeather = weatherUtils.GetCurrentWeather()
	local weatherData = weatherUtils.WEATHER_TYPES[currentWeather]
	
	if not weatherData or not weatherData.effects then
		return {}
	end
	
	local unitDefID = Spring.GetUnitDefID(unitID)
	if not unitDefID then
		return {}
	end
	
	local modifiers = {}
	for key, value in pairs(weatherData.effects) do
		modifiers[key] = value
	end
	return modifiers
end

---============================================================================
--- Weather Impact Analysis
---============================================================================

--- Get a summary of how current weather affects a specific unit type
-- @param unitDefID: The unit def to analyze (or 0 for any unit)
-- @return Table describing impacts
function weatherUtils.AnalyzeWeatherImpact(unitDefID)
	if not Spring then
		return {}
	end
	
	local currentWeather, intensity = weatherUtils.GetCurrentWeather()
	local weatherData = weatherUtils.WEATHER_TYPES[currentWeather]
	
	if not weatherData then
		return {}
	end
	
	local impact = {
		weatherType = currentWeather,
		intensity = intensity,
		severity = weatherData.intensity,
		description = weatherData.description,
		affectsMovement = weatherUtils.AffectsMovement(currentWeather),
		affectsVision = weatherUtils.AffectsVision(currentWeather),
		affectsProduction = weatherUtils.AffectsProduction(currentWeather),
		isSevere = weatherUtils.IsSevereWeather(currentWeather),
		effects = weatherData.effects,
	}
	
	-- Add unit-specific impact analysis if unitDefID provided
	if unitDefID and unitDefID > 0 then
		local unitDef = UnitDefs[unitDefID]
		if unitDef then
			local speedMod = 1.0
			if unitDef.canfly and weatherData.effects.airUnitSpeedMult then
				speedMod = weatherData.effects.airUnitSpeedMult
			elseif weatherData.effects.unitSpeedMult then
				speedMod = weatherData.effects.unitSpeedMult
			end
			
			impact.unitSpecific = {
				unitName = unitDef.name,
				unitType = unitDef.canfly and "air" or "ground",
				speedModifier = speedMod,
				visionModifier = weatherData.effects.visionMult or 1.0,
				affectedBySolar = unitDef.needGeo and (weatherData.effects.solarEnergyMult or 1.0) or nil,
			}
		end
	end
	
	return impact
end

---============================================================================
--- Debug and Logging Functions
---============================================================================

--- Format weather information for display
-- @return Formatted string describing current weather
function weatherUtils.FormatWeatherInfo()
	local weather, intensity = weatherUtils.GetCurrentWeather()
	local weatherData = weatherUtils.WEATHER_TYPES[weather]
	
	if not weatherData then
		return "Unknown weather state"
	end
	
	return string.format(
		"[%s] %s - Intensity: %.1f%% (Severity: %.0f%%)",
		weather,
		weatherData.name,
		intensity * 100,
		weatherData.intensity * 100
	)
end

--- Log weather effect application (for debugging)
-- @param unitID: Unit affected (or nil for system-wide)
-- @param effect: Description of effect applied
function weatherUtils.LogWeatherEffect(unitID, effect)
	if not Spring then
		return
	end
	
	local prefix = unitID and string.format("[Weather Unit#%d]", unitID) or "[Weather System]"
	Spring.Echo(prefix .. " " .. effect)
end

return weatherUtils
