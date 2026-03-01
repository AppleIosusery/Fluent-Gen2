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
		Callback = typeof(Config.Callback) == "function" and Config.Callback or function(Value, OldValue) end,
		Changed = Config.Changed or function() end,
		Type = "Slider"
	}

	local Dragging = false
	local DragInputObject = nil

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

	-- Main slider background
	local SliderInner = New("Frame", {
		Size = UDim2.new(1, 0, 0, 4),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
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
		SliderRail
	})

	-- Large invisible hit area for easy grabbing
	local HitArea = New("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Parent = SliderInner,
		Visible = true,
	})

	-- Start dragging
	local function onInputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragInputObject = input
			-- Immediately set value based on touch position
			local fraction = math.clamp((input.Position.X - SliderRail.AbsolutePosition.X) / SliderRail.AbsoluteSize.X, 0, 1)
			Slider:SetValue(Slider.Min + ((Slider.Max - Slider.Min) * fraction))
		end
	end

	HitArea.InputBegan:Connect(onInputBegan)
	SliderRail.InputBegan:Connect(onInputBegan) -- also allow starting on rail

	-- Update while dragging
	local function onInputChanged(input)
		if Dragging and (input == DragInputObject or input.UserInputType == DragInputObject.UserInputType) then
			local fraction = math.clamp((input.Position.X - SliderRail.AbsolutePosition.X) / SliderRail.AbsoluteSize.X, 0, 1)
			Slider:SetValue(Slider.Min + ((Slider.Max - Slider.Min) * fraction))
		end
	end

	UserInputService.InputChanged:Connect(onInputChanged)

	-- End dragging
	local function onInputEnded(input)
		if Dragging and (input == DragInputObject or input.UserInputType == DragInputObject.UserInputType) then
			Dragging = false
			DragInputObject = nil
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
		local OldValue = self.Value or Value

		rawset(self, "Value", Library.Utilities:Round(math.clamp(Value, Slider.Min, Slider.Max), Slider.Rounding))

		local fraction = (self.Value - Slider.Min) / (Slider.Max - Slider.Min)
		SliderDot.Position = UDim2.new(fraction, 0, 0.5, 0) -- dot stays centered
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
		Slider:SetValue(tonumber(SliderDisplay.Text) or Slider.Value)
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
