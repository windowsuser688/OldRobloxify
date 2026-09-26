--[[
    // FileName: PlayerDropDown.lua
    // 2026 compatibility port of the 2016 CoreScript module (v2).
    // Keeps the old dropdown UI/API while replacing private Roblox services
    // with public experience APIs.
]]

local moduleApiTable = {}

local PlayersService = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = PlayersService.LocalPlayer
while not LocalPlayer do
	PlayersService:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = PlayersService.LocalPlayer
end

local POPUP_ENTRY_SIZE_Y = 24
local ENTRY_PAD = 2
local BG_TRANSPARENCY = 0.5
local BG_COLOR = Color3.new(31/255, 31/255, 31/255)
local TEXT_STROKE_TRANSPARENCY = 0.75
local TEXT_COLOR = Color3.new(1, 1, 243/255)
local TEXT_STROKE_COLOR = Color3.new(34/255, 34/255, 34/255)
local TWEEN_TIME = 0.15

local function createSignal()
	local bindable = Instance.new("BindableEvent")
	local signal = {}

	function signal:fire(...)
		bindable:Fire(...)
	end

	signal.Fire = signal.fire

	function signal:connect(callback)
		assert(type(callback) == "function", "connect expects a function")
		return bindable.Event:Connect(callback)
	end

	signal.Connect = signal.connect

	function signal:wait()
		return bindable.Event:Wait()
	end

	signal.Wait = signal.wait

	function signal:destroy()
		bindable:Destroy()
	end

	return signal
end

local BlockStatusChanged = createSignal()
local BlockedList = {}
local MutedList = {}

local function safeSetCore(name, value)
	local lastError
	for _ = 1, 20 do
		local ok, err = pcall(function()
			StarterGui:SetCore(name, value)
		end)
		if ok then
			return true
		end
		lastError = err
		task.wait(0.1)
	end
	warn(("PlayerDropDown: SetCore(%s) failed after retries: %s"):format(name, tostring(lastError)))
	return false
end

local function safeGetCore(name)
	local lastError
	for _ = 1, 20 do
		local ok, result = pcall(function()
			return StarterGui:GetCore(name)
		end)
		if ok then
			return true, result
		end
		lastError = result
		task.wait(0.1)
	end
	return false, lastError
end

local function sendNotification(title, text, image, duration)
	safeSetCore("SendNotification", {
		Title = title or "",
		Text = text or "",
		Icon = image or "",
		Duration = duration or 5,
	})
end

local function refreshBlockedList()
	local ok, result = safeGetCore("GetBlockedUserIds")

	if ok and type(result) == "table" then
		table.clear(BlockedList)
		for _, userId in ipairs(result) do
			BlockedList[tonumber(userId) or userId] = true
		end
	end
end

task.spawn(refreshBlockedList)

local function hookCoreEvent(coreName, callback)
	task.spawn(function()
		local ok, event = safeGetCore(coreName)
		if ok and event then
			if event:IsA("BindableEvent") then
				event.Event:Connect(callback)
			elseif event.Event then
				event.Event:Connect(callback)
			end
		end
	end)
end

hookCoreEvent("PlayerBlockedEvent", function(playerOrUserId)
	local userId = typeof(playerOrUserId) == "Instance" and playerOrUserId.UserId or tonumber(playerOrUserId)
	if userId then
		BlockedList[userId] = true
		BlockStatusChanged:fire(userId, true)
	else
		refreshBlockedList()
	end
end)

hookCoreEvent("PlayerUnblockedEvent", function(playerOrUserId)
	local userId = typeof(playerOrUserId) == "Instance" and playerOrUserId.UserId or tonumber(playerOrUserId)
	if userId then
		BlockedList[userId] = nil
		BlockStatusChanged:fire(userId, false)
	else
		refreshBlockedList()
	end
end)

local function isBlocked(userId)
	return BlockedList[userId] == true
end

local function isMuted(userId)
	return MutedList[userId] == true
end

local function BlockPlayerAsync(playerToBlock)
	if playerToBlock and playerToBlock ~= LocalPlayer and playerToBlock.UserId > 0 then
		safeSetCore("PromptBlockPlayer", playerToBlock)
	end
end

local function UnblockPlayerAsync(playerToUnblock)
	if playerToUnblock and playerToUnblock.UserId > 0 then
		safeSetCore("PromptUnblockPlayer", playerToUnblock)
	end
end

local function MutePlayer(playerToMute)
	if playerToMute and playerToMute ~= LocalPlayer and playerToMute.UserId > 0 then
		MutedList[playerToMute.UserId] = true
	end
end

local function UnmutePlayer(playerToUnmute)
	if playerToUnmute then
		MutedList[playerToUnmute.UserId] = nil
	end
end

local function getFriendStatus(selectedPlayer)
	if not selectedPlayer or selectedPlayer == LocalPlayer then
		return Enum.FriendStatus.NotFriend
	end

	local success, isFriend = pcall(function()
		return LocalPlayer:IsFriendsWithAsync(selectedPlayer.UserId)
	end)

	if success and isFriend then
		return Enum.FriendStatus.Friend
	end
	return Enum.FriendStatus.NotFriend
end


local function openReportAbusePage(targetPlayer)
	if not targetPlayer or targetPlayer == LocalPlayer then
		return
	end

	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("PlayerListReportAbuse")
	if old then
		old:Destroy()
	end

	local screen = Instance.new("ScreenGui")
	screen.Name = "PlayerListReportAbuse"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 1000
	screen.Parent = playerGui

	local shield = Instance.new("TextButton")
	shield.Name = "Shield"
	shield.Text = ""
	shield.AutoButtonColor = false
	shield.Size = UDim2.fromScale(1, 1)
	shield.BackgroundColor3 = Color3.fromRGB(41, 41, 41)
	shield.BackgroundTransparency = 0.2
	shield.BorderSizePixel = 0
	shield.Parent = screen

	local page = Instance.new("Frame")
	page.Name = "ReportAbusePage"
	page.AnchorPoint = Vector2.new(0.5, 0.5)
	page.Position = UDim2.fromScale(0.5, 0.5)
	page.Size = UDim2.fromOffset(520, 430)
	page.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
	page.BorderSizePixel = 0
	page.Parent = shield

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(24, 18)
	title.Size = UDim2.new(1, -48, 0, 42)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 32
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Report Abuse"
	title.Parent = page

	local target = Instance.new("TextLabel")
	target.BackgroundTransparency = 1
	target.Position = UDim2.fromOffset(24, 68)
	target.Size = UDim2.new(1, -48, 0, 30)
	target.Font = Enum.Font.SourceSans
	target.TextSize = 20
	target.TextColor3 = Color3.new(1, 1, 1)
	target.TextXAlignment = Enum.TextXAlignment.Left
	target.Text = "Player: " .. targetPlayer.Name
	target.Parent = page

	local reasonLabel = Instance.new("TextLabel")
	reasonLabel.BackgroundTransparency = 1
	reasonLabel.Position = UDim2.fromOffset(24, 110)
	reasonLabel.Size = UDim2.new(1, -48, 0, 26)
	reasonLabel.Font = Enum.Font.SourceSans
	reasonLabel.TextSize = 18
	reasonLabel.TextColor3 = Color3.new(1, 1, 1)
	reasonLabel.TextXAlignment = Enum.TextXAlignment.Left
	reasonLabel.Text = "Reason:"
	reasonLabel.Parent = page

	local reasons = {
		"Swearing",
		"Bullying",
		"Scamming",
		"Dating",
		"Cheating / Exploiting",
		"Personal Questions",
		"Offsite Links",
		"Inappropriate Content",
	}
	local selectedReason = reasons[1]

	local reasonButton = Instance.new("TextButton")
	reasonButton.Name = "ReasonButton"
	reasonButton.Position = UDim2.fromOffset(24, 140)
	reasonButton.Size = UDim2.new(1, -48, 0, 38)
	reasonButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	reasonButton.BorderSizePixel = 0
	reasonButton.Font = Enum.Font.SourceSans
	reasonButton.TextSize = 18
	reasonButton.TextColor3 = Color3.new(1, 1, 1)
	reasonButton.TextXAlignment = Enum.TextXAlignment.Left
	reasonButton.Text = "  " .. selectedReason .. "  ▼"
	reasonButton.Parent = page

	local reasonList = Instance.new("Frame")
	reasonList.Name = "ReasonList"
	reasonList.Position = UDim2.fromOffset(24, 178)
	reasonList.Size = UDim2.new(1, -48, 0, #reasons * 28)
	reasonList.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	reasonList.BorderSizePixel = 0
	reasonList.Visible = false
	reasonList.ZIndex = 20
	reasonList.Parent = page

	for i, reason in ipairs(reasons) do
		local option = Instance.new("TextButton")
		option.Name = "Reason" .. i
		option.Position = UDim2.new(0, 0, 0, (i - 1) * 28)
		option.Size = UDim2.new(1, 0, 0, 28)
		option.BackgroundTransparency = 1
		option.Font = Enum.Font.SourceSans
		option.TextSize = 17
		option.TextColor3 = Color3.new(1, 1, 1)
		option.TextXAlignment = Enum.TextXAlignment.Left
		option.Text = "  " .. reason
		option.ZIndex = 21
		option.Parent = reasonList
		option.Activated:Connect(function()
			selectedReason = reason
			reasonButton.Text = "  " .. selectedReason .. "  ▼"
			reasonList.Visible = false
		end)
	end

	reasonButton.Activated:Connect(function()
		reasonList.Visible = not reasonList.Visible
	end)

	local descLabel = Instance.new("TextLabel")
	descLabel.BackgroundTransparency = 1
	descLabel.Position = UDim2.fromOffset(24, 194)
	descLabel.Size = UDim2.new(1, -48, 0, 26)
	descLabel.Font = Enum.Font.SourceSans
	descLabel.TextSize = 18
	descLabel.TextColor3 = Color3.new(1, 1, 1)
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Text = "Description:"
	descLabel.Parent = page

	local description = Instance.new("TextBox")
	description.Name = "Description"
	description.Position = UDim2.fromOffset(24, 224)
	description.Size = UDim2.new(1, -48, 0, 100)
	description.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	description.BorderSizePixel = 0
	description.ClearTextOnFocus = false
	description.MultiLine = true
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.Font = Enum.Font.SourceSans
	description.TextSize = 18
	description.TextColor3 = Color3.new(1, 1, 1)
	description.PlaceholderText = "Describe what happened..."
	description.Text = ""
	description.Parent = page

	local cancel = Instance.new("TextButton")
	cancel.Name = "Cancel"
	cancel.Position = UDim2.new(0.5, -204, 1, -72)
	cancel.Size = UDim2.fromOffset(198, 50)
	cancel.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	cancel.BorderSizePixel = 0
	cancel.Font = Enum.Font.SourceSansBold
	cancel.TextSize = 22
	cancel.TextColor3 = Color3.new(1, 1, 1)
	cancel.Text = "Cancel"
	cancel.Parent = page

	local submit = Instance.new("TextButton")
	submit.Name = "Submit"
	submit.Position = UDim2.new(0.5, 6, 1, -72)
	submit.Size = UDim2.fromOffset(198, 50)
	submit.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
	submit.BorderSizePixel = 0
	submit.Font = Enum.Font.SourceSansBold
	submit.TextSize = 22
	submit.TextColor3 = Color3.new(1, 1, 1)
	submit.Text = "Submit"
	submit.Parent = page

	local function closePage()
		screen:Destroy()
	end

	cancel.Activated:Connect(closePage)

	submit.Activated:Connect(function()
		submit.Active = false
		submit.Text = "Submitting..."

		local ok, err = pcall(function()
			PlayersService:ReportAbuse(targetPlayer, selectedReason, description.Text)
		end)

		if ok then
			sendNotification("Report submitted", "Thank you for your report.", "", 5)
			closePage()
		else
			submit.Active = true
			submit.Text = "Submit"
			warn("Report failed: " .. tostring(err))
			sendNotification(
				"Report failed",
				"Unable to submit report.",
				"",
				7
			)
		end
	end)

	shield.Activated:Connect(function()
		-- Clicking outside the page closes it.
		if not reasonList.Visible then
			closePage()
		else
			reasonList.Visible = false
		end
	end)

	return screen
end

local function createPlayerDropDown()
	local playerDropDown = {
		Player = nil,
		PopupFrame = nil,
		HidePopupImmediately = false,
		PopupFrameOffScreenPosition = nil,
		HiddenSignal = createSignal(),
	}

	local function onFriendButtonPressed()
		local target = playerDropDown.Player
		if not target then return end

		local status = getFriendStatus(target)
		if status == Enum.FriendStatus.Friend then
			safeSetCore("PromptUnfriend", target)
		else
			safeSetCore("PromptSendFriendRequest", target)
		end

		playerDropDown:Hide()
	end

	local function onBlockButtonPressed()
		local target = playerDropDown.Player
		if not target then return end

		if isBlocked(target.UserId) then
			UnblockPlayerAsync(target)
		else
			BlockPlayerAsync(target)
		end

		playerDropDown:Hide()
	end

	local function onReportButtonPressed()
		local target = playerDropDown.Player
		if not target then
			return
		end

		playerDropDown:Hide()

		-- Use the real 2016 SettingsHub Report Abuse page.
		-- Keep the rest of PlayerDropDown completely untouched.
		local playerGui = LocalPlayer:WaitForChild("PlayerGui")
		local robloxGui = playerGui:WaitForChild("RobloxGui")
		local settingsHubModule = robloxGui
			:WaitForChild("Modules")
			:WaitForChild("Settings")
			:WaitForChild("SettingsHub")

		local ok, settingsHub = pcall(require, settingsHubModule)
		if not ok or type(settingsHub) ~= "table" then
			warn("PlayerDropDown: failed to load SettingsHub:", settingsHub)
			return
		end

		if type(settingsHub.ReportPlayer) == "function" then
			local reportOk, reportErr = pcall(function()
				settingsHub:ReportPlayer(target)
			end)

			if not reportOk then
				warn("PlayerDropDown: SettingsHub:ReportPlayer failed:", reportErr)
			end
		else
			warn("PlayerDropDown: SettingsHub.ReportPlayer is missing")
		end
	end

	local function createPopupFrame(buttons)
		local frame = Instance.new("Frame")
		frame.Name = "PopupFrame"
		frame.Size = UDim2.new(1, 0, 0, (POPUP_ENTRY_SIZE_Y * #buttons) + math.max(0, (#buttons - 1) * ENTRY_PAD))
		frame.Position = UDim2.new(1, 1, 0, 0)
		frame.BackgroundTransparency = 1

		for i, button in ipairs(buttons) do
			local btn = Instance.new("TextButton")
			btn.Name = button.Name
			btn.Size = UDim2.new(1, 0, 0, POPUP_ENTRY_SIZE_Y)
			btn.Position = UDim2.new(0, 0, 0, (POPUP_ENTRY_SIZE_Y + ENTRY_PAD) * (i - 1))
			btn.BackgroundTransparency = BG_TRANSPARENCY
			btn.BackgroundColor3 = BG_COLOR
			btn.BorderSizePixel = 0
			btn.Text = button.Text
			btn.Font = Enum.Font.SourceSans
			btn.TextSize = 14
			btn.TextColor3 = TEXT_COLOR
			btn.TextStrokeTransparency = TEXT_STROKE_TRANSPARENCY
			btn.TextStrokeColor3 = TEXT_STROKE_COLOR
			btn.AutoButtonColor = true
			btn.Parent = frame
			btn.Activated:Connect(button.OnPress)
		end

		return frame
	end

	function playerDropDown:Hide()
		local popup = self.PopupFrame
		if popup then
			local offscreenPosition = self.PopupFrameOffScreenPosition
				or UDim2.new(1, 1, 0, popup.Position.Y.Offset)

			if self.HidePopupImmediately then
				popup:Destroy()
				self.PopupFrame = nil
			else
				popup:TweenPosition(
					offscreenPosition,
					Enum.EasingDirection.InOut,
					Enum.EasingStyle.Quad,
					TWEEN_TIME,
					true,
					function()
						if self.PopupFrame == popup then
							popup:Destroy()
							self.PopupFrame = nil
						end
					end
				)
			end
		end

		self.Player = nil
		self.HiddenSignal:fire()
	end

	function playerDropDown:CreatePopup(player)
		self.Player = player

		if self.PopupFrame then
			self.PopupFrame:Destroy()
			self.PopupFrame = nil
		end

		local status = getFriendStatus(player)
		local blocked = isBlocked(player.UserId)
		local buttons = {}

		if not blocked then
			table.insert(buttons, {
				Name = "FriendButton",
				Text = status == Enum.FriendStatus.Friend and "Unfriend Player" or "Send Friend Request",
				OnPress = onFriendButtonPressed,
			})
		end

		table.insert(buttons, {
			Name = "BlockButton",
			Text = blocked and "Unblock Player" or "Block Player",
			OnPress = onBlockButtonPressed,
		})

		table.insert(buttons, {
			Name = "ReportButton",
			Text = "Report Abuse",
			OnPress = onReportButtonPressed,
		})

		-- Roblox's 2016 follower REST endpoints and NewFollower remote were
		-- experience API, so the obsolete Follow/Unfollow row is intentionally
		-- omitted instead of leaving a broken button.
		self.PopupFrame = createPopupFrame(buttons)
		return self.PopupFrame
	end

	PlayersService.PlayerRemoving:Connect(function(leavingPlayer)
		if playerDropDown.Player == leavingPlayer then
			playerDropDown:Hide()
		end
	end)

	return playerDropDown
end

moduleApiTable.FollowerStatusChanged = createSignal()

function moduleApiTable:CreatePlayerDropDown()
	return createPlayerDropDown()
end

function moduleApiTable:CreateBlockingUtility()
	local blockingUtility = {}

	function blockingUtility:BlockPlayerAsync(player)
		return BlockPlayerAsync(player)
	end

	function blockingUtility:UnblockPlayerAsync(player)
		return UnblockPlayerAsync(player)
	end

	function blockingUtility:MutePlayer(player)
		return MutePlayer(player)
	end

	function blockingUtility:UnmutePlayer(player)
		return UnmutePlayer(player)
	end

	function blockingUtility:IsPlayerBlockedByUserId(userId)
		return isBlocked(userId)
	end

	function blockingUtility:GetBlockedStatusChangedEvent()
		return BlockStatusChanged
	end

	function blockingUtility:IsPlayerMutedByUserId(userId)
		return isMuted(userId)
	end

	return blockingUtility
end

return moduleApiTable