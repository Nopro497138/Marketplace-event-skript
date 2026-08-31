--[[
	ProfessionalUI.lua — Rayfield-Style UI Demo

	Baut eine eigenständige UI-Library im Look von Rayfield nach:
	- Fenster mit Titel/Subtitle, draggable, minimierbar
	- Sidebar mit Tabs
	- Sections mit Elementen: Button, Toggle, Slider, Dropdown, Label
	- Notification-System (unten rechts, mit Progressbar)
	- Keybind zum Ein-/Ausblenden (RightShift)

	Als LocalScript in StarterPlayerScripts einfügen.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============ Theme ============

local Theme = {
	Background   = Color3.fromRGB(25, 25, 25),
	Topbar       = Color3.fromRGB(30, 30, 30),
	Sidebar      = Color3.fromRGB(28, 28, 28),
	Section      = Color3.fromRGB(34, 34, 34),
	Element      = Color3.fromRGB(40, 40, 40),
	ElementHover = Color3.fromRGB(48, 48, 48),
	Accent       = Color3.fromRGB(60, 150, 255),
	Text         = Color3.fromRGB(240, 240, 240),
	SubText      = Color3.fromRGB(145, 145, 150),
	Stroke       = Color3.fromRGB(255, 255, 255),
}

local FONT = Enum.Font.Gotham
local FONT_BOLD = Enum.Font.GothamSemibold

-- ============ Helpers ============

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

local function stroke(parent, transparency, thickness)
	local s = Instance.new("UIStroke")
	s.Color = Theme.Stroke
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.9
	s.Parent = parent
	return s
end

local function tween(inst, props, dur, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function makeDraggable(handle, target)
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ============ Root ScreenGui ============

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RayfieldStyleUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ============ Window ============

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.Position = UDim2.fromScale(0.5, 0.5)
Window.Size = UDim2.fromOffset(560, 360)
Window.BackgroundColor3 = Theme.Background
Window.BackgroundTransparency = 1
Window.ClipsDescendants = true
Window.Parent = screenGui
corner(Window, 8)
stroke(Window, 0.85)

local FULL_HEIGHT = 360

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.BackgroundColor3 = Theme.Topbar
Topbar.Size = UDim2.new(1, 0, 0, 42)
Topbar.Parent = Window
corner(Topbar, 8)

local topbarFix = Instance.new("Frame") -- untere Ecken des Topbars wieder eckig
topbarFix.BackgroundColor3 = Theme.Topbar
topbarFix.BorderSizePixel = 0
topbarFix.Position = UDim2.new(0, 0, 1, -8)
topbarFix.Size = UDim2.new(1, 0, 0, 8)
topbarFix.Parent = Topbar

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 16, 0, 0)
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Font = FONT_BOLD
Title.TextSize = 15
Title.TextColor3 = Theme.Text
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Text = "My Hub"
Title.Parent = Topbar

local Subtitle = Instance.new("TextLabel")
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.new(0, 16, 0, 14)
Subtitle.Size = UDim2.new(0.6, 0, 1, 0)
Subtitle.Font = FONT
Subtitle.TextSize = 12
Subtitle.TextColor3 = Theme.SubText
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.TextYAlignment = Enum.TextYAlignment.Top
Subtitle.Text = "by you"
Subtitle.Parent = Topbar

local minimized = false

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.AnchorPoint = Vector2.new(1, 0.5)
MinimizeBtn.Position = UDim2.new(1, -44, 0.5, 0)
MinimizeBtn.Size = UDim2.fromOffset(26, 26)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Font = FONT_BOLD
MinimizeBtn.TextSize = 16
MinimizeBtn.TextColor3 = Theme.SubText
MinimizeBtn.Text = "–"
MinimizeBtn.Parent = Topbar

local CloseBtn = Instance.new("TextButton")
CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
CloseBtn.Position = UDim2.new(1, -12, 0.5, 0)
CloseBtn.Size = UDim2.fromOffset(26, 26)
CloseBtn.BackgroundTransparency = 1
CloseBtn.AutoButtonColor = false
CloseBtn.Font = FONT_BOLD
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Theme.SubText
CloseBtn.Text = "×"
CloseBtn.Parent = Topbar

for _, btn in ipairs({ MinimizeBtn, CloseBtn }) do
	btn.MouseEnter:Connect(function() tween(btn, { TextColor3 = Theme.Text }, 0.15) end)
	btn.MouseLeave:Connect(function() tween(btn, { TextColor3 = Theme.SubText }, 0.15) end)
end

makeDraggable(Topbar, Window)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.Position = UDim2.new(0, 0, 0, 42)
Sidebar.Size = UDim2.new(0, 140, 1, -42)
Sidebar.Parent = Window

local TabList = Instance.new("Frame")
TabList.BackgroundTransparency = 1
TabList.Position = UDim2.new(0, 8, 0, 10)
TabList.Size = UDim2.new(1, -16, 1, -20)
TabList.Parent = Sidebar

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Padding = UDim.new(0, 4)
TabListLayout.Parent = TabList

-- Content
local ContentHolder = Instance.new("Frame")
ContentHolder.Name = "ContentHolder"
ContentHolder.BackgroundTransparency = 1
ContentHolder.Position = UDim2.new(0, 140, 0, 42)
ContentHolder.Size = UDim2.new(1, -140, 1, -42)
ContentHolder.Parent = Window

-- ============ Notifications ============

local NotifyHolder = Instance.new("Frame")
NotifyHolder.Name = "Notifications"
NotifyHolder.AnchorPoint = Vector2.new(1, 1)
NotifyHolder.Position = UDim2.new(1, -20, 1, -20)
NotifyHolder.Size = UDim2.fromOffset(280, 400)
NotifyHolder.BackgroundTransparency = 1
NotifyHolder.Parent = screenGui

local NotifyLayout = Instance.new("UIListLayout")
NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifyLayout.Padding = UDim.new(0, 8)
NotifyLayout.Parent = NotifyHolder

local function Notify(titleText, contentText, duration)
	duration = duration or 3.5

	local notif = Instance.new("Frame")
	notif.BackgroundColor3 = Theme.Section
	notif.Size = UDim2.new(1, 0, 0, 64)
	notif.ClipsDescendants = true
	notif.Parent = NotifyHolder
	corner(notif, 8)
	stroke(notif, 0.85)

	-- start off-screen (rechts) und transparent
	notif.Position = UDim2.fromOffset(300, 0)

	local nTitle = Instance.new("TextLabel")
	nTitle.BackgroundTransparency = 1
	nTitle.Position = UDim2.new(0, 12, 0, 8)
	nTitle.Size = UDim2.new(1, -24, 0, 18)
	nTitle.Font = FONT_BOLD
	nTitle.TextSize = 14
	nTitle.TextColor3 = Theme.Text
	nTitle.TextXAlignment = Enum.TextXAlignment.Left
	nTitle.Text = titleText
	nTitle.Parent = notif

	local nContent = Instance.new("TextLabel")
	nContent.BackgroundTransparency = 1
	nContent.Position = UDim2.new(0, 12, 0, 28)
	nContent.Size = UDim2.new(1, -24, 0, 24)
	nContent.Font = FONT
	nContent.TextSize = 12
	nContent.TextColor3 = Theme.SubText
	nContent.TextXAlignment = Enum.TextXAlignment.Left
	nContent.TextWrapped = true
	nContent.Text = contentText
	nContent.Parent = notif

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, 1)
	bar.Position = UDim2.new(0, 0, 1, 0)
	bar.Size = UDim2.new(1, 0, 0, 3)
	bar.BackgroundColor3 = Theme.Accent
	bar.BorderSizePixel = 0
	bar.Parent = notif

	tween(notif, { Position = UDim2.fromOffset(0, 0) }, 0.35, Enum.EasingStyle.Back)
	tween(bar, { Size = UDim2.new(0, 0, 0, 3) }, duration, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		tween(notif, { Position = UDim2.fromOffset(300, 0) }, 0.3, Enum.EasingStyle.Quint)
		task.delay(0.3, function() notif:Destroy() end)
	end)
end

-- ============ Tabs / Sections / Elements ============

local tabs = {}
local pages = {}
local firstTab = true

local function CreateTab(name)
	local tabBtn = Instance.new("TextButton")
	tabBtn.BackgroundTransparency = 1
	tabBtn.Size = UDim2.new(1, 0, 0, 32)
	tabBtn.AutoButtonColor = false
	tabBtn.Font = FONT
	tabBtn.TextSize = 13
	tabBtn.TextColor3 = Theme.SubText
	tabBtn.Text = name
	tabBtn.Parent = TabList
	corner(tabBtn, 6)

	local page = Instance.new("ScrollingFrame")
	page.BackgroundTransparency = 1
	page.Size = UDim2.fromScale(1, 1)
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Theme.Accent
	page.Visible = firstTab
	page.Parent = ContentHolder

	local pagePad = Instance.new("UIPadding")
	pagePad.PaddingTop = UDim.new(0, 12)
	pagePad.PaddingLeft = UDim.new(0, 12)
	pagePad.PaddingRight = UDim.new(0, 12)
	pagePad.Parent = page

	local pageLayout = Instance.new("UIListLayout")
	pageLayout.Padding = UDim.new(0, 10)
	pageLayout.Parent = page

	if firstTab then
		tween(tabBtn, { BackgroundTransparency = 0, BackgroundColor3 = Theme.Element }, 0.001)
		tabBtn.TextColor3 = Theme.Text
		firstTab = false
	end

	tabBtn.MouseButton1Click:Connect(function()
		for _, t in ipairs(tabs) do
			tween(t.btn, { BackgroundTransparency = 1 }, 0.15)
			tween(t.btn, { TextColor3 = Theme.SubText }, 0.15)
			t.page.Visible = false
		end
		tabBtn.BackgroundColor3 = Theme.Element
		tween(tabBtn, { BackgroundTransparency = 0 }, 0.15)
		tween(tabBtn, { TextColor3 = Theme.Text }, 0.15)
		page.Visible = true
	end)

	tabBtn.MouseEnter:Connect(function()
		if page.Visible then return end
		tween(tabBtn, { BackgroundTransparency = 0.85, BackgroundColor3 = Theme.Element }, 0.15)
	end)
	tabBtn.MouseLeave:Connect(function()
		if page.Visible then return end
		tween(tabBtn, { BackgroundTransparency = 1 }, 0.15)
	end)

	table.insert(tabs, { btn = tabBtn, page = page })

	local TabObject = {}

	function TabObject:CreateSection(sectionName)
		local section = Instance.new("Frame")
		section.BackgroundColor3 = Theme.Section
		section.Size = UDim2.new(1, -6, 0, 0)
		section.AutomaticSize = Enum.AutomaticSize.Y
		section.Parent = page
		corner(section, 8)
		stroke(section, 0.9)

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 10)
		pad.PaddingBottom = UDim.new(0, 10)
		pad.PaddingLeft = UDim.new(0, 10)
		pad.PaddingRight = UDim.new(0, 10)
		pad.Parent = section

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.Parent = section

		local header = Instance.new("TextLabel")
		header.BackgroundTransparency = 1
		header.Size = UDim2.new(1, 0, 0, 16)
		header.Font = FONT_BOLD
		header.TextSize = 13
		header.TextColor3 = Theme.Text
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Text = sectionName
		header.LayoutOrder = 0
		header.Parent = section

		local order = 1
		local SectionObject = {}

		function SectionObject:CreateButton(text, callback)
			order += 1
			local btn = Instance.new("TextButton")
			btn.LayoutOrder = order
			btn.Size = UDim2.new(1, 0, 0, 32)
			btn.BackgroundColor3 = Theme.Element
			btn.AutoButtonColor = false
			btn.Font = FONT
			btn.TextSize = 13
			btn.TextColor3 = Theme.Text
			btn.Text = text
			btn.Parent = section
			corner(btn, 6)

			btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = Theme.ElementHover }, 0.15) end)
			btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = Theme.Element }, 0.15) end)
			btn.MouseButton1Click:Connect(function()
				tween(btn, { BackgroundColor3 = Theme.Accent }, 0.08)
				task.delay(0.08, function() tween(btn, { BackgroundColor3 = Theme.ElementHover }, 0.15) end)
				if callback then callback() end
			end)
			return btn
		end

		function SectionObject:CreateToggle(text, default, callback)
			order += 1
			local state = default or false

			local holder = Instance.new("Frame")
			holder.LayoutOrder = order
			holder.BackgroundColor3 = Theme.Element
			holder.Size = UDim2.new(1, 0, 0, 32)
			holder.Parent = section
			corner(holder, 6)

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Position = UDim2.new(0, 10, 0, 0)
			label.Size = UDim2.new(1, -60, 1, 0)
			label.Font = FONT
			label.TextSize = 13
			label.TextColor3 = Theme.Text
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Text = text
			label.Parent = holder

			local track = Instance.new("Frame")
			track.AnchorPoint = Vector2.new(1, 0.5)
			track.Position = UDim2.new(1, -10, 0.5, 0)
			track.Size = UDim2.fromOffset(36, 20)
			track.BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(55, 55, 55)
			track.Parent = holder
			corner(track, 10)

			local knob = Instance.new("Frame")
			knob.Size = UDim2.fromOffset(16, 16)
			knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
			knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			knob.Parent = track
			corner(knob, 8)

			local click = Instance.new("TextButton")
			click.BackgroundTransparency = 1
			click.Size = UDim2.fromScale(1, 1)
			click.Text = ""
			click.Parent = holder

			click.MouseButton1Click:Connect(function()
				state = not state
				tween(track, { BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(55, 55, 55) }, 0.15)
				tween(knob, { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) }, 0.15)
				if callback then callback(state) end
			end)
			return holder
		end

		function SectionObject:CreateSlider(text, min, max, default, callback)
			order += 1
			local value = default or min

			local holder = Instance.new("Frame")
			holder.LayoutOrder = order
			holder.BackgroundColor3 = Theme.Element
			holder.Size = UDim2.new(1, 0, 0, 46)
			holder.Parent = section
			corner(holder, 6)

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Position = UDim2.new(0, 10, 0, 4)
			label.Size = UDim2.new(1, -60, 0, 16)
			label.Font = FONT
			label.TextSize = 13
			label.TextColor3 = Theme.Text
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Text = text
			label.Parent = holder

			local valueLabel = Instance.new("TextLabel")
			valueLabel.BackgroundTransparency = 1
			valueLabel.AnchorPoint = Vector2.new(1, 0)
			valueLabel.Position = UDim2.new(1, -10, 0, 4)
			valueLabel.Size = UDim2.fromOffset(40, 16)
			valueLabel.Font = FONT
			valueLabel.TextSize = 13
			valueLabel.TextColor3 = Theme.SubText
			valueLabel.TextXAlignment = Enum.TextXAlignment.Right
			valueLabel.Text = tostring(value)
			valueLabel.Parent = holder

			local track = Instance.new("Frame")
			track.Position = UDim2.new(0, 10, 1, -14)
			track.Size = UDim2.new(1, -20, 0, 6)
			track.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
			track.Parent = holder
			corner(track, 3)

			local fill = Instance.new("Frame")
			fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
			fill.BackgroundColor3 = Theme.Accent
			fill.Parent = track
			corner(fill, 3)

			local dragging = false
			local function updateFromX(xPos)
				local pct = math.clamp((xPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				value = math.floor(min + (max - min) * pct + 0.5)
				fill.Size = UDim2.new(pct, 0, 1, 0)
				valueLabel.Text = tostring(value)
				if callback then callback(value) end
			end

			track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					updateFromX(input.Position.X)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromX(input.Position.X)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			return holder
		end

		function SectionObject:CreateDropdown(text, options, default, callback)
			order += 1
			local selected = default or options[1]
			local open = false

			local holder = Instance.new("Frame")
			holder.LayoutOrder = order
			holder.BackgroundColor3 = Theme.Element
			holder.Size = UDim2.new(1, 0, 0, 32)
			holder.ClipsDescendants = true
			holder.ZIndex = 2
			holder.Parent = section
			corner(holder, 6)

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Position = UDim2.new(0, 10, 0, 0)
			label.Size = UDim2.new(0.5, 0, 0, 32)
			label.Font = FONT
			label.TextSize = 13
			label.TextColor3 = Theme.Text
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Text = text
			label.Parent = holder

			local selectedLabel = Instance.new("TextLabel")
			selectedLabel.BackgroundTransparency = 1
			selectedLabel.AnchorPoint = Vector2.new(1, 0)
			selectedLabel.Position = UDim2.new(1, -28, 0, 0)
			selectedLabel.Size = UDim2.new(0.4, 0, 0, 32)
			selectedLabel.Font = FONT
			selectedLabel.TextSize = 13
			selectedLabel.TextColor3 = Theme.SubText
			selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
			selectedLabel.Text = selected
			selectedLabel.Parent = holder

			local chevron = Instance.new("TextLabel")
			chevron.BackgroundTransparency = 1
			chevron.AnchorPoint = Vector2.new(1, 0)
			chevron.Position = UDim2.new(1, -8, 0, 0)
			chevron.Size = UDim2.fromOffset(16, 32)
			chevron.Font = FONT_BOLD
			chevron.TextSize = 12
			chevron.TextColor3 = Theme.SubText
			chevron.Text = "v"
			chevron.Parent = holder

			local optionList = Instance.new("Frame")
			optionList.Position = UDim2.new(0, 0, 0, 34)
			optionList.Size = UDim2.new(1, 0, 0, #options * 26)
			optionList.BackgroundTransparency = 1
			optionList.Parent = holder

			local optListLayout = Instance.new("UIListLayout")
			optListLayout.Parent = optionList

			for _, opt in ipairs(options) do
				local optBtn = Instance.new("TextButton")
				optBtn.Size = UDim2.new(1, 0, 0, 26)
				optBtn.BackgroundTransparency = 1
				optBtn.AutoButtonColor = false
				optBtn.Font = FONT
				optBtn.TextSize = 12
				optBtn.TextColor3 = Theme.SubText
				optBtn.Text = opt
				optBtn.Parent = optionList

				optBtn.MouseEnter:Connect(function() tween(optBtn, { TextColor3 = Theme.Text }, 0.1) end)
				optBtn.MouseLeave:Connect(function() tween(optBtn, { TextColor3 = Theme.SubText }, 0.1) end)
				optBtn.MouseButton1Click:Connect(function()
					selected = opt
					selectedLabel.Text = opt
					open = false
					tween(holder, { Size = UDim2.new(1, 0, 0, 32) }, 0.2)
					tween(chevron, { Rotation = 0 }, 0.2)
					if callback then callback(opt) end
				end)
			end

			local clickArea = Instance.new("TextButton")
			clickArea.BackgroundTransparency = 1
			clickArea.Size = UDim2.new(1, 0, 0, 32)
			clickArea.Text = ""
			clickArea.ZIndex = 3
			clickArea.Parent = holder

			clickArea.MouseButton1Click:Connect(function()
				open = not open
				local targetSize = open and UDim2.new(1, 0, 0, 34 + #options * 26) or UDim2.new(1, 0, 0, 32)
				tween(holder, { Size = targetSize }, 0.2)
				tween(chevron, { Rotation = open and 180 or 0 }, 0.2)
			end)
			return holder
		end

		function SectionObject:CreateLabel(text)
			order += 1
			local label = Instance.new("TextLabel")
			label.LayoutOrder = order
			label.BackgroundTransparency = 1
			label.Size = UDim2.new(1, 0, 0, 16)
			label.Font = FONT
			label.TextSize = 12
			label.TextColor3 = Theme.SubText
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			label.Text = text
			label.Parent = section
			return label
		end

		return SectionObject
	end

	return TabObject
end

-- ============ Demo-Inhalt ============

local homeTab = CreateTab("Home")
local mainSection = homeTab:CreateSection("Allgemein")
mainSection:CreateLabel("Willkommen! Das ist eine Rayfield-Style Demo-UI.")
mainSection:CreateButton("Klick mich", function()
	Notify("Button geklickt", "Du hast gerade den Demo-Button betätigt.", 3)
end)
mainSection:CreateToggle("Auto-Farm aktivieren", false, function(state)
	Notify("Auto-Farm", state and "Aktiviert" or "Deaktiviert", 2.5)
end)
mainSection:CreateSlider("Geschwindigkeit", 0, 100, 50, function(value)
	-- Live-Wert, z.B. WalkSpeed setzen
end)
mainSection:CreateDropdown("Modus wählen", { "Einfach", "Normal", "Schwer" }, "Normal", function(opt)
	Notify("Modus geändert", "Neuer Modus: " .. opt, 2.5)
end)

local settingsTab = CreateTab("Settings")
local uiSection = settingsTab:CreateSection("Oberfläche")
uiSection:CreateToggle("UI-Sounds", true, nil)
uiSection:CreateSlider("Transparenz", 0, 100, 20, nil)
uiSection:CreateLabel("Drücke RightShift um die UI ein-/auszublenden.")

-- ============ Minimize / Öffnungsanimation / Keybind ============

MinimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	Sidebar.Visible = not minimized
	ContentHolder.Visible = not minimized
	tween(Window, { Size = minimized and UDim2.fromOffset(560, 42) or UDim2.fromOffset(560, FULL_HEIGHT) }, 0.25)
	MinimizeBtn.Text = minimized and "+" or "–"
end)

CloseBtn.MouseButton1Click:Connect(function()
	tween(Window, { BackgroundTransparency = 1, Size = Window.Size - UDim2.fromOffset(40, 40) }, 0.2)
	task.delay(0.2, function() screenGui.Enabled = false end)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		screenGui.Enabled = not screenGui.Enabled
	end
end)

Window.BackgroundTransparency = 1
Window.Size = UDim2.fromOffset(560, 340)
tween(Window, { BackgroundTransparency = 0, Size = UDim2.fromOffset(560, FULL_HEIGHT) }, 0.35, Enum.EasingStyle.Back)
