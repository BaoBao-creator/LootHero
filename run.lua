--// Services
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

--// Auto Collect
local pickupsFolder = workspace:WaitForChild("Pickups")
local autocoinconnect = nil

local function tpcoin(obj)
    if obj:IsA("BasePart") then
        obj.CFrame = root.CFrame
    end
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

--// Speed Hack
local basespeed = humanoid.WalkSpeed
local hackspeed = basespeed

local function speed(v)
    if v then
        humanoid.WalkSpeed = hackspeed
    else
        humanoid.WalkSpeed = basespeed
    end
end

--// Bring Mob
local enemies = workspace:WaitForChild("Shader"):WaitForChild("Enemies")
local lastCFrame = root.CFrame
local DISTANCE = 10
local childAddedConn, steppedConn

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

--// Dodge bullets

local MIN_DIST = 10
local MIN_DIST_SQ = MIN_DIST * MIN_DIST
local SEARCH_RADIUS = 30
local STEP = 3
local UPDATE_RATE = 0.08
local CLEANUP_INTERVAL = 5

local projectiles, projCount = {}, 0
local function addProjectile(p)
    if not p or not p:IsA("BasePart") or projectiles[p] then return end
    projectiles[p] = true
    projCount += 1
end
local function removeProjectile(p)
    if projectiles[p] then projectiles[p] = nil projCount -= 1 end
end

workspace.Shader.Debris.ChildAdded:Connect(function(desc)
    if desc:IsA("BasePart") and string.find(desc.Name,"Projectile") then
        addProjectile(desc)
        desc.AncestryChanged:Connect(function(_,parent) if not parent then removeProjectile(desc) end end)
    end
end)
workspace.Shader.Debris.ChildRemoving:Connect(function(desc) if projectiles[desc] then removeProjectile(desc) end end)

task.spawn(function()
    while true do
        task.wait(CLEANUP_INTERVAL)
        for p in pairs(projectiles) do
            if not p or not p.Parent or not p:IsA("BasePart") then removeProjectile(p) end
        end
    end
end)

local function collectProjectiles()
    local out = {}
    for p in pairs(projectiles) do
        if p and p.Parent and p:IsA("BasePart") then table.insert(out,p) end
    end
    return out
end

local function distanceSq(a,b)
    local dx,dy,dz=a.X-b.X,a.Y-b.Y,a.Z-b.Z
    return dx*dx+dy*dy+dz*dz
end

-- Lưu 4 điểm góc bản đồ
local mapCorners = {}

function SaveCorner(index)
    if hrp then
        mapCorners[index] = hrp.Position
    end
end

-- Lấy giới hạn min/max X,Z từ 4 điểm
local function getMapBounds()
    if #mapCorners < 4 then return nil end
    local minX, maxX = math.huge, -math.huge
    local minZ, maxZ = math.huge, -math.huge
    for _,pos in pairs(mapCorners) do
        minX = math.min(minX, pos.X)
        maxX = math.max(maxX, pos.X)
        minZ = math.min(minZ, pos.Z)
        maxZ = math.max(maxZ, pos.Z)
    end
    return minX, maxX, minZ, maxZ
end

-- Kiểm tra xem pos có nằm trong map không
local function inMapBounds(pos)
    local minX, maxX, minZ, maxZ = getMapBounds()
    if not minX then return true end -- chưa set thì cho qua
    return pos.X >= minX and pos.X <= maxX and pos.Z >= minZ and pos.Z <= maxZ
end

local function isValidPosition(pos,bullets)
    for _,b in ipairs(bullets) do
        if b and b:IsA("BasePart") and b.Parent and distanceSq(b.Position,pos)<MIN_DIST_SQ then 
            return false 
        end
    end
    if not inMapBounds(pos) then return false end
    return true
end

local function quickDodgeFromBullet(bullet)
    local dir=hrp.Position-bullet.Position
    dir=Vector3.new(dir.X,0,dir.Z)
    if dir.Magnitude<0.001 then dir=Vector3.new(math.random()-0.5,0,math.random()-0.5) end
    local unit=dir.Unit
    local newPos=bullet.Position+unit*MIN_DIST
    return Vector3.new(newPos.X,hrp.Position.Y,newPos.Z)
end

local function findSafePosition(bullets)
    if not hrp or not hrp.Parent then return nil end
    if isValidPosition(hrp.Position,bullets) then return hrp.Position end
    local closestBullet,closestDistSq=nil,math.huge
    for _,b in ipairs(bullets) do
        if b and b:IsA("BasePart") and b.Parent then
            local d2=distanceSq(b.Position,hrp.Position)
            if d2<closestDistSq then closestDistSq,closestBullet=d2,b end
        end
    end
    if closestBullet and closestDistSq<(MIN_DIST*1.5)*(MIN_DIST*1.5) then
        local tryPos=quickDodgeFromBullet(closestBullet)
        if isValidPosition(tryPos,bullets) then return tryPos end
    end
    local origin=hrp.Position
    for r=STEP,SEARCH_RADIUS,STEP do
        local tries=math.max(8,math.floor(2*math.pi*r/STEP))
        for i=1,tries do
            local angle=(i/tries)*math.pi*2
            local checkPos=origin+Vector3.new(math.cos(angle)*r,0,math.sin(angle)*r)
            if isValidPosition(checkPos,bullets) then return checkPos end
        end
    end
    return nil
end

local function moveHRPTo(pos)
    if not hrp or not hrp.Parent then return end
    hrp.CFrame=CFrame.new(pos.X,hrp.Position.Y,pos.Z)
end

local accumulator=0
RunService.Heartbeat:Connect(function(dt)
    accumulator+=dt
    if accumulator<UPDATE_RATE then return end
    accumulator=0
    if not hrp or not hrp.Parent or projCount==0 then return end
    local bullets=collectProjectiles()
    local limitSq=(SEARCH_RADIUS+MIN_DIST)^2
    local anyNearby=false
    for _,b in ipairs(bullets) do
        if b and b:IsA("BasePart") and b.Parent and distanceSq(b.Position,hrp.Position)<=limitSq then anyNearby=true break end
    end
    if not anyNearby then return end
    local safePos=findSafePosition(bullets)
    if safePos then moveHRPTo(safePos) end
end)
--// UI (Rayfield)
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

MainTab:CreateToggle({
    Name = "Auto Collect",
    CurrentValue = false,
    Flag = "autocoinToggle",
    Callback = autocollect
})

MainTab:CreateSlider({
    Name = "Walkspeed",
    Range = {0, 100},
    Increment = 10,
    CurrentValue = basespeed,
    Flag = "SpeedSlider",
    Callback = function(v)
        hackspeed = v
    end
})

MainTab:CreateToggle({
    Name = "Apply Speed",
    CurrentValue = false,
    Flag = "speedtoggle",
    Callback = speed
})

MainTab:CreateToggle({
    Name = "Bring Mob",
    CurrentValue = false,
    Flag = "bringtoggle",
    Callback = bringmob
})

MainTab:CreateSlider({
    Name = "Distance",
    Range = {0, 100},
    Increment = 10,
    CurrentValue = DISTANCE,
    Flag = "disSlider",
    Callback = function(v)
        DISTANCE = v
    end
})
