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
	DEBUG = true,                  -- Enable debug logging
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
	lastWeatherFrame = 0,
	lastWeatherType = "clear_skies",
	overlay = {r = 1.0, g = 1.0, b = 1.0, a = 0.0},
}

---============================================================================
--- Utility Functions
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
	local newWeather = GetCurrentWeather()
	
	-- Detect weather change and reset particles
	if newWeather ~= visualState.lastWeatherType then
		visualState.lastWeatherFrame = Spring.GetGameFrame()
		visualState.lastWeatherType = newWeather
		visualState.activeParticles = {}
		visualState.weatherStartFrame = Spring.GetGameFrame()
		Spring.Echo("[Weather Visuals] Weather changed to: " .. newWeather)
	end
	
	visualState.currentWeather = newWeather
	visualState.weatherIntensity = GetCurrentWeatherIntensity()
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
		-- Calculate particle count based on intensity and visual intensity
		local particleCount = math.floor(
			visual.particleIntensity * visualState.weatherIntensity * CONFIG.MAX_PARTICLES
		)
		visualState.particleCount = math.min(particleCount, CONFIG.MAX_PARTICLES)
	else
		visualState.particleCount = 0
	end
end

--- Get CEG (Custom Emitter Group) file path for weather type
local function GetWeatherCEGPath(weatherType)
	local cegPaths = {
		light_rain = "projectiles/weather/light_rain.lua",
		heavy_rain = "projectiles/weather/heavy_rain.lua",
		fog = "projectiles/weather/fog.lua",
		dust_storm = "projectiles/weather/dust_storm.lua",
		wind_gust = "projectiles/weather/wind_gust.lua",
		clear_skies = nil,
	}
	return cegPaths[weatherType]
end

--- Apply visual overlay (fog, color tint, etc)
local function ApplyWeatherOverlay()
	local overlay = GetWeatherColorOverlay()
	
	-- Store overlay values for use in draw functions
	visualState.overlay = {
		r = overlay[1],
		g = overlay[2],
		b = overlay[3],
		a = overlay[4],
	}
end

--- Get map boundaries
local function GetMapBounds()
	return {
		x1 = 0,
		z1 = 0,
		x2 = Game.mapSizeX,
		z2 = Game.mapSizeZ,
	}
end

--- Generate particles for weather visualization
local function GenerateWeatherParticles()
	if visualState.particleCount == 0 then
		if CONFIG.DEBUG then
			Spring.Echo("[Weather Visuals DEBUG] GenerateWeatherParticles: particleCount is 0, returning")
		end
		return
	end
	
	local weatherData = weatherUtils.GetWeatherData(visualState.currentWeather)
	if not weatherData then
		if CONFIG.DEBUG then
			Spring.Echo("[Weather Visuals DEBUG] GenerateWeatherParticles: No weather data for " .. visualState.currentWeather)
		end
		return
	end
	
	if CONFIG.DEBUG then
		Spring.Echo("[Weather Visuals DEBUG] GenerateWeatherParticles: Generating particles, target=" .. visualState.particleCount .. ", current=" .. #visualState.activeParticles)
	end
	
	-- Clear old particles if we're switching weather
	if visualState.lastWeatherFrame == nil or 
	   visualState.lastWeatherFrame < Spring.GetGameFrame() - 30 then
		visualState.activeParticles = {}
		visualState.weatherStartFrame = Spring.GetGameFrame()
	end
	
	-- Add new particles more frequently
	local currentFrame = Spring.GetGameFrame()
	local framesSinceStart = currentFrame - visualState.weatherStartFrame
	
	if framesSinceStart % 2 == 0 then  -- Spawn every 2 frames instead of 5
		local bounds = GetMapBounds()
		local particleToAdd = math.ceil(visualState.particleCount / 5)  -- Add 1/5 per spawn instead of 1/10
		
		if CONFIG.DEBUG and framesSinceStart % 10 == 0 then
			Spring.Echo("[Weather Visuals DEBUG] Spawning " .. particleToAdd .. " particles (frame " .. framesSinceStart .. ")")
		end
		
		for i = 1, particleToAdd do
			if #visualState.activeParticles < visualState.particleCount then
				table.insert(visualState.activeParticles, {
					x = math.random(bounds.x1, bounds.x2),
					y = math.random(500, 2000),  -- Random height
					z = math.random(bounds.z1, bounds.z2),
					life = 60 + math.random(0, 60),
					age = 0,
				})
			end
		end
	end
	
	-- Age and remove expired particles
	local i = 1
	while i <= #visualState.activeParticles do
		local particle = visualState.activeParticles[i]
		particle.age = particle.age + 1
		
		if particle.age >= particle.life then
			table.remove(visualState.activeParticles, i)
		else
			i = i + 1
		end
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
		visualState.lastUpdateFrame = frameNum
		UpdateWeatherInfo()
		UpdateWeatherVisuals()
		ApplyWeatherOverlay()
		GenerateWeatherParticles()
		
		-- Debug logging
		Spring.Echo("[Weather Visuals] Weather: " .. visualState.currentWeather .. 
			" | Intensity: " .. string.format("%.2f", visualState.weatherIntensity) ..
			" | Particles: " .. #visualState.activeParticles .. "/" .. visualState.particleCount)
	end
	
	-- Debug: Log every frame if we have particles
	if #visualState.activeParticles > 0 then
		if frameNum % 30 == 0 then  -- Every second at 30fps
			Spring.Echo("[Weather Visuals DEBUG] Frame " .. frameNum .. ": " .. #visualState.activeParticles .. " particles active")
		end
	end
end

--- Draw UI information about current weather (screen-space overlay)
function gadget:DrawScreen()
	if CONFIG.DEBUG then
		Spring.Echo("[Weather Visuals DEBUG] DrawScreen called")
	end
	
	-- Draw weather overlay if there's an active effect
	if visualState.overlay and visualState.overlay.a > 0 then
		if CONFIG.DEBUG then
			Spring.Echo("[Weather Visuals DEBUG] Drawing overlay: A=" .. visualState.overlay.a)
		end
		
		gl.Color(
			visualState.overlay.r,
			visualState.overlay.g,
			visualState.overlay.b,
			visualState.overlay.a
		)
		
		-- Draw fullscreen quad for color overlay
		gl.Begin(gl.QUADS)
		gl.Vertex(0, 0)
		gl.Vertex(Game.screenSizeX, 0)
		gl.Vertex(Game.screenSizeX, Game.screenSizeY)
		gl.Vertex(0, Game.screenSizeY)
		gl.End()
		
		gl.Color(1, 1, 1, 1)  -- Reset color
	end
end

--- Draw world-space effects (particles)
function gadget:DrawWorld()
	if CONFIG.DEBUG then
		Spring.Echo("[Weather Visuals DEBUG] DrawWorld called. Weather=" .. visualState.currentWeather .. " Particles=" .. #visualState.activeParticles)
	end
	
	if visualState.currentWeather == "clear_skies" or #visualState.activeParticles == 0 then
		if CONFIG.DEBUG and #visualState.activeParticles > 0 then
			Spring.Echo("[Weather Visuals DEBUG] Not drawing: clear_skies or no particles")
		end
		return
	end
	
	if CONFIG.DEBUG then
		Spring.Echo("[Weather Visuals DEBUG] Drawing " .. #visualState.activeParticles .. " particles")
	end
	
	-- Enable additive blending for particles
	gl.Blending(GL.SRC_ALPHA, GL.ONE)
	gl.Fog(false)
	
	local colorTint = weatherUtils.GetWeatherColorTint(visualState.currentWeather)
	
	-- Draw particles as simple quads
	for _, particle in ipairs(visualState.activeParticles) do
		local opacity = 1.0 - (particle.age / particle.life)
		local size = 10 * opacity
		
		gl.Color(colorTint[1], colorTint[2], colorTint[3], opacity * 0.5)
		
		-- Draw particle as small quad
		gl.PushMatrix()
		gl.Translate(particle.x, particle.y, particle.z)
		
		gl.Begin(gl.QUADS)
		gl.Vertex(-size, -size, 0)
		gl.Vertex(size, -size, 0)
		gl.Vertex(size, size, 0)
		gl.Vertex(-size, size, 0)
		gl.End()
		
		gl.PopMatrix()
	end
	
	-- Restore rendering state
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.Fog(true)
	gl.Color(1, 1, 1, 1)
end

function gadget:Shutdown()
	Spring.Echo("[Weather Visuals] Client-side weather visualization shutting down")
end
