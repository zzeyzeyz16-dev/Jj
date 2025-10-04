-- AutoFightLocal (StarterPlayerScripts)
-- Local testing auto-fight (for your own place). It checks player's Stamina NumberValue before attacking.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Optional: edit this to point to where your NPCs live (workspace.Enemies etc.)
local SEARCH_ROOT = workspace
local TARGET_NAME_CONTAINS = "Rake"
local MOVE_TIMEOUT = 8
local ATTACK_INTERVAL = 0.35

-- Keep a local copy of server-sent stamina via StaminaUpdate
local currentEnergy = 230
local maxEnergy = 230
local ENERGY_UPDATE = ReplicatedStorage:WaitForChild("EnergyUpdate")

STAMINA_UPDATE.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then return end
    currentStamina = payload.value or currentStamina
    maxStamina = payload.max or maxStamina
end)

local AUTO_FIGHT = false

-- Simple UI toggle (very small)
local function createToggleUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoFightUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", screenGui)
    frame.Size = UDim2.new(0, 220, 0, 88)
    frame.Position = UDim2.new(0, 20, 0, 120)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -10, 0, 28)
    title.Position = UDim2.new(0, 5, 0, 5)
    title.Text = "AutoFight (TEST)"
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.new(1,1,1)

    local startBtn = Instance.new("TextButton", frame)
    startBtn.Size = UDim2.new(0.48, -6, 0, 30)
    startBtn.Position = UDim2.new(0, 5, 0, 36)
    startBtn.Text = "Start"
    startBtn.MouseButton1Click:Connect(function()
        AUTO_FIGHT = true
    end)

    local stopBtn = Instance.new("TextButton", frame)
    stopBtn.Size = UDim2.new(0.48, -6, 0, 30)
    stopBtn.Position = UDim2.new(0.52, 1, 0, 36)
    stopBtn.Text = "Stop"
    stopBtn.MouseButton1Click:Connect(function()
        AUTO_FIGHT = false
    end)
end

createToggleUI()

local function findNearestRake()
    local nearest = nil
    local nearestDist = math.huge
    for _, obj in ipairs(SEARCH_ROOT:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find(TARGET_NAME_CONTAINS:lower()) then
            local rootPart = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
            if rootPart then
                local dist = (rootPart.Position - hrp.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest, nearestDist
end

local function equipBestTool()
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            item.Parent = character
            return item
        end
    end
    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                item.Parent = character
                return item
            end
        end
    end
    return nil
end

local function moveToPosition(position, timeout)
    humanoid:MoveTo(position)
    local start = tick()
    while tick() - start < (timeout or MOVE_TIMEOUT) do
        if (hrp.Position - position).Magnitude < 6 then
            return true
        end
        task.wait(0.2)
    end
    return false
end

local function attackTarget(loopUntilDead, targetModel)
    if not targetModel then return end
    local tool = equipBestTool()
    if not tool then return end
    while AUTO_FIGHT do
        -- stop attacking if stamina is 0 (unless server infinite is on; server keeps stamina at max then)
        if currentStamina <= 0 then break end
        local targetHum = targetModel:FindFirstChildWhichIsA("Humanoid")
        if loopUntilDead and (not targetHum or targetHum.Health <= 0) then break end
        pcall(function()
            if tool.Parent == character then
                tool:Activate()
            end
        end)
        task.wait(ATTACK_INTERVAL)
    end
end

-- Main loop
spawn(function()
    while true do
        if AUTO_FIGHT and character and humanoid and hrp.Parent then
            -- only start auto-fight if stamina > 0 (or infinite toggle on server will keep it >0)
            if currentStamina > 0 then
                local target, dist = findNearestRake()
                if target then
                    local root = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
                    if root then
                        local pos = root.Position + (hrp.CFrame.LookVector * -3)
                        local moved = moveToPosition(pos, MOVE_TIMEOUT)
                        if moved then
                            attackTarget(true, target)
                        end
                    end
                end
            end
        end
        task.wait(0.6)
    end
end)

-- handle respawn
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
end)
