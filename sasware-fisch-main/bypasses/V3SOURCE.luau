repeat wait() until getgenv().sasware_fisch_unload
-- plz dont skid bypass thx

BYPASS_SUBVERSION = "Full-Emulationv2"

local NaughtyNaughty = "RemoveLoadingScreen"
local ACFlags = 0

local ExcludedServices = {
	"ScriptContext",
	"RobloxReplicatedStorage",
	"ReplicatedStorage",
	"StarterGui",
	"Players",
	"Workspace",
}

HandshakeEmulated = LPH_NO_VIRTUALIZE(function(...)
	return task.wait(9e9) -- lol
end)

if getreg and hookfunction and isexecutorclosure and getgc then
	local function AssertFunction(v)
		return type(v) == "function" and islclosure(v) and not isexecutorclosure(v)
	end

	for _, Object in next, getgc() do
		if AssertFunction(Object) then
			local Source = debug.info(Object, "s")
			if Source:find(NaughtyNaughty) then
				--warn("Cleared AC function", Object, "@", Source)
				ACFlags += 1
				hookfunction(Object, LPH_NO_UPVALUES(function() end))
			end
		end
	end

	for _, Object in next, getreg() do
		if type(Object) == "thread" then
			local Source = debug.info(Object, 1, "s")
			if Source and Source:find(NaughtyNaughty) then
				--warn("Killed AC thread", Object, "@", Source)
				ACFlags += 1
				coroutine.close(Object)
			end
		end
	end
else
	BYPASS_SUBVERSION = "Only-Emulationv2"
	if getnilinstances then
		BYPASS_SUBVERSION = "AltKill-Emulatedv2"

		local NilInstances = getnilinstances()
		for _, NilInstance in next, NilInstances do
			if NilInstance:IsA("LuaSourceContainer") and NilInstance.Name:find("Loading") then
				--warn("Cleared AC LuaSourceContainer", NilInstance)
				ACFlags += 1
				NilInstance:Destroy()
			end
		end
	end

	for _, Service in next, game:GetChildren() do
		if table.find(ExcludedServices, Service.Name) then
			continue
		end

		for _, Child in next, Service:GetChildren() do
			if Child:IsA("RemoteEvent") then
				local Name = Child.Name
				local Swap = Instance.new("UnreliableRemoteEvent")
				Swap.Name = Name
				Swap.Parent = Service
				Child:Destroy()
			end
		end
	end
end

local Handshake =
	game:GetService("ReplicatedStorage"):WaitForChild("events"):WaitForChild("getsettings") :: RemoteFunction
Handshake.OnClientInvoke = HandshakeEmulated

-- print("Loaded SasGuard v2 (", BYPASS_SUBVERSION, ")", "Flagged:", ACFlags)
