-- Energy GUI Regenerator for Defeat Some Rake
-- Paste into your exploit/exec environment (Local script).
-- Single-file GUI; no external dependencies.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[EnergyGUI] LocalPlayer not found.")
    return
end

-- Config defaults
local CHECK_INTERVAL = 0.35
local PREFERRED_NAMES = {"Energy","Stamina","Mana","EnergyValue","EP","Stam","StaminaValue"}

-- Utility: search for candidate Number/Int value (breadth-first)
local function findEnergyValue(root)
    for _, name in ipairs(PREFERRED_NAMES) do
        local found = root:FindFirstChild(name, true)
        if found and (found:IsA("NumberValue") or found:IsA("IntValue")) then
            return found
        end
    end
    -- BFS scan
    local queue = {root}
    while #queue > 0 do
        local node = table.remove(queue, 1)
        for _, child in ipairs(node:GetChildren()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                local cname = child.Name:lower()
                for _, name in ipairs(PREFERRED_NAMES) do
                    if cname:find(name:lower()) then
                        return child
                    end
                end
            end
            table.insert(queue, child)
        end
    end
    return nil
end

local function tryFind()
    if LocalPlayer:FindFirstChild("leaderstats") then
        local v = findEnergyValue(LocalPlayer.leaderstats)
        if v then return v end
    end
    local v = findEnergyValue(LocalPlayer)
    if v then return v end
    if LocalPlayer.Character then
        local cv = findEnergyValue(LocalPlayer.Character)
        if cv then return cv end
    end
    if LocalPlayer:FindFirstChild("PlayerGui") then
        local gv = findEnergyValue(LocalPlayer.PlayerGui)
        if gv then return gv end
    end
    return nil
end

local energy = tryFind()
local tries = 0
while not energy and tries < 6 do
    tries = tries + 1
    wait(0.6)
    energy = tryFind()
end

-- Create GUI
local function createGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EnergyRegenGUI"
    screenGui.ResetOnSpawn = false

    local main = Instance.new("Frame", screenGui)
    main.Name = "Main"
    main.Size = UDim2.new(0, 320, 0, 150)
    main.Position = UDim2.new(0.5, -160, 0.15, 0)
    main.BackgroundColor3 = Color3.fromRGB(25,25,25)
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.AnchorPoint = Vector2.new(0.5,0)

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, 0, 0, 28)
    title.Position = UDim2.new(0,0,0,0)
    title.BackgroundTransparency = 1
    title.Text = "Energy Regenerator"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(230,230,230)

    local statusLabel = Instance.new("TextLabel", main)
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, -12, 0, 40)
    statusLabel.Position = UDim2.new(0,6,0,34)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextWrapped = true
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.Text = "Status: "..(energy and ("Found: "..energy:GetFullName()) or "Energy not found")
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextSize = 14
    statusLabel.TextColor3 = Color3.fromRGB(200,200,200)

    local leftBtn = Instance.new("TextButton", main)
    leftBtn.Size = UDim2.new(0, 92, 0, 28)
    leftBtn.Position = UDim2.new(0, 8, 1, -36)
    leftBtn.AnchorPoint = Vector2.new(0,1)
    leftBtn.Text = "Toggle ON"
    leftBtn.Font = Enum.Font.SourceSansBold
    leftBtn.TextSize = 14
    leftBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    leftBtn.TextColor3 = Color3.fromRGB(220,220,220)

    local midBtn = Instance.new("TextButton", main)
    midBtn.Size = UDim2.new(0, 92, 0, 28)
    midBtn.Position = UDim2.new(0.5, -46, 1, -36)
    midBtn.AnchorPoint = Vector2.new(0.5,1)
    midBtn.Text = "Restore Now"
    midBtn.Font = Enum.Font.SourceSans
    midBtn.TextSize = 14
    midBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    midBtn.TextColor3 = Color3.fromRGB(220,220,220)

    local rightBtn = Instance.new("TextButton", main)
    rightBtn.Size = UDim2.new(0, 92, 0, 28)
    rightBtn.Position = UDim2.new(1, -100, 1, -36)
    rightBtn.AnchorPoint = Vector2.new(1,1)
    rightBtn.Text = "Auto-Detect"
    rightBtn.Font = Enum.Font.SourceSans
    rightBtn.TextSize = 14
    rightBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    rightBtn.TextColor3 = Color3.fromRGB(220,220,220)

    local intervalBox = Instance.new("TextBox", main)
    intervalBox.Size = UDim2.new(0, 120, 0, 24)
    intervalBox.Position = UDim2.new(0, 8, 0, 80)
    intervalBox.PlaceholderText = "Interval (s) e.g. 0.35"
    intervalBox.Text = tostring(CHECK_INTERVAL)
    intervalBox.Font = Enum.Font.SourceSans
    intervalBox.TextSize = 14
    intervalBox.ClearTextOnFocus = false
    intervalBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
    intervalBox.TextColor3 = Color3.fromRGB(220,220,220)

    local maxBox = Instance.new("TextBox", main)
    maxBox.Size = UDim2.new(0, 180, 0, 24)
    maxBox.Position = UDim2.new(0, 140, 0, 80)
    maxBox.PlaceholderText = "Max value (leave blank = auto)"
    maxBox.Text = ""
    maxBox.Font = Enum.Font.SourceSans
    maxBox.TextSize = 14
    maxBox.ClearTextOnFocus = false
    maxBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
    maxBox.TextColor3 = Color3.fromRGB(220,220,220)

    local info = Instance.new("TextLabel", main)
    info.Size = UDim2.new(1, -12, 0, 14)
    info.Position = UDim2.new(0,6,1,-18)
    info.BackgroundTransparency = 1
    info.Text = "Keybind: RightCtrl + E to toggle"
    info.Font = Enum.Font.SourceSansItalic
    info.TextSize = 12
    info.TextColor3 = Color3.fromRGB(170,170,170)
    info.TextXAlignment = Enum.TextXAlignment.Left

    -- Make draggable
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    return {
        ScreenGui = screenGui,
        Main = main,
        Status = statusLabel,
        ToggleButton = leftBtn,
        RestoreButton = midBtn,
        AutoDetectButton = rightBtn,
        IntervalBox = intervalBox,
        MaxBox = maxBox,
        Info = info
    }
end

local gui = createGui()

-- State
local enabled = true
local enforcedMax = nil -- number or nil to auto
local hooked = false

local function findMaxFor(val)
    if not val then return nil end
    local parent = val.Parent
    if parent then
        for _, sibling in ipairs(parent:GetChildren()) do
            if (sibling ~= val) and (sibling:IsA("NumberValue") or sibling:IsA("IntValue")) then
                local lname = sibling.Name:lower()
                if lname:find("max") or lname:find("limit") or lname:find("maxenergy") then
                    return sibling.Value
                end
            end
        end
    end
    local attr = val:GetAttribute("Max") or val:GetAttribute("MaxValue") or val:GetAttribute("MaxEnergy")
    if attr then return attr end
    if val.Value <= 100 then return 100 end
    return val.Value
end

-- Hook newindex best-effort
if type(hookmetamethod) == "function" then
    local ok, old = pcall(function() return hookmetamethod(game, "__newindex", function(t,k,v) return old(t,k,v) end) end)
    -- We'll apply the actual hook after we have the energy instance
    -- (we can't safely reference 'old' until we override properly later)
end

local function updateStatusText()
    gui.Status.Text = "Status: "..(energy and ("Found: "..energy:GetFullName()) or "Energy not found")
    gui.Status.Text = gui.Status.Text .. "\nEnabled: "..tostring(enabled) .. "  |  Interval: "..tostring(CHECK_INTERVAL)
    local m = enforcedMax or (energy and findMaxFor(energy)) or "N/A"
    gui.Status.Text = gui.Status.Text .. "  |  Max: "..tostring(m)
end

updateStatusText()

-- Button behaviors
gui.ToggleButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    gui.ToggleButton.Text = enabled and "Toggle ON" or "Toggle OFF"
    updateStatusText()
end)

gui.RestoreButton.MouseButton1Click:Connect(function()
    if energy and energy.Parent then
        local maxv = enforcedMax or findMaxFor(energy) or energy.Value
        pcall(function() energy.Value = maxv end)
        gui.Status.Text = gui.Status.Text .. "\n[Manual] Restored to "..tostring(maxv)
    else
        gui.Status.Text = gui.Status.Text .. "\n[Manual] Energy not available."
    end
end)

gui.AutoDetectButton.MouseButton1Click:Connect(function()
    energy = tryFind()
    if energy then
        gui.Status.Text = "[AutoDetect] Found: "..energy:GetFullName()
        enforcedMax = nil
    else
        gui.Status.Text = "[AutoDetect] Not found."
    end
    updateStatusText()
end)

gui.IntervalBox.FocusLost:Connect(function(enter)
    local t = tonumber(gui.IntervalBox.Text)
    if t and t > 0 then
        CHECK_INTERVAL = t
        gui.Status.Text = gui.Status.Text .. "\n[Config] Interval set to "..t
    else
        gui.IntervalBox.Text = tostring(CHECK_INTERVAL)
    end
    updateStatusText()
end)

gui.MaxBox.FocusLost:Connect(function(enter)
    local t = tonumber(gui.MaxBox.Text)
    if t and t > 0 then
        enforcedMax = t
        gui.Status.Text = gui.Status.Text .. "\n[Config] Max enforced set to "..t
    elseif gui.MaxBox.Text == "" then
        enforcedMax = nil
        gui.Status.Text = gui.Status.Text .. "\n[Config] Max enforcement set to AUTO"
    else
        gui.MaxBox.Text = enforcedMax and tostring(enforcedMax) or ""
    end
    updateStatusText()
end)

-- Keybind toggle RightCtrl + E
UserInputService.InputBegan:Connect(function(inp, gameProcessed)
    if gameProcessed then return end
    if inp.KeyCode == Enum.KeyCode.E and UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
        enabled = not enabled
        gui.ToggleButton.Text = enabled and "Toggle ON" or "Toggle OFF"
        updateStatusText()
    end
end)

-- Main enforcement loop
spawn(function()
    while true do
        if enabled then
            if not energy or not energy.Parent then
                energy = tryFind()
                if energy then
                    gui.Status.Text = "[Auto] Found energy: "..energy:GetFullName()
                end
            end

            if energy and energy.Parent then
                local ok, err = pcall(function()
                    local maxv = enforcedMax or findMaxFor(energy) or energy.Value
                    if type(maxv) ~= "number" or maxv <= 0 then maxv = energy.Value end
                    energy.Value = maxv
                end)
                if not ok then
                    gui.Status.Text = "[Error] Failed to write energy: "..tostring(err)
                end
            end
        end
        updateStatusText()
        wait(CHECK_INTERVAL)
    end
end)

-- Try to hook __newindex to block writes that reduce energy (best-effort; exploit-specific)
pcall(function()
    if type(hookmetamethod) == "function" and energy then
        local old = hookmetamethod(game, "__newindex", function(t,k,v)
            -- if targetting the energy instance's Value property, block writes that lower the value when enabled
            if enabled and t == energy and tostring(k) == "Value" and type(v) == "number" then
                local maxv = enforcedMax or findMaxFor(energy) or energy.Value
                if v < maxv then
                    return nil -- block write
                end
            end
            return old(t,k,v)
        end)
        hooked = true
        gui.Status.Text = gui.Status.Text .. "\n[Hook] __newindex hooked."
    end
end)

-- Final message
gui.Status.Text = gui.Status.Text .. "\n[Ready] GUI loaded. Use the buttons or RightCtrl+E to toggle."
