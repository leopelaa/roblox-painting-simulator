-- House Painter Simulator - FIXED VERSION
-- Put this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local remotesFolder = ReplicatedStorage:FindFirstChild("PainterRemotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "PainterRemotes"
    remotesFolder.Parent = ReplicatedStorage
end

local requestJobRemote = remotesFolder:FindFirstChild("RequestJob")
if not requestJobRemote then
    requestJobRemote = Instance.new("RemoteEvent")
    requestJobRemote.Name = "RequestJob"
    requestJobRemote.Parent = remotesFolder
end

local paintRemote = remotesFolder:FindFirstChild("PaintHouse")
if not paintRemote then
    paintRemote = Instance.new("RemoteEvent")
    paintRemote.Name = "PaintHouse"
    paintRemote.Parent = remotesFolder
end

local buyRemote = remotesFolder:FindFirstChild("BuyUpgrade")
if not buyRemote then
    buyRemote = Instance.new("RemoteEvent")
    buyRemote.Name = "BuyUpgrade"
    buyRemote.Parent = remotesFolder
end

local currentCity = workspace:FindFirstChild("PainterCity")
if currentCity then
    currentCity:Destroy()
end

currentCity = Instance.new("Model")
currentCity.Name = "PainterCity"
currentCity.Parent = workspace

local houses = {}
local houseIndex = 0
local npcs = {}

local function setPlayerDefaults(player)
    player:SetAttribute("Money", player:GetAttribute("Money") or 500)
    player:SetAttribute("CurrentJob", nil)
    player:SetAttribute("PaintLevel", player:GetAttribute("PaintLevel") or 1)
    player:SetAttribute("RollerLevel", player:GetAttribute("RollerLevel") or 1)
end

local function getHouseById(id)
    for _, house in ipairs(houses) do
        if house:GetAttribute("HouseId") == id then
            return house
        end
    end
    return nil
end

local function createNPC(position, name, ownerOfHouse)
    local npcModel = Instance.new("Model")
    npcModel.Name = name .. "_NPC"
    npcModel.Parent = currentCity

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Shape = Enum.PartType.Cylinder
    root.Size = Vector3.new(2, 2, 2)
    root.Transparency = 1
    root.CanCollide = false
    root.CFrame = CFrame.new(position)
    root.Parent = npcModel

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 3, 1)
    torso.Color = Color3.fromRGB(200, 120, 80)
    torso.Material = Enum.Material.SmoothPlastic
    torso.TopSurface = Enum.SurfaceType.Smooth
    torso.BottomSurface = Enum.SurfaceType.Smooth
    torso.CanCollide = true
    torso.Parent = npcModel

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(2, 2, 2)
    head.Color = Color3.fromRGB(255, 200, 160)
    head.Material = Enum.Material.SmoothPlastic
    head.CanCollide = true
    head.TopSurface = Enum.SurfaceType.Smooth
    head.BottomSurface = Enum.SurfaceType.Smooth
    head.Parent = npcModel

    local lArm = Instance.new("Part")
    lArm.Name = "Left Arm"
    lArm.Size = Vector3.new(1, 3, 1)
    lArm.Color = Color3.fromRGB(255, 200, 160)
    lArm.Material = Enum.Material.SmoothPlastic
    lArm.CanCollide = false
    lArm.Parent = npcModel

    local rArm = Instance.new("Part")
    rArm.Name = "Right Arm"
    rArm.Size = Vector3.new(1, 3, 1)
    rArm.Color = Color3.fromRGB(255, 200, 160)
    rArm.Material = Enum.Material.SmoothPlastic
    rArm.CanCollide = false
    rArm.Parent = npcModel

    local lLeg = Instance.new("Part")
    lLeg.Name = "Left Leg"
    lLeg.Size = Vector3.new(1, 3, 1)
    lLeg.Color = Color3.fromRGB(70, 70, 100)
    lLeg.Material = Enum.Material.SmoothPlastic
    lLeg.CanCollide = true
    lLeg.Parent = npcModel

    local rLeg = Instance.new("Part")
    rLeg.Name = "Right Leg"
    rLeg.Size = Vector3.new(1, 3, 1)
    rLeg.Color = Color3.fromRGB(70, 70, 100)
    rLeg.Material = Enum.Material.SmoothPlastic
    rLeg.CanCollide = true
    rLeg.Parent = npcModel

    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = npcModel

    -- Weld parts together
    local weldTorso = Instance.new("WeldConstraint")
    weldTorso.Part0 = root
    weldTorso.Part1 = torso
    weldTorso.Parent = npcModel

    local weldHead = Instance.new("WeldConstraint")
    weldHead.Part0 = torso
    weldHead.Part1 = head
    weldHead.C1 = CFrame.new(0, 1.5, 0)
    weldHead.Parent = npcModel

    local weldLArm = Instance.new("WeldConstraint")
    weldLArm.Part0 = torso
    weldLArm.Part1 = lArm
    weldLArm.C1 = CFrame.new(-1.5, 0, 0)
    weldLArm.Parent = npcModel

    local weldRArm = Instance.new("WeldConstraint")
    weldRArm.Part0 = torso
    weldRArm.Part1 = rArm
    weldRArm.C1 = CFrame.new(1.5, 0, 0)
    weldRArm.Parent = npcModel

    local weldLLeg = Instance.new("WeldConstraint")
    weldLLeg.Part0 = torso
    weldLLeg.Part1 = lLeg
    weldLLeg.C1 = CFrame.new(-0.5, -3, 0)
    weldLLeg.Parent = npcModel

    local weldRLeg = Instance.new("WeldConstraint")
    weldRLeg.Part0 = torso
    weldRLeg.Part1 = rLeg
    weldRLeg.C1 = CFrame.new(0.5, -3, 0)
    weldRLeg.Parent = npcModel

    -- Face
    local face = Instance.new("Decal")
    face.Face = Enum.NormalId.Front
    face.Texture = "rbxasset://textures/face.png"
    face.Parent = head

    -- Proximity Prompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Ask to paint"
    prompt.ObjectText = name
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 16
    prompt.Parent = head

    npcModel:SetAttribute("NPCName", name)
    npcModel:SetAttribute("OwnerOfHouse", ownerOfHouse)

    prompt.Triggered:Connect(function(player)
        if player:GetAttribute("CurrentJob") then
            return
        end

        local house = ownerOfHouse
        if house and house.Parent then
            player:SetAttribute("CurrentJob", house:GetAttribute("HouseId"))

            local speechBubble = Instance.new("BillboardGui")
            speechBubble.Size = UDim2.new(0, 260, 0, 80)
            speechBubble.AlwaysOnTop = true
            speechBubble.StudsOffset = Vector3.new(0, 3, 0)
            speechBubble.Parent = head

            local speechLabel = Instance.new("TextLabel")
            speechLabel.Size = UDim2.new(1, 0, 1, 0)
            speechLabel.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
            speechLabel.BorderSizePixel = 1
            speechLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            speechLabel.Font = Enum.Font.Gotham
            speechLabel.Text = name .. ": \"Can you paint my house? Please!\""
            speechLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
            speechLabel.TextSize = 14
            speechLabel.TextWrapped = true
            speechLabel.Parent = speechBubble

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = speechLabel

            -- Play voice sound
            local voiceSound = Instance.new("Sound")
            voiceSound.SoundId = "rbxassetid://12221967"
            voiceSound.Volume = 0.5
            voiceSound.Parent = head
            voiceSound:Play()
            game:GetService("Debris"):AddItem(voiceSound, 2)

            task.delay(3, function()
                if speechBubble and speechBubble.Parent then
                    speechBubble:Destroy()
                end
            end)
        end
    end)

    table.insert(npcs, npcModel)
    return npcModel
end

local function createWall(size, position, parent, color, name)
    local wall = Instance.new("Part")
    wall.Name = name or "Wall"
    wall.Size = size
    wall.Position = position
    wall.Anchored = true
    wall.Material = Enum.Material.Brick
    wall.Color = color
    wall.TopSurface = Enum.SurfaceType.Smooth
    wall.BottomSurface = Enum.SurfaceType.Smooth
    wall.Parent = parent
    return wall
end

local function createWindow(position, parent)
    local window = Instance.new("Part")
    window.Name = "Window"
    window.Size = Vector3.new(3, 2, 0.4)
    window.Position = position
    window.Anchored = true
    window.Material = Enum.Material.Glass
    window.Color = Color3.fromRGB(135, 206, 235)
    window.CanCollide = false
    window.Parent = parent
    return window
end

local function createDoor(position, parent, color)
    local door = Instance.new("Part")
    door.Name = "Door"
    door.Size = Vector3.new(4, 6, 0.5)
    door.Position = position
    door.Anchored = true
    door.Material = Enum.Material.Wood
    door.Color = color
    door.TopSurface = Enum.SurfaceType.Smooth
    door.BottomSurface = Enum.SurfaceType.Smooth
    door.Parent = parent
    return door
end

local function buildHouse(style, position, direction)
    houseIndex += 1
    local house = Instance.new("Model")
    house.Name = "House_" .. houseIndex
    house.Parent = currentCity

    local baseColor, roofColor, houseSize, npcName, reward

    if style == "Poor" then
        baseColor = Color3.fromRGB(220, 180, 140)
        roofColor = Color3.fromRGB(100, 80, 60)
        houseSize = {24, 8, 16}
        npcName = {"Maria", "Tom", "Jake", "Rosa"}[math.random(1, 4)]
        reward = 150
    elseif style == "Medium" then
        baseColor = Color3.fromRGB(240, 220, 180)
        roofColor = Color3.fromRGB(120, 90, 60)
        houseSize = {28, 9, 20}
        npcName = {"David", "Sarah", "Mike", "Lisa"}[math.random(1, 4)]
        reward = 280
    else -- Rich
        baseColor = Color3.fromRGB(250, 240, 200)
        roofColor = Color3.fromRGB(80, 60, 40)
        houseSize = {36, 10, 26}
        npcName = {"Alexander", "Victoria", "James", "Sophia"}[math.random(1, 4)]
        reward = 450
    end

    local w, h, d = houseSize[1], houseSize[2], houseSize[3]

    -- Foundation
    local foundation = Instance.new("Part")
    foundation.Name = "Foundation"
    foundation.Size = Vector3.new(w + 2, 0.5, d + 2)
    foundation.Position = position + Vector3.new(0, 0.25, 0)
    foundation.Anchored = true
    foundation.Material = Enum.Material.Concrete
    foundation.Color = Color3.fromRGB(140, 140, 140)
    foundation.Parent = house

    -- Main walls
    local frontWall = createWall(Vector3.new(w, h, 1), position + Vector3.new(0, h / 2, d / 2), house, baseColor, "FrontWall")
    local backWall = createWall(Vector3.new(w, h, 1), position + Vector3.new(0, h / 2, -d / 2), house, baseColor, "BackWall")
    local leftWall = createWall(Vector3.new(1, h, d), position + Vector3.new(-w / 2, h / 2, 0), house, baseColor, "LeftWall")
    local rightWall = createWall(Vector3.new(1, h, d), position + Vector3.new(w / 2, h / 2, 0), house, baseColor, "RightWall")

    -- Roof
    local roof = Instance.new("Part")
    roof.Name = "Roof"
    roof.Size = Vector3.new(w + 2, 1, d + 2)
    roof.Position = position + Vector3.new(0, h + 0.5, 0)
    roof.Anchored = true
    roof.Material = Enum.Material.Roofing
    roof.Color = roofColor
    roof.Parent = house

    -- Door
    createDoor(position + Vector3.new(0, 3, d / 2 + 0.4), house, Color3.fromRGB(139, 69, 19))

    -- Windows
    createWindow(position + Vector3.new(-w / 4, h / 2 + 1, d / 2 + 0.3), house)
    createWindow(position + Vector3.new(w / 4, h / 2 + 1, d / 2 + 0.3), house)

    if style ~= "Poor" then
        createWindow(position + Vector3.new(-w / 4, h / 2 + 1, -d / 2 - 0.3), house)
        createWindow(position + Vector3.new(w / 4, h / 2 + 1, -d / 2 - 0.3), house)
    end

    -- Side windows for bigger houses
    if style == "Rich" then
        createWindow(position + Vector3.new(-w / 2 - 0.3, h / 2 + 1, -5), house)
        createWindow(position + Vector3.new(w / 2 + 0.3, h / 2 + 1, 5), house)
    end

    -- Chimney for bigger houses
    if style ~= "Poor" then
        local chimney = createWall(Vector3.new(2, 5, 2), position + Vector3.new(w / 2 - 3, h + 3, 0), house, Color3.fromRGB(160, 80, 60), "Chimney")
    end

    house:SetAttribute("HouseId", houseIndex)
    house:SetAttribute("Style", style)
    house:SetAttribute("Reward", reward)
    house:SetAttribute("OwnerName", npcName)
    house:SetAttribute("PaintedAmount", 0)
    house:SetAttribute("PaintGoal", style == "Poor" and 12 or (style == "Medium" and 16 or 20))

    -- Create NPC for this house
    local npcPosition = position + Vector3.new(0, 0, d / 2 + 8)
    createNPC(npcPosition, npcName, house)

    table.insert(houses, house)
    return house
end

local function createCity()
    -- Ground
    local ground = Instance.new("Part")
    ground.Name = "Ground"
    ground.Size = Vector3.new(300, 1, 300)
    ground.Position = Vector3.new(0, -1, 0)
    ground.Anchored = true
    ground.Material = Enum.Material.Grass
    ground.Color = Color3.fromRGB(85, 110, 85)
    ground.CanCollide = true
    ground.Parent = currentCity

    -- Streets
    local mainStreet = Instance.new("Part")
    mainStreet.Name = "MainStreet"
    mainStreet.Size = Vector3.new(150, 0.3, 18)
    mainStreet.Position = Vector3.new(0, 0.2, 0)
    mainStreet.Anchored = true
    mainStreet.Material = Enum.Material.Asphalt
    mainStreet.Color = Color3.fromRGB(40, 40, 50)
    mainStreet.Parent = currentCity

    local crossStreet = Instance.new("Part")
    crossStreet.Name = "CrossStreet"
    crossStreet.Size = Vector3.new(18, 0.3, 150)
    crossStreet.Position = Vector3.new(0, 0.2, 0)
    crossStreet.Anchored = true
    crossStreet.Material = Enum.Material.Asphalt
    crossStreet.Color = Color3.fromRGB(40, 40, 50)
    crossStreet.Parent = currentCity

    -- Road markings
    for i = -60, 60, 10 do
        local marking = Instance.new("Part")
        marking.Size = Vector3.new(2, 0.05, 1)
        marking.Position = Vector3.new(i, 0.25, 0)
        marking.Anchored = true
        marking.Material = Enum.Material.SmoothPlastic
        marking.Color = Color3.fromRGB(255, 255, 200)
        marking.CanCollide = false
        marking.Parent = currentCity
    end

    for i = -60, 60, 10 do
        local marking = Instance.new("Part")
        marking.Size = Vector3.new(1, 0.05, 2)
        marking.Position = Vector3.new(0, 0.25, i)
        marking.Anchored = true
        marking.Material = Enum.Material.SmoothPlastic
        marking.Color = Color3.fromRGB(255, 255, 200)
        marking.CanCollide = false
        marking.Parent = currentCity
    end

    -- Spawn point
    local spawn = Instance.new("Part")
    spawn.Name = "SpawnPoint"
    spawn.Size = Vector3.new(6, 1, 6)
    spawn.Position = Vector3.new(0, 0.5, -70)
    spawn.Anchored = true
    spawn.Material = Enum.Material.Concrete
    spawn.CanCollide = true
    spawn.Transparency = 1
    spawn.Parent = currentCity

    -- Build houses - POOR NEIGHBORHOOD
    buildHouse("Poor", Vector3.new(-60, 0, -60), 1)
    buildHouse("Poor", Vector3.new(-60, 0, -30), 1)
    buildHouse("Poor", Vector3.new(-60, 0, 0), 1)
    buildHouse("Poor", Vector3.new(-60, 0, 30), 1)
    buildHouse("Poor", Vector3.new(-60, 0, 60), 1)

    -- MEDIUM NEIGHBORHOOD
    buildHouse("Medium", Vector3.new(0, 0, -60), 1)
    buildHouse("Medium", Vector3.new(0, 0, -30), 1)
    buildHouse("Medium", Vector3.new(0, 0, 30), 1)
    buildHouse("Medium", Vector3.new(0, 0, 60), 1)

    -- RICH NEIGHBORHOOD
    buildHouse("Rich", Vector3.new(60, 0, -60), 1)
    buildHouse("Rich", Vector3.new(60, 0, -20), 1)
    buildHouse("Rich", Vector3.new(60, 0, 40), 1)
    buildHouse("Rich", Vector3.new(60, 0, 80), 1)

    print("City created with " .. #houses .. " houses and " .. #npcs .. " NPCs")
end

local function paintHouse(player, houseId, partName)
    local house = getHouseById(houseId)
    if not house then return end

    if player:GetAttribute("CurrentJob") ~= houseId then return end

    local target = house:FindFirstChild(partName, true)
    if target and target:IsA("BasePart") then
        if target.Name == "Roof" or target.Name == "FrontWall" or target.Name == "BackWall" or target.Name == "LeftWall" or target.Name == "RightWall" then
            -- Change paint progress color
            target.Color = Color3.fromRGB(200, 120, 70)

            local currentPainted = house:GetAttribute("PaintedAmount") or 0
            local newPainted = currentPainted + 1
            house:SetAttribute("PaintedAmount", newPainted)

            -- Check if house is fully painted
            if newPainted >= (house:GetAttribute("PaintGoal") or 10) then
                local reward = house:GetAttribute("Reward") or 100
                local currentMoney = player:GetAttribute("Money") or 0
                player:SetAttribute("Money", currentMoney + reward)
                player:SetAttribute("CurrentJob", nil)

                -- Completion message
                local completeBubble = Instance.new("BillboardGui")
                completeBubble.Size = UDim2.new(0, 280, 0, 60)
                completeBubble.AlwaysOnTop = true
                completeBubble.StudsOffset = Vector3.new(0, 4, 0)
                completeBubble.Parent = house:FindFirstChild("FrontWall")

                local completeLabel = Instance.new("TextLabel")
                completeLabel.Size = UDim2.new(1, 0, 1, 0)
                completeLabel.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                completeLabel.BorderSizePixel = 2
                completeLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                completeLabel.Font = Enum.Font.GothamBold
                completeLabel.Text = house:GetAttribute("OwnerName") .. ": \"Finished! You earned $" .. reward .. "!\""
                completeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
                completeLabel.TextSize = 14
                completeLabel.TextWrapped = true
                completeLabel.Parent = completeLabel.Parent

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 8)
                corner.Parent = completeLabel

                task.delay(4, function()
                    if completeBubble and completeBubble.Parent then
                        completeBubble:Destroy()
                    end
                end)
            end
        end
    end
end

paintRemote.OnServerEvent:Connect(function(player, houseId, partName)
    paintHouse(player, houseId, partName)
end)

buyRemote.OnServerEvent:Connect(function(player, itemName)
    local money = player:GetAttribute("Money") or 0
    local prices = {
        StandardRoller = 80,
        ProRoller = 180,
        SprayPaint = 120,
        PremiumBrush = 200
    }

    local price = prices[itemName]
    if not price then return end

    if money >= price then
        player:SetAttribute("Money", money - price)
    end
end)

Players.PlayerAdded:Connect(function(player)
    setPlayerDefaults(player)

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local money = Instance.new("IntValue")
    money.Name = "Money"
    money.Value = player:GetAttribute("Money") or 500
    money.Parent = leaderstats
end)

for _, player in ipairs(Players:GetPlayers()) do
    setPlayerDefaults(player)
end

createCity()
print("House Painter Simulator loaded!")
