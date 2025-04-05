local HttpService = game:GetService("HttpService")
local Url = "https://raw.githubusercontent.com/centerepic/sasware/refs/heads/main/index.json"

local Success, Response = pcall(function()
    return game:HttpGet(Url)
end)

if Success then
    local Data = HttpService:JSONDecode(Response)
    local PlaceId = tostring(game.PlaceId)
    
    if Data.games and Data.games[PlaceId] then
        local ScriptUrl = Data.games[PlaceId]
        print("Loading Script For Game ID:", PlaceId)
        
        local ScriptSuccess, ScriptResponse = pcall(function()
            return game:HttpGet(ScriptUrl)
        end)
        
        if ScriptSuccess then
            local LoadSuccess, ErrorMsg = pcall(function()
                loadstring(ScriptResponse)()
            end)
            
            if not LoadSuccess then
                warn("Error Executing Script:", ErrorMsg)
            end
        else
            warn("Failed To Fetch Script From:", ScriptUrl)
        end
    else
        warn("No Supported Script Found For This Game (PlaceId:", PlaceId, ")")
    end
else
    warn("Failed To Fetch Game Script Index From:", Url)
end
