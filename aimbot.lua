-- Aimbot Script
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

-- ESP Script (Box + Antena + Nama + Health Bar)
local function buatESP(player)
    if player == LocalPlayer then return end

    local box = Drawing.new("Square")
    box.Color = Color3.fromRGB(0, 255, 0)
    box.Thickness = 1
    box.Filled = false

    local line = Drawing.new("Line")
    line.Color = Color3.fromRGB(255, 0, 0)
    line.Thickness = 1

    local name = Drawing.new("Text")
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Size = 14
    name.Center = true
    name.Outline = true

    local healthBar = Drawing.new("Line")
    healthBar.Thickness = 2

    RunService.RenderStepped:Connect(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local head = player.Character.Head
            local hum = player.Character.Humanoid

            local pos, visible = Camera:WorldToViewportPoint(hrp.Position)
            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local footPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

            if visible then
                local height = math.abs(headPos.Y - footPos.Y)
                local width = height / 2
                local x = pos.X - width / 2
                local y = pos.Y - height / 2

                -- Box
                box.Visible = true
                box.Size = Vector2.new(width, height)
                box.Position = Vector2.new(x, y)

                -- Antenna Line
                line.Visible = true
                line.From = Vector2.new(pos.X, 0)
                line.To = Vector2.new(pos.X, pos.Y)

                -- Name
                name.Visible = true
                name.Text = player.Name
                name.Position = Vector2.new(pos.X, y - 16)

                -- Health Bar
                local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local barHeight = height * hpPercent
                local barTop = y + height - barHeight

                healthBar.Visible = true
                healthBar.Color = Color3.fromRGB(255 - (hpPercent * 255), hpPercent * 255, 0)
                healthBar.From = Vector2.new(x - 6, y + height)
                healthBar.To = Vector2.new(x - 6, barTop)
            else
                box.Visible = false
                line.Visible = false
                name.Visible = false
                healthBar.Visible = false
            end
        else
            box.Visible = false
            line.Visible = false
            name.Visible = false
            healthBar.Visible = false
        end
    end)
end

-- Apply ESP to all players
for _, player in ipairs(Players:GetPlayers()) do
    buatESP(player)
end

Players.PlayerAdded:Connect(function(player)
    buatESP(player)
end)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function IsValidTarget(player, aimPartName)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    if not player.Character:FindFirstChild(aimPartName) then return false end
    if not player.Character:FindFirstChild("Humanoid") then return false end
    if player.Character.Humanoid.Health <= 0 then return false end
    if LocalPlayer:IsFriendsWith(player.UserId) then return false end
    if player.Team == LocalPlayer.Team then return false end

    -- Wall check
    local part = player.Character[aimPartName]
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * 500

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}

    local result = workspace:Raycast(origin, direction, rayParams)
    return result and result.Instance:IsDescendantOf(part.Parent)
end
