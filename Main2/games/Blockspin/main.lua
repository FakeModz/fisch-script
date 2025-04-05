--!native
--!nolint BuiltinGlobalWrite
--!nolint UnknownGlobal

local DEBUGGING = true
local USERCONSOLE = true
local HOOKING_ENABLED = true

local Version = "1.3.1"
local SubVersion = "Release Candidate 2"
local HIDN = 0

_G.__HOOK_KEY = ""
_G.__ORIGINAL_KEY = ""

if not (rconsolecreate and rconsolesettitle) then
	USERCONSOLE = false
end

if USERCONSOLE then
	rconsolesettitle("Sasware Debugger")
	rconsolecreate()
end

--#region Initializing core functionality

-- Generates a unique hook ID for hooks with same name
local function GHID()
	HIDN += 1
	return HIDN
end

local function G_Toggle(ToggleName: string): boolean
	if not getgenv().Library then
		repeat
			wait()
		until getgenv().Library
	end

	if not getgenv().Library.Toggles then
		repeat
			wait()
		until getgenv().Library.Toggles
	end

	if not getgenv().Library.Toggles[ToggleName] then
		repeat
			wait()
		until getgenv().Library.Toggles[ToggleName]
	end

	return getgenv().Library.Toggles[ToggleName].Value
end

local function G_Option(OptionName: string): any
	if not getgenv().Library then
		repeat
			wait()
		until getgenv().Library
	end

	if not getgenv().Library.Options then
		repeat
			wait()
		until getgenv().Library.Options
	end

	if not getgenv().Library.Options[OptionName] then
		repeat
			wait()
		until getgenv().Library.Options[OptionName]
	end

	return getgenv().Library.Options[OptionName].Value
end

local function HookSwitch(Hooking: (...any) -> ...any, NoHooking: (...any) -> ...any)
	if HOOKING_ENABLED then
		return Hooking()
	else
		return NoHooking()
	end
end

local function Stringify(Values: { any }): { string }
	local Stringified = {}
	for Index, Value in next, Values do
		table.insert(Stringified, tostring(Value))
	end
	return Stringified
end

local function flen(Table): number
	local Count = 0
	for _ in next, Table do
		Count += 1
	end
	return Count
end

local function dbgprint(...)
	if DEBUGGING then
		-- if USERCONSOLE then
		-- 	rconsoleprint("[DEBUGGING] " .. table.concat(Stringify({ ... }), " "))
		-- else
		print("[DEBUGGING]", ...)
		-- end
	end
end

local function dbgwarn(...)
	if DEBUGGING then
		-- if USERCONSOLE then
		-- rconsolewarn("[DEBUGGING] " .. table.concat(Stringify({ ... }), " "))
		-- else
		warn("[DEBUGGING]", ...)
		-- end
	end
end

local function sprint(...)
	if USERCONSOLE then
		rconsoleprint("[SASWARE] " .. table.concat(Stringify({ ... }), " "))
	else
		dbgprint("[SASWARE]", ...)
	end
end

local function swarn(...)
	if USERCONSOLE then
		rconsolewarn("[SASWARE] " .. table.concat(Stringify({ ... }), " ") .. "\n")
	else
		warn("[SASWARE]", ...)
	end
end

local function ssuccess(...)
	if USERCONSOLE then
		rconsoleinfo("[SASWARE] " .. table.concat(Stringify({ ... }), " ") .. "\n")
	else
		dbgprint("[SASWARE]", ...)
	end
end

local function flen(Table): number
	local Count = 0
	for _ in next, Table do
		Count += 1
	end
	return Count
end

local function mfind(Table, ...): boolean
	local Values = { ... }

	for _, Value in next, Values do
		if not table.find(Table, Value) then
			return false
		end
	end

	return true
end

--#endregion

--#region Checking executor environment

---@diagnostic disable-next-line: undefined-global
if not (hookfunction and hookmetamethod and isexecutorclosure and getgc and debug and restorefunction) then
	HOOKING_ENABLED = false
	swarn("Hooking is disabled due to the executor environment not supporting it.")
end

--#endregion

--#region Cleanup library

local Cleaner = {
	Registry = {},
	AllowedTypes = {
		["RBXScriptConnection"] = true,
		["Instance"] = true,
		["table"] = true,
		["function"] = true,
		["thread"] = true,
	},
	CleanEvent = Instance.new("BindableEvent"),
}

function Cleaner.Register(Object: any)
	if not Cleaner.AllowedTypes[typeof(Object)] then
		swarn("Attempted to register an invalid object type:", typeof(Object))
		return
	end

	if Cleaner.Registry[Object] then
		swarn("Object is already registered for cleanup:", Object)
		return
	end

	Cleaner.Registry[Object] = true

	return {
		Clean = function()
			Cleaner.CleanOne(Object)
		end,
	}
end

function Cleaner.Clean()
	dbgprint("Cleaning up", flen(Cleaner.Registry), "objects.")
	for Object, _ in next, Cleaner.Registry do
		if typeof(Object) == "RBXScriptConnection" then
			Object:Disconnect()
		elseif typeof(Object) == "Instance" then
			Object:Destroy()
		elseif type(Object) == "table" then
			for Index, Value in next, Object do
				Object[Index] = nil
			end
		elseif type(Object) == "function" then
			Object()
		elseif type(Object) == "thread" then
			coroutine.close(Object)
		end

		Cleaner.Registry[Object] = nil
	end
	Cleaner.CleanEvent:Fire()
end

function Cleaner.CleanOne(Object: any)
	if not Cleaner.AllowedTypes[typeof(Object)] then
		swarn("Attempted to clean an invalid object type:", typeof(Object))
		return
	end

	if not Cleaner.Registry[Object] then
		swarn("Object is not registered for cleanup:", Object)
		return
	end

	if typeof(Object) == "RBXScriptConnection" then
		Object:Disconnect()
	elseif typeof(Object) == "Instance" then
		Object:Destroy()
	elseif type(Object) == "table" then
		for Index, Value in next, Object do
			Object[Index] = nil
		end
	elseif type(Object) == "function" then
		Object()
	elseif type(Object) == "thread" then
		coroutine.close(Object)
	end

	Cleaner.Registry[Object] = nil
end

function Cleaner.GetCleanEvent()
	return Cleaner.CleanEvent.Event
end

setmetatable(Cleaner, {
	__call = function(self, Object: any)
		self.Register(Object)
		return Object
	end,
})

--#endregion

--#region Hooking library

local HookMgr = {
	Registry = {},
	GameMT = getrawmetatable(game),
}

HookMgr.RegisterHook = function(
	HookName: string,
	FunctionReference: (...any) -> ...any,
	Hook: (Original: (...any) -> ...any, ...any) -> ...any
): { Original: (...any) -> ...any, Reference: (...any) -> ...any }
	local OriginalFunction: (...any) -> ...any

	if HOOKING_ENABLED then
		local HookKey = "HookMgr_Hook_" .. HookName
		local OriginalKey = "HookMgr_Original_" .. HookName

		shared.HookRegistry = shared.HookRegistry or {}

		-- _G.__HOOK_KEY = HookKey
		-- _G.__ORIGINAL_KEY = OriginalKey

		shared.HookRegistry[HookKey] = Hook

		local Success, Error = pcall(function()
			-- function __HookWrapper(...)
			-- 	return shared.HookRegistry[_G.__HOOK_KEY]( shared.HookRegistry[_G.__ORIGINAL_KEY], ... )
			-- end

			-- dbgprint(`return shared.HookRegistry["{HookKey}"]( shared.HookRegistry["{OriginalKey}"], ... )`)
			-- dbgprint(`return function(...) return shared.HookRegistry["{HookKey}"]( shared.HookRegistry["{OriginalKey}"], ... ) end`)

			OriginalFunction = hookfunction(
				FunctionReference,
				loadstring(
					`return function(...) return shared.HookRegistry["{HookKey}"]( shared.HookRegistry["{OriginalKey}"], ... ) end`
				)()
			)
		end)

		if not Success then
			swarn("Failed to hook function:", HookName, "Error:", Error)
		end

		local RegistryEntry = HookMgr.Registry[HookName]
		if RegistryEntry then
			restorefunction(RegistryEntry.Reference)
			swarn("Hook for function", HookName, "already exists. Overriding.")
		end

		shared.HookRegistry[OriginalKey] = OriginalFunction
	else
		swarn("Hooking is disabled. Skipping hook for function:", HookName)
	end

	HookMgr.Registry[HookName] = {
		Original = OriginalFunction or FunctionReference,
		Reference = FunctionReference,
	}

	return HookMgr.Registry[HookName]
end

HookMgr.UnregisterHook = function(HookName: string)
	if HOOKING_ENABLED then
		local RegistryEntry = HookMgr.Registry[HookName]

		if RegistryEntry then
			local Success, Error = pcall(function()
				restorefunction(RegistryEntry.Reference)
			end)

			if not Success then
				swarn("Failed to unhook function:", HookName, "Error:", Error)
			end
		else
			swarn("Hook for function", HookName, "does not exist.")
		end
	else
		swarn("Hooking is disabled. Skipping unhook for function:", HookName)
	end

	HookMgr.Registry[HookName] = nil
end

HookMgr.ClearHooks = function()
	if HOOKING_ENABLED then
		dbgprint("Clearing", flen(HookMgr.Registry), "hooks.")
		for HookName, RegistryEntry in next, HookMgr.Registry do
			local Success, Error = pcall(function()
				restorefunction(RegistryEntry.Reference)
			end)

			if not Success then
				swarn("Failed to unhook function:", HookName, "Error:", Error)
			end
		end
	else
		swarn("Hooking is disabled. Skipping clearing hooks.")
	end

	HookMgr.Registry = {}
end

--#endregion

--#region ConnectionProxyManager library

local ConnectionProxyMgr = {
	Registry = {},
	Id = 0,
}

function ConnectionProxyMgr._requestId()
	ConnectionProxyMgr.Id += 1
	return ConnectionProxyMgr.Id
end

function ConnectionProxyMgr._newProxyHandler(ConnectionProxy)
	local Id = ConnectionProxyMgr._requestId()

	local Handler = {
		Proxy = ConnectionProxy,
		Enabled = true,
		ClearSignal = Instance.new("BindableEvent"),
	}

	function Handler:Disable()
		self.Enabled = false
		self.Proxy:Disable()
	end

	function Handler:Enable()
		self.Enabled = true
		self.Proxy:Enable()
	end

	Handler.ClearSignal.Event:Once(function()
		pcall(function()
			Handler.Proxy:Enable()
			ConnectionProxyMgr.Registry[Id] = nil
		end)
	end)

	ConnectionProxyMgr.Registry[Id] = Handler

	return Handler
end

function ConnectionProxyMgr:Register(ConnectionProxy)
	return ConnectionProxyMgr._newProxyHandler(ConnectionProxy)
end

function ConnectionProxyMgr:Clear()
	for _, Handler in next, ConnectionProxyMgr.Registry do
		Handler.ClearSignal:Fire()
	end
end

function ConnectionProxyMgr:YieldForConnection(Signal: RBXScriptSignal, SourceNeedle: string, Timeout: number?)
	local Start = os.clock()

	while task.wait() do
		local Connections = getconnections(Signal) :: { any } -- linter thinks it returns connections instead of proxies
		for _, Connection in next, Connections do
			local Function = Connection.Function
			if Function then
				if debug.info(Function, "s"):match(SourceNeedle) then
					return Connection
				end
			end
		end

		if Timeout and os.clock() - Start >= Timeout then
			return nil
		end
	end

	return nil
end
--#endregion

--#region ESP library

local ESP_Library

do
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local Camera = workspace.CurrentCamera
	local CoreGui = game:GetService("CoreGui")

	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		Camera = workspace.CurrentCamera
	end)

	local ESP = {
		Config = {
			UseDisplayName = true,
			Highlights = true,
			Glow = false,
			Arrows = false,
			Tracers = false,
			Enabled = false,
			TeamCheck = false,
			Players = false,
			Boxes = false,
			Text = false,
			BoxType = "2D",
			BoxSize = Vector3.new(4, 6, 2),
			StaticSize = Vector2.new(40, 60),
			BoxColor = Color3.fromRGB(255, 255, 255),
			TextColor = Color3.fromRGB(255, 255, 255),
			TracerColor = Color3.fromRGB(255, 255, 255),
			HighlightFillColor = Color3.fromRGB(255, 145, 20),
			HighlightOutlineColor = Color3.fromRGB(255, 0, 0),
			HighlightFillTransparency = 0.9,
			HighlightOutlineTransparency = 0.5,
			UseTeamColor = false,
			MaxDistance = 500,
			FadeDistance = 100,
		},
		Storage = {
			Highlights = {},
		},
	}

	-- Collection Library
	local Collection = {}
	local RenderQueue = {}

	local function Collect(Item: RBXScriptConnection | thread)
		table.insert(Collection, Item)
	end

	local function Cleanup(Item: any)
		if typeof(Item) == "Instance" then
			Item:Destroy()
			return
		end
		if typeof(Item) == "RBXScriptConnection" then
			Item:Disconnect()
			return
		end
		if type(Item) == "thread" then
			coroutine.close(Item)
			return
		end
		if type(Item) == "table" then
			for Index, Value in pairs(Item) do
				Cleanup(Value)
			end
			table.clear(Item)
			return
		end
		pcall(function()
			Item:Remove()
			return
		end)
	end

	local function Unload()
		for _, Item in next, Collection do
			Cleanup(Item)
		end

		for Index, Box in next, RenderQueue do
			Box:Destroy()
			RenderQueue[Index] = nil
		end
	end

	-- Function Setup

	local function Distance(Position: Vector3)
		return (Position - Camera.CFrame.Position).Magnitude
	end

	local function ToV2(Vector: Vector3): Vector2
		return Vector2.new(Vector.X, Vector.Y)
	end

	local function WTVP(Position: Vector3): (Vector3, boolean)
		return Camera:WorldToViewportPoint(Position)
	end

	local function WTVP2D(Position: Vector3): Vector2
		local ScreenPosition, _ = Camera:WorldToViewportPoint(Position)
		local Vector = ToV2(ScreenPosition)
		return Vector
	end

	local function EnsureInstance(Instance: Instance)
		if not Instance then
			return false
		end
		if Instance.Parent == nil then
			return false
		end
		if not Instance:IsDescendantOf(workspace) then
			return false
		end
		return true
	end

	local function GetPlayer(Character: Model): Player?
		return Players:GetPlayerFromCharacter(Character)
	end

	local function GetColor(Model: Model, Box: any): Color3
		if Box.IsPlayer then
			if ESP.Config.UseTeamColor then
				local Player = GetPlayer(Model)
				if Player then
					return Player.TeamColor.Color
				end
			end
		end

		if Box.DynamicColor then
			return Box.DynamicColor(Model)
		elseif Box.BoxColor then
			return Box.BoxColor
		end

		return ESP.Config.BoxColor
	end

	local function CalculateTransparency(Distance: number): number
		local MaxDistance = ESP.Config.MaxDistance
		local FadeDistance = ESP.Config.FadeDistance

		if Distance >= MaxDistance then
			return 0
		elseif Distance > (MaxDistance - FadeDistance) then
			return 1 - (Distance - (MaxDistance - FadeDistance)) / FadeDistance
		else
			return 1
		end
	end

	local function CreateBox(Root: PVInstance, Config: { any })
		local Box = {
			Root = Root,
			BoxType = ESP.Config.BoxType,
			DynamicColor = nil,
			DrawingObject = nil,
			TextObject = nil,
			Color = nil,
			IsPlayer = false,
		}

		assert(Box.Root.Parent and Box.Root.Parent:IsA("Model"), "Root must be a descendant of a Model")

		if Config then
			for Index, Value in Config do
				Box[Index] = Value
			end
		end

		if Box.IsPlayer then
			Box.Player = GetPlayer(Box.Root.Parent)
		end

		Box.BoxColor = GetColor(Box.Root.Parent, Box)

		function Box:GetPivot(): CFrame
			local Pos, _ = Box.Root.Parent:GetBoundingBox() :: CFrame, Vector3
			return Pos
		end

		local function GetScreen(Model: Model)
			local Pivot = Model:GetPivot()
			local Position = Pivot.Position
			local ScreenPosition, Visible = WTVP(Position)
			return ScreenPosition, Visible
		end

		local function Create2DBox()
			local Drawing = Drawing.new("Quad")
			local DrawingObject = {
				Drawing = Drawing,
			}
			function DrawingObject.Update()
				local Center, Visible = GetScreen(Box.Root.Parent)
				Visible = Visible and ESP.Config.Boxes
				if Visible then
					Drawing.Visible = true
					local ESPSize: Vector2 = ESP.Config.StaticSize
					local Distance = Distance(Box:GetPivot().Position)
					local FieldOfView = Camera.FieldOfView
					if Distance > ESP.Config.MaxDistance then
						Drawing.Visible = false
						return
					end

					Drawing.Transparency = CalculateTransparency(Distance)

					local Size = ESPSize / (Distance / 100) * (FieldOfView / 70)
					local TopLeft = Vector2.new(Center.X - Size.X / 2, Center.Y - Size.Y / 2)
					local TopRight = Vector2.new(Center.X + Size.X / 2, Center.Y - Size.Y / 2)
					local BottomRight = Vector2.new(Center.X + Size.X / 2, Center.Y + Size.Y / 2)
					local BottomLeft = Vector2.new(Center.X - Size.X / 2, Center.Y + Size.Y / 2)
					Drawing.PointA = TopLeft
					Drawing.PointB = TopRight
					Drawing.PointC = BottomRight
					Drawing.PointD = BottomLeft
				else
					Drawing.Visible = false
				end
			end
			return DrawingObject
		end
		local function CreateBox3D()
			local Drawing = Drawing.new("Quad")
			local DrawingObject = {
				Drawing = Drawing,
			}
			function DrawingObject.Update()
				local _, Visible = GetScreen(Box.Root.Parent)
				Visible = Visible and ESP.Config.Boxes
				if Visible then
					Drawing.Visible = true
					local ESPSize = ESP.Config.BoxSize
					local Pivot = Box:GetPivot()
					local Distance = Distance(Pivot.Position)
					if Distance > ESP.Config.MaxDistance then
						Drawing.Visible = false
						return
					end

					Drawing.Transparency = CalculateTransparency(Distance)

					local TopLeft = WTVP2D((Pivot * CFrame.new(ESPSize.X / 2, ESPSize.Y / 2, 0)).Position)
					local TopRight = WTVP2D((Pivot * CFrame.new(-ESPSize.X / 2, ESPSize.Y / 2, 0)).Position)
					local BottomRight = WTVP2D((Pivot * CFrame.new(-ESPSize.X / 2, -ESPSize.Y / 2, 0)).Position)
					local BottomLeft = WTVP2D((Pivot * CFrame.new(ESPSize.X / 2, -ESPSize.Y / 2, 0)).Position)
					Drawing.PointA = TopLeft
					Drawing.PointB = TopRight
					Drawing.PointC = BottomRight
					Drawing.PointD = BottomLeft
				else
					Drawing.Visible = false
				end
			end
			return DrawingObject
		end
		local function CreateBox3DFull()
			local Lines = {}
			local DrawingObject = {
				Drawing = Lines,
			}
			for i = 1, 12 do
				Lines[i] = Drawing.new("Line")
				Lines[i].Thickness = 1
				Lines[i].Transparency = 1
			end
			function DrawingObject.Update()
				local _, Visible = GetScreen(Box.Root.Parent)
				Visible = Visible and ESP.Config.Boxes
				for _, Line in ipairs(Lines) do
					Line.Visible = Visible
				end
				if Visible then
					local ESPSize = ESP.Config.BoxSize
					local Pivot = Box:GetPivot()
					local Distance = Distance(Pivot.Position)
					if Distance > ESP.Config.MaxDistance then
						for _, Line in ipairs(Lines) do
							Line.Visible = false
						end
						return
					end

					local Transparency = CalculateTransparency(Distance)
					for _, Line in ipairs(Lines) do
						Line.Transparency = Transparency
					end

					local sizeX = ESPSize.X / 2
					local sizeY = ESPSize.Y / 2
					local sizeZ = ESPSize.Z / 2
					local Top1 = WTVP2D((Pivot * CFrame.new(-sizeX, sizeY, -sizeZ)).Position)
					local Top2 = WTVP2D((Pivot * CFrame.new(-sizeX, sizeY, sizeZ)).Position)
					local Top3 = WTVP2D((Pivot * CFrame.new(sizeX, sizeY, sizeZ)).Position)
					local Top4 = WTVP2D((Pivot * CFrame.new(sizeX, sizeY, -sizeZ)).Position)
					local Bottom1 = WTVP2D((Pivot * CFrame.new(-sizeX, -sizeY, -sizeZ)).Position)
					local Bottom2 = WTVP2D((Pivot * CFrame.new(-sizeX, -sizeY, sizeZ)).Position)
					local Bottom3 = WTVP2D((Pivot * CFrame.new(sizeX, -sizeY, sizeZ)).Position)
					local Bottom4 = WTVP2D((Pivot * CFrame.new(sizeX, -sizeY, -sizeZ)).Position)
					Lines[1].From, Lines[1].To = Top1, Top2
					Lines[2].From, Lines[2].To = Top2, Top3
					Lines[3].From, Lines[3].To = Top3, Top4
					Lines[4].From, Lines[4].To = Top4, Top1
					Lines[5].From, Lines[5].To = Bottom1, Bottom2
					Lines[6].From, Lines[6].To = Bottom2, Bottom3
					Lines[7].From, Lines[7].To = Bottom3, Bottom4
					Lines[8].From, Lines[8].To = Bottom4, Bottom1
					Lines[9].From, Lines[9].To = Bottom1, Top1
					Lines[10].From, Lines[10].To = Bottom2, Top2
					Lines[11].From, Lines[11].To = Bottom3, Top3
					Lines[12].From, Lines[12].To = Bottom4, Top4

					local BoxColor = GetColor(Box.Root.Parent, Box)
					for _, Line in ipairs(Lines) do
						Line.Color = BoxColor
					end
				end
			end
			function DrawingObject:Remove()
				for _, Line in ipairs(Lines) do
					Line:Remove()
				end
			end
			return DrawingObject
		end
		function Box:Update()
			if not EnsureInstance(self.Root) then
				if self.BoxType == "3DFull" then
					for _, Line in ipairs(self.DrawingObject.Drawing) do
						Line.Visible = false
					end
				else
					self.DrawingObject.Drawing.Visible = false
				end

				if self.TextObject then
					self.TextObject.Visible = false
				end

				return
			end

			if not ESP.Config.Enabled then
				if self.BoxType == "3DFull" then
					for _, Line in ipairs(self.DrawingObject.Drawing) do
						Line.Visible = false
					end
				else
					self.DrawingObject.Drawing.Visible = false
				end

				if self.TextObject then
					self.TextObject.Visible = false
				end

				return
			end

			if self.IsPlayer and not ESP.Config.Players then
				if self.BoxType == "3DFull" then
					for _, Line in ipairs(self.DrawingObject.Drawing) do
						Line.Visible = false
					end
				else
					self.DrawingObject.Drawing.Visible = false
				end

				if self.TextObject then
					self.TextObject.Visible = false
				end

				return
			end

			if self.IsPlayer then
				if ESP.Config.Text then
					if not self.TextObject then
						self.TextObject = Drawing.new("Text")

						if self.TextObject then
							self.TextObject.Size = 16

							if self.Root and self.Root.Parent then
								if ESP.Config.UseDisplayName then
									self.TextObject.Text = self.Player.DisplayName or "Unknown"
								else
									self.TextObject.Text = self.Root.Parent.Name or "Unknown"
								end
							else
								self.TextObject.Text = "Unknown"
							end

							self.TextObject.Center = true
							self.TextObject.Outline = true
						end
					end

					self.TextObject.Color = ESP.Config.TextColor
					local TextPosition = self.Root.Position + Vector3.new(0, 5, 0)
					local ScreenPos, OnScreen = WTVP(TextPosition)
					local Distance = Distance(self.Root.Position)

					if Distance > ESP.Config.MaxDistance then
						self.TextObject.Visible = false
					else
						self.TextObject.Visible = OnScreen and ScreenPos.Z > 0
						self.TextObject.Transparency = CalculateTransparency(Distance)
						self.TextObject.Size = math.max(16 / Distance * 100, 13)
						self.TextObject.Position = Vector2.new(ScreenPos.X, ScreenPos.Y)
					end
				else
					if self.TextObject then
						self.TextObject:Remove()
						self.TextObject = nil
					end
				end
			end

			if self.IsPlayer then
				if self.BoxType ~= ESP.Config.BoxType then
					if self.BoxType == "3DFull" then
						for _, Line in ipairs(self.DrawingObject.Drawing) do
							Line:Remove()
						end
					else
						self.DrawingObject.Drawing:Remove()
					end
					Cleanup(self.DrawingObject)
					self.BoxType = ESP.Config.BoxType
					if Box.BoxType == "2D" then
						Box.DrawingObject = Create2DBox()
					elseif Box.BoxType == "3D" then
						Box.DrawingObject = CreateBox3D()
					elseif Box.BoxType == "3DFull" then
						Box.DrawingObject = CreateBox3DFull()
					else
						error("Invalid BoxType")
					end
				end
			end

			if self.BoxType ~= "3DFull" then
				self.DrawingObject.Drawing.Color = GetColor(self.Root.Parent, self)
			end
			self.DrawingObject.Update()
		end

		local Index = #RenderQueue + 1
		Box.Index = Index
		RenderQueue[Index] = Box

		function Box:Destroy()
			RenderQueue[Index] = nil

			if self.TextObject then
				self.TextObject:Remove()
				self.TextObject = nil
			end
			if self.DrawingObject then
				if self.BoxType == "3DFull" then
					for _, Line in ipairs(self.DrawingObject.Drawing) do
						Line:Remove()
					end
				else
					self.DrawingObject.Drawing:Remove()
				end
			end
		end

		if Box.BoxType == "2D" then
			Box.DrawingObject = Create2DBox()
		elseif Box.BoxType == "3D" then
			Box.DrawingObject = CreateBox3D()
		elseif Box.BoxType == "3DFull" then
			Box.DrawingObject = CreateBox3DFull()
		else
			error("Invalid BoxType")
		end

		return Box
	end

	local function AllocateHighlight(HighlightInstance: Highlight, Player: Player, Character: Model): { any }?
		local HighlightObject = {
			Highlight = HighlightInstance,
			Player = Player,
			Character = Character,
		}

		function HighlightObject:Update()
			if not ESP.Config.Highlights then
				self.Highlight.Enabled = false
				return
			end

			if not EnsureInstance(self.Character) then
				self.Highlight.Enabled = false
				return
			end

			if not ESP.Config.Enabled then
				self.Highlight.Enabled = false
				return
			end

			if ESP.Config.TeamCheck and self.Player.Team == LocalPlayer.Team then
				self.Highlight.Enabled = false
				return
			end

			self.Highlight.Enabled = true

			local TransparencyMultiplier = CalculateTransparency(Distance(self.Character:GetPivot().Position))

			self.Highlight.Adornee = self.Character
			self.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			self.Highlight.FillColor = ESP.Config.HighlightFillColor
			self.Highlight.OutlineColor = ESP.Config.HighlightOutlineColor
			self.Highlight.FillTransparency = ESP.Config.HighlightFillTransparency + (1 - TransparencyMultiplier)
			self.Highlight.OutlineTransparency = ESP.Config.HighlightOutlineTransparency + (1 - TransparencyMultiplier)
		end

		function HighlightObject:Destroy()
			self.Destroyed = true

			if self.Character then
				self.Character = nil
			end

			self.Highlight.FillColor = Color3.fromRGB(255, 0, 0)
			self.Highlight.OutlineColor = Color3.fromRGB(0, 180, 0)
			self.Highlight.FillTransparency = 1
			self.Highlight.OutlineTransparency = 0
			self.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			self.Highlight.Enabled = false
		end

		return HighlightObject
	end

	local function CreateTracer3D(Origin: BasePart, TargetPart: Part)
		local Line = Drawing.new("Line")

		local TracerObject = {
			Line = Line,
			Origin = Origin.Position,
			Target = TargetPart.Position,
		}

		function TracerObject:Update()

			if not ESP.Config.Enabled then
				self.Line.Visible = false
				-- dbgprint("ESP disabled")
				return
			end

			if not ESP.Config.Tracers then
				self.Line.Visible = false
				-- dbgprint("Tracer disabled")
				return
			end

			if TargetPart and EnsureInstance(TargetPart) then
				self.Target = TargetPart.Position
			else
				-- print("Target part is not valid:", TargetPart)
				self.Line.Visible = false
				return
			end

			if Origin and EnsureInstance(Origin) then
				self.Origin = Origin.Position
			else
				-- print("Origin part is not valid:", Origin)
				self.Line.Visible = false
				return
			end

			local Distance = Distance(self.Target)

			if Distance > ESP.Config.MaxDistance then
				self.Line.Visible = false
				return
			end

			local ScreenPos, _ = WTVP(self.Target)

			if ScreenPos.Z < 0 then
				self.Line.Visible = false
				return
			end

			self.Line.Visible = true
			self.Line.Transparency = CalculateTransparency(Distance * 2)
			self.Line.Thickness = math.clamp(5 - Distance / 100, 1, 5)
			self.Line.Color = ESP.Config.TracerColor
			self.Line.From = WTVP2D(self.Origin)
			self.Line.To = WTVP2D(self.Target)
		end

		function TracerObject:Destroy()
			self.Destroyed = true
			self.Line:Remove()
			self.Line = nil
		end

		return TracerObject
	end

	local function CreateESP(Player: Player, Config: { any }): { any }
		dbgprint("Creating ESP for player", Player)
		local Character = Player.Character or Player.CharacterAdded:Wait()
		dbgprint("Character found for player", Player)

		Character.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

		local Box

		-- Create box for ESP visualization
		local Root = Character:WaitForChild("HumanoidRootPart") :: Part
		Box = CreateBox(Root, Config)

		local HighlightObject = AllocateHighlight(Character:WaitForChild("Highlight"), Player, Character)
		table.insert(RenderQueue, HighlightObject)

		local TracerObject = CreateTracer3D(LocalPlayer.Character.HumanoidRootPart, Root)
		table.insert(RenderQueue, TracerObject)

		-- Handle character changes
		Player.CharacterAdded:Connect(function(NewCharacter: Model)
			if NewCharacter ~= Character then
				dbgprint("New character registered for player", Player)
				Character = NewCharacter
				Character.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

				if Box then
					dbgprint("Destroying old box for player", Player)
					Box:Destroy()
					Box = nil
				end

				if HighlightObject then
					dbgprint("Destroying old highlight for player", Player)
					HighlightObject:Destroy()
					HighlightObject = nil
				end

				if TracerObject then
					dbgprint("Destroying old tracer for player", Player)
					TracerObject:Destroy()
					TracerObject = nil
				end

				TracerObject = CreateTracer3D(LocalPlayer.Character.HumanoidRootPart, NewCharacter:WaitForChild("HumanoidRootPart") :: Part)
				HighlightObject = AllocateHighlight(Character:WaitForChild("Highlight"), Player, Character)
				table.insert(RenderQueue, HighlightObject)

				Box = CreateBox(Character:WaitForChild("HumanoidRootPart"), Config)
			end
		end)

		Player.CharacterRemoving:Connect(function()
			if Box then
				dbgprint("Destroying box for player", Player)
				Box:Destroy()
				HighlightObject:Destroy()
				Box = nil
			end
		end)

		dbgprint("ESP registered for player", Player)
		return Box
	end

	local function Update()
		for i, Item in pairs(RenderQueue) do
			if Item.Destroyed then
				dbgprint("Removing item from render queue:", i, Item)
				RenderQueue[i] = nil
				continue
			end

			pcall(function()
				Item:Update()
			end)
		end
	end

	ESP.Config.Enabled = false
	ESP.Config.Players = false
	ESP.Config.Boxes = false

	Collect(RunService.RenderStepped:Connect(Update))

	for _, Player in next, Players:GetPlayers() do
		if Player ~= LocalPlayer then
			dbgprint("Player added [Deferred]:", Player.Name)
			task.spawn(function()
				CreateESP(Player, {
					IsPlayer = true,
					DynamicColor = function(Model: Model)
						local Color = Color3.new(0, 0, 0)
						local Humanoid = Model:FindFirstChildOfClass("Humanoid") :: Humanoid
						local ForceField = Model:FindFirstChild("ForceField") :: ForceField

						if ForceField then
							return Color3.fromRGB(15, 207, 255)
						end

						if Humanoid then
							local Health = Humanoid.Health
							local MaxHealth = Humanoid.MaxHealth

							local HealthPercentage = Health / MaxHealth

							Color = Color3.fromRGB(255 - (255 * HealthPercentage), 255 * HealthPercentage, 0)
						end

						return Color
					end,
				})
			end)
		end
	end

	Collect(Players.PlayerAdded:Connect(function(Player)
		if Player ~= LocalPlayer then
			dbgprint("Player added:", Player.Name)
			CreateESP(Player, {
				IsPlayer = true,
				DynamicColor = function(Model: Model)
					local Color = Color3.new(0, 0, 0)
					local Humanoid = Model:FindFirstChildOfClass("Humanoid") :: Humanoid
					local ForceField = Model:FindFirstChild("ForceField") :: ForceField

					if ForceField then
						return Color3.fromRGB(15, 207, 255)
					end

					if Humanoid then
						local Health = Humanoid.Health
						local MaxHealth = Humanoid.MaxHealth

						local HealthPercentage = Health / MaxHealth

						Color = Color3.fromRGB(255 - (255 * HealthPercentage), 255 * HealthPercentage, 0)
					end

					return Color
				end,
			})
		end
	end))

	ESP.Unload = Unload

	ESP_Library = ESP
end

--#endregion

--#region Aiming library
local Aiming_Library
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Camera = workspace.CurrentCamera

	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		Camera = workspace.CurrentCamera
	end)

	local Aiming = {
		HitChance = 100,
		FOV = 60,
		NPCs = false,
		Players = true,
		Enabled = true,
		ShowFOV = true,
		AimTracer = true,
		DynamicFOV = true,
		FOVColor = Color3.fromRGB(255, 255, 255),
		AimTracerColor = Color3.fromRGB(255, 0, 0),
		CurrentTarget = nil,
	}

	local InternalFOV = Aiming.FOV
	local FOVCircle = Drawing.new("Circle")

	FOVCircle.NumSides = 20
	FOVCircle.Transparency = 1
	FOVCircle.Thickness = 2
	FOVCircle.Color = Aiming.FOVColor
	FOVCircle.Filled = false

	local FOVTracer = Drawing.new("Line")

	FOVTracer.Thickness = 2

	local function UpdateFOV()
		if Aiming.ShowFOV then
			if Aiming.DynamicFOV then
				InternalFOV = Aiming.FOV * (70 / Camera.FieldOfView)
			else
				InternalFOV = Aiming.FOV
			end

			FOVCircle.Visible = true
			FOVCircle.Radius = InternalFOV
			FOVCircle.Color = Aiming.FOVColor
			FOVCircle.Position = UserInputService:GetMouseLocation()
		else
			FOVCircle.Visible = false
		end
	end

	local function GetCharactersInViewport(): { { Character: Model, Position: Vector2 } }
		local ToProcess = {}
		local CharactersOnScreen = {}

		if Aiming.Players then
			for _, Player in ipairs(Players:GetPlayers()) do
				if Player == Players.LocalPlayer then
					continue
				end

				if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
					table.insert(ToProcess, Player.Character)
				end
			end
		end

		if Aiming.NPCs then
			-- for _, NPC in ipairs(workspace.NPCs.Hostile:GetChildren()) do
			--     if NPC:IsA("Model") and NPC:FindFirstChild("HumanoidRootPart") then
			--         table.insert(ToProcess, NPC)
			--     end
			-- end

			for _, NPC in next, game:GetService("CollectionService"):GetTagged("NPC") do
				if
					NPC:IsDescendantOf(workspace)
					and NPC:IsA("Model")
					and NPC:FindFirstChild("HumanoidRootPart")
					and game:GetService("CollectionService"):HasTag(NPC, "ActiveCharacter")
				then
					table.insert(ToProcess, NPC)
				end
			end
		end

		for _, Character in ipairs(ToProcess) do
			local Position, OnScreen = Camera:WorldToViewportPoint(Character.HumanoidRootPart.Position)

			if OnScreen then
				table.insert(CharactersOnScreen, {
					Character = Character,
					Position = Vector2.new(Position.X, Position.Y),
				})
			end
		end

		return CharactersOnScreen
	end

	local function DistanceFromMouse(Position: Vector2): number
		return (UserInputService:GetMouseLocation() - Position).Magnitude
	end

	local function GetPlayersInFOV(): { { Character: Model, Distance: number, Position: Vector2 } }
		local Characters = GetCharactersInViewport()
		local PlayersInFOV = {}

		for _, Character in ipairs(Characters) do
			local Distance = DistanceFromMouse(Character.Position)
			if Distance <= InternalFOV then
				table.insert(PlayersInFOV, {
					Character = Character.Character,
					Distance = Distance,
					Position = Character.Position,
				})
			end
		end

		return PlayersInFOV
	end

	local function GetClosestPlayer(): (Model, number, Vector2)
		local PlayersInFOV = GetPlayersInFOV()
		local ClosestPlayer = nil
		local ClosestDistance = math.huge
		local ClosestPosition = nil

		for _, Player in ipairs(PlayersInFOV) do
			if Player.Distance < ClosestDistance then
				ClosestPlayer = Player.Character
				ClosestPosition = Player.Position
				ClosestDistance = Player.Distance
			end
		end

		return ClosestPlayer, ClosestDistance, ClosestPosition
	end

	local Connection = RunService.RenderStepped:Connect(function()
		if Aiming.Enabled then
			UpdateFOV()
			local ClosestPlayer, Distance, Position = GetClosestPlayer()
			Aiming.CurrentTarget = ClosestPlayer
			if ClosestPlayer then
				FOVTracer.Visible = Aiming.AimTracer
				FOVTracer.From = UserInputService:GetMouseLocation()
				FOVTracer.To = Position
				FOVTracer.Color = Aiming.AimTracerColor
			else
				FOVTracer.Visible = false
			end
		else
			FOVCircle.Visible = false
			FOVTracer.Visible = false
			Aiming.CurrentTarget = nil
		end
	end)

	function Aiming.ShouldMiss()
		local HitChance = Aiming.HitChance / 100
		local RandomValue = math.random(0, 100) / 100
		return RandomValue > HitChance
	end

	local function Unload()
		Connection:Disconnect()
		FOVCircle:Remove()
		FOVTracer:Remove()
	end

	Aiming.Unload = Unload
	Aiming_Library = Aiming
end

--#endregion

--#region Main closure
xpcall(function()
	--#region Enviroment Scanning

	local GameRegistry = {
		consume_stamina = {},
		log_fire = {},
	}

	local Storage = {
		Originals = {},
		Gun_Attributes = {
			{ Name = "Accuracy", Type = "number", Max = 1, Min = 0.2 },
			{ Name = "Automatic", Type = "boolean" },
			{ Name = "FireRate", Type = "number", Max = 5000, Min = 100 },
			{ Name = "Range", Type = "number", Max = 2000, Min = 50 },
			{ Name = "Recoil", Type = "number", Max = 5, Min = 0 },
		},
		Melee_Attributes = {
			{ Name = "ConeAngle", Type = "number", Min = 30, Max = 360 },
			{ Name = "Range", Type = "number", Min = 1, Max = 20 },
			-- {Name = "Speed", Type = "number", Min = 0.1, Max = 5}
		},
		Vehicle_Attributes = {
			{ Name = "acceleration", Type = "number", Min = 5, Max = 100, DisplayName = "Acceleration" },
			{ Name = "forwardMaxSpeed", Type = "number", Min = 5, Max = 120, DisplayName = "Max Speed" },
		},
		Blacklisted_Network_Calls = {
			["replicate_billboard_gui"] = true,
			["replicate_stamina_bar"] = true,
		},
	}

	if HOOKING_ENABLED then
		for _, v in next, getgc(true) do
			if type(v) == "table" then
				pcall(function()
					if rawget(v, "consume_stamina") and type(rawget(v, "consume_stamina")) == "function" then
						swarn("consume_stamina function found @", v)
						table.insert(GameRegistry.consume_stamina, rawget(v, "consume_stamina"))
					end
				end)
			elseif type(v) == "function" and islclosure(v) and (not isexecutorclosure(v)) then
				if not debug.info(v, "s"):match("Gun") then
					continue
				end

				local Constants = debug.getconstants(v)
				if #Constants >= 2 then
					if Constants[1] == "os" and Constants[2] == "clock" then
						if debug.info(v, "n") == "log_fire" then
							swarn("Gun log_fire function found @", v, debug.info(v, "n"))
							table.insert(GameRegistry.log_fire, v)
						end
					end
				end
			end
		end
	else
		swarn("Skipping enviroment scanning due to hooking being disabled.")
	end

	--#endregion

	--#region Game Initialization

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local ProximityPromptService = game:GetService("ProximityPromptService")
	local CollectionService = game:GetService("CollectionService")
	local TweenService = game:GetService("TweenService")
	local LocalPlayer = Players.LocalPlayer
	local LocalUserId = LocalPlayer.UserId
	local Camera = workspace.CurrentCamera
	local Debris = game:GetService("Debris")
	local YieldBind = Instance.new("BindableEvent")

	local Modules = ReplicatedStorage:WaitForChild("Modules")
	local Core = Modules:WaitForChild("Core")
	local Game = Modules:WaitForChild("Game")

	local Net = require(Core:WaitForChild("Net"))
	local Gun = require(Game.ItemTypes:WaitForChild("Gun"))
	local Melee = require(Game.ItemTypes:WaitForChild("Melee"))
	local Crate = require(Game.CrateSystem.Crate)
	local Sprint = require(Game.Sprint)
	local SteakHouseModule = require(Game.Jobs.SteakhouseCook)
	local Char = require(ReplicatedStorage.Modules.Core.Char)

	local RegisteredFirearms = {} -- hoodlumz with they registered firearmz (im losing it)

	local Map = workspace:WaitForChild("Map")
	local Tiles = Map:WaitForChild("Tiles")
	local Vehicles = workspace:WaitForChild("Vehicles")

	Aiming_Library.Enabled = true
	Aiming_Library.FOV = 60
	Aiming_Library.Players = true

	--#endregion

	--#region Defining game-related runtime constants / functions

	local function SetGunFireRate(Gun: Tool)
		local Rate = Gun:GetAttribute("FireRate") :: number
		local Connections = getconnections(Gun.Equipped)
		for _, Connection in next, Connections do
			if Connection.Function and type(Connection.Function) == "function" then
				local Upvalues = debug.getupvalues(Connection.Function)
				if #Upvalues >= 15 then
					print("Gun equipped function found @", Connection.Function)
					local WaitFunction = debug.getupvalue(Connection.Function, 15)
					debug.setupvalue(
						WaitFunction,
						7,
						G_Option("GunMods_FireRate") and (60 / G_Option("GunMods_FireRate")) or (60 / Rate)
					)
				end
			end
		end
	end

	local function HandleCoroutineWithTimeout(Coroutine: thread, Signal: BindableEvent, Timeout: number)
		local Success = false
		local Start = os.clock()
		local Connection = Signal.Event:Once(function()
			Success = true
		end)

		coroutine.resume(Coroutine)

		while not Success do
			if os.clock() - Start >= Timeout then
				break
			end
			task.wait()
		end

		if Connection.Connected then
			Connection:Disconnect()
		end

		return Success
	end

	HookSwitch(function()
		for _, Function in next, GameRegistry.consume_stamina do
			local Sprint_Bar = debug.getupvalue(Function, 2).sprint_bar
			if Sprint_Bar then
				swarn("Sprint bar found @", Sprint_Bar)
			end

			HookMgr.RegisterHook("inf_stamina" .. tostring(Sprint_Bar.update), Sprint_Bar.update, function(Old, ...)
				if G_Toggle("InfiniteStamina") then
					return Old(function()
						return 1
					end)
				else
					return Old(...)
				end
			end)
		end
	end, function()
		Cleaner(LocalPlayer:GetAttributeChangedSignal("StaminaConsumeMultiplier"):Connect(function()
			if G_Toggle("InfiniteStamina") then
				if LocalPlayer:GetAttribute("StaminaConsumeMultiplier") ~= 0 then
					LocalPlayer:SetAttribute("StaminaConsumeMultiplier", 0)
				end
			end
		end))
	end)

	-- for _, Function in next, GameRegistry.log_fire do
	-- 	HookMgr.RegisterHook("log_fire" .. tostring(Function), Function, function(Old, ...)
	-- 		print("Gun log_fire function called with", ...)

	-- 		-- local FireRateUpvalueIdx = 7
	-- 		-- local GunUpvalueIdx = 10

	-- 		-- table.foreach(debug.getupvalues(Function), print)

	-- 		-- if G_Toggle("GunModificationEnabled") then
	-- 		-- 	debug.setupvalue(Old, FireRateUpvalueIdx, G_Option("GunMods_FireRate") / 60)
	-- 		-- else
	-- 		-- 	debug.setupvalue(Old, FireRateUpvalueIdx, debug.getupvalue(Old, GunUpvalueIdx):GetAttribute("FireRate") / 60)
	-- 		-- end

	-- 		return Old(...)
	-- 	end)
	-- end

	local function SignalYield(Signal: RBXScriptSignal, Times: number?, Callback: ((any) -> nil)?)
		if not Times then
			Times = 1
		end

		for _ = 0, Times :: number do
			-- print("Yielding for signal", Signal, "for", Times, "times.")

			if Callback then
				pcall(Callback)
			end

			Signal:Wait()
		end
	end

	local function CharacterAdded(Character: Model)
		local BodyMoverConnection =
			ConnectionProxyMgr:YieldForConnection(Character.DescendantAdded, "PlayerWellbeing", 1)
		dbgprint("BodyMoverConnection:", BodyMoverConnection)
		if BodyMoverConnection then
			ConnectionProxyMgr:Register(BodyMoverConnection):Disable()
		end

		local UpperTorso = Character:WaitForChild("UpperTorso") :: Part

		local NoclipSignal =
			ConnectionProxyMgr:YieldForConnection(UpperTorso:GetPropertyChangedSignal("CanCollide"), "Animate", 1)
		dbgprint("NoclipConnection:", NoclipSignal)
		if NoclipSignal then
			ConnectionProxyMgr:Register(NoclipSignal):Disable()
		end

		Cleaner(RunService.Stepped:Connect(function()
			if G_Toggle("Noclip") then
				for _, Descendant in next, Character:GetDescendants() do
					if Descendant:IsA("BasePart") then
						Descendant.CanCollide = false
					end
				end
			else
				UpperTorso.CanCollide = true
			end
		end))

		Cleaner(Character.ChildAdded:Connect(function(Child: Instance)
			if Child:HasTag("Gun") then
				local Gun = Child :: Tool
				RegisteredFirearms = { Gun }
				SetGunFireRate(Gun)
			end
		end))
	end

	local function AssertCharacter(): Model
		return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	end

	local function WaitForTable(Root: Instance, InstancePath: { string }, Timeout: number?)
		local Instance = Root
		for i, v in pairs(InstancePath) do
			Instance = Instance:WaitForChild(v, Timeout)
		end
		return Instance
	end

	Cleaner(RunService.Heartbeat:Connect(function(DeltaTime)
		local Character = AssertCharacter()
		local Humanoid = Character:FindFirstChildOfClass("Humanoid") :: Humanoid
		local MoveDirection = Humanoid.MoveDirection

		if MoveDirection.Magnitude > 0 then
			local SpeedBoost = G_Option("SpeedBoost")
			if SpeedBoost > 0 then
				Character:TranslateBy(MoveDirection * DeltaTime * SpeedBoost * 2.5)
			end
		end
	end))

	Cleaner(LocalPlayer.CharacterAdded:Connect(CharacterAdded))
	if LocalPlayer.Character then
		CharacterAdded(LocalPlayer.Character)
	end

	HookMgr.RegisterHook("SilentAimHook", Gun.calculate_bullet_direction, function(Old, ...)
		local Target = Aiming_Library.CurrentTarget

		if Target and G_Toggle("SilentAimEnabled") then
			dbgprint("hook stage 1", ...)
			local HitPart: BasePart? = Target:FindFirstChild(G_Option("SilentAimPart"))
				or Target:FindFirstChild("HumanoidRootPart")
			if HitPart then
				if not Aiming_Library.ShouldMiss() then
					dbgprint("hook stage 2", ...)
					local NewDirection = CFrame.new(Camera.CFrame.Position, HitPart.Position).LookVector
					return NewDirection.Unit
				end
			end
		end

		return Old(...)
	end)

	HookMgr.RegisterHook("PrimaryNamecallHook", HookMgr.GameMT.__namecall, function(Old, ...)
		if not checkcaller() then
			local Method = getnamecallmethod()

			if
				(
					G_Toggle("GunModificationEnabled")
					or G_Toggle("MeleeModificationEnabled")
					or G_Toggle("VehicleModificationEnabled")
				) and (Method == "GetAttribute")
			then
				-- dbgprint("GetAttribute called with", ...)

				local Args = { ... }
				local AttributeName = Args[2]

				for _, Attribute in next, Storage.Gun_Attributes do
					if AttributeName == Attribute.Name and Attribute.Type == "number" then
						return G_Option("GunMods_" .. AttributeName)
					elseif AttributeName == Attribute.Name and Attribute.Type == "boolean" then
						return G_Toggle("GunMods_" .. AttributeName)
					end
				end

				for _, Attribute in next, Storage.Melee_Attributes do
					if AttributeName == Attribute.Name and Attribute.Type == "number" then
						return G_Option("MeleeMods_" .. AttributeName)
					end
				end

				for _, Attribute in next, Storage.Vehicle_Attributes do
					if AttributeName == Attribute.Name and Attribute.Type == "number" then
						return G_Option("VehicleMods_" .. AttributeName)
					end
				end
			end
		end

		return Old(...)
	end)

	HookMgr.RegisterHook("SkipCrateAnimationHook", Crate.spin, function(Old, ...)
		if G_Toggle("SkipSpinAnimation") then
			local Args = { ... }
			local Reward = Args[2]

			game:GetService("StarterGui"):SetCore("SendNotification", {
				["Title"] = "Crate Reward",
				["Text"] = Reward.amount .. " " .. Reward.name,
				["Duration"] = 3,
			})

			return
		end
		return Old(...)
	end)

	HookMgr.RegisterHook("WalkspeedHook", Sprint.set_walk_speed, function(Old, ...)
		if G_Toggle("NoSlow") then
			local Args = { ... }
			if Args[1] < 8 then
				return -- nuh uh
			end
		end

		return Old(...)
	end)

	HookMgr.RegisterHook("MeleeHitRegHook", Melee.get_hit_players, function(Old, ...)
		local Args = { ... }
		local Tool = Args[1]
		local Range = LocalPlayer.Character:FindFirstChildOfClass("Tool"):GetAttribute("Range") or 1

		if G_Toggle("MeleeModificationEnabled") then
			Range = G_Option("MeleeMods_Range")
		end

		if G_Toggle("MeleeRemoveConeCheck") then
			local HumanoidRoot = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
			local HRPPosition = HumanoidRoot.Position
			local HitPlayers = {}
			local VisualizerPart

			if G_Toggle("VisualizeMelee") then
				VisualizerPart = Instance.new("Part")
				VisualizerPart.Name = "OutdoorCeiling"
				VisualizerPart.Shape = Enum.PartType.Ball
				VisualizerPart.Size = Vector3.new(Range * 2, Range * 2, Range * 2)
				VisualizerPart.CanCollide = false
				VisualizerPart.CanQuery = false
				VisualizerPart.Anchored = true
				VisualizerPart.Material = Enum.Material.ForceField
				VisualizerPart.Color = Color3.new(1, 0, 0)
				VisualizerPart.Transparency = 0.7
				VisualizerPart.CFrame = HumanoidRoot.CFrame
				VisualizerPart.Parent = workspace

				Debris:AddItem(VisualizerPart, 0.5)
			end

			for Index, Player in next, Players:GetPlayers() do
				if Player ~= LocalPlayer then
					local Character = Player.Character
					if Character then
						local OtherHumanoidRoot = Character:FindFirstChild("HumanoidRootPart")
						local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
						if OtherHumanoidRoot and Humanoid and not Humanoid:GetAttribute("IsDead") then
							if (OtherHumanoidRoot.Position - HRPPosition).magnitude <= Range then
								table.insert(HitPlayers, Player)
							end
						end
					end
				end
			end

			if VisualizerPart and #HitPlayers > 0 then
				VisualizerPart.Color = Color3.new(0, 1, 0)
			end

			return HitPlayers
		end

		return Old(Tool)
	end)

	HookMgr.RegisterHook("NetSendHook", Net.send, function(Old, ...)
		if not checkcaller() then
			local Args = { ... }

			local Call_Type = Args[1]

			if Storage.Blacklisted_Network_Calls[Call_Type] then
				return
			end

			if Call_Type == "melee_attack" and G_Toggle("MeleeFixHitchance") then
				local Hits = Args[3]

				if #Hits > 0 then
					Args[4] = Hits[1].Character:GetPivot()
				end

				local OldPivot = LocalPlayer.Character:GetPivot()
				local OldVelocity = LocalPlayer.Character.HumanoidRootPart.Velocity

				SignalYield(RunService.Heartbeat, 2, function()
					LocalPlayer.Character:PivotTo(Args[4])
					LocalPlayer.Character.HumanoidRootPart.Velocity = OldVelocity
					-- print("Pivoted to", Args[5], os.clock())
				end)

				LocalPlayer.Character:PivotTo(OldPivot)

				return Old(unpack(Args))
			elseif Call_Type == "shoot_gun" and G_Toggle("SilentAimEnabled") then
				local HitPart: BasePart?

				if Aiming_Library.CurrentTarget then
					HitPart = Aiming_Library.CurrentTarget:FindFirstChild(G_Option("SilentAimPart"))
						or Aiming_Library.CurrentTarget:FindFirstChild("HumanoidRootPart")
					if HitPart then
						Args[3] = CFrame.new(Camera.CFrame.Position, HitPart.Position)
					end
				end

				return Old(unpack(Args))
			end
		end

		return Old(...)
	end)

	local UsingPrompt = false

	Cleaner(ProximityPromptService.PromptButtonHoldBegan:Connect(function(Prompt, Player)
		if Player == LocalPlayer then -- redundant? not sure
			UsingPrompt = true
			dbgprint("using prompt")

			if G_Toggle("PromptSkip") then
				local Length = Prompt.HoldDuration
				task.delay(Length * 0.82, function()
					dbgprint("skipping prompt")
					if UsingPrompt then
						dbgprint("chesks passed")
						fireproximityprompt(Prompt)
					end
				end)
			end
		end
	end))

	Cleaner(ProximityPromptService.PromptButtonHoldEnded:Connect(function(Prompt, Player)
		if Player == LocalPlayer then
			dbgprint("not using prompt")
			UsingPrompt = false
		end
	end))

	Cleaner(RunService.PreRender:Connect(function()
		if G_Toggle("Anonymizer") then
			local Character = AssertCharacter()
			local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart") :: Part
			local Name = HumanoidRootPart:WaitForChild("CharacterBillboardGui"):WaitForChild("PlayerName") :: TextLabel
			local Level = Name:WaitForChild("LevelImage"):WaitForChild("LevelText") :: TextLabel

			local String = ""
			for i = 12, 1, -1 do
				String = String .. string.char(math.random(1, 127))
			end
			Name.Text = String

			local LevelText = math.random(10, 99)
			Level.Text = LevelText
		end
	end))

	Cleaner.CleanEvent.Event:Once(function()
		local Character = AssertCharacter()
		local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart") :: Part
		local Name = HumanoidRootPart:WaitForChild("CharacterBillboardGui"):WaitForChild("PlayerName") :: TextLabel
		local Level = Name:WaitForChild("LevelImage"):WaitForChild("LevelText") :: TextLabel

		task.wait(0.1)

		Name.Text = LocalPlayer.Name
		Level.Text = tostring(LocalPlayer:GetAttribute("level")) or "0"
	end)

	local CookFarmRoutine = coroutine.create(function()

		local Fridge = WaitForTable(workspace, {
			"Map",
			"Tiles",
			"ShoppingTile",
			"SteakHouse",
			"Interior",
			"Fridge",
		})

		local FridgePrompt

		for _, Child in next, Fridge:GetChildren() do
			if Child.Name == "Base" and Child:FindFirstChildOfClass("Attachment") then
				FridgePrompt = Child:FindFirstChildOfClass("Attachment"):FindFirstChildOfClass("ProximityPrompt")
			end
		end

		if not FridgePrompt then
			warn("CookFarm: Could not find Fridge ProximityPrompt!")
			return
		end

		local function GetAvailableGrillObject()
			local AvailableGrills = {}
			if SteakHouseModule and SteakHouseModule.grill_class and SteakHouseModule.grill_class.objects then
				for _, GrillObject in pairs(SteakHouseModule.grill_class.objects) do
					if GrillObject.states.user_id_assigned.get() == 0 then
						table.insert(AvailableGrills, GrillObject)
					end
				end
			else
				dbgprint("CookFarm: SteakHouseModule or grill_class not ready yet.")
				return nil
			end

			if #AvailableGrills > 0 then
				if #AvailableGrills == 1 then
					return AvailableGrills[1]
				end

				local Character = AssertCharacter()
				local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
				if not HumanoidRootPart then
					return AvailableGrills[1]
				end

				local PlayerPosition = HumanoidRootPart.Position
				local ClosestGrill = AvailableGrills[1]
				local ClosestDistance = math.huge

				for _, Grill in next, AvailableGrills do
					if Grill.instance then
						local Success, Distance = pcall(function()
							return (Grill.instance:GetPivot().Position - PlayerPosition).Magnitude
						end)

						if Success and Distance and Distance < ClosestDistance then
							ClosestDistance = Distance
							ClosestGrill = Grill
						end
					end
				end

				dbgprint("Found closest grill, distance:", ClosestDistance < math.huge and ClosestDistance or "unknown")
				return ClosestGrill
			end
			return nil
		end

		while task.wait(0.2) do
			if not G_Toggle("CookFarm") then
				continue
			end

			if LocalPlayer:GetAttribute("Job") ~= "steakhouse_cook" then
				dbgprint("CookFarm: Player is not a steakhouse cook. Stopping.")
				task.wait(5)
				continue
			end

			local Success, Error = pcall(function()
				local HeldTool = Char.held_tool.get()
				local HasSteak = HeldTool and HeldTool:GetAttribute("IsCookable") == true

				if not HasSteak then
					dbgprint("Getting steak")
					fireproximityprompt(FridgePrompt)

					local StartTime = os.clock()
					repeat
						task.wait(0.1)
						HeldTool = Char.held_tool.get()
						HasSteak = HeldTool and HeldTool:GetAttribute("IsCookable") == true
						if os.clock() - StartTime > 5 then
							error("Failed to get steak within 5 seconds")
						end
					until HasSteak
					dbgprint("Got steak:", HeldTool and HeldTool.Name or "Unknown")
				else
					dbgprint("Already holding a cookable item:", HeldTool.Name)
				end

				local TargetGrillObject = nil
				local FindStartTime = os.clock()
				repeat
					TargetGrillObject = GetAvailableGrillObject()
					if TargetGrillObject then
						break
					end
					dbgprint("Waiting for an available grill...")
					task.wait(0.5)
					if os.clock() - FindStartTime > 15 then
						error("Could not find an available grill within 15 seconds")
					end
				until TargetGrillObject

				if not TargetGrillObject or not TargetGrillObject.instance then
					error("Failed to get a valid grill object or instance")
				end

				local SelectedGrillHighlight = Instance.new("Highlight", TargetGrillObject.instance)
				SelectedGrillHighlight.FillColor = Color3.fromRGB(255, 255, 0)
				SelectedGrillHighlight.OutlineColor = Color3.fromRGB(255, 255, 0)
				Debris:AddItem(SelectedGrillHighlight, 5)
				TweenService:Create(SelectedGrillHighlight, TweenInfo.new(3), { FillTransparency = 1}):Play()
				TweenService:Create(SelectedGrillHighlight, TweenInfo.new(5), { OutlineTransparency = 1}):Play()

				local GrillInstance = TargetGrillObject.instance
				dbgprint("Found available grill:", GrillInstance.Name)

				dbgprint("Starting grill process for:", GrillInstance.Name)
				Net.send("start_grilling", GrillInstance)

				local PerfectTime = 0
				local WaitStartTime = os.clock()
				dbgprint("Waiting for grill state updates...")
				repeat
					task.wait(0.1)

					if TargetGrillObject.states.user_id_assigned.get() == LocalUserId then
						PerfectTime = TargetGrillObject.states.perfect_cook_time.get()
						dbgprint("Grill assigned, Perfect Time:", PerfectTime)
						pcall(function()
							SelectedGrillHighlight.FillColor = Color3.fromRGB(0, 255, 0)
							SelectedGrillHighlight.OutlineColor = Color3.fromRGB(0, 255, 0)
						end)
					end

					if os.clock() - WaitStartTime > 10 then
						LocalPlayer.Character.Humanoid:UnequipTools()
						error(
							"Grill state did not update (assignment/time) within 10 seconds (this is bad contact sashaa)"
						)
					end
				until PerfectTime > 0

				dbgprint("Grill assigned to user. PerfectTime:", PerfectTime)

				local CookTime = PerfectTime - 0.2
				if CookTime < 0.1 then
					CookTime = 0.1
				end

				print("Calculated CookTime:", CookTime, "(Perfect:", PerfectTime, ")")
				dbgprint("Waiting for cook duration:", CookTime)
				task.wait(CookTime)

				dbgprint("Finishing grill:", GrillInstance.Name)
				Net.send("finish_grilling", GrillInstance, "Perfect")

				dbgprint("Cooked steak successfully on", GrillInstance.Name)
			end)

			if not Success then
				warn("CookFarm Error: ", Error)
				LocalPlayer.Character.Humanoid:UnequipTools()
				task.wait(2)
			end
		end
	end)

	Cleaner(CookFarmRoutine)
	coroutine.resume(CookFarmRoutine)

	--#endregion

	--#region UI Initialization

	local Repository = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
	local Library = loadstring(game:HttpGet(Repository .. "Library.lua"))()
	local ThemeManager = loadstring(game:HttpGet(Repository .. "addons/ThemeManager.lua"))()
	local SaveManager = loadstring(game:HttpGet(Repository .. "addons/SaveManager.lua"))()

	Library.RiskColor = Color3.new(0.960784, 0.592157, 0.376471)

	-- Library.Scheme = {
	-- 	BackgroundColor = Color3.fromRGB(14, 4, 20),
	-- 	MainColor = Color3.fromRGB(26, 15, 36),
	-- 	AccentColor = Color3.fromRGB(116, 61, 180),
	-- 	OutlineColor = Color3.fromRGB(41, 28, 45),
	-- 	FontColor = Color3.new(1, 1, 1),
	-- 	Font = Font.fromEnum(Enum.Font.BuilderSans),
	-- }

	Cleaner.GetCleanEvent():Connect(function()
		Library:Unload()
		ESP_Library.Unload()
	end)

	local Window = Library:CreateWindow({
		Title = "sasware blockspin",
		Center = true,
		AutoShow = true,
		Footer = "Version: " .. Version .. " | " .. SubVersion,
	})

	local Tabs = {
		Main = Window:AddTab("Main"),
		Automation = Window:AddTab("Automation"),
		Combat = Window:AddTab("Combat"),
		Visuals = Window:AddTab("Visuals"),
		UISettings = Window:AddTab("UI Settings"),
	}

	-- Main tab

	local UtilitiesGroup = Tabs.Main:AddLeftGroupbox("Utilities")

	UtilitiesGroup:AddToggle("Anonymizer", {
		Text = "Anonymize",
		Default = false,
		Tooltip = "Hides your name from the game",
		Callback = function(Value)
			if not Value then
				local Character = AssertCharacter()
				local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart") :: Part
				local Name =
					HumanoidRootPart:WaitForChild("CharacterBillboardGui"):WaitForChild("PlayerName") :: TextLabel
				local Level = Name:WaitForChild("LevelImage"):WaitForChild("LevelText") :: TextLabel

				Name.Text = LocalPlayer.Name
				Level.Text = tostring(LocalPlayer:GetAttribute("level"))
			end
		end,
	})

	UtilitiesGroup:AddToggle("SkipSpinAnimation", {
		Text = "Skip Spin Animation",
		Default = false,
		Tooltip = "Skips the crate spin animation",
	})

	UtilitiesGroup:AddToggle("PromptSkip", {
		Text = "Faster Prompts",
		Default = false,
		Tooltip = "Makes prompts slightly faster.",
	})

	local CharacterGroup = Tabs.Main:AddRightGroupbox("Character")

	CharacterGroup:AddToggle("Noclip", {
		Text = "Noclip",
		Default = false,
		Tooltip = "Enables noclip for the player",
	})

	CharacterGroup:AddToggle("NoSlow", {
		Text = "No Slowdown",
		Default = false,
		Tooltip = "Disables slowdowns",
	})

	CharacterGroup:AddToggle("InfiniteStamina", {
		Text = "Infinite Stamina",
		Default = false,
		Tooltip = "Disables stamina consumption",
		Callback = function(Value)
			if not HOOKING_ENABLED then
				if Value then
					LocalPlayer:SetAttribute("StaminaConsumeMultiplier", 0)
				else
					LocalPlayer:SetAttribute("StaminaConsumeMultiplier", nil)
				end
			end
		end,
	})

	CharacterGroup:AddSlider("SpeedBoost", {
		Text = "Speed Boost",
		Default = 0,
		Min = 0,
		Max = 2,
		Rounding = 1,
		Tooltip = "Sets the player speed",
	})

	local VulnerabilitiesGroup = Tabs.Main:AddLeftGroupbox("Vulnerabilities")

	VulnerabilitiesGroup:AddLabel("patched :(")

	local VehicleModificationsGroup = Tabs.Main:AddRightGroupbox("Vehicle Mods")

	VehicleModificationsGroup:AddToggle("VehicleModificationEnabled", {
		Text = "Enabled",
		Default = false,
		Tooltip = "Enables vehicle modification features",
	})

	for _, Attribute in next, Storage.Vehicle_Attributes do
		if Attribute.Type == "number" then
			VehicleModificationsGroup:AddSlider("VehicleMods_" .. Attribute.Name, {
				Text = Attribute.DisplayName,
				Default = Attribute.Min,
				Min = Attribute.Min,
				Max = Attribute.Max,
				Rounding = 2,
				Tooltip = "Sets the " .. Attribute.Name .. " for vehicles",
				Callback = function(Value)
					for _, Vehicle in next, Vehicles:GetChildren() do
						if Vehicle:GetAttribute("OwnerUserId") == LocalUserId then
							Vehicle.Motors:SetAttribute(Attribute.Name, Value)
						end
					end
				end,
			})
		end
	end

	-- Automation tab

	local AutomationGroup = Tabs.Automation:AddRightGroupbox("Automation")

	AutomationGroup:AddToggle("CookFarm", {
		Text = "Cook Farm",
		Default = false,
		Tooltip = "Automatically cooks food",
	})

	AutomationGroup:AddLabel("YOU MUST BE STANDING NEAR FRIDGE AND ON THE JOB TO WORK", true)

	-- Combat tab

	local GunModificationsGroup = Tabs.Combat:AddRightGroupbox("Gun Mods")

	local CurrentGun = GunModificationsGroup:AddLabel("Current: None")

	GunModificationsGroup:AddToggle("GunModificationEnabled", {
		Text = "Enabled",
		Default = false,
		Tooltip = "Enables gun modification features",
	})

	for _, Attribute in next, Storage.Gun_Attributes do
		if Attribute.Type == "number" then
			GunModificationsGroup:AddSlider("GunMods_" .. Attribute.Name, {
				Text = Attribute.Name,
				Default = Attribute.Min,
				Min = Attribute.Min,
				Max = Attribute.Max,
				Rounding = 2,
				Tooltip = "Sets the " .. Attribute.Name .. " for guns",
			})
		elseif Attribute.Type == "boolean" then
			GunModificationsGroup:AddToggle("GunMods_" .. Attribute.Name, {
				Text = Attribute.Name,
				Default = false,
				Tooltip = "Enables " .. Attribute.Name .. " for guns",
			})
		end
	end

	Library.Options.GunMods_FireRate:OnChanged(function(Value) -- im too lazy to make a better system for this
		if RegisteredFirearms[1] then
			SetGunFireRate(RegisteredFirearms[1])
		end
	end)

	local MeleeModificationsGroup = Tabs.Combat:AddLeftGroupbox("Melee Mods")

	MeleeModificationsGroup:AddToggle("MeleeFixHitchance", {
		Text = "HitSync",
		Default = false,
		Tooltip = "game has bad hitreg so probably use this",
	})

	MeleeModificationsGroup:AddToggle("MeleeRemoveConeCheck", {
		Text = "Radius-Only HitReg",
		Default = false,
		Tooltip = "Removes the cone check for melee weapons",
	})

	MeleeModificationsGroup:AddToggle("VisualizeMelee", {
		Text = "Visualize Melee",
		Default = false,
		Tooltip = "Shows melee radius.",
	})

	MeleeModificationsGroup:AddToggle("MeleeModificationEnabled", {
		Text = "Enabled",
		Default = false,
		Tooltip = "Enables melee modification features",
	})

	for _, Attribute in next, Storage.Melee_Attributes do
		MeleeModificationsGroup:AddSlider("MeleeMods_" .. Attribute.Name, {
			Text = Attribute.Name,
			Default = Attribute.Min,
			Min = Attribute.Min,
			Max = Attribute.Max,
			Rounding = 2,
			Tooltip = "Sets the " .. Attribute.Name .. " for melee weapons",
		})
	end

	local SilentAimGroup = Tabs.Combat:AddLeftGroupbox("Silent Aim")

	SilentAimGroup:AddToggle("SilentAimEnabled", {
		Text = "Enabled",
		Default = false,
		Tooltip = "Enables silent aim features",
		Callback = function(Value)
			if Value then
				Aiming_Library.Enabled = true
			else
				Aiming_Library.Enabled = false
			end
		end,
	})

	SilentAimGroup:AddSlider("SilentAimHitChance", {
		Text = "Hit Chance",
		Default = 100,
		Min = 0,
		Max = 100,
		Rounding = 0,
		Tooltip = "Sets the hit chance for silent aim",
		Callback = function(Value)
			Aiming_Library.HitChance = Value
		end,
	})

	SilentAimGroup:AddSlider("SilentAimFOV", {
		Text = "FOV",
		Default = 60,
		Min = 0,
		Max = 360,
		Rounding = 0,
		Tooltip = "Sets the field of view for silent aim",
		Callback = function(Value)
			Aiming_Library.FOV = Value
		end,
	})

	SilentAimGroup:AddDropdown("SilentAimPart", {
		Text = "Part",
		Default = "UpperTorso",
		Values = { "HumanoidRootPart", "UpperTorso", "Head" },
		Tooltip = "Sets the part to aim at",
	})

	-- Visuals tab

	local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP")

	ESPGroup:AddToggle("ESPEnabled", {
		Text = "Enabled",
		Default = false,
		Tooltip = "Enables ESP features",
		Callback = function(Value)
			ESP_Library.Config.Enabled = Value
		end,
	})

	ESPGroup:AddSlider("ESPRange", {
		Text = "Range",
		Default = 500,
		Min = 0,
		Max = 1500,
		Rounding = 0,
		Tooltip = "Sets the maximum distance for ESP",
		Callback = function(Value)
			ESP_Library.Config.MaxDistance = Value
		end,
	})

	ESPGroup:AddSlider("ESPFade", {
		Text = "Fade",
		Default = 100,
		Min = 0,
		Max = 500,
		Rounding = 0,
		Tooltip = "Sets the fade distance for ESP",
		Callback = function(Value)
			ESP_Library.Config.FadeDistance = Value
		end,
	})

	ESPGroup:AddToggle("ESPPlayers", {
		Text = "Players",
		Default = false,
		Tooltip = "Shows ESP for players",
		Callback = function(Value)
			ESP_Library.Config.Players = Value
		end,
	})

	ESPGroup:AddToggle("ESPBoxes", {
		Text = "Boxes",
		Default = false,
		Tooltip = "Shows boxes around players",
		Callback = function(Value)
			ESP_Library.Config.Boxes = Value
		end,
	})

	ESPGroup:AddDropdown("BoxType", {
		Text = "Box Type",
		Default = "2D",
		Values = { "3DFull", "3D", "2D" },
		Tooltip = "Sets the box type for ESP",
		Callback = function(Value)
			ESP_Library.Config.BoxType = Value
		end,
	})

	ESPGroup:AddToggle("ESPTracers", {
		Text = "Tracers",
		Default = false,
		Tooltip = "Shows tracers to players",
		Callback = function(Value)
			ESP_Library.Config.Tracers = Value
		end,
	}):AddColorPicker("TracerColor", {
		Default = Color3.new(1, 1, 1),
		Title = "Tracer Color",
		Transparency = nil,
		Callback = function(Value)
			ESP_Library.Config.TracerColor = Value
		end,
	})

	ESPGroup:AddToggle("ESPHighlight", {
		Text = "Highlight",
		Default = true,
		Tooltip = "Highlights players",
		Callback = function(Value)
			ESP_Library.Config.Highlights = Value
		end,
	})
		:AddColorPicker("HighlightColor", {
			Default = Color3.new(1.000000, 0.568627, 0.000000),
			Title = "Highlight Fill Color",
			Transparency = nil,
			Callback = function(Value)
				ESP_Library.Config.HighlightFillColor = Value
			end,
		})
		:AddColorPicker("HighlightOutlineColor", {
			Default = Color3.new(1.000000, 0.427451, 0.282353),
			Title = "Highlight Outline Color",
			Transparency = nil,
			Callback = function(Value)
				ESP_Library.Config.HighlightOutlineColor = Value
			end,
		})

	ESPGroup:AddSlider("HighlightFillTransparency", {
		Text = "Highlight Fill Transparency",
		Default = 0.8,
		Min = 0,
		Max = 1,
		Rounding = 2,
		Tooltip = "Sets the fill transparency for highlights",
		Callback = function(Value)
			ESP_Library.Config.HighlightFillTransparency = Value
		end,
	})

	ESPGroup:AddSlider("HighlightOutlineTransparency", {
		Text = "Highlight Outline Transparency",
		Default = 0.5,
		Min = 0,
		Max = 1,
		Rounding = 2,
		Tooltip = "Sets the outline transparency for highlights",
		Callback = function(Value)
			ESP_Library.Config.HighlightOutlineTransparency = Value
		end,
	})

	ESPGroup:AddToggle("ESPText", {
		Text = "Text",
		Default = false,
		Tooltip = "Shows text labels for ESP",
		Callback = function(Value)
			ESP_Library.Config.Text = Value
		end,
	}):AddColorPicker("TextColor", {
		Default = Color3.new(1, 1, 1),
		Title = "Text Color",
		Transparency = nil,

		Callback = function(Value)
			ESP_Library.Config.TextColor = Value
		end,
	})

	local MenuGroup = Tabs.UISettings:AddLeftGroupbox("Menu")

	MenuGroup:AddButton("Unload", function()
		sprint("Cleaning up.")
		HookMgr.ClearHooks()
		Cleaner.Clean()
		ConnectionProxyMgr:Clear()
		ESP_Library.Unload()
		Aiming_Library.Unload()
		rconsoledestroy()
	end)

	-- Cleaner(RunService.RenderStepped:Connect(function()
	-- 	Library:SetWatermark("Current connections: " .. flen(Cleaner.Registry))
	-- end))

	-- MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu keybind" })

	-- Library.ToggleKeybind = Options.MenuKeybind

	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)

	SaveManager:IgnoreThemeSettings()

	SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

	ThemeManager:SetFolder("sasware_blockspin")
	SaveManager:SetFolder("sasware_blockspin/main")

	SaveManager:BuildConfigSection(Tabs.UISettings)
	ThemeManager:ApplyToTab(Tabs.UISettings)

	SaveManager:LoadAutoloadConfig()

	Cleaner(LocalPlayer.CharacterAdded:Connect(function(Character)
		Cleaner(Character.ChildAdded:Connect(function(Child)
			if CollectionService:HasTag(Child, "Gun") then
				CurrentGun:SetText("Current: " .. Child.Name)
			end
		end))
		Cleaner(Character.ChildRemoved:Connect(function(Child)
			if CollectionService:HasTag(Child, "Gun") then
				CurrentGun:SetText("Current: None")
			end
		end))
	end))

	if LocalPlayer.Character then
		Cleaner(LocalPlayer.Character.ChildAdded:Connect(function(Child)
			dbgprint(Child, "added")
			if CollectionService:HasTag(Child, "Gun") then
				CurrentGun:SetText("Current: " .. Child.Name)
			end
		end))
		Cleaner(LocalPlayer.Character.ChildRemoved:Connect(function(Child)
			dbgprint(Child, "removed")
			if CollectionService:HasTag(Child, "Gun") then
				CurrentGun:SetText("Current: None")
			end
		end))
	end

	--#endregion
end, function(Error)
	warn("An error occurred during execution:", Error)
	dbgprint(debug.traceback())
end)

--#endregion

-- task.delay(30, function()
-- 	if Success then
-- 		sprint("Cleaning up.")
-- 		task.wait(3)
-- 		HookMgr.ClearHooks()
-- 		Cleaner.Clean()
-- 		rconsoledestroy()
-- 	end
-- end)
