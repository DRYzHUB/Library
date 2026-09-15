--[[
	AuroraUI — A modern, beautiful UI Library for Roblox
	--------------------------------------------------------------
	Features:
		• Draggable window with smooth tween animations
		• Tabs with icons, Sections, Buttons, Toggles, Sliders,
		  Dropdowns, Textboxes, Color pickers, Keybinds and Labels
		• Notification system
		• Minimize / Close controls
		• Toggle visibility with a keybind
		• Clean dark theme with a customizable accent color

	Usage:
		local AuroraUI = loadstring(game:HttpGet("...AuroraUI.lua"))()
		-- or: local AuroraUI = require(path.to.ModuleScript)

		local Window = AuroraUI:CreateWindow({
			Title = "Aurora",
			SubTitle = "v1.0",
			ToggleKey = Enum.KeyCode.RightControl,
		})

		local Tab = Window:CreateTab("Main", "home")
		local Section = Tab:CreateSection("General")

		Section:CreateButton({
			Name = "Click me",
			Callback = function() print("clicked!") end,
		})

		Section:CreateToggle({
			Name = "Enable Feature",
			Default = false,
			Callback = function(state) print(state) end,
		})
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------------------------
-- THEME
--------------------------------------------------------------------
local Theme = {
	Background   = Color3.fromRGB(20, 20, 24),
	Elevated     = Color3.fromRGB(27, 27, 33),
	Secondary    = Color3.fromRGB(34, 34, 41),
	Stroke       = Color3.fromRGB(48, 48, 56),
	Accent       = Color3.fromRGB(139, 92, 246),
	AccentLight  = Color3.fromRGB(173, 141, 255),
	Text         = Color3.fromRGB(240, 240, 245),
	SubText      = Color3.fromRGB(150, 150, 162),
	Success      = Color3.fromRGB(90, 220, 140),
	Error        = Color3.fromRGB(240, 90, 90),
	Font         = Enum.Font.GothamMedium,
	FontBold     = Enum.Font.GothamBold,
}

--------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------
local function create(class, props, children)
	local inst = Instance.new(class)
	for prop, value in pairs(props or {}) do
		inst[prop] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function tween(obj, props, duration, style, direction)
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(color, thickness, transparency)
	return create("UIStroke", {
		Color = color or Theme.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
	})
end

local function padding(all)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
	})
end

local function makeDraggable(dragHandle, target)
	local dragging, dragStart, startPos = false, nil, nil

	dragHandle.InputBegan:Connect(function(input)
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

	dragHandle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--------------------------------------------------------------------
-- LIBRARY
--------------------------------------------------------------------
local AuroraUI = {}
AuroraUI.__index = AuroraUI

function AuroraUI:CreateWindow(config)
	config = config or {}
	local title = config.Title or "Aurora UI"
	local subTitle = config.SubTitle or ""
	local toggleKey = config.ToggleKey or Enum.KeyCode.RightControl
	local windowSize = config.Size or UDim2.fromOffset(560, 380)

	-- Root ScreenGui
	local ScreenGui = create("ScreenGui", {
		Name = "AuroraUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui,
	})
	pcall(function()
		ScreenGui.IgnoreGuiInset = true
	end)

	-- Main container
	local Main = create("Frame", {
		Name = "Main",
		Size = windowSize,
		Position = UDim2.new(0.5, -windowSize.X.Offset / 2, 0.5, -windowSize.Y.Offset / 2),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Parent = ScreenGui,
		ClipsDescendants = true,
	}, { corner(12), stroke(Theme.Stroke, 1) })

	-- subtle drop shadow
	create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		Size = UDim2.new(1, 60, 1, 60),
		Position = UDim2.new(0, -30, 0, -30),
		ZIndex = 0,
		Parent = Main,
	})

	-- Top bar
	local TopBar = create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = Theme.Elevated,
		BorderSizePixel = 0,
		Parent = Main,
	}, { corner(12) })

	-- cover bottom corners of topbar so it looks square-bottomed against body
	create("Frame", {
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = Theme.Elevated,
		BorderSizePixel = 0,
		Parent = TopBar,
	})

	create("Frame", {
		Size = UDim2.new(0, 4, 0, 22),
		Position = UDim2.new(0, 16, 0.5, -11),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = TopBar,
	}, { corner(2) })

	create("TextLabel", {
		Name = "Title",
		Text = title,
		Font = Theme.FontBold,
		TextSize = 16,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 30, 0, 6),
		Size = UDim2.new(0, 250, 0, 20),
		Parent = TopBar,
	})

	create("TextLabel", {
		Name = "SubTitle",
		Text = subTitle,
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 30, 0, 25),
		Size = UDim2.new(0, 250, 0, 16),
		Parent = TopBar,
	})

	-- Close / minimize buttons
	local CloseBtn = create("TextButton", {
		Name = "Close",
		Text = "",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -38, 0.5, -14),
		BackgroundColor3 = Theme.Secondary,
		AutoButtonColor = false,
		Parent = TopBar,
	}, { corner(8) })
	create("TextLabel", {
		Text = "✕",
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = CloseBtn,
	})

	local MinBtn = create("TextButton", {
		Name = "Minimize",
		Text = "",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -72, 0.5, -14),
		BackgroundColor3 = Theme.Secondary,
		AutoButtonColor = false,
		Parent = TopBar,
	}, { corner(8) })
	create("TextLabel", {
		Text = "–",
		Font = Theme.FontBold,
		TextSize = 15,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = MinBtn,
	})

	for _, btn in ipairs({ CloseBtn, MinBtn }) do
		btn.MouseEnter:Connect(function()
			tween(btn, { BackgroundColor3 = Theme.Stroke }, 0.15)
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, { BackgroundColor3 = Theme.Secondary }, 0.15)
		end)
	end

	makeDraggable(TopBar, Main)

	-- Body: Tab list (left) + Pages (right)
	local Body = create("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 1, -48),
		Position = UDim2.new(0, 0, 0, 48),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	local TabList = create("Frame", {
		Name = "TabList",
		Size = UDim2.new(0, 140, 1, -16),
		Position = UDim2.new(0, 8, 0, 8),
		BackgroundColor3 = Theme.Elevated,
		BorderSizePixel = 0,
		Parent = Body,
	}, { corner(10), padding(8) })

	local TabListLayout = create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = TabList,
	})

	local Pages = create("Frame", {
		Name = "Pages",
		Size = UDim2.new(1, -164, 1, -16),
		Position = UDim2.new(0, 156, 0, 8),
		BackgroundTransparency = 1,
		Parent = Body,
	})

	-- Notification holder
	local NotifHolder = create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 280, 1, -32),
		BackgroundTransparency = 1,
		Parent = ScreenGui,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = NotifHolder,
	})

	-- Minimize / show logic
	local minimized = false
	local fullSize = windowSize
	MinBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			tween(Main, { Size = UDim2.new(0, fullSize.X.Offset, 0, 48) }, 0.3)
			Body.Visible = false
		else
			Body.Visible = true
			tween(Main, { Size = fullSize }, 0.3)
		end
	end)

	local visible = true
	CloseBtn.MouseButton1Click:Connect(function()
		visible = false
		tween(Main, { Size = UDim2.fromOffset(0, 0) }, 0.25)
		task.delay(0.25, function()
			ScreenGui.Enabled = false
		end)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == toggleKey then
			visible = not visible
			ScreenGui.Enabled = true
			if visible then
				Main.Size = UDim2.fromOffset(0, 0)
				tween(Main, { Size = fullSize }, 0.25)
			else
				tween(Main, { Size = UDim2.fromOffset(0, 0) }, 0.2)
				task.delay(0.2, function()
					ScreenGui.Enabled = false
				end)
			end
		end
	end)

	--------------------------------------------------------------
	-- Window object
	--------------------------------------------------------------
	local Window = setmetatable({}, { __index = {} })
	Window.ScreenGui = ScreenGui
	Window._tabButtons = {}
	Window._firstTab = nil

	function Window:Notify(config)
		config = config or {}
		local nTitle = config.Title or "Notification"
		local content = config.Content or ""
		local duration = config.Duration or 4
		local kind = config.Type or "Info" -- Info | Success | Error

		local color = Theme.Accent
		if kind == "Success" then color = Theme.Success end
		if kind == "Error" then color = Theme.Error end

		local Notif = create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.Elevated,
			BorderSizePixel = 0,
			LayoutOrder = -os.clock(),
			BackgroundTransparency = 1,
			Parent = NotifHolder,
		}, { corner(10), stroke(Theme.Stroke), padding(12) })

		create("Frame", {
			Size = UDim2.new(0, 3, 1, -8),
			Position = UDim2.new(0, 0, 0, 4),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = Notif,
		}, { corner(2) })

		local TitleLbl = create("TextLabel", {
			Text = nTitle,
			Font = Theme.FontBold,
			TextSize = 14,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -12, 0, 18),
			Position = UDim2.new(0, 12, 0, 0),
			Parent = Notif,
		})

		create("TextLabel", {
			Text = content,
			Font = Theme.Font,
			TextSize = 12,
			TextColor3 = Theme.SubText,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, -12, 0, 0),
			Position = UDim2.new(0, 12, 0, 20),
			Parent = Notif,
		})

		for _, obj in ipairs(Notif:GetDescendants()) do
			if obj:IsA("GuiObject") and obj ~= Notif then
				-- keep children as-is
			end
		end

		Notif.BackgroundTransparency = 1
		tween(Notif, { BackgroundTransparency = 0 }, 0.25)

		task.delay(duration, function()
			tween(Notif, { BackgroundTransparency = 1 }, 0.3)
			task.delay(0.3, function()
				Notif:Destroy()
			end)
		end)
	end

	--------------------------------------------------------------
	-- Tabs
	--------------------------------------------------------------
	function Window:CreateTab(name, icon)
		local TabButton = create("TextButton", {
			Name = name,
			Text = "",
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = Theme.Secondary,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Parent = TabList,
		}, { corner(8) })

		create("TextLabel", {
			Text = (icon and ("•  ") or "") .. name,
			Font = Theme.Font,
			TextSize = 13,
			TextColor3 = Theme.SubText,
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.new(0, 12, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Name = "Label",
			Parent = TabButton,
		})

		local Page = create("ScrollingFrame", {
			Name = name .. "Page",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = Pages,
		})
		local PageLayout = create("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = Page,
		})

		local Tab = setmetatable({}, { __index = {} })
		Tab.Button = TabButton
		Tab.Page = Page

		local function selectTab()
			for _, t in pairs(Window._tabButtons) do
				tween(t.Button, { BackgroundTransparency = 1 }, 0.15)
				t.Button.Label.TextColor3 = Theme.SubText
				t.Page.Visible = false
			end
			tween(TabButton, { BackgroundTransparency = 0 }, 0.15)
			TabButton.Label.TextColor3 = Theme.Text
			Page.Visible = true
		end

		TabButton.MouseButton1Click:Connect(selectTab)
		TabButton.MouseEnter:Connect(function()
			if not Page.Visible then
				tween(TabButton, { BackgroundTransparency = 0.6 }, 0.15)
			end
		end)
		TabButton.MouseLeave:Connect(function()
			if not Page.Visible then
				tween(TabButton, { BackgroundTransparency = 1 }, 0.15)
			end
		end)

		table.insert(Window._tabButtons, Tab)
		if not Window._firstTab then
			Window._firstTab = Tab
			selectTab()
		end

		----------------------------------------------------------
		-- Sections
		----------------------------------------------------------
		function Tab:CreateSection(sectionName)
			local Section = create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Elevated,
				BorderSizePixel = 0,
				Parent = Page,
			}, { corner(10), stroke(Theme.Stroke), padding(12) })

			create("TextLabel", {
				Text = sectionName,
				Font = Theme.FontBold,
				TextSize = 13,
				TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 20),
				Parent = Section,
			})

			local Content = create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Position = UDim2.new(0, 0, 0, 26),
				BackgroundTransparency = 1,
				Parent = Section,
			})
			create("UIListLayout", {
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = Content,
			})
			-- keep Section tall enough for header + content
			Content:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() end)

			local SectionObj = setmetatable({}, { __index = {} })

			--------------------------------------------------
			function SectionObj:CreateLabel(text)
				local Lbl = create("TextLabel", {
					Text = text,
					Font = Theme.Font,
					TextSize = 13,
					TextColor3 = Theme.SubText,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 18),
					AutomaticSize = Enum.AutomaticSize.Y,
					Parent = Content,
				})
				return Lbl
			end

			--------------------------------------------------
			function SectionObj:CreateButton(config)
				config = config or {}
				local Btn = create("TextButton", {
					Text = "",
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundColor3 = Theme.Accent,
					AutoButtonColor = false,
					Parent = Content,
				}, { corner(8) })
				create("TextLabel", {
					Text = config.Name or "Button",
					Font = Theme.FontBold,
					TextSize = 13,
					TextColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Parent = Btn,
				})
				Btn.MouseEnter:Connect(function()
					tween(Btn, { BackgroundColor3 = Theme.AccentLight }, 0.15)
				end)
				Btn.MouseLeave:Connect(function()
					tween(Btn, { BackgroundColor3 = Theme.Accent }, 0.15)
				end)
				Btn.MouseButton1Click:Connect(function()
					tween(Btn, { BackgroundColor3 = Theme.AccentLight }, 0.08)
					task.delay(0.08, function()
						tween(Btn, { BackgroundColor3 = Theme.Accent }, 0.15)
					end)
					if config.Callback then
						local ok, err = pcall(config.Callback)
						if not ok then warn("[AuroraUI] Button callback error: " .. tostring(err)) end
					end
				end)
				return Btn
			end

			--------------------------------------------------
			function SectionObj:CreateToggle(config)
				config = config or {}
				local state = config.Default or false

				local Holder = create("Frame", {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					Parent = Content,
				})
				create("TextLabel", {
					Text = config.Name or "Toggle",
					Font = Theme.Font,
					TextSize = 13,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -50, 1, 0),
					Parent = Holder,
				})

				local Switch = create("Frame", {
					Size = UDim2.fromOffset(40, 22),
					Position = UDim2.new(1, -40, 0.5, -11),
					BackgroundColor3 = state and Theme.Accent or Theme.Secondary,
					Parent = Holder,
				}, { corner(11) })

				local Knob = create("Frame", {
					Size = UDim2.fromOffset(16, 16),
					Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
					BackgroundColor3 = Color3.new(1, 1, 1),
					Parent = Switch,
				}, { corner(8) })

				local ClickArea = create("TextButton", {
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Parent = Holder,
				})

				local function render()
					tween(Switch, { BackgroundColor3 = state and Theme.Accent or Theme.Secondary }, 0.15)
					tween(Knob, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, 0.15)
				end

				ClickArea.MouseButton1Click:Connect(function()
					state = not state
					render()
					if config.Callback then
						local ok, err = pcall(config.Callback, state)
						if not ok then warn("[AuroraUI] Toggle callback error: " .. tostring(err)) end
					end
				end)

				render()
				return {
					Set = function(_, value)
						state = value
						render()
					end,
					Get = function()
						return state
					end,
				}
			end

			--------------------------------------------------
			function SectionObj:CreateSlider(config)
				config = config or {}
				local min = config.Min or 0
				local max = config.Max or 100
				local default = math.clamp(config.Default or min, min, max)
				local decimals = config.Decimals or 0

				local Holder = create("Frame", {
					Size = UDim2.new(1, 0, 0, 42),
					BackgroundTransparency = 1,
					Parent = Content,
				})
				create("TextLabel", {
					Text = config.Name or "Slider",
					Font = Theme.Font,
					TextSize = 13,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -50, 0, 18),
					Parent = Holder,
				})
				local ValueLbl = create("TextLabel", {
					Text = tostring(default),
					Font = Theme.FontBold,
					TextSize = 12,
					TextColor3 = Theme.SubText,
					TextXAlignment = Enum.TextXAlignment.Right,
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 50, 0, 18),
					Position = UDim2.new(1, -50, 0, 0),
					Parent = Holder,
				})

				local Track = create("Frame", {
					Size = UDim2.new(1, 0, 0, 6),
					Position = UDim2.new(0, 0, 0, 26),
					BackgroundColor3 = Theme.Secondary,
					Parent = Holder,
				}, { corner(3) })

				local ratio = (default - min) / (max - min)
				local Fill = create("Frame", {
					Size = UDim2.new(ratio, 0, 1, 0),
					BackgroundColor3 = Theme.Accent,
					Parent = Track,
				}, { corner(3) })

				local Knob = create("Frame", {
					Size = UDim2.fromOffset(14, 14),
					Position = UDim2.new(ratio, -7, 0.5, -7),
					BackgroundColor3 = Color3.new(1, 1, 1),
					ZIndex = 2,
					Parent = Track,
				}, { corner(7) })

				local dragging = false
				local function setFromX(xPos)
					local rel = math.clamp((xPos - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
					local value = min + (max - min) * rel
					if decimals <= 0 then
						value = math.floor(value + 0.5)
					else
						local mult = 10 ^ decimals
						value = math.floor(value * mult + 0.5) / mult
					end
					Fill.Size = UDim2.new(rel, 0, 1, 0)
					Knob.Position = UDim2.new(rel, -7, 0.5, -7)
					ValueLbl.Text = tostring(value)
					if config.Callback then
						local ok, err = pcall(config.Callback, value)
						if not ok then warn("[AuroraUI] Slider callback error: " .. tostring(err)) end
					end
				end

				Track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						setFromX(input.Position.X)
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						setFromX(input.Position.X)
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)

				return {
					Set = function(_, value)
						local rel = math.clamp((value - min) / (max - min), 0, 1)
						Fill.Size = UDim2.new(rel, 0, 1, 0)
						Knob.Position = UDim2.new(rel, -7, 0.5, -7)
						ValueLbl.Text = tostring(value)
					end,
				}
			end

			--------------------------------------------------
			function SectionObj:CreateDropdown(config)
				config = config or {}
				local options = config.Options or {}
				local selected = config.Default

				local Holder = create("Frame", {
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundColor3 = Theme.Secondary,
					ClipsDescendants = true,
					Parent = Content,
				}, { corner(8) })

				local HeaderBtn = create("TextButton", {
					Text = "",
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundTransparency = 1,
					Parent = Holder,
				})
				create("TextLabel", {
					Text = config.Name or "Dropdown",
					Font = Theme.Font,
					TextSize = 13,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.5, -10, 0, 34),
					Position = UDim2.new(0, 12, 0, 0),
					Parent = HeaderBtn,
				})
				local SelectedLbl = create("TextLabel", {
					Text = selected and tostring(selected) or "Select...",
					Font = Theme.Font,
					TextSize = 12,
					TextColor3 = Theme.SubText,
					TextXAlignment = Enum.TextXAlignment.Right,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.5, -30, 0, 34),
					Position = UDim2.new(0.5, 0, 0, 0),
					Parent = HeaderBtn,
				})
				local Arrow = create("TextLabel", {
					Text = "⌄",
					Font = Theme.FontBold,
					TextSize = 14,
					TextColor3 = Theme.SubText,
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(20, 34),
					Position = UDim2.new(1, -26, 0, 0),
					Parent = HeaderBtn,
				})

				local List = create("Frame", {
					Size = UDim2.new(1, -8, 0, #options * 28),
					Position = UDim2.new(0, 4, 0, 36),
					BackgroundTransparency = 1,
					Parent = Holder,
				})
				create("UIListLayout", {
					Padding = UDim.new(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = List,
				})

				local optionButtons = {}
				local function refreshHighlight()
					for text, btn in pairs(optionButtons) do
						btn.BackgroundColor3 = (text == selected) and Theme.Accent or Theme.Elevated
					end
				end

				for _, optionName in ipairs(options) do
					local OptBtn = create("TextButton", {
						Text = "",
						Size = UDim2.new(1, 0, 0, 26),
						BackgroundColor3 = Theme.Elevated,
						AutoButtonColor = false,
						Parent = List,
					}, { corner(6) })
					create("TextLabel", {
						Text = optionName,
						Font = Theme.Font,
						TextSize = 12,
						TextColor3 = Theme.Text,
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						Parent = OptBtn,
					})
					optionButtons[optionName] = OptBtn
					OptBtn.MouseButton1Click:Connect(function()
						selected = optionName
						SelectedLbl.Text = optionName
						refreshHighlight()
						if config.Callback then
							local ok, err = pcall(config.Callback, optionName)
							if not ok then warn("[AuroraUI] Dropdown callback error: " .. tostring(err)) end
						end
					end)
				end
				refreshHighlight()

				local open = false
				HeaderBtn.MouseButton1Click:Connect(function()
					open = not open
					tween(Arrow, { Rotation = open and 180 or 0 }, 0.15)
					tween(Holder, { Size = open and UDim2.new(1, 0, 0, 36 + #options * 28 + 4) or UDim2.new(1, 0, 0, 34) }, 0.2)
				end)

				return {
					Set = function(_, value)
						selected = value
						SelectedLbl.Text = tostring(value)
						refreshHighlight()
					end,
					Get = function()
						return selected
					end,
				}
			end

			--------------------------------------------------
			function SectionObj:CreateTextbox(config)
				config = config or {}
				local Holder = create("Frame", {
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundColor3 = Theme.Secondary,
					Parent = Content,
				}, { corner(8) })

				local Box = create("TextBox", {
					PlaceholderText = config.Placeholder or "Enter text...",
					Text = config.Default or "",
					Font = Theme.Font,
					TextSize = 13,
					TextColor3 = Theme.Text,
					PlaceholderColor3 = Theme.SubText,
					ClearTextOnFocus = false,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -20, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					Parent = Holder,
				})

				Box.FocusLost:Connect(function(enterPressed)
					if config.Callback then
						local ok, err = pcall(config.Callback, Box.Text, enterPressed)
						if not ok then warn("[AuroraUI] Textbox callback error: " .. tostring(err)) end
					end
				end)

				return Box
			end

			return SectionObj
		end

		return Tab
	end

	return Window
end

return AuroraUI
