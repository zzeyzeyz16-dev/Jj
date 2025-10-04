-- DefeatRake_Template.lua + Infinite Stamina (FOR YOUR OWN PLACE ONLY)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Get the character and humanoid like before
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

----------------------------------------------------------------------
-- 🔋 INFINITE STAMINA SECTION
-- change this to the actual location of your stamina NumberValue
-- for example: local stamina = player:WaitForChild("leaderstats"):WaitForChild("Stamina")
----------------------------------------------------------------------

local stamina = player:FindFirstChild("Stamina") or nil
if stamina then
    -- loop to top off stamina every 0.1 seconds
    task.spawn(function()
        while true do
            -- if your value has .MaxValue use that, otherwise pick your full value (like 100)
            local max = stamina:FindFirstChild("MaxValue") and stamina.MaxValue or 1000
            stamina.Value = max
            task.wait(100)
        end
    end)
end

-- if your stamina is actually handled in Humanoid.WalkSpeed/JumpPower instead,
-- you can just bump those up once:
-- humanoid.WalkSpeed = 32
-- humanoid.JumpPower = 75
----------------------------------------------------------------------

-- the rest of your auto-fight script goes here (unchanged)
-- … (the GUI code and auto-fight loop from earlier)
