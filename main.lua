-- StarterPlayerScripts / LegendsGUI
-- Creates one GUI showing Level/XP and ability buttons

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local AbilityEvent = ReplicatedStorage:WaitForChild("UseAbility")
local StatsUpdate = ReplicatedStorage:WaitForChild("StatsUpdate")

local Abilities = {"Fireball","IceBlast"}

-- GUI
local screen = Instance.new("ScreenGui")
screen.Name = "LegendsGUI"
screen.Parent = player:WaitForChild("PlayerGui")

-- Stats frame
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(0,200,0,80)
statsFrame.Position = UDim2.new(0,10,0,10)
statsFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
statsFrame.Parent = screen

local levelLabel = Instance.new("TextLabel")
levelLabel.Size = UDim2.new(1,0,0.5,0)
levelLabel.Position = UDim2.new(0,0,0,0)
levelLabel.TextColor3 = Color3.fromRGB(255,255,255)
levelLabel.Text = "Level: 1"
levelLabel.Parent = statsFrame

local xpLabel = Instance.new("TextLabel")
xpLabel.Size = UDim2.new(1,0,0.5,0)
xpLabel.Position = UDim2.new(0,0,0.5,0)
xpLabel.TextColor3 = Color3.fromRGB(255,255,255)
xpLabel.Text = "XP: 0/100"
xpLabel.Parent = statsFrame

-- Ability buttons frame
local abilitiesFrame = Instance.new("Frame")
abilitiesFrame.Size = UDim2.new(0,150,0,#Abilities*45)
abilitiesFrame.Position = UDim2.new(0,10,0,100)
abilitiesFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
abilitiesFrame.Parent = screen

for i,name in ipairs(Abilities) do
    local btn = Instance.new("TextButton")
    btn.Text = name
    btn.Size = UDim2.new(1,0,0,40)
    btn.Position = UDim2.new(0,0,0,(i-1)*45)
    btn.Parent = abilitiesFrame

    btn.MouseButton1Click:Connect(function()
        AbilityEvent:FireServer(name)
    end)
end

-- Update stats from server
StatsUpdate.OnClientEvent:Connect(function(level,xp,requiredXP)
    levelLabel.Text = "Level: "..level
    xpLabel.Text = "XP: "..xp.."/"..requiredXP
end)
