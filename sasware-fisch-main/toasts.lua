local fscript = Instance.new("Folder")
fscript.Name = "Toasts"

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- Instances:

local Toast = Instance.new("ImageLabel")
local IconBuffer = Instance.new("Frame")
local Icon = Instance.new("ImageLabel")
local TextBuffer = Instance.new("Frame")
local Upper = Instance.new("TextLabel")
local Lower = Instance.new("TextLabel")
local UIGradient = Instance.new("UIGradient")

--Properties:

Toast.Name = "Toast"
Toast.Parent = fscript
Toast.AnchorPoint = Vector2.new(0.5, 0)
Toast.BackgroundTransparency = 1.000
Toast.BorderColor3 = Color3.fromRGB(27, 42, 53)
Toast.BorderSizePixel = 0
Toast.ClipsDescendants = true
Toast.Position = UDim2.new(0.5, 0, 0, 8)
Toast.Size = UDim2.new(0, 80, 0, 58)
Toast.ZIndex = 2
Toast.Image = "rbxasset://textures/ui/Camera/CameraToast9Slice.png"
Toast.ImageColor3 = Color3.fromRGB(27, 15, 32)
Toast.ImageRectSize = Vector2.new(6, 6)
Toast.ImageTransparency = 1.000
Toast.ScaleType = Enum.ScaleType.Slice
Toast.SliceCenter = Rect.new(3, 3, 3, 3)

IconBuffer.Name = "IconBuffer"
IconBuffer.Parent = Toast
IconBuffer.BackgroundTransparency = 1.000
IconBuffer.BorderColor3 = Color3.fromRGB(27, 42, 53)
IconBuffer.BorderSizePixel = 0
IconBuffer.Size = UDim2.new(0, 80, 1, 0)
IconBuffer.ZIndex = 2

Icon.Name = "Icon"
Icon.Parent = IconBuffer
Icon.AnchorPoint = Vector2.new(0.5, 0.5)
Icon.BackgroundTransparency = 1.000
Icon.BorderColor3 = Color3.fromRGB(27, 42, 53)
Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
Icon.Size = UDim2.new(0, 48, 0, 48)
Icon.ZIndex = 3
Icon.Image = "rbxasset://textures/ui/Camera/CameraToastIcon.png"
Icon.ImageColor3 = Color3.fromRGB(200, 200, 200)
Icon.ImageTransparency = 1.000

TextBuffer.Name = "TextBuffer"
TextBuffer.Parent = Toast
TextBuffer.BackgroundTransparency = 1.000
TextBuffer.BorderColor3 = Color3.fromRGB(27, 42, 53)
TextBuffer.BorderSizePixel = 0
TextBuffer.ClipsDescendants = true
TextBuffer.Position = UDim2.new(0, 80, 0, 0)
TextBuffer.Size = UDim2.new(1, -80, 1, 0)
TextBuffer.ZIndex = 2

Upper.Name = "Upper"
Upper.Parent = TextBuffer
Upper.AnchorPoint = Vector2.new(0, 1)
Upper.BackgroundTransparency = 1.000
Upper.BorderColor3 = Color3.fromRGB(27, 42, 53)
Upper.Position = UDim2.new(0, 0, 0.5, 0)
Upper.Size = UDim2.new(1, 0, 0, 19)
Upper.ZIndex = 3
Upper.Font = Enum.Font.GothamMedium
Upper.Text = "Upper text"
Upper.TextColor3 = Color3.fromRGB(200, 200, 200)
Upper.TextSize = 19.000
Upper.TextTransparency = 1.000
Upper.TextXAlignment = Enum.TextXAlignment.Left

Lower.Name = "Lower"
Lower.Parent = TextBuffer
Lower.BackgroundTransparency = 1.000
Lower.BorderColor3 = Color3.fromRGB(27, 42, 53)
Lower.Position = UDim2.new(0, 0, 0.5, 3)
Lower.Size = UDim2.new(1, 0, 0, 15)
Lower.ZIndex = 3
Lower.Font = Enum.Font.Gotham
Lower.Text = "Lower text"
Lower.TextColor3 = Color3.fromRGB(200, 200, 200)
Lower.TextSize = 15.000
Lower.TextTransparency = 1.000
Lower.TextXAlignment = Enum.TextXAlignment.Left

UIGradient.Color = ColorSequence.new({
  ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
  ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 236, 203)),
})
UIGradient.Parent = Toast

local module = {}

local function AnimateToast(toast, anim)
  local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
  local open = anim == "open"

  local imgParams = { ImageTransparency = open and 0 or 1 }
  local txtParams = { TextTransparency = open and 0 or 1 }

  TweenService:Create(toast, tweenInfo, {
    Size = open and UDim2.new(0, 326, 0, 58) or UDim2.new(0, 80, 0, 58),
    ImageTransparency = open and 0.1 or 1,
  }):Play()

  TweenService:Create(toast.IconBuffer.Icon, tweenInfo, imgParams):Play()
  TweenService:Create(toast.TextBuffer.Upper, tweenInfo, txtParams):Play()
  TweenService:Create(toast.TextBuffer.Lower, tweenInfo, txtParams):Play()

  toast = not open and Debris:AddItem(toast, 0.25)
end

local function GetGui()
  local Player = Players.LocalPlayer
  local gui = Player.PlayerGui:FindFirstChild("Toasts") or Instance.new("ScreenGui", Player.PlayerGui)
  gui.DisplayOrder = 2147483647
  gui.Name = "Toasts"

  return gui
end

local function empty()
  return function() end
end

module.CreateToast = function(ToastId, TopText, BottomText, IconId, DisplayTime)
  local newToast = fscript.Toast:Clone()
  newToast.TextBuffer.Upper.Text = TopText
  newToast.TextBuffer.Lower.Text = BottomText
  newToast.IconBuffer.Icon.Image = IconId
  newToast.Name = ToastId

  local oldToast = GetGui():FindFirstChild(ToastId)
  local run = false

  if oldToast then
    run = oldToast.ImageTransparency < 0.1
  end

  if not run then
    Debris:AddItem(newToast, DisplayTime or math.huge)
    AnimateToast(newToast, "open")
    newToast.Parent = GetGui()

    return {
      CancelToast = function()
        AnimateToast(newToast, "cancel")
      end,
      DestroyToast = function(delaytime: "optional")
        Debris:AddItem(newToast, delaytime or 0)
      end,
      HideToast = function()
        newToast.Visible = false
      end,
      ShowToast = function()
        newToast.Visible = true
      end,
    }
  else
    return { CancelToast = empty(), DestroyToast = empty(), HideToast = empty(), ShowToast = empty() }
  end
end

module.GetToast = function(id)
  local gui = GetGui()
  local toast = gui:FindFirstChild(id)

  if toast then
    return {
      CancelToast = function()
        AnimateToast(toast, "cancel")
      end,
      DestroyToast = function(delaytime: "optional")
        Debris:AddItem(toast, delaytime or 0)
      end,
      HideToast = function()
        toast.Visible = false
      end,
      ShowToast = function()
        toast.Visible = true
      end,
    }
  else
    return { CancelToast = empty(), DestroyToast = empty(), HideToast = empty(), ShowToast = empty() }
  end
end

module.CancelAllToasts = function()
  for i, toast in pairs(GetGui():GetChildren()) do
    AnimateToast(toast, "cancel")
  end
end

return module
