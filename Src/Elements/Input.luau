local UserInputService = game:GetService("UserInputService")
local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local AddSignal = Creator.AddSignal
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Input"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "Input - Missing Title")
	Config.Callback = Config.Callback or function() end

	local Input = {
		Value = Config.Default or Config.Value or "",
		Numeric = Config.Numeric or false,
		Finished = Config.Finished or false,
		Callback = Config.Callback or function(Value) end,
		ClearOnFocusLost = Config.ClearOnFocusLost or false,
		Type = "Input",
		MaxLength = Config.MaxLength,               -- NEW
		Password = Config.Password or false,        -- NEW
		Clearable = Config.Clearable or false,      -- NEW
		Validation = Config.Validation,              -- NEW: function(value) returns error string or nil
	}

	local InputFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, false)

	Input.SetTitle = InputFrame.SetTitle
	Input.SetDesc = InputFrame.SetDesc

	local Textbox = require(Components.Textbox)(InputFrame.Frame, true)
	Textbox.Frame.Position = UDim2.new(1, -10, 0.5, 0)
	Textbox.Frame.AnchorPoint = Vector2.new(1, 0.5)
	Textbox.Frame.Size = UDim2.fromOffset(160, 30)
	Textbox.Input.Text = Config.Default or ""
	Textbox.Input.PlaceholderText = Config.Placeholder or ""

	-- Password mode
	if Input.Password then
		Textbox.Input.TextXAlignment = Enum.TextXAlignment.Left
		-- We'll use a separate toggle to show/hide
	end

	local Box = Textbox.Input

	-- Password visibility toggle
	local PasswordToggle = nil
	if Input.Password then
		PasswordToggle = New("ImageButton", {
			Size = UDim2.fromOffset(20, 20),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Image = "rbxassetid://10723462360", -- eye icon (replace with better)
			BackgroundTransparency = 1,
			Visible = true,
			Parent = Textbox.Frame,
			ThemeTag = {
				ImageColor3 = "SubText",
			},
		}) :: ImageButton
		Box.TextBox.Password = true
		Box.TextBox.PasswordChar = "•"
	end

	-- Clear button
	local ClearButton = nil
	if Input.Clearable then
		ClearButton = New("ImageButton", {
			Size = UDim2.fromOffset(16, 16),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, - (Input.Password and 28 or 8), 0.5, 0),
			Image = "rbxassetid://10723462360", -- X icon (replace)
			BackgroundTransparency = 1,
			Visible = false,
			Parent = Textbox.Frame,
			ThemeTag = {
				ImageColor3 = "SubText",
			},
		}) :: ImageButton
	end

	-- Character counter
	local CounterLabel = nil
	if Input.MaxLength then
		CounterLabel = New("TextLabel", {
			Size = UDim2.fromOffset(40, 14),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, - (Input.Password and 48 or (Input.Clearable and 28 or 8)), 0.5, 0),
			Text = `0/{Input.MaxLength}`,
			TextColor3 = Color3.fromRGB(150,150,150),
			TextSize = 11,
			Font = Enum.Font.Gotham,
			BackgroundTransparency = 1,
			Parent = Textbox.Frame,
		}) :: TextLabel
	end

	-- Validation error indicator
	local ErrorStroke = New("UIStroke", {
		Thickness = 2,
		Transparency = 1,
		Color = Color3.fromRGB(255, 80, 80),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = Textbox.Frame,
	})

	local function updateValidation()
		if Input.Validation then
			local err = Input.Validation(Box.Text)
			if err then
				ErrorStroke.Transparency = 0
				-- Optionally show a tooltip with the error (advanced)
			else
				ErrorStroke.Transparency = 1
			end
		end
	end

	local function updateCounter()
		if CounterLabel then
			local len = #Box.Text
			CounterLabel.Text = `{len}/{Input.MaxLength}`
			-- Change color if near limit
			if len > Input.MaxLength then
				CounterLabel.TextColor3 = Color3.fromRGB(255,80,80)
			else
				CounterLabel.TextColor3 = Color3.fromRGB(150,150,150)
			end
		end
	end

	local function updateClearButton()
		if ClearButton then
			ClearButton.Visible = Input.Clearable and #Box.Text > 0
		end
	end

	-- Password toggle click
	if PasswordToggle then
		AddSignal(PasswordToggle.MouseButton1Click, function()
			local isPassword = Box.TextBox.Password
			Box.TextBox.Password = not isPassword
			Box.TextBox.PasswordChar = isPassword and "" or "•"
			-- Change icon (optional)
		end)
	end

	-- Clear button click
	if ClearButton then
		AddSignal(ClearButton.MouseButton1Click, function()
			Box.Text = ""
			Input:SetValue("")
			updateClearButton()
		end)
	end

	-- Connect to text changes
	AddSignal(Box:GetPropertyChangedSignal("Text"), function()
		updateCounter()
		updateClearButton()
		updateValidation()
		Input:SetValue(Box.Text)
	end)

	if Input.Finished then
		AddSignal(Box.FocusLost, function(enter: boolean, input: InputObject)
			if not enter then
				return
			end

			Input:SetValue(Box.Text)
			updateValidation()

			if Config.ClearOnFocusLost then
				Box.Text = ""
				updateCounter()
				updateClearButton()
			end
		end)
	end

	function Input:SetValue(Text)
		if Input.MaxLength and #Text > Input.MaxLength then
			Text = Text:sub(1, Input.MaxLength)
		end

		if Input.Numeric then
			if (not tonumber(Text)) and Text:len() > 0 then
				Text = Input.Value
			end
		end

		rawset(Input, "Value", Text)
		Box.Text = Text
		updateCounter()
		updateClearButton()
		updateValidation()

		if typeof(Input.Callback) == "function" then
			Library:SafeCallback(Input.Callback, Input.Value)
		end
		if typeof(Input.Changed) == "function" then
			Library:SafeCallback(Input.Changed, Input.Value)
		end
	end

	function Input:OnChanged(Func)
		Input.Changed = Func
		Library:SafeCallback(Func, Input.Value, Input.Value)
	end

	function Input:Destroy()
		InputFrame:Destroy()
		Library.Options[Idx] = nil
	end

	-- Initial updates
	updateCounter()
	updateClearButton()
	updateValidation()

	Library.Options[Idx] = Input

	Input.Instance = InputFrame

	return setmetatable(Input, {
		__newindex =  function(self, index, newvalue)
			if index == "Value" then
				task.spawn(Input.SetValue, Input, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})
end

return Element
