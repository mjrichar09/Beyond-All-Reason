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

return weatherUtils
