-- OldLightning | single LocalScript conversion
-- Place in StarterPlayer > StarterCharacterScripts.
-- All lighting effects and the Glow MaterialVariant are built at runtime.
-- Based on the supplied OldLightning.rbxmx. Applies visual changes locally.

local Lighting = game:GetService("Lighting")
local MaterialService = game:GetService("MaterialService")

local function ensureEffect(className, name, properties)
    local effect = Lighting:FindFirstChild(name)
    if not effect or not effect:IsA(className) then
        effect = Instance.new(className)
        effect.Name = name
        effect.Parent = Lighting
    end
    for property, value in pairs(properties) do
        pcall(function() effect[property] = value end)
    end
    return effect
end

-- Originally embedded instances in the .rbxmx file:
local grading = ensureEffect("ColorGradingEffect", "ColorGrading", {
    Enabled = true,
})
-- The original has TonemapperPreset token = 1; this setting is applied only
-- where the matching property and enum are exposed to normal scripts.
pcall(function()
    local enumItem = Enum.TonemapperPreset and Enum.TonemapperPreset:GetEnumItems()[2]
    if enumItem then grading.TonemapperPreset = enumItem end
end)

ensureEffect("ColorCorrectionEffect", "LegacyColor", {
    Enabled = true, Brightness = 0, Contrast = -0.05,
    Saturation = 0, TintColor = Color3.new(1, 1, 1),
})
ensureEffect("BloomEffect", "NoBloom", {
    Enabled = true, Intensity = 0, Size = 24, Threshold = 0.95,
})

local glow = MaterialService:FindFirstChild("Glow")
if not glow or not glow:IsA("MaterialVariant") then
    glow = Instance.new("MaterialVariant")
    glow.Name = "Glow"
    glow.Parent = MaterialService
end
pcall(function() glow.BaseMaterial = Enum.Material.SmoothPlastic end)
pcall(function() glow.EmissiveStrength = 4 end)
pcall(function() glow.StudsPerTile = 10 end)

-- Original legacy lighting logic follows, adapted to run without child instances.

local LastShadow = game.Lighting.GlobalShadows

local FogIgnore = false
local Ignore = false
local ExcludeTransparent = true
local Deferred = false -- Must be set depending on workspace.SignalBehavior value

local function AdjustColor(Color)
	local H,S,V = Color:ToHSV()
	return Color3.fromHSV(H,math.clamp(S / (2 - (0.75 * V)),0,1),math.clamp(V ^ (0.59 + V/1.41) + 4/255,0,205/255))
end

local function Adjust(v)
	if v:HasTag("Ignore_Legacy") then
		return
	end
	if v:IsA("BasePart") then -- Might redo this, code is kinda messy
		if v.Material == Enum.Material.Neon then
			v.Material = Enum.Material.SmoothPlastic
			v.MaterialVariant = "Glow"
		end
		v:GetPropertyChangedSignal("Material"):Connect(function()
			if v.Material == Enum.Material.Neon then
				v.Material = Enum.Material.SmoothPlastic
				v.MaterialVariant = "Glow"
			end
		end)
		--[[local bool = false
		local connect
		local originalcolor = v.Color
		if v.Material == Enum.Material.Neon then
			v.Color = AdjustColor(v.Color)
			connect = v:GetPropertyChangedSignal("Color"):Connect(function()
				if v.Material == Enum.Material.Neon then
					if bool == false then
						originalcolor = v.Color
						bool = true
						v.Color = AdjustColor(v.Color)
						if Deferred then
							task.defer(function()
								bool = false
							end)
						else
							bool = false
						end
					end
				else
					connect:Disconnect()
					v.Color = originalcolor
				end
			end)
		end
		v:GetPropertyChangedSignal("Material"):Connect(function()
			if v.Material == Enum.Material.Neon then
				v.Color = AdjustColor(v.Color)
				connect = v:GetPropertyChangedSignal("Color"):Connect(function()
					if bool == false then
						originalcolor = v.Color
						bool = true
						v.Color = AdjustColor(v.Color)
						if Deferred then
							task.defer(function()
								bool = false
							end)
						else
							bool = false
						end
					end
				end)
			else
				connect:Disconnect()
				v.Color = originalcolor
			end
		end)]]
	elseif v:IsA("Light") then -- Quite inaccurate
		local Light
		v.Brightness = math.min(v.Brightness,1.5)
		if v.Brightness > 0 then
			v.Brightness /= 2 * 1/v.Brightness
		end
		v.Range -= 4 * v.Range/60
		if v:IsA("SpotLight") then
			v.Angle *= 0.75
		end
		Light = v:Clone()
		Light.Range /= 2
		if Light:IsA("SurfaceLight") then
			Light.Angle /= 2
		end
		Light:AddTag("Ignore_Legacy")
		Light.Parent = v.Parent
	end
end

local function ShadowFix(Part)
	if Part.Name == "PartialShadow" then
		return
	end
	if Part:IsA("BasePart") and not Part:IsA("MeshPart") and not Part:IsA("UnionOperation") and not Part:IsA("TrussPart") then
		if Part.CastShadow then
			if Part.Size.X < 4 or Part.Size.Y < 4 or Part.Size.Z < 4 then
				local Direct
				if game.Lighting.ClockTime <= 18 and game.Lighting.ClockTime > 6 then
					Direct = game.Lighting:GetSunDirection()
				else
					Direct = game.Lighting:GetMoonDirection()
				end
				local Ray = workspace:Raycast(Part.Position,Direct * 2048)
				if not Ray then
					if Part.Transparency == 0 then
						if not Part.Anchored or Part:FindFirstChildWhichIsA("FileMesh") then
							return
						end
						local Thickness = math.min(Part.Size.X,Part.Size.Y,Part.Size.Z)
						local NewPart = Part:Clone()
						NewPart.Name = "PartialShadow"
						NewPart.Transparency = math.min(1 - Thickness/16 - 0.32,0.6)
						NewPart.CanCollide = false
						NewPart.CanQuery = false
						NewPart.CanTouch = false
						NewPart.Material = Enum.Material.SmoothPlastic
						NewPart:ClearAllChildren()
						if (Part:IsA("Part") and Part.Shape == Enum.PartType.Wedge) or Part:IsA("WedgePart") then
							NewPart.CFrame *= CFrame.new(0,-0.0125,0.0125)
							NewPart.Size = Vector3.new(NewPart.Size.X - 0.05,NewPart.Size.Y * 0.99,NewPart.Size.Z * 0.99)
						elseif (Part:IsA("Part") and Part.Shape == Enum.PartType.CornerWedge) or Part:IsA("CornerWedgePart") then
							NewPart.CFrame *= CFrame.new(0.0125,-0.0125,-0.0125)
							NewPart.Size *= Vector3.one * 0.975
						else
							NewPart.Size -= Vector3.one * 0.05
						end
						NewPart.Parent = Part
						Part.CastShadow = false
					elseif ExcludeTransparent then
						Part.CastShadow = false
					end
				end
			end
		end
	end
end

local function AdjustLighting(Ambient)
	if not Ignore then
		Ignore = true
		if not Ambient then
			game.Lighting:SetAttribute("Brightness",game.Lighting.Brightness)
		end
		local Brightness
		local H,S,V = game.Lighting.Ambient:ToHSV()
		local OH,OS,OV = game.Lighting.OutdoorAmbient:ToHSV()
		Brightness = math.max(V,OV)
		Brightness = math.clamp(Brightness,32/255,1)
		if (not game.Lighting.GlobalShadows and LastShadow) or (not game.Lighting.GlobalShadows and not LastShadow) then
			Brightness = V
			Brightness = math.clamp(Brightness,32/255,1)
			game.Lighting:SetAttribute("OutdoorAmbient",game.Lighting.OutdoorAmbient)
			game.Lighting.OutdoorAmbient = Color3.new(0,0,0)
		elseif game.Lighting.GlobalShadows and not LastShadow then
			if game.Lighting:GetAttribute("OutdoorAmbient") then
				game.Lighting.OutdoorAmbient = game.Lighting:GetAttribute("OutdoorAmbient")
				OH,OS,OV = game.Lighting.OutdoorAmbient:ToHSV()
				Brightness = math.max(V,OV)
				Brightness = math.clamp(Brightness,32/255,1)
			end
		end
		if not game.Lighting:GetAttribute("Brightness") then
			game.Lighting:SetAttribute("Brightness",game.Lighting.Brightness)
		end
		game.Lighting.Brightness = game.Lighting:GetAttribute("Brightness") * Brightness * 4
		LastShadow = game.Lighting.GlobalShadows
		if Deferred then
			task.defer(function()
				Ignore = false
			end)
		else
			Ignore = false
		end
	end
end

local function AdjustFog(Color) -- Inaccurate but just reduces the density
	if not FogIgnore then
		FogIgnore = true
		local H,S,Brightness = game.Lighting.FogColor:ToHSV()
		Brightness = math.max(Brightness * 4,1)
		if not Color then
			game.Lighting:SetAttribute("FogEnd",game.Lighting.FogEnd)
		end
		if not game.Lighting:GetAttribute("FogEnd") then
			game.Lighting:SetAttribute("FogEnd",game.Lighting.FogEnd)
		end
		game.Lighting.FogEnd = game.Lighting:GetAttribute("FogEnd") * Brightness
		if Deferred then
			task.defer(function()
				FogIgnore = false
			end)
		else
			FogIgnore = false
		end
	end
end

for i,v in pairs(workspace:GetDescendants()) do
	Adjust(v)
	ShadowFix(v)
end

AdjustLighting()

AdjustFog()

workspace.DescendantAdded:Connect(function(Object)
	Adjust(Object)
	ShadowFix(Object)
end)

game.Lighting:GetPropertyChangedSignal("Brightness"):Connect(AdjustLighting)
game.Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
	AdjustLighting(true)
end)
game.Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(function()
	AdjustLighting(true)
end)
game.Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(function()
	AdjustLighting(true)
end)
game.Lighting:GetPropertyChangedSignal("FogEnd"):Connect(AdjustFog)
game.Lighting:GetPropertyChangedSignal("FogColor"):Connect(function()
	AdjustFog(true)
end)

-- Glow MaterialVariant is initialized above (no script child required).
