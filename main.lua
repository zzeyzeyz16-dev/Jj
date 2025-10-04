local gui = script.Parent
local activateBtn = gui:WaitForChild("ActivateButton")
local toggleBtn   = gui:WaitForChild("ToggleNoCooldown")
local cdLabel     = gui:WaitForChild("CooldownLabel")

local COOLDOWN_SECONDS = 5  -- normal cooldown time
local noCooldown = false    -- toggle state
local onCooldown = false
local remaining = 0

local function updateLabel()
	if onCooldown then
		cdLabel.Text = string.format("Cooldown: %.1f s", remaining)
	else
		cdLabel.Text = "Ready"
	end
end

local function useAbility()
	if noCooldown then
		-- Do your ability instantly (no cooldown)
		print("Ability used (no cooldown mode)")
		cdLabel.Text = "Used (no cooldown)"
		wait(0.5)
		updateLabel()
		return
	end
	
	if onCooldown then
		print("Ability on cooldown!")
		return
	end
	
	-- normal ability
	print("Ability used")
	onCooldown = true
	remaining = COOLDOWN_SECONDS
	updateLabel()
	
	while remaining > 0 do
		wait(0.1)
		remaining -= 0.1
		if remaining < 0 then remaining = 0 end
		updateLabel()
	end
	
	onCooldown = false
	updateLabel()
end

local function toggleNoCooldown()
	noCooldown = not noCooldown
	toggleBtn.Text = noCooldown and "No Cooldown: ON" or "No Cooldown: OFF"
	updateLabel()
end

activateBtn.MouseButton1Click:Connect(useAbility)
toggleBtn.MouseButton1Click:Connect(toggleNoCooldown)

updateLabel()
