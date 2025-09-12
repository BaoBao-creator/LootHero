local player = game.Players.LocalPlayer
local char = player.Character
local humanoid = char.Humanoid
local health = humanoid.Health
local maxhealth = humanoid.MaxHealth
local function heal()
    health = maxhealth
end
humanoid.HealthChanged:Connect(function()
    heal()
end)
humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
    maxhealth = humanoid.MaxHealth
end)
