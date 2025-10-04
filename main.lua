-- LocalScript (put under ScreenGui)
local players = game:GetService("Players")
local player = players.LocalPlayer
local gui = script.Parent

local activateBtn = gui:WaitForChild("ActivateButton")
local toggleBtn   = gui:WaitForChild("ToggleNoCooldown")
local cdLabel     = gui:WaitForChild("CooldownLabel")

-- CONFIG
local COOLDOWN_SECONDS = 8            -- default cooldown length
local isDevMode = false               -- toggleable for developer testing

-- internal state
local onCooldown = false
local cooldownRemaining = 0

-- Utility: update label
local function updateLabel()
    if onCooldown then
        cdLabel.Text = string.format("Cooldown: %.1f s", cooldownRemaining)
    else
        cdLabel.Text = "Ready"
    end
end

-- Ability activation logic
local function activateAbility()
    -- If dev mode (no cooldown), just perform action
    if isDevMode then
        -- perform ability (replace with your own effect)
        print("Ability used (DEV MODE - no cooldown)")
        -- show a quick feedback flash
        cdLabel.Text = "Used (dev)"
        wait(0.5)
        updateLabel()
        return
    end

    -- Normal flow: respect cooldown
    if onCooldown then
        -- optionally notify the player
        print("Ability on cooldown; please wait.")
        return
    end

    -- perform ability (replace with desired behavior)
    print("Ability used")
    -- start cooldown
    onCooldown = true
    cooldownRemaining = COOLDOWN_SECONDS
    updateLabel()

    -- tick the cooldown (client-side timer for UI; server should enforce real cooldown for security)
    while cooldownRemaining > 0 do
        wait(0.1)
        cooldownRemaining = cooldownRemaining - 0.1
        if cooldownRemaining < 0 then cooldownRemaining = 0 end
        updateLabel()
    end

    onCooldown = false
    updateLabel()
end

-- Toggle developer no-cooldown mode
local function toggleDevMode()
    isDevMode = not isDevMode
    toggleBtn.Text = isDevMode and "Dev Mode: ON" or "Dev Mode: OFF"
    print("Dev mode set to", isDevMode)
    updateLabel()
end

-- connect UI
activateBtn.MouseButton1Click:Connect(activateAbility)
toggleBtn.MouseButton1Click:Connect(toggleDevMode)

-- initial UI
toggleBtn.Text = "Dev Mode: OFF"
updateLabel()
