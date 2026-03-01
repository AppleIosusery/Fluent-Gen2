local UserInputService = game:GetService("UserInputService")
local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Slider"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Max, "Slider - Missing maximum value.")

	local Slider = {
		Value = nil,
		Min = typeof(Config.Min) == "number" and Config.Min or 0,
		Max = Config.Max,
		Rounding = typeof(Config.Rounding) == "number" and Config.Rounding or 0,
		Step = Config.Step or nil,                       -- NEW: step snapping
		Callback = typeof(Config.Callback) == "function" and Config.Callback or function(Value, OldValue) end,
		Changed = Config.Changed or function() end,
		Type = "Slider",
		IconStart = Config.IconStart,                     -- NEW: start icon asset id
		IconEnd = Config.IconEnd,                         -- NEW: end icon asset id
		IconSize = Config.IconSize or 16,                 -- NEW: icon size (square)
		ShowTooltip = Config.ShowTooltip or false,        -- NEW: show value tooltip while dragging
	}

	local Dragging = false
	local DragInputObject = nil
	local tooltipConnection = nil

	local SliderFrame = require(Components.Element)(Config.Title or "Slider", Config.Description, self.Container, false)
	SliderFrame.DescLabel.Size = UDim2.new(1, -170, 0, 14)

	Slider.SetTitle = SliderFrame.SetTitle
	Slider.SetDesc = SliderFrame.SetDesc

	-- Visual dot (centered)
	local SliderDot = New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Image = "http://www.roblox.com/asset/?id=12266946128",
		ThemeTag = {
			ImageColor3 = "Accent",
		}
	})

	-- Rail container for dot
	local SliderRail = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(7, 0),
		Size = UDim2.new(1, -14, 1, 0)
	}, {
		SliderDot,
	})

	-- Filled part
	local SliderFill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		ThemeTag = {
			BackgroundColor3 = "Accent",
		}
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(1, 0),
		})
	})

	-- Value display
	local SliderDisplay = New("TextBox", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		Text = "Value",
		ClearTextOnFocus = true,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 100, 0, 14),
		Position = UDim2.new(0, -4, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ThemeTag = {
			TextColor3 = "SubText",
		}
	})

	-- Tooltip (floating above slider while dragging)
	local SliderTooltip = nil
	if Slider.ShowTooltip then
		SliderTooltip = New("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0, 0, 0, -8),
			Size = UDim2.fromOffset(40, 20),
			BackgroundColor3 = Color3.fromRGB(30,30,30),
			Text = tostring(Slider.Value),
			TextColor3 = Color3.fromRGB(255,255,255),
			TextSize = 12,
			Visible = false,
			ZIndex = 10,
		}, {
			New("UICorner", { CornerRadius = UDim.new(0, 4) }),
			New("UIStroke", { Color = Color3.fromRGB(80,80,80) }),
		}) :: TextLabel
	end

	-- Start icon
	local IconStart = nil
	if Slider.IconStart then
		IconStart = New("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(Slider.IconSize, Slider.IconSize),
			Image = Slider.IconStart,
			BackgroundTransparency = 1,
			ThemeTag = {
				ImageColor3 = "SubText",
			}
		})
	end

	-- End icon
	local IconEnd = nil
	if Slider.IconEnd then
		IconEnd = New("ImageLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(Slider.IconSize, Slider.IconSize),
			Image = Slider.IconEnd,
			BackgroundTransparency = 1,
			ThemeTag = {
				ImageColor3 = "SubText",
			}
		})
	end

	-- Main slider background – now positioned between icons
	local sliderInnerXOffset = (IconStart and (Slider.IconSize + 15) or 10)
	local sliderInnerWidth = 160 - (IconStart and (Slider.IconSize + 5) or 0) - (IconEnd and (Slider.IconSize + 5) or 0)

	local SliderInner = New("Frame", {
		Size = UDim2.new(0, sliderInnerWidth, 0, 4),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, - (IconEnd and (Slider.IconSize + 20) or 10), 0.5, 0),
		BackgroundTransparency = 0.4,
		Parent = SliderFrame.Frame,
		ThemeTag = {
			BackgroundColor3 = "SliderRail",
		}
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		New("UISizeConstraint", {
			MaxSize = Vector2.new(150, math.huge),
		}),
		SliderDisplay,
		SliderFill,
		SliderRail,
	})

	-- Add icons to the frame
	if IconStart then
		IconStart.Parent = SliderFrame.Frame
	end
	if IconEnd then
		IconEnd.Parent = SliderFrame.Frame
	end
	if SliderTooltip then
		SliderTooltip.Parent = SliderFrame.Frame
	end

	-- Large invisible hit area for easy grabbing
	local HitArea = New("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Parent = SliderInner,
		Visible = true,
	})

	-- Helper: snap value to step
	local function snapValue(value)
		if Slider.Step and Slider.Step > 0 then
			local stepCount = math.round((value - Slider.Min) / Slider.Step)
			return Slider.Min + stepCount * Slider.Step
		end
		return value
	end

	-- Update value based on input position
	local function updateFromInput(input)
		local fraction = math.clamp((input.Position.X - SliderRail.AbsolutePosition.X) / SliderRail.AbsoluteSize.X, 0, 1)
		local rawValue = Slider.Min + ((Slider.Max - Slider.Min) * fraction)
		local snapped = snapValue(rawValue)
		Slider:SetValue(snapped)
	end

	-- Start dragging
	local function onInputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragInputObject = input
			updateFromInput(input)
			if SliderTooltip then
				SliderTooltip.Visible = true
			end
		end
	end

	HitArea.InputBegan:Connect(onInputBegan)
	SliderRail.InputBegan:Connect(onInputBegan)

	-- Update while dragging
	local function onInputChanged(input)
		if Dragging and (input == DragInputObject or input.UserInputType == DragInputObject.UserInputType) then
			updateFromInput(input)
			if SliderTooltip then
				SliderTooltip.Position = UDim2.new(0, (SliderDot.AbsolutePosition.X - SliderFrame.Frame.AbsolutePosition.X) / SliderFrame.Frame.AbsoluteSize.X, 0, -8)
				SliderTooltip.Text = tostring(Slider.Value)
			end
		end
	end

	UserInputService.InputChanged:Connect(onInputChanged)

	-- End dragging
	local function onInputEnded(input)
		if Dragging and (input == DragInputObject or input.UserInputType == DragInputObject.UserInputType) then
			Dragging = false
			DragInputObject = nil
			if SliderTooltip then
				SliderTooltip.Visible = false
			end
		end
	end

	UserInputService.InputEnded:Connect(onInputEnded)

	-- Store connections for cleanup
	Slider.Connections = {
		HitArea.InputBegan:Connect(onInputBegan),
		SliderRail.InputBegan:Connect(onInputBegan),
		UserInputService.InputChanged:Connect(onInputChanged),
		UserInputService.InputEnded:Connect(onInputEnded),
	}

	function Slider:OnChanged(Func)
		Slider.Changed = Func
		Library:SafeCallback(Func, Slider.Value, Slider.Value)
	end

	function Slider:SetValue(Value: number)
		local snapped = snapValue(Value)
		local clamped = math.clamp(snapped, Slider.Min, Slider.Max)
		local OldValue = self.Value or clamped

		rawset(self, "Value", Library.Utilities:Round(clamped, Slider.Rounding))

		local fraction = (self.Value - Slider.Min) / (Slider.Max - Slider.Min)
		SliderDot.Position = UDim2.new(fraction, 0, 0.5, 0)
		SliderFill.Size = UDim2.fromScale(fraction, 1)
		SliderDisplay.Text = tostring(self.Value)

		if typeof(Slider.Callback) == "function" then
			Library:SafeCallback(Slider.Callback, self.Value, OldValue)
		end
		if typeof(Slider.Changed) == "function" then
			Library:SafeCallback(Slider.Changed, self.Value, OldValue)
		end
	end

	Creator.AddSignal(SliderDisplay.FocusLost, function()
		local num = tonumber(SliderDisplay.Text)
		if num then
			Slider:SetValue(num)
		else
			SliderDisplay.Text = tostring(Slider.Value)
		end
	end)

	function Slider:Destroy()
		SliderFrame:Destroy()
		Library.Options[Idx] = nil
		for _, conn in ipairs(Slider.Connections) do
			conn:Disconnect()
		end
	end

	Slider:SetValue(typeof(Config.Default) == "number" and Config.Default or Slider.Min)

	Library.Options[Idx] = Slider

	Slider.Instance = SliderFrame

	return setmetatable(Slider, {
		__newindex = function(self, index, newvalue)
			if index == "Value" then
				task.spawn(Slider.SetValue, Slider, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})
end

return Element
