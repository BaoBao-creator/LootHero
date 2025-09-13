local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local function heal()
    humanoid.Health = humanoid.MaxHealth
end
humanoid.HealthChanged:Connect(heal)
humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(heal)
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/BaoBao-creator/Simple-Ui/main/UI.lua'))()
local Window = UI:CreateWindow({
    Name = "Loot Hero Panel",
    LoadingTitle = "Simple-Hub, Welcome",
    LoadingSubtitle = "Made by BaoBao",
    ConfigurationSaving = {
        Enabled = true,
        FileName = "MyConfig"
    }
})
