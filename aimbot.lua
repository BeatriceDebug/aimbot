local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local AimEnabled = false
local AimbotMode = "Instant"
local Smoothness = 0.2
local FOVRadius = 50 -- radius dalam piksel

-- FOV Circle - Biru
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = FOVRadius
fovCircle.Color = Color3.fromRGB(0, 0, 255) -- Biru
fovCircle.Thickness = 1.5
fovCircle.Transparency = 1
fovCircle.Filled = false
fovCircle.Visible = true

RunService.RenderStepped:Connect(function()
	local viewport = Camera.ViewportSize
	fovCircle.Position = Vector2.new(viewport.X / 2, viewport.Y / 2)
end)

-- Target part fallback: Head > NeckAttachment > HumanoidRootPart
local function getTargetPart(character)
	local head = character:FindFirstChild("Head")
	if head then
		return head.Position
	end

	local upperTorso = character:FindFirstChild("UpperTorso")
	if upperTorso then
		local neckAttachment = upperTorso:FindFirstChild("NeckAttachment")
		if neckAttachment then
			return neckAttachment.WorldPosition
		end
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		return root.Position
	end

	return nil
end

local function getClosestPlayerInFOV()
	local closest = nil
	local shortest = FOVRadius
	local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local pos = getTargetPart(player.Character)
			if pos then
				local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
				if onScreen then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
					if dist <= FOVRadius and dist < shortest then
						shortest = dist
						closest = pos
					end
				end
			end
		end
	end
	return closest
end

local function aimAtTarget()
	local target = getClosestPlayerInFOV()
	if target then
		if AimbotMode == "Instant" then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, target)
		else
			Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target), Smoothness)
		end
	end
end

-- Tahan klik kanan untuk aktifkan aimbot
UserInputService.InputBegan:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		AimEnabled = true
	end
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		AimEnabled = false
	end
end)

RunService.RenderStepped:Connect(function()
	if AimEnabled then
		aimAtTarget()
	end
end)
