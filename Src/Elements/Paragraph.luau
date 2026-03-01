local Root = script.Parent.Parent
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Paragraph"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "Paragraph - Missing Title")
	Config.Content = Config.Content or ""

	local Paragraph = {
		Value = Config.Content,
		Callback = Config.Callback or function(Value: string) end,
		Type = "Paragraph",
		Copyable = Config.Copyable ~= false, -- default true
	}

	local ParagraphFrame = require(Components.Element)(Config.Title, Paragraph.Value, self.Container, false, {
		TitleAlignment = Config.TitleAlignment == "Middle" and "Center" or Config.TitleAlignment,
		DescriptionAlignment = Config.ContentAlignment == "Middle" and "Center" or Config.ContentAlignment
	})

	ParagraphFrame.Frame.BackgroundTransparency = 0.92
	ParagraphFrame.Border.Transparency = 0.6

	-- Copy button (only if Copyable)
	local CopyButton = nil
	if Paragraph.Copyable then
		CopyButton = New("ImageButton", {
			Size = UDim2.fromOffset(20, 20),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 8),
			Image = "rbxassetid://10723462360", -- clipboard icon (use a better one if available)
			BackgroundTransparency = 1,
			Visible = false, -- initially hidden
			Parent = ParagraphFrame.Frame,
			ThemeTag = {
				ImageColor3 = "SubText",
			},
		}) :: ImageButton

		-- Show on hover
		Creator.AddSignal(ParagraphFrame.Frame.MouseEnter, function()
			CopyButton.Visible = true
		end)
		Creator.AddSignal(ParagraphFrame.Frame.MouseLeave, function()
			CopyButton.Visible = false
		end)

		-- Copy functionality
		Creator.AddSignal(CopyButton.MouseButton1Click, function()
			local content = Paragraph.Value
			local success, err = pcall(function()
				if setclipboard then
					setclipboard(content)
				elseif Clipboard and Clipboard.set then
					Clipboard.set(content)
				else
					-- fallback: try to use a TextBox hack (less reliable)
					local tb = Instance.new("TextBox")
					tb.Parent = Library.GUI
					tb.Text = content
					tb:CaptureFocus()
					tb:ReleaseFocus(nil)
					tb:Destroy()
				end
			end)
			if not success then
				Library:Notify({
					Title = "Copy Failed",
					Content = "Could not copy to clipboard.",
					Duration = 3,
				})
			else
				Library:Notify({
					Title = "Copied!",
					Content = "Paragraph content copied.",
					Duration = 2,
				})
			end
		end)
	end

	function Paragraph:OnChanged(Func)
		Paragraph.Changed = Func
		Library:SafeCallback(Func, Paragraph.Value, Paragraph.Value)
	end

	function Paragraph:SetContent(Value)
		Value = Value or ""
		rawset(Paragraph, "Value", Value)

		ParagraphFrame:SetDesc(Value)

		ParagraphFrame.Frame.BackgroundTransparency = 0.92
		ParagraphFrame.Border.Transparency = 0.6

		if typeof(Paragraph.Callback) == "function" then
			Library:SafeCallback(Paragraph.Callback, Paragraph.Value)
		end
		if typeof(Paragraph.Changed) == "function" then
			Library:SafeCallback(Paragraph.Changed, Paragraph.Value)
		end
	end

	function Paragraph:SetValue(Value)
		Paragraph:SetContent(Value)
	end

	function Paragraph:Destroy()
		ParagraphFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Paragraph:SetValue(Paragraph.Value)

	Library.Options[Idx] = Paragraph

	Paragraph.Instance = ParagraphFrame

	return setmetatable(Paragraph, {
		__newindex =  function(self, index, newvalue)
			if index == "Value" then
				task.spawn(Paragraph.SetValue, Paragraph, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})

end

return Element
