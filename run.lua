local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local function heal()
    humanoid.Health = humanoid.MaxHealth
end
humanoid.HealthChanged:Connect(heal)
humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(heal)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Simple Hub",
    LoadingTitle = "Welcome!",
    LoadingSubtitle = "by BaoBao",
    ShowText = "UI",
    Theme = "Bloom",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "Simple Hub Config"
    }
})
local MainTab = Window:CreateTab("Main", 0)
local AutoHealToggle = EventTab:CreateToggle({
    Name = "Auto Heal",
    Flag = "AutoHealToggle",
    Callback = function(v)
        autoCollectFairy(v)
    end
})
