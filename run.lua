local player = game.Players.LocalPlayer
local char = player.Character
local humanoid = char.Humanoid
local health = humanoid.Health
local maxhealth = humanoid.MaxHealth
local healthchangeconnect
local maxhealthchangeconnect
local function heal()
    health = maxhealth
end
