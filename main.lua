-- Universal Roblox GUI Script Template
-- Place this LocalScript in StarterPlayerScripts

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Tab Buttons
local tabs = {"Player", "World", "Settings"}
local tabFrames = {}
local tabButtons = {}

for i, tabName in ipairs(tabs) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 120, 0, 30)
    tabBtn.Position = UDim2.new(0, (i-1)*125, 0, 0)
    tabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    tabBtn.Text = tabName
    tabBtn.TextColor3 = Color3.fromRGB(255,255,255)
    tabBtn.Parent = mainFrame
    tabButtons[tabName] = tabBtn

    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, 0, 1, -35)
    tabFrame.Position = UDim2.new(0, 0, 0, 35)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = (i == 1)
    tabFrame.Parent = mainFrame
    tabFrames[tabName] = tabFrame
end

-- Tab Switching Functionality
for tabName, tabBtn in pairs(tabButtons) do
    tabBtn.MouseButton1Click:Connect(function()
        for t, frame in pairs(tabFrames) do
            frame.Visible = (t == tabName)
        end
    end)
end

-------------------------
-- PLAYER TAB FEATURES --
-------------------------
do
    local frame = tabFrames["Player"]
    
    -- Walkspeed Button
    local wsBtn = Instance.new("TextButton")
    wsBtn.Size = UDim2.new(0, 180, 0, 40)
    wsBtn.Position = UDim2.new(0, 20, 0, 10)
    wsBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 60)
    wsBtn.Text = "Set WalkSpeed: 50"
    wsBtn.TextColor3 = Color3.fromRGB(255,255,255)
    wsBtn.Parent = frame
    wsBtn.MouseButton1Click:Connect(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 50
        end
    end)

    -- JumpPower Button
    local jpBtn = Instance.new("TextButton")
    jpBtn.Size = UDim2.new(0, 180, 0, 40)
    jpBtn.Position = UDim2.new(0, 20, 0, 60)
    jpBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
    jpBtn.Text = "Set JumpPower: 100"
    jpBtn.TextColor3 = Color3.fromRGB(255,255,255)
    jpBtn.Parent = frame
    jpBtn.MouseButton1Click:Connect(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = 100
        end
    end)
end

-------------------------
-- WORLD TAB FEATURES --
-------------------------
do
    local frame = tabFrames["World"]

    -- Remove Fog Button
    local fogBtn = Instance.new("TextButton")
    fogBtn.Size = UDim2.new(0, 180, 0, 40)
    fogBtn.Position = UDim2.new(0, 20, 0, 10)
    fogBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    fogBtn.Text = "Remove Fog"
    fogBtn.TextColor3 = Color3.fromRGB(255,255,255)
    fogBtn.Parent = frame
    fogBtn.MouseButton1Click:Connect(function()
        game.Lighting.FogEnd = 100000
    end)

    -- Set Time Button
    local timeBtn = Instance.new("TextButton")
    timeBtn.Size = UDim2.new(0, 180, 0, 40)
    timeBtn.Position = UDim2.new(0, 20, 0, 60)
    timeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 60)
    timeBtn.Text = "Set Time: Noon"
    timeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    timeBtn.Parent = frame
    timeBtn.MouseButton1Click:Connect(function()
        game.Lighting.TimeOfDay = "12:00:00"
    end)
end

-------------------------
-- SETTINGS TAB FEATURES --
-------------------------
do
    local frame = tabFrames["Settings"]

    -- Toggle GUI Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 180, 0, 40)
    toggleBtn.Position = UDim2.new(0, 20, 0, 10)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 100)
    toggleBtn.Text = "Toggle GUI"
    toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
    toggleBtn.Parent = frame

    local visible = true
    toggleBtn.MouseButton1Click:Connect(function()
        visible = not visible
        mainFrame.Visible = visible
    end)
end

-- Optionally, add a keybind to toggle UI (e.g., press 'F')
game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- End of Universal GUI Script Template
