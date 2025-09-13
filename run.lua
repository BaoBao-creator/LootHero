local player = game.Players.LocalPlayer
local char = player.Character
local humanoid = char.Humanoid
local root = char.HumanoidRootPart
local healthchangeconnect = nil
local maxhealthchangeconnect = nil
local function heal()
    humanoid.Health = humanoid.MaxHealth
end
local function autoheal(v)
    if v then
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
local pickupsFolder = workspace.Pickups
local autocoinconnect = nil
local function tpcoin(obj)
    obj.CFrame = root.CFrame
end
local function autocollect(v)
    if v then
        for _, coin in ipairs(pickupsFolder:GetChildren()) do
            tpcoin(coin)
        end
        autocoinconnect = pickupsFolder.ChildAdded:Connect(function(child)
            task.wait(0.01)
            tpcoin(child)
        end)
    else
        if autocoinconnect then
            autocoinconnect:Disconnect()
            autocoinconnect = nil
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
local AutoHealToggle = MainTab:CreateToggle({
    Name = "Auto Heal",
    CurrentValue = false,
    Flag = "autohealToggle",
    Callback = function(v)
        autoheal(v)
    end
})
local AutoCoinToggle = MainTab:CreateToggle({
    Name = "Auto Collect",
    CurrentValue = false,
    Flag = "autocoinToggle",
    Callback = function(v)
        autocollect(v)
    end
})
local Slider = Tab:CreateSlider({
    Name = "Walkspeed",
    Range = {0, 100},
    Increment = 10,
    Suffix = "Bananas",
    CurrentValue = 10,
    Flag = "Slider1",
    Callback = function(Value)
    end
})
