local G2L = {};

-- StarterGui.Cursor
G2L["1"] = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"));
G2L["1"]["DisplayOrder"] = 1000000020;
G2L["1"]["Enabled"] = false;
G2L["1"]["Name"] = [[Cursor]];


-- StarterGui.Cursor.ImageLabel
G2L["2"] = Instance.new("ImageLabel", G2L["1"]);
G2L["2"]["ZIndex"] = 1000000010;
G2L["2"]["BorderSizePixel"] = 0;
G2L["2"]["ScaleType"] = Enum.ScaleType.Crop;
G2L["2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["2"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["2"]["Image"] = [[rbxasset://textures/ArrowFarCursor.png]];
G2L["2"]["Size"] = UDim2.new(0, 64, 0, 64);
G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["2"]["BackgroundTransparency"] = 1;


-- StarterGui.Cursor.ImageLabel.Local
G2L["3"] = Instance.new("LocalScript", G2L["2"]);
-- [ERROR] cannot convert Capabilities, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"
G2L["3"]["Sandboxed"] = true;
G2L["3"]["Name"] = [[Local]];


-- StarterGui.Cursor.ImageLabel.Server
G2L["4"] = Instance.new("Script", G2L["2"]);
-- [ERROR] cannot convert Capabilities, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"
G2L["4"]["Sandboxed"] = true;
G2L["4"]["Name"] = [[Server]];


-- StarterGui.Cursor.ImageLabel.ToLocal
G2L["5"] = Instance.new("RemoteEvent", G2L["2"]);
-- [ERROR] cannot convert Capabilities, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"
G2L["5"]["Name"] = [[ToLocal]];
G2L["5"]["Sandboxed"] = true;


-- StarterGui.Cursor.ImageLabel.Local
local function C_3()
local script = G2L["3"];
	script.Parent.Parent.Enabled = true
	script.Parent.Parent.Name = "OldCursorGui"
	
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	
	local player = Players.LocalPlayer
	local mouse = player:GetMouse()
	local cursor = script.Parent
	
	mouse.Icon = ""
	
	local hovers = 0
	local di = mouse.Icon
	local cdi = false
	
	-- Cursor sizes
	local NORMAL_CURSOR_SIZE = UDim2.fromOffset(64, 64)
	local SHIFTLOCK_CURSOR_SIZE = UDim2.fromOffset(32, 32)
	
	local function hasProperty(object, propertyName)
		local success = pcall(function()
			object[propertyName] = object[propertyName]
		end)
	
		return success
	end
	
	local function checktool()
		local character = player.Character
	
		if character then
			return character:FindFirstChildOfClass("Tool")
		end
	
		return nil
	end
	
	local function isShiftLocked()
		return UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
	end
	
	UserInputService.MouseIconEnabled = false
	
	RunService.RenderStepped:Connect(function()
		local shiftLocked = isShiftLocked()
	
		-- Fix cursor scaling
		if shiftLocked then
			cursor.Size = SHIFTLOCK_CURSOR_SIZE
		else
			cursor.Size = NORMAL_CURSOR_SIZE
		end
	
		if hovers > 0 then
			UserInputService.MouseIconEnabled = false
	
			cursor.Visible = true
			cursor.Image = "rbxasset://textures/ArrowCursor.png"
		else
			local tool = checktool()
	
			if tool ~= nil then
				UserInputService.MouseIconEnabled = true
	
				cursor.Image = "rbxasset://textures/ArrowCursor.png"
				cursor.Visible = false
			else
				UserInputService.MouseIconEnabled = false
				cursor.Visible = true
	
				if mouse.Icon == di then
					if cdi ~= true then
						cursor.Image = "rbxasset://textures/ArrowFarCursor.png"
	
						UserInputService.MouseIconEnabled = false
						cursor.Visible = true
					else
						UserInputService.MouseIconEnabled = true
						cursor.Visible = false
					end
				else
					if cdi ~= true then
						cursor.Image = mouse.Icon
	
						UserInputService.MouseIconEnabled = false
						cursor.Visible = true
					else
						UserInputService.MouseIconEnabled = true
						cursor.Visible = false
					end
				end
			end
		end
	end)
	
	local function check(o)
		if o:IsA("GuiObject")
			and hasProperty(o, "Active")
			and o.Active == true then
	
			o.MouseEnter:Connect(function()
				hovers += 1
			end)
	
			o.MouseLeave:Connect(function()
				hovers = math.max(0, hovers - 1)
			end)
		end
	end
	
	local function newchild(o)
		check(o)
	
		o.ChildAdded:Connect(function(c)
			check(c)
		end)
	end
	
	for _, gobj in pairs(player.PlayerGui:GetDescendants()) do
		newchild(gobj)
	end
	
	player.PlayerGui.ChildAdded:Connect(function(c)
		check(c)
	
		for _, gobj in pairs(c:GetDescendants()) do
			newchild(gobj)
		end
	end)
	
	RunService.RenderStepped:Connect(function()
		if isShiftLocked() then
			-- Shift Lock cursor is centered.
			cursor.Position = UDim2.new(
				0.5, -16,
				0.5, -16
			)
		else
			cursor.Position = UDim2.fromOffset(
				mouse.X,
				mouse.Y
			)
		end
	end)
end;
task.spawn(C_3);

return G2L["1"], require;
