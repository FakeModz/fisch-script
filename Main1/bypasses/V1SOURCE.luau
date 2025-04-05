repeat wait() until getgenv().sasware_fisch_unload
-- plz dont skid bypass thx

BYPASS_SUBVERSION = "Full"

local NaughtyNaughty = "RemoveLoadingScreen"
local ACFlags = 0

if getreg and hookfunction and isexecutorclosure and getgc then
    local function AssertFunction(v)
        return type(v) == "function" and islclosure(v) and not isexecutorclosure(v)
    end

    for _, Object in next, getgc() do
        if AssertFunction(Object) then
            local Source = debug.info(Object, "s")
            if Source:find(NaughtyNaughty) then
                warn("Cleared AC function", Object, "@", Source)
                ACFlags += 1
                hookfunction(Object, LPH_NO_UPVALUES(function() end))
            end
        end
    end

    for _, Object in next, getreg() do
        if type(Object) == "thread" then
            local Source = debug.info(Object, 1, "s")
            if Source and Source:find(NaughtyNaughty) then
                warn("Killed AC thread", Object, "@", Source)
                ACFlags += 1
                coroutine.close(Object)
            end
        end
    end
else
    BYPASS_SUBVERSION = "Partial"

    local AdService = game:GetService("AdService")

    for _, Child in next, AdService:GetChildren() do
        if Child:IsA("RemoteEvent") then
            local Name = Child.Name
            local Swap = Instance.new("UnreliableRemoteEvent")
            Swap.Name = Name
            Swap.Parent = AdService
            Child:Destroy()
        end
    end
end

print("Loaded SasGuard v1 (", BYPASS_SUBVERSION, ")", "Flagged:", ACFlags)
