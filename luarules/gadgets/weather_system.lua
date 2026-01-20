-- Weather System - Global periodic and random trigger
-- Manages weather event scheduling and selection
--
-- Weather events occur at random intervals:
--   Minimum: 2 minutes (120 seconds)
--   Maximum: 15 minutes (900 seconds)
-- At game start, state is equivalent to 2 minutes already elapsed

local gadget = gadget ---@type Gadget

function gadget:GetInfo()
	return {
		name      = "Weather System",
		desc      = "Manages global weather events with periodic triggers",
		author    = "Weather Mod Team",
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		version   = 1,
		layer     = -100,  -- Load early
		enabled   = true
	}
end

-- Only run synced code for deterministic weather across all players
if not gadgetHandler:IsSyncedCode() then
	return false
end

---============================================================================
--- Configuration
---============================================================================

local CONFIG = {
	GAME_SPEED = 30,              -- Default game speed (frames per second)
	MIN_INTERVAL = 120,           -- Minimum seconds between weather events
	MAX_INTERVAL = 900,           -- Maximum seconds between weather events (15 minutes)
	INITIAL_DELAY = 120,          -- Initial delay at game start (2 minutes)
	UPDATE_INTERVAL = 10,         -- Check for weather trigger every N frames
}

---============================================================================
--- Weather Event Types
---============================================================================

local WEATHER_EVENTS = {
	"light_rain",
	"heavy_rain",
	"fog",
	"dust_storm",
	"wind_gust",
	"clear_skies",
}

---============================================================================
--- State
---============================================================================

local weatherState = {
	lastEventFrame = nil,          -- Frame of last weather event
	nextEventFrame = nil,          -- Frame when next event should trigger
	currentWeather = "clear_skies", -- Current weather type
	isWeatherActive = false,        -- Whether weather is currently affecting gameplay
	eventData = {},                 -- Additional data for current weather event
}

---============================================================================
--- Helper Functions
---============================================================================

--- Calculate the game speed (frames per second)
local function GetGameSpeed()
	return Game.gameSpeed or CONFIG.GAME_SPEED
end

--- Get current game frame
local function GetCurrentFrame()
	return Spring.GetGameFrame()
end

--- Convert seconds to frames using current game speed
local function SecondsToFrames(seconds)
	return math.floor(seconds * GetGameSpeed())
end

--- Select a random weather event from available types
local function SelectRandomWeatherEvent()
	return WEATHER_EVENTS[math.random(1, #WEATHER_EVENTS)]
end

--- Calculate next trigger time with random interval
local function CalculateNextEventTime()
	local minFrames = SecondsToFrames(CONFIG.MIN_INTERVAL)
	local maxFrames = SecondsToFrames(CONFIG.MAX_INTERVAL)
	local randomFrames = math.random(minFrames, maxFrames)
	return GetCurrentFrame() + randomFrames
end

---============================================================================
--- Weather Event Management
---============================================================================

--- Initialize weather system at game start
local function InitializeWeather()
	weatherState.lastEventFrame = 0
	-- Start with initial delay equivalent to 2 minutes already elapsed
	weatherState.nextEventFrame = CalculateNextEventTime()
	weatherState.currentWeather = "clear_skies"
	weatherState.isWeatherActive = false
	weatherState.eventData = {}
	
	Spring.Echo("[Weather] System initialized. First weather event in ~" .. 
		math.floor((weatherState.nextEventFrame - GetCurrentFrame()) / GetGameSpeed()) .. " seconds")
end

--- Trigger a new weather event
local function TriggerWeatherEvent()
	local currentFrame = GetCurrentFrame()
	
	-- Select random weather event
	local newWeather = SelectRandomWeatherEvent()
	weatherState.currentWeather = newWeather
	weatherState.lastEventFrame = currentFrame
	weatherState.nextEventFrame = CalculateNextEventTime()
	weatherState.isWeatherActive = true
	
	-- Prepare event data
	weatherState.eventData = {
		type = newWeather,
		startFrame = currentFrame,
		weatherIntensity = 0.5 + math.random() * 0.5,  -- Random intensity 0.5-1.0
	}
	
	Spring.Echo("[Weather] Event triggered: " .. newWeather .. 
		" (Intensity: " .. string.format("%.2f", weatherState.eventData.weatherIntensity) .. 
		") | Next event in ~" .. 
		math.floor((weatherState.nextEventFrame - currentFrame) / GetGameSpeed()) .. " seconds")
end

---============================================================================
--- Public API
---============================================================================

--- Get current weather state
function gadget:GetWeatherState()
	return {
		currentWeather = weatherState.currentWeather,
		isActive = weatherState.isWeatherActive,
		lastEventFrame = weatherState.lastEventFrame,
		nextEventFrame = weatherState.nextEventFrame,
		eventData = weatherState.eventData,
	}
end

--- Get current weather type
function gadget:GetCurrentWeather()
	return weatherState.currentWeather
end

--- Get weather intensity (0.0-1.0)
function gadget:GetWeatherIntensity()
	return weatherState.eventData.weatherIntensity or 0
end

--- Get remaining time until next weather event (in seconds)
function gadget:GetTimeUntilNextEvent()
	local framesRemaining = math.max(0, weatherState.nextEventFrame - GetCurrentFrame())
	return framesRemaining / GetGameSpeed()
end

--- Get available weather event types
function gadget:GetAvailableWeatherEvents()
	return WEATHER_EVENTS
end

---============================================================================
--- Callins
---============================================================================

function gadget:Initialize()
	InitializeWeather()
end

local frameCounter = 0
function gadget:GameFrame(frameNum)
	frameCounter = frameCounter + 1
	
	-- Check for weather trigger at regular intervals
	if frameCounter % CONFIG.UPDATE_INTERVAL == 0 then
		if GetCurrentFrame() >= weatherState.nextEventFrame then
			TriggerWeatherEvent()
		end
	end
end

function gadget:Shutdown()
	Spring.Echo("[Weather] System shutting down")
end
