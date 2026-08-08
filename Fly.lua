-- ==============================================
-- اسکریپت پرواز حرفه‌ای با منوی فارسی
-- سازگار با موبایل و کامپیوتر | کاملاً FE
-- ==============================================

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local runService = game:GetService("RunService")
local userInput = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

-- متغیرهای اصلی
local flying = false
local speed = 30
local bodyVelocity = nil
local bodyForce = nil
local noclip = true
local connection = nil
local character = nil
local humanoid = nil
local rootPart = nil

-- ==============================================
-- بخش توابع پرواز
-- ==============================================

local function getCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    if not character then return false end
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    return true
end

local function startFly()
    if not getCharacter() then return end
    if flying then return end
    
    flying = true
    
    -- BodyVelocity برای حرکت
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 100000
    bodyVelocity.P = 5000
    bodyVelocity.Parent = rootPart
    
    -- BodyForce برای خنثی‌سازی جاذبه (شناور ماندن)
    bodyForce = Instance.new("BodyForce")
    bodyForce.Force = Vector3.new(0, rootPart.AssemblyMass * workspace.Gravity, 0)
    bodyForce.Parent = rootPart
    
    -- حلقه اصلی پرواز
    connection = runService.Heartbeat:Connect(function()
        if not flying or not rootPart or not humanoid then return end
        
        local moveDirection = humanoid.MoveDirection
        local lookVector = camera.CFrame.LookVector
        local rightVector = camera.CFrame.RightVector
        
        -- محاسبه حرکت بر اساس WASD و جهت دوربین
        local forward = lookVector * moveDirection.Z
        local right = rightVector * moveDirection.X
        local up = Vector3.new(0, moveDirection.Y, 0)
        
        local velocity = (forward + right + up) * speed
        
        -- اگر هیچ کلیدی زده نشد، در هوا ثابت می‌ماند
        if moveDirection.Magnitude == 0 then
            velocity = Vector3.new(0, 0, 0)
        end
        
        bodyVelocity.Velocity = velocity
        
        -- Noclip (عبور از دیوار)
        if noclip then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function stopFly()
    flying = false
    
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyForce then bodyForce:Destroy() bodyForce = nil end
    if connection then connection:Disconnect() connection = nil end
    
    -- برگرداندن برخوردها به حالت عادی
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- ==============================================
-- بخش ساخت منوی گرافیکی (GUI) به زبان فارسی
-- ==============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PersianFlyMenu"
screenGui.Parent = player.PlayerGui

-- فریم اصلی منو
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 320)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- سایه و گردی گوشه‌ها
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local shadow = Instance.new("UIStroke")
shadow.Color = Color3.fromRGB(100, 150, 255)
shadow.Thickness = 2
shadow.Transparency = 0.5
shadow.Parent = mainFrame

-- عنوان منو
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🚀 پنل پرواز حرفه‌ای"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- خط جداکننده
local line = Instance.new("Frame")
line.Size = UDim2.new(0.9, 0, 0, 2)
line.Position = UDim2.new(0.05, 0, 0, 45)
line.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
line.BackgroundTransparency = 0.5
line.Parent = mainFrame

-- دکمه شروع/توقف پرواز
toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.85, 0, 0, 50)
toggleButton.Position = UDim2.new(0.075, 0, 0, 60)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
toggleButton.Text = "🔥 شروع پرواز"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleButton
toggleButton.Parent = mainFrame

-- بخش تنظیم سرعت
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.4, 0, 0, 40)
speedLabel.Position = UDim2.new(0.05, 0, 0, 125)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "⚡ سرعت:"
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.GothamMedium
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = mainFrame

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.35, 0, 0, 40)
speedBox.Position = UDim2.new(0.5, 0, 0, 125)
speedBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
speedBox.Text = "30"
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.TextScaled = true
speedBox.Font = Enum.Font.GothamBold
local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = speedBox
speedBox.Parent = mainFrame

-- دکمه اعمال سرعت
local applySpeedBtn = Instance.new("TextButton")
applySpeedBtn.Size = UDim2.new(0.2, 0, 0, 40)
applySpeedBtn.Position = UDim2.new(0.75, 0, 0, 125)
applySpeedBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
applySpeedBtn.Text = "✅"
applySpeedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
applySpeedBtn.TextScaled = true
applySpeedBtn.Font = Enum.Font.GothamBold
local btnCorner2 = Instance.new("UICorner")
btnCorner2.CornerRadius = UDim.new(0, 6)
btnCorner2.Parent = applySpeedBtn
applySpeedBtn.Parent = mainFrame

-- چک‌باکس Noclip (سفارشی)
local noclipLabel = Instance.new("TextLabel")
noclipLabel.Size = UDim2.new(0.5, 0, 0, 40)
noclipLabel.Position = UDim2.new(0.05, 0, 0, 180)
noclipLabel.BackgroundTransparency = 1
noclipLabel.Text = "🧱 حالت Noclip:"
noclipLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
noclipLabel.TextScaled = true
noclipLabel.Font = Enum.Font.GothamMedium
noclipLabel.TextXAlignment = Enum.TextXAlignment.Left
noclipLabel.Parent = mainFrame

local noclipStatus = Instance.new("TextLabel")
noclipStatus.Size = UDim2.new(0.2, 0, 0, 40)
noclipStatus.Position = UDim2.new(0.7, 0, 0, 180)
noclipStatus.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
noclipStatus.Text = "فعال"
noclipStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipStatus.TextScaled = true
noclipStatus.Font = Enum.Font.GothamBold
local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = noclipStatus
noclipStatus.Parent = mainFrame

-- دکمه تغییر وضعیت Noclip
local noclipToggle = Instance.new("TextButton")
noclipToggle.Size = UDim2.new(0.15, 0, 0, 40)
noclipToggle.Position = UDim2.new(0.85, 0, 0, 180)
noclipToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
noclipToggle.Text = "🔁"
noclipToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipToggle.TextScaled = true
noclipToggle.Font = Enum.Font.GothamBold
local btnCorner3 = Instance.new("UICorner")
btnCorner3.CornerRadius = UDim.new(0, 6)
btnCorner3.Parent = noclipToggle
noclipToggle.Parent = mainFrame

-- دکمه بستن منو
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.85, 0, 0, 45)
closeButton.Position = UDim2.new(0.075, 0, 0, 245)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "❌ بستن منو"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
local btnCorner4 = Instance.new("UICorner")
btnCorner4.CornerRadius = UDim.new(0, 8)
btnCorner4.Parent = closeButton
closeButton.Parent = mainFrame

-- متن راهنما
local helpText = Instance.new("TextLabel")
helpText.Size = UDim2.new(1, 0, 0, 30)
helpText.Position = UDim2.new(0, 0, 0, 290)
helpText.BackgroundTransparency = 1
helpText.Text = "⌨️ WASD حرکت | Space بالا | Shift پایین"
helpText.TextColor3 = Color3.fromRGB(150, 150, 180)
helpText.TextScaled = true
helpText.Font = Enum.Font.GothamMedium
helpText.Parent = mainFrame

-- ==============================================
-- بخش رویدادهای دکمه‌ها
-- ==============================================

toggleButton.MouseButton1Click:Connect(function()
    if not flying then
        startFly()
        toggleButton.Text = "⏹ توقف پرواز"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    else
        stopFly()
        toggleButton.Text = "🔥 شروع پرواز"
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
    end
end)

applySpeedBtn.MouseButton1Click:Connect(function()
    local newSpeed = tonumber(speedBox.Text)
    if newSpeed and newSpeed > 0 then
        speed = newSpeed
        speedBox.Text = tostring(newSpeed)
    else
        speedBox.Text = tostring(speed)
    end
end)

noclipToggle.MouseButton1Click:Connect(function()
    noclip = not noclip
    if noclip then
        noclipStatus.Text = "فعال"
        noclipStatus.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
    else
        noclipStatus.Text = "غیرفعال"
        noclipStatus.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    if flying then stopFly() end
end)

player.CharacterAdded:Connect(function()
    if flying then
        stopFly()
        toggleButton.Text = "🔥 شروع پرواز"
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
    end
end)

game:GetService("Players").LocalPlayer:GetMouse().KeyDown:Connect(function(key)
    if key == "F" then
        if not flying then
            startFly()
            toggleButton.Text = "⏹ توقف پرواز"
            toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        else
            stopFly()
            toggleButton.Text = "🔥 شروع پرواز"
            toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
        end
    end
end)

print("✅ اسکریپت پرواز فارسی با موفقیت اجرا شد! کلید F را بزنید تا پرواز کنید.")