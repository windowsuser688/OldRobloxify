--[=[
 d888b  db    db d888888b      .d888b.      db      db    db  .d8b.  
88' Y8b 88    88   `88'        VP  `8D      88      88    88 d8' `8b 
88      88    88    88            odD'      88      88    88 88ooo88 
88  ooo 88    88    88          .88'        88      88    88 88~~~88 
88. ~8~ 88b  d88   .88.        j88.         88booo. 88b  d88 88   88    @uniquadev
 Y888P  ~Y8888P' Y888888P      888888D      Y88888P ~Y8888P' YP   YP  CONVERTER 
]=]

-- Instances: 8 | Scripts: 1 | Modules: 5 | Tags: 0
local G2L = {};

-- StarterGui.RobloxGui
G2L["1"] = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"));
G2L["1"]["IgnoreGuiInset"] = true;
G2L["1"]["DisplayOrder"] = 10;
G2L["1"]["ScreenInsets"] = Enum.ScreenInsets.DeviceSafeInsets;
G2L["1"]["Name"] = [[RobloxGui]];
G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling;
G2L["1"]["ResetOnSpawn"] = false;


-- StarterGui.RobloxGui.BackpackScript
G2L["2"] = Instance.new("ModuleScript", G2L["1"]);
G2L["2"]["Name"] = [[BackpackScript]];


-- StarterGui.RobloxGui.Settings
G2L["3"] = Instance.new("LocalScript", G2L["1"]);
G2L["3"]["Name"] = [[Settings]];


-- StarterGui.RobloxGui.ChatScript2
G2L["4"] = Instance.new("ModuleScript", G2L["1"]);
G2L["4"]["Name"] = [[ChatScript2]];


-- StarterGui.RobloxGui.HealthScript
G2L["5"] = Instance.new("ModuleScript", G2L["1"]);
G2L["5"]["Name"] = [[HealthScript]];


-- StarterGui.RobloxGui.PlayerListScript2
G2L["6"] = Instance.new("ModuleScript", G2L["1"]);
G2L["6"]["Name"] = [[PlayerListScript2]];


-- StarterGui.RobloxGui.Libraries
G2L["7"] = Instance.new("Folder", G2L["1"]);
G2L["7"]["Name"] = [[Libraries]];


-- StarterGui.RobloxGui.Libraries.RbxGui
G2L["8"] = Instance.new("ModuleScript", G2L["7"]);
G2L["8"]["Name"] = [[RbxGui]];


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

G2L_MODULES[G2L["2"]] = {
Closure = function()
    local script = G2L["2"];-- Backpack Version 4.4
-- OnlyTwentyCharacters
-- Compatibility patch of the original user-supplied 2015 backpack (not a reimplementation).

-- Configurables --

local ICON_SIZE = 60
local ICON_BUFFER = 5

local SLOT_TRANSPARENCY = 0.70
local SLOT_COLOR_EQUIP = Color3.new(0.35, 0.55, 0.91)
local SLOT_COLOR_NORMAL = Color3.new(0, 0, 0)

local ARROW_IMAGE_OPEN = 'rbxasset://textures/ui/Backpack_Open.png'
local ARROW_IMAGE_CLOSE = 'rbxasset://textures/ui/Backpack_Close.png'
local ARROW_SIZE = UDim2.new(0, 14, 0, 9)
local ARROW_HOTKEY = Enum.KeyCode.Backquote.Value --TODO: Hookup '~' too?
local ARROW_HOTKEY_STRING = '`'

local HOTBAR_SLOTS_FULL = 10
local HOTBAR_SLOTS_MINI = 3
local HOTBAR_SLOTS_WIDTH_CUTOFF = 1024 -- Anything smaller is MINI
local HOTBAR_OFFSET_FROMBOTTOM = 30
local BACKPACK_ROOT_RAISE = 10 -- Raise the whole backpack UI by 10 pixels

local INVENTORY_ROWS = 5
local INVENTORY_HEADER_SIZE = 40

local TITLE_OFFSET = 20 -- From left side
local TITLE_TEXT = "Backpack"

local SEARCH_BUFFER = 5
local SEARCH_WIDTH = 200
local SEARCH_TEXT = "Search"
local SEARCH_TEXT_OFFSET_FROMLEFT = 15

local DOUBLE_CLICK_TIME = 0.5

-- Variables --

-- Debug printing disabled in original; do not override global print.
local function debugPrint(...) end

local PlayersService = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local StarterGui = game:GetService('StarterGui')
local GuiService = game:GetService('GuiService')

local HOTBAR_SLOTS = (UserInputService.TouchEnabled and workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X < HOTBAR_SLOTS_WIDTH_CUTOFF) and HOTBAR_SLOTS_MINI or HOTBAR_SLOTS_FULL
local HOTBAR_SIZE = UDim2.new(0, ICON_BUFFER + (HOTBAR_SLOTS * (ICON_SIZE + ICON_BUFFER)), 0, ICON_BUFFER + ICON_SIZE + ICON_BUFFER)
local ZERO_KEY_VALUE = Enum.KeyCode.Zero.Value
local DROP_HOTKEY_VALUE = Enum.KeyCode.Backspace.Value

local Player = PlayersService.LocalPlayer or PlayersService.PlayerAdded:Wait()

local CoreGui = nil -- initialized by BackpackScript.Start() in PlayerGui

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
local UpdateArrowFrame = nil -- Function defined in Init logic at the bottom
local ActiveHopper = nil -- HopperBins unsupported on modern Roblox
local StarterToolFound = false -- Special handling is required for the gear currently equipped on the site
local WholeThingEnabled = false
local TextBoxFocused = false
local ResultsIndices = nil -- Results of a search

-- Functions --

local function NewGui(className, objectName)
	local newGui = Instance.new(className)
	newGui.Name = tostring(objectName)
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
		newGui.BackgroundTransparency = 1
		if className == 'TextButton' then
			newGui.Font = Enum.Font.SourceSansBold
			newGui.BorderSizePixel = 2
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
	if not InventoryFrame or not HotbarFrame then return end
	local inventoryOpen = InventoryFrame.Visible
	local visualTotal = (inventoryOpen) and HOTBAR_SLOTS or FullHotbarSlots
	local visualIndex = 0
	for i = 1, HOTBAR_SLOTS do
		local slot = Slots[i]
		if slot.Tool or inventoryOpen then
			visualIndex = visualIndex + 1
			slot:Readjust(visualIndex, visualTotal)
			slot.Frame.Visible = true
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

local function UnequipTools()
	if Humanoid then Humanoid:UnequipTools() end
end
local function EquipTool(tool)
	if Humanoid and tool and tool:IsA('Tool') then
		Humanoid:EquipTool(tool)
	end
end

local function MakeSlot(parent, index)
	index = index or (#Slots + 1)

	-- Slot Definition --

	local slot = {}
	slot.Tool = nil
	slot.Index = index
	slot.Frame = nil

	local slotFrame = NewGui('Frame', slot.Index)
	slotFrame.BackgroundTransparency = SLOT_TRANSPARENCY
	slotFrame.BackgroundColor3 = SLOT_COLOR_NORMAL
	slotFrame.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
	slotFrame.Active = true
	-- slot dragging handled by UserInputService
	slot.Frame = slotFrame

	-- Opaque, inward-facing equipped border. All four edges are inside the 60x60 slot.
	local EQUIPPED_BORDER_SIZE = 3
	slotFrame.BorderSizePixel = 0
	local equipEdges = {}
	local edgeSizes = {
		{UDim2.new(1, 0, 0, EQUIPPED_BORDER_SIZE), UDim2.new(0, 0, 0, 0)},
		{UDim2.new(1, 0, 0, EQUIPPED_BORDER_SIZE), UDim2.new(0, 0, 1, -EQUIPPED_BORDER_SIZE)},
		{UDim2.new(0, EQUIPPED_BORDER_SIZE, 1, -2 * EQUIPPED_BORDER_SIZE), UDim2.new(0, 0, 0, EQUIPPED_BORDER_SIZE)},
		{UDim2.new(0, EQUIPPED_BORDER_SIZE, 1, -2 * EQUIPPED_BORDER_SIZE), UDim2.new(1, -EQUIPPED_BORDER_SIZE, 0, EQUIPPED_BORDER_SIZE)},
	}
	for i, dimensions in ipairs(edgeSizes) do
		local edge = Instance.new("Frame")
		edge.Name = "EquippedBorder" .. i
		edge.Size = dimensions[1]
		edge.Position = dimensions[2]
		edge.BackgroundColor3 = SLOT_COLOR_EQUIP
		edge.BackgroundTransparency = 0
		edge.BorderSizePixel = 0
		edge.ZIndex = 5
		edge.Visible = false
		edge.Parent = slotFrame
		equipEdges[i] = edge
	end

	local toolIcon = NewGui('ImageLabel', 'Icon')
	toolIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
	toolIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
	toolIcon.Parent = slotFrame

	local toolName = NewGui('TextLabel', 'ToolName')
	toolName.Parent = slotFrame

	local toolTip = nil --TODO: Clean up
	if slot.Index <= HOTBAR_SLOTS then
		toolTip = NewGui('TextLabel', 'ToolTip')
		toolTip.TextWrapped = false
		toolTip.TextYAlignment = Enum.TextYAlignment.Top
		toolTip.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		toolTip.BackgroundTransparency = 0
		toolTip.Visible = false
		toolTip.Parent = slotFrame
		slotFrame.MouseEnter:Connect(function()
			if toolTip.Text ~= '' then
				toolTip.Visible = true
			end
		end)
		slotFrame.MouseLeave:Connect(function() toolTip.Visible = false end)
	end

	local slotNumber = nil --NOTE: Only defined for Hotbar Slots
	local clickArea = nil --NOTE: Only defined for Hotbar Slots


	-- Slot Functions --

	function slot:Reposition()
		-- Slots are positioned into rows
		local index = (ResultsIndices and ResultsIndices[self]) or self.Index
		local sizePlus = ICON_BUFFER + ICON_SIZE
		local modSlots = ((index - 1) % HOTBAR_SLOTS) + 1
		local row = (index > HOTBAR_SLOTS) and (math.floor((index - 1) / HOTBAR_SLOTS)) - 1 or 0
		slotFrame.Position = UDim2.new(0, ICON_BUFFER + ((modSlots - 1) * sizePlus), 0, ICON_BUFFER + (sizePlus * row))
		-- debugPrint("     Reposition", self.Index, "at...............", index, "                      Output:", slotFrame.Position.X.Offset, slotFrame.Position.Y.Offset, "           row:", row)
	end
	slot:Reposition()

	function slot:Readjust(visualIndex, visualTotal)
		local centered = HOTBAR_SIZE.X.Offset / 2
		local sizePlus = ICON_BUFFER + ICON_SIZE
		local midpointish = (visualTotal / 2) + 0.5
		local factor = visualIndex - midpointish
		--debugPrint("      Slot", self.Index, "'s new visualIndex:", visualIndex, "MN:", midpointish, "factor:", factor)
		slotFrame.Position = UDim2.new(0, centered - (ICON_SIZE / 2) + (sizePlus * factor), 0, ICON_BUFFER)
	end

	function slot:Fill(tool)
		debugPrint("   Filling gui data for slot", self.Index, "tool:", tool)
		self.Tool = tool
		-- slot dragging handled by UserInputService
		local icon = tool.TextureId
		toolIcon.Image = icon
		toolName.Text = (icon == '') and tool.Name or ''
		if toolTip and tool:IsA('Tool') then --NOTE: HopperBin
			--TODO: No magic numbers
			toolTip.Text = tool.ToolTip
			local width = toolTip.TextBounds.X + 6
			toolTip.Size = UDim2.new(0, width, 0, 16)
			toolTip.Position = UDim2.new(0.5, -width / 2, 0, -25)
		end
		self:UpdateEquipView()

		if self.Index <= HOTBAR_SLOTS then
			FullHotbarSlots = FullHotbarSlots + 1
		end

		SlotsByTool[tool] = self
		LowestEmptySlot = FindLowestEmpty()
		AdjustHotbarFrames()
		if UpdateArrowFrame then UpdateArrowFrame() end
	end

	function slot:Clear()
		debugPrint("   Clearing gui data for slot", self.Index, "tool:", self.Tool)
		-- slot dragging handled by UserInputService
		toolIcon.Image = ''
		toolName.Text = ''
		if toolTip then
			toolTip.Text = ''
			toolTip.Visible = false
		end
		self:UpdateEquipView(true) -- Always show as unequipped

		if self.Index <= HOTBAR_SLOTS then
			FullHotbarSlots = FullHotbarSlots - 1
		end

		SlotsByTool[self.Tool] = nil
		self.Tool = nil
		LowestEmptySlot = FindLowestEmpty()
		AdjustHotbarFrames()
		if UpdateArrowFrame then UpdateArrowFrame() end
	end

	function slot:UpdateEquipView(unequippedOverride)
		local tool = self.Tool
		local isEquipped = not unequippedOverride and tool ~= nil and tool.Parent == Character
		debugPrint("     Showing", self.Index, isEquipped and "as equipped:" or "as unequipped:", tool)
		-- Preserve the normal translucent background in both states.
		slotFrame.BackgroundColor3 = SLOT_COLOR_NORMAL
		slotFrame.BackgroundTransparency = SLOT_TRANSPARENCY
		for _, edge in ipairs(equipEdges) do
			edge.Visible = isEquipped
		end
	end

	function slot:Delete()
		debugPrint("   Deleting slot", self.Index, "Tool:", self.Tool)
		slotFrame:Destroy()
		table.remove(Slots, self.Index)
		local newSize = #Slots

		-- Now adjust the rest (both visually and representationally)
		for i = self.Index, newSize do
			Slots[i]:SlideBack()
		end

		if newSize > 0 and newSize % HOTBAR_SLOTS == 0 then -- We lost a row at the end! Adjust the CanvasSize
			local lastSlot = Slots[newSize]
			local lowestPoint = lastSlot.Frame.Position.Y.Offset + lastSlot.Frame.Size.Y.Offset
			ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, lowestPoint + ICON_BUFFER)
			local offset = Vector2.new(0, math.max(0, ScrollingFrame.CanvasPosition.Y - (lastSlot.Frame.Size.Y.Offset + ICON_BUFFER)))
			ScrollingFrame.CanvasPosition = offset
		end
	end

	function slot:Swap(targetSlot) --NOTE: This slot (self) must not be empty!
		debugPrint("   Swapping content of slots:", self.Index, "and", targetSlot.Index)
		local myTool, otherTool = self.Tool, targetSlot.Tool
		self:Clear()
		if otherTool then -- (Target slot might be empty)
			targetSlot:Clear()
			self:Fill(otherTool)
		end
		targetSlot:Fill(myTool)
	end


	function slot:SlideBack() -- For inventory slot shifting
		debugPrint("   SlideBack:", self.Index, "to", self.Index - 1)
		self.Index = self.Index - 1
		self:Reposition()
	end

	function slot:TurnNumber(on)
		if slotNumber then slotNumber.Visible = on end
	end

	function slot:SetClickability(on)
		if clickArea then clickArea.Visible = on end
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


	if index <= HOTBAR_SLOTS then -- Hotbar-Specific Slot Stuff
		local function selectSlot()
			debugPrint("Click!")
			local tool = slot.Tool
			if tool then
				if tool.Parent == Character or (false) then --NOTE: HopperBin
					debugPrint("   UNEQUIP!")
					UnequipTools()
				elseif tool.Parent == Backpack then
					debugPrint("   EQUIP!")
					EquipTool(tool)
				end
			end
		end

		clickArea = NewGui('TextButton', 'GimmieYerClicks')
		clickArea.MouseButton1Click:Connect(selectSlot)
		clickArea.Parent = slotFrame

		-- Show label and assign hotkeys for 1-9 and 0 (zero is always last slot when > 10 total)
		if index < 10 or index == HOTBAR_SLOTS then -- NOTE: Hardcoded on purpose!
			local slotNum = (index < 10) and index or 0
			slotNumber = NewGui('TextLabel', 'Number')
			slotNumber.Text = tostring(slotNum)
			slotNumber.Size = UDim2.new(0.15, 0, 0.15, 0)
			slotNumber.Visible = false
			slotNumber.Parent = slotFrame
			local keyNames = {'One','Two','Three','Four','Five','Six','Seven','Eight','Nine'}
			local key = slotNum == 0 and Enum.KeyCode.Zero or Enum.KeyCode[keyNames[slotNum]]
			HotkeyFns[key.Value] = selectSlot
		end
	else -- Inventory-Specific Slot Stuff
		if index % HOTBAR_SLOTS == 1 then -- We are the first slot of a new row! Adjust the CanvasSize
			local lowestPoint = slotFrame.Position.Y.Offset + slotFrame.Size.Y.Offset
			ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, lowestPoint + ICON_BUFFER)
		end
	end


	do -- Modern drag-and-drop handling (replaces GuiObject.DragBegin / DragStopped)
		local pointer = nil
		local initialPoint = nil
		local activeDrag = false
		local oldParent = nil
		local oldPosition = nil
		local moveConnection = nil
		local endConnection = nil
		local lastClick = 0
		local dragThreshold = 8

		local function cleanup()
			if moveConnection then moveConnection:Disconnect(); moveConnection = nil end
			if endConnection then endConnection:Disconnect(); endConnection = nil end
			Dragging[slotFrame] = nil
			if oldParent then
				slotFrame.Parent = oldParent
				slotFrame.Position = oldPosition
				oldParent = nil
			end
			slotFrame.ZIndex = 1
			toolIcon.ZIndex = 1
			toolName.ZIndex = 1
			if slotNumber then slotNumber.ZIndex = 1 end
		end
		local function dropAt(x, y)
			local now = os.clock()
			if not slot.Tool then return end
			if InventoryFrame.Visible and CheckBounds(InventoryFrame,x,y) then
				if slot.Index <= HOTBAR_SLOTS then
					local tool = slot.Tool
					if tool.Parent == Character then UnequipTools() end
					slot:Clear()
					MakeSlot(ScrollingFrame):Fill(tool)
				elseif now - lastClick < DOUBLE_CLICK_TIME and LowestEmptySlot then
					local tool = slot.Tool
					slot:Clear()
					LowestEmptySlot:Fill(tool)
					slot:Delete()
				end
			elseif CheckBounds(HotbarFrame,x,y) then
				local closest, distance = nil, math.huge
				for i=1,HOTBAR_SLOTS do
					local other = Slots[i]
					if other then
						local d = GetOffset(other.Frame,Vector2.new(x,y))
						if d < distance then distance=d; closest=other end
					end
				end
				if closest and closest ~= slot then
					local wasInventory = slot.Index > HOTBAR_SLOTS
					slot:Swap(closest)
					if wasInventory then
						if slot.Tool and slot.Tool.Parent == Character then UnequipTools() end
						if not slot.Tool then slot:Delete() end
					end
				end
			end
			lastClick = now
		end
		local dragTarget = clickArea or slotFrame
		dragTarget.InputBegan:Connect(function(input)
			if not slot.Tool or not WholeThingEnabled then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			if pointer then return end
			pointer = input
			local start = Vector2.new(input.Position.X,input.Position.Y)
			initialPoint = start
			activeDrag = false
			oldPosition = slotFrame.Position
			local absolute = slotFrame.AbsolutePosition
			local pixelOffset = start - absolute
			moveConnection = UserInputService.InputChanged:Connect(function(changed)
				if not pointer then return end
				if input.UserInputType == Enum.UserInputType.Touch and changed ~= input then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 and changed.UserInputType ~= Enum.UserInputType.MouseMovement then return end
				local current = Vector2.new(changed.Position.X,changed.Position.Y)
				if not activeDrag and (current-start).Magnitude >= dragThreshold then
					activeDrag = true
					Dragging[slotFrame] = true
					oldParent = slotFrame.Parent
					slotFrame.Parent = MainFrame
					slotFrame.ZIndex = 6
					toolIcon.ZIndex = 6
					toolName.ZIndex = 6
					if slotNumber then slotNumber.ZIndex = 6 end
				end
				if activeDrag then
					local parentAbs = MainFrame.AbsolutePosition
					slotFrame.Position = UDim2.fromOffset(current.X-parentAbs.X-pixelOffset.X,current.Y-parentAbs.Y-pixelOffset.Y)
				end
			end)
			endConnection = UserInputService.InputEnded:Connect(function(ended)
				if input.UserInputType == Enum.UserInputType.Touch then
					if ended ~= input then return end
				elseif ended.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				local didDrag = activeDrag
				pointer = nil
				cleanup()
				if didDrag then dropAt(ended.Position.X,ended.Position.Y) end
				activeDrag = false
			end)
		end)
	end

	-- All ready!
	slotFrame.Parent = parent
	Slots[index] = slot
	return slot
end

local function OnChildAdded(child) -- To Character or Backpack
	if not child:IsA('Tool') then --NOTE: HopperBin
		if child:IsA('Humanoid') and child.Parent == Character then
			Humanoid = child
		end
		return
	end
	local tool = child
	debugPrint("A" .. (tool.Parent == Backpack and 'B' or (tool.Parent == Character and 'C' or '?')), tool)

	-- HopperBin support removed

	--TODO: Optimize / refactor / do something else
	if not StarterToolFound and tool.Parent == Character and not SlotsByTool[tool] then
		local starterGear = Player:FindFirstChild('StarterGear')
		if starterGear then
			if starterGear:FindFirstChild(tool.Name) then
				StarterToolFound = true
				local firstEmptyIndex = LowestEmptySlot and LowestEmptySlot.Index or #Slots + 1
				if LowestEmptySlot then
					firstEmptyIndex = LowestEmptySlot.Index
				else -- No slots free in hotbar, make a new inventory slot
					local newSlot = MakeSlot(ScrollingFrame)
					firstEmptyIndex = newSlot.Index
				end
				for i = firstEmptyIndex, 1, -1 do
					local curr = Slots[i] -- An empty slot, because above
					local pIndex = i - 1
					if pIndex > 0 then
						local prev = Slots[pIndex] -- Guaranteed to be full, because above
						prev:Swap(curr)
					else
						curr:Fill(tool)
					end
				end
				return -- We're done here
			end
		end
	end

	-- either moving or new

	local slot = SlotsByTool[tool]
	if slot then
		debugPrint("   Already exists")
		slot:UpdateEquipView()
	else -- Not yet showing this tool
		debugPrint("   New! Showing in lowest empty or a new inventory slot")
		slot = LowestEmptySlot or MakeSlot(ScrollingFrame)
		slot:Fill(tool)
	end
end

local function OnChildRemoved(child) -- From Character or Backpack
	if not child:IsA('Tool') then --NOTE: HopperBin
		return
	end
	local tool = child
	debugPrint("R-->" .. (tool.Parent == Backpack and 'B' or (tool.Parent == Character and 'C' or '?')), tool)

	-- Ignore this event if we're just moving between the two
	task.defer(function()
		if not SlotsByTool[tool] then return end
		if tool.Parent == Character or tool.Parent == Backpack then
			SlotsByTool[tool]:UpdateEquipView()
			return
		end
		local slot = SlotsByTool[tool]
		if slot then
			slot:Clear()
			if slot.Index > HOTBAR_SLOTS then slot:Delete() end
		end
	end)

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

	Character = character
	Humanoid = character:FindFirstChildOfClass('Humanoid') or character:WaitForChild('Humanoid', 10)
	character.ChildRemoved:Connect(OnChildRemoved)
	character.ChildAdded:Connect(OnChildAdded)
	for _, child in pairs(character:GetChildren()) do
		OnChildAdded(child)
	end
	--NOTE: Humanoid is set inside OnChildAdded

	Backpack = Player:WaitForChild('Backpack')
	local addTime = os.clock(); Backpack.Changed:Connect(function(prop) if prop == 'Parent' then debugPrint("Backpack added", os.clock() - addTime, "seconds ago just got removed! Izat coo?") end end) --TODO: Remove
	Backpack.ChildRemoved:Connect(OnChildRemoved)
	Backpack.ChildAdded:Connect(OnChildAdded)
	for _, child in pairs(Backpack:GetChildren()) do
		OnChildAdded(child)
	end

	debugPrint("CharAdded finished")
end

local function OnInputBegan(input, isProcessed)
	if not isProcessed and not TextBoxFocused and not UserInputService:GetFocusedTextBox() and WholeThingEnabled and input.UserInputType == Enum.UserInputType.Keyboard then
		local hotkeyBehavior = HotkeyFns[input.KeyCode.Value]
		if hotkeyBehavior then
			hotkeyBehavior()
		end
	end
end

local function OnUISChanged(property)
	--debugPrint("UIS CHANGED:", property)
	if property == 'KeyboardEnabled' then
		local on = UserInputService.KeyboardEnabled
		for i = 1, HOTBAR_SLOTS do
			Slots[i]:TurnNumber(on)
		end
	end
end

local function OnCoreGuiChanged(coreGuiType, enabled)
	if coreGuiType == Enum.CoreGuiType.Backpack or coreGuiType == Enum.CoreGuiType.All then
		debugPrint("Make whole everything", enabled and "visible" or "hidden!")
		WholeThingEnabled = true
		MainFrame.Visible = true
	end
	-- Modern Roblox may disable its built-in Health CoreGui after our custom health bar starts.
	-- Do not shift the 2015 backpack in response: its custom health bar is independent.
	if coreGuiType == Enum.CoreGuiType.Health or coreGuiType == Enum.CoreGuiType.All then
		MainFrame.Position = UDim2.new(0, 0, 0, -BACKPACK_ROOT_RAISE)
	end
end

local BackpackScript = {}
local started = false
function BackpackScript.Start()
	if started then return end
	started = true
	local playerGui = Player:WaitForChild("PlayerGui")
	local previous = playerGui:FindFirstChild("2015EBackpackGui")
	if previous then previous:Destroy() end
	CoreGui = Instance.new("ScreenGui")
	CoreGui.Name = "2015EBackpackGui"
	CoreGui.ResetOnSpawn = false
	CoreGui.IgnoreGuiInset = true
	CoreGui.DisplayOrder = 490
	CoreGui.Parent = playerGui
	-- Hide default backpack when the custom classic UI starts.
	task.spawn(function()
		for _ = 1, 12 do
			local ok = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			end)
			if ok then break end
			task.wait(0.25)
		end
	end)
	-- Script Logic --

	-- Make the main frame, which covers the screen
	MainFrame = NewGui('Frame', 'Backpack')
	MainFrame.Position = UDim2.new(0, 0, 0, -BACKPACK_ROOT_RAISE)
	MainFrame.Visible = true
	MainFrame.Parent = CoreGui

	-- Make the HotbarFrame, which holds only the Hotbar Slots
	HotbarFrame = NewGui('Frame', 'Hotbar')
	HotbarFrame.Active = true
	HotbarFrame.Size = HOTBAR_SIZE
	HotbarFrame.Position = UDim2.new(0.5, -HotbarFrame.Size.X.Offset / 2, 1, -HotbarFrame.Size.Y.Offset - HOTBAR_OFFSET_FROMBOTTOM)
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
	InventoryFrame.BackgroundTransparency = SLOT_TRANSPARENCY
	InventoryFrame.Active = true
	InventoryFrame.Size = UDim2.new(0, HotbarFrame.Size.X.Offset, 0, HotbarFrame.Size.Y.Offset * 5) --TODO: No MNs
	InventoryFrame.Position = UDim2.new(0.5, -InventoryFrame.Size.X.Offset / 2, 1, HotbarFrame.Position.Y.Offset - InventoryFrame.Size.Y.Offset)
	InventoryFrame.Visible = false
	InventoryFrame.Parent = MainFrame

	-- Make the header title, in the Inventory
	-- local headerText = NewGui('TextLabel', 'Header')
	-- headerText.Text = TITLE_TEXT
	-- headerText.TextXAlignment = Enum.TextXAlignment.Left
	-- headerText.Font = Enum.Font.SourceSansBold
	-- headerText.FontSize = Enum.FontSize.Size48
	-- headerText.TextStrokeColor3 = SLOT_COLOR_EQUIP
	-- headerText.TextStrokeTransparency = 0.75 --TODO: No MNs
	-- headerText.Size = UDim2.new(0, (InventoryFrame.Size.X.Offset / 2) - TITLE_OFFSET, 0, INVENTORY_HEADER_SIZE)
	-- headerText.Position = UDim2.new(0, TITLE_OFFSET, 0, 0)
	-- headerText.Parent = InventoryFrame

	do -- Search stuff
		local searchFrame = NewGui('Frame', 'Search')
		searchFrame.BackgroundColor3 = Color3.new(0.37, 0.37, 0.37) --TODO: NO MNs
		searchFrame.BackgroundTransparency = 0.15 --TODO: NO MNs
		searchFrame.Size = UDim2.new(0, SEARCH_WIDTH, 0, INVENTORY_HEADER_SIZE - (SEARCH_BUFFER * 2))
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
		xButton.TextColor3 = SLOT_COLOR_EQUIP
		xButton.FontSize = Enum.FontSize.Size24
		xButton.TextYAlignment = Enum.TextYAlignment.Bottom
		xButton.Size = UDim2.new(0, searchFrame.Size.Y.Offset - (SEARCH_BUFFER * 2), 0, searchFrame.Size.Y.Offset - (SEARCH_BUFFER * 2))
		xButton.Position = UDim2.new(1, -xButton.Size.X.Offset - (SEARCH_BUFFER * 2), 0.5, -xButton.Size.Y.Offset / 2)
		xButton.ZIndex = 3
		xButton.Visible = false
		xButton.Parent = searchFrame

		local clickArea = NewGui('TextButton', 'GimmieYerClicks')
		clickArea.MouseButton1Click:Connect(function()
			debugPrint("YOINK!")
			searchBox:CaptureFocus()
			if searchBox.Text == SEARCH_TEXT then
				searchBox.Text = ''
			end
		end)
		clickArea.ZIndex = 2
		clickArea.Parent = searchFrame

		local function resetSearch()
			debugPrint("Reset!")
			if xButton.Visible then
				ResultsIndices = nil
				for i = HOTBAR_SLOTS + 1, #Slots do
					local slot = Slots[i]
					slot:Reposition()
					slot.Frame.Visible = true
				end
			end
			xButton.Visible = false
			searchBox.Text = SEARCH_TEXT
		end
		xButton.MouseButton1Click:Connect(resetSearch)

		searchBox.FocusLost:Connect(function(enterPressed)
			debugPrint("FocusLost! enterPressed:", enterPressed)
			if enterPressed then
				local text = searchBox.Text
				debugPrint(" Want to search for:", text)
				local terms = {}
				for word in text:gmatch('%S+') do
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
						debugPrint("   ", i, "- Slot ", slot.Index, "Hits", hits)
						slot:Reposition()
						slot.Frame.Visible = true
					end
				end

				xButton.Visible = true
			else
				resetSearch()
			end
		end)
	end

	-- Make the ScrollingFrame, which holds the rest of the Slots (however many) 
	ScrollingFrame = NewGui('ScrollingFrame', 'ScrollingFrame')
	ScrollingFrame.Size = UDim2.new(1, ScrollingFrame.ScrollBarThickness + 1, 1, -INVENTORY_HEADER_SIZE)
	ScrollingFrame.Position = UDim2.new(0, 0, 0, INVENTORY_HEADER_SIZE)
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	ScrollingFrame.Parent = InventoryFrame

	do -- Make the Inventory expand/collapse arrow
		local arrowFrame = NewGui('Frame', 'Arrow')
		arrowFrame.BackgroundTransparency = SLOT_TRANSPARENCY
		arrowFrame.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE / 2)
		local hotbarBottom = HotbarFrame.Position.Y.Offset + HotbarFrame.Size.Y.Offset
		arrowFrame.Position = UDim2.new(0.5, -arrowFrame.Size.X.Offset / 2, 1, hotbarBottom - arrowFrame.Size.Y.Offset)

		local arrowIcon = NewGui('ImageLabel', 'Icon')
		arrowIcon.Image = ARROW_IMAGE_OPEN
		arrowIcon.Size = ARROW_SIZE
		arrowIcon.Position = UDim2.new(0.5, -arrowIcon.Size.X.Offset / 2, 0.5, -arrowIcon.Size.Y.Offset / 2)
		arrowIcon.Parent = arrowFrame

		-- With no tools, keep the toggle above the custom health bar (at bottom -48).
		-- Keep the original tool-present and inventory-open positions unchanged.
		local EMPTY_ARROW_RAISE = 6
		local closedBase = arrowFrame.Position
		local collapsed = closedBase + UDim2.new(0, 0, 0, -EMPTY_ARROW_RAISE)
		local closed = closedBase + UDim2.new(0, 0, 0, -HotbarFrame.Size.Y.Offset)
		local opened = closed + UDim2.new(0, 0, 0, -InventoryFrame.Size.Y.Offset)
		arrowFrame.Position = collapsed

		local function openClose()
			if not next(Dragging) then -- Only continue if nothing is being dragged
				InventoryFrame.Visible = not InventoryFrame.Visible
				local nowOpen = InventoryFrame.Visible
				arrowIcon.Image = (nowOpen) and ARROW_IMAGE_CLOSE or ARROW_IMAGE_OPEN
				AdjustHotbarFrames()
				if UpdateArrowFrame then UpdateArrowFrame() end
				for i = 1, HOTBAR_SLOTS do
					Slots[i]:SetClickability(not nowOpen)
				end
			end
		end
		local clickArea = NewGui('TextButton', 'GimmieYerClicks')
		clickArea.MouseButton1Click:Connect(openClose)
		clickArea.Parent = arrowFrame
		HotkeyFns[ARROW_HOTKEY] = openClose

		-- Define global function
		UpdateArrowFrame = function()
			arrowFrame.Position = (InventoryFrame.Visible) and opened or ((FullHotbarSlots == 0) and collapsed or closed)
		end

		arrowFrame.Parent = MainFrame
	end


	-- Finally, connect the major events

	while not Player do --TODO: Only necessary in RunSolo? -- Still a valid case though.
		wait()
		Player = PlayersService.LocalPlayer
	end

	Player.CharacterAdded:Connect(OnCharacterAdded)
	if Player.Character then
		OnCharacterAdded(Player.Character)
	end

	-- Eat keys
	-- Legacy GuiService:AddKey removed; modern keyboard handling is below.

	UserInputService.InputBegan:Connect(OnInputBegan)

	UserInputService.Changed:Connect(OnUISChanged)
	OnUISChanged('KeyboardEnabled')

	UserInputService.TextBoxFocused:Connect(function() TextBoxFocused = true end)
	UserInputService.TextBoxFocusReleased:Connect(function() TextBoxFocused = false end)

	-- Old HopperBin drop hotkey removed

	StarterGui.CoreGuiChangedSignal:Connect(OnCoreGuiChanged)
	local backpackType = Enum.CoreGuiType.Backpack
	OnCoreGuiChanged(backpackType, true)
	MainFrame.Visible = true
	WholeThingEnabled = true

end
return BackpackScript

end;
};
G2L_MODULES[G2L["4"]] = {
Closure = function()
    local script = G2L["4"];--[[
	// FileName: ChatScript.lua
	// Written by: SolarCrane
	// Description: Code for lua side chat on ROBLOX.
]]

--[[ CONSTANTS ]]
local FORCE_CHAT_GUI = false
local USE_PLAYER_GUI_TESTING = true

local ADMIN_LIST = {
	['68465808'] = true, -- IMightBeLying
	['32345429'] = true, -- Rbadam
	['48453004'] = true, -- Adamintygum
	['57705391'] = true, -- androidtest
	['58491921'] = true, -- RobloxFrenchie
	['29341155'] = true, -- JacksSmirkingRevenge
	['60629145'] = true, -- Mandaari
	['6729993'] = true, -- vaiobot
	['9804369'] = true, -- Goddessnoob
	['67906358'] = true, -- Thr33pakShak3r
	['41101356'] = true, -- effward
	['29667843'] = true, -- Blockhaak
	['26076267'] = true, -- Drewbda
	['65171466'] = true, -- triptych999
	['264635'] = true, -- Tone
	['59257875'] = true, -- fasterbuilder19
	['30068452'] = true, -- Zeuxcg
	['53627251'] = true, -- concol2
	['56449'] = true, -- ReeseMcBlox
	['7210880'] = true, -- Jeditkacheff
	['35187797'] = true, -- ChiefJustus
	['21964644'] = true, -- Ellissar
	['63971416'] = true, -- geekndestroy
	['111627'] = true, -- Noob007
	['482238'] = true, -- Limon
	['39861325'] = true, -- hawkington
	['32580099'] = true, -- Tabemono
	['504316'] = true, -- BrightEyes
	['35825637'] = true, -- Monsterinc3D
	['55311255'] = true, -- IsolatedEvent
	['48988254'] = true, -- CountOnConnor
	['357346'] = true, -- Scubasomething
	['28969907'] = true, -- OnlyTwentyCharacters
	['17707636'] = true, -- LordRugdumph
	['26714811'] = true, -- bellavour
	['24941'] = true, -- david.baszucki
	['13057592'] = true, -- ibanez2189
	['66766775'] = true, -- ConvexHero
	['13268404'] = true, -- Sorcus
	['26065068'] = true, -- DeeAna00
	['4108667'] = true, -- TheLorekt
	['605367'] = true, -- MSE6
	['28350010'] = true, -- CorgiParade
	['1636196'] = true, -- Varia
	['27861308'] = true, -- 4runningwolves
	['26699190'] = true, -- pulmoesflor
	['9733258'] = true, -- Olive71
	['2284059'] = true, -- groundcontroll2
	['28080592'] = true, -- GuruKrish
	['28137935'] = true, -- Countvelcro
	['25964666'] = true, -- IltaLumi
	['31221099'] = true, -- juanjuan23
	['13965343'] = true, -- OstrichSized
	['541489'] = true, -- jackintheblox
	['38324232'] = true, -- SlingshotJunkie
	['146569'] = true, -- gordonrox24
	['61666252'] = true, -- sharpnine
	['25540124'] = true, -- Motornerve
	['29044576'] = true, -- watchmedogood
	['49626068'] = true, -- jmargh
	['57352126'] = true, -- JayKorean
	['25682044'] = true, -- Foyle
	['1113299'] = true, -- MajorTom4321
	['30598693'] = true, -- supernovacaine
	['1311'] = true, -- FFJosh
	['23603273'] = true, -- Sickenedmonkey
	['28568151'] = true, -- Doughtless
	['8298697'] = true, -- KBUX
	['39871898'] = true, -- totallynothere
	['57708043'] = true, -- ErzaStar
	['22'] = true, -- Keith
	['2430782'] = true, -- Chro
	['29373363'] = true, -- SolarCrane
	['29116915'] = true, -- GloriousSalt
	['6783205'] = true, -- UristMcSparks
	['62155769'] = true, -- ITOlaurEN
	['24162607'] = true, -- Malcomso
	['66692187'] = true, -- HeySeptember
	['80254'] = true, -- Stickmasterluke
	['66093461'] = true, -- chefdeletat
	['62968051'] = true, -- windlight13
	['80119'] = true, -- Stravant
	['61890000'] = true, -- imaginationsensation
	['916'] = true, -- Matt Dusek
	['4550725'] = true, -- CrimmsonGhost
	['59737068'] = true, -- Mcrtest
	['5600283'] = true, -- Seranok
	['48656806'] = true, -- maxvee
	['48656806'] = true, -- Coatp0cketninja
	['35231885'] = true, -- Screenme
	['55958416'] = true, -- b1tsh1ft
	['51763936'] = true, -- ConvexRumbler
	['59638684'] = true, -- mpliner476
	['44231609'] = true, -- Totbl
	['16906083'] = true, -- Aquabot8
	['23984372'] = true, -- grossinger
	['13416513'] = true, -- Merely
	['27416429'] = true, -- CDakkar
	['46526337'] = true, -- logitek00
	['21969613'] = true, -- Siekiera
	['39488230'] = true, -- Robloxkidsaccount
	['60425210'] = true, -- flotsamthespork
	['16732061'] = true, -- Soggoth
	['33904052'] = true, -- Phil
	['39882028'] = true, -- OrcaSparkles
	['62060462'] = true, -- skullgoblin
	['29044708'] = true, -- RickROSStheB0SS
	['15782010'] = true, -- ArgonPirate
	['6949935'] = true, -- NobleDragon
	['41256555'] = true, -- Squidcod
	['16150324'] = true, -- Raeglyn
	['24419770'] = true, -- Xerolayne
	['20396599'] = true, -- Robloxsai
	['55579189'] = true, -- Briarroze
	['21641566'] = true, -- hawkeyebandit
	['39871292'] = true, -- DapperBuffalo
	['48725400'] = true, -- Vukota
	['60880618'] = true, -- swiftstone
	['8736269'] = true, -- Gemlocker
	['17199995'] = true, -- Tarabyte
	['6983145'] = true, -- Timobius
	['20048521'] = true, -- Tobotrobot
	['1644345'] = true, -- Foster008
	['33067469'] = true, -- Twberg
	['57741156'] = true, -- DarthVaden
	['51164101'] = true, -- Khanovich
	['61380399'] = true, -- oLEFTo
	['39876101'] = true, -- CodeWriter
	['23598967'] = true, -- VladTheFirst
	['39299049'] = true, -- Phaedre
	['39855185'] = true, -- gorroth
	['61004766'] = true, -- jynj1984
	['10261020'] = true, -- RoboYZ
	['44564747'] = true, -- ZodiacZak
}

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
-- These emotes are copy-pastad from the humanoidLocalAnimateKeyframe script
local EMOTE_NAMES = {wave = true, point = true, dance = true, dance2 = true, dance3 = true, laugh = true, cheer = true}
local MESSAGES_FADE_OUT_TIME = 30
--[[ END OF CONSTANTS ]]

--[[ SERVICES ]]
local RunService = game:GetService('RunService')
local CoreGuiService = game:GetService('CoreGui')
local TextChatService = game:GetService('TextChatService')
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
if USE_PLAYER_GUI_TESTING then
	GuiRoot = Instance.new("ScreenGui")
	GuiRoot.Name = "ChatScript2Gui"
	GuiRoot.ResetOnSpawn = false
	GuiRoot.IgnoreGuiInset = true
	GuiRoot.DisplayOrder = 450
	GuiRoot.Parent = Player:WaitForChild('PlayerGui')
else
	GuiRoot = CoreGuiService:WaitForChild('RobloxGui')
end
--[[ END OF SCRIPT VARIABLES ]]

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
			return mSignaler.Event:connect(function()
				f(unpack(mArgData, 1, mArgDataCount))
			end)
		end

		function sig:wait()
			mSignaler.Event:wait()
			assert(mArgData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
			return unpack(mArgData, 1, mArgDataCount)
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
		local success, _ = pcall(function() GuiService:SetGlobalGuiInset(0, x, 0, y) end)
		if not success then
			pcall(function() GuiService:SetGlobalSizeOffsetPixel(-x, -y) end) -- Legacy GUI-offset function
		end
	end

	local baseUrl = "https://www.roblox.com/"
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
		return value%8
	end

	function Util.ComputeChatColor(pName)
		return CHAT_COLORS[GetNameValue(pName) + 1]
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
		return "[" ..  playerName .. "]"
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
		local toMesasgeDisplayText = "To: "
		local toMessageSize = Util.GetStringTextBounds(toMesasgeDisplayText, this.Settings.Font, this.Settings.FontSize)
		local fromMesasgeDisplayText = "From: "
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
				Name = 'whisperFromText';
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
		else
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
				SelectPlayerEvent:fire(this.SendingPlayer)
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
		if this.SendingPlayer and ADMIN_LIST[tostring(this.SendingPlayer.userId)] then
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
	this.MessageMode = "All"
	this.TargetWhisperPlayer = nil
	this.Settings = settings

	this.ChatBarGainedFocusEvent = Util.Signal()
	this.ChatBarLostFocusEvent = Util.Signal()
	this.ChatCommandEvent = Util.Signal() -- success, actionType, captures
	this.ChatErrorEvent = Util.Signal() -- success, actionType, captures

	this.ChatMatchingRegex =
		{
			[function(chatBarText) return string.find(string.lower(chatBarText), "^/w (%w+)") end] = "Whisper";
			[function(chatBarText) return string.find(string.lower(chatBarText), "^/whisper (%w+)") end] = "Whisper";

			[function(chatBarText) return string.find(chatBarText, "^%%") end] = "Team";
			[function(chatBarText) return string.find(chatBarText, "^(TEAM)") end] = "Team";
			[function(chatBarText) return string.find(string.lower(chatBarText), "^/t") end] = "Team";
			[function(chatBarText) return string.find(string.lower(chatBarText), "^/team") end] = "Team";

			[function(chatBarText) return string.find(string.lower(chatBarText), "^/a") end] = "All";
			[function(chatBarText) return string.find(string.lower(chatBarText), "^/all") end] = "All";
			[function(chatBarText) return string.find(string.lower(chatBarText), "^/s") end] = "All";
			[function(chatBarText) return string.find(string.lower(chatBarText), "^/say") end] = "All";

			[function(chatBarText) return string.find(string.lower(chatBarText), "^/e") end] = "Emote";
			[function(chatBarText) return string.find(string.lower(chatBarText), "^/emote") end] = "Emote";

			[function(chatBarText) return string.find(string.lower(chatBarText), "^/%?") end] = "Help";
			[function(chatBarText) return string.find(string.lower(chatBarText), "^/help?") end] = "Help";
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
		-- Chat hotkey is handled through UserInputService
		this.SpecialKeyPressedConn = Util.DisconnectEvent(this.SpecialKeyPressedConn)
		this.SlashKeyReleaseConn = Util.DisconnectEvent(this.SlashKeyReleaseConn)
		this.ClickToChatButtonConn = Util.DisconnectEvent(this.ClickToChatButtonConn)
		this.ChatBarFocusLostConn = Util.DisconnectEvent(this.ChatBarFocusLostConn)
		this.ChatBarLostFocusConn = Util.DisconnectEvent(this.ChatBarLostFocusConn)
		this.SelectChatModeConn = Util.DisconnectEvent(this.SelectChatModeConn)
		this.SelectPlayerConn = Util.DisconnectEvent(this.SelectPlayerConn)
		this.FocusChatBarInputBeganConn = Util.DisconnectEvent(this.FocusChatBarInputBeganConn)
		this.InputBeganConn = Util.DisconnectEvent(this.InputBeganConn)
	end

	local function HookUpEvents()
		TearDownEvents() -- Cleanup old events

		-- ChatHotKey is '/'
		-- Focus on key RELEASE so the initiating slash cannot be typed into the TextBox.
		-- Focusing on InputBegan works in Studio but may insert "/" in the live client.
		this.SpecialKeyPressedConn = InputService.InputBegan:Connect(function(input, processed)
			if processed or input.KeyCode ~= Enum.KeyCode.Slash then return end
			if InputService:GetFocusedTextBox() then return end
			if this.SlashKeyReleaseConn then return end
			this.SlashKeyReleaseConn = InputService.InputEnded:Connect(function(endedInput)
				if endedInput.KeyCode ~= Enum.KeyCode.Slash then return end
				this.SlashKeyReleaseConn:Disconnect()
				this.SlashKeyReleaseConn = nil
				this:FocusChatBar()
			end)
		end)

		if this.ClickToChatButton then this.ClickToChatButtonConn = this.ClickToChatButton.MouseButton1Click:connect(function() this:FocusChatBar() end) end

		if this.ChatBar then this.ChatBarFocusLostConn = this.ChatBar.FocusLost:connect(function(...) this.ChatBarLostFocusEvent:fire(...) end) end

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

	function this:CoreGuiChanged(coreGuiType, enabled)
		if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
			if enabled then
				HookUpEvents()
			else
				TearDownEvents()
			end
			if this.ChatBarContainer then
				this.ChatBarContainer.Visible = enabled
			end
		end
	end

	function this:IsAChatMode(mode)
		return ChatModesDict[mode] ~= nil
	end

	function this:IsAnEmoteMode(mode)
		return mode == "Emote"
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
			local newText = this:GetChatBarText()
			if #newText > this.Settings.MaxCharactersInMessage then
				local fixedText = ""
				-- This is a hack to deal with the bug that holding down a key for repeated input doesn't trigger the textChanged event
				if #newText == #previousText + 1 then
					fixedText = string.sub(previousText, 1, this.Settings.MaxCharactersInMessage)
				else
					fixedText = string.sub(newText, 1, this.Settings.MaxCharactersInMessage)
				end
				this:SetChatBarText(fixedText)
				previousText = fixedText
				-- TODO: Flash Max Characters Feedback
			else
				previousText = newText
			end
		end
	end

	function this:GetChatBarText()
		return this.ChatBar and this.ChatBar.Text or ""
	end

	function this:SetChatBarText(newText)
		if this.ChatBar then
			this.ChatBar.Text = newText
		end
	end

	function this:GetMessageMode()
		return this.MessageMode
	end

	function this:SetMessageMode(newMessageMode)
		newMessageMode = ChatModesDict[newMessageMode]
		if this.MessageMode ~= newMessageMode then
			this.MessageMode = newMessageMode
			if this.ChatModeText then
				if newMessageMode == 'Whisper' then
					-- TODO: also update this when they change players to whisper to
					local chatRecipientText = "[" .. (this.TargetWhisperPlayer and this.TargetWhisperPlayer.Name or "") .. "]"
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
					this.ChatBar.Size = UDim2.new(1, -offset - 5, 1, 0)
					this.ChatBar.Position = UDim2.new(0, offset + 5, 0, 0)
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
			this.ChatBarChangedConn = Util.DisconnectEvent(this.ChatBarChangedConn)
			this.ChatBarChangedConn = this.ChatBar.Changed:connect(function(prop)
				if prop == "Text" then
					this:OnChatBarTextChanged()
				end
			end)
			if Util.IsTouchDevice() then
				this:SetMessageMode('All') -- Don't remember message mode on mobile devices
			else
				-- Use a count to make sure you double backspace out of a chatmode; less likely to accidently do it.
				local count = 0
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

	function this:SendToChannel(name, text)
		local channels = TextChatService:FindFirstChild("TextChannels")
		local channel = channels and channels:FindFirstChild(name)
		if not channel then
			self.ChatErrorEvent:fire("Chat channel unavailable: " .. name)
			return
		end
		task.spawn(function()
			local success, err = pcall(function() channel:SendAsync(text) end)
			if not success then self.ChatErrorEvent:fire(tostring(err)) end
		end)
	end

	function this:SendWhisper(target, text)
		local channels = TextChatService:FindFirstChild("TextChannels")
		local userA, userB = math.min(Player.UserId, target.UserId), math.max(Player.UserId, target.UserId)
		local whisper = channels and channels:FindFirstChild("RBXWhisper:" .. userA .. "_" .. userB)
		if not whisper then
			self.ChatErrorEvent:fire("Whisper channel unavailable; try /w " .. target.Name .. " in Roblox chat.")
			return
		end
		task.spawn(function()
			local success, err = pcall(function() whisper:SendAsync(text) end)
			if not success then self.ChatErrorEvent:fire(tostring(err)) end
		end)
	end

	function this:OnChatBarFocusLost(enterPressed)
		if self.ChatBar then
			self.ChatBar.Visible = false
			if enterPressed then
				local didMatchSlashCommand = this:ProcessChatBarModes(false)
				local cText = this:SanitizeInput(this:GetChatBarText())
				if cText ~= "" then
					-- For now we will let any slash command go through
					--if not didMatchSlashCommand and string.sub(cText,1,1) == "/" then
					--	this.ChatCommandEvent:fire(false, "Unknown", cText)
					--else
					local currentMessageMode = this:GetMessageMode()
					-- {All, Team, Whisper}
					if currentMessageMode == 'Team' then
						if Player and Player.Neutral == true then
							this.ChatErrorEvent:fire("You are not in any team.")
						else
							this:SendToChannel("RBXTeam", cText)
						end
					elseif currentMessageMode == 'Whisper' then
						if this.TargetWhisperPlayer then
							if this.TargetWhisperPlayer == Player then
								this.ChatErrorEvent:fire("You cannot send a whisper to yourself.")
							else
								this:SendWhisper(this.TargetWhisperPlayer, cText)
							end
						else
							this.ChatErrorEvent:fire("Invalid whisper target.")
						end
					elseif currentMessageMode == 'All' then
						this:SendToChannel("RBXGeneral", cText)
					else
						spawn(function() error("ChatScript: Unknown Message Mode of " .. tostring(currentMessageMode)) end)
					end
					--end
				end
				this:SetChatBarText("")
			end
		end
		if self.ClickToChatButton then
			self.ClickToChatButton.Visible = true
		end
		if this.ChatModeText then
			this.ChatModeText.Visible = false
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
		};
		local clickToChatButton = Util.Create'TextButton'
		{
			Name = 'ClickToChat';
			Position = UDim2.new(0,9,0,0);
			Size = UDim2.new(1, -9, 1, 0);
			BackgroundTransparency = 1;
			ZIndex = 3;
			Text = 'To chat click here or press "/" key';
			TextColor3 = this.Settings.GlobalTextColor;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Top;
			Font = Enum.Font.SourceSansBold;
			FontSize = Enum.FontSize.Size18;
			Parent = chatBarContainer;
		}
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
		local chatModeText = Util.Create'TextButton'
		{
			Name = 'ChatModeText';
			Position = UDim2.new(0, 9, 0, 0);
			Size = UDim2.new(1, -9, 1, 0);
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

		this.ChatBarContainer = chatBarContainer
		this.ClickToChatButton = clickToChatButton
		this.ChatBar = chatBar
		this.ChatModeText = chatModeText
		this.ChatBarContainer.Parent = GuiRoot
		this.ChatBarContainer.Position = UDim2.new(0,0,1,-20)
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
		return point0.X <= pt.X and point1.X >= pt.X and
			point0.Y <= pt.Y and point1.Y >= pt.Y
	end

	function this:IsHovering()
		if this.ChatContainer and this.LastMousePosition then
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

	function this:FadeIn(duration, lockFade)
		if not FadeLock then
			duration = duration or 0.75
			-- fade in
			if this.BackgroundTweener then
				this.BackgroundTweener:Cancel()
			end
			lastFadeInTime = tick()
			lastChatActivity = tick()
			this.ScrollingFrame.ScrollingEnabled = true
			this.BackgroundTweener = Util.PropertyTweener(this.ChatContainer, 'BackgroundTransparency', this.ChatContainer.BackgroundTransparency, 0.7, duration, Util.Linear)
			this.BackgroundVisible = true
			this:FadeInChats()

			this.ChatWindowPagingConn = Util.DisconnectEvent(this.ChatWindowPagingConn)
			this.ChatWindowPagingConn = InputService.InputBegan:connect(function(inputObject)
				local key = inputObject.KeyCode
				if key == Enum.KeyCode.PageUp then
					this.ScrollingFrame.CanvasPosition = Vector2.new(0, math.max(0, this.ScrollingFrame.CanvasPosition.Y - this.ScrollingFrame.AbsoluteSize.Y))
				elseif key == Enum.KeyCode.PageDown then
					this.ScrollingFrame.CanvasPosition =
						Vector2.new(0, Util.Clamp(0, --min
							this.ScrollingFrame.CanvasSize.Y.Offset - this.ScrollingFrame.AbsoluteSize.Y, --max
							this.ScrollingFrame.CanvasPosition.Y + this.ScrollingFrame.AbsoluteSize.Y))
				elseif key == Enum.KeyCode.Home then
					this.ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
				elseif key == Enum.KeyCode.End then
					this.ScrollingFrame.CanvasPosition = Vector2.new(0, this.ScrollingFrame.CanvasSize.Y.Offset - this.ScrollingFrame.AbsoluteSize.Y)
				end
			end)
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

	function this:ScrollToBottom()
		if this.ScrollingFrame then
			this.ScrollingFrame.CanvasPosition = Vector2.new(0, math.max(0, this.ScrollingFrame.CanvasSize.Y.Offset - math.max(0, this.ScrollingFrame.AbsoluteWindowSize.Y)))
		end
	end

	local ResizeCount = 0
	function this:OnResize()
		ResizeCount = ResizeCount + 1
		local currentResizeCount = ResizeCount
		local isScrolledDown = this:IsScrolledDown()
		-- Unfortunately there is a race condition so we need this wait here.
		wait()
		if isScrolledDown then
			this:ScrollToBottom()
		end
		if this.ScrollingFrame then
			if currentResizeCount ~= ResizeCount then return end
			local scrollingFrameAbsoluteSize = this.ScrollingFrame.AbsoluteSize
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

					this.ScrollingFrame.CanvasSize = UDim2.new(this.ScrollingFrame.CanvasSize.X.Scale, this.ScrollingFrame.CanvasSize.X.Offset, this.ScrollingFrame.CanvasSize.Y.Scale, ySize)
				end
			end
			if isScrolledDown then
				this:ScrollToBottom()
			end
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
		end

		if silently then
			chatMessage:FadeOut(true)
		else
			this:FadeInChats()
			lastChatActivity = tick()
		end
	end

	function this:AddSystemChatMessage(chattedMessage, silently)
		local chatMessage = CreateSystemChatMessage(this.Settings, chattedMessage)
		this:PushMessageIntoQueue(chatMessage, silently)
	end

	function this:AddChatMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer, silently)
		if this:FilterMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer) then
			local chatMessage = CreatePlayerChatMessage(this.Settings, playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
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
						this.ScrollingFrame.CanvasPosition =
							Vector2.new(this.ScrollingFrame.CanvasPosition.X,
								Util.Clamp(0, --min
									this.ScrollingFrame.CanvasSize.Y.Offset - this.ScrollingFrame.AbsoluteSize.Y, --max
									this.ScrollingFrame.CanvasPosition.Y))
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
				yCanvasSize - yScrolledPosition <= yContainerSize + 5 -- Give a little wiggle room for the is scrolldown check
		end
		return false
	end

	function this:CoreGuiChanged(coreGuiType, enabled)
		if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
			if this.ChatContainer then
				this.ChatContainer.Visible = enabled
			end
		end
		-- If we are using bubble-chat then do not show chat window
		if this.ChatContainer and false then
			this.ChatContainer.Visible = false
		end
	end

	local function CreateChatWindow()
		local container = Util.Create'Frame'
		{
			Name = 'ChatWindowContainer';
			-- Height is a multiple of chat message height, maybe keep this value at 150 and move that padding into the messageContainer
			Size = UDim2.new(0.3, 0, 0.25, 0);
			Position = UDim2.new(0, 8, 0, 37);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
		};
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
		end
		container.Changed:connect(function(prop) if prop == 'AbsoluteSize' then this:OnResize() end end)

		local function RobloxClientScreenSizeChanged(newSize)
			if container then
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

		if Util.IsTouchDevice() then
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
				while true do
					wait()
					if this.BackgroundVisible then
						if not dontFadeOutOnMouseLeave then
							this:FadeOut(0.25)
						end
						-- If background is not visible/in-focus
					elseif this.ChatsVisible and now > lastChatActivity + MESSAGES_FADE_OUT_TIME then
						this:FadeOutChats()
					end
				end
			end)
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
							this:FadeOutChats()
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
			GlobalTextColor = Color3.new(255/255, 255/255, 243/255);
			WhisperTextColor = Color3.new(77/255, 139/255, 255/255);
			TeamTextColor = Color3.new(230/255, 207/255, 0);
			DefaultMessageTextColor = Color3.new(255/255, 255/255, 243/255);
			AdminTextColor = Color3.new(1, 215/255, 0);
			TextStrokeTransparency = 0.75;
			TextStrokeColor = Color3.new(34/255,34/255,34/255);
			Font = Enum.Font.SourceSansBold;
			--Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size18;
			MaxWindowChatMessages = 50;
			MaxCharactersInMessage = 140; -- Same as a tweet :D
		}


	function this:CoreGuiChanged(coreGuiType, enabled)
		if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
			if Util.IsTouchDevice() then
				Util.SetGUIInsetBounds(0, 0)
			else
				if enabled and this.ChatBarWidget then
					-- Reserve bottom 20 pixels for our chat bar
					Util.SetGUIInsetBounds(0, 20)
				else
					Util.SetGUIInsetBounds(0, 0)
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
			this.ChatWindowWidget:CoreGuiChanged(coreGuiType, enabled)
		end
		if this.ChatBarWidget then
			this.ChatBarWidget:CoreGuiChanged(coreGuiType, enabled)
		end
	end

	-- This event has 4 callback arguments
	-- Enum.PlayerChatType.{All|Team|Whisper}, chatPlayer, message, targetPlayer
	function this:OnPlayerChatted(playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
		if this.ChatWindowWidget then
			this.ChatWindowWidget:AddChatMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
		end
	end

	function this:OnPlayerAdded()
		self.PlayerChattedConn = Util.DisconnectEvent(self.PlayerChattedConn)
		self.PlayerChattedConn = TextChatService.MessageReceived:Connect(function(message)
			if not message.Text or message.Text == "" then return end
			local source = message.TextSource
			local author = source and PlayersService:GetPlayerByUserId(source.UserId) or nil
			local channel = message.TextChannel
			local channelName = channel and channel.Name or ""
			local chatType = Enum.PlayerChatType.All
			local receiver = nil
			if channelName == "RBXTeam" then
				chatType = Enum.PlayerChatType.Team
			elseif channelName:match("^RBXWhisper") then
				chatType = Enum.PlayerChatType.Whisper
				if source and author == Player then
					local id1, id2 = channelName:match("^RBXWhisper:(%d+)_(%d+)")
					local otherId = tonumber(id1) == Player.UserId and tonumber(id2) or tonumber(id1)
					if otherId then receiver = PlayersService:GetPlayerByUserId(otherId) end
				end
			end
			self:OnPlayerChatted(chatType, author, message.Text, receiver)
		end)
	end

	function this:GetBlockedPlayersAsync()
		-- The old internal HTTP endpoint is no longer accessible to LocalScripts.
		return {}
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
			--this.ChatWindowWidget:AddSystemChatMessage("Welcome to Roblox")
			this.ChatWindowWidget:AddSystemChatMessage("Please type /? for a list of commands", true)
		end
	end

	function this:PrintHelp()
		if this.ChatWindowWidget then
			this.ChatWindowWidget:AddSystemChatMessage("Help Menu")
			this.ChatWindowWidget:AddSystemChatMessage("Chat Commands:")
			this.ChatWindowWidget:AddSystemChatMessage("/w [PlayerName] or /whisper [PlayerName] - Whisper Chat")
			this.ChatWindowWidget:AddSystemChatMessage("/t or /team - Team Chat")
			this.ChatWindowWidget:AddSystemChatMessage("/a or /all - All Chat")
		end
	end

	function this:CreateGUI()
		if true then -- Modern TextChatService replaces legacy ChatMode
			-- NOTE: eventually we will make multiple chat window frames
			-- Settings is a table, which makes it a pointing and is kosher to pass by reference
			this.ChatWindowWidget = CreateChatWindowWidget(this.Settings)
			this.ChatBarWidget = CreateChatBarWidget(this.Settings)
			this.ChatWindowWidget:FadeOut(0)
			local focusCount = 0
			this.ChatBarWidget.ChatBarGainedFocusEvent:connect(function()
				focusCount = focusCount + 1
				this.ChatWindowWidget:FadeIn(0.25)
				this.ChatWindowWidget:SetFadeLock(true)
			end)
			this.ChatBarWidget.ChatBarLostFocusEvent:connect(function()
				local focusNow = focusCount
				if Util.IsTouchDevice() then
					wait(2)
					if focusNow == focusCount then
						this.ChatWindowWidget:SetFadeLock(false)
					end
				else
					this.ChatWindowWidget:SetFadeLock(false)
				end
			end)

			this.ChatBarWidget.ChatErrorEvent:connect(function(msg)
				if msg then
					this.ChatWindowWidget:AddSystemChatMessage(msg)
				end
			end)

			this.ChatBarWidget.ChatCommandEvent:connect(function(success, actionType, capture)
				if actionType == "Help" then
					this:PrintHelp()
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

			if Util.IsTouchDevice() then
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

	function this:Initialize()
		--spawn(function()
		--	this:GetBlockedPlayersAsync()
		--end)

		pcall(function() TextChatService.ChatWindowConfiguration.Enabled = false end)
		pcall(function() TextChatService.ChatInputBarConfiguration.Enabled = false end)
		this:OnPlayerAdded()
		-- Upsettingly, it seems everytime a player is added, you have to redo the connection
		-- NOTE: PlayerAdded only fires on the server, hence ChildAdded is used here
		PlayersService.ChildAdded:connect(function()
			this:OnPlayerAdded()
		end)

		this:CreateGUI()

		pcall(function()
			this:CoreGuiChanged(Enum.CoreGuiType.Chat, StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat))
			this.CoreGuiChangedConn = Util.DisconnectEvent(this.CoreGuiChangedConn)
			this.CoreGuiChangedConn = StarterGui.CoreGuiChangedSignal:connect(
				function(coreGuiType,enabled)
					this:CoreGuiChanged(coreGuiType, enabled)
				end)
		end)

		this:PrintWelcome()
	end

	return this
end

-- ModuleScript entry point. Settings calls ChatScript2.Start().
local ChatScript2 = {}
local started = false
function ChatScript2.Start()
	if started then return end
	started = true
	local ChatInstance = CreateChat()
	ChatInstance:Initialize()
	return ChatInstance
end
return ChatScript2

end;
};
G2L_MODULES[G2L["5"]] = {
Closure = function()
    local script = G2L["5"];-- 2014 Roblox HealthScript, modernized as a ModuleScript for 2015E Settings.
-- Preserves original cap textures, 170x15 centered health bar, colors and hurt overlay.
-- Requires no external modules. Place alongside Settings and BackpackScript in StarterGui.

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local player = Players.LocalPlayer


local HealthScript = {}
local started = false
local connections = {}
local currentHumanoid = nil
local healthGui, healthBar, overlay
local coloredPieces = {}
local lastHealth = nil
local hurtTween = nil
local overlayGeneration = 0

local CAP_WIDTH = 7
local BAR_HEIGHT = 15
local BAR_WIDTH = 170
local HURT_THRESHOLD_PERCENT = 5
local GREEN = Color3.new(0.2, 1, 0.2)
local RED = Color3.new(1, 0.2, 0.2)
local YELLOW = Color3.new(1, 1, 0.2)
local BACK_CENTER = "rbxasset://textures/ui/Health-BKG-Center.png"
local BACK_LEFT = "rbxasset://textures/ui/Health-BKG-Left-Cap.png"
local BACK_RIGHT = "rbxasset://textures/ui/Health-BKG-Right-Cap.png"
local HURT_IMAGE = "rbxassetid://34854607"

local function connect(signal, fn)
	local conn = signal:Connect(fn)
	table.insert(connections, conn)
	return conn
end

local function createImage(name, image, size, position, parent, color)
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = name
	imageLabel.BackgroundTransparency = 1
	imageLabel.BorderSizePixel = 0
	imageLabel.Image = image
	imageLabel.Size = size
	imageLabel.Position = position
	imageLabel.ImageColor3 = color or Color3.new(1,1,1)
	imageLabel.Parent = parent
	return imageLabel
end

local function createGui()
	if healthGui and healthGui.Parent then return end
	local playerGui = player:WaitForChild("PlayerGui")
	local previous = playerGui:FindFirstChild("2015EHealthGui")
	if previous then previous:Destroy() end

	healthGui = Instance.new("ScreenGui")
	healthGui.Name = "2015EHealthGui"
	healthGui.ResetOnSpawn = false
	healthGui.IgnoreGuiInset = true
	healthGui.DisplayOrder = 501
	healthGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	healthGui.Parent = playerGui

	overlay = createImage("HurtOverlay", HURT_IMAGE,
		UDim2.new(20,0,20,0), UDim2.new(-10,0,-10,0), healthGui)
	overlay.Visible = false
	overlay.ZIndex = 1

	local frame = Instance.new("Frame")
	frame.Name = "HealthFrame"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Position = UDim2.new(0.5,-85,1,-48) -- 18 pixels higher than previous version
	frame.Size = UDim2.new(0,BAR_WIDTH,0,BAR_HEIGHT)
	frame.ZIndex = 2
	frame.Parent = healthGui

	-- Original white background cap images.
	createImage("healthBarBackCenter", BACK_CENTER,
		UDim2.new(1,-CAP_WIDTH*2,1,0), UDim2.new(0,CAP_WIDTH,0,0), frame).ZIndex = 2
	createImage("healthBarBackLeft", BACK_LEFT,
		UDim2.new(0,CAP_WIDTH,1,0), UDim2.new(), frame).ZIndex = 2
	createImage("healthBarBackRight", BACK_RIGHT,
		UDim2.new(0,CAP_WIDTH,1,0), UDim2.new(1,-CAP_WIDTH,0,0), frame).ZIndex = 2

	healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.BackgroundTransparency = 1 -- Preserve original 2014 image-only health fill
	healthBar.BackgroundColor3 = GREEN
	healthBar.BorderSizePixel = 0
	healthBar.ClipsDescendants = true
	healthBar.Size = UDim2.fromScale(1,1)
	healthBar.ZIndex = 3
	healthBar.Parent = frame

	coloredPieces.center = createImage("healthBarCenter", BACK_CENTER,
		UDim2.new(1,-CAP_WIDTH*2,1,0), UDim2.new(0,CAP_WIDTH,0,0), healthBar, GREEN)
	coloredPieces.left = createImage("healthBarLeft", BACK_LEFT,
		UDim2.new(0,CAP_WIDTH,1,0), UDim2.new(), healthBar, GREEN)
	coloredPieces.right = createImage("healthBarRight", BACK_RIGHT,
		UDim2.new(0,CAP_WIDTH,1,0), UDim2.new(1,-CAP_WIDTH,0,0), healthBar, GREEN)
	for _, piece in pairs(coloredPieces) do piece.ZIndex = 3 end
end

local function animateHurtOverlay()
	if not overlay then return end
	overlayGeneration += 1
	local generation = overlayGeneration
	if hurtTween then hurtTween:Cancel() end
	overlay.Position = UDim2.new(0,0,0,0)
	overlay.Size = UDim2.new(1,0,1,0)
	overlay.Visible = true
	hurtTween = TweenService:Create(overlay,
		TweenInfo.new(10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = UDim2.new(-10,0,-10,0), Size = UDim2.new(20,0,20,0)})
	hurtTween.Completed:Once(function()
		if generation == overlayGeneration and overlay then overlay.Visible = false end
	end)
	hurtTween:Play()
end

local function updateGui(health)
	if not healthBar or not currentHumanoid then return end
	local maxHealth = currentHumanoid.MaxHealth
	local percent = (maxHealth > 0 and maxHealth < math.huge) and health / maxHealth or 1
	if percent ~= percent then percent = 1 end
	percent = math.clamp(percent, 0, 1)
	local color = maxHealth == math.huge and YELLOW or (percent > 0.25 and GREEN or RED)
	for _, piece in pairs(coloredPieces) do piece.ImageColor3 = color end
	healthBar.Size = UDim2.new(percent,0,1,0)

	local pixelWidth = BAR_WIDTH * percent
	coloredPieces.center.Visible = pixelWidth >= CAP_WIDTH
	coloredPieces.right.Visible = pixelWidth >= 2 * CAP_WIDTH + 1
	if pixelWidth >= CAP_WIDTH and pixelWidth < 2 * CAP_WIDTH + 1 then
		coloredPieces.center.Size = UDim2.new(0, pixelWidth - CAP_WIDTH, 1, 0)
	else
		coloredPieces.center.Size = UDim2.new(1, -CAP_WIDTH * 2, 1, 0)
	end

	if lastHealth ~= nil and maxHealth > 0 and maxHealth < math.huge then
		if lastHealth - health >= maxHealth * HURT_THRESHOLD_PERCENT / 100 then
			animateHurtOverlay()
		end
	end
	lastHealth = health
end

local humanoidConnections = {}
local function disconnectHumanoid()
	for _, conn in ipairs(humanoidConnections) do conn:Disconnect() end
	table.clear(humanoidConnections)
	currentHumanoid = nil
	lastHealth = nil
end

local function onCharacter(character)
	disconnectHumanoid()
	local humanoid = character:WaitForChild("Humanoid", 15)
	if not humanoid or player.Character ~= character then return end
	currentHumanoid = humanoid
	lastHealth = humanoid.Health
	createGui()
	updateGui(humanoid.Health)
	table.insert(humanoidConnections, humanoid.HealthChanged:Connect(function(health)
		if currentHumanoid == humanoid then updateGui(health) end
	end))
	table.insert(humanoidConnections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		if currentHumanoid == humanoid then updateGui(humanoid.Health) end
	end))
	table.insert(humanoidConnections, humanoid.Died:Connect(function()
		if currentHumanoid == humanoid then updateGui(0) end
	end))
end

function HealthScript.Start()
	if started then return end
	started = true
	task.spawn(function()
		local backpackModule = script.Parent:WaitForChild("BackpackScript", 10)
		if not backpackModule then
			warn("2015E BackpackScript ModuleScript missing from StarterGui")
			return
		end
		local ok, result = pcall(require, backpackModule)
		if not ok then
			warn("2015E BackpackScript require failed:", result)
			return
		end
		local startOk, err = pcall(function() result.Start() end)
		if not startOk then warn("2015E BackpackScript startup failed:", err) end
	end)
	createGui()
	-- Disable Roblox's default health display; custom display remains visible.
	-- SetCoreGuiEnabled may temporarily fail before Roblox initializes CoreGui.
	task.spawn(function()
		for _ = 1, 8 do
			local ok = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
			end)
			if ok then break end
			task.wait(0.5)
		end
	end)
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({BACK_CENTER, BACK_LEFT, BACK_RIGHT, HURT_IMAGE})
		end)
	end)
	connect(player.CharacterAdded, onCharacter)
	if player.Character then task.spawn(onCharacter, player.Character) end
end

function HealthScript.Stop()
	if not started then return end
	started = false
	disconnectHumanoid()
	for _, conn in ipairs(connections) do conn:Disconnect() end
	table.clear(connections)
	overlayGeneration += 1
	if hurtTween then hurtTween:Cancel(); hurtTween = nil end
	if healthGui then healthGui:Destroy(); healthGui = nil end
	healthBar, overlay = nil, nil
	coloredPieces = {}
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true) end)
end

return HealthScript

end;
};
G2L_MODULES[G2L["6"]] = {
Closure = function()
    local script = G2L["6"];-- PlayerListScript2: original 2015 player list ported as a StarterGui ModuleScript.
local Module = {}
local running = false
function Module.Start()
	if running then return end
	running = true
	local ok, err = xpcall(function()
        --[[
        		// FileName: PlayerListScript.lua
        		// Written by: jmargh
        		// Description: Implementation of in game player list and leaderboard
        ]]
		local GuiService = game:GetService('GuiService')	-- NOTE: Can only use in core scripts
		local UserInputService = game:GetService('UserInputService')
		local Players = game:GetService('Players')
		local TeamsService = game:FindFirstChildOfClass('Teams')

		-- Standalone dropdown helper replaces the retired LoadLibrary('RbxGui').
		local RbxGui = {}
		function RbxGui.CreateDropDownMenu(options, onSelect, _, _, zIndex)
			local root = Instance.new('Frame')
			root.Name = 'ClassicDropDown'
			root.BackgroundTransparency = 1
			root.Size = UDim2.fromOffset(220, 32)
			local button = Instance.new('TextButton')
			button.Name = 'DropDownMenuButton'
			button.Size = UDim2.fromScale(1, 1)
			button.Style = Enum.ButtonStyle.RobloxButton
			button.Font = Enum.Font.Arial
			button.TextSize = 14
			button.TextColor3 = Color3.new(1, 1, 1)
			button.Text = 'Select'
			button.ZIndex = (zIndex or 2) + 2
			button.Parent = root
			local menu = Instance.new('ScrollingFrame')
			menu.Name = 'DropDownList'
			menu.Size = UDim2.new(1, 0, 0, math.min(#options * 28, 170))
			menu.Position = UDim2.fromOffset(0, 32)
			menu.CanvasSize = UDim2.fromOffset(0, #options * 28)
			menu.ScrollBarThickness = 5
			menu.BorderSizePixel = 1
			menu.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			menu.Visible = false
			menu.ZIndex = (zIndex or 2) + 10
			menu.Parent = root
			for i, choice in ipairs(options) do
				local item = Instance.new('TextButton')
				item.Name = 'Choice' .. i
				item.Position = UDim2.fromOffset(0, (i - 1) * 28)
				item.Size = UDim2.new(1, -6, 0, 28)
				item.BackgroundTransparency = 1
				item.Font = Enum.Font.Arial
				item.TextSize = 14
				item.TextColor3 = Color3.new(1, 1, 1)
				item.Text = choice
				item.ZIndex = menu.ZIndex + 1
				item.Parent = menu
				item.MouseButton1Click:Connect(function()
					button.Text = choice
					menu.Visible = false
					onSelect(choice)
				end)
			end
			button.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)
			return root, function(selection)
				button.Text = selection or 'Select'
				menu.Visible = false
			end
		end

		while not Players.LocalPlayer do
			wait()
		end
		local Player = Players.LocalPlayer
		local playerGui = Player:WaitForChild('PlayerGui')
		local RobloxGui = playerGui:FindFirstChild('PlayerListScript2Gui')
		if RobloxGui then RobloxGui:Destroy() end
		RobloxGui = Instance.new('ScreenGui')
		RobloxGui.Name = 'PlayerListScript2Gui'
		RobloxGui.ResetOnSpawn = false
		RobloxGui.DisplayOrder = 210
		RobloxGui.IgnoreGuiInset = false
		RobloxGui.Parent = playerGui
		pcall(function() game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end)

		--[[ Script Variables ]]--
		local MyPlayerEntry = nil
		local PlayerEntries = {}
		local GameStats = {}
		local StatAddId = 0
		local TeamEntries = {}
		local TeamAddId = 0
		local ScaleX = 1
		local NeutralTeam = nil
		local IsShowingNeutralFrame = false
		local IsExpanding = false
		local LastSelectedFrame = nil
		local LastSelectedPlayer = nil
		local IsPlayerListExpanded = false
		local MinContainerSize = UDim2.new(0, 200, 0.5, 0)
		local StatNameFrame = nil
		local PlayerEntrySizeY = 20
		local TeamEntrySizeY = 20
		local NameEntrySizeX = 165
		local StatEntrySizeX = 60

		local IsPersonalServer = false
		local PersonalServerService = nil
		if workspace:FindFirstChild('PSVariable') then
			IsPersonalServer = true
			PersonalServerService = nil -- PersonalServerService retired
		end
		workspace.ChildAdded:connect(function(child)
			if child.Name == 'PSVariable' and child:IsA('BoolValue') then
				IsPersonalServer = true
				PersonalServerService = nil -- PersonalServerService retired
			end
		end)

		--Report Abuse
		local AbusingPlayer = nil
		local AbuseReason = nil

		--[[ Constants ]]--
		local ENTRY_PAD = 1
		local BG_TRANSPARENCY = 0.7
		local TEXT_STROKE_TRANSPARENCY = 0.75
		local TEXT_COLOR = Color3.new(1, 1, 243/255)
		local TEXT_STROKE_COLOR = Color3.new(34/255, 34/255, 34/255)
		local TWEEN_TIME = 0.15
		local MAX_LEADERSTATS = 4
		local MAX_STR_LEN = 10

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

		local PRIVILEGE_LEVEL = {
			OWNER = 255,
			ADMIN = 240,
			MEMBER = 128,
			VISITOR = 10,
			BANNED = 0,
		}

		--[[ Images ]]--
		local EXPAND_ICON = 'rbxasset://textures/ui/expandPlayerList.png'
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
					return Player:GetFriendStatus(selectedPlayer)
				end)
				if success then
					return result
				else
					return Enum.FriendStatus.NotFriend
				end
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

		local function getMembershipIcon(player)
			local userIdStr = tostring(player.UserId)
			if ADMINS[userIdStr] then return ADMINS[userIdStr] end
			if player.UserId == game.CreatorId and game.CreatorType == Enum.CreatorType.User then
				return PLACE_OWNER_ICON
			end
			-- Legacy Builders Club/TBC/OBC membership tiers have been retired.
			return nil
		end

		local function isValidStat(obj)
			return obj:IsA('StringValue') or obj:IsA('IntValue') or obj:IsA('BoolValue') or obj:IsA('NumberValue') or
				obj:IsA('DoubleConstrainedValue') or obj:IsA('IntConstrainedValue')
		end

		local function sortPlayerEntries(a, b)
			if a.IsPrimary == b.IsPrimary then
				return a.Player.Name:upper() < b.Player.Name:upper()
			end
			if not a.IsPrimary then return false end
			if not b.IsPrimary then return true end
			return a.IsPrimary < b.IsPrimary
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

		-- Start of Gui Creation
		local Container = Instance.new('Frame')
		Container.Name = "PlayerListContainer"
		Container.Position = UDim2.new(1, -202, 0, 2)
		Container.Size = MinContainerSize
		Container.BackgroundTransparency = 1
		Container.Visible = false
		Container.Parent = RobloxGui

		-- Header
		local Header = Instance.new('Frame')
		Header.Name = "Header"
		Header.Position = UDim2.new(0, 0, 0, 0)
		Header.Size = UDim2.new(1, 0, 0, 40)
		Header.BackgroundTransparency = BG_TRANSPARENCY
		Header.BackgroundColor3 = Color3.new()
		Header.BorderSizePixel = 0
		Header.Active = true
		Header.ClipsDescendants = true
		Header.Parent = Container

		local HeaderName = Instance.new('TextLabel')
		HeaderName.Name = "HeaderName"
		HeaderName.Size = UDim2.new(1, 0, 0.5, 0)
		HeaderName.Position = UDim2.new(-0.02, 0, 0.245, 0)
		HeaderName.BackgroundTransparency = 1
		HeaderName.Font = Enum.Font.SourceSansBold
		HeaderName.FontSize = Enum.FontSize.Size18
		HeaderName.TextColor3 = TEXT_COLOR
		HeaderName.TextStrokeTransparency = TEXT_STROKE_TRANSPARENCY
		HeaderName.TextStrokeColor3 = TEXT_STROKE_COLOR
		HeaderName.TextXAlignment = Enum.TextXAlignment.Right
		HeaderName.Text = Player.Name
		HeaderName.Parent = Header

		local HeaderScore = Instance.new('TextLabel')
		HeaderScore.Name = "HeaderScore"
		HeaderScore.Size = UDim2.new(1, 0, 0.5, 0)
		HeaderScore.Position = UDim2.new(-0.02, 0, 0.495, 0)
		HeaderScore.BackgroundTransparency = 1
		HeaderScore.Font = Enum.Font.SourceSansBold
		HeaderScore.FontSize = Enum.FontSize.Size18
		HeaderScore.TextColor3 = TEXT_COLOR
		HeaderScore.TextStrokeTransparency = TEXT_STROKE_TRANSPARENCY
		HeaderScore.TextStrokeColor3 = TEXT_STROKE_COLOR
		HeaderScore.TextXAlignment = Enum.TextXAlignment.Right
		HeaderScore.Text = ""
		HeaderScore.Parent = Header

		-- Scrolling Frame
		local ScrollList = Instance.new('ScrollingFrame')
		ScrollList.Name = "ScrollList"
		ScrollList.Size = UDim2.new(1, -1, 0, 0)
		ScrollList.Position = UDim2.new(0, 0, 0.1, 1)
		ScrollList.BackgroundTransparency = 1
		ScrollList.BackgroundColor3 = Color3.new()
		ScrollList.BorderSizePixel = 0
		ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)	-- NOTE: Look into if x needs to be set to anything
		ScrollList.ScrollBarThickness = 6
		ScrollList.BottomImage = 'rbxasset://textures/ui/scroll-bottom.png'
		ScrollList.MidImage = 'rbxasset://textures/ui/scroll-middle.png'
		ScrollList.TopImage = 'rbxasset://textures/ui/scroll-top.png'
		ScrollList.Parent = Container

		-- Expand Frame
		local ExpandFrame = Instance.new('Frame')
		ExpandFrame.Name = "ExpandFrame"
		ExpandFrame.Size = UDim2.new(1, 0, 0, 22)
		ExpandFrame.Position = UDim2.new(0, 0, 0, 0)
		ExpandFrame.BackgroundTransparency = 1
		ExpandFrame.Active = true
		ExpandFrame.Parent = Container

		local ExpandImage = Instance.new('ImageLabel')
		ExpandImage.Name = "ExpandImage"
		ExpandImage.Size = UDim2.new(0, 27, 0, ExpandFrame.Size.Y.Offset/2)
		ExpandImage.Position = UDim2.new(0.5, -ExpandImage.Size.X.Offset/2, 0, 0)
		ExpandImage.BackgroundTransparency = 1
		ExpandImage.Image = EXPAND_ICON
		ExpandImage.Parent = ExpandFrame

		-- Friend/Report Popup
		local PopupFrame = nil
		local PopupClipFrame = Instance.new('Frame')
		PopupClipFrame.Name = "PopupClipFrame"
		PopupClipFrame.Size = UDim2.new(0, 150, 1, 0)
		PopupClipFrame.Position = UDim2.new(0, -151, 0, 2)
		PopupClipFrame.BackgroundTransparency = 1
		PopupClipFrame.ClipsDescendants = true
		PopupClipFrame.Parent = Container

		-- Report Abuse Gui
		local ReportAbuseShield = Instance.new('TextButton')
		ReportAbuseShield.Name = "ReportAbuseShield"
		ReportAbuseShield.Size = UDim2.new(1, 0, 1, 0)
		ReportAbuseShield.Position = UDim2.new(0, 0, 0, 0)
		ReportAbuseShield.BackgroundColor3 = Color3.new(51/255, 51/255, 51/255)
		ReportAbuseShield.BackgroundTransparency = 0.4
		ReportAbuseShield.ZIndex = 1
		ReportAbuseShield.Text = ""
		ReportAbuseShield.AutoButtonColor = false

		local ReportAbuseFrame = Instance.new('Frame')
		ReportAbuseFrame.Name = "ReportAbuseFrame"
		ReportAbuseFrame.Size = UDim2.new(0, 480, 0, 320)
		ReportAbuseFrame.Position = UDim2.new(0.5, -240, 0.5, -160)
		ReportAbuseFrame.BackgroundTransparency = 0.7
		ReportAbuseFrame.BackgroundColor3 = Color3.new(0, 0, 0)
		ReportAbuseFrame.Style = Enum.FrameStyle.DropShadow
		ReportAbuseFrame.Parent = ReportAbuseShield

		local ReportAbuseDescription = Instance.new('TextLabel')
		ReportAbuseDescription.Name = "ReportAbuseDescription"
		ReportAbuseDescription.Text = "Classic report form. To submit an actual report, use Roblox's built-in Report Abuse menu."
		ReportAbuseDescription.Size = UDim2.new(1, -20, 0, 40)
		ReportAbuseDescription.Position = UDim2.new(0, 10, 0, 10)
		ReportAbuseDescription.BackgroundTransparency = 1
		ReportAbuseDescription.Font = Enum.Font.SourceSans
		ReportAbuseDescription.FontSize = Enum.FontSize.Size18
		ReportAbuseDescription.TextColor3 = Color3.new(1, 1, 1)
		ReportAbuseDescription.TextWrap = true
		ReportAbuseDescription.TextXAlignment = Enum.TextXAlignment.Left
		ReportAbuseDescription.TextYAlignment = Enum.TextYAlignment.Top
		ReportAbuseDescription.Parent = ReportAbuseFrame

		local ReportPlayerLabel = Instance.new('TextLabel')
		ReportPlayerLabel.Name = "ReportPlayerLabel"
		ReportPlayerLabel.Text = "Player Reporting:"
		ReportPlayerLabel.Size = UDim2.new(0.4, 0, 0, 36)
		ReportPlayerLabel.Position = UDim2.new(0.025, 20, 0, 80)
		ReportPlayerLabel.BackgroundTransparency = 1
		ReportPlayerLabel.Font = Enum.Font.SourceSans
		ReportPlayerLabel.FontSize = Enum.FontSize.Size18
		ReportPlayerLabel.TextColor3 = Color3.new(1, 1, 1)
		ReportPlayerLabel.TextXAlignment = Enum.TextXAlignment.Left
		ReportPlayerLabel.Parent = ReportAbuseFrame

		local ReportPlayerName = Instance.new('TextLabel')
		ReportPlayerName.Name = "ReportPlayerName"
		ReportPlayerName.Text = "jmargh"
		ReportPlayerName.Size = UDim2.new(0.95, 0, 0, 36)
		ReportPlayerName.Position = UDim2.new(0.025, 0, 0, 80)
		ReportPlayerName.BackgroundTransparency = 1
		ReportPlayerName.Font = Enum.Font.SourceSans
		ReportPlayerName.FontSize = Enum.FontSize.Size18
		ReportPlayerName.TextColor3 = Color3.new(1, 1, 1)
		ReportPlayerName.TextXAlignment = Enum.TextXAlignment.Right
		ReportPlayerName.Parent = ReportAbuseFrame

		local ReportReasonLabel = Instance.new('TextLabel')
		ReportReasonLabel.Name = "ReportReasonLabel"
		ReportReasonLabel.Text = "Type of Abuse:"
		ReportReasonLabel.Size = UDim2.new(0.4, 0, 0, 36)
		ReportReasonLabel.Position = UDim2.new(0.025, 20, 0, 119)
		ReportReasonLabel.BackgroundTransparency = 1
		ReportReasonLabel.Font = Enum.Font.SourceSans
		ReportReasonLabel.FontSize = Enum.FontSize.Size18
		ReportReasonLabel.TextColor3 = Color3.new(1, 1, 1)
		ReportReasonLabel.TextXAlignment = Enum.TextXAlignment.Left
		ReportReasonLabel.Parent = ReportAbuseFrame

		local ReportDescriptionLabel = Instance.new('TextLabel')
		ReportDescriptionLabel.Name = "ReportDescriptionLabel"
		ReportDescriptionLabel.Text = "Short Description: (optional)"
		ReportDescriptionLabel.Size = UDim2.new(0.95, 0, 0, 36)
		ReportDescriptionLabel.Position = UDim2.new(0.025, 0, 0, 165)
		ReportDescriptionLabel.BackgroundTransparency = 1
		ReportDescriptionLabel.Font = Enum.Font.SourceSans
		ReportDescriptionLabel.FontSize = Enum.FontSize.Size18
		ReportDescriptionLabel.TextColor3 = Color3.new(1, 1, 1)
		ReportDescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
		ReportDescriptionLabel.Parent = ReportAbuseFrame

		local ReportSubmitButton = Instance.new('TextButton')
		ReportSubmitButton.Name = "ReportSubmitButton"
		ReportSubmitButton.Text = "Submit Report"
		ReportSubmitButton.Size = UDim2.new(0.35, 0, 0, 40)
		ReportSubmitButton.Position = UDim2.new(0.1, 0, 1, -50)
		ReportSubmitButton.Font = Enum.Font.SourceSans
		ReportSubmitButton.FontSize = Enum.FontSize.Size18
		ReportSubmitButton.TextColor3 = Color3.new(163/255, 162/255, 165/255)
		ReportSubmitButton.Active = false
		ReportSubmitButton.AutoButtonColor = true
		ReportSubmitButton.Modal = true
		ReportSubmitButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
		ReportSubmitButton.Parent = ReportAbuseFrame

		local ReportCanelButton = Instance.new('TextButton')
		ReportCanelButton.Name = "ReportCanelButton"
		ReportCanelButton.Text = "Cancel"
		ReportCanelButton.Size = UDim2.new(0.35, 0, 0, 40)
		ReportCanelButton.Position = UDim2.new(0.55, 0, 1, -50)
		ReportCanelButton.Font = Enum.Font.SourceSans
		ReportCanelButton.FontSize = Enum.FontSize.Size18
		ReportCanelButton.TextColor3 = Color3.new(1, 1, 1)
		ReportCanelButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
		ReportCanelButton.Parent = ReportAbuseFrame

		local AbuseDropDown, updateAbuseSelection = RbxGui.CreateDropDownMenu(ABUSES,
			function(abuseText)
				AbuseReason = abuseText
				if AbuseReason and AbusingPlayer then
					ReportSubmitButton.Active = true
					ReportSubmitButton.TextColor3 = Color3.new(1, 1, 1)
				end
			end, true, true, 1)
		AbuseDropDown.Name = "AbuseDropDown"
		AbuseDropDown.Size = UDim2.new(0.55, 0, 0, 32)
		AbuseDropDown.Position = UDim2.new(0.425, 0, 0, 121)
		AbuseDropDown.Parent = ReportAbuseFrame

		local ReportDescriptionTextFrame = Instance.new('Frame')
		ReportDescriptionTextFrame.Name = "ReportDescriptionTextFrame"
		ReportDescriptionTextFrame.Size = UDim2.new(0.95, 0, 1, -250)
		ReportDescriptionTextFrame.Position = UDim2.new(0.025, 0, 0, 195)
		ReportDescriptionTextFrame.BackgroundColor3 = Color3.new(206/255, 206/255, 206/255)
		ReportDescriptionTextFrame.BorderSizePixel = 0
		ReportDescriptionTextFrame.Parent = ReportAbuseFrame

		local ReportDescriptionBox = Instance.new('TextBox')
		ReportDescriptionBox.Name = "ReportDescriptionBox"
		ReportDescriptionBox.Text = ""
		ReportDescriptionBox.Size = UDim2.new(1, -6, 1, -6)
		ReportDescriptionBox.Position = UDim2.new(0, 3, 0, 3)
		ReportDescriptionBox.Font = Enum.Font.SourceSans
		ReportDescriptionBox.FontSize = Enum.FontSize.Size18
		ReportDescriptionBox.TextColor3 = Color3.new(0, 0, 0)
		ReportDescriptionBox.BackgroundColor3 = Color3.new(206/255, 206/255, 206/255)
		ReportDescriptionBox.BorderColor3 = Color3.new(206/255, 206/255, 206/255)
		ReportDescriptionBox.TextXAlignment = Enum.TextXAlignment.Left
		ReportDescriptionBox.TextYAlignment = Enum.TextYAlignment.Top
		ReportDescriptionBox.TextWrap = true
		ReportDescriptionBox.ClearTextOnFocus = false
		ReportDescriptionBox.Parent = ReportDescriptionTextFrame

		-- Report Confirm Gui
		local ReportConfirmFrame = Instance.new('Frame')
		ReportConfirmFrame.Name = "ReportConfirmFrame"
		ReportConfirmFrame.Size = UDim2.new(0, 400, 0, 160)
		ReportConfirmFrame.Position = UDim2.new(0.5, -200, 0.5, -80)
		ReportConfirmFrame.BackgroundTransparency = 0.7
		ReportConfirmFrame.BackgroundColor3 = Color3.new(0, 0, 0)
		ReportConfirmFrame.Style = Enum.FrameStyle.DropShadow

		local ReportConfirmHeader = Instance.new('TextLabel')
		ReportConfirmHeader.Name = "ReportConfirmHeader"
		ReportConfirmHeader.Size = UDim2.new(0, 0, 0, 0)
		ReportConfirmHeader.Position = UDim2.new(0.5, 0, 0, 14)
		ReportConfirmHeader.BackgroundTransparency = 1
		ReportConfirmHeader.Text = "Thank You For Your Report"
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
		ReportConfirmButton.Size = UDim2.new(0, 162, 0, 40)
		ReportConfirmButton.Position = UDim2.new(0.5, -81, 1, -50)
		ReportConfirmButton.Font = Enum.Font.SourceSans
		ReportConfirmButton.FontSize = Enum.FontSize.Size18
		ReportConfirmButton.TextColor3 = Color3.new(1, 1, 1)
		ReportConfirmButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
		ReportConfirmButton.Parent = ReportConfirmFrame

		local function onReportConfirmPressed()
			ReportConfirmFrame.Parent = nil
			ReportAbuseShield.Parent = nil
			ReportAbuseFrame.Parent = ReportAbuseShield
		end
		ReportConfirmButton.MouseButton1Click:connect(onReportConfirmPressed)
		ReportConfirmButton.TouchTap:connect(onReportConfirmPressed)

		--[[ Creation Helper Functions ]]--
		local function createEntryFrame(name, sizeYOffset)
			local containerFrame = Instance.new('Frame')
			containerFrame.Name = name
			containerFrame.Position = UDim2.new(0, 0, 0, 0)
			containerFrame.Size = UDim2.new(1, 0, 0, sizeYOffset)
			containerFrame.BackgroundTransparency = 1
			containerFrame.Parent = ScrollList

			local nameFrame = Instance.new('Frame')
			nameFrame.Name = "BGFrame"
			nameFrame.Position = UDim2.new(0, 0, 0, 0)
			nameFrame.Size = UDim2.new(0, NameEntrySizeX * ScaleX, 0, sizeYOffset)
			nameFrame.BackgroundTransparency = BG_TRANSPARENCY
			nameFrame.BackgroundColor3 = Color3.new(0, 0, 0)
			nameFrame.BorderSizePixel = 0
			nameFrame.ClipsDescendants = true
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
			statFrame.Size = UDim2.new(0, StatEntrySizeX * ScaleX, 1, 0)
			statFrame.Position = UDim2.new(0, offset + 1, 0, 0)
			statFrame.BackgroundTransparency = BG_TRANSPARENCY
			statFrame.BackgroundColor3 = Color3.new(0, 0, 0)
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

		local function formatStatString(text)
			local maxLength = MAX_STR_LEN * ScaleX
			if strWidth(text) <= maxLength then
				return text
			else
				return string.sub(text, 1, maxLength - 3).."..."
			end
		end

		--[[ Resize Functions ]]--
		local LastExpandPosition = ScrollList.Size.Y.Offset
		local function setExpandFramePosition()
			local canvasOffset = ScrollList.AbsolutePosition.y + ScrollList.CanvasSize.Y.Offset
			local scrollListOffset = ScrollList.AbsolutePosition.y + ScrollList.AbsoluteSize.y
			local newPosition = math.min(canvasOffset, scrollListOffset)
			ExpandFrame.Position = UDim2.new(0, 0, 0, newPosition - Container.AbsolutePosition.y + 2)
		end

		local LastMaxScrollSize = 0
		local function setScrollListSize()
			local teamSize = #TeamEntries * TeamEntrySizeY
			local playerSize = #PlayerEntries * PlayerEntrySizeY
			local spacing = #PlayerEntries * ENTRY_PAD + #TeamEntries * ENTRY_PAD
			local canvasSize = teamSize + playerSize + spacing + (#GameStats > 0 and PlayerEntrySizeY or 0)
			if #TeamEntries > 0 and NeutralTeam and IsShowingNeutralFrame then
				canvasSize = canvasSize + TeamEntrySizeY + ENTRY_PAD
			end
			ScrollList.CanvasSize = UDim2.new(0, 0, 0, canvasSize)
			local newScrollListSize = math.min(canvasSize, Container.AbsoluteSize.y - Header.AbsoluteSize.y)
			if ScrollList.Size.Y.Offset == LastMaxScrollSize and not IsExpanding then
				ScrollList.Size = UDim2.new(1, 0, 0, newScrollListSize)
			end
			LastMaxScrollSize = newScrollListSize
			setExpandFramePosition()
			LastExpandPosition = ScrollList.Size.Y.Offset
		end

		--[[ Re-position Functions ]]--
		local function setPlayerEntryPositions()
			local position = #GameStats > 0 and PlayerEntrySizeY + 1 or 0
			for i = 1, #PlayerEntries do
				PlayerEntries[i].Frame.Position = UDim2.new(0, 0, 0, position)
				position = position + PlayerEntrySizeY + 1
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
					teams.Neutral = teams.Neutral or {}
					teams.Neutral = teams.Neutral or {}; table.insert(teams.Neutral, playerEntry)
				elseif teams[tostring(player.TeamColor)] then
					table.insert(teams[tostring(player.TeamColor)], playerEntry)
				else
					teams.Neutral = teams.Neutral or {}; table.insert(teams.Neutral, playerEntry)
				end
			end

			local position = #GameStats > 0 and PlayerEntrySizeY + 1 or 0
			for _,teamEntry in ipairs(TeamEntries) do
				local team = teamEntry.Team
				teamEntry.Frame.Position = UDim2.new(0, 0, 0, position)
				position = position + TeamEntrySizeY + 1
				local players = teams[tostring(team.TeamColor)]
				for _,playerEntry in ipairs(players) do
					playerEntry.Frame.Position = UDim2.new(0, 0, 0, position)
					position = position + PlayerEntrySizeY + 1
				end
			end
			if NeutralTeam then
				NeutralTeam.Frame.Position = UDim2.new(0, 0, 0, position)
				position = position + TeamEntrySizeY + 1
				if #teams.Neutral > 0 then
					IsShowingNeutralFrame = true
					local players = teams.Neutral
					for _,playerEntry in ipairs(players) do
						playerEntry.Frame.Position = UDim2.new(0, 0, 0, position)
						position = position + PlayerEntrySizeY + 1
					end
				else
					IsShowingNeutralFrame = false
				end
			end
		end

		local function setEntryPositions()
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
			frame.Size = UDim2.new(1, 0, 0, (PlayerEntrySizeY * #buttons) + (#buttons - 1))
			frame.Position = UDim2.new(1, 1, 0, 0)
			frame.BackgroundTransparency = 1
			frame.Parent = PopupClipFrame

			for i,button in ipairs(buttons) do
				local btn = Instance.new('TextButton')
				btn.Name = button.Name
				btn.Size = UDim2.new(1, 0, 0, PlayerEntrySizeY)
				btn.Position = UDim2.new(0, 0, 0, PlayerEntrySizeY * (i - 1) + (i - 1))
				btn.BackgroundTransparency = BG_TRANSPARENCY
				btn.BackgroundColor3 = Color3.new(0, 0, 0)
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
				btn.TouchTap:connect(button.OnPress)
			end

			return frame
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
					if childFrame:IsA('Frame') then
						childFrame.BackgroundColor3 = Color3.new(0, 0, 0)
					end
				end
			end
			LastSelectedFrame = nil
			LastSelectedPlayer = nil
		end

		local function onFriendButtonPressed()
			if LastSelectedPlayer then
				local status = getFriendStatus(LastSelectedPlayer)
				if status == Enum.FriendStatus.Friend then
					pcall(function() game:GetService('StarterGui'):SetCore('PromptUnfriend', LastSelectedPlayer) end)
				elseif status == Enum.FriendStatus.Unknown or status == Enum.FriendStatus.NotFriend then
					pcall(function() game:GetService('StarterGui'):SetCore('PromptSendFriendRequest', LastSelectedPlayer) end)
				elseif status == Enum.FriendStatus.FriendRequestSent then
					pcall(function() game:GetService('StarterGui'):SetCore('PromptUnfriend', LastSelectedPlayer) end)
				elseif status == Enum.FriendStatus.FriendRequestReceived then
					pcall(function() game:GetService('StarterGui'):SetCore('PromptSendFriendRequest', LastSelectedPlayer) end)
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
			updateAbuseSelection(nil)
			ReportPlayerName.Text = ""
			ReportDescriptionBox.Text = ""
			ReportSubmitButton.Active = false
			ReportSubmitButton.TextColor3 = Color3.new(163/255, 162/255, 165/255)
		end

		local function onAbuseDialogCanceled()
			ReportAbuseShield.Parent = nil
			resetReportDialog()
		end
		ReportCanelButton.MouseButton1Click:connect(onAbuseDialogCanceled)
		ReportCanelButton.TouchTap:connect(onAbuseDialogCanceled)

		local function onAbuseDialogSubmit()
			if ReportSubmitButton.Active then
				if AbuseReason and AbusingPlayer then
					-- Ordinary client scripts cannot submit moderation reports directly.
					-- Preserve the form, but do not claim a report was submitted.
					ReportConfirmHeader.Text = 'Report Not Submitted'
					ReportConfirmText.Text = 'Please use the Roblox menu to report this player. This classic form cannot send reports.'
					resetReportDialog()
					ReportAbuseFrame.Parent = nil
					ReportConfirmFrame.Parent = ReportAbuseShield
				end
			end
		end
		ReportSubmitButton.MouseButton1Click:connect(onAbuseDialogSubmit)
		ReportSubmitButton.TouchTap:connect(onAbuseDialogSubmit)

		local function onDeclineFriendButonPressed()
			if LastSelectedPlayer then
				pcall(function() game:GetService('StarterGui'):SetCore('PromptUnfriend', LastSelectedPlayer) end)
				hideFriendReportPopup()
			end
		end

		-- Personal servers and their privilege ranks are no longer available.
		local function createPersonalServerDialog(buttons, selectedPlayer)
			-- Keep the classic player popup; retired rank actions are intentionally omitted.
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
			PopupFrame.Position = UDim2.new(1, 1, 0, selectedFrame.Position.Y.Offset - ScrollList.CanvasPosition.y + 39)
			PopupFrame:TweenPosition(UDim2.new(0, 0, 0, selectedFrame.Position.Y.Offset - ScrollList.CanvasPosition.y + 39), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, TWEEN_TIME, true)
			selectedEntryMovedCn = selectedFrame.Changed:connect(function(property)
				if property == "Position" then
					PopupFrame.Position = UDim2.new(0, 0, 0, selectedFrame.Position.Y.Offset - ScrollList.CanvasPosition.y + 39)
				end
			end)
		end

		local function onEntryFrameSelected(selectedFrame, selectedPlayer)
			if selectedPlayer ~= Player and selectedPlayer.UserId > 1 and Player.UserId > 1 then
				if LastSelectedFrame ~= selectedFrame then
					if LastSelectedFrame then
						for _,childFrame in pairs(LastSelectedFrame:GetChildren()) do
							if childFrame:IsA('Frame') then
								childFrame.BackgroundColor3 = Color3.new(0, 0, 0)
							end
						end
					end
					LastSelectedFrame = selectedFrame
					LastSelectedPlayer = selectedPlayer
					for _,childFrame in pairs(selectedFrame:GetChildren()) do
						if childFrame:IsA('Frame') then
							childFrame.BackgroundColor3 = Color3.new(0, 1, 1)
						end
					end
					-- NOTE: Core script only
					ScrollList.ScrollingEnabled = false
					showFriendReportPopup(selectedFrame, selectedPlayer)
				else
					hideFriendReportPopup()
					ScrollList.ScrollingEnabled = true
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
			local friendIcon = nil
			local nameFrame = nil
			if bgFrame then
				friendIcon = bgFrame:FindFirstChild('FriendshipIcon')
				nameFrame = bgFrame:FindFirstChild('PlayerName')
			end
			local offset = 19
			if friendIcon then
				if newIcon then
					friendIcon.Image = newIcon
				else
					if nameFrame then
						newSize = nameFrame.Size.X.Offset + friendIcon.Size.X.Offset + 2
						nameFrame.Size = UDim2.new(-0.01, newSize, 0.5, 0)
						nameFrame.Position = UDim2.new(0.01, offset, 0.245, 0)
					end
					friendIcon:Destroy()
				end
			elseif newIcon and bgFrame then
				friendIcon = createImageIcon(newIcon, "FriendshipIcon", offset, bgFrame)
				offset = offset + friendIcon.Size.X.Offset + 2
				if nameFrame then
					local newSize = bgFrame.Size.X.Offset - offset
					nameFrame.Size = UDim2.new(-0.01, newSize, 0.5, 0)
					nameFrame.Position = UDim2.new(0.01, offset, 0.245, 0)
				end
			end
		end

		-- NOTE: Core script only
		pcall(function() Player.FriendStatusChanged:Connect(onFriendshipChanged) end)

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

		local function updateHeaderScore(statObject)
			if #GameStats > 0 then
				if statObject.Name == GameStats[1].Name then
					if HeaderScore.Text == "" then
						HeaderName.Position = UDim2.new(-0.02, 0, 0.005, 0)
					end
					local score = getScoreValue(statObject)
					HeaderScore.Text = tostring(score)
				end
			end
		end

		local function updateTeamEntry(entry)
			local frame = entry.Frame
			local team = entry.Team
			local color = team.TeamColor.Color
			local offset = NameEntrySizeX * ScaleX
			for _,stat in ipairs(GameStats) do
				local statFrame = frame:FindFirstChild(stat.Name)
				if not statFrame then
					statFrame = createStatFrame(offset, frame, stat.Name)
					statFrame.BackgroundColor3 = color
					createStatText(statFrame, "")
				end
				statFrame.Position = UDim2.new(0, offset + 1, 0, 0)
				offset = offset + statFrame.Size.X.Offset + 1
			end
		end

		local function updateLeaderstatFrames()
			if StatNameFrame then
				local offset = NameEntrySizeX * ScaleX
				for _,stat in ipairs(GameStats) do
					local statFrame = StatNameFrame:FindFirstChild(stat.Name)
					if not statFrame then
						statFrame = createStatFrame(offset, StatNameFrame, stat.Name)
						createStatText(statFrame, formatStatString(stat.Name))
					end
					statFrame.Position = UDim2.new(0, offset + 1, 0, 0)
					offset = offset + statFrame.Size.X.Offset + 1
				end
			end
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
				local offset = NameEntrySizeX * ScaleX
				local leaderstats = player:FindFirstChild('leaderstats')

				if leaderstats then
					for _,stat in ipairs(GameStats) do
						local statObject = leaderstats:FindFirstChild(stat.Name)
						local statFrame = mainFrame:FindFirstChild(stat.Name)

						if not statFrame then
							statFrame = createStatFrame(offset, mainFrame, stat.Name)
							if statObject then
								local statValue = getScoreValue(statObject)
								local statText = createStatText(statFrame, formatStatString(tostring(statValue)))
								statObject.Changed:connect(function(newValue)
									statText.Text = formatStatString(tostring(getScoreValue(statObject)))
									updateAllTeamScores()
								end)
								if player == Player then
									updateHeaderScore(statObject)
									statObject.Changed:connect(function(newValue)
										updateHeaderScore(statObject)
									end)
								end
							end
						elseif statObject then
							local statText = statFrame:FindFirstChild('StatText')
							if not statText then
								local statValue = getScoreValue(statObject)
								statText = createStatText(statFrame, formatStatString(tostring(statValue)))
								statObject.Changed:connect(function(newValue)
									statText.Text = formatStatString(tostring(getScoreValue(statObject)))
									updateAllTeamScores()
								end)
								if player == Player then
									updateHeaderScore(statObject)
									statObject.Changed:connect(function(newValue)
										updateHeaderScore(statObject)
									end)
								end
							end
						end
						statFrame.Position = UDim2.new(0, offset + 1, 0, 0)
						offset = offset + statFrame.Size.X.Offset + 1
					end
				else
					for _,stat in ipairs(GameStats) do
						local statFrame = mainFrame:FindFirstChild(stat.Name)
						if not statFrame then
							statFrame = createStatFrame(offset, mainFrame, stat.Name)
						end
						offset = offset + statFrame.Size.X.Offset + 1
					end
				end

				Container.Position = IsPlayerListExpanded and UDim2.new(0.5, -offset/2, 0.15, 0) or
					UDim2.new(1, -offset - 2, 0, 2)
				Container.Size = UDim2.new(0, offset, 0.5, 0)
				local newMinContainerOffset = IsPlayerListExpanded and offset/2 or offset
				MinContainerSize = UDim2.new(0, newMinContainerOffset, 0.5, 0)
			end
			updateAllTeamScores()
		end

		local function createStatNameFrame()
			StatNameFrame = Instance.new('Frame')
			StatNameFrame.Name = "StatNameFrame"
			StatNameFrame.Position = UDim2.new(0, 0, 0, 0)
			StatNameFrame.Size = UDim2.new(1, 0, 0, PlayerEntrySizeY)
			StatNameFrame.BackgroundTransparency = 1
			StatNameFrame.Parent = ScrollList

			local blankFrame = Instance.new('Frame')
			blankFrame.Name = "Players"
			blankFrame.Position = UDim2.new(0, 0, 0, 0)
			blankFrame.Size = UDim2.new(0, NameEntrySizeX * ScaleX, 0, PlayerEntrySizeY)
			blankFrame.BackgroundTransparency = BG_TRANSPARENCY
			blankFrame.BackgroundColor3 = Color3.new(0, 0, 0, 0)
			blankFrame.BorderSizePixel = 0
			blankFrame.Parent = StatNameFrame

			local nameText = createEntryNameText("PlayerNames", "Players", blankFrame.Size.X.Offset - 2, 2)
			nameText.Parent = blankFrame
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
						newStat.Priority = 0
						newStat.MaxLength = 0
						local priority = stat:FindFirstChild('Priority')
						if priority and priority:IsA('ValueBase') then newStat.Priority = priority.Value end
						newStat.IsPrimary = false
						local isPrimary = stat:FindFirstChild('IsPrimary')
						if isPrimary then
							newStat.IsPrimary = true
						else
							stat.ChildAdded:connect(function(child)
								if child.Name == "IsPrimary" then
									newStat.IsPrimary = true
									table.sort(GameStats, sortLeaderStats)
									updateHeaderScore(stat)
									updateLeaderstatFrames()
								end
							end)
						end
						newStat.AddId = StatAddId
						StatAddId = StatAddId + 1
						table.insert(GameStats, newStat)
						table.sort(GameStats, sortLeaderStats)
						if #GameStats == 1 then
							createStatNameFrame()
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

		local function onStatAdded(newStat)
			if isValidStat(newStat) then
				addNewStats(newStat.Parent)
				updateLeaderstatFrames()
			end
		end

		local function onStatRemoved(oldStat, entry)
			if isValidStat(oldStat) then
				removeStatFrameFromEntry(oldStat, entry.Frame)
				local statExists = doesStatExists(oldStat)
				if not statExists then
					-- remove from player entries
					for _,playerEntry in ipairs(PlayerEntries) do
						removeStatFrameFromEntry(oldStat, playerEntry.Frame)
					end
					-- remove from teams
					for _,teamEntry in ipairs(TeamEntries) do
						removeStatFrameFromEntry(oldStat, teamEntry.Frame)
					end
					-- remove from statName frame
					if StatNameFrame then removeStatFrameFromEntry(oldStat, StatNameFrame) end
					local toRemove = nil
					for i,stat in ipairs(GameStats) do
						if stat.Name == oldStat.Name then
							toRemove = i
							break
						end
					end
					if toRemove then
						table.remove(GameStats, toRemove)
						table.sort(GameStats, sortLeaderStats)
					end
				end
				if #GameStats == 0 then
					if StatNameFrame then StatNameFrame:Destroy(); StatNameFrame = nil end
					setEntryPositions()
					setScrollListSize()
				else
					local leaderstats = Player:FindFirstChild('leaderstats')
					if leaderstats then
						local newPrimaryStat = leaderstats:FindFirstChild(GameStats[1].Name)
						if newPrimaryStat then
							updateHeaderScore(newPrimaryStat)
						else
							HeaderScore.Text = ""
							HeaderName.Position = UDim2.new(-0.02, 0, 0.245, 0)
						end
					end
				end
				updateLeaderstatFrames()
			end
		end

		local function setLeaderStats(entry)
			local player = entry.Player
			local leaderstats = player:FindFirstChild('leaderstats')

			if leaderstats then
				addNewStats(leaderstats)
				leaderstats.ChildAdded:connect(onStatAdded)
				leaderstats.ChildRemoved:connect(function(child)
					onStatRemoved(child, entry)
				end)
			end
			updateLeaderstatFrames()

			player.ChildAdded:connect(function(child)
				if child.Name == 'leaderstats' then
					addNewStats(child)
					updateLeaderstatFrames()
				end

				child.ChildAdded:connect(onStatAdded)
				child.ChildRemoved:connect(function(removedStat)
					onStatRemoved(removedStat, entry)
				end)
			end)

			player.ChildRemoved:connect(function(child)
				if child.Name == 'leaderstats' then
					for i,stat in ipairs(child:GetChildren()) do
						onStatRemoved(stat, entry)
					end
					updateLeaderstatFrames()
					if player == Player then
						HeaderScore.Text = ""
						HeaderName.Position = UDim2.new(-0.02, 0, 0.245, 0)
					end
				end
			end)
		end

		local function createPlayerEntry(player)
			local playerEntry = {}
			local name = player.Name

			local containerFrame, entryFrame = createEntryFrame(name, PlayerEntrySizeY)
			entryFrame.Active = true
			entryFrame.InputBegan:connect(function(inputObject)
				local inputType = inputObject.UserInputType
				if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
					onEntryFrameSelected(containerFrame, player)
				end
			end)

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

			-- check friendship
			local friendStatus = getFriendStatus(player)
			local friendshipIconImage = getFriendStatusIcon(friendStatus)
			local friendshipIcon = nil
			if friendshipIconImage then
				friendshipIcon = createImageIcon(friendshipIconImage, "FriendshipIcon", currentXOffset, entryFrame)
				currentXOffset = currentXOffset + friendshipIcon.Size.X.Offset + 2
			end

			local playerNameXSize = math.max(20, NameEntrySizeX * ScaleX - currentXOffset)
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
			end
		end

		--[[ Insert/Remove Player Functions ]]--
		local function insertPlayerEntry(player)
			local entry = createPlayerEntry(player)
			if player == Player then
				MyPlayerEntry = entry.Frame
			end
			table.insert(PlayerEntries, entry)
			table.sort(PlayerEntries, sortPlayerEntries)
			setEntryPositions()
			setLeaderStats(entry)
			setScrollListSize()

			player.Changed:connect(function(property)
				if #TeamEntries > 0 and (property == 'Neutral' or property == 'TeamColor') then
					setTeamEntryPositions()
					updateAllTeamScores()
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
		end

		local function onTeamRemoved(removedTeam)
			for i = 1, #TeamEntries do
				local team = TeamEntries[i].Team
				if team.Name == removedTeam.Name then
					TeamEntries[i].Frame:Destroy()
					table.remove(TeamEntries, i)
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

		local function resizeScrollList()
			local desiredSize = Container.AbsoluteSize.y - Header.AbsoluteSize.y
			if ScrollList.Size.Y.Offset > desiredSize then
				ScrollList.Size = UDim2.new(1, 0, 0, desiredSize)
			else
				local newSize = math.min(desiredSize, LastExpandPosition)
				ScrollList.Size = UDim2.new(1, 0, 0, newSize)
			end
			ScrollList.Position = UDim2.new(0, 0, 0, Header.AbsoluteSize.y + 1)
			clampCanvasPosition()
			setExpandFramePosition()
		end

		local function resizeExpandedFrame(containerFrame, scale, name, func)
			local offset = 0
			local nameFrame = containerFrame:FindFirstChild(name)
			if nameFrame then
				nameFrame.Size = UDim2.new(0, nameFrame.Size.X.Offset * scale, 1, 0)
				nameFrame.Position = UDim2.new(0, offset, 0, 0)
				offset = offset + nameFrame.Size.X.Offset + 1
			end
			for _,stat in ipairs(GameStats) do
				local subFrame = containerFrame:FindFirstChild(stat.Name)
				if subFrame then
					subFrame.Size = UDim2.new(0, subFrame.Size.X.Offset * scale, 1, 0)
					subFrame.Position = UDim2.new(0, offset, 0, 0)
					offset = offset + subFrame.Size.X.Offset + 1
					if func then
						func(subFrame, stat.Name)
					end
				end
			end
		end

		local function expandPlayerList(endPosition, subFrameScale)
			local containerOffset = 5 * (ScaleX - 1)
			Container:TweenSizeAndPosition(
				UDim2.new(0, MinContainerSize.X.Offset * ScaleX - containerOffset, 0.5, 0),
				endPosition, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, TWEEN_TIME, true)

			if StatNameFrame then
				resizeExpandedFrame(StatNameFrame, subFrameScale, 'Players')
				for _,stat in pairs(GameStats) do
					local subFrame = StatNameFrame:FindFirstChild(stat.Name)
					if subFrame then
						local statText = subFrame:FindFirstChild('StatText')
						if statText then
							statText.Text = formatStatString(stat.Name)
						end
					end
				end
			end
			for _,entry in ipairs(PlayerEntries) do
				local player = entry.Player
				local leaderstats = player:FindFirstChild('leaderstats')
				local function setScore(subFrame, statName)
					if leaderstats then
						local statObject = leaderstats:FindFirstChild(statName)
						local statText = subFrame:FindFirstChild('StatText')
						if statObject and statText then
							local score = getScoreValue(statObject)
							statText.Text = formatStatString(tostring(score))
						end
					end
				end
				resizeExpandedFrame(entry.Frame, subFrameScale, 'BGFrame', setScore)
			end
			for _,entry in ipairs(TeamEntries) do
				resizeExpandedFrame(entry.Frame, subFrameScale, 'BGFrame')
			end
			if NeutralTeam then
				resizeExpandedFrame(NeutralTeam.Frame, subFrameScale, 'BGFrame')
			end
			updateAllTeamScores()
		end

		local function resizePlayerList()
			resizeScrollList()
		end

		RobloxGui.Changed:connect(function(property)
			if property == 'AbsoluteSize' then
				spawn(function()	-- must spawn because F11 delays when abs size is set
					resizePlayerList()
				end)
			end
		end)

		--[[ Input Connections ]]--
		local ExpandInputObject = nil
		local LastExpandInputPosition = nil
		local ExpandOffset = nil
		ExpandFrame.InputBegan:connect(function(inputObject)
			if LastSelectedFrame then return end
			local inputType = inputObject.UserInputType
			local inputState = inputObject.UserInputState
			if (inputType == Enum.UserInputType.Touch and inputState == Enum.UserInputState.Begin) or inputType == Enum.UserInputType.MouseButton1 then
				IsExpanding = true
				ExpandInputObject = inputObject
				LastExpandInputPosition = inputObject.Position.y
				ExpandOffset = inputObject.Position.y - (ScrollList.AbsolutePosition.y + ScrollList.AbsoluteSize.y)
			end
		end)

		UserInputService.InputChanged:connect(function(inputObject)
			if inputObject == ExpandInputObject or (ExpandInputObject and inputObject.UserInputType == Enum.UserInputType.MouseMovement) then
				local minExpand = ScrollList.AbsolutePosition.y + ExpandOffset
				local maxExpand = minExpand + LastMaxScrollSize
				local currentPosition = clamp(inputObject.Position.y, minExpand, maxExpand)
				local delta = LastExpandInputPosition - currentPosition
				local newPosition = clamp(ScrollList.Size.Y.Offset - delta, 0, Container.AbsoluteSize.y - Header.AbsoluteSize.y)
				ScrollList.Size = UDim2.new(1, 0, 0, newPosition)

				clampCanvasPosition()
				setExpandFramePosition()
				LastExpandInputPosition = currentPosition
			end
		end)

		UserInputService.InputEnded:connect(function(inputObject)
			if inputObject == ExpandInputObject then
				ExpandInputObject = nil
				LastExpandInputPosition = nil
				LastExpandPosition = ScrollList.Size.Y.Offset
				IsExpanding = false
			elseif ReportAbuseShield.Parent == RobloxGui then
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

		local function doListExpand()
			if not IsPlayerListExpanded then
				ScaleX = 2
				expandPlayerList(UDim2.new(0.5, -MinContainerSize.X.Offset, 0.15, 0), 2)
			else
				ScaleX = 1
				expandPlayerList(UDim2.new(1, -MinContainerSize.X.Offset - 2, 0, 2), 0.5)
			end
			IsPlayerListExpanded = not IsPlayerListExpanded
		end

		Header.InputBegan:connect(function(inputObject)
			if LastSelectedFrame then return end
			local inputType = inputObject.UserInputType
			local inputState = inputObject.UserInputState
			if inputObject == ExpandInputObject then return end
			if (inputType == Enum.UserInputType.Touch and inputState == Enum.UserInputState.Begin) or inputType == Enum.UserInputType.MouseButton1 then
				doListExpand()
			end
		end)

		-- NOTE: Core script only
		UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.Tab then
				doListExpand()
			end
		end)

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

		TeamsService = game:FindFirstChildOfClass('Teams')
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
		local function onCoreGuiChanged(coreGuiType, enabled)
			if coreGuiType == Enum.CoreGuiType.All or coreGuiType == Enum.CoreGuiType.PlayerList then
				Container.Visible = enabled
				-- The Tab key is handled by UserInputService, not CoreScript-only GuiService.
			end
		end
		pcall(function()
			onCoreGuiChanged(Enum.CoreGuiType.PlayerList, true)
			game:GetService("StarterGui").CoreGuiChangedSignal:connect(onCoreGuiChanged)
		end)

		resizePlayerList()
		Container.Visible = true

	end, debug.traceback)
	if not ok then
		running = false
		error(err, 0)
	end
end
return Module

end;
};
G2L_MODULES[G2L["8"]] = {
Closure = function()
    local script = G2L["8"];local t = {}

local function ScopedConnect(parentInstance, instance, event, signalFunc, syncFunc, removeFunc)
	local eventConnection = nil

	--Connection on parentInstance is scoped by parentInstance (when destroyed, it goes away)
	local tryConnect = function()
		if parentInstance:IsDescendantOf(game) then
			--Entering the world, make sure we are connected/synced
			if not eventConnection then
				eventConnection = instance[event]:Connect(signalFunc)
				if syncFunc then syncFunc() end
			end
		else
			--Probably leaving the world, so disconnect for now
			if eventConnection then
				eventConnection:Disconnect()
				if removeFunc then removeFunc() end
			end
		end
	end

	--Hook it up to ancestryChanged signal
	local connection = parentInstance.AncestryChanged:Connect(tryConnect)

	--Now connect us if we're already in the world
	tryConnect()

	return connection
end

local function getScreenGuiAncestor(instance)
	local localInstance = instance
	while localInstance and not localInstance:IsA("ScreenGui") do
		localInstance = localInstance.Parent
	end
	return localInstance
end

local function CreateButtons(frame, buttons, yPos, ySize)
	local buttonNum = 1
	local buttonObjs = {}
	for i, obj in ipairs(buttons) do 
		local button = Instance.new("TextButton")
		button.Name = "Button" .. buttonNum
		button.Font = Enum.Font.Arial
		button.FontSize = Enum.FontSize.Size18
		button.AutoButtonColor = true
		button.Modal = true
		if obj["Style"] then
			button.Style = obj.Style
		else
			button.Style = Enum.ButtonStyle.RobloxButton
		end
		if obj["ZIndex"] then
			button.ZIndex = obj.ZIndex
		end
		button.Text = obj.Text
		button.TextColor3 = Color3.new(1,1,1)
		button.MouseButton1Click:connect(obj.Function)
		button.Parent = frame
		buttonObjs[buttonNum] = button

		buttonNum = buttonNum + 1
	end
	local numButtons = buttonNum-1

	if numButtons == 1 then
		frame.Button1.Position = UDim2.new(0.35, 0, yPos.Scale, yPos.Offset)
		frame.Button1.Size = UDim2.new(.4,0,ySize.Scale, ySize.Offset)
	elseif numButtons == 2 then
		frame.Button1.Position = UDim2.new(0.1, 0, yPos.Scale, yPos.Offset)
		frame.Button1.Size = UDim2.new(.8/3,0, ySize.Scale, ySize.Offset)

		frame.Button2.Position = UDim2.new(0.55, 0, yPos.Scale, yPos.Offset)
		frame.Button2.Size = UDim2.new(.35,0, ySize.Scale, ySize.Offset)
	elseif numButtons >= 3 then
		local spacing = .1 / numButtons
		local buttonSize = .9 / numButtons

		buttonNum = 1
		while buttonNum <= numButtons do
			buttonObjs[buttonNum].Position = UDim2.new(spacing*buttonNum + (buttonNum-1) * buttonSize, 0, yPos.Scale, yPos.Offset)
			buttonObjs[buttonNum].Size = UDim2.new(buttonSize, 0, ySize.Scale, ySize.Offset)
			buttonNum = buttonNum + 1
		end
	end
end

local function setSliderPos(newAbsPosX,slider,sliderPosition,bar,steps)

	local newStep = math.max(1, steps - 1) -- avoid dividing by zero
	local relativePosX = math.min(1, math.max(0, (newAbsPosX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X ))
	local wholeNum, remainder = math.modf(relativePosX * newStep)
	if remainder > 0.5 then
		wholeNum = wholeNum + 1
	end
	relativePosX = wholeNum/newStep

	local result = math.ceil(relativePosX * newStep)
	if sliderPosition.Value ~= (result + 1) then --only update if we moved a step
		sliderPosition.Value = result + 1
		slider.Position = UDim2.new(relativePosX,-slider.AbsoluteSize.X/2,slider.Position.Y.Scale,slider.Position.Y.Offset)
	end

end

local areaSoakMouseMoveCon = nil
local function cancelSlide(areaSoak)
	areaSoak.Visible = false
	if areaSoakMouseMoveCon then areaSoakMouseMoveCon:Disconnect(); areaSoakMouseMoveCon = nil end
end

t.CreateStyledMessageDialog = function(title, message, style, buttons)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.5, 0, 0, 165)
	frame.Position = UDim2.new(0.25, 0, 0.5, -72.5)
	frame.Name = "MessageDialog"
	frame.Active = true
	frame.Style = Enum.FrameStyle.RobloxRound	

	local styleImage = Instance.new("ImageLabel")
	styleImage.Name = "StyleImage"
	styleImage.BackgroundTransparency = 1
	styleImage.Position = UDim2.new(0,5,0,15)
	if style == "error" or style == "Error" then
		styleImage.Size = UDim2.new(0, 71, 0, 71)
		styleImage.Image = "http://www.roblox.com/asset/?id=42565285"
	elseif style == "notify" or style == "Notify" then
		styleImage.Size = UDim2.new(0, 71, 0, 71)
		styleImage.Image = "http://www.roblox.com/asset/?id=42604978"
	elseif style == "confirm" or style == "Confirm" then
		styleImage.Size = UDim2.new(0, 74, 0, 76)
		styleImage.Image = "http://www.roblox.com/asset/?id=42557901"
	else
		return t.CreateMessageDialog(title,message,buttons)
	end
	styleImage.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Text = title
	titleLabel.TextStrokeTransparency = 0
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.new(221/255,221/255,221/255)
	titleLabel.Position = UDim2.new(0, 80, 0, 0)
	titleLabel.Size = UDim2.new(1, -80, 0, 40)
	titleLabel.Font = Enum.Font.ArialBold
	titleLabel.FontSize = Enum.FontSize.Size36
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.Parent = frame

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Text = message
	messageLabel.TextStrokeTransparency = 0
	messageLabel.TextColor3 = Color3.new(221/255,221/255,221/255)
	messageLabel.Position = UDim2.new(0.025, 80, 0, 45)
	messageLabel.Size = UDim2.new(0.95, -80, 0, 55)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = Enum.Font.Arial
	messageLabel.FontSize = Enum.FontSize.Size18
	messageLabel.TextWrap = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.Parent = frame

	CreateButtons(frame, buttons, UDim.new(0, 105), UDim.new(0, 40) )

	return frame
end

t.CreateMessageDialog = function(title, message, buttons)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.5, 0, 0.5, 0)
	frame.Position = UDim2.new(0.25, 0, 0.25, 0)
	frame.Name = "MessageDialog"
	frame.Active = true
	frame.Style = Enum.FrameStyle.RobloxRound

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Text = title
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.new(221/255,221/255,221/255)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
	titleLabel.Font = Enum.Font.ArialBold
	titleLabel.FontSize = Enum.FontSize.Size36
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.Parent = frame

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.new(221/255,221/255,221/255)
	messageLabel.Position = UDim2.new(0.025, 0, 0.175, 0)
	messageLabel.Size = UDim2.new(0.95, 0, .55, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = Enum.Font.Arial
	messageLabel.FontSize = Enum.FontSize.Size18
	messageLabel.TextWrap = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.Parent = frame

	CreateButtons(frame, buttons, UDim.new(0.8,0), UDim.new(0.15, 0))

	return frame
end

t.CreateDropDownMenu = function(items, onSelect, forRoblox, whiteSkin, baseZ)
	local baseZIndex = 0
	if type(baseZ) == "number" then
		baseZIndex = baseZ
	end
	local width = UDim.new(0, 100)
	local height = UDim.new(0, 32)

	local xPos = 0.055
	local frame = Instance.new("Frame")
	local textColor = Color3.new(1,1,1)
	if (whiteSkin) then
		textColor = Color3.new(0.5, 0.5, 0.5)
	end
	frame.Name = "DropDownMenu"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(width, height)

	local dropDownMenu = Instance.new("TextButton")
	dropDownMenu.Name = "DropDownMenuButton"
	dropDownMenu.TextWrap = true
	dropDownMenu.TextColor3 = textColor
	dropDownMenu.Text = "Choose One"
	dropDownMenu.Font = Enum.Font.ArialBold
	dropDownMenu.FontSize = Enum.FontSize.Size18
	dropDownMenu.TextXAlignment = Enum.TextXAlignment.Left
	dropDownMenu.TextYAlignment = Enum.TextYAlignment.Center
	dropDownMenu.BackgroundTransparency = 1
	dropDownMenu.AutoButtonColor = true
	if (whiteSkin) then
		pcall(function() dropDownMenu.Style = Enum.ButtonStyle.RobloxRoundDropdownButton end)
	else
		dropDownMenu.Style = Enum.ButtonStyle.RobloxButton
	end
	dropDownMenu.Size = UDim2.new(1,0,1,0)
	dropDownMenu.Parent = frame
	dropDownMenu.ZIndex = 2 + baseZIndex

	local dropDownIcon = Instance.new("ImageLabel")
	dropDownIcon.Name = "Icon"
	dropDownIcon.Active = false
	if (whiteSkin) then
		dropDownIcon.Image = "rbxasset://textures/ui/dropdown_arrow.png"
		dropDownIcon.Size = UDim2.new(0,16,0,12)
		dropDownIcon.Position = UDim2.new(1,-17,0.5, -6)
	else
		dropDownIcon.Image = "http://www.roblox.com/asset/?id=45732894"
		dropDownIcon.Size = UDim2.new(0,11,0,6)
		dropDownIcon.Position = UDim2.new(1,-11,0.5, -2)
	end
	dropDownIcon.BackgroundTransparency = 1
	dropDownIcon.Parent = dropDownMenu
	dropDownIcon.ZIndex = 2 + baseZIndex

	local itemCount = #items
	local dropDownItemCount = #items
	local useScrollButtons = false
	if dropDownItemCount > 6 then
		useScrollButtons = true
		dropDownItemCount = 6
	end

	local droppedDownMenu = Instance.new("TextButton")
	droppedDownMenu.Name = "List"
	droppedDownMenu.Text = ""
	droppedDownMenu.BackgroundTransparency = 1
	--droppedDownMenu.AutoButtonColor = true
	if (whiteSkin) then
		pcall(function() droppedDownMenu.Style = Enum.ButtonStyle.RobloxRoundDropdownButton end)
	else
		droppedDownMenu.Style = Enum.ButtonStyle.RobloxButton
	end
	droppedDownMenu.Visible = false
	droppedDownMenu.Active = true	--Blocks clicks
	droppedDownMenu.Position = UDim2.new(0,0,0,0)
	droppedDownMenu.Size = UDim2.new(1,0, (1 + dropDownItemCount)*.8, 0)
	droppedDownMenu.Parent = frame
	droppedDownMenu.ZIndex = 2 + baseZIndex

	local choiceButton = Instance.new("TextButton")
	choiceButton.Name = "ChoiceButton"
	choiceButton.BackgroundTransparency = 1
	choiceButton.BorderSizePixel = 0
	choiceButton.Text = "ReplaceMe"
	choiceButton.TextColor3 = textColor
	choiceButton.TextXAlignment = Enum.TextXAlignment.Left
	choiceButton.TextYAlignment = Enum.TextYAlignment.Center
	choiceButton.BackgroundColor3 = Color3.new(1, 1, 1)
	choiceButton.Font = Enum.Font.Arial
	choiceButton.FontSize = Enum.FontSize.Size18
	if useScrollButtons then
		choiceButton.Size = UDim2.new(1,-13, .8/((dropDownItemCount + 1)*.8),0) 
	else
		choiceButton.Size = UDim2.new(1, 0, .8/((dropDownItemCount + 1)*.8),0) 
	end
	choiceButton.TextWrap = true
	choiceButton.ZIndex = 2 + baseZIndex

	local areaSoak = Instance.new("TextButton")
	areaSoak.Name = "AreaSoak"
	areaSoak.Text = ""
	areaSoak.BackgroundTransparency = 1
	areaSoak.Active = true
	areaSoak.Size = UDim2.new(1,0,1,0)
	areaSoak.Visible = false
	areaSoak.ZIndex = 3 + baseZIndex

	local dropDownSelected = false

	local scrollUpButton 
	local scrollDownButton
	local scrollMouseCount = 0

	local setZIndex = function(baseZIndex)
		droppedDownMenu.ZIndex = baseZIndex +1
		if scrollUpButton then
			scrollUpButton.ZIndex = baseZIndex + 3
		end
		if scrollDownButton then
			scrollDownButton.ZIndex = baseZIndex + 3
		end

		local children = droppedDownMenu:GetChildren()
		if children then
			for i, child in ipairs(children) do
				if child.Name == "ChoiceButton" then
					child.ZIndex = baseZIndex + 2
				elseif child.Name == "ClickCaptureButton" then
					child.ZIndex = baseZIndex
				end
			end
		end
	end

	local scrollBarPosition = 1
	local updateScroll = function()
		if scrollUpButton then
			scrollUpButton.Active = scrollBarPosition > 1 
		end
		if scrollDownButton then
			scrollDownButton.Active = scrollBarPosition + dropDownItemCount <= itemCount 
		end

		local children = droppedDownMenu:GetChildren()
		if not children then return end

		local childNum = 1			
		for i, obj in ipairs(children) do
			if obj.Name == "ChoiceButton" then
				if childNum < scrollBarPosition or childNum >= scrollBarPosition + dropDownItemCount then
					obj.Visible = false
				else
					obj.Position = UDim2.new(0,0,((childNum-scrollBarPosition+1)*.8)/((dropDownItemCount+1)*.8),0)
					obj.Visible = true
				end
				obj.TextColor3 = textColor
				obj.BackgroundTransparency = 1

				childNum = childNum + 1
			end
		end
	end
	local toggleVisibility = function()
		dropDownSelected = not dropDownSelected

		areaSoak.Visible = not areaSoak.Visible
		dropDownMenu.Visible = not dropDownSelected
		droppedDownMenu.Visible = dropDownSelected
		if dropDownSelected then
			setZIndex(4 + baseZIndex)
		else
			setZIndex(2 + baseZIndex)
		end
		if useScrollButtons then
			updateScroll()
		end
	end
	droppedDownMenu.MouseButton1Click:connect(toggleVisibility)

	local updateSelection = function(text)
		local foundItem = false
		local children = droppedDownMenu:GetChildren()
		local childNum = 1
		if children then
			for i, obj in ipairs(children) do
				if obj.Name == "ChoiceButton" then
					if obj.Text == text then
						obj.Font = Enum.Font.ArialBold
						foundItem = true			
						scrollBarPosition = childNum						
						if (whiteSkin) then
							obj.TextColor3 = Color3.new(90/255,142/255,233/255)
						end
					else
						obj.Font = Enum.Font.Arial
						if (whiteSkin) then
							obj.TextColor3 = textColor
						end
					end
					childNum = childNum + 1
				end
			end
		end
		if not text then
			dropDownMenu.Text = "Choose One"
			scrollBarPosition = 1
		else
			if not foundItem then
				error("Invalid Selection Update -- " .. text)
			end

			if scrollBarPosition + dropDownItemCount > itemCount + 1 then
				scrollBarPosition = itemCount - dropDownItemCount + 1
			end

			dropDownMenu.Text = text
		end
	end

	local function scrollDown()
		if scrollBarPosition + dropDownItemCount <= itemCount then
			scrollBarPosition = scrollBarPosition + 1
			updateScroll()
			return true
		end
		return false
	end
	local function scrollUp()
		if scrollBarPosition > 1 then
			scrollBarPosition = scrollBarPosition - 1
			updateScroll()
			return true
		end
		return false
	end

	if useScrollButtons then
		--Make some scroll buttons
		scrollUpButton = Instance.new("ImageButton")
		scrollUpButton.Name = "ScrollUpButton"
		scrollUpButton.BackgroundTransparency = 1
		scrollUpButton.Image = "rbxasset://textures/ui/scrollbuttonUp.png"
		scrollUpButton.Size = UDim2.new(0,17,0,17) 
		scrollUpButton.Position = UDim2.new(1,-11,(1*.8)/((dropDownItemCount+1)*.8),0)
		scrollUpButton.MouseButton1Click:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
			end)
		scrollUpButton.MouseLeave:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
			end)
		scrollUpButton.MouseButton1Down:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1

				scrollUp()
				local val = scrollMouseCount
				wait(0.5)
				while val == scrollMouseCount do
					if scrollUp() == false then
						break
					end
					wait(0.1)
				end				
			end)

		scrollUpButton.Parent = droppedDownMenu

		scrollDownButton = Instance.new("ImageButton")
		scrollDownButton.Name = "ScrollDownButton"
		scrollDownButton.BackgroundTransparency = 1
		scrollDownButton.Image = "rbxasset://textures/ui/scrollbuttonDown.png"
		scrollDownButton.Size = UDim2.new(0,17,0,17) 
		scrollDownButton.Position = UDim2.new(1,-11,1,-11)
		scrollDownButton.Parent = droppedDownMenu
		scrollDownButton.MouseButton1Click:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
			end)
		scrollDownButton.MouseLeave:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
			end)
		scrollDownButton.MouseButton1Down:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1

				scrollDown()
				local val = scrollMouseCount
				wait(0.5)
				while val == scrollMouseCount do
					if scrollDown() == false then
						break
					end
					wait(0.1)
				end				
			end)	

		local scrollbar = Instance.new("ImageLabel")
		scrollbar.Name = "ScrollBar"
		scrollbar.Image = "rbxasset://textures/ui/scrollbar.png"
		scrollbar.BackgroundTransparency = 1
		scrollbar.Size = UDim2.new(0, 18, (dropDownItemCount*.8)/((dropDownItemCount+1)*.8), -(17) - 11 - 4)
		scrollbar.Position = UDim2.new(1,-11,(1*.8)/((dropDownItemCount+1)*.8),17+2)
		scrollbar.Parent = droppedDownMenu
	end

	for i,item in ipairs(items) do
		-- needed to maintain local scope for items in event listeners below
		local button = choiceButton:clone()
		if forRoblox then
			-- RobloxLocked was restricted to CoreScripts; normal ModuleScripts cannot set it.
		end		
		button.Text = item
		button.Parent = droppedDownMenu
		if (whiteSkin) then
			button.TextColor3 = textColor
		end

		button.MouseButton1Click:connect(function()
			--Remove Highlight
			if (not whiteSkin) then
				button.TextColor3 = Color3.new(1,1,1)
			end
			button.BackgroundTransparency = 1

			updateSelection(item)
			onSelect(item)

			toggleVisibility()
		end)
		button.MouseEnter:connect(function()
			--Add Highlight	
			if (not whiteSkin) then
				button.TextColor3 = Color3.new(0,0,0)
			end
			button.BackgroundTransparency = 0
		end)

		button.MouseLeave:connect(function()
			--Remove Highlight
			if (not whiteSkin) then
				button.TextColor3 = Color3.new(1,1,1)
			end
			button.BackgroundTransparency = 1
		end)
	end

	--This does the initial layout of the buttons	
	updateScroll()

	frame.AncestryChanged:connect(function(child,parent)
		if parent == nil then
			areaSoak.Parent = nil
		else
			areaSoak.Parent = getScreenGuiAncestor(frame)
		end
	end)

	dropDownMenu.MouseButton1Click:connect(toggleVisibility)
	areaSoak.MouseButton1Click:connect(toggleVisibility)
	return frame, updateSelection
end

t.CreatePropertyDropDownMenu = function(instance, property, enum)

	local items = enum:GetEnumItems()
	local names = {}
	local nameToItem = {}
	for i,obj in ipairs(items) do
		names[i] = obj.Name
		nameToItem[obj.Name] = obj
	end

	local frame
	local updateSelection
	frame, updateSelection = t.CreateDropDownMenu(names, function(text) instance[property] = nameToItem[text] end)

	ScopedConnect(frame, instance, "Changed", 
		function(prop)
			if prop == property then
				updateSelection(instance[property].Name)
			end
		end,
		function()
			updateSelection(instance[property].Name)
		end)

	return frame
end

t.GetFontHeight = function(font, fontSize)
	if font == nil or fontSize == nil then
		error("Font and FontSize must be non-nil")
	end

	if font == Enum.Font.Legacy then
		if fontSize == Enum.FontSize.Size8 then
			return 12
		elseif fontSize == Enum.FontSize.Size9 then
			return 14
		elseif fontSize == Enum.FontSize.Size10 then
			return 15
		elseif fontSize == Enum.FontSize.Size11 then
			return 17
		elseif fontSize == Enum.FontSize.Size12 then
			return 18
		elseif fontSize == Enum.FontSize.Size14 then
			return 21
		elseif fontSize == Enum.FontSize.Size18 then
			return 27
		elseif fontSize == Enum.FontSize.Size24 then
			return 36
		elseif fontSize == Enum.FontSize.Size36 then
			return 54
		elseif fontSize == Enum.FontSize.Size48 then
			return 72
		else
			error("Unknown FontSize")
		end
	elseif font == Enum.Font.Arial or font == Enum.Font.ArialBold then
		if fontSize == Enum.FontSize.Size8 then
			return 8
		elseif fontSize == Enum.FontSize.Size9 then
			return 9
		elseif fontSize == Enum.FontSize.Size10 then
			return 10
		elseif fontSize == Enum.FontSize.Size11 then
			return 11
		elseif fontSize == Enum.FontSize.Size12 then
			return 12
		elseif fontSize == Enum.FontSize.Size14 then
			return 14
		elseif fontSize == Enum.FontSize.Size18 then
			return 18
		elseif fontSize == Enum.FontSize.Size24 then
			return 24
		elseif fontSize == Enum.FontSize.Size36 then
			return 36
		elseif fontSize == Enum.FontSize.Size48 then
			return 48
		else
			error("Unknown FontSize")
		end
	else
		error("Unknown Font " .. font)
	end
end

local function layoutGuiObjectsHelper(frame, guiObjects, settingsTable)
	local totalPixels = frame.AbsoluteSize.Y
	local pixelsRemaining = frame.AbsoluteSize.Y
	for i, child in ipairs(guiObjects) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			local isLabel = child:IsA("TextLabel")
			if isLabel then
				pixelsRemaining = pixelsRemaining - settingsTable["TextLabelPositionPadY"]
			else
				pixelsRemaining = pixelsRemaining - settingsTable["TextButtonPositionPadY"]
			end
			child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, 0, totalPixels - pixelsRemaining)
			child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, pixelsRemaining)

			if child.TextFits and child.TextBounds.Y < pixelsRemaining then
				child.Visible = true
				if isLabel then
					child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, child.TextBounds.Y + settingsTable["TextLabelSizePadY"])
				else 
					child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, child.TextBounds.Y + settingsTable["TextButtonSizePadY"])
				end

				while not child.TextFits do
					child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, child.AbsoluteSize.Y + 1)
				end
				pixelsRemaining = pixelsRemaining - child.AbsoluteSize.Y		

				if isLabel then
					pixelsRemaining = pixelsRemaining - settingsTable["TextLabelPositionPadY"]
				else
					pixelsRemaining = pixelsRemaining - settingsTable["TextButtonPositionPadY"]
				end
			else
				child.Visible = false
				pixelsRemaining = -1
			end			

		else
			--GuiObject
			child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, 0, totalPixels - pixelsRemaining)
			pixelsRemaining = pixelsRemaining - child.AbsoluteSize.Y
			child.Visible = (pixelsRemaining >= 0)
		end
	end
end

t.LayoutGuiObjects = function(frame, guiObjects, settingsTable)
	if not frame:IsA("GuiObject") then
		error("Frame must be a GuiObject")
	end
	for i, child in ipairs(guiObjects) do
		if not child:IsA("GuiObject") then
			error("All elements that are layed out must be of type GuiObject")
		end
	end

	if not settingsTable then
		settingsTable = {}
	end

	if not settingsTable["TextLabelSizePadY"] then
		settingsTable["TextLabelSizePadY"] = 0
	end
	if not settingsTable["TextLabelPositionPadY"] then
		settingsTable["TextLabelPositionPadY"] = 0
	end
	if not settingsTable["TextButtonSizePadY"] then
		settingsTable["TextButtonSizePadY"] = 12
	end
	if not settingsTable["TextButtonPositionPadY"] then
		settingsTable["TextButtonPositionPadY"] = 2
	end

	--Wrapper frame takes care of styled objects
	local wrapperFrame = Instance.new("Frame")
	wrapperFrame.Name = "WrapperFrame"
	wrapperFrame.BackgroundTransparency = 1
	wrapperFrame.Size = UDim2.new(1,0,1,0)
	wrapperFrame.Parent = frame

	for i, child in ipairs(guiObjects) do
		child.Parent = wrapperFrame
	end

	local recalculate = function()
		wait()
		layoutGuiObjectsHelper(wrapperFrame, guiObjects, settingsTable)
	end

	frame.Changed:connect(
		function(prop)
			if prop == "AbsoluteSize" then
				--Wait a heartbeat for it to sync in
				recalculate(nil)
			end
		end)
	frame.AncestryChanged:connect(recalculate)

	layoutGuiObjectsHelper(wrapperFrame, guiObjects, settingsTable)
end


t.CreateSlider = function(steps,width,position)
	local sliderGui = Instance.new("Frame")
	sliderGui.Size = UDim2.new(1,0,1,0)
	sliderGui.BackgroundTransparency = 1
	sliderGui.Name = "SliderGui"

	local sliderSteps = Instance.new("IntValue")
	sliderSteps.Name = "SliderSteps"
	sliderSteps.Value = steps
	sliderSteps.Parent = sliderGui

	local areaSoak = Instance.new("TextButton")
	areaSoak.Name = "AreaSoak"
	areaSoak.Text = ""
	areaSoak.BackgroundTransparency = 1
	areaSoak.Active = false
	areaSoak.Size = UDim2.new(1,0,1,0)
	areaSoak.Visible = false
	areaSoak.ZIndex = 4

	sliderGui.AncestryChanged:connect(function(child,parent)
		if parent == nil then
			areaSoak.Parent = nil
		else
			areaSoak.Parent = getScreenGuiAncestor(sliderGui)
		end
	end)

	local sliderPosition = Instance.new("IntValue")
	sliderPosition.Name = "SliderPosition"
	sliderPosition.Value = 0
	sliderPosition.Parent = sliderGui

	local id = math.random(1,100)

	local bar = Instance.new("TextButton")
	bar.Text = ""
	bar.AutoButtonColor = false
	bar.Name = "Bar"
	bar.BackgroundColor3 = Color3.new(0,0,0)
	if type(width) == "number" then
		bar.Size = UDim2.new(0,width,0,5)
	else
		bar.Size = UDim2.new(0,200,0,5)
	end
	bar.BorderColor3 = Color3.new(95/255,95/255,95/255)
	bar.ZIndex = 2
	bar.Parent = sliderGui

	if position["X"] and position["X"]["Scale"] and position["X"]["Offset"] and position["Y"] and position["Y"]["Scale"] and position["Y"]["Offset"] then
		bar.Position = position
	end

	local slider = Instance.new("ImageButton")
	slider.Name = "Slider"
	slider.BackgroundTransparency = 1
	slider.Image = "rbxasset://textures/ui/Slider.png"
	slider.Position = UDim2.new(0,0,0.5,-10)
	slider.Size = UDim2.new(0,20,0,20)
	slider.ZIndex = 3
	slider.Parent = bar

	areaSoakMouseMoveCon = nil

	areaSoak.MouseLeave:connect(function()
		if areaSoak.Visible then
			cancelSlide(areaSoak)
		end
	end)
	areaSoak.MouseButton1Up:connect(function()
		if areaSoak.Visible then
			cancelSlide(areaSoak)
		end
	end)

	slider.MouseButton1Down:connect(function()
		areaSoak.Visible = true
		if areaSoakMouseMoveCon then areaSoakMouseMoveCon:Disconnect(); areaSoakMouseMoveCon = nil end
		areaSoakMouseMoveCon = areaSoak.MouseMoved:connect(function(x,y)
			setSliderPos(x,slider,sliderPosition,bar,steps)
		end)
	end)

	slider.MouseButton1Up:connect(function() cancelSlide(areaSoak) end)

	sliderPosition.Changed:connect(function(prop)
		sliderPosition.Value = math.min(steps, math.max(1,sliderPosition.Value))
		local relativePosX = (sliderPosition.Value - 1) / math.max(1, steps - 1)
		slider.Position = UDim2.new(relativePosX,-slider.AbsoluteSize.X/2,slider.Position.Y.Scale,slider.Position.Y.Offset)
	end)

	bar.MouseButton1Down:connect(function(x,y)
		setSliderPos(x,slider,sliderPosition,bar,steps)
	end)

	return sliderGui, sliderPosition, sliderSteps

end



t.CreateSliderNew = function(steps,width,position)
	local sliderGui = Instance.new("Frame")
	sliderGui.Size = UDim2.new(1,0,1,0)
	sliderGui.BackgroundTransparency = 1
	sliderGui.Name = "SliderGui"

	local sliderSteps = Instance.new("IntValue")
	sliderSteps.Name = "SliderSteps"
	sliderSteps.Value = steps
	sliderSteps.Parent = sliderGui

	local areaSoak = Instance.new("TextButton")
	areaSoak.Name = "AreaSoak"
	areaSoak.Text = ""
	areaSoak.BackgroundTransparency = 1
	areaSoak.Active = false
	areaSoak.Size = UDim2.new(1,0,1,0)
	areaSoak.Visible = false
	areaSoak.ZIndex = 6

	sliderGui.AncestryChanged:connect(function(child,parent)
		if parent == nil then
			areaSoak.Parent = nil
		else
			areaSoak.Parent = getScreenGuiAncestor(sliderGui)
		end
	end)

	local sliderPosition = Instance.new("IntValue")
	sliderPosition.Name = "SliderPosition"
	sliderPosition.Value = 0
	sliderPosition.Parent = sliderGui

	local id = math.random(1,100)

	local sliderBarImgHeight = 7
	local sliderBarCapImgWidth = 4

	local bar = Instance.new("ImageButton")
	bar.BackgroundTransparency = 1
	bar.Image = "rbxasset://textures/ui/Slider-BKG-Center.png"
	bar.Name = "Bar"
	local displayWidth = 200
	if type(width) == "number" then
		bar.Size = UDim2.new(0,width - (sliderBarCapImgWidth * 2),0,sliderBarImgHeight)
		displayWidth = width - (sliderBarCapImgWidth * 2)
	else
		bar.Size = UDim2.new(0,200,0,sliderBarImgHeight)
	end
	bar.ZIndex = 3
	bar.Parent = sliderGui	
	if position["X"] and position["X"]["Scale"] and position["X"]["Offset"] and position["Y"] and position["Y"]["Scale"] and position["Y"]["Offset"] then
		bar.Position = position
	end

	local barLeft = bar:clone()
	barLeft.Name = "BarLeft"
	barLeft.Image = "rbxasset://textures/ui/Slider-BKG-Left-Cap.png"
	barLeft.Size = UDim2.new(0, sliderBarCapImgWidth, 0, sliderBarImgHeight)
	barLeft.Position = UDim2.new(position.X.Scale, position.X.Offset - sliderBarCapImgWidth, position.Y.Scale, position.Y.Offset)
	barLeft.Parent = sliderGui	
	barLeft.ZIndex = 3

	local barRight = barLeft:clone()
	barRight.Name = "BarRight"
	barRight.Image = "rbxasset://textures/ui/Slider-BKG-Right-Cap.png"
	barRight.Position = UDim2.new(position.X.Scale, position.X.Offset + displayWidth, position.Y.Scale, position.Y.Offset)
	barRight.Parent = sliderGui	

	local fillLeft = barLeft:clone()
	fillLeft.Name = "FillLeft"
	fillLeft.Image = "rbxasset://textures/ui/Slider-Fill-Left-Cap.png"
	fillLeft.Parent = sliderGui	
	fillLeft.ZIndex = 4

	local fill = fillLeft:clone()
	fill.Name = "Fill"
	fill.Image = "rbxasset://textures/ui/Slider-Fill-Center.png"
	fill.Parent = bar	
	fill.ZIndex = 4
	fill.Position = UDim2.new(0, 0, 0, 0)
	fill.Size = UDim2.new(0.5, 0, 1, 0)


	--	bar.Visible = false

	local slider = Instance.new("ImageButton")
	slider.Name = "Slider"
	slider.BackgroundTransparency = 1
	slider.Image = "rbxasset://textures/ui/slider_new_tab.png"
	slider.Position = UDim2.new(0,0,0.5,-14)
	slider.Size = UDim2.new(0,28,0,28)
	slider.ZIndex = 5
	slider.Parent = bar

	areaSoakMouseMoveCon = nil

	areaSoak.MouseLeave:connect(function()
		if areaSoak.Visible then
			cancelSlide(areaSoak)
		end
	end)
	areaSoak.MouseButton1Up:connect(function()
		if areaSoak.Visible then
			cancelSlide(areaSoak)
		end
	end)

	slider.MouseButton1Down:connect(function()
		areaSoak.Visible = true
		if areaSoakMouseMoveCon then areaSoakMouseMoveCon:Disconnect(); areaSoakMouseMoveCon = nil end
		areaSoakMouseMoveCon = areaSoak.MouseMoved:connect(function(x,y)
			setSliderPos(x,slider,sliderPosition,bar,steps)
		end)
	end)

	slider.MouseButton1Up:connect(function() cancelSlide(areaSoak) end)

	sliderPosition.Changed:connect(function(prop)
		sliderPosition.Value = math.min(steps, math.max(1,sliderPosition.Value))
		local relativePosX = (sliderPosition.Value - 1) / math.max(1, steps - 1)
		slider.Position = UDim2.new(relativePosX,-slider.AbsoluteSize.X/2,slider.Position.Y.Scale,slider.Position.Y.Offset)
		fill.Size = UDim2.new(relativePosX, 0, 1, 0)
	end)

	bar.MouseButton1Down:connect(function(x,y)
		setSliderPos(x,slider,sliderPosition,bar,steps)
	end)

	fill.MouseButton1Down:connect(function(x,y)
		setSliderPos(x,slider,sliderPosition,bar,steps)
	end)

	fillLeft.MouseButton1Down:connect(function(x,y)
		setSliderPos(x,slider,sliderPosition,bar,steps)
	end)


	return sliderGui, sliderPosition, sliderSteps

end





t.CreateTrueScrollingFrame = function()
	local lowY = nil
	local highY = nil

	local dragCon = nil
	local upCon = nil

	local internalChange = false

	local descendantsChangeConMap = {}

	local scrollingFrame = Instance.new("Frame")
	scrollingFrame.Name = "ScrollingFrame"
	scrollingFrame.Active = true
	scrollingFrame.Size = UDim2.new(1,0,1,0)
	scrollingFrame.ClipsDescendants = true

	local controlFrame = Instance.new("Frame")
	controlFrame.Name = "ControlFrame"
	controlFrame.BackgroundTransparency = 1
	controlFrame.Size = UDim2.new(0,18,1,0)
	controlFrame.Position = UDim2.new(1,-20,0,0)
	controlFrame.Parent = scrollingFrame

	local scrollBottom = Instance.new("BoolValue")
	scrollBottom.Value = false
	scrollBottom.Name = "ScrollBottom"
	scrollBottom.Parent = controlFrame

	local scrollUp = Instance.new("BoolValue")
	scrollUp.Value = false
	scrollUp.Name = "scrollUp"
	scrollUp.Parent = controlFrame

	local scrollUpButton = Instance.new("TextButton")
	scrollUpButton.Name = "ScrollUpButton"
	scrollUpButton.Text = ""
	scrollUpButton.AutoButtonColor = false
	scrollUpButton.BackgroundColor3 = Color3.new(0,0,0)
	scrollUpButton.BorderColor3 = Color3.new(1,1,1)
	scrollUpButton.BackgroundTransparency = 0.5
	scrollUpButton.Size = UDim2.new(0,18,0,18)
	scrollUpButton.ZIndex = 2
	scrollUpButton.Parent = controlFrame
	for i = 1, 6 do
		local triFrame = Instance.new("Frame")
		triFrame.BorderColor3 = Color3.new(1,1,1)
		triFrame.Name = "tri" .. tostring(i)
		triFrame.ZIndex = 3
		triFrame.BackgroundTransparency = 0.5
		triFrame.Size = UDim2.new(0,12 - ((i -1) * 2),0,0)
		triFrame.Position = UDim2.new(0,3 + (i -1),0.5,2 - (i -1))
		triFrame.Parent = scrollUpButton
	end
	scrollUpButton.MouseEnter:connect(function()
		scrollUpButton.BackgroundTransparency = 0.1
		local upChildren = scrollUpButton:GetChildren()
		for i = 1, #upChildren do
			upChildren[i].BackgroundTransparency = 0.1
		end
	end)
	scrollUpButton.MouseLeave:connect(function()
		scrollUpButton.BackgroundTransparency = 0.5
		local upChildren = scrollUpButton:GetChildren()
		for i = 1, #upChildren do
			upChildren[i].BackgroundTransparency = 0.5
		end
	end)

	local scrollDownButton = scrollUpButton:clone()
	scrollDownButton.Name = "ScrollDownButton"
	scrollDownButton.Position = UDim2.new(0,0,1,-18)
	local downChildren = scrollDownButton:GetChildren()
	for i = 1, #downChildren do
		downChildren[i].Position = UDim2.new(0,3 + (i -1),0.5,-2 + (i - 1))
	end
	scrollDownButton.MouseEnter:connect(function()
		scrollDownButton.BackgroundTransparency = 0.1
		local downChildren = scrollDownButton:GetChildren()
		for i = 1, #downChildren do
			downChildren[i].BackgroundTransparency = 0.1
		end
	end)
	scrollDownButton.MouseLeave:connect(function()
		scrollDownButton.BackgroundTransparency = 0.5
		local downChildren = scrollDownButton:GetChildren()
		for i = 1, #downChildren do
			downChildren[i].BackgroundTransparency = 0.5
		end
	end)
	scrollDownButton.Parent = controlFrame

	local scrollTrack = Instance.new("Frame")
	scrollTrack.Name = "ScrollTrack"
	scrollTrack.BackgroundTransparency = 1
	scrollTrack.Size = UDim2.new(0,18,1,-38)
	scrollTrack.Position = UDim2.new(0,0,0,19)
	scrollTrack.Parent = controlFrame

	local scrollbar = Instance.new("TextButton")
	scrollbar.BackgroundColor3 = Color3.new(0,0,0)
	scrollbar.BorderColor3 = Color3.new(1,1,1)
	scrollbar.BackgroundTransparency = 0.5
	scrollbar.AutoButtonColor = false
	scrollbar.Text = ""
	scrollbar.Active = true
	scrollbar.Name = "ScrollBar"
	scrollbar.ZIndex = 2
	scrollbar.BackgroundTransparency = 0.5
	scrollbar.Size = UDim2.new(0, 18, 0.1, 0)
	scrollbar.Position = UDim2.new(0,0,0,0)
	scrollbar.Parent = scrollTrack

	local scrollNub = Instance.new("Frame")
	scrollNub.Name = "ScrollNub"
	scrollNub.BorderColor3 = Color3.new(1,1,1)
	scrollNub.Size = UDim2.new(0,10,0,0)
	scrollNub.Position = UDim2.new(0.5,-5,0.5,0)
	scrollNub.ZIndex = 2
	scrollNub.BackgroundTransparency = 0.5
	scrollNub.Parent = scrollbar

	local newNub = scrollNub:clone()
	newNub.Position = UDim2.new(0.5,-5,0.5,-2)
	newNub.Parent = scrollbar

	local lastNub = scrollNub:clone()
	lastNub.Position = UDim2.new(0.5,-5,0.5,2)
	lastNub.Parent = scrollbar

	scrollbar.MouseEnter:connect(function()
		scrollbar.BackgroundTransparency = 0.1
		scrollNub.BackgroundTransparency = 0.1
		newNub.BackgroundTransparency = 0.1
		lastNub.BackgroundTransparency = 0.1
	end)
	scrollbar.MouseLeave:connect(function()
		scrollbar.BackgroundTransparency = 0.5
		scrollNub.BackgroundTransparency = 0.5
		newNub.BackgroundTransparency = 0.5
		lastNub.BackgroundTransparency = 0.5
	end)

	local mouseDrag = Instance.new("ImageButton")
	mouseDrag.Active = false
	mouseDrag.Size = UDim2.new(1.5, 0, 1.5, 0)
	mouseDrag.AutoButtonColor = false
	mouseDrag.BackgroundTransparency = 1
	mouseDrag.Name = "mouseDrag"
	mouseDrag.Position = UDim2.new(-0.25, 0, -0.25, 0)
	mouseDrag.ZIndex = 10

	local function positionScrollBar(x,y,offset)
		local oldPos = scrollbar.Position

		if y < scrollTrack.AbsolutePosition.y then
			scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,0,0)
			return (oldPos ~= scrollbar.Position)
		end

		local relativeSize = scrollbar.AbsoluteSize.Y/scrollTrack.AbsoluteSize.Y

		if y > (scrollTrack.AbsolutePosition.y + scrollTrack.AbsoluteSize.y) then
			scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,1 - relativeSize,0)
			return (oldPos ~= scrollbar.Position)
		end
		local newScaleYPos = (y - scrollTrack.AbsolutePosition.y - offset)/scrollTrack.AbsoluteSize.y
		if newScaleYPos + relativeSize > 1 then
			newScaleYPos = 1 - relativeSize
			scrollBottom.Value = true
			scrollUp.Value = false
		elseif newScaleYPos <= 0 then
			newScaleYPos = 0
			scrollUp.Value = true
			scrollBottom.Value = false
		else
			scrollUp.Value = false
			scrollBottom.Value = false
		end
		scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,newScaleYPos,0)

		return (oldPos ~= scrollbar.Position)
	end

	local function drillDownSetHighLow(instance)
		if not instance or not instance:IsA("GuiObject") then return end
		if instance == controlFrame then return end
		if instance:IsDescendantOf(controlFrame) then return end
		if not instance.Visible then return end

		if lowY and lowY > instance.AbsolutePosition.Y then
			lowY = instance.AbsolutePosition.Y
		elseif not lowY then
			lowY = instance.AbsolutePosition.Y
		end
		if highY and highY < (instance.AbsolutePosition.Y + instance.AbsoluteSize.Y) then
			highY = instance.AbsolutePosition.Y + instance.AbsoluteSize.Y
		elseif not highY then
			highY = instance.AbsolutePosition.Y + instance.AbsoluteSize.Y
		end
		local children = instance:GetChildren()
		for i = 1, #children do
			drillDownSetHighLow(children[i])
		end
	end

	local function resetHighLow()
		local firstChildren = scrollingFrame:GetChildren()

		for i = 1, #firstChildren do
			drillDownSetHighLow(firstChildren[i])
		end
	end

	local function recalculate()
		internalChange = true

		local percentFrame = 0
		if scrollbar.Position.Y.Scale > 0 then
			if scrollbar.Visible then
				percentFrame = scrollbar.Position.Y.Scale/((scrollTrack.AbsoluteSize.Y - scrollbar.AbsoluteSize.Y)/scrollTrack.AbsoluteSize.Y)
			else
				percentFrame = 0
			end
		end
		if percentFrame > 0.99 then percentFrame = 1 end

		local hiddenYAmount = (scrollingFrame.AbsoluteSize.Y - (highY - lowY)) * percentFrame

		local guiChildren = scrollingFrame:GetChildren()
		for i = 1, #guiChildren do
			if guiChildren[i] ~= controlFrame then
				guiChildren[i].Position = UDim2.new(guiChildren[i].Position.X.Scale,guiChildren[i].Position.X.Offset,
					0, math.ceil(guiChildren[i].AbsolutePosition.Y) - math.ceil(lowY) + hiddenYAmount)
			end
		end

		lowY = nil
		highY = nil
		resetHighLow()
		internalChange = false
	end

	local function setSliderSizeAndPosition()
		if not highY or not lowY then return end

		local totalYSpan = math.abs(highY - lowY)
		if totalYSpan == 0 then
			scrollbar.Visible = false
			scrollDownButton.Visible = false
			scrollUpButton.Visible = false

			if dragCon then dragCon:disconnect() dragCon = nil end
			if upCon then upCon:disconnect() upCon = nil end
			return
		end

		local percentShown = scrollingFrame.AbsoluteSize.Y/totalYSpan
		if percentShown >= 1 then
			scrollbar.Visible = false
			scrollDownButton.Visible = false
			scrollUpButton.Visible = false
			recalculate()
		else
			scrollbar.Visible = true
			scrollDownButton.Visible = true
			scrollUpButton.Visible = true

			scrollbar.Size = UDim2.new(scrollbar.Size.X.Scale,scrollbar.Size.X.Offset,percentShown,0)
		end

		local percentPosition = (scrollingFrame.AbsolutePosition.Y - lowY)/totalYSpan
		scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,percentPosition,-scrollbar.AbsoluteSize.X/2)

		if scrollbar.AbsolutePosition.y < scrollTrack.AbsolutePosition.y then
			scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,0,0)
		end

		if (scrollbar.AbsolutePosition.y + scrollbar.AbsoluteSize.Y) > (scrollTrack.AbsolutePosition.y + scrollTrack.AbsoluteSize.y) then
			local relativeSize = scrollbar.AbsoluteSize.Y/scrollTrack.AbsoluteSize.Y
			scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,1 - relativeSize,0)
		end
	end

	local buttonScrollAmountPixels = 7
	local reentrancyGuardScrollUp = false
	local function doScrollUp()
		if reentrancyGuardScrollUp then return end

		reentrancyGuardScrollUp = true
		if positionScrollBar(0,scrollbar.AbsolutePosition.Y - buttonScrollAmountPixels,0) then
			recalculate()
		end
		reentrancyGuardScrollUp = false
	end

	local reentrancyGuardScrollDown = false
	local function doScrollDown()
		if reentrancyGuardScrollDown then return end

		reentrancyGuardScrollDown = true
		if positionScrollBar(0,scrollbar.AbsolutePosition.Y + buttonScrollAmountPixels,0) then
			recalculate()
		end
		reentrancyGuardScrollDown = false
	end

	local function scrollUp(mouseYPos)
		if scrollUpButton.Active then
			scrollStamp = tick()
			local current = scrollStamp
			local upCon
			upCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				upCon:disconnect()
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
			doScrollUp()
			wait(0.2)
			local t = tick()
			local w = 0.1
			while scrollStamp == current do
				doScrollUp()
				if mouseYPos and mouseYPos > scrollbar.AbsolutePosition.y then
					break
				end
				if not scrollUpButton.Active then break end
				if tick()-t > 5 then
					w = 0
				elseif tick()-t > 2 then
					w = 0.06
				end
				wait(w)
			end
		end
	end

	local function scrollDown(mouseYPos)
		if scrollDownButton.Active then
			scrollStamp = tick()
			local current = scrollStamp
			local downCon
			downCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				downCon:disconnect()
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
			doScrollDown()
			wait(0.2)
			local t = tick()
			local w = 0.1
			while scrollStamp == current do
				doScrollDown()
				if mouseYPos and mouseYPos < (scrollbar.AbsolutePosition.y + scrollbar.AbsoluteSize.x) then
					break
				end
				if not scrollDownButton.Active then break end
				if tick()-t > 5 then
					w = 0
				elseif tick()-t > 2 then
					w = 0.06
				end
				wait(w)
			end
		end
	end

	scrollbar.MouseButton1Down:connect(function(x,y)
		if scrollbar.Active then
			scrollStamp = tick()
			local mouseOffset = y - scrollbar.AbsolutePosition.y
			if dragCon then dragCon:disconnect() dragCon = nil end
			if upCon then upCon:disconnect() upCon = nil end
			local prevY = y
			local reentrancyGuardMouseScroll = false
			dragCon = mouseDrag.MouseMoved:connect(function(x,y)
				if reentrancyGuardMouseScroll then return end

				reentrancyGuardMouseScroll = true
				if positionScrollBar(x,y,mouseOffset) then
					recalculate()
				end
				reentrancyGuardMouseScroll = false

			end)
			upCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				dragCon:disconnect(); dragCon = nil
				upCon:disconnect(); drag = nil
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
		end
	end)

	local scrollMouseCount = 0

	scrollUpButton.MouseButton1Down:connect(function()
		scrollUp()
	end)
	scrollUpButton.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)

	scrollDownButton.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)
	scrollDownButton.MouseButton1Down:connect(function()
		scrollDown()
	end)

	scrollbar.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)

	local function heightCheck(instance)
		if highY and (instance.AbsolutePosition.Y + instance.AbsoluteSize.Y) > highY then
			highY = instance.AbsolutePosition.Y + instance.AbsoluteSize.Y
		elseif not highY then
			highY = instance.AbsolutePosition.Y + instance.AbsoluteSize.Y
		end
		setSliderSizeAndPosition()
	end

	local function highLowRecheck()
		local oldLowY = lowY
		local oldHighY = highY
		lowY = nil
		highY = nil
		resetHighLow()

		if (lowY ~= oldLowY) or (highY ~= oldHighY) then
			setSliderSizeAndPosition()
		end
	end

	local function descendantChanged(this, prop)
		if internalChange then return end
		if not this.Visible then return end

		if prop == "Size" or prop == "Position" then
			wait()
			highLowRecheck()
		end
	end

	scrollingFrame.DescendantAdded:connect(function(instance)
		if not instance:IsA("GuiObject") then return end

		if instance.Visible then
			wait() -- wait a heartbeat for sizes to reconfig
			highLowRecheck()
		end

		descendantsChangeConMap[instance] = instance.Changed:connect(function(prop) descendantChanged(instance, prop) end)
	end)

	scrollingFrame.DescendantRemoving:connect(function(instance)
		if not instance:IsA("GuiObject") then return end
		if descendantsChangeConMap[instance] then
			descendantsChangeConMap[instance]:disconnect()
			descendantsChangeConMap[instance] = nil
		end
		wait() -- wait a heartbeat for sizes to reconfig
		highLowRecheck()
	end)

	scrollingFrame.Changed:connect(function(prop)
		if prop == "AbsoluteSize" then
			if not highY or not lowY then return end

			highLowRecheck()
			setSliderSizeAndPosition()
		end
	end)

	return scrollingFrame, controlFrame
end

t.CreateScrollingFrame = function(orderList,scrollStyle)
	local frame = Instance.new("Frame")
	frame.Name = "ScrollingFrame"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1,0,1,0)

	local scrollUpButton = Instance.new("ImageButton")
	scrollUpButton.Name = "ScrollUpButton"
	scrollUpButton.BackgroundTransparency = 1
	scrollUpButton.Image = "rbxasset://textures/ui/scrollbuttonUp.png"
	scrollUpButton.Size = UDim2.new(0,17,0,17) 


	local scrollDownButton = Instance.new("ImageButton")
	scrollDownButton.Name = "ScrollDownButton"
	scrollDownButton.BackgroundTransparency = 1
	scrollDownButton.Image = "rbxasset://textures/ui/scrollbuttonDown.png"
	scrollDownButton.Size = UDim2.new(0,17,0,17) 

	local scrollbar = Instance.new("ImageButton")
	scrollbar.Name = "ScrollBar"
	scrollbar.Image = "rbxasset://textures/ui/scrollbar.png"
	scrollbar.BackgroundTransparency = 1
	scrollbar.Size = UDim2.new(0, 18, 0, 150)

	local scrollStamp = 0

	local scrollDrag = Instance.new("ImageButton")
	scrollDrag.Image = "http://www.roblox.com/asset/?id=61367186"
	scrollDrag.Size = UDim2.new(1, 0, 0, 16)
	scrollDrag.BackgroundTransparency = 1
	scrollDrag.Name = "ScrollDrag"
	scrollDrag.Active = true
	scrollDrag.Parent = scrollbar

	local mouseDrag = Instance.new("ImageButton")
	mouseDrag.Active = false
	mouseDrag.Size = UDim2.new(1.5, 0, 1.5, 0)
	mouseDrag.AutoButtonColor = false
	mouseDrag.BackgroundTransparency = 1
	mouseDrag.Name = "mouseDrag"
	mouseDrag.Position = UDim2.new(-0.25, 0, -0.25, 0)
	mouseDrag.ZIndex = 10

	local style = "simple"
	if scrollStyle and tostring(scrollStyle) then
		style = scrollStyle
	end

	local scrollPosition = 1
	local rowSize = 0
	local howManyDisplayed = 0

	local layoutGridScrollBar = function()
		howManyDisplayed = 0
		local guiObjects = {}
		if orderList then
			for i, child in ipairs(orderList) do
				if child.Parent == frame then
					table.insert(guiObjects, child)
				end
			end
		else
			local children = frame:GetChildren()
			if children then
				for i, child in ipairs(children) do 
					if child:IsA("GuiObject") then
						table.insert(guiObjects, child)
					end
				end
			end
		end
		if #guiObjects == 0 then
			scrollUpButton.Active = false
			scrollDownButton.Active = false
			scrollDrag.Active = false
			scrollPosition = 1
			return
		end

		if scrollPosition > #guiObjects then
			scrollPosition = #guiObjects
		end

		if scrollPosition < 1 then scrollPosition = 1 end

		local totalPixelsY = frame.AbsoluteSize.Y
		local pixelsRemainingY = frame.AbsoluteSize.Y

		local totalPixelsX  = frame.AbsoluteSize.X

		local xCounter = 0
		local rowSizeCounter = 0
		local setRowSize = true

		local pixelsBelowScrollbar = 0
		local pos = #guiObjects

		local currentRowY = 0

		pos = scrollPosition
		--count up from current scroll position to fill out grid
		while pos <= #guiObjects and pixelsBelowScrollbar < totalPixelsY do
			xCounter = xCounter + guiObjects[pos].AbsoluteSize.X
			--previous pos was the end of a row
			if xCounter >= totalPixelsX then
				pixelsBelowScrollbar = pixelsBelowScrollbar + currentRowY
				currentRowY = 0
				xCounter = guiObjects[pos].AbsoluteSize.X
			end
			if guiObjects[pos].AbsoluteSize.Y > currentRowY then
				currentRowY = guiObjects[pos].AbsoluteSize.Y
			end
			pos = pos + 1
		end
		--Count wherever current row left off
		pixelsBelowScrollbar = pixelsBelowScrollbar + currentRowY
		currentRowY = 0

		pos = scrollPosition - 1
		xCounter = 0

		--objects with varying X,Y dimensions can rarely cause minor errors
		--rechecking every new scrollPosition is necessary to avoid 100% of errors

		--count backwards from current scrollPosition to see if we can add more rows
		while pixelsBelowScrollbar + currentRowY < totalPixelsY and pos >= 1 do
			xCounter = xCounter + guiObjects[pos].AbsoluteSize.X
			rowSizeCounter = rowSizeCounter + 1
			if xCounter >= totalPixelsX then
				rowSize = rowSizeCounter - 1
				rowSizeCounter = 0
				xCounter = guiObjects[pos].AbsoluteSize.X
				if pixelsBelowScrollbar + currentRowY <= totalPixelsY then
					--It fits, so back up our scroll position
					pixelsBelowScrollbar = pixelsBelowScrollbar + currentRowY
					if scrollPosition <= rowSize then
						scrollPosition = 1 
						break
					else
						scrollPosition = scrollPosition - rowSize
					end
					currentRowY = 0
				else
					break
				end
			end

			if guiObjects[pos].AbsoluteSize.Y > currentRowY then
				currentRowY = guiObjects[pos].AbsoluteSize.Y
			end

			pos = pos - 1
		end

		--Do check last time if pos = 0
		if (pos == 0) and (pixelsBelowScrollbar + currentRowY <= totalPixelsY) then
			scrollPosition = 1
		end

		xCounter = 0
		--pos = scrollPosition
		rowSizeCounter = 0
		setRowSize = true
		local lastChildSize = 0

		local xOffset,yOffset = 0
		if guiObjects[1] then
			yOffset = math.ceil(math.floor(math.fmod(totalPixelsY,guiObjects[1].AbsoluteSize.X))/2)
			xOffset = math.ceil(math.floor(math.fmod(totalPixelsX,guiObjects[1].AbsoluteSize.Y))/2)
		end

		for i, child in ipairs(guiObjects) do
			if i < scrollPosition then
				--print("Hiding " .. child.Name)
				child.Visible = false
			else
				if pixelsRemainingY < 0 then
					--print("Out of Space " .. child.Name)
					child.Visible = false
				else
					--print("Laying out " .. child.Name)
					--GuiObject
					if setRowSize then rowSizeCounter = rowSizeCounter + 1 end
					if xCounter + child.AbsoluteSize.X >= totalPixelsX then
						if setRowSize then
							rowSize = rowSizeCounter - 1
							setRowSize = false
						end
						xCounter = 0
						pixelsRemainingY = pixelsRemainingY - child.AbsoluteSize.Y
					end
					child.Position = UDim2.new(child.Position.X.Scale,xCounter + xOffset, 0, totalPixelsY - pixelsRemainingY + yOffset)
					xCounter = xCounter + child.AbsoluteSize.X
					child.Visible = ((pixelsRemainingY - child.AbsoluteSize.Y) >= 0)
					if child.Visible then
						howManyDisplayed = howManyDisplayed + 1
					end
					lastChildSize = child.AbsoluteSize				
				end
			end
		end

		scrollUpButton.Active = (scrollPosition > 1)
		if lastChildSize == 0 then 
			scrollDownButton.Active = false
		else
			scrollDownButton.Active = ((pixelsRemainingY - lastChildSize.Y) < 0)
		end
		scrollDrag.Active = #guiObjects > howManyDisplayed
		scrollDrag.Visible = scrollDrag.Active
	end



	local layoutSimpleScrollBar = function()
		local guiObjects = {}	
		howManyDisplayed = 0

		if orderList then
			for i, child in ipairs(orderList) do
				if child.Parent == frame then
					table.insert(guiObjects, child)
				end
			end
		else
			local children = frame:GetChildren()
			if children then
				for i, child in ipairs(children) do 
					if child:IsA("GuiObject") then
						table.insert(guiObjects, child)
					end
				end
			end
		end
		if #guiObjects == 0 then
			scrollUpButton.Active = false
			scrollDownButton.Active = false
			scrollDrag.Active = false
			scrollPosition = 1
			return
		end

		if scrollPosition > #guiObjects then
			scrollPosition = #guiObjects
		end

		local totalPixels = frame.AbsoluteSize.Y
		local pixelsRemaining = frame.AbsoluteSize.Y

		local pixelsBelowScrollbar = 0
		local pos = #guiObjects
		while pixelsBelowScrollbar < totalPixels and pos >= 1 do
			if pos >= scrollPosition then
				pixelsBelowScrollbar = pixelsBelowScrollbar + guiObjects[pos].AbsoluteSize.Y
			else
				if pixelsBelowScrollbar + guiObjects[pos].AbsoluteSize.Y <= totalPixels then
					--It fits, so back up our scroll position
					pixelsBelowScrollbar = pixelsBelowScrollbar + guiObjects[pos].AbsoluteSize.Y
					if scrollPosition <= 1 then
						scrollPosition = 1
						break
					else
						--local ("Backing up ScrollPosition from -- " ..scrollPosition)
						scrollPosition = scrollPosition - 1
					end
				else
					break
				end
			end
			pos = pos - 1
		end

		pos = scrollPosition
		for i, child in ipairs(guiObjects) do
			if i < scrollPosition then
				--print("Hiding " .. child.Name)
				child.Visible = false
			else
				if pixelsRemaining < 0 then
					--print("Out of Space " .. child.Name)
					child.Visible = false
				else
					--print("Laying out " .. child.Name)
					--GuiObject
					child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, 0, totalPixels - pixelsRemaining)
					pixelsRemaining = pixelsRemaining - child.AbsoluteSize.Y
					if  (pixelsRemaining >= 0) then
						child.Visible = true
						howManyDisplayed = howManyDisplayed + 1
					else
						child.Visible = false
					end		
				end
			end
		end
		scrollUpButton.Active = (scrollPosition > 1)
		scrollDownButton.Active = (pixelsRemaining < 0)
		scrollDrag.Active = #guiObjects > howManyDisplayed
		scrollDrag.Visible = scrollDrag.Active
	end


	local moveDragger = function()	
		local guiObjects = 0
		local children = frame:GetChildren()
		if children then
			for i, child in ipairs(children) do 
				if child:IsA("GuiObject") then
					guiObjects = guiObjects + 1
				end
			end
		end

		if not scrollDrag.Parent then return end

		local dragSizeY = scrollDrag.Parent.AbsoluteSize.y * (1/(guiObjects - howManyDisplayed + 1))
		if dragSizeY < 16 then dragSizeY = 16 end
		scrollDrag.Size = UDim2.new(scrollDrag.Size.X.Scale,scrollDrag.Size.X.Offset,scrollDrag.Size.Y.Scale,dragSizeY)

		local relativeYPos = (scrollPosition - 1)/(guiObjects - (howManyDisplayed))
		if relativeYPos > 1 then relativeYPos = 1
		elseif relativeYPos < 0 then relativeYPos = 0 end
		local absYPos = 0

		if relativeYPos ~= 0 then
			absYPos = (relativeYPos * scrollbar.AbsoluteSize.y) - (relativeYPos * scrollDrag.AbsoluteSize.y)
		end

		scrollDrag.Position = UDim2.new(scrollDrag.Position.X.Scale,scrollDrag.Position.X.Offset,scrollDrag.Position.Y.Scale,absYPos)
	end

	local reentrancyGuard = false
	local recalculate = function()
		if reentrancyGuard then
			return
		end
		reentrancyGuard = true
		wait()
		local success, err = nil
		if style == "grid" then
			success, err = pcall(function() layoutGridScrollBar() end)
		elseif style == "simple" then
			success, err = pcall(function() layoutSimpleScrollBar() end)
		end
		if not success then print(err) end
		moveDragger()
		reentrancyGuard = false
	end

	local doScrollUp = function()
		scrollPosition = (scrollPosition) - rowSize
		if scrollPosition < 1 then scrollPosition = 1 end
		recalculate(nil)
	end

	local doScrollDown = function()
		scrollPosition = (scrollPosition) + rowSize
		recalculate(nil)
	end

	local scrollUp = function(mouseYPos)
		if scrollUpButton.Active then
			scrollStamp = tick()
			local current = scrollStamp
			local upCon
			upCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				upCon:disconnect()
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
			doScrollUp()
			wait(0.2)
			local t = tick()
			local w = 0.1
			while scrollStamp == current do
				doScrollUp()
				if mouseYPos and mouseYPos > scrollDrag.AbsolutePosition.y then
					break
				end
				if not scrollUpButton.Active then break end
				if tick()-t > 5 then
					w = 0
				elseif tick()-t > 2 then
					w = 0.06
				end
				wait(w)
			end
		end
	end

	local scrollDown = function(mouseYPos)
		if scrollDownButton.Active then
			scrollStamp = tick()
			local current = scrollStamp
			local downCon
			downCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				downCon:disconnect()
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
			doScrollDown()
			wait(0.2)
			local t = tick()
			local w = 0.1
			while scrollStamp == current do
				doScrollDown()
				if mouseYPos and mouseYPos < (scrollDrag.AbsolutePosition.y + scrollDrag.AbsoluteSize.x) then
					break
				end
				if not scrollDownButton.Active then break end
				if tick()-t > 5 then
					w = 0
				elseif tick()-t > 2 then
					w = 0.06
				end
				wait(w)
			end
		end
	end

	local y = 0
	scrollDrag.MouseButton1Down:connect(function(x,y)
		if scrollDrag.Active then
			scrollStamp = tick()
			local mouseOffset = y - scrollDrag.AbsolutePosition.y
			local dragCon
			local upCon
			dragCon = mouseDrag.MouseMoved:connect(function(x,y)
				local barAbsPos = scrollbar.AbsolutePosition.y
				local barAbsSize = scrollbar.AbsoluteSize.y

				local dragAbsSize = scrollDrag.AbsoluteSize.y
				local barAbsOne = barAbsPos + barAbsSize - dragAbsSize
				y = y - mouseOffset
				y = y < barAbsPos and barAbsPos or y > barAbsOne and barAbsOne or y
				y = y - barAbsPos

				local guiObjects = 0
				local children = frame:GetChildren()
				if children then
					for i, child in ipairs(children) do 
						if child:IsA("GuiObject") then
							guiObjects = guiObjects + 1
						end
					end
				end

				local doublePercent = y/(barAbsSize-dragAbsSize)
				local rowDiff = rowSize
				local totalScrollCount = guiObjects - (howManyDisplayed - 1)
				local newScrollPosition = math.floor((doublePercent * totalScrollCount) + 0.5) + rowDiff
				if newScrollPosition < scrollPosition then
					rowDiff = -rowDiff
				end

				if newScrollPosition < 1 then
					newScrollPosition = 1
				end

				scrollPosition = newScrollPosition
				recalculate(nil)
			end)
			upCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				dragCon:disconnect(); dragCon = nil
				upCon:disconnect(); drag = nil
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
		end
	end)

	local scrollMouseCount = 0

	scrollUpButton.MouseButton1Down:connect(
		function()
			scrollUp()
		end)
	scrollUpButton.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)


	scrollDownButton.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)
	scrollDownButton.MouseButton1Down:connect(
		function()
			scrollDown()	
		end)

	scrollbar.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)
	scrollbar.MouseButton1Down:connect(
		function(x,y)
			if y > (scrollDrag.AbsoluteSize.y + scrollDrag.AbsolutePosition.y) then
				scrollDown(y)
			elseif y < (scrollDrag.AbsolutePosition.y) then
				scrollUp(y)
			end
		end)


	frame.ChildAdded:connect(function()
		recalculate(nil)
	end)

	frame.ChildRemoved:connect(function()
		recalculate(nil)
	end)

	frame.Changed:connect(
		function(prop)
			if prop == "AbsoluteSize" then
				--Wait a heartbeat for it to sync in
				recalculate(nil)
			end
		end)
	frame.AncestryChanged:connect(function() recalculate(nil) end)

	return frame, scrollUpButton, scrollDownButton, recalculate, scrollbar
end
local function binaryGrow(min, max, fits)
	if min > max then
		return min
	end
	local biggestLegal = min

	while min <= max do
		local mid = min + math.floor((max - min) / 2)
		if fits(mid) and (biggestLegal == nil or biggestLegal < mid) then
			biggestLegal = mid

			--Try growing
			min = mid + 1
		else
			--Doesn't fit, shrink
			max = mid - 1
		end
	end
	return biggestLegal
end


local function binaryShrink(min, max, fits)
	if min > max then
		return min
	end
	local smallestLegal = max

	while min <= max do
		local mid = min + math.floor((max - min) / 2)
		if fits(mid) and (smallestLegal == nil or smallestLegal > mid) then
			smallestLegal = mid

			--It fits, shrink
			max = mid - 1			
		else
			--Doesn't fit, grow
			min = mid + 1
		end
	end
	return smallestLegal
end


local function getGuiOwner(instance)
	while instance ~= nil do
		if instance:IsA("ScreenGui") or instance:IsA("BillboardGui")  then
			return instance
		end
		instance = instance.Parent
	end
	return nil
end

t.AutoTruncateTextObject = function(textLabel)
	local text = textLabel.Text

	local fullLabel = textLabel:Clone()
	fullLabel.Name = "Full" .. textLabel.Name 
	fullLabel.BorderSizePixel = 0
	fullLabel.BackgroundTransparency = 0
	fullLabel.Text = text
	fullLabel.TextXAlignment = Enum.TextXAlignment.Center
	fullLabel.Position = UDim2.new(0,-3,0,0)
	fullLabel.Size = UDim2.new(0,100,1,0)
	fullLabel.Visible = false
	fullLabel.Parent = textLabel

	local shortText = nil
	local mouseEnterConnection = nil
	local mouseLeaveConnection= nil

	local checkForResize = function()
		if getGuiOwner(textLabel) == nil then
			return
		end
		textLabel.Text = text
		if textLabel.TextFits then 
			--Tear down the rollover if it is active
			if mouseEnterConnection then
				mouseEnterConnection:disconnect()
				mouseEnterConnection = nil
			end
			if mouseLeaveConnection then
				mouseLeaveConnection:disconnect()
				mouseLeaveConnection = nil
			end
		else
			local len = string.len(text)
			textLabel.Text = text .. "~"

			--Shrink the text
			local textSize = binaryGrow(0, len, 
				function(pos)
					if pos == 0 then
						textLabel.Text = "~"
					else
						textLabel.Text = string.sub(text, 1, pos) .. "~"
					end
					return textLabel.TextFits
				end)
			shortText = string.sub(text, 1, textSize) .. "~"
			textLabel.Text = shortText

			--Make sure the fullLabel fits
			if not fullLabel.TextFits then
				--Already too small, grow it really bit to start
				fullLabel.Size = UDim2.new(0, 10000, 1, 0)
			end

			--Okay, now try to binary shrink it back down
			local fullLabelSize = binaryShrink(textLabel.AbsoluteSize.X,fullLabel.AbsoluteSize.X, 
				function(size)
					fullLabel.Size = UDim2.new(0, size, 1, 0)
					return fullLabel.TextFits
				end)
			fullLabel.Size = UDim2.new(0,fullLabelSize+6,1,0)

			--Now setup the rollover effects, if they are currently off
			if mouseEnterConnection == nil then
				mouseEnterConnection = textLabel.MouseEnter:connect(
					function()
						fullLabel.ZIndex = textLabel.ZIndex + 1
						fullLabel.Visible = true
						--textLabel.Text = ""
					end)
			end
			if mouseLeaveConnection == nil then
				mouseLeaveConnection = textLabel.MouseLeave:connect(
					function()
						fullLabel.Visible = false
						--textLabel.Text = shortText
					end)
			end
		end
	end
	textLabel.AncestryChanged:connect(checkForResize)
	textLabel.Changed:connect(
		function(prop) 
			if prop == "AbsoluteSize" then 
				checkForResize() 	
			end 
		end)

	checkForResize()

	local function changeText(newText)
		text = newText
		fullLabel.Text = text
		checkForResize()
	end

	return textLabel, changeText
end

local function TransitionTutorialPages(fromPage, toPage, transitionFrame, currentPageValue)	
	if fromPage then
		fromPage.Visible = false
		if transitionFrame.Visible == false then
			transitionFrame.Size = fromPage.Size
			transitionFrame.Position = fromPage.Position
		end
	else
		if transitionFrame.Visible == false then
			transitionFrame.Size = UDim2.new(0.0,50,0.0,50)
			transitionFrame.Position = UDim2.new(0.5,-25,0.5,-25)
		end
	end
	transitionFrame.Visible = true
	currentPageValue.Value = nil

	local newsize, newPosition
	if toPage then
		--Make it visible so it resizes
		toPage.Visible = true

		newSize = toPage.Size
		newPosition = toPage.Position

		toPage.Visible = false
	else
		newSize = UDim2.new(0.0,50,0.0,50)
		newPosition = UDim2.new(0.5,-25,0.5,-25)
	end
	transitionFrame:TweenSizeAndPosition(newSize, newPosition, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.3, true,
		function(state)
			if state == Enum.TweenStatus.Completed then
				transitionFrame.Visible = false
				if toPage then
					toPage.Visible = true
					currentPageValue.Value = toPage
				end
			end
		end)
end

t.CreateTutorial = function(name, tutorialKey, createButtons)
	local frame = Instance.new("Frame")
	frame.Name = "Tutorial-" .. name
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(0.6, 0, 0.6, 0)
	frame.Position = UDim2.new(0.2, 0, 0.2, 0)

	local transitionFrame = Instance.new("Frame")
	transitionFrame.Name = "TransitionFrame"
	transitionFrame.Style = Enum.FrameStyle.RobloxRound
	transitionFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
	transitionFrame.Position = UDim2.new(0.2, 0, 0.2, 0)
	transitionFrame.Visible = false
	transitionFrame.Parent = frame

	local currentPageValue = Instance.new("ObjectValue")
	currentPageValue.Name = "CurrentTutorialPage"
	currentPageValue.Value = nil
	currentPageValue.Parent = frame

	local boolValue = Instance.new("BoolValue")
	boolValue.Name = "Buttons"
	boolValue.Value = createButtons
	boolValue.Parent = frame

	local pages = Instance.new("Frame")
	pages.Name = "Pages"
	pages.BackgroundTransparency = 1
	pages.Size = UDim2.new(1,0,1,0)
	pages.Parent = frame

	local function getVisiblePageAndHideOthers()
		local visiblePage = nil
		local children = pages:GetChildren()
		if children then
			for i,child in ipairs(children) do
				if child.Visible then
					if visiblePage then
						child.Visible = false
					else
						visiblePage = child
					end
				end
			end
		end
		return visiblePage
	end

	local showTutorial = function(alwaysShow)
		if alwaysShow or UserSettings().GameSettings:GetTutorialState(tutorialKey) == false then
			print("Showing tutorial-",tutorialKey)
			local currentTutorialPage = getVisiblePageAndHideOthers()

			local firstPage = pages:FindFirstChild("TutorialPage1")
			if firstPage then
				TransitionTutorialPages(currentTutorialPage, firstPage, transitionFrame, currentPageValue)	
			else
				error("Could not find TutorialPage1")
			end
		end
	end

	local dismissTutorial = function()
		local currentTutorialPage = getVisiblePageAndHideOthers()

		if currentTutorialPage then
			TransitionTutorialPages(currentTutorialPage, nil, transitionFrame, currentPageValue)
		end

		UserSettings().GameSettings:SetTutorialState(tutorialKey, true)
	end

	local gotoPage = function(pageNum)
		local page = pages:FindFirstChild("TutorialPage" .. pageNum)
		local currentTutorialPage = getVisiblePageAndHideOthers()
		TransitionTutorialPages(currentTutorialPage, page, transitionFrame, currentPageValue)
	end

	return frame, showTutorial, dismissTutorial, gotoPage
end 

local function CreateBasicTutorialPage(name, handleResize, skipTutorial, giveDoneButton)
	local frame = Instance.new("Frame")
	frame.Name = "TutorialPage"
	frame.Style = Enum.FrameStyle.RobloxRound
	frame.Size = UDim2.new(0.6, 0, 0.6, 0)
	frame.Position = UDim2.new(0.2, 0, 0.2, 0)
	frame.Visible = false

	local frameHeader = Instance.new("TextLabel")
	frameHeader.Name = "Header"
	frameHeader.Text = name
	frameHeader.BackgroundTransparency = 1
	frameHeader.FontSize = Enum.FontSize.Size24
	frameHeader.Font = Enum.Font.ArialBold
	frameHeader.TextColor3 = Color3.new(1,1,1)
	frameHeader.TextXAlignment = Enum.TextXAlignment.Center
	frameHeader.TextWrap = true
	frameHeader.Size = UDim2.new(1,-55, 0, 22)
	frameHeader.Position = UDim2.new(0,0,0,0)
	frameHeader.Parent = frame

	local skipButton = Instance.new("ImageButton")
	skipButton.Name = "SkipButton"
	skipButton.AutoButtonColor = false
	skipButton.BackgroundTransparency = 1
	skipButton.Image = "rbxasset://textures/ui/closeButton.png"
	skipButton.MouseButton1Click:connect(function()
		skipTutorial()
	end)
	skipButton.MouseEnter:connect(function()
		skipButton.Image = "rbxasset://textures/ui/closeButton_dn.png"
	end)
	skipButton.MouseLeave:connect(function()
		skipButton.Image = "rbxasset://textures/ui/closeButton.png"
	end)
	skipButton.Size = UDim2.new(0, 25, 0, 25)
	skipButton.Position = UDim2.new(1, -25, 0, 0)
	skipButton.Parent = frame


	if giveDoneButton then
		local doneButton = Instance.new("TextButton")
		doneButton.Name = "DoneButton"
		doneButton.Style = Enum.ButtonStyle.RobloxButtonDefault
		doneButton.Text = "Done"
		doneButton.TextColor3 = Color3.new(1,1,1)
		doneButton.Font = Enum.Font.ArialBold
		doneButton.FontSize = Enum.FontSize.Size18
		doneButton.Size = UDim2.new(0,100,0,50)
		doneButton.Position = UDim2.new(0.5,-50,1,-50)

		if skipTutorial then
			doneButton.MouseButton1Click:connect(function() skipTutorial() end)
		end

		doneButton.Parent = frame
	end

	local innerFrame = Instance.new("Frame")
	innerFrame.Name = "ContentFrame"
	innerFrame.BackgroundTransparency = 1
	innerFrame.Position = UDim2.new(0,0,0,25)
	innerFrame.Parent = frame

	local nextButton = Instance.new("TextButton")
	nextButton.Name = "NextButton"
	nextButton.Text = "Next"
	nextButton.TextColor3 = Color3.new(1,1,1)
	nextButton.Font = Enum.Font.Arial
	nextButton.FontSize = Enum.FontSize.Size18
	nextButton.Style = Enum.ButtonStyle.RobloxButtonDefault
	nextButton.Size = UDim2.new(0,80, 0, 32)
	nextButton.Position = UDim2.new(0.5, 5, 1, -32)
	nextButton.Active = false
	nextButton.Visible = false
	nextButton.Parent = frame

	local prevButton = Instance.new("TextButton")
	prevButton.Name = "PrevButton"
	prevButton.Text = "Previous"
	prevButton.TextColor3 = Color3.new(1,1,1)
	prevButton.Font = Enum.Font.Arial
	prevButton.FontSize = Enum.FontSize.Size18
	prevButton.Style = Enum.ButtonStyle.RobloxButton
	prevButton.Size = UDim2.new(0,80, 0, 32)
	prevButton.Position = UDim2.new(0.5, -85, 1, -32)
	prevButton.Active = false
	prevButton.Visible = false
	prevButton.Parent = frame

	if giveDoneButton then
		innerFrame.Size = UDim2.new(1,0,1,-75)
	else
		innerFrame.Size = UDim2.new(1,0,1,-22)
	end

	local parentConnection = nil

	local function basicHandleResize()
		if frame.Visible and frame.Parent then
			local maxSize = math.min(frame.Parent.AbsoluteSize.X, frame.Parent.AbsoluteSize.Y)
			handleResize(200,maxSize)
		end
	end

	frame.Changed:connect(
		function(prop)
			if prop == "Parent" then
				if parentConnection ~= nil then
					parentConnection:disconnect()
					parentConnection = nil
				end
				if frame.Parent and frame.Parent:IsA("GuiObject") then
					parentConnection = frame.Parent.Changed:connect(
						function(parentProp)
							if parentProp == "AbsoluteSize" then
								wait()
								basicHandleResize()
							end
						end)
					basicHandleResize()
				end
			end

			if prop == "Visible" then 
				basicHandleResize()
			end
		end)

	return frame, innerFrame
end

t.CreateTextTutorialPage = function(name, text, skipTutorialFunc)
	local frame = nil
	local contentFrame = nil

	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1,1,1)
	textLabel.Text = text
	textLabel.TextWrap = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.Font = Enum.Font.Arial
	textLabel.FontSize = Enum.FontSize.Size14
	textLabel.Size = UDim2.new(1,0,1,0)

	local function handleResize(minSize, maxSize)
		size = binaryShrink(minSize, maxSize,
			function(size)
				frame.Size = UDim2.new(0, size, 0, size)
				return textLabel.TextFits
			end)
		frame.Size = UDim2.new(0, size, 0, size)
		frame.Position = UDim2.new(0.5, -size/2, 0.5, -size/2)
	end

	frame, contentFrame = CreateBasicTutorialPage(name, handleResize, skipTutorialFunc)
	textLabel.Parent = contentFrame

	return frame
end

t.CreateImageTutorialPage = function(name, imageAsset, x, y, skipTutorialFunc, giveDoneButton)
	local frame = nil
	local contentFrame = nil

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = imageAsset
	imageLabel.Size = UDim2.new(0,x,0,y)
	imageLabel.Position = UDim2.new(0.5,-x/2,0.5,-y/2)

	local function handleResize(minSize, maxSize)
		size = binaryShrink(minSize, maxSize,
			function(size)
				return size >= x and size >= y
			end)
		if size >= x and size >= y then
			imageLabel.Size = UDim2.new(0,x, 0,y)
			imageLabel.Position = UDim2.new(0.5,-x/2, 0.5, -y/2)
		else
			if x > y then
				--X is limiter, so 
				imageLabel.Size = UDim2.new(1,0,y/x,0)
				imageLabel.Position = UDim2.new(0,0, 0.5 - (y/x)/2, 0)
			else
				--Y is limiter
				imageLabel.Size = UDim2.new(x/y,0,1, 0)
				imageLabel.Position = UDim2.new(0.5-(x/y)/2, 0, 0, 0)
			end
		end
		size = size + 50
		frame.Size = UDim2.new(0, size, 0, size)
		frame.Position = UDim2.new(0.5, -size/2, 0.5, -size/2)
	end

	frame, contentFrame = CreateBasicTutorialPage(name, handleResize, skipTutorialFunc, giveDoneButton)
	imageLabel.Parent = contentFrame

	return frame
end

t.AddTutorialPage = function(tutorial, tutorialPage)
	local transitionFrame = tutorial.TransitionFrame
	local currentPageValue = tutorial.CurrentTutorialPage

	if not tutorial.Buttons.Value then
		tutorialPage.NextButton.Parent = nil
		tutorialPage.PrevButton.Parent = nil
	end

	local children = tutorial.Pages:GetChildren()
	if children and #children > 0 then
		tutorialPage.Name = "TutorialPage" .. (#children+1)
		local previousPage = children[#children]
		if not previousPage:IsA("GuiObject") then
			error("All elements under Pages must be GuiObjects")
		end

		if tutorial.Buttons.Value then
			if previousPage.NextButton.Active then
				error("NextButton already Active on previousPage, please only add pages with RbxGui.AddTutorialPage function")
			end
			previousPage.NextButton.MouseButton1Click:connect(
				function()
					TransitionTutorialPages(previousPage, tutorialPage, transitionFrame, currentPageValue)
				end)
			previousPage.NextButton.Active = true
			previousPage.NextButton.Visible = true

			if tutorialPage.PrevButton.Active then
				error("PrevButton already Active on tutorialPage, please only add pages with RbxGui.AddTutorialPage function")
			end
			tutorialPage.PrevButton.MouseButton1Click:connect(
				function()
					TransitionTutorialPages(tutorialPage, previousPage, transitionFrame, currentPageValue)
				end)
			tutorialPage.PrevButton.Active = true
			tutorialPage.PrevButton.Visible = true
		end

		tutorialPage.Parent = tutorial.Pages
	else
		--First child
		tutorialPage.Name = "TutorialPage1"
		tutorialPage.Parent = tutorial.Pages
	end
end 

t.CreateSetPanel = function(userIdsForSets, objectSelected, dialogClosed, size, position, showAdminCategories, useAssetVersionId)

	if not userIdsForSets then
		error("CreateSetPanel: userIdsForSets (first arg) is nil, should be a table of number ids")
	end
	if type(userIdsForSets) ~= "table" and type(userIdsForSets) ~= "userdata" then
		error("CreateSetPanel: userIdsForSets (first arg) is of type " ..type(userIdsForSets) .. ", should be of type table or userdata")
	end
	if not objectSelected then
		error("CreateSetPanel: objectSelected (second arg) is nil, should be a callback function!")
	end
	if type(objectSelected) ~= "function" then
		error("CreateSetPanel: objectSelected (second arg) is of type " .. type(objectSelected) .. ", should be of type function!")
	end
	if dialogClosed and type(dialogClosed) ~= "function" then
		error("CreateSetPanel: dialogClosed (third arg) is of type " .. type(dialogClosed) .. ", should be of type function!")
	end

	if showAdminCategories == nil then -- by default, don't show beta sets
		showAdminCategories = false
	end

	local arrayPosition = 1
	local insertButtons = {}
	local insertButtonCons = {}
	local contents = nil
	local setGui = nil

	-- used for water selections
	local waterForceDirection = "NegX"
	local waterForce = "None"
	local waterGui, waterTypeChangedEvent = nil

	local Data = {}
	Data.CurrentCategory = nil
	Data.Category = {}
	local SetCache = {}

	local userCategoryButtons = nil

	local buttonWidth = 64
	local buttonHeight = buttonWidth

	local SmallThumbnailUrl = nil
	local LargeThumbnailUrl = nil
	local BaseUrl = game:GetService("ContentProvider").BaseUrl:lower()

	if useAssetVersionId then
		LargeThumbnailUrl = BaseUrl .. "Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=420&ht=420&assetversionid="
		SmallThumbnailUrl = BaseUrl .. "Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=75&ht=75&assetversionid="
	else
		LargeThumbnailUrl = BaseUrl .. "Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=420&ht=420&aid="
		SmallThumbnailUrl = BaseUrl .. "Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=75&ht=75&aid="
	end

	local function drillDownSetZIndex(parent, index)
		local children = parent:GetChildren()
		for i = 1, #children do
			if children[i]:IsA("GuiObject") then
				children[i].ZIndex = index
			end
			drillDownSetZIndex(children[i], index)
		end
	end

	-- for terrain stamping
	local currTerrainDropDownFrame = nil
	local terrainShapes = {"Block","Vertical Ramp","Corner Wedge","Inverse Corner Wedge","Horizontal Ramp","Auto-Wedge"}
	local terrainShapeMap = {}
	for i = 1, #terrainShapes do
		terrainShapeMap[terrainShapes[i]] = i - 1
	end	
	terrainShapeMap[terrainShapes[#terrainShapes]] = 6

	local function createWaterGui()
		local waterForceDirections = {"NegX","X","NegY","Y","NegZ","Z"}
		local waterForces = {"None", "Small", "Medium", "Strong", "Max"}

		local waterFrame = Instance.new("Frame")
		waterFrame.Name = "WaterFrame"
		waterFrame.Style = Enum.FrameStyle.RobloxSquare
		waterFrame.Size = UDim2.new(0,150,0,110)
		waterFrame.Visible = false

		local waterForceLabel = Instance.new("TextLabel")
		waterForceLabel.Name = "WaterForceLabel"
		waterForceLabel.BackgroundTransparency = 1
		waterForceLabel.Size = UDim2.new(1,0,0,12)
		waterForceLabel.Font = Enum.Font.ArialBold
		waterForceLabel.FontSize = Enum.FontSize.Size12
		waterForceLabel.TextColor3 = Color3.new(1,1,1)
		waterForceLabel.TextXAlignment = Enum.TextXAlignment.Left
		waterForceLabel.Text = "Water Force"
		waterForceLabel.Parent = waterFrame

		local waterForceDirLabel = waterForceLabel:Clone()
		waterForceDirLabel.Name = "WaterForceDirectionLabel"
		waterForceDirLabel.Text = "Water Force Direction"
		waterForceDirLabel.Position = UDim2.new(0,0,0,50)
		waterForceDirLabel.Parent = waterFrame

		local waterTypeChangedEvent = Instance.new("BindableEvent",waterFrame)
		waterTypeChangedEvent.Name = "WaterTypeChangedEvent"

		local waterForceDirectionSelectedFunc = function(newForceDirection)
			waterForceDirection = newForceDirection
			waterTypeChangedEvent:Fire({waterForce, waterForceDirection})
		end
		local waterForceSelectedFunc = function(newForce)
			waterForce = newForce
			waterTypeChangedEvent:Fire({waterForce, waterForceDirection})
		end

		local waterForceDirectionDropDown, forceWaterDirectionSelection = t.CreateDropDownMenu(waterForceDirections, waterForceDirectionSelectedFunc)
		waterForceDirectionDropDown.Size = UDim2.new(1,0,0,25)
		waterForceDirectionDropDown.Position = UDim2.new(0,0,1,3)
		forceWaterDirectionSelection("NegX")
		waterForceDirectionDropDown.Parent = waterForceDirLabel

		local waterForceDropDown, forceWaterForceSelection = t.CreateDropDownMenu(waterForces, waterForceSelectedFunc)
		forceWaterForceSelection("None")
		waterForceDropDown.Size = UDim2.new(1,0,0,25)
		waterForceDropDown.Position = UDim2.new(0,0,1,3)
		waterForceDropDown.Parent = waterForceLabel

		return waterFrame, waterTypeChangedEvent
	end

	-- Helper Function that contructs gui elements
	local function createSetGui()

		local setGui = Instance.new("ScreenGui")
		setGui.Name = "SetGui"

		local setPanel = Instance.new("Frame")
		setPanel.Name = "SetPanel"
		setPanel.Active = true
		setPanel.BackgroundTransparency = 1
		if position then
			setPanel.Position = position
		else
			setPanel.Position = UDim2.new(0.2, 29, 0.1, 24)
		end
		if size then
			setPanel.Size = size
		else
			setPanel.Size = UDim2.new(0.6, -58, 0.64, 0)
		end
		setPanel.Style = Enum.FrameStyle.RobloxRound
		setPanel.ZIndex = 6
		setPanel.Parent = setGui

		-- Children of SetPanel
		local itemPreview = Instance.new("Frame")
		itemPreview.Name = "ItemPreview"
		itemPreview.BackgroundTransparency = 1
		itemPreview.Position = UDim2.new(0.8,5,0.085,0)
		itemPreview.Size = UDim2.new(0.21,0,0.9,0)
		itemPreview.ZIndex = 6
		itemPreview.Parent = setPanel

		-- Children of ItemPreview
		local textPanel = Instance.new("Frame")
		textPanel.Name = "TextPanel"
		textPanel.BackgroundTransparency = 1
		textPanel.Position = UDim2.new(0,0,0.45,0)
		textPanel.Size = UDim2.new(1,0,0.55,0)
		textPanel.ZIndex = 6
		textPanel.Parent = itemPreview

		-- Children of TextPanel
		local rolloverText = Instance.new("TextLabel")
		rolloverText.Name = "RolloverText"
		rolloverText.BackgroundTransparency = 1
		rolloverText.Size = UDim2.new(1,0,0,48)
		rolloverText.ZIndex = 6
		rolloverText.Font = Enum.Font.ArialBold
		rolloverText.FontSize = Enum.FontSize.Size24
		rolloverText.Text = ""
		rolloverText.TextColor3 = Color3.new(1,1,1)
		rolloverText.TextWrap = true
		rolloverText.TextXAlignment = Enum.TextXAlignment.Left
		rolloverText.TextYAlignment = Enum.TextYAlignment.Top
		rolloverText.Parent = textPanel

		local largePreview = Instance.new("ImageLabel")
		largePreview.Name = "LargePreview"
		largePreview.BackgroundTransparency = 1
		largePreview.Image = ""
		largePreview.Size = UDim2.new(1,0,0,170)
		largePreview.ZIndex = 6
		largePreview.Parent = itemPreview

		local sets = Instance.new("Frame")
		sets.Name = "Sets"
		sets.BackgroundTransparency = 1
		sets.Position = UDim2.new(0,0,0,5)
		sets.Size = UDim2.new(0.23,0,1,-5)
		sets.ZIndex = 6
		sets.Parent = setPanel

		-- Children of Sets
		local line = Instance.new("Frame")
		line.Name = "Line"
		line.BackgroundColor3 = Color3.new(1,1,1)
		line.BackgroundTransparency = 0.7
		line.BorderSizePixel = 0
		line.Position = UDim2.new(1,-3,0.06,0)
		line.Size = UDim2.new(0,3,0.9,0)
		line.ZIndex = 6
		line.Parent = sets

		local setsLists, controlFrame = t.CreateTrueScrollingFrame()
		setsLists.Size = UDim2.new(1,-6,0.94,0)
		setsLists.Position = UDim2.new(0,0,0.06,0)
		setsLists.BackgroundTransparency = 1
		setsLists.Name = "SetsLists"
		setsLists.ZIndex = 6
		setsLists.Parent = sets
		drillDownSetZIndex(controlFrame, 7)

		local setsHeader = Instance.new("TextLabel")
		setsHeader.Name = "SetsHeader"
		setsHeader.BackgroundTransparency = 1
		setsHeader.Size = UDim2.new(0,47,0,24)
		setsHeader.ZIndex = 6
		setsHeader.Font = Enum.Font.ArialBold
		setsHeader.FontSize = Enum.FontSize.Size24
		setsHeader.Text = "Sets"
		setsHeader.TextColor3 = Color3.new(1,1,1)
		setsHeader.TextXAlignment = Enum.TextXAlignment.Left
		setsHeader.TextYAlignment = Enum.TextYAlignment.Top
		setsHeader.Parent = sets

		local cancelButton = Instance.new("TextButton")
		cancelButton.Name = "CancelButton"
		cancelButton.Position = UDim2.new(1,-32,0,-2)
		cancelButton.Size = UDim2.new(0,34,0,34)
		cancelButton.Style = Enum.ButtonStyle.RobloxButtonDefault
		cancelButton.ZIndex = 6
		cancelButton.Text = ""
		cancelButton.Modal = true
		cancelButton.Parent = setPanel

		-- Children of Cancel Button
		local cancelImage = Instance.new("ImageLabel")
		cancelImage.Name = "CancelImage"
		cancelImage.BackgroundTransparency = 1
		cancelImage.Image = "http://www.roblox.com/asset/?id=54135717"
		cancelImage.Position = UDim2.new(0,-2,0,-2)
		cancelImage.Size = UDim2.new(0,16,0,16)
		cancelImage.ZIndex = 6
		cancelImage.Parent = cancelButton

		return setGui
	end

	local function createSetButton(text)
		local setButton = Instance.new("TextButton")

		if text then setButton.Text = text
		else setButton.Text = "" end

		setButton.AutoButtonColor = false
		setButton.BackgroundTransparency = 1
		setButton.BackgroundColor3 = Color3.new(1,1,1)
		setButton.BorderSizePixel = 0
		setButton.Size = UDim2.new(1,-5,0,18)
		setButton.ZIndex = 6
		setButton.Visible = false
		setButton.Font = Enum.Font.Arial
		setButton.FontSize = Enum.FontSize.Size18
		setButton.TextColor3 = Color3.new(1,1,1)
		setButton.TextXAlignment = Enum.TextXAlignment.Left

		return setButton
	end

	local function buildSetButton(name, setId, setImageId, i,  count)
		local button = createSetButton(name)
		button.Text = name
		button.Name = "SetButton"
		button.Visible = true

		local setValue = Instance.new("IntValue")
		setValue.Name = "SetId"
		setValue.Value = setId
		setValue.Parent = button

		local setName = Instance.new("StringValue")
		setName.Name = "SetName"
		setName.Value = name
		setName.Parent = button

		return button
	end

	local function processCategory(sets)
		local setButtons = {}
		local numSkipped = 0
		for i = 1, #sets do
			if not showAdminCategories and sets[i].Name == "Beta" then
				numSkipped = numSkipped + 1
			else
				setButtons[i - numSkipped] = buildSetButton(sets[i].Name, sets[i].CategoryId, sets[i].ImageAssetId, i - numSkipped, #sets)
			end
		end
		return setButtons
	end

	local function handleResize()
		wait() -- neccessary to insure heartbeat happened

		local itemPreview = setGui.SetPanel.ItemPreview

		itemPreview.LargePreview.Size = UDim2.new(1,0,0,itemPreview.AbsoluteSize.X)
		itemPreview.LargePreview.Position = UDim2.new(0.5,-itemPreview.LargePreview.AbsoluteSize.X/2,0,0)
		itemPreview.TextPanel.Position = UDim2.new(0,0,0,itemPreview.LargePreview.AbsoluteSize.Y)
		itemPreview.TextPanel.Size = UDim2.new(1,0,0,itemPreview.AbsoluteSize.Y - itemPreview.LargePreview.AbsoluteSize.Y)
	end

	local function makeInsertAssetButton()
		local insertAssetButtonExample = Instance.new("Frame")
		insertAssetButtonExample.Name = "InsertAssetButtonExample"
		insertAssetButtonExample.Position = UDim2.new(0,128,0,64)
		insertAssetButtonExample.Size = UDim2.new(0,64,0,64)
		insertAssetButtonExample.BackgroundTransparency = 1
		insertAssetButtonExample.ZIndex = 6
		insertAssetButtonExample.Visible = false

		local assetId = Instance.new("IntValue")
		assetId.Name = "AssetId"
		assetId.Value = 0
		assetId.Parent = insertAssetButtonExample

		local assetName = Instance.new("StringValue")
		assetName.Name = "AssetName"
		assetName.Value = ""
		assetName.Parent = insertAssetButtonExample

		local button = Instance.new("TextButton")
		button.Name = "Button"
		button.Text = ""
		button.Style = Enum.ButtonStyle.RobloxButton
		button.Position = UDim2.new(0.025,0,0.025,0)
		button.Size = UDim2.new(0.95,0,0.95,0)
		button.ZIndex = 6
		button.Parent = insertAssetButtonExample

		local buttonImage = Instance.new("ImageLabel")
		buttonImage.Name = "ButtonImage"
		buttonImage.Image = ""
		buttonImage.Position = UDim2.new(0,-7,0,-7)
		buttonImage.Size = UDim2.new(1,14,1,14)
		buttonImage.BackgroundTransparency = 1
		buttonImage.ZIndex = 7
		buttonImage.Parent = button

		local configIcon = buttonImage:clone()
		configIcon.Name = "ConfigIcon"
		configIcon.Visible = false
		configIcon.Position = UDim2.new(1,-23,1,-24)
		configIcon.Size = UDim2.new(0,16,0,16)
		configIcon.Image = ""
		configIcon.ZIndex = 6
		configIcon.Parent = insertAssetButtonExample

		return insertAssetButtonExample
	end

	local function showLargePreview(insertButton)
		if insertButton:FindFirstChild("AssetId") then
			delay(0,function()
				game:GetService("ContentProvider"):Preload(LargeThumbnailUrl .. tostring(insertButton.AssetId.Value))
				setGui.SetPanel.ItemPreview.LargePreview.Image = LargeThumbnailUrl .. tostring(insertButton.AssetId.Value)
			end)
		end
		if insertButton:FindFirstChild("AssetName") then
			setGui.SetPanel.ItemPreview.TextPanel.RolloverText.Text = insertButton.AssetName.Value
		end
	end

	local function selectTerrainShape(shape)
		if currTerrainDropDownFrame then
			objectSelected(tostring(currTerrainDropDownFrame.AssetName.Value), tonumber(currTerrainDropDownFrame.AssetId.Value), shape)
		end
	end

	local function createTerrainTypeButton(name, parent)
		local dropDownTextButton = Instance.new("TextButton")
		dropDownTextButton.Name = name .. "Button"
		dropDownTextButton.Font = Enum.Font.ArialBold
		dropDownTextButton.FontSize = Enum.FontSize.Size14
		dropDownTextButton.BorderSizePixel = 0
		dropDownTextButton.TextColor3 = Color3.new(1,1,1)
		dropDownTextButton.Text = name
		dropDownTextButton.TextXAlignment = Enum.TextXAlignment.Left
		dropDownTextButton.BackgroundTransparency = 1
		dropDownTextButton.ZIndex = parent.ZIndex + 1
		dropDownTextButton.Size = UDim2.new(0,parent.Size.X.Offset - 2,0,16)
		dropDownTextButton.Position = UDim2.new(0,1,0,0)

		dropDownTextButton.MouseEnter:connect(function()
			dropDownTextButton.BackgroundTransparency = 0
			dropDownTextButton.TextColor3 = Color3.new(0,0,0)
		end)

		dropDownTextButton.MouseLeave:connect(function()
			dropDownTextButton.BackgroundTransparency = 1
			dropDownTextButton.TextColor3 = Color3.new(1,1,1)
		end)

		dropDownTextButton.MouseButton1Click:connect(function()
			dropDownTextButton.BackgroundTransparency = 1
			dropDownTextButton.TextColor3 = Color3.new(1,1,1)
			if dropDownTextButton.Parent and dropDownTextButton.Parent:IsA("GuiObject") then
				dropDownTextButton.Parent.Visible = false
			end
			selectTerrainShape(terrainShapeMap[dropDownTextButton.Text])
		end)

		return dropDownTextButton
	end

	local function createTerrainDropDownMenu(zIndex)
		local dropDown = Instance.new("Frame")
		dropDown.Name = "TerrainDropDown"
		dropDown.BackgroundColor3 = Color3.new(0,0,0)
		dropDown.BorderColor3 = Color3.new(1,0,0)
		dropDown.Size = UDim2.new(0,200,0,0)
		dropDown.Visible = false
		dropDown.ZIndex = zIndex
		dropDown.Parent = setGui

		for i = 1, #terrainShapes do
			local shapeButton = createTerrainTypeButton(terrainShapes[i],dropDown)
			shapeButton.Position = UDim2.new(0,1,0,(i - 1) * (shapeButton.Size.Y.Offset))
			shapeButton.Parent = dropDown
			dropDown.Size = UDim2.new(0,200,0,dropDown.Size.Y.Offset + (shapeButton.Size.Y.Offset))
		end

		dropDown.MouseLeave:connect(function()
			dropDown.Visible = false
		end)
	end


	local function createDropDownMenuButton(parent)
		local dropDownButton = Instance.new("ImageButton")
		dropDownButton.Name = "DropDownButton"
		dropDownButton.Image = "http://www.roblox.com/asset/?id=67581509"
		dropDownButton.BackgroundTransparency = 1
		dropDownButton.Size = UDim2.new(0,16,0,16)
		dropDownButton.Position = UDim2.new(1,-24,0,6)
		dropDownButton.ZIndex = parent.ZIndex + 2
		dropDownButton.Parent = parent

		if not setGui:FindFirstChild("TerrainDropDown") then
			createTerrainDropDownMenu(8)
		end

		dropDownButton.MouseButton1Click:connect(function()
			setGui.TerrainDropDown.Visible = true
			setGui.TerrainDropDown.Position = UDim2.new(0,parent.AbsolutePosition.X,0,parent.AbsolutePosition.Y)
			currTerrainDropDownFrame = parent
		end)
	end

	local function buildInsertButton()
		local insertButton = makeInsertAssetButton()
		insertButton.Name = "InsertAssetButton"
		insertButton.Visible = true

		if Data.Category[Data.CurrentCategory].SetName == "High Scalability" then
			createDropDownMenuButton(insertButton)
		end

		local lastEnter = nil
		local mouseEnterCon = insertButton.MouseEnter:connect(function()
			lastEnter = insertButton
			delay(0.1,function()
				if lastEnter == insertButton then
					showLargePreview(insertButton)
				end
			end)
		end)
		return insertButton, mouseEnterCon
	end

	local function realignButtonGrid(columns)
		local x = 0
		local y = 0 
		for i = 1, #insertButtons do
			insertButtons[i].Position = UDim2.new(0, buttonWidth * x, 0, buttonHeight * y)
			x = x + 1
			if x >= columns then
				x = 0
				y = y + 1
			end
		end
	end

	local function setInsertButtonImageBehavior(insertFrame, visible, name, assetId)
		if visible then
			insertFrame.AssetName.Value = name
			insertFrame.AssetId.Value = assetId
			local newImageUrl = SmallThumbnailUrl  .. assetId
			if newImageUrl ~= insertFrame.Button.ButtonImage.Image then
				delay(0,function()
					game:GetService("ContentProvider"):Preload(SmallThumbnailUrl  .. assetId)
					if insertFrame:findFirstChild("Button") then
						insertFrame.Button.ButtonImage.Image = SmallThumbnailUrl  .. assetId
					end
				end)
			end
			table.insert(insertButtonCons,
				insertFrame.Button.MouseButton1Click:connect(function()
					-- special case for water, show water selection gui
					local isWaterSelected = (name == "Water") and (Data.Category[Data.CurrentCategory].SetName == "High Scalability")
					waterGui.Visible = isWaterSelected
					if isWaterSelected then
						objectSelected(name, tonumber(assetId), nil)
					else
						objectSelected(name, tonumber(assetId))
					end
				end)
			)
			insertFrame.Visible = true
		else
			insertFrame.Visible = false
		end
	end

	local function loadSectionOfItems(setGui, rows, columns)
		local pageSize = rows * columns

		if arrayPosition > #contents then return end

		local origArrayPos = arrayPosition

		local yCopy = 0
		for i = 1, pageSize + 1 do 
			if arrayPosition >= #contents + 1 then
				break
			end

			local buttonCon
			insertButtons[arrayPosition], buttonCon = buildInsertButton()
			table.insert(insertButtonCons,buttonCon)
			insertButtons[arrayPosition].Parent = setGui.SetPanel.ItemsFrame
			arrayPosition = arrayPosition + 1
		end
		realignButtonGrid(columns)

		local indexCopy = origArrayPos
		for index = origArrayPos, arrayPosition do
			if insertButtons[index] then
				if contents[index] then

					-- we don't want water to have a drop down button
					if contents[index].Name == "Water" then
						if Data.Category[Data.CurrentCategory].SetName == "High Scalability" then
							insertButtons[index]:FindFirstChild("DropDownButton",true):Destroy()
						end
					end

					local assetId
					if useAssetVersionId then
						assetId = contents[index].AssetVersionId
					else
						assetId = contents[index].AssetId
					end
					setInsertButtonImageBehavior(insertButtons[index], true, contents[index].Name, assetId)
				else
					break
				end
			else
				break
			end
			indexCopy = index
		end
	end

	local function setSetIndex()
		Data.Category[Data.CurrentCategory].Index = 0

		rows = 7
		columns = math.floor(setGui.SetPanel.ItemsFrame.AbsoluteSize.X/buttonWidth)

		contents = Data.Category[Data.CurrentCategory].Contents
		if contents then
			-- remove our buttons and their connections
			for i = 1, #insertButtons do
				insertButtons[i]:remove()
			end
			for i = 1, #insertButtonCons do
				if insertButtonCons[i] then insertButtonCons[i]:disconnect() end
			end
			insertButtonCons = {}
			insertButtons = {}

			arrayPosition = 1
			loadSectionOfItems(setGui, rows, columns)
		end
	end

	local function selectSet(button, setName, setId, setIndex)
		if button and Data.Category[Data.CurrentCategory] ~= nil then
			if button ~= Data.Category[Data.CurrentCategory].Button then
				Data.Category[Data.CurrentCategory].Button = button

				if SetCache[setId] == nil then
					SetCache[setId] = game:GetService("InsertService"):GetCollection(setId)
				end
				Data.Category[Data.CurrentCategory].Contents = SetCache[setId]

				Data.Category[Data.CurrentCategory].SetName = setName
				Data.Category[Data.CurrentCategory].SetId = setId
			end
			setSetIndex()
		end
	end

	local function selectCategoryPage(buttons, page)
		if buttons ~= Data.CurrentCategory then
			if Data.CurrentCategory then
				for key, button in pairs(Data.CurrentCategory) do
					button.Visible = false
				end
			end

			Data.CurrentCategory = buttons
			if Data.Category[Data.CurrentCategory] == nil then
				Data.Category[Data.CurrentCategory] = {}
				if #buttons > 0 then
					selectSet(buttons[1], buttons[1].SetName.Value, buttons[1].SetId.Value, 0)
				end
			else
				Data.Category[Data.CurrentCategory].Button = nil
				selectSet(Data.Category[Data.CurrentCategory].ButtonFrame, Data.Category[Data.CurrentCategory].SetName, Data.Category[Data.CurrentCategory].SetId, Data.Category[Data.CurrentCategory].Index)
			end
		end
	end

	local function selectCategory(category)
		selectCategoryPage(category, 0)
	end

	local function resetAllSetButtonSelection()
		local setButtons = setGui.SetPanel.Sets.SetsLists:GetChildren()
		for i = 1, #setButtons do
			if setButtons[i]:IsA("TextButton") then
				setButtons[i].Selected = false
				setButtons[i].BackgroundTransparency = 1
				setButtons[i].TextColor3 = Color3.new(1,1,1)
				setButtons[i].BackgroundColor3 = Color3.new(1,1,1)
			end
		end
	end

	local function populateSetsFrame()
		local currRow = 0
		for i = 1, #userCategoryButtons do
			local button = userCategoryButtons[i]
			button.Visible = true
			button.Position = UDim2.new(0,5,0,currRow * button.Size.Y.Offset)
			button.Parent = setGui.SetPanel.Sets.SetsLists

			if i == 1 then -- we will have this selected by default, so show it
				button.Selected = true
				button.BackgroundColor3 = Color3.new(0,204/255,0)
				button.TextColor3 = Color3.new(0,0,0)
				button.BackgroundTransparency = 0
			end

			button.MouseEnter:connect(function()
				if not button.Selected then
					button.BackgroundTransparency = 0
					button.TextColor3 = Color3.new(0,0,0)
				end
			end)
			button.MouseLeave:connect(function()
				if not button.Selected then
					button.BackgroundTransparency = 1
					button.TextColor3 = Color3.new(1,1,1)
				end
			end)
			button.MouseButton1Click:connect(function()
				resetAllSetButtonSelection()
				button.Selected = not button.Selected
				button.BackgroundColor3 = Color3.new(0,204/255,0)
				button.TextColor3 = Color3.new(0,0,0)
				button.BackgroundTransparency = 0
				selectSet(button, button.Text, userCategoryButtons[i].SetId.Value, 0)
			end)

			currRow = currRow + 1
		end

		local buttons =  setGui.SetPanel.Sets.SetsLists:GetChildren()

		-- set first category as loaded for default
		if buttons then
			for i = 1, #buttons do
				if buttons[i]:IsA("TextButton") then
					selectSet(buttons[i], buttons[i].Text, userCategoryButtons[i].SetId.Value, 0)
					selectCategory(userCategoryButtons)
					break
				end
			end
		end
	end

	setGui = createSetGui()
	waterGui, waterTypeChangedEvent = createWaterGui()
	waterGui.Position = UDim2.new(0,55,0,0)
	waterGui.Parent = setGui
	setGui.Changed:connect(function(prop) -- this resizes the preview image to always be the right size
		if prop == "AbsoluteSize" then
			handleResize()
			setSetIndex()
		end
	end)

	local scrollFrame, controlFrame = t.CreateTrueScrollingFrame()
	scrollFrame.Size = UDim2.new(0.54,0,0.85,0)
	scrollFrame.Position = UDim2.new(0.24,0,0.085,0)
	scrollFrame.Name = "ItemsFrame"
	scrollFrame.ZIndex = 6
	scrollFrame.Parent = setGui.SetPanel
	scrollFrame.BackgroundTransparency = 1

	drillDownSetZIndex(controlFrame,7)

	controlFrame.Parent = setGui.SetPanel
	controlFrame.Position = UDim2.new(0.76, 5, 0, 0)

	local debounce = false
	controlFrame.ScrollBottom.Changed:connect(function(prop)
		if controlFrame.ScrollBottom.Value == true then
			if debounce then return end
			debounce = true
			loadSectionOfItems(setGui, rows, columns)
			debounce = false
		end
	end)

	local userData = {}
	for id = 1, #userIdsForSets do
		local newUserData = game:GetService("InsertService"):GetUserSets(userIdsForSets[id])
		if newUserData and #newUserData > 2 then
			-- start at #3 to skip over My Decals and My Models for each account
			for category = 3, #newUserData do
				if newUserData[category].Name == "High Scalability" then -- we want high scalability parts to show first
					table.insert(userData,1,newUserData[category])
				else
					table.insert(userData, newUserData[category])
				end
			end
		end

	end
	if userData then
		userCategoryButtons = processCategory(userData)
	end

	rows = math.floor(setGui.SetPanel.ItemsFrame.AbsoluteSize.Y/buttonHeight)
	columns = math.floor(setGui.SetPanel.ItemsFrame.AbsoluteSize.X/buttonWidth)

	populateSetsFrame()

	insertPanelCloseCon = setGui.SetPanel.CancelButton.MouseButton1Click:connect(function()
		setGui.SetPanel.Visible = false
		if dialogClosed then dialogClosed() end
	end)

	local setVisibilityFunction = function(visible)
		if visible then
			setGui.SetPanel.Visible = true
		else
			setGui.SetPanel.Visible = false
		end
	end

	local getVisibilityFunction = function()
		if setGui then
			if setGui:FindFirstChild("SetPanel") then
				return setGui.SetPanel.Visible
			end
		end

		return false
	end

	return setGui, setVisibilityFunction, getVisibilityFunction, waterTypeChangedEvent
end

t.CreateTerrainMaterialSelector = function(size,position)
	local terrainMaterialSelectionChanged = Instance.new("BindableEvent")
	terrainMaterialSelectionChanged.Name = "TerrainMaterialSelectionChanged"

	local selectedButton = nil

	local frame = Instance.new("Frame")
	frame.Name = "TerrainMaterialSelector"
	if size then
		frame.Size = size
	else
		frame.Size = UDim2.new(0, 245, 0, 230)
	end
	if position then
		frame.Position = position
	end
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = Color3.new(0,0,0)
	frame.Active = true

	terrainMaterialSelectionChanged.Parent = frame

	local waterEnabled = true -- todo: turn this on when water is ready

	local materialToImageMap = {}
	local materialNames = {"Grass", "Sand", "Brick", "Granite", "Asphalt", "Iron", "Aluminum", "Gold", "Plank", "Log", "Gravel", "Cinder Block", "Stone Wall", "Concrete", "Plastic (red)", "Plastic (blue)"}
	if waterEnabled then
		table.insert(materialNames,"Water")
	end
	local currentMaterial = 1

	function getEnumFromName(choice)
		if choice == "Grass" then return 1 end
		if choice == "Sand" then return 2 end 
		if choice == "Erase" then return 0 end
		if choice == "Brick" then return 3 end
		if choice == "Granite" then return 4 end
		if choice == "Asphalt" then return 5 end
		if choice == "Iron" then return 6 end
		if choice == "Aluminum" then return 7 end
		if choice == "Gold" then return 8 end
		if choice == "Plank" then return 9 end
		if choice == "Log" then return 10 end
		if choice == "Gravel" then return 11 end
		if choice == "Cinder Block" then return 12 end
		if choice == "Stone Wall" then return 13 end
		if choice == "Concrete" then return 14 end
		if choice == "Plastic (red)" then return 15 end
		if choice == "Plastic (blue)" then return 16 end
		if choice == "Water" then return 17 end
	end

	function getNameFromEnum(choice)
		if choice == Enum.CellMaterial.Grass or choice == 1 then return "Grass"end
		if choice == Enum.CellMaterial.Sand or choice == 2 then return "Sand" end 
		if choice == Enum.CellMaterial.Empty or choice == 0 then return "Erase" end
		if choice == Enum.CellMaterial.Brick or choice == 3 then return "Brick" end
		if choice == Enum.CellMaterial.Granite or choice == 4 then return "Granite" end
		if choice == Enum.CellMaterial.Asphalt or choice == 5 then return "Asphalt" end
		if choice == Enum.CellMaterial.Iron or choice == 6 then return "Iron" end
		if choice == Enum.CellMaterial.Aluminum or choice == 7 then return "Aluminum" end
		if choice == Enum.CellMaterial.Gold or choice == 8 then return "Gold" end
		if choice == Enum.CellMaterial.WoodPlank or choice == 9 then return "Plank" end
		if choice == Enum.CellMaterial.WoodLog or choice == 10 then return "Log" end
		if choice == Enum.CellMaterial.Gravel or choice == 11 then return "Gravel" end
		if choice == Enum.CellMaterial.CinderBlock or choice == 12 then return "Cinder Block" end
		if choice == Enum.CellMaterial.MossyStone or choice == 13 then return "Stone Wall" end
		if choice == Enum.CellMaterial.Cement or choice == 14 then return "Concrete" end
		if choice == Enum.CellMaterial.RedPlastic or choice == 15 then return "Plastic (red)" end
		if choice == Enum.CellMaterial.BluePlastic or choice == 16 then return "Plastic (blue)" end

		if waterEnabled then
			if choice == Enum.CellMaterial.Water or choice == 17 then return "Water" end
		end
	end


	local function updateMaterialChoice(choice)
		currentMaterial = getEnumFromName(choice)
		terrainMaterialSelectionChanged:Fire(currentMaterial)
	end

	-- we so need a better way to do this
	for i,v in pairs(materialNames) do
		materialToImageMap[v] = {}
		if v == "Grass" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=56563112"
		elseif v == "Sand" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=62356652"
		elseif v == "Brick" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=65961537"
		elseif v == "Granite" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532153"
		elseif v == "Asphalt" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532038"
		elseif v == "Iron" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532093"
		elseif v == "Aluminum" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67531995"
		elseif v == "Gold" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532118"
		elseif v == "Plastic (red)" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67531848"
		elseif v == "Plastic (blue)" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67531924"
		elseif v == "Plank" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532015"
		elseif v == "Log" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532051"
		elseif v == "Gravel" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532206"
		elseif v == "Cinder Block" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532103"
		elseif v == "Stone Wall" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67531804"
		elseif v == "Concrete" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532059"
		elseif v == "Water" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=81407474"
		else materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=66887593" -- fill in the rest here!!
		end
	end

	local scrollFrame, scrollUp, scrollDown, recalculateScroll = t.CreateScrollingFrame(nil,"grid")
	scrollFrame.Size = UDim2.new(0.85,0,1,0)
	scrollFrame.Position = UDim2.new(0,0,0,0)
	scrollFrame.Parent = frame

	scrollUp.Parent = frame
	scrollUp.Visible = true
	scrollUp.Position = UDim2.new(1,-19,0,0)

	scrollDown.Parent = frame
	scrollDown.Visible = true
	scrollDown.Position = UDim2.new(1,-19,1,-17)

	local function goToNewMaterial(buttonWrap, materialName)
		updateMaterialChoice(materialName)
		buttonWrap.BackgroundTransparency = 0
		selectedButton.BackgroundTransparency = 1
		selectedButton = buttonWrap
	end

	local function createMaterialButton(name)	
		local buttonWrap = Instance.new("TextButton")
		buttonWrap.Text = ""
		buttonWrap.Size = UDim2.new(0,32,0,32)
		buttonWrap.BackgroundColor3 = Color3.new(1,1,1)
		buttonWrap.BorderSizePixel = 0
		buttonWrap.BackgroundTransparency = 1
		buttonWrap.AutoButtonColor = false
		buttonWrap.Name = tostring(name)

		local imageButton = Instance.new("ImageButton")
		imageButton.AutoButtonColor = false
		imageButton.BackgroundTransparency = 1
		imageButton.Size = UDim2.new(0,30,0,30)
		imageButton.Position = UDim2.new(0,1,0,1)
		imageButton.Name = tostring(name)
		imageButton.Parent = buttonWrap
		imageButton.Image = materialToImageMap[name].Regular

		local enumType = Instance.new("NumberValue")
		enumType.Name = "EnumType"
		enumType.Parent = buttonWrap
		enumType.Value = 0

		imageButton.MouseEnter:connect(function()
			buttonWrap.BackgroundTransparency = 0
		end)
		imageButton.MouseLeave:connect(function()
			if selectedButton ~= buttonWrap then
				buttonWrap.BackgroundTransparency = 1
			end
		end)
		imageButton.MouseButton1Click:connect(function()
			if selectedButton ~= buttonWrap then
				goToNewMaterial(buttonWrap, tostring(name))
			end
		end)

		return buttonWrap 
	end

	for i = 1, #materialNames do
		local imageButton = createMaterialButton(materialNames[i])

		if materialNames[i] == "Grass" then -- always start with grass as the default
			selectedButton = imageButton
			imageButton.BackgroundTransparency = 0
		end

		imageButton.Parent = scrollFrame
	end

	local forceTerrainMaterialSelection = function(newMaterialType)
		if not newMaterialType then return end
		if currentMaterial == newMaterialType then return end

		local matName = getNameFromEnum(newMaterialType)
		local buttons = scrollFrame:GetChildren()
		for i = 1, #buttons do
			if buttons[i].Name == "Plastic (blue)" and matName == "Plastic (blue)" then goToNewMaterial(buttons[i],matName) return end
			if buttons[i].Name == "Plastic (red)" and matName == "Plastic (red)" then goToNewMaterial(buttons[i],matName) return end
			if string.find(buttons[i].Name, matName) then
				goToNewMaterial(buttons[i],matName)
				return
			end
		end
	end

	frame.Changed:connect(function ( prop )
		if prop == "AbsoluteSize" then
			recalculateScroll()
		end
	end)

	recalculateScroll()
	return frame, terrainMaterialSelectionChanged, forceTerrainMaterialSelection
end

t.CreateLoadingFrame = function(name,size,position)
	game:GetService("ContentProvider"):Preload("http://www.roblox.com/asset/?id=35238053")

	local loadingFrame = Instance.new("Frame")
	loadingFrame.Name = "LoadingFrame"
	loadingFrame.Style = Enum.FrameStyle.RobloxRound

	if size then loadingFrame.Size = size
	else loadingFrame.Size = UDim2.new(0,300,0,160) end
	if position then loadingFrame.Position = position 
	else loadingFrame.Position = UDim2.new(0.5, -150, 0.5,-80) end

	local loadingBar = Instance.new("Frame")
	loadingBar.Name = "LoadingBar"
	loadingBar.BackgroundColor3 = Color3.new(0,0,0)
	loadingBar.BorderColor3 = Color3.new(79/255,79/255,79/255)
	loadingBar.Position = UDim2.new(0,0,0,41)
	loadingBar.Size = UDim2.new(1,0,0,30)
	loadingBar.Parent = loadingFrame

	local loadingGreenBar = Instance.new("ImageLabel")
	loadingGreenBar.Name = "LoadingGreenBar"
	loadingGreenBar.Image = "http://www.roblox.com/asset/?id=35238053"
	loadingGreenBar.Position = UDim2.new(0,0,0,0)
	loadingGreenBar.Size = UDim2.new(0,0,1,0)
	loadingGreenBar.Visible = false
	loadingGreenBar.Parent = loadingBar

	local loadingPercent = Instance.new("TextLabel")
	loadingPercent.Name = "LoadingPercent"
	loadingPercent.BackgroundTransparency = 1
	loadingPercent.Position = UDim2.new(0,0,1,0)
	loadingPercent.Size = UDim2.new(1,0,0,14)
	loadingPercent.Font = Enum.Font.Arial
	loadingPercent.Text = "0%"
	loadingPercent.FontSize = Enum.FontSize.Size14
	loadingPercent.TextColor3 = Color3.new(1,1,1)
	loadingPercent.Parent = loadingBar

	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Position = UDim2.new(0.5,-60,1,-40)
	cancelButton.Size = UDim2.new(0,120,0,40)
	cancelButton.Font = Enum.Font.Arial
	cancelButton.FontSize = Enum.FontSize.Size18
	cancelButton.TextColor3 = Color3.new(1,1,1)
	cancelButton.Text = "Cancel"
	cancelButton.Style = Enum.ButtonStyle.RobloxButton
	cancelButton.Parent = loadingFrame

	local loadingName = Instance.new("TextLabel")
	loadingName.Name = "loadingName"
	loadingName.BackgroundTransparency = 1
	loadingName.Size = UDim2.new(1,0,0,18)
	loadingName.Position = UDim2.new(0,0,0,2)
	loadingName.Font = Enum.Font.Arial
	loadingName.Text = name
	loadingName.TextColor3 = Color3.new(1,1,1)
	loadingName.TextStrokeTransparency = 1
	loadingName.FontSize = Enum.FontSize.Size18
	loadingName.Parent = loadingFrame

	local cancelButtonClicked = Instance.new("BindableEvent")
	cancelButtonClicked.Name = "CancelButtonClicked"
	cancelButtonClicked.Parent = cancelButton
	cancelButton.MouseButton1Click:connect(function()
		cancelButtonClicked:Fire()
	end)

	local updateLoadingGuiPercent = function(percent, tweenAction, tweenLength)
		if percent and type(percent) ~= "number" then
			error("updateLoadingGuiPercent expects number as argument, got",type(percent),"instead")
		end

		local newSize = nil
		if percent < 0 then
			newSize = UDim2.new(0,0,1,0)
		elseif percent > 1 then
			newSize = UDim2.new(1,0,1,0)
		else
			newSize = UDim2.new(percent,0,1,0)
		end

		if tweenAction then
			if not tweenLength then
				error("updateLoadingGuiPercent is set to tween new percentage, but got no tween time length! Please pass this in as third argument")
			end

			if (newSize.X.Scale > 0) then
				loadingGreenBar.Visible = true
				loadingGreenBar:TweenSize(	newSize,
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					tweenLength,
					true)
			else
				loadingGreenBar:TweenSize(	newSize,
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					tweenLength,
					true,
					function() 
						if (newSize.X.Scale < 0) then
							loadingGreenBar.Visible = false
						end
					end)
			end

		else
			loadingGreenBar.Size = newSize
			loadingGreenBar.Visible = (newSize.X.Scale > 0)
		end
	end

	loadingGreenBar.Changed:connect(function(prop)
		if prop == "Size" then
			loadingPercent.Text = tostring( math.ceil(loadingGreenBar.Size.X.Scale * 100) ) .. "%"
		end
	end)

	return loadingFrame, updateLoadingGuiPercent, cancelButtonClicked
end

t.CreatePluginFrame = function (name,size,position,scrollable,parent)
	function createMenuButton(size,position,text,fontsize,name,parent)
		local button = Instance.new("TextButton",parent)
		button.AutoButtonColor = false
		button.Name = name
		button.BackgroundTransparency = 1
		button.Position = position
		button.Size = size
		button.Font = Enum.Font.ArialBold
		button.FontSize = fontsize
		button.Text =  text
		button.TextColor3 = Color3.new(1,1,1)
		button.BorderSizePixel = 0
		button.BackgroundColor3 = Color3.new(20/255,20/255,20/255)

		button.MouseEnter:connect(function ( )
			if button.Selected then return end
			button.BackgroundTransparency = 0
		end)
		button.MouseLeave:connect(function ( )
			if button.Selected then return end
			button.BackgroundTransparency = 1
		end)

		return button

	end

	local dragBar = Instance.new("Frame",parent)
	dragBar.Name = tostring(name) .. "DragBar"
	dragBar.BackgroundColor3 = Color3.new(39/255,39/255,39/255)
	dragBar.BorderColor3 = Color3.new(0,0,0)
	if size then
		dragBar.Size =  UDim2.new(size.X.Scale,size.X.Offset,0,20)  + UDim2.new(0,20,0,0)
	else
		dragBar.Size = UDim2.new(0,183,0,20)
	end
	if position then
		dragBar.Position = position
	end
	dragBar.Active = true
	dragBar.Draggable = true
	--dragBar.Visible = false
	dragBar.MouseEnter:connect(function (  )
		dragBar.BackgroundColor3 = Color3.new(49/255,49/255,49/255)
	end)
	dragBar.MouseLeave:connect(function (  )
		dragBar.BackgroundColor3 = Color3.new(39/255,39/255,39/255)
	end)

	-- plugin name label
	local pluginNameLabel = Instance.new("TextLabel",dragBar)
	pluginNameLabel.Name = "BarNameLabel"
	pluginNameLabel.Text = " " .. tostring(name)
	pluginNameLabel.TextColor3 = Color3.new(1,1,1)
	pluginNameLabel.TextStrokeTransparency = 0
	pluginNameLabel.Size = UDim2.new(1,0,1,0)
	pluginNameLabel.Font = Enum.Font.ArialBold
	pluginNameLabel.FontSize = Enum.FontSize.Size18
	pluginNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	pluginNameLabel.BackgroundTransparency = 1

	-- close button
	local closeButton = createMenuButton(UDim2.new(0,15,0,17),UDim2.new(1,-16,0.5,-8),"X",Enum.FontSize.Size14,"CloseButton",dragBar)
	local closeEvent = Instance.new("BindableEvent")
	closeEvent.Name = "CloseEvent"
	closeEvent.Parent = closeButton
	closeButton.MouseButton1Click:connect(function ()
		closeEvent:Fire()
		closeButton.BackgroundTransparency = 1
	end)

	-- help button
	local helpButton = createMenuButton(UDim2.new(0,15,0,17),UDim2.new(1,-51,0.5,-8),"?",Enum.FontSize.Size14,"HelpButton",dragBar)
	local helpFrame = Instance.new("Frame",dragBar)
	helpFrame.Name = "HelpFrame"
	helpFrame.BackgroundColor3 = Color3.new(0,0,0)
	helpFrame.Size = UDim2.new(0,300,0,552)
	helpFrame.Position = UDim2.new(1,5,0,0)
	helpFrame.Active = true
	helpFrame.BorderSizePixel = 0
	helpFrame.Visible = false

	helpButton.MouseButton1Click:connect(function(  )
		helpFrame.Visible = not helpFrame.Visible
		if helpFrame.Visible then
			helpButton.Selected = true
			helpButton.BackgroundTransparency = 0
			local screenGui = getScreenGuiAncestor(helpFrame)
			if screenGui then
				if helpFrame.AbsolutePosition.X + helpFrame.AbsoluteSize.X > screenGui.AbsoluteSize.X then --position on left hand side
					helpFrame.Position = UDim2.new(0,-5 - helpFrame.AbsoluteSize.X,0,0)
				else -- position on right hand side
					helpFrame.Position = UDim2.new(1,5,0,0)
				end
			else
				helpFrame.Position = UDim2.new(1,5,0,0)
			end
		else
			helpButton.Selected = false
			helpButton.BackgroundTransparency = 1
		end
	end)

	local minimizeButton = createMenuButton(UDim2.new(0,16,0,17),UDim2.new(1,-34,0.5,-8),"-",Enum.FontSize.Size14,"MinimizeButton",dragBar)
	minimizeButton.TextYAlignment = Enum.TextYAlignment.Top

	local minimizeFrame = Instance.new("Frame",dragBar)
	minimizeFrame.Name = "MinimizeFrame"
	minimizeFrame.BackgroundColor3 = Color3.new(73/255,73/255,73/255)
	minimizeFrame.BorderColor3 = Color3.new(0,0,0)
	minimizeFrame.Position = UDim2.new(0,0,1,0)
	if size then
		minimizeFrame.Size =  UDim2.new(size.X.Scale,size.X.Offset,0,50) + UDim2.new(0,20,0,0)
	else
		minimizeFrame.Size = UDim2.new(0,183,0,50)
	end
	minimizeFrame.Visible = false

	local minimizeBigButton = Instance.new("TextButton",minimizeFrame)
	minimizeBigButton.Position = UDim2.new(0.5,-50,0.5,-20)
	minimizeBigButton.Name = "MinimizeButton"
	minimizeBigButton.Size = UDim2.new(0,100,0,40)
	minimizeBigButton.Style = Enum.ButtonStyle.RobloxButton
	minimizeBigButton.Font = Enum.Font.ArialBold
	minimizeBigButton.FontSize = Enum.FontSize.Size18
	minimizeBigButton.TextColor3 = Color3.new(1,1,1)
	minimizeBigButton.Text = "Show"

	local separatingLine = Instance.new("Frame",dragBar)
	separatingLine.Name = "SeparatingLine"
	separatingLine.BackgroundColor3 = Color3.new(115/255,115/255,115/255)
	separatingLine.BorderSizePixel = 0
	separatingLine.Position = UDim2.new(1,-18,0.5,-7)
	separatingLine.Size = UDim2.new(0,1,0,14)

	local otherSeparatingLine = separatingLine:clone()
	otherSeparatingLine.Position = UDim2.new(1,-35,0.5,-7)
	otherSeparatingLine.Parent = dragBar

	local widgetContainer = Instance.new("Frame",dragBar)
	widgetContainer.Name = "WidgetContainer"
	widgetContainer.BackgroundTransparency = 1
	widgetContainer.Position = UDim2.new(0,0,1,0)
	widgetContainer.BorderColor3 = Color3.new(0,0,0)
	if not scrollable then
		widgetContainer.BackgroundTransparency = 0
		widgetContainer.BackgroundColor3 = Color3.new(72/255,72/255,72/255)
	end

	if size then
		if scrollable then
			widgetContainer.Size = size
		else
			widgetContainer.Size = UDim2.new(0,dragBar.AbsoluteSize.X,size.Y.Scale,size.Y.Offset)
		end
	else
		if scrollable then
			widgetContainer.Size = UDim2.new(0,163,0,400)
		else
			widgetContainer.Size = UDim2.new(0,dragBar.AbsoluteSize.X,0,400)
		end
	end
	if position then
		widgetContainer.Position = position + UDim2.new(0,0,0,20)
	end

	local frame,control,verticalDragger = nil
	if scrollable then
		--frame for widgets
		frame,control = t.CreateTrueScrollingFrame()
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.new(72/255,72/255,72/255)
		frame.BorderColor3 = Color3.new(0,0,0)
		frame.Active = true
		frame.Parent = widgetContainer
		control.Parent = dragBar
		control.BackgroundColor3 = Color3.new(72/255,72/255,72/255)
		control.BorderSizePixel = 0
		control.BackgroundTransparency = 0
		control.Position = UDim2.new(1,-21,1,1)
		if size then
			control.Size = UDim2.new(0,21,size.Y.Scale,size.Y.Offset)
		else
			control.Size = UDim2.new(0,21,0,400)
		end
		control:FindFirstChild("ScrollDownButton").Position = UDim2.new(0,0,1,-20)

		local fakeLine = Instance.new("Frame",control)
		fakeLine.Name = "FakeLine"
		fakeLine.BorderSizePixel = 0
		fakeLine.BackgroundColor3 = Color3.new(0,0,0)
		fakeLine.Size = UDim2.new(0,1,1,1)
		fakeLine.Position = UDim2.new(1,0,0,0)

		verticalDragger = Instance.new("TextButton",widgetContainer)
		verticalDragger.ZIndex = 2
		verticalDragger.AutoButtonColor = false
		verticalDragger.Name = "VerticalDragger"
		verticalDragger.BackgroundColor3 = Color3.new(50/255,50/255,50/255)
		verticalDragger.BorderColor3 = Color3.new(0,0,0)
		verticalDragger.Size = UDim2.new(1,20,0,20)
		verticalDragger.Position = UDim2.new(0,0,1,0)
		verticalDragger.Active = true
		verticalDragger.Text = ""

		local scrubFrame = Instance.new("Frame",verticalDragger)
		scrubFrame.Name = "ScrubFrame"
		scrubFrame.BackgroundColor3 = Color3.new(1,1,1)
		scrubFrame.BorderSizePixel = 0
		scrubFrame.Position = UDim2.new(0.5,-5,0.5,0)
		scrubFrame.Size = UDim2.new(0,10,0,1)
		scrubFrame.ZIndex = 5
		local scrubTwo = scrubFrame:clone()
		scrubTwo.Position = UDim2.new(0.5,-5,0.5,-2)
		scrubTwo.Parent = verticalDragger
		local scrubThree = scrubFrame:clone()
		scrubThree.Position = UDim2.new(0.5,-5,0.5,2)
		scrubThree.Parent = verticalDragger

		local areaSoak = Instance.new("TextButton",getScreenGuiAncestor(parent))
		areaSoak.Name = "AreaSoak"
		areaSoak.Size = UDim2.new(1,0,1,0)
		areaSoak.BackgroundTransparency = 1
		areaSoak.BorderSizePixel = 0
		areaSoak.Text = ""
		areaSoak.ZIndex = 10
		areaSoak.Visible = false
		areaSoak.Active = true

		local draggingVertical = false
		local startYPos = nil
		verticalDragger.MouseEnter:connect(function ()
			verticalDragger.BackgroundColor3 = Color3.new(60/255,60/255,60/255)
		end)
		verticalDragger.MouseLeave:connect(function ()
			verticalDragger.BackgroundColor3 = Color3.new(50/255,50/255,50/255)
		end)
		verticalDragger.MouseButton1Down:connect(function(x,y)
			draggingVertical = true
			areaSoak.Visible = true
			startYPos = y
		end)
		areaSoak.MouseButton1Up:connect(function (  )
			draggingVertical = false
			areaSoak.Visible = false
		end)
		areaSoak.MouseMoved:connect(function(x,y)
			if not draggingVertical then return end

			local yDelta = y - startYPos
			if not control.ScrollDownButton.Visible and yDelta > 0 then
				return
			end

			if (widgetContainer.Size.Y.Offset + yDelta) < 150 then
				widgetContainer.Size = UDim2.new(widgetContainer.Size.X.Scale, widgetContainer.Size.X.Offset,widgetContainer.Size.Y.Scale,150)
				control.Size = UDim2.new (0,21,0,150)
				return 
			end 

			startYPos = y

			if widgetContainer.Size.Y.Offset + yDelta >= 0 then
				widgetContainer.Size = UDim2.new(widgetContainer.Size.X.Scale, widgetContainer.Size.X.Offset,widgetContainer.Size.Y.Scale,widgetContainer.Size.Y.Offset + yDelta)
				control.Size = UDim2.new(0,21,0,control.Size.Y.Offset + yDelta )
			end
		end)
	end

	local function switchMinimize()
		minimizeFrame.Visible = not minimizeFrame.Visible
		if scrollable then
			frame.Visible = not frame.Visible
			verticalDragger.Visible = not verticalDragger.Visible
			control.Visible = not control.Visible
		else
			widgetContainer.Visible = not widgetContainer.Visible
		end

		if minimizeFrame.Visible then
			minimizeButton.Text = "+"
		else
			minimizeButton.Text = "-"
		end
	end

	minimizeBigButton.MouseButton1Click:connect(function (  )
		switchMinimize()
	end)

	minimizeButton.MouseButton1Click:connect(function(  )
		switchMinimize()
	end)

	if scrollable then
		return dragBar, frame, helpFrame, closeEvent
	else
		return dragBar, widgetContainer, helpFrame, closeEvent
	end
end

t.Help = 
	function(funcNameOrFunc) 
		--input argument can be a string or a function.  Should return a description (of arguments and expected side effects)
		if funcNameOrFunc == "CreatePropertyDropDownMenu" or funcNameOrFunc == t.CreatePropertyDropDownMenu then
			return "Function CreatePropertyDropDownMenu.  " ..
			"Arguments: (instance, propertyName, enumType).  " .. 
			"Side effect: returns a container with a drop-down-box that is linked to the 'property' field of 'instance' which is of type 'enumType'" 
		end 
		if funcNameOrFunc == "CreateDropDownMenu" or funcNameOrFunc == t.CreateDropDownMenu then
			return "Function CreateDropDownMenu.  " .. 
			"Arguments: (items, onItemSelected).  " .. 
			"Side effect: Returns 2 results, a container to the gui object and a 'updateSelection' function for external updating.  The container is a drop-down-box created around a list of items" 
		end 
		if funcNameOrFunc == "CreateMessageDialog" or funcNameOrFunc == t.CreateMessageDialog then
			return "Function CreateMessageDialog.  " .. 
			"Arguments: (title, message, buttons). " .. 
			"Side effect: Returns a gui object of a message box with 'title' and 'message' as passed in.  'buttons' input is an array of Tables contains a 'Text' and 'Function' field for the text/callback of each button"
		end		
		if funcNameOrFunc == "CreateStyledMessageDialog" or funcNameOrFunc == t.CreateStyledMessageDialog then
			return "Function CreateStyledMessageDialog.  " .. 
			"Arguments: (title, message, style, buttons). " .. 
			"Side effect: Returns a gui object of a message box with 'title' and 'message' as passed in.  'buttons' input is an array of Tables contains a 'Text' and 'Function' field for the text/callback of each button, 'style' is a string, either Error, Notify or Confirm"
		end
		if funcNameOrFunc == "GetFontHeight" or funcNameOrFunc == t.GetFontHeight then
			return "Function GetFontHeight.  " .. 
			"Arguments: (font, fontSize). " .. 
			"Side effect: returns the size in pixels of the given font + fontSize"
		end
		if funcNameOrFunc == "LayoutGuiObjects" or funcNameOrFunc == t.LayoutGuiObjects then

		end
		if funcNameOrFunc == "CreateScrollingFrame" or funcNameOrFunc == t.CreateScrollingFrame then
			return "Function CreateScrollingFrame.  " .. 
			"Arguments: (orderList, style) " .. 
			"Side effect: returns 4 objects, (scrollFrame, scrollUpButton, scrollDownButton, recalculateFunction).  'scrollFrame' can be filled with GuiObjects.  It will lay them out and allow scrollUpButton/scrollDownButton to interact with them.  Orderlist is optional (and specifies the order to layout the children.  Without orderlist, it uses the children order. style is also optional, and allows for a 'grid' styling if style is passed 'grid' as a string.  recalculateFunction can be called when a relayout is needed (when orderList changes)"
		end
		if funcNameOrFunc == "CreateTrueScrollingFrame" or funcNameOrFunc == t.CreateTrueScrollingFrame then
			return "Function CreateTrueScrollingFrame.  " .. 
			"Arguments: (nil) " .. 
			"Side effect: returns 2 objects, (scrollFrame, controlFrame).  'scrollFrame' can be filled with GuiObjects, and they will be clipped if not inside the frame's bounds. controlFrame has children scrollup and scrolldown, as well as a slider.  controlFrame can be parented to any guiobject and it will readjust itself to fit."
		end
		if funcNameOrFunc == "AutoTruncateTextObject" or funcNameOrFunc == t.AutoTruncateTextObject then
			return "Function AutoTruncateTextObject.  " .. 
			"Arguments: (textLabel) " .. 
			"Side effect: returns 2 objects, (textLabel, changeText).  The 'textLabel' input is modified to automatically truncate text (with ellipsis), if it gets too small to fit.  'changeText' is a function that can be used to change the text, it takes 1 string as an argument"
		end
		if funcNameOrFunc == "CreateSlider" or funcNameOrFunc == t.CreateSlider then
			return "Function CreateSlider.  " ..
			"Arguments: (steps, width, position) " ..
			"Side effect: returns 2 objects, (sliderGui, sliderPosition).  The 'steps' argument specifies how many different positions the slider can hold along the bar.  'width' specifies in pixels how wide the bar should be (modifiable afterwards if desired). 'position' argument should be a UDim2 for slider positioning. 'sliderPosition' is an IntValue whose current .Value specifies the specific step the slider is currently on."
		end
		if funcNameOrFunc == "CreateSliderNew" or funcNameOrFunc == t.CreateSliderNew then
			return "Function CreateSliderNew.  " ..
			"Arguments: (steps, width, position) " ..
			"Side effect: returns 2 objects, (sliderGui, sliderPosition).  The 'steps' argument specifies how many different positions the slider can hold along the bar.  'width' specifies in pixels how wide the bar should be (modifiable afterwards if desired). 'position' argument should be a UDim2 for slider positioning. 'sliderPosition' is an IntValue whose current .Value specifies the specific step the slider is currently on."
		end
		if funcNameOrFunc == "CreateLoadingFrame" or funcNameOrFunc == t.CreateLoadingFrame then
			return "Function CreateLoadingFrame.  " ..
			"Arguments: (name, size, position) " ..
			"Side effect: Creates a gui that can be manipulated to show progress for a particular action.  Name appears above the loading bar, and size and position are udim2 values (both size and position are optional arguments).  Returns 3 arguments, the first being the gui created. The second being updateLoadingGuiPercent, which is a bindable function.  This function takes one argument (two optionally), which should be a number between 0 and 1, representing the percentage the loading gui should be at.  The second argument to this function is a boolean value that if set to true will tween the current percentage value to the new percentage value, therefore our third argument is how long this tween should take. Our third returned argument is a BindableEvent, that when fired means that someone clicked the cancel button on the dialog."
		end
		if funcNameOrFunc == "CreateTerrainMaterialSelector" or funcNameOrFunc == t.CreateTerrainMaterialSelector then
			return "Function CreateTerrainMaterialSelector.  " ..
			"Arguments: (size, position) " ..
			"Side effect: Size and position are UDim2 values that specifies the selector's size and position.  Both size and position are optional arguments. This method returns 3 objects (terrainSelectorGui, terrainSelected, forceTerrainSelection).  terrainSelectorGui is just the gui object that we generate with this function, parent it as you like. TerrainSelected is a BindableEvent that is fired whenever a new terrain type is selected in the gui.  ForceTerrainSelection is a function that takes an argument of Enum.CellMaterial and will force the gui to show that material as currently selected."
		end
	end

return t

end;
};
-- StarterGui.RobloxGui.Settings
local function C_3()
local script = G2L["3"];
	-- 2015E CORE MENU - PATCHED ORIGINAL (2026)
	-- January 2015 RbxGui library, loaded from Libraries folder.
	local RbxGui = require(script.Parent:WaitForChild("Libraries"):WaitForChild("RbxGui"))
	
	-- Uses this original script's menu builders / UI, not a replacement UI.
	-- Put as a LocalScript in StarterGui. No additional modules or GUI required.
	-- Put the patched ChatScript2, HealthScript, and BackpackScript ModuleScripts next to this Settings LocalScript.
	-- This preserves the classic settings UI while modern chat runs separately.
	local ChatScript2 = require(script.Parent:WaitForChild("ChatScript2"))
	task.defer(function()
		local ok, err = pcall(ChatScript2.Start)
		if not ok then warn("2015E ChatScript2 failed: " .. tostring(err)) end
	end)
	-- Start the patched 2014-style health bar alongside ChatScript2.
	local HealthScript = require(script.Parent:WaitForChild("HealthScript"))
	task.defer(function()
		local ok, err = pcall(HealthScript.Start)
		if not ok then warn("2015E HealthScript failed: " .. tostring(err)) end
	end)
	-- Original 2015E player list (module in StarterGui alongside this Settings LocalScript).
	local PlayerListScript2 = require(script.Parent:WaitForChild("PlayerListScript2"))
	task.defer(function()
		local ok, err = pcall(PlayerListScript2.Start)
		if not ok then warn("2015E PlayerListScript2 failed: " .. tostring(err)) end
	end)
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local StarterGui = game:GetService("StarterGui")
	local GuiService = game:GetService("GuiService")
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local root = playerGui:FindFirstChild("Roblox2015EPatched")
	if root then root:Destroy() end
	root = Instance.new("ScreenGui")
	root.Name = "Roblox2015EPatched"
	root.ResetOnSpawn = false
	root.IgnoreGuiInset = true
	root.DisplayOrder = 500
	root.Parent = playerGui
	local topControl = Instance.new("Frame")
	topControl.Name = "TopLeftControl"
	topControl.BackgroundTransparency = 1
	topControl.Size = UDim2.new(0,80,0,48)
	topControl.Parent = root
	local bottomControl = Instance.new("Frame")
	bottomControl.Name = "BottomLeftControl"
	bottomControl.BackgroundTransparency = 1
	bottomControl.Position = UDim2.new(0,0,1,-52)
	bottomControl.Size = UDim2.new(0,80,0,52)
	bottomControl.Parent = root
	local gui = root
	local function safeSet(obj, key, value)
		pcall(function() obj[key] = value end)
	end
	local function oldCreate(className)
		return function(props)
			local obj = Instance.new(className)
			for k, v in pairs(props) do
				if k ~= "Parent" then safeSet(obj, k, v) end
			end
			if props.Parent then obj.Parent = props.Parent end
			return obj
		end
	end
	local Create = oldCreate
	local function showCoreReport()
		-- In-game reports are owned by Roblox, not submitted by a LocalScript.
		pcall(function() StarterGui:SetCore("ReportAbuse", true) end)
	end
	-- The original RbxGui functions are supplied by Libraries/RbxGui.
	-- Obsolete GuiService center-dialog methods are replaced by visible-screen behavior.
	local function addCenterDialog(item, _, show)
		if show then show() else item.Visible=true end
	end
	local function removeCenterDialog(item)
		if item then item.Visible=false end
	end
	-- Safe adapter for legacy flags removed from modern Roblox.
	local function getLegacyFlag(_) return false end
	
	local function waitForChild(instance, name)
		while not instance:FindFirstChild(name) do
			instance.ChildAdded:Wait()
		end
	end
	
	local function waitForProperty(instance, property)
		while not instance[property] do
			instance.Changed:Wait()
		end
	end
	
	--Include
	-- Create is inlined above
	
	
	-- A Few Script Globals
	-- gui is the standalone ScreenGui created above
	
	local helpButton = nil
	local updateCameraDropDownSelection = nil
	local updateVideoCaptureDropDownSelection = nil
	local updateSmartCameraDropDownSelection = nil
	local updateMovementDropDownSelection = nil
	local tweenTime = 0.2
	
	local mouseLockLookScreenUrl = "http://www.roblox.com/asset?id=54071825"
	local classicLookScreenUrl = "http://www.roblox.com/Asset?id=45915798"
	
	local hasGraphicsSlider = false -- legacy Rendering quality writes are protected
	local GraphicsQualityLevels = 10 -- how many levels we allow on graphics slider
	local recordingVideo = false
	
	local volumeFlagExists, volumeFlagValue = pcall(function () return getLegacyFlag("VolumeControlInGameEnabled") end)
	local hasVolumeSlider = false -- MasterVolume is engine-controlled; do not show a fake slider
	
	local currentMenuSelection = nil
	local lastMenuSelection = {}
	
	local defaultPosition = UDim2.new(0,0,0,0)
	
	local centerDialogs = {}
	local mainShield = nil
	
	local settingsChoices = {}
	
	local testReport = false
	
	local inStudioMode = game:GetService("RunService"):IsStudio()
	-- REMOVE WHEN NOT TESTING
	-- inStudioMode = false
	
	local macClient = false
	local success, isMac = true, false
	macClient = success and isMac
	-- REMOVE WHEN NOT TESTING
	--macClient = true
	
	local customCameraDefaultType = "Default (Classic)"
	local touchClient = false
	pcall(function() touchClient = game:GetService("UserInputService").TouchEnabled end)
	
	-- REMOVE WHEN NOT TESTING
	-- touchClient = true
	
	if touchClient then
		hasGraphicsSlider = false
		customCameraDefaultType = "Default (Follow)"
	end
	
	
	local newMovementScripts = true
	local successFlagRead, luaFlagValue = pcall(function() return true end)
	if successFlagRead and luaFlagValue == true then
		newMovementScripts = true
	end
	
	
	local function Color3I(r,g,b)
		return Color3.new(r/255,g/255,b/255)
	end
	
	local function robloxLock(instance)
		-- RobloxLocked is RobloxScriptSecurity; cannot set in an ordinary LocalScript
		local children = instance:GetChildren()
		if children then
			for i, child in ipairs(children) do
				robloxLock(child)
			end
		end
	end
	
	function resumeGameFunction(shield)
		shield.Settings:TweenPosition(UDim2.new(0.5, -262,-0.5, -200),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
		task.delay(tweenTime,function()
			shield.Visible = false
			for i = 1, #centerDialogs do
				centerDialogs[i].Visible = false
				removeCenterDialog(centerDialogs[i])
			end
			removeCenterDialog(shield)
			settingsButton.Active = true
			currentMenuSelection = nil
			lastMenuSelection = {}
			pcall(function() game:GetService("UserInputService").OverrideMouseIconEnabled = false end)
			-- NOTE: This is a hacky way to raise an event when the menu closes. This is being used by the new
			-- lua controls to correctly set the state of the mouse and shift lock mode when leaving the settings menu.
			if localPlayer.DevEnableMouseLock then
				UserSettings().GameSettings.ControlMode = Enum.ControlMode.Classic
				UserSettings().GameSettings.ControlMode = Enum.ControlMode.MouseLockSwitch
			end
		end)
	end
	
	function goToMenu(container,menuName, moveDirection,size,position)
		if type(menuName) ~= "string" then return end
	
		table.insert(lastMenuSelection,currentMenuSelection)
		if menuName == "GameMainMenu" then
			lastMenuSelection = {}
		end
	
		local containerChildren = container:GetChildren()
		local selectedMenu = false
		for i = 1, #containerChildren do
			if containerChildren[i].Name == menuName then
				containerChildren[i].Visible = true
				currentMenuSelection = {container = container,name = menuName, direction = moveDirection, lastSize = size}
				selectedMenu = true
				if size and position then
					containerChildren[i]:TweenSizeAndPosition(size,position,Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
				elseif size then
					containerChildren[i]:TweenSizeAndPosition(size,UDim2.new(0.5,-size.X.Offset/2,0.5,-size.Y.Offset/2),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
				else
					containerChildren[i]:TweenPosition(UDim2.new(0,0,0,0),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
				end
			else
				if moveDirection == "left" then
					containerChildren[i]:TweenPosition(UDim2.new(-1,-525,0,0),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
				elseif moveDirection == "right" then
					containerChildren[i]:TweenPosition(UDim2.new(1,525,0,0),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
				elseif moveDirection == "up" then
					containerChildren[i]:TweenPosition(UDim2.new(0,0,-1,-400),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
				elseif moveDirection == "down" then
					containerChildren[i]:TweenPosition(UDim2.new(0,0,1,400),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
				end
				task.delay(tweenTime,function()
					containerChildren[i].Visible = false
				end)
			end
		end	
	end
	
	function resetLocalCharacter()
		local player = game:GetService("Players").LocalPlayer
		if player then
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.Health = 0
			end
		end
	end
	
	local function createTextButton(text,style,fontSize,buttonSize,buttonPosition)
		local newTextButton = Instance.new("TextButton")
		newTextButton.Font = Enum.Font.SourceSansBold
		newTextButton.FontSize = fontSize
		newTextButton.Size = buttonSize
		newTextButton.Position = buttonPosition
		newTextButton.Style = style
		newTextButton.TextColor3 = Color3.new(1,1,1)
		newTextButton.Text = text
		return newTextButton
	end
	
	local function CreateTextButtons(frame, buttons, yPos, ySize)
		if #buttons < 1 then
			error("Must have more than one button")
		end
	
		local buttonNum = 1
		local buttonObjs = {}
	
		local function toggleSelection(button)
			for i, obj in ipairs(buttonObjs) do
				if obj == button then
					obj.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
				else
					obj.Style = Enum.ButtonStyle.RobloxRoundButton
				end
			end
		end
	
		for i, obj in ipairs(buttons) do 
			local button = Instance.new("TextButton")
			button.Name = "Button" .. buttonNum
			button.Font = Enum.Font.SourceSansBold
			button.FontSize = Enum.FontSize.Size18
			button.AutoButtonColor = true
			button.Style = Enum.ButtonStyle.RobloxRoundButton
			button.Text = obj.Text
			button.TextColor3 = Color3.new(1,1,1)
			button.MouseButton1Click:Connect(function() toggleSelection(button) obj.Function() end)
			button.Parent = frame
			button.ZIndex = 8
			buttonObjs[buttonNum] = button
	
			buttonNum = buttonNum + 1
		end
	
		toggleSelection(buttonObjs[1])
	
		local numButtons = buttonNum-1
	
		if numButtons == 1 then
			frame.Button1.Position = UDim2.new(0.35, 0, yPos.Scale, yPos.Offset)
			frame.Button1.Size = UDim2.new(.4,0,ySize.Scale, ySize.Offset)
		elseif numButtons == 2 then
			frame.Button1.Position = UDim2.new(0.1, 0, yPos.Scale, yPos.Offset)
			frame.Button1.Size = UDim2.new(.35,0, ySize.Scale, ySize.Offset)
	
			frame.Button2.Position = UDim2.new(0.55, 0, yPos.Scale, yPos.Offset)
			frame.Button2.Size = UDim2.new(.35,0, ySize.Scale, ySize.Offset)
		elseif numButtons >= 3 then
			local spacing = .1 / numButtons
			local buttonSize = .9 / numButtons
	
			buttonNum = 1
			while buttonNum <= numButtons do
				buttonObjs[buttonNum].Position = UDim2.new(spacing*buttonNum + (buttonNum-1) * buttonSize, 0, yPos.Scale, yPos.Offset)
				buttonObjs[buttonNum].Size = UDim2.new(buttonSize, 0, ySize.Scale, ySize.Offset)
				buttonNum = buttonNum + 1
			end
		end
	end
	
	function setRecordGui(recording, stopRecordButton, recordVideoButton)
		if recording then 
			stopRecordButton.Visible = true
			recordVideoButton.Text = "Stop Recording"
		else
			stopRecordButton.Visible = false
			recordVideoButton.Text = "Record Video"
		end
	end
	
	function recordVideoClick(recordVideoButton, stopRecordButton)
		recordingVideo = not recordingVideo
		setRecordGui(recordingVideo, stopRecordButton, recordVideoButton)
	end
	
	local currentlyToggling = false;
	local DevConsoleToggle = nil;
	
	task.delay(0, function()
		DevConsoleToggle = gui:WaitForChild("ToggleDevConsole")
	end)
	
	function toggleDeveloperConsole()
		if not DevConsoleToggle then
			return
		end
	
		DevConsoleToggle:Invoke()
	end
	
	function backToGame(buttonClicked, shield, settingsButton)
		buttonClicked.Parent.Parent.Parent.Parent.Visible = false
		shield.Visible = false
		for i = 1, #centerDialogs do
			removeCenterDialog(centerDialogs[i])
			centerDialogs[i].Visible = false
		end
		centerDialogs = {}
		removeCenterDialog(shield)
		settingsButton.Active = true
	end
	
	function setDisabledState(guiObject)
		if not guiObject then return end
	
		if guiObject:IsA("TextLabel") then
			guiObject.TextTransparency = 0.9
		elseif guiObject:IsA("TextButton") then
			guiObject.TextTransparency = 0.9
			guiObject.Active = false
		else
			if guiObject["ClassName"] then
				print("setDisabledState() got object of unsupported type.  object type is ",guiObject.ClassName)
			end
		end
	end
	
	local function createHelpDialog(baseZIndex)
	
		if helpButton == nil then
			if gui:FindFirstChild("TopLeftControl") and gui.TopLeftControl:FindFirstChild("Help") then
				helpButton = gui.TopLeftControl.Help
			elseif gui:FindFirstChild("BottomRightControl") and gui.BottomRightControl:FindFirstChild("Help") then
				helpButton = gui.BottomRightControl.Help
			end
		end
	
		local shield = Instance.new("Frame")
		shield.Name = "HelpDialogShield"
		shield.Active = true
		shield.Visible = false
		shield.Size = UDim2.new(1,0,1,0)
		shield.BackgroundColor3 = Color3I(51,51,51)
		shield.BorderColor3 = Color3I(27,42,53)
		shield.BackgroundTransparency = 0.4
		shield.ZIndex = baseZIndex + 2
	
		local helpDialog = Instance.new("Frame")
		helpDialog.Name = "HelpDialog"
		helpDialog.Style = Enum.FrameStyle.DropShadow
		helpDialog.Position = UDim2.new(.2, 0, .2, 0)
		helpDialog.Size = UDim2.new(0.6, 0, 0.6, 0)
		helpDialog.Active = true
		helpDialog.Parent = shield
		helpDialog.ZIndex = baseZIndex + 2
	
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "Title"
		titleLabel.Text = "Keyboard & Mouse Controls"
		titleLabel.Font = Enum.Font.SourceSansBold
		titleLabel.FontSize = Enum.FontSize.Size36
		titleLabel.Position = UDim2.new(0, 0, 0.025, 0)
		titleLabel.Size = UDim2.new(1, 0, 0, 40)
		titleLabel.TextColor3 = Color3.new(1,1,1)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Parent = helpDialog
		titleLabel.ZIndex = baseZIndex + 2
	
		local buttonRow = Instance.new("Frame")
		buttonRow.Name = "Buttons"
		buttonRow.Position = UDim2.new(0.1, 0, .07, 40)
		buttonRow.Size = UDim2.new(0.8, 0, 0, 45)
		buttonRow.BackgroundTransparency = 1
		buttonRow.Parent = helpDialog
		buttonRow.ZIndex = baseZIndex + 2
	
		local imageFrame = Instance.new("Frame")
		imageFrame.Name = "ImageFrame"
		imageFrame.Position = UDim2.new(0.05, 0, 0.075, 80)
		imageFrame.Size = UDim2.new(0.9, 0, .9, -120)
		imageFrame.BackgroundTransparency = 1
		imageFrame.Parent = helpDialog
		imageFrame.ZIndex = baseZIndex + 2
	
		local layoutFrame = Instance.new("Frame")
		layoutFrame.Name = "LayoutFrame"
		layoutFrame.Position = UDim2.new(0.5, 0, 0, 0)
		layoutFrame.Size = UDim2.new(1.5, 0, 1, 0)
		layoutFrame.BackgroundTransparency = 1
		layoutFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
		layoutFrame.Parent = imageFrame
		layoutFrame.ZIndex = baseZIndex + 2
	
		local image = Instance.new("ImageLabel")
		image.Name = "Image"
		if localPlayer.DevEnableMouseLock then
			image.Image = mouseLockLookScreenUrl
		else
			image.Image = classicLookScreenUrl
		end
		image.Position = UDim2.new(-0.5, 0, 0, 0)
		image.Size = UDim2.new(1, 0, 1, 0)
		image.BackgroundTransparency = 1
		image.Parent = layoutFrame
		image.ZIndex = baseZIndex + 2
	
		local buttons = {}
		buttons[1] = {}
		buttons[1].Text = "Look"
		buttons[1].Function = function()
			if localPlayer.DevEnableMouseLock then
				image.Image = mouseLockLookScreenUrl
			else
				image.Image = classicLookScreenUrl
			end
		end 
		buttons[2] = {}
		buttons[2].Text = "Move"
		buttons[2].Function = function() 
			image.Image = "http://www.roblox.com/Asset?id=45915811"
		end 
		buttons[3] = {}
		buttons[3].Text = "Gear"
		buttons[3].Function = function() 
			image.Image = "http://www.roblox.com/Asset?id=45917596"
		end
		buttons[4] = {}
		buttons[4].Text = "Zoom"
		buttons[4].Function = function() 	
			image.Image = "http://www.roblox.com/Asset?id=45915825"
		end 
	
		CreateTextButtons(buttonRow, buttons, UDim.new(0, 0), UDim.new(1,0))
	
		local devConsoleButton = Create'TextButton'{
			Name = "DeveloperConsoleButton";
			Text = "Log";
			Size = UDim2.new(0,60,0,30);
			Style = Enum.ButtonStyle.RobloxRoundButton;
			Position = UDim2.new(1,-65,1,-35);
			Font = Enum.Font.SourceSansBold;
			FontSize = Enum.FontSize.Size18;
			TextColor3 = Color3.new(1,1,1);
			ZIndex = baseZIndex + 4;
			BackgroundTransparency = 1;
			Parent = helpDialog;
		}
	
		Create'TextLabel'{
			Name = "DeveloperConsoleButton";
			Text = "F9";
			Size = UDim2.new(0,14,0,14);
			Position = UDim2.new(1,-6,0, -2);
			Font = Enum.Font.SourceSansBold;
			FontSize = Enum.FontSize.Size12;
			TextColor3 = Color3.new(0,1,0);
			ZIndex = baseZIndex + 4;
			BackgroundTransparency = 1;
			Parent = devConsoleButton;
		}
	
		waitForProperty(game:GetService("Players"), "LocalPlayer")
		game:GetService("Players").LocalPlayer:GetMouse().KeyDown:Connect(function(key)
			if string.byte(key) == 34 then --F9
				toggleDeveloperConsole()
			end
		end)
	
		devConsoleButton.MouseButton1Click:Connect(function()
			toggleDeveloperConsole()
			shield.Visible = false
			removeCenterDialog(shield)
		end)
	
		-- set up listeners for type of mouse mode, but keep constructing gui at same time
		task.delay(0, function()
			waitForChild(gui,"UserSettingsShield")
			waitForChild(gui.UserSettingsShield,"Settings")
			waitForChild(gui.UserSettingsShield.Settings,"SettingsStyle")
			waitForChild(gui.UserSettingsShield.Settings.SettingsStyle, "GameSettingsMenu")
			waitForChild(gui.UserSettingsShield.Settings.SettingsStyle.GameSettingsMenu, "CameraField")
			waitForChild(gui.UserSettingsShield.Settings.SettingsStyle.GameSettingsMenu.CameraField, "DropDownMenuButton")
			gui.UserSettingsShield.Settings.SettingsStyle.GameSettingsMenu.CameraField.DropDownMenuButton.Changed:Connect(function(prop)
				if prop ~= "Text" then return end
				if buttonRow.Button1.Style == Enum.ButtonStyle.RobloxRoundDefaultButton then -- only change if this is the currently selected panel
					if gui.UserSettingsShield.Settings.SettingsStyle.GameSettingsMenu.CameraField.DropDownMenuButton.Text == "Classic" then
						image.Image = classicLookScreenUrl
					else
						image.Image = mouseLockLookScreenUrl
					end
				end
			end)
		end)
	
	
		local okBtn = Instance.new("TextButton")
		okBtn.Name = "OkBtn"
		okBtn.Text = "OK"
		okBtn.Modal = true
		okBtn.Size = UDim2.new(0.3, 0, 0, 45)
		okBtn.Position = UDim2.new(0.35, 0, .975, -50)
		okBtn.Font = Enum.Font.SourceSansBold
		okBtn.FontSize = Enum.FontSize.Size18
		okBtn.BackgroundTransparency = 1
		okBtn.TextColor3 = Color3.new(1,1,1)
		okBtn.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
		okBtn.ZIndex = baseZIndex + 2
		okBtn.MouseButton1Click:Connect(
			function()
				shield.Visible = false
				removeCenterDialog(shield)
			end)
		okBtn.Parent = helpDialog
	
		robloxLock(shield)
		return shield
	end
	
	local function createLeaveConfirmationMenu(baseZIndex,shield)
		local frame = Instance.new("Frame")
		frame.Name = "LeaveConfirmationMenu"
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(1,0,1,0)
		frame.Position = UDim2.new(0,0,2,400)
		frame.ZIndex = baseZIndex + 4
	
		local yesButton = createTextButton("Leave",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size24,UDim2.new(0,128,0,50),UDim2.new(0,313,0.8,0))
		yesButton.Name = "YesButton"
		yesButton.ZIndex = baseZIndex + 4
		yesButton.Parent = frame
		yesButton.Modal = true
		yesButton.MouseButton1Click:Connect(function()
			pcall(function() game:Shutdown() end)
		end)
	
		local noButton = createTextButton("Stay",Enum.ButtonStyle.RobloxRoundDefaultButton,Enum.FontSize.Size24,UDim2.new(0,128,0,50),UDim2.new(0,90,0.8,0))
		noButton.Name = "NoButton"
		noButton.Parent = frame
		noButton.ZIndex = baseZIndex + 4
		noButton.MouseButton1Click:Connect(function()
			goToMenu(shield.Settings.SettingsStyle,"GameMainMenu","down",UDim2.new(0,525,0,430))
			shield.Settings:TweenSize(UDim2.new(0,525,0,430),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
		end)
	
		local leaveText = Instance.new("TextLabel")
		leaveText.Name = "LeaveText"
		leaveText.Text = "Leave this game?"
		leaveText.Size = UDim2.new(1,0,0.8,0)
		leaveText.TextWrap = true
		leaveText.TextColor3 = Color3.new(1,1,1)
		leaveText.Font = Enum.Font.SourceSansBold
		leaveText.FontSize = Enum.FontSize.Size36
		leaveText.BackgroundTransparency = 1
		leaveText.ZIndex = baseZIndex + 4
		leaveText.Parent = frame
	
		return frame
	end
	
	local function createResetConfirmationMenu(baseZIndex,shield)
		local frame = Instance.new("Frame")
		frame.Name = "ResetConfirmationMenu"
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(1,0,1,0)
		frame.Position = UDim2.new(0,0,2,400)
		frame.ZIndex = baseZIndex + 4
	
		local yesButton = createTextButton("Reset",Enum.ButtonStyle.RobloxRoundDefaultButton,Enum.FontSize.Size24,UDim2.new(0,128,0,50),UDim2.new(0,313,0,280))
		yesButton.Name = "YesButton"
		yesButton.ZIndex = baseZIndex + 4
		yesButton.Parent = frame
		yesButton.Modal  = true
		yesButton.MouseButton1Click:Connect(function()
			resumeGameFunction(shield)
			resetLocalCharacter()
		end)
	
		local noButton = createTextButton("Cancel",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size24,UDim2.new(0,128,0,50),UDim2.new(0,90,0,280))
		noButton.Name = "NoButton"
		noButton.Parent = frame
		noButton.ZIndex = baseZIndex + 4
		noButton.MouseButton1Click:Connect(function()
			goToMenu(shield.Settings.SettingsStyle,"GameMainMenu","down",UDim2.new(0,525,0,430))
			shield.Settings:TweenSize(UDim2.new(0,525,0,430),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
		end)
	
		local resetCharacterText = Instance.new("TextLabel")
		resetCharacterText.Name = "ResetCharacterText"
		resetCharacterText.Text = "Are you sure you want to reset your character?"
		resetCharacterText.Size = UDim2.new(1,0,0.8,0)
		resetCharacterText.TextWrap = true
		resetCharacterText.TextColor3 = Color3.new(1,1,1)
		resetCharacterText.Font = Enum.Font.SourceSansBold
		resetCharacterText.FontSize = Enum.FontSize.Size36
		resetCharacterText.BackgroundTransparency = 1
		resetCharacterText.ZIndex = baseZIndex + 4
		resetCharacterText.Parent = frame
	
		local fineResetCharacterText = resetCharacterText:Clone()
		fineResetCharacterText.Name = "FineResetCharacterText"
		fineResetCharacterText.Text = "You will be put back on a spawn point"
		fineResetCharacterText.Size = UDim2.new(0,303,0,18)
		fineResetCharacterText.Position = UDim2.new(0, 109, 0, 215)
		fineResetCharacterText.FontSize = Enum.FontSize.Size18
		fineResetCharacterText.Parent = frame
	
		return frame
	end
	
	local function createGameMainMenu(baseZIndex, shield)
	
		local buttonTop = 54
	
		local gameMainMenuFrame = Instance.new("Frame")
		gameMainMenuFrame.Name = "GameMainMenu"
		gameMainMenuFrame.BackgroundTransparency = 1
		gameMainMenuFrame.Size = UDim2.new(1,0,1,0)
		gameMainMenuFrame.ZIndex = baseZIndex + 4
		-- The caller attaches this frame to settingsFrame.
	
		-- GameMainMenu Children
	
		-- RESUME GAME
		local resumeGameButton = createTextButton("Resume Game",Enum.ButtonStyle.RobloxRoundDefaultButton,Enum.FontSize.Size24,UDim2.new(0,340,0,50),UDim2.new(0.5,-170,0,buttonTop))
		resumeGameButton.Name = "resumeGameButton"
		resumeGameButton.ZIndex = baseZIndex + 4
		resumeGameButton.Parent = gameMainMenuFrame
		resumeGameButton.Modal = true
		resumeGameButton.MouseButton1Click:Connect(function() resumeGameFunction(shield) end)
		buttonTop = buttonTop + 51
	
		-- RESET CHARACTER
		local resetButton = createTextButton("Reset Character",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size24,UDim2.new(0,340,0,50),UDim2.new(0.5,-170,0,buttonTop))
		resetButton.Name = "ResetButton"
		resetButton.ZIndex = baseZIndex + 4
		resetButton.Parent = gameMainMenuFrame
		buttonTop = buttonTop + 51
	
		-- GAME SETTINGS
		local gameSettingsButton = createTextButton("Game Settings",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size24,UDim2.new(0,340,0,50),UDim2.new(0.5,-170,0,buttonTop))
		gameSettingsButton.Name = "SettingsButton"
		gameSettingsButton.ZIndex = baseZIndex + 4
		gameSettingsButton.Parent = gameMainMenuFrame
		buttonTop = buttonTop + 51
	
		-- HELP BUTTON
		local robloxHelpButton = createTextButton("Help",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,164,0,50),UDim2.new(0,92,0,buttonTop))
		robloxHelpButton.Name = "HelpButton"
		robloxHelpButton.ZIndex = baseZIndex + 4
		robloxHelpButton.Parent = gameMainMenuFrame
		robloxHelpButton.Visible =  not touchClient
		if macClient or touchClient then
			robloxHelpButton.Size = UDim2.new(0,340,0,50)
			robloxHelpButton.FontSize = Enum.FontSize.Size24
		end
	
		helpButton = robloxHelpButton
	
		local helpDialog = createHelpDialog(baseZIndex)
		helpDialog.Parent = gui
	
		helpButton.MouseButton1Click:Connect(
			function() 
				table.insert(centerDialogs,helpDialog)
				addCenterDialog(helpDialog, Enum.CenterDialogType.ModalDialog,
					--ShowFunction
					function()
						helpDialog.Visible = true
						mainShield.Visible = false
					end,
					--HideFunction
					function()
						helpDialog.Visible = false
					end)
			end)
		helpButton.Active = true
	
		-- SCREEN SHOT
		local screenshotButton = createTextButton("Screenshot",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,168,0,50),UDim2.new(0,264,0,buttonTop))
		screenshotButton.Name = "ScreenshotButton"
		screenshotButton.ZIndex = baseZIndex + 4
		screenshotButton.Parent = gameMainMenuFrame
		screenshotButton.Visible = true -- preserve 2015E button; click just closes menu
		-- Removed engine-only SetVerb; not available to regular LocalScripts.
		if not touchClient then
			buttonTop = buttonTop + 51
		end
	
		-- REPORT ABUSE
		local reportAbuseButton = createTextButton("Report Abuse",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,164,0,50),UDim2.new(0,92,0,buttonTop))
		reportAbuseButton.Name = "ReportAbuseButton"
		reportAbuseButton.ZIndex = baseZIndex + 4
		reportAbuseButton.Parent = gameMainMenuFrame
		if macClient or touchClient then
			reportAbuseButton.Size = UDim2.new(0,340,0,50)
			reportAbuseButton.FontSize = Enum.FontSize.Size24
		end
	
		-- RECORD VIDEO
		local recordVideoButton = createTextButton("Record Video",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,168,0,50),UDim2.new(0,264,0,buttonTop))
		recordVideoButton.Name = "RecordVideoButton"
		recordVideoButton.ZIndex = baseZIndex + 4
		recordVideoButton.Parent = gameMainMenuFrame
		recordVideoButton.Visible = true -- preserve 2015E button; click just closes menu
		-- Removed engine-only SetVerb; not available to regular LocalScripts.
		local stopRecordButton = Instance.new("ImageButton")
		stopRecordButton.Name = "StopRecordButton"
		stopRecordButton.BackgroundTransparency = 1
		stopRecordButton.Image = "rbxasset://textures/ui/RecordStop.png"
		stopRecordButton.Size = UDim2.new(0,59,0,27)
		-- Removed engine-only SetVerb; not available to regular LocalScripts.
		stopRecordButton.MouseButton1Click:Connect(function() recordVideoClick(recordVideoButton, stopRecordButton) end)
		stopRecordButton.Visible = false
		stopRecordButton.Parent = gui
		buttonTop = buttonTop + 51
	
		-- LEAVE GAME	
		local leaveGameButton = createTextButton("Leave Game",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size24,UDim2.new(0,340,0,50),UDim2.new(0.5,-170,0,buttonTop))
		leaveGameButton.Name = "LeaveGameButton"
		leaveGameButton.ZIndex = baseZIndex + 4
		leaveGameButton.Parent = gameMainMenuFrame
	
		return gameMainMenuFrame
	end
	
	local function createGameSettingsMenu(baseZIndex, shield)
		local gameSettingsMenuFrame = Instance.new("Frame")
		gameSettingsMenuFrame.Name = "GameSettingsMenu"
		gameSettingsMenuFrame.BackgroundTransparency = 1
		gameSettingsMenuFrame.Size = UDim2.new(1,0,1,0)
		gameSettingsMenuFrame.ZIndex = baseZIndex + 4
	
		local itemTop = 0
		if workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y <= 500 then
			itemTop = 50
		end
		----------------------------------------------------------------------------------------------------
		--  C A M E R A    C O N T R O L S
		----------------------------------------------------------------------------------------------------
	
		if not touchClient then
			local cameraLabel = Instance.new("TextLabel")
			cameraLabel.Name = "CameraLabel"
			if (newMovementScripts) then
				cameraLabel.Text = "Enable Mouse Lock Switch"
			else
				cameraLabel.Text = "Character & Camera Controls"
			end
			cameraLabel.Font = Enum.Font.SourceSansBold
			cameraLabel.FontSize = Enum.FontSize.Size18
			cameraLabel.Position = UDim2.new(0,31,0,itemTop + 6)
			cameraLabel.Size = UDim2.new(0,224,0,18)
			cameraLabel.TextColor3 = Color3I(255,255,255)
			cameraLabel.TextXAlignment = Enum.TextXAlignment.Left
			cameraLabel.BackgroundTransparency = 1
			cameraLabel.ZIndex = baseZIndex + 4
			cameraLabel.Parent = gameSettingsMenuFrame
	
			if (newMovementScripts) then
				local mouseLockDisabled = Instance.new("TextLabel")
				mouseLockDisabled.Name = "mouseLockDisabled"
				mouseLockDisabled.Text = "Set by Game"
				mouseLockDisabled.Font = Enum.Font.SourceSansBold
				mouseLockDisabled.FontSize = Enum.FontSize.Size18
				mouseLockDisabled.Position = UDim2.new(0,275,0,itemTop + 6)
				mouseLockDisabled.Size = UDim2.new(0,200,0,18)
				mouseLockDisabled.TextColor3 = Color3I(180,180,180)
				mouseLockDisabled.TextXAlignment = Enum.TextXAlignment.Left
				mouseLockDisabled.BackgroundTransparency = 1
				mouseLockDisabled.ZIndex = baseZIndex + 4
				mouseLockDisabled.Parent = gameSettingsMenuFrame
	
				settingsChoices["MouseLockDisabled"] = mouseLockDisabled
			end
	
			local mouseLockLabel = nil -- hidden CoreGui elements cannot be modified by ordinary LocalScripts
			if (newMovementScripts) then
				local mouseLockCheckbox = createTextButton("",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,32,0,32),UDim2.new(0, 270, 0, itemTop- 4))
				mouseLockCheckbox.Name = "mouseLockCheckbox"
				mouseLockCheckbox.ZIndex = baseZIndex + 4
				mouseLockCheckbox.Parent = gameSettingsMenuFrame
				if (localPlayer.DevEnableMouseLock and "MouseLockSwitch" or "Classic") == "MouseLockSwitch" then 
					mouseLockCheckbox.Text = "X" 
				end
				mouseLockCheckbox.MouseButton1Click:Connect(function()
					if mouseLockCheckbox.Text == "" then
						mouseLockCheckbox.Text = "X"
						pcall(function() localPlayer.DevEnableMouseLock = true end)
					else
						mouseLockCheckbox.Text = ""
						pcall(function() localPlayer.DevEnableMouseLock = false end)
					end
	
					pcall(function()
						if mouseLockLabel and localPlayer.DevEnableMouseLock then
							mouseLockLabel.Visible = true
						elseif mouseLockLabel then
							mouseLockLabel.Visible = false
						end
					end)
				end)	
				settingsChoices["MouseLockEnabled"] = mouseLockCheckbox
			else
	
				local enumItems = Enum.ControlMode:GetEnumItems()
				local enumNames = {}
				local enumNameToItem = {}
				for i,obj in ipairs(enumItems) do
					enumNames[i] = obj.Name
					enumNameToItem[obj.Name] = obj
				end
	
				local cameraDropDown
				cameraDropDown, updateCameraDropDownSelection = RbxGui.CreateDropDownMenu(enumNames, 
					function(text) 
						UserSettings().GameSettings.ControlMode = enumNameToItem[text] 
	
						pcall(function()
							if mouseLockLabel and localPlayer.DevEnableMouseLock then
								mouseLockLabel.Visible = true
							elseif mouseLockLabel then
								mouseLockLabel.Visible = false
							end
						end)
					end, false, true, baseZIndex + 1)
				cameraDropDown.Name = "CameraField"
				cameraDropDown.Position = UDim2.new(0, 270, 0, itemTop)
				cameraDropDown.Size = UDim2.new(0,200,0,32)
				cameraDropDown.Parent = gameSettingsMenuFrame
			end
	
			itemTop = itemTop + 35
		end
	
		----------------------------------------------------------------------------------------------------
		--  C U S T O M    C A M E R A    C O N T R O L S
		----------------------------------------------------------------------------------------------------
	
		local smartCameraLabel = Instance.new("TextLabel")
		smartCameraLabel.Name = "SmartCameraLabel"
		smartCameraLabel.Text = "Camera Mode"
		smartCameraLabel.Font = Enum.Font.SourceSansBold
		smartCameraLabel.FontSize = Enum.FontSize.Size18
		smartCameraLabel.Position = UDim2.new(0,31,0,itemTop + 6)
		smartCameraLabel.Size = UDim2.new(0,224,0,18)
		smartCameraLabel.TextColor3 = Color3I(255,255,255)
		smartCameraLabel.TextXAlignment = Enum.TextXAlignment.Left
		smartCameraLabel.BackgroundTransparency = 1
		smartCameraLabel.ZIndex = baseZIndex + 4
		smartCameraLabel.Parent = gameSettingsMenuFrame
	
		if (newMovementScripts) then
			local smartCameraDisabled = Instance.new("TextLabel")
			smartCameraDisabled.Name = "smartCameraDisabled"
			smartCameraDisabled.Text = "Set by Game"
			smartCameraDisabled.Font = Enum.Font.SourceSansBold
			smartCameraDisabled.FontSize = Enum.FontSize.Size18
			smartCameraDisabled.Position = UDim2.new(0,275,0,itemTop + 6)
			smartCameraDisabled.Size = UDim2.new(0,200,0,18)
			smartCameraDisabled.TextColor3 = Color3I(180,180,180)
			smartCameraDisabled.TextXAlignment = Enum.TextXAlignment.Left
			smartCameraDisabled.BackgroundTransparency = 1
			smartCameraDisabled.ZIndex = baseZIndex + 4
			smartCameraDisabled.Parent = gameSettingsMenuFrame
	
			settingsChoices["CameraModeDevChoice"] = smartCameraDisabled
		end
	
		local smartEnumItems = nil
		if (not newMovementScripts) then
			smartEnumItems = Enum.ComputerCameraMovementMode:GetEnumItems()
		elseif (touchClient) then
			smartEnumItems = Enum.TouchCameraMovementMode:GetEnumItems()
		else
			smartEnumItems = Enum.ComputerCameraMovementMode:GetEnumItems()
		end
	
		local smartEnumNames = {}
		local smartEnumNameToItem = {}
	
		for i,obj in pairs(smartEnumItems) do
			local displayName = obj.Name
			if (obj.Name == "Default") then
				displayName = customCameraDefaultType
			end
			smartEnumNames[i] = displayName
			smartEnumNameToItem[displayName] = obj
		end
	
		local smartCameraDropDown
		smartCameraDropDown, updateSmartCameraDropDownSelection = RbxGui.CreateDropDownMenu(smartEnumNames, 
			function(text) 
				if (not newMovementScripts) then
					UserSettings().GameSettings.ComputerCameraMovementMode = Enum.ComputerCameraMovementMode[text]
				elseif (touchClient) then
					UserSettings().GameSettings.TouchCameraMovementMode = Enum.TouchCameraMovementMode[text] 
				else
					UserSettings().GameSettings.ComputerCameraMovementMode = Enum.ComputerCameraMovementMode[text] 
				end
			end, false, true, baseZIndex + 1)
		smartCameraDropDown.Name = "SmartCameraField"
		smartCameraDropDown.Position = UDim2.new(0, 270, 0, itemTop)
		smartCameraDropDown.Size = UDim2.new(0,200,0,32)
		smartCameraDropDown.Parent = gameSettingsMenuFrame
	
		settingsChoices["CameraModeUserChoice"] = smartCameraDropDown
	
		itemTop = itemTop + 35
	
	
		----------------------------------------------------------------------------------------------------
		--  T O U C H    M O V E M E N T    C O N T R O L S
		----------------------------------------------------------------------------------------------------
	
		if (touchClient or newMovementScripts) then
			local movementModeLabel = Instance.new("TextLabel")
			movementModeLabel.Name = "movementModeLabel"
			movementModeLabel.Text = "Movement Mode"
			movementModeLabel.Font = Enum.Font.SourceSansBold
			movementModeLabel.FontSize = Enum.FontSize.Size18
			movementModeLabel.Position = UDim2.new(0,31,0,itemTop + 6)
			movementModeLabel.Size = UDim2.new(0,224,0,18)
			movementModeLabel.TextColor3 = Color3I(255,255,255)
			movementModeLabel.TextXAlignment = Enum.TextXAlignment.Left
			movementModeLabel.BackgroundTransparency = 1
			movementModeLabel.ZIndex = baseZIndex + 4
			movementModeLabel.Parent = gameSettingsMenuFrame
	
			if (newMovementScripts) then
				local movementModeDisabled = Instance.new("TextLabel")
				movementModeDisabled.Name = "movementModeDisabled"
				movementModeDisabled.Text = "Set by Game"
				movementModeDisabled.Font = Enum.Font.SourceSansBold
				movementModeDisabled.FontSize = Enum.FontSize.Size18
				movementModeDisabled.Position = UDim2.new(0,275,0,itemTop + 6)
				movementModeDisabled.Size = UDim2.new(0,200,0,18)
				movementModeDisabled.TextColor3 = Color3I(180,180,180)
				movementModeDisabled.TextXAlignment = Enum.TextXAlignment.Left
				movementModeDisabled.BackgroundTransparency = 1
				movementModeDisabled.ZIndex = baseZIndex + 4
				movementModeDisabled.Parent = gameSettingsMenuFrame
	
				settingsChoices["MovementModeDevChoice"] = movementModeDisabled
			end
	
			local enumNames
			local enumNameToItem 
			if (touchClient) then
				local touchEnumItems = Enum.TouchMovementMode:GetEnumItems()
				local touchEnumNames = {}
				local touchEnumNameToItem = {}
				for i,obj in ipairs(touchEnumItems) do
					local displayName = obj.Name
					if (obj.Name == "Default") then
						displayName = "Default (Thumbstick)"
					end
					touchEnumNames[i] = displayName
					touchEnumNameToItem[displayName] = obj
				end
				enumNames = touchEnumNames
				enumNameToItem = touchEnumNameToItem
			else 
				local computerEnumItems = Enum.ComputerMovementMode:GetEnumItems()
				local computerEnumNames = {}
				local computerEnumNameToItem = {}
				for i,obj in ipairs(computerEnumItems) do
					local displayName = obj.Name
					if (obj.Name == "Default") then
						displayName = "Default (Keyboard)"
					end
					computerEnumNames[i] = displayName
					computerEnumNameToItem[displayName] = obj
				end
				enumNames = computerEnumNames
				enumNameToItem = computerEnumNameToItem
			end
	
			local movementModeDropDown
			movementModeDropDown,  updateMovementDropDownSelection = RbxGui.CreateDropDownMenu(enumNames, 
				function(text) 
					if (touchClient) then
						UserSettings().GameSettings.TouchMovementMode = enumNameToItem[text]
					else
						UserSettings().GameSettings.ComputerMovementMode = enumNameToItem[text]
					end
				end, false, true, baseZIndex + 1)
			movementModeDropDown.Name = "movementModeField"
			movementModeDropDown.Position = UDim2.new(0, 270, 0, itemTop)
			movementModeDropDown.Size = UDim2.new(0,200,0,32)
			movementModeDropDown.Parent = gameSettingsMenuFrame
	
			settingsChoices["MovementModeUserChoice"] = movementModeDropDown
	
			itemTop = itemTop + 35
		end
	
		----------------------------------------------------------------------------------------------------
		--  V I D E O   C A P T U R E   S E T T I N G S
		----------------------------------------------------------------------------------------------------
	
		-- Roblox removed the old video upload settings and UploadSetting enum.
		-- Keep the original settings menu layout without accessing removed engine APIs.
		local syncVideoCaptureSetting = nil
		if not macClient and not touchClient then
			local videoCaptureLabel = Instance.new("TextLabel")
			videoCaptureLabel.Name = "VideoCaptureLabel"
			videoCaptureLabel.Text = "After Capturing Video"
			videoCaptureLabel.Font = Enum.Font.SourceSansBold
			videoCaptureLabel.TextSize = 18
			videoCaptureLabel.Position = UDim2.new(0, 32, 0, itemTop + 6)
			videoCaptureLabel.Size = UDim2.new(0, 220, 0, 18)
			videoCaptureLabel.BackgroundTransparency = 1
			videoCaptureLabel.TextColor3 = Color3I(255,255,255)
			videoCaptureLabel.TextXAlignment = Enum.TextXAlignment.Left
			videoCaptureLabel.ZIndex = baseZIndex + 4
			videoCaptureLabel.Parent = gameSettingsMenuFrame
	
			local unsupportedLabel = Instance.new("TextLabel")
			unsupportedLabel.Name = "VideoCaptureField"
			unsupportedLabel.Text = "No longer supported"
			unsupportedLabel.Font = Enum.Font.SourceSans
			unsupportedLabel.TextSize = 16
			unsupportedLabel.Position = UDim2.new(0, 270, 0, itemTop)
			unsupportedLabel.Size = UDim2.new(0, 200, 0, 32)
			unsupportedLabel.TextColor3 = Color3I(180,180,180)
			unsupportedLabel.BackgroundTransparency = 1
			unsupportedLabel.ZIndex = baseZIndex + 4
			unsupportedLabel.Parent = gameSettingsMenuFrame
			itemTop = itemTop + 35
		end
	
		----------------------------------------------------------------------------------------------------
		-- F U L L  S C R E E N    M O D E
		----------------------------------------------------------------------------------------------------
	
		local fullscreenText = nil
		local fullscreenShortcut = nil
		local fullscreenCheckbox = nil
	
		if not touchClient then
	
			itemTop = itemTop + 15
	
			fullscreenText = Instance.new("TextLabel")
			fullscreenText.Name = "FullscreenText"
			fullscreenText.Text = "Fullscreen Mode"
	
			fullscreenText.Position = UDim2.new(0,31,0,itemTop + 6)
			fullscreenText.Size = UDim2.new(0,224,0,18)
	
			fullscreenText.Font = Enum.Font.SourceSansBold
			fullscreenText.FontSize = Enum.FontSize.Size18
			fullscreenText.TextXAlignment = Enum.TextXAlignment.Left
			fullscreenText.TextColor3 = Color3.new(1,1,1)
			fullscreenText.ZIndex = baseZIndex + 4
			fullscreenText.BackgroundTransparency = 1
			fullscreenText.Parent = gameSettingsMenuFrame
	
			fullscreenCheckbox = createTextButton("",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,32,0,32),UDim2.new(0, 270, 0, itemTop- 4))
			fullscreenCheckbox.Name = "FullscreenCheckbox"
			fullscreenCheckbox.Visible = false -- fullscreen is controlled by Roblox/OS
			fullscreenCheckbox.ZIndex = baseZIndex + 4
			fullscreenCheckbox.Parent = gameSettingsMenuFrame
			-- Removed engine-only SetVerb; not available to regular LocalScripts.
			if UserSettings().GameSettings:InFullScreen() then fullscreenCheckbox.Text = "X" end
			if hasGraphicsSlider then
				UserSettings().GameSettings.FullscreenChanged:Connect(function(isFullscreen)
					if isFullscreen then
						fullscreenCheckbox.Text = "X"
					else
						fullscreenCheckbox.Text = ""
					end
				end)
			else
				fullscreenCheckbox.MouseButton1Click:Connect(function()
					if fullscreenCheckbox.Text == "" then
						fullscreenCheckbox.Text = "X"
					else
						fullscreenCheckbox.Text = ""
					end
				end)	
			end
		end
	
		----------------------------------------------------------------------------------------------------
		-- G R A P H I C S    S L I D E R
		----------------------------------------------------------------------------------------------------
		local graphicsSlider, graphicsLevel = nil
		if hasGraphicsSlider then
			local graphicsQualityYOffset = -45
	
			local qualityText = Instance.new("TextLabel")
			qualityText.Name = "QualityText"
			qualityText.Text = "Graphics Quality"
			qualityText.Size = UDim2.new(0,224,0,18)
			qualityText.Position = UDim2.new(0,31,0,239 + graphicsQualityYOffset)
	
			qualityText.TextXAlignment = Enum.TextXAlignment.Left
			qualityText.Font = Enum.Font.SourceSansBold
			qualityText.FontSize = Enum.FontSize.Size18
			qualityText.TextColor3 = Color3.new(1,1,1)
			qualityText.ZIndex = baseZIndex + 4
			qualityText.BackgroundTransparency = 1
			qualityText.Parent = gameSettingsMenuFrame
			qualityText.Visible = not inStudioMode
	
			local autoText = qualityText:Clone()
			autoText.Name = "AutoText"
			autoText.Text = "Auto"
			autoText.Position = UDim2.new(0,235,0,239 + graphicsQualityYOffset)
			autoText.TextColor3 = Color3.new(128/255,128/255,128/255)
			autoText.Size = UDim2.new(0,34,0,18)
			autoText.Parent = gameSettingsMenuFrame
			autoText.Visible = not inStudioMode
	
			local fasterText = autoText:Clone()
			fasterText.Name = "FasterText"
			fasterText.Text = "Faster"
			fasterText.Position = UDim2.new(0,185,0,274 + graphicsQualityYOffset)
			fasterText.TextColor3 = Color3.new(95,95,95)
			fasterText.FontSize = Enum.FontSize.Size14
			fasterText.Parent = gameSettingsMenuFrame
			fasterText.Visible = not inStudioMode
	
			local betterQualityText = autoText:Clone()
			betterQualityText.Name = "BetterQualityText"
			betterQualityText.Text = "Better Quality"
			betterQualityText.TextWrap = true
			betterQualityText.Size = UDim2.new(0,41,0,28)
			betterQualityText.Position = UDim2.new(0,390,0,269 + graphicsQualityYOffset)
			betterQualityText.TextColor3 = Color3.new(95,95,95)
			betterQualityText.FontSize = Enum.FontSize.Size14
			betterQualityText.Parent = gameSettingsMenuFrame
			betterQualityText.Visible = not inStudioMode
	
			local autoGraphicsButton = createTextButton("X",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,32,0,32),UDim2.new(0,270,0,232 + graphicsQualityYOffset))
			autoGraphicsButton.Name = "AutoGraphicsButton"
			autoGraphicsButton.ZIndex = baseZIndex + 4
			autoGraphicsButton.Parent = gameSettingsMenuFrame
			autoGraphicsButton.Visible = not inStudioMode
	
			graphicsSlider, graphicsLevel = RbxGui.CreateSliderNew(GraphicsQualityLevels,150,UDim2.new(0, 230, 0, 280 + graphicsQualityYOffset)) -- graphics - 1 because slider starts at 1 instead of 0
			graphicsSlider.Parent = gameSettingsMenuFrame
			graphicsSlider.Bar.ZIndex = baseZIndex + 4
			graphicsSlider.Bar.Slider.ZIndex = baseZIndex + 5
			graphicsSlider.Visible = not inStudioMode
			graphicsLevel.Value = math.floor((settings().Rendering:GetMaxQualityLevel() - 1)/2)
	
			local graphicsSetter = Instance.new("TextBox")
			graphicsSetter.Name = "GraphicsSetter"
			graphicsSetter.BackgroundColor3 = Color3.new(0,0,0)
			graphicsSetter.BorderColor3 = Color3.new(128/255,128/255,128/255)
			graphicsSetter.Size = UDim2.new(0,50,0,25)
			graphicsSetter.Position = UDim2.new(0,450,0,269 + graphicsQualityYOffset)
			graphicsSetter.TextColor3 = Color3.new(1,1,1)
			graphicsSetter.Font = Enum.Font.SourceSansBold
			graphicsSetter.FontSize = Enum.FontSize.Size18
			graphicsSetter.Text = "Auto"
			graphicsSetter.ZIndex = 1
			graphicsSetter.TextWrap = true
			graphicsSetter.Parent = gameSettingsMenuFrame
			graphicsSetter.Visible = not inStudioMode
	
			local isAutoGraphics = true
			if not inStudioMode then
				isAutoGraphics = (UserSettings().GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic)
			else
				-- legacy EnableFRM is unavailable
			end
	
			local listenToGraphicsLevelChange = true
	
			local function setAutoGraphicsGui(active)
				isAutoGraphics = active
				if active then
					autoGraphicsButton.Text = "X"
					betterQualityText.ZIndex = 1
					fasterText.ZIndex = 1
					graphicsSlider.Bar.ZIndex = 1
					graphicsSlider.BarLeft.ZIndex = 1
					graphicsSlider.BarRight.ZIndex = 1
					graphicsSlider.Bar.Fill.ZIndex = 1
					graphicsSlider.FillLeft.ZIndex = 1
					graphicsSlider.Bar.Slider.ZIndex = 1
					graphicsSetter.ZIndex = 1
					graphicsSetter.Text = "Auto"
				else
					autoGraphicsButton.Text = ""
					graphicsSlider.Bar.ZIndex = baseZIndex + 4
					graphicsSlider.Bar.Slider.ZIndex = baseZIndex + 6
					graphicsSlider.BarLeft.ZIndex = baseZIndex + 4
					graphicsSlider.BarRight.ZIndex = baseZIndex + 4
					graphicsSlider.Bar.Fill.ZIndex = baseZIndex + 5
					graphicsSlider.FillLeft.ZIndex = baseZIndex + 5
					betterQualityText.ZIndex = baseZIndex + 4
					fasterText.ZIndex = baseZIndex + 4
					graphicsSetter.ZIndex = baseZIndex + 4
				end
			end
	
			local function goToAutoGraphics()
				setAutoGraphicsGui(true)
	
				UserSettings().GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.Automatic
	
				settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
			end
	
			local function setGraphicsQualityLevel(newLevel)
				local percentage = newLevel/GraphicsQualityLevels
				local newSetting = math.floor((settings().Rendering:GetMaxQualityLevel() - 1) * percentage)
				if newSetting == 20 then -- Level 20 is the same as level 21, except it doesn't render ambient occlusion
					newSetting = 21
				elseif newLevel == 1 then -- make sure we can go to lowest settings (for terrible computers)
					newSetting = 1
				elseif newSetting > settings().Rendering:GetMaxQualityLevel() then
					newSetting = settings().Rendering:GetMaxQualityLevel() - 1
				end
	
				UserSettings().GameSettings.SavedQualityLevel = newLevel
				settings().Rendering.QualityLevel = newSetting
			end
	
			local function goToManualGraphics(explicitLevel)
				setAutoGraphicsGui(false)
	
				if explicitLevel then
					graphicsLevel.Value = explicitLevel
				else
					graphicsLevel.Value = math.floor((settings().Rendering.AutoFRMLevel/(settings().Rendering:GetMaxQualityLevel() - 1)) * GraphicsQualityLevels)
				end
	
				if explicitLevel == graphicsLevel.Value then -- make sure we are actually in right graphics mode
					setGraphicsQualityLevel(graphicsLevel.Value)
				end
	
				if not explicitLevel then
					UserSettings().GameSettings.SavedQualityLevel = graphicsLevel.Value
				end
				graphicsSetter.Text = tostring(graphicsLevel.Value)
			end
	
			local function showAutoGraphics()
				autoText.ZIndex = baseZIndex + 4
				autoGraphicsButton.ZIndex = baseZIndex + 4
			end
	
			local function hideAutoGraphics()
				autoText.ZIndex = 1
				autoGraphicsButton.ZIndex = 1
			end
	
			local function showManualGraphics()
				graphicsSlider.Bar.ZIndex = baseZIndex + 4
				graphicsSlider.Bar.Slider.ZIndex = baseZIndex + 5
				betterQualityText.ZIndex = baseZIndex + 4
				fasterText.ZIndex = baseZIndex + 4
				graphicsSetter.ZIndex = baseZIndex + 4
			end
	
			local function hideManualGraphics()
				betterQualityText.ZIndex = 1
				fasterText.ZIndex = 1
				graphicsSlider.Bar.ZIndex = 1
				graphicsSlider.Bar.Slider.ZIndex = 1
				graphicsSetter.ZIndex = 1
			end
	
			local function translateSavedQualityLevelToInt(savedQualityLevel)
				if savedQualityLevel == Enum.SavedQualitySetting.Automatic then
					return 0
				elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel1 then
					return 1
				elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel2 then
					return 2
				elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel3 then
					return 3
				elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel4 then
					return 4
				elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel5 then
					return 5
				elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel6 then
					return 6
				elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel7 then
					return 7
				elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel8 then
					return 8
				elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel9 then
					return 9
				elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel10 then
					return 10
				end
			end
	
			local function enableGraphicsWidget()
				-- legacy EnableFRM is unavailable
	
				isAutoGraphics = (UserSettings().GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic)
				if isAutoGraphics then
					showAutoGraphics()
					goToAutoGraphics()
				else
					showAutoGraphics()
					showManualGraphics()
					goToManualGraphics(translateSavedQualityLevelToInt(UserSettings().GameSettings.SavedQualityLevel))
				end
			end
	
			local function disableGraphicsWidget()
				hideManualGraphics()
				hideAutoGraphics()
				-- legacy EnableFRM is unavailable
			end
	
			graphicsSetter.FocusLost:Connect(function()
				if isAutoGraphics then 
					graphicsSetter.Text = tostring(graphicsLevel.Value)
					return
				end
	
				local newGraphicsValue = tonumber(graphicsSetter.Text)
				if newGraphicsValue == nil then
					graphicsSetter.Text = tostring(graphicsLevel.Value)
					return
				end
	
				if newGraphicsValue < 1 then newGraphicsValue = 1
				elseif newGraphicsValue >= settings().Rendering:GetMaxQualityLevel() then
					newGraphicsValue = settings().Rendering:GetMaxQualityLevel() - 1
				end
	
				graphicsLevel.Value = newGraphicsValue
				setGraphicsQualityLevel(graphicsLevel.Value)
				graphicsSetter.Text = tostring(graphicsLevel.Value)
			end)
	
			graphicsLevel.Changed:Connect(function(prop)
				if isAutoGraphics then return end
				if not listenToGraphicsLevelChange then return end
	
				graphicsSetter.Text = tostring(graphicsLevel.Value)
				setGraphicsQualityLevel(graphicsLevel.Value)
			end)
	
			-- setup our graphic mode on load
			if inStudioMode or UserSettings().GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic then
				if inStudioMode then
					-- legacy EnableFRM is unavailable
					disableGraphicsWidget()
				else
					-- legacy EnableFRM is unavailable
					goToAutoGraphics()
				end
			else
				-- legacy EnableFRM is unavailable
				goToManualGraphics(translateSavedQualityLevelToInt(UserSettings().GameSettings.SavedQualityLevel))
			end
	
			autoGraphicsButton.MouseButton1Click:Connect(function()
				if inStudioMode and not game:GetService("Players").LocalPlayer then return end
	
				if not isAutoGraphics then
					goToAutoGraphics()
				else
					goToManualGraphics(graphicsLevel.Value)
				end
			end)
	
			local lastUpdate = nil
			game.GraphicsQualityChangeRequest:Connect(function(graphicsIncrease)
				if isAutoGraphics then return end -- only can set graphics in manual mode
	
				if graphicsIncrease then
					if (graphicsLevel.Value + 1) > GraphicsQualityLevels then return end
					graphicsLevel.Value = graphicsLevel.Value + 1
					graphicsSetter.Text = tostring(graphicsLevel.Value)
					setGraphicsQualityLevel(graphicsLevel.Value)
	
					game:GetService("GuiService"):SendNotification("Graphics Quality",
						"Increased to (" .. graphicsSetter.Text .. ")",
						"",
						2,
						function()
						end)
				else
					if (graphicsLevel.Value - 1) <= 0 then return end
					graphicsLevel.Value = graphicsLevel.Value - 1
					graphicsSetter.Text = tostring(graphicsLevel.Value)
					setGraphicsQualityLevel(graphicsLevel.Value)
	
					game:GetService("GuiService"):SendNotification("Graphics Quality",
						"Decreased to (" .. graphicsSetter.Text .. ")",
						"",
						2,
						function()
						end)
				end
			end)
	
			game:GetService("Players").PlayerAdded:Connect(function(player)
				if player == game:GetService("Players").LocalPlayer and inStudioMode then
					enableGraphicsWidget()
				end
			end)
			game:GetService("Players").PlayerRemoving:Connect(function(player)
				if player == game:GetService("Players").LocalPlayer and inStudioMode then
					disableGraphicsWidget()
				end
			end)
	
			local wasManualGraphics = (settings().Rendering.QualityLevel ~= Enum.QualityLevel.Automatic)
			if inStudioMode and not game:GetService("Players").LocalPlayer then
				disableGraphicsWidget()
			elseif inStudioMode then
				enableGraphicsWidget()
			end
			if hasGraphicsSlider then
				UserSettings().GameSettings.StudioModeChanged:Connect(function(isStudioMode)
					inStudioMode = isStudioMode
					if isStudioMode then
						wasManualGraphics = (settings().Rendering.QualityLevel ~= Enum.QualityLevel.Automatic)
						goToAutoGraphics()
						autoGraphicsButton.ZIndex = 1
						autoText.ZIndex = 1
					else
						if wasManualGraphics then
							goToManualGraphics()
						end
						autoGraphicsButton.ZIndex = baseZIndex + 4
						autoText.ZIndex = baseZIndex + 4
					end
				end)
			end
	
			if graphicsSlider and graphicsSlider.Bar and graphicsSlider.Visible then
				itemTop = graphicsSlider.Bar.Position.Y.Offset + 20
			end
		end
		----------------------------------------------------------------------------------------------------
		-- V O L U M E    S L I D E R
		----------------------------------------------------------------------------------------------------
		if hasVolumeSlider then
			local maxVolumeLevel = 256
	
			local volumeText = Instance.new("TextLabel")
			volumeText.Name = "VolumeText"
			volumeText.Text = "Volume"
			volumeText.Size = UDim2.new(0,224,0,18)
	
			local volumeTextOffset = 25
			if graphicsSlider and not graphicsSlider.Visible then
				volumeTextOffset = volumeTextOffset + 30
			end
			volumeText.Position = UDim2.new(0,31,0, itemTop + volumeTextOffset)
	
			volumeText.TextXAlignment = Enum.TextXAlignment.Left
			volumeText.Font = Enum.Font.SourceSansBold
			volumeText.FontSize = Enum.FontSize.Size18
			volumeText.TextColor3 = Color3.new(1,1,1)
			volumeText.ZIndex = baseZIndex + 4
			volumeText.BackgroundTransparency = 1
			volumeText.Parent = gameSettingsMenuFrame
			volumeText.Visible = true
	
			local volumeSliderOffset = 32
			if graphicsSlider and not graphicsSlider.Visible then
				volumeSliderOffset = volumeSliderOffset + 30
			end
			local volumeSlider, volumeLevel = RbxGui.CreateSliderNew( maxVolumeLevel,256,UDim2.new(0, 180, 0, itemTop + volumeSliderOffset) )
			volumeSlider.Parent = gameSettingsMenuFrame
			volumeSlider.Bar.ZIndex = baseZIndex + 3
			volumeSlider.Bar.Slider.ZIndex = baseZIndex + 4
			volumeSlider.BarLeft.ZIndex = baseZIndex + 3
			volumeSlider.BarRight.ZIndex = baseZIndex + 3
			volumeSlider.Bar.Fill.ZIndex = baseZIndex + 3
			volumeSlider.FillLeft.ZIndex = baseZIndex + 3
			volumeSlider.Visible = true
			volumeLevel.Value = math.min(math.max(UserSettings().GameSettings.MasterVolume * maxVolumeLevel, 1), maxVolumeLevel)
	
			volumeLevel.Changed:Connect(function(prop)
				local volume = volumeLevel.Value - 1 -- smallest value is 1, so need to subtract one for muting
				UserSettings().GameSettings.MasterVolume = volume/maxVolumeLevel
			end)
	
			itemTop = itemTop + volumeSliderOffset
		end
	
	
		----------------------------------------------------------------------------------------------------
		--  O K    B U T T O N
		----------------------------------------------------------------------------------------------------
	
	
		local backButton
		if hasGraphicsSlider then
			backButton = createTextButton("OK",Enum.ButtonStyle.RobloxRoundDefaultButton,Enum.FontSize.Size24,UDim2.new(0,180,0,50),UDim2.new(0,170,0,315))
			backButton.Modal = true
		else
			backButton = createTextButton("OK",Enum.ButtonStyle.RobloxRoundDefaultButton,Enum.FontSize.Size24,UDim2.new(0,180,0,50),UDim2.new(0,170,0,270))
			backButton.Modal = true
		end
	
		backButton.Name = "BackButton"
		backButton.ZIndex = baseZIndex + 4
		backButton.Parent = gameSettingsMenuFrame
	
		if (newMovementScripts) then
			updateUserSettings()
			game.Players.LocalPlayer.Changed:Connect(function(prop) 
				if prop == "DevTouchMovementMode" or prop == "DevComputerMovementMode" or prop == "DevTouchCameraMode" or prop == "DevComputerCameraMode" or
					prop == "DevEnableMouseLock" then
					updateUserSettings()
				end
			end)
		end
	
		return gameSettingsMenuFrame
	end
	
	function updateUserSettings()	
		if not newMovementScripts then return end
	
		local player = game.Players.LocalPlayer
		if (touchClient) then
			if (player.DevTouchMovementMode.Name == "UserChoice") then
				settingsChoices["MovementModeDevChoice"].Visible = false
				settingsChoices["MovementModeUserChoice"].Visible = true
			else
				settingsChoices["MovementModeDevChoice"].Visible = true
				settingsChoices["MovementModeUserChoice"].Visible = false
			end
			if (player.DevTouchCameraMode.Name == "UserChoice") then
				settingsChoices["CameraModeDevChoice"].Visible = false
				settingsChoices["CameraModeUserChoice"].Visible = true
			else
				settingsChoices["CameraModeDevChoice"].Visible = true
				settingsChoices["CameraModeUserChoice"].Visible = false
			end
		else
			if (player.DevComputerMovementMode.Name == "UserChoice") then
				settingsChoices["MovementModeDevChoice"].Visible = false
				settingsChoices["MovementModeUserChoice"].Visible = true
			else
				settingsChoices["MovementModeDevChoice"].Visible = true
				settingsChoices["MovementModeUserChoice"].Visible = false
			end	
			if (player.DevComputerCameraMode.Name == "UserChoice") then
				settingsChoices["CameraModeDevChoice"].Visible = false
				settingsChoices["CameraModeUserChoice"].Visible = true
			else
				settingsChoices["CameraModeDevChoice"].Visible = true
				settingsChoices["CameraModeUserChoice"].Visible = false
			end
			settingsChoices["MouseLockEnabled"].Visible = player.DevEnableMouseLock
			settingsChoices["MouseLockDisabled"].Visible = not player.DevEnableMouseLock
		end
	end
	
	local showMainMenu = nil 
	
	do -- original RbxGui loaded from Libraries
		local baseZIndex = 4
		if UserSettings then
	
			waitForChild(gui,"TopLeftControl")
			waitForChild(gui,"BottomLeftControl")
	
	
			local settingButtonParent = gui:WaitForChild("TopLeftControl") 
			local createSettingsDialog = function()
				if touchClient then
					waitForChild(gui,"TopLeftControl")
				else
					settingButtonParent = gui:WaitForChild("BottomLeftControl")
				end
	
				settingsButton = settingButtonParent:FindFirstChild("SettingsButton")
	
				if settingsButton == nil then
					settingsButton = Instance.new("ImageButton")
					settingsButton.Name = "SettingsButton"
					settingsButton.Image = "rbxasset://textures/ui/homeButton.png"
					settingsButton.BackgroundTransparency = 1
					settingsButton.Active = false
					settingsButton.Size = UDim2.new(0,36,0,28)
					if (touchClient) then
						settingsButton.Position = UDim2.new(0,2,0,-3)
					else
						settingsButton.Position = UDim2.new(0, 15, 1, -50)
					end
					settingsButton.Parent = settingButtonParent
				end
	
				local shield = Instance.new("TextButton")
				shield.Text = ""
				shield.Name = "UserSettingsShield"
				shield.Active = true
				shield.AutoButtonColor = false
				shield.Visible = false
				shield.Size = UDim2.new(1,0,1,0)
				shield.BackgroundColor3 = Color3I(51,51,51)
				shield.BorderColor3 = Color3I(27,42,53)
				shield.BackgroundTransparency = 0.4
				shield.ZIndex = baseZIndex + 2
				mainShield = shield
	
				local frame = Instance.new("Frame")
				frame.Name = "Settings"
				frame.Position = UDim2.new(0.5, -262, -0.5, -200)
				frame.Size = UDim2.new(0, 525, 0, 430)
				frame.BackgroundTransparency = 1
				frame.Active = true
				frame.Parent = shield
	
				local settingsFrame = Instance.new("Frame")
				settingsFrame.Name = "SettingsStyle"
				settingsFrame.Size = UDim2.new(1, 0, 1, 0)
				settingsFrame.Style = Enum.FrameStyle.DropShadow
				settingsFrame.Active = true
				settingsFrame.ZIndex = baseZIndex + 3
				settingsFrame.Parent = frame
	
				local gameMainMenu = createGameMainMenu(baseZIndex, shield)
				gameMainMenu.Parent = settingsFrame
	
				-- Capture buttons retain their original appearance, but simply close instantly.
				local function closeForCapture()
					shield.Visible = false
					shield.Settings.Position = UDim2.new(0.5, -262, -0.5, -200)
					settingsButton.Active = true
					currentMenuSelection = nil
					lastMenuSelection = {}
					for i = #centerDialogs, 1, -1 do
						local dialog = centerDialogs[i]
						if dialog then dialog.Visible = false end
						centerDialogs[i] = nil
					end
				end
				gameMainMenu.ScreenshotButton.MouseButton1Click:Connect(closeForCapture)
				gameMainMenu.RecordVideoButton.MouseButton1Click:Connect(closeForCapture)
	
				if false then -- removed internal Game Options APIs
					pcall(function()
						settings():FindFirstChild("Game Options").VideoRecordingChangeRequest:Connect(function(recording)
							recordingVideo = recording
							setRecordGui(recording, gui.StopRecordButton, gameMainMenu.RecordVideoButton)
						end)
					end)
				end
	
				gui.Changed:Connect(function(prop) -- We have stopped recording when we resize
					if prop == "AbsoluteSize" and recordingVideo then
						recordVideoClick(gameMainMenu.RecordVideoButton, gui.StopRecordButton)
					end
				end)
	
				function localPlayerChange()
					gameMainMenu.ResetButton.Visible = game:GetService("Players").LocalPlayer ~= nil
					if game:GetService("Players").LocalPlayer then
						-- legacy EnableFRM is unavailable
					elseif inStudioMode then
						-- legacy EnableFRM is unavailable
					end
				end
	
				gameMainMenu.ResetButton.Visible = game:GetService("Players").LocalPlayer ~= nil
				if game:GetService("Players").LocalPlayer ~= nil then
					game:GetService("Players").LocalPlayer.Changed:Connect(function()
						localPlayerChange()
					end)
				else
					task.delay(0,function()
						waitForProperty(game:GetService("Players"),"LocalPlayer")
						gameMainMenu.ResetButton.Visible = game:GetService("Players").LocalPlayer ~= nil
						game:GetService("Players").LocalPlayer.Changed:Connect(function()
							localPlayerChange()
						end)
					end)
				end
	
				gameMainMenu.ReportAbuseButton.Visible = true
				gameMainMenu.ReportAbuseButton.Active = true
	
				gameMainMenu.ResetButton.MouseButton1Click:Connect(function()
					goToMenu(settingsFrame,"ResetConfirmationMenu","up",UDim2.new(0,525,0,370))
				end)
	
				local leaveGameButton = gameMainMenu:FindFirstChild("LeaveGameButton")
				if (leaveGameButton) then
					gameMainMenu.LeaveGameButton.MouseButton1Click:Connect(function()
						goToMenu(settingsFrame,"LeaveConfirmationMenu","down",UDim2.new(0,525,0,300))
					end)
				end
	
				showMainMenu = function(overrideMenu, overrideDir, overrideSize)
					if shield.Visible and overrideMenu then
						goToMenu(settingsFrame,overrideMenu,overrideDir,overrideSize)
						return
					end
	
					addCenterDialog(shield, Enum.CenterDialogType.ModalDialog,
						--showFunction
						function()
							settingsButton.Active = false
							if updateCameraDropDownSelection ~= nil then
								updateCameraDropDownSelection((localPlayer.DevEnableMouseLock and "MouseLockSwitch" or "Classic"))
							end
	
							local cameraMode = "None"
							local cameraOk, cameraValue = pcall(function()
								return touchClient and UserSettings().GameSettings.TouchCameraMovementMode.Name or UserSettings().GameSettings.ComputerCameraMovementMode.Name
							end)
							if cameraOk then cameraMode = cameraValue end
							if false then
								cameraMode = UserSettings().GameSettings.ComputerCameraMovementMode.Name
							end
	
							if (cameraMode == "Default") then
								cameraMode = customCameraDefaultType
							end
	
							if updateSmartCameraDropDownSelection then updateSmartCameraDropDownSelection(cameraMode) end
	
							if updateMovementDropDownSelection ~= nil then
								local moveMode = "None"
								if (touchClient) then
									moveMode = UserSettings().GameSettings.TouchMovementMode.Name
									if (moveMode == "Default") then
										moveMode = "Default (Thumbstick)"
									end
								else 
									moveMode = UserSettings().GameSettings.ComputerMovementMode.Name
									if (moveMode == "Default") then
										moveMode = "Default (Keyboard)"
									end
								end
								updateMovementDropDownSelection(moveMode)
							end
	
							pcall(function() game:GetService("UserInputService").OverrideMouseIconEnabled = true end)
							if syncVideoCaptureSetting then
								syncVideoCaptureSetting()
							end
	
							local menuToGoTo = "GameMainMenu"
							local direction = "right"
							local menuSize = UDim2.new(0,525,0,430)
	
							if overrideMenu then
								menuToGoTo = overrideMenu
							end
							if overrideDir then
								direction = overrideDir
							end
							if overrideSize then
								menuSize = overrideSize
							end
	
							goToMenu(settingsFrame,menuToGoTo,direction,menuSize)
							shield.Visible = true
							shield.Active = true
							settingsFrame.Parent:TweenPosition(UDim2.new(0.5, -262,0.5, -200),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
							settingsFrame.Parent:TweenSize(UDim2.new(0,525,0,430),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
						end,
						--hideFunction
						function()
							settingsFrame.Parent:TweenPosition(UDim2.new(0.5, -262,-0.5, -200),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
							settingsFrame.Parent:TweenSize(UDim2.new(0,525,0,430),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
							shield.Visible = false
							settingsButton.Active = true
						end)
				end
	
				UserInputService.InputBegan:Connect(function(input, processed)
					if processed or input.KeyCode ~= Enum.KeyCode.Escape then return end
					if currentMenuSelection == nil then
						showMainMenu()
					elseif #lastMenuSelection > 0 then
						if #centerDialogs > 0 then
							for i = 1, #centerDialogs do
								removeCenterDialog(centerDialogs[i])
								centerDialogs[i].Visible = false
							end
							centerDialogs = {}
						end
	
						goToMenu(lastMenuSelection[#lastMenuSelection]["container"],lastMenuSelection[#lastMenuSelection]["name"],
							lastMenuSelection[#lastMenuSelection]["direction"],lastMenuSelection[#lastMenuSelection]["lastSize"])
	
						table.remove(lastMenuSelection,#lastMenuSelection)
						if #lastMenuSelection == 1 then -- apparently lua can't reduce count to 0... T_T
							lastMenuSelection = {}
						end
					else
						resumeGameFunction(shield)
					end
				end)
	
				local gameSettingsMenu = createGameSettingsMenu(baseZIndex, shield)
				gameSettingsMenu.Visible = false
				gameSettingsMenu.Parent = settingsFrame
	
				gameMainMenu.SettingsButton.MouseButton1Click:Connect(function() 
					goToMenu(settingsFrame,"GameSettingsMenu","left",UDim2.new(0,525,0,350))
				end)
	
				gameSettingsMenu.BackButton.MouseButton1Click:Connect(function()
					goToMenu(settingsFrame,"GameMainMenu","right",UDim2.new(0,525,0,430))
				end)
	
				local resetConfirmationWindow = createResetConfirmationMenu(baseZIndex, shield)
				resetConfirmationWindow.Visible = false
				resetConfirmationWindow.Parent = settingsFrame
	
				local leaveConfirmationWindow = createLeaveConfirmationMenu(baseZIndex,shield)
				leaveConfirmationWindow.Visible = false
				leaveConfirmationWindow.Parent = settingsFrame
	
				robloxLock(shield)
	
				settingsButton.MouseButton1Click:Connect(
					function()
						addCenterDialog(shield, Enum.CenterDialogType.ModalDialog,
							--showFunction
							function()
								settingsButton.Active = false
								if updateCameraDropDownSelection ~= nil then
									updateCameraDropDownSelection((localPlayer.DevEnableMouseLock and "MouseLockSwitch" or "Classic"))
								end
	
								local cameraMode = "None"
								if (not newMovementScripts) then
									cameraMode = UserSettings().GameSettings.ComputerCameraMovementMode.Name
								elseif (touchClient) then
									cameraMode = UserSettings().GameSettings.TouchCameraMovementMode.Name
								else
									cameraMode = UserSettings().GameSettings.ComputerCameraMovementMode.Name
								end
								if (cameraMode == "Default") then
									cameraMode = customCameraDefaultType
								end
								if updateSmartCameraDropDownSelection then updateSmartCameraDropDownSelection(cameraMode) end
	
								if updateMovementDropDownSelection ~= nil then
									local moveMode = "None"
									if (touchClient) then
										moveMode = UserSettings().GameSettings.TouchMovementMode.Name
										if (moveMode == "Default") then
											moveMode = "Default (Thumbstick)"
										end
									else 
										moveMode = UserSettings().GameSettings.ComputerMovementMode.Name
										if (moveMode == "Default") then
											moveMode = "Default (Keyboard)"
										end
									end
									updateMovementDropDownSelection(moveMode)
								end
	
								if syncVideoCaptureSetting then
									syncVideoCaptureSetting()
								end
	
								goToMenu(settingsFrame,"GameMainMenu","right",UDim2.new(0,525,0,430))
								shield.Visible = true
								settingsFrame.Parent:TweenPosition(UDim2.new(0.5, -262,0.5, -200),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
								settingsFrame.Parent:TweenSize(UDim2.new(0,525,0,430),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
							end,
							--hideFunction
							function()
								settingsFrame.Parent:TweenPosition(UDim2.new(0.5, -262,-0.5, -200),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
								settingsFrame.Parent:TweenSize(UDim2.new(0,525,0,430),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
								shield.Visible = false
								settingsButton.Active = true
							end)
					end)
	
				return shield
			end
	
			task.defer(function()
				local ok, err = xpcall(function()
					createSettingsDialog().Parent = gui
	
					settingButtonParent.SettingsButton.Active = true
					--		settingButtonParent.SettingsButton.Position = UDim2.new(0,2,0,-2)
	
					-- MouseLockLabel belongs to protected CoreGui; skip it in this scope.
					-- our script has loaded, get rid of older buttons now
					local leaveGameButton = gui.BottomLeftControl:FindFirstChild("Exit")
					if leaveGameButton then leaveGameButton:Destroy() end
	
					local topLeft = gui:FindFirstChild("TopLeftControl")
					if topLeft then 
						leaveGameButton = topLeft:FindFirstChild("Exit")
						if leaveGameButton then leaveGameButton:Destroy() end
	
						if settingButtonParent ~= topLeft then
							topLeft:Destroy()
						end
					end
				end, debug.traceback)
				if not ok then
					warn("[2015E PATCH] Menu initialization error: " .. tostring(err))
					local fallback = Instance.new("TextButton")
					fallback.Name = "2015EError"
					fallback.Size = UDim2.fromOffset(330, 48)
					fallback.Position = UDim2.new(0, 10, 1, -60)
					fallback.Text = "2015E ERROR - open Output (F9)"
					fallback.TextColor3 = Color3.new(1, 1, 1)
					fallback.BackgroundColor3 = Color3.fromRGB(135, 25, 25)
					fallback.Parent = gui
					fallback.MouseButton1Click:Connect(function() warn(tostring(err)) end)
				end
			end)
	
		end --UserSettings call
	
		local createSaveDialogs = function()
			local shield = Instance.new("TextButton")
			shield.Text = ""
			shield.AutoButtonColor = false
			shield.Name = "SaveDialogShield"
			shield.Active = true
			shield.Visible = false
			shield.Size = UDim2.new(1,0,1,0)
			shield.BackgroundColor3 = Color3I(51,51,51)
			shield.BorderColor3 = Color3I(27,42,53)
			shield.BackgroundTransparency = 0.4
			shield.ZIndex = baseZIndex+1
	
			local clearAndResetDialog
			local save
			local saveLocal
			local dontSave
			local cancel
	
			local messageBoxButtons = {}
			messageBoxButtons[1] = {}
			messageBoxButtons[1].Text = "Save"
			messageBoxButtons[1].Style = Enum.ButtonStyle.RobloxRoundDefaultButton
			messageBoxButtons[1].Function = function() save() end 
			messageBoxButtons[1].ZIndex =  baseZIndex+3
			messageBoxButtons[2] = {}
			messageBoxButtons[2].Text = "Cancel"
			messageBoxButtons[2].Function = function() cancel() end 
			messageBoxButtons[2].Style = Enum.ButtonStyle.RobloxRoundButton
			messageBoxButtons[2].ZIndex =  baseZIndex+3
			messageBoxButtons[3] = {}
			messageBoxButtons[3].Text = "Don't Save"
			messageBoxButtons[3].Function = function() dontSave() end 
			messageBoxButtons[3].Style = Enum.ButtonStyle.RobloxRoundButton
			messageBoxButtons[3].ZIndex =  baseZIndex+3
	
			local saveDialogMessageBox = RbxGui.CreateStyledMessageDialog("Unsaved Changes", "Save your changes to ROBLOX before leaving?", "Confirm", messageBoxButtons)
			saveDialogMessageBox.Visible = true
			saveDialogMessageBox.Parent = shield
			saveDialogMessageBox.ZIndex = baseZIndex+2
			saveDialogMessageBox.Style = Enum.FrameStyle.DropShadow
			saveDialogMessageBox.Title.ZIndex = baseZIndex+3
			saveDialogMessageBox.Message.ZIndex = baseZIndex+3
			saveDialogMessageBox.StyleImage.ZIndex = baseZIndex+3
	
	
			local errorBoxButtons = {}
	
			local buttonOffset = 1
			if game.LocalSaveEnabled then
				errorBoxButtons[buttonOffset] = {}
				errorBoxButtons[buttonOffset].Text = "Save to Disk"
				errorBoxButtons[buttonOffset].Function = function() saveLocal() end 
				buttonOffset = buttonOffset + 1
			end
			errorBoxButtons[buttonOffset] = {}
			errorBoxButtons[buttonOffset].Text = "Keep Playing"
			errorBoxButtons[buttonOffset].Function = function() cancel() end 
			errorBoxButtons[buttonOffset].Style = Enum.ButtonStyle.RobloxRoundButton
			errorBoxButtons[buttonOffset].ZIndex =  baseZIndex+3
			errorBoxButtons[buttonOffset+1] = {}
			errorBoxButtons[buttonOffset+1].Text = "Don't Save"
			errorBoxButtons[buttonOffset+1].Function = function() dontSave() end 
			errorBoxButtons[buttonOffset+1].Style = Enum.ButtonStyle.RobloxRoundButton
			errorBoxButtons[buttonOffset+1].ZIndex =  baseZIndex+3
	
			local errorDialogMessageBox = RbxGui.CreateStyledMessageDialog("Upload Failed", "Sorry, we could not save your changes to ROBLOX. If this problem continues to occur, please make sure your Roblox account has a verified email address.", "Error", errorBoxButtons)
			errorDialogMessageBox.Visible = false
			errorDialogMessageBox.Parent = shield
			errorDialogMessageBox.ZIndex = baseZIndex+2
			errorDialogMessageBox.Style = Enum.FrameStyle.DropShadow
			errorDialogMessageBox.Title.ZIndex = baseZIndex+3
			errorDialogMessageBox.Message.ZIndex = baseZIndex+3
			errorDialogMessageBox.StyleImage.ZIndex = baseZIndex+3
	
			local spinnerDialog = Instance.new("Frame")
			spinnerDialog.Name = "SpinnerDialog"
			spinnerDialog.Style = Enum.FrameStyle.DropShadow
			spinnerDialog.Size = UDim2.new(0, 350, 0, 150)
			spinnerDialog.Position = UDim2.new(.5, -175, .5, -75)
			spinnerDialog.Visible = false
			spinnerDialog.Active = true
			spinnerDialog.ZIndex = baseZIndex+1
			spinnerDialog.Parent = shield
	
			local waitingLabel = Instance.new("TextLabel")
			waitingLabel.Name = "WaitingLabel"
			waitingLabel.Text = "Saving to ROBLOX..."
			waitingLabel.Font = Enum.Font.SourceSansBold
			waitingLabel.FontSize = Enum.FontSize.Size18
			waitingLabel.Position = UDim2.new(0.5, 25, 0.5, 0)
			waitingLabel.TextColor3 = Color3.new(1,1,1)
			waitingLabel.ZIndex = baseZIndex+2
			waitingLabel.Parent = spinnerDialog
	
			local spinnerFrame = Instance.new("Frame")
			spinnerFrame.Name = "Spinner"
			spinnerFrame.Size = UDim2.new(0, 80, 0, 80)
			spinnerFrame.Position = UDim2.new(0.5, -150, 0.5, -40)
			spinnerFrame.BackgroundTransparency = 1
			spinnerFrame.ZIndex = baseZIndex+2
			spinnerFrame.Parent = spinnerDialog
	
			local spinnerIcons = {}
			local spinnerNum = 1
			while spinnerNum <= 8 do
				local spinnerImage = Instance.new("ImageLabel")
				spinnerImage.Name = "Spinner"..spinnerNum
				spinnerImage.Size = UDim2.new(0, 16, 0, 16)
				spinnerImage.Position = UDim2.new(.5+.3*math.cos(math.rad(45*spinnerNum)), -8, .5+.3*math.sin(math.rad(45*spinnerNum)), -8)
				spinnerImage.BackgroundTransparency = 1
				spinnerImage.Image = "http://www.roblox.com/Asset?id=45880710"
				spinnerImage.ZIndex = baseZIndex+3
				spinnerImage.Parent = spinnerFrame
	
				spinnerIcons[spinnerNum] = spinnerImage
				spinnerNum = spinnerNum + 1
			end
	
			save = function()
				saveDialogMessageBox.Visible = false
	
				--Show the spinner dialog
				spinnerDialog.Visible = true
				local spin = true
				--Make it spin
				task.delay(0, function()
					local spinPos = 0
					while spin do
						local pos = 0
	
						while pos < 8 do
							if pos == spinPos or pos == ((spinPos+1)%8) then
								spinnerIcons[pos+1].Image = "http://www.roblox.com/Asset?id=45880668"
							else
								spinnerIcons[pos+1].Image = "http://www.roblox.com/Asset?id=45880710"
							end
	
							pos = pos + 1
						end
						spinPos = (spinPos + 1) % 8
						task.wait(0.2)
					end
				end)
	
				--Do the save while the spinner is going, function will wait
				local result = game:SaveToRoblox()
				if not result then
					--Try once more
					result = game:SaveToRoblox()
				end
	
				--Hide the spinner dialog
				spinnerDialog.Visible = false
				--And cause the delay thread to stop
				spin = false	
	
				--Now process the result
				if result then
					--Success, close
					game:FinishShutdown(false)
					clearAndResetDialog()
				else
					--Failure, show the second dialog prompt
					errorDialogMessageBox.Visible = true
				end
			end
	
			saveLocal = function()
				errorDialogMessageBox.Visible = false
				game:FinishShutdown(true)
				clearAndResetDialog()
			end
	
			dontSave = function()
				saveDialogMessageBox.Visible = false
				errorDialogMessageBox.Visible = false
				game:FinishShutdown(false)
				clearAndResetDialog()
			end
			cancel = function()
				saveDialogMessageBox.Visible = false
				errorDialogMessageBox.Visible = false
				clearAndResetDialog()
			end
	
			clearAndResetDialog = function()
				saveDialogMessageBox.Visible = true
				errorDialogMessageBox.Visible = false
				spinnerDialog.Visible = false
				shield.Visible = false
				removeCenterDialog(shield)
			end
	
			robloxLock(shield)
			shield.Visible = false
			return shield
		end
	
		-- Report Abuse uses the same dropdown as the other menus.
		local createClassicReportDropDown = RbxGui.CreateDropDownMenu
	
		local createReportAbuseDialog = function()
			--Only show things if we are a NetworkClient
			-- TODO: add line back in when not testing report abuse
			-- NetworkClient instance is no longer used as a prerequisite for a LocalScript.
	
			waitForChild(game,"Players")
			waitForProperty(game:GetService("Players"), "LocalPlayer")
			local localPlayer = game:GetService("Players").LocalPlayer
	
			local reportAbuseButton
			waitForChild(gui,"UserSettingsShield")
			waitForChild(gui.UserSettingsShield, "Settings")
			waitForChild(gui.UserSettingsShield.Settings,"SettingsStyle")
			waitForChild(gui.UserSettingsShield.Settings.SettingsStyle,"GameMainMenu")
			waitForChild(gui.UserSettingsShield.Settings.SettingsStyle.GameMainMenu, "ReportAbuseButton")
			reportAbuseButton = gui.UserSettingsShield.Settings.SettingsStyle.GameMainMenu.ReportAbuseButton
	
			local shield = Instance.new("TextButton")
			shield.Name = "ReportAbuseShield"
			shield.Text = ""
			shield.AutoButtonColor = false
			shield.Active = true
			shield.Visible = false
			shield.Size = UDim2.new(1,0,1,0)
			shield.BackgroundColor3 = Color3I(51,51,51)
			shield.BorderColor3 = Color3I(27,42,53)
			shield.BackgroundTransparency = 0.4
			shield.ZIndex = baseZIndex + 1
	
			local closeAndResetDialgo
	
			local messageBoxButtons = {}
			messageBoxButtons[1] = {}
			messageBoxButtons[1].Text = "Ok"
			messageBoxButtons[1].Modal = true
			messageBoxButtons[1].Style = Enum.ButtonStyle.RobloxRoundDefaultButton
			messageBoxButtons[1].ZIndex = baseZIndex+3
			messageBoxButtons[1].Function = function() closeAndResetDialog() end 
			local calmingMessageBox = RbxGui.CreateMessageDialog("Thanks for your report!", "Our moderators will review the chat logs and determine what happened.  The other user is probably just trying to make you mad.\n\nIf anyone used swear words, inappropriate language, or threatened you in real life, please report them for Bad Words or Threats", messageBoxButtons)
			calmingMessageBox.Visible = false
			calmingMessageBox.Parent = shield
			calmingMessageBox.ZIndex = baseZIndex+2
			calmingMessageBox.Style = Enum.FrameStyle.DropShadow
			calmingMessageBox.Title.ZIndex = baseZIndex+3
			calmingMessageBox.Message.ZIndex = baseZIndex+3
	
			local recordedMessageBox = RbxGui.CreateMessageDialog("Thanks for your report!","We've recorded your report for evaluation.", messageBoxButtons)
			recordedMessageBox.Visible = false
			recordedMessageBox.Parent = shield
			recordedMessageBox.ZIndex = baseZIndex+2
			recordedMessageBox.Style = Enum.FrameStyle.DropShadow
			recordedMessageBox.Title.ZIndex = baseZIndex+3
			recordedMessageBox.Message.ZIndex = baseZIndex+3
	
			local normalMessageBox = RbxGui.CreateMessageDialog("Thanks for your report!", "Our moderators will review the chat logs and determine what happened.", messageBoxButtons)
			normalMessageBox.Visible = false
			normalMessageBox.Parent = shield
			normalMessageBox.ZIndex = baseZIndex+2
			normalMessageBox.Style = Enum.FrameStyle.DropShadow
			normalMessageBox.Title.ZIndex = baseZIndex+3
			normalMessageBox.Message.ZIndex = baseZIndex+3
	
			local frame = Instance.new("Frame")
			frame.Name = "Settings"
			frame.Position = UDim2.new(0.5, -240, 0.5, -160)
			frame.Size = UDim2.new(0.0, 480, 0.0, 320)
			frame.BackgroundTransparency = 1
			frame.Active = true
			frame.Parent = shield
	
			local settingsFrame = Instance.new("Frame")
			settingsFrame.Name = "ReportAbuseStyle"
			settingsFrame.Size = UDim2.new(1, 0, 1, 0)
			settingsFrame.Style = Enum.FrameStyle.DropShadow
			settingsFrame.Active = true
			settingsFrame.ZIndex = baseZIndex + 1
			settingsFrame.Parent = frame
	
			local description = Instance.new("TextLabel")
			description.Name = "Description"
			description.Text = "This will send a complete report to a moderator.  The moderator will review the chat log and take appropriate action."
			description.TextColor3 = Color3I(221,221,221)
			description.Position = UDim2.new(0, 10, 0, 10)
			description.Size = UDim2.new(1, -20, 0, 40)
			description.BackgroundTransparency = 1
			description.Font = Enum.Font.SourceSans
			description.FontSize = Enum.FontSize.Size18
			description.TextWrap = true
			description.ZIndex = baseZIndex + 2
			description.TextXAlignment = Enum.TextXAlignment.Left
			description.TextYAlignment = Enum.TextYAlignment.Top
			description.Parent = settingsFrame
	
			local playerLabel = Instance.new("TextLabel")
			playerLabel.Name = "PlayerLabel"
			playerLabel.Text = "Which player?"
			playerLabel.BackgroundTransparency = 1
			playerLabel.Font = Enum.Font.SourceSans
			playerLabel.FontSize = Enum.FontSize.Size18
			playerLabel.Position = UDim2.new(0.025,20,0,92)
			playerLabel.Size 	   = UDim2.new(0.4,0,0,36)
			playerLabel.TextColor3 = Color3I(255,255,255)
			playerLabel.TextXAlignment = Enum.TextXAlignment.Left
			playerLabel.ZIndex = baseZIndex + 2
			playerLabel.Parent = settingsFrame
	
			local gameOrPlayerLabel = Instance.new("TextLabel")
			gameOrPlayerLabel.Name = "TypeLabel"
			gameOrPlayerLabel.Text = "Game or Player:"
			gameOrPlayerLabel.BackgroundTransparency = 1
			gameOrPlayerLabel.Font = Enum.Font.SourceSans
			gameOrPlayerLabel.FontSize = Enum.FontSize.Size18
			gameOrPlayerLabel.Position = UDim2.new(0.025,20,0,55)
			gameOrPlayerLabel.Size 	   = UDim2.new(0.4,0,0,36)
			gameOrPlayerLabel.TextColor3 = Color3I(255,255,255)
			gameOrPlayerLabel.TextXAlignment = Enum.TextXAlignment.Left
			gameOrPlayerLabel.ZIndex = baseZIndex + 2
			gameOrPlayerLabel.Parent = settingsFrame
	
			local abuseLabel = Instance.new("TextLabel")
			abuseLabel.Name = "AbuseLabel"
			abuseLabel.Text = "Type of Abuse:"
			abuseLabel.Font = Enum.Font.SourceSans
			abuseLabel.BackgroundTransparency = 1
			abuseLabel.FontSize = Enum.FontSize.Size18
			abuseLabel.Position = UDim2.new(0.025,20,0,131)
			abuseLabel.Size = UDim2.new(0.4,0,0,36)
			abuseLabel.TextColor3 = Color3I(255,255,255)
			abuseLabel.TextXAlignment = Enum.TextXAlignment.Left
			abuseLabel.ZIndex = baseZIndex + 2
			abuseLabel.Parent = settingsFrame
	
			local abusingPlayer = nil
			local abuse = nil
			local submitReportButton = nil
			local gameOrPlayer = nil
	
			local updatePlayerSelection = nil
			local createPlayersDropDown = function()
				local players = game:GetService("Players")
				local playerNames = {}
				local nameToPlayer = {}
				local children = players:GetChildren()
				local pos = 1
				if children then
					for i, player in ipairs(children) do
						if player:IsA("Player") and player ~= localPlayer then
							playerNames[pos] = player.Name
							nameToPlayer[player.Name] = player
							pos = pos + 1
						end
					end
				end
				local playerDropDown = nil
				playerDropDown, updatePlayerSelection = createClassicReportDropDown(playerNames, 
					function(playerName) 
						abusingPlayer = nameToPlayer[playerName] 
						if abuse and abusingPlayer then
							submitReportButton.Active = true
						end
					end, false, true, baseZIndex)
				playerDropDown.Name = "PlayersComboBox"
				playerDropDown.ZIndex = baseZIndex + 2
				playerDropDown.Position = UDim2.new(.425, 0, 0, 94)
				playerDropDown.Size = UDim2.new(.55,0,0,32)
	
				return playerDropDown
			end
	
			local gameOrPlayerTable = {"Game","Player"}
			local gameOrPlayerDropDown = nil
			gameOrPlayerDropDown = createClassicReportDropDown(gameOrPlayerTable, 
				function(gameOrPlayerText) 
					gameOrPlayer = gameOrPlayerText
					if gameOrPlayer == "Game" then
						submitReportButton.Active = (abuse ~= nil)
						playerLabel.Visible = false
						local playerDropDown = gameOrPlayerDropDown.Parent:FindFirstChild("PlayersComboBox")
						if playerDropDown then
							playerDropDown.Visible = false
						end
					else
						submitReportButton.Active = (abuse ~= nil and abusingPlayer ~= nil)
						playerLabel.Visible = true
						local playerDropDown = gameOrPlayerDropDown.Parent:FindFirstChild("PlayersComboBox")
						if playerDropDown then
							playerDropDown.Visible = true
						end
					end
				end, true, true, baseZIndex)
			gameOrPlayerDropDown.Name = "TypeComboBox"
			gameOrPlayerDropDown.ZIndex = baseZIndex + 2
			gameOrPlayerDropDown.Position = UDim2.new(0.425, 0, 0, 55)
			gameOrPlayerDropDown.Size = UDim2.new(0.55,0,0,32)
			gameOrPlayerDropDown.Parent = settingsFrame
	
			local abuses = {"Swearing","Bullying","Scamming","Dating","Cheating/Exploiting","Personal Questions","Offsite Links","Bad Model or Script","Bad Username"}
			local abuseDropDown, updateAbuseSelection = createClassicReportDropDown(abuses, 
				function(abuseText) 
					abuse = abuseText 
					submitReportButton.Active = (abuse ~= nil and (gameOrPlayer == "Game" or abusingPlayer ~= nil))
				end, true, true, baseZIndex)
			abuseDropDown.Name = "AbuseComboBox"
			abuseDropDown.ZIndex = baseZIndex + 2
			abuseDropDown.Position = UDim2.new(0.425, 0, 0, 133)
			abuseDropDown.Size = UDim2.new(0.55,0,0,32)
			abuseDropDown.Parent = settingsFrame
	
			local shortDescriptionLabel = Instance.new("TextLabel")
			shortDescriptionLabel.Name = "ShortDescriptionLabel"
			shortDescriptionLabel.Text = "Short Description: (optional)"
			shortDescriptionLabel.Font = Enum.Font.SourceSans
			shortDescriptionLabel.FontSize = Enum.FontSize.Size18
			shortDescriptionLabel.Position = UDim2.new(0.025,0,0,165)
			shortDescriptionLabel.Size = UDim2.new(0.95,0,0,36)
			shortDescriptionLabel.TextColor3 = Color3I(255,255,255)
			shortDescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
			shortDescriptionLabel.BackgroundTransparency = 1
			shortDescriptionLabel.ZIndex = baseZIndex + 2
			shortDescriptionLabel.Parent = settingsFrame
	
			local shortDescriptionWrapper = Instance.new("Frame")
			shortDescriptionWrapper.Name = "ShortDescriptionWrapper"
			shortDescriptionWrapper.Position = UDim2.new(0.025,0,0,195)
			shortDescriptionWrapper.Size = UDim2.new(0.95,0,1,-250)
			shortDescriptionWrapper.BackgroundColor3 = Color3I(206,206,206)
			shortDescriptionWrapper.BorderSizePixel = 0
			shortDescriptionWrapper.ZIndex = baseZIndex + 2
			shortDescriptionWrapper.Parent = settingsFrame
	
			local shortDescriptionBox = Instance.new("TextBox")
			shortDescriptionBox.Name = "TextBox"
			shortDescriptionBox.Text = ""
			shortDescriptionBox.ClearTextOnFocus = false
			shortDescriptionBox.Font = Enum.Font.SourceSans
			shortDescriptionBox.FontSize = Enum.FontSize.Size18
			shortDescriptionBox.Position = UDim2.new(0,3,0,3)
			shortDescriptionBox.Size = UDim2.new(1,-6,1,-6)
			shortDescriptionBox.TextColor3 = Color3I(0,0,0)
			shortDescriptionBox.TextXAlignment = Enum.TextXAlignment.Left
			shortDescriptionBox.TextYAlignment = Enum.TextYAlignment.Top
			shortDescriptionBox.TextWrap = true
			shortDescriptionBox.BackgroundColor3 = Color3I(206,206,206)
			shortDescriptionBox.BorderColor3 = Color3I(206,206,206)
			shortDescriptionBox.ZIndex = baseZIndex + 2
			shortDescriptionBox.Parent = shortDescriptionWrapper
	
			submitReportButton = Instance.new("TextButton")
			submitReportButton.Name = "SubmitReportBtn"
			submitReportButton.Active = false
			submitReportButton.Modal = true
			submitReportButton.Font = Enum.Font.SourceSans
			submitReportButton.FontSize = Enum.FontSize.Size18
			submitReportButton.Position = UDim2.new(0.1, 0, 1, -50)
			submitReportButton.Size = UDim2.new(0.35,0,0,40)
			submitReportButton.AutoButtonColor = true
			submitReportButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton 
			submitReportButton.Text = "Submit Report"
			submitReportButton.TextColor3 = Color3I(255,255,255)
			submitReportButton.ZIndex = baseZIndex + 2
			submitReportButton.Parent = settingsFrame
	
			submitReportButton.MouseButton1Click:Connect(function()
				if not submitReportButton.Active then return end
				-- Regular LocalScripts cannot invoke the old Players:ReportAbuse API.
				-- Preserve the original form visually. Route submission to the built-in
				-- Roblox reporting UI where supported; do not claim a report was sent.
				frame.Visible = false
				normalMessageBox.Title.Text = "Report Abuse"
				normalMessageBox.Message.Text = "This classic form cannot submit reports through a LocalScript. Open Roblox's built-in Report menu to submit a real report. No report has been sent."
				normalMessageBox.Visible = true
			end)
	
			local cancelButton = Instance.new("TextButton")
			cancelButton.Name = "CancelBtn"
			cancelButton.Font = Enum.Font.SourceSans
			cancelButton.FontSize = Enum.FontSize.Size18
			cancelButton.Position = UDim2.new(0.55, 0, 1, -50)
			cancelButton.Size = UDim2.new(0.35,0,0,40)
			cancelButton.AutoButtonColor = true
			cancelButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton 
			cancelButton.Text = "Cancel"
			cancelButton.TextColor3 = Color3I(255,255,255)
			cancelButton.ZIndex = baseZIndex + 2
			cancelButton.Parent = settingsFrame
	
			closeAndResetDialog = function()
				--Delete old player combo box
				local oldComboBox = settingsFrame:FindFirstChild("PlayersComboBox")
				if oldComboBox then
					oldComboBox.Parent = nil
				end
	
				abusingPlayer = nil
				if updatePlayerSelection then updatePlayerSelection(nil) end
				abuse = nil
				if updateAbuseSelection then updateAbuseSelection(nil) end
				submitReportButton.Active = false
				shortDescriptionBox.Text = ""
				frame.Visible = true
				calmingMessageBox.Visible = false
				recordedMessageBox.Visible = false
				normalMessageBox.Visible = false
				shield.Visible = false		
				reportAbuseButton.Active = true
				removeCenterDialog(shield)
			end
	
			cancelButton.MouseButton1Click:Connect(closeAndResetDialog)
	
			reportAbuseButton.MouseButton1Click:Connect(
				function() 
					createPlayersDropDown().Parent = settingsFrame
					table.insert(centerDialogs,shield)
					addCenterDialog(shield, Enum.CenterDialogType.ModalDialog, 
						--ShowFunction
						function()
							reportAbuseButton.Active = false
							shield.Visible = true
							mainShield.Visible = false
						end,
						--HideFunction
						function()
							reportAbuseButton.Active = true
							shield.Visible = false
						end)
				end)
	
			robloxLock(shield)
			return shield
		end
	
		local createChatBar = function()
			--Only show a chat bar if we are a NetworkClient
			waitForChild(game, "NetworkClient")
	
			waitForChild(game, "Players")
			waitForProperty(game:GetService("Players"), "LocalPlayer")
	
			local chatBar = Instance.new("Frame")
			chatBar.Name = "ChatBar"
			chatBar.Size = UDim2.new(1, 0, 0, 22)
			chatBar.Position = UDim2.new(0, 0, 1, 0)
			chatBar.BackgroundColor3 = Color3.new(0,0,0)
			chatBar.BorderSizePixel = 0
	
			local chatBox = Instance.new("TextBox")
			chatBox.Text = ""
			chatBox.Visible = false
			chatBox.Size = UDim2.new(1,-4,1,0)
			chatBox.Position = UDim2.new(0,2,0,0)
			chatBox.TextXAlignment = Enum.TextXAlignment.Left
			chatBox.Font = Enum.Font.SourceSansBold
			chatBox.ClearTextOnFocus = false
			chatBox.FontSize = Enum.FontSize.Size14
			chatBox.TextColor3 = Color3.new(1,1,1)
			chatBox.BackgroundTransparency = 1
			--chatBox.Parent = chatBar
	
			local chatButton = Instance.new("TextButton")
			chatButton.Size = UDim2.new(1,-4,1,0)
			chatButton.Position = UDim2.new(0,2,0,0)
			chatButton.AutoButtonColor = false
			chatButton.Text = "To chat click here or press \"/\" key"
			chatButton.TextXAlignment = Enum.TextXAlignment.Left
			chatButton.Font = Enum.Font.SourceSansBold
			chatButton.FontSize = Enum.FontSize.Size14
			chatButton.TextColor3 = Color3.new(1,1,1)
			chatButton.BackgroundTransparency = 1
			--chatButton.Parent = chatBar
	
			local activateChat = function()
				if chatBox.Visible then
					return
				end
				chatButton.Visible = false
				chatBox.Text = ""
				chatBox.Visible = true
				chatBox:CaptureFocus()
			end
	
			chatButton.MouseButton1Click:Connect(activateChat)
	
			local hotKeyEnabled = true
			local toggleHotKey = function(value)
				hotKeyEnabled = value
			end
	
			local guiService = game:GetService("GuiService")
			local newChatMode = pcall(function()
				--guiService:AddSpecialKey(Enum.SpecialKey.ChatHotkey)
				--guiService.SpecialKeyPressed:Connect(function(key) if key == Enum.SpecialKey.ChatHotkey and hotKeyEnabled then activateChat() end end)
			end)
			if not newChatMode then
				--guiService:AddKey("/")
				--guiService.KeyPressed:Connect(function(key) if key == "/" and hotKeyEnabled then activateChat() end end)
			end
	
			chatBox.FocusLost:Connect(
				function(enterPressed)
					if enterPressed then
						if chatBox.Text ~= "" then
							local str = chatBox.Text
							if string.sub(str, 1, 1) == '%' then
								game:GetService("Players"):TeamChat(string.sub(str, 2))
							else
								game:GetService("Players"):Chat(str)
							end
						end
					end
					chatBox.Text = ""
					chatBox.Visible = false
					chatButton.Visible = true
				end)
			robloxLock(chatBar)
			return chatBar, toggleHotKey
		end
	
		--Spawn a thread for the Save dialogs
		local isSaveDialogSupported = false -- old local-save shutdown hooks no longer supported
		if isSaveDialogSupported then
			task.delay(0, 
				function()
					local saveDialogs = createSaveDialogs()
					saveDialogs.Parent = gui
	
					game.RequestShutdown = function()
						table.insert(centerDialogs,saveDialogs)
						addCenterDialog(saveDialogs, Enum.CenterDialogType.QuitDialog,
							--ShowFunction
							function()
								saveDialogs.Visible = true 
							end,
							--HideFunction
							function()
								saveDialogs.Visible = false
							end)
	
						return true
					end
				end)
		end
	
		--Spawn a thread to listen to leave game prompts
		task.spawn(function()
			local showLeaveEvent = nil -- engine-only event; no accessible replacement
			if not showLeaveEvent then return end
	
			function showLeaveConfirmation()
				if showMainMenu then
					showMainMenu("LeaveConfirmationMenu","down",UDim2.new(0,525,0,300))
				end
			end
	
			game:GetService("GuiService").ShowLeaveConfirmation:Connect(function( )
				if currentMenuSelection == nil then
					showLeaveConfirmation()
				else
					resumeGameFunction(gui.UserSettingsShield)
				end
			end)
		end)
	
		-- Restore the original 2015E report layout and wire the menu button to it.
		task.defer(function()
			local ok, err = xpcall(function()
				waitForChild(gui, "UserSettingsShield")
				local reportShield = createReportAbuseDialog()
				reportShield.Parent = gui
			end, debug.traceback)
			if not ok then warn("2015E Report Abuse form initialization: " .. tostring(err)) end
		end)
	
	end -- standalone module scope
	
end;
task.spawn(C_3);

return G2L["1"], require;
