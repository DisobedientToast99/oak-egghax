if game.PlaceId ~= 9938675423 then return end

local defaultSettings = {
	["SearchFor"] = {"Epic", "Special"}, --// Rarities
	["Exclude"] = {"MoonEgg"}, --// Specific Eggs
	["Keybinds"] = {
		TeleportToSellSpot = Enum.KeyCode.G,
		TeleportToNextEgg = Enum.KeyCode.Z,
		ServerHop = Enum.KeyCode.P
	}
}

local settings = table.clone(_G._Egg or {})

for i,v in pairs(defaultSettings) do
	if not settings[i] then
		settings[i] = v
	end
end

for i,v in pairs(defaultSettings.Keybinds) do
	if not settings.Keybinds[i] then
		settings.Keybinds[i] = v
	end
end

_G._Egg = settings

repeat task.wait() until game:IsLoaded()

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local world = workspace:WaitForChild("World")
local variantRegions = world:WaitForChild("VariantRegions")

local trackedEggs = {}

local eggRarities = {
	["GrudgeEgg"] = "Special",
	["GurtEgg"] = "Special",
	["MoonEgg"] = "Special",
	["GoldenEgg"] = "Special",
	["RainbowEgg"] = "Common",
	["StripedEgg"] = "Common",
	["WatermelonEgg"] = "Rare",
	["TreeEgg"] = "Epic",
	["WhiteEgg"] = "Normal",
	["RedEgg"] = "Common",
	["HoleEgg"] = "Common",
	["FireEgg"] = "Rare",
	["UnstableEgg"] = "Epic",
	["CactusEgg"] = "Common",
	["SandyEgg"] = "Common",
	["DuckEgg"] = "Rare",
	["DinoEgg"] = "Epic",
	["MegentaEgg"] = "Common",
	["PinkEgg"] = "Common",
	["SwirlyEgg"] = "Rare",
	["RabbitEgg"] = "Epic",
	["GreenEgg"] = "Common",
	["CommanderEgg"] = "Common",
	["ZombieEgg"] = "Rare",
	["AcidEgg"] = "Epic",
	["BlueEgg"] = "Common",
	["PurpleEgg"] = "Common",
	["FrozenEgg"] = "Rare",
	["EggcasedEgg"] = "Epic",
}

local rarityColors = {
	Normal = Color3.fromRGB(150, 150, 150),
	Common = Color3.fromRGB(0, 255, 0),
	Rare = Color3.fromRGB(255, 140, 0),
	Epic = Color3.fromRGB(180, 0, 255),
	Special = Color3.fromRGB(255, 255, 0)
}

local function getTotalEggs()
	local t=0 for _,_ in trackedEggs do t+=1 end return t
end

local function getRandomEgg()
	local keys = {}
	for _,key in pairs(trackedEggs) do
		table.insert(keys, key)
	end

	if #keys == 0 then
		return nil
	end
	local randomIndex = keys[math.random(1, #keys)]
	table.clear(keys) keys = nil
	return randomIndex
end

local function createESP(model)
	if not model:FindFirstChildOfClass("MeshPart") then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EggESP"
	billboard.Adornee = model:FindFirstChildOfClass("MeshPart")
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.MaxDistance = math.huge
	billboard.AlwaysOnTop = true
	billboard.Parent = model:FindFirstChildOfClass("MeshPart")

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.SourceSansBold
	label.TextScaled = true
	label.Parent = billboard

	label.Text = model.Name
	label.TextColor3 = rarityColors[eggRarities[model.Name] or "Normal"] or Color3.new(1, 1, 1)

	return billboard
end

local function isValidEgg(model)
	if not model:IsA("Model") then print(model.Name, "no model") return false end
	if table.find(_G._Egg.SearchFor or {"all"}, "all") or (not table.find(_G._Egg.SearchFor or {"all"}, eggRarities[model.Name]) or table.find(_G._Egg.Exclude or {}, model.Name)) then return false end

	local owner = model:FindFirstChild("Owner")
	if not owner or owner.Value ~= nil then print(model.Name, "already owned") return false end

	local meshPart = model:FindFirstChildOfClass("MeshPart")
	if not meshPart then print(model.Name, "no meshpart") return false end

	return true
end

local function trackEgg(model)
	if not isValidEgg(model) then return end

	print(model.Name, eggRarities[model.Name], "valid egg")

	trackedEggs[model] = {
		model = model,
		part = model:FindFirstChildOfClass("MeshPart"),
		gui = createESP(model)
	}
end

local function serverHop()
	local servers = {}
	local success, result = pcall(function()
		return httpService:JSONDecode(game:HttpGet(
			string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
			))
	end)

	if success and result and result.data then
		for _, server in pairs(result.data) do
			if server.playing < server.maxPlayers and server.id ~= game.JobId then
				table.insert(servers, server.id)
			end
		end

		if #servers > 0 then
			local randomServerId = servers[math.random(1, #servers)]
			teleportService:TeleportToPlaceInstance(game.PlaceId, randomServerId, player)
		end
	end
end

userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == (_G._Egg.Keybinds.TeleportToNextEgg) then
		player.Character:WaitForChild("HumanoidRootPart").CFrame = getRandomEgg().part.CFrame
	elseif input.KeyCode == (_G._Egg.Keybinds.ServerHop) then
		serverHop()
	elseif input.KeyCode == (_G._Egg.Keybinds.TeleportToSellSpot) then
		player.Character:WaitForChild("HumanoidRootPart").Position = Vector3.new(940, 45, 1079)
	end
end)

local stopTracking = false

game["Run Service"].RenderStepped:Connect(function()
	if stopTracking then return end

	for _, data in pairs(trackedEggs) do
		if not data.model:IsDescendantOf(workspace) or not isValidEgg(data.model) or not data.model:FindFirstChildOfClass("MeshPart") then
			trackedEggs[data.model] = nil
		end
	end

	for _, region in pairs(variantRegions:GetChildren()) do
		if region:IsA("Folder") and string.find(region.Name, "Egg") then
			for _, patch in pairs(region:GetChildren()) do
				if patch:IsA("Model") and patch.Name == "Patch" then
					if patch:FindFirstChild("Fruit") and patch:FindFirstChild("Fruit"):IsA("Folder") then
						for _, model in pairs(patch:FindFirstChild("Fruit"):GetChildren()) do
							if not trackedEggs[model] then
								trackEgg(model)
							end
						end
					end
				end
			end
		end
	end

	if getTotalEggs() == 0 then
		print("none")
		stopTracking = true
		task.wait(0.5)
		stopTracking = false
	end
end)
