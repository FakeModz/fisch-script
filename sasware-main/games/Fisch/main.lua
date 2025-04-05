--!nolint BuiltinGlobalWrite
--!optimize 2
--!native

local PreloadConstants = {
	PlaceVersionSupport = 4000,
	BypassVersion = "V3",
}

local Success, Error = pcall(function()
	Start = os.clock()
	local NO_HOOKING = false

	local Version = 1.3
	local SubVersion = "beta"
	local Debugging = true
	local Title = "Sasware"

	local HttpService = game:GetService("HttpService")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TweenService = game:GetService("TweenService")
	local VirtualInputManager = Instance.new("VirtualInputManager") -- fak u
	local VirtualUser = game:GetService("VirtualUser")
	local StarterGui = game:GetService("StarterGui")
	local CoreGui = game:GetService("CoreGui")
	local GuiService = game:GetService("GuiService")
	local CollectionService = game:GetService("CollectionService")
	local UserInputService = game:GetService("UserInputService")
	local Lighting = game:GetService("Lighting")
	local CorePackages = game:GetService("CorePackages")
	local VeryImportantPart = Instance.new("Part") -- fake zone for tricking temperature/oxygen scripts
	-- 												  it's scuffed but works on literally any exec

	local Toasts = loadstring(
		game:HttpGet("https://raw.githubusercontent.com/centerepic/sasware-fisch/refs/heads/main/toasts.lua")
	)()

	local function InteractiveToast() : ScreenGui | ImageButton | ImageButton
		local ActiveToastObject = Instance.new("ScreenGui")
		ActiveToastObject.Parent = nil --[[ e.g. PlayerGui ]]
		ActiveToastObject.Enabled = true
		ActiveToastObject.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension
		ActiveToastObject.ResetOnSpawn = false
		ActiveToastObject.IgnoreGuiInset = false
		ActiveToastObject.Name = "InteractiveToast"
		ActiveToastObject.DisplayOrder = 0
		ActiveToastObject.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		ActiveToastObject.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
		ActiveToastObject.ClipToDeviceSafeArea = true
		local Frame_2241 = Instance.new("Frame")
		Frame_2241.Parent = ActiveToastObject
		Frame_2241.LayoutOrder = 0
		Frame_2241.BorderMode = Enum.BorderMode.Outline
		Frame_2241.Interactable = true
		Frame_2241.AnchorPoint = Vector2.new(0, 0)
		Frame_2241.BorderColor = BrickColor.new("Black")
		Frame_2241.SizeConstraint = Enum.SizeConstraint.RelativeXY
		Frame_2241.ZIndex = 1
		Frame_2241.AutomaticSize = Enum.AutomaticSize.Y
		Frame_2241.Size = UDim2.new(1, 0, 1, 0)
		Frame_2241.Draggable = false
		Frame_2241.Visible = true
		Frame_2241.ClipsDescendants = false
		Frame_2241.BorderColor3 = Color3.fromRGB(27, 42, 53)
		Frame_2241.Selectable = false
		Frame_2241.Style = Enum.FrameStyle.Custom
		Frame_2241.SelectionOrder = 0
		Frame_2241.Rotation = 0
		Frame_2241.Transparency = 1
		Frame_2241.BackgroundTransparency = 1
		Frame_2241.Position = UDim2.new(0, 0, 0, 0)
		Frame_2241.Active = false
		Frame_2241.Name = "1"
		Frame_2241.BorderSizePixel = 1
		Frame_2241.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
			local Child = Instance.new("Frame")
			Child.Parent = Frame_2241
			Child.LayoutOrder = 0
			Child.BorderMode = Enum.BorderMode.Outline
			Child.Interactable = true
			Child.AnchorPoint = Vector2.new(0.5, 0.5)
			Child.BorderColor = BrickColor.new("Black")
			Child.SizeConstraint = Enum.SizeConstraint.RelativeXY
			Child.ZIndex = 1
			Child.AutomaticSize = Enum.AutomaticSize.Y
			Child.Size = UDim2.new(0, 360, 0, 0)
			Child.Draggable = false
			Child.Visible = true
			Child.ClipsDescendants = false
			Child.BorderColor3 = Color3.fromRGB(27, 42, 53)
			Child.Selectable = false
			Child.Style = Enum.FrameStyle.Custom
			Child.SelectionOrder = 0
			Child.Rotation = 0
			Child.Transparency = 0.30000001192092896
			Child.BackgroundTransparency = 0.30000001192092896
			Child.Position = UDim2.new(0.5, 0, 0.5, 0)
			Child.Active = false
			Child.Name = "Child"
			Child.BorderSizePixel = 0
			Child.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			local ListLayout = Instance.new("UIListLayout")
			ListLayout.Parent = Child
			ListLayout.FillDirection = Enum.FillDirection.Horizontal
			ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			ListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
			ListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
			ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			ListLayout.Name = "ListLayout"
			ListLayout.Wraps = false
			ListLayout.Padding = UDim.new(0, 8)
			ListLayout.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
			ListLayout.VerticalFlex = Enum.UIFlexAlignment.None
			local Padding = Instance.new("UIPadding")
			Padding.Parent = Child
			Padding.PaddingTop = UDim.new(0, 12)
			Padding.Name = "Padding"
			Padding.PaddingBottom = UDim.new(0, 12)
			Padding.PaddingLeft = UDim.new(0, 12)
			Padding.PaddingRight = UDim.new(0, 12)
			local Content = Instance.new("Frame")
			Content.Parent = Child
			Content.LayoutOrder = 2
			Content.BorderMode = Enum.BorderMode.Outline
			Content.Interactable = true
			Content.AnchorPoint = Vector2.new(0, 0)
			Content.BorderColor = BrickColor.new("Black")
			Content.SizeConstraint = Enum.SizeConstraint.RelativeXY
			Content.ZIndex = 1
			Content.AutomaticSize = Enum.AutomaticSize.Y
			Content.Size = UDim2.new(0, 0, 0, 0)
			Content.Draggable = false
			Content.Visible = true
			Content.ClipsDescendants = false
			Content.BorderColor3 = Color3.fromRGB(27, 42, 53)
			Content.Selectable = false
			Content.Style = Enum.FrameStyle.Custom
			Content.SelectionOrder = 0
			Content.Rotation = 0
			Content.Transparency = 1
			Content.BackgroundTransparency = 1
			Content.Position = UDim2.new(0, 0, 0, 0)
			Content.Active = false
			Content.Name = "Content"
			Content.BorderSizePixel = 0
			Content.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
				local FlexItem = Instance.new("UIFlexItem")
				FlexItem.Parent = Content
				FlexItem.Name = "FlexItem"
				FlexItem.FlexMode = Enum.UIFlexMode.Fill
				FlexItem.ShrinkRatio = 0
				FlexItem.GrowRatio = 0
				FlexItem.ItemLineAlignment = Enum.ItemLineAlignment.Center
				local ListLayout = Instance.new("UIListLayout")
				ListLayout.Parent = Content
				ListLayout.FillDirection = Enum.FillDirection.Vertical
				ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
				ListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
				ListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
				ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
				ListLayout.Name = "ListLayout"
				ListLayout.Wraps = false
				ListLayout.Padding = UDim.new(0, 2)
				ListLayout.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
				ListLayout.VerticalFlex = Enum.UIFlexAlignment.None
				local Actions = Instance.new("Frame")
				Actions.Parent = Content
				Actions.LayoutOrder = 3
				Actions.BorderMode = Enum.BorderMode.Outline
				Actions.Interactable = true
				Actions.AnchorPoint = Vector2.new(0, 0)
				Actions.BorderColor = BrickColor.new("Black")
				Actions.SizeConstraint = Enum.SizeConstraint.RelativeXY
				Actions.ZIndex = 1
				Actions.AutomaticSize = Enum.AutomaticSize.Y
				Actions.Size = UDim2.new(1, 0, 0, 0)
				Actions.Draggable = false
				Actions.Visible = true
				Actions.ClipsDescendants = false
				Actions.BorderColor3 = Color3.fromRGB(27, 42, 53)
				Actions.Selectable = false
				Actions.Style = Enum.FrameStyle.Custom
				Actions.SelectionOrder = 0
				Actions.Rotation = 0
				Actions.Transparency = 1
				Actions.BackgroundTransparency = 1
				Actions.Position = UDim2.new(0, 0, 0, 0)
				Actions.Active = false
				Actions.Name = "Actions"
				Actions.BorderSizePixel = 0
				Actions.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
				local ListLayout = Instance.new("UIListLayout")
				ListLayout.Parent = Actions
				ListLayout.FillDirection = Enum.FillDirection.Horizontal
				ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
				ListLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
				ListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
				ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
				ListLayout.Name = "ListLayout"
				ListLayout.Wraps = false
				ListLayout.Padding = UDim.new(0, 8)
				ListLayout.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
				ListLayout.VerticalFlex = Enum.UIFlexAlignment.None
				local ToastButton1 = Instance.new("ImageButton")
				ToastButton1.Parent = Actions
				ToastButton1.LayoutOrder = 1
				ToastButton1.Active = true
				ToastButton1.Interactable = true
				ToastButton1.SizeConstraint = Enum.SizeConstraint.RelativeXY
				ToastButton1.ZIndex = 1
				ToastButton1.BorderSizePixel = 0
				ToastButton1.SliceCenter = Rect.new(0, 0, 0, 0)
				ToastButton1.Draggable = false
				ToastButton1.ScaleType = Enum.ScaleType.Stretch
				ToastButton1.Modal = false
				ToastButton1.AutoButtonColor = false
				ToastButton1.Transparency = 1
				ToastButton1.SelectionOrder = 0
				ToastButton1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				ToastButton1.ImageTransparency = 0
				ToastButton1.Selectable = true
				ToastButton1.AnchorPoint = Vector2.new(0, 0)
				ToastButton1.Image = ""
				ToastButton1.TileSize = UDim2.new(1, 0, 1, 0)
				ToastButton1.ImageRectSize = Vector2.new(0, 0)
				ToastButton1.Selected = false
				ToastButton1.AutomaticSize = Enum.AutomaticSize.X
				ToastButton1.Size = UDim2.new(1, 0, 0, 36)
				ToastButton1.Visible = true
				ToastButton1.HoverImage = ""
				ToastButton1.Style = Enum.ButtonStyle.Custom
				ToastButton1.ClipsDescendants = true
				ToastButton1.BorderColor3 = Color3.fromRGB(27, 42, 53)
				ToastButton1.BorderMode = Enum.BorderMode.Outline
				ToastButton1.ImageColor3 = Color3.fromRGB(255, 255, 255)
				ToastButton1.PressedImage = ""
				ToastButton1.Rotation = 0
				ToastButton1.ImageRectOffset = Vector2.new(0, 0)
				ToastButton1.BackgroundTransparency = 1
				ToastButton1.Position = UDim2.new(0, 0, 0, 0)
				ToastButton1.SliceScale = 1
				ToastButton1.ResampleMode = Enum.ResamplerMode.Default
				ToastButton1.BorderColor = BrickColor.new("Black")
				ToastButton1.Name = "ToastButton1"
					local Stroke = Instance.new("UIStroke")
					Stroke.Parent = ToastButton1
					Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
					Stroke.LineJoinMode = Enum.LineJoinMode.Round
					Stroke.Name = "Stroke"
					Stroke.Color = Color3.fromRGB(255, 255, 255)
					Stroke.Transparency = 0
					Stroke.Thickness = 1
					Stroke.Enabled = true
					local Text = Instance.new("TextLabel")
					Text.Parent = ToastButton1
					Text.LayoutOrder = 2
					Text.FontSize = Enum.FontSize.Size24
					Text.TextDirection = Enum.TextDirection.Auto
					Text.Active = false
					Text.Interactable = true
					Text.TextStrokeTransparency = 1
					Text.TextTruncate = Enum.TextTruncate.AtEnd
					Text.SizeConstraint = Enum.SizeConstraint.RelativeXY
					Text.ZIndex = 1
					Text.BorderSizePixel = 0
					Text.Draggable = false
					Text.RichText = false
					Text.SelectionOrder = 0
					Text.TextYAlignment = Enum.TextYAlignment.Center
					Text.TextScaled = false
					Text.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
					Text.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
					Text.BorderMode = Enum.BorderMode.Outline
					Text.Selectable = false
					Text.OpenTypeFeatures = ""
					Text.AnchorPoint = Vector2.new(0, 0)
					Text.BorderColor = BrickColor.new("Black")
					Text.Visible = true
					Text.TextXAlignment = Enum.TextXAlignment.Center
					Text.AutomaticSize = Enum.AutomaticSize.X
					Text.Size = UDim2.new(1, 0, 1, 0)
					Text.TextWrapped = true
					Text.TextWrap = true
					Text.TextTransparency = 0
					Text.ClipsDescendants = false
					Text.BorderColor3 = Color3.fromRGB(27, 42, 53)
					Text.Text = "Exit"
					Text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
					Text.LineHeight = 1
					Text.Rotation = 0
					Text.Font = Enum.Font.BuilderSansBold
					Text.BackgroundTransparency = 1
					Text.Position = UDim2.new(0, 0, 0, 0)
					Text.TextSize = 20
					Text.MaxVisibleGraphemes = -1
					Text.TextColor3 = Color3.fromRGB(255, 255, 255)
					Text.Name = "Text"
					local CornerRadius = Instance.new("UICorner")
					CornerRadius.Parent = ToastButton1
					CornerRadius.Name = "CornerRadius"
					CornerRadius.CornerRadius = UDim.new(0, 8)
					local ListLayout = Instance.new("UIListLayout")
					ListLayout.Parent = ToastButton1
					ListLayout.FillDirection = Enum.FillDirection.Horizontal
					ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
					ListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
					ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
					ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
					ListLayout.Name = "ListLayout"
					ListLayout.Wraps = false
					ListLayout.Padding = UDim.new(0, 4)
					ListLayout.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
					ListLayout.VerticalFlex = Enum.UIFlexAlignment.None
				local ToastButton2 = Instance.new("ImageButton")
				ToastButton2.Parent = Actions
				ToastButton2.LayoutOrder = 2
				ToastButton2.Active = true
				ToastButton2.Interactable = true
				ToastButton2.SizeConstraint = Enum.SizeConstraint.RelativeXY
				ToastButton2.ZIndex = 1
				ToastButton2.BorderSizePixel = 0
				ToastButton2.SliceCenter = Rect.new(0, 0, 0, 0)
				ToastButton2.Draggable = false
				ToastButton2.ScaleType = Enum.ScaleType.Stretch
				ToastButton2.Modal = false
				ToastButton2.AutoButtonColor = false
				ToastButton2.Transparency = 0
				ToastButton2.SelectionOrder = 0
				ToastButton2.BackgroundColor3 = Color3.fromRGB(0, 179, 108)
				ToastButton2.ImageTransparency = 0
				ToastButton2.Selectable = true
				ToastButton2.AnchorPoint = Vector2.new(0, 0)
				ToastButton2.Image = ""
				ToastButton2.TileSize = UDim2.new(1, 0, 1, 0)
				ToastButton2.ImageRectSize = Vector2.new(0, 0)
				ToastButton2.Selected = false
				ToastButton2.AutomaticSize = Enum.AutomaticSize.X
				ToastButton2.Size = UDim2.new(1, 0, 0, 36)
				ToastButton2.Visible = true
				ToastButton2.HoverImage = ""
				ToastButton2.Style = Enum.ButtonStyle.Custom
				ToastButton2.ClipsDescendants = true
				ToastButton2.BorderColor3 = Color3.fromRGB(27, 42, 53)
				ToastButton2.BorderMode = Enum.BorderMode.Outline
				ToastButton2.ImageColor3 = Color3.fromRGB(255, 255, 255)
				ToastButton2.PressedImage = ""
				ToastButton2.Rotation = 0
				ToastButton2.ImageRectOffset = Vector2.new(0, 0)
				ToastButton2.BackgroundTransparency = 0
				ToastButton2.Position = UDim2.new(0, 0, 0, 0)
				ToastButton2.SliceScale = 1
				ToastButton2.ResampleMode = Enum.ResamplerMode.Default
				ToastButton2.BorderColor = BrickColor.new("Black")
				ToastButton2.Name = "ToastButton2"
					local Stroke = Instance.new("UIStroke")
					Stroke.Parent = ToastButton2
					Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
					Stroke.LineJoinMode = Enum.LineJoinMode.Round
					Stroke.Name = "Stroke"
					Stroke.Color = Color3.fromRGB(0, 0, 0)
					Stroke.Transparency = 1
					Stroke.Thickness = 1
					Stroke.Enabled = true
					local Text = Instance.new("TextLabel")
					Text.Parent = ToastButton2
					Text.LayoutOrder = 2
					Text.FontSize = Enum.FontSize.Size24
					Text.TextDirection = Enum.TextDirection.Auto
					Text.Active = false
					Text.Interactable = true
					Text.TextStrokeTransparency = 1
					Text.TextTruncate = Enum.TextTruncate.AtEnd
					Text.SizeConstraint = Enum.SizeConstraint.RelativeXY
					Text.ZIndex = 1
					Text.BorderSizePixel = 0
					Text.Draggable = false
					Text.RichText = false
					Text.SelectionOrder = 0
					Text.TextYAlignment = Enum.TextYAlignment.Center
					Text.TextScaled = false
					Text.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
					Text.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
					Text.BorderMode = Enum.BorderMode.Outline
					Text.Selectable = false
					Text.OpenTypeFeatures = ""
					Text.AnchorPoint = Vector2.new(0, 0)
					Text.BorderColor = BrickColor.new("Black")
					Text.Visible = true
					Text.TextXAlignment = Enum.TextXAlignment.Center
					Text.AutomaticSize = Enum.AutomaticSize.X
					Text.Size = UDim2.new(1, 0, 1, 0)
					Text.TextWrapped = true
					Text.TextWrap = true
					Text.TextTransparency = 0
					Text.ClipsDescendants = false
					Text.BorderColor3 = Color3.fromRGB(27, 42, 53)
					Text.Text = "Continue"
					Text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
					Text.LineHeight = 1
					Text.Rotation = 0
					Text.Font = Enum.Font.BuilderSansBold
					Text.BackgroundTransparency = 1
					Text.Position = UDim2.new(0, 0, 0, 0)
					Text.TextSize = 20
					Text.MaxVisibleGraphemes = -1
					Text.TextColor3 = Color3.fromRGB(255, 255, 255)
					Text.Name = "Text"
					local CornerRadius = Instance.new("UICorner")
					CornerRadius.Parent = ToastButton2
					CornerRadius.Name = "CornerRadius"
					CornerRadius.CornerRadius = UDim.new(0, 8)
					local ListLayout = Instance.new("UIListLayout")
					ListLayout.Parent = ToastButton2
					ListLayout.FillDirection = Enum.FillDirection.Horizontal
					ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
					ListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
					ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
					ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
					ListLayout.Name = "ListLayout"
					ListLayout.Wraps = false
					ListLayout.Padding = UDim.new(0, 4)
					ListLayout.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
					ListLayout.VerticalFlex = Enum.UIFlexAlignment.None
				local Padding = Instance.new("UIPadding")
				Padding.Parent = Actions
				Padding.PaddingTop = UDim.new(0, 8)
				Padding.Name = "Padding"
				Padding.PaddingBottom = UDim.new(0, 0)
				Padding.PaddingLeft = UDim.new(0, 0)
				Padding.PaddingRight = UDim.new(0, 0)
				local Body = Instance.new("TextLabel")
				Body.Parent = Content
				Body.LayoutOrder = 2
				Body.FontSize = Enum.FontSize.Size18
				Body.TextDirection = Enum.TextDirection.Auto
				Body.Active = false
				Body.Interactable = true
				Body.TextStrokeTransparency = 1
				Body.TextTruncate = Enum.TextTruncate.None
				Body.SizeConstraint = Enum.SizeConstraint.RelativeXY
				Body.ZIndex = 1
				Body.BorderSizePixel = 0
				Body.Draggable = false
				Body.RichText = false
				Body.SelectionOrder = 0
				Body.TextYAlignment = Enum.TextYAlignment.Center
				Body.TextScaled = false
				Body.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
				Body.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
				Body.BorderMode = Enum.BorderMode.Outline
				Body.Selectable = false
				Body.OpenTypeFeatures = ""
				Body.AnchorPoint = Vector2.new(0, 0)
				Body.BorderColor = BrickColor.new("Black")
				Body.Visible = true
				Body.TextXAlignment = Enum.TextXAlignment.Left
				Body.AutomaticSize = Enum.AutomaticSize.Y
				Body.Size = UDim2.new(1, 0, 0, 0)
				Body.TextWrapped = true
				Body.TextWrap = true
				Body.TextTransparency = 0
				Body.ClipsDescendants = false
				Body.BorderColor3 = Color3.fromRGB(27, 42, 53)
				Body.Text = "SasGuard is unable to load due to the current PlaceVersion being higher than the supported version. This means the anti-cheat will be running. Do you want to continue?"
				Body.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
				Body.LineHeight = 1.031999945640564
				Body.Rotation = 0
				Body.Font = Enum.Font.BuilderSans
				Body.BackgroundTransparency = 1
				Body.Position = UDim2.new(0, 0, 0, 0)
				Body.TextSize = 15
				Body.MaxVisibleGraphemes = -1
				Body.TextColor3 = Color3.fromRGB(189, 190, 190)
				Body.Name = "Body"
				local Padding = Instance.new("UIPadding")
				Padding.Parent = Body
				Padding.PaddingTop = UDim.new(0, 0)
				Padding.Name = "Padding"
				Padding.PaddingBottom = UDim.new(0, 0)
				Padding.PaddingLeft = UDim.new(0, 0)
				Padding.PaddingRight = UDim.new(0, 0)
				local Header = Instance.new("TextLabel")
				Header.Parent = Content
				Header.LayoutOrder = 1
				Header.FontSize = Enum.FontSize.Size32
				Header.TextDirection = Enum.TextDirection.Auto
				Header.Active = false
				Header.Interactable = true
				Header.TextStrokeTransparency = 1
				Header.TextTruncate = Enum.TextTruncate.AtEnd
				Header.SizeConstraint = Enum.SizeConstraint.RelativeXY
				Header.ZIndex = 1
				Header.BorderSizePixel = 0
				Header.Draggable = false
				Header.RichText = false
				Header.SelectionOrder = 0
				Header.TextYAlignment = Enum.TextYAlignment.Center
				Header.TextScaled = false
				Header.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
				Header.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
				Header.BorderMode = Enum.BorderMode.Outline
				Header.Selectable = false
				Header.OpenTypeFeatures = ""
				Header.AnchorPoint = Vector2.new(0, 0)
				Header.BorderColor = BrickColor.new("Black")
				Header.Visible = true
				Header.TextXAlignment = Enum.TextXAlignment.Center
				Header.AutomaticSize = Enum.AutomaticSize.Y
				Header.Size = UDim2.new(1, 0, 0, 0)
				Header.TextWrapped = false
				Header.TextWrap = false
				Header.TextTransparency = 0
				Header.ClipsDescendants = false
				Header.BorderColor3 = Color3.fromRGB(27, 42, 53)
				Header.Text = "Warning"
				Header.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
				Header.LineHeight = 1
				Header.Rotation = 0
				Header.Font = Enum.Font.BuilderSansBold
				Header.BackgroundTransparency = 1
				Header.Position = UDim2.new(0, 0, 0, 0)
				Header.TextSize = 30
				Header.MaxVisibleGraphemes = -1
				Header.TextColor3 = Color3.fromRGB(255, 255, 255)
				Header.Name = "Header"
				local Padding = Instance.new("UIPadding")
				Padding.Parent = Header
				Padding.PaddingTop = UDim.new(0, 0)
				Padding.Name = "Padding"
				Padding.PaddingBottom = UDim.new(0, 5)
				Padding.PaddingLeft = UDim.new(0, 0)
				Padding.PaddingRight = UDim.new(0, 0)
			local CornerRadius = Instance.new("UICorner")
			CornerRadius.Parent = Child
			CornerRadius.Name = "CornerRadius"
			CornerRadius.CornerRadius = UDim.new(0, 8)
		return ActiveToastObject, ToastButton1, ToastButton2
	end

	do
		VeryImportantPart.Name = "SpawnBox"
		local prio = Instance.new("IntValue", VeryImportantPart)
		prio.Name = "priority"
		prio.Value = 10
		local name = Instance.new("StringValue", VeryImportantPart)
		name.Name = "zonename"
		name.Value = "???"
	end

	local Camera = workspace.CurrentCamera

	local ZoneFishOrigin = nil

	local PreAutoloadConfig = true

	local State = {
		GettingMeteor = false,
		OwnedBoats = {},
		LastToolReset = os.clock(),
		ToolResetCooldown = 5,
	}

	local GlobalStorage = {
		PeakZones = {
			["Overgrowth Caves"] = true,
			["Frigid Cavern"] = true,
			["Cryogenic Canal"] = true,
			["Glacial Grotto"] = true,
		},
	}

	-- Game instance paths
	local LocalPlayer = Players.LocalPlayer
	local Unloaded = false
	local CurrentTool: Tool?

	-- Test if hooking is enabled
	if not (hookfunction and hookmetamethod) then
		hookfunction = function(...) end
		hookmetamethod = function(...) end
		NO_HOOKING = true
	end

	if not getconnections then
		getconnections = function(...) end
	end

	if not setthreadidentity then
		setthreadidentity = function(...) end -- i hate you solara
	end

	if getgenv().sasware_fisch_unload then
		pcall(getgenv().sasware_fisch_unload)
	end

	local function Unimplemented()
		return warn("This feature is not implemented yet")
	end

	local function dbgprint(...)
		if Debugging then
			print("[Debugging]", ...)
		end
	end

	local function dbgwarn(...)
		if Debugging then
			warn("[Debugging]", ...)
		end
	end

	--[[
		Recursively waits for instances to exist from a root instance.
	]]
	--
	local function WaitForTable(Root: Instance, InstancePath: { string }, Timeout: number?)
		local Instance = Root
		for i, v in pairs(InstancePath) do
			Instance = Instance:WaitForChild(v, Timeout)
		end
		return Instance
	end

	local function GetFirstAncestorOfClass(Object: Instance, Class: string)
		local Ancestor = Object.Parent
		local Depth = 0
		while Ancestor do
			Depth += 1

			if Depth > 255 then
				warn("Aborted GetFirstAncestorOfClass: Too deep")
				return nil
			end

			if Ancestor:IsA(Class) then
				return Ancestor
			end

			Ancestor = Ancestor.Parent
		end
		return nil
	end

	local function LockPersistent(Object: Model)
		assert(Object:IsA("Model"), "Object must be a model")
		if Object.ModelStreamingMode ~= Enum.ModelStreamingMode.Persistent then
			CollectionService:AddTag(Object, "ForcePersistent")
			Object:SetAttribute("OldStreamingMode", Object.ModelStreamingMode.Name)
			Object.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		end
	end

	local function EnsureStream(Root, InstancePath, Position, Timeout)
		LocalPlayer:RequestStreamAroundAsync(Position, Timeout)

		local Target = WaitForTable(Root, InstancePath, Timeout)

		local Model = GetFirstAncestorOfClass(Target, "Model")

		if Model then
			LockPersistent(Model)
		end

		return Target
	end

	local function EnsureInstance(Instance: Instance?): boolean
		return (Instance and Instance:IsDescendantOf(game))
	end

	local function _round(num, numDecimalPlaces): number
		local mult = 10 ^ (numDecimalPlaces or 0)
		return math.floor(num * mult + 0.5) / mult
	end

	local Configuration = {
		CheckSafeRange = 50,
	}

	local Remotes = {
		ReelFinished = ReplicatedStorage.events:WaitForChild("reelfinished "),
		SellAll = ReplicatedStorage.events:WaitForChild("SellAll"),
		Power = EnsureStream(
			workspace,
			{ "world", "npcs", "Merlin", "Merlin", "power" },
			Vector3.new(-930, 226, -993),
			5
		),
		Luck = EnsureStream(
			workspace,
			{ "world", "npcs", "Merlin", "Merlin", "luck" },
			Vector3.new(-930, 226, -993),
			5
		),
	}

	-- Check PlaceVersion
	if game.PlaceVersion > PreloadConstants.PlaceVersionSupport then

		local PromptToast, Button1, Button2 = InteractiveToast()
		PromptToast.Parent = CoreGui

		local Con1, Con2, Done

		Con1 = Button1.MouseButton1Click:Connect(function()
			PromptToast:Destroy()
			LocalPlayer:Kick("Aborted due to PlaceVersion being higher than supported version.")
			game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end)

		Con2 = Button2.MouseButton1Click:Connect(function()
			PromptToast:Destroy()
			Con1:Disconnect()
			Con2:Disconnect()
			Done = true
		end)

		repeat RunService.Heartbeat:Wait() until Done == true
	end

	local Interface = {
		FishRadar = ReplicatedStorage.resources.items.items["Fish Radar"]["Fish Radar"],
		TeleportSpots = WaitForTable(workspace, { "world", "spawns", "TpSpots" }),
		Inventory = WaitForTable(LocalPlayer.PlayerGui, { "hud", "safezone", "backpack" }),
		MeteorItems = workspace:WaitForChild("active"):WaitForChild("meteorItems"),
		PlayerData = workspace:WaitForChild("PlayerStats"):WaitForChild(LocalPlayer.Name):WaitForChild("T"):GetChildren()[1],
		NPCs = workspace:WaitForChild("world"):WaitForChild("npcs"),
		BoatModels = WaitForTable(ReplicatedStorage, { "resources", "replicated", "instances", "vessels" }),
		Active = workspace:WaitForChild("active"),
		ActiveBoats = workspace:WaitForChild("active"):WaitForChild("boats"),
	}

	local Collection = {}
	local OnUnload = Instance.new("BindableEvent")
	local function Collect(Item: RBXScriptConnection | thread)
		table.insert(Collection, Item)
	end

	local Repository = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/refs/heads/main/"
	local Library = loadstring(game:HttpGet(Repository .. "Library.lua"))()
	local ThemeManager = loadstring(game:HttpGet(Repository .. "addons/ThemeManager.lua"))()
	local SaveManager = loadstring(game:HttpGet(Repository .. "addons/SaveManager.lua"))()
	local VelocityFly =
		loadstring(game:HttpGet("https://raw.githubusercontent.com/centerepic/VelocityFly/main/VelocityFly.lua"))()

	local UI = {
		Library = Library,
		Options = getgenv().Options,
		Toggles = getgenv().Toggles,
	}

	local function GetToggleValue(Name: string): boolean?
		local Toggle = UI.Toggles[Name]

		if not Toggle then
			dbgwarn("Toggle not found:", Name)
			return nil
		else
			return Toggle.Value
		end
	end

	local function GetOptionValue(Name: string)
		local Option = UI.Options[Name]

		if not Option then
			dbgwarn("Option not found:", Name)
			return nil
		else
			return Option.Value
		end
	end

	local Utils = {}
	do
		function Utils.CountInstances(Parent: Instance, Name: string): number
			local Count = 0
			for _, Instance in next, Parent:GetChildren() do
				if Instance.Name == Name then
					Count += 1
				end
			end
			return Count
		end

		function Utils:BreakVelocity()
			if LocalPlayer.Character then
				task.spawn(function()
					for i = 20, 1, -1 do
						RunService.Heartbeat:Wait()
						for _, Part in next, LocalPlayer.Character:GetDescendants() do
							if Part:IsA("BasePart") then
								Part.Velocity = Vector3.new(0, 0, 0)
								Part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
							end
						end
					end
				end)
			end
		end

		function Utils.ToggleLocationCC(Value: boolean)
			local LocationCC = Lighting:FindFirstChild("location")

			if LocationCC then
				LocationCC.Enabled = Value
			end
		end

		function Utils.GameNotify(Message: string)
			ReplicatedStorage.events.anno_localthoughtbig:Fire(Message, nil, nil, nil, "Exotic")
		end

		function Utils.GetCharacters()
			local Characters = {}

			for _, Player: Player in next, Players:GetPlayers() do
				if Player.Character then
					table.insert(Characters, Player.Character)
				end
			end

			return Characters
		end

		function Utils.Net(Type: string, Index: string)
			return ReplicatedStorage.packages.Net:FindFirstChild(Type .. "/" .. Index)
		end

		function Utils.Character()
			return LocalPlayer.Character
		end

		function Utils.Humanoid(): Humanoid?
			local Character = Utils.Character()

			if Character then
				return Character:FindFirstChildOfClass("Humanoid")
			end

			return nil
		end

		function Utils.CastTo(A: Vector3, B: Vector3, Params: RaycastParams): RaycastResult?
			local Direction = (B - A)
			return workspace:Raycast(A, Direction, Params)
		end

		--[[
		Checks if there are any characters within range of a position.
		It raycasts from the position to the character's head, alongside checking a sphere of half the range around the position.
	]]
		--
		function Utils.SafePosition(Position: Vector3, Range: number)
			local Characters = Utils.GetCharacters()
			local RayParams = RaycastParams.new()
			RayParams.FilterType = Enum.RaycastFilterType.Exclude
			RayParams.RespectCanCollide = true
			RayParams.FilterDescendantsInstances = Characters

			for _, Character in next, Characters do
				local Head = Character:FindFirstChild("Head")
				local Pivot = Character:GetPivot()

				if Head then
					local Raycast = Utils.CastTo(Position, Head.Position, RayParams)

					if Raycast then
						return false
					end
				end

				if Pivot then
					local Distance = (Position - Pivot.Position).Magnitude * 0.5

					if Distance <= Range then
						return false
					end
				end
			end

			return true
		end

		function Utils.TP(Target: Vector3 | CFrame | PVInstance, CheckSafe: boolean?): boolean
			local Pivot: CFrame

			if typeof(Target) == "CFrame" then
				Pivot = Target
			elseif typeof(Target) == "Vector3" then
				Pivot = CFrame.new(Target)
			elseif typeof(Target) == "PVInstance" then
				Pivot = Target:GetPivot()
			elseif typeof(Target) == "BasePart" then
				Pivot = Target:GetPivot()
			elseif typeof(Target) == "Model" then
				Pivot = Target:GetPivot()
			end

			if CheckSafe then
				if not Utils.SafePosition(Pivot.Position, Configuration.CheckSafeRange) then
					return false
				end
			end

			local Character = Utils.Character()
			if Character then
				Character:PivotTo(Pivot)
				return true
			end

			return false
		end

		function Utils.EliminateVelocity(Model: Model): nil
			for _, Part in next, Model:GetDescendants() do
				if Part:IsA("BasePart") then
					Part.Velocity = Vector3.new(0, 0, 0)
					Part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				end
			end
			return nil
		end

		function Utils.GenericToast(Duration: number, Message: string, CustomTitle: string?)
			local MessageTitle = CustomTitle or Title

			Toasts.CreateToast(
				HttpService:GenerateGUID(false),
				MessageTitle,
				Message,
				"rbxassetid://18259985431",
				Duration
			)
		end

		function Utils.GetUsernameMatch(PartialName: string): Player?
			local BestMatch = nil
			local BestMatchLength = 0

			for _, Player in next, Players:GetPlayers() do
				if string.find(Player.Name:lower(), PartialName:lower()) then
					if #Player.Name > BestMatchLength then
						BestMatch = Player
						BestMatchLength = #Player.Name
					end
				end
			end

			return BestMatch
		end

		function Utils.CharacterChildAdded(Child: Instance)
			if Child:IsA("Tool") then
				CurrentTool = Child

				if GetToggleValue("ServerStresser") then
					local FishModel = Child:WaitForChild("Fish", 1)

					if FishModel then
						FishModel:Destroy()
					end

					task.delay(0.5, function()
						for i, v in next, Child:GetDescendants() do
							if v:IsA("BasePart") then
								v.Anchored = true
							end
						end
					end)
				end
			elseif Child:IsA("Humanoid") then
				Collect(Child.StateChanged:Connect(function()
					if GetToggleValue("ZoneFish") then
						for _, State: Enum.HumanoidStateType in next, Enum.HumanoidStateType:GetEnumItems() do
							if State ~= Enum.HumanoidStateType.Running then
								Child:SetStateEnabled(State, false)
							end
						end
						Child:ChangeState(Enum.HumanoidStateType.Running)
					end
				end))
				Collect(Child.Died:Once(function()
					UI.Toggles.ZoneFish:SetValue(false)
				end))
			end
		end

		function Utils.CharacterChildRemoved(Child: Instance)
			if Child:IsA("Tool") then
				CurrentTool = nil
			end
		end

		function Utils.CharacterAdded(Character: Model)
			for _, Child in next, Character:GetChildren() do
				Utils.CharacterChildAdded(Child)
			end

			Collect(Character.ChildAdded:Connect(Utils.CharacterChildAdded))
			Collect(Character.ChildRemoved:Connect(Utils.CharacterChildRemoved))

			local Zone = Character:WaitForChild("zone", 1) :: ObjectValue

			if Zone then
				Collect(RunService.RenderStepped:Connect(function()
					if GetToggleValue("DisablePeakEffects") then
						Zone.Value = VeryImportantPart
					end
				end))
			end
		end

		function Utils.Capitalize(String: string): string
			return string.upper(string.sub(String, 1, 1)) .. string.sub(String, 2)
		end

		function Utils.GetNPC(Type: string, Single: boolean?): Model | { Model } | nil
			local function GetNPCType(NPC: Model) -- i hate this function so much
				local NPCType = "Unknown"

				if NPC:FindFirstChild("shipwright") then
					NPCType = "Shipwright"
				elseif NPC:FindFirstChild("merchant") then
					NPCType = "Merchant"
				elseif NPC:FindFirstChild("angler") then
					NPCType = "Angler"
				end

				return NPCType
			end

			local NPCs = Interface.NPCs:GetChildren()
			local Results = {}

			for _, Character in next, NPCs do
				local NPCType = GetNPCType(Character)

				if NPCType == Type then
					if Single then
						return Character
					else
						table.insert(Results, Character)
					end
				end
			end

			return nil
		end

		function Utils.BoatsChanged()
			local Boats = Interface.PlayerData.Boats:GetChildren()

			State.OwnedBoats = {}

			for _, Boat in next, Boats do
				table.insert(State.OwnedBoats, Boat.Name)
			end

			UI.Options.BoatSpawnDropdown:SetValues(State.OwnedBoats)
		end

		function Utils.UpdateShopDropdown()
			local Items = workspace:WaitForChild("world"):WaitForChild("interactables"):GetChildren()

			local Values = {}

			for _, Item in next, Items do
				table.insert(Values, Item.Name)
			end

			UI.Options.RemoteShopDropdown:SetValues(Values)
		end
	end

	local TeleportLocations = {}
	local TeleportLocations_DropDownValues = {}

	for _, Location in next, Interface.TeleportSpots:GetChildren() do
		TeleportLocations[Utils.Capitalize(Location.Name)] = Location.Position + Vector3.new(0, 6, 0)
	end

	for Name, Position in next, TeleportLocations do
		table.insert(TeleportLocations_DropDownValues, Name)
	end

	table.sort(TeleportLocations_DropDownValues)

	local FishingZones = {}

	for _, Zone in next, workspace:WaitForChild("zones"):WaitForChild("fishing"):GetChildren() do
		if not FishingZones[Zone.Name] then
			FishingZones[Zone.Name] = Zone
		end
	end

	local FishingZones_DropDownValues = {}

	for Name, Zone in next, FishingZones do
		table.insert(FishingZones_DropDownValues, Name)
	end

	local function ResetTool()
		if CurrentTool then
			local ToolCache = LocalPlayer.Character:FindFirstChildOfClass("Tool")
			if CurrentTool then
				if State.LastToolReset + State.ToolResetCooldown < os.clock() then
					State.LastToolReset = os.clock()
					LocalPlayer.Character.Humanoid:UnequipTools()
					task.wait()
					ToolCache.Parent = LocalPlayer.Character
				end
			end
		end
	end

	local function Unload()
		Toasts.CancelAllToasts()

		RunService:Set3dRenderingEnabled(true)

		Library:Unload()
		VelocityFly:Toggle(false)

		for _, Item in ipairs(Collection) do
			if typeof(Item) == "RBXScriptConnection" then
				Item:Disconnect()
			end

			if type(Item) == "thread" then
				coroutine.close(Item)
			end
		end

		local Inventory = WaitForTable(LocalPlayer.PlayerGui, { "hud", "safezone", "backpack" })
		if Inventory then
			Inventory.Visible = true
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end

		Utils.ToggleLocationCC(true)

		if GetToggleValue("ZoneFish") then
			task.defer(function()
				LocalPlayer.Character.Humanoid:UnequipTools()
				for _ = 1, 10 do
					task.wait()
					Utils.TP(ZoneFishOrigin.Position)
				end
				ZoneFishOrigin = nil
			end)
		end

		OnUnload:Fire()

		Toasts = nil
		Library = nil
		ThemeManager = nil
		SaveManager = nil
		VelocityFly = nil

		getgenv().Toggles = nil
		getgenv().Options = nil
		getgenv().sasware_fisch_unload = nil

		Utils.GenericToast(3, "Unloaded successfully!")

		Unloaded = true
	end

	getgenv().sasware_fisch_unload = Unload

	-- Load bypasses

	do
		if game.PlaceVersion >= 3744 and (game.PlaceVersion <= PreloadConstants.PlaceVersionSupport) then
			local URL = "https://raw.githubusercontent.com/centerepic/sasware-fisch/refs/heads/main/bypasses/"
				.. PreloadConstants.BypassVersion
				.. ".luau"

			local Success, Error = pcall(function()
				return loadstring(game:HttpGet(URL))()
			end)

			if not Success then
				LocalPlayer:Kick("Failed to load SasGuard! " .. Error)
			end
		end
	end

	-- Initalize UI (finally)

	local Window = Library:CreateWindow({
		Title = Title .. " | Fisch | " .. tostring(Version) .. SubVersion,
		Center = true,
		AutoShow = true,
	})

	local Tabs = {
		Main = Window:AddTab("Main"),
		Automation = Window:AddTab("Automation"),
		Visuals = Window:AddTab("Visuals"),
		Vulnerabilities = Window:AddTab("Vulnerabilities"),
		Settings = Window:AddTab("Settings"),
	}

	-- Main

	local FishingTabBox = Tabs.Main:AddLeftTabbox("Fishing")
	local CastingGroup = FishingTabBox:AddTab("Casting")
	local ReelingGroup = FishingTabBox:AddTab("Reeling")
	local OtherGroup = FishingTabBox:AddTab("Other")

	CastingGroup:AddToggle("AutoCast", {
		Text = "Auto-cast",
		Default = false,
		Tooltip = "Automatically casts for you.",
	})

	if not NO_HOOKING then
		CastingGroup:AddToggle("PerfectCast", {
			Text = "Always perfect [Server]",
			Default = false,
			Tooltip = "Makes your casts always perfect.",
		})
	end

	CastingGroup:AddToggle("InstantBob", {
		Text = "Instant bob [Blatant]",
		Default = false,
		Tooltip = "Forces the bobber to fall instantly.",
	})

	ReelingGroup:AddToggle("AutoReel", {
		Text = "Auto-reel [Legit]",
		Default = false,
		Tooltip = "Automatically plays the reel minigame.",
		Callback = function(Value: boolean)
			if Value then
				UI.Toggles.InstantReel:SetValue(false)
			end
		end,
	})

	ReelingGroup:AddToggle("InstantReel", {
		Text = "Insta-reel [Blatant]",
		Default = false,
		Tooltip = "Automatically reels in fish instantly.",
		Callback = function(Value: boolean)
			if Value then
				UI.Toggles.AutoReel:SetValue(false)
			end
		end,
	})

	ReelingGroup:AddToggle("PerfectReel", {
		Text = "Always perfect",
		Default = false,
		Tooltip = "Reels in fish perfectly!",
	})

	OtherGroup:AddToggle("AutoShake", {
		Text = "Auto shake",
		Default = false,
		Tooltip = "Automatically shakes the rod.",
	})

	OtherGroup:AddToggle("CenterShake", {
		Text = "Center-shake [Improves AutoShake]",
		Default = false,
		Tooltip = "Centers the shake UI.",
	})

	local TeleportsGroupBox = Tabs.Main:AddLeftGroupbox("Teleports")

	TeleportsGroupBox:AddDropdown("TeleportsDropdown", {
		Values = TeleportLocations_DropDownValues,
		Default = 1,
		Multi = false,

		Text = "Select location",
		Tooltip = "Location to teleport to",
	})

	TeleportsGroupBox:AddButton("Teleport", function()
		local Selected = GetOptionValue("TeleportsDropdown")
		local Position = TeleportLocations[Selected]

		if Position then
			Utils.TP(Position)
		end
	end)

	local UtilitiesGroupBox = Tabs.Main:AddRightGroupbox("Utilities")

	if not NO_HOOKING then
		UtilitiesGroupBox:AddToggle("FakeFishRadar", {
			Text = "Fish radar",
			Default = false,
			Tooltip = "A fake clientside fish radar.",
		}):AddKeyPicker("FakeFishRadarKeybind", {
			Default = "Insert",
			SyncToggleState = true,

			Mode = "Toggle",

			Text = "Fish radar",
			NoUI = false,
		})
	end

	UtilitiesGroupBox:AddToggle("DisablePeakEffects", {
		Text = "Disable oxygen/temperature",
		Default = false,
		Tooltip = "Disables peak effects.",
	})

	UtilitiesGroupBox:AddToggle("InfiniteOxygen", {
		Text = "Infinite oxygen [Water]",
		Default = false,
		Tooltip = "Gives you infinite oxygen.",
	})

	UtilitiesGroupBox:AddToggle("AntiAFK", {
		Text = "Anti-AFK",
		Default = false,
		Tooltip = "Prevents you from being kicked for being AFK.",
	})

	UtilitiesGroupBox:AddDivider()
	UtilitiesGroupBox:AddLabel("Performance")

	UtilitiesGroupBox:AddToggle("DestroyFish", {
		Text = "No fish models",
		Default = false,
		Tooltip = "Automatically deletes fish models.",
	})

	UtilitiesGroupBox:AddToggle("DisableRendering", {
		Text = "Disable rendering [+FPS]",
		Default = false,
		Tooltip = "Disables 3D rendering.",
		Callback = function(Value: boolean)
			RunService:Set3dRenderingEnabled(not Value)
		end,
	})

	UtilitiesGroupBox:AddToggle("DisableInventory", {
		Text = "Disable custom inventory [+FPS]",
		Default = false,
		Tooltip = "Disables the inventory UI.",
		Callback = function(Value: boolean)
			local Inventory = WaitForTable(LocalPlayer.PlayerGui, { "hud", "safezone", "backpack" })
			if Inventory then
				Inventory.Visible = not Value
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, Value)
			end
		end,
	})

	UtilitiesGroupBox:AddDivider()
	UtilitiesGroupBox:AddLabel("Tools")

	UtilitiesGroupBox:AddToggle("SpamTool", {
		Text = "Spam equipped tool",
		Default = false,
		Tooltip = "Spam-activates your equipped tool. [For crates]",
	})

	local ShopGroupBox = Tabs.Main:AddLeftGroupbox("Remote Shop")

	ShopGroupBox:AddDropdown("RemoteShopDropdown", {
		Values = {},
		Default = 1,
		Multi = false,
		Text = "Target item",
		Tooltip = "The item you want to buy",
	})

	ShopGroupBox:AddButton("Buy Item", function()
		local Selected = GetOptionValue("RemoteShopDropdown")
		local Item = workspace:WaitForChild("world"):WaitForChild("interactables"):FindFirstChild(Selected) :: Model?

		if Item then
			local Origin = LocalPlayer.Character:GetPivot()
			local LockPositionConnection = RunService.Heartbeat:Connect(function()
				Utils.TP(Item:GetPivot())
			end)

			task.wait(0.3)

			for _, Descendant in next, Item:GetDescendants() do
				if Descendant:IsA("ProximityPrompt") then
					fireproximityprompt(Descendant)
					break
				end
			end

			task.wait(0.3)

			LockPositionConnection:Disconnect()
			Utils.TP(Origin.Position)
			Utils:BreakVelocity()
		end
	end)

	ShopGroupBox:AddDivider()

	ShopGroupBox:AddLabel("Merlin")

	ShopGroupBox:AddSlider("MerlinAmount", {
		Text = "Item amount",
		Default = 1,
		Min = 1,
		Max = 1000,
		Rounding = 0,
		Compact = false,
	})

	ShopGroupBox:AddButton("Buy Power", function()
		local Amount = GetOptionValue("MerlinAmount")
		for i = 1, Amount do
			task.spawn(function()
				Remotes.Power:InvokeServer()
			end)
		end
	end)

	ShopGroupBox:AddButton("Buy Luck", function()
		local Amount = GetOptionValue("MerlinAmount")
		for i = 1, Amount do
			task.spawn(function()
				Remotes.Luck:InvokeServer()
			end)
		end
	end)

	local BoatGroupBox = Tabs.Main:AddRightGroupbox("Boat")

	BoatGroupBox:AddDropdown("BoatSpawnDropdown", {
		Values = State.OwnedBoats,
		Default = 1,
		Multi = false,

		Text = "Select boat",
		Tooltip = "Boat to spawn",
	})

	BoatGroupBox:AddButton("Remote-Spawn Boat", function()
		UI.Library:Toggle()

		local BoatSpawnLocation = LocalPlayer.Character:GetPivot().Position
		local BoatPreview = nil
		local BoatName = GetOptionValue("BoatSpawnDropdown")
		local ShipwrightNPC = Utils.GetNPC("Shipwright", true)

		if not ShipwrightNPC then
			Utils.GenericToast(3, "Shipwright not found.")
			UI.Library:Toggle()
			return
		end

		if not BoatName then
			Utils.GenericToast(3, "Please select a boat.")
			UI.Library:Toggle()
			return
		end

		if Interface.BoatModels:FindFirstChild(BoatName) then
			BoatPreview = Interface.BoatModels:FindFirstChild(BoatName):Clone()
			BoatPreview.Parent = Camera
		else
			BoatPreview = Instance.new("Model")
		end

		for _, Part in next, BoatPreview:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.Anchored = true
				Part.CanCollide = false
				Part.CanTouch = false
			end
		end

		local Origin: CFrame = LocalPlayer.Character:GetPivot()
		Camera.CameraType = Enum.CameraType.Scriptable

		TweenService:Create(Camera, TweenInfo.new(0.5), {
			CFrame = CFrame.new(Origin.Position + Vector3.new(0, 80, 0), Origin.Position),
		}):Play()

		task.wait(0.5)

		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition

		local CameraMotionConnection
		CameraMotionConnection = RunService.RenderStepped:Connect(function()
			local Delta = UserInputService:GetMouseDelta()
			local X, Y = Delta.X, Delta.Y
			Camera.CFrame *= CFrame.Angles(0, math.rad(-X * 0.5), 0) * CFrame.Angles(math.rad(-Y * 0.5), 0, 0)

			local Params = RaycastParams.new()
			Params.FilterType = Enum.RaycastFilterType.Exclude
			Params.FilterDescendantsInstances = { LocalPlayer.Character, BoatPreview }

			local CameraHit = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * 500, Params)

			if CameraHit then
				BoatSpawnLocation = CameraHit.Position + Vector3.new(0, 10, 0)
				BoatPreview:PivotTo(CFrame.new(BoatSpawnLocation))
			end
		end)

		local InputConnection
		InputConnection = UserInputService.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				InputConnection:Disconnect()
				CameraMotionConnection:Disconnect()
				Camera.CameraType = Enum.CameraType.Custom
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default

				LocalPlayer.Character:PivotTo(ShipwrightNPC:GetPivot())

				task.wait(0.3)
				fireproximityprompt(ShipwrightNPC.dialogprompt)

				local Result = ShipwrightNPC.shipwright.giveUI:InvokeServer()
				BoatPreview:Destroy()

				if Result then
					Utils.Net("RF", "Boats/Spawn"):InvokeServer(BoatName)
					Utils.Net("RE", "Boats/Close"):FireServer()
					LocalPlayer.PlayerGui.hud.safezone.shipwright.Visible = false

					-- this game is so bad
					repeat
						task.wait(0.5)
					until Interface.ActiveBoats:FindFirstChild(LocalPlayer.Name)

					local Ship =
						Interface.ActiveBoats:FindFirstChild(LocalPlayer.Name):FindFirstChildOfClass("Model") :: Model
					local Seat = Ship:FindFirstChildOfClass("VehicleSeat")
					local SitPrompt = Seat:WaitForChild("sitprompt")

					task.wait(0.5)
					fireproximityprompt(SitPrompt)
					task.wait(0.5)

					for i = 1, 60 do
						task.wait()
						Ship:PivotTo(CFrame.new(BoatSpawnLocation))
					end

					Ship.PlanePart.Rotation = Vector3.new(0, 0, 0)

					local WaterRayParams = RaycastParams.new()
					WaterRayParams.FilterType = Enum.RaycastFilterType.Include
					WaterRayParams.FilterDescendantsInstances = { workspace.Terrain }
					WaterRayParams.IgnoreWater = false

					local WaterHeight =
						workspace:Raycast(Ship.PlanePart.Position + Vector3.new(0, 100, 0), Vector3.new(0, -255, 0))

					if WaterHeight then
						Ship.PlanePart.Position = Ship.PlanePart.Position * Vector3.new(1, 0, 1)
							+ Vector3.new(0, 127, 0)
					end
				end

				UI.Library:Toggle()
			end
		end)
	end)

	local AutomationMiscGroup = Tabs.Automation:AddLeftGroupbox("Enviromental")

	AutomationMiscGroup:AddToggle("AutoMeteor", {
		Text = "Auto-Meteor",
		Default = false,
		Tooltip = "Automatically grabs item from meteor.",
	})

	local AutomationFishingGroup = Tabs.Automation:AddRightGroupbox("Fishing")

	AutomationFishingGroup:AddToggle("ZoneFish", {
		Text = "Zone-fish",
		Default = false,
		Tooltip = "Zones fish for you.",
		Callback = function(Value: boolean)
			if Value then
				UI.Toggles.InfiniteOxygen:SetValue(true)
				ZoneFishOrigin = LocalPlayer.Character:GetPivot()
			else
				for _, State: Enum.HumanoidStateType in next, Enum.HumanoidStateType:GetEnumItems() do
					LocalPlayer.Character.Humanoid:SetStateEnabled(State, true)
				end

				if ZoneFishOrigin then
					LocalPlayer.Character.Humanoid:UnequipTools()
					for _ = 1, 10 do
						task.wait()
						Utils.TP(ZoneFishOrigin.Position)
					end
					ZoneFishOrigin = nil
				end
			end
		end,
	})

	AutomationFishingGroup:AddDropdown("ZoneFishDropdown", {
		Values = FishingZones_DropDownValues,
		Default = 1,
		Multi = false,
		Text = "Select zone",
		Tooltip = "Zone to fish in",
	})

	local AutomationEconomyGroup = Tabs.Automation:AddLeftGroupbox("Economy")

	AutomationEconomyGroup:AddToggle("AutoSell", {
		Text = "Auto-sell",
		Default = false,
		Tooltip = "Automatically sells items.",
	})

	local GameVisualsGroup = Tabs.Visuals:AddLeftGroupbox("In-game")

	GameVisualsGroup:AddToggle("NoLocationCC", {
		Text = "No ambient",
		Default = false,
		Tooltip = "Disables the location Color-Correction.",
	})

	local GameplayDisruptionGroup = Tabs.Vulnerabilities:AddLeftGroupbox("Gameplay Disruption")

	GameplayDisruptionGroup:AddToggle("ServerStresser", {
		Text = "Lag/Crash server",
		Default = false,
		Tooltip = "Spams tools to lag the server.",
		Callback = function(Value: boolean)
			if not Value then
				game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
			else
				Utils.TP(LocalPlayer.Character:GetPivot().Position + Vector3.new(0, 9e9, 0))
			end
		end,
	})

	GameplayDisruptionGroup:AddLabel(
		"The server lagger is irreversible and you will be forced to rejoin if you want to disable it.",
		true
	)

	local VulnGroup = Tabs.Vulnerabilities:AddRightGroupbox("Vulnerabilities")

	VulnGroup:AddLabel("dupe coming 2025")

	-- Settings

	local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")

	MenuGroup:AddButton("Unload", Unload)

	Collect(RunService.RenderStepped:Connect(function()
		Library:SetWatermark("Current connections: " .. #Collection)
	end))

	MenuGroup:AddLabel("Menu bind")
		:AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu keybind" })
	MenuGroup:AddToggle("Rainbow", {
		Text = "Rainbow UI",
		Default = false,
		Tooltip = "Rainbow UI colors.",
	})

	Library.ToggleKeybind = UI.Options.MenuKeybind

	MenuGroup:AddToggle("ShowCustomCursor", {
		Text = "Custom Cursor",
		Default = true,
		Callback = function(Value)
			Library.ShowCustomCursor = Value
		end,
	})
	Library.ShowCustomCursor = UI.Toggles.ShowCustomCursor.Value

	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)

	SaveManager:IgnoreThemeSettings()

	SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

	ThemeManager:SetFolder("sasware_fisch")
	SaveManager:SetFolder("sasware_fisch/main")

	SaveManager:BuildConfigSection(Tabs.Settings)

	ThemeManager:ApplyToTab(Tabs.Settings)

	-- Initalize hooks / script modifications

	if not NO_HOOKING then
		local FakeFishRadar = Interface.FishRadar:Clone()
		local FishRadarTool = Instance.new("Tool")

		for _, Child in next, FakeFishRadar:GetChildren() do
			Child.Parent = FishRadarTool
		end

		FakeFishRadar:Destroy()
		FishRadarTool.radar.Enabled = false
		FishRadarTool.radar.ui.UIStroke.Color = Color3.fromRGB(204, 128, 255)
		FishRadarTool.Parent = LocalPlayer.PlayerScripts

		UI.Toggles.FakeFishRadar:OnChanged(function(Value: boolean)
			if Value == false and PreAutoloadConfig then
				return -- yes.
			end

			for _, Connection in next, getconnections(FishRadarTool.Activated) do
				local cf = Connection.Function
				debug.setupvalue(cf, 1, false) -- disable debounce lawl

				setthreadidentity(2)
				task.spawn(Connection.Function) -- why does seliware call the function in THIS thread when you fire it
				setthreadidentity(7)
			end

			FishRadarTool.radar.Enabled = true
		end)

		OnUnload.Event:Once(function()
			FishRadarTool:Destroy()
		end)
	end

	local FakeTank = Instance.new("Glue")
	FakeTank.Name = "DivingTank"
	FakeTank:SetAttribute("Tier", 9e9)

	OnUnload.Event:Once(function()
		FakeTank:Destroy()
	end)

	UI.Toggles.InfiniteOxygen:OnChanged(function(Value: boolean)
		if Value then
			FakeTank.Parent = LocalPlayer.Character
		else
			FakeTank.Parent = nil
		end
	end)

	setthreadidentity(7) -- some edge cases with seliware's connection:Fire bugs colliding with unload race conditions cause
	-- identity to be reset to 3 (or maybe it was 2 i forgot)

	Utils.BoatsChanged()

	Collect(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		Camera = workspace.CurrentCamera
	end))

	Collect(Interface.PlayerData.Boats.AncestryChanged:Connect(Utils.BoatsChanged))

	Collect(workspace:WaitForChild("active").ChildAdded:Connect(function(Child: Instance)
		if Child:IsA("Model") then
			local Fish = Child:WaitForChild("Fish", 1)

			if Fish then
				if GetToggleValue("DestroyFish") then
					task.wait()
					Child:Destroy()
				end
			end
		end
	end))

	Collect(Interface.Inventory:GetPropertyChangedSignal("Visible"):Connect(function()
		if GetToggleValue("DisableInventory") and Interface.Inventory.Visible == true then
			task.wait()
			Interface.Inventory.Visible = false
		end
	end))

	Collect(Interface.MeteorItems.ChildAdded:Connect(function(Item: Model)
		if GetToggleValue("AutoMeteor") then
			State.GettingMeteor = true

			local Origin = LocalPlayer.Character:GetPivot()
			local Prompt: ProximityPrompt = WaitForTable(Item, { "Center", "prompt" }, 5)
			local Center: Part = Prompt.Parent :: Part

			local TPConnection = RunService.PostSimulation:Connect(function()
				Utils.TP(Center:GetPivot() - (Vector3.yAxis * 5))
			end)

			task.delay(2, function()
				fireproximityprompt(Prompt)
			end)

			task.delay(4, function()
				TPConnection:Disconnect()
				Utils.TP(Origin)
				State.GettingMeteor = false
			end)
		end
	end))

	if not NO_HOOKING then
		local oldindex
		oldindex = hookmetamethod(game, "__index", function(...)
			if not Unloaded then
				if not checkcaller() then
					local Args = { ... } -- i forgot argguard wasnt a thing anymore
					local self, key = Args[1], Args[2]

					if self == Interface.Inventory and key == "Visible" then
						local callingscript = getcallingscript()

						if callingscript and (not game.IsDescendantOf(callingscript, Interface.Inventory)) then
							return true -- for some reason when the backpack isn't visible it disables the menu buttons
						end
					end
				end
			end

			return oldindex(...)
		end)

		local oldnamecall
		oldnamecall = hookmetamethod(game, "__namecall", function(...)
			if not Unloaded then
				if not checkcaller() then
					local Method = getnamecallmethod()

					local Args = { ... }
					local self = table.remove(Args, 1)

					if Method == "FireServer" then
						if self == Remotes.ReelFinished then
							if GetToggleValue("PerfectReel") then
								Args[1] = 100 -- Reel percentage
								Args[2] = true -- If the reel was perfect
							end
						elseif tostring(self) == "cast" then -- ultra detectable but i dont care because im sigma.
							if GetToggleValue("PerfectCast") then
								Args[1] = 100 -- Cast percentage
							end
						end

						return oldnamecall(self, unpack(Args))
					end
				end
			end

			return oldnamecall(...)
		end)
	end

	local ShopUpdateCoroutine = coroutine.create(function()
		while task.wait(1) do
			if GetToggleValue("AutoSell") then
				Remotes.SellAll:InvokeServer()
			end
			Utils.UpdateShopDropdown()
		end
	end)

	local AutoClickCoroutine = coroutine.create(function()
		function Utils.MountShakeUI(ShakeUI: ScreenGui)
			local SafeZone: Frame? = ShakeUI:WaitForChild("safezone", 5) :: Frame?

			local function HandleButton(Button: ImageButton)
				Button.Selectable = true -- For some reason this is false for the first 0.2 seconds.

				if EnsureInstance(Button) then
					GuiService.SelectedObject = Button
				end
			end

			if not SafeZone then
				dbgwarn("Unable to mount shake UI.")
				return
			end

			if GetToggleValue("CenterShake") then
				local Connect = SafeZone:WaitForChild("connect", 1)

				if Connect then
					Connect.Enabled = false -- this script locks the size of the safezone, so we disable it.
				end

				SafeZone.Size = UDim2.fromOffset(0, 0)
				SafeZone.Position = UDim2.fromScale(0.5, 0.5)
				SafeZone.AnchorPoint = Vector2.new(0.5, 0.5)
			end

			if GetToggleValue("AutoShake") then
				local Connection = SafeZone.ChildAdded:Connect(function(Child)
					if not Child:IsA("ImageButton") then return end
					
					if replicatesignal then
						replicatesignal(Child.MouseButton1Click)
						task.delay(0.05, function() Child:Destroy() end) -- the shake ui is a bit buggy if you click it this fast so to avoid the visual glitch we destroy it
						return
					end
					
					local Done = false

					task.spawn(function()
						repeat
							RunService.Heartbeat:Wait()
							HandleButton(Child)
						until Done
					end)

					task.spawn(function()
						repeat
							RunService.Heartbeat:Wait()
						until (not Child) or (not Child:IsDescendantOf(SafeZone))
						Done = true
					end)
				end)

				if replicatesignal then return end
				
				repeat
					RunService.Heartbeat:Wait()
					if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(SafeZone) then
						VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
						VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
					end
					RunService.Heartbeat:Wait()
				until not SafeZone:IsDescendantOf(LocalPlayer.PlayerGui)
				Connection:Disconnect()
				GuiService.SelectedObject = nil
			end
		end

		Collect(LocalPlayer.PlayerGui.ChildAdded:Connect(function(Child: Instance)
			if Child.Name == "shakeui" and Child:IsA("ScreenGui") then
				Utils.MountShakeUI(Child)
			end
		end))
	end)

	local AutoReelCoroutine = coroutine.create(function()
		while true do
			RunService.RenderStepped:Wait()

			local ReelUI: ScreenGui = LocalPlayer.PlayerGui:FindFirstChild("reel")

			if not ReelUI then
				continue
			end

			if GetToggleValue("InstantReel") then
				local Bar = ReelUI:FindFirstChild("bar")

				if Bar then
					local ReelScript = Bar:FindFirstChild("reel")
					if ReelScript and ReelScript.Enabled == true then
						Remotes.ReelFinished:FireServer(100, GetToggleValue("PerfectReel"))
					end
				end
			elseif GetToggleValue("AutoReel") then
				local Bar = ReelUI:FindFirstChild("bar")

				if not Bar then
					continue
				end

				local PlayerBar: Frame = Bar:FindFirstChild("playerbar")
				local TargetBar: Frame = Bar:FindFirstChild("fish")

				while Bar and ReelUI:IsDescendantOf(LocalPlayer.PlayerGui) do
					RunService.RenderStepped:Wait()
					local UnfilteredTargetPosition = PlayerBar.Position:Lerp(TargetBar.Position, 0.7)
					local TargetPosition = UDim2.fromScale(
						math.clamp(UnfilteredTargetPosition.X.Scale, 0.15, 0.85),
						UnfilteredTargetPosition.Y.Scale
					)

					PlayerBar.Position = TargetPosition
				end
			end
		end
	end)

	local AutoCastCoroutine = coroutine.create(function()
		local LastCastAttempt = 0

		while task.wait(0.5) do
			if GetToggleValue("AutoCast") then
				pcall(function()
					if not CurrentTool then
						return
					end

					local Values = CurrentTool:FindFirstChild("values")
					if CurrentTool and Values then
						local Events = CurrentTool:FindFirstChild("events")

						-- sometimes the game freaks out and gets stuck after reeling in with blatant autoreel and we need to fix it
						if
							Values:FindFirstChild("bite")
							and Values.bite.Value == true
							and Values.casted.Value == true
						then
							if (not LocalPlayer.PlayerGui:FindFirstChild("reel")) and tick() - LastCastAttempt > 5 then
								ResetTool()
							end
						end

						-- another fix
						if Utils.CountInstances(LocalPlayer.PlayerGui, "reel") > 1 then
							-- reeling is broken, reset tool and delete the glitched reel UI
							ResetTool()
							for _, Child in next, LocalPlayer.PlayerGui:GetChildren() do
								if Child.Name == "reel" then
									Child:Destroy()
								end
							end
						end

						if Values.casted.Value == false then
							LastCastAttempt = tick()

							local AnimationFolder = ReplicatedStorage:WaitForChild("resources")
								:WaitForChild("animations")

							local CastAnimation: AnimationTrack = LocalPlayer.Character
								:FindFirstChild("Humanoid")
								:LoadAnimation(AnimationFolder.fishing.throw)
							CastAnimation.Priority = Enum.AnimationPriority.Action3
							CastAnimation:Play()
							Events.cast:FireServer(100, 1)

							CastAnimation.Stopped:Once(function()
								CastAnimation:Destroy()

								local WaitingAnimation: AnimationTrack = LocalPlayer.Character
									:FindFirstChild("Humanoid")
									:LoadAnimation(AnimationFolder.fishing.waiting)
								WaitingAnimation.Priority = Enum.AnimationPriority.Action3
								WaitingAnimation:Play()

								local UnequippedLoop, CastConnection

								CastConnection = Values.casted.Changed:Once(function()
									WaitingAnimation:Stop()
									WaitingAnimation:Destroy()
									coroutine.close(UnequippedLoop)
								end)

								UnequippedLoop = coroutine.create(function()
									repeat
										task.wait()
									until not CurrentTool
									WaitingAnimation:Stop()
									WaitingAnimation:Destroy()
									CastConnection:Disconnect()
								end)

								coroutine.resume(UnequippedLoop)
							end)
						end
					end
				end)
			end
		end
	end)

	local ServerStressCoroutine = coroutine.create(function()
		local Backpack = LocalPlayer.Backpack

		local function IsFish(Tool: Tool)
			return Tool:FindFirstChild("fishscript") or (Tool:GetAttribute("IsFish") == true)
		end

		while task.wait(5) do
			if not GetToggleValue("ServerStresser") then
				continue
			end

			for i, Tool in next, Backpack:GetChildren() do
				task.spawn(function()
					if IsFish(Tool) then
						Tool:SetAttribute("IsFish", true)

						local FishModel = Tool:FindFirstChild("Fish")

						if FishModel then
							FishModel:Destroy()
						end

						Tool.Parent = LocalPlayer.Character
					end
				end)
			end

			LocalPlayer.Character.Humanoid:UnequipTools()
		end
	end)

	-- VULNERABILTY SECTION: PRONE TO DETECTION & PATCHES

	-- all patched for now

	-- yea thats the vulnerability section lol

	Collect(RunService.RenderStepped:Connect(function()
		local Inventory = WaitForTable(LocalPlayer.PlayerGui, { "hud", "safezone", "backpack" })
		if Inventory and Inventory.Visible then
			Inventory.Visible = not GetToggleValue("DisableInventory")
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, GetToggleValue("DisableInventory"))
		end

		if GetToggleValue("SpamTool") then
			if CurrentTool then
				for i = 20, 1, -1 do
					CurrentTool:Activate()
				end
			end
		end

		UserInputService.MouseIconEnabled = not GetToggleValue("ShowCustomCursor") or not UI.Library.Toggled

		if GetToggleValue("NoLocationCC") then
			Utils.ToggleLocationCC(false)
		else
			Utils.ToggleLocationCC(true)
		end
	end))

	Collect(RunService.PostSimulation:Connect(function()
		if GetToggleValue("ZoneFish") then
			if State.GettingMeteor then
				return -- dont conflict with meteor grabbing
			end

			for _, Part in next, LocalPlayer.Character:GetDescendants() do
				if Part:IsA("BasePart") then
					Part.CanTouch = false -- killzones and such
					Part.AssemblyLinearVelocity = Vector3.zero
					Part.AssemblyAngularVelocity = Vector3.zero
				end
			end

			local Zone = FishingZones[GetOptionValue("ZoneFishDropdown")]

			if Zone then
				local Origin = Zone:GetPivot()
				Utils.TP(Origin - Vector3.new(0, 20, 0))

				if CurrentTool then
					local Bobber = CurrentTool:FindFirstChild("bobber")
					if Bobber then
						local Rope = Bobber:FindFirstChildOfClass("RopeConstraint")
						if Rope then
							Rope.Length = 9e9
						end
						Bobber:PivotTo(Origin)
					end
				end
			end
		elseif GetToggleValue("InstantBob") then
			if CurrentTool then
				local Bobber = CurrentTool:FindFirstChild("bobber")
				if Bobber then
					local Params = RaycastParams.new()

					Params.FilterType = Enum.RaycastFilterType.Include
					Params.FilterDescendantsInstances = { workspace.Terrain }

					local RaycastResult = workspace:Raycast(Bobber.Position, -Vector3.yAxis * 100, Params)

					if RaycastResult then
						if RaycastResult.Instance:IsA("Terrain") then
							Bobber:PivotTo(CFrame.new(RaycastResult.Position))
						end
					end
				end
			end
		end
	end))

	Collect(LocalPlayer.Idled:Connect(function()
		if GetToggleValue("AntiAFK") then -- pasted from infinite yield weeeeeeeee
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end
	end))

	-- Start coroutines
	coroutine.resume(ServerStressCoroutine)
	coroutine.resume(AutoClickCoroutine)
	coroutine.resume(AutoReelCoroutine)
	coroutine.resume(AutoCastCoroutine)
	coroutine.resume(ShopUpdateCoroutine)
	Collect(ServerStressCoroutine)
	Collect(AutoClickCoroutine)
	Collect(AutoReelCoroutine)
	Collect(AutoCastCoroutine)
	Collect(ShopUpdateCoroutine)

	Collect(LocalPlayer.CharacterAdded:Connect(Utils.CharacterAdded))
	Collect(RunService.RenderStepped:Connect(function()
		if GetToggleValue("Rainbow") then
			Library.AccentColor = Library.CurrentRainbowColor
			Library:UpdateColorsUsingRegistry()
		end
	end))

	OnUnload.Event:Once(function()
		for _, PersistentModel: Model in next, CollectionService:GetTagged("ForcePersistent") do
			if PersistentModel:GetAttribute("OldStreamingMode") then
				local OldStreamingMode: string = PersistentModel:GetAttribute("OldStreamingMode") :: string
				PersistentModel.ModelStreamingMode =
					Enum.ModelStreamingMode[OldStreamingMode] :: Enum.ModelStreamingMode
			else
				PersistentModel.ModelStreamingMode = Enum.ModelStreamingMode.Default
			end

			CollectionService:RemoveTag(PersistentModel, "ForcePersistent")
			PersistentModel:SetAttribute("OldStreamingMode", nil)
		end
	end)

	if LocalPlayer.Character then
		Utils.CharacterAdded(LocalPlayer.Character)
	end

	SaveManager:LoadAutoloadConfig()
	PreAutoloadConfig = false

	Utils.GameNotify("Sasware [Fisch] loaded successfully!")

	-- DONT REMOVE this end remember this is wrapped in a pcall
end)

if not Success then
	warn("Error:", Error)
end

-- task.wait(220)
-- getgenv().sasware_fisch_unload()
