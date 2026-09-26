--!nocheck

--[[
	// FileName: Topbar.lua

	// Written by: SolarCrane
	// Description: Code for lua side Top Menu items in ROBLOX.
]]


--[[ CONSTANTS ]]

local TOPBAR_THICKNESS = 36
local USERNAME_CONTAINER_WIDTH = 170
local COLUMN_WIDTH = 75
local NAME_LEADERBOARD_SEP_WIDTH = 2

local ITEM_SPACING = 0
local VR_ITEM_SPACING = 3

local FONT_COLOR = Color3.new(1,1,1)
local TOPBAR_BACKGROUND_COLOR = Color3.new(31/255,31/255,31/255)
local TOPBAR_OPAQUE_TRANSPARENCY = 0
local TOPBAR_TRANSLUCENT_TRANSPARENCY = 0.5

local HEALTH_BACKGROUND_COLOR = Color3.new(228/255, 236/255, 246/255)
local HEALTH_RED_COLOR = Color3.new(255/255, 28/255, 0/255)
local HEALTH_YELLOW_COLOR = Color3.new(250/255, 235/255, 0)
local HEALTH_GREEN_COLOR = Color3.new(27/255, 252/255, 107/255)

local HEALTH_PERCANTAGE_FOR_OVERLAY = 5 / 100

local HURT_OVERLAY_IMAGE = "http://www.roblox.com/asset/?id=34854607"

local DEBOUNCE_TIME = 0.25

--[[ END OF CONSTANTS ]]

--[[ FFLAG VALUES ]]

--local defeatableTopbarSuccess, defeatableTopbarFlagValue = pcall(function() return settings():GetFFlag("EnableSetCoreTopbarEnabled") end)
local defeatableTopbar = false --(defeatableTopbarSuccess and defeatableTopbarFlagValue == true)

--local vr3dGuisSuccess, vr3dGuisFlagValue = pcall(function() return settings():GetFFlag("RenderUserGuiIn3DSpace") end)
local vr3dGuis = false --(vr3dGuisSuccess and vr3dGuisFlagValue == true)

--[[ END OF FFLAG VALUES ]]

--[[DISABLE SOME COREGUI STUFF (ADDED BY programmerandgamer, ADDED BECAUSE TO DISABLE SOME UNUSED COREGUI STUFF THAT ISNT USED)]]
local modules = script.Parent:WaitForChild("Modules")
local StarterGui = game:GetService("StarterGui")
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)


--[[ SERVICES ]]

local PlayersService = game:GetService('Players')
local Player = PlayersService.LocalPlayer
while Player == nil do
	PlayersService:GetPropertyChangedSignal("LocalPlayer"):Wait()
	Player = PlayersService.LocalPlayer
end
local CoreGuiService = Player:WaitForChild("PlayerGui")
local GuiService = game:GetService('GuiService')
local InputService = game:GetService('UserInputService')
local StarterGui = game:GetService('StarterGui')
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService('RunService')
local TextService = game:GetService('TextService')
local TextChatService = game:GetService('TextChatService')

--[[ END OF SERVICES ]]


local topbarEnabled = true
local topbarEnabledChangedEvent = Instance.new('BindableEvent')

local settingsActive = false

--local GameSettings = UserSettings().GameSettings

local GuiRoot = CoreGuiService:WaitForChild('RobloxGui')
local Modules = GuiRoot:WaitForChild('Modules')

local VREnabled = InputService.VREnabled

local function SafeRequire(moduleScript, label)
	if not moduleScript then
		warn("[Topbar] Missing module:", label)
		return nil
	end

	local ok, result = pcall(require, moduleScript)
	if not ok then
		warn("[Topbar] Failed to require " .. tostring(label) .. ":", result)
		return nil
	end

	return result
end

local TenFootInterface = nil
local isTenFootInterface = false
do
	local flag = game:GetService("Lighting"):FindFirstChild("TenFootInterface")
	if flag and flag:IsA("BoolValue") then
		isTenFootInterface = flag.Value
	end
end

local PlayerlistModule = nil
local PlayerlistLoading = false
local SettingsHub = nil
local ChatModule = nil
local BackpackModule = nil

local LegacyCompatReady = false
local LegacyGlobalSettings = nil
local LegacyUserSettings = nil


local function EnsureSettingsHubRuntimeObjects()
	-- SettingsHub dereferences game.Lighting.TenFootInterface.Value during require().
	-- In the old CoreScript environment this BoolValue existed already.
	local lighting = game:GetService("Lighting")

	local tenFootFlag = lighting:FindFirstChild("TenFootInterface")
	if not tenFootFlag then
		tenFootFlag = Instance.new("BoolValue")
		tenFootFlag.Name = "TenFootInterface"
		tenFootFlag.Value = false
		tenFootFlag.Parent = lighting
	elseif tenFootFlag:IsA("BoolValue") == false then
		warn("[Topbar] Lighting.TenFootInterface exists but is not a BoolValue")
	end

	-- Do NOT create Lighting.MacClient when absent. SettingsHub only tests
	-- whether that object exists; creating a false BoolValue would still be truthy.
	-- If one already exists, leave the prototype's value/object untouched.

	-- SettingsHub waits for ControlFrame during require().
	local controlFrame = GuiRoot:FindFirstChild("ControlFrame")
	if not controlFrame then
		controlFrame = Instance.new("Frame")
		controlFrame.Name = "ControlFrame"
		controlFrame.BackgroundTransparency = 1
		controlFrame.Size = UDim2.fromOffset(0, 0)
		controlFrame.Visible = false
		controlFrame.Parent = GuiRoot
	end

	if not controlFrame:FindFirstChild("ToggleDevConsole") then
		local toggle = Instance.new("BindableFunction")
		toggle.Name = "ToggleDevConsole"
		toggle.OnInvoke = function()
			return nil
		end
		toggle.Parent = controlFrame
	end

	-- GameSettings.lua creates a Sound inside _G.CoreGui.RobloxGui.Sounds.
	-- Ensure the Sounds folder exists so that path does not yield or error.
	if not GuiRoot:FindFirstChild("Sounds") then
		local soundsFolder = Instance.new("Folder")
		soundsFolder.Name = "Sounds"
		soundsFolder.Parent = GuiRoot
	end

	return true
end

local function PrepareLegacyCoreCompat()
	EnsureSettingsHubRuntimeObjects()

	if LegacyCompatReady then
		return
	end
	LegacyCompatReady = true

	-- The prototype modules were CoreScripts and call _G:GetService().
	LegacyGlobalSettings = {
		GetFFlag = function(self, flagName)
			-- Keep risky/removed feature flags off unless the old module can
			-- safely support them in a normal LocalScript.
			local enabledFlags = {
				UseInGameTopBar = true,
			}
			return enabledFlags[flagName] == true
		end,
		GetFVariable = function(self, variableName)
			return ""
		end,
		GetMaxQualityLevel = function(self)
			return 21
		end,
		EnableFRM = false,
		QualityLevel = Enum.QualityLevel.Automatic,
	}

	do
		local ok, realSettings = pcall(function()
			return UserSettings():GetService("UserGameSettings")
		end)

		-- Default values used when the real UserGameSettings property is
		-- inaccessible (e.g. MasterVolume requires RobloxScript capability).
		local defaults = {
			SavedQualityLevel = Enum.SavedQualitySetting.Automatic,
			ControlMode = Enum.ControlMode.Classic,
			TouchCameraMovementMode = Enum.TouchCameraMovementMode.Default,
			ComputerCameraMovementMode = Enum.ComputerCameraMovementMode.Default,
			TouchMovementMode = Enum.TouchMovementMode.Default,
			ComputerMovementMode = Enum.ComputerMovementMode.Default,
			MasterVolume = 1,
			MouseSensitivity = 1,
		}

		if ok and realSettings then
			-- Wrap the real UserGameSettings in a safe proxy because some
			-- properties (e.g. MasterVolume) require CoreScript/RobloxScript
			-- capabilities that a normal LocalScript does not have.
			LegacyUserSettings = setmetatable({
				RequestUpdate = function()
					pcall(function() realSettings:RequestUpdate() end)
				end,
				InFullScreen = function()
					local ok2, result = pcall(function()
						return realSettings:InFullScreen()
					end)
					if ok2 then return result end
					return false
				end,
			}, {
				__index = function(_, key)
					local ok2, result = pcall(function()
						return realSettings[key]
					end)
					if ok2 and result ~= nil then
						return result
					end
					return defaults[key]
				end,
				__newindex = function(_, key, value)
					pcall(function()
						realSettings[key] = value
					end)
					defaults[key] = value
				end,
			})
		else
			LegacyUserSettings = {
				SavedQualityLevel = Enum.SavedQualitySetting.Automatic,
				ControlMode = Enum.ControlMode.Classic,
				TouchCameraMovementMode = Enum.TouchCameraMovementMode.Default,
				ComputerCameraMovementMode = Enum.ComputerCameraMovementMode.Default,
				TouchMovementMode = Enum.TouchMovementMode.Default,
				ComputerMovementMode = Enum.ComputerMovementMode.Default,
				MasterVolume = 1,
				MouseSensitivity = 1,
				RequestUpdate = function() end,
				InFullScreen = function() return false end,
			}
		end
	end

	local previousGetService = rawget(_G, "GetService")
	-- Some legacy modules access _G.CoreGui directly instead of _G:GetService("CoreGui").
	_G.CoreGui = CoreGuiService

	_G.GetService = function(self, serviceName)
		if serviceName == "CoreGui" then
			-- Port CoreGui.RobloxGui -> LocalPlayer.PlayerGui.RobloxGui.
			return CoreGuiService
		elseif serviceName == "GuiService" then
			return GuiService
		elseif serviceName == "StarterGui" then
			return StarterGui
		elseif serviceName == "GlobalSettings" then
			return LegacyGlobalSettings
		elseif serviceName == "UserSettings" then
			return LegacyUserSettings
		end

		if type(previousGetService) == "function" then
			local ok, result = pcall(previousGetService, self, serviceName)
			if ok and result ~= nil then
				return result
			end
		end

		local ok, result = pcall(function()
			return game:GetService(serviceName)
		end)
		return ok and result or nil
	end

	-- PlayerlistModule calls _G:LoadLibrary("RbxGui"), but this prototype
	-- only stores the result and never uses it. Return an empty compatibility table.
	local previousLoadLibrary = rawget(_G, "LoadLibrary")
	-- Players page calls _G:GetTrueName(player) to obtain display names.
	_G.GetTrueName = function(self, player)
		if type(player) == "table" or typeof(player) == "Instance" then
			local ok, name = pcall(function()
				return player.DisplayName or player.Name
			end)
			if ok and name then
				return name
			end
		end
		return tostring(player)
	end

	_G.LoadLibrary = function(self, libraryName)
		if libraryName == "RbxGui" then
			return {}
		end
		if type(previousLoadLibrary) == "function" then
			local ok, result = pcall(previousLoadLibrary, self, libraryName)
			if ok then return result end
		end
		return {}
	end

	-- In the prototype, DeveloperConsole creates this before SettingsHub is used.
	-- The standalone port does not have that CoreScript, so create the API object.
	local controlFrame = GuiRoot:FindFirstChild("ControlFrame")
	if not controlFrame then
		controlFrame = Instance.new("Frame")
		controlFrame.Name = "ControlFrame"
		controlFrame.BackgroundTransparency = 1
		controlFrame.Size = UDim2.fromOffset(0, 0)
		controlFrame.Visible = false
		controlFrame.Parent = GuiRoot
	end

	local toggleDevConsole = controlFrame:FindFirstChild("ToggleDevConsole")
	if not toggleDevConsole then
		toggleDevConsole = Instance.new("BindableFunction")
		toggleDevConsole.Name = "ToggleDevConsole"
		toggleDevConsole.OnInvoke = function()
			-- F9 remains handled by modern Roblox/Studio. This satisfies the
			-- exact 2016 SettingsHub API expected by the prototype.
			return nil
		end
		toggleDevConsole.Parent = controlFrame
	end
end

local CompleteTenFootAPI

local function LoadTenFootInterface()
	if TenFootInterface then
		return TenFootInterface
	end

	PrepareLegacyCoreCompat()
	TenFootInterface = CompleteTenFootAPI(SafeRequire(
		Modules:FindFirstChild("TenFootInterface"),
		"TenFootInterface"
		))

	if TenFootInterface and type(TenFootInterface.IsEnabled) == "function" then
		local ok, enabled = pcall(function()
			return TenFootInterface:IsEnabled()
		end)
		if ok then
			isTenFootInterface = enabled == true
		end
	end

	return TenFootInterface
end


local function CompletePlayerlistAPI(module)
	if type(module) ~= "table" then return module end

	if type(module.GetVisibility) ~= "function" then
		function module:GetVisibility()
			if type(self.IsOpen) == "function" then
				local ok, value = pcall(self.IsOpen)
				return ok and value == true or false
			end
			return false
		end
	end

	if type(module.SetVisible) ~= "function" then
		function module:SetVisible(visible)
			local current = false
			if type(self.IsOpen) == "function" then
				local ok, value = pcall(self.IsOpen)
				current = ok and value == true or false
			end
			if current ~= (visible == true) and type(self.ToggleVisibility) == "function" then
				self.ToggleVisibility()
			end
		end
	end

	if type(module.Show) ~= "function" then
		function module:Show()
			self:SetVisible(true)
		end
	end

	if type(module.Hide) ~= "function" then
		function module:Hide()
			self:SetVisible(false)
		end
	end

	return module
end

local function CompleteChatAPI(module)
	if type(module) ~= "table" then return module end

	local focused = false

	-- Original Topbar.lua calls these two, but this exact prototype's Chat
	-- public module table does not export them.
	if type(module.SetVisible) ~= "function" then
		function module:SetVisible(visible)
			local current = false
			if type(self.GetVisibility) == "function" then
				local ok, value = pcall(function()
					return self:GetVisibility()
				end)
				current = ok and value == true or false
			end

			if current ~= (visible == true) and type(self.ToggleVisibility) == "function" then
				self:ToggleVisibility()
			end
		end
	end

	if module.ChatBarFocusChanged then
		local signal = module.ChatBarFocusChanged
		pcall(function()
			if type(signal.connect) == "function" then
				signal:connect(function(value)
					focused = value == true
				end)
			elseif type(signal.Connect) == "function" then
				signal:Connect(function(value)
					focused = value == true
				end)
			elseif typeof(signal) == "RBXScriptSignal" then
				signal:Connect(function(value)
					focused = value == true
				end)
			end
		end)
	end

	if type(module.IsFocused) ~= "function" then
		function module:IsFocused()
			return focused
		end
	end

	if type(module.Show) ~= "function" then
		function module:Show()
			self:SetVisible(true)
		end
	end

	if type(module.Hide) ~= "function" then
		function module:Hide()
			self:SetVisible(false)
		end
	end

	return module
end

local function CompleteBackpackAPI(module)
	if type(module) ~= "table" then return module end

	if type(module.GetVisibility) ~= "function" then
		function module:GetVisibility()
			return self.IsOpen == true
		end
	end

	if type(module.SetVisible) ~= "function" then
		function module:SetVisible(visible)
			local current = self.IsOpen == true
			if current ~= (visible == true) and type(self.OpenClose) == "function" then
				self:OpenClose()
			end
		end
	end

	if type(module.ToggleVisibility) ~= "function" then
		function module:ToggleVisibility()
			if type(self.OpenClose) == "function" then
				self:OpenClose()
			end
		end
	end

	if type(module.Show) ~= "function" then
		function module:Show()
			self:SetVisible(true)
		end
	end

	if type(module.Hide) ~= "function" then
		function module:Hide()
			self:SetVisible(false)
		end
	end

	return module
end

CompleteTenFootAPI = function(module)
	if type(module) ~= "table" then return module end

	if type(module.GetEnabled) ~= "function" then
		function module:GetEnabled()
			if type(self.IsEnabled) == "function" then
				local ok, value = pcall(function()
					return self:IsEnabled()
				end)
				return ok and value == true or false
			end
			return false
		end
	end

	return module
end

local function CompleteSettingsHubAPI(hub)
	if type(hub) ~= "table" then return hub end

	local function instance()
		return hub.Instance
	end

	-- Forward EVERY callable SettingsHub.Instance API found in the prototype.
	local forwards = {
		"AddPage",
		"RemovePage",
		"HideBar",
		"ShowBar",
		"ScrollPixels",
		"ScrollToFrame",
		"SwitchToPage",
		"SetActive",
		"SetVisibility",
		"ToggleVisibility",
		"AddToMenuStack",
		"PopMenu",
		"ShowShield",
		"HideShield",
	}

	for _, methodName in ipairs(forwards) do
		if type(hub[methodName]) ~= "function" then
			hub[methodName] = function(self, ...)
				local inst = instance()
				if inst and type(inst[methodName]) == "function" then
					return inst[methodName](inst, ...)
				end
			end
		end
	end

	-- Dynamic state/event accessors for fields that live on Instance.

	-- Aliases for old code paths/pages that use inconsistent field names.
	if hub.Instance then
		if hub.Instance.PlayersPage and not hub.Instance.PlayerPage then
			hub.Instance.PlayerPage = hub.Instance.PlayersPage
		end
	end

	if type(hub.GetInstance) ~= "function" then
		function hub:GetInstance()
			return instance()
		end
	end

	if type(hub.GetPages) ~= "function" then
		function hub:GetPages()
			local inst = instance()
			return inst and inst.Pages or nil
		end
	end

	if type(hub.GetCurrentPage) ~= "function" then
		function hub:GetCurrentPage()
			local inst = instance()
			return inst and inst.Pages and inst.Pages.CurrentPage or nil
		end
	end

	if type(hub.GetMenuStack) ~= "function" then
		function hub:GetMenuStack()
			local inst = instance()
			return inst and inst.MenuStack or nil
		end
	end

	if type(hub.GetTabHeaders) ~= "function" then
		function hub:GetTabHeaders()
			local inst = instance()
			return inst and inst.TabHeaders or nil
		end
	end

	if type(hub.GetBottomBarButtons) ~= "function" then
		function hub:GetBottomBarButtons()
			local inst = instance()
			return inst and inst.BottomBarButtons or nil
		end
	end

	if type(hub.GetPoppedMenuSignal) ~= "function" then
		function hub:GetPoppedMenuSignal()
			local inst = instance()
			return inst and inst.PoppedMenu or nil
		end
	end

	if type(hub.GetPage) ~= "function" then
		function hub:GetPage(name)
			local inst = instance()
			if not inst or type(name) ~= "string" then return nil end

			local aliases = {
				LeaveGame = "LeaveGamePage",
				ResetCharacter = "ResetCharacterPage",
				Home = "HomePage",
				GameSettings = "GameSettingsPage",
				ReportAbuse = "ReportAbusePage",
				ReportAbuseMenu = "ReportAbusePage",
				Help = "HelpPage",
				Record = "RecordPage",
				Players = "PlayersPage",
			}
			return inst[aliases[name] or name]
		end
	end

	if type(hub.GetGuiObject) ~= "function" then
		function hub:GetGuiObject(name)
			local inst = instance()
			if not inst then return nil end
			return inst[name]
		end
	end

	return hub
end

local SettingsUtility = nil
local SettingsPageFactory = nil
local SettingsPageModules = {}

local function LoadSettingsUtility()
	if SettingsUtility then return SettingsUtility end
	local settingsFolder = Modules:FindFirstChild("Settings")
	if not settingsFolder then return nil end
	SettingsUtility = SafeRequire(settingsFolder:FindFirstChild("Utility"), "Settings.Utility")
	return SettingsUtility
end

local function LoadSettingsPageFactory()
	if SettingsPageFactory then return SettingsPageFactory end
	local settingsFolder = Modules:FindFirstChild("Settings")
	if not settingsFolder then return nil end
	SettingsPageFactory = SafeRequire(settingsFolder:FindFirstChild("SettingsPageFactory"), "Settings.SettingsPageFactory")
	return SettingsPageFactory
end

local function LoadSettingsPageModule(pageName)
	if SettingsPageModules[pageName] then
		return SettingsPageModules[pageName]
	end

	local settingsFolder = Modules:FindFirstChild("Settings")
	local pages = settingsFolder and settingsFolder:FindFirstChild("Pages")
	local moduleScript = pages and pages:FindFirstChild(pageName)
	if not moduleScript then
		warn("[Topbar] Missing Settings page module:", pageName)
		return nil
	end

	local result = SafeRequire(moduleScript, "Settings.Pages." .. tostring(pageName))
	SettingsPageModules[pageName] = result
	return result
end

local function LoadPlayerlistModule()
	PrepareLegacyCoreCompat()
	LoadTenFootInterface()

	if PlayerlistModule then
		return PlayerlistModule
	end
	if PlayerlistLoading then
		return nil
	end

	PlayerlistLoading = true

	-- The 2016 Playerlist reads this state during initialization.
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
	end)

	local moduleScript = Modules:FindFirstChild("PlayerlistModule")
		or Modules:WaitForChild("PlayerlistModule", 10)

	PlayerlistModule = CompletePlayerlistAPI(SafeRequire(moduleScript, "PlayerlistModule"))
	PlayerlistLoading = false
	return PlayerlistModule
end

local function TogglePlayerlist()
	-- Load/use the real 2016 Playerlist module first. On mobile a
	-- PlayerListToggle BindableEvent may already exist before anything is
	-- connected to it, which made the old code fire a no-op and return.
	local module = PlayerlistModule or LoadPlayerlistModule()
	if module and type(module.ToggleVisibility) == "function" then
		local ok, err = pcall(function()
			module.ToggleVisibility()
		end)
		if ok then
			return true
		end
		warn("[Topbar] PlayerlistModule.ToggleVisibility failed:", err)
	end

	-- Keep the bridge as a fallback for builds that implement playerlist
	-- toggling through RobloxGui.PlayerListToggle.
	local bridge = GuiRoot:FindFirstChild("PlayerListToggle")
	if bridge and bridge:IsA("BindableEvent") then
		bridge:Fire()
		return true
	end

	warn("[Topbar] PlayerlistModule is unavailable")
	return false
end


local function PreflightSettingsHubDependencies()
	PrepareLegacyCoreCompat()

	local settingsFolder = Modules:FindFirstChild("Settings")
	if not settingsFolder then
		return false, "Modules.Settings is missing"
	end

	local pagesFolder = settingsFolder:FindFirstChild("Pages")
	if not pagesFolder then
		return false, "Modules.Settings.Pages is missing"
	end

	local checks = {
		{Modules:FindFirstChild("TenFootInterface"), "TenFootInterface"},
		{Modules:FindFirstChild("Chat"), "Chat"},
		{Modules:FindFirstChild("PlayerlistModule"), "PlayerlistModule"},
		{Modules:FindFirstChild("BackpackScript"), "BackpackScript"},
		{settingsFolder:FindFirstChild("Utility"), "Settings.Utility"},
		{settingsFolder:FindFirstChild("SettingsPageFactory"), "Settings.SettingsPageFactory"},
		{pagesFolder:FindFirstChild("LeaveGame"), "Settings.Pages.LeaveGame"},
		{pagesFolder:FindFirstChild("ResetCharacter"), "Settings.Pages.ResetCharacter"},
		{pagesFolder:FindFirstChild("GameSettings"), "Settings.Pages.GameSettings"},
		{pagesFolder:FindFirstChild("ReportAbuseMenu"), "Settings.Pages.ReportAbuseMenu"},
		{pagesFolder:FindFirstChild("Help"), "Settings.Pages.Help"},
		{pagesFolder:FindFirstChild("Record"), "Settings.Pages.Record"},
		{pagesFolder:FindFirstChild("Players"), "Settings.Pages.Players"},
	}

	for _, pair in ipairs(checks) do
		local moduleScript, label = pair[1], pair[2]

		-- Some pages are platform-conditional, but preflighting them is useful
		-- because SettingsHub may require them on Windows.
		if moduleScript then
			local ok, result = pcall(require, moduleScript)
			if not ok then
				warn("[Topbar][SettingsHub preflight] " .. label .. " failed:", result)
				return false, label .. ": " .. tostring(result)
			end

			if label == "Chat" then
				CompleteChatAPI(result)
			elseif label == "PlayerlistModule" then
				PlayerlistModule = CompletePlayerlistAPI(result)
			elseif label == "BackpackScript" then
				BackpackModule = CompleteBackpackAPI(result)
			elseif label == "TenFootInterface" then
				TenFootInterface = CompleteTenFootAPI(result)
			elseif label == "Settings.Utility" then
				SettingsUtility = result
			elseif label == "Settings.SettingsPageFactory" then
				SettingsPageFactory = result
			end
		elseif label ~= "Settings.Pages.Home" then
			warn("[Topbar][SettingsHub preflight] Missing:", label)
		end
	end

	return true
end

local function LoadSettingsHub()
	PrepareLegacyCoreCompat()
	LoadTenFootInterface()

	if SettingsHub then
		return SettingsHub
	end

	local okPreflight, preflightError = PreflightSettingsHubDependencies()
	if not okPreflight then
		warn("[Topbar] SettingsHub dependency preflight failed:", preflightError)
		return nil
	end

	local settingsFolder = Modules:FindFirstChild("Settings")
		or Modules:WaitForChild("Settings", 10)
	if not settingsFolder then
		warn("[Topbar] Modules.Settings is missing")
		return nil
	end

	local moduleScript = settingsFolder:FindFirstChild("SettingsHub")
		or settingsFolder:WaitForChild("SettingsHub", 10)
	local hub = nil
	do
		local ok, result = pcall(require, moduleScript)
		if not ok then
			warn("[Topbar] SettingsHub itself failed after dependency preflight:", result)
			return nil
		end
		hub = CompleteSettingsHubAPI(result)
	end
	if type(hub) ~= "table" then
		return nil
	end

	-- Exact API exposed by settings2016.rbxm.
	for _, methodName in ipairs({
		"SetVisibility",
		"ToggleVisibility",
		"SwitchToPage",
		"GetVisibility",
		"ShowShield",
		"HideShield",
		"ReportPlayer",
		}) do
		if type(hub[methodName]) ~= "function" then
			warn("[Topbar] SettingsHub missing API:", methodName)
			return nil
		end
	end

	if hub.SettingsShowSignal == nil then
		warn("[Topbar] SettingsHub missing SettingsShowSignal")
		return nil
	end

	if type(hub.Instance) ~= "table" then
		warn("[Topbar] SettingsHub missing Instance API")
		return nil
	end

	for _, methodName in ipairs({
		"AddPage",
		"RemovePage",
		"HideBar",
		"ShowBar",
		"ScrollPixels",
		"ScrollToFrame",
		"SwitchToPage",
		"SetActive",
		"SetVisibility",
		"ToggleVisibility",
		"AddToMenuStack",
		"PopMenu",
		"ShowShield",
		"HideShield",
		}) do
		if type(hub.Instance[methodName]) ~= "function" then
			warn("[Topbar] SettingsHub.Instance missing API:", methodName)
			return nil
		end
	end

	SettingsHub = hub
	return SettingsHub
end

local Panel3D = nil
local Topbar3DPanel = nil

local Util = {}
do
	-- Check if we are running on a touch device
	function Util.IsTouchDevice()
		return InputService.TouchEnabled
	end

	-- Modern mobile compatibility.
	-- The old 2016 topbar assumed a much wider desktop viewport.
	function Util.GetViewportSize()
		local camera = workspace.CurrentCamera
		if camera then
			return camera.ViewportSize
		end

		local ok, resolution = pcall(function()
			return GuiService:GetScreenResolution()
		end)
		if ok and resolution then
			return resolution
		end

		return Vector2.new(1280, 720)
	end

	function Util.IsCompactTouchDevice()
		if not InputService.TouchEnabled then
			return false
		end

		local viewport = Util.GetViewportSize()
		return viewport.X < 900 or viewport.Y < 600
	end

	function Util.IsVerySmallTouchDevice()
		if not InputService.TouchEnabled then
			return false
		end

		local viewport = Util.GetViewportSize()
		return viewport.X < 520
	end

	function Util.Create(instanceType)
		return function(data)
			local obj = Instance.new(instanceType)
			for k, v in pairs(data) do
				if type(k) == 'number' then
					v.Parent = obj
				else
					obj[k] = v
				end
			end
			return obj
		end
	end

	function Util.Clamp(low, high, input)
		return math.max(low, math.min(high, input))
	end

	function Util.DisconnectEvent(conn)
		if conn then
			conn:disconnect()
		end
		return nil
	end

	function Util.SetGUIInsetBounds(x1, y1, x2, y2)
		--GuiService:SetGlobalGuiInset(x1, y1, x2, y2)
		if GuiRoot:FindFirstChild("GuiInsetChanged") then
			GuiRoot.GuiInsetChanged:Fire(x1, y1, x2, y2)
		end
	end

	local humanoidCache = {}
	function Util.FindPlayerHumanoid(player)
		local character = player and player.Character
		if character then
			local resultHumanoid = humanoidCache[player]
			if resultHumanoid and resultHumanoid.Parent == character then
				return resultHumanoid
			else
				humanoidCache[player] = nil -- Bust Old Cache
				for _, child in pairs(character:GetChildren()) do
					if child:IsA('Humanoid') then
						humanoidCache[player] = child
						return child
					end
				end
			end
		end
	end
end

local selectionRing = Util.Create "ImageLabel" {
	Name = "SelectionRing",
	Position = UDim2.new(0.5, -23, 0.5, -23),
	Size = UDim2.new(0, 46, 0, 46),
	BackgroundTransparency = 1,
	Image = "rbxasset://textures/ui/menu/buttonHover.png"
}

local function CreateTopBar()
	local this = {}

	local playerGuiChangedConn = nil

	local topbarContainer = Util.Create'Frame'{
		Name = "TopBarContainer";
		Size = UDim2.new(1, 0, 0, TOPBAR_THICKNESS);
		Position = UDim2.new(0, 0, 0, 0);
		BackgroundTransparency = TOPBAR_OPAQUE_TRANSPARENCY;
		BackgroundColor3 = TOPBAR_BACKGROUND_COLOR;
		BorderSizePixel = 0;
		Active = true;
		ZIndex = 10;
		Parent = GuiRoot;
	};

	local topbarShadow = Util.Create'ImageLabel'{
		Name = "TopBarShadow";
		Size = UDim2.new(1, 0, 0, 3);
		Position = UDim2.new(0, 0, 1, 0);
		Image = "rbxasset://textures/ui/TopBar/dropshadow.png";
		BackgroundTransparency = 1;
		Active = false;
		Visible = false;
		Parent = topbarContainer;
	};

	local function ComputeTransparency()
		if not topbarEnabled then
			return 1
		end

		local playerGui = Player:FindFirstChild('PlayerGui')
		if playerGui then
			local ok, transparency = pcall(function()
				return playerGui:GetTopbarTransparency()
			end)
			if ok and type(transparency) == "number" then
				return transparency
			end
		end

		return TOPBAR_TRANSLUCENT_TRANSPARENCY
	end

	function this:UpdateBackgroundTransparency()
		if settingsActive and not VREnabled then
			topbarContainer.BackgroundTransparency = TOPBAR_OPAQUE_TRANSPARENCY
			topbarShadow.Visible = false
		else
			topbarContainer.BackgroundTransparency = ComputeTransparency()
			topbarShadow.Visible = (topbarContainer.BackgroundTransparency == 0)
		end
	end

	function this:GetInstance()
		return topbarContainer
	end

	spawn(function()
		local playerGui = Player:WaitForChild('PlayerGui')
		playerGuiChangedConn = Util.DisconnectEvent(playerGuiChangedConn)
		pcall(function()
			playerGuiChangedConn = playerGui.TopbarTransparencyChangedSignal:connect(this.UpdateBackgroundTransparency)
		end)
		this:UpdateBackgroundTransparency()
	end)

	return this
end


local BarAlignmentEnum =
	{
		Right = 0;
		Left = 1;
		Middle = 2;
	}

local function CreateMenuBar(barAlignment)
	local this = {}
	local thickness = TOPBAR_THICKNESS
	local alignment = barAlignment or BarAlignmentEnum.Right
	local items = {}
	local propertyChangedConnections = {}
	local dock = nil

	function this:ArrangeItems()
		local totalWidth = 0

		local spacing = ITEM_SPACING
		if InputService.VREnabled then
			spacing = VR_ITEM_SPACING
		end

		for i, item in ipairs(items) do
			local width = item:GetWidth()

			if alignment == BarAlignmentEnum.Left then
				item.Position = UDim2.new(0, totalWidth, 0, 0)
			elseif alignment == BarAlignmentEnum.Right then
				item.Position = UDim2.new(1, -totalWidth - width, 0, 0)
			end

			if i ~= #items then
				width = width + spacing
			end

			totalWidth = totalWidth + width
		end

		if alignment == BarAlignmentEnum.Middle then
			local currentX = -totalWidth / 2
			for _, item in ipairs(items) do
				item.Position = UDim2.new(0, currentX, 0, 0)

				currentX = currentX + item:GetWidth() + spacing
			end
		end

		return totalWidth
	end

	function this:GetThickness()
		return thickness
	end

	function this:GetNumberOfItems()
		return #items
	end

	function this:SetDock(newDock)
		dock = newDock
		for _, item in pairs(items) do
			item.Parent = dock
		end
	end

	function this:IndexOfItem(searchItem)
		for index, item in pairs(items) do
			if item == searchItem then
				return index
			end
		end
		return nil
	end

	function this:ItemAtIndex(index)
		return items[index]
	end

	function this:GetItems()
		return items
	end

	function this:AddItem(item, index)
		local numItems = self:GetNumberOfItems()
		index = Util.Clamp(1, numItems + 1, (index or numItems + 1))

		local alreadyFoundIndex = self:IndexOfItem(item)
		if alreadyFoundIndex then
			return item, index
		end

		table.insert(items, index, item)
		Util.DisconnectEvent(propertyChangedConnections[item])
		propertyChangedConnections[item] = item.Changed:connect(function(property)
			if property == 'AbsoluteSize' then
				self:ArrangeItems()
			end
		end)
		self:ArrangeItems()

		if dock then
			item.Parent = dock
		end

		return item, index
	end

	function this:RemoveItem(item)
		local index = self:IndexOfItem(item)
		if index then
			local removedItem = table.remove(items, index)

			removedItem.Parent = nil
			Util.DisconnectEvent(propertyChangedConnections[removedItem])

			self:ArrangeItems()
			return removedItem, index
		end
	end


	return this
end

local function Create3DMenuBar(barAlignment, threeDPanel)
	local this = CreateMenuBar(barAlignment)

	local superArrangeItems = this.ArrangeItems
	function this:ArrangeItems()
		local totalWidth = superArrangeItems(self)
		if threeDPanel then
			threeDPanel:ResizePixels(totalWidth, 120)
		end
		for _, v in pairs(this:GetItems()) do
			v:UpdateHoverText()
		end
		return totalWidth
	end

	function this:CloseAllExcept(item)
		for _, v in pairs(this:GetItems()) do
			if v ~= item then
				v:SetActive(false)
			end
		end
	end

	return this
end


local function CreateMenuItem(origInstance)
	local this = {}
	local instance = origInstance

	function this:SetInstance(newInstance)
		if not instance then
			instance = newInstance
		else
			print("Trying to set an Instance of a Menu Item that already has an instance; doing nothing.")
		end
	end

	function this:GetWidth()
		return self.Size.X.Offset
	end

	-- We are extending a regular instance.
	do
		local mt =
			{
				__index = function (t, k)
					return instance[k]
				end;

				__newindex = function (t, k, v)
					--if instance[k] ~= nil then
					instance[k] = v
					--else
					--	rawset(t, k, v)
					--end
				end;
			}
		setmetatable(this, mt)
	end

	return this
end

local function Create3DMenuItem()
	local menuItem = {}

	local backgroundButton = Util.Create 'ImageButton' {
		Name = "ButtonBackground",
		Size = UDim2.new(0, 52, 0, 52),

		BackgroundTransparency = 1,
		SelectionImageObject = selectionRing:Clone(),

		ClipsDescendants = false
	}

	local isActive = false

	function menuItem:SetActive(active)
		isActive = active
		if active then
			backgroundButton.Image = "rbxasset://textures/ui/menu/buttonActive.png"
		else
			backgroundButton.Image = "rbxasset://textures/ui/menu/buttonBackground.png"
		end
		backgroundButton.SelectionImageObject.Visible = not active
	end

	function menuItem:GetWidth()
		return backgroundButton.AbsoluteSize.X
	end

	function menuItem:GetInstance()
		return backgroundButton
	end

	local function setTransparency(parent, transparency)
		if parent:IsA("ImageLabel") or parent:IsA("ImageButton") then
			parent.ImageTransparency = transparency
		elseif parent:IsA("TextLabel") or parent:IsA("TextButton") then
			parent.TextTransparency = transparency
		end
		for _, v in pairs(parent:GetChildren()) do
			if v:IsA("GuiObject") then
				setTransparency(v, transparency)
			end
		end
	end
	function menuItem:SetTransparency(transparency)
		setTransparency(backgroundButton, transparency)
	end

	menuItem:SetActive(false)

	local hoverTextFrame = Util.Create 'Frame' {
		Name = "ButtonHoverText",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Position = UDim2.new(0.5, -45, 0, 55),
		Size = UDim2.new(0, 90, 0, 60),

		Visible = false,
		Parent = backgroundButton
	}
	local hoverMid = Util.Create 'ImageLabel' {
		Name = "HoverMid",
		BackgroundTransparency = 1,

		Image = "rbxasset://textures/ui/Menu/hoverPopupMid.png",

		Position = UDim2.new(0.5, -12, 0, 0),
		Size = UDim2.new(0, 24, 1, 0),
		Parent = hoverTextFrame
	}
	local hoverLeft = Util.Create 'ImageLabel' {
		Name = "HoverLeft",
		BackgroundTransparency = 1,

		Image = "rbxasset://textures/ui/Menu/hoverPopupLeft.png",

		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0.5, -12, 1, 0),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(1, 1, 33, 59),
		Parent = hoverTextFrame
	}
	local hoverRight = Util.Create 'ImageLabel' {
		Name = "HoverRight",
		BackgroundTransparency = 1,

		Image = "rbxasset://textures/ui/Menu/hoverPopupRight.png",

		Position = UDim2.new(0.5, 12, 0, 0),
		Size = UDim2.new(0.5, -12, 1, 0),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(0, 1, 32, 59),
		Parent = hoverTextFrame
	}

	local hoverTextLabel = Util.Create 'TextLabel' {
		Name = "ButtonHoverTextLabel",
		BackgroundTransparency = 1,

		Font = Enum.Font.SourceSansBold,
		FontSize = Enum.FontSize.Size24,
		Text = "",
		TextColor3 = Color3.new(1, 1, 1),

		Position = UDim2.new(0, 0, 0, 8),
		Size = UDim2.new(1, 0, 1, -5),

		Parent = hoverTextFrame
	}

	function menuItem:SetHoverText(text)
		hoverTextLabel.Text = text
		local textSize = TextService:GetTextSize(
			hoverTextLabel.Text,
			24,
			hoverTextLabel.Font,
			Vector2.new(1000, 10000))
		local frameWidth = textSize.x + 20
		hoverTextFrame.Position = UDim2.new(0.5, -frameWidth / 2, 0, 55)
		hoverTextFrame.Size = UDim2.new(0, frameWidth, 0, 60)
	end

	backgroundButton.SelectionGained:connect(function()
		hoverTextFrame.Visible = true
	end)
	backgroundButton.SelectionLost:connect(function()
		hoverTextFrame.Visible = false
	end)

	function menuItem:UpdateHoverText()
		self:SetHoverText(hoverTextLabel.Text)
	end

	setmetatable(menuItem, {
		__index = function(t, k)
			return backgroundButton[k]
		end,
		__newindex = function(t, k, v)
			backgroundButton[k] = v
		end
	})

	return menuItem
end

local function createNormalHealthBar()
	local container = Util.Create'ImageButton'
	{
		Name = "NameHealthContainer";
		Size = UDim2.new(0, USERNAME_CONTAINER_WIDTH, 1, 0);
		AutoButtonColor = false;
		Image = "";
		BackgroundTransparency = 1;
	}

	local username = Util.Create'TextLabel'{
		Name = "Username";
		Text = Player.Name;
		Size = UDim2.new(1, -14, 0, 22);
		Position = UDim2.new(0, 7, 0, 0);
		Font = Enum.Font.SourceSansBold;
		FontSize = Enum.FontSize.Size14;
		BackgroundTransparency = 1;
		TextColor3 = FONT_COLOR;
		TextYAlignment = Enum.TextYAlignment.Bottom;
		TextXAlignment = Enum.TextXAlignment.Left;
		Parent = container;
	};

	local healthContainer = Util.Create'Frame'{
		Name = "HealthContainer";
		Size = UDim2.new(1, -14, 0, 3);
		Position = UDim2.new(0, 7, 1, -9);
		BorderSizePixel = 0;
		BackgroundColor3 = HEALTH_BACKGROUND_COLOR;
		Parent = container;
	};

	local healthFill = Util.Create'Frame'{
		Name = "HealthFill";
		Size = UDim2.new(1, 0, 1, 0);
		BorderSizePixel = 0;
		BackgroundColor3 = HEALTH_GREEN_COLOR;
		Parent = healthContainer;
	};

	return container, username, healthContainer, healthFill
end

----- HEALTH -----
local function CreateUsernameHealthMenuItem()

	local container, username, healthContainer, healthFill = nil

	if isTenFootInterface and TenFootInterface and type(TenFootInterface.CreateHealthBar) == "function" then
		container, username, healthContainer, healthFill = TenFootInterface:CreateHealthBar()
	else
		container, username, healthContainer, healthFill = createNormalHealthBar()
	end

	local hurtOverlay = Util.Create'ImageLabel'
	{
		Name = "HurtOverlay";
		BackgroundTransparency = 1;
		Image = HURT_OVERLAY_IMAGE;
		Position = UDim2.new(-10,0,-10,0);
		Size = UDim2.new(20,0,20,0);
		Visible = false;
		Parent = GuiRoot;
	};

	local this = CreateMenuItem(container)

	--- EVENTS ---
	local humanoidChangedConn, childAddedConn, childRemovedConn = nil
	--------------

	local function AnimateHurtOverlay()
		if hurtOverlay and not VREnabled then
			local newSize = UDim2.new(20, 0, 20, 0)
			local newPos = UDim2.new(-10, 0, -10, 0)

			if hurtOverlay:IsDescendantOf(game) then
				-- stop any tweens on overlay
				hurtOverlay:TweenSizeAndPosition(newSize, newPos, Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0, true, function()
					-- show the gui
					hurtOverlay.Size = UDim2.new(1,0,1,0)
					hurtOverlay.Position = UDim2.new(0,0,0,0)
					hurtOverlay.Visible = true
					-- now tween the hide
					if hurtOverlay:IsDescendantOf(game) then
						hurtOverlay:TweenSizeAndPosition(newSize, newPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 10, false, function()
							hurtOverlay.Visible = false
						end)
					else
						hurtOverlay.Size = newSize
						hurtOverlay.Position = newPos
					end
				end)
			end
		end
	end

	local healthColorToPosition = {
		[Vector3.new(HEALTH_RED_COLOR.r, HEALTH_RED_COLOR.g, HEALTH_RED_COLOR.b)] = 0.1;
		[Vector3.new(HEALTH_YELLOW_COLOR.r, HEALTH_YELLOW_COLOR.g, HEALTH_YELLOW_COLOR.b)] = 0.5;
		[Vector3.new(HEALTH_GREEN_COLOR.r, HEALTH_GREEN_COLOR.g, HEALTH_GREEN_COLOR.b)] = 0.8;
	}
	local min = 0.1
	local minColor = HEALTH_RED_COLOR
	local max = 0.8
	local maxColor = HEALTH_GREEN_COLOR

	local function HealthbarColorTransferFunction(healthPercent)
		if healthPercent < min then
			return minColor
		elseif healthPercent > max then
			return maxColor
		end

		-- Shepard's Interpolation
		local numeratorSum = Vector3.new(0,0,0)
		local denominatorSum = 0
		for colorSampleValue, samplePoint in pairs(healthColorToPosition) do
			local distance = healthPercent - samplePoint
			if distance == 0 then
				-- If we are exactly on an existing sample value then we don't need to interpolate
				return Color3.new(colorSampleValue.x, colorSampleValue.y, colorSampleValue.z)
			else
				local wi = 1 / (distance*distance)
				numeratorSum = numeratorSum + wi * colorSampleValue
				denominatorSum = denominatorSum + wi
			end
		end
		local result = numeratorSum / denominatorSum
		return Color3.new(result.x, result.y, result.z)
	end

	local function OnHumanoidAdded(humanoid)
		local lastHealth = humanoid.Health
		local function OnHumanoidHealthChanged(health)
			if humanoid then
				local healthDelta = lastHealth - health
				local healthPercent = health / humanoid.MaxHealth
				if humanoid.MaxHealth <= 0 then
					healthPercent = 0
				end
				healthPercent = Util.Clamp(0, 1, healthPercent)
				local healthColor = HealthbarColorTransferFunction(healthPercent)
				local thresholdForHurtOverlay = humanoid.MaxHealth * HEALTH_PERCANTAGE_FOR_OVERLAY

				if healthDelta >= thresholdForHurtOverlay and health ~= humanoid.MaxHealth and true then
					AnimateHurtOverlay()
				end

				healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
				healthFill.BackgroundColor3 = healthColor

				lastHealth = health
			end
		end
		Util.DisconnectEvent(humanoidChangedConn)
		humanoidChangedConn = humanoid.HealthChanged:connect(OnHumanoidHealthChanged)
		OnHumanoidHealthChanged(lastHealth)
	end

	local function OnCharacterAdded(character)
		local humanoid = Util.FindPlayerHumanoid(Player)
		if humanoid then
			OnHumanoidAdded(humanoid)
		end

		local function onChildAddedOrRemoved()
			local tempHumanoid = Util.FindPlayerHumanoid(Player)
			if tempHumanoid and tempHumanoid ~= humanoid then
				humanoid = tempHumanoid
				OnHumanoidAdded(humanoid)
			end
		end
		Util.DisconnectEvent(childAddedConn)
		Util.DisconnectEvent(childRemovedConn)
		childAddedConn = character.ChildAdded:connect(onChildAddedOrRemoved)
		childRemovedConn = character.ChildRemoved:connect(onChildAddedOrRemoved)
	end

	rawset(this, "SetHealthbarEnabled",
		function(self, enabled)
			healthContainer.Visible = enabled
			if enabled then
				username.Size = UDim2.new(1, -14, 0, 22);
				username.TextYAlignment = Enum.TextYAlignment.Bottom;
			else
				username.Size = UDim2.new(1, -14, 1, 0);
				username.TextYAlignment = Enum.TextYAlignment.Center;
			end
		end)

	rawset(this, "SetNameVisible",
		function(self, visible)
			username.Visible = visible
		end)

	-- Don't need to disconnect this one because we never reconnect it.
	Player.CharacterAdded:connect(OnCharacterAdded)
	if Player.Character then
		OnCharacterAdded(Player.Character)
	end

	container.Activated:Connect(function()
		if topbarEnabled then
			TogglePlayerlist()
		end
	end)

	return this
end
----- END OF HEALTH -----

----- LEADERSTATS -----
local function CreateLeaderstatsMenuItem()

	local leaderstatsContainer = Util.Create'ImageButton'
	{
		Name = "LeaderstatsContainer";
		Size = UDim2.new(0, 0, 1, 0);
		AutoButtonColor = false;
		Image = "";
		BackgroundTransparency = 1;
	};

	local this = CreateMenuItem(leaderstatsContainer)
	local columns = {}

	rawset(this, "SetColumns",
		function(self, columnsList)
			-- Should we handle is the screen dimensions change and it is no longer a small touch device after we set columns?
			local isSmallTouchDevice = Util.IsTouchDevice() and GuiService:GetScreenResolution().Y < 500
			local numColumns = #columnsList

			-- Destroy old columns
			for _, oldColumn in pairs(columns) do
				oldColumn:Destroy()
			end
			columns = {}
			-- End destroy old columns
			local count = 0
			for index, columnData in pairs(columnsList) do  -- i = 1, numColumns do
				if not isSmallTouchDevice or index <= 1 then
					local columnName = columnData.Name
					local columnValue = columnData.Text

					local columnframe = Util.Create'Frame'
					{
						Name = "Column" .. tostring(index);
						Size = UDim2.new(0, COLUMN_WIDTH + (index == numColumns and 0 or NAME_LEADERBOARD_SEP_WIDTH), 1, 0);
						Position = UDim2.new(0, NAME_LEADERBOARD_SEP_WIDTH + (COLUMN_WIDTH + NAME_LEADERBOARD_SEP_WIDTH) * (index-1), 0, 0);
						BackgroundTransparency = 1;
						Parent = leaderstatsContainer;

						Util.Create'TextLabel'
						{
							Name = "ColumnName";
							Text = columnName;
							Size = UDim2.new(1, 0, 0, 10);
							Position = UDim2.new(0, 0, 0, 4);
							Font = Enum.Font.SourceSans;
							FontSize = Enum.FontSize.Size14;
							BorderSizePixel = 0;
							BackgroundTransparency = 1;
							TextColor3 = FONT_COLOR;
							TextYAlignment = Enum.TextYAlignment.Center;
							TextXAlignment = Enum.TextXAlignment.Center;
						};

						Util.Create'TextLabel'
						{
							Name = "ColumnValue";
							Text = columnValue;
							Size = UDim2.new(1, 0, 0, 10);
							Position = UDim2.new(0, 0, 0, 19);
							Font = Enum.Font.SourceSansBold;
							FontSize = Enum.FontSize.Size14;
							BorderSizePixel = 0;
							BackgroundTransparency = 1;
							TextColor3 = FONT_COLOR;
							TextYAlignment = Enum.TextYAlignment.Center;
							TextXAlignment = Enum.TextXAlignment.Center;
						};
					};
					columns[columnName] = columnframe
					count = count + 1
				end
			end
			leaderstatsContainer.Size = UDim2.new(0, COLUMN_WIDTH * count + NAME_LEADERBOARD_SEP_WIDTH * count, 1, 0)
		end)

	rawset(this, "UpdateColumnValue",
		function(self, columnName, value)
			local column = columns[columnName]
			local columnValue = column and column:FindFirstChild('ColumnValue')
			if columnValue then
				columnValue.Text = tostring(value)
			end
		end)

	local playerlistConnectionsAttached = false

	local function attachPlayerlistModule(module)
		if not module or playerlistConnectionsAttached then
			return
		end
		playerlistConnectionsAttached = true

		-- IMPORTANT: do not call module.TopbarEnabledChanged().
		-- That old API re-reads CoreGuiType.PlayerList and can disable this
		-- custom list when the bootstrapper hides Roblox's native player list.

		if type(module.GetStats) == "function" then
			local ok, stats = pcall(module.GetStats)
			if ok and type(stats) == "table" then
				this:SetColumns(stats)
			end
		end

		if module.OnLeaderstatsChanged and module.OnLeaderstatsChanged.Event then
			module.OnLeaderstatsChanged.Event:connect(function(newStatColumns)
				this:SetColumns(newStatColumns)
			end)
		end

		if module.OnStatChanged and module.OnStatChanged.Event then
			module.OnStatChanged.Event:connect(function(statName, statValueAsString)
				this:UpdateColumnValue(statName, statValueAsString)
			end)
		end
	end

	rawset(this, "AttachPlayerlistModule", function(self, module)
		attachPlayerlistModule(module)
	end)

	rawset(this, "TogglePlayerlist", function(self)
		return TogglePlayerlist()
	end)

	rawset(this, "IsPlayerlistOpen", function(self)
		local module = PlayerlistModule
		if module and type(module.IsOpen) == "function" then
			local ok, value = pcall(module.IsOpen)
			if ok then return value == true end
		end
		return false
	end)

	rawset(this, "HidePlayerlistTemp", function(self, key, hidden)
		local module = PlayerlistModule or LoadPlayerlistModule()
		if module and type(module.HideTemp) == "function" then
			return pcall(function()
				module:HideTemp(key, hidden)
			end)
		end
		return false
	end)

	rawset(this, "GetPlayerlistModule", function(self)
		return PlayerlistModule
	end)

	leaderstatsContainer.Activated:Connect(function()
		if topbarEnabled then
			TogglePlayerlist()
		end
	end)

	return this
end
----- END OF LEADERSTATS -----

--- SETTINGS ---
local function CreateSettingsIcon(topBarInstance)
	local MenuModule = nil
	local settingsSignalConnection = nil

	local settingsIconButton = Util.Create'ImageButton'
	{
		Name = "Settings";
		Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
		Image = "";
		AutoButtonColor = false;
		BackgroundTransparency = 1;
		Active = true;
		Selectable = true;
		ZIndex = 50;
	}

	local settingsIconImage = Util.Create'ImageLabel'
	{
		Name = "SettingsIcon";
		Size = UDim2.new(0, 32, 0, 25);
		Position = UDim2.new(0.5, -16, 0.5, -12);
		BackgroundTransparency = 1;
		ZIndex = 51;
		Active = false;
		Image = "rbxasset://textures/ui/Menu/Hamburger.png";
		Parent = settingsIconButton;
	};

	local function UpdateHamburgerIcon()
		if settingsActive then
			settingsIconImage.Image = "rbxasset://textures/ui/Menu/HamburgerDown.png";
		else
			settingsIconImage.Image = "rbxasset://textures/ui/Menu/Hamburger.png";
		end
	end

	local function readVisibility()
		if MenuModule and type(MenuModule.GetVisibility) == "function" then
			local ok, visible = pcall(function()
				return MenuModule:GetVisibility()
			end)
			if ok then
				return visible == true
			end
		end
		return settingsActive
	end

	local function onVisibilityChanged(active)
		settingsActive = active == true
		UpdateHamburgerIcon()
		topBarInstance:UpdateBackgroundTransparency()
	end

	local function connectSignal()
		if settingsSignalConnection or not MenuModule then
			return
		end

		local signal = MenuModule.SettingsShowSignal
		if not signal then
			return
		end

		if type(signal.connect) == "function" then
			local ok, connection = pcall(function()
				return signal:connect(onVisibilityChanged)
			end)
			if ok then
				settingsSignalConnection = connection
				return
			end
		end

		if type(signal.Connect) == "function" then
			local ok, connection = pcall(function()
				return signal:Connect(onVisibilityChanged)
			end)
			if ok then
				settingsSignalConnection = connection
				return
			end
		end

		if typeof(signal) == "RBXScriptSignal" then
			settingsSignalConnection = signal:Connect(onVisibilityChanged)
		elseif typeof(signal) == "Instance" and signal:IsA("BindableEvent") then
			settingsSignalConnection = signal.Event:Connect(onVisibilityChanged)
		end
	end

	local function ensureHub()
		if MenuModule then
			return MenuModule
		end

		MenuModule = LoadSettingsHub()
		if MenuModule then
			connectSignal()
			onVisibilityChanged(readVisibility())
		end
		return MenuModule
	end

	local function forceHubVisualState(hub, visible, customStartPage)
		if not hub then return false end
		local instance = hub.Instance
		if type(instance) ~= "table" then return false end

		instance.Visible = visible == true
		instance.Active = visible == true

		if instance.Modal then
			instance.Modal.Visible = visible == true
		end

		if instance.ClippingShield then
			instance.ClippingShield.Visible = visible == true
		end

		if instance.Shield then
			instance.Shield.Visible = visible == true
			if visible then
				instance.Shield.Position = UDim2.new(0, 0, 0, 0)
			else
				instance.Shield.Position = UDim2.new(0, 0, -1, -36)
			end
		end

		if visible then
			local targetPage = customStartPage
				or (instance.Pages and instance.Pages.CurrentPage)
				or instance.PlayersPage
				or instance.HomePage
				or instance.GameSettingsPage
				or instance.HelpPage

			if targetPage and type(instance.SwitchToPage) == "function" then
				pcall(function()
					instance:SwitchToPage(targetPage, true, 1, true)
				end)
			end

			if type(instance.ShowBar) == "function" then
				pcall(function()
					instance:ShowBar()
				end)
			end
		else
			if type(instance.HideBar) == "function" then
				pcall(function()
					instance:HideBar()
				end)
			end
		end

		-- Keep the old SettingsShowSignal consumers synchronized.
		local signal = hub.SettingsShowSignal
		if signal then
			pcall(function()
				if type(signal.fire) == "function" then
					signal:fire(visible == true)
				elseif type(signal.Fire) == "function" then
					signal:Fire(visible == true)
				elseif typeof(signal) == "Instance" and signal:IsA("BindableEvent") then
					signal:Fire(visible == true)
				end
			end)
		end

		return true
	end

	local function setVisible(visible, noAnimation, customStartPage, switchedFromGamepadInput)
		local hub = ensureHub()
		if not hub then
			warn("[Topbar] SettingsHub unavailable")
			return false
		end

		-- Prefer the real 2016 API first.
		local ok, err = pcall(function()
			hub:SetVisibility(visible, noAnimation, customStartPage, switchedFromGamepadInput)
		end)

		if not ok then
			warn("[Topbar] SettingsHub:SetVisibility failed; using visual fallback:", err)
			forceHubVisualState(hub, visible, customStartPage)
		end

		-- Verify the state because some old SettingsHub code paths can return
		-- successfully without making the PlayerGui version visible.
		local actual = nil
		local readOk, readResult = pcall(function()
			return hub:GetVisibility()
		end)
		if readOk then
			actual = readResult == true
		elseif hub.Instance then
			actual = hub.Instance.Visible == true
		end

		if actual ~= (visible == true) then
			warn("[Topbar] SettingsHub visibility did not change; forcing GUI state")
			forceHubVisualState(hub, visible, customStartPage)
		end

		onVisibilityChanged(visible == true)
		return true
	end

	local function toggleSettings(switchedFromGamepadInput)
		local hub = ensureHub()
		if not hub then
			warn("[Topbar] SettingsHub unavailable")
			return settingsActive
		end

		local currentlyVisible = false
		local ok, value = pcall(function()
			return hub:GetVisibility()
		end)

		if ok then
			currentlyVisible = value == true
		elseif hub.Instance then
			currentlyVisible = hub.Instance.Visible == true
		else
			currentlyVisible = settingsActive
		end

		setVisible(not currentlyVisible, false, nil, switchedFromGamepadInput)
		return not currentlyVisible
	end

	-- Dedicated capture button so no other transparent topbar GUI can eat the click.
	local settingsClickCapture = Util.Create'TextButton'
	{
		Name = "SettingsClickCapture";
		Size = UDim2.new(1, 0, 1, 0);
		Position = UDim2.new(0, 0, 0, 0);
		BackgroundTransparency = 1;
		Text = "";
		AutoButtonColor = false;
		Active = true;
		Selectable = true;
		ZIndex = 100;
		Parent = settingsIconButton;
	}

	local hamburgerBusy = false

	local function hamburgerActivated()
		if hamburgerBusy then return end
		hamburgerBusy = true

		task.spawn(function()
			local hub = LoadSettingsHub()
			if not hub then
				warn("[Topbar] Hamburger: SettingsHub failed to load")
				hamburgerBusy = false
				return
			end

			MenuModule = hub
			connectSignal()

			local ok, err = pcall(function()
				hub:ToggleVisibility(false)
			end)

			if not ok then
				warn("[Topbar] Hamburger: SettingsHub:ToggleVisibility failed:", err)
			end

			-- The hub's SettingsShowSignal is authoritative for the icon.
			task.delay(0.1, function()
				onVisibilityChanged(readVisibility())
				hamburgerBusy = false
			end)
		end)
	end

	settingsClickCapture.Activated:Connect(hamburgerActivated)

	local menuItem = CreateMenuItem(settingsIconButton)

	rawset(menuItem, "SetTransparency", function(self, transparency)
		settingsIconImage.ImageTransparency = transparency
	end)

	rawset(menuItem, "SetImage", function(self, image)
		settingsIconImage.Image = image
	end)

	rawset(menuItem, "SetSettingsActive", function(self, active)
		setVisible(active == true)
		return readVisibility()
	end)

	-- Exact SettingsHub API helpers from settings2016.rbxm.
	rawset(menuItem, "OpenSettings", function(self, customStartPage)
		return setVisible(true, false, customStartPage, false)
	end)

	rawset(menuItem, "CloseSettings", function(self)
		return setVisible(false)
	end)

	rawset(menuItem, "ToggleSettings", function(self, switchedFromGamepadInput)
		local hub = LoadSettingsHub()
		if not hub then return false end

		local ok, err = pcall(function()
			hub:ToggleVisibility(switchedFromGamepadInput)
		end)
		if not ok then
			warn("[Topbar] SettingsHub:ToggleVisibility failed:", err)
			return false
		end

		MenuModule = hub
		connectSignal()
		onVisibilityChanged(readVisibility())
		return readVisibility()
	end)

	rawset(menuItem, "GetSettingsVisibility", function(self)
		ensureHub()
		return readVisibility()
	end)

	rawset(menuItem, "SwitchSettingsPage", function(self, pageToSwitchTo, ignoreStack)
		local hub = ensureHub()
		if not hub then return false end
		return pcall(function()
			hub:SwitchToPage(pageToSwitchTo, ignoreStack)
		end)
	end)

	rawset(menuItem, "ReportPlayer", function(self, player)
		local hub = ensureHub()
		if not hub or type(hub.ReportPlayer) ~= "function" then
			return false
		end
		return pcall(function()
			hub:ReportPlayer(player)
		end)
	end)

	rawset(menuItem, "ShowSettingsShield", function(self)
		local hub = ensureHub()
		if not hub then return false end
		return pcall(function()
			hub:ShowShield()
		end)
	end)

	rawset(menuItem, "HideSettingsShield", function(self)
		local hub = ensureHub()
		if not hub then return false end
		return pcall(function()
			hub:HideShield()
		end)
	end)

	-- Full SettingsHub.Instance compatibility API.
	local function getInstance()
		local hub = ensureHub()
		return hub and hub.Instance or nil
	end

	rawset(menuItem, "GetSettingsInstance", function(self)
		return getInstance()
	end)

	rawset(menuItem, "AddSettingsPage", function(self, pageToAdd)
		local instance = getInstance()
		if not instance or type(instance.AddPage) ~= "function" then return false end
		return pcall(function()
			instance:AddPage(pageToAdd)
		end)
	end)

	rawset(menuItem, "RemoveSettingsPage", function(self, pageToRemove)
		local instance = getInstance()
		if not instance or type(instance.RemovePage) ~= "function" then return false end
		return pcall(function()
			instance:RemovePage(pageToRemove)
		end)
	end)

	rawset(menuItem, "HideSettingsBar", function(self)
		local instance = getInstance()
		if not instance or type(instance.HideBar) ~= "function" then return false end
		return pcall(function()
			instance:HideBar()
		end)
	end)

	rawset(menuItem, "ShowSettingsBar", function(self)
		local instance = getInstance()
		if not instance or type(instance.ShowBar) ~= "function" then return false end
		return pcall(function()
			instance:ShowBar()
		end)
	end)

	rawset(menuItem, "ScrollSettingsPixels", function(self, pixels)
		local instance = getInstance()
		if not instance or type(instance.ScrollPixels) ~= "function" then return false end
		return pcall(function()
			instance:ScrollPixels(pixels)
		end)
	end)

	rawset(menuItem, "ScrollSettingsToFrame", function(self, frame, forced)
		local instance = getInstance()
		if not instance or type(instance.ScrollToFrame) ~= "function" then return false end
		return pcall(function()
			instance:ScrollToFrame(frame, forced)
		end)
	end)

	rawset(menuItem, "SwitchSettingsPageFull", function(self, pageToSwitchTo, ignoreStack, direction, skipAnimation)
		local instance = getInstance()
		if not instance or type(instance.SwitchToPage) ~= "function" then return false end
		return pcall(function()
			instance:SwitchToPage(pageToSwitchTo, ignoreStack, direction, skipAnimation)
		end)
	end)

	rawset(menuItem, "SetSettingsHubActive", function(self, active)
		local instance = getInstance()
		if not instance or type(instance.SetActive) ~= "function" then return false end
		return pcall(function()
			instance:SetActive(active == true)
		end)
	end)

	rawset(menuItem, "AddToSettingsMenuStack", function(self, newItem)
		local instance = getInstance()
		if not instance or type(instance.AddToMenuStack) ~= "function" then return false end
		return pcall(function()
			instance:AddToMenuStack(newItem)
		end)
	end)

	rawset(menuItem, "PopSettingsMenu", function(self, switchedFromGamepadInput, skipAnimation)
		local instance = getInstance()
		if not instance or type(instance.PopMenu) ~= "function" then return false end
		return pcall(function()
			instance:PopMenu(switchedFromGamepadInput, skipAnimation)
		end)
	end)

	rawset(menuItem, "GetSettingsPoppedMenuSignal", function(self)
		local instance = getInstance()
		return instance and instance.PoppedMenu or nil
	end)

	rawset(menuItem, "GetSettingsShowSignal", function(self)
		local hub = ensureHub()
		return hub and hub.SettingsShowSignal or nil
	end)

	rawset(menuItem, "GetSettingsPages", function(self)
		local instance = getInstance()
		return instance and instance.Pages or nil
	end)

	rawset(menuItem, "GetCurrentSettingsPage", function(self)
		local instance = getInstance()
		return instance and instance.Pages and instance.Pages.CurrentPage or nil
	end)

	rawset(menuItem, "GetSettingsMenuStack", function(self)
		local instance = getInstance()
		return instance and instance.MenuStack or nil
	end)

	rawset(menuItem, "GetSettingsTabHeaders", function(self)
		local instance = getInstance()
		return instance and instance.TabHeaders or nil
	end)

	rawset(menuItem, "GetSettingsBottomBarButtons", function(self)
		local instance = getInstance()
		return instance and instance.BottomBarButtons or nil
	end)

	rawset(menuItem, "GetSettingsPageByName", function(self, pageName)
		local instance = getInstance()
		if not instance or type(pageName) ~= "string" then return nil end

		local pageMap = {
			LeaveGame = "LeaveGamePage",
			ResetCharacter = "ResetCharacterPage",
			Home = "HomePage",
			GameSettings = "GameSettingsPage",
			ReportAbuse = "ReportAbusePage",
			Help = "HelpPage",
			Record = "RecordPage",
			Players = "PlayersPage",
		}

		local field = pageMap[pageName] or pageName
		return instance[field]
	end)

	rawset(menuItem, "GetSettingsGuiObject", function(self, objectName)
		local instance = getInstance()
		if not instance or type(objectName) ~= "string" then return nil end

		local allowed = {
			ClippingShield = true,
			Shield = true,
			Modal = true,
			HubBar = true,
			PageViewClipper = true,
			PageView = true,
			BottomButtonFrame = true,
		}

		if allowed[objectName] then
			return instance[objectName]
		end
		return nil
	end)

	rawset(menuItem, "AddPage", function(self, ...)
		local hub = ensureHub()
		return hub and hub:AddPage(...) or nil
	end)

	rawset(menuItem, "RemovePage", function(self, ...)
		local hub = ensureHub()
		return hub and hub:RemovePage(...) or nil
	end)

	rawset(menuItem, "HideBar", function(self, ...)
		local hub = ensureHub()
		return hub and hub:HideBar(...) or nil
	end)

	rawset(menuItem, "ShowBar", function(self, ...)
		local hub = ensureHub()
		return hub and hub:ShowBar(...) or nil
	end)

	rawset(menuItem, "ScrollPixels", function(self, ...)
		local hub = ensureHub()
		return hub and hub:ScrollPixels(...) or nil
	end)

	rawset(menuItem, "ScrollToFrame", function(self, ...)
		local hub = ensureHub()
		return hub and hub:ScrollToFrame(...) or nil
	end)

	rawset(menuItem, "SetActive", function(self, ...)
		local hub = ensureHub()
		return hub and hub:SetActive(...) or nil
	end)

	rawset(menuItem, "AddToMenuStack", function(self, ...)
		local hub = ensureHub()
		return hub and hub:AddToMenuStack(...) or nil
	end)

	rawset(menuItem, "PopMenu", function(self, ...)
		local hub = ensureHub()
		return hub and hub:PopMenu(...) or nil
	end)

	rawset(menuItem, "GetSettingsState", function(self)
		local instance = getInstance()
		if not instance then return nil end

		return {
			Visible = instance.Visible,
			Active = instance.Active,
			OpenStateChangedCount = instance.OpenStateChangedCount,
			CurrentPage = instance.Pages and instance.Pages.CurrentPage or nil,
			MenuStack = instance.MenuStack,
		}
	end)

	rawset(menuItem, "PreflightSettingsHub", function(self)
		return PreflightSettingsHubDependencies()
	end)

	rawset(menuItem, "GetSettingsHub", function(self)
		return ensureHub()
	end)

	rawset(menuItem, "GetSettingsUtility", function(self)
		PrepareLegacyCoreCompat()
		return LoadSettingsUtility()
	end)

	rawset(menuItem, "GetSettingsPageFactory", function(self)
		PrepareLegacyCoreCompat()
		return LoadSettingsPageFactory()
	end)

	rawset(menuItem, "GetSettingsPageModule", function(self, pageName)
		PrepareLegacyCoreCompat()
		if type(pageName) ~= "string" then return nil end
		return LoadSettingsPageModule(pageName)
	end)

	rawset(menuItem, "GetSettingsModule", function(self, moduleName)
		PrepareLegacyCoreCompat()
		if type(moduleName) ~= "string" then return nil end

		if moduleName == "SettingsHub" then
			return ensureHub()
		elseif moduleName == "Utility" then
			return LoadSettingsUtility()
		elseif moduleName == "SettingsPageFactory" then
			return LoadSettingsPageFactory()
		end

		return LoadSettingsPageModule(moduleName)
	end)

	rawset(menuItem, "GetAllSettingsPages", function(self)
		PrepareLegacyCoreCompat()
		local result = {}
		for _, pageName in ipairs({
			"GameSettings",
			"Help",
			"Home",
			"LeaveGame",
			"ResetCharacter",
			"Record",
			"Players",
			"ReportAbuseMenu",
			}) do
			result[pageName] = LoadSettingsPageModule(pageName)
		end
		return result
	end)

	return menuItem
end

local function Create3DSettingsIcon(topBarInstance, panel, menubar)
	local MenuModule = LoadSettingsHub()
	if not MenuModule then return nil end
	local menuItem = Create3DMenuItem()
	menuItem:SetHoverText("Settings")

	local icon = Util.Create "ImageLabel" {
		Parent = menuItem:GetInstance(),

		Position = UDim2.new(0.5, -15, 0.5, -11),
		Size = UDim2.new(0, 30, 0, 22),

		BackgroundTransparency = 1,

		Image = "rbxasset://textures/ui/Menu/hamburger3D.png"
	}

	menuItem.MouseButton1Click:connect(function()
		MenuModule:SetVisibility(true)
		menubar:CloseAllExcept(menuItem)
	end)

	local settingsPanel = Panel3D.Get("SettingsMenu")
	function settingsPanel:OnVisibilityChanged(visible)
		menuItem:SetActive(visible)
	end

	return menuItem
end

------------

--- CHAT ---
local function CreateUnreadMessagesNotifier(ChatModule)
	local chatActive = false
	local lastMessageCount = 0

	local chatCounter = Util.Create'ImageLabel'
	{
		Name = "ChatCounter";
		Size = UDim2.new(0, 18, 0, 18);
		Position = UDim2.new(1, -12, 0, -4);
		BackgroundTransparency = 1;
		Image = "rbxasset://textures/ui/Chat/MessageCounter.png";
		Visible = false;
	};

	local chatCountText = Util.Create'TextLabel'
	{
		Name = "ChatCounterText";
		Text = '';
		Size = UDim2.new(0, 13, 0, 9);
		Position = UDim2.new(0.5, -7, 0.5, -7);
		Font = Enum.Font.SourceSansBold;
		FontSize = Enum.FontSize.Size14;
		BorderSizePixel = 0;
		BackgroundTransparency = 1;
		TextColor3 = FONT_COLOR;
		TextYAlignment = Enum.TextYAlignment.Center;
		TextXAlignment = Enum.TextXAlignment.Center;
		Parent = chatCounter;
	};

	local function OnUnreadMessagesChanged(count)
		if chatActive then
			lastMessageCount = count
		end
		local unreadCount = count - lastMessageCount

		if unreadCount <= 0 then
			chatCountText.Text = ""
			chatCounter.Visible = false
		else
			if unreadCount < 100 then
				chatCountText.Text = tostring(unreadCount)
			else
				chatCountText.Text = "!"
			end
			chatCounter.Visible = true
		end
	end

	local function onChatStateChanged(visible)
		chatActive = visible
		if ChatModule then
			OnUnreadMessagesChanged(ChatModule:GetMessageCount())
		end
	end


	if ChatModule then
		if ChatModule.VisibilityStateChanged then
			ChatModule.VisibilityStateChanged:connect(onChatStateChanged)
		end
		if ChatModule.MessagesChanged then
			ChatModule.MessagesChanged:connect(OnUnreadMessagesChanged)
		end

		onChatStateChanged(ChatModule:GetVisibility())
		OnUnreadMessagesChanged(ChatModule:GetMessageCount())
	end

	return chatCounter
end

local function CreateChatIcon()
	local chatIconButton = Util.Create'ImageButton'
	{
		Name = "Chat";
		Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
		Image = "";
		AutoButtonColor = false;
		BackgroundTransparency = 1;
		Active = true;
		Selectable = true;
		ZIndex = 50;
	};

	local chatIconImage = Util.Create'ImageLabel'
	{
		Name = "ChatIcon";
		Size = UDim2.new(0, 28, 0, 27);
		ZIndex = 51;
		Active = false;
		Position = UDim2.new(0.5, -14, 0.5, -13);
		BackgroundTransparency = 1;
		Image = "rbxasset://textures/ui/Chat/Chat.png";
		Parent = chatIconButton;
	};

	local function getTextButton()
		local button = GuiRoot:FindFirstChild("TextButton")
		if button and button:IsA("TextButton") then
			return button
		end
		return nil
	end

	local function getWindow()
		return TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
			or TextChatService:FindFirstChild("ChatWindowConfiguration")
	end

	local function getInput()
		return TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")
			or TextChatService:FindFirstChild("ChatInputBarConfiguration")
	end

	local function getVisible()
		local button = getTextButton()
		if button then
			return button.Visible
		end

		if ChatModule and type(ChatModule.GetVisibility) == "function" then
			local ok, visible = pcall(function()
				return ChatModule:GetVisibility()
			end)
			if ok then return visible == true end
		end

		local window = getWindow()
		return window and window.Enabled or false
	end

	local function updateIcon(visible)
		chatIconImage.Image = visible
			and "rbxasset://textures/ui/Chat/ChatDown.png"
			or "rbxasset://textures/ui/Chat/Chat.png"
	end

	local function setVisible(visible)
		local button = getTextButton()
		if button then
			button.Visible = visible
		end

		if ChatModule then
			pcall(function()
				if type(ChatModule.SetVisible) == "function" then
					ChatModule:SetVisible(visible)
				elseif type(ChatModule.GetVisibility) == "function"
					and type(ChatModule.ToggleVisibility) == "function"
					and (ChatModule:GetVisibility() == true) ~= visible then
					ChatModule:ToggleVisibility()
				end
			end)
		else
			local window = getWindow()
			local input = getInput()
			if window then window.Enabled = visible end
			if input then input.Enabled = visible end
		end

		updateIcon(visible)
	end

	local chatIconActive = false

	chatIconButton.Activated:Connect(function()
		-- On mobile, the Chat button should ONLY focus the chat bar for
		-- typing mode (2016 Roblox behavior). It must NOT toggle chat
		-- visibility — that is handled by the separate Show/Hide Chat button.
		if Util.IsTouchDevice() then
			chatIconActive = not chatIconActive
			updateIcon(chatIconActive)
			if ChatModule and type(ChatModule.FocusChatBar) == "function" then
				pcall(function()
					ChatModule:FocusChatBar()
				end)
			end
			return
		end

		-- Desktop keeps the normal visibility toggle behavior.
		if ChatModule and type(ChatModule.ToggleVisibility) == "function" then
			local ok = pcall(function()
				ChatModule:ToggleVisibility()
			end)
			if ok then
				local visible = getVisible()
				local button = getTextButton()
				if button then button.Visible = visible end
				updateIcon(visible)
				return
			end
		end

		setVisible(not getVisible())
	end)

	local menuItem = CreateMenuItem(chatIconButton)

	rawset(menuItem, "ToggleChat", function(self)
		setVisible(not getVisible())
	end)

	rawset(menuItem, "SetTransparency", function(self, transparency)
		chatIconImage.ImageTransparency = transparency
	end)

	rawset(menuItem, "SetImage", function(self, newImage)
		chatIconImage.Image = newImage
	end)

	rawset(menuItem, "AttachChatModule", function(self, module)
		ChatModule = CompleteChatAPI(module)
		if not module then
			return
		end

		-- Exact public API/events exposed by Chat in 2016prototype.rbxm.
		if module.VisibilityStateChanged then
			pcall(function()
				module.VisibilityStateChanged:connect(function(visible)
					local button = getTextButton()
					if button then button.Visible = visible == true end
					-- Do NOT update the Chat icon here on mobile — the Chat icon
					-- is controlled by the Chat button click, not by visibility.
					if not Util.IsTouchDevice() then
						updateIcon(visible == true)
					end
				end)
			end)
		end

		if module.ChatBarFocusChanged then
			pcall(function()
				module.ChatBarFocusChanged:connect(function(isFocused)
					if Util.IsTouchDevice() then
						-- On mobile, the Chat icon follows focus state, not visibility.
						chatIconActive = isFocused == true
						updateIcon(chatIconActive)
					else
						updateIcon(getVisible())
					end
				end)
			end)
		end

		if not Util.IsTouchDevice()
			and type(module.GetMessageCount) == "function"
			and module.MessagesChanged then
			local chatCounter = CreateUnreadMessagesNotifier(module)
			chatCounter.Parent = chatIconImage
		end

		if Util.IsTouchDevice() then
			updateIcon(false)
		else
			updateIcon(getVisible())
		end
	end)

	rawset(menuItem, "FocusChatBar", function(self)
		if ChatModule and type(ChatModule.FocusChatBar) == "function" then
			return pcall(function()
				ChatModule:FocusChatBar()
			end)
		end
		return false
	end)

	rawset(menuItem, "GetChatVisibility", function(self)
		return getVisible()
	end)

	rawset(menuItem, "GetChatMessageCount", function(self)
		if ChatModule and type(ChatModule.GetMessageCount) == "function" then
			local ok, count = pcall(function()
				return ChatModule:GetMessageCount()
			end)
			if ok then return count end
		end
		return 0
	end)

	rawset(menuItem, "GetChatModule", function(self)
		return ChatModule
	end)

	topbarEnabledChangedEvent.Event:connect(function()
		if ChatModule and type(ChatModule.TopbarEnabledChanged) == "function" then
			pcall(function()
				ChatModule:TopbarEnabledChanged(topbarEnabled)
			end)
		end
	end)

	if Util.IsTouchDevice() then
		updateIcon(false)
	else
		updateIcon(getVisible())
	end
	return menuItem
end

local function CreateMobileHideChatIcon()
	if not Util.IsTouchDevice() then
		return nil
	end

	local button = Util.Create'ImageButton'
	{
		Name = "ShowChat";
		Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Image = "";
		AutoButtonColor = false;
		Active = true;
		Selectable = true;
		ZIndex = 50;
	};

	local icon = Util.Create'ImageLabel'
	{
		Name = "ToggleChatIcon";
		Size = UDim2.new(0, 28, 0, 28);
		Position = UDim2.new(0.5, -14, 0.5, -14);
		BackgroundTransparency = 1;
		Image = "rbxasset://textures/ui/Chat/ToggleChat.png";
		Active = false;
		ZIndex = 51;
		Parent = button;
	};

	local menuItem = CreateMenuItem(button)

	local function getWindow()
		return TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
			or TextChatService:FindFirstChild("ChatWindowConfiguration")
	end

	local function getInput()
		return TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")
			or TextChatService:FindFirstChild("ChatInputBarConfiguration")
	end

	local function forceLegacyChatWindowVisible(visible)
		-- The 2016 Chat module can update its own Visible state before its
		-- ChatWindowContainer catches up on mobile. Force the actual window too.
		local chatWindow = GuiRoot:FindFirstChild("ChatWindowContainer", true)
		if chatWindow and chatWindow:IsA("GuiObject") then
			chatWindow.Visible = visible == true
		end
	end

	local function queryVisible()
		if ChatModule and type(ChatModule.GetVisibility) == "function" then
			local ok, visible = pcall(function()
				return ChatModule:GetVisibility()
			end)
			if ok then
				return visible == true
			end
		end

		local window = getWindow()
		if window then
			return window.Enabled == true
		end

		return false
	end

	local mobileChatVisible = queryVisible()

	local function updateIcon()
		icon.Image = mobileChatVisible
			and "rbxasset://textures/ui/Chat/ToggleChatDown.png"
			or "rbxasset://textures/ui/Chat/ToggleChat.png"
	end

	local function applyVisible(visible)
		mobileChatVisible = visible == true

		if ChatModule then
			if type(ChatModule.SetVisible) == "function" then
				pcall(function()
					ChatModule:SetVisible(mobileChatVisible)
				end)
			elseif type(ChatModule.ToggleVisibility) == "function" then
				local current = queryVisible()
				if current ~= mobileChatVisible then
					pcall(function()
						ChatModule:ToggleVisibility()
					end)
				end
			end
		end

		-- This is the important mobile fix: make the actual 2016
		-- ChatWindowContainer follow the Show Chat toggle immediately.
		forceLegacyChatWindowVisible(mobileChatVisible)

		-- Some old chat code updates one task later, so enforce it once more
		-- after the module has processed SetVisible().
		task.defer(function()
			forceLegacyChatWindowVisible(mobileChatVisible)
		end)

		-- The generic Chat icon remains responsible for focusing the input.
		-- Do not focus the chat bar here.
		local input = getInput()
		if input then
			input.Enabled = true
		end

		updateIcon()
	end

	button.Activated:Connect(function()
		-- IMPORTANT: toggle our own state instead of immediately re-reading the
		-- chat module. The old chat module can report its previous state for a frame.
		applyVisible(not mobileChatVisible)
	end)

	rawset(menuItem, "SetChatVisible", function(self, visible)
		applyVisible(visible == true)
	end)

	rawset(menuItem, "GetChatVisibility", function(self)
		return mobileChatVisible
	end)

	rawset(menuItem, "SetTransparency", function(self, transparency)
		icon.ImageTransparency = transparency
	end)

	rawset(menuItem, "AttachChatModule", function(self, module)
		ChatModule = CompleteChatAPI(module)
		mobileChatVisible = queryVisible()
		updateIcon()

		if ChatModule and ChatModule.VisibilityStateChanged then
			pcall(function()
				ChatModule.VisibilityStateChanged:connect(function(visible)
					mobileChatVisible = visible == true
					forceLegacyChatWindowVisible(mobileChatVisible)
					updateIcon()
				end)
			end)
		end
	end)

	updateIcon()
	return menuItem
end


local function Create3DChatIcon(topBarInstance, panel, menubar)
	local chatEnabled = game:GetService("UserInputService"):GetPlatform() ~= Enum.Platform.XBoxOne
	if not chatEnabled then return end

	local ChatModule = require(GuiRoot.Modules.Chat)

	local menuItem = Create3DMenuItem()
	menuItem:SetHoverText("Chat")

	local icon = Util.Create "ImageLabel" {
		Parent = menuItem:GetInstance(),

		Position = UDim2.new(0.5, -14, 0.5, -12),
		Size = UDim2.new(0, 28, 0, 28),

		BackgroundTransparency = 1,

		Image = "rbxasset://textures/ui/Chat/Chat.png"
	}

	menuItem.MouseButton1Click:connect(function()
		ChatModule:SetVisible(not ChatModule:GetVisibility())
		if ChatModule:GetVisibility() then
			ChatModule:FocusChatBar()
		end
		menubar:CloseAllExcept(menuItem)
	end)

	local closedEventConn = nil
	local function OnVREnabled(prop)
		if prop == 'VREnabled' then
			if closedEventConn then
				closedEventConn:disconnect()
				closedEventConn = nil
			end
			if InputService.VREnabled then
				local VirtualKeyboardModule = require(GuiRoot.Modules.VR.VirtualKeyboard)
				closedEventConn = VirtualKeyboardModule.ClosedEvent:connect(function()
					if ChatModule:IsFocused(true) then
						ChatModule:SetVisible(false)
					end
				end)
			end
		end
	end
	InputService.Changed:connect(OnVREnabled)
	spawn(function() OnVREnabled("VREnabled") end)


	local chatPanel = Panel3D.Get("Chat")
	function chatPanel:OnVisibilityChanged(visible)
		menuItem:SetActive(visible)
	end

	return menuItem
end

local function Create3DUserGuiToggleIcon(topBarInstance, panel, menubar)
	local menuItem = Create3DMenuItem()
	menuItem:SetHoverText("2D UI")

	local icon = Util.Create "ImageLabel" {
		Parent = menuItem:GetInstance(),

		Position = UDim2.new(0.5, -14, 0.5, -14),
		Size = UDim2.new(0, 28, 0, 28),

		BackgroundTransparency = 1,

		Image = "rbxasset://textures/ui/VR/toggle2D.png"
	}

	local userGuiPanel = Panel3D.Get("UserGui")
	userGuiPanel:SetType(Panel3D.Type.Fixed)
	userGuiPanel:ResizePixels(300, 125)
	userGuiPanel:SetVisible(false, false)

	menuItem.MouseButton1Click:connect(function()
		if InputService.VREnabled then
			userGuiPanel:SetVisible(not userGuiPanel.isVisible, false)
		end
	end)

	function userGuiPanel:OnVisibilityChanged(visible)
		if visible then
			local headLook = Panel3D.GetHeadLookXZ(true)
			userGuiPanel.localCF = headLook * CFrame.Angles(math.rad(5), 0, 0) * CFrame.new(0, 0, 5)
		end
		menuItem:SetActive(visible)
		local success, msg = pcall(function()
			CoreGuiService:SetUserGuiRendering(true, visible and userGuiPanel:GetPart() or nil, Enum.NormalId.Front)
		end)
	end

	local function OnVREnabled(prop)
		if prop == 'VREnabled' then
			local guiPart = nil
			if InputService.VREnabled then
				if userGuiPanel.isVisible then
					guiPart = userGuiPanel:GetPart()
				end
			else
				userGuiPanel:SetVisible(false, false)
			end
			local success, msg = pcall(function()
				CoreGuiService:SetUserGuiRendering(InputService.VREnabled, guiPart, Enum.NormalId.Front)
			end)
		end
	end
	InputService.Changed:connect(OnVREnabled)
	spawn(function() OnVREnabled("VREnabled") end)

	return menuItem
end

-----------

--- Backpack ---
local function CreateBackpackIcon()
	local backpackIconButton = Util.Create'ImageButton'
	{
		Name = "Backpack";
		Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
		Image = "";
		AutoButtonColor = false;
		BackgroundTransparency = 1;
		Active = true;
		Selectable = true;
		ZIndex = 50;
	};

	local backpackIconImage = Util.Create'ImageLabel'
	{
		Name = "BackpackIcon";
		Size = UDim2.new(0, 22, 0, 28);
		ZIndex = 51;
		Active = false;
		Position = UDim2.new(0.5, -11, 0.5, -14);
		BackgroundTransparency = 1;
		Image = "rbxasset://textures/ui/Backpack/Backpack.png";
		Parent = backpackIconButton;
	};

	local function loadBackpack()
		PrepareLegacyCoreCompat()
		LoadTenFootInterface()

		if BackpackModule then
			return BackpackModule
		end
		BackpackModule = CompleteBackpackAPI(SafeRequire(Modules:FindFirstChild("BackpackScript"), "BackpackScript"))
		return BackpackModule
	end

	local function updateState(open)
		backpackIconImage.Image = open
			and "rbxasset://textures/ui/Backpack/Backpack_Down.png"
			or "rbxasset://textures/ui/Backpack/Backpack.png"
	end

	backpackIconButton.Activated:Connect(function()
		local module = loadBackpack()
		if module and type(module.OpenClose) == "function" then
			module:OpenClose()
		end
	end)

	local menuItem = CreateMenuItem(backpackIconButton)

	rawset(menuItem, "AttachBackpackModule", function(self, module)
		BackpackModule = module
		if not module then return end

		if module.StateChanged and module.StateChanged.Event then
			module.StateChanged.Event:connect(updateState)
		end

		if module.IsOpen ~= nil then
			updateState(module.IsOpen == true)
		end
	end)

	rawset(menuItem, "ToggleBackpack", function(self)
		local module = BackpackModule or loadBackpack()
		if module and type(module.OpenClose) == "function" then
			return pcall(function()
				module:OpenClose()
			end)
		end
		return false
	end)

	rawset(menuItem, "GetBackpackOpen", function(self)
		local module = BackpackModule
		return module and module.IsOpen == true or false
	end)

	rawset(menuItem, "GetBackpackStateChanged", function(self)
		local module = BackpackModule
		return module and module.StateChanged or nil
	end)

	rawset(menuItem, "GetBackpackModule", function(self)
		return BackpackModule
	end)

	topbarEnabledChangedEvent.Event:connect(function()
		if BackpackModule and type(BackpackModule.TopbarEnabledChanged) == "function" then
			pcall(function()
				BackpackModule:TopbarEnabledChanged(topbarEnabled)
			end)
		end
	end)

	return menuItem
end

--------------

----- Stop Recording --
local function CreateStopRecordIcon()
	local stopRecordIconButton = Util.Create'ImageButton'
	{
		Name = "StopRecording";
		Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
		Image = "";
		Visible = true;
		BackgroundTransparency = 1;
	};
	--stopRecordIconButton:SetVerb("RecordToggle")

	local stopRecordIconLabel = Util.Create'ImageLabel'
	{
		Name = "StopRecordingIcon";
		Size = UDim2.new(0, 28, 0, 28);
		Position = UDim2.new(0.5, -14, 0.5, -14);
		BackgroundTransparency = 1;
		Image = "rbxasset://textures/ui/RecordDown.png";
		Parent = stopRecordIconButton;
	};

	return CreateMenuItem(stopRecordIconButton)
end
-----------------------

local TopBar = CreateTopBar()
TopBar:GetInstance().Position = UDim2.new(0, 0, 0, 0)
TopBar:GetInstance().Visible = true
TopBar:GetInstance().ClipsDescendants = false

-- Keep the shared RobloxGui's inset behavior untouched; SettingsHub and other
-- 2016 modules live under the same ScreenGui. We only make the topbar itself
-- responsive instead of forcing IgnoreGuiInset for the whole UI.
local LeftMenubar = CreateMenuBar(BarAlignmentEnum.Left)
local RightMenubar = CreateMenuBar(BarAlignmentEnum.Right)
--local ThreeDMenubar = Create3DMenuBar(BarAlignmentEnum.Left, Topbar3DPanel)

local settingsIcon = CreateSettingsIcon(TopBar)
local mobileShowChatIcon = Util.IsTouchDevice() and CreateMobileHideChatIcon() or nil
local chatIcon = CreateChatIcon()
local backpackIcon = CreateBackpackIcon()
local stopRecordingIcon = CreateStopRecordIcon()

local leaderstatsMenuItem = CreateLeaderstatsMenuItem()
local nameAndHealthMenuItem = CreateUsernameHealthMenuItem()

local settingsIcon3D = nil
local chatIcon3D = nil
local userGuiIcon3D = nil

local LEFT_ITEM_ORDER = {}
local RIGHT_ITEM_ORDER = {}
local THREE_D_ITEM_ORDER = {}


-- Set Item Orders
if settingsIcon then
	LEFT_ITEM_ORDER[settingsIcon] = 1
end
if mobileShowChatIcon then
	LEFT_ITEM_ORDER[mobileShowChatIcon] = 2
end
if chatIcon then
	LEFT_ITEM_ORDER[chatIcon] = 3
end
if backpackIcon then
	LEFT_ITEM_ORDER[backpackIcon] = 4
end
if stopRecordingIcon then
	LEFT_ITEM_ORDER[stopRecordingIcon] = 5
end

if leaderstatsMenuItem then
	RIGHT_ITEM_ORDER[leaderstatsMenuItem] = 1
end
if nameAndHealthMenuItem and not isTenFootInterface then
	RIGHT_ITEM_ORDER[nameAndHealthMenuItem] = 2
end

if settingsIcon3D then
	THREE_D_ITEM_ORDER[settingsIcon3D] = 1
end
if chatIcon3D then
	THREE_D_ITEM_ORDER[chatIcon3D] = 2
end
if userGuiIcon3D then
	THREE_D_ITEM_ORDER[userGuiIcon3D] = 3
end

-------------------------


local function AddItemInOrder(Bar, Item, ItemOrder)
	local index = 1
	while ItemOrder[Bar:ItemAtIndex(index)] and ItemOrder[Bar:ItemAtIndex(index)] < ItemOrder[Item] do
		index = index + 1
	end
	Bar:AddItem(Item, index)
end

local function OnCoreGuiChanged(coreGuiType, coreGuiEnabled)
	local enabled = coreGuiEnabled and topbarEnabled
	enabled = true
	if coreGuiType == Enum.CoreGuiType.PlayerList or coreGuiType == Enum.CoreGuiType.All then
		if leaderstatsMenuItem then
			if enabled then
				AddItemInOrder(RightMenubar, leaderstatsMenuItem, RIGHT_ITEM_ORDER)
			else
				RightMenubar:RemoveItem(leaderstatsMenuItem)
			end
		end
	end
	if coreGuiType == Enum.CoreGuiType.Health or coreGuiType == Enum.CoreGuiType.All then
		if nameAndHealthMenuItem then
			nameAndHealthMenuItem:SetHealthbarEnabled(enabled)
		end
	end
	if coreGuiType == Enum.CoreGuiType.Backpack or coreGuiType == Enum.CoreGuiType.All then
		if backpackIcon then
			if enabled then
				AddItemInOrder(LeftMenubar, backpackIcon, LEFT_ITEM_ORDER)
			else
				LeftMenubar:RemoveItem(backpackIcon)
			end
		end
	end
	if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
		local showTopbarChatIcon = enabled
		local showThree3DChatIcon = coreGuiEnabled and InputService.VREnabled

		if showThree3DChatIcon then
			if chatIcon3D then
				AddItemInOrder(ThreeDMenubar, chatIcon3D, THREE_D_ITEM_ORDER)
			end
		else
			if chatIcon3D then
				ThreeDMenubar:RemoveItem(chatIcon3D)
			end
		end
		if showTopbarChatIcon then
			if chatIcon then
				AddItemInOrder(LeftMenubar, chatIcon, LEFT_ITEM_ORDER)
			end
			if mobileShowChatIcon and PlayersService.ClassicChat then
				AddItemInOrder(LeftMenubar, mobileShowChatIcon, LEFT_ITEM_ORDER)
			end
		else
			if chatIcon then
				LeftMenubar:RemoveItem(chatIcon)
			end
			if mobileShowChatIcon then
				LeftMenubar:RemoveItem(mobileShowChatIcon)
			end
		end
	end

	if nameAndHealthMenuItem then
		local playerListOn = true
		local healthbarOn = true
		-- Left-align the player's name if either playerlist or healthbar is shown
		nameAndHealthMenuItem:SetNameVisible((playerListOn or healthbarOn) and topbarEnabled)
	end
end


TopBar:UpdateBackgroundTransparency()

LeftMenubar:SetDock(TopBar:GetInstance())
RightMenubar:SetDock(TopBar:GetInstance())
--ThreeDMenubar:SetDock(Topbar3DPanel:GetGUI())


if not isTenFootInterface then
	Util.SetGUIInsetBounds(0, TOPBAR_THICKNESS, 0, 0)
end

if settingsIcon then
	AddItemInOrder(LeftMenubar, settingsIcon, LEFT_ITEM_ORDER)
end
if nameAndHealthMenuItem and topbarEnabled and not isTenFootInterface then
	AddItemInOrder(RightMenubar, nameAndHealthMenuItem, RIGHT_ITEM_ORDER)
end


-- --------------------------------------------------------------------------
-- IMPORTANT: PlayerlistModule itself originally returns early on small touch screens.
-- Use OldRobloxify_PlayerlistModule_MobileEnabled.lua as Modules.PlayerlistModule
-- or the topbar button will fire correctly but the module will intentionally refuse to open.
-- -- MOBILE / TOUCH TOPBAR COMPATIBILITY
-- --------------------------------------------------------------------------
local function SetBarItemPresent(bar, item, orderTable, shouldBePresent)
	if not item then return end

	local existingIndex = bar:IndexOfItem(item)
	if shouldBePresent then
		if not existingIndex then
			AddItemInOrder(bar, item, orderTable)
		end
	else
		if existingIndex then
			bar:RemoveItem(item)
		end
	end
end

local function ApplyResponsiveTopbarLayout()
	local isTouch = Util.IsTouchDevice()
	local compactTouch = Util.IsCompactTouchDevice()
	local verySmallTouch = Util.IsVerySmallTouchDevice()
	local viewport = Util.GetViewportSize()

	-- Keep the classic 36px appearance, but make the available controls
	-- large enough to tap reliably on phones.
	if settingsIcon then
		settingsIcon.Size = UDim2.new(0, isTouch and 52 or 50, 0, TOPBAR_THICKNESS)
	end
	if chatIcon then
		chatIcon.Size = UDim2.new(0, isTouch and 52 or 50, 0, TOPBAR_THICKNESS)
	end
	if backpackIcon then
		backpackIcon.Size = UDim2.new(0, isTouch and 52 or 50, 0, TOPBAR_THICKNESS)
	end

	-- Desktop-only information takes a huge amount of horizontal space.
	-- On phones, prioritize controls over username/health/leaderstats.
	if compactTouch then
		-- Keep the username/health item as the mobile Playerlist button.
		-- The previous mobile patch removed BOTH right-side items, which meant
		-- there was no control left that could open the custom 2016 playerlist.
		if nameAndHealthMenuItem and topbarEnabled and not isTenFootInterface then
			nameAndHealthMenuItem.Size = UDim2.new(0, math.min(120, math.max(88, viewport.X * 0.28)), 1, 0)
			nameAndHealthMenuItem:SetNameVisible(true)
			nameAndHealthMenuItem:SetHealthbarEnabled(false)
			SetBarItemPresent(RightMenubar, nameAndHealthMenuItem, RIGHT_ITEM_ORDER, true)
		end
		SetBarItemPresent(RightMenubar, leaderstatsMenuItem, RIGHT_ITEM_ORDER, false)

		-- Recording is not useful enough to steal scarce mobile topbar space.
		SetBarItemPresent(LeftMenubar, stopRecordingIcon, LEFT_ITEM_ORDER, false)

		-- Settings and Chat always stay available.
		SetBarItemPresent(LeftMenubar, settingsIcon, LEFT_ITEM_ORDER, settingsIcon ~= nil)
		SetBarItemPresent(LeftMenubar, chatIcon, LEFT_ITEM_ORDER, chatIcon ~= nil)

		-- On very narrow phones keep Backpack too if there is still room;
		-- three 52px buttons fit comfortably on common phone widths.
		SetBarItemPresent(LeftMenubar, backpackIcon, LEFT_ITEM_ORDER,
			backpackIcon ~= nil and viewport.X >= 260)
	else
		-- Tablet / desktop restores the normal layout.
		if nameAndHealthMenuItem and topbarEnabled and not isTenFootInterface then
			nameAndHealthMenuItem.Size = UDim2.new(0, USERNAME_CONTAINER_WIDTH, 1, 0)
			nameAndHealthMenuItem:SetNameVisible(true)
			nameAndHealthMenuItem:SetHealthbarEnabled(true)
			SetBarItemPresent(RightMenubar, nameAndHealthMenuItem, RIGHT_ITEM_ORDER, true)
		end

		SetBarItemPresent(LeftMenubar, settingsIcon, LEFT_ITEM_ORDER, settingsIcon ~= nil)
		SetBarItemPresent(LeftMenubar, chatIcon, LEFT_ITEM_ORDER, chatIcon ~= nil)
		SetBarItemPresent(LeftMenubar, backpackIcon, LEFT_ITEM_ORDER, backpackIcon ~= nil)
	end

	LeftMenubar:ArrangeItems()
	RightMenubar:ArrangeItems()

	-- Avoid stale selections after rotating/resizing on touch.
	if isTouch then
		pcall(function()
			GuiService.SelectedObject = nil
		end)
	end
end

ApplyResponsiveTopbarLayout()

-- Mobile can tap the Playerlist control immediately after the topbar appears.
-- Start loading the old module now so the first tap has a real target.
if Util.IsTouchDevice() then
	task.defer(function()
		local module = LoadPlayerlistModule()
		if module and leaderstatsMenuItem and leaderstatsMenuItem.AttachPlayerlistModule then
			leaderstatsMenuItem:AttachPlayerlistModule(module)
		end
	end)
end

-- Re-layout when rotating a phone/tablet or resizing Studio's emulator.
local viewportConnection = nil
local function ConnectViewportListener()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end

	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			task.defer(ApplyResponsiveTopbarLayout)
		end)
	end
end

ConnectViewportListener()

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	ConnectViewportListener()
	task.defer(ApplyResponsiveTopbarLayout)
end)

InputService:GetPropertyChangedSignal("TouchEnabled"):Connect(function()
	task.defer(ApplyResponsiveTopbarLayout)
end)

if userGuiIcon3D and vr3dGuis then
	local function FindScreenGuiChild(object)
		for _, child in pairs(object:GetChildren()) do
			if child:IsA('ScreenGui') then
				return child
			end
		end
	end

	local function onPlayerGuiAdded(playerGui)
		playerGui.ChildAdded:connect(function(child)
			if FindScreenGuiChild(playerGui) then
				AddItemInOrder(ThreeDMenubar, userGuiIcon3D, THREE_D_ITEM_ORDER)
			end
		end)
		playerGui.ChildRemoved:connect(function(child)
			if child:IsA('ScreenGui') and not FindScreenGuiChild(playerGui) then
				ThreeDMenubar:RemoveItem(userGuiIcon3D)
			end
		end)
		if FindScreenGuiChild(playerGui) then
			AddItemInOrder(ThreeDMenubar, userGuiIcon3D, THREE_D_ITEM_ORDER)
		end
	end
	Player.ChildAdded:connect(function(child)
		if child:IsA('PlayerGui') then
			onPlayerGuiAdded(child)
		end
	end)
	if Player:FindFirstChild('PlayerGui') then
		onPlayerGuiAdded(Player:FindFirstChild('PlayerGui'))
	end
end


local function MoveHamburgerTo3D()
	--Topbar3DPanel:SetType(Panel3D.Type.Fixed)
	--Topbar3DPanel:LinkTo("Backpack")
	--Topbar3DPanel:SetVisible(true)

	local backpackPanel = Panel3D.Get("Backpack")
	local panelLocalCF = CFrame.Angles(math.rad(5), 0, 0) * CFrame.new(0, -1.625, 0) * CFrame.Angles(math.rad(5), 0, 0)
	--function Topbar3DPanel:PreUpdate(cameraCF, cameraRenderCF, userHeadCF, lookRay)
	--	local panelOriginCF = backpackPanel.localCF or CFrame.new()
	--	self.localCF = panelOriginCF * panelLocalCF
	--end

	--function Topbar3DPanel:OnUpdate()
	--	for _, item in pairs(ThreeDMenubar:GetItems()) do
	--		item:SetTransparency(self.transparency)
	--	end
	--end

	LeftMenubar:RemoveItem(settingsIcon)
	AddItemInOrder(ThreeDMenubar, settingsIcon3D, THREE_D_ITEM_ORDER)
end

--local gameOptions = settings():FindFirstChild("Game Options")
--if gameOptions and not isTenFootInterface then
--	local success, result = pcall(function()
--		gameOptions.VideoRecordingChangeRequest:connect(function(recording)
--			if recording and topbarEnabled then
--				AddItemInOrder(LeftMenubar, stopRecordingIcon, LEFT_ITEM_ORDER)
--			else
--				LeftMenubar:RemoveItem(stopRecordingIcon)
--			end
--		end)
--	end)
--end

local function topBarEnabledChanged()
	topbarEnabledChangedEvent:Fire(topbarEnabled)
	TopBar:UpdateBackgroundTransparency()
	for _, enumItem in pairs(Enum.CoreGuiType:GetEnumItems()) do
		-- The All enum will be false if any of the coreguis are false
		-- therefore by force updating it we are clobbering the previous sets
		if enumItem ~= Enum.CoreGuiType.All then
			OnCoreGuiChanged(enumItem, true)
		end
	end
end

local UISChanged;
local function OnVREnabled(prop)
	--if prop == "VREnabled" and InputService.VREnabled then
	--	VREnabled = true
	--	topbarEnabled = false
	--	MoveHamburgerTo3D()
	--	topBarEnabledChanged()
	--	if UISChanged then
	--		UISChanged:disconnect()
	--		UISChanged = nil
	--	end
	--end
end
--UISChanged = InputService.Changed:connect(OnVREnabled)
--OnVREnabled("VREnabled")


local function SetTopbarEnabledCompat(enabled)
	if type(enabled) ~= "boolean" then
		return
	end
	topbarEnabled = enabled
	topBarEnabledChanged()
end

do
	-- Local fallback API for non-CoreScript environments.
	local api = GuiRoot:FindFirstChild("TopbarEnabled")
	if not api then
		api = Instance.new("BindableFunction")
		api.Name = "TopbarEnabled"
		api.Parent = GuiRoot
	end
	if api:IsA("BindableFunction") then
		api.OnInvoke = function(enabled)
			SetTopbarEnabledCompat(enabled)
			return topbarEnabled
		end
	end

	-- Use the historical SetCore API when Roblox permits it.
	pcall(function()
		StarterGui:RegisterSetCore("TopbarEnabled", function(enabled)
			SetTopbarEnabledCompat(enabled)
		end)
	end)
end

if defeatableTopbar then
	--StarterGui:RegisterSetCore("TopbarEnabled", function(enabled)
	--	if type(enabled) == "boolean" then
	--		topbarEnabled = enabled
	--		topBarEnabledChanged()
	--	end
	--end)
end

-- Hook-up coregui changing
--StarterGui.CoreGuiChangedSignal:connect(OnCoreGuiChanged)
topBarEnabledChanged()


-- Load old modules only after the original topbar has been created and docked.
task.defer(function()
	local module = LoadPlayerlistModule()
	if module and leaderstatsMenuItem and leaderstatsMenuItem.AttachPlayerlistModule then
		leaderstatsMenuItem:AttachPlayerlistModule(module)
	end
end)

task.defer(function()
	PrepareLegacyCoreCompat()
	LoadTenFootInterface()
	local moduleScript = Modules:FindFirstChild("Chat")
	if moduleScript then
		local module = CompleteChatAPI(SafeRequire(moduleScript, "Chat"))
		if module and chatIcon and chatIcon.AttachChatModule then
			chatIcon:AttachChatModule(module)
		end
		if module and mobileShowChatIcon and mobileShowChatIcon.AttachChatModule then
			mobileShowChatIcon:AttachChatModule(module)
		end

		-- Activate the chat UI after gameplay starts so the topbar
		-- effectively becomes the chat interface.
		if module then
			task.spawn(function()
				-- Wait for the game to be running (Play mode / live game)
				while not RunService:IsRunning() do
					task.wait(0.5)
				end
				-- Small grace period after gameplay starts so the chat
				-- doesn't pop in during the loading screen.
				task.wait(2)

				pcall(function()
					if type(module.GetVisibility) == "function" and not module:GetVisibility() then
						if type(module.ToggleVisibility) == "function" then
							module:ToggleVisibility()
						end
					end
				end)

				-- Sync the chat icon state with the now-visible chat.
				-- On mobile, the chat icon follows focus state (not visibility),
				-- so we skip this override to avoid showing ChatDown when the
				-- keyboard isn't actually active.
				if not Util.IsTouchDevice() then
					if chatIcon and chatIcon.GetChatVisibility then
						local visible = chatIcon:GetChatVisibility()
						if visible and chatIcon.SetImage then
							chatIcon:SetImage("rbxasset://textures/ui/Chat/ChatDown.png")
						end
					end
				end
			end)
		end
	end
end)

task.defer(function()
	PrepareLegacyCoreCompat()
	LoadTenFootInterface()
	local moduleScript = Modules:FindFirstChild("BackpackScript")
	if moduleScript then
		local module = CompleteBackpackAPI(SafeRequire(moduleScript, "BackpackScript"))
		if module and backpackIcon and backpackIcon.AttachBackpackModule then
			backpackIcon:AttachBackpackModule(module)
		end
	end
end)

task.defer(function()
	LoadTenFootInterface()
end)

print("[Topbar] 2016 prototype API compatibility loaded; legacy modules are post-start/lazy")
