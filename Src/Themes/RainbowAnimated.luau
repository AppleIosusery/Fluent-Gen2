local RunService = game:GetService("RunService")
local Creator = require(script.Parent.Parent.Modules.Creator)  -- adjust path if needed

local theme = {
	Accent = Color3.fromRGB(255, 0, 0),  -- will be animated

	AcrylicMain = Color3.fromRGB(30, 20, 40),
	AcrylicBorder = Color3.fromRGB(100, 70, 130),
	AcrylicGradient = ColorSequence.new(Color3.fromRGB(70, 40, 100), Color3.fromRGB(40, 20, 60)),
	AcrylicNoise = 0.92,

	TitleBarLine = Color3.fromRGB(150, 100, 200),
	Tab = Color3.fromRGB(200, 150, 255),

	Element = Color3.fromRGB(80, 50, 120),
	ElementBorder = Color3.fromRGB(40, 20, 60),
	InElementBorder = Color3.fromRGB(255, 200, 100),
	ElementTransparency = 0.87,

	ToggleSlider = Color3.fromRGB(255, 140, 0),
	ToggleToggled = Color3.fromRGB(0, 0, 0),

	SliderRail = Color3.fromRGB(255, 255, 0),

	DropdownFrame = Color3.fromRGB(200, 255, 150),
	DropdownHolder = Color3.fromRGB(60, 80, 40),
	DropdownBorder = Color3.fromRGB(40, 50, 20),
	DropdownOption = Color3.fromRGB(100, 255, 100),

	Keybind = Color3.fromRGB(100, 100, 255),

	Input = Color3.fromRGB(150, 100, 255),
	InputFocused = Color3.fromRGB(30, 20, 40),
	InputIndicator = Color3.fromRGB(200, 150, 255),

	Dialog = Color3.fromRGB(80, 40, 80),
	DialogHolder = Color3.fromRGB(50, 20, 50),
	DialogHolderLine = Color3.fromRGB(30, 10, 30),
	DialogButton = Color3.fromRGB(80, 40, 80),
	DialogButtonBorder = Color3.fromRGB(150, 80, 150),
	DialogBorder = Color3.fromRGB(120, 60, 120),
	DialogInput = Color3.fromRGB(90, 50, 90),
	DialogInputLine = Color3.fromRGB(200, 100, 255),

	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(200, 200, 200),
	Hover = Color3.fromRGB(200, 100, 255),
	HoverChange = 0.04
}

-- Animation state
local hue = 0
local animationConnection = nil

function theme.OnSelect()
	-- Stop any previous animation
	if animationConnection then
		animationConnection:Disconnect()
	end
	-- Start new animation
	animationConnection = RunService.Heartbeat:Connect(function()
		hue = (hue + 0.005) % 1  -- adjust speed here
		theme.Accent = Color3.fromHSV(hue, 1, 1)
		-- Update all UI elements that use theme tags
		Creator.UpdateTheme()
	end)
end

function theme.OnDeselect()
	if animationConnection then
		animationConnection:Disconnect()
		animationConnection = nil
	end
end

return theme
