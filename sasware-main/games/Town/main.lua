local function Stringify(Values : {any}) : {string}
	local Stringified = {}
	for Index, Value in next, Values do
		table.insert(Stringified, tostring(Value))
	end
	return Stringified
end


local fprint = print
local fwarn = warn

pcall(function()

	rconsolecreate()

	if rconsoleprint then
		fprint = function(...)
			rconsoleprint('PCV3: ' .. table.concat(Stringify({...}), ' '))
		end
		fwarn = function(...)
			rconsolewarn('PCV3: ' .. table.concat(Stringify({...}), ' '))
		end
	end

end)

local Compression = loadstring(game:HttpGet("https://raw.githubusercontent.com/centerepic/PCV3/refs/heads/main/Compression.lua"))()
local Region = loadstring(game:HttpGet("https://github.com/centerepic/PCV3/raw/refs/heads/main/Region.lua"))()

--#region Adonis Bypasses

-- if hookfunction then
-- 	local Success = pcall(function()
-- 		local LogService = game:GetService("LogService")
-- 		local Offset = math.random(1, workspace.DistributedGameTime)
-- 		local OldGetLogHistory; OldGetLogHistory = hookfunction(LogService.GetLogHistory, function(...)
-- 			if checkcaller() then return OldGetLogHistory(...) end

-- 			local Success, _ = pcall(OldGetLogHistory, ...)

-- 			if not Success then
-- 				-- fprint("Check averted.")
-- 				-- fprint(Error, ...)
-- 				return OldGetLogHistory(...)
-- 			end

-- 			return {
-- 				{
-- 					message = "JointsService is deprecated, but an instance was added to JointsService: JointsService.Weld",
-- 					messageType = Enum.MessageType.MessageWarning,
-- 					timeStamp = workspace.DistributedGameTime - Offset
-- 				}
-- 			}
-- 		end)
-- 	end)
-- 	if not Success then
-- 		fwarn("Failed to load ChecksCashed")
-- 	else
-- 		fwarn("Loaded ChecksCashed")
-- 	end
-- end

--#endregion

--#region Constants

local game = game :: DataModel -- FAAAAAAAAAAAA YOUUUUUUUUUUUUUUU
local CallQueueFlushRate = 1 / 20
local MaxPartsPerCloneCall = 499
local MaxPartsPerMoveCall = 50000
local MaxPartsPerColorCall = 50000
local MaxPartsPerMaterialCall = 50000
local MaxPartsPerResizeCall = 50000
local IgnoreEmptyGroups = true

-- FakePart is a client-side part that is used to replicate part properties to the server
-- It is identical to BasePart type and inherits from it
type FakeBasePart = BasePart

-- Initialize services

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

--#endregion

--#region Game dependencies

local LocalPlayer = Players.LocalPlayer
local BuildingAreas = workspace:WaitForChild("Private Building Areas") :: Folder

--#endregion

-- Initialize globals

local DefaultPartSize = Vector3.new(4, 1, 2)
local CallQueue = {}
local SelectingPlot = false
local Options = {
	SkipNonWiringGroups = true,
	Decoration = true
}
local State = {
	CurrentPlot = nil,
	StateText = "Idle",
	PlotInformation = {
		Parts = 0,
		Meshes = 0,
		Lights = 0,
		Groups = 0,
		Owner = "None"
	}
}

--#region Functions

local function SelectPlot() : Part
	SelectingPlot = true

	local Camera = workspace.CurrentCamera
	LocalPlayer.CameraMaxZoomDistance = 10000
	local CameraPart = Instance.new("Part")
	CameraPart.Transparency = 1
	CameraPart.Anchored = true
	CameraPart.Parent = workspace

	local Plots = BuildingAreas:GetChildren()
	local CurrentPlotsIndex = 1

	Camera.CameraSubject = CameraPart

	local SelectedPlot = nil

	CameraPart.Position = Plots[CurrentPlotsIndex].Position + Vector3.new(0, 50, 0)

	local KeyboardConnection
	KeyboardConnection = UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Q then
			CurrentPlotsIndex = CurrentPlotsIndex - 1
			if CurrentPlotsIndex == 0 then
				CurrentPlotsIndex = #Plots
			end
			CameraPart.Position = Plots[CurrentPlotsIndex].Position + Vector3.new(0, 50, 0)
		elseif input.KeyCode == Enum.KeyCode.E then
			CurrentPlotsIndex = CurrentPlotsIndex + 1
			if CurrentPlotsIndex > #Plots then
				CurrentPlotsIndex = 1
			end
			CameraPart.Position = Plots[CurrentPlotsIndex].Position + Vector3.new(0, 50, 0)
		elseif input.KeyCode == Enum.KeyCode.Return then
			KeyboardConnection:Disconnect()
			Camera.CameraType = Enum.CameraType.Custom
			Camera.CameraSubject = LocalPlayer.Character.Humanoid
			SelectingPlot = false
			LocalPlayer.CameraMaxZoomDistance = 400
			SelectedPlot = Plots[CurrentPlotsIndex]
		end
	end)

	repeat
		task.wait()
	until not SelectingPlot

	CameraPart:Destroy()
	KeyboardConnection:Disconnect()

	return SelectedPlot
end

function State.QueryPlotInformation(PlotCache : Part)
	local Parts = 0
	local Meshes = 0
	local Lights = 0
	local Groups = 0

	for _, Child in next, PlotCache:GetDescendants() do
		if Child:IsA("Model") then
			Groups += 1
		elseif Child:IsA("BasePart") then
			Parts += 1
		elseif Child:IsA("Light") then
			Lights += 1
		elseif Child:IsA("SpecialMesh") then
			Meshes += 1
		end
	end

	return {
		Parts = Parts,
		Meshes = Meshes,
		Lights = Lights,
		Groups = Groups,
		Owner = PlotCache.Name:gsub("BuildArea", "")
	}
end

local Utility = {}

function Utility.ShuffleTable(Table: { any })
	for i = #Table, 2, -1 do
		local j = math.random(i)
		Table[i], Table[j] = Table[j], Table[i]
	end
end

function Utility:GetCharacter(): Model
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

function Utility:GetSyncEndpoint(): RemoteFunction
	local Character = self:GetCharacter()
	local BuildingTools = Character:WaitForChild("Building Tools") :: Tool
	local SyncAPI = BuildingTools:WaitForChild("SyncAPI") :: BindableFunction
	local ServerEndpoint = SyncAPI:WaitForChild("ServerEndpoint") :: RemoteFunction

	return ServerEndpoint
end

function Utility:GetPlot(Target: (Player | string)?): Part?
	if Target and (typeof(Target) ~= "string") then
		if Target:IsA("Player") then
			Target = Target.Name
		end
	else
		Target = LocalPlayer.Name -- Default to LocalPlayer
	end

	return BuildingAreas:FindFirstChild(Target :: string .. "BuildArea") :: Part?
end

function Utility.EnsureReturn(Target: (...any) -> ...any, ...)
	local Result = Target(...)

	while not Result do
		Result = Target(...)
	end

	return Result
end

function Utility.GetDepthFromAncestor(Item: Instance, Ancestor: Instance): number
	local Origin = Item.Parent

	if Item.Parent == nil then
		fwarn("Item has no parent")
		return 9999
	end

	local Depth = 0

	while Item ~= Ancestor do
		if Item == nil then
			fwarn("Item is not a descendant of Ancestor", Origin, Ancestor)
			return 9999
		end

		if Item.Parent == nil then
			fwarn("Item has no parent")
			return 9999
		end

		Depth = Depth + 1
		Item = Item.Parent
	end

	-- Return depth
	return Depth
end

function Utility.IsCooling() : boolean
	return LocalPlayer:FindFirstChild("BuildCooling")
end

--#endregion

--#region Queue

local Queue = {}

function Queue:EnqueueAsync(CallType: string, Arguments: { any })
	table.insert(CallQueue, { nil, CallType, Arguments })
end

function Queue:Enqueue(CallType: string, Arguments: { any })
	local Callback = Instance.new("BindableEvent")
	table.insert(CallQueue, { Callback, CallType, Arguments })
	return Callback.Event:Wait()
end

function Queue:EnqueueNoRet(CallType: string, Arguments: { any })
	local Callback = Instance.new("BindableEvent")
	Callback.Name = "NoRet"
	table.insert(CallQueue, { Callback, CallType, Arguments })
	return Callback.Event:Wait()
end

function Queue:Step()
	if #CallQueue == 0 then
		return
	end

	local SyncEndpoint = Utility:GetSyncEndpoint() :: RemoteFunction

	if SyncEndpoint then
		local Call = table.remove(CallQueue, 1)

		if Call then
			local Callback: BindableEvent, CallType: string, Arguments: { any } = unpack(Call)
			
			local NoRet = ((not Callback) or Callback.Name == "NoRet")

			local Ret
			local Success
			local Error

			repeat task.wait() until not Utility.IsCooling()

			repeat
				Success, Error = pcall(function()
					if NoRet then
						SyncEndpoint:InvokeServer(CallType, unpack(Arguments))
					else
						Ret = {SyncEndpoint:InvokeServer(CallType, unpack(Arguments))}
					end
				end)
				if not Success then
					fwarn("Failed to invoke server, retrying...", Error)
					task.wait(1)
				end
			until Success and ((Ret and type(Ret) == "table") or NoRet)

			if Callback then
				if NoRet then
					Callback:Fire()
				else
					Callback:Fire(unpack(Ret))
				end
			end
		end
	end
end

--#endregion

--#region Serializer

local Serializer = {}

do
	local TypeSerializer = {}

	do
		TypeSerializer.Serializers = {
			["Vector3"] = function(Value)
				return { Type = "Vector3", Data = { Value.X, Value.Y, Value.Z } }
			end,
			["Color3"] = function(Value)
				return { Type = "Color3", Data = { Value.R, Value.G, Value.B } }
			end,
			["CFrame"] = function(Value)
				local Components = { Value:components() }
				local Data = {}
				for i = 1, 12 do
					table.insert(Data, Components[i])
				end
				return { Type = "CFrame", Data = Data }
			end,
		}

		TypeSerializer.Deserializers = {
			["Vector3"] = function(VecData)
				return Vector3.new(VecData[1], VecData[2], VecData[3])
			end,
			["Color3"] = function(ColData)
				return Color3.new(ColData[1], ColData[2], ColData[3])
			end,
			["CFrame"] = function(CFData)
				return CFrame.new(unpack(CFData))
			end,
		}
	end

	local ClassProperties = {
		["Part"] = {
			"Anchored",
			"CanCollide",
			"CFrame",
			"Color",
			"Material",
			"Shape",
			"Size",
			"Transparency",
		},
		["Seat"] = {
			"Anchored",
			"CanCollide",
			"CFrame",
			"Color",
			"Material",
			"Size",
			"Transparency",
		},
		["VehicleSeat"] = {
			"Anchored",
			"CanCollide",
			"CFrame",
			"Color",
			"Material",
			"Size",
			"Transparency",
		},
		["CornerWedgePart"] = {
			"Anchored",
			"CanCollide",
			"CFrame",
			"Color",
			"Material",
			"Size",
			"Transparency",
		},
		["WedgePart"] = {
			"Anchored",
			"CanCollide",
			"CFrame",
			"Color",
			"Material",
			"Size",
			"Transparency",
		},
		["TrussPart"] = {
			"Anchored",
			"CanCollide",
			"CFrame",
			"Color",
			"Material",
			"Size",
			"Transparency",
		},
		["PointLight"] = {
			"Color",
			"Range",
			"Brightness",
			"Shadows"
		},
		["SpotLight"] = {
			"Color",
			"Range",
			"Brightness",
			"Face",
			"Angle",
			"Shadows"
		},
		["SurfaceLight"] = {
			"Color",
			"Range",
			"Brightness",
			"Face",
			"Shadows"
		},
		["Texture"] = {
			"Texture",
			"StudsPerTileU",
			"StudsPerTileV",
			"Transparency",
			"Face",
		},
		["Decal"] = {
			"Texture",
			"Face",
			"Transparency",
		},
		["SpecialMesh"] = {
			"MeshId",
			"TextureId",
			"MeshType",
			"Scale",
		},
		["BlockMesh"] = {
			"Scale",
		},
		["CylinderMesh"] = {
			"Scale",
		},
		["Model"] = {
			"PrimaryPart",
		},
		["BoolValue"] = {
			"Value"
		}
	}

	function Serializer:SerializeInstance(TargetObj: Instance): string
		local SerializedData = {
			ClassName = TargetObj.ClassName,
			Name = TargetObj.Name,
			Properties = {},
			Children = {},
		}

		local function PopulateProperties(PropTable, Object: Instance)
			local PropertyList = ClassProperties[Object.ClassName]

			if not PropertyList then
				return
			end

			for _, Property in next, PropertyList do

				local Value = Object[Property]
				if TypeSerializer.Serializers[typeof(Value)] then
					PropTable[Property] = TypeSerializer.Serializers[typeof(Value)](Value)
				elseif Property == "Material" then
					PropTable[Property] = Value.Name
				elseif Property == "Shape" then
					PropTable[Property] = Value.Name
				elseif Property == "Face" then
					PropTable[Property] = Value.Name
				elseif Property == "MeshType" then
					PropTable[Property] = Value.Name
				else
					PropTable[Property] = Value
				end
			end
		end

		local function RecurseSerialize(CurObj: Instance, OutData)
			PopulateProperties(OutData.Properties, CurObj)

			for _, Child in next, CurObj:GetChildren() do
				local ChildData = {
					ClassName = Child.ClassName,
					Name = Child.Name,
					Properties = {},
					Children = {},
				}
				RecurseSerialize(Child, ChildData)
				table.insert(OutData.Children, ChildData)
			end
		end

		PopulateProperties(SerializedData.Properties, TargetObj)
		RecurseSerialize(TargetObj, SerializedData)

		return HttpService:JSONEncode(SerializedData)
	end

	function Serializer:DeserializeInstance(SerializedData: string, ParentObj: Instance): Instance
		local DecodedData = HttpService:JSONDecode(SerializedData)

		local function PopulateProperties(Object: Instance, PropData)
			local PropertyList = ClassProperties[Object.ClassName]

			if not PropertyList then
				return
			end

			local ValueFlag = false

			for Property, Value in next, PropData do

				if Property == "Value" then
					ValueFlag = true
				end

				if typeof(Value) == "table" and Value["Type"] and TypeSerializer.Deserializers[Value.Type] then
					Object[Property] = TypeSerializer.Deserializers[Value.Type](Value.Data)
				elseif Property == "Material" then
					Object[Property] = Enum.Material[Value]
				elseif Property == "Shape" then
					Object[Property] = Enum.PartType[Value]
				elseif Property == "Face" then
					Object[Property] = Enum.NormalId[Value]
				elseif Property == "MeshType" then
					Object[Property] = Enum.MeshType[Value]
				else
					Object[Property] = Value
				end
			end

			-- If the Object is a BoolValue and it was saved before the Value property was added, set Value to True by default
			if Object:IsA("BoolValue") and (not ValueFlag) then
				Object["Value"] = true
			end
		end

		local function RecurseDeserialize(ObjData, ObjParent)

			if ObjData.ClassName == "TouchTransmitter" then
				return fwarn("Cannot create instance of type TouchTransmitter (Ignored)")
			end

			local NewObj = Instance.new(ObjData.ClassName)
			NewObj.Parent = ObjParent
			NewObj.Name = ObjData.Name

			PopulateProperties(NewObj, ObjData.Properties)

			for _, ChildData in next, ObjData.Children do
				RecurseDeserialize(ChildData, NewObj)
			end
		end

		RecurseDeserialize(DecodedData, ParentObj)

		return ParentObj
	end
end

--#endregion

--#region Progress

local Progress = {}

do
	function Progress.new()
		local ProgressObject = {}

		local LoadingBar = Instance.new("ScreenGui")
		local Root = Instance.new("Frame")
		local Bar = Instance.new("Frame")
		local UIGradient = Instance.new("UIGradient")
		local Text = Instance.new("TextLabel")

		--Properties:

		LoadingBar.Name = "LoadingBar"
		LoadingBar.Parent = game:GetService("CoreGui") or LocalPlayer.PlayerGui
		LoadingBar.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		LoadingBar.ResetOnSpawn = false

		Root.Name = "Root"
		Root.Parent = LoadingBar
		Root.AnchorPoint = Vector2.new(0.5, 0)
		Root.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Root.BackgroundTransparency = 0.900
		Root.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Root.BorderSizePixel = 0
		Root.Position = UDim2.new(0.5, 0, 0, 60)
		Root.Size = UDim2.new(0, 500, 0, 20)

		Bar.Name = "Bar"
		Bar.Parent = Root
		Bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Bar.BorderSizePixel = 0
		Bar.Size = UDim2.new(0.5, 0, 1, 0)

		UIGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(67, 67, 67)),
		})
		UIGradient.Parent = Root

		Text.Name = "Text"
		Text.Parent = Root
		Text.AnchorPoint = Vector2.new(0.5, 0)
		Text.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Text.BackgroundTransparency = 0.2
		Text.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Text.BorderSizePixel = 1
		Text.Position = UDim2.new(0.5, 0, 1, 0)
		Text.Size = UDim2.new(0, 400, 0, 20)
		Text.Font = Enum.Font.Roboto
		Text.Text = "Progress Bar Text"
		Text.TextColor3 = Color3.fromRGB(255, 255, 255)
		Text.TextSize = 14.000

		function ProgressObject:UpdateProgress(Progress: number)
			Bar.Size = UDim2.fromScale(Progress / 100, 1)
		end

		function ProgressObject:SetText(Str: string)
			Text.Text = Str
		end

		function ProgressObject:Destroy()
			LoadingBar:Destroy()
		end

		ProgressObject.Gui = LoadingBar

		return ProgressObject
	end
end

--#endregion

--#region Building API

local Building = {}

function Building:WaitForBuildCooldown(ProgressBar: any?)
	local BuildCooldown = LocalPlayer:WaitForChild("BuildCooling", 2) :: BoolValue

	if ProgressBar then
		ProgressBar:SetText("Waiting for ratelimit...")
	end

	if BuildCooldown then
		local StartTime = workspace.DistributedGameTime

		repeat
			task.wait()

			if ProgressBar then
				local BuildCooling = LocalPlayer:FindFirstChild("BuildCooling")
				if BuildCooling then
					local DesiredTime = BuildCooldown:FindFirstChild("DesiredTime") :: NumberValue
					local TimeLeft = DesiredTime.Value - workspace.DistributedGameTime
					local Progress = math.clamp(1 - (TimeLeft / (DesiredTime.Value - StartTime)), 0, 1)

					ProgressBar:UpdateProgress(Progress * 100)
				end
			end

		until not LocalPlayer:FindFirstChild("BuildCooling")
	end
end

function Building.IsPointInVolume(Point: Vector3, VolumeCenter: CFrame, VolumeSize: Vector3): boolean
	local VolumeSpacePoint = VolumeCenter:PointToObjectSpace(Point)
	return VolumeSpacePoint.X >= -VolumeSize.X / 2
		and VolumeSpacePoint.X <= VolumeSize.X / 2
		and VolumeSpacePoint.Y >= -VolumeSize.Y / 2
		and VolumeSpacePoint.Y <= VolumeSize.Y / 2
		and VolumeSpacePoint.Z >= -VolumeSize.Z / 2
		and VolumeSpacePoint.Z <= VolumeSize.Z / 2
end

function Building:WorldToPlotSpace(Plot: Part, Position: CFrame): CFrame
	return Plot.CFrame:ToObjectSpace(Position)
end

function Building:PlotToWorldSpace(Plot: Part, Position: CFrame): CFrame
	return Plot.CFrame:ToWorldSpace(Position)
end

function Building:CheckPosition(Plot: Part, Position: Vector3)
	local Mesh = Plot:FindFirstChild("Mesh") :: SpecialMesh

	local PlotSize = Plot.Size * Mesh.Scale
	local PlotPosition = Plot.CFrame + Mesh.Offset

	return self.IsPointInVolume(Position, PlotPosition, PlotSize)
end

function Building:NewPartEdgeCheck(Plot: Part, Position: CFrame): boolean
	local Mesh = Plot:FindFirstChild("Mesh") :: SpecialMesh

	local PlotSize = Plot.Size * Mesh.Scale
	local PlotPosition = Plot.CFrame + Mesh.Offset

	-- Generate points for each corner of the part using attachments

	local Points = {}

	--- im actually tweaking
	table.insert(
		Points,
		Position:PointToWorldSpace(Vector3.new(-DefaultPartSize.X / 2, -DefaultPartSize.Y / 2, -DefaultPartSize.Z / 2))
	)
	table.insert(
		Points,
		Position:PointToWorldSpace(Vector3.new(DefaultPartSize.X / 2, -DefaultPartSize.Y / 2, -DefaultPartSize.Z / 2))
	)
	table.insert(
		Points,
		Position:PointToWorldSpace(Vector3.new(-DefaultPartSize.X / 2, -DefaultPartSize.Y / 2, DefaultPartSize.Z / 2))
	)
	table.insert(
		Points,
		Position:PointToWorldSpace(Vector3.new(DefaultPartSize.X / 2, -DefaultPartSize.Y / 2, DefaultPartSize.Z / 2))
	)
	table.insert(
		Points,
		Position:PointToWorldSpace(Vector3.new(-DefaultPartSize.X / 2, DefaultPartSize.Y / 2, -DefaultPartSize.Z / 2))
	)
	table.insert(
		Points,
		Position:PointToWorldSpace(Vector3.new(DefaultPartSize.X / 2, DefaultPartSize.Y / 2, -DefaultPartSize.Z / 2))
	)
	table.insert(
		Points,
		Position:PointToWorldSpace(Vector3.new(-DefaultPartSize.X / 2, DefaultPartSize.Y / 2, DefaultPartSize.Z / 2))
	)
	table.insert(
		Points,
		Position:PointToWorldSpace(Vector3.new(DefaultPartSize.X / 2, DefaultPartSize.Y / 2, DefaultPartSize.Z / 2))
	)

	-- Check if each point is in the plot

	for _, Point: Vector3 in next, Points do
		if not self.IsPointInVolume(Point, PlotPosition, PlotSize) then
			return false
		end
	end

	return true
end

function Building:CreateGroup(Children: { Instance }, Parent: Instance?): Model?
	if not Parent then
		local Plot = Utility:GetPlot()
		if Plot then
			Parent = Plot.Build
		else
			error("No parent specified and no plot found!")
		end
	end

	if #Children == 0 then
		if IgnoreEmptyGroups then
			return nil
		end
	end


	return Queue:Enqueue("CreateGroup", { "Model", Parent, Children })
end

function Building:BoundsCheck(Plot: Part, Reference: BasePart | FakeBasePart): boolean
	-- Ensure the build area is a valid part
	if not Plot or not Plot:IsA("BasePart") then
		return false
	end

	local Mesh = Plot:FindFirstChild("Mesh") :: SpecialMesh

    local PlotSize = Plot.Size * Mesh.Scale
    local PlotPosition = Plot.CFrame + Mesh.Offset

	-- Create fake temporary part for the Region
	local RefPlot = Instance.new("Part")
	RefPlot.Size = PlotSize
	RefPlot.CFrame = PlotPosition

	-- Create a region for the build area
	local BuildRegion = Region.FromPart(RefPlot)

	-- Check if all corners of the part are within the build region
	local Corners = {
		Reference.CFrame * CFrame.new(Reference.Size.X / 2, Reference.Size.Y / 2, Reference.Size.Z / 2),
		Reference.CFrame * CFrame.new(-Reference.Size.X / 2, Reference.Size.Y / 2, Reference.Size.Z / 2),
		Reference.CFrame * CFrame.new(Reference.Size.X / 2, -Reference.Size.Y / 2, Reference.Size.Z / 2),
		Reference.CFrame * CFrame.new(Reference.Size.X / 2, Reference.Size.Y / 2, -Reference.Size.Z / 2),
		Reference.CFrame * CFrame.new(-Reference.Size.X / 2, -Reference.Size.Y / 2, Reference.Size.Z / 2),
		Reference.CFrame * CFrame.new(-Reference.Size.X / 2, Reference.Size.Y / 2, -Reference.Size.Z / 2),
		Reference.CFrame * CFrame.new(Reference.Size.X / 2, -Reference.Size.Y / 2, -Reference.Size.Z / 2),
		Reference.CFrame * CFrame.new(-Reference.Size.X / 2, -Reference.Size.Y / 2, -Reference.Size.Z / 2),
	}
	
	for _, Corner in ipairs(Corners) do
		if not BuildRegion:CastPoint(Corner.Position) then
			RefPlot:Destroy()
			return false
		end
	end

	RefPlot:Destroy()
	return true
end

-- Part creation & property replication methods

function Building.TypeFromReference(Reference: FakeBasePart)
	local Type = "Normal"

	local ClassTypeReference = {
		["Part"] = "Normal",
		["CornerWedgePart"] = "Corner",
		["WedgePart"] = "Wedge",
		["TrussPart"] = "Truss",
		["Seat"] = "Seat",
		["VehicleSeat"] = "Vehicle Seat",
	}

	local ShapeTypeReference = {
		[Enum.PartType.Cylinder] = "Cylinder",
		[Enum.PartType.Ball] = "Ball",
	}

	if Reference:IsA("Seat") then
		Type = "Seat"
	elseif Reference:IsA("VehicleSeat") then
		Type = "Vehicle Seat"
	elseif Reference:IsA("Part") then
		Type = ShapeTypeReference[Reference.Shape] or "Normal"
	else
		Type = ClassTypeReference[Reference.ClassName] or "Normal"
	end

	return Type
end

function Building:CreatePart(Position: CFrame, Plot: Part, Type: string?): BasePart

	local Build = Plot:WaitForChild("Build") :: Folder

	if not Type then
		Type = "Normal"
	end

	local Part

	repeat
		Part = Queue:Enqueue("CreatePart", { Type, Position, Build })
		task.wait(1)
		fwarn("Failed to create part, retrying...")
	until Part

	return Part
end

function Building:BatchResize(PartsAndSizes: { { Part: BasePart, Size: Vector3, CFrame: CFrame } })
	if #PartsAndSizes > MaxPartsPerResizeCall then
		fwarn("[LargeBatch] Processing batch of " .. #PartsAndSizes .. " resize calls")
	end

	-- Split the parts into chunks of MaxPartsPerResizeCall
	if #PartsAndSizes > MaxPartsPerResizeCall then
		local PartChunks = {}

		for i = 1, #PartsAndSizes, MaxPartsPerResizeCall do
			local Chunk = {}
			for j = i, math.min(i + MaxPartsPerResizeCall - 1, #PartsAndSizes) do
				table.insert(Chunk, PartsAndSizes[j])
			end
			table.insert(PartChunks, Chunk)
		end

		for i, Chunk in next, PartChunks do
			fprint("Processing chunk " .. i .. " of " .. #PartChunks .. " [Size: " .. #Chunk .. "]")
			local success, err = pcall(function()
				Queue:EnqueueNoRet("SyncResize", { Chunk })
			end)
			if not success then
				fwarn("Failed to enqueue chunk " .. i .. ": " .. err)
			end
			task.wait(0.1)
		end

		return
	else
		Queue:EnqueueNoRet("SyncResize", { PartsAndSizes })
	end
end

function Building:Resize(Part: BasePart, Size: Vector3)
	Queue:EnqueueNoRet("SyncResize", { { Part = Part, CFrame = Part.CFrame, Size = Size } })
end

function Building:BatchMove(PartsAndPositions: { { Part: BasePart, CFrame: CFrame } })
	-- Split the parts into chunks of MaxPartsPerMoveCall

	if #PartsAndPositions > MaxPartsPerMoveCall then
		local PartChunks = {}

		for i = 1, #PartsAndPositions, MaxPartsPerMoveCall do
			local Chunk = {}
			for j = i, math.min(i + MaxPartsPerMoveCall - 1, #PartsAndPositions) do
				table.insert(Chunk, PartsAndPositions[j])
			end
			table.insert(PartChunks, Chunk)
		end

		for _, Chunk in next, PartChunks do
			Queue:EnqueueAsync("SyncMove", { Chunk })
			task.wait(1)
		end

		return
	else
		Queue:EnqueueAsync("SyncMove", { PartsAndPositions })
	end
end

function Building:BatchUpdateMaterials(PartsAndReferences: { { Part: BasePart, Reference: FakeBasePart } })
	-- Split the parts into chunks of MaxPartsPerMaterialCall

	if #PartsAndReferences > MaxPartsPerMaterialCall then
		local PartChunks = {}

		for i = 1, #PartsAndReferences, MaxPartsPerMaterialCall do
			local Chunk = {}
			for j = i, math.min(i + MaxPartsPerMaterialCall - 1, #PartsAndReferences) do
				table.insert(Chunk, PartsAndReferences[j])
			end
			table.insert(PartChunks, Chunk)
		end

		for _, Chunk in next, PartChunks do
			self:BatchUpdateMaterials(Chunk)
			task.wait(0.5)
		end

		return
	else
		local Changes = {}

		for _, PartAndReference in next, PartsAndReferences do
			local Part = PartAndReference.Part
			local Reference = PartAndReference.Reference

			table.insert(Changes, {
				Part = Part,
				Material = Reference.Material,
				Transparency = Reference.Transparency,
				Reflectance = Reference.Reflectance,
			})
		end

		Queue:EnqueueNoRet("SyncMaterial", { Changes })
	end
end

function Building:BatchUpdateColors(PartsAndColors: { { Part: BasePart, Color: Color3, UnionColoring: boolean } })
	-- Split the parts into chunks of MaxPartsPerColorCall

	if #PartsAndColors > MaxPartsPerColorCall then
		local PartChunks = {}

		for i = 1, #PartsAndColors, MaxPartsPerColorCall do
			local Chunk = {}
			for j = i, math.min(i + MaxPartsPerColorCall - 1, #PartsAndColors) do
				table.insert(Chunk, PartsAndColors[j])
			end
			table.insert(PartChunks, Chunk)
		end

		for _, Chunk in next, PartChunks do
			Queue:EnqueueNoRet("SyncColor", { Chunk })
			task.wait(0.1)
		end

		return
	else
		Queue:EnqueueNoRet("SyncColor", { PartsAndColors })
	end
end

function Building:BatchSetMeshes(PartsAndReferences: { { Part: BasePart, Reference: SpecialMesh } }, ProgressBar: any)
	-- Step 1. Create the meshes

	local Changes = {}

	for _, PartAndReference in next, PartsAndReferences do
		local Part = PartAndReference.Part

		table.insert(Changes, {
			Part = Part,
		})
	end

	local Results = Queue:Enqueue("CreateMeshes", { Changes })

	Building:WaitForBuildCooldown(ProgressBar)

	-- Step 2. Configure the meshes

	Changes = {}

	for _, PartAndReference in next, PartsAndReferences do
		local Part = PartAndReference.Part
		local Reference = PartAndReference.Reference

		if Reference.MeshType == Enum.MeshType.FileMesh then
			table.insert(Changes, {
				Part = Part,
				MeshType = Reference.MeshType,
				MeshId = Reference.MeshId,
				TextureId = Reference.TextureId,
				Scale = Reference.Scale,
			})
		else
			table.insert(Changes, {
				Part = Part,
				MeshType = Reference.MeshType,
				Scale = Reference.Scale,
			})
		end
	end

	Queue:Enqueue("SyncMesh", { Changes })
	Building:WaitForBuildCooldown(ProgressBar)

	return Results
end

function Building:Clone(Targets: { Instance }, Parent: Instance?)
	assert(#Targets <= MaxPartsPerCloneCall, "Too many parts to clone")

	if not Parent then
		local Plot = Utility:GetPlot()
		if Plot then
			Parent = Plot.Build
		else
			error("No parent specified and no plot found!")
		end
	end

	local Clones = Queue:Enqueue("Clone", { Targets, Parent })
	if not Clones then
		repeat Clones = Queue:Enqueue("Clone", { Targets, Parent }) until Clones
	end
	return Clones
end

function Building:BatchUpdateLights(
	PartsAndReferences: { { Part: BasePart, Reference: FakeBasePart } },
	ProgressBar: any
)
	ProgressBar:SetText("Creating lights...")
	ProgressBar:UpdateProgress(0)

	for LightNumber, LightClass in next, { "SpotLight", "SurfaceLight", "PointLight" } do
		local Changes = {}

		-- Step 1. Create the lights

		for _, PartAndReference in next, PartsAndReferences do
			local Part = PartAndReference.Part
			local Reference = PartAndReference.Reference

			for _, Child: SpotLight | SurfaceLight in next, Reference:GetChildren() do
				if Child.ClassName == LightClass then
					table.insert(Changes, {
						Part = Part,
						LightType = LightClass,
					})
				end
			end
		end

		ProgressBar:SetText("Creating " .. #Changes .. " " .. LightClass .. " lights")

		fprint("Batch creating " .. #Changes .. " " .. LightClass .. " lights")

		ProgressBar:UpdateProgress(0)

		Queue:Enqueue("CreateLights", { Changes })

		ProgressBar:UpdateProgress(100)

		fprint("Waiting for light configuration cooldown...")
		ProgressBar:SetText("Waiting for cooldown...")

		Building:WaitForBuildCooldown(ProgressBar)
		fprint("Configuring lights...")

		-- Step 2. Configure the lights

		Changes = {}

		for _, PartAndReference in next, PartsAndReferences do
			local Part = PartAndReference.Part
			local Reference = PartAndReference.Reference

			for _, Child: SpotLight | SurfaceLight | PointLight in next, Reference:GetChildren() do
				if Child.ClassName == LightClass then
					if Child:IsA("SpotLight") or Child:IsA("SurfaceLight") then
						table.insert(Changes, {
							Part = Part,
							LightType = LightClass,
							Face = Child.Face,
							Range = Child.Range,
							Brightness = Child.Brightness,
							Angle = Child.Angle,
							Color = Child.Color,
						})
					else
						table.insert(Changes, {
							Part = Part,
							LightType = LightClass,
							Range = Child.Range,
							Brightness = Child.Brightness,
							Color = Child.Color,
						})
					end
				end
			end
		end

		ProgressBar:SetText("Configuring " .. #Changes .. " " .. LightClass .. " lights")
		Queue:Enqueue("SyncLighting", { Changes })
	end
end

function Building:BatchUpdateTexturesAndDecals(PartsAndReferences: { { Part: BasePart, Reference: FakeBasePart } })
	local Changes = {}

	-- Step 1. Create the textures

	for _, Face in next, Enum.NormalId:GetEnumItems() do
		fprint("Processing face " .. Face.Name)

		Changes = {}

		for _, PartAndReference in next, PartsAndReferences do
			local Part = PartAndReference.Part
			local Reference = PartAndReference.Reference

			for _, Child in next, Reference:GetChildren() do
				if Child:IsA("Texture") and Child.ClassName == "Texture" and Child.Face == Face then
					-- if Child.Texture == "" then
					-- 	fwarn("Texture is empty, skipping...")
					-- 	continue
					-- end
					table.insert(Changes, {
						Part = Part,
						Face = Face,
						TextureType = "Texture",
					})
				end
			end
		end

		if #Changes > 0 then
			fprint("Batch creating " .. #Changes .. " textures")
			Queue:EnqueueNoRet("CreateTextures", { Changes })
		end

		Changes = {}

		for _, PartAndReference in next, PartsAndReferences do
			local Part = PartAndReference.Part
			local Reference = PartAndReference.Reference

			for _, Child in next, Reference:GetChildren() do
				if Child:IsA("Decal") and Child.ClassName == "Decal" and Child.Face == Face then
					if Child.Texture == "" then
						fwarn("Decal is empty, skipping...")
						continue
					end
					table.insert(Changes, {
						Part = Part,
						Face = Face,
						TextureType = "Decal",
					})
				end
			end
		end

		if #Changes > 0 then
			fprint("Batch creating " .. #Changes .. " decals")
			Queue:Enqueue("CreateTextures", { Changes })
		end

		Changes = {}

		for _, PartAndReference in next, PartsAndReferences do
			local Part = PartAndReference.Part
			local Reference = PartAndReference.Reference

			for _, Child in next, Reference:GetChildren() do
				if Child:IsA("Texture") and Child.ClassName == "Texture" and Child.Face == Face then
					table.insert(Changes, {
						Part = Part,
						Face = Face,
						TextureType = "Texture",
						Texture = Child.Texture,
						StudsPerTileU = Child.StudsPerTileU,
						StudsPerTileV = Child.StudsPerTileV,
						Transparency = Child.Transparency,
					})
				end
			end
		end

		if #Changes > 0 then
			fprint("Batch configuring " .. #Changes .. " textures")
			Queue:Enqueue("SyncTexture", { Changes })
		end

		Changes = {}

		for _, PartAndReference in next, PartsAndReferences do
			local Part = PartAndReference.Part
			local Reference = PartAndReference.Reference

			for _, Child in next, Reference:GetChildren() do
				if Child:IsA("Decal") and Child.ClassName == "Decal" and Child.Face == Face then
					table.insert(Changes, {
						Part = Part,
						Face = Face,
						TextureType = "Decal",
						Texture = Child.Texture,
						Transparency = Child.Transparency,
					})
				end
			end
		end

		if #Changes > 0 then
			fprint("Batch configuring " .. #Changes .. " decals")
			Queue:Enqueue("SyncTexture", { Changes })
		end
	end
end

function Building:AllocateParts(Amount: number, Type: string, Plot: Part?, ProgressBar: any?): { BasePart }
	local AllocatedParts = {}
	Plot = Plot or Utility:GetPlot()

	-- Exponentially clone parts to reduce the amount of calls to the server
	-- Until the target amount is reached

	if Plot then
		-- Create the first part
		table.insert(AllocatedParts, self:CreatePart(Plot.CFrame + Vector3.new(0,1,0), Plot, Type))
	end

	if ProgressBar then
		ProgressBar:SetText("Allocating " .. tostring(Amount) .. " " .. Type .. " parts...")
	end

	while #AllocatedParts < Amount do
		if ProgressBar then
			ProgressBar:UpdateProgress(#AllocatedParts / Amount * 100)
		end

		fprint("AllocatedParts", #AllocatedParts)
		fprint("Target", Amount)

		-- Max we can clone per call must be less than or equal to MaxPartsPerCloneCall

		local PartsToCloneAmount = math.min(MaxPartsPerCloneCall, Amount - #AllocatedParts)
		PartsToCloneAmount = math.min(PartsToCloneAmount, #AllocatedParts)

		local PartsToClone = {}

		for i = 1, PartsToCloneAmount do
			table.insert(PartsToClone, AllocatedParts[i])
		end

		local ClonedParts = self:Clone(PartsToClone)

		for _, ClonedPart in next, ClonedParts do
			table.insert(AllocatedParts, ClonedPart)
		end
	end

	fwarn("Successfully allocated " .. #AllocatedParts .. " parts!")

	if ProgressBar then
		ProgressBar:UpdateProgress(0)
		ProgressBar:SetText("")
	end

	return AllocatedParts
end

function Building.FilterByClassName(Instances: { Instance }, ClassName: string): { Instance }
	local Filtered = {}

	for _, Instance in next, Instances do
		if Instance.ClassName == ClassName then
			table.insert(Filtered, Instance)
		end
	end

	return Filtered
end

function Building.FilterByProperty(Instances: { Instance }, Property: string, Value: any): { Instance }
	local Filtered = {}

	for _, Instance in next, Instances do
		if Instance[Property] == Value then
			table.insert(Filtered, Instance)
		end
	end

	return Filtered
end

function Building:VerifyPart(Part: BasePart | FakeBasePart): boolean
	return Part:IsA("BasePart") and Part:IsDescendantOf(workspace) and Part.Parent ~= nil
end

-- Recursively creates a group of parts and models based on the given model and part references.
-- @param Model The model to recurse through.
function Building:RecurseGroup(Model: Model, PartReferences, Depth: number?): Model?
	local Children = {} :: { Instance }
	if not Depth then
		Depth = 0
	end
	assert(Depth, "make linter happy")

	for _, Child in next, Model:GetChildren() do
		if Child:IsA("BasePart") then
			if PartReferences[Child] then
				table.insert(Children, PartReferences[Child] :: BasePart)
			end
		elseif Child:IsA("Model") then
			local Result = self:RecurseGroup(Child, PartReferences, Depth + 1)
			if Result then
				table.insert(Children, Result)
			end
		end
	end

	fprint("Creating group with " .. #Children .. " children | Depth: " .. Depth)

	return Building:CreateGroup(Children, PartReferences[Model])
end

function Building:IsGroupWired(Model : Model) : boolean
	local Wired = false

	if Model.Name == "Interactable" then
		Wired = true
	else
		local Parent = Model.Parent
		local Depth = 0
		local MaxDepth = 10
		while Parent and Depth < MaxDepth do
			Depth += 1
			if Parent.Name == "Interactable" then
				Wired = true
				break
			end
			Parent = Parent.Parent
		end
	end

	return Wired
end

--#endregion

task.spawn(function()
	while true do
		-- if #CallQueue > 0 then
		-- 	table.foreach(CallQueue[1], fprint)
		-- end
		Queue:Step()
		task.wait(CallQueueFlushRate)
	end
end)

local LoadTemplate = false
local BuildThread = nil

function Building:Build(PlotCache: Part, MyPlot: Part, Configuration)
	
	local Allocation = {}

	if not Configuration then
		Configuration = {
			LoadDecorations = true,
			SkipNonWiringGroups = true,
		}
	end

	-- Step 1. Allocate normal parts (ClassName Part and Shape Block)

	-- local GenerateInformation = {}

	local PlotCacheParts = {}
	local PartTypes = {}
	local FilteredParts = 0
	local BoundsFilteredParts = 0
	local UnallocatedParts = 0
	local Build = PlotCache:FindFirstChild("Build") :: Folder
	local MyBuild = MyPlot:FindFirstChild("Build") :: Folder

	for _, Part: FakeBasePart in next, Build:GetDescendants() do
		if Part:IsA("BasePart") then
			if not Building:CheckPosition(MyPlot, Part.Position) then
				FilteredParts += 1
				continue
			end

			if not Building:BoundsCheck(MyPlot, Part) then
				fprint("Part", Part, "is out of bounds", "ClassName:", Part.ClassName)
				BoundsFilteredParts += 1
				continue
			end

			if Part.Name == "BaseHinge" then
				-- This is a wired component, let's check if the door it's a part of is on.
				local State = Part:FindFirstChild("DoorState")

				if State and State.Value == false then
					fprint("Checking hinge")
					-- Reset the hinge to its default position
					if Part.Parent then
						fprint("Parent found")
						local OutHinge = Part.Parent:FindFirstChild("OutHinge") :: BasePart
						local InHinge = Part.Parent:FindFirstChild("InHinge") :: BasePart
						if OutHinge and InHinge then
							local Transform = InHinge.CFrame * OutHinge.CFrame:Inverse()

							for _, part in next, Part.Parent:GetDescendants() do
								if part:IsA("BasePart") and part.Name ~= "OutHinge" and part.Name ~= "InHinge" then
									part.CFrame = Transform * part.CFrame
								end
							end
						end
					end
				end
			end

			table.insert(PlotCacheParts, Part)

			local TypeKey = Building.TypeFromReference(Part)
			fprint("TypeKey", TypeKey, Part)

			if not PartTypes[TypeKey] then
				PartTypes[TypeKey] = {}
			end

			table.insert(PartTypes[TypeKey], Part)
		end
	end

	local ProgressBar = Progress.new()

	for Type, Parts in next, PartTypes do
		fwarn("Allocating " .. #Parts .. " " .. Type .. " parts")
		local AllocatedParts = Building:AllocateParts(#Parts, Type, MyPlot, ProgressBar)

		if not Allocation[Type] then
			Allocation[Type] = {}
		end

		for _, Part in next, AllocatedParts do
			table.insert(Allocation[Type], Part)
		end
	end

	--#region Configure allocated parts

	local ColorChanges = {}
	local MaterialChanges = {}
	local SizeChanges = {}
	local LightingChanges = {}
	local TextureAndDecalChanges = {}
	local MeshChanges = {}

	local PartAssociations = {}

	for i, Part in next, PlotCacheParts do
		local AllocatedPart = table.remove(Allocation[Building.TypeFromReference(Part)], 1)

		PartAssociations[Part] = AllocatedPart

		if not Building:VerifyPart(AllocatedPart) then
			UnallocatedParts += 1
		end

		table.insert(SizeChanges, { Part = AllocatedPart, Size = Part.Size, CFrame = Part.CFrame })
		if Part.Color ~= BrickColor.new("Medium stone grey").Color then
			table.insert(
				ColorChanges,
				{
					Part = AllocatedPart,
					Color = Part.Color or BrickColor.new("Electric blue").Color,
					UnionColoring = true,
				}
			)
		end
		if Part.Material ~= Enum.Material.Plastic or Part.Transparency ~= 0 or Part.Reflectance ~= 0 then
			table.insert(MaterialChanges, { Part = AllocatedPart, Reference = Part })
		end
		table.insert(LightingChanges, { Part = AllocatedPart, Reference = Part })

		if Part:FindFirstChildOfClass("SpecialMesh") then
			table.insert(MeshChanges, { Part = AllocatedPart, Reference = Part:FindFirstChildOfClass("SpecialMesh") })
		end

		if Part:FindFirstChildOfClass("Decal") or Part:FindFirstChildOfClass("Texture") then
			table.insert(TextureAndDecalChanges, { Part = AllocatedPart, Reference = Part })
		end
	end

	-- Recount the parts to ensure that they are all allocated

	local RealAllocatedParts = {}

	for _, Part: BasePart in next, MyBuild:GetChildren() do
		table.insert(RealAllocatedParts, Part)
	end

	fwarn("Allocated " .. #RealAllocatedParts .. " parts")
	fwarn("Allocation supposed to be " .. #PlotCacheParts .. " parts")
	fwarn("Filtered " .. FilteredParts .. " parts")
	fwarn("Bounds filtered " .. BoundsFilteredParts .. " parts")
	fwarn("Unallocated " .. UnallocatedParts .. " parts")

	-- task.wait(10)

	if #ColorChanges > 0 then
		ProgressBar:SetText("Updating colors...")
		ProgressBar:UpdateProgress(0)
		Building:BatchUpdateColors(ColorChanges)
	end

	fwarn("Colors done!")
	ProgressBar:UpdateProgress(0)
	if #MaterialChanges > 0 then
		ProgressBar:SetText("Updating materials...")
		ProgressBar:UpdateProgress(0)
		Building:BatchUpdateMaterials(MaterialChanges)
		ProgressBar:UpdateProgress(100)
	end
	fwarn("Materials done!")

	if Configuration.LoadDecorations then

		ProgressBar:UpdateProgress(0)
		ProgressBar:SetText("Updating textures...")
		Building:BatchUpdateTexturesAndDecals(TextureAndDecalChanges)
		ProgressBar:UpdateProgress(100)
		fwarn("Textures and decals done!")

		ProgressBar:SetText("Loading lights...")
		ProgressBar:UpdateProgress(0)
		Building:BatchUpdateLights(LightingChanges, ProgressBar)
		ProgressBar:UpdateProgress(100)
		fwarn("Lights done!")

		ProgressBar:SetText("Loading meshes...")
		ProgressBar:UpdateProgress(0)
		Building:BatchSetMeshes(MeshChanges)
	end

	ProgressBar:SetText("Positioning parts...")
	ProgressBar:UpdateProgress(0)

	Building:BatchResize(SizeChanges)

	ProgressBar:UpdateProgress(100)

	ProgressBar:SetText("Making groups...")
	ProgressBar:UpdateProgress(0)

	local Groups = 0
	local GroupsDone = 0

	if Configuration.SkipNonWiringGroups then
		for _, Child in next, Build:GetChildren() do
			if Child:IsA("Model") and Building:IsGroupWired(Child) then
				Groups += 1
			end
		end

		for _, Child in next, Build:GetChildren() do
			if Child:IsA("Model") and Building:IsGroupWired(Child) then
				Building:RecurseGroup(Child, PartAssociations)
				GroupsDone += 1
				ProgressBar:UpdateProgress(GroupsDone / Groups * 100)
			end
		end
	else
		for _, Child in next, Build:GetChildren() do
			if Child:IsA("Model") then
				Groups += 1
			end
		end

		for _, Child in next, Build:GetChildren() do
			if Child:IsA("Model") then
				Building:RecurseGroup(Child, PartAssociations)
				GroupsDone += 1
				ProgressBar:UpdateProgress(GroupsDone / Groups * 100)
			end
		end
	end

	fwarn("Done!")

	PlotCache:Destroy()
	ProgressBar:Destroy()
end

--#endregion

local UI

do
	local G2L = {};

	-- StarterGui.PCV3
	G2L["1"] = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"));
	G2L["1"]["Name"] = [[PCV3]];
	G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling;


	-- StarterGui.PCV3.Border
	G2L["2"] = Instance.new("Frame", G2L["1"]);
	G2L["2"]["BorderSizePixel"] = 0;
	G2L["2"]["BackgroundColor3"] = Color3.fromRGB(50, 50, 50);
	G2L["2"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["2"]["Size"] = UDim2.new(0, 382, 0, 201);
	G2L["2"]["Position"] = UDim2.new(0.40939, 0, 0.33441, 0);
	G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2"]["Name"] = [[Border]];

	-- Tags
	CollectionService:AddTag(G2L["2"], [[UIColor1]]);

	-- StarterGui.PCV3.Border.Background
	G2L["3"] = Instance.new("Frame", G2L["2"]);
	G2L["3"]["BorderSizePixel"] = 0;
	G2L["3"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["3"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["3"]["Size"] = UDim2.new(1, -2, 1, -2);
	G2L["3"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3"]["Name"] = [[Background]];

	-- Tags
	CollectionService:AddTag(G2L["3"], [[UIColor1]]);

	-- StarterGui.PCV3.Border.Background.UIGradient
	G2L["4"] = Instance.new("UIGradient", G2L["3"]);
	G2L["4"]["Rotation"] = 90;
	G2L["4"]["Transparency"] = NumberSequence.new{NumberSequenceKeypoint.new(0.000, 0.5),NumberSequenceKeypoint.new(1.000, 0.5)};
	G2L["4"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(215, 67, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(119, 39, 255))};


	-- StarterGui.PCV3.Border.Background.Foreground
	G2L["5"] = Instance.new("Frame", G2L["3"]);
	G2L["5"]["BorderSizePixel"] = 0;
	G2L["5"]["BackgroundColor3"] = Color3.fromRGB(23, 23, 23);
	G2L["5"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["5"]["Size"] = UDim2.new(1, -2, 1, -2);
	G2L["5"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["5"]["Name"] = [[Foreground]];

	-- Tags
	CollectionService:AddTag(G2L["5"], [[UIColor2]]);

	-- StarterGui.PCV3.Border.Background.Foreground.Title
	G2L["6"] = Instance.new("Frame", G2L["5"]);
	G2L["6"]["BorderSizePixel"] = 0;
	G2L["6"]["BackgroundColor3"] = Color3.fromRGB(45, 45, 45);
	G2L["6"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["6"]["Size"] = UDim2.new(1, 0, 0, 20);
	G2L["6"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["6"]["Name"] = [[Title]];

	-- Tags
	CollectionService:AddTag(G2L["6"], [[UIColor2]]);

	-- StarterGui.PCV3.Border.Background.Foreground.Title.Text
	G2L["7"] = Instance.new("TextLabel", G2L["6"]);
	G2L["7"]["TextStrokeTransparency"] = 0;
	G2L["7"]["BorderSizePixel"] = 0;
	G2L["7"]["TextSize"] = 14;
	G2L["7"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["7"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["7"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["7"]["BackgroundTransparency"] = 1;
	G2L["7"]["RichText"] = true;
	G2L["7"]["Size"] = UDim2.new(1, -20, 1, 0);
	G2L["7"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["7"]["Text"] = [[PlotCopy v3.8]];
	G2L["7"]["Name"] = [[Text]];


	-- StarterGui.PCV3.Border.Background.Foreground.Title.Text.UIPadding
	G2L["8"] = Instance.new("UIPadding", G2L["7"]);
	G2L["8"]["PaddingTop"] = UDim.new(0, 1);
	G2L["8"]["PaddingRight"] = UDim.new(0, 5);
	G2L["8"]["PaddingLeft"] = UDim.new(0, 5);


	-- StarterGui.PCV3.Border.Background.Foreground.Title.UIListLayout
	G2L["9"] = Instance.new("UIListLayout", G2L["6"]);
	G2L["9"]["HorizontalFlex"] = Enum.UIFlexAlignment.Fill;
	G2L["9"]["Padding"] = UDim.new(0, 5);
	G2L["9"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
	G2L["9"]["FillDirection"] = Enum.FillDirection.Horizontal;


	-- StarterGui.PCV3.Border.Background.Foreground.UIListLayout
	G2L["a"] = Instance.new("UIListLayout", G2L["5"]);
	G2L["a"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center;
	G2L["a"]["HorizontalFlex"] = Enum.UIFlexAlignment.SpaceEvenly;
	G2L["a"]["SortOrder"] = Enum.SortOrder.LayoutOrder;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex
	G2L["b"] = Instance.new("Frame", G2L["5"]);
	G2L["b"]["BorderSizePixel"] = 0;
	G2L["b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["b"]["Size"] = UDim2.new(1, 0, 1, -20);
	G2L["b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["b"]["Name"] = [[ContentFlex]];


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.UIListLayout
	G2L["c"] = Instance.new("UIListLayout", G2L["b"]);
	G2L["c"]["HorizontalFlex"] = Enum.UIFlexAlignment.Fill;
	G2L["c"]["VerticalFlex"] = Enum.UIFlexAlignment.Fill;
	G2L["c"]["SortOrder"] = Enum.SortOrder.LayoutOrder;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section
	G2L["d"] = Instance.new("Frame", G2L["b"]);
	G2L["d"]["BorderSizePixel"] = 0;
	G2L["d"]["BackgroundColor3"] = Color3.fromRGB(23, 23, 23);
	G2L["d"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["d"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["d"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["d"]["Name"] = [[Section]];

	-- Tags
	CollectionService:AddTag(G2L["d"], [[UIColor2]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.UIListLayout
	G2L["e"] = Instance.new("UIListLayout", G2L["d"]);
	G2L["e"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center;
	G2L["e"]["HorizontalFlex"] = Enum.UIFlexAlignment.Fill;
	G2L["e"]["Padding"] = UDim.new(0, 5);
	G2L["e"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
	G2L["e"]["FillDirection"] = Enum.FillDirection.Horizontal;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline
	G2L["f"] = Instance.new("Frame", G2L["d"]);
	G2L["f"]["BorderSizePixel"] = 0;
	G2L["f"]["BackgroundColor3"] = Color3.fromRGB(148, 148, 148);
	G2L["f"]["Size"] = UDim2.new(0.5, 0, 1, 0);
	G2L["f"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["f"]["Name"] = [[OptionsOutline]];
	G2L["f"]["BackgroundTransparency"] = 0.5;

	-- Tags
	CollectionService:AddTag(G2L["f"], [[UIColor2]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options
	G2L["10"] = Instance.new("Frame", G2L["f"]);
	G2L["10"]["BorderSizePixel"] = 0;
	G2L["10"]["BackgroundColor3"] = Color3.fromRGB(35, 35, 35);
	G2L["10"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["10"]["Size"] = UDim2.new(1, -2, 1, -2);
	G2L["10"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["10"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["10"]["Name"] = [[Options]];

	-- Tags
	CollectionService:AddTag(G2L["10"], [[UIColor2]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.UIListLayout
	G2L["11"] = Instance.new("UIListLayout", G2L["10"]);
	G2L["11"]["VerticalFlex"] = Enum.UIFlexAlignment.Fill;
	G2L["11"]["SortOrder"] = Enum.SortOrder.LayoutOrder;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.UIPadding
	G2L["12"] = Instance.new("UIPadding", G2L["10"]);
	G2L["12"]["PaddingTop"] = UDim.new(0, 1);
	G2L["12"]["PaddingRight"] = UDim.new(0, 1);
	G2L["12"]["PaddingLeft"] = UDim.new(0, 1);
	G2L["12"]["PaddingBottom"] = UDim.new(0, 1);


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle
	G2L["13"] = Instance.new("Frame", G2L["10"]);
	G2L["13"]["BorderSizePixel"] = 0;
	G2L["13"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["13"]["Size"] = UDim2.new(1, 0, 0, 20);
	G2L["13"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["13"]["Name"] = [[Toggle]];
	G2L["13"]["LayoutOrder"] = 2;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.Label
	G2L["14"] = Instance.new("TextLabel", G2L["13"]);
	G2L["14"]["TextStrokeTransparency"] = 0;
	G2L["14"]["BorderSizePixel"] = 0;
	G2L["14"]["TextSize"] = 14;
	G2L["14"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["14"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["14"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["14"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["14"]["BackgroundTransparency"] = 1;
	G2L["14"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["14"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["14"]["Text"] = [[Decorations]];
	G2L["14"]["Name"] = [[Label]];


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.Label.UIPadding
	G2L["15"] = Instance.new("UIPadding", G2L["14"]);
	G2L["15"]["PaddingLeft"] = UDim.new(0, 2);


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.ToggleButton
	G2L["16"] = Instance.new("ImageButton", G2L["13"]);
	G2L["16"]["BorderSizePixel"] = 0;
	G2L["16"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["16"]["LayoutOrder"] = -1;
	G2L["16"]["Size"] = UDim2.new(0, 20, 1, 0);
	G2L["16"]["BackgroundTransparency"] = 1;
	G2L["16"]["Name"] = [[ToggleButton]];
	G2L["16"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	-- Attributes
	G2L["16"]:SetAttribute([[S_UIButton_Toggle]], true);
	G2L["16"]:SetAttribute([[ToggleName]], [[CopyDecorations]]);

	-- Tags
	CollectionService:AddTag(G2L["16"], [[SUI_DecorationsToggle]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.ToggleButton.UIAspectRatioConstraint
	G2L["17"] = Instance.new("UIAspectRatioConstraint", G2L["16"]);
	G2L["17"]["DominantAxis"] = Enum.DominantAxis.Height;
	G2L["17"]["AspectType"] = Enum.AspectType.ScaleWithParentSize;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.ToggleButton.SubImage
	G2L["18"] = Instance.new("ImageLabel", G2L["16"]);
	G2L["18"]["Active"] = true;
	G2L["18"]["BorderSizePixel"] = 0;
	G2L["18"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["18"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["18"]["Image"] = [[rbxasset://studio_svg_textures/Shared/WidgetIcons/Dark/Standard/Unchecked.png]];
	G2L["18"]["Size"] = UDim2.new(0.7, 0, 0.7, 0);
	G2L["18"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["18"]["BackgroundTransparency"] = 1;
	G2L["18"]["LayoutOrder"] = -1;
	G2L["18"]["Selectable"] = true;
	G2L["18"]["Name"] = [[SubImage]];
	G2L["18"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.UIListLayout
	G2L["19"] = Instance.new("UIListLayout", G2L["13"]);
	G2L["19"]["HorizontalFlex"] = Enum.UIFlexAlignment.Fill;
	G2L["19"]["VerticalAlignment"] = Enum.VerticalAlignment.Center;
	G2L["19"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
	G2L["19"]["FillDirection"] = Enum.FillDirection.Horizontal;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.UIGradient
	G2L["1a"] = Instance.new("UIGradient", G2L["13"]);
	G2L["1a"]["Transparency"] = NumberSequence.new{NumberSequenceKeypoint.new(0.000, 0.95625),NumberSequenceKeypoint.new(1.000, 1)};


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle
	G2L["1b"] = Instance.new("Frame", G2L["10"]);
	G2L["1b"]["BorderSizePixel"] = 0;
	G2L["1b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["1b"]["Size"] = UDim2.new(1, 0, 0, 20);
	G2L["1b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["1b"]["Name"] = [[Toggle]];
	G2L["1b"]["LayoutOrder"] = 2;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.Label
	G2L["1c"] = Instance.new("TextLabel", G2L["1b"]);
	G2L["1c"]["TextStrokeTransparency"] = 0;
	G2L["1c"]["BorderSizePixel"] = 0;
	G2L["1c"]["TextSize"] = 14;
	G2L["1c"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["1c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["1c"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["1c"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["1c"]["BackgroundTransparency"] = 1;
	G2L["1c"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["1c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["1c"]["Text"] = [[Only Wired]];
	G2L["1c"]["Name"] = [[Label]];


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.Label.UIPadding
	G2L["1d"] = Instance.new("UIPadding", G2L["1c"]);
	G2L["1d"]["PaddingLeft"] = UDim.new(0, 2);


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.ToggleButton
	G2L["1e"] = Instance.new("ImageButton", G2L["1b"]);
	G2L["1e"]["BorderSizePixel"] = 0;
	G2L["1e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["1e"]["LayoutOrder"] = -1;
	G2L["1e"]["Size"] = UDim2.new(0, 20, 1, 0);
	G2L["1e"]["BackgroundTransparency"] = 1;
	G2L["1e"]["Name"] = [[ToggleButton]];
	G2L["1e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	-- Attributes
	G2L["1e"]:SetAttribute([[S_UIButton_Toggle]], true);
	G2L["1e"]:SetAttribute([[ToggleName]], [[ObscurePlot]]);

	-- Tags
	CollectionService:AddTag(G2L["1e"], [[SUI_ObscurePlotToggle]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.ToggleButton.UIAspectRatioConstraint
	G2L["1f"] = Instance.new("UIAspectRatioConstraint", G2L["1e"]);
	G2L["1f"]["DominantAxis"] = Enum.DominantAxis.Height;
	G2L["1f"]["AspectType"] = Enum.AspectType.ScaleWithParentSize;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.ToggleButton.SubImage
	G2L["20"] = Instance.new("ImageLabel", G2L["1e"]);
	G2L["20"]["Active"] = true;
	G2L["20"]["BorderSizePixel"] = 0;
	G2L["20"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["20"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["20"]["Image"] = [[rbxasset://studio_svg_textures/Shared/WidgetIcons/Dark/Standard/Unchecked.png]];
	G2L["20"]["Size"] = UDim2.new(0.7, 0, 0.7, 0);
	G2L["20"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["20"]["BackgroundTransparency"] = 1;
	G2L["20"]["LayoutOrder"] = -1;
	G2L["20"]["Selectable"] = true;
	G2L["20"]["Name"] = [[SubImage]];
	G2L["20"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.UIListLayout
	G2L["21"] = Instance.new("UIListLayout", G2L["1b"]);
	G2L["21"]["HorizontalFlex"] = Enum.UIFlexAlignment.Fill;
	G2L["21"]["VerticalAlignment"] = Enum.VerticalAlignment.Center;
	G2L["21"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
	G2L["21"]["FillDirection"] = Enum.FillDirection.Horizontal;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Toggle.UIGradient
	G2L["22"] = Instance.new("UIGradient", G2L["1b"]);
	G2L["22"]["Transparency"] = NumberSequence.new{NumberSequenceKeypoint.new(0.000, 0.95625),NumberSequenceKeypoint.new(1.000, 1)};


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.TitleNoGradient
	G2L["23"] = Instance.new("Frame", G2L["10"]);
	G2L["23"]["BorderSizePixel"] = 0;
	G2L["23"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["23"]["Size"] = UDim2.new(1, 0, 0, 20);
	G2L["23"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["23"]["Name"] = [[TitleNoGradient]];
	G2L["23"]["LayoutOrder"] = -2;
	G2L["23"]["BackgroundTransparency"] = 1;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.TitleNoGradient.Label
	G2L["24"] = Instance.new("TextLabel", G2L["23"]);
	G2L["24"]["TextStrokeTransparency"] = 0;
	G2L["24"]["BorderSizePixel"] = 0;
	G2L["24"]["TextSize"] = 14;
	G2L["24"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["24"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["24"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["24"]["BackgroundTransparency"] = 1;
	G2L["24"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["24"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["24"]["Text"] = [[Options]];
	G2L["24"]["Name"] = [[Label]];


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.TitleNoGradient.Label.UIPadding
	G2L["25"] = Instance.new("UIPadding", G2L["24"]);
	G2L["25"]["PaddingLeft"] = UDim.new(0, 2);


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.TitleNoGradient.UIListLayout
	G2L["26"] = Instance.new("UIListLayout", G2L["23"]);
	G2L["26"]["HorizontalFlex"] = Enum.UIFlexAlignment.Fill;
	G2L["26"]["VerticalAlignment"] = Enum.VerticalAlignment.Center;
	G2L["26"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
	G2L["26"]["FillDirection"] = Enum.FillDirection.Horizontal;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.TextInput
	G2L["27"] = Instance.new("Frame", G2L["10"]);
	G2L["27"]["BorderSizePixel"] = 0;
	G2L["27"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["27"]["Size"] = UDim2.new(1, 0, 0, 20);
	G2L["27"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["27"]["Name"] = [[TextInput]];
	G2L["27"]["LayoutOrder"] = 2;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.TextInput.UIListLayout
	G2L["28"] = Instance.new("UIListLayout", G2L["27"]);
	G2L["28"]["HorizontalFlex"] = Enum.UIFlexAlignment.Fill;
	G2L["28"]["VerticalAlignment"] = Enum.VerticalAlignment.Center;
	G2L["28"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
	G2L["28"]["FillDirection"] = Enum.FillDirection.Horizontal;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.TextInput.Input
	G2L["29"] = Instance.new("TextBox", G2L["27"]);
	G2L["29"]["CursorPosition"] = -1;
	G2L["29"]["Active"] = false;
	G2L["29"]["TextStrokeTransparency"] = 0;
	G2L["29"]["Name"] = [[Input]];
	G2L["29"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["29"]["BorderSizePixel"] = 0;
	G2L["29"]["TextSize"] = 14;
	G2L["29"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["29"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["29"]["RichText"] = true;
	G2L["29"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["29"]["Selectable"] = false;
	G2L["29"]["PlaceholderText"] = [[File Name]];
	G2L["29"]["Size"] = UDim2.new(2, 0, 1, 0);
	G2L["29"]["BorderColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["29"]["Text"] = [[]];
	G2L["29"]["LayoutOrder"] = -1;
	G2L["29"]["BackgroundTransparency"] = 1;
	-- Attributes
	G2L["29"]:SetAttribute([[S_UITextBox]], true);

	-- Tags
	CollectionService:AddTag(G2L["29"], [[SUI_FileNameTextBox]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.TextInput.UIPadding
	G2L["2a"] = Instance.new("UIPadding", G2L["27"]);
	G2L["2a"]["PaddingLeft"] = UDim.new(0, 2);


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.TextInput.UIGradient
	G2L["2b"] = Instance.new("UIGradient", G2L["27"]);
	G2L["2b"]["Transparency"] = NumberSequence.new{NumberSequenceKeypoint.new(0.000, 0.925),NumberSequenceKeypoint.new(1.000, 1)};


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.TextInput.Icon
	G2L["2c"] = Instance.new("ImageButton", G2L["27"]);
	G2L["2c"]["BorderSizePixel"] = 0;
	G2L["2c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["2c"]["LayoutOrder"] = -2;
	G2L["2c"]["Size"] = UDim2.new(0, 20, 1, 0);
	G2L["2c"]["BackgroundTransparency"] = 1;
	G2L["2c"]["Name"] = [[Icon]];
	G2L["2c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.TextInput.Icon.UIAspectRatioConstraint
	G2L["2d"] = Instance.new("UIAspectRatioConstraint", G2L["2c"]);
	G2L["2d"]["DominantAxis"] = Enum.DominantAxis.Height;
	G2L["2d"]["AspectType"] = Enum.AspectType.ScaleWithParentSize;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.TextInput.Icon.Image
	G2L["2e"] = Instance.new("ImageLabel", G2L["2c"]);
	G2L["2e"]["Active"] = true;
	G2L["2e"]["BorderSizePixel"] = 0;
	G2L["2e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["2e"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["2e"]["Image"] = [[rbxasset://studio_svg_textures/Shared/InsertableObjects/Dark/Standard/Field.png]];
	G2L["2e"]["Size"] = UDim2.new(0, 17, 0, 17);
	G2L["2e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2e"]["BackgroundTransparency"] = 1;
	G2L["2e"]["LayoutOrder"] = -2;
	G2L["2e"]["Selectable"] = true;
	G2L["2e"]["Name"] = [[Image]];
	G2L["2e"]["Position"] = UDim2.new(0.5, -1, 0.5, 0);


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.TextInput.Icon.Image.UIAspectRatioConstraint
	G2L["2f"] = Instance.new("UIAspectRatioConstraint", G2L["2e"]);
	G2L["2f"]["DominantAxis"] = Enum.DominantAxis.Height;
	G2L["2f"]["AspectType"] = Enum.AspectType.ScaleWithParentSize;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Button
	G2L["30"] = Instance.new("TextButton", G2L["10"]);
	G2L["30"]["TextStrokeTransparency"] = 0.5;
	G2L["30"]["BorderSizePixel"] = 0;
	G2L["30"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["30"]["TextSize"] = 14;
	G2L["30"]["BackgroundColor3"] = Color3.fromRGB(71, 50, 142);
	G2L["30"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["30"]["Size"] = UDim2.new(1, 0, 0, 20);
	G2L["30"]["LayoutOrder"] = 4;
	G2L["30"]["Name"] = [[Button]];
	G2L["30"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["30"]["Text"] = [[Save File]];
	G2L["30"]["Position"] = UDim2.new(0, 1, 0, 1);

	-- Tags
	CollectionService:AddTag(G2L["30"], [[SUI_SaveFileButton]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Button
	G2L["31"] = Instance.new("TextButton", G2L["10"]);
	G2L["31"]["TextStrokeTransparency"] = 0.5;
	G2L["31"]["BorderSizePixel"] = 0;
	G2L["31"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["31"]["TextSize"] = 14;
	G2L["31"]["BackgroundColor3"] = Color3.fromRGB(71, 50, 142);
	G2L["31"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["31"]["Size"] = UDim2.new(1, 0, 0, 20);
	G2L["31"]["LayoutOrder"] = 6;
	G2L["31"]["Name"] = [[Button]];
	G2L["31"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["31"]["Text"] = [[Load File]];
	G2L["31"]["Position"] = UDim2.new(0, 1, 0, 1);

	-- Tags
	CollectionService:AddTag(G2L["31"], [[SUI_LoadFileButton]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Divider
	G2L["32"] = Instance.new("Frame", G2L["10"]);
	G2L["32"]["BorderSizePixel"] = 0;
	G2L["32"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["32"]["Size"] = UDim2.new(1, 0, 0, 10);
	G2L["32"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["32"]["Name"] = [[Divider]];
	G2L["32"]["LayoutOrder"] = 2;
	G2L["32"]["BackgroundTransparency"] = 1;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.OptionsOutline.Options.Divider.Inner
	G2L["33"] = Instance.new("Frame", G2L["32"]);
	G2L["33"]["BorderSizePixel"] = 0;
	G2L["33"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["33"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["33"]["Size"] = UDim2.new(1, 0, 0, 1);
	G2L["33"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["33"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["33"]["Name"] = [[Inner]];
	G2L["33"]["BackgroundTransparency"] = 0.8;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.UIPadding
	G2L["34"] = Instance.new("UIPadding", G2L["d"]);
	G2L["34"]["PaddingTop"] = UDim.new(0, 5);
	G2L["34"]["PaddingRight"] = UDim.new(0, 5);
	G2L["34"]["PaddingLeft"] = UDim.new(0, 5);
	G2L["34"]["PaddingBottom"] = UDim.new(0, 5);


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.VerticalStack
	G2L["35"] = Instance.new("Frame", G2L["d"]);
	G2L["35"]["BorderSizePixel"] = 0;
	G2L["35"]["BackgroundColor3"] = Color3.fromRGB(23, 23, 23);
	G2L["35"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["35"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["35"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["35"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["35"]["Name"] = [[VerticalStack]];

	-- Tags
	CollectionService:AddTag(G2L["35"], [[UIColor2]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.VerticalStack.UIListLayout
	G2L["36"] = Instance.new("UIListLayout", G2L["35"]);
	G2L["36"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center;
	G2L["36"]["HorizontalFlex"] = Enum.UIFlexAlignment.Fill;
	G2L["36"]["VerticalFlex"] = Enum.UIFlexAlignment.Fill;
	G2L["36"]["Padding"] = UDim.new(0, 5);
	G2L["36"]["SortOrder"] = Enum.SortOrder.LayoutOrder;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.VerticalStack.OptionsOutline
	G2L["37"] = Instance.new("Frame", G2L["35"]);
	G2L["37"]["BorderSizePixel"] = 0;
	G2L["37"]["BackgroundColor3"] = Color3.fromRGB(148, 148, 148);
	G2L["37"]["Size"] = UDim2.new(0.5, 0, 0.4, 0);
	G2L["37"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["37"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["37"]["Name"] = [[OptionsOutline]];
	G2L["37"]["LayoutOrder"] = 1;
	G2L["37"]["BackgroundTransparency"] = 0.5;

	-- Tags
	CollectionService:AddTag(G2L["37"], [[UIColor2]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.VerticalStack.OptionsOutline.Options
	G2L["38"] = Instance.new("Frame", G2L["37"]);
	G2L["38"]["BorderSizePixel"] = 0;
	G2L["38"]["BackgroundColor3"] = Color3.fromRGB(35, 35, 35);
	G2L["38"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["38"]["Size"] = UDim2.new(1, -2, 1, -2);
	G2L["38"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["38"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["38"]["Name"] = [[Options]];

	-- Tags
	CollectionService:AddTag(G2L["38"], [[UIColor2]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.VerticalStack.OptionsOutline.Options.UIListLayout
	G2L["39"] = Instance.new("UIListLayout", G2L["38"]);
	G2L["39"]["Padding"] = UDim.new(0, 2);
	G2L["39"]["VerticalAlignment"] = Enum.VerticalAlignment.Center;
	G2L["39"]["SortOrder"] = Enum.SortOrder.LayoutOrder;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.VerticalStack.OptionsOutline.Options.UIPadding
	G2L["3a"] = Instance.new("UIPadding", G2L["38"]);
	G2L["3a"]["PaddingTop"] = UDim.new(0, 1);
	G2L["3a"]["PaddingRight"] = UDim.new(0, 1);
	G2L["3a"]["PaddingLeft"] = UDim.new(0, 1);
	G2L["3a"]["PaddingBottom"] = UDim.new(0, 1);


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.VerticalStack.OptionsOutline.Options.Button
	G2L["3b"] = Instance.new("TextButton", G2L["38"]);
	G2L["3b"]["TextStrokeTransparency"] = 0.5;
	G2L["3b"]["BorderSizePixel"] = 0;
	G2L["3b"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["3b"]["TextSize"] = 14;
	G2L["3b"]["BackgroundColor3"] = Color3.fromRGB(71, 50, 142);
	G2L["3b"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["3b"]["Size"] = UDim2.new(1, 0, .5, -4);
	G2L["3b"]["LayoutOrder"] = 1;
	G2L["3b"]["Name"] = [[Button]];
	G2L["3b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3b"]["Text"] = [[Load Live Plot]];
	G2L["3b"]["Position"] = UDim2.new(0, 1, 0, 1);

	-- Tags
	CollectionService:AddTag(G2L["3b"], [[SUI_LoadLivePlotButton]]);

	G2L["3bx"] = Instance.new("TextButton", G2L["38"]);
	G2L["3bx"]["TextStrokeTransparency"] = 0.5;
	G2L["3bx"]["BorderSizePixel"] = 0;
	G2L["3bx"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["3bx"]["TextSize"] = 14;
	G2L["3bx"]["BackgroundColor3"] = Color3.fromRGB(142, 50, 62);
	G2L["3bx"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["3bx"]["Size"] = UDim2.new(1, 0, .5, -4);
	G2L["3bx"]["LayoutOrder"] = 1;
	G2L["3bx"]["Name"] = [[Button]];
	G2L["3bx"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3bx"]["Text"] = [[Cancel]];
	G2L["3bx"]["Position"] = UDim2.new(0, 1, 0, 1);

	-- Tags
	CollectionService:AddTag(G2L["3bx"], [[SUI_CancelButton]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.VerticalStack.InformationOutline
	G2L["3c"] = Instance.new("Frame", G2L["35"]);
	G2L["3c"]["BorderSizePixel"] = 0;
	G2L["3c"]["BackgroundColor3"] = Color3.fromRGB(148, 148, 148);
	G2L["3c"]["Size"] = UDim2.new(0.5, 0, 1, 0);
	G2L["3c"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["3c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3c"]["Name"] = [[InformationOutline]];
	G2L["3c"]["BackgroundTransparency"] = 0.5;

	-- Tags
	CollectionService:AddTag(G2L["3c"], [[UIColor2]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.VerticalStack.InformationOutline.Log
	G2L["3d"] = Instance.new("Frame", G2L["3c"]);
	G2L["3d"]["BorderSizePixel"] = 0;
	G2L["3d"]["BackgroundColor3"] = Color3.fromRGB(35, 35, 35);
	G2L["3d"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["3d"]["Size"] = UDim2.new(1, -2, 1, -2);
	G2L["3d"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["3d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3d"]["Name"] = [[Log]];

	-- Tags
	CollectionService:AddTag(G2L["3d"], [[UIColor2]]);

	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.VerticalStack.InformationOutline.Log.UIListLayout
	G2L["3e"] = Instance.new("UIListLayout", G2L["3d"]);
	G2L["3e"]["SortOrder"] = Enum.SortOrder.LayoutOrder;


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.VerticalStack.InformationOutline.Log.UIPadding
	G2L["3f"] = Instance.new("UIPadding", G2L["3d"]);
	G2L["3f"]["PaddingTop"] = UDim.new(0, 10);
	G2L["3f"]["PaddingRight"] = UDim.new(0, 10);
	G2L["3f"]["PaddingLeft"] = UDim.new(0, 10);
	G2L["3f"]["PaddingBottom"] = UDim.new(0, 10);


	-- StarterGui.PCV3.Border.Background.Foreground.ContentFlex.Section.VerticalStack.InformationOutline.Log.Information
	G2L["40"] = Instance.new("TextLabel", G2L["3d"]);
	G2L["40"]["TextStrokeTransparency"] = 0.5;
	G2L["40"]["BorderSizePixel"] = 0;
	G2L["40"]["TextSize"] = 14;
	G2L["40"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["40"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["40"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["40"]["TextColor3"] = Color3.fromRGB(227, 227, 227);
	G2L["40"]["BackgroundTransparency"] = 1;
	G2L["40"]["RichText"] = true;
	G2L["40"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["40"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["40"]["Text"] = [[Build Information:<br/>Parts: 1337<br/>Lights: 1337<br/>Meshes: 1337<br/>Groups: 1337<br/><br/>Status: Idle]];
	G2L["40"]["Name"] = [[Information]];

	-- Tags
	CollectionService:AddTag(G2L["40"], [[SUI_InformationText]]);


	UI = G2L["1"]
end

Instance.new("UIDragDetector", UI.Border)
local CheckedTexture = "rbxassetid://110380213236198"
local UncheckedTexture = "rbxassetid://138668896719643"
local UITagging = {
	Tags = {
		'SUI_LoadLivePlotButton',
		'SUI_InformationText',
		'SUI_FileNameTextBox',
		'SUI_SaveFileButton',
		'SUI_LoadFileButton',
		'SUI_DecorationsToggle',
		'SUI_ObscurePlotToggle'
	},
}

function UITagging:FromTag(Tag: string): Instance	
	return CollectionService:GetTagged(Tag)[1] or nil
end

UI.Parent = game:GetService("CoreGui")

local LoadLivePlotButton = UITagging:FromTag("SUI_LoadLivePlotButton") :: TextButton
local InformationText = UITagging:FromTag("SUI_InformationText") :: TextLabel
local FileNameTextBox = UITagging:FromTag("SUI_FileNameTextBox") :: TextBox
local SaveFileButton = UITagging:FromTag("SUI_SaveFileButton") :: TextButton
local LoadFileButton = UITagging:FromTag("SUI_LoadFileButton") :: TextButton
local DecorationsToggle = UITagging:FromTag("SUI_DecorationsToggle") :: ImageButton
local ObscurePlotToggle = UITagging:FromTag("SUI_ObscurePlotToggle") :: ImageButton
local CancelButton = UITagging:FromTag("SUI_CancelButton") :: TextButton

local function InitalizeToggle(Toggle, OptionName : string)
	if Options[OptionName] then
		Toggle.SubImage.Image = CheckedTexture
	else
		Toggle.SubImage.Image = UncheckedTexture
	end

	Toggle.MouseButton1Click:Connect(function()
		if Options[OptionName] then
			Options[OptionName] = false
			Toggle.SubImage.Image = UncheckedTexture
		else
			Options[OptionName] = true
			Toggle.SubImage.Image = CheckedTexture
		end
	end)
end

local function BindButton(Button, Function)
	Button.MouseButton1Click:Connect(Function)
end

InitalizeToggle(DecorationsToggle, "Decoration")
InitalizeToggle(ObscurePlotToggle, "SkipNonWiringGroups")
BindButton(LoadLivePlotButton, function()
	local Plot = SelectPlot()

	if Plot then
		local PlotCache = Plot:Clone()
		local MyPlot = Utility:GetPlot()

		if MyPlot then
			PlotCache:PivotTo(MyPlot:GetPivot())

			State.StateText = "Building..."
			State.PlotInformation = State.QueryPlotInformation(PlotCache)

			Building:Build(PlotCache, MyPlot, {
				LoadDecorations = Options.Decoration,
				SkipNonWiringGroups = Options.SkipNonWiringGroups
			})

			State.StateText = "Idle"

		end
		
	end
end)
BindButton(SaveFileButton, function()
	local FileName = FileNameTextBox.Text

	if FileName == "" then
		return
	end

	local Plot = SelectPlot()

	if not isfolder("plots") then
		makefolder("plots")
	end

	if Plot then
		local Data = Serializer:SerializeInstance(Plot)
		local CompressedData = Compression.Zlib.Compress(Data, {level = 2})
		writefile("plots/" .. FileName .. ".rplot", CompressedData)
	end
end)
BindButton(LoadFileButton, function()
	local FileName = FileNameTextBox.Text
	local MyPlot = Utility:GetPlot()

	if FileName == "" then
		return
	end

	if not isfolder("plots") then
		makefolder("plots")
	end

	if not MyPlot then
		return
	end

	if isfile("plots/" .. FileName .. ".rplot") then
		local CompressedData = readfile("plots/" .. FileName .. ".rplot")
		local Data = Compression.Zlib.Decompress(CompressedData)
		local Container = Instance.new("Folder")
		local PlotCache = Serializer:DeserializeInstance(Data, Container):FindFirstChildOfClass("Part")

		if PlotCache then
			PlotCache:PivotTo(MyPlot:GetPivot())
			State.StateText = "Building..."
			State.PlotInformation = State.QueryPlotInformation(PlotCache)

			if BuildThread then
				coroutine.close(BuildThread)
				BuildThread = nil
			end

			BuildThread = coroutine.create(function()
				Building:Build(PlotCache, MyPlot, {
					LoadDecorations = Options.Decoration,
					SkipNonWiringGroups = Options.SkipNonWiringGroups
				})
			end)

			coroutine.resume(BuildThread)
		else
			fwarn("Failed to load plot")
		end

		State.StateText = "Idle"
	end
end)
BindButton(CancelButton, function()
	if BuildThread then
		coroutine.close(BuildThread)
		BuildThread = nil
	end
end)

task.spawn(function()
	while task.wait(1) do
		InformationText.Text = string.format(
			"Build Information:<br/>\tParts: %d<br/>\tLights: %d<br/>\tMeshes: %d<br/>\tGroups: %d<br/>\tOwner: %s<br/>Status: %s",
			State.PlotInformation.Parts,
			State.PlotInformation.Lights,
			State.PlotInformation.Meshes,
			State.PlotInformation.Groups,
			State.PlotInformation.Owner,
			State.StateText
		)
	end
end)
