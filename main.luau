-- Layanan Roblox
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Gunakan shared keybind jika ada, default T
local currentKeybind = shared.SnakeShootKeybind or Enum.KeyCode.T

local player = Players.LocalPlayer
local abilitiesFolder = player:WaitForChild("PlayerGui"):WaitForChild("InGameUI"):WaitForChild("Bottom"):WaitForChild("Abilities")

-- Setup tombol
local originalButton = abilitiesFolder:WaitForChild("1")
local snakeShootButton = originalButton:Clone()
snakeShootButton.Name = "SnakeShoot"
snakeShootButton.Parent = abilitiesFolder

-- Ubah teks & keybind
local timerLabel = snakeShootButton:FindFirstChild("Timer")
if timerLabel and timerLabel:IsA("TextLabel") then
	timerLabel.Text = snakeActive and "SnakeShoot: ON" or "SnakeShoot: OFF"
end

local keybindLabel = snakeShootButton:FindFirstChild("Keybind")
if keybindLabel and keybindLabel:IsA("TextLabel") then
    keybindLabel.Text = currentKeybind.Name

    -- Perbarui label saat user ganti keybind lewat UI
    task.spawn(function()
        while task.wait(0.2) do
            if shared.SnakeShootKeybind and keybindLabel.Text ~= shared.SnakeShootKeybind.Name then
                keybindLabel.Text = shared.SnakeShootKeybind.Name
            end
        end
    end)
end

-- Tambah Sound
local function createSound(id, name)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. id
	sound.Volume = 1
	sound.Name = name
	sound.Parent = snakeShootButton
	return sound
end

local clickSound = createSound("10066968815", "ClickSound")
local hoverSound = createSound("10066931761", "HoverSound")

-- Cooldown animasi
local cooldownFrame = snakeShootButton:FindFirstChild("Cooldown")
local uiGradient = cooldownFrame and cooldownFrame:FindFirstChild("UIGradient")
local cooldownTime = 0
local onCooldown = false

local function startCooldown()
	if not cooldownFrame or not uiGradient then return end
	onCooldown = true
	cooldownFrame.Visible = true
	uiGradient.Offset = Vector2.new(0, 0)
	local tweenInfo = TweenInfo.new(cooldownTime, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(uiGradient, tweenInfo, { Offset = Vector2.new(0, 1) })
	tween:Play()
	tween.Completed:Wait()
	cooldownFrame.Visible = false
	onCooldown = false
end

-- Tween klik tombol
local pressTween, releaseTween
local function createTween(instance, goal, time)
	local info = TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	return TweenService:Create(instance, info, goal)
end

local function animatePress()
	if pressTween then pressTween:Cancel() end
	pressTween = createTween(snakeShootButton, {
		Size = snakeShootButton.Size + UDim2.new(0.1, 0, 0.1, 0)
	}, 0.1)
	pressTween:Play()
end

local function animateRelease()
	if releaseTween then releaseTween:Cancel() end
	releaseTween = createTween(snakeShootButton, {
		Size = originalButton.Size
	}, 0.1)
	releaseTween:Play()
end

-- Hover Sound
snakeShootButton.MouseEnter:Connect(function()
	hoverSound:Play()
end)

-- Keybind tampil saat keyboard
if keybindLabel and keybindLabel:IsA("TextLabel") then
	keybindLabel.Visible = false
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			keybindLabel.Visible = true
		elseif input.UserInputType == Enum.UserInputType.Touch then
			keybindLabel.Visible = false
		end
	end)
end

-- Support tekan mobile/PC
snakeShootButton.MouseButton1Down:Connect(animatePress)
snakeShootButton.MouseButton1Up:Connect(animateRelease)
snakeShootButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then animatePress() end
end)
snakeShootButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then animateRelease() end
end)

--------------------------------------------------------------------------------
-- === SNAKE SHOOT ===
--------------------------------------------------------------------------------
local snakeActive = false
local zigzagAmplitude = 3
local zigzagSpeed = 100
local basePower = 500
local startTime = tick()
local targetGoal = nil

local function cycleStyle()
	snakeActive = not snakeActive
	startTime = tick()
	clickSound:Play()
	timerLabel.Text = snakeActive and "SnakeShoot: ON" or "SnakeShoot: OFF"
	snakeShootButton.BackgroundColor3 = snakeActive and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(255, 255, 255)
end

snakeShootButton.MouseButton1Click:Connect(function()
	if onCooldown then return end
	cycleStyle()
	startCooldown()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Refresh keybind dari shared jika tersedia
	currentKeybind = shared.SnakeShootKeybind or currentKeybind

	if input.KeyCode == currentKeybind then
		if not onCooldown then
			cycleStyle()
			startCooldown()
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if not snakeActive then return end
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	local ball = workspace:FindFirstChild("Football")
	if not ball then return end

	if tick() - startTime > 0.1 then
		startTime = tick()
		local team = tostring(player.Team)
		local goalList = (team == "Home") and {
			Vector3.new(-238, 11, -69),
			Vector3.new(-238, 11, -33)
		} or {
			Vector3.new(317, 11, -30),
			Vector3.new(315, 11, -67)
		}
		targetGoal = goalList[math.random(1, #goalList)]
	end

	if not targetGoal then return end

	local dirToGoal = (targetGoal - ball.Position).Unit
	local timeNow = tick() - startTime
	local verticalOffset = math.sin(timeNow * zigzagSpeed) * zigzagAmplitude
	local zigzagVector = Vector3.new(0, verticalOffset, 0)
	local finalDirection = (dirToGoal + zigzagVector).Unit

	ball.AssemblyLinearVelocity = finalDirection * basePower
	ball.AssemblyAngularVelocity = Vector3.zero
	ball.AssemblyGravityScale = 0
end)
