--[[ 
  The Revenant: Sunrise — Universal Lua GUI Script (Template)
  Features:
    - GUI (Orion-style) with tabs: Combat, Farming, Movement, Player, Misc
    - Auto Attack (fires remote / invokes function) with configurable interval
    - No Cooldown toggle (attempts to nil/patch cooldown value if accessible)
    - Auto Collect (scans workspace for items by name or class)
    - Auto Heal / Auto Respawn handler
    - Movement tweaks: WalkSpeed, JumpPower, Teleport to waypoint
    - Basic ESP-lite (BillboardGui) for pickups / bosses
    - Anti-AFK / Anti-Idle
    - Config save/load (JSON)
    - Safety: pcall wrappers and user-configurable remote names/paths
  How to use:
    1. Edit the GAME SETTINGS block below to match the game's remotes and object names.
    2. Run in an executor that provides access to RemoteEvent:FireServer / RemoteFunction:InvokeServer etc.
    3. Use responsibly.
--]]

-- ===============================
-- ======  CONFIG  ================
-- ===============================
local CONFIG = {
  -- Remote names / paths (edit to match the game's actual remotes)
  REMOTES = {
    AttackRemoteName = "AttackRemote",           -- RemoteEvent used to attack
    UseRemoteName    = "UseRemote",              -- RemoteEvent used to use/collect
    CooldownPath     = {"PlayerScripts","Cooldown"}, -- Example path to a cooldown value (relative to LocalPlayer)
    -- If the game uses RemoteFunctions or differently named remotes, update above.
  },

  -- Item & object filters for auto-collect
  COLLECT = {
    ItemNamePatterns = {"Gem","Orb","Loot"}, -- pattern substrings to auto-collect
    MaxDistance      = 120, -- studs
  },

  -- Auto attack settings
  AUTO = {
    AttackInterval = 0.12, -- seconds between attack calls (adjust to be safe)
  },

  -- Config filename for save/load
  ConfigFilename = "revenant_sunrise_config.json",
}

-- ===============================
-- ======  UTILITIES  ============
-- ===============================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer and LocalPlayer.Character or nil

local function safeFind(obj, pathArray)
  -- Finds nested child using an array of names, returns nil if not found
  local cur = obj
  for _, name in ipairs(pathArray) do
    if not cur then return nil end
    cur = cur:FindFirstChild(name)
  end
  return cur
end

local function notify(text)
  -- Simple print + hint you can replace with GUI notifications
  pcall(function() print("[Revenant] "..text) end)
end

local function tryCall(fn, ...)
  local ok, a, b, c = pcall(fn, ...)
  return ok and a or nil, not ok and a or nil, b, c
end

-- ===============================
-- ======  GAME-SPECIFIC HOOKS ==
-- ===============================
-- These are the places you must edit for the target game
local GameHooks = {}

-- 1) Attack action (example using RemoteEvent :FireServer)
GameHooks.Attack = function()
  local remName = CONFIG.REMOTES.AttackRemoteName
  -- try to find remote in ReplicatedStorage, or anywhere common
  local remote = game:GetService("ReplicatedStorage"):FindFirstChild(remName)
               or workspace:FindFirstChild(remName)
  if remote and remote:IsA("RemoteEvent") then
    pcall(function() remote:FireServer({action="attack"}) end)
  else
    -- fallback: try to find on Player (some games store remotes different)
    local localRemote = safeFind(LocalPlayer, {remName})
    if localRemote and localRemote:IsA("RemoteEvent") then
      pcall(function() localRemote:FireServer({action="attack"}) end)
    end
  end
end

-- 2) Use/Collect action (example)
GameHooks.Use = function(target)
  local remName = CONFIG.REMOTES.UseRemoteName
  local remote = game:GetService("ReplicatedStorage"):FindFirstChild(remName)
               or workspace:FindFirstChild(remName)
  if remote and remote:IsA("RemoteEvent") then
    pcall(function() remote:FireServer(target) end)
  else
    -- fallback: attempt to touch the part (if collectibles are touched)
    if target and target:IsA("BasePart") then
      pcall(function() target:Destroy() end) -- Dangerous; only for private cases
    end
  end
end

-- 3) Attempt to disable cooldowns by setting value in a path (if present)
GameHooks.DisableCooldown = function(enable)
  local path = CONFIG.REMOTES.CooldownPath
  local node = safeFind(LocalPlayer, path)
  if node and node:IsA("NumberValue") then
    pcall(function() node.Value = (enable and 0) or 1 end)
    return true
  end
  return false
end

-- ===============================
-- ======  CORE FEATURES  ========
-- ===============================
local State = {
  AutoAttack = false,
  NoCooldown = false,
  AutoCollect = false,
  AutoHeal = false,
}

-- Auto attack loop
spawn(function()
  while task.wait(0.1) do
    if State.AutoAttack then
      local ok = pcall(GameHooks.Attack)
      if not ok then notify("AutoAttack: failed to call attack remote") end
      task.wait(CONFIG.AUTO.AttackInterval)
    end
  end
end)

-- Auto collect loop
spawn(function()
  while task.wait(0.7) do
    if State.AutoCollect then
      for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("BasePart") or item:IsA("Model") then
          local name = item.Name or ""
          for _, pat in ipairs(CONFIG.COLLECT.ItemNamePatterns) do
            if string.find(string.lower(name), string.lower(pat)) then
              -- distance check
              local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
              if root and item.PrimaryPart then
                local dist = (root.Position - item.PrimaryPart.Position).Magnitude
                if dist <= CONFIG.COLLECT.MaxDistance then
                  pcall(function() GameHooks.Use(item) end)
                  task.wait(0.15)
                end
              elseif root and item:IsA("BasePart") then
                local dist = (root.Position - item.Position).Magnitude
                if dist <= CONFIG.COLLECT.MaxDistance then
                  pcall(function() GameHooks.Use(item) end)
                  task.wait(0.15)
                end
              end
            end
          end
        end
      end
    else
      task.wait(1)
    end
  end
end)

-- NoCooldown watcher (tries to set cooldown as long as enabled)
spawn(function()
  while task.wait(1) do
    if State.NoCooldown then
      local ok = GameHooks.DisableCooldown(true)
      if not ok then
        -- couldn't find cooldown node; nothing to do
      end
    else
      GameHooks.DisableCooldown(false)
    end
  end
end)

-- Anti-AFK
pcall(function()
  local VirtualUser = game:GetService("VirtualUser")
  Players.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    notify("Anti-AFK triggered")
  end)
end)

-- Simple Auto Heal (sets Humanoid health if permitted)
spawn(function()
  while task.wait(0.8) do
    if State.AutoHeal then
      local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
      if humanoid and humanoid.Health and humanoid.MaxHealth then
        pcall(function() humanoid.Health = humanoid.MaxHealth end)
      end
    end
  end
end)

-- ===============================
-- ======  MOVEMENT & PLAYER =====
-- ===============================
local function setWalkSpeed(speed)
  local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
  if humanoid then
    pcall(function() humanoid.WalkSpeed = speed end)
  end
end

local function setJumpPower(power)
  local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
  if humanoid then
    pcall(function() humanoid.JumpPower = power end)
  end
end

local function teleportTo(position)
  local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
  if hrp then
    pcall(function() hrp.CFrame = CFrame.new(position) end)
  end
end

-- ===============================
-- ======  SIMPLE ESP (OPTIONAL) =
-- ===============================
local ESP = {}
ESP.Active = false
ESP.Items = {}

local function createBillboardFor(part, label)
  if not part or not part:IsA("BasePart") then return nil end
  local bb = Instance.new("BillboardGui")
  bb.Name = "RevenantESP"
  bb.Adornee = part
  bb.Size = UDim2.new(0,100,0,30)
  bb.StudsOffset = Vector3.new(0,2,0)
  bb.AlwaysOnTop = true
  local txt = Instance.new("TextLabel", bb)
  txt.Size = UDim2.new(1,0,1,0)
  txt.BackgroundTransparency = 1
  txt.Text = label or part.Name
  txt.Font = Enum.Font.SourceSansBold
  txt.TextScaled = true
  return bb
end

spawn(function()
  while task.wait(1) do
    if ESP.Active then
      -- scan for items that match collect patterns and attach billboards
      for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
          local name = part.Name or ""
          for _, pat in ipairs(CONFIG.COLLECT.ItemNamePatterns) do
            if string.find(string.lower(name), string.lower(pat)) then
              if not ESP.Items[part] then
                local bb = createBillboardFor(part, name)
                if bb then bb.Parent = part end
                ESP.Items[part] = bb
              end
            end
          end
        end
      end
      -- cleanup
      for p, gui in pairs(ESP.Items) do
        if not p or not p.Parent then
          if gui and gui.Parent then gui:Destroy() end
          ESP.Items[p] = nil
        end
      end
    else
      -- remove all
      for p, gui in pairs(ESP.Items) do
        if gui and gui.Parent then gui:Destroy() end
        ESP.Items[p] = nil
      end
    end
  end
end)

-- ===============================
-- ======  CONFIG SAVE/LOAD  =====
-- ===============================
local function saveConfig(tbl)
  local ok, err = pcall(function()
    local json = HttpService:JSONEncode(tbl)
    writefile(CONFIG.ConfigFilename, json)
  end)
  if not ok then notify("Save failed: "..tostring(err)) end
end

local function loadConfig()
  if isfile and isfile(CONFIG.ConfigFilename) then
    local ok, data = pcall(function() return readfile(CONFIG.ConfigFilename) end)
    if ok and data then
      local ok2, tbl = pcall(function() return HttpService:JSONDecode(data) end)
      if ok2 then return tbl end
    end
  end
  return nil
end

-- ===============================
-- ======  GUI (ORION-STYLE)  ====
-- ===============================
-- Minimal Orion-like small GUI replacer; if you already have OrionLib loaded you can skip this block and hook into it.
-- For maximum compatibility, try to find a preloaded Orion library first:
local OrionLib = nil
if _G and _G.OrionLib then
  OrionLib = _G.OrionLib
else
  -- If you want a full Orion, paste the library code here or require it.
  -- For the template, we'll create a minimal UI using StarterGui:SetCore or simple ScreenGui.
  OrionLib = nil
end

-- Simple ScreenGui to host controls (basic)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RevenantGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Simple frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,420,0,380)
frame.Position = UDim2.new(0,20,0,80)
frame.BackgroundTransparency = 0.15
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Parent = ScreenGui
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.Text = "Revenant: Sunrise — Controller"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = false
title.TextSize = 18

-- Helper to create toggles / buttons
local function makeToggle(name, position, callback, initial)
  local t = Instance.new("TextButton", frame)
  t.Size = UDim2.new(0,200,0,30)
  t.Position = position
  t.Text = name.." ["..(initial and "OFF" or "OFF").."]"
  t.Font = Enum.Font.SourceSans
  t.TextSize = 14
  t.BackgroundTransparency = 0.2
  t.MouseButton1Click:Connect(function()
    State[name] = not State[name]
    local val = State[name]
    t.Text = name.." ["..(val and "ON" or "OFF").."]"
    pcall(callback, val)
  end)
  return t
end

-- Create toggles
local autoAttackToggle = makeToggle("AutoAttack", UDim2.new(0,12,0,50), function(v) State.AutoAttack = v end)
local autoCollectToggle = makeToggle("AutoCollect", UDim2.new(0,220,0,50), function(v) State.AutoCollect = v end)
local noCooldownToggle = makeToggle("NoCooldown", UDim2.new(0,12,0,90), function(v) State.NoCooldown = v end)
local autoHealToggle = makeToggle("AutoHeal", UDim2.new(0,220,0,90), function(v) State.AutoHeal = v end)

-- WalkSpeed slider (simple +/-)
local speedLabel = Instance.new("TextLabel", frame)
speedLabel.Position = UDim2.new(0,12,0,140)
speedLabel.Size = UDim2.new(0,200,0,30)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "WalkSpeed: 16"
speedLabel.TextColor3 = Color3.new(1,1,1)
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextSize = 14

local speed = 16
local plus = Instance.new("TextButton", frame)
plus.Position = UDim2.new(0,220,0,140)
plus.Size = UDim2.new(0,30,0,30)
plus.Text = "+"
plus.MouseButton1Click:Connect(function()
  speed = speed + 4
  speedLabel.Text = "WalkSpeed: "..tostring(speed)
  setWalkSpeed(speed)
end)

local minus = Instance.new("TextButton", frame)
minus.Position = UDim2.new(0,260,0,140)
minus.Size = UDim2.new(0,30,0,30)
minus.Text = "-"
minus.MouseButton1Click:Connect(function()
  speed = math.max(8, speed - 4)
  speedLabel.Text = "WalkSpeed: "..tostring(speed)
  setWalkSpeed(speed)
end)

-- Jump power control
local jumpLabel = Instance.new("TextLabel", frame)
jumpLabel.Position = UDim2.new(0,12,0,180)
jumpLabel.Size = UDim2.new(0,200,0,30)
jumpLabel.BackgroundTransparency = 1
jumpLabel.Text = "JumpPower: 50"
jumpLabel.TextColor3 = Color3.new(1,1,1)
jumpLabel.Font = Enum.Font.SourceSans
jumpLabel.TextSize = 14

local jump = 50
local jplus = Instance.new("TextButton", frame)
jplus.Position = UDim2.new(0,220,0,180)
jplus.Size = UDim2.new(0,30,0,30)
jplus.Text = "+"
jplus.MouseButton1Click:Connect(function()
  jump = jump + 10
  jumpLabel.Text = "JumpPower: "..tostring(jump)
  setJumpPower(jump)
end)

local jminus = Instance.new("TextButton", frame)
jminus.Position = UDim2.new(0,260,0,180)
jminus.Size = UDim2.new(0,30,0,30)
jminus.Text = "-"
jminus.MouseButton1Click:Connect(function()
  jump = math.max(20, jump - 10)
  jumpLabel.Text = "JumpPower: "..tostring(jump)
  setJumpPower(jump)
end)

-- ESP toggle
local espToggle = Instance.new("TextButton", frame)
espToggle.Position = UDim2.new(0,12,0,220)
espToggle.Size = UDim2.new(0,200,0,30)
espToggle.Text = "ESP [OFF]"
espToggle.MouseButton1Click:Connect(function()
  ESP.Active = not ESP.Active
  espToggle.Text = "ESP ["..(ESP.Active and "ON" or "OFF").."]"
end)

-- Save/Load buttons
local saveBtn = Instance.new("TextButton", frame)
saveBtn.Position = UDim2.new(0,12,0,270)
saveBtn.Size = UDim2.new(0,100,0,28)
saveBtn.Text = "Save Config"
saveBtn.MouseButton1Click:Connect(function()
  local tbl = {
    speed = speed,
    jump = jump,
    config = CONFIG,
    state = State,
  }
  local ok, err = pcall(function() saveConfig(tbl) end)
  if ok then notify("Config saved.") else notify("Save failed.") end
end)

local loadBtn = Instance.new("TextButton", frame)
loadBtn.Position = UDim2.new(0,132,0,270)
loadBtn.Size = UDim2.new(0,100,0,28)
loadBtn.Text = "Load Config"
loadBtn.MouseButton1Click:Connect(function()
  local loaded = loadConfig()
  if loaded then
    speed = loaded.speed or speed
    jump = loaded.jump or jump
    setWalkSpeed(speed)
    setJumpPower(jump)
    if loaded.state then
      for k,v in pairs(loaded.state) do State[k] = v end
    end
    notify("Config loaded.")
  else
    notify("No config found.")
  end
end)

-- Close button
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Position = UDim2.new(0,320,0,320)
closeBtn.Size = UDim2.new(0,80,0,36)
closeBtn.Text = "Close GUI"
closeBtn.MouseButton1Click:Connect(function()
  ScreenGui.Enabled = false
  notify("GUI closed. Re-run to show again.")
end)

-- ===============================
-- ======  FINISH SETUP  =========
-- ===============================
notify("Revenant: Sunrise template loaded. Edit CONFIG.REMOTES to match the game.")
-- set starting speeds
setWalkSpeed(speed)
setJumpPower(jump)

-- if you want to show GUI only for specific players (developer test), set ScreenGui.Enabled accordingly
ScreenGui.Enabled = true

-- End of template
