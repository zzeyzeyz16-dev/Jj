-- Defeat Some Rake — Energy Regeneration (local override)
-- Paste into your exploit/exec environment.
-- Simple, robust: tries to find an "Energy" / "Stamina" NumberValue and keep it at max.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("[EnergyRegen] LocalPlayer not found (must run as a Local Script in an exploit).")
    return
end

-- Config
local CHECK_INTERVAL = 0.1   -- how often to enforce (seconds)
local PREFERRED_NAMES = {"Energy","Stamina","Mana","EnergyValue","EP","Stam"} -- names to look for

-- Utility: recursively find NumberValue/IntValue that matches a name (case-insensitive)
local function findEnergyValue(root)
    for _, name in ipairs(PREFERRED_NAMES) do
        local v = root:FindFirstChild(name, true) -- fast path if exists directly under root
        if v and (v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v
        end
    end
    -- fallback: scan children for any numeric instance that probably indicates energy
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

-- Look into Player first (common places)
local function tryFind()
    -- 1) leaderstats
    if LocalPlayer:FindFirstChild("leaderstats") then
        local v = findEnergyValue(LocalPlayer.leaderstats)
        if v then return v end
    end
    -- 2) Player values
    local v = findEnergyValue(LocalPlayer)
    if v then return v end
    -- 3) Character
    if LocalPlayer.Character then
        local cv = findEnergyValue(LocalPlayer.Character)
        if cv then return cv end
    end
    -- 4) PlayerGui (some games keep a client value)
    if LocalPlayer:FindFirstChild("PlayerGui") then
        local gv = findEnergyValue(LocalPlayer.PlayerGui)
        if gv then return gv end
    end
    return nil
end

-- Attempt to find energy value (try a few times)
local energy = tryFind()
local tries = 0
while not energy and tries < 6 do
    tries = tries + 1
    wait(0.6)
    energy = tryFind()
end

if not energy then
    warn("[EnergyRegen] Couldn't automatically find an energy/stamina NumberValue.")
    -- show a small Gui prompt for manual
    pcall(function()
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "EnergyRegen_NotFound"
        ScreenGui.ResetOnSpawn = false
        local txt = Instance.new("TextLabel", ScreenGui)
        txt.Size = UDim2.new(0,360,0,60)
        txt.Position = UDim2.new(0.5,-180,0.1,0)
        txt.BackgroundTransparency = 0.4
        txt.Text = "Energy value not found automatically.\nOpen Explorer and set 'energy' variable manually."
        txt.TextWrapped = true
        txt.TextScaled = true
        txt.BackgroundColor3 = Color3.fromRGB(30,30,30)
        txt.TextColor3 = Color3.fromRGB(255,255,255)
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
    return
end

 -- Add a close button
‎    local closeBtn = Instance.new("TextButton", ScreenGui)
‎    closeBtn.Size = UDim2.new(0,100,0,30)
‎    closeBtn.Position = UDim2.new(0.5,-50,0.1,70)
‎    closeBtn.Text = "Close"
‎    closeBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
‎    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
‎    closeBtn.MouseButton1Click:Connect(function()
‎        ScreenGui:Destroy()
‎    end)
‎
‎    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
‎end)

-- Determine max value: if there's an associated MaxValue or similar, use it; otherwise use current or 100
local function findMaxValueFor(val)
    local parent = val.Parent
    if parent then
        for _, sibling in ipairs(parent:GetChildren()) do
            if (sibling ~= val) and (sibling:IsA("NumberValue") or sibling:IsA("IntValue")) then
                local lname = sibling.Name:lower()
                if lname:find("max") or lname:find("maxenergy") or lname:find("maxstam") or lname:find("limit") then
                    return sibling.Value
                end
            end
        end
    end
    -- Check attributes (some games use attributes)
    local attr = val:GetAttribute("Max") or val:GetAttribute("MaxValue") or val:GetAttribute("MaxEnergy")
    if attr then return attr end
    -- fallback: if value looks like percent (0-100) use 100, else default to current or 100
    if val.Value <= 100 then
        return 100
    end
    return val.Value
end

local maxEnergy = findMaxValueFor(energy)
if type(maxEnergy) ~= "number" or maxEnergy <= 0 then
    maxEnergy = energy.Value > 0 and energy.Value or 100
end

-- Toggle control
local enabled = true

-- Optional simple Bindable UI: press RightControl + E to toggle
pcall(function()
    local UserInput = game:GetService("UserInputService")
    UserInput.InputBegan:Connect(function(inp, gameProcessed)
        if gameProcessed then return end
        if inp.KeyCode == Enum.KeyCode.E and UserInput:IsKeyDown(Enum.KeyCode.RightControl) then
            enabled = not enabled
            print(("[EnergyRegen] Toggled %s"):format(enabled and "ON" or "OFF"))
        end
    end)
end)

-- Try to prevent local writes that set it lower by hooking __newindex if available (best-effort; exploit function)
local hooked = false
if (type(hookmetamethod) == "function") then
    local old = hookmetamethod(game, "__newindex", function(t,k,v)
        -- protect the energy Value instance from being set to something less than our target
        if t == energy and tostring(k) == "Value" then
            if not enabled then
                return old(t,k,v)
            end
            if type(v) == "number" and v < maxEnergy then
                -- block the write
                return nil
            end
        end
        return old(t,k,v)
    end)
    hooked = true
end

-- Main enforcement loop
spawn(function()
    while true do
        if enabled and energy and energy.Parent then
            pcall(function()
                -- some games use fractional values, enforce full
                energy.Value = maxEnergy
            end)
        end
        wait(CHECK_INTERVAL)
    end
end)

-- feedback
print(("[EnergyRegen] Running. Energy instance = %s (parent: %s). Max enforced = %s. Hooked newindex = %s")
      :format(energy:GetFullName(), energy.Parent and energy.Parent:GetFullName() or "nil", tostring(maxEnergy), tostring(hooked)))
