local RunService = game:GetService("RunService")
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
local basespeed = humanoid.WalkSpeed
local hackspeed = basespeed
local function speed(v)
    if v then
        Humanoid.WalkSpeed = hackspeed
    else
        Humanoid.WalkSpeed = basespeed
    end
end
local enemies = workspace.Shader.Enemies
local lastCFrame = root.CFrame
local DISTANCE = 10
local childAddedConn
local steppedConn
local function lockMob(mob)
	local hum = mob:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 0
		hum.AutoRotate = false
		hum.PlatformStand = true
	end
	for _, part in ipairs(mob:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
end
local function placeMob(mob, targetCFrame)
	local hrp = mob:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local pos = targetCFrame.Position + targetCFrame.LookVector * DISTANCE
	mob:PivotTo(CFrame.new(pos))
end
local function onNewEnemy(e)
	if e:IsA("Model") and e:FindFirstChild("HumanoidRootPart") then
		lockMob(e)
		placeMob(e, root.CFrame)
	end
end
local function bringmob(v)
    if v then
        for _, mob in ipairs(enemies:GetChildren()) do 
            onNewEnemy(mob)
        end
        childAddedConn = enemies.ChildAdded:Connect(onNewEnemy)
        steppedConn = RunService.Stepped:Connect(function()
            if root.CFrame ~= lastCFrame then
                lastCFrame = root.CFrame
                for _, mob in ipairs(enemies:GetChildren()) do
                    if mob:IsA("Model") then
                        placeMob(mob, lastCFrame)
                    end
                end
            end
        end)
    else
        if childAddedConn then
            childAddedConn:Disconnect()
            childAddedConn = nil
        end   
        if steppedConn then 
            steppedConn:Disconnect() 
            steppedConn = nil
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
local SpeedSlider = MainTab:CreateSlider({
    Name = "Walkspeed",
    Range = {0, 100},
    Increment = 10,
    Suffix = "",
    CurrentValue = basespeed,
    Flag = "SpeedSlider",
    Callback = function(v)
        hackspeed = v
    end
})
local speedToggle = MainTab:CreateToggle({
    Name = "Apply Speed",
    CurrentValue = false,
    Flag = "speedtoggle",
    Callback = function(v)
        speed(v)
    end
})
local bringToggle = MainTab:CreateToggle({
    Name = "Bring Mob",
    CurrentValue = false,
    Flag = "bringtoggle",
    Callback = function(v)
        bringmon(v)
    end
})
local DisSlider = MainTab:CreateSlider({
    Name = "Distance",
    Range = {0, 100},
    Increment = 10,
    Suffix = "",
    CurrentValue = 10,
    Flag = "disSlider",
    Callback = function(v)
        DISTANCE = v
    end
})
