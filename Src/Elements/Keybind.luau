local UserInputService = game:GetService("UserInputService")

local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Keybind"

function Element:New(Idx, Config)
	local Library = self.Library

	local Keybind = {
		Value = Config.Default or Config.Value or Enum.KeyCode.Unknown,
		Toggled = false,
		Mode = Config.Mode or "Toggle",
		Type = "Keybind",
		Callback = Config.Callback or function(Value) end,
		ChangedCallback = Config.ChangedCallback or function(New) end,
		AllowGamepad = Config.AllowGamepad ~= false,   -- default true
		AllowUnbind = Config.AllowUnbind ~= false,     -- default true
	}

	local Picking = false
	local pickingCancelled = false

	local KeybindFrame = require(Components.Element)(Config.Title or "Keybind", Config.Description, self.Container, true)

	Keybind.SetTitle = KeybindFrame.SetTitle
	Keybind.SetDesc = KeybindFrame.SetDesc

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

	-- Clear button (X) – only shown when AllowUnbind is true and not picking
	local ClearButton = nil
	if Keybind.AllowUnbind then
		ClearButton = New("TextButton", {
			Size = UDim2.fromOffset(16, 16),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -4, 0.5, 0),
			BackgroundTransparency = 1,
			Text = "",
			Visible = false,  -- initially hidden
		}, {
			New("ImageLabel", {
				Size = UDim2.fromOffset(12, 12),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = "rbxassetid://10723462360", -- a simple X icon
				BackgroundTransparency = 1,
				ThemeTag = {
					ImageColor3 = "SubText",
				},
			}),
		}) :: TextButton
	end

	local KeybindDisplayFrame: TextButton = New("TextButton", {
		Size = UDim2.fromOffset(0, 30),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 0.9,
		Parent = KeybindFrame.Frame,
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
		KeybindDisplayLabel,
	})

	if ClearButton then
		ClearButton.Parent = KeybindDisplayFrame
	end

	-- Helper to update the display text and clear button visibility
	local function updateDisplay()
		local displayText = Library.Utilities:Prettify(Keybind.Value)
		KeybindDisplayLabel.Text = displayText

		if ClearButton then
			ClearButton.Visible = Keybind.AllowUnbind and not Picking and Keybind.Value ~= "None" and Keybind.Value ~= Enum.KeyCode.Unknown
		end
	end

	function Keybind:GetState()
		if UserInputService:GetFocusedTextBox() and Keybind.Mode ~= "Always" then
			return false
		end

		if Keybind.Mode == "Always" then
			return true
		elseif Keybind.Mode == "Hold" then
			if Keybind.Value == "None" then
				return false
			end

			local Key = Keybind.Value

			if Key == "LeftMousebutton" or Key == "RightMousebutton" then
				return Key == "LeftMousebutton" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
					or Key == "RightMousebutton" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			elseif typeof(Key) == "EnumItem" and Key.EnumType == Enum.KeyCode then
				return UserInputService:IsKeyDown(Key)
			elseif typeof(Key) == "EnumItem" and Key.EnumType == Enum.UserInputType then
				-- Gamepad buttons are UserInputType
				return UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Key)
			end
		else -- Toggle mode
			return Keybind.Toggled
		end
	end

	function Keybind:SetValue(Key, Mode)
		Key = Key or Keybind.Value
		Mode = Mode or Keybind.Mode

		rawset(Keybind, "Value", Key)
		Keybind.Mode = Mode

		updateDisplay()

		if typeof(Keybind.ChangedCallback) == "function" then
			Library:SafeCallback(Keybind.ChangedCallback, Key)
		end
		if typeof(Keybind.Changed) == "function" then
			Library:SafeCallback(Keybind.Changed, Key)
		end
	end

	function Keybind:Clear()
		Keybind:SetValue("None")
	end

	function Keybind:OnClick(Callback)
		Keybind.Clicked = Callback
	end

	function Keybind:OnChanged(Callback)
		Keybind.Changed = Callback
		Library:SafeCallback(Callback, Keybind.Value, Keybind.Value)
	end

	function Keybind:DoClick()
		if typeof(Keybind.Callback) == "function" then
			Library:SafeCallback(Keybind.Callback, Keybind.Toggled)
		end
		if typeof(Keybind.Clicked) == "function" then
			Library:SafeCallback(Keybind.Clicked, Keybind.Toggled)
		end
	end

	function Keybind:Destroy()
		KeybindFrame:Destroy()
		Library.Options[Idx] = nil
	end

	-- Clear button click
	if ClearButton then
		Creator.AddSignal(ClearButton.MouseButton1Click, function()
			Keybind:Clear()
		end)
	end

	-- Start picking
	Creator.AddSignal(KeybindDisplayFrame.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			Picking = true
			pickingCancelled = false
			KeybindDisplayLabel.Text = "..."
			-- Highlight the border
			Creator.OverrideTag(KeybindDisplayFrame, { BackgroundColor3 = "InputFocused" })
			updateDisplay() -- hide clear button

			-- Wait for any input
			local connection
			connection = UserInputService.InputBegan:Connect(function(input)
				if not Picking then return end
				local key

				if input.UserInputType == Enum.UserInputType.Keyboard then
					-- Check for Escape to cancel
					if input.KeyCode == Enum.KeyCode.Escape then
						pickingCancelled = true
						Picking = false
						connection:Disconnect()
						updateDisplay()
						Creator.OverrideTag(KeybindDisplayFrame, { BackgroundColor3 = "Keybind" })
						return
					end
					key = input.KeyCode
				elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
					key = "LeftMousebutton"
				elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
					key = "RightMousebutton"
				elseif Keybind.AllowGamepad and input.UserInputType == Enum.UserInputType.Gamepad1 then
					-- Gamepad button pressed (EnumItem of type UserInputType)
					key = input.KeyCode -- actually it's a UserInputType, e.g., Enum.UserInputType.Gamepad1
					-- We'll store the UserInputType enum itself
				else
					return -- ignore other inputs
				end

				-- Wait for release before finalizing (to avoid immediate retrigger)
				local releaseConn
				releaseConn = UserInputService.InputEnded:Connect(function(endedInput)
					if endedInput == input then
						releaseConn:Disconnect()
						if Picking and not pickingCancelled then
							Picking = false
							Keybind:SetValue(key)
							Creator.OverrideTag(KeybindDisplayFrame, { BackgroundColor3 = "Keybind" })
						end
					end
				end)
			end)

			-- Also allow cancelling by clicking outside (optional, but we'll keep simple for now)
		end
	end)

	-- Toggle mode handling (unchanged)
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
					if Input.KeyCode == Key then
						Keybind.Toggled = not Keybind.Toggled
						Keybind:DoClick()
					end
				elseif Keybind.AllowGamepad and Input.UserInputType == Enum.UserInputType.Gamepad1 then
					if Input.KeyCode == Key then
						Keybind.Toggled = not Keybind.Toggled
						Keybind:DoClick()
					end
				end
			end
		end
	end)

	-- Hold mode is handled by GetState, not here.

	updateDisplay()
	Library.Options[Idx] = Keybind

	Keybind.Instance = KeybindFrame

	return setmetatable(Keybind, {
		__newindex =  function(self, index, newvalue)
			if index == "Value" then
				task.spawn(Keybind.SetValue, Keybind, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})
end

return Element
