local TeleportService = cloneref(game:GetService('TeleportService'))
local HttpService = cloneref(game:GetService('HttpService'))
local proxyUrlPrefix = "http://127.0.0.1:1337/"
local PlaceId, JobId = game.PlaceId, game.JobId
local TextChatService = game:GetService("TextChatService")
local WebhookURL = "https://discord.com/api/webhooks/1356844976927150130/2IRL-ptrWDWT4v8TqSbpWOyTnBu6Y2dTc4G-k5fCN_YbxppNRB46dqQnLs1YyTwMdTYl"

local Messages = {
	"saswaresoftworks is so pasted it made me crash my NEW WHIP! 🚗",
	"guys... u should get sasware it gives you SO MUCH MONEY 💸",
	"sasware #1 softwarez for blockspin... get now 🤑",
	"i just 💰 got 7 ZILLION dollars from sasware",
	"my grandma got me sasware and now i have NO surviving opps 👵",
	"sasware made my father come back 🥛",
	"sasware softworks LLC supported by Microsoft Windows 12 🪟",
	"sasware has best autofarm... made me crash my brand new whip.",
	"GET #1 BLOCKCHAIN SOFTWARE SASWARE SOFTWORKS LLC CHEAT WORK 2025",
	"get sasware and never miss a shot again.",
	"is your aim terrible? get sasware.",
	"dont get good, get sasware.",
	"sasguard protects my p2c and sasware gives me infinite money in blockspin",
	"the sasware engine upgrade service made my civic hit mach 5... get now",
	"sasware softworks llc is the best \"funny boxes\" provider for blockspin.",
	"riftcore blew up my old whip sasware bought me a new one",
	"get the only f2c that david baszucki approves: sasware",
	"i got sasware and now i have 20 RDC invitations in my inbox",
}

local Senders = {
	"[Blockspin Announcements]: ",
	"[Roblox]: ",
	"[sasware]: ",
	"[Builderman]: ",
	"[1x1x1x1]: ",
	"[Sasware]: ",
	"[Sasware Softworks]: ",
	"[david.baszucki]: ",
	"[your father]: ",
	"[Saint Von the III]: ",
	"[System]: ",
	"[JackCinnamon]: ",
}

local TextChannels = TextChatService:WaitForChild("TextChannels")
local RBXGeneral = TextChannels:WaitForChild("RBXGeneral")

task.spawn(function()
	while task.wait(math.random(4,6)) do

		RBXGeneral:SendAsync(
			`.\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r{Senders[math.random(1, #Senders)]}{Messages[math.random(1, #Messages)]}`
		)

		task.spawn(function()
			pcall(function()
				local data = {
					["content"] = "[v3] Sent advertisement in JobId " .. JobId
				}
				
				local jsonData = HttpService:JSONEncode(data)
				
				local headers = {
					["content-type"] = "application/json"
				}
				
				request({
					Url = WebhookURL,
					Method = "POST",
					Headers = headers,
					Body = jsonData
				})
			end)
		end)
		
		task.wait(3)
	end
end)

task.spawn(function()
	queue_on_teleport(game:HttpGet(proxyUrlPrefix .. "https://raw.githubusercontent.com/centerepic/sasware/refs/heads/main/games/Blockspin/adbot.lua", false))
end)

while task.wait(math.random(10, 15)) do
	pcall(function()
		task.spawn(function()
			game:GetService("GuiService"):ClearError()
			local servers = {}
			local req = http_request({Url = proxyUrlPrefix .. string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true", PlaceId)})
			local body = HttpService:JSONDecode(req.Body)

			if body and body.data then
				for i, v in next, body.data do
					if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= JobId then
						table.insert(servers, 1, v.id)
					end
				end
			end

			if #servers > 0 then
				TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], game.Players.LocalPlayer)
			end
		end)
	end)
end
