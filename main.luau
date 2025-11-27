local function SafeHUI()
	if gethui then return gethui()
	elseif game.CoreGui then return game.CoreGui end

	local ui = Instance.new("ScreenGui")
	ui.Name = "HUI_SAFE_"..math.random(9999)
	ui.ResetOnSpawn = false
	ui.Parent = game:GetService("CoreGui")
	return ui
end

local HUI = SafeHUI()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local snakeActive = false
local cooldown = 0 -- atur CD
local onCooldown = false
local zigzagAmplitude = 3
local zigzagSpeed = 100
local basePower = 500
local startTime = tick()
local targetGoal = nil

local currentKeybind = shared.SnakeShootKeybind or Enum.KeyCode.T

local UI = Instance.new("ScreenGui",HUI)
UI.Name = "SnakeUI_"..math.random(1000,9999)
UI.ZIndexBehavior = Enum.ZIndexBehavior.Global

local Frame = Instance.new("Frame",UI)
Frame.Size = UDim2.new(0,50,0,50)
Frame.Position = UDim2.new(0.02,0,0.45,0)
Frame.BackgroundColor3 = Color3.fromRGB(15,15,20)

Instance.new("UICorner",Frame).CornerRadius = UDim.new(0,12)

local glow = Instance.new("UIStroke",Frame)
glow.Thickness = 2.5
glow.Color = Color3.fromRGB(180,0,255)

local grad = Instance.new("UIGradient",Frame)
grad.Rotation = 90
grad.Color = ColorSequence.new(Color3.fromRGB(120,0,255),Color3.fromRGB(200,0,100))
grad.Transparency = NumberSequence.new(0.15)

local Button = Instance.new("TextButton",Frame)
Button.Size = UDim2.new(1,0,1,0)
Button.BackgroundTransparency = 1
Button.TextScaled = true
Button.TextColor3 = Color3.new(1,1,1)
Button.Font = Enum.Font.GothamBold
Button.Text = "SnakeShoot: OFF"
Button.ZIndex = 20

local function Sound(ID)
	local s=Instance.new("Sound",Frame); s.SoundId="rbxassetid://"..ID; s.Volume=1; return s
end

local ClickSFX=Sound(10066968815)
local HoverSFX=Sound(10066931761)

local DragBar = Instance.new("Frame", Frame)
DragBar.Size = UDim2.new(1,0,0,5) -- tinggi 10px sebagai area drag
DragBar.Position = UDim2.new(0,0,0,55) -- di atas tombol
DragBar.BackgroundTransparency = 0.7
DragBar.BackgroundColor3 = Color3.fromRGB(500,500,500)

local corner = Instance.new("UICorner",DragBar)
corner.CornerRadius = UDim.new(0,6)

local dragging = false
local dragStart, startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

DragBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateDrag(input)
	end
end)

Button.MouseEnter:Connect(function()
	HoverSFX:Play()
	TweenService:Create(Frame,TweenInfo.new(.15),{Size=UDim2.new(0,55,0,50)}):Play()
end)
Button.MouseLeave:Connect(function()
	TweenService:Create(Frame,TweenInfo.new(.15),{Size=UDim2.new(0,50,0,50)}):Play()
end)

local function ToggleShoot()
	if onCooldown then return end

	snakeActive = not snakeActive
	ClickSFX:Play()

	Button.Text = snakeActive and "SnakeShoot: ON" or "SnakeShoot: OFF"
	Frame.BackgroundColor3 = snakeActive and Color3.fromRGB(50,200,100) or Color3.fromRGB(15,15,20)

	onCooldown = true
	task.delay(cooldown,function() 
		onCooldown=false 
	end)
end

Button.MouseButton1Click:Connect(ToggleShoot)

UIS.InputBegan:Connect(function(input,gp)
	if gp then return end
	currentKeybind = shared.SnakeShootKeybind or currentKeybind
	if input.KeyCode==currentKeybind then ToggleShoot() end
end)

RunService.Heartbeat:Connect(function()
	if not snakeActive then return end

	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	local ball = workspace:FindFirstChild("Football") 
	if not ball then return end

	if tick()-startTime>.1 then
		startTime=tick()
		local team=tostring(player.Team)
		local goal=(team=="Home") and {
			Vector3.new(-238,11,-69),Vector3.new(-238,11,-33)
		} or {
			Vector3.new(317,11,-30),Vector3.new(315,11,-67)
		}
		targetGoal = goal[math.random(1,#goal)]
	end

	if not targetGoal then return end
	local dir=(targetGoal-ball.Position).Unit
	local z=math.sin((tick()-startTime)*zigzagSpeed)*zigzagAmplitude
	ball.AssemblyLinearVelocity=(dir+Vector3.new(0,z,0)).Unit*basePower
	ball.AssemblyAngularVelocity=Vector3.zero
	ball.AssemblyGravityScale=0
end)
