--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local Sprinting = game:GetService("ReplicatedStorage").Systems.Character.Game.Sprinting
local stamina = require(Sprinting)
energy.MaxEnergy = 230  -- Maximum stamina
energy.MinEnergy = -20  -- Minimum stamina
energy.EnergyGain = 100 -- Stamina gain
energy.EnergyLoss = 5 -- Stamina loss
energy.SprintSpeed = 40 -- Sprint speed
energy.EnergyLossDisabled = true -- Disable stamina drain (true/false)
