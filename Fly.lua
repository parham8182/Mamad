-- =====================================================
-- 🍎 BLOX FRUITS MOBILE HUB - حرفه‌ای و کامل
-- 📱 مناسب موبایل | کاملاً فارسی | Keyless
-- ⚡ Auto Farm هوشمند با مدیریت کوئست، جزیره و سلاح
-- =====================================================

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local replicatedStorage = game:GetService("ReplicatedStorage")
local guiService = game:GetService("GuiService")

local Settings = {
    Farming = false,
    Weapon = "مشت",
    CurrentQuest = nil,
    CurrentNPC = nil,
    TargetEnemy = nil,
    CurrentIsland = nil,
    FarmLoop = nil,
    MenuOpen = false,
    DragOffset = nil,
    IsDragging = false
}

local QuestData = {
    { level = 1, npc = "مرد دریایی", island = "جزیره شروع", quest = "کشتن 5 دزد دریایی" },
    { level = 10, npc = "دزد دریایی", island = "جزیره اول", quest = "کشتن 8 دزد دریایی" },
    { level = 30, npc = "گوریل", island = "جزیره جنگل", quest = "کشتن 10 گوریل" },
    { level = 50, npc = "مرد شنی", island = "جزیره شن", quest = "کشتن 12 مرد شنی" },
}

local function getCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    if not character then return false end
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    return true
end

local function findNearestEnemy(npcName)
    local nearest = nil
    local minDist = math.huge
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Name == npcName or (v.Name:lower():find(npcName:lower())) then
                local dist = (rootPart.Position - v.HumanoidRootPart.Position).Magnitude
                if dist < minDist and v.Humanoid.Health > 0 then
                    nearest = v
                    minDist = dist
                end
            end
        end
    end
    return nearest
end

local function getQuestForLevel(level)
    local selected = nil
    for _, quest in ipairs(QuestData) do
        if level >= quest.level then
            selected = quest
        else
            break
        end
    end
    return selected
end

local function getIslandPosition(islandName)
    local positions = {
        ["جزیره شروع"] = Vector3.new(-1000, 0, -1000),
        ["جزیره اول"] = Vector3.new(0, 0, 0),
        ["جزیره جنگل"] = Vector3.new(1000, 0, 1000),
        ["جزیره شن"] = Vector3.new(2000, 0, 2000),
    }
    return positions[islandName] or Vector3.new(0, 0, 0)
end

local function getWeaponTool()
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            if Settings.Weapon == "مشت" and tool.Name:lower():find("fist") then
                return tool
            elseif Settings.Weapon == "شمشیر" and tool.Name:lower():find("sword") then
                return tool
            elseif Settings.Weapon == "میوه" and tool.Name:lower():find("fruit") then
                return tool
            elseif Settings.Weapon == "تفنگ" and tool.Name:lower():find("gun") then
                return tool
            end
        end
    end
    return nil
end

local function equipBestWeapon()
    local tool = getWeaponTool()
    if tool then
        character.Humanoid:EquipTool(tool)
        return true
    else
        for _, t in ipairs(character:GetChildren()) do
            if t:IsA("Tool") then
                character.Humanoid:EquipTool(t)
                return true
            end
        end
    end
    return false
end

local function attackEnemy(enemy)
    if not enemy or not enemy.Humanoid or enemy.Humanoid.Health <= 0 then return false end
    local targetPos = enemy.HumanoidRootPart.Position
    rootPart.CFrame = CFrame.new(rootPart.Position, Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z))
    local tool = character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Handle") then
        tool:Activate()
    end
    return true
end

local function stopFarming()
    Settings.Farming = false
    if Settings.FarmLoop then
        Settings.FarmLoop:Disconnect()
        Settings.FarmLoop = nil
    end
    Settings.CurrentQuest = nil
    Settings.CurrentNPC = nil
    Settings.TargetEnemy = nil
    Settings.CurrentIsland = nil
end

local function startFarming()
    if Settings.Farming then return end
    if not getCharacter() then return end
    Settings.Farming = true
    Settings.FarmLoop = runService.Heartbeat:Connect(function()
        if not Settings.Farming or not character or not humanoid or humanoid.Health <= 0 then
            return
        end

        local level = player:FindFirstChild("Data") and player.Data:FindFirstChild("Level") and player.Data.Level.Value or 1
        local quest = getQuestForLevel(level)
        if not quest then return end

        if not Settings.CurrentQuest or Settings.CurrentQuest ~= quest then
            Settings.CurrentQuest = quest
            Settings.CurrentNPC = quest.npc
            Settings.CurrentIsland = quest.island
            local islandPos = getIslandPosition(quest.island)
            if islandPos then
                tweenService:Create(rootPart, TweenInfo.new(5), {CFrame = CFrame.new(islandPos)}):Play()
            end
        end

        if not Settings.TargetEnemy or not Settings.TargetEnemy.Parent or not Settings.TargetEnemy:FindFirstChild("Humanoid") or Settings.TargetEnemy.Humanoid.Health <= 0 then
            Settings.TargetEnemy = findNearestEnemy(Settings.CurrentNPC)
        end

        if Settings.TargetEnemy then
            local enemyPos = Settings.TargetEnemy.HumanoidRootPart.Position
            local dist = (rootPart.Position - enemyPos).Magnitude
            if dist > 10 then
                rootPart.CFrame = CFrame.new(rootPart.Position, Vector3.new(enemyPos.X, rootPart.Position.Y, enemyPos.Z))
                humanoid:MoveTo(enemyPos)
            else
                equipBestWeapon()
                attackEnemy(Settings.TargetEnemy)
            end
        end
    end)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BloxFruitsMobileHub"
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false

local floatingButton = Instance.new("ImageButton")
floatingButton.Size = UDim2.new(0, 60, 0, 60)
floatingButton.Position = UDim2.new(0.02, 0, 0.05, 0)
floatingButton.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
floatingButton.BackgroundTransparency = 0
floatingButton.Image = "rbxassetid://6031090972"
floatingButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
floatingButton.ScaleType = Enum.ScaleType.Fit
floatingButton.Parent = screenGui

local cornerF = Instance.new("UICorner")
cornerF.CornerRadius = UDim.new(1, 0)
cornerF.Parent = floatingButton

local shadowF = Instance.new("UIStroke")
shadowF.Color = Color3.fromRGB(255, 255, 255)
shadowF.Thickness = 2
shadowF.Transparency = 0.5
shadowF.Parent = floatingButton

local mainMenu = Instance.new("Frame")
mainMenu.Size = UDim2.new(0, 350, 0, 500)
mainMenu.Position = UDim2.new(0.5, -175, 0.5, -250)
mainMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainMenu.BackgroundTransparency = 0.1
mainMenu.BorderSizePixel = 0
mainMenu.Visible = false
mainMenu.Parent = screenGui

local cornerM = Instance.new("UICorner")
cornerM.CornerRadius = UDim.new(0, 15)
cornerM.Parent = mainMenu

local shadowM = Instance.new("UIStroke")
shadowM.Color = Color3.fromRGB(100, 150, 255)
shadowM.Thickness = 2
shadowM.Transparency = 0.6
shadowM.Parent = mainMenu

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🍎 Blox Fruits Hub"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainMenu

local line = Instance.new("Frame")
line.Size = UDim2.new(0.9, 0, 0, 2)
line.Position = UDim2.new(0.05, 0, 0, 55)
line.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
line.BackgroundTransparency = 0.5
line.Parent = mainMenu

local farmButton = Instance.new("TextButton")
farmButton.Size = UDim2.new(0.85, 0, 0, 55)
farmButton.Position = UDim2.new(0.075, 0, 0, 70)
farmButton.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
farmButton.Text = "⚔️ اتو فارم لول"
farmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
farmButton.TextScaled = true
farmButton.Font = Enum.Font.GothamBold
local cornerFB = Instance.new("UICorner")
cornerFB.CornerRadius = UDim.new(0, 10)
cornerFB.Parent = farmButton
farmButton.Parent = mainMenu

local weaponLabel = Instance.new("TextLabel")
weaponLabel.Size = UDim2.new(0.85, 0, 0, 30)
weaponLabel.Position = UDim2.new(0.075, 0, 0, 140)
weaponLabel.BackgroundTransparency = 1
weaponLabel.Text = "🎯 با چی اتو فارم کند؟"
weaponLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
weaponLabel.TextScaled = true
weaponLabel.Font = Enum.Font.GothamMedium
weaponLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponLabel.Parent = mainMenu

local weaponButtons = {}
local weaponNames = {"مشت", "شمشیر", "میوه", "تفنگ"}
local weaponColors = {Color3.fromRGB(255, 100, 100), Color3.fromRGB(100, 200, 255), Color3.fromRGB(255, 200, 50), Color3.fromRGB(150, 255, 150)}
local startY = 180
local btnWidth = 0.2
local spacing = 0.05
local totalWidth = btnWidth * 4 + spacing * 3
local startX = (1 - totalWidth) / 2

for i, name in ipairs(weaponNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(btnWidth, 0, 0, 45)
    btn.Position = UDim2.new(startX + (btnWidth + spacing) * (i-1), 0, 0, startY)
    btn.BackgroundColor3 = weaponColors[i]
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    local cornerBtn = Instance.new("UICorner")
    cornerBtn.CornerRadius = UDim.new(0, 8)
    cornerBtn.Parent = btn
    btn.Parent = mainMenu
    weaponButtons[name] = btn
end

local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(0.85, 0, 0, 100)
statusFrame.Position = UDim2.new(0.075, 0, 0, 250)
statusFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
statusFrame.BackgroundTransparency = 0.5
local cornerSF = Instance.new("UICorner")
cornerSF.CornerRadius = UDim.new(0, 8)
cornerSF.Parent = statusFrame
statusFrame.Parent = mainMenu

local statusLines = {}
local statusTexts = {"Auto Farm: OFF", "Quest: -", "Target: -", "Level: -", "Weapon: -", "Island: -"}
for i, text in ipairs(statusTexts) do
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 16)
    label.Position = UDim2.new(0, 0, 0, (i-1)*17)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextScaled = false
    label.TextSize = 14
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = statusFrame
    statusLines[i] = label
end

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.4, 0, 0, 40)
closeBtn.Position = UDim2.new(0.3, 0, 0, 440)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "❌ بستن"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
local cornerCB = Instance.new("UICorner")
cornerCB.CornerRadius = UDim.new(0, 8)
cornerCB.Parent = closeBtn
closeBtn.Parent = mainMenu

floatingButton.MouseButton1Click:Connect(function()
    Settings.MenuOpen = not Settings.MenuOpen
    mainMenu.Visible = Settings.MenuOpen
end)

farmButton.MouseButton1Click:Connect(function()
    if Settings.Farming then
        stopFarming()
        farmButton.Text = "⚔️ اتو فارم لول"
        farmButton.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
        statusLines[1].Text = "Auto Farm: OFF"
    else
        startFarming()
        farmButton.Text = "⏹ توقف فارم"
        farmButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        statusLines[1].Text = "Auto Farm: ON"
    end
end)

for name, btn in pairs(weaponButtons) do
    btn.MouseButton1Click:Connect(function()
        Settings.Weapon = name
        for n, b in pairs(weaponButtons) do
            b.BackgroundTransparency = 0
        end
        btn.BackgroundTransparency = 0.3
        statusLines[5].Text = "Weapon: " .. name
    end)
end

closeBtn.MouseButton1Click:Connect(function()
    mainMenu.Visible = false
    Settings.MenuOpen = false
end)

local function makeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

makeDraggable(mainMenu)
makeDraggable(floatingButton)

local function updateStatus()
    while wait(1) do
        if not mainMenu.Visible then continue end
        local level = player:FindFirstChild("Data") and player.Data:FindFirstChild("Level") and player.Data.Level.Value or "?"
        statusLines[4].Text = "Level: " .. tostring(level)
        if Settings.CurrentQuest then
            statusLines[2].Text = "Quest: " .. Settings.CurrentQuest.quest
            statusLines[3].Text = "Target: " .. Settings.CurrentNPC
            statusLines[6].Text = "Island: " .. Settings.CurrentIsland
        else
            statusLines[2].Text = "Quest: -"
            statusLines[3].Text = "Target: -"
            statusLines[6].Text = "Island: -"
        end
        statusLines[5].Text = "Weapon: " .. Settings.Weapon
    end
end

coroutine.wrap(updateStatus)()

player.CharacterAdded:Connect(function()
    wait(1)
    getCharacter()
    if Settings.Farming then
        startFarming()
    end
end)

game:BindToClose(function()
    stopFarming()
end)

print("✅ Blox Fruits Mobile Hub loaded successfully!")
print("📱 Tap the floating icon to open the menu.")