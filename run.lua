local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local healing = false
local healthchangeconnect = nil
local maxhealthchangeconnect = nil
local function heal()
    humanoid.Health = humanoid.MaxHealth
end
local function autoheal(v)
    healing = v
    if healing then
        heal()
        healthchangeconnect = humanoid.HealthChanged:Connect(heal)
        maxhealthchangeconnect = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(heal)
    else
        if healthchangeconnect and maxhealthchangeconnect then
            healthchangeconnect:Disconnect()
            maxhealthchangeconnect:Disconnect()
            healthchangeconnect = nil
            maxhealthchangeconnect = nil
        end
    end
end
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
        autoheal(v)
    end
})
