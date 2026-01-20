-- Weather System - Visual Effects (Unsynced/Client-Side)
-- Handles particle effects, visual feedback, and rendering for weather
-- This code runs on each client independently

local gadget = gadget ---@type Gadget

function gadget:GetInfo()
	return {
		name      = "Weather Visual Effects",
		desc      = "Renders cosmetic weather effects",
		author    = "Weather Mod Team",
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		version   = 1,
		layer     = 5,
		enabled   = true
	}
end

-- Only run unsynced code for client-side visuals
if gadgetHandler:IsSyncedCode() then
	return false
end

local weatherUtils = VFS.Include('common/weather_utils.lua')

---============================================================================
--- Configuration
---============================================================================

local CONFIG = {
	UPDATE_INTERVAL = 5,           -- Update weather effects every N frames
	PARTICLE_SCALE = 1.0,          -- Scale factor for all particle effects
	MAX_PARTICLES = 5000,          -- Maximum concurrent particles
}

---============================================================================
--- State
---============================================================================

local visualState = {
	currentWeather = "clear_skies",
	weatherIntensity = 0,
	lastUpdateFrame = 0,
	activeParticles = {},
	particleCount = 0,
	weatherStartFrame = 0,
	weatherSystem = nil,           -- Cache for weather system gadget
}

---============================================================================
--- Utility Functions
---============================================================================

--- Get synced weather system gadget (lazy load and cache)
local function GetWeatherSystem()
	if visualState.weatherSystem == nil then
		visualState.weatherSystem = gadgetHandler:FindGadget("Weather System")
	end
	return visualState.weatherSystem
end

--- Convert table iterator to array
local function TableToArray(tbl)
	local arr = {}
	for k, v in pairs(tbl) do
		table.insert(arr, {key = k, value = v})
	end
	return arr
end

---============================================================================
--- Weather Effect Management
---============================================================================

--- Get color overlay for current weather
local function GetWeatherColorOverlay()
	local colorTint = weatherUtils.GetWeatherColorTint(visualState.currentWeather)
	if visualState.weatherIntensity > 0 then
		-- Interpolate between normal and weather color
		return {
			colorTint[1],
			colorTint[2],
			colorTint[3],
			visualState.weatherIntensity * 0.15,  -- Light overlay (max 15% opacity)
		}
	end
	return {1.0, 1.0, 1.0, 0.0}
end

--- Update weather information from synced system
local function UpdateWeatherInfo()
	local weatherSys = GetWeatherSystem()
	if not weatherSys then
		return
	end
	
	local state = weatherSys:GetWeatherState()
	if state then
		visualState.currentWeather = state.currentWeather
		visualState.weatherIntensity = state.eventData.weatherIntensity or 0
		visualState.weatherStartFrame = state.lastEventFrame
	end
end

--- Generate visual effect for current weather
local function UpdateWeatherVisuals()
	local weatherData = weatherUtils.GetWeatherData(visualState.currentWeather)
	if not weatherData or not weatherData.visual then
		return
	end
	
	local visual = weatherData.visual
	
	-- Update particle intensity if applicable
	if visual.particleIntensity > 0 then
		-- Particles would be rendered here
		-- For now, this is a placeholder for CEG integration
		local particleCount = math.floor(visual.particleIntensity * CONFIG.MAX_PARTICLES)
		visualState.particleCount = particleCount
	else
		visualState.particleCount = 0
	end
end

---============================================================================
--- Callins
---============================================================================

function gadget:Initialize()
	Spring.Echo("[Weather Visuals] Client-side weather visualization initialized")
end

local frameCounter = 0
function gadget:GameFrame(frameNum)
	frameCounter = frameCounter + 1
	
	-- Update weather info periodically
	if frameCounter % CONFIG.UPDATE_INTERVAL == 0 then
		UpdateWeatherInfo()
		UpdateWeatherVisuals()
	end
end

--- Draw UI information about current weather (optional debug)
function gadget:DrawScreenEffects()
	-- This is called for rendering screen-space effects
	-- Could be used for HUD elements showing current weather
end

--- Draw world-space effects (particles, etc)
function gadget:DrawWorldPreUnit()
	-- This is where particle effects would be rendered
	-- Integration with Spring's particle system and CEGs
end

function gadget:Shutdown()
	Spring.Echo("[Weather Visuals] Client-side weather visualization shutting down")
end
