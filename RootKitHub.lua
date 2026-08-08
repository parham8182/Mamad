-- =====================================================
-- 🍎 RootKit Hub - Chest Movement Module
-- =====================================================
-- تغییر درخواستی: حرکت به چست، برخورد/نوسان بالا و پایین،
-- سپس رفتن سراغ چست بعدی.
-- این فایل فقط منطق حرکت را نگه می‌دارد و برای پروژه خودت
-- در Roblox Studio قابل استفاده است.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local State = {
    AutoFarm = false,
    Speed = 100,
    TargetChest = nil,
    CollectedChests = {},
    MoveLoop = nil,
}

local character
local humanoid
local rootPart

local function getCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:FindFirstChildOfClass("Humanoid")
    rootPart = character:FindFirstChild("HumanoidRootPart")
    return humanoid ~= nil and rootPart ~= nil
end

local function bumpChest(chest)
    if not chest or not chest.Parent or not rootPart then
        return
    end

    local basePosition = chest.Position

    -- سه حرکت کوتاه بالا/پایین برای برخورد با چست
    for _ = 1, 3 do
        if not State.AutoFarm or not chest.Parent or not rootPart then
            return
        end

        rootPart.CFrame = CFrame.new(basePosition + Vector3.new(0, 2, 0))
        task.wait(0.12)

        rootPart.CFrame = CFrame.new(basePosition + Vector3.new(0, 5, 0))
        task.wait(0.12)
    end

    table.insert(State.CollectedChests, chest)
    State.TargetChest = nil
end

local function moveToChest(chest)
    if not chest or not chest.Parent or not rootPart then
        return false
    end

    local distance = (rootPart.Position - chest.Position).Magnitude
    if distance > 4 then
        if humanoid then
            humanoid:MoveTo(chest.Position)
        end
        return false
    end

    bumpChest(chest)
    return true
end

local function findNextChest(chests)
    local nearest
    local nearestDistance = math.huge

    for _, chest in ipairs(chests) do
        if chest and chest.Parent and chest:IsA("BasePart") and not table.find(State.CollectedChests, chest) then
            local distance = (rootPart.Position - chest.Position).Magnitude
            if distance < nearestDistance then
                nearest = chest
                nearestDistance = distance
            end
        end
    end

    return nearest
end

function StartChestLoop(getChests)
    if State.MoveLoop then
        State.MoveLoop:Disconnect()
        State.MoveLoop = nil
    end

    if not getCharacter() then
        return
    end

    State.AutoFarm = true
    State.CollectedChests = {}

    State.MoveLoop = RunService.Heartbeat:Connect(function()
        if not State.AutoFarm then
            return
        end

        if not character or not humanoid or not rootPart or humanoid.Health <= 0 then
            getCharacter()
            return
        end

        if not State.TargetChest then
            local chests = getChests()
            State.TargetChest = findNextChest(chests)
        end

        if State.TargetChest then
            moveToChest(State.TargetChest)
        end
    end)
end

function StopChestLoop()
    State.AutoFarm = false
    State.TargetChest = nil

    if State.MoveLoop then
        State.MoveLoop:Disconnect()
        State.MoveLoop = nil
    end

    if humanoid and rootPart then
        humanoid:MoveTo(rootPart.Position)
    end
end

player.CharacterAdded:Connect(function()
    task.wait(1)
    getCharacter()
end)

getCharacter()
print("✅ RootKit Hub - Chest Movement Module loaded")
