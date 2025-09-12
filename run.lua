local player = game.Players.LocalPlayer
local char = player.Character
local humanoid = char.Humanoid
local function heal()
while true do
    task.wait(0.1)
    if humanoid.Health < humanoid.MaxHealth then
        humanoid.Health = humanoid.MaxHealth
    end
end
