local ChatToggle = (function()
local v1={};
local v2=game:GetService("Players");
local v_u_3=game:GetService("UserInputService");
local v_u_4=game:GetService("StarterGui");
local v_u_5=game:GetService("RunService");
local v_u_6=v2.LocalPlayer;

local _chatActive = false

function v_u_10(p_u_7,...)
	local v_u_8={...};
	if p_u_7 == "GetCore" and v_u_8[1] == "ChatActive" then
		return true, _chatActive
	end
	if p_u_7 == "SetCore" and v_u_8[1] == "ChatActive" then
		_chatActive = v_u_8[2]
		return true
	end
	return pcall(function()
		local v9=v_u_8;
		return v_u_4[p_u_7](v_u_4,table.unpack(v9));
	end);
end

function v_u_13()
	local v11=workspace.CurrentCamera or workspace:WaitForChild("CurrentCamera");
	local v12=v11.ViewportSize;
	if((v12.X==0)or(v12.Y==0))then
		v_u_5.RenderStepped:Wait();
		v12=v11.ViewportSize;
		if((v12.X==0)or(v12.Y==0))then
			v12=Vector2.new(1024,768);
		end
	end
	return v12;
end

v1.init=function(p_u_14,obj)
	local v15=v_u_13();
	local v16=((v15.X<800)and true)or(v15.Y<600);
	local v_u_17=v_u_3.TouchEnabled;
	if v_u_17 then
		v_u_17=not v_u_3.KeyboardEnabled or v16;
	end
	local v_u_18=obj;
	if not v_u_18 then
		v_u_18=v_u_6:FindFirstChildOfClass("PlayerGui")or v_u_6:WaitForChild("PlayerGui");
		v_u_18=v_u_18:FindFirstChild("ZenosChat");
	end
	local v_u_19=0;
	local v_u_20=false;
	local v21=nil;
	local v_u_22={};

	function v_u_28(p23)
		local v24=v_u_18 and v_u_18:FindFirstChild("appLayout");
		if v24 then
			v24.Visible=p23;
			if(p_u_14 and p23)then
				if p_u_14.isFadedOut then
					local v25=p_u_14.cancelFade;
					if(type(v25)=="function")then
						p_u_14:cancelFade();
					end
				else
					local v26=p_u_14.fadeIn;
					if(type(v26)=="function")then
						p_u_14:fadeIn();
					end
				end
			end
			if(not p23 and v_u_17)then
				local v27=v24:FindFirstChild("MainFrame")and v24.MainFrame:FindFirstChild("InputBar");
				if v27 then
					v27=v24.MainFrame.InputBar:FindFirstChild("InputBox");
				end
				if v27 then
					v27:ReleaseFocus();
				end
			end
			if _G.setChatImmediate then
				_G.setChatImmediate(not p23);
			end
			v_u_20=p23;
			if p23 then
				v_u_19=0;
			end
		end
	end

	function v30()
		if not v_u_20 then
			local v29=v_u_19+1;
			v_u_19=math.min(v29,99);
		end
	end

	if v21 then
		task.cancel(v21);
	end

	local v_u_33=task.spawn(function()
		while true do
			local v31,v32=v_u_10("GetCore","ChatActive");
			if(v31 and(type(v32)=="boolean")and(v32~=v_u_20))then
				v_u_28(v32);
			end
			task.wait(0.05);
		end
	end);

	local v36=v_u_3.InputBegan:Connect(function(p34,p35)
		if not p35 then
			if((p34.KeyCode==Enum.KeyCode.Slash)and not v_u_20)then
				v_u_10("SetCore","ChatActive",true);
			end
		end
	end);

	table.insert(v_u_22,v36);

	task.spawn(function()
		local v37=0;
		local v38=nil;
		while true do
			v38=(v37>=10)or(v_u_18 and v_u_18:FindFirstChild("appLayout"));
			if v38 then
				break;
			end
			task.wait(0.1);
			v37=v37+0.1;
		end
		if v38 then
			local v39=v_u_18 and v_u_18:FindFirstChild("appLayout");
			if v39 then
				v39.Visible=true;
				if p_u_14 then
					if p_u_14.isFadedOut then
						local v40=p_u_14.cancelFade;
						if(type(v40)=="function")then
							p_u_14:cancelFade();
						end
					else
						local v41=p_u_14.fadeIn;
						if(type(v41)=="function")then
							p_u_14:fadeIn();
						end
					end
				end
				if _G.setChatImmediate then
					_G.setChatImmediate(false);
				end
				v_u_20=true;
				v_u_19=0;
			end
			v_u_10("SetCore","ChatActive",true);
		else
			warn("oof");
		end
	end);

	return function()
		if v_u_33 then
			task.cancel(v_u_33);
			v_u_33=nil;
		end
		for _,v42 in ipairs(v_u_22)do
			v42:Disconnect();
		end
		table.clear(v_u_22);
	end,v30;
end;

return v1;
end)()

local BubbleChat = (function()
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local MAX_BUBBLE_WIDTH = 360
local BUBBLE_HEIGHT_TEXT_SIZE = 20 -- preserve the shorter classic bubble height
local MAX_TOTAL_BUBBLE_HEIGHT = 150
local NEAR_BUBBLE_DISTANCE = 45
local MAX_BUBBLE_DISTANCE = 80
local MIN_BUBBLE_LIFETIME = 12
local MAX_BUBBLE_LIFETIME = 20
local MIN_BUBBLE_LIFETIME_SELF = 8
local MAX_BUBBLE_LIFETIME_SELF = 15
local BUBBLE_FADE_TIME = 1.5

local function convertRichTextEscapeStrings(message: string): string
	message = string.gsub(message, "&lt;", "<")
	message = string.gsub(message, "&gt;", ">")
	message = string.gsub(message, "&quot;", "\"")
	message = string.gsub(message, "&apos;", "'")
	message = string.gsub(message, "&amp;", "&")
	return message
end

local function getMessageLength(message: string): number
	return utf8.len(utf8.nfcnormalize(message)) or 0
end

local ELLIPSES = "..."
local MaxChatMessageLength = 128
local MaxChatMessageLengthExclusive = MaxChatMessageLength - getMessageLength(ELLIPSES) - 1

local resizeBubbleTweenInfo = TweenInfo.new(.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local shiftBubblesUpTweenInfo = TweenInfo.new(.07, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local BubbleChat = {}
local chatBubbleQueues = {}

local function lerpLength(msg: string, min: number, max: number): number
	return min + (max - min) * math.min(getMessageLength(msg) / 75.0, 1.0)
end

local function removeOldestFromQueue(adornee: PVInstance)
	local queue = chatBubbleQueues[adornee]
	if not queue then return end
	local oldestBubble = queue[#queue]
	if not oldestBubble then return end
	oldestBubble:Destroy()
	queue[#queue] = nil
end

local function addBubbleToQueue(adornee: PVInstance, chatBubble: BillboardGui, lifetime: number)
	local queue = chatBubbleQueues[adornee]
	if queue == nil then
		queue = {}
		chatBubbleQueues[adornee] = queue
		adornee.Destroying:Connect(function()
			chatBubbleQueues[adornee] = nil
		end)
	end

	local gap = 4
	local newChatBubbleSizeY = chatBubble.BillboardFrame.ChatBubble.AbsoluteSize.Y
	local totalYSpaceUsed = newChatBubbleSizeY
	for _,v in queue do
		if v.Parent == nil then continue end
		local shiftUp = newChatBubbleSizeY+gap
		local newPosition = v.BillboardFrame.Position - UDim2.fromOffset(0, shiftUp)
		TweenService:Create(v.BillboardFrame, shiftBubblesUpTweenInfo, {Position = newPosition}):Play()
		totalYSpaceUsed += v.BillboardFrame.ChatBubble.AbsoluteSize.Y
		v.BillboardFrame.ChatBubble.BubbleText.TextTransparency = 0.5
	end
	if totalYSpaceUsed > MAX_TOTAL_BUBBLE_HEIGHT then
		removeOldestFromQueue(adornee)
	end

	table.insert(queue, 1, chatBubble)

	task.delay(lifetime+BUBBLE_FADE_TIME, function()
		if chatBubble.Parent ~= nil then
			removeOldestFromQueue(adornee)
		end
	end)
end

function BubbleChat.createBubble(adornee: PVInstance, message: string, sentBySelf: boolean?)
	if not adornee or not adornee.Parent then return end

	local chatBubbleGui = Instance.new("BillboardGui")
	chatBubbleGui.Name = "ChatBubbleGui"
	chatBubbleGui.Size = UDim2.fromOffset(400, 250)

	local billboardFrame = Instance.new("Frame")
	billboardFrame.Name = "BillboardFrame"
	billboardFrame.AnchorPoint = Vector2.new(0.5, 0)
	billboardFrame.BackgroundTransparency = 1
	billboardFrame.Position = UDim2.fromScale(0.5, -0.5)
	billboardFrame.Size = UDim2.fromScale(1, 1)

	local smallTalkBubble = Instance.new("ImageLabel")
	smallTalkBubble.Name = "SmallTalkBubble"
	smallTalkBubble.AnchorPoint = Vector2.new(0.5, 1)
	smallTalkBubble.BackgroundTransparency = 1
	smallTalkBubble.BorderSizePixel = 0
	smallTalkBubble.Image = "rbxasset://textures/ui/dialog_white.png"
	smallTalkBubble.ImageColor3 = Color3.new(1, 1, 1)
	smallTalkBubble.Position = UDim2.fromScale(0.5, 1)
	smallTalkBubble.ScaleType = Enum.ScaleType.Slice
	smallTalkBubble.Size = UDim2.fromOffset(40, 28)
	smallTalkBubble.SliceCenter = Rect.new(5, 5, 15, 15)
	smallTalkBubble.Visible = false

	local smallTalkBubbleText = Instance.new("TextLabel")
	smallTalkBubbleText.Name = "BubbleText"
	smallTalkBubbleText.BackgroundTransparency = 1
	smallTalkBubbleText.ClipsDescendants = true
	smallTalkBubbleText.Font = Enum.Font.SourceSans
	smallTalkBubbleText.Size = UDim2.fromScale(1, 1)
	smallTalkBubbleText.Text = "..."
	smallTalkBubbleText.TextColor3 = Color3.fromRGB(55, 55, 55)
	smallTalkBubbleText.TextSize = 20

	local smallTalkBubbleUIPadding = Instance.new("UIPadding")
	smallTalkBubbleUIPadding.Name = "UIPadding"
	smallTalkBubbleUIPadding.PaddingBottom = UDim.new(0, 8)
	smallTalkBubbleUIPadding.PaddingLeft = UDim.new(0, 12)
	smallTalkBubbleUIPadding.PaddingRight = UDim.new(0, 12)
	smallTalkBubbleUIPadding.PaddingTop = UDim.new(0, 8)
	smallTalkBubbleUIPadding.Parent = smallTalkBubbleText
	smallTalkBubbleText.Parent = smallTalkBubble

	local chatBubbleTailFrame = Instance.new("Frame")
	chatBubbleTailFrame.Name = "ChatBubbleTailFrame"
	chatBubbleTailFrame.BackgroundTransparency = 1
	chatBubbleTailFrame.Position = UDim2.fromScale(0.5, 1)
	chatBubbleTailFrame.Size = UDim2.fromScale(0.5, 0.5)
	chatBubbleTailFrame.SizeConstraint = Enum.SizeConstraint.RelativeXX

	local chatBubbleTail = Instance.new("ImageLabel")
	chatBubbleTail.Name = "ChatBubbleTail"
	chatBubbleTail.BackgroundTransparency = 1
	chatBubbleTail.BorderSizePixel = 0
	chatBubbleTail.Image = "rbxasset://textures/ui/dialog_tail.png"
	chatBubbleTail.ImageColor3 = Color3.new(1, 1, 1)
	chatBubbleTail.Position = UDim2.fromScale(-0.5, 0)
	chatBubbleTail.Size = UDim2.fromScale(1, 0.5)
	chatBubbleTail.Parent = chatBubbleTailFrame
	chatBubbleTailFrame.Parent = smallTalkBubble
	smallTalkBubble.Parent = billboardFrame

	local chatBubble = Instance.new("ImageLabel")
	chatBubble.Name = "ChatBubble"
	chatBubble.AnchorPoint = Vector2.new(0.5, 1)
	chatBubble.BackgroundTransparency = 1
	chatBubble.BorderSizePixel = 0
	chatBubble.Image = "rbxasset://textures/ui/dialog_white.png"
	chatBubble.ImageColor3 = Color3.new(1, 1, 1)
	chatBubble.Position = UDim2.fromScale(0.5, 1)
	chatBubble.ScaleType = Enum.ScaleType.Slice
	chatBubble.SliceCenter = Rect.new(5, 5, 15, 15)
	chatBubble.Visible = false

	local bubbleText = Instance.new("TextLabel")
	bubbleText.Name = "BubbleText"
	bubbleText.BackgroundTransparency = 1
	bubbleText.ClipsDescendants = false
	bubbleText.TextTruncate = Enum.TextTruncate.None
	bubbleText.Font = Enum.Font.SourceSans
	bubbleText.Size = UDim2.fromScale(1, 1)
	bubbleText.Text = ""
	bubbleText.TextColor3 = Color3.fromRGB(55, 55, 55)
	bubbleText.TextSize = 25
	bubbleText.TextWrapped = true

	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0, 8)
	uiPadding.PaddingLeft = UDim.new(0, 7)
	uiPadding.PaddingRight = UDim.new(0, 7)
	uiPadding.PaddingTop = UDim.new(0, 8)
	uiPadding.Parent = bubbleText
	bubbleText.Parent = chatBubble
	chatBubble.Parent = billboardFrame

	local chatBubbleTail1 = Instance.new("ImageLabel")
	chatBubbleTail1.Name = "ChatBubbleTail"
	chatBubbleTail1.BackgroundTransparency = 1
	chatBubbleTail1.BorderSizePixel = 0
	chatBubbleTail1.Image = "rbxasset://textures/ui/dialog_tail.png"
	chatBubbleTail1.ImageColor3 = Color3.new(1, 1, 1)
	chatBubbleTail1.Position = UDim2.new(0.5, -12, 1, -1)
	chatBubbleTail1.Size = UDim2.fromOffset(24, 12)
	chatBubbleTail1.Visible = false
	chatBubbleTail1.Parent = billboardFrame

	billboardFrame.Parent = chatBubbleGui
	message = convertRichTextEscapeStrings(message)

	local actualTextSize = bubbleText.TextSize
	local horizontalPadding = uiPadding.PaddingLeft.Offset + uiPadding.PaddingRight.Offset
	local glyphSafety = math.max(8, math.ceil(actualTextSize * 0.35))
	local maxContentWidth = math.max(1, MAX_BUBBLE_WIDTH - glyphSafety)

	local widthBounds = TextService:GetTextSize(
		message,
		actualTextSize,
		bubbleText.Font,
		Vector2.new(maxContentWidth, math.huge)
	)

	-- Keep the classic short 2015M vertical proportions. Width follows the
	-- real TextSize, while height intentionally stays based on the classic
	-- layout size.
	local heightBounds = TextService:GetTextSize(
		message,
		BUBBLE_HEIGHT_TEXT_SIZE,
		bubbleText.Font,
		Vector2.new(maxContentWidth, math.huge)
	)

	local multiline = widthBounds.Y > actualTextSize
	if not multiline then
		-- 2015M had less empty space above the text than the later bubble.
		uiPadding.PaddingTop = UDim.new(0, 2)
		uiPadding.PaddingBottom = UDim.new(0, 6)
	end

	local chatBubbleSize = UDim2.fromOffset(
		widthBounds.X + horizontalPadding + glyphSafety,
		heightBounds.Y + uiPadding.PaddingTop.Offset + uiPadding.PaddingBottom.Offset
	)

	chatBubble.Size = UDim2.fromOffset(chatBubbleSize.X.Offset+8, chatBubbleSize.Y.Offset+8)
	local resizeTween = TweenService:Create(chatBubble, resizeBubbleTweenInfo, {Size = chatBubbleSize})
	resizeTween:Play()

	task.delay(resizeBubbleTweenInfo.Time, function()
		bubbleText.Text = message
	end)

	chatBubbleGui.Adornee = adornee
	chatBubbleGui.Parent = adornee

	local lifetime = sentBySelf and lerpLength(bubbleText.Text, MIN_BUBBLE_LIFETIME_SELF, MAX_BUBBLE_LIFETIME_SELF) or lerpLength(bubbleText.Text, MIN_BUBBLE_LIFETIME, MAX_BUBBLE_LIFETIME)
	chatBubbleGui.StudsOffset = sentBySelf and Vector3.new(0, 1.8, 0) or Vector3.new(0, 2.4, 0)

	Debris:AddItem(chatBubbleGui, lifetime + BUBBLE_FADE_TIME + 0.1)

	task.delay(lifetime, function()
		local tweenInfo = TweenInfo.new(BUBBLE_FADE_TIME, Enum.EasingStyle.Linear)
		for _,v in chatBubbleGui:GetDescendants() do
			if v:IsA("ImageLabel") then
				TweenService:Create(v, tweenInfo, {ImageTransparency = 1}):Play()
			elseif v:IsA("TextLabel") then
				TweenService:Create(v, tweenInfo, {TextTransparency = 1}):Play()
			end
		end
	end)

	addBubbleToQueue(adornee, chatBubbleGui, lifetime)
end

task.spawn(function()
	local camera = workspace.CurrentCamera
	while true do
		task.wait()
		for adornee, queue in chatBubbleQueues do
			if #queue == 0 or not adornee or not adornee.Parent then continue end

			local mostRecentChatBubble = queue[1]
			if not mostRecentChatBubble or not mostRecentChatBubble.Parent then continue end

			local success, dist = pcall(function()
				return (camera.CFrame.Position - adornee:GetPivot().Position).Magnitude
			end)

			if not success or not dist then continue end

			for i = 1, #queue do
				local bubbleGui = queue[i]
				if not bubbleGui or bubbleGui.Parent == nil then continue end
				local billboardFrame = bubbleGui:FindFirstChild("BillboardFrame")
				if not billboardFrame then continue end

				if dist < NEAR_BUBBLE_DISTANCE then
					billboardFrame.ChatBubble.Visible = true
					billboardFrame.ChatBubbleTail.Visible = (i == 1)
					billboardFrame.SmallTalkBubble.Visible = false
					bubbleGui.Enabled = true
				elseif dist < MAX_BUBBLE_DISTANCE and i == 1 then
					billboardFrame.ChatBubble.Visible = false
					billboardFrame.ChatBubbleTail.Visible = false
					billboardFrame.SmallTalkBubble.Visible = true
					bubbleGui.Enabled = true
				else
					bubbleGui.Enabled = false
				end
			end
		end
	end
end)

return BubbleChat
end)()

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer

-- Disable built-in bubble chat since we use a custom BubbleChat module
local bubbleChatConfig = TextChatService:FindFirstChild("BubbleChatConfiguration")
if bubbleChatConfig then
	bubbleChatConfig.Enabled = false
end

	if message.Status ~= Enum.TextChatMessageStatus.Success then return end

	local textSource = message.TextSource
	if not textSource then return end

	-- Don't create bubbles for empty messages
	if not message.Text or message.Text == "" then return end

	-- Find the sender's player and character
	local senderPlayer = Players:GetPlayerByUserId(textSource.UserId)
	if not senderPlayer then return end

	local character = senderPlayer.Character
	if not character then return end

	-- Prefer Head as adornee, fallback to HumanoidRootPart
	local adornee = character:FindFirstChild("Head")
	if not adornee then
		adornee = character:FindFirstChild("HumanoidRootPart")
	end
	if not adornee then return end

	local sentBySelf = (senderPlayer == player)
	BubbleChat.createBubble(adornee, message.Text, sentBySelf)
end)

local playerGui = player:FindFirstChildOfClass("PlayerGui")
if not playerGui then
	playerGui = player:WaitForChild("PlayerGui", 5)
end
if playerGui then
	local zenosChat = playerGui:FindFirstChild("ZenosChat")
	if zenosChat and ChatToggle then
		ChatToggle.init(nil, zenosChat)
	end
end
game.CoreGui.TopBarApp:Destroy()
local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
local CoreGui = game:GetService("CoreGui")
local ContextActionService = game:GetService("ContextActionService")

local connections = {}

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function hideGuiObject(object)
	if not object or not object:IsA("GuiObject") then
		return
	end

	pcall(function()
		object.Visible = false
	end)

	pcall(function()
		object.Active = false
	end)

	pcall(function()
		object.Selectable = false
	end)

	pcall(function()
		object.AutoButtonColor = false
	end)

	pcall(function()
		object.BackgroundTransparency = 1
	end)

	pcall(function()
		object.ImageTransparency = 1
	end)

	pcall(function()
		object.TextTransparency = 1
	end)
end

local function hideNativeSettingsMenu()
	local robloxGui = CoreGui:FindFirstChild("RobloxGui")
	if not robloxGui then
		return
	end

	local shield = robloxGui:FindFirstChild("SettingsClippingShield")
	if not shield then
		return
	end

	hideGuiObject(shield)

	for _, object in ipairs(shield:GetDescendants()) do
		hideGuiObject(object)
	end
end

local hookedObjects = {}

local function hookGuiObject(object)
	if not object then
		return
	end

	if not object:IsA("GuiObject") then
		return
	end

	if hookedObjects[object] then
		return
	end

	hookedObjects[object] = true

	connect(object:GetPropertyChangedSignal("Visible"), function()
		if object.Visible then
			hideNativeSettingsMenu()
		end
	end)

	if object.Visible then
		hideGuiObject(object)
	end
end

local function hookSettingsShield(shield)
	if not shield then
		return
	end

	hideNativeSettingsMenu()

	hookGuiObject(shield)

	for _, object in ipairs(shield:GetDescendants()) do
		hookGuiObject(object)
	end

	connect(shield.DescendantAdded, function(object)
		hookGuiObject(object)

		task.defer(function()
			hideGuiObject(object)
			hideNativeSettingsMenu()
		end)
	end)
end

local function hookRobloxGui()
	local robloxGui = CoreGui:FindFirstChild("RobloxGui")

	if not robloxGui then
		robloxGui = CoreGui:WaitForChild("RobloxGui", 10)
	end

	if not robloxGui then
		return
	end

	local shield = robloxGui:FindFirstChild("SettingsClippingShield")

	if shield then
		hookSettingsShield(shield)
	end

	connect(robloxGui.ChildAdded, function(child)
		if child.Name == "SettingsClippingShield" then
			task.defer(function()
				hookSettingsShield(child)
			end)
		end
	end)

	connect(robloxGui.DescendantAdded, function(object)
		local currentShield =
			robloxGui:FindFirstChild("SettingsClippingShield")

		if currentShield and object:IsDescendantOf(currentShield) then
			hookGuiObject(object)

			task.defer(function()
				hideGuiObject(object)
			end)
		end
	end)
end

local function blockEscapeMenu(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		hideNativeSettingsMenu()

		task.defer(function()
			hideNativeSettingsMenu()
		end)
	end

	return Enum.ContextActionResult.Sink
end

-- Try Roblox's CoreAction API first.
local bound = pcall(function()
	ContextActionService:BindCoreActionAtPriority(
		"RBXEscapeMainMenu",
		blockEscapeMenu,
		false,
		10000,
		Enum.KeyCode.Escape,
		Enum.KeyCode.ButtonStart
	)
end)

-- Fallback.
if not bound then
	bound = pcall(function()
		ContextActionService:BindCoreAction(
			"RBXEscapeMainMenu",
			blockEscapeMenu,
			false,
			Enum.KeyCode.Escape,
			Enum.KeyCode.ButtonStart
		)
	end)
end

-- Final fallback if CoreAction isn't available.
if not bound then
	ContextActionService:BindActionAtPriority(
		"RBXEscapeMainMenu",
		blockEscapeMenu,
		false,
		10000,
		Enum.KeyCode.Escape,
		Enum.KeyCode.ButtonStart
	)
end

hookRobloxGui()

hideNativeSettingsMenu()

task.defer(function()
	hideNativeSettingsMenu()
end)


local G2L = {};

-- StarterGui.RobloxGui
G2L["1"] = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"));
G2L["1"]["IgnoreGuiInset"] = true;
G2L["1"]["DisplayOrder"] = 10;
G2L["1"]["ScreenInsets"] = Enum.ScreenInsets.DeviceSafeInsets;
G2L["1"]["Name"] = [[RobloxGui]];
G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling;
G2L["1"]["ResetOnSpawn"] = false;


-- StarterGui.RobloxGui.ControlFrame
G2L["2"] = Instance.new("Frame", G2L["1"]);
G2L["2"]["BorderSizePixel"] = 0;
G2L["2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["2"]["Size"] = UDim2.new(1, 0, 1, 0);
G2L["2"]["BorderColor3"] = Color3.fromRGB(28, 43, 54);
G2L["2"]["Name"] = [[ControlFrame]];
G2L["2"]["BackgroundTransparency"] = 1;


-- StarterGui.RobloxGui.ControlFrame.BottomLeftControl
G2L["3"] = Instance.new("Frame", G2L["2"]);
G2L["3"]["Size"] = UDim2.new(0, 130, 0, 46);
G2L["3"]["Position"] = UDim2.new(0, 0, 1, -46);
G2L["3"]["BorderColor3"] = Color3.fromRGB(28, 43, 54);
G2L["3"]["Name"] = [[BottomLeftControl]];
G2L["3"]["BackgroundTransparency"] = 1;


-- StarterGui.RobloxGui.ControlFrame.BottomRightControl
G2L["4"] = Instance.new("Frame", G2L["2"]);
G2L["4"]["Size"] = UDim2.new(0, 130, 0, 46);
G2L["4"]["Position"] = UDim2.new(1, -130, 1, -46);
G2L["4"]["BorderColor3"] = Color3.fromRGB(28, 43, 54);
G2L["4"]["Name"] = [[BottomRightControl]];
G2L["4"]["BackgroundTransparency"] = 1;


-- StarterGui.RobloxGui.ControlFrame.TopLeftControl
G2L["5"] = Instance.new("Frame", G2L["2"]);
G2L["5"]["Size"] = UDim2.new(0, 130, 0, 46);
G2L["5"]["BorderColor3"] = Color3.fromRGB(28, 43, 54);
G2L["5"]["Name"] = [[TopLeftControl]];
G2L["5"]["BackgroundTransparency"] = 1;


-- StarterGui.RobloxGui.Topbar
G2L["6"] = Instance.new("LocalScript", G2L["1"]);
G2L["6"]["Name"] = [[Topbar]];


-- StarterGui.RobloxGui.Modules
G2L["7"] = Instance.new("Folder", G2L["1"]);
G2L["7"]["Name"] = [[Modules]];


-- StarterGui.RobloxGui.Modules.BackpackScript
G2L["8"] = Instance.new("ModuleScript", G2L["7"]);
G2L["8"]["Name"] = [[BackpackScript]];


-- StarterGui.RobloxGui.Modules.Settings2
G2L["9"] = Instance.new("ModuleScript", G2L["7"]);
G2L["9"]["Name"] = [[Settings2]];


-- StarterGui.RobloxGui.Modules.PlayerlistModule
G2L["a"] = Instance.new("ModuleScript", G2L["7"]);
G2L["a"]["Name"] = [[PlayerlistModule]];


-- StarterGui.RobloxGui.Modules.Chat
G2L["b"] = Instance.new("ModuleScript", G2L["7"]);
G2L["b"]["Name"] = [[Chat]];


-- StarterGui.RobloxGui.Disable CoreGui
G2L["c"] = Instance.new("LocalScript", G2L["1"]);
G2L["c"]["Name"] = [[Disable CoreGui]];


-- Require G2L wrapper
local G2L_REQUIRE = require;
local G2L_MODULES = {};
local function require(Module:ModuleScript)
    local ModuleState = G2L_MODULES[Module];
    if ModuleState then
        if not ModuleState.Required then
            ModuleState.Required = true;
            ModuleState.Value = ModuleState.Closure();
        end
        return ModuleState.Value;
    end;
    return G2L_REQUIRE(Module);
end

G2L_MODULES[G2L["8"]] = {
Closure = function()
    local script = G2L["8"];-- Backpack Version 4.21
-- OnlyTwentyCharacters

-------------------
--| Exposed API |--
-------------------

local BackpackScript = {}
BackpackScript.OpenClose = nil -- Function to toggle open/close
BackpackScript.StateChanged = Instance.new('BindableEvent') -- Fires after any open/close, passes IsNowOpen

---------------------
--| Configurables |--
---------------------

local UseExperimentalGamepadEquip = false -- hotbar equipping in a new way! (its better!)

local ICON_SIZE = 60
if UseExperimentalGamepadEquip then
	ICON_SIZE = 100
end
local ICON_BUFFER = 5

local BACKGROUND_FADE = 0.50
local BACKGROUND_COLOR = Color3.new(31/255, 31/255, 31/255)

local SLOT_DRAGGABLE_COLOR = Color3.new(49/255, 49/255, 49/255)
local SLOT_EQUIP_COLOR = Color3.new(90/255, 142/255, 233/255)
local SLOT_EQUIP_THICKNESS = 0.1 -- Relative
local SLOT_FADE_LOCKED = 0.50 -- Locked means undraggable
local SLOT_BORDER_COLOR = Color3.new(1, 1, 1) -- Appears when dragging

local TOOLTIP_BUFFER = 6
local TOOLTIP_HEIGHT = 16
local TOOLTIP_OFFSET = -25 -- From top

local ARROW_IMAGE_OPEN = 'rbxasset://textures/ui/Backpack_Open.png'
local ARROW_IMAGE_CLOSE = 'rbxasset://textures/ui/Backpack_Close.png'
local ARROW_SIZE = UDim2.new(0, 14, 0, 9)
local ARROW_HOTKEY = Enum.KeyCode.Backquote.Value --TODO: Hookup '~' too?
local ARROW_HOTKEY_STRING = '`'

local HOTBAR_SLOTS_FULL = 10
if UseExperimentalGamepadEquip then
	HOTBAR_SLOTS_FULL = 8
end
local HOTBAR_SLOTS_MINI = 3
local HOTBAR_SLOTS_WIDTH_CUTOFF = 1024 -- Anything smaller is MINI
local HOTBAR_OFFSET_FROMBOTTOM = -30 -- Offset to make room for the Health GUI

local INVENTORY_ROWS_FULL = 4
local INVENTORY_ROWS_MINI = 2
local INVENTORY_HEADER_SIZE = 40

--local TITLE_OFFSET = 20 -- From left side
--local TITLE_TEXT = "Backpack"

local SEARCH_BUFFER = 5
local SEARCH_WIDTH = 200
local SEARCH_TEXT = "   Search"
local SEARCH_TEXT_OFFSET_FROMLEFT = 0
local SEARCH_BACKGROUND_COLOR = Color3.new(0.37, 0.37, 0.37)
local SEARCH_BACKGROUND_FADE = 0.15

local DOUBLE_CLICK_TIME = 0.5

-----------------
--| Variables |--
-----------------

local PlayersService = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local StarterGui = game:GetService('StarterGui')
local GuiService = game:GetService('GuiService')
local CoreGui = game.Players.LocalPlayer.PlayerGui
local ContextActionService = game:GetService('ContextActionService')
local RobloxGui = CoreGui:WaitForChild('RobloxGui')

--local gamepadSupportSuccess, gamepadSupportFlagValue = pcall(function() return settings():GetFFlag("TopbarGamepadSupport") end)
local IsGamepadSupported = false

local IS_PHONE = UserInputService.TouchEnabled and game.Workspace.CurrentCamera.ViewportSize.X < HOTBAR_SLOTS_WIDTH_CUTOFF

local HOTBAR_SLOTS = (IS_PHONE) and HOTBAR_SLOTS_MINI or HOTBAR_SLOTS_FULL
local HOTBAR_SIZE = UDim2.new(0, ICON_BUFFER + (HOTBAR_SLOTS * (ICON_SIZE + ICON_BUFFER)), 0, ICON_BUFFER + ICON_SIZE + ICON_BUFFER)
local ZERO_KEY_VALUE = Enum.KeyCode.Zero.Value
local DROP_HOTKEY_VALUE = Enum.KeyCode.Backspace.Value
local INVENTORY_ROWS = (IS_PHONE) and INVENTORY_ROWS_MINI or INVENTORY_ROWS_FULL

local Player = PlayersService.LocalPlayer

local MainFrame = nil
local HotbarFrame = nil
local InventoryFrame = nil
local ScrollingFrame = nil

local Character = nil
local Humanoid = nil
local Backpack = nil

local Slots = {} -- List of all Slots by index
local LowestEmptySlot = nil
local SlotsByTool = {} -- Map of Tools to their assigned Slots
local HotkeyFns = {} -- Map of KeyCode values to their assigned behaviors
local Dragging = {} -- Only used to check if anything is being dragged, to disable other input
local FullHotbarSlots = 0
local UpdateArrowFrame = nil -- Function defined in arrow init logic at bottom
local ActiveHopper = nil --NOTE: HopperBin
local StarterToolFound = false -- Special handling is required for the gear currently equipped on the site
local WholeThingEnabled = false
local TextBoxFocused = false -- ANY TextBox, not just the search box
local ResultsIndices = nil -- Results of a search, or nil
local HotkeyStrings = {} -- Used for eating/releasing hotkeys
local CharConns = {} -- Holds character connections to be cleared later
local TopBarEnabled = true
local GamepadEnabled = false -- determines if our gui needs to be gamepad friendly


-----------------
--| Functions |--
-----------------

local function NewGui(className, objectName)
	local newGui = Instance.new(className)
	newGui.Name = objectName
	newGui.BackgroundColor3 = Color3.new(0, 0, 0)
	newGui.BackgroundTransparency = 1
	newGui.BorderColor3 = Color3.new(0, 0, 0)
	newGui.BorderSizePixel = 0
	newGui.Size = UDim2.new(1, 0, 1, 0)
	if className:match('Text') then
		newGui.TextColor3 = Color3.new(1, 1, 1)
		newGui.Text = ''
		newGui.Font = Enum.Font.SourceSans
		newGui.FontSize = Enum.FontSize.Size14
		newGui.TextWrapped = true
		if className == 'TextButton' then
			newGui.Font = Enum.Font.SourceSansBold
			newGui.BorderSizePixel = 1
		end
	end
	return newGui
end

local function FindLowestEmpty()
	for i = 1, HOTBAR_SLOTS do
		local slot = Slots[i]
		if not slot.Tool then
			return slot
		end
	end
	return nil
end

local function AdjustHotbarFrames()
	local inventoryOpen = InventoryFrame.Visible -- (Show all)
	local visualTotal = (inventoryOpen) and HOTBAR_SLOTS or FullHotbarSlots
	local visualIndex = 0
	for i = 1, HOTBAR_SLOTS do
		local slot = Slots[i]
		if slot.Tool or inventoryOpen then
			visualIndex = visualIndex + 1
			slot:Readjust(visualIndex, visualTotal)

			if not UseExperimentalGamepadEquip then
				slot.Frame.Visible = true
			end
		else
			slot.Frame.Visible = false
		end
	end
end

local function CheckBounds(guiObject, x, y)
	local pos = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return (x > pos.X and x <= pos.X + size.X and y > pos.Y and y <= pos.Y + size.Y)
end

local function GetOffset(guiObject, point)
	local centerPoint = guiObject.AbsolutePosition + (guiObject.AbsoluteSize / 2)
	return (centerPoint - point).magnitude
end

local function DisableActiveHopper() --NOTE: HopperBin
	ActiveHopper:ToggleSelect()
	SlotsByTool[ActiveHopper]:UpdateEquipView()
	ActiveHopper = nil
end

local function UnequipAllTools() --NOTE: HopperBin
	Humanoid:UnequipTools()
	if ActiveHopper then
		DisableActiveHopper()
	end
end

local function EquipNewTool(tool) --NOTE: HopperBin
	UnequipAllTools()
	if tool:IsA('HopperBin') then
		tool:ToggleSelect()
		SlotsByTool[tool]:UpdateEquipView()
		ActiveHopper = tool
	else
		--Humanoid:EquipTool(tool) --NOTE: This would also unequip current Tool
		tool.Parent = Character --TODO: Switch back to above line after EquipTool is fixed!
	end
end

local function IsEquipped(tool)
	return tool and ((tool:IsA('HopperBin') and tool.Active) or tool.Parent == Character) --NOTE: HopperBin
end

local function MakeSlot(parent, index)
	index = index or (#Slots + 1)

	-- Slot Definition --

	local slot = {}
	slot.Tool = nil
	slot.Index = index
	slot.Frame = nil

	local SlotFrame = nil
	local ToolIcon = nil
	local ToolName = nil
	local ToolChangeConn = nil
	local HighlightFrame = nil

	--NOTE: The following are only defined for Hotbar Slots
	local ToolTip = nil
	local SlotNumber = nil

	-- Slot Functions --

	local function UpdateSlotFading()
		SlotFrame.BackgroundTransparency = (SlotFrame.Draggable) and 0 or SLOT_FADE_LOCKED
		SlotFrame.BackgroundColor3 = (SlotFrame.Draggable) and SLOT_DRAGGABLE_COLOR or BACKGROUND_COLOR
	end

	function slot:Reposition()
		-- Slots are positioned into rows
		local index = (ResultsIndices and ResultsIndices[self]) or self.Index
		local sizePlus = ICON_BUFFER + ICON_SIZE

		local modSlots = 0
		if UseExperimentalGamepadEquip then
			modSlots = ((index - HOTBAR_SLOTS) % 5)
			if modSlots == 0 then
				modSlots = 5
			end
		else
			modSlots = ((index - 1) % HOTBAR_SLOTS) + 1
		end

		local row = 0 
		if UseExperimentalGamepadEquip then
			row = math.floor( (index - HOTBAR_SLOTS - 1) / 5 )
		else
			row = (index > HOTBAR_SLOTS) and (math.floor((index - 1) / HOTBAR_SLOTS)) - 1 or 0
		end

		SlotFrame.Position = UDim2.new(0, ICON_BUFFER + ((modSlots - 1) * sizePlus), 0, ICON_BUFFER + (sizePlus * row))
	end

	function slot:Readjust(visualIndex, visualTotal) --NOTE: Only used for Hotbar slots
		if UseExperimentalGamepadEquip then return end

		local centered = HOTBAR_SIZE.X.Offset / 2
		local sizePlus = ICON_BUFFER + ICON_SIZE
		local midpointish = (visualTotal / 2) + 0.5
		local factor = visualIndex - midpointish
		SlotFrame.Position = UDim2.new(0, centered - (ICON_SIZE / 2) + (sizePlus * factor), 0, ICON_BUFFER)
	end

	function slot:Fill(tool)
		if not tool then
			return self:Clear()
		end

		self.Tool = tool

		local function assignToolData()
			local icon = tool.TextureId
			ToolIcon.Image = icon
			ToolName.Text = (icon == '') and tool.Name or '' -- (Only show name if no icon)
			if ToolTip and tool:IsA('Tool') then --NOTE: HopperBin
				ToolTip.Text = tool.ToolTip
				local width = ToolTip.TextBounds.X + TOOLTIP_BUFFER
				ToolTip.Size = UDim2.new(0, width, 0, TOOLTIP_HEIGHT)
				ToolTip.Position = UDim2.new(0.5, -width / 2, 0, TOOLTIP_OFFSET)
			end
		end
		assignToolData()

		if ToolChangeConn then 
			ToolChangeConn:disconnect()
			ToolChangeConn = nil
		end

		ToolChangeConn = tool.Changed:connect(function(property)
			if property == 'TextureId' or property == 'Name' or property == 'ToolTip' then
				assignToolData()
			end
		end)

		local hotbarSlot = (self.Index <= HOTBAR_SLOTS)
		local inventoryOpen = InventoryFrame.Visible

		if not hotbarSlot or inventoryOpen then
			SlotFrame.Draggable = true
		end

		self:UpdateEquipView()

		if hotbarSlot then
			FullHotbarSlots = FullHotbarSlots + 1
		end

		SlotsByTool[tool] = self
		LowestEmptySlot = FindLowestEmpty()
		UpdateArrowFrame()
	end

	function slot:Clear()
		if not self.Tool then return end

		if ToolChangeConn then 
			ToolChangeConn:disconnect()
			ToolChangeConn = nil
		end

		ToolIcon.Image = ''
		ToolName.Text = ''
		if ToolTip then
			ToolTip.Text = ''
			ToolTip.Visible = false
		end
		SlotFrame.Draggable = false

		self:UpdateEquipView(true) -- Show as unequipped

		if self.Index <= HOTBAR_SLOTS then
			FullHotbarSlots = FullHotbarSlots - 1
		end

		SlotsByTool[self.Tool] = nil
		self.Tool = nil
		LowestEmptySlot = FindLowestEmpty()
		UpdateArrowFrame()
	end

	function slot:UpdateEquipView(unequippedOverride)
		if not unequippedOverride and IsEquipped(self.Tool) then -- Equipped
			if not HighlightFrame then
				HighlightFrame = NewGui('Frame', 'Equipped')
				HighlightFrame.ZIndex = SlotFrame.ZIndex
				local t = SLOT_EQUIP_THICKNESS
				local dataTable = { -- Relative sizes and positions
					{t, 1, 0, 0},
					{1, t, 0, 0},
					{t, 1, 1 - t, 0},
					{1, t, 0, 1 - t},
				}
				for _, data in pairs(dataTable) do
					local edgeFrame = NewGui('Frame', 'Edge')
					edgeFrame.BackgroundTransparency = 0
					edgeFrame.BackgroundColor3 = SLOT_EQUIP_COLOR
					edgeFrame.Size = UDim2.new(data[1], 0, data[2], 0)
					edgeFrame.Position = UDim2.new(data[3], 0, data[4], 0)
					edgeFrame.ZIndex = HighlightFrame.ZIndex
					edgeFrame.Parent = HighlightFrame
				end
			end
			HighlightFrame.Parent = SlotFrame
		else -- In the Backpack
			if HighlightFrame then
				HighlightFrame.Parent = nil
			end
		end
		UpdateSlotFading()
	end

	function slot:IsEquipped()
		return IsEquipped(self.Tool)
	end

	function slot:Delete()
		SlotFrame:Destroy() --NOTE: Also clears connections
		table.remove(Slots, self.Index)
		local newSize = #Slots

		-- Now adjust the rest (both visually and representationally)
		for i = self.Index, newSize do
			Slots[i]:SlideBack()
		end

		if newSize % HOTBAR_SLOTS == 0 then -- We lost a row at the bottom! Adjust the CanvasSize
			local lastSlot = Slots[newSize]
			local lowestPoint = lastSlot.Frame.Position.Y.Offset + lastSlot.Frame.Size.Y.Offset
			ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, lowestPoint + ICON_BUFFER)
		end
	end

	function slot:Swap(targetSlot) --NOTE: This slot (self) must not be empty!
		local myTool, otherTool = self.Tool, targetSlot.Tool
		self:Clear()
		if otherTool then -- (Target slot might be empty)
			targetSlot:Clear()
			self:Fill(otherTool)
		end
		if myTool then
			targetSlot:Fill(myTool)
		else
			targetSlot:Clear()
		end
	end

	function slot:SlideBack() -- For inventory slot shifting
		self.Index = self.Index - 1
		SlotFrame.Name = self.Index
		self:Reposition()
	end

	function slot:TurnNumber(on)
		if SlotNumber then
			SlotNumber.Visible = on
		end
	end

	function slot:SetClickability(on) -- (Happens on open/close arrow)
		if self.Tool then
			SlotFrame.Draggable = not on
			UpdateSlotFading()
		end
	end

	function slot:CheckTerms(terms)
		local hits = 0
		local function checkEm(str, term)
			local _, n = str:lower():gsub(term, '')
			hits = hits + n
		end
		local tool = self.Tool
		for term in pairs(terms) do
			checkEm(tool.Name, term)
			if tool:IsA('Tool') then --NOTE: HopperBin
				checkEm(tool.ToolTip, term)
			end
		end
		return hits
	end

	-- Slot Init Logic --

	SlotFrame = NewGui('TextButton', index)
	SlotFrame.BackgroundColor3 = BACKGROUND_COLOR
	SlotFrame.BorderColor3 = SLOT_BORDER_COLOR
	SlotFrame.Text = ""
	SlotFrame.AutoButtonColor = false
	SlotFrame.BorderSizePixel = 0
	SlotFrame.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
	SlotFrame.Active = true
	SlotFrame.Draggable = false
	SlotFrame.BackgroundTransparency = SLOT_FADE_LOCKED
	SlotFrame.MouseButton1Click:connect(function() changeSlot(slot) end)
	slot.Frame = SlotFrame

	ToolIcon = NewGui('ImageLabel', 'Icon')
	ToolIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
	ToolIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
	ToolIcon.Parent = SlotFrame

	ToolName = NewGui('TextLabel', 'ToolName')
	ToolName.Size = UDim2.new(1, -2, 1, -2)
	ToolName.Position = UDim2.new(0, 1, 0, 1)
	ToolName.Parent = SlotFrame

	slot:Reposition()

	if index <= HOTBAR_SLOTS then -- Hotbar-Specific Slot Stuff
		-- ToolTip stuff
		ToolTip = NewGui('TextLabel', 'ToolTip')
		ToolTip.TextWrapped = false
		ToolTip.TextYAlignment = Enum.TextYAlignment.Top
		ToolTip.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		ToolTip.BackgroundTransparency = 0
		ToolTip.Visible = false
		ToolTip.Parent = SlotFrame
		SlotFrame.MouseEnter:connect(function()
			if ToolTip.Text ~= '' then
				ToolTip.Visible = true
			end
		end)
		SlotFrame.MouseLeave:connect(function() ToolTip.Visible = false end)

		-- Slot select logic, activated by clicking or pressing hotkey
		function slot:Select()
			local tool = slot.Tool
			if tool then
				if IsEquipped(tool) then --NOTE: HopperBin
					UnequipAllTools()
				elseif tool.Parent == Backpack then
					EquipNewTool(tool)
				end
			end
		end

		function slot:MoveToInventory()
			if slot.Index <= HOTBAR_SLOTS then -- From a Hotbar slot
				local tool = slot.Tool
				self:Clear() --NOTE: Order matters here
				local newSlot = MakeSlot(ScrollingFrame)
				newSlot:Fill(tool)
				if IsEquipped(tool) then -- Also unequip it --NOTE: HopperBin
					UnequipAllTools()
				end
				-- Also hide the inventory slot if we're showing results right now
				if ResultsIndices then
					newSlot.Frame.Visible = false
				end
			end
		end

		-- Show label and assign hotkeys for 1-9 and 0 (zero is always last slot when > 10 total)
		if index < 10 or index == HOTBAR_SLOTS then -- NOTE: Hardcoded on purpose!
			local slotNum = (index < 10) and index or 0
			SlotNumber = NewGui('TextLabel', 'Number')
			SlotNumber.Text = slotNum
			SlotNumber.Size = UDim2.new(0.15, 0, 0.15, 0)
			SlotNumber.Visible = false
			SlotNumber.Parent = SlotFrame
			HotkeyFns[ZERO_KEY_VALUE + slotNum] = slot.Select
		end

		if UseExperimentalGamepadEquip then
			local radius = 200
			local angle = (index + 5) * (math.pi/4)
			SlotFrame.Position = UDim2.new(0.5,-50 + math.cos(angle) * radius,0.5,-50 + math.sin(angle) * radius)
			SlotFrame.Visible = false
		end

	else -- Inventory-Specific Slot Stuff

		local newRow = false
		if UseExperimentalGamepadEquip then
			newRow = (index % 5 == 1)
		else
			newRow = (index % HOTBAR_SLOTS == 1)
		end

		if newRow then -- We are the first slot of a new row! Adjust the CanvasSize
			local lowestPoint = SlotFrame.Position.Y.Offset + SlotFrame.Size.Y.Offset
			ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, lowestPoint + ICON_BUFFER)
		end
		
		-- Scroll to new inventory slot, if we're open and not viewing search results
		if InventoryFrame.Visible and not ResultsIndices then
			local offset = ScrollingFrame.CanvasSize.Y.Offset - ScrollingFrame.AbsoluteSize.Y
			ScrollingFrame.CanvasPosition = Vector2.new(0, math.max(0, offset))
		end
	end

	do -- Dragging Logic
		local startPoint = SlotFrame.Position
		local lastUpTime = 0
		local startParent = nil

		SlotFrame.DragBegin:connect(function(dragPoint)
			Dragging[SlotFrame] = true
			startPoint = dragPoint

			SlotFrame.BorderSizePixel = 2

			-- Raise above other slots
			SlotFrame.ZIndex = 2
			ToolIcon.ZIndex = 2
			ToolName.ZIndex = 2
			if SlotNumber then
				SlotNumber.ZIndex = 2
			end
			if HighlightFrame then
				HighlightFrame.ZIndex = 2
				for _, child in pairs(HighlightFrame:GetChildren()) do
					child.ZIndex = 2
				end
			end

			-- Circumvent the ScrollingFrame's ClipsDescendants property
			startParent = SlotFrame.Parent
			if startParent == ScrollingFrame then
				SlotFrame.Parent = InventoryFrame
				local pos = ScrollingFrame.Position
				local offset = ScrollingFrame.CanvasPosition - Vector2.new(pos.X.Offset, pos.Y.Offset)
				SlotFrame.Position = SlotFrame.Position - UDim2.new(0, offset.X, 0, offset.Y)
			end
		end)

		SlotFrame.DragStopped:connect(function(x, y)
			local now = tick()
			SlotFrame.Position = startPoint
			SlotFrame.Parent = startParent

			SlotFrame.BorderSizePixel = 0

			-- Restore height
			SlotFrame.ZIndex = 1
			ToolIcon.ZIndex = 1
			ToolName.ZIndex = 1
			if SlotNumber then
				SlotNumber.ZIndex = 1
			end
			if HighlightFrame then
				HighlightFrame.ZIndex = 1
				for _, child in pairs(HighlightFrame:GetChildren()) do
					child.ZIndex = 1
				end
			end

			Dragging[SlotFrame] = nil

			-- Make sure the tool wasn't dropped
			if not slot.Tool then
				return
			end

			-- Check where we were dropped
			if CheckBounds(InventoryFrame, x, y) then
				if slot.Index <= HOTBAR_SLOTS then
					slot:MoveToInventory()
				end
				-- Check for double clicking on an inventory slot, to move into empty hotbar slot
				if slot.Index > HOTBAR_SLOTS and now - lastUpTime < DOUBLE_CLICK_TIME then
					if LowestEmptySlot then
						local myTool = slot.Tool
						slot:Clear()
						LowestEmptySlot:Fill(myTool)
						slot:Delete()
					end
					now = 0 -- Resets the timer
				end
			elseif CheckBounds(HotbarFrame, x, y) then
				local closest = {math.huge, nil}
				for i = 1, HOTBAR_SLOTS do
					local otherSlot = Slots[i]
					local offset = GetOffset(otherSlot.Frame, Vector2.new(x, y))
					if offset < closest[1] then
						closest = {offset, otherSlot}
					end
				end
				local closestSlot = closest[2]
				if closestSlot ~= slot then
					slot:Swap(closestSlot)
					if slot.Index > HOTBAR_SLOTS then
						local tool = slot.Tool
						if not tool then -- Clean up after ourselves if we're an inventory slot that's now empty
							slot:Delete()
						else -- Moved inventory slot to hotbar slot, and gained a tool that needs to be unequipped
							if IsEquipped(tool) then --NOTE: HopperBin
								UnequipAllTools()
							end
							-- Also hide the inventory slot if we're showing results right now
							if ResultsIndices then
								slot.Frame.Visible = false
							end
						end
					end
				end
			else
				-- local tool = slot.Tool
				-- if tool.CanBeDropped then --TODO: HopperBins
					-- tool.Parent = workspace
					-- --TODO: Move away from character
				-- end
				if slot.Index <= HOTBAR_SLOTS then
					slot:MoveToInventory() --NOTE: Temporary
				end
			end

			lastUpTime = now
		end)
	end

	-- All ready!
	SlotFrame.Parent = parent
	Slots[index] = slot
	return slot
end

local function OnChildAdded(child) -- To Character or Backpack
	if not child:IsA('Tool') and not child:IsA('HopperBin') then --NOTE: HopperBin
		if child:IsA('Humanoid') and child.Parent == Character then
			Humanoid = child
		end
		return
	end
	local tool = child

	if ActiveHopper and tool.Parent == Character then --NOTE: HopperBin
		DisableActiveHopper()
	end

	--TODO: Optimize / refactor / do something else
	if not StarterToolFound and tool.Parent == Character and not SlotsByTool[tool] then
		local starterGear = Player:FindFirstChild('StarterGear')
		if starterGear then
			if starterGear:FindFirstChild(tool.Name) then
				StarterToolFound = true
				local slot = LowestEmptySlot or MakeSlot(ScrollingFrame)
				for i = slot.Index, 1, -1 do
					local curr = Slots[i] -- An empty slot, because above
					local pIndex = i - 1
					if pIndex > 0 then
						local prev = Slots[pIndex] -- Guaranteed to be full, because above
						prev:Swap(curr)
					else
						curr:Fill(tool)
					end
				end
				-- Have to manually unequip a possibly equipped tool
				for _, child in pairs(Character:GetChildren()) do
					if child:IsA('Tool') and child ~= tool then
						child.Parent = Backpack
					end
				end
				AdjustHotbarFrames()
				return -- We're done here
			end
		end
	end

	-- The tool is either moving or new
	local slot = SlotsByTool[tool]
	if slot then
		slot:UpdateEquipView()
	else -- New! Put into lowest hotbar slot or new inventory slot
		slot = LowestEmptySlot or MakeSlot(ScrollingFrame)
		slot:Fill(tool)
		if slot.Index <= HOTBAR_SLOTS and not InventoryFrame.Visible then
			AdjustHotbarFrames()
		end
		if tool:IsA('HopperBin') then --NOTE: HopperBin
			if tool.Active then
				UnequipAllTools()
				ActiveHopper = tool
			end
		end
	end
end

local function OnChildRemoved(child) -- From Character or Backpack
	if not child:IsA('Tool') and not child:IsA('HopperBin') then --NOTE: HopperBin
		return
	end
	local tool = child

	-- Ignore this event if we're just moving between the two
	local newParent = tool.Parent
	if newParent == Character or newParent == Backpack then
		return
	end

	local slot = SlotsByTool[tool]
	if slot then
		slot:Clear()
		if slot.Index > HOTBAR_SLOTS then -- Inventory slot
			slot:Delete()
		elseif not InventoryFrame.Visible then
			AdjustHotbarFrames()
		end
	end

	if tool == ActiveHopper then --NOTE: HopperBin
		ActiveHopper = nil
	end
end

local function OnCharacterAdded(character)
	-- First, clean up any old slots
	for i = #Slots, 1, -1 do
		local slot = Slots[i]
		if slot.Tool then
			slot:Clear()
		end
		if i > HOTBAR_SLOTS then
			slot:Delete()
		end
	end
	ActiveHopper = nil --NOTE: HopperBin

	-- And any old connections
	for _, conn in pairs(CharConns) do
		conn:disconnect()
	end
	CharConns = {}

	-- Hook up the new character
	Character = character
	table.insert(CharConns, character.ChildRemoved:connect(OnChildRemoved))
	table.insert(CharConns, character.ChildAdded:connect(OnChildAdded))
	for _, child in pairs(character:GetChildren()) do
		OnChildAdded(child)
	end
	--NOTE: Humanoid is set inside OnChildAdded

	-- And the new backpack, when it gets here
	Backpack = Player:WaitForChild('Backpack')
	table.insert(CharConns, Backpack.ChildRemoved:connect(OnChildRemoved))
	table.insert(CharConns, Backpack.ChildAdded:connect(OnChildAdded))
	for _, child in pairs(Backpack:GetChildren()) do
		OnChildAdded(child)
	end

	AdjustHotbarFrames()
end

local function OnInputBegan(input, isProcessed)
	-- Pass through keyboard hotkeys when not typing into a TextBox and not disabled (except for the Drop key)
	if input.UserInputType == Enum.UserInputType.Keyboard and not TextBoxFocused and (WholeThingEnabled or input.KeyCode.Value == DROP_HOTKEY_VALUE) then
		local hotkeyBehavior = HotkeyFns[input.KeyCode.Value]
		if hotkeyBehavior then
			hotkeyBehavior(isProcessed)
		end
	end
end

local function OnUISChanged(property)
	if property == 'KeyboardEnabled' then
		local on = UserInputService.KeyboardEnabled
		for i = 1, HOTBAR_SLOTS do
			Slots[i]:TurnNumber(on)
		end
	end
end



-------------------------
--| Gamepad Functions |--
-------------------------
local lastChangeToolInputObject = nil
local lastChangeToolInputTime = nil
local maxEquipDeltaTime = 0.06
local noOpFunc = function() end
local selectDirection = Vector2.new(0,0)
local hotbarVisible = false

function unbindAllGamepadEquipActions()
	ContextActionService:UnbindAction("RBXBackpackHasGamepadFocus")
	ContextActionService:UnbindAction("RBXCloseInventory")
end

local function setHotbarVisibility(visible, isInventoryScreen)
	for i = 1, HOTBAR_SLOTS do
		local hotbarSlot = Slots[i]
		if hotbarSlot and hotbarSlot.Frame and (isInventoryScreen or hotbarSlot.Tool) then
			hotbarSlot.Frame.Visible = visible
		end
	end
end

local function getInputDirection(inputObject)
	local buttonModifier = 1
	if inputObject.UserInputState == Enum.UserInputState.End then
		buttonModifier = -1
	end

	if inputObject.KeyCode == Enum.KeyCode.Thumbstick1 then

		local magnitude = inputObject.Position.magnitude

		if magnitude > 0.98 then
			local normalizedVector = Vector2.new(inputObject.Position.x / magnitude, -inputObject.Position.y / magnitude)
			selectDirection =  normalizedVector
		else
			selectDirection = Vector2.new(0,0)
		end
	elseif inputObject.KeyCode == Enum.KeyCode.DPadLeft then
		selectDirection = Vector2.new(selectDirection.x - 1 * buttonModifier, selectDirection.y)
	elseif inputObject.KeyCode == Enum.KeyCode.DPadRight then
		selectDirection = Vector2.new(selectDirection.x + 1 * buttonModifier, selectDirection.y)
	elseif inputObject.KeyCode == Enum.KeyCode.DPadUp then
		selectDirection = Vector2.new(selectDirection.x, selectDirection.y - 1 * buttonModifier)
	elseif inputObject.KeyCode == Enum.KeyCode.DPadDown then
		selectDirection = Vector2.new(selectDirection.x, selectDirection.y + 1 * buttonModifier)
	else
		selectDirection = Vector2.new(0,0)
	end

	return selectDirection
end

local selectToolExperiment = function(actionName, inputState, inputObject)

	local inputDirection = getInputDirection(inputObject)

	if inputDirection == Vector2.new(0,0) then
		return
	end

	local angle = math.atan2(inputDirection.y, inputDirection.x) - math.atan2(-1, 0)
	if angle < 0 then
		angle = angle + (math.pi * 2)
	end

	local quarterPi = (math.pi * 0.25)

	local index = (angle/quarterPi) + 1
	index = math.floor(index + 0.5) -- round index to whole number
	if index > HOTBAR_SLOTS then
		index = 1
	end

	if index > 0 then
		local selectedSlot = Slots[index]
		if selectedSlot and selectedSlot.Tool and not selectedSlot:IsEquipped() then
			selectedSlot:Select()
		end
	else
		UnequipAllTools()
	end
end

local changeToolFuncExperiment = nil
changeToolFuncExperiment = function(actionName, inputState, inputObject)
	local hasHotBar = false
	for i = 1, HOTBAR_SLOTS do
		if Slots[i].Tool then
			hasHotBar = true
			break
		end
	end

	if not hasHotBar then return end

	if inputState == Enum.UserInputState.Begin then
		hotbarVisible = not hotbarVisible
		if hotbarVisible then
			HotbarFrame.Position = UDim2.new(0.5, -HotbarFrame.AbsoluteSize.x/2, 0.5, -HotbarFrame.AbsoluteSize.y/2)
		end
		setHotbarVisibility(hotbarVisible)
	else
		return
	end

	if not hotbarVisible then
		selectDirection = Vector2.new(0,0)
		ContextActionService:UnbindAction("RBXRadialSelectTool")
		ContextActionService:UnbindAction("RBXRadialSelectToolKillInput")
		ContextActionService:UnbindAction("RBXHotbarEquip")
		ContextActionService:BindAction("RBXHotbarEquip", changeToolFuncExperiment, false, Enum.KeyCode.ButtonR1)
	else
		UnequipAllTools()

		ContextActionService:BindAction("RBXRadialSelectToolKillInput", noOpFunc, false, Enum.UserInputType.Gamepad1)
		ContextActionService:UnbindAction("RBXHotbarEquip")
		ContextActionService:BindAction("RBXHotbarEquip", changeToolFuncExperiment, false, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonB)
		ContextActionService:BindAction("RBXRadialSelectTool", selectToolExperiment, false, Enum.KeyCode.Thumbstick1, 
											Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown)
	end
end

local changeToolFunc = function(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then return end

	if lastChangeToolInputObject then
		if (lastChangeToolInputObject.KeyCode == Enum.KeyCode.ButtonR1 and 
			inputObject.KeyCode == Enum.KeyCode.ButtonL1) or
			(lastChangeToolInputObject.KeyCode == Enum.KeyCode.ButtonL1 and 
			inputObject.KeyCode == Enum.KeyCode.ButtonR1) then
				if (tick() - lastChangeToolInputTime) <= maxEquipDeltaTime then
					UnequipAllTools()
					lastChangeToolInputObject = inputObject
					lastChangeToolInputTime = tick()
					return
				end
		end
	end

	lastChangeToolInputObject = inputObject
	lastChangeToolInputTime = tick()

	delay(maxEquipDeltaTime, function()
		if lastChangeToolInputObject ~= inputObject then return end

		local moveDirection = 0
		if (inputObject.KeyCode == Enum.KeyCode.ButtonL1) then
			moveDirection = -1
		else
			moveDirection = 1
		end

		for i = 1, HOTBAR_SLOTS do
			local hotbarSlot = Slots[i]
			if hotbarSlot:IsEquipped() then

				local newSlotPosition = moveDirection + i
				if newSlotPosition > HOTBAR_SLOTS then
					newSlotPosition = 1
				elseif newSlotPosition < 1 then
					newSlotPosition = HOTBAR_SLOTS
				end

				local origNewSlotPos = newSlotPosition
				while not Slots[newSlotPosition].Tool do
					newSlotPosition = newSlotPosition + moveDirection
					if newSlotPosition == origNewSlotPos then return end

					if newSlotPosition > HOTBAR_SLOTS then
						newSlotPosition = 1
					elseif newSlotPosition < 1 then
						newSlotPosition = HOTBAR_SLOTS
					end
				end

				Slots[newSlotPosition]:Select()
				return
			end
		end

		for i = 1, HOTBAR_SLOTS do
			if Slots[i].Tool then
				Slots[i]:Select()
				return
			end
		end
	end)
end

function getGamepadSwapSlot()
	for i = 1, #Slots do
		if Slots[i].Frame.BorderSizePixel > 0 then
			return Slots[i]
		end
	end
end


function changeSlot(slot)
	if slot.Frame == GuiService.SelectedObject then
		local currentlySelectedSlot = getGamepadSwapSlot()

		if currentlySelectedSlot then
			currentlySelectedSlot.Frame.BorderSizePixel = 0
			if currentlySelectedSlot ~= slot then
				slot:Swap(currentlySelectedSlot)
				
				if slot.Index > HOTBAR_SLOTS and not slot.Tool then
					if GuiService.SelectedObject == slot.Frame then
						GuiService.SelectedObject = currentlySelectedSlot.Frame
					end
					slot:Delete()
				end

				if currentlySelectedSlot.Index > HOTBAR_SLOTS and not currentlySelectedSlot.Tool then
					if GuiService.SelectedObject == currentlySelectedSlot.Frame then
						GuiService.SelectedObject = slot.Frame
					end
					currentlySelectedSlot:Delete()
				end
			end
		else
			slot.Frame.BorderSizePixel = 1
		end
	else
		slot:Select()
	end
end


function enableGamepadInventoryControl()
	local goBackOneLevel = function(actionName, inputState, inputObject)
		if inputState ~= Enum.UserInputState.Begin then return end

		local selectedSlot = getGamepadSwapSlot()
		if selectedSlot then
			local selectedSlot = getGamepadSwapSlot()
			if selectedSlot then
				selectedSlot.Frame.BorderSizePixel = 0
				return
			end
		elseif InventoryFrame.Visible then
			BackpackScript.OpenClose()
		end
	end

	ContextActionService:BindAction("RBXBackpackHasGamepadFocus",noOpFunc, false, Enum.UserInputType.Gamepad1)
	ContextActionService:BindAction("RBXCloseInventory", goBackOneLevel, false, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonStart)

	GuiService.SelectedObject = HotbarFrame:FindFirstChild("1")
end

function disableGamepadInventoryControl()
	unbindAllGamepadEquipActions()

	for i = 1, HOTBAR_SLOTS do
		local hotbarSlot = Slots[i]
		if hotbarSlot and hotbarSlot.Frame then
			hotbarSlot.Frame.BorderSizePixel = 0
		end
	end

	GuiService.SelectedObject = nil
end

function gamepadDisconnected()
	GamepadEnabled = false
	disableGamepadInventoryControl()
	ContextActionService:UnbindAction("RBXHotbarEquip")
end

function gamepadConnected()
	GamepadEnabled = true
	GuiService:AddSelectionParent("RBXBackpackSelection", MainFrame)

	if UseExperimentalGamepadEquip then
		ContextActionService:BindAction("RBXHotbarEquip", changeToolFuncExperiment, false, Enum.KeyCode.ButtonR1)
		HotbarFrame.Position = UDim2.new(HotbarFrame.Position.X.Scale, HotbarFrame.Position.X.Offset, 0.5, -35)
	else
		ContextActionService:BindAction("RBXHotbarEquip", changeToolFunc, false, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
	end

	if InventoryFrame.Visible then
		enableGamepadInventoryControl()
	end
end
-----------------------------
--| End Gamepad Functions |--
-----------------------------

--game:GetService('UserInputService').InputBegan:Connect(function(key, proc)
--	if not proc then
--		local str = game.UserInputService:GetStringForKeyCode(key.KeyCode)
--		changeToolFunc(str)
--	end
--end)

local function OnCoreGuiChanged(coreGuiType, enabled)
	-- Check for enabling/disabling the whole thing
	if coreGuiType == Enum.CoreGuiType.Backpack or coreGuiType == Enum.CoreGuiType.All then
		WholeThingEnabled = enabled
		MainFrame.Visible = enabled

		-- Eat/Release hotkeys (Doesn't affect UserInputService)
		for _, keyString in pairs(HotkeyStrings) do
			if enabled then
				--GuiService:AddKey(keyString)
			else
				--GuiService:RemoveKey(keyString)
			end
		end

		if IsGamepadSupported and GamepadEnabled then
			if enabled then
				if UseExperimentalGamepadEquip then
					ContextActionService:BindAction("RBXHotbarEquip", changeToolFuncExperiment, false, Enum.KeyCode.ButtonR1)
				else
					ContextActionService:BindAction("RBXHotbarEquip", changeToolFunc, false, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
				end
			else
				disableGamepadInventoryControl()
				ContextActionService:UnbindAction("RBXHotbarEquip")
			end
		end
	end

	-- Also check if the Health GUI is showing, and shift everything down (or back up) accordingly
	if not TopBarEnabled and (coreGuiType == Enum.CoreGuiType.Health or coreGuiType == Enum.CoreGuiType.All) then
		MainFrame.Position = UDim2.new(0, 0, 0, enabled and HOTBAR_OFFSET_FROMBOTTOM or 0)
	end
end



--------------------
--| Script Logic |--
--------------------

-- First check if the TopBar is enabled. This affects the ArrowFrame existence and MainFrame position
--pcall(function() TopBarEnabled = settings():GetFFlag('UseInGameTopBar') end)

-- Make the main frame, which (mostly) covers the screen
MainFrame = NewGui('Frame', 'Backpack')
MainFrame.Visible = false
MainFrame.Parent = RobloxGui

-- Make the HotbarFrame, which holds only the Hotbar Slots
HotbarFrame = NewGui('Frame', 'Hotbar')
HotbarFrame.Size = HOTBAR_SIZE
HotbarFrame.Position = UDim2.new(0.5, -HotbarFrame.Size.X.Offset / 2, 1, -HotbarFrame.Size.Y.Offset)
HotbarFrame.Parent = MainFrame

-- Make all the Hotbar Slots
for i = 1, HOTBAR_SLOTS do
	local slot = MakeSlot(HotbarFrame, i)
	slot.Frame.Visible = false

	if not LowestEmptySlot then
		LowestEmptySlot = slot
	end
end

-- Make the Inventory, which holds the ScrollingFrame, the header, and the search box
InventoryFrame = NewGui('Frame', 'Inventory')
InventoryFrame.BackgroundTransparency = BACKGROUND_FADE
InventoryFrame.BackgroundColor3 = BACKGROUND_COLOR
InventoryFrame.Active = true
if UseExperimentalGamepadEquip then
	InventoryFrame.Size = UDim2.new(0, 530, 0, 480)
	InventoryFrame.Position = UDim2.new(0.5, -530, 0.5, -240)
else
	InventoryFrame.Size = UDim2.new(0, HotbarFrame.Size.X.Offset, 0, (HotbarFrame.Size.Y.Offset * INVENTORY_ROWS) + INVENTORY_HEADER_SIZE)
	InventoryFrame.Position = UDim2.new(0.5, -InventoryFrame.Size.X.Offset / 2, 1, HotbarFrame.Position.Y.Offset - InventoryFrame.Size.Y.Offset)
end
InventoryFrame.Visible = false
InventoryFrame.Parent = MainFrame

-- Make the ScrollingFrame, which holds the rest of the Slots (however many)
ScrollingFrame = NewGui('ScrollingFrame', 'ScrollingFrame')
if UseExperimentalGamepadEquip then
	ScrollingFrame.Size = UDim2.new(1, 0, 1, -INVENTORY_HEADER_SIZE)
else
	ScrollingFrame.Size = UDim2.new(1, ScrollingFrame.ScrollBarThickness + 1, 1, -INVENTORY_HEADER_SIZE)
end

ScrollingFrame.Position = UDim2.new(0, 0, 0, INVENTORY_HEADER_SIZE)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.Parent = InventoryFrame

-- Make the header title, in the Inventory
--local headerText = NewGui('TextLabel', 'Header')
--headerText.Text = TITLE_TEXT
--headerText.TextXAlignment = Enum.TextXAlignment.Left
--headerText.Font = Enum.Font.SourceSansBold
--headerText.FontSize = Enum.FontSize.Size48
--headerText.TextStrokeColor3 = SLOT_EQUIP_COLOR
--headerText.TextStrokeTransparency = BACKGROUND_FADE
--headerText.Size = UDim2.new(0, (InventoryFrame.Size.X.Offset / 2) - TITLE_OFFSET, 0, INVENTORY_HEADER_SIZE)
--headerText.Position = UDim2.new(0, TITLE_OFFSET, 0, 0)
--headerText.Parent = InventoryFrame

do -- Search stuff
	local searchFrame = NewGui('Frame', 'Search')
	searchFrame.BackgroundColor3 = SEARCH_BACKGROUND_COLOR
	searchFrame.BackgroundTransparency = SEARCH_BACKGROUND_FADE
	searchFrame.Size = UDim2.new(0, SEARCH_WIDTH - (SEARCH_BUFFER * 2), 0, INVENTORY_HEADER_SIZE - (SEARCH_BUFFER * 2))
	searchFrame.Position = UDim2.new(1, -searchFrame.Size.X.Offset - SEARCH_BUFFER, 0, SEARCH_BUFFER)
	searchFrame.Parent = InventoryFrame

	local searchBox = NewGui('TextBox', 'TextBox')
	searchBox.Text = SEARCH_TEXT
	searchBox.ClearTextOnFocus = false
	searchBox.FontSize = Enum.FontSize.Size24
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.Size = searchFrame.Size - UDim2.new(0, SEARCH_TEXT_OFFSET_FROMLEFT, 0, 0)
	searchBox.Position = UDim2.new(0, SEARCH_TEXT_OFFSET_FROMLEFT, 0, 0)
	searchBox.Parent = searchFrame

	local xButton = NewGui('TextButton', 'X')
	xButton.Text = 'x'
	xButton.TextColor3 = SLOT_EQUIP_COLOR
	xButton.FontSize = Enum.FontSize.Size24
	xButton.TextYAlignment = Enum.TextYAlignment.Bottom
	xButton.BackgroundColor3 = SEARCH_BACKGROUND_COLOR
	xButton.BackgroundTransparency = 0
	xButton.Size = UDim2.new(0, searchFrame.Size.Y.Offset - (SEARCH_BUFFER * 2), 0, searchFrame.Size.Y.Offset - (SEARCH_BUFFER * 2))
	xButton.Position = UDim2.new(1, -xButton.Size.X.Offset - (SEARCH_BUFFER * 2), 0.5, -xButton.Size.Y.Offset / 2)
	xButton.ZIndex = 0
	xButton.Visible = true
	xButton.BorderSizePixel = 0
	xButton.Parent = searchFrame

	local function search()
		local terms = {}
		for word in searchBox.Text:gmatch('%S+') do
			terms[word:lower()] = true
		end

		local hitTable = {}
		for i = HOTBAR_SLOTS + 1, #Slots do -- Only search inventory slots
			local slot = Slots[i]
			local hits = slot:CheckTerms(terms)
			table.insert(hitTable, {slot, hits})
			slot.Frame.Visible = false
		end

		table.sort(hitTable, function(left, right)
			return left[2] > right[2]
		end)
		ResultsIndices = {}

		for i, data in ipairs(hitTable) do
			local slot, hits = data[1], data[2]
			if hits > 0 then
				ResultsIndices[slot] = HOTBAR_SLOTS + i
				slot:Reposition()
				slot.Frame.Visible = true
			end
		end
		
		ScrollingFrame.CanvasPosition = Vector2.new(0, 0)

		xButton.ZIndex = 3
	end

	local function clearResults()
		if xButton.ZIndex > 0 then
			ResultsIndices = nil
			for i = HOTBAR_SLOTS + 1, #Slots do
				local slot = Slots[i]
				slot:Reposition()
				slot.Frame.Visible = true
			end
			xButton.ZIndex = 0
		end
	end

	local function reset()
		clearResults()
		searchBox.Text = SEARCH_TEXT
	end

	local function onChanged(property)
		if property == 'Text' then
			local text = searchBox.Text
			if text == '' then
				clearResults()
			elseif text ~= SEARCH_TEXT then
				search()
			end
		end
	end

	local function onFocused()
		if searchBox.Text == SEARCH_TEXT then
			searchBox.Text = ''
		end
	end

	local function focusLost(enterPressed)
		if enterPressed then
			--TODO: Could optimize
			search()
		elseif searchBox.Text == '' then
			searchBox.Text = SEARCH_TEXT
		end
	end

	searchBox.Focused:connect(onFocused)
	xButton.MouseButton1Click:connect(reset)
	searchBox.Changed:connect(onChanged)
	searchBox.FocusLost:connect(focusLost)

	BackpackScript.StateChanged.Event:connect(function(isNowOpen)
		xButton.Modal = isNowOpen -- Allows free mouse movement even in first person
		if not isNowOpen then
			reset()
		end
	end)

	HotkeyFns[Enum.KeyCode.Escape.Value] = function(isProcessed)
		if isProcessed then -- Pressed from within a TextBox
			reset()
		elseif InventoryFrame.Visible then
			BackpackScript.OpenClose()
		end
	end
end

do -- Make the Inventory expand/collapse arrow (unless TopBar)
	local arrowFrame, arrowIcon = nil, nil, nil
	local collapsed, closed, opened = nil, nil, nil

	local removeHotBarSlot = function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		if not GuiService.SelectedObject then return end

		for i = 1, HOTBAR_SLOTS do
			if Slots[i].Frame == GuiService.SelectedObject and Slots[i].Tool then
				Slots[i]:MoveToInventory()
				return
			end
		end
	end

	local function openClose()
		if not next(Dragging) then -- Only continue if nothing is being dragged
			InventoryFrame.Visible = not InventoryFrame.Visible
			local nowOpen = InventoryFrame.Visible
			if arrowIcon then
				arrowIcon.Image = (nowOpen) and ARROW_IMAGE_CLOSE or ARROW_IMAGE_OPEN
			end
			AdjustHotbarFrames()
			UpdateArrowFrame()
			HotbarFrame.Active = not HotbarFrame.Active
			for i = 1, HOTBAR_SLOTS do
				Slots[i]:SetClickability(not nowOpen)
			end
		end

		if IsGamepadSupported then
			if GamepadEnabled then
				if InventoryFrame.Visible then
					enableGamepadInventoryControl()
				else
					disableGamepadInventoryControl()
				end
			end

			if InventoryFrame.Visible and GamepadEnabled then
				ContextActionService:BindAction("RBXRemoveSlot", removeHotBarSlot, false, Enum.KeyCode.ButtonX)
				if UseExperimentalGamepadEquip then
					HotbarFrame.Position = UDim2.new(1, -800, 0.5, -35)
					setHotbarVisibility(true, true)
				end
			elseif GamepadEnabled then
				ContextActionService:UnbindAction("RBXRemoveSlot")

				if UseExperimentalGamepadEquip then
					setHotbarVisibility(false)
					HotbarFrame.Position = UDim2.new(0.5, -HotbarFrame.AbsoluteSize.x/2, 0.5, -HotbarFrame.AbsoluteSize.y/2)
				end
			end
		end
		BackpackScript.StateChanged:Fire(InventoryFrame.Visible)
	end
	HotkeyFns[ARROW_HOTKEY] = openClose
	BackpackScript.OpenClose = openClose -- Exposed

	if not TopBarEnabled then
		arrowFrame = NewGui('Frame', 'Arrow')
		arrowFrame.BackgroundTransparency = BACKGROUND_FADE
		arrowFrame.BackgroundColor3 = BACKGROUND_COLOR
		arrowFrame.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE / 2)
		local hotbarBottom = HotbarFrame.Position.Y.Offset + HotbarFrame.Size.Y.Offset
		arrowFrame.Position = UDim2.new(0.5, -arrowFrame.Size.X.Offset / 2, 1, hotbarBottom - arrowFrame.Size.Y.Offset)

		arrowIcon = NewGui('ImageLabel', 'Icon')
		arrowIcon.Image = ARROW_IMAGE_OPEN
		arrowIcon.Size = ARROW_SIZE
		arrowIcon.Position = UDim2.new(0.5, -arrowIcon.Size.X.Offset / 2, 0.5, -arrowIcon.Size.Y.Offset / 2)
		arrowIcon.Parent = arrowFrame

		collapsed = arrowFrame.Position
		closed = collapsed + UDim2.new(0, 0, 0, -HotbarFrame.Size.Y.Offset)
		opened = closed + UDim2.new(0, 0, 0, -InventoryFrame.Size.Y.Offset)

		arrowFrame.Parent = MainFrame
	end

	-- Define global function
	UpdateArrowFrame = function()
		if arrowFrame then
			arrowFrame.Position = (InventoryFrame.Visible) and opened or ((FullHotbarSlots == 0) and collapsed or closed)
		end
	end
end

-- Now that we're done building the GUI, we connect to all the major events

-- Wait for the player if LocalPlayer wasn't ready earlier
while not Player do
	wait()
	Player = PlayersService.LocalPlayer
end

-- Listen to current and all future characters of our player
Player.CharacterAdded:connect(OnCharacterAdded)
if Player.Character then
	OnCharacterAdded(Player.Character)
end

do -- Hotkey stuff
	-- Init HotkeyStrings, used for eating hotkeys
	for i = 0, 9 do
		table.insert(HotkeyStrings, tostring(i))
	end
	table.insert(HotkeyStrings, ARROW_HOTKEY_STRING)

	-- Listen to key down
	UserInputService.InputBegan:connect(OnInputBegan)

	-- Listen to ANY TextBox gaining or losing focus, for disabling all hotkeys
	UserInputService.TextBoxFocused:connect(function() TextBoxFocused = true end)
	UserInputService.TextBoxFocusReleased:connect(function() TextBoxFocused = false end)

	-- Manual unequip for HopperBins on drop button pressed
	HotkeyFns[DROP_HOTKEY_VALUE] = function() --NOTE: HopperBin
		if ActiveHopper then
			UnequipAllTools()
		end
	end

	-- Listen to keyboard status, for showing/hiding hotkey labels
	UserInputService.Changed:connect(OnUISChanged)
	OnUISChanged('KeyboardEnabled')

	-- Listen to gamepad status, for allowing gamepad style selection/equip
	if IsGamepadSupported then
		if UserInputService:GetGamepadConnected(Enum.UserInputType.Gamepad1) then
			gamepadConnected()
		end
		UserInputService.GamepadConnected:connect(function(gamepadEnum) 
			if gamepadEnum == Enum.UserInputType.Gamepad1 then
				gamepadConnected()
			end
		end)
		UserInputService.GamepadDisconnected:connect(function(gamepadEnum) 
			if gamepadEnum == Enum.UserInputType.Gamepad1 then
				gamepadDisconnected()
			end
		end)
	end
end

-- Listen to enable/disable signals from the StarterGui
--StarterGui.CoreGuiChangedSignal:connect(OnCoreGuiChanged)
local backpackType, healthType = Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health
OnCoreGuiChanged(backpackType, true)
OnCoreGuiChanged(healthType, true)

return BackpackScript

end;
};
G2L_MODULES[G2L["9"]] = {
Closure = function()
    local script = G2L["9"];--[[
		Filename: Settings2.lua
		Written by: jmargh
		Version 1.4
		Description: Implements the in game settings menu with the new control schemes
--]]

-- PATCHED MODULE STARTUP
-- Placement: StarterGui > RobloxGui > Modules > Settings2

local Players = game:GetService('Players')
local GuiService = game:GetService('GuiService')
local UserInputService = game:GetService('UserInputService')
local ContextActionService = game:GetService('ContextActionService')

while not Players.LocalPlayer do
	task.wait()
end

local LocalPlayer = Players.LocalPlayer
local RobloxGui = script.Parent.Parent

assert(RobloxGui and RobloxGui:IsA("LayerCollector"),
	"[2015 Settings2] Settings2 must be a ModuleScript inside RobloxGui > Modules")

local Settings = UserSettings()
local GameSettings = Settings.GameSettings

-- PATCH: no LoadLibrary / RbxGui dependency.
-- Settings2 only needed RbxGui.CreateSliderNew() in the active code below,
-- so provide a small local compatibility implementation instead.

local function CreateSliderNewCompat(steps, width, position)
	local container = Instance.new("Frame")
	container.Name = "Slider"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(0, width, 0, 32)
	container.Position = position

	local barLeft = Instance.new("Frame")
	barLeft.Name = "BarLeft"
	barLeft.BorderSizePixel = 0
	barLeft.BackgroundColor3 = Color3.new(0.35, 0.35, 0.35)
	barLeft.Size = UDim2.new(0, 4, 0, 8)
	barLeft.Position = UDim2.new(0, 0, 0.5, -4)
	barLeft.Parent = container

	local barRight = barLeft:Clone()
	barRight.Name = "BarRight"
	barRight.Position = UDim2.new(1, -4, 0.5, -4)
	barRight.Parent = container

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = Color3.new(0.35, 0.35, 0.35)
	bar.Size = UDim2.new(1, -8, 0, 8)
	bar.Position = UDim2.new(0, 4, 0.5, -4)
	bar.Parent = container

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.Parent = bar

	local fillLeft = Instance.new("Frame")
	fillLeft.Name = "FillLeft"
	fillLeft.BorderSizePixel = 0
	fillLeft.BackgroundColor3 = Color3.new(1, 1, 1)
	fillLeft.Size = UDim2.new(0, 4, 0, 8)
	fillLeft.Position = UDim2.new(0, 0, 0.5, -4)
	fillLeft.Parent = container

	local slider = Instance.new("TextButton")
	slider.Name = "Slider"
	slider.Text = ""
	slider.AutoButtonColor = false
	slider.BackgroundColor3 = Color3.new(1, 1, 1)
	slider.BorderSizePixel = 0
	slider.Size = UDim2.new(0, 12, 0, 20)
	slider.Position = UDim2.new(0, -6, 0.5, -10)
	slider.Parent = bar

	local value = Instance.new("IntValue")
	value.Name = "Value"
	value.Value = 1

	local dragging = false

	local function clampStep(v)
		return math.clamp(math.floor(v + 0.5), 1, steps)
	end

	local function updateVisual()
		local denom = math.max(steps - 1, 1)
		local alpha = (value.Value - 1) / denom
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		slider.Position = UDim2.new(alpha, -6, 0.5, -10)
	end

	local function setFromX(x)
		local absPos = bar.AbsolutePosition.X
		local absSize = bar.AbsoluteSize.X
		if absSize <= 0 then return end
		local alpha = math.clamp((x - absPos) / absSize, 0, 1)
		value.Value = clampStep(1 + alpha * (steps - 1))
	end

	slider.MouseButton1Down:Connect(function()
		dragging = true
	end)

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			) then
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	value.Changed:Connect(updateVisual)
	updateVisual()

	-- Return container directly. Bar, BarLeft, BarRight, FillLeft are all
	-- parented to container with those names, so container.Bar etc. work
	-- via Luau's built-in FindFirstChild behavior on instance property access.
	return container, value
end

-- The original script read Lighting.MacClient.Value, which was provided by
-- old Roblox client internals. Treat it as false when that value is absent.
local IsMacClient = false
do
	local macClient = game:GetService("Lighting"):FindFirstChild("MacClient")
	if macClient then
		local ok, value = pcall(function()
			return macClient.Value
		end)
		if ok then
			IsMacClient = value and true or false
		end
	end
end

local IsTouchClient = false
local isTouchSuccess, isTouch = pcall(function()
	return UserInputService.TouchEnabled
end)
IsTouchClient = isTouchSuccess and isTouch

-- These flags were already intentionally forced in your 2015M copy.
local isTopBar = true
local isLuaControls = false
local isGamepadSupport = false

-- Old Roblox supplied ControlFrame/TopLeftControl/BottomLeftControl.
-- Settings2 only uses these later to remove an old Exit button, so use
-- harmless detached fallback folders when those engine-created objects
-- are not present in the recreated RobloxGui.
local ControlFrame = RobloxGui:FindFirstChild('ControlFrame')
local TopLeftControl
local BottomLeftControl

if ControlFrame then
	TopLeftControl = ControlFrame:FindFirstChild('TopLeftControl')
	BottomLeftControl = ControlFrame:FindFirstChild('BottomLeftControl')
end

if not TopLeftControl then
	TopLeftControl = Instance.new("Folder")
	TopLeftControl.Name = "TopLeftControlCompat"
end

if not BottomLeftControl then
	BottomLeftControl = Instance.new("Folder")
	BottomLeftControl.Name = "BottomLeftControlCompat"
end

--[[ Control Variables ]]--
local CurrentYOffset = 24
local IsShiftLockEnabled = false
--if isLuaControls then
--	IsShiftLockEnabled = LocalPlayer.DevEnableMouseLock and GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
--else
--	IsShiftLockEnabled = GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
--end
local IsResumingGame = false
-- TODO: Change dev console script to parent this to somewhere other than an engine created gui
--local BindableFunc_ToggleDevConsole = ControlFrame:WaitForChild('ToggleDevConsole')
local MenuStack = {}
local IsHelpMenuOpen = false
local CurrentOpenedDropDownMenu = nil
local IsMenuClosing = false
local IsRecordingVideo = false
local currentCamera = workspace.CurrentCamera
local IsSmallScreen = false

--[[ Debug Variables - PLEASE RESET BEFORE COMMIT ]]--
local isTestingReportAbuse = false

--[[ Constants ]]--
local GRAPHICS_QUALITY_LEVELS = 10
local BASE_Z_INDEX = 4
local BG_TRANSPARENCY = 0.5
local TWEEN_TIME = 0.2
local SHOW_MENU_POS = UDim2.new(0.5, -262, 0.5, -215)
local CLOSE_MENU_POS = UDim2.new(0.5, -262, -0.5, -215)
local CAMERA_MODE_DEFAULT_STRING = IsTouchClient and "Default (Follow)" or "Default (Classic)"
local MOVEMENT_MODE_DEFAULT_STRING = IsTouchClient and "Default (Thumbstick)" or "Default (Keyboard)"
local MENU_BTN_LRG = UDim2.new(0, 340, 0, 50)
local MENU_BTN_SML = UDim2.new(0, 168, 0, 50)
local STOP_RECORD_IMG = 'rbxasset://textures/ui/RecordStop.png'
local HELP_IMG = {
	CLASSIC_MOVE = 'http://www.roblox.com/Asset?id=45915798',
	SHIFT_LOCK = 'http://www.roblox.com/asset?id=54071825',
	MOVEMENT = 'http://www.roblox.com/Asset?id=45915811',
	GEAR = 'http://www.roblox.com/Asset?id=45917596',
	ZOOM = 'http://www.roblox.com/Asset?id=45915825'
}

local PC_CHANGED_PROPS = {
	DevComputerMovementMode = true,
	DevComputerCameraMode = true,
	DevEnableMouseLock = true,
}
local TOUCH_CHANGED_PROPS = {
	DevTouchMovementMode = true,
	DevTouchCameraMode = true,
}

local GRAPHICS_QUALITY_TO_INT = {
	["Enum.SavedQualitySetting.Automatic"] = 0,
	["Enum.SavedQualitySetting.QualityLevel1"] = 1,
	["Enum.SavedQualitySetting.QualityLevel2"] = 2,
	["Enum.SavedQualitySetting.QualityLevel3"] = 3,
	["Enum.SavedQualitySetting.QualityLevel4"] = 4,
	["Enum.SavedQualitySetting.QualityLevel5"] = 5,
	["Enum.SavedQualitySetting.QualityLevel6"] = 6,
	["Enum.SavedQualitySetting.QualityLevel7"] = 7,
	["Enum.SavedQualitySetting.QualityLevel8"] = 8,
	["Enum.SavedQualitySetting.QualityLevel9"] = 9,
	["Enum.SavedQualitySetting.QualityLevel10"] = 10,
}

local ABUSE_TYPES_PLAYER = {
	"Swearing",
	"Inappropriate Username",
	"Bullying",
	"Scamming",
	"Dating",
	"Cheating/Exploiting",
	"Personal Question",
	"Offsite Links",
}

local ABUSE_TYPES_GAME = {
	"Inappropriate Content",
	"Bad Model or Script",
	"Offsite Link",
}


--[[ Gui Creation Helper Functions ]]--

local function Signal()
	local sig = {}

	local mSignaler = Instance.new('BindableEvent')

	local mArgData = nil
	local mArgDataCount = nil

	function sig:fire(...)
		mArgData = {...}
		mArgDataCount = select('#', ...)
		mSignaler:Fire()
	end

	function sig:connect(f)
		if not f then error("connect(nil)", 2) end
		return mSignaler.Event:Connect(function()
			f(table.unpack(mArgData, 1, mArgDataCount))
		end)
	end

	function sig:Connect(f)
		return self:connect(f)
	end

	function sig:wait()
		mSignaler.Event:Wait()
		assert(mArgData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
		return table.unpack(mArgData, 1, mArgDataCount)
	end

	return sig
end

local function createTextButton(size, position, text, fontSize, style)
	local textButton = Instance.new('TextButton')
	textButton.Size = size
	textButton.Position = position
	textButton.Font = Enum.Font.SourceSansBold
	textButton.FontSize = fontSize
	textButton.Style = style
	textButton.TextColor3 = Color3.new(1, 1, 1)
	textButton.Text = text
	textButton.ZIndex = BASE_Z_INDEX + 4

	return textButton
end

local function createTextLabel(position, text, name)
	local textLabel = Instance.new('TextLabel')
	textLabel.Name = name
	textLabel.Size = UDim2.new(0, 0, 0, 0)
	textLabel.Position = position
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.FontSize = Enum.FontSize.Size18
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextXAlignment = Enum.TextXAlignment.Right
	textLabel.ZIndex = BASE_Z_INDEX + 4
	textLabel.Text = text

	return textLabel
end

local function createMenuFrame(name, position)
	local frame = Instance.new('Frame')
	frame.Name = name
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Position = position
	frame.BackgroundTransparency = 1
	frame.ZIndex = BASE_Z_INDEX + 4

	pcall(function() GuiService:AddSelectionParent(name .. "Group", frame) end)

	return frame
end

local function createMenuTitleLabel(name, text, yOffset)
	local label = Instance.new('TextLabel')
	label.Name = name
	label.Size = UDim2.new(0, 0, 0, 0)
	label.Position = UDim2.new(0.5, 0, 0, yOffset)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSansBold
	label.FontSize = Enum.FontSize.Size36
	label.TextColor3 = Color3.new(1, 1, 1)
	label.ZIndex = BASE_Z_INDEX + 4
	label.Text = text

	return label
end

local function closeCurrentDropDownMenu()
	if CurrentOpenedDropDownMenu and CurrentOpenedDropDownMenu.IsOpen() then
		CurrentOpenedDropDownMenu.Close()
	end
	CurrentOpenedDropDownMenu = nil
end

--[[ Gui Creation ]]--
-- Main Container for everything in the settings menu

local MasterVolume = 0

local SettingsShowSignal = Signal()

local SettingsMenuFrame = Instance.new('Frame')
SettingsMenuFrame.Name = "SettingsMenu"
SettingsMenuFrame.Size = UDim2.new(1, 0, 1, 0)
SettingsMenuFrame.BackgroundTransparency = 1

local SettingsButton = Instance.new('ImageButton')
SettingsButton.Name = "SettingsButton"
SettingsButton.Size = UDim2.new(0, 36, 0, 28)
SettingsButton.Position = IsTouchClient and UDim2.new(0, 2, 0, 5) or UDim2.new(0, 15, 1, -42)
SettingsButton.BackgroundTransparency = 1
SettingsButton.Image = 'rbxasset://textures/ui/homeButton.png'
if not isTopBar then
	SettingsButton.Parent = SettingsMenuFrame
end

local SettingsShield = Instance.new('TextButton')
SettingsShield.Name = "SettingsShield"
-- Full-screen blocker/dimmer, matching the classic menu behavior.
SettingsShield.Size = UDim2.new(1, 0, 1, 36)
SettingsShield.Position = UDim2.new(0, 0, 0, -36)
SettingsShield.BackgroundTransparency = BG_TRANSPARENCY
SettingsShield.BackgroundColor3 = Color3.new(31/255, 31/255, 31/255)
SettingsShield.BorderSizePixel = 0
SettingsShield.Visible = false
SettingsShield.Active = true
SettingsShield.AutoButtonColor = false
SettingsShield.Text = ""
SettingsShield.Modal = true
SettingsShield.ZIndex = BASE_Z_INDEX + 2

local SettingClipFrame = Instance.new('Frame')
SettingClipFrame.Name = "SettingClipFrame"
-- Actual settings window remains non-fullscreen.
SettingClipFrame.Size = UDim2.new(0, 525, 0, 430)
SettingClipFrame.Position = CLOSE_MENU_POS
SettingClipFrame.Active = true
SettingClipFrame.BackgroundTransparency = BG_TRANSPARENCY
SettingClipFrame.BackgroundColor3 = Color3.new(31/255, 31/255, 31/255)
SettingClipFrame.BorderSizePixel = 0
SettingClipFrame.ZIndex = BASE_Z_INDEX + 3
SettingClipFrame.ClipsDescendants = true
SettingClipFrame.Parent = SettingsShield

--[[ Root Settings Menu ]]--
CurrentYOffset = 24
local RootMenuFrame = createMenuFrame("RootMenuFrame", UDim2.new(0, 0, 0, 0))
RootMenuFrame.Parent = SettingClipFrame

local RootMenuTitle = createMenuTitleLabel("RootMenuTitle", "Game Menu", CurrentYOffset)
RootMenuTitle.Parent = RootMenuFrame
CurrentYOffset = CurrentYOffset + 32

local ResumeGameButton = createTextButton(MENU_BTN_LRG, UDim2.new(0.5, -170, 0, CurrentYOffset),
	"Resume Game", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
ResumeGameButton.Name = "ResumeGameButton"
ResumeGameButton.Modal = true
ResumeGameButton.Parent = RootMenuFrame
CurrentYOffset = CurrentYOffset + 51

local ResetCharacterButton = createTextButton(MENU_BTN_LRG, UDim2.new(0.5, -170, 0, CurrentYOffset),
	"Reset Character", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
ResetCharacterButton.Name = "ResetCharacterButton"
ResetCharacterButton.Parent = RootMenuFrame
CurrentYOffset = CurrentYOffset + 51

local GameSettingsButton = createTextButton(MENU_BTN_LRG, UDim2.new(0.5, -170, 0, CurrentYOffset),
	"Game Settings", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
GameSettingsButton.Name = "GameSettingsButton"
GameSettingsButton.Parent = RootMenuFrame
CurrentYOffset = CurrentYOffset + 51

local HelpButton = nil
if not IsTouchClient then
	HelpButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -170, 0, CurrentYOffset),
		"Help", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
	HelpButton.Name = "HelpButton"
	if IsMacClient then HelpButton.Size = MENU_BTN_LRG end
	HelpButton.Parent = RootMenuFrame
end

local ScreenshotButton = nil
if not IsMacClient and not IsTouchClient then
	ScreenshotButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, 2, 0, CurrentYOffset),
		"Screenshot", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
	ScreenshotButton.Name = "ScreenshotButton"
	ScreenshotButton.Parent = RootMenuFrame
	--ScreenshotButton:SetVerb("Screenshot")
end
if not IsTouchClient then CurrentYOffset = CurrentYOffset + 51 end

local ReportAbuseButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -170, 0, CurrentYOffset),
	"Report Abuse", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
ReportAbuseButton.Name = "ReportAbuseButton"
ReportAbuseButton.Parent = RootMenuFrame
if IsMacClient or IsTouchClient then
	ReportAbuseButton.Size = MENU_BTN_LRG
end
ReportAbuseButton.Visible = true -- game:FindService('NetworkClient')
if isTestingReportAbuse then
	ReportAbuseButton.Visible = true
end
if not ReportAbuseButton.Visible then
	game.ChildAdded:connect(function(child)
		if child:IsA('NetworkClient') then
			ReportAbuseButton.Visible = true --game:FindService('NetworkClient')
		end
	end)
end

local RecordVideoButton = nil
local StopRecordingVideoButton = nil
if not IsMacClient and not IsTouchClient then
	RecordVideoButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, 2, 0, CurrentYOffset),
		"Record Video", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
	RecordVideoButton.Name = "RecordVideoButton"
	RecordVideoButton.Parent = RootMenuFrame
	--RecordVideoButton:SetVerb("RecordToggle")

	StopRecordingVideoButton = Instance.new('ImageButton')
	StopRecordingVideoButton.Name = "StopRecordingVideoButton"
	StopRecordingVideoButton.Size = UDim2.new(0, 59, 0, 27)
	StopRecordingVideoButton.BackgroundTransparency = 1
	StopRecordingVideoButton.Image = STOP_RECORD_IMG
	--StopRecordingVideoButton:SetVerb("RecordToggle")
	StopRecordingVideoButton.Visible = false
	StopRecordingVideoButton.Parent = SettingsMenuFrame
end
CurrentYOffset = CurrentYOffset + 51

local LeaveGameButton = createTextButton(MENU_BTN_LRG, UDim2.new(0.5, -170, 0, CurrentYOffset),
	"Leave Game", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
LeaveGameButton.Name = "LeaveGameButton"
LeaveGameButton.Parent = RootMenuFrame

--[[ Reset Character Confirmation Menu ]]--
CurrentYOffset = IsSmallScreen and 70 or 140
local ResetCharacterFrame = createMenuFrame("ResetCharacterFrame", UDim2.new(1, 0, 0, 0))
ResetCharacterFrame.Parent = SettingClipFrame

local ResetCharacterText = Instance.new('TextLabel')
ResetCharacterText.Name = "ResetCharacterText"
ResetCharacterText.Size = UDim2.new(1, 0, 0, 80)
ResetCharacterText.Position = UDim2.new(0, 0, 0, CurrentYOffset)
ResetCharacterText.BackgroundTransparency = 1
ResetCharacterText.Font = Enum.Font.SourceSansBold
ResetCharacterText.FontSize = Enum.FontSize.Size36
ResetCharacterText.TextColor3 = Color3.new(1, 1, 1)
ResetCharacterText.TextWrap = true
ResetCharacterText.ZIndex = BASE_Z_INDEX + 4
ResetCharacterText.Text = "Are you sure you want to reset\nyour character?"
ResetCharacterText.Parent = ResetCharacterFrame
CurrentYOffset = CurrentYOffset + 90

local ResetCharacterToolTipText = createTextLabel(UDim2.new(0.5, 0, 0, CurrentYOffset), "You will return to the spawn point", "ResetCharacterToolTipText")
ResetCharacterToolTipText.TextXAlignment = Enum.TextXAlignment.Center
ResetCharacterToolTipText.Parent = ResetCharacterFrame
CurrentYOffset = CurrentYOffset + 32

local ConfirmResetButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, 2, 0, CurrentYOffset),
	"Confirm", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
ConfirmResetButton.Name = "ConfirmResetButton"
ConfirmResetButton.Modal = true
ConfirmResetButton.Parent = ResetCharacterFrame

local CancelResetButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -170, 0, CurrentYOffset),
	"Cancel", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
CancelResetButton.Name = "CancelResetButton"
CancelResetButton.Parent = ResetCharacterFrame

--[[ Game Settings Menu ]]--
CurrentYOffset = 24
local GameSettingsMenuFrame = createMenuFrame("GameSettingsMenuFrame", UDim2.new(1, 0, 0, 0))
GameSettingsMenuFrame.Parent = SettingClipFrame

local GameSettingsMenuTitle = createMenuTitleLabel("GameSettingsMenuTitle", "Settings", CurrentYOffset)
GameSettingsMenuTitle.Parent = GameSettingsMenuFrame
CurrentYOffset = CurrentYOffset + 36
if IsTouchClient then CurrentYOffset = CurrentYOffset + 10 end

-- Shift Lock Controls
local shiftLockImageLabel = nil
if not isLuaControls then 	-- FFlag, remove when new controls are live
	shiftLockImageLabel = not isLuaControls and RobloxGui:FindFirstChild('MouseLockLabel', true) or nil
	if shiftLockImageLabel then
		--shiftLockImageLabel.Visible = GameSettings.ControlMode == Enum.ControlMode["Mouse Lock Switch"]
		shiftLockImageLabel.Visible = false
	end
end
local ShiftLockText, ShiftLockCheckBox, ShiftLockOverrideText = nil, nil, nil
if not IsTouchClient then
	ShiftLockText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Enable Shift Lock Switch:", "ShiftLockText")
	ShiftLockText.Parent = GameSettingsMenuFrame

	ShiftLockCheckBox = createTextButton(UDim2.new(0, 32, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 18),
		IsShiftLockEnabled and "X" or "", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
	ShiftLockCheckBox.Name = "ShiftLockCheckBox"
	ShiftLockCheckBox.ZIndex = BASE_Z_INDEX + 4
	if isLuaControls then
		ShiftLockCheckBox.Visible = LocalPlayer.DevEnableMouseLock
	end
	ShiftLockCheckBox.Parent = GameSettingsMenuFrame

	ShiftLockOverrideText = createTextLabel(UDim2.new(0.5, 6, 0, CurrentYOffset), "Set By Developer", "ShiftLockOverrideText")
	ShiftLockOverrideText.TextXAlignment = Enum.TextXAlignment.Left
	ShiftLockOverrideText.TextColor3 = Color3.new(180/255, 180/255, 180/255)
	ShiftLockOverrideText.Visible = false
	if isLuaControls then
		ShiftLockOverrideText.Visible = not LocalPlayer.DevEnableMouseLock
	end
	ShiftLockOverrideText.Parent = GameSettingsMenuFrame

	CurrentYOffset = CurrentYOffset + 36
end

-- Camera Mode Controls
local CameraModeText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Camera Mode:", "CameraModeText")
CameraModeText.Parent = GameSettingsMenuFrame

local CameraModeDropDown = nil
do
	local enumItems = nil
	if not isLuaControls then
		enumItems = Enum.CustomCameraMode:GetEnumItems()
	elseif IsTouchClient then
		enumItems = Enum.TouchCameraMovementMode:GetEnumItems()
	else
		enumItems = Enum.ComputerCameraMovementMode:GetEnumItems()
	end

	local enumNames = {}
	local enumNameToItem = {}
	for i = 1, #enumItems do
		local displayName = enumItems[i].Name
		if displayName == 'Default' then
			displayName = CAMERA_MODE_DEFAULT_STRING
		end
		enumNames[i] = displayName
		enumNameToItem[displayName] = enumItems[i].Value
	end
	--CameraModeDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
	--	function(text)
	--		if not isLuaControls then
	--			GameSettings.CameraMode = enumNameToItem[text]
	--		elseif IsTouchClient then
	--			GameSettings.TouchCameraMovementMode = enumNameToItem[text]
	--		else
	--			GameSettings.ComputerCameraMovementMode = enumNameToItem[text]
	--		end
	--	end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 16), BASE_Z_INDEX + 4)
	--CameraModeDropDown.CreateList(enumNames)
	local displayName = ""
	if not isLuaControls then
		--displayName = GameSettings.CameraMode.Name
	else
		--displayName = IsTouchClient and GameSettings.TouchCameraMovementMode.Name or GameSettings.ComputerCameraMovementMode.Name
	end
	if displayName == 'Default' then displayName = CAMERA_MODE_DEFAULT_STRING end
	--CameraModeDropDown.SetSelectionText(displayName)
	--CameraModeDropDown.Frame.Parent = GameSettingsMenuFrame
end

local CameraModeOverrideText = createTextLabel(UDim2.new(0.5, 6, 0, CurrentYOffset), "Set By Developer", "CameraModeOverrideText")
CameraModeOverrideText.TextColor3 = Color3.new(180/255, 180/255, 180/255)
CameraModeOverrideText.TextXAlignment = Enum.TextXAlignment.Left
CameraModeOverrideText.Parent = GameSettingsMenuFrame

do
	local isUserChoice = false
	if not isLuaControls then
		isUserChoice = true
	elseif IsTouchClient then
		isUserChoice = LocalPlayer.DevTouchCameraMode == Enum.DevTouchCameraMovementMode.UserChoice
	else
		isUserChoice = LocalPlayer.DevComputerCameraMode == Enum.DevComputerCameraMovementMode.UserChoice
	end
	if CameraModeDropDown then
		CameraModeDropDown.SetVisible(isUserChoice)
	end
	CameraModeOverrideText.Visible = not isUserChoice
end
CurrentYOffset = CurrentYOffset + 36

-- Movement Mode Controls
local MovementModeDropDown = nil
local MovementModeOverrideText = nil
if isLuaControls or IsTouchClient then
	local MovementModeText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Movement Mode:", "MovementModeText")
	MovementModeText.Parent = GameSettingsMenuFrame

	do
		local enumItems = IsTouchClient and Enum.TouchMovementMode:GetEnumItems() or Enum.ComputerMovementMode:GetEnumItems()
		local enumNames = {}
		local enumNameToItem = {}
		for i = 1, #enumItems do
			if not isLuaControls and enumItems[i].Name == "ClickToMove" then
				-- lets skip click to move until new controls are live
			else
				local displayName = enumItems[i].Name
				if displayName == "Default" then
					displayName = MOVEMENT_MODE_DEFAULT_STRING
				end
				enumNames[i] = displayName
				enumNameToItem[displayName] = enumItems[i]
			end
		end
		--
		--MovementModeDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
		--	function(text)
		--		if IsTouchClient then
		--			--GameSettings.TouchMovementMode = enumNameToItem[text]
		--		else
		--			--GameSettings.ComputerMovementMode = enumNameToItem[text]
		--		end
		--	end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 16), BASE_Z_INDEX + 4)
		--MovementModeDropDown.CreateList(enumNames)
		--local displayName = IsTouchClient and GameSettings.TouchMovementMode.Name or GameSettings.ComputerMovementMode.Name
		--if displayName == 'Default' then displayName = MOVEMENT_MODE_DEFAULT_STRING end
		--MovementModeDropDown.SetSelectionText(displayName)
		--MovementModeDropDown.Frame.Parent = GameSettingsMenuFrame
	end

	MovementModeOverrideText = createTextLabel(UDim2.new(0.5, 6, 0, CurrentYOffset), "Set By Developer", "MovementModeOverrideText")
	MovementModeOverrideText.TextColor3 = Color3.new(180/255, 180/255, 180/255)
	MovementModeOverrideText.TextXAlignment = Enum.TextXAlignment.Left
	MovementModeOverrideText.Parent = GameSettingsMenuFrame

	do
		local isUserChoice = false
		if not isLuaControls then
			isUserChoice = true
		elseif IsTouchClient then
			isUserChoice = LocalPlayer.DevTouchMovementMode == Enum.DevTouchMovementMode.UserChoice
		else
			isUserChoice = LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.UserChoice
		end
		if MovementModeDropDown then
			MovementModeDropDown.SetVisible(isUserChoice)
		end
		MovementModeOverrideText.Visible = not isUserChoice
	end
	CurrentYOffset = CurrentYOffset + 36
end

-- Video Capture Settings
local VideoCaptureDropDown = nil
if not IsMacClient and not IsTouchClient then
	local videoCaptureText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "After Capturing Video:", "VideoCaptureText")
	videoCaptureText.Parent = GameSettingsMenuFrame

	local enumNames = {}
	local enumNamesToItem = {}
	enumNames[1] = "Save To Disk"
	enumNamesToItem[enumNames[1]] = Enum.TriStateBoolean.True
	enumNames[2] = "Upload to YouTube"
	enumNamesToItem[enumNames[2]] = Enum.TriStateBoolean.False

	--VideoCaptureDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
	--	function(text)
	--		--GameSettings.VideoUploadPromptBehavior = enumNamesToItem[text]
	--	end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 16), BASE_Z_INDEX + 4)
	--VideoCaptureDropDown.CreateList(enumNames)
	--VideoCaptureDropDown.Frame.Parent = GameSettingsMenuFrame

	--local displayName = ""
	----if GameSettings.VideoUploadPromptBehavior == Enum.UploadSetting["Never"] then
	--	displayName = enumNames[1]
	--elseif GameSettings.VideoUploadPromptBehavior == Enum.UploadSetting["Ask me first"] then
	--	displayName = enumNames[2]
	--else
	--	GameSettings.VideoUploadPromptBehavior = Enum.UploadSetting["Ask me first"]
	--	displayName = enumNames[2]
	--end
	--VideoCaptureDropDown.SetSelectionText(displayName)

	CurrentYOffset = CurrentYOffset + 36
end

--[[ Fullscreen Mode ]]--
if false then
	local fullScreenText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Fullscreen:", "FullScreenText")
	fullScreenText.Parent = GameSettingsMenuFrame

	local fullScreenTextCheckBox = createTextButton(UDim2.new(0, 32, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 18),
		GameSettings:InFullScreen() and "X" or "", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
	fullScreenTextCheckBox.Name = "FullScreenTextCheckBox"
	fullScreenTextCheckBox.ZIndex = BASE_Z_INDEX + 4
	fullScreenTextCheckBox.Parent = GameSettingsMenuFrame
	fullScreenTextCheckBox.Modal = true
	--fullScreenTextCheckBox:SetVerb("ToggleFullScreen")

	--GameSettings.FullscreenChanged:connect(function(isFullscreen)
	--	fullScreenTextCheckBox.Text = isFullscreen and "X" or ""
	--end)
	--CurrentYOffset = CurrentYOffset + 36
end

--[[ Graphics Slider ]]--
if not IsTouchClient then
	local qualityText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Graphics Quality:", "QualityText")
	qualityText.Parent = GameSettingsMenuFrame

	local qualityAutoCheckBox = createTextButton(UDim2.new(0, 32, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 18), "X", Enum.FontSize.Size18, Enum.ButtonStyle.RobloxRoundButton)
	qualityAutoCheckBox.Name = "QualityAutoCheckBox"
	qualityAutoCheckBox.ZIndex = BASE_Z_INDEX + 4
	qualityAutoCheckBox.Parent = GameSettingsMenuFrame

	local qualityAutoText = createTextLabel(UDim2.new(0.5, 44, 0, CurrentYOffset), "Auto", "QualityAutoText")
	qualityAutoText.TextXAlignment = Enum.TextXAlignment.Left
	--qualityAutoText.TextColor3 = GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic and Color3.new(1, 1, 1) or Color3.new(128/255,128/255,128/255)
	qualityAutoText.Parent = GameSettingsMenuFrame

	local graphicsSlider, graphicsLevel = CreateSliderNewCompat(GRAPHICS_QUALITY_LEVELS, 300, UDim2.new(0.5, -150, 0, CurrentYOffset + 36))
	graphicsSlider.Bar.ZIndex = BASE_Z_INDEX + 4
	graphicsSlider.Bar.Slider.ZIndex = BASE_Z_INDEX + 6
	graphicsSlider.BarLeft.ZIndex = BASE_Z_INDEX + 4
	graphicsSlider.BarRight.ZIndex = BASE_Z_INDEX + 4
	graphicsSlider.Bar.Fill.ZIndex = BASE_Z_INDEX + 5
	graphicsSlider.FillLeft.ZIndex = BASE_Z_INDEX + 5
	graphicsSlider.Parent = GameSettingsMenuFrame
	-- TODO: We don't save the previous non-auto setting. So what should this default to?
	graphicsLevel.Value = math.floor((21 - 1)/2)

	local graphicsMinText = createTextLabel(UDim2.new(0.5, -164, 0, CurrentYOffset + 37), "Min", "GraphicsMinText")
	graphicsMinText.Parent = GameSettingsMenuFrame

	local graphicsMaxText = createTextLabel(UDim2.new(0.5, 158, 0, CurrentYOffset + 37), "Max", "GraphicsMaxText")
	graphicsMaxText.TextXAlignment = Enum.TextXAlignment.Left
	graphicsMaxText.Parent = GameSettingsMenuFrame

	local isAutoGraphics = true
	--isAutoGraphics = GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic

	local function setGraphicsQualityLevel(newLevel)
		local percentage = newLevel/GRAPHICS_QUALITY_LEVELS
		local newQualityLevel = math.floor((21 - 1) * percentage)
		if newQualityLevel == 20 then
			newQualityLevel = 21
		elseif newLevel == 1 then
			newQualityLevel = 1
		elseif newQualityLevel > 21 then
			newQualityLevel = 21 - 1
		end

		--GameSettings.SavedQualityLevel = newLevel
		--settings().Rendering.QualityLevel = newQualityLevel
	end

	local function setGraphicsGuiZIndex()
		qualityAutoCheckBox.Text = isAutoGraphics and "X" or ""
		if isAutoGraphics then
			graphicsSlider.Bar.ZIndex = 1
			graphicsSlider.BarLeft.ZIndex = 1
			graphicsSlider.BarRight.ZIndex = 1
			graphicsSlider.Bar.Fill.ZIndex = 1
			graphicsSlider.Bar.Slider.ZIndex = 2
			graphicsSlider.Bar.Slider.Active = false
			graphicsSlider.FillLeft.ZIndex = 1
			graphicsMinText.ZIndex = 1
			graphicsMaxText.ZIndex = 1
		else
			graphicsSlider.Bar.ZIndex = BASE_Z_INDEX + 4
			graphicsSlider.BarLeft.ZIndex = BASE_Z_INDEX + 4
			graphicsSlider.BarRight.ZIndex = BASE_Z_INDEX + 4
			graphicsSlider.Bar.Fill.ZIndex = BASE_Z_INDEX + 5
			graphicsSlider.Bar.Slider.ZIndex = BASE_Z_INDEX + 6
			graphicsSlider.Bar.Slider.Active = true
			graphicsSlider.FillLeft.ZIndex = BASE_Z_INDEX + 5
			graphicsMinText.ZIndex = BASE_Z_INDEX + 4
			graphicsMaxText.ZIndex = BASE_Z_INDEX + 4
		end
	end

	local function setGraphicsToAtuo()
		--GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.Automatic
		--settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
	end

	local function setGraphicsToManual(level)
		graphicsLevel.Value = level
		setGraphicsQualityLevel(level)
	end

	local function onGraphicsCheckBoxPressed()
		isAutoGraphics = not isAutoGraphics
		setGraphicsGuiZIndex()
		if isAutoGraphics then
			setGraphicsToAtuo()
		else
			setGraphicsToManual(graphicsLevel.Value)
		end
	end

	graphicsLevel.Changed:connect(function(newValue)
		if isAutoGraphics then return end
		--
		setGraphicsQualityLevel(graphicsLevel.Value)
	end)

	qualityAutoCheckBox.MouseButton1Click:connect(onGraphicsCheckBoxPressed)

	-- graphics can be changed with F10 and Shift+F10
	pcall(function()
		game.GraphicsQualityChangeRequest:connect(function(isIncrease)
			if isAutoGraphics then return end
			--
			if isIncrease then
				if graphicsLevel.Value + 1 > GRAPHICS_QUALITY_LEVELS then return end
				graphicsLevel.Value = graphicsLevel.Value + 1
				setGraphicsQualityLevel(graphicsLevel.Value)
			else
				if graphicsLevel.Value - 1 <= 0 then return end
				graphicsLevel.Value = graphicsLevel.Value - 1
				setGraphicsQualityLevel(graphicsLevel.Value)
			end
		end)
	end)

	-- initial load setup
	setGraphicsGuiZIndex()
	--if GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic then
	--settings().Rendering.EnableFRM = true
	setGraphicsToAtuo()
	--else
	--settings().Rendering.EnableFRM = true
	--local level = tostring(GameSettings.SavedQualityLevel)
	--if GRAPHICS_QUALITY_TO_INT[level] then
	--	setGraphicsToManual(GRAPHICS_QUALITY_TO_INT[level])
	--end
	--end
	CurrentYOffset = CurrentYOffset + 72
end

--[[ Volume Slider ]]--
local maxVolumeLevel = 256

local volumeText = createTextLabel(UDim2.new(0.5, 0, 0, CurrentYOffset), "Volume", "VolumeText")
volumeText.TextXAlignment = Enum.TextXAlignment.Center
volumeText.Parent = GameSettingsMenuFrame

local volumeSlider, volumeLevel = CreateSliderNewCompat(maxVolumeLevel, 300, UDim2.new(0.5, -150, 0, CurrentYOffset + 20))
volumeSlider.Bar.ZIndex = BASE_Z_INDEX + 2
volumeSlider.Bar.Slider.ZIndex = BASE_Z_INDEX + 4
volumeSlider.BarLeft.ZIndex = BASE_Z_INDEX + 2
volumeSlider.BarRight.ZIndex = BASE_Z_INDEX + 2
volumeSlider.Bar.Fill.ZIndex = BASE_Z_INDEX + 3
volumeSlider.FillLeft.ZIndex = BASE_Z_INDEX + 3
volumeSlider.Parent = GameSettingsMenuFrame
volumeLevel.Value = math.min(math.max(MasterVolume * maxVolumeLevel, 1), maxVolumeLevel)

local volumeMinText = createTextLabel(UDim2.new(0.5, -164, 0, CurrentYOffset + 21), "Min", "VolumeMinText")
volumeMinText.Parent = GameSettingsMenuFrame

local volumeMaxText = createTextLabel(UDim2.new(0.5, 158, 0, CurrentYOffset + 21), "Max", "VolumeMaxText")
volumeMaxText.TextXAlignment = Enum.TextXAlignment.Left
volumeMaxText.Parent = GameSettingsMenuFrame

volumeLevel.Changed:connect(function(newValue)
	local volume = volumeLevel.Value - 1
	MasterVolume = volume/maxVolumeLevel
end)

CurrentYOffset = CurrentYOffset + 42
if not isLuaControls and not IsTouchClient then
	CurrentYOffset = CurrentYOffset + 36
end

--[[ OK/Return button ]]--
if IsTouchClient then
	if IsSmallScreen then
		CurrentYOffset = CurrentYOffset + 64
	else
		CurrentYOffset = CurrentYOffset + 134
	end
end
local GameSettingsBackButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -84, 0, CurrentYOffset),
	"Back", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
GameSettingsBackButton.Name = "GameSettingsBackButton"
GameSettingsBackButton.Parent = GameSettingsMenuFrame
GameSettingsBackButton.Modal = true

--[[ Game Settings Menu Drop Down Connections ]]--
if CameraModeDropDown then
	CameraModeDropDown.CurrentSelectionButton.MouseButton1Click:connect(function()
		if CurrentOpenedDropDownMenu ~= CameraModeDropDown then
			closeCurrentDropDownMenu()
			CurrentOpenedDropDownMenu = CameraModeDropDown
		end
	end)
end
if MovementModeDropDown then
	MovementModeDropDown.CurrentSelectionButton.MouseButton1Click:connect(function()
		if CurrentOpenedDropDownMenu ~= MovementModeDropDown then
			closeCurrentDropDownMenu()
			CurrentOpenedDropDownMenu = MovementModeDropDown
		end
	end)
end
if VideoCaptureDropDown then
	VideoCaptureDropDown.CurrentSelectionButton.MouseButton1Click:connect(function()
		if CurrentOpenedDropDownMenu ~= VideoCaptureDropDown then
			closeCurrentDropDownMenu()
			CurrentOpenedDropDownMenu = VideoCaptureDropDown
		end
	end)
end

--[[ Help Menu ]]--
CurrentYOffset = 24
local HelpMenuFrame = createMenuFrame("HelpMenuFrame", UDim2.new(1, 0, 0, 0))
HelpMenuFrame.Parent = SettingClipFrame

local HelpMenuTitle = createMenuTitleLabel("HelpMenuTitle", "Keyboard & Mouse Controls", CurrentYOffset)
HelpMenuTitle.Parent = HelpMenuFrame
CurrentYOffset = CurrentYOffset + 32

local HelpMenuButtonFrame = Instance.new('Frame')
HelpMenuButtonFrame.Name = "HelpMenuButtonFrame"
HelpMenuButtonFrame.Size = UDim2.new(0.9, 0, 0, 45)
HelpMenuButtonFrame.Position = UDim2.new(0.05, 0, 0, CurrentYOffset)
HelpMenuButtonFrame.BackgroundTransparency = 1
HelpMenuButtonFrame.ZIndex = BASE_Z_INDEX + 4
HelpMenuButtonFrame.Parent = HelpMenuFrame
CurrentYOffset = CurrentYOffset + 60

local CurrentHelpDialogButton = nil
local HelpLookButton = createTextButton(UDim2.new(0.25, 0, 1, 0), UDim2.new(0, 0, 0, 0),
	"Look", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
HelpLookButton.Name = "HelpLookButton"
HelpLookButton.Parent = HelpMenuButtonFrame

local HelpMoveButton = createTextButton(UDim2.new(0.25, 0, 1, 0), UDim2.new(0.25, 0, 0, 0),
	"Movement", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
HelpMoveButton.Name = "HelpMoveButton"
HelpMoveButton.Parent = HelpMenuButtonFrame

local HelpGearButton = createTextButton(UDim2.new(0.25, 0, 1, 0), UDim2.new(0.5, 0, 0, 0),
	"Gear", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
HelpGearButton.Name = "HelpGearButton"
HelpGearButton.Parent = HelpMenuButtonFrame

local HelpZoomButton = createTextButton(UDim2.new(0.25, 0, 1, 0), UDim2.new(0.75, 0, 0, 0),
	"Zoom", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
HelpZoomButton.Name = "HelpZoomButton"
HelpZoomButton.Parent = HelpMenuButtonFrame

CurrentHelpDialogButton = HelpLookButton

local HelpMenuImage = Instance.new('ImageLabel')
HelpMenuImage.Name = "HelpMenuImage"
HelpMenuImage.Size = UDim2.new(0.9, 0, 0.5, 0)
HelpMenuImage.Position = UDim2.new(0.05, 0, 0, CurrentYOffset)
HelpMenuImage.BackgroundTransparency = 1
HelpMenuImage.Image = HELP_IMG.CLASSIC_MOVE
HelpMenuImage.ZIndex = BASE_Z_INDEX + 4
HelpMenuImage.Parent = HelpMenuFrame
CurrentYOffset = CurrentYOffset + 234

local HelpConsoleButton = createTextButton(UDim2.new(0, 70, 0, 30), UDim2.new(1, -75, 0, CurrentYOffset + 20),
	"Log:", Enum.FontSize.Size18, Enum.ButtonStyle.RobloxRoundButton)
HelpConsoleButton.Name = "HelpConsoleButton"
HelpConsoleButton.TextXAlignment = Enum.TextXAlignment.Left
HelpConsoleButton.Parent = HelpMenuFrame

local HelpConsoleText = Instance.new('TextLabel')
HelpConsoleText.Name = "HelpConsoleText"
HelpConsoleText.Size = UDim2.new(0, 16, 0, 30)
HelpConsoleText.Position = UDim2.new(1, -14, 0, -12)
HelpConsoleText.BackgroundTransparency = 1
HelpConsoleText.Font = Enum.Font.SourceSansBold
HelpConsoleText.FontSize = Enum.FontSize.Size18
HelpConsoleText.TextColor3 = Color3.new(0, 1, 0)
HelpConsoleText.ZIndex = BASE_Z_INDEX + 4
HelpConsoleText.Text = "F9"
HelpConsoleText.Parent = HelpConsoleButton

local HelpMenuBackButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -84, 0, CurrentYOffset),
	"Back", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
HelpMenuBackButton.Name = "HelpMenuBackButton"
HelpMenuBackButton.Modal = true
HelpMenuBackButton.Parent = HelpMenuFrame

--[[ Report Abuse Menu ]]--
CurrentYOffset = 24
local IsReportingPlayer = false
local CurrentAbusingPlayer = nil
local AbuseReason = nil

local ReportAbuseFrame = createMenuFrame("ReportAbuseFrame", UDim2.new(1, 0, 0, 0))
ReportAbuseFrame.Parent = SettingClipFrame

local ReportAbuseTitle = createMenuTitleLabel("ReportAbuseTitle", "Report Abuse", CurrentYOffset)
ReportAbuseTitle.Parent = ReportAbuseFrame
CurrentYOffset = IsSmallScreen and (CurrentYOffset + 20) or (CurrentYOffset + 32)

local ReportAbuseDescription = Instance.new('TextLabel')
ReportAbuseDescription.Name = "ReportAbuseDescription"
ReportAbuseDescription.Size = UDim2.new(1, -40, 0, 40)
ReportAbuseDescription.Position = UDim2.new(0, 35, 0, CurrentYOffset)
ReportAbuseDescription.BackgroundTransparency = 1
ReportAbuseDescription.Font = Enum.Font.SourceSans
ReportAbuseDescription.FontSize = Enum.FontSize.Size18
ReportAbuseDescription.TextColor3 = Color3.new(1, 1, 1)
ReportAbuseDescription.TextWrap = true
ReportAbuseDescription.TextXAlignment = Enum.TextXAlignment.Left
ReportAbuseDescription.TextYAlignment = Enum.TextYAlignment.Top
ReportAbuseDescription.ZIndex = BASE_Z_INDEX + 4
ReportAbuseDescription.Text = "This will send a complete report to a moderator. The moderator will review the chat log and take appropriate action."
ReportAbuseDescription.Parent = ReportAbuseFrame
CurrentYOffset = IsSmallScreen and (CurrentYOffset + 48) or (CurrentYOffset + 70)

local ReportGameOrPlayerText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Game or Player:", "ReportGameOrPlayerText")
ReportGameOrPlayerText.Parent = ReportAbuseFrame
CurrentYOffset = CurrentYOffset + 40

local ReportPlayerText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Which Player:", "ReportPlayerText")
ReportPlayerText.Parent = ReportAbuseFrame
CurrentYOffset = CurrentYOffset + 40

local ReportTypeOfAbuseText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Type of Abuse:", "ReportTypeOfAbuseText")
ReportTypeOfAbuseText.Parent = ReportAbuseFrame
CurrentYOffset = IsSmallScreen and (CurrentYOffset + 10) or (CurrentYOffset + 40)

local ReportDescriptionText = ReportAbuseDescription:Clone()
ReportDescriptionText.Name = "ReportDescriptionText"
ReportDescriptionText.Text = "Short Description: (optional)"
ReportDescriptionText.Position = UDim2.new(0, 35, 0, CurrentYOffset)
ReportDescriptionText.Parent = ReportAbuseFrame
CurrentYOffset = CurrentYOffset + 28

local ReportDescriptionTextBox = Instance.new('TextBox')
ReportDescriptionTextBox.Name = "ReportDescriptionTextBox"
ReportDescriptionTextBox.Size = UDim2.new(1, -70, 1, IsSmallScreen and (-CurrentYOffset - 60) or (-CurrentYOffset - 100))
ReportDescriptionTextBox.Position = UDim2.new(0, 35, 0, CurrentYOffset)
ReportDescriptionTextBox.BackgroundTransparency = 1
ReportDescriptionTextBox.Font = Enum.Font.SourceSans
ReportDescriptionTextBox.FontSize = Enum.FontSize.Size18
ReportDescriptionTextBox.ClearTextOnFocus = false
ReportDescriptionTextBox.TextColor3 = Color3.new(0, 0, 0)
ReportDescriptionTextBox.TextXAlignment = Enum.TextXAlignment.Left
ReportDescriptionTextBox.TextYAlignment = Enum.TextYAlignment.Top
ReportDescriptionTextBox.Text = ""
ReportDescriptionTextBox.TextWrap = true
ReportDescriptionTextBox.ZIndex = BASE_Z_INDEX + 4
ReportDescriptionTextBox.Visible = false
ReportDescriptionTextBox.Parent = ReportAbuseFrame

local ReportDescriptionTextBoxBg = Instance.new('TextButton')
ReportDescriptionTextBoxBg.Name = "ReportDescriptionTextBoxBg"
ReportDescriptionTextBoxBg.Size = UDim2.new(1, 16, 1, 16)
ReportDescriptionTextBoxBg.Position = UDim2.new(0, -8, 0, -8)
ReportDescriptionTextBoxBg.Text = ""
ReportDescriptionTextBoxBg.Active = false
ReportDescriptionTextBoxBg.AutoButtonColor = false
ReportDescriptionTextBoxBg.Style = Enum.ButtonStyle.RobloxRoundDropdownButton
ReportDescriptionTextBoxBg.ZIndex = BASE_Z_INDEX + 4
ReportDescriptionTextBoxBg.Parent = ReportDescriptionTextBox
CurrentYOffset = CurrentYOffset + ReportDescriptionTextBox.AbsoluteSize.y + 20

local buttonPosition = IsSmallScreen and UDim2.new(0.5, 2, 1, -MENU_BTN_SML.Y.Offset - 4) or
	UDim2.new(0.5, 2, 0, CurrentYOffset)

local ReportSubmitButton = createTextButton(MENU_BTN_SML, buttonPosition,
	"Submit", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
ReportSubmitButton.Name = "ReportSubmitButton"
ReportSubmitButton.ZIndex = BASE_Z_INDEX
ReportSubmitButton.Active = false
ReportSubmitButton.Parent = ReportAbuseFrame

buttonPosition = IsSmallScreen and UDim2.new(0.5, -170, 1, -MENU_BTN_SML.Y.Offset - 4) or
	UDim2.new(0.5, -170, 0, CurrentYOffset)

local ReportCancelButton = createTextButton(MENU_BTN_SML, buttonPosition,
	"Cancel", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
ReportCancelButton.Name = "ReportSubmitButton"
ReportCancelButton.Parent = ReportAbuseFrame
ReportCancelButton.Modal = true

local ReportPlayerDropDown = nil
local ReportTypeOfAbuseDropDown = nil
local ReportPlayerOrGameDropDown = nil

local function cleanupReportAbuseMenu()
	ReportDescriptionTextBox.Visible = false
	ReportDescriptionTextBox.Text = ""
	ReportSubmitButton.ZIndex = BASE_Z_INDEX
	ReportSubmitButton.Active = false
	if ReportPlayerDropDown then
		ReportPlayerDropDown.Frame:Destroy()
		ReportPlayerDropDown = nil
	end
	if ReportTypeOfAbuseDropDown then
		ReportTypeOfAbuseDropDown.Frame:Destroy()
		ReportTypeOfAbuseDropDown = nil
	end
	if ReportPlayerOrGameDropDown then
		ReportPlayerOrGameDropDown.Frame:Destroy()
		ReportPlayerOrGameDropDown = nil
	end
end

local function createReportAbuseMenu()
	local playerNames = {}
	local nameToRbxPlayer = {}
	local players = Players:GetChildren()
	local index = 1
	for i = 1, #players do
		local player = players[i]
		if player:IsA('Player') and player ~= LocalPlayer then
			playerNames[index] = player.Name
			nameToRbxPlayer[player.Name] = player
			index = index + 1
		end
	end

	--ReportTypeOfAbuseDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
	--	function(text)
	--		AbuseReason = text
	--		ReportSubmitButton.ZIndex = BASE_Z_INDEX + 4
	--		ReportSubmitButton.Active = true
	--	end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, ReportTypeOfAbuseText.Position.Y.Offset - 16), BASE_Z_INDEX)
	--ReportTypeOfAbuseDropDown.SetActive(false)
	--ReportTypeOfAbuseDropDown.Frame.Parent = ReportAbuseFrame
	-- list will be set depending on which type of report it is (game or player)

	--ReportPlayerDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
	--	function(text)
	--		CurrentAbusingPlayer = nameToRbxPlayer[text] or LocalPlayer
	--		ReportTypeOfAbuseText.ZIndex = BASE_Z_INDEX + 4
	--		ReportTypeOfAbuseDropDown.CreateList(ABUSE_TYPES_PLAYER)
	--		ReportTypeOfAbuseDropDown.UpdateZIndex(BASE_Z_INDEX + 4)
	--		ReportTypeOfAbuseDropDown.SetActive(true)
	--	end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, ReportPlayerText.Position.Y.Offset - 16), BASE_Z_INDEX)
	--ReportPlayerDropDown.SetActive(false)
	--ReportPlayerDropDown.CreateList(playerNames)
	--ReportPlayerDropDown.Frame.Parent = ReportAbuseFrame

	--ReportPlayerOrGameDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
	--	function(text)
	--		if text == "Player" then
	--			IsReportingPlayer = true
	--			ReportPlayerText.ZIndex = BASE_Z_INDEX + 4
	--			ReportPlayerDropDown.UpdateZIndex(BASE_Z_INDEX + 4)
	--			ReportPlayerDropDown.SetActive(true)
	--			--
	--			ReportTypeOfAbuseText.ZIndex = BASE_Z_INDEX
	--			ReportTypeOfAbuseDropDown.CreateList(ABUSE_TYPES_PLAYER)
	--			ReportTypeOfAbuseDropDown.UpdateZIndex(BASE_Z_INDEX)
	--			ReportTypeOfAbuseDropDown.SetActive(false)
	--		elseif text == "Game" then
	--			IsReportingPlayer = false
	--			if CurrentAbusingPlayer then
	--				CurrentAbusingPlayer = nil
	--			end
	--			ReportPlayerDropDown.SetSelectionText("Choose One")
	--			ReportPlayerText.ZIndex = BASE_Z_INDEX
	--			ReportPlayerDropDown.SetActive(false)
	--			ReportPlayerDropDown.UpdateZIndex(BASE_Z_INDEX)
	--			--
	--			ReportTypeOfAbuseText.ZIndex = BASE_Z_INDEX + 4
	--			ReportTypeOfAbuseDropDown.CreateList(ABUSE_TYPES_GAME)
	--			ReportTypeOfAbuseDropDown.UpdateZIndex(BASE_Z_INDEX + 4)
	--			ReportTypeOfAbuseDropDown.SetActive(true)
	--		else
	--			IsReportingPlayer = false
	--			ReportPlayerText.ZIndex = BASE_Z_INDEX
	--			ReportPlayerDropDown.SetActive(false)
	--			ReportPlayerDropDown.UpdateZIndex(BASE_Z_INDEX)
	--		end
	--		ReportSubmitButton.ZIndex = BASE_Z_INDEX
	--		ReportSubmitButton.Active = false
	--	end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, ReportGameOrPlayerText.Position.Y.Offset - 16), BASE_Z_INDEX + 4)
	--ReportPlayerOrGameDropDown.Frame.Parent = ReportAbuseFrame
	--ReportPlayerOrGameDropDown.CreateList({ "Game", "Player", })

	-- drop down menu connections
	--ReportPlayerDropDown.CurrentSelectionButton.MouseButton1Click:connect(function()
	--	if CurrentOpenedDropDownMenu ~= ReportPlayerDropDown then
	--		closeCurrentDropDownMenu()
	--		CurrentOpenedDropDownMenu = ReportPlayerDropDown
	--	end
	--end)
	--ReportTypeOfAbuseDropDown.CurrentSelectionButton.MouseButton1Click:connect(function()
	--	if CurrentOpenedDropDownMenu ~= ReportTypeOfAbuseDropDown then
	--		closeCurrentDropDownMenu()
	--		CurrentOpenedDropDownMenu = ReportTypeOfAbuseDropDown
	--	end
	--end)
	--ReportPlayerOrGameDropDown.CurrentSelectionButton.MouseButton1Click:connect(function()
	--	if CurrentOpenedDropDownMenu ~= ReportPlayerOrGameDropDown then
	--		closeCurrentDropDownMenu()
	--		CurrentOpenedDropDownMenu = ReportPlayerOrGameDropDown
	--	end
	--end)
	ReportDescriptionTextBox.Visible = true
end

CurrentYOffset = IsSmallScreen and 70 or 140
local ReportAbuseConfirmationFrame = createMenuFrame("ReportAbuseConfirmationFrame", UDim2.new(1, 0, 0, 0))
ReportAbuseConfirmationFrame.Parent = SettingClipFrame

local ReportAbuseConfirmationText = Instance.new('TextLabel')
ReportAbuseConfirmationText.Name = "ReportAbuseConfirmationText"
ReportAbuseConfirmationText.Size = UDim2.new(1, -20, 0, 80)
ReportAbuseConfirmationText.Position = UDim2.new(0, 10, 0, CurrentYOffset)
ReportAbuseConfirmationText.BackgroundTransparency = 1
ReportAbuseConfirmationText.Font = Enum.Font.SourceSans
ReportAbuseConfirmationText.FontSize = Enum.FontSize.Size24
ReportAbuseConfirmationText.TextColor3 = Color3.new(1, 1, 1)
ReportAbuseConfirmationText.TextWrap = true
ReportAbuseConfirmationText.TextScaled = true
ReportAbuseConfirmationText.ZIndex = BASE_Z_INDEX + 4
ReportAbuseConfirmationText.Text = ""
ReportAbuseConfirmationText.Parent = ReportAbuseConfirmationFrame
CurrentYOffset = CurrentYOffset + 122

local ReportAbuseConfirmationButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -MENU_BTN_SML.X.Offset/2, 0, CurrentYOffset),
	"OK", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
ReportAbuseConfirmationButton.Name = "ReportAbuseConfirmationButton"
ReportAbuseConfirmationButton.Parent = ReportAbuseConfirmationFrame

--[[ Leave Game Confirmation Menu ]]--
CurrentYOffset = IsSmallScreen and 70 or 140
local LeaveGameMenuFrame = createMenuFrame("LeaveGameMenuFrame", UDim2.new(1, 0, 0, 0))
LeaveGameMenuFrame.Parent = SettingClipFrame

local LeaveGameText = Instance.new('TextLabel')
LeaveGameText.Name = "LeaveGameText"
LeaveGameText.Size = UDim2.new(1, 0, 0, 80)
LeaveGameText.Position = UDim2.new(0, 0, 0, CurrentYOffset)
LeaveGameText.BackgroundTransparency = 1
LeaveGameText.Font = Enum.Font.SourceSansBold
LeaveGameText.FontSize = Enum.FontSize.Size36
LeaveGameText.TextColor3 = Color3.new(1, 1, 1)
LeaveGameText.TextWrap = true
LeaveGameText.ZIndex = BASE_Z_INDEX + 4
LeaveGameText.Text = "Are you sure you want to leave this game?"
LeaveGameText.Parent = LeaveGameMenuFrame
CurrentYOffset = CurrentYOffset + 122

local LeaveConfirmButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, 2, 0, CurrentYOffset),
	"Confirm", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
LeaveConfirmButton.Name = "LeaveConfirmButton"
LeaveConfirmButton.Parent = LeaveGameMenuFrame
LeaveConfirmButton.Modal = true
--LeaveConfirmButton:SetVerb("Exit")
LeaveConfirmButton.MouseButton1Click:Connect(function()
	local exitEvent = game.ReplicatedStorage:FindFirstChild("Exit")
	if exitEvent and exitEvent:IsA("RemoteEvent") then
		exitEvent:FireServer()
	else
		-- Fallback: leave the game directly if no Exit RemoteEvent exists
		local player = game:GetService("Players").LocalPlayer
		if player then
			player:Kick("You have left the game.")
		end
	end
end)

local LeaveCancelButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -170, 0, CurrentYOffset),
	"Cancel", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
LeaveCancelButton.Name = "LeaveCancelButton"
LeaveCancelButton.Parent = LeaveGameMenuFrame

--[[ Menu Functions ]]--
local function setGamepadButton(currentMenu)
	if not isGamepadSupport then return end
	if not UserInputService.GamepadEnabled then return end 

	if currentMenu == LeaveGameMenuFrame then 
		--pcall(function() GuiService.SelectedCoreObject = LeaveGameMenuFrame.LeaveConfirmButton end)
	elseif currentMenu == RootMenuFrame then 
		--pcall(function() GuiService.SelectedCoreObject = ResumeGameButton end)
	elseif currentMenu == ResetCharacterFrame then 
		--pcall(function() GuiService.SelectedCoreObject = ConfirmResetButton end)
	elseif currentMenu == GameSettingsMenuFrame then 
		if GameSettingsMenuFrame.ShiftLockCheckBox and GameSettingsMenuFrame.ShiftLockCheckBox.Visible then 
			--pcall(function() GuiService.SelectedCoreObject = GameSettingsMenuFrame.ShiftLockCheckBox end)
		else 
			--pcall(function() GuiService.SelectedCoreObject = CameraModeDropDown.CurrentSelectionButton end)
		end 
	end 
end 

local function pushMenu(nextMenu)
	if IsMenuClosing then return end
	local prevMenu = MenuStack[#MenuStack]
	MenuStack[#MenuStack + 1] = nextMenu
	--
	if prevMenu then
		prevMenu:TweenPosition(UDim2.new(-1, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
	end
	if #MenuStack > 1 then
		nextMenu:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
	end

	setGamepadButton(nextMenu)
end

local function popMenu()
	if #MenuStack == 0 then return end
	--
	local currentMenu = MenuStack[#MenuStack]
	MenuStack[#MenuStack] = nil
	local prevMenu = MenuStack[#MenuStack]
	--
	if #MenuStack > 0 then
		currentMenu:TweenPosition(UDim2.new(1, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
		-- special case to close drop down menus on game settings menu when it goes out of focus
		closeCurrentDropDownMenu()
	end
	if prevMenu then
		prevMenu:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
		setGamepadButton(prevMenu)
	end
end

local function emptyMenuStack()
	for k,v in pairs(MenuStack) do
		if k ~= 1 then
			v.Position = UDim2.new(1, 0, 0, 0)
		else
			v.Position = UDim2.new(0, 0, 0, 0)
		end
		MenuStack[k] = nil
	end
end


local function turnOffSettingsMenu()
	SettingsShield.Active = false
	SettingsShield.Visible = false
	SettingsButton.Active = true
	SettingClipFrame.Position = CLOSE_MENU_POS
	--
	emptyMenuStack()
	IsMenuClosing = false
	pcall(function() game:GetService("UserInputService").OverrideMouseIconEnabled = false end)
end

local function closeSettingsMenu(forceClose)
	IsMenuClosing = true
	if forceClose then
		turnOffSettingsMenu()
	else
		SettingClipFrame:TweenPosition(CLOSE_MENU_POS, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true, turnOffSettingsMenu)
	end

	if UserInputService.GamepadEnabled and isGamepadSupport then
		--pcall(function() GuiService.SelectedCoreObject = nil
		--ContextActionService:UnbindCoreAction("backbutton")
		--ContextActionService:UnbindCoreAction("DontMove") end)
	end

	pcall(function()
		ContextActionService:UnbindAction("Settings2_BlockMovement")
	end)

	SettingsShowSignal:fire(false)
end

local backButtonFunc = function(actionName, state, input)
	if state ~= Enum.UserInputState.Begin then return end

	if #MenuStack == 1 then
		closeSettingsMenu(true)
	else
		popMenu()
	end
end

local noOptFunc = function() end

local function showSettingsRootMenu()
	SettingsButton.Active = false
	pushMenu(RootMenuFrame)
	pcall(function() UserInputService.OverrideMouseIconEnabled = true end)
	--
	SettingsShield.Visible = true
	SettingsShield.Active = true
	SettingsShield.Modal = true

	-- Block character controls while the menu is open.
	pcall(function()
		ContextActionService:BindAction(
			"Settings2_BlockMovement",
			function()
				return Enum.ContextActionResult.Sink
			end,
			false,
			Enum.PlayerActions.CharacterForward,
			Enum.PlayerActions.CharacterBackward,
			Enum.PlayerActions.CharacterLeft,
			Enum.PlayerActions.CharacterRight,
			Enum.PlayerActions.CharacterJump
		)
	end)
	--
	SettingClipFrame:TweenPosition(SHOW_MENU_POS, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
	SettingsShowSignal:fire(true)

	if not isGamepadSupport then return end
	if UserInputService.GamepadEnabled then
		pcall(function() game.ContextActionService:BindCoreAction("DontMove", noOptFunc, false, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2, 
			Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonSelect,
			Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonL2, Enum.KeyCode.ButtonL3, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonR3,
			Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown)

			ContextActionService:BindCoreAction("backbutton", backButtonFunc, false, Enum.KeyCode.ButtonB) end)
	end
end

local function showHelpMenu()
	SettingClipFrame:TweenPosition(CLOSE_MENU_POS, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true,
		function()
			SettingClipFrame.Visible = false
		end)
	HelpMenuFrame.Visible = true
	HelpMenuFrame:TweenPosition(UDim2.new(0.2, 0, 0.2, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
end

local function hideHelpMenu()
	HelpMenuFrame:TweenPosition(UDim2.new(0.2, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true,
		function()
			HelpMenuFrame.Visible = false
		end)
	SettingClipFrame.Visible = true
	SettingClipFrame:TweenPosition(SHOW_MENU_POS, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
end

local function changeHelpDialog(button, img)
	if CurrentHelpDialogButton == button then return end
	--
	CurrentHelpDialogButton.Style = Enum.ButtonStyle.RobloxRoundButton
	CurrentHelpDialogButton = button
	CurrentHelpDialogButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
	HelpMenuImage.Image = img
end

local function resetLocalCharacter()
	-- NOTE: This should be fixed at some point to not find humanoid by name.
	-- Devs can rename the players humanoid and bypass this. I am leaving it this way
	-- as to not break any games that currently do this. We need to come up with
	-- a better solution to allow devs to disable character reset
	local player = Players.LocalPlayer
	if player then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild('Humanoid')
			if humanoid then
				humanoid.Health = 0
			end
		end
	end
end

local function onRecordVideoToggle()
	if not StopRecordingVideoButton then return end
	IsRecordingVideo = not IsRecordingVideo
	if IsRecordingVideo then
		StopRecordingVideoButton.Visible = true
		RecordVideoButton.Text = "Stop Recording"
	else
		StopRecordingVideoButton.Visible = false
		RecordVideoButton.Text = "Record Video"
	end
end

local function onReportSubmitted()
	if not ReportSubmitButton.Active then return end
	--
	if IsReportingPlayer then
		if CurrentAbusingPlayer and AbuseReason then
			Players:ReportAbuse(CurrentAbusingPlayer, AbuseReason, ReportDescriptionTextBox.Text)
		end
	else
		if AbuseReason then
			Players:ReportAbuse(nil, AbuseReason, ReportDescriptionTextBox.Text)
		end
	end
	if AbuseReason == 'Cheating/Exploiting' then
		ReportAbuseConfirmationText.Text = "Thanks for your report!\n We've recorded your report for evaluation."
	elseif AbuseReason == 'Bullying' or AbuseReason == 'Swearing' then
		ReportAbuseConfirmationText.Text = "Thanks for your report! Our moderators will review the chat logs and determine what happened. The other user is probably just trying to make you mad. If anyone used swear words, inappropriate language, or threatened you in real life, please report them for Bad Words or Threats"
	else
		ReportAbuseConfirmationText.Text = "Thanks for your report! Our moderators will review the chat logs and determine what happened."
	end
	pushMenu(ReportAbuseConfirmationFrame)
	cleanupReportAbuseMenu()
end

local function toggleDevConsole(actionName, inputState, inputObject)
	--if actionName == "Open Dev Console" then 	-- ContextActionService->F9
	--	if inputState and inputState == Enum.UserInputState.Begin and BindableFunc_ToggleDevConsole then
	--		BindableFunc_ToggleDevConsole:Invoke()
	--	end
	--elseif BindableFunc_ToggleDevConsole then 	-- Button Press from help menu
	--	BindableFunc_ToggleDevConsole:Invoke()
	--end
end

local function updateUserSettingsMenu(property)
	if not isLuaControls then return end
	if property == "DevEnableMouseLock" then
		ShiftLockCheckBox.Visible = LocalPlayer.DevEnableMouseLock
		ShiftLockOverrideText.Visible = not LocalPlayer.DevEnableMouseLock
		IsShiftLockEnabled = false
		ShiftLockCheckBox.Text = IsShiftLockEnabled and "X" or ""
	elseif property == "DevComputerCameraMode" then
		local isUserChoice = LocalPlayer.DevComputerCameraMode == Enum.DevComputerCameraMovementMode.UserChoice
		CameraModeDropDown.SetVisible(isUserChoice)
		CameraModeOverrideText.Visible = not isUserChoice
	elseif property == "DevComputerMovementMode" then
		local isUserChoice = LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.UserChoice
		if MovementModeDropDown then MovementModeDropDown.SetVisible(isUserChoice) end
		if MovementModeOverrideText then MovementModeOverrideText.Visible = not isUserChoice end
		-- TOUCH
	elseif property == "DevTouchMovementMode" then
		local isUserChoice = LocalPlayer.DevTouchMovementMode == Enum.DevTouchMovementMode.UserChoice
		if MovementModeDropDown then MovementModeDropDown.SetVisible(isUserChoice) end
		if MovementModeOverrideText then MovementModeOverrideText.Visible = not isUserChoice end
	elseif property == "DevTouchCameraMode" then
		local isUserChoice = LocalPlayer.DevTouchCameraMode == Enum.DevTouchCameraMovementMode.UserChoice
		CameraModeDropDown.SetVisible(isUserChoice)
		CameraModeOverrideText.Visible = not isUserChoice
	end
end

--[[ Input Actions ]]--
do
	SettingsShield.InputBegan:connect(function(inputObject)
		local inputType = inputObject.UserInputType
		if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
			closeCurrentDropDownMenu()
		end
	end)
	--
	local escapePressedCn = nil
	SettingsShield.Parent = SettingsMenuFrame
	--

	local function handleEscapePressed()
		if #MenuStack == 0 then
			showSettingsRootMenu()
		elseif #MenuStack == 1 then
			closeSettingsMenu()
		else
			local currentMenu = MenuStack[#MenuStack]
			popMenu()
			if currentMenu == ReportAbuseFrame then
				cleanupReportAbuseMenu()
			end
		end
	end

	-- Modern replacement for the removed ReplicatedStorage.GlobalEvents.EscapeKeyPressed.
	escapePressedCn = UserInputService.InputBegan:connect(function(inputObject, gameProcessed)
		if inputObject.KeyCode == Enum.KeyCode.Escape then
			handleEscapePressed()
		end
	end)
	SettingsButton.MouseButton1Click:connect(showSettingsRootMenu)
	-- Root Menu Connections
	ResumeGameButton.MouseButton1Click:connect(closeSettingsMenu)
	ResetCharacterButton.MouseButton1Click:connect(function() pushMenu(ResetCharacterFrame) end)
	GameSettingsButton.MouseButton1Click:connect(function() pushMenu(GameSettingsMenuFrame) end)
	ReportAbuseButton.MouseButton1Click:connect(function()
		createReportAbuseMenu()
		pushMenu(ReportAbuseFrame)
	end)
	LeaveGameButton.MouseButton1Click:connect(function() pushMenu(LeaveGameMenuFrame) end)
	if ScreenshotButton then
		ScreenshotButton.MouseButton1Click:connect(function()
			closeSettingsMenu(true)
		end)
	end
	if HelpButton then
		HelpButton.MouseButton1Click:connect(function() pushMenu(HelpMenuFrame) end)
	end

	--[[ Video Recording ]]--
	if RecordVideoButton then
		RecordVideoButton.MouseButton1Click:connect(function()
			closeSettingsMenu(true)
		end)
	end
	--local gameOptions = settings():FindFirstChild("Game Options")

	--if gameOptions then
	--	local success, result = pcall(function()
	--		gameOptions.VideoRecordingChangeRequest:connect(function(recording)
	--			if isTopBar then
	--				IsRecordingVideo = not IsRecordingVideo
	--				RecordVideoButton.Text = IsRecordingVideo and "Stop Recording" or "Record Video"
	--			else
	--				onRecordVideoToggle()
	--			end
	--		end)
	--	end)
	--	if not success then
	--		print("Settings2.lua: VideoRecordingChangeRequest connection failed because", result)
	--	end
	--end

	-- Reset Character Menu Connections
	ConfirmResetButton.MouseButton1Click:connect(function()
		resetLocalCharacter()
		closeSettingsMenu()
	end)
	CancelResetButton.MouseButton1Click:connect(popMenu)

	if ShiftLockCheckBox then
		ShiftLockCheckBox.MouseButton1Click:connect(function()
			IsShiftLockEnabled = not IsShiftLockEnabled
			ShiftLockCheckBox.Text = IsShiftLockEnabled and "X" or ""
			--GameSettings.ControlMode = 
			--"Classic"
			if shiftLockImageLabel then
				shiftLockImageLabel.Visible = IsShiftLockEnabled
			end
		end)
	end
	-- Game Settings Menu Connections

	GameSettingsBackButton.MouseButton1Click:connect(popMenu)

	-- Help Menu Connections
	HelpMenuBackButton.MouseButton1Click:connect(popMenu)
	HelpLookButton.MouseButton1Click:connect(function()
		changeHelpDialog(HelpLookButton, HELP_IMG.CLASSIC_MOVE)
	end)
	HelpMoveButton.MouseButton1Click:connect(function()
		changeHelpDialog(HelpMoveButton, HELP_IMG.MOVEMENT)
	end)
	HelpGearButton.MouseButton1Click:connect(function()
		changeHelpDialog(HelpGearButton, HELP_IMG.GEAR)
	end)
	HelpZoomButton.MouseButton1Click:connect(function()
		changeHelpDialog(HelpZoomButton, HELP_IMG.ZOOM)
	end)

	-- Report Abuse Connections
	ReportCancelButton.MouseButton1Click:connect(function()
		popMenu()
		cleanupReportAbuseMenu()
	end)
	ReportSubmitButton.MouseButton1Click:connect(onReportSubmitted)
	ReportAbuseConfirmationButton.MouseButton1Click:connect(closeSettingsMenu)

	-- Leave Game Menu
	LeaveCancelButton.MouseButton1Click:connect(popMenu)

	-- Dev Console Connections
	HelpConsoleButton.MouseButton1Click:connect(toggleDevConsole)
	local success = pcall(function() ContextActionService:BindCoreAction("Open Dev Console", toggleDevConsole, false, Enum.KeyCode.F9) end)
	if not success then
		UserInputService.InputBegan:connect(function(inputObject)
			if inputObject.KeyCode == Enum.KeyCode.F9 then
				toggleDevConsole("Open Dev Console", Enum.UserInputState.Begin, inputObject)
			end
		end)
		UserInputService.InputEnded:connect(function(inputObject)
			if inputObject.KeyCode == Enum.KeyCode.F9 then
				toggleDevConsole("Open Dev Console", Enum.UserInputState.End, inputObject)
			end
		end)
	end

	LocalPlayer.Changed:connect(function(property)
		if IsTouchClient then
			if TOUCH_CHANGED_PROPS[property] then
				updateUserSettingsMenu(property)
			end
		else
			if PC_CHANGED_PROPS[property] then
				updateUserSettingsMenu(property)
			end
		end
	end)

	-- connect back button on android
	local showLeaveEvent = nil
	--pcall(function() showLeaveEvent = GuiService.ShowLeaveConfirmation end)
	if showLeaveEvent then
		--GuiService.ShowLeaveConfirmation:connect(function()
		--	if #MenuStack == 0 then
		--		showSettingsRootMenu()
		--		RootMenuFrame.Position = UDim2.new(-1, 0, 0, 0)
		--		LeaveGameMenuFrame.Position = UDim2.new(0, 0, 0, 0)
		--		pushMenu(LeaveGameMenuFrame)
		--	else
		--		closeSettingsMenu()
		--	end
		--end)
	end

	-- Remove old gui buttons
	-- TODO: Gut this from the engine code
	local oldLeaveGameButton = TopLeftControl:FindFirstChild('Exit')
	if oldLeaveGameButton then
		oldLeaveGameButton:Destroy()
	else
		oldLeaveGameButton = BottomLeftControl:FindFirstChild('Exit')
		if oldLeaveGameButton then oldLeaveGameButton:Destroy() end
	end

	SettingsMenuFrame.Parent = RobloxGui
end

local moduleApiTable = {}

function moduleApiTable:ToggleVisibility(visible)
	if visible == nil then
		visible = (#MenuStack == 0)
	end

	if visible then
		if #MenuStack == 0 then
			showSettingsRootMenu()
		end
	else
		if #MenuStack > 0 then
			closeSettingsMenu()
		end
	end
end

function moduleApiTable:GetVisibility()
	return #MenuStack > 0 and SettingsShield.Visible
end

moduleApiTable.SettingsShowSignal = SettingsShowSignal

return moduleApiTable

end;
};
G2L_MODULES[G2L["a"]] = {
Closure = function()
    local script = G2L["a"];--[[
		// FileName: PlayerlistModule.lua
		// Version 1.3
		// Written by: jmargh
		// Description: Implementation of in game player list and leaderboard
]]

local GuiService = game:GetService('GuiService')
local UserInputService = game:GetService('UserInputService')
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')
local TeamsService = game:FindService('Teams')
local ContextActionService = game:GetService('ContextActionService')

while not Players.LocalPlayer do
	task.wait()
end

local Player = Players.LocalPlayer
local RobloxGui = script.Parent.Parent

assert(RobloxGui and RobloxGui:IsA("LayerCollector"),
	"[2015 Playerlist] PlayerlistModule must be inside RobloxGui > Modules")

local HttpRbxApiService = nil
pcall(function()
	HttpRbxApiService = game:GetService('HttpRbxApiService')
end)

local RobloxReplicatedStorage = nil
local RbxGuiLibrary = nil

--[[ Fast Flags ]]--
local IsNewSettings = true
local IsServerCoreScripts = false
local IsGamepadSupported = UserInputService.GamepadEnabled

--[[ Start Module ]]--
local Playerlist = {}

--[[ Public Event API ]]--
-- Parameters: Sorted Array - see GameStats below
Playerlist.OnLeaderstatsChanged = Instance.new('BindableEvent')
-- Parameters: nameOfStat(string), formatedStringOfStat(string)
Playerlist.OnStatChanged = Instance.new('BindableEvent')

--[[ Client Stat Table ]]--
-- Sorted Array of tables
local GameStats = {}
-- Fields
-- Name: String the developer has given the stat
-- Text: Formated string of the stat value
-- AddId: Child add order id
-- IsPrimary: Is this the primary stat
-- Priority: Sorting priority
-- NOTE: IsPrimary and Priority are unofficially supported. They are left over legacy from the old player list.
-- They can be un-supported at anytime. You should prefer using child add order to order your stats in the leader board.

--[[ Script Variables ]]--
local MyPlayerEntry = nil
local PlayerEntries = {}
local StatAddId = 0
local TeamEntries = {}
local TeamAddId = 0
local NeutralTeam = nil
local IsShowingNeutralFrame = false
local LastSelectedFrame = nil
local LastSelectedPlayer = nil
local MinContainerSize = UDim2.new(0, 165, 0.5, 0)
local PlayerEntrySizeY = 24
local TeamEntrySizeY = 18
local NameEntrySizeX = 170
local StatEntrySizeX = 75
local currentCamera = workspace.CurrentCamera
local screenHeight = currentCamera and currentCamera.ViewportSize.Y or 720
local IsSmallScreenDevice = UserInputService.TouchEnabled and screenHeight <= 500

--[[ Bindables ]]--
local BinbableFunction_SendNotification = RobloxGui:FindFirstChild('SendNotification')

--[[ Remotes ]]--
local RemoteEvent_OnNewFollower = nil 	-- we get this later in the script

local IsPersonalServer = false
local PersonalServerService = nil
if workspace:FindFirstChild('PSVariable') then
	IsPersonalServer = true
	PersonalServerService = game:GetService('PersonalServerService')
end
workspace.ChildAdded:connect(function(child)
	if child.Name == 'PSVariable' and child:IsA('BoolValue') then
		IsPersonalServer = true
		PersonalServerService = game:GetService('PersonalServerService')
	end
end)

--Report Abuse
local AbusingPlayer = nil
local AbuseReason = nil

--[[ Constants ]]--
local ENTRY_PAD = 2
local BG_TRANSPARENCY = 0.5
local BG_COLOR = Color3.new(31/255, 31/255, 31/255)
local TEXT_STROKE_TRANSPARENCY = 0.75
local TEXT_COLOR = Color3.new(1, 1, 243/255)
local TEXT_STROKE_COLOR = Color3.new(34/255, 34/255, 34/255)
local TWEEN_TIME = 0.15
local MAX_LEADERSTATS = 4
local MAX_STR_LEN = 12
local MAX_FRIEND_COUNT = 200

local ADMINS = {	-- Admins with special icons
	['7210880'] = 'http://www.roblox.com/asset/?id=134032333', -- Jeditkacheff
	['13268404'] = 'http://www.roblox.com/asset/?id=113059239', -- Sorcus
	['261'] = 'http://www.roblox.com/asset/?id=105897927', -- shedlestky
	['20396599'] = 'http://www.roblox.com/asset/?id=161078086', -- Robloxsai
}

local ABUSES = {
	"Swearing",
	"Bullying",
	"Scamming",
	"Dating",
	"Cheating/Exploiting",
	"Personal Questions",
	"Offsite Links",
	"Bad Username",
}

local FOLLOWER_STATUS = {
	FOLLOWER = 0,
	FOLLOWING = 1,
	MUTUAL = 2,
}

local PRIVILEGE_LEVEL = {
	OWNER = 255,
	ADMIN = 240,
	MEMBER = 128,
	VISITOR = 10,
	BANNED = 0,
}

--[[ Images ]]--
local CHAT_ICON = 'rbxasset://textures/ui/chat_teamButton.png'
local ADMIN_ICON = 'rbxasset://textures/ui/icon_admin-16.png'
local PLACE_OWNER_ICON = 'rbxasset://textures/ui/icon_placeowner.png'
local BC_ICON = 'rbxasset://textures/ui/icon_BC-16.png'
local TBC_ICON = 'rbxasset://textures/ui/icon_TBC-16.png'
local OBC_ICON = 'rbxasset://textures/ui/icon_OBC-16.png'
local FRIEND_ICON = 'rbxasset://textures/ui/icon_friends_16.png'
local FRIEND_REQUEST_ICON = 'rbxasset://textures/ui/icon_friendrequestsent_16.png'
local FRIEND_RECEIVED_ICON = 'rbxasset://textures/ui/icon_friendrequestrecieved-16.png'

local FOLLOWER_ICON = 'rbxasset://textures/ui/icon_follower-16.png'
local FOLLOWING_ICON = 'rbxasset://textures/ui/icon_following-16.png'
local MUTUAL_FOLLOWING_ICON = 'rbxasset://textures/ui/icon_mutualfollowing-16.png'

local FRIEND_IMAGE = 'http://www.roblox.com/thumbs/avatar.ashx?userId='

--[[ Helper Functions ]]--
local function clamp(value, min, max)
	if value < min then
		value = min
	elseif value > max then
		value = max
	end

	return value
end

local function getFriendStatus(selectedPlayer)
	if selectedPlayer == Player then
		return Enum.FriendStatus.NotFriend
	else
		local success, result = pcall(function()
			-- NOTE: Core script only
			return require(game.ReplicatedStorage.GlobalEvents):GetFriendStatus(selectedPlayer.UserId)
		end)
		if success then
			return result
		else
			return Enum.FriendStatus.NotFriend
		end
	end
end

-- Returns whether followerUserId is following userId
local function isFollowing(userId, followerUserId)
	local apiPath = "user/following-exists?userId="
	local params = userId.."&followerUserId="..followerUserId
	local success, result = pcall(function()
		if not HttpRbxApiService then error('HttpRbxApiService unavailable') end
		return HttpRbxApiService:GetAsync(apiPath..params, true)
	end)
	if not success then
		print("isFollowing() failed because", result)
		return false
	end

	-- can now parse web response
	result = HttpService:JSONDecode(result)
	return result["success"] and result["isFollowing"]
end

local function getFollowerStatus(selectedPlayer)
	if selectedPlayer == Player then
		return nil
	end

	-- ignore guest
	if selectedPlayer.userId <= 0 or Player.userId <= 0 then
		return
	end

	local myUserId = tostring(Player.userId)
	local theirUserId = tostring(selectedPlayer.userId)

	local isFollowingMe = isFollowing(myUserId, theirUserId)
	local isFollowingThem = isFollowing(theirUserId, myUserId)

	if isFollowingMe and isFollowingThem then 	-- mutual
		return FOLLOWER_STATUS.MUTUAL
	elseif isFollowingMe then
		return FOLLOWER_STATUS.FOLLOWER
	elseif isFollowingThem then
		return FOLLOWER_STATUS.FOLLOWING
	else
		return nil
	end
end

local function getFriendStatusIcon(friendStatus)
	if friendStatus == Enum.FriendStatus.Unknown or friendStatus == Enum.FriendStatus.NotFriend then
		return nil
	elseif friendStatus == Enum.FriendStatus.Friend then
		return FRIEND_ICON
	elseif friendStatus == Enum.FriendStatus.FriendRequestSent then
		return FRIEND_REQUEST_ICON
	elseif friendStatus == Enum.FriendStatus.FriendRequestReceived then
		return FRIEND_RECEIVED_ICON
	else
		error("PlayerList: Unknown value for friendStatus: "..tostring(friendStatus))
	end
end

local function getFollowerStatusIcon(followerStatus)
	if followerStatus == FOLLOWER_STATUS.MUTUAL then
		return MUTUAL_FOLLOWING_ICON
	elseif followerStatus == FOLLOWER_STATUS.FOLLOWING then
		return FOLLOWING_ICON
	elseif followerStatus == FOLLOWER_STATUS.FOLLOWER then
		return FOLLOWER_ICON
	else
		return nil
	end
end

local function getAdminIcon(player)
	local userIdStr = tostring(player.userId)
	if ADMINS[userIdStr] then return nil end
	--
	local success, result = pcall(function()
		return player:IsInGroup(1200769)	-- yields
	end)
	if not success then
		print("PlayerListScript2: getAdminIcon() failed because", result)
		return nil
	end
	--
	if result then
		return ADMIN_ICON
	end
end

local function getMembershipIcon(player)
	local userIdStr = tostring(player.userId)
	local membershipType = player.MembershipType
	if ADMINS[userIdStr] then
		return ADMINS[userIdStr]
	elseif player.userId == game.CreatorId and game.CreatorType == Enum.CreatorType.User then
		return PLACE_OWNER_ICON
	elseif membershipType == Enum.MembershipType.None then
		return nil
	elseif membershipType == Enum.MembershipType.Premium then
		return OBC_ICON
	else
		error("PlayerList: Unknown value for membershipType"..tostring(membershipType))
	end
end

local function isValidStat(obj)
	return obj:IsA('StringValue') or obj:IsA('IntValue') or obj:IsA('BoolValue') or obj:IsA('NumberValue') or
		obj:IsA('DoubleConstrainedValue') or obj:IsA('IntConstrainedValue')
end

local function sortPlayerEntries(a, b)
	if a.PrimaryStat == b.PrimaryStat then
		return a.Player.Name:upper() < b.Player.Name:upper()
	end
	if not a.PrimaryStat then return false end
	if not b.PrimaryStat then return true end
	return a.PrimaryStat > b.PrimaryStat
end

local function sortLeaderStats(a, b)
	if a.IsPrimary ~= b.IsPrimary then
		return a.IsPrimary
	end
	if a.Priority == b.Priority then
		return a.AddId < b.AddId
	end
	return a.Priority < b.Priority
end

local function sortTeams(a, b)
	if a.TeamScore == b.TeamScore then
		return a.Id < b.Id
	end
	if not a.TeamScore then return false end
	if not b.TeamScore then return true end
	return a.TeamScore < b.TeamScore
end

local function sendNotification(title, text, image, duration, callback)
	if BinbableFunction_SendNotification then
		BinbableFunction_SendNotification:Invoke(title, text, image, duration, callback)
	end
end

-- Start of Gui Creation
local Container = Instance.new('Frame')
Container.Name = "PlayerListContainer"
Container.Position = UDim2.new(1, -167, 0, 38)
Container.Size = MinContainerSize
Container.BackgroundTransparency = 1
Container.Visible = false
Container.Parent = RobloxGui

-- Scrolling Frame
local ScrollList = Instance.new('ScrollingFrame')
ScrollList.Name = "ScrollList"
ScrollList.Size = UDim2.new(1, -1, 0, 0)
ScrollList.BackgroundTransparency = 1
ScrollList.BackgroundColor3 = Color3.new()
ScrollList.BorderSizePixel = 0
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)	-- NOTE: Look into if x needs to be set to anything
ScrollList.ScrollBarThickness = 6
ScrollList.BottomImage = 'rbxasset://textures/ui/scroll-bottom.png'
ScrollList.MidImage = 'rbxasset://textures/ui/scroll-middle.png'
ScrollList.TopImage = 'rbxasset://textures/ui/scroll-top.png'
ScrollList.Parent = Container

-- Friend/Report Popup
local PopupFrame = nil
local PopupClipFrame = Instance.new('Frame')
PopupClipFrame.Name = "PopupClipFrame"
PopupClipFrame.Size = UDim2.new(0, 150, 1.5, 0)
PopupClipFrame.Position = UDim2.new(0, -150 - ENTRY_PAD, 0, 0)
PopupClipFrame.BackgroundTransparency = 1
PopupClipFrame.ClipsDescendants = true
PopupClipFrame.Parent = Container

-- Report Abuse Gui
local ReportAbuseShield = Instance.new('TextButton')
ReportAbuseShield.Name = "ReportAbuseShield"
ReportAbuseShield.Size = UDim2.new(1, 0, 1, 36)
ReportAbuseShield.Position = UDim2.new(0, 0, 0, -36)
ReportAbuseShield.BackgroundColor3 = Color3.new(51/255, 51/255, 51/255)
ReportAbuseShield.BackgroundTransparency = 0.4
ReportAbuseShield.ZIndex = 1
ReportAbuseShield.Text = ""
ReportAbuseShield.AutoButtonColor = false

local ReportAbuseFrame = Instance.new('Frame')
ReportAbuseFrame.Name = "ReportAbuseFrame"
ReportAbuseFrame.Size = UDim2.new(0, 525, 0, 390)
ReportAbuseFrame.Position = UDim2.new(0.5, -262, 0.5, -195)
ReportAbuseFrame.BackgroundTransparency = 0.7
ReportAbuseFrame.BackgroundColor3 = Color3.new(0, 0, 0)
ReportAbuseFrame.Style = Enum.FrameStyle.DropShadow
ReportAbuseFrame.Parent = ReportAbuseShield

local reportYOffset = 24
local ReportAbuseTitle = Instance.new('TextLabel')
ReportAbuseTitle.Name = "ReportAbuseTitle"
ReportAbuseTitle.Text = "Report Abuse"
ReportAbuseTitle.Size = UDim2.new(0, 0, 0, 0)
ReportAbuseTitle.Position = UDim2.new(0.5, 0, 0, reportYOffset)
ReportAbuseTitle.BackgroundTransparency = 1
ReportAbuseTitle.Font = Enum.Font.SourceSansBold
ReportAbuseTitle.FontSize = Enum.FontSize.Size36
ReportAbuseTitle.TextColor3 = Color3.new(1, 1, 1)
ReportAbuseTitle.Parent = ReportAbuseFrame
reportYOffset = reportYOffset + 32

local ReportAbuseDescription = Instance.new('TextLabel')
ReportAbuseDescription.Name = "ReportAbuseDescription"
ReportAbuseDescription.Text = "This will send a complete report to a moderator.  The moderator will review the chat log and take appropriate action."
ReportAbuseDescription.Size = UDim2.new(1, -40, 0, 40)
ReportAbuseDescription.Position = UDim2.new(0, 35, 0, reportYOffset)
ReportAbuseDescription.BackgroundTransparency = 1
ReportAbuseDescription.Font = Enum.Font.SourceSans
ReportAbuseDescription.FontSize = Enum.FontSize.Size18
ReportAbuseDescription.TextColor3 = Color3.new(1, 1, 1)
ReportAbuseDescription.TextWrap = true
ReportAbuseDescription.TextXAlignment = Enum.TextXAlignment.Left
ReportAbuseDescription.TextYAlignment = Enum.TextYAlignment.Top
ReportAbuseDescription.Parent = ReportAbuseFrame
reportYOffset = reportYOffset + 70

local ReportPlayerLabel = Instance.new('TextLabel')
ReportPlayerLabel.Name = "ReportPlayerLabel"
ReportPlayerLabel.Text = "Player Reporting:"
ReportPlayerLabel.Size = UDim2.new(0, 0, 0, 0)
ReportPlayerLabel.Position = UDim2.new(0.5, -6, 0, reportYOffset)
ReportPlayerLabel.BackgroundTransparency = 1
ReportPlayerLabel.Font = Enum.Font.SourceSans
ReportPlayerLabel.FontSize = Enum.FontSize.Size18
ReportPlayerLabel.TextColor3 = Color3.new(1, 1, 1)
ReportPlayerLabel.TextXAlignment = Enum.TextXAlignment.Right
ReportPlayerLabel.Parent = ReportAbuseFrame

local ReportPlayerName = Instance.new('TextLabel')
ReportPlayerName.Name = "ReportPlayerName"
ReportPlayerName.Text = ""
ReportPlayerName.Size = UDim2.new(0, 0, 0, 0)
ReportPlayerName.Position = UDim2.new(0.5, 18, 0, reportYOffset)
ReportPlayerName.BackgroundTransparency = 1
ReportPlayerName.Font = Enum.Font.SourceSans
ReportPlayerName.FontSize = Enum.FontSize.Size18
ReportPlayerName.TextColor3 = Color3.new(1, 1, 1)
ReportPlayerName.TextXAlignment = Enum.TextXAlignment.Left
ReportPlayerName.Parent = ReportAbuseFrame
reportYOffset = reportYOffset + 40

local ReportReasonLabel = Instance.new('TextLabel')
ReportReasonLabel.Name = "ReportReasonLabel"
ReportReasonLabel.Text = "Type of Abuse:"
ReportReasonLabel.Size = UDim2.new(0, 0, 0, 0)
ReportReasonLabel.Position = UDim2.new(0.5, -6, 0, reportYOffset)
ReportReasonLabel.BackgroundTransparency = 1
ReportReasonLabel.Font = Enum.Font.SourceSans
ReportReasonLabel.FontSize = Enum.FontSize.Size18
ReportReasonLabel.TextColor3 = Color3.new(1, 1, 1)
ReportReasonLabel.TextXAlignment = Enum.TextXAlignment.Right
ReportReasonLabel.Parent = ReportAbuseFrame
reportYOffset = reportYOffset + 40

local ReportDescriptionLabel = ReportAbuseDescription:Clone()
ReportDescriptionLabel.Name = "ReportDescriptionLabel"
ReportDescriptionLabel.Text = "Short Description: (optional)"
ReportDescriptionLabel.Position = UDim2.new(0, 35, 0, reportYOffset)
ReportDescriptionLabel.Parent = ReportAbuseFrame
reportYOffset = reportYOffset + 28

local ReportDescriptionBox = Instance.new('TextBox')
ReportDescriptionBox.Name = "ReportDescriptionBox"
ReportDescriptionBox.Text = ""
ReportDescriptionBox.Size = UDim2.new(1, -70, 1, -reportYOffset - 80)
ReportDescriptionBox.Position = UDim2.new(0, 35, 0, reportYOffset)
ReportDescriptionBox.BackgroundTransparency = 1
ReportDescriptionBox.Font = Enum.Font.SourceSans
ReportDescriptionBox.FontSize = Enum.FontSize.Size18
ReportDescriptionBox.TextColor3 = Color3.new(0, 0, 0)
ReportDescriptionBox.TextXAlignment = Enum.TextXAlignment.Left
ReportDescriptionBox.TextYAlignment = Enum.TextYAlignment.Top
ReportDescriptionBox.TextWrap = true
ReportDescriptionBox.ClearTextOnFocus = false
ReportDescriptionBox.Parent = ReportAbuseFrame

local ReportDescriptionBg = Instance.new('TextButton')
ReportDescriptionBg.Name = "ReportDescriptionBg"
ReportDescriptionBg.Size = UDim2.new(1, 16, 1, 16)
ReportDescriptionBg.Position = UDim2.new(0, -8, 0, -8)
ReportDescriptionBg.Text = ""
ReportDescriptionBg.Active = false
ReportDescriptionBg.AutoButtonColor = false
ReportDescriptionBg.Style = Enum.ButtonStyle.RobloxRoundDropdownButton
ReportDescriptionBg.Parent = ReportDescriptionBox
reportYOffset = reportYOffset + ReportDescriptionBox.AbsoluteSize.y + 20

local ReportSubmitButton = Instance.new('TextButton')
ReportSubmitButton.Name = "ReportSubmitButton"
ReportSubmitButton.Text = "Submit"
ReportSubmitButton.Size = UDim2.new(0, 168, 0, 50)
ReportSubmitButton.Position = UDim2.new(0.5, 2, 0, reportYOffset)
ReportSubmitButton.Font = Enum.Font.SourceSansBold
ReportSubmitButton.FontSize = Enum.FontSize.Size24
ReportSubmitButton.TextColor3 = Color3.new(163/255, 162/255, 165/255)
ReportSubmitButton.Active = false
ReportSubmitButton.AutoButtonColor = true
ReportSubmitButton.Modal = true
ReportSubmitButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
ReportSubmitButton.Parent = ReportAbuseFrame

local ReportCanelButton = Instance.new('TextButton')
ReportCanelButton.Name = "ReportCanelButton"
ReportCanelButton.Text = "Cancel"
ReportCanelButton.Size = UDim2.new(0, 168, 0, 50)
ReportCanelButton.Position = UDim2.new(0.5, -170, 0, reportYOffset)
ReportCanelButton.Font = Enum.Font.SourceSansBold
ReportCanelButton.FontSize = Enum.FontSize.Size24
ReportCanelButton.TextColor3 = Color3.new(1, 1, 1)
ReportCanelButton.Style = Enum.ButtonStyle.RobloxRoundButton
ReportCanelButton.Parent = ReportAbuseFrame

local AbuseDropDown, updateAbuseSelection = nil, nil
if IsNewSettings then
	--AbuseDropDown = RbxGuiLibrary.CreateScrollingDropDownMenu(
	--	function(text)
	--		AbuseReason = text
	--		if AbuseReason and AbusingPlayer then
	--			ReportSubmitButton.Active = true
	--			ReportSubmitButton.TextColor3 = Color3.new(1, 1, 1)
	--		end
	--	end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, ReportReasonLabel.Position.Y.Offset - 16), 1)
	--AbuseDropDown.CreateList(ABUSES)
	--AbuseDropDown.Frame.Parent = ReportAbuseFrame
else
	--AbuseDropDown, updateAbuseSelection = RbxGuiLibrary.CreateDropDownMenu(ABUSES,
	--	function(abuseText)
	--		AbuseReason = abuseText
	--		if AbuseReason and AbusingPlayer then
	--			ReportSubmitButton.Active = true
	--			ReportSubmitButton.TextColor3 = Color3.new(1, 1, 1)
	--		end
	--	end, true, true, 1)
	--AbuseDropDown.Name = "AbuseDropDown"
	--AbuseDropDown.Size = UDim2.new(0, 200, 0, 32)
	--AbuseDropDown.Position = UDim2.new(0.5, 6, 0, ReportReasonLabel.Position.Y.Offset - 16)
	--AbuseDropDown.Parent = ReportAbuseFrame
end

-- Report Confirm Gui
local ReportConfirmFrame = Instance.new('Frame')
ReportConfirmFrame.Name = "ReportConfirmFrame"
ReportConfirmFrame.Size = UDim2.new(0, 400, 0, 170)
ReportConfirmFrame.Position = UDim2.new(0.5, -200, 0.5, -80)
ReportConfirmFrame.BackgroundTransparency = 0.7
ReportConfirmFrame.BackgroundColor3 = Color3.new(0, 0, 0)
ReportConfirmFrame.Style = Enum.FrameStyle.DropShadow

local ReportConfirmHeader = Instance.new('TextLabel')
ReportConfirmHeader.Name = "ReportConfirmHeader"
ReportConfirmHeader.Size = UDim2.new(0, 0, 0, 0)
ReportConfirmHeader.Position = UDim2.new(0.5, 0, 0, 14)
ReportConfirmHeader.BackgroundTransparency = 1
ReportConfirmHeader.Text = "Thank you for your Report"
ReportConfirmHeader.Font = Enum.Font.SourceSans
ReportConfirmHeader.FontSize = Enum.FontSize.Size36
ReportConfirmHeader.TextColor3 = Color3.new(1, 1, 1)
ReportConfirmHeader.Parent = ReportConfirmFrame

local ReportConfirmText = Instance.new('TextLabel')
ReportConfirmText.Name = "ReportConfirmText"
ReportConfirmText.Text = "Our moderators will review your report and the chat log to determine what happened."
ReportConfirmText.Size = UDim2.new(1, -20, 0, 40)
ReportConfirmText.Position = UDim2.new(0, 10, 0, 46)
ReportConfirmText.BackgroundTransparency = 1
ReportConfirmText.Font = Enum.Font.SourceSans
ReportConfirmText.FontSize = Enum.FontSize.Size18
ReportConfirmText.TextColor3 = Color3.new(1, 1, 1)
ReportConfirmText.TextWrap = true
ReportConfirmText.TextXAlignment = Enum.TextXAlignment.Left
ReportConfirmText.TextYAlignment = Enum.TextYAlignment.Top
ReportConfirmText.Parent = ReportConfirmFrame

local ReportConfirmButton = Instance.new('TextButton')
ReportConfirmButton.Name = "ReportConfirmButton"
ReportConfirmButton.Text = "OK"
ReportConfirmButton.Size = UDim2.new(0, 168, 0, 50)
ReportConfirmButton.Position = UDim2.new(0.5, -81, 1, -60)
ReportConfirmButton.Font = Enum.Font.SourceSans
ReportConfirmButton.FontSize = Enum.FontSize.Size24
ReportConfirmButton.TextColor3 = Color3.new(1, 1, 1)
ReportConfirmButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
ReportConfirmButton.Parent = ReportConfirmFrame

local function onReportConfirmPressed()
	ReportConfirmFrame.Parent = nil
	ReportAbuseShield.Parent = nil
	ReportAbuseFrame.Parent = ReportAbuseShield
end
ReportConfirmButton.MouseButton1Click:connect(onReportConfirmPressed)

--[[ Creation Helper Functions ]]--
local function createEntryFrame(name, sizeYOffset)
	local containerFrame = Instance.new('Frame')
	containerFrame.Name = name
	containerFrame.Position = UDim2.new(0, 0, 0, 0)
	containerFrame.Size = UDim2.new(1, 0, 0, sizeYOffset)
	containerFrame.BackgroundTransparency = 1

	local nameFrame = Instance.new('TextButton')
	nameFrame.Name = "BGFrame"
	nameFrame.Position = UDim2.new(0, 0, 0, 0)
	nameFrame.Size = UDim2.new(0, NameEntrySizeX, 0, sizeYOffset)
	nameFrame.BackgroundTransparency = BG_TRANSPARENCY
	nameFrame.BackgroundColor3 = BG_COLOR
	nameFrame.BorderSizePixel = 0
	nameFrame.ClipsDescendants = true
	nameFrame.AutoButtonColor = false
	nameFrame.Text = ""
	nameFrame.Parent = containerFrame

	return containerFrame, nameFrame
end

local function createEntryNameText(name, text, sizeXOffset, posXOffset)
	local nameLabel = Instance.new('TextLabel')
	nameLabel.Name = name
	nameLabel.Size = UDim2.new(-0.01, sizeXOffset, 0.5, 0)
	nameLabel.Position = UDim2.new(0.01, posXOffset, 0.245, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.SourceSans
	nameLabel.FontSize = Enum.FontSize.Size14
	nameLabel.TextColor3 = TEXT_COLOR
	nameLabel.TextStrokeTransparency = TEXT_STROKE_TRANSPARENCY
	nameLabel.TextStrokeColor3 = TEXT_STROKE_COLOR
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = text

	return nameLabel
end

local function createStatFrame(offset, parent, name)
	local statFrame = Instance.new('Frame')
	statFrame.Name = name
	statFrame.Size = UDim2.new(0, StatEntrySizeX, 1, 0)
	statFrame.Position = UDim2.new(0, offset + 2, 0, 0)
	statFrame.BackgroundTransparency = BG_TRANSPARENCY
	statFrame.BackgroundColor3 = BG_COLOR
	statFrame.BorderSizePixel = 0
	statFrame.Parent = parent

	return statFrame
end

local function createStatText(parent, text)
	local statText = Instance.new('TextLabel')
	statText.Name = "StatText"
	statText.Size = UDim2.new(1, 0, 1, 0)
	statText.Position = UDim2.new(0, 0, 0, 0)
	statText.BackgroundTransparency = 1
	statText.Font = Enum.Font.SourceSans
	statText.FontSize = Enum.FontSize.Size14
	statText.TextColor3 = TEXT_COLOR
	statText.TextStrokeColor3 = TEXT_STROKE_COLOR
	statText.TextStrokeTransparency = TEXT_STROKE_TRANSPARENCY
	statText.Text = text
	statText.Active = true
	statText.Parent = parent

	return statText
end

local function createImageIcon(image, name, xOffset, parent)
	local imageLabel = Instance.new('ImageLabel')
	imageLabel.Name = name
	imageLabel.Size = UDim2.new(0, 16, 0, 16)
	imageLabel.Position = UDim2.new(0.01, xOffset, 0.5, -imageLabel.Size.Y.Offset/2)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = image
	imageLabel.BorderSizePixel = 0
	imageLabel.Parent = parent

	return imageLabel
end

local function getScoreValue(statObject)
	if statObject:IsA('DoubleConstrainedValue') or statObject:IsA('IntConstrainedValue') then
		return statObject.ConstrainedValue
	elseif statObject:IsA('BoolValue') then
		if statObject.Value then return 1 else return 0 end
	else
		return statObject.Value
	end
end

local THIN_CHARS = "[^%[iIl\%.,']"
local function strWidth(str)
	return string.len(str) - math.floor(string.len(string.gsub(str, THIN_CHARS, "")) / 2)
end

local function formatNumber(value)
	local _,_,minusSign, int, fraction = tostring(value):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("%d%d%d", "%1,")
	return minusSign..int:reverse():gsub("^,", "")..fraction
end

local function formatStatString(text)
	local numberValue = tonumber(text)
	if numberValue then
		text = formatNumber(numberValue)
	end

	if strWidth(text) <= MAX_STR_LEN then
		return text
	else
		return string.sub(text, 1, MAX_STR_LEN - 3).."..."
	end
end

--[[ Resize Functions ]]--
local LastMaxScrollSize = 0
local function setScrollListSize()
	local teamSize = #TeamEntries * TeamEntrySizeY
	local playerSize = #PlayerEntries * PlayerEntrySizeY
	local spacing = #PlayerEntries * ENTRY_PAD + #TeamEntries * ENTRY_PAD
	local canvasSize = teamSize + playerSize + spacing
	if #TeamEntries > 0 and NeutralTeam and IsShowingNeutralFrame then
		canvasSize = canvasSize + TeamEntrySizeY + ENTRY_PAD
	end
	ScrollList.CanvasSize = UDim2.new(0, 0, 0, canvasSize)
	local newScrollListSize = math.min(canvasSize, Container.AbsoluteSize.y)
	if ScrollList.Size.Y.Offset == LastMaxScrollSize then
		ScrollList.Size = UDim2.new(1, 0, 0, newScrollListSize)
	end
	LastMaxScrollSize = newScrollListSize
end

--[[ Re-position Functions ]]--
local function setPlayerEntryPositions()
	local position = 0
	for i = 1, #PlayerEntries do
		PlayerEntries[i].Frame.Position = UDim2.new(0, 0, 0, position)
		position = position + PlayerEntrySizeY + 2
	end
end

local function setTeamEntryPositions()
	local teams = {}
	for _,teamEntry in ipairs(TeamEntries) do
		local team = teamEntry.Team
		teams[tostring(team.TeamColor)] = {}
	end
	if NeutralTeam then
		teams.Neutral = {}
	end

	for _,playerEntry in ipairs(PlayerEntries) do
		local player = playerEntry.Player
		if player.Neutral then
			table.insert(teams.Neutral, playerEntry)
		elseif teams[tostring(player.TeamColor)] then
			table.insert(teams[tostring(player.TeamColor)], playerEntry)
		else
			table.insert(teams.Neutral, playerEntry)
		end
	end

	local position = 0
	for _,teamEntry in ipairs(TeamEntries) do
		local team = teamEntry.Team
		teamEntry.Frame.Position = UDim2.new(0, 0, 0, position)
		position = position + TeamEntrySizeY + 2
		local players = teams[tostring(team.TeamColor)]
		for _,playerEntry in ipairs(players) do
			playerEntry.Frame.Position = UDim2.new(0, 0, 0, position)
			position = position + PlayerEntrySizeY + 2
		end
	end
	if NeutralTeam then
		NeutralTeam.Frame.Position = UDim2.new(0, 0, 0, position)
		position = position + TeamEntrySizeY + 2
		if #teams.Neutral > 0 then
			IsShowingNeutralFrame = true
			local players = teams.Neutral
			for _,playerEntry in ipairs(players) do
				playerEntry.Frame.Position = UDim2.new(0, 0, 0, position)
				position = position + PlayerEntrySizeY + 2
			end
		else
			IsShowingNeutralFrame = false
		end
	end
end

local function setEntryPositions()
	table.sort(PlayerEntries, sortPlayerEntries)
	if #TeamEntries > 0 then
		setTeamEntryPositions()
	else
		setPlayerEntryPositions()
	end
end

--[[ Friend/Report Functions ]]--
local selectedEntryMovedCn = nil
local function createPopupFrame(buttons)
	local frame = Instance.new('Frame')
	frame.Name = "PopupFrame"
	frame.Size = UDim2.new(1, 0, 0, (PlayerEntrySizeY * #buttons) + (#buttons - ENTRY_PAD))
	frame.Position = UDim2.new(1, 1, 0, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = PopupClipFrame

	for i,button in ipairs(buttons) do
		local btn = Instance.new('TextButton')
		btn.Name = button.Name
		btn.Size = UDim2.new(1, 0, 0, PlayerEntrySizeY)
		btn.Position = UDim2.new(0, 0, 0, PlayerEntrySizeY * (i - 1) + ((i - 1) * ENTRY_PAD))
		btn.BackgroundTransparency = BG_TRANSPARENCY
		btn.BackgroundColor3 = BG_COLOR
		btn.BorderSizePixel = 0
		btn.Text = button.Text
		btn.Font = Enum.Font.SourceSans
		btn.FontSize = Enum.FontSize.Size14
		btn.TextColor3 = TEXT_COLOR
		btn.TextStrokeTransparency = TEXT_STROKE_TRANSPARENCY
		btn.TextStrokeColor3 = TEXT_STROKE_COLOR
		btn.AutoButtonColor = true
		btn.Parent = frame

		btn.MouseButton1Click:connect(button.OnPress)
	end

	return frame
end

-- if userId = nil, then it will get count for local player
local function getFriendCountAsync(userId)
	local friendCount = nil
	local wasSuccess, result = pcall(function()
		local str = 'user/get-friendship-count'
		if userId then
			str = str..'?userId='..tostring(userId)
		end
		if not HttpRbxApiService then error('HttpRbxApiService unavailable') end
		return HttpRbxApiService:GetAsync(str, true)
	end)
	if not wasSuccess then
		print("getFriendCountAsync() failed because", result)
		return nil
	end
	result = HttpService:JSONDecode(result)

	if result["success"] and result["count"] then
		friendCount = result["count"]
	end

	return friendCount
end

-- checks if we can send a friend request. Right now the only way we
-- can't is if one of the players is at the max friend limit
local function canSendFriendRequestAsync(otherPlayer)
	local theirFriendCount = getFriendCountAsync(otherPlayer.userId)
	local myFriendCount = getFriendCountAsync()

	-- assume max friends if web call fails
	if not myFriendCount or not theirFriendCount then
		return false
	end
	if myFriendCount < MAX_FRIEND_COUNT and theirFriendCount < MAX_FRIEND_COUNT then
		return true
	elseif myFriendCount >= MAX_FRIEND_COUNT then
		sendNotification("Cannot send friend request", "You are at the max friends limit.", "", 5, function() end)
		return false
	elseif theirFriendCount >= MAX_FRIEND_COUNT then
		sendNotification("Cannot send friend request", otherPlayer.Name.." is at the max friends limit.", "", 5, function() end)
		return false
	end
end

local function hideFriendReportPopup()
	if PopupFrame then
		PopupFrame:TweenPosition(UDim2.new(1, 1, 0, PopupFrame.Position.Y.Offset), Enum.EasingDirection.InOut,
			Enum.EasingStyle.Quad, TWEEN_TIME, true, function()
				PopupFrame:Destroy()
				PopupFrame = nil
				if selectedEntryMovedCn then
					selectedEntryMovedCn:disconnect()
					selectedEntryMovedCn = nil
				end
			end)
	end
	if LastSelectedFrame then
		for _,childFrame in pairs(LastSelectedFrame:GetChildren()) do
			if childFrame:IsA('TextButton') or childFrame:IsA('Frame') then
				childFrame.BackgroundColor3 = BG_COLOR
			end
		end
	end
	ScrollList.ScrollingEnabled = true
	LastSelectedFrame = nil
	LastSelectedPlayer = nil
end

local function updateSocialIcon(newIcon, bgFrame)
	local socialIcon = bgFrame:FindFirstChild('SocialIcon')
	local nameFrame = bgFrame:FindFirstChild('PlayerName')
	local offset = 19
	if socialIcon then
		if newIcon then
			socialIcon.Image = newIcon
		else
			if nameFrame then
				newSize = nameFrame.Size.X.Offset + socialIcon.Size.X.Offset + 2
				nameFrame.Size = UDim2.new(-0.01, newSize, 0.5, 0)
				nameFrame.Position = UDim2.new(0.01, offset, 0.245, 0)
			end
			socialIcon:Destroy()
		end
	elseif newIcon and bgFrame then
		socialIcon = createImageIcon(newIcon, "SocialIcon", offset, bgFrame)
		offset = offset + socialIcon.Size.X.Offset + 2
		if nameFrame then
			local newSize = bgFrame.Size.X.Offset - offset
			nameFrame.Size = UDim2.new(-0.01, newSize, 0.5, 0)
			nameFrame.Position = UDim2.new(0.01, offset, 0.245, 0)
		end
	end
end

local function onFollowerStatusChanged()
	if not LastSelectedFrame or not LastSelectedPlayer then
		return
	end

	-- don't update icon if already friends
	local friendStatus = getFriendStatus(LastSelectedPlayer)
	if friendStatus == Enum.FriendStatus.Friend then
		return
	end

	local bgFrame = LastSelectedFrame:FindFirstChild('BGFrame')
	local followerStatus = getFollowerStatus(LastSelectedPlayer)
	local newIcon = getFollowerStatusIcon(followerStatus)
	if bgFrame then
		updateSocialIcon(newIcon, bgFrame)
	end
end

-- Client follows followedUserId
local function onFollowButtonPressed()
	if not LastSelectedPlayer then return end
	--
	local followedUserId = tostring(LastSelectedPlayer.userId)
	local apiPath = "user/follow"
	local params = "followedUserId="..followedUserId
	local success, result = pcall(function()
		if not HttpRbxApiService then error('HttpRbxApiService unavailable') end
		return HttpRbxApiService:PostAsync(apiPath, params, true, Enum.ThrottlingPriority.Default, Enum.HttpContentType.ApplicationUrlEncoded)
	end)
	if not success then
		print("followPlayer() failed because", result)
		hideFriendReportPopup()
		return
	end

	result = HttpService:JSONDecode(result)
	if result["success"] then
		sendNotification("You are", "now following "..LastSelectedPlayer.Name, FRIEND_IMAGE..followedUserId.."&x=48&y=48", 5, function() end)
		if RemoteEvent_OnNewFollower then
			RemoteEvent_OnNewFollower:FireServer(LastSelectedPlayer)
		end
		-- now update the social icon
		onFollowerStatusChanged()
	end

	hideFriendReportPopup()
end

-- TODO: Move this to the notifications script. For now I want to keep it here until the
-- new notifications system goes live
if IsServerCoreScripts then
	-- don't block the rest of the core gui
	spawn(function()
		RobloxReplicatedStorage = game:GetService('RobloxReplicatedStorage')
		RemoteEvent_OnNewFollower = RobloxReplicatedStorage:WaitForChild('OnNewFollower')
		--
		RemoteEvent_OnNewFollower.OnClientEvent:connect(function(followerRbxPlayer)
			sendNotification("New Follower", followerRbxPlayer.Name.."is now following you!",
				FRIEND_IMAGE..followerRbxPlayer.userId.."&x=48&y=48", 5, function() end)
		end)
	end)
end

-- Client unfollows followedUserId
local function onUnfollowButtonPressed()
	if not LastSelectedPlayer then return end
	--
	local apiPath = "user/unfollow"
	local params = "followedUserId="..tostring(LastSelectedPlayer.userId)
	local success, result = pcall(function()
		if not HttpRbxApiService then error('HttpRbxApiService unavailable') end
		return HttpRbxApiService:PostAsync(apiPath, params, true, Enum.ThrottlingPriority.Default, Enum.HttpContentType.ApplicationUrlEncoded)
	end)
	if not success then
		print("unfollowPlayer() failed because", result)
		hideFriendReportPopup()
		return
	end

	result = HttpService:JSONDecode(result)
	if result["success"] then
		onFollowerStatusChanged()
	end

	hideFriendReportPopup()
	-- no need to send notification when someone unfollows
end

local function onFriendButtonPressed()
	if LastSelectedPlayer then
		local status = getFriendStatus(LastSelectedPlayer)
		if status == Enum.FriendStatus.Friend then
			Player:RevokeFriendship(LastSelectedPlayer)
		elseif status == Enum.FriendStatus.Unknown or status == Enum.FriendStatus.NotFriend then
			-- cache and spawn
			local cachedLastSelectedPlayer = LastSelectedPlayer
			spawn(function()
				-- check for max friends before letting them send the request
				if canSendFriendRequestAsync(cachedLastSelectedPlayer) then 	-- Yields
					if cachedLastSelectedPlayer and cachedLastSelectedPlayer.Parent == Players then
						Player:RequestFriendship(cachedLastSelectedPlayer)
					end
				end
			end)
		elseif status == Enum.FriendStatus.FriendRequestSent then
			Player:RevokeFriendship(LastSelectedPlayer)
		elseif status == Enum.FriendStatus.FriendRequestReceived then
			Player:RequestFriendship(LastSelectedPlayer)
		end

		hideFriendReportPopup()
	end
end

local function onReportButtonPressed()
	if LastSelectedPlayer then
		AbusingPlayer = LastSelectedPlayer
		ReportPlayerName.Text = AbusingPlayer.Name
		ReportAbuseShield.Parent = RobloxGui
		hideFriendReportPopup()
	end
end

local function resetReportDialog()
	AbuseReason = nil
	AbusingPlayer = nil
	if IsNewSettings and AbuseDropDown then 	-- FFlag
		AbuseDropDown.SetSelectionText("Choose One")
		if AbuseDropDown.IsOpen() then
			AbuseDropDown.Reset()
		end
	elseif updateAbuseSelection then
		-- GUI2Lua compatibility: the legacy dropdown constructor is commented out
		-- in this recreation, so updateAbuseSelection can legitimately be nil.
		pcall(function() updateAbuseSelection(nil) end)
	end
	ReportPlayerName.Text = ""
	ReportDescriptionBox.Text = ""
	ReportSubmitButton.Active = false
	ReportSubmitButton.TextColor3 = Color3.new(163/255, 162/255, 165/255)
end

local function onAbuseDialogCanceled()
	resetReportDialog()
	ReportAbuseShield.Parent = nil
end
ReportCanelButton.MouseButton1Click:connect(onAbuseDialogCanceled)

local function onAbuseDialogSubmit()
	if ReportSubmitButton.Active then
		if AbuseReason and AbusingPlayer then
			local success, errorMsg = pcall(function()
				Players:ReportAbuse(AbusingPlayer, AbuseReason, ReportDescriptionBox.Text)
			end)
			if not success then
				print("PlayerlistModule: Players:ReportAbuse() failed because", errorMsg)
			end
			resetReportDialog()
			ReportAbuseFrame.Parent = nil
			ReportConfirmFrame.Parent = ReportAbuseShield
		end
	end
end
ReportSubmitButton.MouseButton1Click:connect(onAbuseDialogSubmit)

local function onDeclineFriendButonPressed()
	if LastSelectedPlayer then
		Player:RevokeFriendship(LastSelectedPlayer)
		hideFriendReportPopup()
	end
end

local function onPrivilegeLevelSelect(player, rank)
	while player.PersonalServerRank < rank do
		PersonalServerService:Promote(player)
	end
	while player.PersonalServerRank > rank do
		PersonalServerService:Demote(player)
	end
end

local function createPersonalServerDialog(buttons, selectedPlayer)
	local showPersonalServerRanks = IsPersonalServer and Player.PersonalServerRank >= PRIVILEGE_LEVEL.ADMIN and
		Player.PersonalServerRank > selectedPlayer.PersonalServerRank
	if showPersonalServerRanks then
		table.insert(buttons, {
			Name = "BanButton",
			Text = "Ban",
			OnPress = function()
				hideFriendReportPopup()
				onPrivilegeLevelSelect(selectedPlayer, PRIVILEGE_LEVEL.BANNED)
			end,
		})
		table.insert(buttons, {
			Name = "VistorButton",
			Text = "Visitor",
			OnPress = function()
				onPrivilegeLevelSelect(selectedPlayer, PRIVILEGE_LEVEL.VISITOR)
			end,
		})
		table.insert(buttons, {
			Name = "MemberButton",
			Text = "Member",
			OnPress = function()
				onPrivilegeLevelSelect(selectedPlayer, PRIVILEGE_LEVEL.MEMBER)
			end,
		})
		table.insert(buttons, {
			Name = "AdminButton",
			Text = "Admin",
			OnPress = function()
				onPrivilegeLevelSelect(selectedPlayer, PRIVILEGE_LEVEL.ADMIN)
			end,
		})
	end
end

local function showFriendReportPopup(selectedFrame, selectedPlayer)
	local buttons = {}

	local status = getFriendStatus(selectedPlayer)
	local friendText = ""
	local canDeclineFriend = false
	if status == Enum.FriendStatus.Friend then
		friendText = "Unfriend Player"
	elseif status == Enum.FriendStatus.Unknown or status == Enum.FriendStatus.NotFriend then
		friendText = "Send Friend Request"
	elseif status == Enum.FriendStatus.FriendRequestSent then
		friendText = "Revoke Friend Request"
	elseif status == Enum.FriendStatus.FriendRequestReceived then
		friendText = "Accept Friend Request"
		canDeclineFriend = true
	end

	table.insert(buttons, {
		Name = "FriendButton",
		Text = friendText,
		OnPress = onFriendButtonPressed,
	})
	if canDeclineFriend then
		table.insert(buttons, {
			Name = "DeclineFriend",
			Text = "Decline Friend Request",
			OnPress = onDeclineFriendButonPressed,
		})
	end
	-- following status
	local following = isFollowing(selectedPlayer.userId, Player.userId)
	local followerText = following and "Unfollow Player" or "Follow Player"
	table.insert(buttons, {
		Name = "FollowerButton",
		Text = followerText,
		OnPress = following and onUnfollowButtonPressed or onFollowButtonPressed,
	})
	table.insert(buttons, {
		Name = "ReportButton",
		Text = "Report Abuse",
		OnPress = onReportButtonPressed,
	})

	createPersonalServerDialog(buttons, selectedPlayer)
	if PopupFrame then
		PopupFrame:Destroy()
		if selectedEntryMovedCn then
			selectedEntryMovedCn:disconnect()
			selectedEntryMovedCn = nil
		end
	end
	PopupFrame = createPopupFrame(buttons)
	PopupFrame.Position = UDim2.new(1, 1, 0, selectedFrame.Position.Y.Offset - ScrollList.CanvasPosition.y)
	PopupFrame:TweenPosition(UDim2.new(0, 0, 0, selectedFrame.Position.Y.Offset - ScrollList.CanvasPosition.y), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, TWEEN_TIME, true)
	selectedEntryMovedCn = selectedFrame.Changed:connect(function(property)
		if property == "Position" then
			PopupFrame.Position = UDim2.new(0, 0, 0, selectedFrame.Position.Y.Offset - ScrollList.CanvasPosition.y)
		end
	end)
end

local function onEntryFrameSelected(selectedFrame, selectedPlayer)
	if selectedPlayer ~= Player and selectedPlayer.userId > 1 and Player.userId > 1 then
		if LastSelectedFrame ~= selectedFrame then
			if LastSelectedFrame then
				for _,childFrame in pairs(LastSelectedFrame:GetChildren()) do
					if childFrame:IsA('TextButton') or childFrame:IsA('Frame') then
						childFrame.BackgroundColor3 = BG_COLOR
					end
				end
			end
			LastSelectedFrame = selectedFrame
			LastSelectedPlayer = selectedPlayer
			for _,childFrame in pairs(selectedFrame:GetChildren()) do
				if childFrame:IsA('TextButton') or childFrame:IsA('Frame') then
					childFrame.BackgroundColor3 = Color3.new(0, 1, 1)
				end
			end
			-- NOTE: Core script only
			ScrollList.ScrollingEnabled = false
			showFriendReportPopup(selectedFrame, selectedPlayer)
		else
			hideFriendReportPopup()
			LastSelectedFrame = nil
			LastSelectedPlayer = nil
		end
	end
end

local function onFriendshipChanged(otherPlayer, newFriendStatus)
	local entryToUpdate = nil
	for _,entry in ipairs(PlayerEntries) do
		if entry.Player == otherPlayer then
			entryToUpdate = entry
			break
		end
	end
	if not entryToUpdate then
		return
	end
	local newIcon = getFriendStatusIcon(newFriendStatus)
	local frame = entryToUpdate.Frame
	local bgFrame = frame:FindFirstChild('BGFrame')
	if bgFrame then
		-- no longer friends, but might still be following
		if not newIcon then
			local followerStatus = getFollowerStatus(otherPlayer)
			newIcon = getFollowerStatusIcon(followerStatus)
		end

		updateSocialIcon(newIcon, bgFrame)
	end
end

-- NOTE: Core script only. This fires when a layer joins the game.
--Player.FriendStatusChanged:connect(onFriendshipChanged)

local function updateAllTeamScores()
	local teamScores = {}
	for _,playerEntry in ipairs(PlayerEntries) do
		local player = playerEntry.Player
		local leaderstats = player:FindFirstChild('leaderstats')
		local team = player.Neutral and 'Neutral' or tostring(player.TeamColor)
		local isInValidColor = true
		if team ~= 'Neutral' then
			for _,teamEntry in ipairs(TeamEntries) do
				local color = teamEntry.Team.TeamColor
				if team == tostring(color) then
					isInValidColor = false
					break
				end
			end
		end
		if isInValidColor then
			team = 'Neutral'
		end
		if not teamScores[team] then
			teamScores[team] = {}
		end
		if leaderstats then
			for _,stat in ipairs(GameStats) do
				local statObject = leaderstats:FindFirstChild(stat.Name)
				if statObject and not statObject:IsA('StringValue') then
					if not teamScores[team][stat.Name] then
						teamScores[team][stat.Name] = 0
					end
					teamScores[team][stat.Name] = teamScores[team][stat.Name] + getScoreValue(statObject)
				end
			end
		end
	end

	for _,teamEntry in ipairs(TeamEntries) do
		local team = teamEntry.Team
		local frame = teamEntry.Frame
		local color = tostring(team.TeamColor)
		local stats = teamScores[color]
		if stats then
			for statName,statValue in pairs(stats) do
				local statFrame = frame:FindFirstChild(statName)
				if statFrame then
					local statText = statFrame:FindFirstChild('StatText')
					if statText then
						statText.Text = formatStatString(tostring(statValue))
					end
				end
			end
		else
			for _,childFrame in pairs(frame:GetChildren()) do
				local statText = childFrame:FindFirstChild('StatText')
				if statText then
					statText.Text = ''
				end
			end
		end
	end
	if NeutralTeam then
		local frame = NeutralTeam.Frame
		local stats = teamScores['Neutral']
		if stats then
			for statName,statValue in pairs(stats) do
				local statFrame = frame:FindFirstChild(statName)
				if statFrame then
					local statText = statFrame:FindFirstChild('StatText')
					if statText then
						statText.Text = formatStatString(tostring(statValue))
					end
				end
			end
		end
	end
end

local function updateTeamEntry(entry)
	local frame = entry.Frame
	local team = entry.Team
	local color = team.TeamColor.Color
	local offset = NameEntrySizeX
	for _,stat in ipairs(GameStats) do
		local statFrame = frame:FindFirstChild(stat.Name)
		if not statFrame then
			statFrame = createStatFrame(offset, frame, stat.Name)
			statFrame.BackgroundColor3 = color
			createStatText(statFrame, "")
		end
		statFrame.Position = UDim2.new(0, offset + 2, 0, 0)
		offset = offset + statFrame.Size.X.Offset + 2
	end
end

local function updatePrimaryStats(statName)
	for _,entry in ipairs(PlayerEntries) do
		local player = entry.Player
		local leaderstats = player:FindFirstChild('leaderstats')
		entry.PrimaryStat = nil
		if leaderstats then
			local statObject = leaderstats:FindFirstChild(statName)
			if statObject then
				local scoreValue = getScoreValue(statObject)
				entry.PrimaryStat = scoreValue
			end
		end
	end
end

local updateLeaderstatFrames = nil
-- TODO: fire event to top bar?
local function initializeStatText(stat, statObject, entry, statFrame, index)
	local player = entry.Player
	local statValue = getScoreValue(statObject)
	if statObject.Name == GameStats[1].Name then
		entry.PrimaryStat = statValue
	end
	local statText = createStatText(statFrame, formatStatString(tostring(statValue)))
	-- Top Bar insertion
	if player == Player then
		stat.Text = statText.Text
	end

	statObject.Changed:connect(function(newValue)
		local scoreValue = getScoreValue(statObject)
		statText.Text = formatStatString(tostring(scoreValue))
		if statObject.Name == GameStats[1].Name then
			entry.PrimaryStat = scoreValue
		end
		-- Top bar changed event
		if player == Player then
			stat.Text = statText.Text
			Playerlist.OnStatChanged:Fire(stat.Name, stat.Text)
		end
		updateAllTeamScores()
		setEntryPositions()
	end)
	statObject.ChildAdded:connect(function(child)
		if child.Name == "IsPrimary" then
			GameStats[1].IsPrimary = false
			stat.IsPrimary = true
			updatePrimaryStats(stat.Name)
			if updateLeaderstatFrames then updateLeaderstatFrames() end
			Playerlist.OnLeaderstatsChanged:Fire(GameStats)
		end
	end)
end

updateLeaderstatFrames = function()
	table.sort(GameStats, sortLeaderStats)
	if #TeamEntries > 0 then
		for _,entry in ipairs(TeamEntries) do
			updateTeamEntry(entry)
		end
		if NeutralTeam then
			updateTeamEntry(NeutralTeam)
		end
	end

	for _,entry in ipairs(PlayerEntries) do
		local player = entry.Player
		local mainFrame = entry.Frame
		local offset = NameEntrySizeX
		local leaderstats = player:FindFirstChild('leaderstats')

		if leaderstats then
			for _,stat in ipairs(GameStats) do
				local statObject = leaderstats:FindFirstChild(stat.Name)
				local statFrame = mainFrame:FindFirstChild(stat.Name)

				if not statFrame then
					statFrame = createStatFrame(offset, mainFrame, stat.Name)
					if statObject then
						initializeStatText(stat, statObject, entry, statFrame, _)
					end
				elseif statObject then
					local statText = statFrame:FindFirstChild('StatText')
					if not statText then
						initializeStatText(stat, statObject, entry, statFrame, _)
					end
				end
				statFrame.Position = UDim2.new(0, offset + 2, 0, 0)
				offset = offset + statFrame.Size.X.Offset + 2
			end
		else
			for _,stat in ipairs(GameStats) do
				local statFrame = mainFrame:FindFirstChild(stat.Name)
				if not statFrame then
					statFrame = createStatFrame(offset, mainFrame, stat.Name)
				end
				offset = offset + statFrame.Size.X.Offset + 2
			end
		end
		Container.Position = UDim2.new(1, -offset, 0, 38)
		Container.Size = UDim2.new(0, offset, 0.5, 0)
		local newMinContainerOffset = offset
		MinContainerSize = UDim2.new(0, newMinContainerOffset, 0.5, 0)
	end
	updateAllTeamScores()
	setEntryPositions()
	Playerlist.OnLeaderstatsChanged:Fire(GameStats)
end

local function addNewStats(leaderstats)
	for i,stat in ipairs(leaderstats:GetChildren()) do
		if isValidStat(stat) and #GameStats < MAX_LEADERSTATS then
			local gameHasStat = false
			for _,gStat in ipairs(GameStats) do
				if stat.Name == gStat.Name then
					gameHasStat = true
					break
				end
			end

			if not gameHasStat then
				local newStat = {}
				newStat.Name = stat.Name
				newStat.Text = "-"
				newStat.Priority = 0
				local priority = stat:FindFirstChild('Priority')
				if priority then newStat.Priority = priority end
				newStat.IsPrimary = false
				local isPrimary = stat:FindFirstChild('IsPrimary')
				if isPrimary then
					newStat.IsPrimary = true
				end
				newStat.AddId = StatAddId
				StatAddId = StatAddId + 1
				table.insert(GameStats, newStat)
				table.sort(GameStats, sortLeaderStats)
				if #GameStats == 1 then
					setScrollListSize()
					setEntryPositions()
				end
			end
		end
	end
end

local function removeStatFrameFromEntry(stat, frame)
	local statFrame = frame:FindFirstChild(stat.Name)
	if statFrame then
		statFrame:Destroy()
	end
end

local function doesStatExists(stat)
	local doesExists = false
	for _,entry in ipairs(PlayerEntries) do
		local player = entry.Player
		if player then
			local leaderstats = player:FindFirstChild('leaderstats')
			if leaderstats and leaderstats:FindFirstChild(stat.Name) then
				doesExists = true
				break
			end
		end
	end

	return doesExists
end

local function onStatRemoved(oldStat, entry)
	if isValidStat(oldStat) then
		removeStatFrameFromEntry(oldStat, entry.Frame)
		local statExists = doesStatExists(oldStat)
		--
		local toRemove = nil
		for i, stat in ipairs(GameStats) do
			if stat.Name == oldStat.Name then
				toRemove = i
				break
			end
		end
		-- removed from player but not from game; another player still has this stat
		if statExists then
			if toRemove and entry.Player == Player then
				GameStats[toRemove].Text = "-"
				Playerlist.OnStatChanged:Fire(GameStats[toRemove].Name, GameStats[toRemove].Text)
			end
			-- removed from game
		else
			for _,playerEntry in ipairs(PlayerEntries) do
				removeStatFrameFromEntry(oldStat, playerEntry.Frame)
			end
			for _,teamEntry in ipairs(TeamEntries) do
				removeStatFrameFromEntry(oldStat, teamEntry.Frame)
			end
			if toRemove then
				table.remove(GameStats, toRemove)
				table.sort(GameStats, sortLeaderStats)
			end
		end
		if GameStats[1] then
			updatePrimaryStats(GameStats[1].Name)
		end
		updateLeaderstatFrames()
	end
end

local function onStatAdded(leaderstats, entry)
	leaderstats.ChildAdded:connect(function(newStat)
		if isValidStat(newStat) then
			addNewStats(newStat.Parent)
			updateLeaderstatFrames()
		end
	end)
	leaderstats.ChildRemoved:connect(function(child)
		onStatRemoved(child, entry)
	end)
	addNewStats(leaderstats)
	updateLeaderstatFrames()
end

local function setLeaderStats(entry)
	local player = entry.Player
	local leaderstats = player:FindFirstChild('leaderstats')

	if leaderstats then
		onStatAdded(leaderstats, entry)
	end

	local function onPlayerChildChanged(property, child)
		if property == 'Name' and child.Name == 'leaderstats' then
			onStatAdded(child, entry)
		end
	end

	player.ChildAdded:connect(function(child)
		if child.Name == 'leaderstats' then
			onStatAdded(child, entry)
		end
		child.Changed:connect(function(property) onPlayerChildChanged(property, child) end)
	end)
	for _,child in pairs(player:GetChildren()) do
		child.Changed:connect(function(property) onPlayerChildChanged(property, child) end)
	end

	player.ChildRemoved:connect(function(child)
		if child.Name == 'leaderstats' then
			for i,stat in ipairs(child:GetChildren()) do
				onStatRemoved(stat, entry)
			end
			updateLeaderstatFrames()
		end
	end)
end
local function createPlayerEntry(player)
	local playerEntry = {}
	local name = player.Name

	local containerFrame, entryFrame = createEntryFrame(name, PlayerEntrySizeY)
	entryFrame.Active = true
	local function localEntrySelected()
		onEntryFrameSelected(containerFrame, player)
	end
	entryFrame.MouseButton1Click:connect(localEntrySelected)

	local currentXOffset = 1

	-- check membership
	local membershipIconImage = getMembershipIcon(player)
	local membershipIcon = nil
	if membershipIconImage then
		membershipIcon = createImageIcon(membershipIconImage, "MembershipIcon", currentXOffset, entryFrame)
		currentXOffset = currentXOffset + membershipIcon.Size.X.Offset + 2
	else
		currentXOffset = currentXOffset + 18
	end

	-- Some functions yield, so we need to spawn off in order to not cause a race condition with other events like Players.ChildRemoved
	spawn(function()
		local success, result = pcall(function()
			return player:GetRankInGroup(game.CreatorId) == 255
		end)
		if success then
			if game.CreatorType == Enum.CreatorType.Group and result then
				membershipIconImage = PLACE_OWNER_ICON
				if not membershipIcon then
					membershipIcon = createImageIcon(membershipIconImage, "MembershipIcon", 1, entryFrame)
				else
					membershipIcon.Image = membershipIconImage
				end
			end
		else
			print("PlayerList: GetRankInGroup failed because", result)
		end
		local adminIconImage = getAdminIcon(player)
		if adminIconImage then
			if not membershipIcon then
				membershipIcon = createImageIcon(adminIconImage, "MembershipIcon", 1, entryFrame)
			else
				membershipIcon.Image = adminIconImage
			end
		end
		-- Friendship and Follower status is checked by onFriendshipChanged, which is called by the FriendStatusChanged
		-- event. This event is fired when any player joins the game. onFriendshipChanged will check Follower status in
		-- the case that we are not friends with the new player who is joining.
	end)

	local playerNameXSize = entryFrame.Size.X.Offset - currentXOffset
	local playerName = createEntryNameText("PlayerName", name, playerNameXSize, currentXOffset)
	playerName.Parent = entryFrame
	playerEntry.Player = player
	playerEntry.Frame = containerFrame

	return playerEntry
end

local function createTeamEntry(team)
	local teamEntry = {}
	teamEntry.Team = team
	teamEntry.TeamScore = 0

	local containerFrame, entryFrame = createEntryFrame(team.Name, TeamEntrySizeY)
	entryFrame.BackgroundColor3 = team.TeamColor.Color

	local teamName = createEntryNameText("TeamName", team.Name, entryFrame.AbsoluteSize.x, 1)
	teamName.Parent = entryFrame

	teamEntry.Frame = containerFrame

	-- connections
	team.Changed:connect(function(property)
		if property == 'Name' then
			teamName.Text = team.Name
		elseif property == 'TeamColor' then
			for _,childFrame in pairs(containerFrame:GetChildren()) do
				if childFrame:IsA('Frame') then
					childFrame.BackgroundColor3 = team.TeamColor.Color
				end
			end
		end
	end)

	return teamEntry
end

local function createNeutralTeam()
	if not NeutralTeam then
		local team = Instance.new('Team')
		team.Name = 'Neutral'
		team.TeamColor = BrickColor.new('White')
		NeutralTeam = createTeamEntry(team)
		NeutralTeam.Frame.Parent = ScrollList
	end
end

--[[ Insert/Remove Player Functions ]]--
local function insertPlayerEntry(player)
	local entry = createPlayerEntry(player)
	if player == Player then
		MyPlayerEntry = entry.Frame
	end
	setLeaderStats(entry)
	table.insert(PlayerEntries, entry)
	setScrollListSize()
	updateLeaderstatFrames()
	entry.Frame.Parent = ScrollList

	player.Changed:connect(function(property)
		if #TeamEntries > 0 and (property == 'Neutral' or property == 'TeamColor') then
			setTeamEntryPositions()
			updateAllTeamScores()
			setEntryPositions()
			setScrollListSize()
		end
	end)
end

local function removePlayerEntry(player)
	for i = 1, #PlayerEntries do
		if PlayerEntries[i].Player == player then
			PlayerEntries[i].Frame:Destroy()
			table.remove(PlayerEntries, i)
			break
		end
	end
	setEntryPositions()
	setScrollListSize()
end

--[[ Team Functions ]]--
local function onTeamAdded(team)
	for i = 1, #TeamEntries do
		if TeamEntries[i].Team.TeamColor == team.TeamColor then
			TeamEntries[i].Frame:Destroy()
			table.remove(TeamEntries, i)
			break
		end
	end
	local entry = createTeamEntry(team)
	entry.Id = TeamAddId
	TeamAddId = TeamAddId + 1
	if not NeutralTeam then
		createNeutralTeam()
	end
	table.insert(TeamEntries, entry)
	table.sort(TeamEntries, sortTeams)
	setTeamEntryPositions()
	updateLeaderstatFrames()
	setScrollListSize()
	entry.Frame.Parent = ScrollList
end

local function onTeamRemoved(removedTeam)
	for i = 1, #TeamEntries do
		local team = TeamEntries[i].Team
		if team.Name == removedTeam.Name then
			TeamEntries[i].Frame:Destroy()
			table.remove(TeamEntries, i)
			break
		end
	end
	if #TeamEntries == 0 then
		if NeutralTeam then
			NeutralTeam.Frame:Destroy()
			NeutralTeam.Team:Destroy()
			NeutralTeam = nil
			IsShowingNeutralFrame = false
		end
	end
	setEntryPositions()
	updateLeaderstatFrames()
	setScrollListSize()
end

--[[ Resize/Position Functions ]]--
local function clampCanvasPosition()
	local maxCanvasPosition = ScrollList.CanvasSize.Y.Offset - ScrollList.Size.Y.Offset
	if maxCanvasPosition >= 0 and ScrollList.CanvasPosition.y > maxCanvasPosition then
		ScrollList.CanvasPosition = Vector2.new(0, maxCanvasPosition)
	end
end

local function resizePlayerList()
	setScrollListSize()
	clampCanvasPosition()
end

RobloxGui.Changed:connect(function(property)
	if property == 'AbsoluteSize' then
		spawn(function()	-- must spawn because F11 delays when abs size is set
			resizePlayerList()
		end)
	end
end)

--[[ Input Connections ]]--
UserInputService.InputEnded:connect(function(inputObject)
	if ReportAbuseShield.Parent == RobloxGui then
		if inputObject.KeyCode == Enum.KeyCode.Escape then
			onAbuseDialogCanceled()
		end
	end
end)

UserInputService.InputBegan:connect(function(inputObject, isProcessed)
	if isProcessed then return end
	local inputType = inputObject.UserInputType
	if (inputType == Enum.UserInputType.Touch and  inputObject.UserInputState == Enum.UserInputState.Begin) or
		inputType == Enum.UserInputType.MouseButton1 then
		if LastSelectedFrame then
			hideFriendReportPopup()
		end
	end
end)

ReportAbuseShield.InputBegan:connect(function(inputObject)
	if not IsNewSettings then return end 	-- FFlag
	--
	local inputType = inputObject.UserInputType
	if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
		if AbuseDropDown and AbuseDropDown.IsOpen() then
			AbuseDropDown.Close()
		end
	end
end)

-- NOTE: Core script only

--[[ Player Add/Remove Connections ]]--
Players.ChildAdded:connect(function(child)
	if child:IsA('Player') then
		insertPlayerEntry(child)
	end
end)
for _,player in pairs(Players:GetPlayers()) do
	insertPlayerEntry(player)
end

Players.ChildRemoved:connect(function(child)
	if child:IsA('Player') then
		if LastSelectedPlayer and child == LastSelectedPlayer then
			hideFriendReportPopup()
		end
		removePlayerEntry(child)
	end
end)

--[[ Teams ]]--
local function initializeTeams(teams)
	for _,team in pairs(teams:GetTeams()) do
		onTeamAdded(team)
	end

	teams.ChildAdded:connect(function(team)
		if team:IsA('Team') then
			onTeamAdded(team)
		end
	end)

	teams.ChildRemoved:connect(function(team)
		if team:IsA('Team') then
			onTeamRemoved(team)
		end
	end)
end

TeamsService = game:FindService('Teams')
if TeamsService then
	initializeTeams(TeamsService)
end

game.ChildAdded:connect(function(child)
	if child:IsA('Teams') then
		initializeTeams(child)
	end
end)

--[[ Core Gui Changed events ]]--
-- NOTE: Core script only
local isOpen = true
local function onCoreGuiChanged(coreGuiType, enabled)
	if coreGuiType == Enum.CoreGuiType.All or coreGuiType == Enum.CoreGuiType.PlayerList then
		-- not visible on small screen devices
		if IsSmallScreenDevice then
			Container.Visible = false
			return
		end
		Container.Visible = enabled and isOpen
		-- legacy GuiService AddKey/RemoveKey removed
	end
end
pcall(function()
	onCoreGuiChanged(Enum.CoreGuiType.PlayerList, true)
	--game:GetService("StarterGui").CoreGuiChangedSignal:connect(onCoreGuiChanged)
end)

resizePlayerList()
Container.Visible = not IsSmallScreenDevice

--[[ Public API ]]--
Playerlist.GetStats = function()
	return GameStats
end

local noOpFunc = function ( )
end

local closeListFunc = function(name, state, input)
	if state ~= Enum.UserInputState.Begin then return end

	ContextActionService:UnbindAction("CloseList")
	ContextActionService:UnbindAction("StopAction")
	GuiService.SelectedObject = nil
end

Playerlist.ToggleVisibility = function()
	if IsSmallScreenDevice then return end
	if not true then return end
	isOpen = not isOpen
	Container.Visible = isOpen

	if IsGamepadSupported and UserInputService:GetGamepadConnected(Enum.UserInputType.Gamepad1) then
		if isOpen then
			local children = ScrollList:GetChildren()
			if children and #children > 0 then
				local frame = children[1]
				local frameChildren = frame:GetChildren()
				for i = 1, #frameChildren do
					if frameChildren[i]:IsA("TextButton") then
						GuiService.SelectedObject = frameChildren[i]
						ContextActionService:BindAction("StopAction", noOpFunc, false, Enum.UserInputType.Gamepad1)
						ContextActionService:BindAction("CloseList", closeListFunc, false, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonStart)
						break
					end
				end
			end
		else
			ContextActionService:UnbindAction("CloseList")
			ContextActionService:UnbindAction("StopAction")
			GuiService.SelectedObject = nil
		end
	end
end

Playerlist.IsOpen = function()
	return isOpen
end

game.UserInputService.InputBegan:Connect(function(key, proc)
	if key.KeyCode == Enum.KeyCode.Tab and not proc then
		Playerlist.ToggleVisibility()
	end
end)

-- NOTE: Core script only
--if GuiService then
--GuiService.KeyPressed:connect(function(key)
--	if key == "\t" then
--		Playerlist.ToggleVisibility()
--	end
--end)

--GuiService:AddSelectionParent("PlayerListSelection", Container)
--end

-- Legacy GlobalEvents friendship polling removed.
-- The player list itself does not depend on it.




return Playerlist

end;
};
G2L_MODULES[G2L["b"]] = {
Closure = function()
    local script = G2L["b"];--[[
	// FileName: Chat.lua
	// Written by: SolarCrane
	// Description: Code for lua side chat on ROBLOX.
]]

--[[ CONSTANTS ]]

-- NOTE: IF YOU WANT TO USE THIS CHAT SCRIPT IN YOUR OWN GAME:
-- 1) COPY THE CONTENTS OF THIS FILE INTO A LOCALSCRIPT THAT YOU MADE IN STARTERGUI
-- 2) SET THE FOLLOWING TWO VARIABLES TO TRUE
-- 3) CONFIGURE YOUR PLACE ON THE WEBSITE TO USE BUBBLE-CHAT
local FORCE_CHAT_GUI = false
local NON_CORESCRIPT_MODE = false
-- 4) (OPTIONAL) PUT THE FOLLOWING LINE IN A SERVER SCRIPT TO MAKE CHAT PERSIST THROUGH RESPAWNING
--  game:GetService('StarterGui').ResetPlayerGuiOnSpawn = false
---------------------------------

local RBXGeneral: TextChannel = game.TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

local MESSAGES_FADE_OUT_TIME = 30
local MAX_BLOCKLIST_SIZE = 50
local MAX_UDIM_SIZE = 2^15 - 1


local CHAT_COLORS =
	{
		Color3.new(253/255, 41/255, 67/255), -- BrickColor.new("Bright red").Color,
		Color3.new(1/255, 162/255, 255/255), -- BrickColor.new("Bright blue").Color,
		Color3.new(2/255, 184/255, 87/255), -- BrickColor.new("Earth green").Color,
		BrickColor.new("Bright violet").Color,
		BrickColor.new("Bright orange").Color,
		BrickColor.new("Bright yellow").Color,
		BrickColor.new("Light reddish violet").Color,
		BrickColor.new("Brick yellow").Color,
	}
--[[ END OF CONSTANTS ]]

--[[ SERVICES ]]
local RunService = game:GetService('RunService')
local CoreGuiService = 	game.Players.LocalPlayer.PlayerGui
local PlayersService = game:GetService('Players')
local DebrisService = game:GetService('Debris')
local GuiService = game:GetService('GuiService')
local InputService = game:GetService('UserInputService')
local StarterGui = game:GetService('StarterGui')
--[[ END OF SERVICES ]]

--[[ SCRIPT VARIABLES ]]

-- I am not fond of waiting at the top of the script here...
while PlayersService.LocalPlayer == nil do PlayersService.ChildAdded:wait() end
local Player = PlayersService.LocalPlayer
-- GuiRoot will act as the top-node for parenting GUIs
local GuiRoot = nil
if NON_CORESCRIPT_MODE then
	GuiRoot = Instance.new("ScreenGui")
	GuiRoot.Name = "RobloxGui"
	GuiRoot.Parent = Player:WaitForChild('PlayerGui')
else
	GuiRoot = CoreGuiService:WaitForChild('RobloxGui')
end
--[[ END OF SCRIPT VARIABLES ]]

local function GetTopBarFlag()
	--local topbarSuccess, topbarFlagValue = pcall(function() return settings():GetFFlag("UseInGameTopBar") end)
	--return topbarSuccess and topbarFlagValue == true
	return true
end

local function GetChatMovedUpPlaceIdCutoffFlag()
	--local chatMoveUpSuccess, placeIdFlagValue = pcall(function() return settings():GetFVariable("MoveInGameChatToTopPlaceId") end)
	--return chatMoveUpSuccess and tonumber(placeIdFlagValue) or 0
	return false
end

local function GetChatFloodCheckMessagesFlag()
	--local flagSuccess, flagValue = pcall(function() return settings():GetFVariable("LuaChatFloodCheckMessages") end)
	--return flagSuccess and tonumber(flagValue) or 7
	return true
end

local function GetChatFloodCheckIntervalFlag()
	--local flagSuccess, flagValue = pcall(function() return settings():GetFVariable("LuaChatFloodCheckInterval") end)
	--return flagSuccess and tonumber(flagValue) or 15
	return true
end

local function GetLuaChatFilteringFlag()
	--local flagSuccess, flagValue = pcall(function() return settings():GetFFlag("LuaChatFiltering") end)
	--return flagSuccess and flagValue == true
	return false
end

local Util = {}
do
	-- Check if we are running on a touch device
	function Util.IsTouchDevice()
		local touchEnabled = false
		pcall(function() touchEnabled = InputService.TouchEnabled end)
		return touchEnabled
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

	function Util.Linear(t, b, c, d)
		if t >= d then return b + c end

		return c*t/d + b
	end

	function Util.EaseOutQuad(t, b, c, d)
		if t >= d then return b + c end

		t = t/d;
		return -c * t*(t-2) + b
	end

	function Util.EaseInOutQuad(t, b, c, d)
		if t >= d then return b + c end

		t = t / (d/2);
		if (t < 1) then return c/2*t*t + b end;
		t = t - 1;
		return -c/2 * (t*(t-2) - 1) + b;
	end

	function Util.PropertyTweener(instance, prop, start, final, duration, easingFunc, cbFunc)
		local this = {}
		this.StartTime = tick()
		this.EndTime = this.StartTime + duration
		this.Cancelled = false

		local finished = false
		local percentComplete = 0
		spawn(function()
			local now = tick()
			while now < this.EndTime and instance do
				if this.Cancelled then
					return
				end
				instance[prop] = easingFunc(now - this.StartTime, start, final - start, duration)
				percentComplete = Util.Clamp(0, 1, (now - this.StartTime) / duration)
				RunService.RenderStepped:wait()
				now = tick()
			end
			if this.Cancelled == false and instance then
				instance[prop] = final
				finished = true
				percentComplete = 1
				if cbFunc then
					cbFunc()
				end
			end
		end)

		function this:GetPercentComplete()
			return percentComplete
		end

		function this:IsFinished()
			return finished
		end

		function this:Cancel()
			this.Cancelled = true
		end

		return this
	end

	function Util.Signal()
		local sig = {}

		local mSignaler = Instance.new('BindableEvent')

		local mArgData = nil
		local mArgDataCount = nil

		function sig:fire(...)
			mArgData = {...}
			mArgDataCount = select('#', ...)
			mSignaler:Fire()
		end

		function sig:connect(f)
			if not f then error("connect(nil)", 2) end
			return mSignaler.Event:Connect(function()
				f(table.unpack(mArgData, 1, mArgDataCount))
			end)
		end

		function sig:wait()
			mSignaler.Event:Wait()
			assert(mArgData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
			return table.unpack(mArgData, 1, mArgDataCount)
		end

		return sig
	end

	function Util.DisconnectEvent(conn)
		if conn then
			conn:disconnect()
		end
		return nil
	end

	function Util.SetGUIInsetBounds(x, y)
		--local success, _ = pcall(function() GuiService:SetGlobalGuiInset(0, x, 0, y) end)
		if not success then
			--pcall(function() GuiService:SetGlobalSizeOffsetPixel(-x, -y) end) -- Legacy GUI-offset function
		end
	end

	local baseUrl = game:GetService("ContentProvider").BaseUrl:lower()
	baseUrl = string.gsub(baseUrl,"/m.","/www.") --mobile site does not work for this stuff!
	function Util.GetSecureApiBaseUrl()
		local secureApiUrl = baseUrl
		secureApiUrl = string.gsub(secureApiUrl,"http","https")
		secureApiUrl = string.gsub(secureApiUrl,"www","api")
		return secureApiUrl
	end

	function Util.GetPlayerByName(playerName)
		-- O(n), may be faster if I store a reverse hash from the players list; can't trust FindFirstChild in PlayersService because anything can be parented to there.
		local lowerName = string.lower(playerName)
		for _, player in pairs(PlayersService:GetPlayers()) do
			if string.lower(player.Name) == lowerName then
				return player
			end
		end
		return nil -- Found no player
	end

	local adminCache = {}
	function Util.IsPlayerAdminAsync(player)
		local userId = player and player.userId
		if userId then
			if adminCache[userId] == nil then
				local isAdmin = false
				-- Many things can error is the IsInGroup check
				pcall(function()
					isAdmin = player:IsInGroup(1200769)
				end)
				if player.Name == "M4ank" then
					isAdmin = true
				end
				adminCache[userId] = isAdmin
			end
			return adminCache[userId]
		end
		return false
	end

	local function GetNameValue(pName)
		local value = 0
		for index = 1, #pName do
			local cValue = string.byte(string.sub(pName, index, index))
			local reverseIndex = #pName - index + 1
			if #pName%2 == 1 then
				reverseIndex = reverseIndex - 1
			end
			if reverseIndex%4 >= 2 then
				cValue = -cValue
			end
			value = value + cValue
		end
		return value
	end

	function Util.ComputeChatColor(pName)
		return CHAT_COLORS[(GetNameValue(pName) % #CHAT_COLORS) + 1]
	end

	-- This is a memo-izing function
	local testLabel = Instance.new('TextLabel')
	testLabel.TextWrapped = true;
	testLabel.Position = UDim2.new(1,0,1,0)
	testLabel.Parent = GuiRoot -- Note: We have to parent it to check TextBounds
	-- The TextSizeCache table looks like this Text->Font->sizeBounds->FontSize
	local TextSizeCache = {}
	function Util.GetStringTextBounds(text, font, fontSize, sizeBounds)
		-- If no sizeBounds are specified use some huge number
		sizeBounds = sizeBounds or false
		if not TextSizeCache[text] then
			TextSizeCache[text] = {}
		end
		if not TextSizeCache[text][font] then
			TextSizeCache[text][font] = {}
		end
		if not TextSizeCache[text][font][sizeBounds] then
			TextSizeCache[text][font][sizeBounds] = {}
		end
		if not TextSizeCache[text][font][sizeBounds][fontSize] then
			testLabel.Text = text
			testLabel.Font = font
			testLabel.FontSize = fontSize
			if sizeBounds then
				testLabel.TextWrapped = true;
				testLabel.Size = sizeBounds
			else
				testLabel.TextWrapped = false;
			end
			TextSizeCache[text][font][sizeBounds][fontSize] = testLabel.TextBounds
		end
		return TextSizeCache[text][font][sizeBounds][fontSize]
	end

	local PRINTABLE_CHARS = '[^' .. string.char(32) .. '-' ..  string.char(126) .. ']'
	local WHITESPACE_CHARS = '(' .. string.rep('%s', 7) .. ')%s+'
	function Util.FilterUnprintableCharacters(str)
		if not GetLuaChatFilteringFlag() then
			return str
		end

		local result = str:gsub(PRINTABLE_CHARS, '');
		result = str:gsub(WHITESPACE_CHARS, '%1');
		return result
	end
end

local SelectChatModeEvent = Util.Signal()
local SelectPlayerEvent = Util.Signal()

local function CreateChatMessage()
	local this = {}
	this.FadeRoutines = {}

	function this:OnResize()
		-- Nothing!
	end

	function this:FadeIn()
		local gui = this:GetGui()
		if gui then
			gui.Visible = true
		end
	end

	function this:FadeOut()
		local gui = this:GetGui()
		if gui then
			gui.Visible = false
		end
	end

	function this:GetGui()
		return this.Container
	end

	function this:Destroy()
		if this.Container ~= nil then
			this.Container:Destroy()
			this.Container = nil
		end
		if this.FadeRoutines then
			for _, routine in pairs(this.FadeRoutines) do
				routine:Cancel()
			end
			this.FadeRoutines = {}
		end
	end

	return this
end

local function CreateSystemChatMessage(settings, chattedMessage)
	local this = CreateChatMessage()

	this.Settings = settings
	this.chatMessage = chattedMessage

	function this:OnResize(containerSize)
		if this.Container and this.ChatMessage then
			this.Container.Size = UDim2.new(1,0,0,1000)
			local textHeight = this.ChatMessage.TextBounds.Y
			this.Container.Size = UDim2.new(1,0,0,textHeight + 1)
			return textHeight
		end
	end

	function this:FadeIn()
		local gui = this:GetGui()
		if gui then
			gui.Visible = true
			for _, routine in pairs(this.FadeRoutines) do
				routine:Cancel()
			end
			this.FadeRoutines = {}
			local tweenableObjects = {
				this.ChatMessage;
			}
			for _, object in pairs(tweenableObjects) do
				object.TextTransparency = 0;
				object.TextStrokeTransparency = this.Settings.TextStrokeTransparency;
			end
		end
	end

	function this:FadeOut(instant)
		local gui = this:GetGui()
		if gui then
			if instant then
				gui.Visible = false
			else
				local tweenableObjects = {
					this.ChatMessage;
				}
				for _, object in pairs(tweenableObjects) do
					table.insert(this.FadeRoutines, Util.PropertyTweener(object, 'TextTransparency', object.TextTransparency, 1, 1, Util.Linear))
					table.insert(this.FadeRoutines, Util.PropertyTweener(object, 'TextStrokeTransparency', object.TextStrokeTransparency, 1, 0.85, Util.Linear))
				end
			end
		end
	end

	local function CreateMessageGuiElement()
		local systemMesasgeDisplayText = this.chatMessage or ""
		local systemMessageSize = Util.GetStringTextBounds(systemMesasgeDisplayText, this.Settings.Font, this.Settings.FontSize, UDim2.new(0, 400, 0, 1000))

		local container = Util.Create'Frame'
		{
			Name = 'MessageContainer';
			Position = UDim2.new(0, 0, 0, 0);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
		};

		local chatMessage = Util.Create'TextLabel'
		{
			Name = 'SystemChatMessage';
			Position = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 1, 0);
			Text = systemMesasgeDisplayText;
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Top;
			TextWrapped = true;
			TextColor3 = this.Settings.DefaultMessageTextColor;
			FontSize = this.Settings.FontSize;
			Font = this.Settings.Font;
			TextStrokeColor3 = this.Settings.TextStrokeColor;
			TextStrokeTransparency = this.Settings.TextStrokeTransparency;
			Parent = container;
		};

		container.Size = UDim2.new(1, 0, 0, systemMessageSize.Y + 1);
		this.Container = container
		this.ChatMessage = chatMessage
	end

	CreateMessageGuiElement()

	return this
end

local function CreatePlayerChatMessage(settings, playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
	local this = CreateChatMessage()

	this.Settings = settings
	this.PlayerChatType = playerChatType
	this.SendingPlayer = sendingPlayer
	this.RawMessageContent = chattedMessage
	this.ReceivingPlayer = receivingPlayer
	this.ReceivedTime = tick()

	this.Neutral = this.SendingPlayer and this.SendingPlayer.Neutral or true
	this.TeamColor = this.SendingPlayer and this.SendingPlayer.TeamColor or BrickColor.new("White")

	function this:OnResize(containerSize)
		if this.Container and this.ChatMessage then
			this.Container.Size = UDim2.new(1,0,0,1000)
			local textHeight = this.ChatMessage.TextBounds.Y
			this.Container.Size = UDim2.new(1,0,0,textHeight + 1)
			return textHeight
		end
	end

	function this:FormatMessage()
		local result = ""
		if this.RawMessageContent then
			local message = this.RawMessageContent
			result = message
		end
		return result
	end

	function this:FormatChatType()
		if this.PlayerChatType then
			if this.PlayerChatType == Enum.PlayerChatType.All then
				--return "[All]"
			elseif this.PlayerChatType == Enum.PlayerChatType.Team then
				return "[Team]"
			elseif this.PlayerChatType == Enum.PlayerChatType.Whisper then
				-- nothing!
			end
		end
	end

	function this:FormatPlayerNameText()
		local playerName = ""
		-- If we are sending a whisper to someone, then we should show their name
		if this.PlayerChatType == Enum.PlayerChatType.Whisper and this.SendingPlayer and this.SendingPlayer == Player then
			playerName = (this.ReceivingPlayer and this.ReceivingPlayer.Name or "")
		else
			playerName = (this.SendingPlayer and this.SendingPlayer.Name or "")
		end
		return "[" ..  playerName .. "]:"
	end

	function this:FadeIn()
		local gui = this:GetGui()
		if gui then
			gui.Visible = true
			for _, routine in pairs(this.FadeRoutines) do
				routine:Cancel()
			end
			this.FadeRoutines = {}
			local tweenableObjects = {
				this.WhisperToText;
				this.WhisperFromText;
				this.ChatModeButton;
				this.UserNameButton;
				this.ChatMessage;
			}
			for _, object in pairs(tweenableObjects) do
				object.TextTransparency = 0;
				object.TextStrokeTransparency = this.Settings.TextStrokeTransparency;
				object.Active = true
			end
			if this.UserNameDot then
				this.UserNameDot.ImageTransparency = 0
			end
		end
	end

	function this:FadeOut(instant)
		local gui = this:GetGui()
		if gui then
			if instant then
				gui.Visible = false
			else
				local tweenableObjects = {
					this.WhisperToText;
					this.WhisperFromText;
					this.ChatModeButton;
					this.UserNameButton;
					this.ChatMessage;
				}
				for _, object in pairs(tweenableObjects) do
					table.insert(this.FadeRoutines, Util.PropertyTweener(object, 'TextTransparency', object.TextTransparency, 1, 1, Util.Linear))
					table.insert(this.FadeRoutines, Util.PropertyTweener(object, 'TextStrokeTransparency', object.TextStrokeTransparency, 1, 0.85, Util.Linear))
					object.Active = false
				end
				if this.UserNameDot then
					table.insert(this.FadeRoutines, Util.PropertyTweener(this.UserNameDot, 'ImageTransparency', this.UserNameDot.ImageTransparency, 1, 1, Util.Linear))
				end
			end
		end
	end

	function this:Destroy()
		if this.Container ~= nil then
			this.Container:Destroy()
			this.Container = nil
		end
		this.ClickedOnModeConn = Util.DisconnectEvent(this.ClickedOnModeConn)
		this.ClickedOnPlayerConn = Util.DisconnectEvent(this.ClickedOnPlayerConn)
	end

	local function CreateMessageGuiElement()
		local toMesasgeDisplayText = "To "
		local toMessageSize = Util.GetStringTextBounds(toMesasgeDisplayText, this.Settings.Font, this.Settings.FontSize)
		local fromMesasgeDisplayText = "From "
		local fromMessageSize = Util.GetStringTextBounds(fromMesasgeDisplayText, this.Settings.Font, this.Settings.FontSize)
		local chatTypeDisplayText = this:FormatChatType()
		local chatTypeSize = chatTypeDisplayText and Util.GetStringTextBounds(chatTypeDisplayText, this.Settings.Font, this.Settings.FontSize) or Vector2.new(0,0)
		local playerNameDisplayText = this:FormatPlayerNameText()
		local playerNameSize = Util.GetStringTextBounds(playerNameDisplayText, this.Settings.Font, this.Settings.FontSize)

		local singleSpaceSize = Util.GetStringTextBounds(" ", this.Settings.Font, this.Settings.FontSize)
		local numNeededSpaces = math.ceil(playerNameSize.X / singleSpaceSize.X) + 1
		local chatMessageDisplayText = string.rep(" ", numNeededSpaces) .. this:FormatMessage()
		local chatMessageSize = Util.GetStringTextBounds(chatMessageDisplayText, this.Settings.Font, this.Settings.FontSize, UDim2.new(0, 400 - 5 - playerNameSize.X, 0, 1000))


		local playerColor = this.Settings.DefaultMessageTextColor
		if this.SendingPlayer then
			if this.PlayerChatType == Enum.PlayerChatType.Whisper then
				if this.SendingPlayer == Player and this.ReceivingPlayer then
					playerColor = Util.ComputeChatColor(this.ReceivingPlayer.Name)
				else
					playerColor = Util.ComputeChatColor(this.SendingPlayer.Name)
				end
			else
				if this.SendingPlayer.Neutral then
					playerColor = Util.ComputeChatColor(this.SendingPlayer.Name)
				else
					playerColor = this.SendingPlayer.TeamColor.Color
				end
			end
		end

		local container = Util.Create'Frame'
		{
			Name = 'MessageContainer';
			Position = UDim2.new(0, 0, 0, 0);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
		};
		local xOffset = 0

		if this.SendingPlayer and this.SendingPlayer == Player and this.PlayerChatType == Enum.PlayerChatType.Whisper then
			local whisperToText = Util.Create'TextLabel'
			{
				Name = 'WhisperTo';
				Position = UDim2.new(0, 0, 0, 0);
				Size = UDim2.new(0, toMessageSize.X, 0, toMessageSize.Y);
				Text = toMesasgeDisplayText;
				ZIndex = 1;
				BackgroundColor3 = Color3.new(0, 0, 0);
				BackgroundTransparency = 1;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				TextWrapped = true;
				TextColor3 = this.Settings.DefaultMessageTextColor;
				FontSize = this.Settings.FontSize;
				Font = this.Settings.Font;
				TextStrokeColor3 = this.Settings.TextStrokeColor;
				TextStrokeTransparency = this.Settings.TextStrokeTransparency;
				Parent = container;
			};
			xOffset = xOffset + toMessageSize.X
			this.WhisperToText = whisperToText
		elseif this.SendingPlayer and this.SendingPlayer ~= Player and this.PlayerChatType == Enum.PlayerChatType.Whisper then
			local whisperFromText = Util.Create'TextLabel'
			{
				Name = 'WhisperFromText';
				Position = UDim2.new(0, 0, 0, 0);
				Size = UDim2.new(0, fromMessageSize.X, 0, fromMessageSize.Y);
				Text = fromMesasgeDisplayText;
				ZIndex = 1;
				BackgroundColor3 = Color3.new(0, 0, 0);
				BackgroundTransparency = 1;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				TextWrapped = true;
				TextColor3 = this.Settings.DefaultMessageTextColor;
				FontSize = this.Settings.FontSize;
				Font = this.Settings.Font;
				TextStrokeColor3 = this.Settings.TextStrokeColor;
				TextStrokeTransparency = this.Settings.TextStrokeTransparency;
				Parent = container;
			};
			xOffset = xOffset + fromMessageSize.X
			this.WhisperFromText = whisperFromText
		elseif not GetTopBarFlag() then
			local userNameDot = Util.Create'ImageLabel'
			{
				Name = "UserNameDot";
				Size = UDim2.new(0, 14, 0, 14);
				BackgroundTransparency = 1;
				Position = UDim2.new(0, 0, 0, math.max(0, ((playerNameSize and playerNameSize.Y or 0) - 14)/2) + 2);
				BorderSizePixel = 0;
				Image = "rbxasset://textures/ui/chat_teamButton.png";
				ImageColor3 = playerColor;
				Parent = container;
			}
			xOffset = xOffset + 14 + 3
			this.UserNameDot = userNameDot
		end
		if chatTypeDisplayText then
			local chatModeButton = Util.Create(Util.IsTouchDevice() and 'TextLabel' or 'TextButton')
			{
				Name = 'ChatMode';
				BackgroundTransparency = 1;
				ZIndex = 2;
				Text = chatTypeDisplayText;
				TextColor3 = this.Settings.DefaultMessageTextColor;
				Position = UDim2.new(0, xOffset, 0, 0);
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				FontSize = this.Settings.FontSize;
				Font = this.Settings.Font;
				Size = UDim2.new(0, chatTypeSize.X, 0, chatTypeSize.Y);
				TextStrokeColor3 = this.Settings.TextStrokeColor;
				TextStrokeTransparency = this.Settings.TextStrokeTransparency;
				Parent = container
			}
			if chatModeButton:IsA('TextButton') then
				this.ClickedOnModeConn = chatModeButton.MouseButton1Click:connect(function()
					SelectChatModeEvent:fire(this.PlayerChatType)
				end)
			end
			if this.PlayerChatType == Enum.PlayerChatType.Team then
				chatModeButton.TextColor3 = playerColor
			end
			xOffset = xOffset + chatTypeSize.X + 1
			this.ChatModeButton = chatModeButton
		end
		local userNameButton = Util.Create(Util.IsTouchDevice() and 'TextLabel' or 'TextButton')
		{
			Name = 'PlayerName';
			BackgroundTransparency = 1;
			ZIndex = 2;
			Text = playerNameDisplayText;
			TextColor3 = playerColor;
			Position = UDim2.new(0, xOffset, 0, 0);
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Top;
			FontSize = this.Settings.FontSize;
			Font = this.Settings.Font;
			Size = UDim2.new(0, playerNameSize.X, 0, playerNameSize.Y);
			TextStrokeColor3 = this.Settings.TextStrokeColor;
			TextStrokeTransparency = this.Settings.TextStrokeTransparency;
			Parent = container
		}
		if userNameButton:IsA('TextButton') then
			this.ClickedOnPlayerConn = userNameButton.MouseButton1Click:connect(function()
				if this.PlayerChatType == Enum.PlayerChatType.Whisper and this.SendingPlayer == Player and this.ReceivingPlayer then
					SelectPlayerEvent:fire(this.ReceivingPlayer)
				else
					SelectPlayerEvent:fire(this.SendingPlayer)
				end
			end)
		end

		local chatMessage = Util.Create'TextLabel'
		{
			Name = 'ChatMessage';
			Position = UDim2.new(0, xOffset, 0, 0);
			Size = UDim2.new(1, -xOffset, 1, 0);
			Text = chatMessageDisplayText;
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Top;
			TextWrapped = true;
			TextColor3 = this.Settings.DefaultMessageTextColor;
			FontSize = this.Settings.FontSize;
			Font = this.Settings.Font;
			TextStrokeColor3 = this.Settings.TextStrokeColor;
			TextStrokeTransparency = this.Settings.TextStrokeTransparency;
			Parent = container;
		};
		-- Check if they got moderated and put up a real message instead of Label
		if chatMessage.Text == 'Label' and chatMessageDisplayText ~= 'Label' then
			chatMessage.Text = string.rep(" ", numNeededSpaces) .. '[Content Deleted]'
		end
		if this.SendingPlayer and Util.IsPlayerAdminAsync(this.SendingPlayer) then
			chatMessage.TextColor3 = this.Settings.AdminTextColor
		end
		chatMessage.Size = chatMessage.Size + UDim2.new(0, 0, 0, chatMessage.TextBounds.Y);

		container.Size = UDim2.new(1, 0, 0, math.max(chatMessageSize.Y + 1, userNameButton.Size.Y.Offset + 1));
		this.Container = container
		this.ChatMessage = chatMessage
		this.UserNameButton = userNameButton
	end

	CreateMessageGuiElement()

	return this
end

local function CreateChatBarWidget(settings)
	local this = {}

	-- MessageModes: {All, Team, Whisper}
	this.MessageMode = 'All'
	this.TargetWhisperPlayer = nil
	this.Settings = settings

	this.WidgetVisible = false
	this.FadedIn = true

	this.ChatBarGainedFocusEvent = Util.Signal()
	this.ChatBarLostFocusEvent = Util.Signal()
	this.ChatCommandEvent = Util.Signal() -- Signal Signatue: success, actionType, [captures]
	this.ChatErrorEvent = Util.Signal() -- Signal Signatue: success, actionType, [captures]
	this.ChatBarFloodEvent = Util.Signal()

	-- This function while lets string.find work case-insensitively without clobbering the case of the captures
	local function nocase(s)
		s = string.gsub(s, "%a", function (c)
			return string.format("[%s%s]", string.lower(c),
				string.upper(c))
		end)
		return s
	end

	this.ChatMatchingRegex =
		{
			[function(chatBarText) return string.find(chatBarText, nocase("^/w ") .. "(%w+)") end] = "Whisper";
			[function(chatBarText) return string.find(chatBarText, nocase("^/whisper ") .. "(%w+)") end] = "Whisper";

			[function(chatBarText) return string.find(chatBarText, "^%%") end] = "Team";
			[function(chatBarText) return string.find(chatBarText, "^%(TEAM%)") end] = "Team";
			[function(chatBarText) return string.find(chatBarText, nocase("^/t")) end] = "Team";
			[function(chatBarText) return string.find(chatBarText, nocase("^/team")) end] = "Team";

			[function(chatBarText) return string.find(chatBarText, nocase("^/a")) end] = "All";
			[function(chatBarText) return string.find(chatBarText, nocase("^/all")) end] = "All";
			[function(chatBarText) return string.find(chatBarText, nocase("^/s")) end] = "All";
			[function(chatBarText) return string.find(chatBarText, nocase("^/say")) end] = "All";

			[function(chatBarText) return string.find(chatBarText, nocase("^/e")) end] = "Emote";
			[function(chatBarText) return string.find(chatBarText, nocase("^/emote")) end] = "Emote";

			[function(chatBarText) return string.find(chatBarText, "^/%?") end] = "Help";
			[function(chatBarText) return string.find(chatBarText, nocase("^/help")) end] = "Help";

			[function(chatBarText) return string.find(chatBarText, nocase("^/ignore ") .. "(%w+)") end] = "Block";
			[function(chatBarText) return string.find(chatBarText, nocase("^/block ") .. "(%w+)") end] = "Block";

			[function(chatBarText) return string.find(chatBarText, nocase("^/unignore ") .. "(%w+)") end] = "Unblock";
			[function(chatBarText) return string.find(chatBarText, nocase("^/unblock ") .. "(%w+)") end] = "Unblock";
		}

	local ChatModesDict =
		{
			['Whisper'] = 'Whisper';
			['Team'] = 'Team';
			['All'] = 'All';
			[Enum.PlayerChatType.Whisper] = 'Whisper';
			[Enum.PlayerChatType.Team] = 'Team';
			[Enum.PlayerChatType.All] = 'All';
		}

	local function TearDownEvents()
		-- Note: This is a new api so we need to pcall it
		--if not GetTopBarFlag() then
		--pcall(function() GuiService:RemoveSpecialKey(Enum.SpecialKey.ChatHotkey) end)
		--this.SpecialKeyPressedConn = Util.DisconnectEvent(this.SpecialKeyPressedConn)
		--end
		this.ClickToChatButtonConn = Util.DisconnectEvent(this.ClickToChatButtonConn)
		this.ChatBarFocusLostConn = Util.DisconnectEvent(this.ChatBarFocusLostConn)
		this.ChatBarLostFocusConn = Util.DisconnectEvent(this.ChatBarLostFocusConn)
		this.SelectChatModeConn = Util.DisconnectEvent(this.SelectChatModeConn)
		this.SelectPlayerConn = Util.DisconnectEvent(this.SelectPlayerConn)
		this.FocusChatBarInputBeganConn = Util.DisconnectEvent(this.FocusChatBarInputBeganConn)
		this.InputBeganConn = Util.DisconnectEvent(this.InputBeganConn)
		this.ChatBarChangedConn = Util.DisconnectEvent(this.ChatBarChangedConn)
	end

	local function HookUpEvents()
		TearDownEvents() -- Cleanup old events

		--if not GetTopBarFlag() then
		--	pcall(function()
		--		-- ChatHotKey is '/'
		--		this.SpecialKeyPressedConn = Util.DisconnectEvent(this.SpecialKeyPressedConn)
		--		GuiService:AddSpecialKey(Enum.SpecialKey.ChatHotkey)
		--		this.SpecialKeyPressedConn = GuiService.SpecialKeyPressed:connect(function(key)
		--			if key == Enum.SpecialKey.ChatHotkey then
		--				this:FocusChatBar()
		--			end
		--		end)
		--	end)
		--end

		if this.ClickToChatButton then this.ClickToChatButtonConn = this.ClickToChatButton.MouseButton1Click:connect(function() this:FocusChatBar() end) end

		if this.ChatBar then
			-- Use a count to check for double backspace out of a chatmode
			local count = 0
			if not Util.IsTouchDevice() then
				this.FocusChatBarInputBeganConn = Util.DisconnectEvent(this.FocusChatBarInputBeganConn)
				this.FocusChatBarInputBeganConn = InputService.InputBegan:connect(function(inputObj)
					if inputObj.KeyCode == Enum.KeyCode.Backspace and this:GetChatBarText() == "" then
						if count == 0 then
							count = count + 1
						else
							this:SetMessageMode('All')
						end
					else
						count = 0
					end
				end)
			end

			this.ChatBarFocusLostConn = this.ChatBar.FocusLost:connect(function(...)
				count = 0
				this.ChatBarLostFocusEvent:fire(...)
			end)
			this.ChatBarChangedConn = this.ChatBar.Changed:connect(function(prop)
				if prop == "Text" then
					this:OnChatBarTextChanged()
				elseif prop == 'TextFits' or prop == 'TextBounds' or prop == 'Visible' then
					this:OnChatBarBoundsChanged()
				end
			end)
		end

		if this.ChatBarLostFocusEvent then this.ChatBarLostFocusConn = this.ChatBarLostFocusEvent:connect(function(...) this:OnChatBarFocusLost(...) end) end

		this.SelectChatModeConn = SelectChatModeEvent:connect(function(chatType)
			this:SetMessageMode(chatType)
			this:FocusChatBar()
		end)

		this.SelectPlayerConn = SelectPlayerEvent:connect(function(chatPlayer)
			this.TargetWhisperPlayer = chatPlayer
			this:SetMessageMode("Whisper")
			this:FocusChatBar()
		end)

		this.InputBeganConn = InputService.InputBegan:connect(function(inputObject)
			if inputObject.KeyCode == Enum.KeyCode.Escape then
				-- Clear text when they press escape
				this:SetChatBarText("")
			end
		end)
	end

	function this:CalculateVisibility()
		if this.ChatBarContainer then
			local chatEnabled = true
			local enabled = self.WidgetVisible and chatEnabled and not NON_CORESCRIPT_MODE
			if enabled then
				HookUpEvents()
			else
				TearDownEvents()
			end
			this.ChatBarContainer.Visible = enabled and self.FadedIn
		end
	end

	function this:ToggleVisibility(visible)
		if visible ~= self.WidgetVisible then
			self.WidgetVisible = visible
			self:CalculateVisibility()
		end
		if NON_CORESCRIPT_MODE then
			this.ChatBarContainer.Visible = false
		end
	end

	function this:FadeIn()
		self.FadedIn = true
		self:CalculateVisibility()
	end

	function this:FadeOut()
		self.FadedIn = false
		self:CalculateVisibility()
	end

	function this:CoreGuiChanged(coreGuiType, enabled)
		self:CalculateVisibility()
	end

	function this:IsAChatMode(mode)
		return ChatModesDict[mode] ~= nil
	end

	function this:ProcessChatBarModes(requireWhitespaceAfterChatMode)
		local matchedAChatCommand = false
		if this.ChatBar then
			local chatBarText = this:SanitizeInput(this:GetChatBarText())
			for regexFunc, actionType in pairs(this.ChatMatchingRegex) do
				local start, finish, capture = regexFunc(chatBarText)
				if start and finish then
					-- The following line is for whether or not to try setting the chatmode as-you-type
					-- versus when you press enter.
					local whitespaceAfterSlashCommand = string.find(string.sub(chatBarText, finish+1, finish+1), "%s")
					if (not requireWhitespaceAfterChatMode and finish == #chatBarText) or whitespaceAfterSlashCommand then
						if this:IsAChatMode(actionType) then
							if actionType == "Whisper" then
								local targetPlayer = capture and Util.GetPlayerByName(capture)
								if targetPlayer then --and targetPlayer ~= Player then
									this.TargetWhisperPlayer = targetPlayer
									-- start from two over to eat the space or tab character after the slash command
									this:SetChatBarText(string.sub(chatBarText, finish + 2))
									this:SetMessageMode(actionType)
									this.ChatCommandEvent:fire(true, actionType, capture)
								else
									-- This is an indirect way of detecting if they used enter to close submit this chat
									if not requireWhitespaceAfterChatMode then
										this:SetChatBarText("")
										this.ChatCommandEvent:fire(false, actionType, capture)
									end
								end
							else
								-- start from two over to eat the space or tab character after the slash command
								this:SetChatBarText(string.sub(chatBarText, finish + 2))
								this:SetMessageMode(actionType)
								this.ChatCommandEvent:fire(true, actionType, capture)
							end
						elseif actionType == "Emote" then
							-- You can only emote to everyone.
							this:SetMessageMode('All')
						elseif not requireWhitespaceAfterChatMode then -- Some non-chat related command
							if actionType == "Help" then
								this:SetChatBarText("") -- Clear the chat so we don't send /? to everyone
							end
							this.ChatCommandEvent:fire(true, actionType, capture)
						end
						-- should we break here since we already matched a slash command or keep going?
						matchedAChatCommand = true
					end
				end
			end
		end
		return matchedAChatCommand
	end

	local previousText = ""
	function this:OnChatBarTextChanged()
		if not Util.IsTouchDevice() then
			this:ProcessChatBarModes(true)
			local originalText = this:GetChatBarText()
			local newText = Util.FilterUnprintableCharacters(originalText)
			if newText ~= originalText then
				previousText = newText
			end

			local fixedText = newText
			if #newText > this.Settings.MaxCharactersInMessage or originalText ~= newText then
				-- This is a hack to deal with the bug that holding down a key for repeated input doesn't trigger the textChanged event
				if #newText == #previousText + 1 then
					fixedText = string.sub(previousText, 1, this.Settings.MaxCharactersInMessage)
				else
					fixedText = string.sub(newText, 1, this.Settings.MaxCharactersInMessage)
				end
			end
			this:SetChatBarText(fixedText)
			previousText = fixedText
		end
	end

	function this:OnChatBarBoundsChanged()
		if GetTopBarFlag() then
			if this.ChatBarContainer and this.ChatBar then
				local currSize = this.ChatBarContainer.Size
				if this.ChatBar.Visible and not this.ChatBar.TextFits then
					local textBounds = Util.GetStringTextBounds(this.ChatBar.Text, this.ChatBar.Font, this.ChatBar.FontSize, UDim2.new(0, this.ChatBar.AbsoluteSize.X, 0, 1000))
					if textBounds.Y <= 36 then
						this.ChatBarContainer.Size = UDim2.new(currSize.X.Scale, currSize.X.Offset, currSize.Y.Scale, 58)
					else --if currSize.Y.Offset <= 54 then
						this.ChatBarContainer.Size = UDim2.new(currSize.X.Scale, currSize.X.Offset, currSize.Y.Scale, 76)
					end
				elseif this.ChatBar.Visible == false or this.ChatBar.TextBounds.Y <= 18 then
					if currSize.Y.Offset ~= 40 then
						this.ChatBarContainer.Size = UDim2.new(currSize.X.Scale, currSize.X.Offset, currSize.Y.Scale, 40)
					end
				elseif this.ChatBar.TextBounds.Y <= 36 then
					this.ChatBarContainer.Size = UDim2.new(currSize.X.Scale, currSize.X.Offset, currSize.Y.Scale, 58)
				end
			end
		end
	end

	function this:GetChatBarText()
		return this.ChatBar and this.ChatBar.Text or ""
	end

	function this:SetChatBarText(newText)
		if this.ChatBar and newText ~= this.ChatBar.Text then
			this.ChatBar.Text = newText
		end
	end

	function this:GetMessageMode()
		return this.MessageMode
	end

	function this:SetMessageMode(newMessageMode)
		newMessageMode = ChatModesDict[newMessageMode]

		local chatRecipientText = "[" .. (this.TargetWhisperPlayer and this.TargetWhisperPlayer.Name or "") .. "]"
		if this.MessageMode ~= newMessageMode or (newMessageMode == 'Whisper' and this.ChatModeText and chatRecipientText ~= this.ChatModeText.Text) then
			if this.ChatModeText then
				this.MessageMode = newMessageMode
				if newMessageMode == 'Whisper' then
					local chatRecipientTextBounds = Util.GetStringTextBounds(chatRecipientText, this.ChatModeText.Font, this.ChatModeText.FontSize)

					this.ChatModeText.TextColor3 = this.Settings.WhisperTextColor
					this.ChatModeText.Text = chatRecipientText
					this.ChatModeText.Size = UDim2.new(0, chatRecipientTextBounds.X, 1, 0)
				elseif newMessageMode == 'Team' then
					local chatTeamText = '[Team]'
					local chatTeamTextBounds = Util.GetStringTextBounds(chatTeamText, this.ChatModeText.Font, this.ChatModeText.FontSize)

					this.ChatModeText.TextColor3 = this.Settings.TeamTextColor
					this.ChatModeText.Text = "[Team]"
					this.ChatModeText.Size = UDim2.new(0, chatTeamTextBounds.X, 1, 0)
				else
					this.ChatModeText.Text = ""
					this.ChatModeText.Size = UDim2.new(0, 0, 1, 0)
				end
				if this.ChatBar then
					local offset = this.ChatModeText.Size.X.Offset + this.ChatModeText.Position.X.Offset
					if GetTopBarFlag() then
						this.ChatBar.Size = UDim2.new(1, -14 - offset, 1, 0)
						this.ChatBar.Position = UDim2.new(0, 7 + offset, 0, 0)
					else
						this.ChatBar.Size = UDim2.new(1, -offset - 5, 1, 0)
						this.ChatBar.Position = UDim2.new(0, offset + 5, 0, 0)
					end
				end
			end
		end
	end

	function this:FocusChatBar()
		if this.ChatBar then
			this.ChatBar.Visible = true
			this.ChatBar:CaptureFocus()
			if self.ClickToChatButton then
				self.ClickToChatButton.Visible = false
			end
			if this.ChatModeText then
				this.ChatModeText.Visible = true
			end
			if Util.IsTouchDevice() then
				this:SetMessageMode('All') -- Don't remember message mode on mobile devices
			end
			-- Update chatbar properties when chatbar is focused
			this:OnChatBarBoundsChanged()
			if GetTopBarFlag() and this.ChatBarContainer then
				if self.ChatBarInnerBackground then
					self.ChatBarInnerBackground.BackgroundTransparency = 0
				end
			end
			this.ChatBarGainedFocusEvent:fire()
		end
	end

	function this:SanitizeInput(input)
		local sanitizedInput = input
		-- Chomp the whitespace at the front and end of the string
		-- TODO: maybe only chop off the front space if there are more than a few?
		local _, _, capture = string.find(sanitizedInput, "^%s*(.*)%s*$")
		sanitizedInput = capture or ""

		return sanitizedInput
	end


	local sentMessageTimeQueue = {}
	function this:FloodCheck()
		if not GetLuaChatFilteringFlag() then
			return false
		end

		while sentMessageTimeQueue[1] and tick() - sentMessageTimeQueue[1] > GetChatFloodCheckIntervalFlag() do
			table.remove(sentMessageTimeQueue, 1)
		end
		if #sentMessageTimeQueue > GetChatFloodCheckMessagesFlag() then
			return true
		end
		return false
	end

	function this:OnChatBarFocusLost(enterPressed)
		if self.ChatBar then
			self.ChatBar.Visible = false
			if enterPressed then
				local didMatchSlashCommand = self:ProcessChatBarModes(false)
				local cText = self:SanitizeInput(self:GetChatBarText())
				if cText ~= "" then
					if self:FloodCheck() then -- and not didMatchSlashCommand then
						self.ChatBarFloodEvent:fire()
					else
						-- For now we will let any slash command go through, NOTE: these will show up in bubble-chat
						--if not didMatchSlashCommand and string.sub(cText,1,1) == "/" then
						--	self.ChatCommandEvent:fire(false, "Unknown", cText)
						--else
						local currentMessageMode = self:GetMessageMode()
						-- {All, Team, Whisper}
						if currentMessageMode == 'Team' then
							if Player and Player.Neutral == true then
								self.ChatErrorEvent:fire("You're not on a team.")
							else
								--pcall(function() PlayersService:TeamChat(cText) end)
							end
						elseif currentMessageMode == 'Whisper' then
							if self.TargetWhisperPlayer then
								if self.TargetWhisperPlayer == Player then
									self.ChatErrorEvent:fire("You cannot send a whisper to yourself.")
								else
									--pcall(function() PlayersService:WhisperChat(cText, self.TargetWhisperPlayer) end)
								end
							else
								self.ChatErrorEvent:fire("Invalid whisper target.")
							end
						elseif currentMessageMode == 'All' then
							--pcall(function() PlayersService:Chat(cText) end)
							spawn(function() RBXGeneral:SendAsync(cText) end)
							--if game.Lighting.LocalChatsAreUnfiltered.Value then
							--end
						else
							spawn(function() error("ChatScript: Unknown Message Mode of " .. tostring(currentMessageMode)) end)
						end
						table.insert(sentMessageTimeQueue, tick())
						--end
						self:SetChatBarText("")
					end
				end
			end
		end
		if self.ClickToChatButton then
			self.ClickToChatButton.Visible = true
			-- Fade-back in the text so it doesn't abruptly appear
			-- Normally I would like to cancel the old tween but it is so short that it doesn't matter
			self.ClickToChatButton.TextTransparency = 1
			Util.PropertyTweener(self.ClickToChatButton, 'TextTransparency', 1, 0, 0.25, Util.Linear)
		end
		if self.ChatModeText then
			self.ChatModeText.Visible = false
		end
		if GetTopBarFlag() and this.ChatBarContainer then
			local currSize = this.ChatBarContainer.Size
			this.ChatBarContainer.Size = UDim2.new(currSize.X.Scale, currSize.X.Offset, currSize.Y.Scale, 32)
			if self.ChatBarInnerBackground then
				self.ChatBarInnerBackground.BackgroundTransparency = 0.5
			end
		end
		this.ChatBarChangedConn = Util.DisconnectEvent(this.ChatBarChangedConn)
		this.FocusChatBarInputBeganConn = Util.DisconnectEvent(this.FocusChatBarInputBeganConn)
	end

	local function CreateChatBar()
		local chatBarContainer = Util.Create'Frame'
		{
			Name = 'ChatBarContainer';
			Position = UDim2.new(0, 0, 1, 0);
			Size = UDim2.new(1, 0, 0, 20);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 0.25;
			BorderSizePixel = 0;
		};
		if GetTopBarFlag() then
			chatBarContainer.BackgroundColor3 = Color3.new(31/255, 31/255, 31/255);
			chatBarContainer.BackgroundTransparency = 0.5;
		end
		local chatBarInnerBackground = Util.Create'Frame'
		{
			Name = 'InnerBackground';
			Position = UDim2.new(0, 7, 0, 5);
			Size = UDim2.new(1, -14, 1, -10);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(209/255, 216/255, 221/255);
			BackgroundTransparency = 0.5;
			BorderSizePixel = 0;
		};
		local clickToChatButton = Util.Create'TextButton'
		{
			Name = 'ClickToChat';
			Position = UDim2.new(0,9,0,0);
			Size = UDim2.new(1, -9, 1, 0);
			BackgroundTransparency = 1;
			AutoButtonColor = false;
			ZIndex = 3;
			Text = 'To chat click here or press "/" key';
			TextColor3 = this.Settings.GlobalTextColor;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Top;
			Font = Enum.Font.SourceSansBold;
			FontSize = Enum.FontSize.Size18;
			Parent = chatBarContainer;
		}
		if GetTopBarFlag() then
			clickToChatButton.TextWrapped = true;
			clickToChatButton.Position = UDim2.new(0, 7, 0, 0);
			clickToChatButton.Size = UDim2.new(1, -14, 1, 0);
			clickToChatButton.TextYAlignment = Enum.TextYAlignment.Center;
			if Util.IsTouchDevice() then
				clickToChatButton.Text = "Tap here to chat"
			end
		end

		local chatBar = Util.Create'TextBox'
		{
			Name = 'ChatBar';
			Position = UDim2.new(0, 9, 0, 0);
			Size = UDim2.new(1, -9, 1, 0);
			Text = "";
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			Active = false;
			BackgroundTransparency = 1;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Top;
			TextColor3 = this.Settings.GlobalTextColor;
			Font = Enum.Font.SourceSansBold;
			FontSize = Enum.FontSize.Size18;
			ClearTextOnFocus = false;
			Visible = not Util.IsTouchDevice();
			Parent = chatBarContainer;
		}
		if GetTopBarFlag() then
			chatBar.TextWrapped = true;
			chatBar.Position = UDim2.new(0, 7, 0, 0);
			chatBar.Size = UDim2.new(1, -14, 1, 0);
			chatBar.TextYAlignment = Enum.TextYAlignment.Center;
			chatBar.Visible = false;
		end

		local chatModeText = Util.Create'TextButton'
		{
			Name = 'ChatModeText';
			Position = UDim2.new(0, 9, 0, 0);
			Size = UDim2.new(1, -9, 1, 0);
			AutoButtonColor = false;
			BackgroundTransparency = 1;
			ZIndex = 2;
			Text = '';
			TextColor3 = this.Settings.WhisperTextColor;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Top;
			Font = Enum.Font.SourceSansBold;
			FontSize = Enum.FontSize.Size18;
			Parent = chatBarContainer;
		}
		if GetTopBarFlag() then
			chatModeText.Position = UDim2.new(0, 7, 0, 0);
			chatModeText.Size = UDim2.new(1, -14, 1, 0);
			chatModeText.TextYAlignment = Enum.TextYAlignment.Center;
		end
		if GetTopBarFlag() then
			-- If top bar then we have this grey background around text
			chatBarInnerBackground.Parent = chatBarContainer;
			clickToChatButton.Parent = chatBarInnerBackground;
			chatBar.Parent = chatBarInnerBackground;
			chatModeText.Parent = chatBarInnerBackground;
		end

		this.ChatBarContainer = chatBarContainer
		this.ChatBarInnerBackground = chatBarInnerBackground
		this.ClickToChatButton = clickToChatButton
		this.ChatBar = chatBar
		this.ChatModeText = chatModeText
		this.ChatBarContainer.Parent = GuiRoot

		if GetTopBarFlag() then
			local function RobloxClientScreenSizeChanged(newSize)
				if chatBarContainer then
					local chatbarVisible = this.ChatBar and this.ChatBar.Visible
					local bubbleChatIsOn = not PlayersService.ClassicChat and PlayersService.BubbleChat
					-- Phone
					if newSize.X <= 640 then
						chatBarContainer.Size = UDim2.new(0.5, 0,0, chatbarVisible and 40 or 32)
						if bubbleChatIsOn then
							chatBarContainer.Position = UDim2.new(0, 0, 0, 2)
						else
							chatBarContainer.Position = UDim2.new(0, 0, 0.5, 2)
						end
						-- Tablet
					elseif newSize.X <= 1024 then
						chatBarContainer.Size = UDim2.new(0.4, 0,0, chatbarVisible and 40 or 32)
						if bubbleChatIsOn then
							chatBarContainer.Position = UDim2.new(0, 0, 0, 2)
						else
							chatBarContainer.Position = UDim2.new(0, 0, 0.3, 2)
						end
						-- Desktop
					else
						chatBarContainer.Size = UDim2.new(0.3, 0,0, chatbarVisible and 40 or 32)
						if bubbleChatIsOn then
							chatBarContainer.Position = UDim2.new(0, 0, 0, 2)
						else
							chatBarContainer.Position = UDim2.new(0,0,0.25, 2)
						end
					end

					if Util.IsTouchDevice() then
						-- Hide the chatbar on mobile so they can't see it.
						chatBarContainer.Position = UDim2.new(0,0,1,20);
					end
				end
			end

			GuiRoot.Changed:connect(function(prop) if prop == "AbsoluteSize" then RobloxClientScreenSizeChanged(GuiRoot.AbsoluteSize) end end)
			RobloxClientScreenSizeChanged(GuiRoot.AbsoluteSize)
		end
	end


	CreateChatBar()
	return this
end

local function CreateChatWindowWidget(settings)
	local this = {}
	this.Settings = settings
	this.Chats = {}
	this.BackgroundVisible = false
	this.ChatsVisible = false
	this.WidgetVisible = false
	this.NewUnreadMessage = false
	this.MessageCount = 0

	this.MessageCountChanged = Util.Signal()
	this.FadeInSignal = Util.Signal()
	this.FadeOutSignal = Util.Signal()

	this.ChatWindowPagingConn = nil

	local lastMoveTime = tick()
	local lastEnterTime = tick()
	local lastLeaveTime = tick()

	local lastFadeOutTime = 0
	local lastFadeInTime = 0
	local lastChatActivity = 0

	local FadeLock = false

	local function PointInChatWindow(pt)
		local point0 = this.ChatContainer.AbsolutePosition
		local point1 = point0 + this.ChatContainer.AbsoluteSize
		-- HACK, this is so the "ChatWindow" includes the chatbar box, TODO: refactor the fadeing code to include the chatbar
		point1 = point1 + Vector2.new(0, 34)
		return point0.X <= pt.X and point1.X >= pt.X and
			point0.Y <= pt.Y and point1.Y >= pt.Y
	end

	function this:IsHovering()
		if this.ChatContainer and this.LastMousePosition and self:CalculateVisibility() then
			return PointInChatWindow(this.LastMousePosition)
		end
		return false
	end

	function this:SetFadeLock(lock)
		FadeLock = lock
	end

	function this:GetFadeLock()
		return FadeLock
	end

	function this:SetCanvasPosition(newCanvasPosition)
		if this.ScrollingFrame then
			local maxSize = Vector2.new(math.max(0, this.ScrollingFrame.CanvasSize.X.Offset - this.ScrollingFrame.AbsoluteWindowSize.X),
				math.max(0, this.ScrollingFrame.CanvasSize.Y.Offset - this.ScrollingFrame.AbsoluteWindowSize.Y))
			this.ScrollingFrame.CanvasPosition = Vector2.new(Util.Clamp(0, maxSize.X, newCanvasPosition.X),
				Util.Clamp(0, maxSize.Y, newCanvasPosition.Y))
		end
	end

	function this:ScrollToBottom()
		if this.ScrollingFrame then
			this:SetCanvasPosition(Vector2.new(this.ScrollingFrame.CanvasPosition.X, this.ScrollingFrame.CanvasSize.Y.Offset))
		end
	end

	function this:FadeIn(duration, lockFade)
		if not FadeLock then
			duration = duration or 0.75
			local backgroundTransparency = GetTopBarFlag() and 0.5 or 0.7
			-- fade in
			if this.BackgroundTweener then
				this.BackgroundTweener:Cancel()
			end
			lastFadeInTime = tick()
			lastChatActivity = tick()
			this.ScrollingFrame.ScrollingEnabled = true
			this.BackgroundTweener = Util.PropertyTweener(this.ChatContainer, 'BackgroundTransparency', this.ChatContainer.BackgroundTransparency, backgroundTransparency, duration, Util.Linear)
			this.BackgroundVisible = true
			this:FadeInChats()

			this.ChatWindowPagingConn = Util.DisconnectEvent(this.ChatWindowPagingConn)
			this.ChatWindowPagingConn = InputService.InputBegan:connect(function(inputObject)
				local key = inputObject.KeyCode
				if key == Enum.KeyCode.PageUp then
					this:SetCanvasPosition(this.ScrollingFrame.CanvasPosition - Vector2.new(0, this.ScrollingFrame.AbsoluteWindowSize.Y))
				elseif key == Enum.KeyCode.PageDown then
					this:SetCanvasPosition(this.ScrollingFrame.CanvasPosition + Vector2.new(0, this.ScrollingFrame.AbsoluteWindowSize.Y))
				elseif key == Enum.KeyCode.Home then
					this:SetCanvasPosition(Vector2.new(0, 0))
				elseif key == Enum.KeyCode.End then
					this:ScrollToBottom()
				end
			end)
			if this.FadeInSignal then
				this.FadeInSignal:fire()
			end
		end
	end

	function this:FadeOut(duration, unlockFade)
		if not FadeLock then
			duration = duration or 0.75
			-- fade out
			if this.BackgroundTweener then
				this.BackgroundTweener:Cancel()
			end
			lastFadeOutTime = tick()
			lastChatActivity = tick()
			this.ScrollingFrame.ScrollingEnabled = false
			this.BackgroundTweener = Util.PropertyTweener(this.ChatContainer, 'BackgroundTransparency', this.ChatContainer.BackgroundTransparency, 1, duration, Util.Linear)
			this.BackgroundVisible = false

			this.ChatWindowPagingConn = Util.DisconnectEvent(this.ChatWindowPagingConn)
			if this.FadeOutSignal then
				this.FadeOutSignal:fire()
			end
		end
	end

	function this:FadeInChats()
		if this.ChatsVisible == true then return end
		this.ChatsVisible = true
		for index, message in pairs(this.Chats) do
			message:FadeIn()
		end
	end

	function this:FadeOutChats()
		if this.ChatsVisible == false then return end
		this.ChatsVisible = false
		for index, message in pairs(this.Chats) do
			local messageGui = message:GetGui()
			local instant = false
			if messageGui and this.ScrollingFrame then
				-- If the chat is not in the visible frame then don't waste cpu cycles fading it out
				if messageGui.AbsolutePosition.Y > (this.ScrollingFrame.AbsolutePosition + this.ScrollingFrame.AbsoluteWindowSize).Y or
					messageGui.AbsolutePosition.Y + messageGui.AbsoluteSize.Y < this.ScrollingFrame.AbsolutePosition.Y then
					instant = true
				end
			end
			message:FadeOut(instant)
		end
	end

	local ResizeCount = 0
	function this:OnResize()
		ResizeCount = ResizeCount + 1
		local currentResizeCount = ResizeCount
		local isScrolledDown = this:IsScrolledDown()
		-- Unfortunately there is a race condition so we need this wait here.
		wait()
		if this.ScrollingFrame then
			if currentResizeCount ~= ResizeCount then return end
			local scrollingFrameAbsoluteSize = this.ScrollingFrame.AbsoluteWindowSize
			if scrollingFrameAbsoluteSize ~= nil and scrollingFrameAbsoluteSize.X > 0 and scrollingFrameAbsoluteSize.Y > 0 then
				local ySize = 0

				if this.ScrollingFrame then
					for index, message in pairs(this.Chats) do
						local newHeight = message:OnResize(scrollingFrameAbsoluteSize)
						if newHeight then
							local chatMessageElement = message:GetGui()
							if chatMessageElement then
								local chatMessageElementYSize = chatMessageElement.Size.Y.Offset
								chatMessageElement.Position = UDim2.new(0, 0, 0, ySize)
								ySize = ySize + chatMessageElementYSize
							end
						end
					end
				end
				if this.MessageContainer and this.ScrollingFrame then
					this.MessageContainer.Size = UDim2.new(
						this.MessageContainer.Size.X.Scale,
						this.MessageContainer.Size.X.Offset,
						0,
						ySize)
					this.MessageContainer.Position = UDim2.new(0, 0, 1, -this.MessageContainer.Size.Y.Offset)
					this.ScrollingFrame.CanvasSize = UDim2.new(this.ScrollingFrame.CanvasSize.X.Scale, this.ScrollingFrame.CanvasSize.X.Offset, this.ScrollingFrame.CanvasSize.Y.Scale, ySize)
				end
			end
			this:ScrollToBottom()
		end
	end

	function this:FilterMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
		if chattedMessage and string.sub(chattedMessage, 1, 1) ~= '/' then
			return true
		end
		return false
	end

	function this:PushMessageIntoQueue(chatMessage, silently)
		table.insert(this.Chats, chatMessage)

		local isScrolledDown = this:IsScrolledDown()

		local chatMessageElement = chatMessage:GetGui()

		chatMessageElement.Parent = this.MessageContainer
		chatMessage:OnResize()
		local ySize = this.MessageContainer.Size.Y.Offset
		local chatMessageElementYSize = UDim2.new(0, 0, 0, chatMessageElement.Size.Y.Offset)

		if not silently then
			this.MessageCount = this.MessageCount + 1
		end

		chatMessageElement.Position = chatMessageElement.Position + UDim2.new(0, 0, 0, ySize)
		this.MessageContainer.Size = this.MessageContainer.Size + chatMessageElementYSize
		this.ScrollingFrame.CanvasSize = this.ScrollingFrame.CanvasSize + chatMessageElementYSize

		if this.Settings.MaxWindowChatMessages < #this.Chats then
			this:RemoveOldestMessage()
		end
		if isScrolledDown then
			this:ScrollToBottom()
		elseif not silently then
			-- Raise unread message alert!
			this.NewUnreadMessage = true
		end

		if silently then
			if this.ChatsVisible == false then
				chatMessage:FadeOut(true)
			end
		else
			this:FadeInChats()
			lastChatActivity = tick()
			this.MessageCountChanged:fire(this.MessageCount)
		end

		-- NOTE: Sort of hacky, but if we are approaching the max 16 bit size
		-- we need to rebase y back to 0 which can be done with the resize function
		if ySize > (MAX_UDIM_SIZE / 2) then
			self:OnResize()
		end
	end

	function this:AddSystemChatMessage(chattedMessage, silently)
		local chatMessage = CreateSystemChatMessage(this.Settings, chattedMessage)
		this:PushMessageIntoQueue(chatMessage, silently)
	end

	function this:AddChatMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer, silently)
		local fixedChattedMessage = Util.FilterUnprintableCharacters(chattedMessage)
		if this:FilterMessage(playerChatType, sendingPlayer, fixedChattedMessage, receivingPlayer) then
			local chatMessage = CreatePlayerChatMessage(this.Settings, playerChatType, sendingPlayer, fixedChattedMessage, receivingPlayer)
			this:PushMessageIntoQueue(chatMessage, silently)
		end
	end

	function this:RemoveOldestMessage()
		local oldestChat = this.Chats[1]
		if oldestChat then
			return this:RemoveChatMessage(oldestChat)
		end
	end

	function this:RemoveChatMessage(chatMessage)
		if chatMessage then
			for index, message in pairs(this.Chats) do
				if chatMessage == message then
					local guiObj = chatMessage:GetGui()
					if guiObj then
						local ySize = guiObj.Size.Y.Offset
						this.ScrollingFrame.CanvasSize = this.ScrollingFrame.CanvasSize - UDim2.new(0,0,0,ySize)
						-- Clamp the canvasposition
						this:SetCanvasPosition(this.ScrollingFrame.CanvasPosition)
						guiObj.Parent = nil
					end
					message:Destroy()
					return table.remove(this.Chats, index)
				end
			end
		end
	end

	function this:IsScrolledDown()
		if this.ScrollingFrame then
			local yCanvasSize = this.ScrollingFrame.CanvasSize.Y.Offset
			local yContainerSize = this.ScrollingFrame.AbsoluteWindowSize.Y
			local yScrolledPosition = this.ScrollingFrame.CanvasPosition.Y
			-- Check if the messages are at the bottom
			return yCanvasSize < yContainerSize or
				yCanvasSize - yScrolledPosition <= yContainerSize + 5 -- a little wiggle room
		end
		return false
	end

	function this:GetMessageCount()
		return this.MessageCount
	end

	function this:CalculateVisibility()
		local chatEnabled = true
		return this.WidgetVisible and ((chatEnabled and PlayersService.ClassicChat) or NON_CORESCRIPT_MODE)
	end

	function this:ToggleVisibility(visible)
		if visible ~= self.WidgetVisible then
			self.WidgetVisible = visible
			if this.ChatContainer then
				this.ChatContainer.Visible = self:CalculateVisibility()
			end
		end
		if NON_CORESCRIPT_MODE then
			this.ChatContainer.Visible = true
		end
	end

	function this:CoreGuiChanged(coreGuiType, enabled)
		if this.ChatContainer then
			this.ChatContainer.Visible = self:CalculateVisibility()
		end
	end

	local function CreateChatWindow()
		local container = Util.Create'Frame'
		{
			Name = 'ChatWindowContainer';
			Size = UDim2.new(0.3, 0, 0.25, 0);
			Position = UDim2.new(0, 8, 0, 37);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
		};
		if GetTopBarFlag() then
			container.Position = UDim2.new(0,0,0,37);
			container.BackgroundColor3 = Color3.new(31/255, 31/255, 31/255);
		end
		local scrollingFrame = Util.Create'ScrollingFrame'
		{
			Name = 'ChatWindow';
			Size = UDim2.new(1, -4 - 10, 1, -20);
			CanvasSize = UDim2.new(1, -4 - 10, 0, 0);
			Position = UDim2.new(0, 10, 0, 10);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
			BottomImage = "rbxasset://textures/ui/scroll-bottom.png";
			MidImage = "rbxasset://textures/ui/scroll-middle.png";
			TopImage = "rbxasset://textures/ui/scroll-top.png";
			ScrollBarThickness = 7;
			BorderSizePixel = 0;
			ScrollingEnabled = false;
			Parent = container;
		};
		local messageContainer = Util.Create'Frame'
		{
			Name = 'MessageContainer';
			Size = UDim2.new(1, -scrollingFrame.ScrollBarThickness - 1, 0, 0);
			Position = UDim2.new(0, 0, 1, 0);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
			Parent = scrollingFrame
		};

		-- This is some trickery we are doing to make the first chat messages appear at the bottom and go towards the top.
		local function OnChatWindowResize(prop)
			if prop == 'AbsoluteSize' then
				messageContainer.Position = UDim2.new(0, 0, 1, -messageContainer.Size.Y.Offset)
			end
			if prop == 'CanvasPosition' then
				if this.ScrollingFrame then
					if this:IsScrolledDown() then
						this.NewUnreadMessage = false
					end
				end
			end
		end
		container.Changed:connect(function(prop) if prop == 'AbsoluteSize' then this:OnResize() end end)

		local function RobloxClientScreenSizeChanged(newSize)
			if container then
				if GetTopBarFlag() then
					local placeIdCutoff = GetChatMovedUpPlaceIdCutoffFlag()
					if placeIdCutoff and game.PlaceId then
						if game.PlaceId < placeIdCutoff or placeIdCutoff == 0 then
							container.Position = UDim2.new(0,0,0,37);
						else
							container.Position = UDim2.new(0,0,0,37);
						end
					end
				end
				-- Phone
				if newSize.X <= 640 then
					container.Size = UDim2.new(0.5,0,0.5,0) - container.Position
					-- Tablet
				elseif newSize.X <= 1024 then
					container.Size = UDim2.new(0.4,0,0.3,0) - container.Position
					-- Desktop
				else
					container.Size = UDim2.new(0.3,0,0.25,0) - container.Position
				end
			end
		end

		GuiRoot.Changed:connect(function(prop) if prop == "AbsoluteSize" then RobloxClientScreenSizeChanged(GuiRoot.AbsoluteSize) end end)
		RobloxClientScreenSizeChanged(GuiRoot.AbsoluteSize)

		messageContainer.Changed:connect(OnChatWindowResize)
		scrollingFrame.Changed:connect(OnChatWindowResize)

		this.ChatContainer = container
		this.ScrollingFrame = scrollingFrame
		this.MessageContainer = messageContainer
		this.ChatContainer.Parent = GuiRoot

		--- BACKGROUND FADING CODE ---
		-- This is so we don't accidentally fade out when we are scrolling and mess with the scrollbar.
		local dontFadeOutOnMouseLeave = false

		if Util:IsTouchDevice() then
			--if not GetTopBarFlag() then
			local touchCount = 0
			this.InputBeganConn = InputService.InputBegan:connect(function(inputObject)
				if inputObject.UserInputType == Enum.UserInputType.Touch and inputObject.UserInputState == Enum.UserInputState.Begin then
					if PointInChatWindow(Vector2.new(inputObject.Position.X, inputObject.Position.Y)) then
						touchCount = touchCount + 1
						dontFadeOutOnMouseLeave = true
					end
				end
			end)

			this.InputEndedConn = InputService.InputEnded:connect(function(inputObject)
				if inputObject.UserInputType == Enum.UserInputType.Touch and inputObject.UserInputState == Enum.UserInputState.End then
					local endedCount = touchCount
					wait(2)
					if touchCount == endedCount then
						dontFadeOutOnMouseLeave = false
					end
				end
			end)

			spawn(function()
				local now = tick()
				while true do
					wait()
					now = tick()
					if this.BackgroundVisible then
						if not dontFadeOutOnMouseLeave then
							this:FadeOut(0.25)
						end
						-- If background is not visible/in-focus
					elseif this.ChatsVisible and now > lastChatActivity + MESSAGES_FADE_OUT_TIME then
						--if not GetTopBarFlag() then
						this:FadeOutChats()
						--end
					end
				end
			end)
			--end
		else
			this.LastMousePosition = Vector2.new()

			this.MouseEnterFrameConn = this.ChatContainer.MouseEnter:connect(function()
				lastEnterTime = tick()
				if this.BackgroundTweener and not this.BackgroundTweener:IsFinished() and not this.BackgroundVisible then
					this:FadeIn()
				end
			end)

			this.MouseMoveConn = InputService.InputChanged:connect(function(inputObject)
				if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
					lastMoveTime = tick()
					this.LastMousePosition = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
					if this.BackgroundTweener and this.BackgroundTweener:GetPercentComplete() < 0.5 and this.BackgroundVisible then
						if not dontFadeOutOnMouseLeave then
							this:FadeOut()
						end
					end
				end
			end)

			local clickCount = 0
			this.InputBeganConn = InputService.InputBegan:connect(function(inputObject)
				if inputObject.UserInputType == Enum.UserInputType.MouseButton1 and inputObject.UserInputState == Enum.UserInputState.Begin then
					if PointInChatWindow(Vector2.new(inputObject.Position.X, inputObject.Position.Y)) then
						clickCount = clickCount + 1
						dontFadeOutOnMouseLeave = true
					end
				end
			end)

			this.InputEndedConn = InputService.InputEnded:connect(function(inputObject)
				if inputObject.UserInputType == Enum.UserInputType.MouseButton1 and inputObject.UserInputState == Enum.UserInputState.End then
					local nowCount = clickCount
					wait(1.3)
					if nowCount == clickCount then
						dontFadeOutOnMouseLeave = false
					end
				end
			end)

			this.MouseLeaveFrameConn = this.ChatContainer.MouseLeave:connect(function()
				lastLeaveTime = tick()
				if this.BackgroundTweener and not this.BackgroundTweener:IsFinished() and this.BackgroundVisible then
					if not dontFadeOutOnMouseLeave then
						this:FadeOut()
					end
				end
			end)

			spawn(function()
				while true do
					wait()
					local now = tick()
					if this:IsHovering() then
						if now - lastMoveTime > 1.3 and not this.BackgroundVisible then
							this:FadeIn()
						end
					else -- not this:IsHovering()
						if this.BackgroundVisible then
							if not dontFadeOutOnMouseLeave then
								this:FadeOut(0.25)
							end
							-- If background is not visible/in-focus
						elseif this.ChatsVisible and now > lastChatActivity + MESSAGES_FADE_OUT_TIME then
							--if not GetTopBarFlag() then
							this:FadeOutChats()
							--end
						end
					end
				end
			end)
		end
		--- END OF BACKGROUND FADING CODE ---
	end

	CreateChatWindow()

	return this
end


local function CreateChat()
	local this = {}

	this.Settings =
		{
			GlobalTextColor = GetTopBarFlag() and Color3.new(112/255, 110/255, 106/255) or Color3.new(255/255, 255/255, 243/255);
			WhisperTextColor = GetTopBarFlag() and Color3.new(77/255, 139/255, 255/255) or Color3.new(77/255, 139/255, 255/255);
			TeamTextColor = Color3.new(230/255, 207/255, 0);
			DefaultMessageTextColor = Color3.new(255/255, 255/255, 243/255);
			AdminTextColor = Color3.new(1, 215/255, 0);
			TextStrokeTransparency = 0.75;
			TextStrokeColor = Color3.new(34/255,34/255,34/255);
			Font = Enum.Font.SourceSansBold;
			FontSize = Enum.FontSize.Size18;
			MaxWindowChatMessages = 50;
			MaxCharactersInMessage = 140;
		}

	this.BlockList = {}

	this.CurrentWindowMessageCountChanged = nil
	this.VisibilityStateChanged = Util.Signal()
	this.ChatBarFocusChanged = Util.Signal()
	--this.Visible = false

	function this:CoreGuiChanged(coreGuiType, enabled)
		if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
			if not GetTopBarFlag() then
				if Util:IsTouchDevice() then
					Util.SetGUIInsetBounds(0, 0)
				else
					if enabled and this.ChatBarWidget then
						-- Reserve bottom 20 pixels for our chat bar
						Util.SetGUIInsetBounds(0, 20)
					else
						Util.SetGUIInsetBounds(0, 0)
					end
				end
			end
			if GetTopBarFlag() then
				if true then
					pcall(function()
						--self.SpecialKeyPressedConn = Util.DisconnectEvent(self.SpecialKeyPressedConn)
						--GuiService:AddSpecialKey(Enum.SpecialKey.ChatHotkey)
						self.SpecialKeyPressedConn = game.UserInputService.InputBegan:connect(function(key, proc)
							if key.KeyCode == Enum.KeyCode.Slash and not proc then
								task.wait(.05)
								if self.Visible == false then
									self:ToggleVisibility()
								end
								if self.ChatBarWidget then
									self.ChatBarWidget:FocusChatBar()
								end
							end
						end)
					end)
				else
					--pcall(function() GuiService:RemoveSpecialKey(Enum.SpecialKey.ChatHotkey) end)
					self.SpecialKeyPressedConn = Util.DisconnectEvent(self.SpecialKeyPressedConn)
				end
			end
			if this.MobileChatButton then
				if enabled == true then
					this.MobileChatButton.Parent = GuiRoot
					-- we need to set it to be visible in-case we missed a lost focus event while chat was turned off.
					this.MobileChatButton.Visible = true
				else
					this.MobileChatButton.Parent = nil
				end
			end
		end
		if this.ChatWindowWidget then
			this.ChatWindowWidget:CoreGuiChanged(coreGuiType, true)
		end
		if this.ChatBarWidget then
			this.ChatBarWidget:CoreGuiChanged(coreGuiType, true)
		end
	end

	-- This event has 4 callback arguments
	-- Enum.PlayerChatType.{All|Team|Whisper}, chatPlayer, message, targetPlayer
	function this:OnPlayerChatted(playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
		if this.ChatWindowWidget then
			-- Don't add messages from blocked players
			if not this:IsPlayerBlocked(sendingPlayer) then
				this.ChatWindowWidget:AddChatMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
			end
		end
	end

	function this:OnPlayerAdded(newPlayer)
		if newPlayer then
			spawn(function() Util.IsPlayerAdminAsync(newPlayer) end)
		end
		--if NON_CORESCRIPT_MODE then
		--	newPlayer.Chatted:connect(function(msg, recipient)
		--		this:OnPlayerChatted(Enum.PlayerChatType.All, newPlayer, msg, recipient)
		--	end)
		--else
		--	this.PlayerChattedConn = Util.DisconnectEvent(this.PlayerChattedConn)
		--	this.PlayerChattedConn = PlayersService.PlayerChatted:connect(function(...)
		--		this:OnPlayerChatted(...)
		--	end)
		--end
	end

	function this:IsPlayerBlockedByUserId(userId)
		for _, currentBlockedUserId in pairs(this.BlockList) do
			if currentBlockedUserId == userId then
				return true
			end
		end
		return false
	end

	function this:IsPlayerBlocked(player)
		return player and this:IsPlayerBlockedByUserId(player.userId)
	end

	function this:GetBlockedPlayersAsync()
		local userId = Player.userId
		local secureBaseUrl = Util.GetSecureApiBaseUrl()
		local url = secureBaseUrl .. "userblock/getblockedusers" .. "?" .. "userId=" .. tostring(userId) .. "&" .. "page=" .. "1"
		if userId > 0 then
			local blockList = nil
			local success, msg = ypcall(function()
				local request = game:HttpGetAsync(url)
				blockList = request and game:GetService('HttpService'):JSONDecode(request)
			end)
			if blockList and blockList['success'] == true and blockList['userList'] then
				return blockList['userList']
			end
		end
		return {}
	end

	function this:BlockPlayerAsync(playerToBlock)
		--if playerToBlock and Player ~= playerToBlock then
		--	local blockUserId = playerToBlock.userId
		--	local playerToBlockName = playerToBlock.Name
		--	if blockUserId > 0 then
		--		if not this:IsPlayerBlockedByUserId(blockUserId) then
		--			-- TODO: We may want to use a more dynamic way of changing the blockList size.
		--			--if #this.BlockList < MAX_BLOCKLIST_SIZE then
		--				table.insert(this.BlockList, blockUserId)
		--				this.ChatWindowWidget:AddSystemChatMessage(playerToBlockName .. " is now blocked.")
		--				-- Make Block call
		--				pcall(function()
		--					local success = PlayersService:BlockUser(Player.userId, blockUserId)
		--				end)
		--			--else
		--			--	this.ChatWindowWidget:AddSystemChatMessage("You cannot block " .. playerToBlockName .. " because your list is full.")
		--			--end
		--		else
		--			this.ChatWindowWidget:AddSystemChatMessage(playerToBlockName .. " is already blocked.")
		--		end
		--	else
		--		this.ChatWindowWidget:AddSystemChatMessage("You cannot block guests.")
		--	end
		--else
		--	this.ChatWindowWidget:AddSystemChatMessage("You cannot block yourself.")
		--end
	end

	function this:UnblockPlayerAsync(playerToUnblock)
		if playerToUnblock then
			--local unblockUserId = playerToUnblock.userId
			--local playerToUnblockName = playerToUnblock.Name

			--if this:IsPlayerBlockedByUserId(unblockUserId) then
			--	local blockedUserIndex = nil
			--	for index, blockedUserId in pairs(this.BlockList) do
			--		if blockedUserId == unblockUserId then
			--			blockedUserIndex = index
			--		end
			--	end
			--	if blockedUserIndex then
			--		table.remove(this.BlockList, blockedUserIndex)
			--	end
			--	this.ChatWindowWidget:AddSystemChatMessage(playerToUnblockName .. " is no longer blocked.")
			--	-- Make Unblock call
			--	pcall(function()
			--		local success = PlayersService:UnblockUser(Player.userId, unblockUserId)
			--	end)
			--else
			--	this.ChatWindowWidget:AddSystemChatMessage(playerToUnblockName .. " is not blocked.")
			--end
		end
	end

	function this:CreateTouchDeviceChatButton()
		return Util.Create'ImageButton'
		{
			Name = 'TouchDeviceChatButton';
			Size = UDim2.new(0, 128, 0, 32);
			Position = UDim2.new(0, 88, 0, 0);
			BackgroundTransparency = 1.0;
			Image = 'http://www.roblox.com/asset/?id=97078724';
		};
	end

	function this:PrintWelcome()
		if this.ChatWindowWidget then
			if Util.IsTouchDevice() then
				this.ChatWindowWidget:AddSystemChatMessage("Please press the '...' icon to chat", true)
			end
			this.ChatWindowWidget:AddSystemChatMessage("Please chat '/?' for a list of commands", true)
		end
	end

	function this:PrintHelp()
		if this.ChatWindowWidget then
			this.ChatWindowWidget:AddSystemChatMessage("Help Menu")
			this.ChatWindowWidget:AddSystemChatMessage("Chat Commands:")
			this.ChatWindowWidget:AddSystemChatMessage("/w [PlayerName] or /whisper [PlayerName] - Whisper Chat")
			this.ChatWindowWidget:AddSystemChatMessage("/t or /team - Team Chat")
			this.ChatWindowWidget:AddSystemChatMessage("/a or /all - All Chat")

			this.ChatWindowWidget:AddSystemChatMessage("/block [PlayerName] or /ignore [PlayerName] - Block communications from Target Player")
			this.ChatWindowWidget:AddSystemChatMessage("/unblock [PlayerName] or /unignore [PlayerName] - Restore communications with Target Player")
		end
	end

	local focusCount = 0
	function this:CreateGUI()
		if FORCE_CHAT_GUI or true then
			-- NOTE: eventually we will make multiple chat window frames
			this.ChatWindowWidget = CreateChatWindowWidget(this.Settings)
			this.ChatBarWidget = CreateChatBarWidget(this.Settings)
			this.CurrentWindowMessageCountChanged = this.ChatWindowWidget.MessageCountChanged

			if GetTopBarFlag() then
				this.ChatWindowWidget.FadeInSignal:connect(function()
					this.ChatBarWidget:FadeIn()
				end)
				this.ChatWindowWidget.FadeOutSignal:connect(function()
					this.ChatBarWidget:FadeOut()
				end)
			end

			--if not GetTopBarFlag() then
			this.ChatWindowWidget:FadeOut(0)
			this.ChatBarWidget.ChatBarGainedFocusEvent:connect(function()
				focusCount = focusCount + 1
				this.ChatWindowWidget:FadeIn(0.25)
				this.ChatWindowWidget:SetFadeLock(true)
				this.ChatBarFocusChanged:fire(true)
			end)
			this.ChatBarWidget.ChatBarLostFocusEvent:connect(function()
				local focusNow = focusCount
				if Util:IsTouchDevice() then
					delay(2, function()
						if focusNow == focusCount then
							this.ChatWindowWidget:SetFadeLock(false)
						end
					end)
				else
					this.ChatWindowWidget:SetFadeLock(false)
				end
				this.ChatBarFocusChanged:fire(false)
			end)
			this.ChatBarWidget.ChatBarFloodEvent:connect(function()
				if this.ChatWindowWidget then
					this.ChatWindowWidget:AddSystemChatMessage("Wait before sending another message.")
				end
			end)
			--else
			--	this.ChatWindowWidget:FadeIn(0)
			--end

			this.ChatBarWidget.ChatErrorEvent:connect(function(msg)
				if msg then
					this.ChatWindowWidget:AddSystemChatMessage(msg)
				end
			end)

			this.ChatBarWidget.ChatCommandEvent:connect(function(success, actionType, capture)
				if actionType == "Help" then
					this:PrintHelp()
				elseif actionType == "Block" then
					local blockPlayerName = capture and tostring(capture) or ""
					local playerToBlock = Util.GetPlayerByName(blockPlayerName)
					if playerToBlock then
						spawn(function() this:BlockPlayerAsync(playerToBlock) end)
					else
						this.ChatWindowWidget:AddSystemChatMessage("Cannot block " .. blockPlayerName .. " because they are not in the game.")
					end
				elseif actionType == "Unblock" then
					local unblockPlayerName = capture and tostring(capture) or ""
					local playerToBlock = Util.GetPlayerByName(unblockPlayerName)
					if playerToBlock then
						spawn(function() this:UnblockPlayerAsync(playerToBlock) end)
					else
						this.ChatWindowWidget:AddSystemChatMessage("Cannot unblock " .. unblockPlayerName .. " because they are not in the game.")
					end
				elseif actionType == "Whisper" then
					if success == false then
						local playerName = capture and tostring(capture) or "Unknown"
						this.ChatWindowWidget:AddSystemChatMessage("Unable to Send a Whisper to Player: " .. playerName)
					end
				elseif actionType == "Unknown" then
					if success == false then
						local commandText = capture and tostring(capture) or "Unknown"
						this.ChatWindowWidget:AddSystemChatMessage("Invalid Slash Command: " .. commandText)
					end
				end
			end)

			if Util.IsTouchDevice() and not GetTopBarFlag() then
				local mobileChatButton = this:CreateTouchDeviceChatButton()
				if StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat) then
					mobileChatButton.Parent = GuiRoot
				end

				mobileChatButton.TouchTap:connect(function()
					mobileChatButton.Visible = false
					if this.ChatBarWidget then
						this.ChatBarWidget:FocusChatBar()
					end
				end)

				this.ChatBarWidget.ChatBarLostFocusEvent:connect(function()
					mobileChatButton.Visible = true
				end)

				this.MobileChatButton = mobileChatButton
			end
		end
	end

	local toggleCount = 0
	local function SetVisbility(newVisibility)
		this.Visible = newVisibility
		if this.ChatWindowWidget then
			this.ChatWindowWidget:ToggleVisibility(this.Visible)
			if this.Visible then
				toggleCount = toggleCount + 1
				local thisToggle = toggleCount
				local thisFocusCount = focusCount
				this.ChatWindowWidget:FadeIn()
				this.ChatWindowWidget:SetFadeLock(true)
				delay(5, function()
					if thisToggle == toggleCount and thisFocusCount == focusCount then
						this.ChatWindowWidget:SetFadeLock(false)
					end
				end)
			end
		end
		if this.ChatBarWidget then
			this.ChatBarWidget:ToggleVisibility(this.Visible)
			if this.Visible then
				this.ChatBarWidget:FadeIn()
			end
		end
		this.VisibilityStateChanged:fire(this.Visible)
	end

	function this:ToggleVisibility()
		SetVisbility(not self.Visible)
	end

	function this:FocusChatBar()
		if self.ChatBarWidget and this.Visible then
			self.ChatBarWidget:FocusChatBar()
		end
	end

	function this:GetCurrentWindowMessageCount()
		if this.ChatWindowWidget then
			return this.ChatWindowWidget:GetMessageCount()
		end
		return 0
	end

	function this:Initialize()
		spawn(function()
			this.BlockList = this:GetBlockedPlayersAsync()
		end)

		this:OnPlayerAdded(Player)
		-- Upsettingly, it seems everytime a player is added, you have to redo the connection
		-- NOTE: PlayerAdded only fires on the server, hence ChildAdded is used here
		--PlayersService.ChildAdded:connect(function(child)
		--	if child:IsA('Player') then
		--		this:OnPlayerAdded(child)
		--	end
		--end)
		this:CreateGUI()

		RBXGeneral.MessageReceived:Connect(function(msg)
			if not msg.TextSource then return end
			if msg.Status ~= Enum.TextChatMessageStatus.Success then return end

			local plr = nil
			local ok, result = pcall(function()
				return PlayersService:GetPlayerByUserId(msg.TextSource.UserId)
			end)
			if ok then
				plr = result
			end
			if not plr then return end

			this:OnPlayerChatted(Enum.PlayerChatType.All, plr, msg.Text, nil)
		end)

		-- playerChatType, sendingPlayer, chattedMessage, receivingPlayer

		this:CoreGuiChanged(Enum.CoreGuiType.Chat, true)
		--this.CoreGuiChangedConn = Util.DisconnectEvent(this.CoreGuiChangedConn)
		--pcall(function()
		--	this.CoreGuiChangedConn = StarterGui.CoreGuiChangedSignal:connect(
		--		function(coreGuiType,enabled)
		--			this:CoreGuiChanged(coreGuiType, enabled)
		--		end)
		--end)

		if not NON_CORESCRIPT_MODE then
			this:PrintWelcome()
		end

		--SetVisbility(true)
	end

	return this
end


local moduleApiTable = {}
-- Main Entry Point
do
	local ChatInstance = CreateChat()
	ChatInstance:Initialize()

	function moduleApiTable:ToggleVisibility()
		ChatInstance:ToggleVisibility()
	end

	function moduleApiTable:FocusChatBar()
		ChatInstance:FocusChatBar()
	end

	function moduleApiTable:GetVisibility()
		return ChatInstance.Visible
	end

	function moduleApiTable:GetMessageCount()
		return ChatInstance:GetCurrentWindowMessageCount()
	end

	moduleApiTable.ChatBarFocusChanged = ChatInstance.ChatBarFocusChanged
	moduleApiTable.VisibilityStateChanged = ChatInstance.VisibilityStateChanged
	moduleApiTable.MessagesChanged = ChatInstance.CurrentWindowMessageCountChanged
end

return moduleApiTable


end;
};
-- StarterGui.RobloxGui.Topbar
local function C_6()
local script = G2L["6"];
	--[[
		// FileName: Topbar.lua
		// Written by: SolarCrane
		// Description: Code for lua side Top Menu items in ROBLOX.
	]]
	
	
	--[[ MODERN COMPATIBILITY PATCH (2026) ]]
	-- This script is intended to run as a LocalScript under StarterGui > RobloxGui.
	-- The 2015 CoreScript depended on privileged CoreGui modules and internal FFlags.
	-- These compatibility shims keep the original visual structure while gracefully
	-- disabling unavailable internal pieces.
	
	local function safeRequire(moduleScript)
		if not moduleScript or not moduleScript:IsA("ModuleScript") then
			return nil
		end
		local ok, result = pcall(require, moduleScript)
		return ok and result or nil
	end
	
	local function findModule(name)
		local root = script.Parent
		local modules = root and root:FindFirstChild("Modules")
		if not modules then
			local robloxGui = script:FindFirstAncestor("RobloxGui")
			modules = robloxGui and robloxGui:FindFirstChild("Modules")
		end
		return modules and modules:FindFirstChild(name)
	end
	
	
	local function requireModule(name)
		local moduleScript = findModule(name)
		if not moduleScript then
			warn("[2015 Topbar] Modules." .. name .. " is missing")
			return nil
		end
	
		local ok, result = pcall(require, moduleScript)
		if not ok then
			warn("[2015 Topbar] " .. name .. " require failed: " .. tostring(result))
			return nil
		end
	
		return result
	end
	
	-- 2015M Topbar modules.
	local ChatModule = requireModule("Chat")
	local PlayerlistModule = requireModule("PlayerlistModule")
	
	local function connectModuleSignal(signal, callback)
		if not signal then return nil end
	
		if typeof(signal) == "RBXScriptSignal" then
			return signal:Connect(callback)
		end
	
		if typeof(signal) == "Instance" and signal:IsA("BindableEvent") then
			return signal.Event:Connect(callback)
		end
	
		if type(signal) == "table" then
			if signal.Connect then
				return signal:Connect(callback)
			elseif signal.connect then
				return signal:connect(callback)
			end
		end
	
		return nil
	end
	
	--[[ CONSTANTS ]]
	
	local TOPBAR_THICKNESS = 36
	local USERNAME_CONTAINER_WIDTH = 170
	local COLUMN_WIDTH = 75
	local NAME_LEADERBOARD_SEP_WIDTH = 2
	
	local FONT_COLOR = Color3.new(1,1,1)
	local TOPBAR_BACKGROUND_COLOR = Color3.new(31/255,31/255,31/255)
	local TOPBAR_OPAQUE_TRANSPARENCY = 0
	local TOPBAR_TRANSLUCENT_TRANSPARENCY = 0.5
	
	local HEALTH_BACKGROUND_COLOR = Color3.new(228/255, 236/255, 246/255)
	local HEALTH_RED_COLOR = Color3.new(226/255, 73/255, 41/255)
	local HEALTH_YELLOW_COLOR = Color3.new(250/255, 235/255, 0)
	local HEALTH_GREEN_COLOR = Color3.new(27/255, 252/255, 107/255)
	
	local HEALTH_PERCANTAGE_FOR_OVERLAY = 5 / 100
	
	local HURT_OVERLAY_IMAGE = "http://www.roblox.com/asset/?id=34854607"
	
	--[[ END OF CONSTANTS ]]
	
	--[[ FFLAG VALUES - compatibility defaults ]]
	local useNewSettings = findModule("Settings2") ~= nil
	local useNewBackpack = findModule("BackpackScript") ~= nil
	local useNewPlayerlist = PlayerlistModule ~= nil
	
	local function GetBubbleChatbarFlag()
		return false
	end
	--[[ END OF FFLAG VALUES ]]
	
	
	--[[ SERVICES ]]
	
	local CoreGuiService = game:GetService('CoreGui')
	local PlayersService = game:GetService('Players')
	local GuiService = game:GetService('GuiService')
	local InputService = game:GetService('UserInputService')
	local StarterGui = game:GetService('StarterGui')
	
	--[[ END OF SERVICES ]]
	
	
	local GameSettings = UserSettings().GameSettings
	local Player = PlayersService.LocalPlayer
	while Player == nil do
		wait()
		Player = PlayersService.LocalPlayer
	end
	
	local requestedRoot = script.Parent
	local GuiRoot = nil
	
	-- A Frame only renders when it ultimately lives under a LayerCollector such as ScreenGui.
	-- Prefer the RobloxGui ScreenGui itself; otherwise create a private host in PlayerGui.
	if requestedRoot and requestedRoot:IsA("LayerCollector") then
		GuiRoot = requestedRoot
	else
		GuiRoot = script:FindFirstAncestorWhichIsA("LayerCollector")
	end
	
	if not GuiRoot then
		local playerGui = Player:WaitForChild("PlayerGui")
		local oldHost = playerGui:FindFirstChild("Legacy2015TopbarHost")
		if oldHost and oldHost:IsA("ScreenGui") then
			GuiRoot = oldHost
		else
			GuiRoot = Instance.new("ScreenGui")
			GuiRoot.Name = "Legacy2015TopbarHost"
			GuiRoot.Parent = playerGui
		end
	end
	
	if GuiRoot:IsA("ScreenGui") then
		GuiRoot.Enabled = true
		GuiRoot.IgnoreGuiInset = true
		GuiRoot.ResetOnSpawn = false
		GuiRoot.DisplayOrder = math.max(GuiRoot.DisplayOrder, 100)
		GuiRoot.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	end
	
	local Util = {}
	do
		-- Check if we are running on a touch device
		function Util.IsTouchDevice()
			return InputService.TouchEnabled
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
				conn:Disconnect()
			end
			return nil
		end
	
		function Util.SetGUIInsetBounds(x1, y1, x2, y2)
			pcall(function() GuiService:SetGlobalGuiInset(x1, y1, x2, y2) end)
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
	
	local function CreateTopBar()
		local this = {}
	
		local playerGuiChangedConn = nil
	
		local topbarContainer = Util.Create'Frame'{
			Name = "TopBarContainer";
			Size = UDim2.new(1, 0, 0, TOPBAR_THICKNESS);
			Position = UDim2.new(0, 0, 0, 0); -- CoreGui used a negative offset; cloned ScreenGui should sit at y=0
			BackgroundTransparency = TOPBAR_OPAQUE_TRANSPARENCY;
			BackgroundColor3 = TOPBAR_BACKGROUND_COLOR;
			BorderSizePixel = 0;
			Active = true;
			Visible = true;
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
	
		local function UpdateBackgroundTransparency()
			-- GetTopbarTransparency/TopbarTransparencyChangedSignal were CoreScript-era APIs.
			-- Keep the legacy recreation's own chosen transparency instead of depending on them.
			topbarContainer.Visible = true
			topbarShadow.Visible = (topbarContainer.BackgroundTransparency == 0)
		end
	
		function this:GetInstance()
			return topbarContainer
		end
	
		function this:SetTopbarDisplayMode(opaque)
			topbarContainer.BackgroundTransparency = opaque and TOPBAR_OPAQUE_TRANSPARENCY or TOPBAR_TRANSLUCENT_TRANSPARENCY
			topbarShadow.Visible = not opaque
			UpdateBackgroundTransparency()
		end
	
		task.spawn(function()
			local playerGui = Player:WaitForChild('PlayerGui')
			playerGuiChangedConn = Util.DisconnectEvent(playerGuiChangedConn)
			pcall(function()
				playerGuiChangedConn = playerGui.TopbarTransparencyChangedSignal:Connect(UpdateBackgroundTransparency)
			end)
			UpdateBackgroundTransparency()
		end)
	
		return this
	end
	
	local function CreateMenuBar(barAlignment)
		local this = {}
		local thickness = TOPBAR_THICKNESS
		local alignment = (barAlignment == 'Right' and 'Right' or 'Left')
		local items = {}
		local propertyChangedConnections = {}
		local dock = nil
	
		local function ArrangeItems()
			local totalWidth = 0
			for i, item in pairs(items) do
				local width = item:GetWidth()
				if alignment == 'Left' then
					item.Position = UDim2.new(0, totalWidth, 0, 0)
				else -- Right
					item.Position = UDim2.new(1, -totalWidth - width, 0, 0)
				end
	
				totalWidth = totalWidth + width
			end
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
	
		function this:AddItem(item, index)
			local numItems = self:GetNumberOfItems()
			index = Util.Clamp(1, numItems + 1, (index or numItems + 1))
	
			local alreadyFoundIndex = self:IndexOfItem(item)
			if alreadyFoundIndex then
				return item, index
			end
	
			table.insert(items, index, item)
			Util.DisconnectEvent(propertyChangedConnections[item])
			propertyChangedConnections[item] = item.Changed:Connect(function(property)
				if property == 'AbsoluteSize' then
					ArrangeItems()
				end
			end)
			ArrangeItems()
	
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
	
				ArrangeItems()
				return removedItem, index
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
	
	
	----- HEALTH -----
	local function CreateUsernameHealthMenuItem()
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
			TextSize = 14;
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
			if hurtOverlay then
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
				else
					hurtOverlay.Size = newSize
					hurtOverlay.Position = newPos
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
	
					if healthDelta >= thresholdForHurtOverlay and health ~= humanoid.MaxHealth then
						AnimateHurtOverlay()
					end
					healthFill.BackgroundColor3 = healthColor
					healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
	
					lastHealth = health
				end
			end
			Util.DisconnectEvent(humanoidChangedConn)
			humanoidChangedConn = humanoid.HealthChanged:Connect(OnHumanoidHealthChanged)
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
			childAddedConn = character.ChildAdded:Connect(onChildAddedOrRemoved)
			childRemovedConn = character.ChildRemoved:Connect(onChildAddedOrRemoved)
		end
	
		local mtStore = getmetatable(this)
		setmetatable(this, {})
		function this:SetHealthbarEnabled(enabled)
			healthContainer.Visible = enabled
			if enabled then
				username.Size = UDim2.new(1, -14, 0, 22);
				username.TextYAlignment = Enum.TextYAlignment.Bottom;
			else
				username.Size = UDim2.new(1, -14, 1, 0);
				username.TextYAlignment = Enum.TextYAlignment.Center;
			end
		end
	
		function this:SetNameVisible(visible)
			username.Visible = visible
		end
	
		setmetatable(this, mtStore)
	
		-- Don't need to disconnect this one because we never reconnect it.
		Player.CharacterAdded:Connect(OnCharacterAdded)
		if Player.Character then
			OnCharacterAdded(Player.Character)
		end
	
		if useNewPlayerlist and PlayerlistModule and type(PlayerlistModule.ToggleVisibility) == "function" then
			container.MouseButton1Click:Connect(function()
				local ok, err = pcall(PlayerlistModule.ToggleVisibility)
				if not ok then
					warn("[2015 Topbar] PlayerlistModule.ToggleVisibility failed: " .. tostring(err))
				end
			end)
		end
	
		return this
	end
	----- END OF HEALTH -----
	
	----- LEADERSTATS -----
	local function CreateLeaderstatsMenuItem()
		if not PlayerlistModule then return nil end
	
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
	
		local mtStore = getmetatable(this)
		setmetatable(this, {})
		function this:SetColumns(columnsList)
			-- Should we handle is the screen dimensions change and it is no longer a small touch device after we set columns?
			local isSmallTouchDevice = Util.IsTouchDevice() and workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y < 500
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
							TextSize = 14;
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
							TextSize = 14;
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
		end
	
		function this:UpdateColumnValue(columnName, value)
			local column = columns[columnName]
			local columnValue = column and column:FindFirstChild('ColumnValue')
			if columnValue then
				columnValue.Text = tostring(value)
			end
		end
		setmetatable(this, mtStore)
	
		this:SetColumns(PlayerlistModule.GetStats())
		if PlayerlistModule.OnLeaderstatsChanged then
			connectModuleSignal(PlayerlistModule.OnLeaderstatsChanged, function(newStatColumns)
				this:SetColumns(newStatColumns)
			end)
		end
	
		if PlayerlistModule.OnStatChanged then
			connectModuleSignal(PlayerlistModule.OnStatChanged, function(statName, statValueAsString)
				this:UpdateColumnValue(statName, statValueAsString)
			end)
		end
	
		leaderstatsContainer.MouseButton1Click:Connect(function()
			if type(PlayerlistModule.ToggleVisibility) == "function" then
				local ok, err = pcall(PlayerlistModule.ToggleVisibility)
				if not ok then
					warn("[2015 Topbar] PlayerlistModule.ToggleVisibility failed: " .. tostring(err))
				end
			end
		end)
	
		return this
	end
	----- END OF LEADERSTATS -----
	
	--- SETTINGS ---
	local function CreateSettingsIcon()
		local settingsIconButton = Util.Create'ImageButton'
		{
			Name = "Settings";
			Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
			Image = "";
			AutoButtonColor = false;
			BackgroundTransparency = 1;
		};
	
		local settingsIconImage = Util.Create'ImageLabel'
		{
			Name = "SettingsIcon";
			Size = UDim2.new(0, 32, 0, 25);
			Position = UDim2.new(0.5, -16, 0.5, -12);
			BackgroundTransparency = 1;
			Image = "rbxasset://textures/ui/Menu/Hamburger.png";
			ZIndex = 2;
			Parent = settingsIconButton;
		};
	
		local settingsActive = false
		local MenuModule = nil
	
		local function UpdateHamburgerIcon()
			settingsIconImage.Image = settingsActive
				and "rbxasset://textures/ui/Menu/HamburgerDown.png"
				or "rbxasset://textures/ui/Menu/Hamburger.png"
		end
	
		-- Create the visible button first, then try to load Settings2.
		local settingsModuleObject = findModule("Settings2")
		if settingsModuleObject then
			local ok, result = pcall(require, settingsModuleObject)
			if ok then
				MenuModule = result
	
				if MenuModule.SettingsShowSignal then
					local signal = MenuModule.SettingsShowSignal
	
					if typeof(signal) == "RBXScriptSignal" then
						signal:Connect(function(active)
							settingsActive = active and true or false
							UpdateHamburgerIcon()
						end)
					elseif typeof(signal) == "Instance" and signal:IsA("BindableEvent") then
						signal.Event:Connect(function(active)
							settingsActive = active and true or false
							UpdateHamburgerIcon()
						end)
					elseif type(signal) == "table" then
						-- 2015M Settings2 uses its own Signal() implementation with
						-- lowercase :connect(), not RBXScriptSignal:Connect().
						if signal.Connect then
							signal:Connect(function(active)
								settingsActive = active and true or false
								UpdateHamburgerIcon()
							end)
						elseif signal.connect then
							signal:connect(function(active)
								settingsActive = active and true or false
								UpdateHamburgerIcon()
							end)
						end
					end
				end
			else
				warn("[2015 Topbar] Settings2 require failed: " .. tostring(result))
			end
		else
			warn("[2015 Topbar] Modules.Settings2 is missing")
		end
	
		local function toggleSettings()
			if not MenuModule then
				warn("[2015 Topbar] Menu button clicked, but Settings2 is unavailable")
				return false
			end

			local currentlyVisible = settingsActive
			if type(MenuModule.GetVisibility) == "function" then
				local readOk, value = pcall(function()
					return MenuModule:GetVisibility()
				end)
				if readOk then
					currentlyVisible = value == true
				end
			end

			local targetVisible = not currentlyVisible
			local ok, err = pcall(function()
				MenuModule:ToggleVisibility(targetVisible)
			end)

			if not ok then
				warn("[2015 Topbar] Settings2 ToggleVisibility failed: " .. tostring(err))
				return currentlyVisible
			end

			settingsActive = targetVisible
			UpdateHamburgerIcon()
			return settingsActive
		end
	
		settingsIconButton.MouseButton1Click:Connect(toggleSettings)
	
		UpdateHamburgerIcon()
		return CreateMenuItem(settingsIconButton)
	end
	------------
	
	--- CHAT ---
	local function CreateChatIcon()
		local chatIconButton = Util.Create'ImageButton'
		{
			Name = "Chat";
			Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
			Image = "";
			AutoButtonColor = false;
			BackgroundTransparency = 1;
		};
	
		local chatIconImage = Util.Create'ImageLabel'
		{
			Name = "ChatIcon";
			Size = UDim2.new(0, 28, 0, 27);
			Position = UDim2.new(0.5, -14, 0.5, -13);
			BackgroundTransparency = 1;
			Image = "rbxasset://textures/ui/Chat/Chat.png";
			ZIndex = 2;
			Parent = chatIconButton;
		};
	
		local chatCounter = Util.Create'ImageLabel'
		{
			Name = "ChatCounter";
			Size = UDim2.new(0, 18, 0, 18);
			Position = UDim2.new(1, -12, 0, -4);
			BackgroundTransparency = 1;
			Image = "rbxasset://textures/ui/Chat/MessageCounter.png";
			Visible = false;
			ZIndex = 3;
			Parent = chatIconImage;
		};
	
		local chatCountText = Util.Create'TextLabel'
		{
			Name = "ChatCounterText";
			Text = "";
			Size = UDim2.new(0, 13, 0, 9);
			Position = UDim2.new(0.5, -7, 0.5, -7);
			Font = Enum.Font.SourceSansBold;
			TextSize = 14;
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			TextColor3 = FONT_COLOR;
			TextYAlignment = Enum.TextYAlignment.Center;
			TextXAlignment = Enum.TextXAlignment.Center;
			ZIndex = 4;
			Parent = chatCounter;
		};
	
		local chatActive = false
		local lastMessageCount = 0
		local debounce = 0
		local DEBOUNCE_TIME = 0.25
	
		local function callChat(methodName, ...)
			if not ChatModule then
				return false, nil
			end
	
			local method = ChatModule[methodName]
			if type(method) ~= "function" then
				return false, nil
			end
	
			local ok, result = pcall(method, ChatModule, ...)
			if not ok then
				-- Some old modules expose plain functions instead of colon-methods.
				ok, result = pcall(method, ...)
			end
	
			if not ok then
				warn("[2015 Topbar] Chat." .. methodName .. " failed: " .. tostring(result))
			end
	
			return ok, result
		end
	
		local function getMessageCount()
			local ok, count = callChat("GetMessageCount")
			return ok and tonumber(count) or 0
		end
	
		local function updateUnread(count)
			count = tonumber(count) or 0
	
			if chatActive then
				lastMessageCount = count
			end
	
			local unreadCount = count - lastMessageCount
			if unreadCount <= 0 then
				chatCountText.Text = ""
				chatCounter.Visible = false
			elseif unreadCount < 100 then
				chatCountText.Text = tostring(unreadCount)
				chatCounter.Visible = true
			else
				chatCountText.Text = "!"
				chatCounter.Visible = true
			end
		end
	
		local function updateIcon(down)
			chatIconImage.Image = down
				and "rbxasset://textures/ui/Chat/ChatDown.png"
				or "rbxasset://textures/ui/Chat/Chat.png"
		end
	
		local function onChatStateChanged(visible)
			chatActive = visible and true or false
			if not Util.IsTouchDevice() then
				updateIcon(chatActive)
			end
			updateUnread(getMessageCount())
		end
	
		chatIconButton.MouseButton1Click:Connect(function()
			if not ChatModule then
				warn("[2015 Topbar] Menu Chat button clicked, but Modules.Chat is unavailable")
				return
			end
	
			if Util.IsTouchDevice() then
				if debounce + DEBOUNCE_TIME < tick() then
					callChat("FocusChatBar")
				end
			else
				callChat("ToggleVisibility")
			end
		end)
	
		if ChatModule then
			connectModuleSignal(ChatModule.MessagesChanged, updateUnread)
	
			connectModuleSignal(ChatModule.ChatBarFocusChanged, function(isFocused)
				if Util.IsTouchDevice() then
					updateIcon(isFocused)
					debounce = tick()
				end
			end)
	
			connectModuleSignal(ChatModule.VisibilityStateChanged, onChatStateChanged)
	
			local okVisible, visible = callChat("GetVisibility")
			if okVisible then
				onChatStateChanged(visible)
			else
				updateIcon(false)
			end
	
			updateUnread(getMessageCount())
	
			-- Match the original 2015 Topbar behavior: initialize chat visible.
			callChat("ToggleVisibility", true)
		else
			updateIcon(false)
		end
	
		return CreateMenuItem(chatIconButton)
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
		};
	
		local backpackIconImage = Util.Create'ImageLabel'
		{
			Name = "BackpackIcon";
			Size = UDim2.new(0, 22, 0, 28);
			Position = UDim2.new(0.5, -11, 0.5, -14);
			BackgroundTransparency = 1;
			Image = "rbxasset://textures/ui/Backpack/Backpack.png";
			ZIndex = 2;
			Parent = backpackIconButton;
		};
	
		local BackpackModule = nil
	
		local function setBackpackIcon(open)
			backpackIconImage.Image = open
				and "rbxasset://textures/ui/Backpack/Backpack_Down.png"
				or "rbxasset://textures/ui/Backpack/Backpack.png"
		end
	
		-- Require AFTER the visual button exists.
		-- A broken BackpackScript must never make the button disappear.
		local backpackModuleObject = findModule("BackpackScript")
		if backpackModuleObject then
			local ok, result = pcall(require, backpackModuleObject)
			if ok then
				BackpackModule = result
	
				if BackpackModule.StateChanged and BackpackModule.StateChanged.Event then
					BackpackModule.StateChanged.Event:Connect(setBackpackIcon)
				end
			else
				warn("[2015 Topbar] BackpackScript require failed: " .. tostring(result))
			end
		else
			warn("[2015 Topbar] Modules.BackpackScript is missing")
		end
	
		backpackIconButton.MouseButton1Click:Connect(function()
			if BackpackModule and type(BackpackModule.OpenClose) == "function" then
				local ok, err = pcall(BackpackModule.OpenClose)
				if not ok then
					warn("[2015 Topbar] Backpack OpenClose failed: " .. tostring(err))
				end
			else
				warn("[2015 Topbar] Backpack button clicked, but BackpackScript is unavailable")
			end
		end)
	
		setBackpackIcon(false)
		return CreateMenuItem(backpackIconButton)
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
		-- SetVerb was removed; recording toggle is not exposed to normal LocalScripts.
	
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
	
	----- Shift Lock ------
	local function CreateShiftLockIcon()
		local shiftlockIconButton = Util.Create'ImageButton'
		{
			Name = "ShiftLock";
			Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
			AutoButtonColor = false;
			Image = "";
			BackgroundTransparency = 1;
		};
	
		local shiftlockIconLabel = Util.Create'ImageLabel'
		{
			Name = "ShiftlockIcon";
			Size = UDim2.new(0, 31, 0, 31);
			Position = UDim2.new(0.5, -15, 0.5, -15);
			BackgroundTransparency = 1;
			Image = "rbxasset://textures/ui/ShiftLock/ShiftLock.png";
			Parent = shiftlockIconButton;
		};
	
		local shiftlockActive = false
		shiftlockIconButton.MouseButton1Click:Connect(function()
			if shiftlockActive == false then
				shiftlockActive = true
				shiftlockIconLabel.Image = "rbxasset://textures/ui/ShiftLock/ShiftLockDown.png";
			else
				shiftlockActive = false
				shiftlockIconLabel.Image = "rbxasset://textures/ui/ShiftLock/ShiftLock.png";
			end
		end)
	
		return CreateMenuItem(shiftlockIconButton)
	end
	----------------------
	
	-- Create the actual bar FIRST. Optional 2015 modules are allowed to fail afterward.
	local TopBar = CreateTopBar()
	local LeftMenubar = CreateMenuBar('Left')
	local RightMenubar = CreateMenuBar('Right')
	
	LeftMenubar:SetDock(TopBar:GetInstance())
	RightMenubar:SetDock(TopBar:GetInstance())
	
	local function safeCreate(label, creator)
		local ok, result = pcall(creator)
		if not ok then
			warn("[2015 Topbar] " .. label .. " failed: " .. tostring(result))
			return nil
		end
		return result
	end
	
	local settingsIcon = safeCreate("Settings", CreateSettingsIcon)
	local chatIcon = safeCreate("Chat", CreateChatIcon)
	local backpackIcon = safeCreate("Backpack", CreateBackpackIcon)
	--local shiftlockIcon = safeCreate("ShiftLock", CreateShiftLockIcon)
	local shiftlockIcon = nil
	local nameAndHealthMenuItem = safeCreate("Username/Health", CreateUsernameHealthMenuItem)
	local leaderstatsMenuItem = useNewPlayerlist and safeCreate("PlayerList", CreateLeaderstatsMenuItem) or nil
	local stopRecordingIcon = safeCreate("Recording", CreateStopRecordIcon)
	
	-- Set Item Orders
	local LEFT_ITEM_ORDER = {}
	if settingsIcon then
		LEFT_ITEM_ORDER[settingsIcon] = 1
	end
	if chatIcon then
		LEFT_ITEM_ORDER[chatIcon] = 2
	end
	if backpackIcon then
		LEFT_ITEM_ORDER[backpackIcon] = 3
	end
	if shiftlockIcon then
		LEFT_ITEM_ORDER[shiftlockIcon] = 4
	end
	if stopRecordingIcon then
		LEFT_ITEM_ORDER[stopRecordingIcon] = 5
	end
	
	local RIGHT_ITEM_ORDER = {}
	if leaderstatsMenuItem then
		RIGHT_ITEM_ORDER[leaderstatsMenuItem] = 1
	end
	if nameAndHealthMenuItem then
		RIGHT_ITEM_ORDER[nameAndHealthMenuItem] = 2
	end
	-------------------------
	
	local function AddItemInOrder(Bar, Item, ItemOrder)
		local index = 1
		while ItemOrder[Bar:ItemAtIndex(index)] and ItemOrder[Bar:ItemAtIndex(index)] < ItemOrder[Item] do
			index = index + 1
		end
		Bar:AddItem(Item, index)
	end
	
	local function RobloxClientScreenSizeChanged(newSize)
		if TopBar and TopBar:GetInstance() then
			-- Portrait Phone
			if newSize.X <= 400 then
				-- Phone
			elseif newSize.X <= 640 then
				-- Tablet
			elseif newSize.X <= 1024 then
				-- Desktop
			else
	
			end
		end
	end
	
	local function OnCoreGuiChanged(coreGuiType, enabled)
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
			-- 2015M recreation compatibility:
			-- keep the recreated health bar independent from Roblox's modern CoreGui Health state.
			if nameAndHealthMenuItem then
				nameAndHealthMenuItem:SetHealthbarEnabled(true)
			end
		end
		if coreGuiType == Enum.CoreGuiType.Backpack or coreGuiType == Enum.CoreGuiType.All then
			-- Keep the legacy Backpack button visible for the recreation.
			-- It is intentionally a no-op until the Backpack CoreScript is patched.
			if backpackIcon and not LeftMenubar:IndexOfItem(backpackIcon) then
				AddItemInOrder(LeftMenubar, backpackIcon, LEFT_ITEM_ORDER)
			end
		end
		if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
			-- The legacy Chat button must always stay visible, even when Chat CoreGui is off,
			-- otherwise there would be no button available to turn Chat back on.
			if chatIcon and not LeftMenubar:IndexOfItem(chatIcon) then
				AddItemInOrder(LeftMenubar, chatIcon, LEFT_ITEM_ORDER)
			end
		end
		if nameAndHealthMenuItem then
			-- The recreated name/health item is always part of the legacy topbar.
			nameAndHealthMenuItem:SetNameVisible(true)
		end
	end
	
	local function IsShiftLockModeEnabled()
		local ok, result = pcall(function()
			return GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch and
				GameSettings.ComputerMovementMode ~= Enum.ComputerMovementMode.ClickToMove and
				Player.DevEnableMouseLock and
				Player.DevComputerMovementMode ~= Enum.DevComputerMovementMode.Scriptable and
				Player.DevComputerMovementMode ~= Enum.DevComputerMovementMode.ClickToMove and
				not Util.IsTouchDevice()
		end)
		return ok and result or false
	end
	
	local function CheckShiftLockMode()
		if shiftlockIcon then
			if IsShiftLockModeEnabled() then
				AddItemInOrder(LeftMenubar, shiftlockIcon, LEFT_ITEM_ORDER)
			else
				LeftMenubar:RemoveItem(shiftlockIcon)
			end
		end
	end
	
	
	
	local function OnGameSettingsChanged(property)
		if property == 'ControlMode' or property == 'ComputerMovementMode' then
			CheckShiftLockMode()
		end
	end
	
	local function OnPlayerChanged(property)
		if property == 'DevEnableMouseLock' or property == 'DevComputerMovementMode' then
			CheckShiftLockMode()
		end
	end
	
	
	TopBar:SetTopbarDisplayMode(false)
	
	Util.SetGUIInsetBounds(0, TOPBAR_THICKNESS, 0, 0)
	
	-- These three 2015M buttons are permanent members of the recreated topbar.
	-- Do not wait for modern CoreGui state/events before displaying them.
	if settingsIcon then
		AddItemInOrder(LeftMenubar, settingsIcon, LEFT_ITEM_ORDER)
	end
	if chatIcon then
		AddItemInOrder(LeftMenubar, chatIcon, LEFT_ITEM_ORDER)
	end
	if backpackIcon then
		AddItemInOrder(LeftMenubar, backpackIcon, LEFT_ITEM_ORDER)
	end
	
	if nameAndHealthMenuItem then
		AddItemInOrder(RightMenubar, nameAndHealthMenuItem, RIGHT_ITEM_ORDER)
		-- Force the recreated 2015M health bar on at startup.
		nameAndHealthMenuItem:SetHealthbarEnabled(true)
		nameAndHealthMenuItem:SetNameVisible(true)
	end
	
	local gameOptions = settings():FindFirstChild("Game Options")
	if gameOptions then
		local success, result = pcall(function()
			gameOptions.VideoRecordingChangeRequest:Connect(function(recording)
				if recording then
					AddItemInOrder(LeftMenubar, stopRecordingIcon, LEFT_ITEM_ORDER)
				else
					LeftMenubar:RemoveItem(stopRecordingIcon)
				end
			end)
		end)
	end
	
	-- Hook-up coregui changing
	pcall(function()
		StarterGui.CoreGuiChangedSignal:Connect(OnCoreGuiChanged)
	end)
	for _, enumItem in pairs(Enum.CoreGuiType:GetEnumItems()) do
		local ok, enabled = pcall(function() return StarterGui:GetCoreGuiEnabled(enumItem) end)
		if ok then
			OnCoreGuiChanged(enumItem, enabled)
		end
	end
	-- Hook up Shiftlock detection
	GameSettings.Changed:Connect(OnGameSettingsChanged)
	Player.Changed:Connect(OnPlayerChanged)
	CheckShiftLockMode()
	
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			RobloxClientScreenSizeChanged(camera.ViewportSize)
		end)
		RobloxClientScreenSizeChanged(camera.ViewportSize)
	end
	
	
	
	
	
	
	
	
	
	
end;
task.spawn(C_6);
-- StarterGui.RobloxGui.Disable CoreGui
local function C_c()
local script = G2L["c"];
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end;
task.spawn(C_c);

return G2L["1"], require;
