local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Modules.Creator)
local Acrylic = require(Root.Modules.Acrylic)
local TweenService = game:GetService("TweenService")

local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local New = Creator.New

local Notification = {
	Queue = {},
	Active = 0,
	MaxVisible = 5,
	Holder = nil,
}

function Notification:Init(GUI)
	self.Holder = New("Frame", {
		Position = UDim2.new(1, -30, 1, -30),
		Size = UDim2.new(0, 310, 1, -30),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
		Parent = GUI,
	}, {
		New("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 20),
		}),
	})
end

function Notification:New(Config)
	local self = {}
	self.Config = Config or {}
	self.Config.Title = self.Config.Title or "Title"
	self.Config.Content = self.Config.Content or "Content"
	self.Config.SubContent = self.Config.SubContent or ""
	self.Config.Duration = self.Config.Duration or 5
	self.Config.Icon = self.Config.Icon or nil
	self.Config.Buttons = self.Config.Buttons or {}
	self.Config.Sound = self.Config.Sound or nil

	-- Create the notification GUI
	self.AcrylicPaint = Acrylic.AcrylicPaint()
	self.AcrylicPaint.Frame.Size = UDim2.fromScale(1, 1)
	self.AcrylicPaint.Frame.BackgroundTransparency = 0.2

	-- Title
	self.Title = New("TextLabel", {
		Position = UDim2.new(0, 14, 0, 12),
		Text = self.Config.Title,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255,255,255),
		Size = UDim2.new(1, -50, 0, 20),
		BackgroundTransparency = 1,
	})

	-- Close button
	self.CloseButton = New("TextButton", {
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(1, -30, 0, 12),
		BackgroundTransparency = 1,
		Text = "",
	}, {
		New("ImageLabel", {
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://9886659671",
			BackgroundTransparency = 1,
			ThemeTag = { ImageColor3 = "Text" },
		}),
	})

	-- Optional icon
	self.Icon = nil
	if self.Config.Icon then
		self.Icon = New("ImageLabel", {
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.new(0, 14, 0, 12),
			Image = self.Config.Icon,
			BackgroundTransparency = 1,
		})
	end

	-- Main content
	self.Content = New("TextLabel", {
		Position = UDim2.new(0, 14, 0, 38),
		Text = self.Config.Content,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(240,240,240),
		Size = UDim2.new(1, -28, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})

	-- Sub‑content (optional)
	self.SubContent = nil
	if self.Config.SubContent and self.Config.SubContent ~= "" then
		self.SubContent = New("TextLabel", {
			Position = UDim2.new(0, 14, 0, 38 + self.Content.AbsoluteSize.Y + 4),
			Text = self.Config.SubContent,
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(200,200,200),
			Size = UDim2.new(1, -28, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		})
	end

	-- Button holder
	self.ButtonHolder = nil
	if #self.Config.Buttons > 0 then
		self.ButtonHolder = New("Frame", {
			Position = UDim2.new(0, 14, 0, 38 + (self.Content.AbsoluteSize.Y + 4) * (self.SubContent and 2 or 1)),
			Size = UDim2.new(1, -28, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),
		})

		for _, btnConfig in ipairs(self.Config.Buttons) do
			local btn = self:CreateButton(btnConfig.Title, btnConfig.Callback)
			btn.Parent = self.ButtonHolder
		end
	end

	-- Build the main frame
	self.Frame = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = Notification.Holder,
		LayoutOrder = -Notification.Active, -- so newest appears at bottom
	}, {
		self.AcrylicPaint.Frame,
		self.Title,
		self.CloseButton,
		self.Content,
		self.SubContent,
		self.ButtonHolder,
		self.Icon,
	})

	-- Apply corner rounding
	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 8)
	UICorner.Parent = self.Frame

	-- Play sound if provided
	if self.Config.Sound and self.Config.Sound.SoundId then
		local sound = Instance.new("Sound")
		sound.SoundId = self.Config.Sound.SoundId
		sound.Parent = self.Frame
		sound:Play()
		task.delay(2, sound.Destroy, sound)
	end

	-- Animation: slide + fade in
	self.Frame.Position = UDim2.new(1, 50, 0, 0)
	self.Frame.BackgroundTransparency = 1
	TweenService:Create(self.Frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -10, 0, 0),
		BackgroundTransparency = 0,
	}):Play()

	-- Close button click
	self.CloseButton.MouseButton1Click:Connect(function()
		self:Close()
	end)

	-- Auto‑close after duration
	if self.Config.Duration > 0 then
		task.delay(self.Config.Duration, function()
			if self.Frame and self.Frame.Parent then
				self:Close()
			end
		end)
	end

	-- Store in queue
	Notification.Active = Notification.Active + 1
	table.insert(Notification.Queue, self)

	return self
end

function Notification:CreateButton(text, callback)
	local btn = New("TextButton", {
		Size = UDim2.fromOffset(60, 28),
		Text = text,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255,255,255),
		BackgroundColor3 = Color3.fromRGB(60,60,60),
		AutoButtonColor = false,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 4) }),
	})
	btn.MouseButton1Click:Connect(function()
		if callback then callback() end
		self:Close()
	end)
	return btn
end

function Notification:Close()
	if not self.Frame then return end

	-- Animate out
	TweenService:Create(self.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
		Position = UDim2.new(1, 50, 0, 0),
		BackgroundTransparency = 1,
	}):Play()

	task.delay(0.3, function()
		if self.AcrylicPaint then
			self.AcrylicPaint.Model:Destroy()
		end
		self.Frame:Destroy()

		Notification.Active = Notification.Active - 1
		-- Remove from queue
		for i, n in ipairs(Notification.Queue) do
			if n == self then
				table.remove(Notification.Queue, i)
				break
			end
		end
	end)
end

return Notification
