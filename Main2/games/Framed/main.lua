-- Define variables / constants

local Startup = tick()

local httprequest = (syn and syn.request)
	or (http and http.request)
	or http_request
	or (fluxus and fluxus.request)
	or request

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ServerMode = game:GetService("Workspace").Values.ServerMode
local Targets = game:GetService("Workspace").Values.Targets
local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui
local MissNextShot = false
local HitChance = 100

local GunStats = require(ReplicatedStorage.gunStats)
local DefaultGunStats = require(ReplicatedStorage.ServerConfig.DefaultGunStats)

local AllowedSilentAimGuns = {}

for GunName : string, Data in next, DefaultGunStats do
	if Data.Bullets == 1 then
		print(GunName)
		AllowedSilentAimGuns[GunName] = true
	end
end

-- Load in modules

local ESP = loadstring(game:HttpGet("https://kiriot22.com/releases/ESP.lua"))()
-- // Load Aiming Module
local Aiming = loadstring(
	game:HttpGet("https://raw.githubusercontent.com/centerepic/sasware_maplecounty/refs/heads/main/aiming_library.luau")
)()

Aiming.Enabled = false
Aiming.FOV = 60
Aiming.FOVColor = Color3.fromRGB(255, 255, 255)
Aiming.Players = true

ESP:Toggle(true)

local function BetterRound(num, numDecimalPlaces): number
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function GameInProgress()
	return ServerMode.Value == "In Progress"
end

ServerMode.Changed:Connect(function()
	if Toggles.ESPToggle.Value == false then
		ESP:Toggle(false)
	end
	if Toggles.ESPToggle.Value == true then
		ESP:Toggle(GameInProgress())
	end
end)

local function GetUserFromId(Id)
	return Players:GetPlayerByUserId(Id)
end

local function Miss()
	return (math.random(0, 100) >= HitChance)
end

local function GetTargets(Player)
	local Decoded = game:GetService("HttpService"):JSONDecode(Targets.Value)
	local Targets = Decoded[tostring(Player.UserId)]
	local PlayerTable = {}
	if Targets then
		for _, b in pairs(Targets) do
			table.insert(PlayerTable, GetUserFromId(b))
		end
	end

	return PlayerTable
end

local function MyTargets()
	return GetTargets(LocalPlayer)
end

local UndercoverESP
local TargetESP = {}
local HunterESP = {}

local function Mark(Player, Role, Color)
	return ESP:Add(Player.Character, {
		Name = Role or Player.Name,
		Color = Color,
		Player = Player,
		Temporary = true,
		PrimaryPart = Player.Character:FindFirstChild("HumanoidRootPart") or Player.Character:FindFirstChild("Torso"),
		IsEnabled = Role,
	})
end

local Repository = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/refs/heads/main/"
local Library = loadstring(game:HttpGet(Repository .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repository .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repository .. "addons/SaveManager.lua"))()

local Window
Window = Library:CreateWindow({
	Title = "sasware v1 | OpenWare",
	Center = true,
	AutoShow = true,
})

local Tabs = {
	CombatTab = Window:AddTab("Combat"),
	VisualsTab = Window:AddTab("Visuals"),
	CreditsTab = Window:AddTab("Credits"),
	UISettings = Window:AddTab("UI Settings"),
}

local AimingGroup = Tabs.CombatTab:AddLeftGroupbox("Aiming")

AimingGroup:AddToggle("SilentAim", {
	Text = "Silent Aim",
	Default = false,
	Tooltip = "Enables/Disables silent aim.",
    Callback = function(Value)
        Aiming.Enabled = Value
    end
})

AimingGroup:AddSlider("FOVSlider", {
	Text = "Aim FOV",
	Default = 60,
	Min = 15,
	Max = 360,
	Rounding = 0,
	Compact = false,
    Callback = function(Value)
        Aiming.FOV = Value
    end,
})

AimingGroup:AddDropdown("SilentAimParts", {
	Values = { "Head", "Torso" },
	Default = 1,
	Multi = false,
	Text = "Target part",
	Tooltip = "Select parts that the silent-aim will target",
})

Options.FOVSlider:OnChanged(function()
	Aiming.FOV = Options.FOVSlider.Value
end)

AimingGroup:AddSlider("AccuracySlider", {
	Text = "Hitchance",
	Default = 100,
	Min = 10,
	Max = 100,
	Rounding = 0,
	Compact = false,
})

Options.AccuracySlider:OnChanged(function()
	HitChance = Options.AccuracySlider.Value
end)

local CombatOtherGroup = Tabs.CombatTab:AddRightGroupbox("Main")

CombatOtherGroup:AddToggle("AlwaysBackstabToggle", {
	Text = "Always backstab",
	Default = false,
	Tooltip = "Makes all knife hits backstabs.",
})

CombatOtherGroup:AddButton("Remove Face [BLATANT]", function()
	LocalPlayer.Character.Head.Face:Destroy()
end)

local MainGroup = Tabs.VisualsTab:AddLeftGroupbox("Main")

MainGroup:AddToggle("ESPToggle", {
	Text = "ESP",
	Default = false,
	Tooltip = "Enables/Disables ESP.",
	Callback = function(Value)
		ESP:Toggle(Value)
	end
})

MainGroup:AddToggle("ESPNames", {
	Text = "Names",
	Default = false,
	Tooltip = "Enables/Disables Names.",
	Callback = function(Value)
		ESP.Names = Value
	end
})

MainGroup:AddToggle("HunterESPToggle", {
	Text = "Hunter ESP",
	Default = false,
	Tooltip = "Enables/Disables hunter ESP.",
})

Toggles.HunterESPToggle:OnChanged(function(Value)
	ESP.Hunter = Value
end)

MainGroup:AddToggle("TargetESPToggle", {
	Text = "Target ESP",
	Default = false,
	Tooltip = "Enables/Disables target ESP.",
})

Toggles.TargetESPToggle:OnChanged(function(Value)
	ESP.Target = Value
end)

MainGroup:AddToggle("UndercoverESPToggle", {
	Text = "Undercover ESP",
	Default = false,
	Tooltip = "Enables/Disables undercover ESP.",
})

MainGroup:AddToggle("ModDetection", {
	Text = "Warn on mod join",
	Default = true,
	Tooltip = "Notifies you when a moderator joins the game.",
})

Toggles.UndercoverESPToggle:OnChanged(function(Value)
	ESP.Undercover = Value
end)

local CreditsGroup = Tabs.CreditsTab:AddLeftGroupbox("Credits")

CreditsGroup:AddButton("Stefanuk12 [Aiming Lib]", function()
	print("hi")
end)
CreditsGroup:AddButton("Kiriot [ESP Lib]", function()
	print("hi")
end)
CreditsGroup:AddButton("Wally [UI Lib]", function()
	print("hi")
end)

ServerMode.Changed:Connect(function()
	if not GameInProgress() then
		if UndercoverESP then
			UndercoverESP:Remove()
            UndercoverESP = nil
		end
		for i, v in pairs(HunterESP) do
			v:Remove()
		end
		HunterESP = {}
		for i, v in pairs(TargetESP) do
			v:Remove()
		end
		TargetESP = {}
	end
end)

local function ESPConnect(Player)
	local CurrentCoro
	Player.CharacterAdded:Connect(function(Character)
		if GameInProgress() then
			if CurrentCoro then
				coroutine.close(CurrentCoro)
			end
			CurrentCoro = coroutine.create(function()
				task.wait(2)

                local targets = GetTargets(Player)
                local myTargets = MyTargets()
                local playerRole = Player.Role.Value

                if playerRole ~= '' then
                    playerRole = game:GetService("HttpService"):JSONDecode(playerRole).Name
                end

                while Player.Character and Player.Character:IsDescendantOf(workspace) do

                    task.wait(1)

                    targets = GetTargets(Player)
                    myTargets = MyTargets()
                    playerRole = Player.Role.Value
                    if playerRole ~= '' then
                        playerRole = game:GetService("HttpService"):JSONDecode(playerRole).Name
                    end

                    if playerRole == "Undercover" then
                        if not UndercoverESP then
                            UndercoverESP = Mark(Player, "Undercover", Color3.new(0.415686, 0.858823, 0.054901))
                        end
                    else
                        if table.find(targets, LocalPlayer) then
                            if not HunterESP[Player] then
                                HunterESP[Player] = Mark(Player, "Hunter", Color3.new(1, 0.482352, 0))
                            end
                        end
                        if table.find(myTargets, Player) then
                            if not TargetESP[Player] then
                                TargetESP[Player] = Mark(Player, "Target", Color3.new(0.384313, 0, 1))
                            end
                        end
                    end

                end
			end)
			coroutine.resume(CurrentCoro)
		end
	end)
end

task.spawn(function()
	while task.wait(1) do
		for i, v in pairs(HunterESP) do
			if not table.find(GetTargets(i), LocalPlayer) then
				v:Remove()
			end
		end

		for i, v in pairs(TargetESP) do
			if not table.find(MyTargets(), i) then
				v:Remove()
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(Player)
	if Player:IsInGroup(1146321) and Player:GetRoleInGroup(1146321):lower() ~= "fan" then
		if Toggles.ModDetection.Value == true then
			Library:Notify("Moderator/Contributor detected! Consider leaving soon.", 5)
		end
	end
end)

for i, v in pairs(Players:GetPlayers()) do
	ESPConnect(v)
end

Players.PlayerAdded:Connect(function(player)
	ESPConnect(player)
end)

-- new code (can you tell lol)

local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)

    if not checkcaller() then
        local Args = { ... }
        local NamecallMethod = getnamecallmethod()

        if
            (Toggles.AlwaysBackstabToggle.Value or Toggles.SilentAim.Value)
            and tostring(self) == "Shoot"
            and NamecallMethod == "FireServer"
        then

            if tostring(Args[1].Tool) == "Knife" then
                Args[1].IsBackstab = Toggles.AlwaysBackstabToggle.Value
            else
				warn('FireHook. PreCall: ' .. Args[1].Tool.Name)

				local WeaponName = Args[1].Tool.Name
				if ReplicatedStorage.Guns:FindFirstChild(WeaponName) then
					WeaponName = "Pistol"
				end

                if Toggles.SilentAim.Value and Aiming.CurrentTarget and shared.LastSpreadResult and AllowedSilentAimGuns[WeaponName] then
					print('FireHook. Call: ' .. Args[1].Tool.Name)

					Args[1].Aiming = false

                    local NewLookDir = CFrame.new(workspace.CurrentCamera.CFrame.Position, Aiming.CurrentTarget[Options.SilentAimParts.Value].Position)

                    if #Args[1].Bullets == 1 then
                        NewLookDir *= shared.LastSpreadResult:Inverse() -- nice check
						shared.LastSpreadResult = nil -- dont reuse or we get bombed

                        setnamecallmethod(NamecallMethod)

                        if not shared.LastShouldMissResult then
                            Args[1].LookDir = NewLookDir
                        end
                    else
                        if not Miss() then
                            Args[1].LookDir = NewLookDir
                        end
                    end  
                end
            end

            return OldNamecall(self, table.unpack(Args))
        end
    end

	return OldNamecall(self, ...)
end)

local GetSpreadF: (Spread: number, CurrentTime: number, Seed: number) -> CFrame
local GetRayF: (
	Humanoid: Instance,
	HumanoidRootPart: Instance,
	CameraCF: CFrame,
	Weapon: Instance,
	IsAiming: boolean,
	Time: number,
	Seed: number
) -> Ray

GetRayF = require(ReplicatedStorage.getRay)
assert(GetRayF and type(GetRayF) == "function", "Failed to find GetRayF")
GetSpreadF = debug.getupvalue(GetRayF, 2)
assert(GetSpreadF and type(GetSpreadF) == "function", "Failed to find GetSpreadF")

shared.OldGetSpreadF = function(spread, time, seed)
	local randomSeed = (time - math.floor(time)) * 13 * 67 * 1000
	local rng = Random.new(randomSeed + seed * 7)

	local angleX = math.rad(rng:NextNumber(-0.5, 0.5) * spread)
	local angleY = math.rad(rng:NextNumber(-0.5, 0.5) * spread)
	local angleZ = math.rad(rng:NextNumber(-0.5, 0.5) * spread)

	return CFrame.Angles(angleX, angleY, angleZ)
end

debug.setupvalue(GetRayF, 2, function(...)
    return shared.OldGetSpreadF(...)
end)

local GetRayHook = function(Humanoid, HumanoidRootPart : Part, CamCFrame : CFrame, Weapon, IsAiming, Time, Seed)

	IsAiming = false

    local ShouldMiss = Miss()
    shared.LastShouldMissResult = ShouldMiss

	local WeaponName = Weapon.Name
	if ReplicatedStorage.Guns:FindFirstChild(WeaponName) then
		WeaponName = "Pistol"
	end

	warn('GetRayHook. PreCall: ' .. Weapon.Name)
	if (not ShouldMiss) and Toggles.SilentAim.Value and Aiming.CurrentTarget and AllowedSilentAimGuns[WeaponName] then
		print('GetRayHook. Call: ' .. Weapon.Name)
		local TargetPart = Aiming.CurrentTarget[Options.SilentAimParts.Value]

		if TargetPart then
			local TargetPosition = TargetPart.Position

			if TargetPosition then
                CamCFrame = CFrame.new(CamCFrame.Position, Aiming.CurrentTarget[Options.SilentAimParts.Value].Position)
			end
		end
	end

    local HumanoidState = Humanoid:GetState()
	local Moving = HumanoidState == Enum.HumanoidStateType.Jumping and true or HumanoidState == Enum.HumanoidStateType.Freefall
	local GunStat = GunStats[Weapon.Name] or GunStats.Pistol

    local SpreadResult : CFrame

    if Moving then
		local v24 = GunStat.JumpSpread
		SpreadResult = shared.OldGetSpreadF(v24, Time, Seed)
	elseif IsAiming then
		local v25 = GunStat.AimSpread
		SpreadResult = shared.OldGetSpreadF(v25, Time, Seed)
	elseif HumanoidRootPart.AssemblyLinearVelocity.Magnitude > 2 then
		local v26 = GunStat.WalkSpread
		SpreadResult = shared.OldGetSpreadF(v26, Time, Seed)
	else
		local v27 = GunStat.IdleSpread
		SpreadResult = shared.OldGetSpreadF(v27, Time, Seed)
	end

    shared.LastSpreadResult = SpreadResult

	if ShouldMiss or (not Toggles.SilentAim.Value) or (not Aiming.CurrentTarget) or (not AllowedSilentAimGuns[WeaponName]) then
		CamCFrame *= SpreadResult
	end
    
    return Ray.new(CamCFrame.Position, CamCFrame.LookVector * 500)
end

hookfunction(GetRayF, function(...)
    return GetRayHook(...)
end)

RunService.RenderStepped:Connect(function()
    UserInputService.MouseIconEnabled = not Toggles.ShowCustomCursor.Value or not Library.Toggled
end)

ThemeManager:SetLibrary(Library)

SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("sasware_framed")

SaveManager:SetFolder("sasware_framed/main")

SaveManager:BuildConfigSection(Tabs.UISettings)

ThemeManager:ApplyToTab(Tabs.UISettings)

local MenuGroup = Tabs.UISettings:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = false,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})
Library.ShowCustomCursor = Toggles.ShowCustomCursor.Value


Library:Notify("All features loaded in " .. tostring(BetterRound(tick() - Startup, 3)) .. " seconds.", 3)
