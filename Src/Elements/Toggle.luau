local TweenService, UserInputService = game:GetService("TweenService"), game:GetService("UserInputService")
local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)
 
local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Toggle"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "Toggle - Missing Title")

	local Toggle = {
		Value = Config.Default or Config.Value or false,
		Callback = Config.Callback or function(Value) end,
		Type = "Toggle",
		Disabled = Config.Disabled or false,          -- New: disabled state
		ShowText = Config.ShowText or false,         -- New: show ON/OFF text
	}

	local ToggleFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, true)
	ToggleFrame.DescLabel.Size = UDim2.new(1, -54, 0, 14)

	Toggle.SetTitle = ToggleFrame.SetTitle
	Toggle.SetDesc = ToggleFrame.SetDesc

	local ToggleCircle = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 2, 0.5, 0),
		Image = "http://www.roblox.com/asset/?id=12266946128",
		ImageTransparency = 0.5,
		ThemeTag = {
			ImageColor3 = "ToggleSlider",
		},
	}) :: ImageLabel

	local ToggleBorder = New("UIStroke", {
		Transparency = 0.5,
		ThemeTag = {
			Color = "ToggleSlider",
		},
	})

	-- Optional ON/OFF text label
	local ToggleText = nil
	if Toggle.ShowText then
		ToggleText = New("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.fromOffset(30, 14),
			Text = Toggle.Value and "ON" or "OFF",
			TextColor3 = Color3.fromRGB(255,255,255),
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Visible = Toggle.ShowText,
			ZIndex = 5,
		}) :: TextLabel
	end

	local ToggleSlider = New("Frame", {
		Size = UDim2.fromOffset(36, 18),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Parent = ToggleFrame.Frame,
		BackgroundTransparency = 1,
		ThemeTag = {
			BackgroundColor3 = "Accent",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 9),
		}),
		ToggleBorder,
		ToggleCircle,
		ToggleText, -- nil if not used
	}) :: Frame

	-- Store any ongoing tween for cleanup
	local currentBackgroundTween = nil

	local function updateVisuals()
		if Toggle.Disabled then
			-- Cancel any running tween
			if currentBackgroundTween then
				currentBackgroundTween:Cancel()
				currentBackgroundTween = nil
			end

			-- Set disabled appearance directly (no animation)
			Creator.OverrideTag(ToggleBorder, { Color = "ToggleSlider" })
			Creator.OverrideTag(ToggleCircle, { ImageColor3 = "ToggleSlider" })
			ToggleSlider.BackgroundTransparency = 0.7
			ToggleCircle.ImageTransparency = 0.7
			if ToggleText then
				ToggleText.TextTransparency = 0.7
			end

			-- Move circle to the correct position without animation
			ToggleCircle.Position = UDim2.new(0, Toggle.Value and 19 or 2, 0.5, 0)
		else
			-- Animate background transparency using TweenService
			local targetTransparency = Toggle.Value and 0 or 1
			if ToggleSlider.BackgroundTransparency ~= targetTransparency then
				currentBackgroundTween = TweenService:Create(
					ToggleSlider,
					TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{ BackgroundTransparency = targetTransparency }
				)
				currentBackgroundTween:Play()
			end

			-- Animate circle position
			ToggleCircle:TweenPosition(
				UDim2.new(0, Toggle.Value and 19 or 2, 0.5, 0),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quint,
				.25,
				true
			)

			-- Update colors and text
			Creator.OverrideTag(ToggleBorder, { Color = Toggle.Value and "Accent" or "ToggleSlider" })
			Creator.OverrideTag(ToggleCircle, { ImageColor3 = Toggle.Value and "ToggleToggled" or "ToggleSlider" })
			ToggleCircle.ImageTransparency = Toggle.Value and 0 or 0.5

			if ToggleText then
				ToggleText.TextTransparency = 0
				ToggleText.Text = Toggle.Value and "ON" or "OFF"
			end
		end
	end

	function Toggle:OnChanged(Func)
		Toggle.Changed = Func
		Library:SafeCallback(Func, Toggle.Value, Toggle.Value)
	end

	function Toggle:SetValue(Value)
		if Toggle.Disabled then return end -- Ignore if disabled

		Value = not not Value
		rawset(Toggle, "Value", Value)

		updateVisuals()

		if typeof(Toggle.Callback) == "function" then
			Library:SafeCallback(Toggle.Callback, Toggle.Value)
		end
		if typeof(Toggle.Changed) == "function" then
			Library:SafeCallback(Toggle.Changed, Toggle.Value)
		end
	end

	function Toggle:SetDisabled(Disabled)
		Toggle.Disabled = Disabled
		updateVisuals()
	end

	function Toggle:Destroy()
		if currentBackgroundTween then
			currentBackgroundTween:Cancel()
		end
		ToggleFrame:Destroy()
		Library.Options[Idx] = nil
	end

	-- Click handler (only if not disabled)
	Creator.AddSignal(ToggleFrame.Frame.MouseButton1Click, function()
		if not Toggle.Disabled then
			Toggle:SetValue(not Toggle.Value)
		end
	end)

	-- Initial update
	updateVisuals()

	-- Keybind code (unchanged, except for respecting disabled state in DoClick)
	Toggle.Keybind = setmetatable({}, { -- TODO: Rewrite this piece of shit
		__call = function(_, self, Idx, Config)
			local Keybind = {
				Value = Config.Default or Config.Value or Enum.KeyCode.Unknown,
				Toggled = false,
				Mode = Config.Mode or "Toggle",
				Type = "Keybind",
				Callback = Config.Callback or function(Value) end,
				ChangedCallback = Config.ChangedCallback or function(New) end,
				Instance = nil
			}

			local Picking = false

			local KeybindDisplayLabel = New("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				Text = Library.Utilities:Prettify(Keybind.Value),
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(0, 0, 0, 14),
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				ThemeTag = {
					TextColor3 = "Text",
				},
			})
		
			local KeybindDisplayFrame: TextButton = New("TextButton", {
				Size = UDim2.fromOffset(0, 30),
				Position = UDim2.new(1, -10, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 0.9,
				Parent = ToggleFrame.Frame,
				AutomaticSize = Enum.AutomaticSize.X,
				ThemeTag = {
					BackgroundColor3 = "Keybind",
				},
			}, {
				New("UICorner", {
					CornerRadius = UDim.new(0, 5),
				}),
				New("UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
				}),
				New("UIStroke", {
					Transparency = 0.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					ThemeTag = {
						Color = "InElementBorder",
					},
				}),
				KeybindDisplayLabel
			})

			Keybind.Instance = setmetatable({
				CreatedAt = tick()
			}, {
				__index = function(self, idx)
					if rawget(self, idx) then
						return rawget(self, idx)
					else
						return KeybindDisplayFrame[idx]
					end
				end
			})
	
			local function UpdateTogglePosition()
				ToggleSlider.Position = UDim2.new(1, KeybindDisplayFrame.Position.X.Offset - KeybindDisplayFrame.AbsoluteSize.X - 10, 0.5, 0)
			end
	
			function Keybind:GetState()
				if UserInputService:GetFocusedTextBox() and self.Mode ~= "Always" then
					return false
				end
		
				if self.Mode == "Always" then
					return true
				elseif self.Mode == "Hold" then
					if self.Value == "None" then
						return false
					end
		
					local Key = self.Value
		
					if Key == "LeftMousebutton" or Key == "RightMousebutton" then
						return Key == "LeftMousebutton" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
							or Key == "RightMousebutton"
								and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
					else
						return UserInputService:IsKeyDown(Enum.KeyCode[self.Value])
					end
				else
					return self.Toggled
				end
			end
		
			function Keybind:SetValue(Key, Mode)
				Key = Key or self.Value
				Mode = Mode or self.Mode
		
				self.Value = Key
				self.Mode = Mode
		
				KeybindDisplayLabel.Text = Library.Utilities:Prettify(self.Value)
			end
		
			function Keybind:OnClick(Callback)
				self.Clicked = Callback
			end
		
			function Keybind:OnChanged(Callback)
				self.Changed = Callback
				Library:SafeCallback(Callback, self.Value, self.Value)
			end
		
			function Keybind:DoClick()
				if not Toggle.Disabled then  -- Respect disabled state
					Toggle:SetValue(not Toggle.Value)
				end
				
				if typeof(self.Callback) == "function" then
					Library:SafeCallback(self.Callback, self.Value)
				end
				if typeof(self.Clicked) == "function" then
					Library:SafeCallback(self.Clicked, self.Value)
				end
			end
		
			function Keybind:Destroy()
				KeybindDisplayFrame.Size = UDim2.new()
				KeybindDisplayFrame.Position = UDim2.new()
				KeybindDisplayFrame:Destroy()
				Library.Options[Idx] = nil
			end
		
			Creator.AddSignal(KeybindDisplayFrame.InputBegan, function(Input)
				if
					Input.UserInputType == Enum.UserInputType.MouseButton1
					or Input.UserInputType == Enum.UserInputType.Touch
				then
					Picking = true
					KeybindDisplayLabel.Text = "..."
		
					wait(0.2)
		
					UserInputService.InputBegan:Once(function(Input)
						local Key
		
						if Input.UserInputType == Enum.UserInputType.Keyboard then
							Key = Input.KeyCode.Name
						elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
							Key = "LeftMousebutton"
						elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
							Key = "RightMousebutton"
						end
		
						UserInputService.InputEnded:Once(function(Input)
							if (Input.KeyCode.Name == Key
								or Key == "LeftMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton1
								or Key == "RightMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton2)
								and not Library.Unloaded
							then
								Picking = false
		
								Keybind:SetValue(Key)
		
								Library:SafeCallback(self.ChangedCallback, Input.KeyCode or Input.UserInputType)
								Library:SafeCallback(self.Changed, Input.KeyCode or Input.UserInputType)
							end
						end)
					end)
				end
			end)
		
			Creator.AddSignal(UserInputService.InputBegan, function(Input)
				if not Picking and not UserInputService:GetFocusedTextBox() then
					if Keybind.Mode == "Toggle" then
						local Key = Keybind.Value

						if Key == "LeftMousebutton" or Key == "RightMousebutton" then
							if
								Key == "LeftMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton1
								or Key == "RightMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton2
							then
								Keybind.Toggled = not Keybind.Toggled
								Keybind:DoClick()
							end
						elseif Input.UserInputType == Enum.UserInputType.Keyboard then
							if Input.KeyCode.Name == Key or Input.KeyCode == Key then
								Keybind.Toggled = not Keybind.Toggled
								Keybind:DoClick()
							end
						end
					end
				end
			end)
	
			Creator.AddSignal(KeybindDisplayFrame:GetPropertyChangedSignal("AbsoluteSize"), UpdateTogglePosition)

			Library.Options[Idx] = Keybind

			Toggle.Keybind = Keybind
	
			return setmetatable(Toggle.Keybind, {
				__newindex =  function(self, index, newvalue)
					if index == "Value" then
						task.spawn(Keybind.SetValue, Keybind, newvalue)
					end
					rawset(self, index, newvalue)
				end
			})
		end
	})

	Toggle:SetValue(Toggle.Value)

	Library.Options[Idx] = Toggle

	Toggle.Instance = ToggleFrame

	return setmetatable(Toggle, {
		__newindex =  function(self, index, newvalue)
			if index == "Value" then
				task.spawn(Toggle.SetValue, Toggle, newvalue)
			elseif index == "Disabled" then
				task.spawn(Toggle.SetDisabled, Toggle, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})
end

return Element
