-- =====================================================
-- 🍎 پژمان هاب - نسخه موبایل
--    Script Hub حرفه‌ای برای Blox Fruits
--    طراحی مدرن، مینیمال و کاملاً فارسی
-- =====================================================

-- =====================================================
-- 📦 تنظیمات اولیه و متغیرها
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

-- تنظیمات وضعیت
local Settings = {
    Farming = false,
    Weapon = "مشت", -- "مشت", "شمشیر", "میوه", "تفنگ"
    CurrentQuest = nil,
    CurrentNPC = nil,
    TargetEnemy = nil,
    CurrentIsland = nil,
    FarmLoop = nil,
    MenuOpen = false,
    DragOffset = nil,
    IsDragging = false
}

-- داده‌های کوئست (نمونه)
local QuestData = {
    { level = 1, npc = "مرد دریایی", island = "جزیره شروع", quest = "کشتن 5 دزد دریایی" },
    { level = 10, npc = "دزد دریایی", island = "جزیره اول", quest = "کشتن 8 دزد دریایی" },
    { level = 30, npc = "گوریل", island = "جزیره جنگل", quest = "کشتن 10 گوریل" },
    { level = 50, npc = "مرد شنی", island = "جزیره شن", quest = "کشتن 12 مرد شنی" },
    -- ادامه دهید...
}

-- =====================================================
-- 🛠 توابع کمکی (همان‌های قبلی با بهبود)
-- =====================================================

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
        humanoid:EquipTool(tool)
        return true
    else
        for _, t in ipairs(character:GetChildren()) do
            if t:IsA("Tool") then
                humanoid:EquipTool(t)
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

-- =====================================================
-- 🎯 سیستم Auto Farm (همان قبلی با اصلاحات)
-- =====================================================

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
            if humanoid and humanoid.Health <= 0 then
                wait(3)
                getCharacter()
            end
            return
        end

        -- دریافت سطح (با فرض وجود Data)
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
                wait(5)
            end
        end

        if not Settings.TargetEnemy or not Settings.TargetEnemy.Parent or Settings.TargetEnemy.Humanoid.Health <= 0 then
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
        else
            wait(0.5)
        end
    end)
end

-- =====================================================
-- 📱 رابط کاربری (UI) - پژمان هاب
-- =====================================================

-- ایجاد ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PezhmanHub"
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false

-- =====================================================
-- 🔵 آیکون شناور (بالا سمت چپ)
-- =====================================================

local floatingButton = Instance.new("ImageButton")
floatingButton.Size = UDim2.new(0, 65, 0, 65)
floatingButton.Position = UDim2.new(0.03, 0, 0.05, 0)
floatingButton.BackgroundColor3 = Color3.fromRGB(40, 80, 200)
floatingButton.BackgroundTransparency = 0.15
floatingButton.Image = "rbxassetid://6031090972"
floatingButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
floatingButton.ScaleType = Enum.ScaleType.Fit
floatingButton.Parent = screenGui

-- گرد کردن و سایه
local cornerF = Instance.new("UICorner")
cornerF.CornerRadius = UDim.new(1, 0)
cornerF.Parent = floatingButton

local shadowF = Instance.new("UIStroke")
shadowF.Color = Color3.fromRGB(255, 255, 255)
shadowF.Thickness = 2
shadowF.Transparency = 0.4
shadowF.Parent = floatingButton

-- =====================================================
-- 📋 منوی اصلی «پژمان هاب»
-- =====================================================

local mainMenu = Instance.new("Frame")
mainMenu.Size = UDim2.new(0, 380, 0, 560)
mainMenu.Position = UDim2.new(0.5, -190, 0.5, -280)
mainMenu.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
mainMenu.BackgroundTransparency = 0.15
mainMenu.BorderSizePixel = 0
mainMenu.Visible = false
mainMenu.Parent = screenGui

-- گوشه‌های گرد
local cornerM = Instance.new("UICorner")
cornerM.CornerRadius = UDim.new(0, 20)
cornerM.Parent = mainMenu

-- سایه اصلی
local shadowM = Instance.new("UIStroke")
shadowM.Color = Color3.fromRGB(100, 150, 255)
shadowM.Thickness = 2.5
shadowM.Transparency = 0.5
shadowM.Parent = mainMenu

-- =====================================================
-- 🌊 Watermark پس‌زمینه «پژمان هاب»
-- =====================================================

local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(1, 0, 1, 0)
watermark.Position = UDim2.new(0, 0, 0, 0)
watermark.BackgroundTransparency = 1
watermark.Text = "پژمان هاب"
watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
watermark.TextScaled = true
watermark.TextSize = 80
watermark.Font = Enum.Font.GothamBold
watermark.TextTransparency = 0.9
watermark.TextXAlignment = Enum.TextXAlignment.Center
watermark.TextYAlignment = Enum.TextYAlignment.Center
watermark.Parent = mainMenu

-- =====================================================
-- 🏷️ عنوان اصلی «پژمان هاب»
-- =====================================================

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 70)
titleLabel.Position = UDim2.new(0, 0, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "پژمان هاب"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.TextSize = 40
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextTransparency = 0.1
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Parent = mainMenu

-- خط جداکننده
local line = Instance.new("Frame")
line.Size = UDim2.new(0.85, 0, 0, 2)
line.Position = UDim2.new(0.075, 0, 0, 85)
line.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
line.BackgroundTransparency = 0.6
line.Parent = mainMenu

-- =====================================================
-- ⚔️ دکمه Toggle Auto Farm
-- =====================================================

local farmFrame = Instance.new("Frame")
farmFrame.Size = UDim2.new(0.85, 0, 0, 55)
farmFrame.Position = UDim2.new(0.075, 0, 0, 100)
farmFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
farmFrame.BackgroundTransparency = 0.3
local cornerFF = Instance.new("UICorner")
cornerFF.CornerRadius = UDim.new(0, 12)
cornerFF.Parent = farmFrame
farmFrame.Parent = mainMenu

-- برچسب
local farmLabel = Instance.new("TextLabel")
farmLabel.Size = UDim2.new(0.7, 0, 1, 0)
farmLabel.Position = UDim2.new(0.05, 0, 0, 0)
farmLabel.BackgroundTransparency = 1
farmLabel.Text = "⚔️ اتو فارم لول"
farmLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
farmLabel.TextScaled = true
farmLabel.TextSize = 20
farmLabel.Font = Enum.Font.GothamMedium
farmLabel.TextXAlignment = Enum.TextXAlignment.Left
farmLabel.Parent = farmFrame

-- دکمه Toggle
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.25, 0, 0.7, 0)
toggleBtn.Position = UDim2.new(0.72, 0, 0.15, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
toggleBtn.Text = "OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextScaled = true
toggleBtn.TextSize = 18
toggleBtn.Font = Enum.Font.GothamBold
local cornerTB = Instance.new("UICorner")
cornerTB.CornerRadius = UDim.new(0, 8)
cornerTB.Parent = toggleBtn
toggleBtn.Parent = farmFrame

-- =====================================================
-- 🎯 انتخاب سلاح
-- =====================================================

local weaponLabel = Instance.new("TextLabel")
weaponLabel.Size = UDim2.new(0.85, 0, 0, 30)
weaponLabel.Position = UDim2.new(0.075, 0, 0, 170)
weaponLabel.BackgroundTransparency = 1
weaponLabel.Text = "🎯 با چی اتو فارم کند؟"
weaponLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
weaponLabel.TextScaled = true
weaponLabel.TextSize = 18
weaponLabel.Font = Enum.Font.GothamMedium
weaponLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponLabel.Parent = mainMenu

-- دکمه‌های انتخاب سلاح (4 عدد در یک ردیف)
local weaponButtons = {}
local weaponNames = {"مشت", "شمشیر", "میوه", "تفنگ"}
local weaponIcons = {"👊", "⚔️", "🍎", "🔫"}
local weaponColors = {Color3.fromRGB(255, 100, 100), Color3.fromRGB(100, 200, 255), Color3.fromRGB(255, 200, 50), Color3.fromRGB(150, 255, 150)}
local startYw = 210
local btnW = 0.2
local spacingW = 0.033
local totalW = btnW * 4 + spacingW * 3
local startXw = (1 - totalW) / 2

for i, name in ipairs(weaponNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(btnW, 0, 0, 50)
    btn.Position = UDim2.new(startXw + (btnW + spacingW) * (i-1), 0, 0, startYw)
    btn.BackgroundColor3 = weaponColors[i]
    btn.BackgroundTransparency = 0.3
    btn.Text = weaponIcons[i] .. " " .. name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.TextSize = 16
    btn.Font = Enum.Font.GothamBold
    local cornerBtn = Instance.new("UICorner")
    cornerBtn.CornerRadius = UDim.new(0, 10)
    cornerBtn.Parent = btn
    btn.Parent = mainMenu
    weaponButtons[name] = btn
end

-- =====================================================
-- 📊 بخش وضعیت (Status Card)
-- =====================================================

local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(0.85, 0, 0, 140)
statusFrame.Position = UDim2.new(0.075, 0, 0, 280)
statusFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
statusFrame.BackgroundTransparency = 0.2
local cornerSF = Instance.new("UICorner")
cornerSF.CornerRadius = UDim.new(0, 12)
cornerSF.Parent = statusFrame
statusFrame.Parent = mainMenu

-- عنوان کارت
local statusTitle = Instance.new("TextLabel")
statusTitle.Size = UDim2.new(1, 0, 0, 25)
statusTitle.Position = UDim2.new(0, 0, 0, 5)
statusTitle.BackgroundTransparency = 1
statusTitle.Text = "📊 وضعیت سیستم"
statusTitle.TextColor3 = Color3.fromRGB(180, 180, 200)
statusTitle.TextScaled = true
statusTitle.TextSize = 16
statusTitle.Font = Enum.Font.GothamMedium
statusTitle.TextXAlignment = Enum.TextXAlignment.Center
statusTitle.Parent = statusFrame

-- خط جداکننده داخلی
local line2 = Instance.new("Frame")
line2.Size = UDim2.new(0.9, 0, 0, 1)
line2.Position = UDim2.new(0.05, 0, 0, 32)
line2.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
line2.BackgroundTransparency = 0.7
line2.Parent = statusFrame

-- لیبل‌های وضعیت
local statusLines = {}
local statusTexts = {
    "● اتو فارم: خاموش",
    "ماموریت: ---",
    "هدف: ---",
    "لول: ?",
    "سلاح: مشت",
    "جزیره: ---"
}
for i, text in ipairs(statusTexts) do
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.95, 0, 0, 17)
    label.Position = UDim2.new(0.05, 0, 0, 35 + (i-1)*18)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.TextScaled = false
    label.TextSize = 14
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = statusFrame
    statusLines[i] = label
end

-- =====================================================
-- ❌ دکمه بستن منو
-- =====================================================

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.4, 0, 0, 45)
closeBtn.Position = UDim2.new(0.3, 0, 0, 490)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BackgroundTransparency = 0.2
closeBtn.Text = "✖ بستن"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
local cornerCB = Instance.new("UICorner")
cornerCB.CornerRadius = UDim.new(0, 10)
cornerCB.Parent = closeBtn
closeBtn.Parent = mainMenu

-- =====================================================
-- 🔄 رویدادها و انیمیشن‌ها
-- =====================================================

-- آیکون شناور: باز/بستن منو با انیمیشن
floatingButton.MouseButton1Click:Connect(function()
    Settings.MenuOpen = not Settings.MenuOpen
    if Settings.MenuOpen then
        mainMenu.Visible = true
        mainMenu.BackgroundTransparency = 0.15
        tweenService:Create(mainMenu, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.15}):Play()
    else
        tweenService:Create(mainMenu, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
        wait(0.2)
        mainMenu.Visible = false
    end
end)

-- Toggle Auto Farm
toggleBtn.MouseButton1Click:Connect(function()
    if Settings.Farming then
        stopFarming()
        toggleBtn.Text = "OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        statusLines[1].Text = "● اتو فارم: خاموش"
        tweenService:Create(toggleBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
    else
        startFarming()
        toggleBtn.Text = "ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
        statusLines[1].Text = "● اتو فارم: روشن"
        tweenService:Create(toggleBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
    end
end)

-- انتخاب سلاح با هایلایت
for name, btn in pairs(weaponButtons) do
    btn.MouseButton1Click:Connect(function()
        Settings.Weapon = name
        for n, b in pairs(weaponButtons) do
            b.BackgroundTransparency = 0.3
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        btn.BackgroundTransparency = 0.1
        btn.TextColor3 = Color3.fromRGB(255, 255, 200)
        statusLines[5].Text = "سلاح: " .. name
        tweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(btnW*1.05, 0, 0, 52)}):Play()
        wait(0.1)
        tweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(btnW, 0, 0, 50)}):Play()
    end)
end

-- بستن منو
closeBtn.MouseButton1Click:Connect(function()
    if Settings.MenuOpen then
        Settings.MenuOpen = false
        tweenService:Create(mainMenu, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        wait(0.2)
        mainMenu.Visible = false
    end
end)

-- =====================================================
-- 🖱 قابلیت Drag کردن منو و آیکون
-- =====================================================

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

-- =====================================================
-- 🔄 به‌روزرسانی وضعیت در UI
-- =====================================================

local function updateStatus()
    while wait(0.5) do
        if not mainMenu.Visible then continue end
        local level = player:FindFirstChild("Data") and player.Data:FindFirstChild("Level") and player.Data.Level.Value or "?"
        statusLines[4].Text = "لول: " .. tostring(level)
        if Settings.CurrentQuest then
            statusLines[2].Text = "ماموریت: " .. Settings.CurrentQuest.quest
            statusLines[3].Text = "هدف: " .. Settings.CurrentNPC
            statusLines[6].Text = "جزیره: " .. Settings.CurrentIsland
        else
            statusLines[2].Text = "ماموریت: ---"
            statusLines[3].Text = "هدف: ---"
            statusLines[6].Text = "جزیره: ---"
        end
        statusLines[5].Text = "سلاح: " .. Settings.Weapon
    end
end

coroutine.wrap(updateStatus)()

-- =====================================================
-- 🧹 پاکسازی و مدیریت ری‌اسپاون
-- =====================================================

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

-- انتخاب پیش‌فرض سلاح (مشت)
weaponButtons["مشت"].BackgroundTransparency = 0.1
weaponButtons["مشت"].TextColor3 = Color3.fromRGB(255, 255, 200)

-- =====================================================
-- ✅ پایان اسکریپت
-- =====================================================

print("✅ پژمان هاب با موفقیت بارگذاری شد!")
print("📱 برای باز کردن منو، روی آیکون شناور ضربه بزنید.")