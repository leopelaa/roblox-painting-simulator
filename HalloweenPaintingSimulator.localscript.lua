-- House Painter Client
-- Put this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local remotes = ReplicatedStorage:WaitForChild("PainterRemotes")
local paintRemote = remotes:WaitForChild("PaintHouse")
local buyRemote = remotes:WaitForChild("BuyUpgrade")

local currentHouseId = nil
local selectedColor = Color3.fromRGB(220, 100, 70)
local isPainting = false
local paintCooldown = 0
local paintRate = 0.3

local function createHUD()
    local gui = Instance.new("ScreenGui")
    gui.Name = "PainterHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Main info panel
    local topPanel = Instance.new("Frame")
    topPanel.Name = "TopPanel"
    topPanel.Size = UDim2.new(0, 400, 0, 140)
    topPanel.Position = UDim2.new(0, 20, 0, 20)
    topPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    topPanel.BorderSizePixel = 0
    topPanel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = topPanel

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 140, 70)
    stroke.Thickness = 2
    stroke.Parent = topPanel

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.Text = "House Painter"
    titleLabel.TextColor3 = Color3.fromRGB(255, 150, 70)
    titleLabel.TextSize = 24
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topPanel

    -- Money Label
    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Name = "MoneyLabel"
    moneyLabel.Size = UDim2.new(1, -20, 0, 25)
    moneyLabel.Position = UDim2.new(0, 10, 0, 42)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Font = Enum.Font.Gotham
    moneyLabel.Text = "Money: $500"
    moneyLabel.TextColor3 = Color3.fromRGB(200, 255, 100)
    moneyLabel.TextSize = 18
    moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
    moneyLabel.Parent = topPanel

    -- Job Label
    local jobLabel = Instance.new("TextLabel")
    jobLabel.Name = "JobLabel"
    jobLabel.Size = UDim2.new(1, -20, 0, 25)
    jobLabel.Position = UDim2.new(0, 10, 0, 72)
    jobLabel.BackgroundTransparency = 1
    jobLabel.Font = Enum.Font.Gotham
    jobLabel.Text = "Job: None"
    jobLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    jobLabel.TextSize = 16
    jobLabel.TextXAlignment = Enum.TextXAlignment.Left
    jobLabel.Parent = topPanel

    -- Help text
    local helpLabel = Instance.new("TextLabel")
    helpLabel.Name = "HelpLabel"
    helpLabel.Size = UDim2.new(1, -20, 0, 20)
    helpLabel.Position = UDim2.new(0, 10, 0, 103)
    helpLabel.BackgroundTransparency = 1
    helpLabel.Font = Enum.Font.GothamBold
    helpLabel.Text = "Click to paint | SHOP (S) | Pick color (C)"
    helpLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    helpLabel.TextSize = 12
    helpLabel.TextXAlignment = Enum.TextXAlignment.Left
    helpLabel.Parent = topPanel

    -- Shop button
    local shopButton = Instance.new("TextButton")
    shopButton.Name = "ShopButton"
    shopButton.Size = UDim2.new(0, 100, 0, 40)
    shopButton.Position = UDim2.new(1, -130, 0, 20)
    shopButton.BackgroundColor3 = Color3.fromRGB(255, 140, 70)
    shopButton.Text = "SHOP"
    shopButton.Font = Enum.Font.GothamBold
    shopButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    shopButton.TextSize = 16
    shopButton.BorderSizePixel = 0
    shopButton.Parent = gui

    local shopCorner = Instance.new("UICorner")
    shopCorner.CornerRadius = UDim.new(0, 12)
    shopCorner.Parent = shopButton

    -- Shop panel
    local shopPanel = Instance.new("Frame")
    shopPanel.Name = "ShopPanel"
    shopPanel.Visible = false
    shopPanel.Size = UDim2.new(0, 280, 0, 220)
    shopPanel.Position = UDim2.new(1, -320, 0, 70)
    shopPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    shopPanel.BorderSizePixel = 0
    shopPanel.Parent = gui

    local shopCorner2 = Instance.new("UICorner")
    shopCorner2.CornerRadius = UDim.new(0, 16)
    shopCorner2.Parent = shopPanel

    local shopStroke = Instance.new("UIStroke")
    shopStroke.Color = Color3.fromRGB(255, 140, 70)
    shopStroke.Thickness = 2
    shopStroke.Parent = shopPanel

    local shopTitleLabel = Instance.new("TextLabel")
    shopTitleLabel.Size = UDim2.new(1, -20, 0, 30)
    shopTitleLabel.Position = UDim2.new(0, 10, 0, 8)
    shopTitleLabel.BackgroundTransparency = 1
    shopTitleLabel.Font = Enum.Font.GothamBold
    shopTitleLabel.Text = "Shop"
    shopTitleLabel.TextColor3 = Color3.fromRGB(255, 150, 70)
    shopTitleLabel.TextSize = 20
    shopTitleLabel.Parent = shopPanel

    local items = {
        {name = "Standard Roller", price = 80},
        {name = "Pro Roller", price = 180},
        {name = "Spray Paint", price = 120},
        {name = "Premium Brush", price = 200}
    }

    local yPos = 45
    for _, item in ipairs(items) do
        local itemButton = Instance.new("TextButton")
        itemButton.Size = UDim2.new(1, -20, 0, 35)
        itemButton.Position = UDim2.new(0, 10, 0, yPos)
        itemButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        itemButton.Font = Enum.Font.Gotham
        itemButton.Text = item.name .. " - $" .. item.price
        itemButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        itemButton.TextSize = 14
        itemButton.BorderSizePixel = 0
        itemButton.Parent = shopPanel

        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 8)
        itemCorner.Parent = itemButton

        itemButton.MouseButton1Click:Connect(function()
            buyRemote:FireServer(item.name)
        end)

        yPos = yPos + 40
    end

    shopButton.MouseButton1Click:Connect(function()
        shopPanel.Visible = not shopPanel.Visible
    end)

    return gui
end

local function updateHUD()
    local gui = player:FindFirstChild("PlayerGui"):FindFirstChild("PainterHUD")
    if not gui then return end

    local topPanel = gui:FindFirstChild("TopPanel")
    if not topPanel then return end

    local moneyLabel = topPanel:FindFirstChild("MoneyLabel")
    if moneyLabel then
        moneyLabel.Text = "Money: $" .. tostring(player:GetAttribute("Money") or 0)
    end

    local jobLabel = topPanel:FindFirstChild("JobLabel")
    if jobLabel then
        local currentJob = player:GetAttribute("CurrentJob")
        if currentJob then
            jobLabel.Text = "Job: House #" .. tostring(currentJob)
        else
            jobLabel.Text = "Job: None"
        end
    end
end

local function paintWall()
    if not isPainting then return end
    if os.clock() - paintCooldown < paintRate then return end
    if not player:GetAttribute("CurrentJob") then return end

    local target = mouse.Target
    if not target then return end
    if not target:IsDescendantOf(workspace.PainterCity) then return end

    local house = target:FindFirstAncestorOfClass("Model")
    if not house then return end
    if not house.Name:find("House_") then return end

    local houseId = house:GetAttribute("HouseId")
    if houseId ~= player:GetAttribute("CurrentJob") then return end

    if target.Name == "FrontWall" or target.Name == "BackWall" or target.Name == "LeftWall" or target.Name == "RightWall" or target.Name == "Roof" then
        paintCooldown = os.clock()
        paintRemote:FireServer(houseId, target.Name)
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.S then
        local gui = player:FindFirstChild("PlayerGui"):FindFirstChild("PainterHUD")
        if gui then
            local shopPanel = gui:FindFirstChild("ShopPanel")
            if shopPanel then
                shopPanel.Visible = not shopPanel.Visible
            end
        end
    end
end)

mouse.Button1Down:Connect(function()
    isPainting = true
end)

mouse.Button1Up:Connect(function()
    isPainting = false
end)

RunService.RenderStepped:Connect(function()
    updateHUD()
    paintWall()
end)

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end)

createHUD()
print("Painter client loaded!")
