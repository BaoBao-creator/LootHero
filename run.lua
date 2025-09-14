--// Services
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local char = player.Character
local humanoid = char.Humanoid
local root = char.HumanoidRootPart
local shader = workspace.Shader
--// Auto Collect
local pickupsFolder = workspace.Pickups
local autocoinconnect = nil
local function tpcoin(obj)
    obj.CFrame = root.CFrame
end
local function autocollect(v)
    if v then
        task.spawn(function()
            while autocoinconnect do
                for _, coin in ipairs(pickupsFolder:GetChildren()) do
                    tpcoin(coin)
                end
            end
            task.wait(60)
        end)
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
local enemiesFolder = shader.Enemies
local enemies
local childAddedConn
local firstmob
local function lockMob(mob)
    local hum = mob.Humanoid
    hum.WalkSpeed = 0
    hum.AutoRotate = false
    hum.PlatformStand = true
    for _, part in ipairs(mob:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end
end
local function placeMob(mob, targetCFrame)
    local hrp = mob.HumanoidRootPart
    
    mob:PivotTo(CFrame.new())
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
local DISTANCE = 10
local MIN_DIST = 10
local MIN_DIST_SQ = MIN_DIST * MIN_DIST
local SEARCH_RADIUS = 30
local STEP = 3
local BRING_INTERVAL = 0.25
local DODGE_INTERVAL = 0.12
local MAX_SCAN_PROJECTILES = 20

local enemies = {}
local projectiles = {}
local projCount = 0

local enemiesChildAddedConn, enemiesChildRemovingConn
local debrisChildAddedConn, debrisChildRemovingConn

local bringEnabled = false
local connectEnemiesEnabled = true
local connectDebrisEnabled = true

local primaryEnemy = nil
local primaryDiedConn = nil

local function distanceSq(a,b)
    local dx,dy,dz = a.X-b.X, a.Y-b.Y, a.Z-b.Z
    return dx*dx + dy*dy + dz*dz
end

local function isEnemyAlive(m)
    if not m or not m:IsA("Model") then return false end
    local h = m:FindFirstChildOfClass("Humanoid")
    return h and h.Health and h.Health > 0
end

local function addEnemy(m)
    if not m or not m:IsA("Model") then return end
    if enemies[m] then return end
    enemies[m] = {locked = false}
end

local function removeEnemy(m)
    if enemies[m] then enemies[m] = nil end
    if primaryEnemy == m then primaryEnemy = nil end
end

local function populateEnemies()
    for _,v in ipairs(enemiesFolder:GetChildren()) do
        if v:IsA("Model") then addEnemy(v) end
    end
end

local function addProjectile(p)
    if not p or not p:IsA("BasePart") then return end
    if projectiles[p] then return end
    projectiles[p] = true
    projCount = projCount + 1
    p.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if projectiles[p] then projectiles[p] = nil; projCount = math.max(0, projCount - 1) end
        end
    end)
end

local function removeProjectile(p)
    if projectiles[p] then projectiles[p] = nil; projCount = math.max(0, projCount - 1) end
end

local function populateProjectiles()
    for _,v in ipairs(debrisFolder:GetChildren()) do
        if v:IsA("BasePart") and string.find(v.Name, "Projectile") then
            addProjectile(v)
        end
    end
end

local function lockMob(mob)
    if not mob or not mob:IsA("Model") then return end
    local info = enemies[mob]
    if info and info.locked then return end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum.WalkSpeed = 0
            hum.AutoRotate = false
            hum.PlatformStand = true
        end)
    end
    for _, part in ipairs(mob:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end
    if info then info.locked = true end
end

local function placeMobAt(mob, targetCFrame, offset)
    if not mob or not mob:IsA("Model") then return end
    local hrpm = mob:FindFirstChild("HumanoidRootPart")
    if not hrpm or not targetCFrame then return end
    local pos = targetCFrame.Position + (offset or Vector3.new(0,0,0))
    mob:PivotTo(CFrame.new(pos))
end

local function choosePrimary()
    if primaryEnemy and isEnemyAlive(primaryEnemy) then return primaryEnemy end
    local best = nil
    local bestDist = math.huge
    for m,_ in pairs(enemies) do
        if isEnemyAlive(m) then
            local mhrp = m:FindFirstChild("HumanoidRootPart")
            if mhrp then
                local d2 = distanceSq(mhrp.Position, hrp.Position)
                if d2 < bestDist then
                    bestDist = d2
                    best = m
                end
            end
        end
    end
    primaryEnemy = best
    if primaryEnemy then
        local phum = primaryEnemy:FindFirstChildOfClass("Humanoid")
        if phum then
            if primaryDiedConn then primaryDiedConn:Disconnect() end
            primaryDiedConn = phum.Died:Connect(function() primaryEnemy = nil end)
        end
    end
    return primaryEnemy
end

local function bringAllToPrimaryOnce()
    if not primaryEnemy or not isEnemyAlive(primaryEnemy) then return end
    local pHRP = primaryEnemy:FindFirstChild("HumanoidRootPart")
    if not pHRP then return end
    local list = {}
    for m,_ in pairs(enemies) do
        if m ~= primaryEnemy and isEnemyAlive(m) then
            local mhrp = m:FindFirstChild("HumanoidRootPart")
            if mhrp then
                table.insert(list, m)
            end
        end
    end
    local n = #list
    if n == 0 then return end
    for i,m in ipairs(list) do
        local angle = ((i-1) / n) * math.pi * 2
        local radius = math.max(1.5, DISTANCE)
        local off = Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
        lockMob(m)
        placeMobAt(m, pHRP.CFrame, off)
    end
end

local function bringUpdate(dt)
    if not bringEnabled then return end
    if not primaryEnemy or not isEnemyAlive(primaryEnemy) then
        choosePrimary()
        if not primaryEnemy then return end
        bringAllToPrimaryOnce()
        return
    end
    local pHRP = primaryEnemy:FindFirstChild("HumanoidRootPart")
    if not pHRP then return end
    for m,info in pairs(enemies) do
        if m ~= primaryEnemy and isEnemyAlive(m) then
            local mhrp = m:FindFirstChild("HumanoidRootPart")
            if mhrp then
                local dist2 = distanceSq(mhrp.Position, pHRP.Position)
                local threshold = (DISTANCE + 1) * (DISTANCE + 1)
                if dist2 > threshold then
                    lockMob(m)
                    local dir = (mhrp.Position - pHRP.Position)
                    dir = Vector3.new(dir.X, 0, dir.Z)
                    local mag = dir.Magnitude
                    local unit = mag > 0.001 and dir.Unit or Vector3.new(1,0,0)
                    local targetPos = pHRP.Position + unit * DISTANCE
                    m:PivotTo(CFrame.new(targetPos))
                end
            end
        end
    end
end

local function collectProjectilesNear()
    local out = {}
    for p,_ in pairs(projectiles) do
        if p and p.Parent and p:IsA("BasePart") then
            table.insert(out, p)
        end
    end
    table.sort(out, function(a,b)
        return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
    end)
    local limit = math.min(#out, MAX_SCAN_PROJECTILES)
    local res = {}
    for i=1,limit do res[i] = out[i] end
    return res
end

local function isValidPosition(pos, bullets)
    for _, b in ipairs(bullets) do
        if b and b:IsA("BasePart") and b.Parent and distanceSq(b.Position, pos) < MIN_DIST_SQ then
            return false
        end
    end
    for m,_ in pairs(enemies) do
        if m and m.Parent and isEnemyAlive(m) then
            local mhrp = m:FindFirstChild("HumanoidRootPart")
            if mhrp and distanceSq(mhrp.Position, pos) < MIN_DIST_SQ then
                return false
            end
        end
    end
    return true
end

local function quickDodgeFromBullet(bullet)
    if not bullet then return hrp.Position end
    local dir = hrp.Position - bullet.Position
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude < 0.001 then dir = Vector3.new(math.random()-0.5, 0, math.random()-0.5) end
    local unit = dir.Unit
    local newPos = bullet.Position + unit * MIN_DIST
    return Vector3.new(newPos.X, hrp.Position.Y, newPos.Z)
end

local function findSafePosition(bullets)
    if not hrp or not hrp.Parent then return nil end
    if isValidPosition(hrp.Position, bullets) then return hrp.Position end
    local closestBullet, closestDistSq = nil, math.huge
    for _, b in ipairs(bullets) do
        if b and b:IsA("BasePart") and b.Parent then
            local d2 = distanceSq(b.Position, hrp.Position)
            if d2 < closestDistSq then closestDistSq, closestBullet = d2, b end
        end
    end
    if closestBullet and closestDistSq < (MIN_DIST*1.5)*(MIN_DIST*1.5) then
        local tryPos = quickDodgeFromBullet(closestBullet)
        if isValidPosition(tryPos, bullets) then return tryPos end
    end
    local origin = hrp.Position
    for r = STEP, SEARCH_RADIUS, STEP do
        local tries = math.max(8, math.floor(2*math.pi*r/STEP))
        for i = 1, tries do
            local angle = (i / tries) * math.pi * 2
            local checkPos = origin + Vector3.new(math.cos(angle)*r, 0, math.sin(angle)*r)
            if isValidPosition(checkPos, bullets) then return checkPos end
        end
    end
    return nil
end

local function moveHRPTo(pos)
    if not hrp or not hrp.Parent then return end
    hrp.CFrame = CFrame.new(pos.X, hrp.Position.Y, pos.Z)
end

local lastBring = 0
local lastDodge = 0

local function heartbeat(dt)
    lastBring = lastBring + dt
    lastDodge = lastDodge + dt
    if lastDodge >= DODGE_INTERVAL then
        lastDodge = 0
        if projCount > 0 then
            local bullets = collectProjectilesNear()
            local anyNearby = false
            for _, b in ipairs(bullets) do
                if b and b:IsA("BasePart") and b.Parent and distanceSq(b.Position, hrp.Position) <= (SEARCH_RADIUS + MIN_DIST) ^ 2 then anyNearby = true break end
            end
            if anyNearby then
                local safePos = findSafePosition(bullets)
                if safePos then moveHRPTo(safePos) end
            end
        end
    end
    if lastBring >= BRING_INTERVAL then
        lastBring = 0
        bringUpdate(dt)
    end
end

local heartbeatConn = RunService.Heartbeat:Connect(heartbeat)

local function onEnemyAdded(child)
    if child:IsA("Model") then
        addEnemy(child)
        if bringEnabled and primaryEnemy and isEnemyAlive(primaryEnemy) then
            local pHRP = primaryEnemy:FindFirstChild("HumanoidRootPart")
            if pHRP then
                local idx = 1
                for _ in pairs(enemies) do idx = idx + 1 end
                local angle = ((idx-1) / math.max(1, idx)) * math.pi * 2
                local radius = math.max(1.5, DISTANCE)
                local off = Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
                lockMob(child)
                placeMobAt(child, pHRP.CFrame, off)
            end
        end
    end
end

local function onEnemyRemoving(child)
    if child and child:IsA("Model") then removeEnemy(child) end
end

local function onDebrisAdded(child)
    if child:IsA("BasePart") and string.find(child.Name, "Projectile") then addProjectile(child) end
end

local function onDebrisRemoving(child)
    if child and projectiles[child] then removeProjectile(child) end
end

local function connectEnemies()
    if enemiesChildAddedConn then return end
    populateEnemies()
    enemiesChildAddedConn = enemiesFolder.ChildAdded:Connect(onEnemyAdded)
    enemiesChildRemovingConn = enemiesFolder.ChildRemoving:Connect(onEnemyRemoving)
    connectEnemiesEnabled = true
end

local function disconnectEnemies()
    if enemiesChildAddedConn then enemiesChildAddedConn:Disconnect(); enemiesChildAddedConn = nil end
    if enemiesChildRemovingConn then enemiesChildRemovingConn:Disconnect(); enemiesChildRemovingConn = nil end
    enemies = {}
    connectEnemiesEnabled = false
    primaryEnemy = nil
    if primaryDiedConn then primaryDiedConn:Disconnect(); primaryDiedConn = nil end
end

local function connectDebris()
    if debrisChildAddedConn then return end
    populateProjectiles()
    debrisChildAddedConn = debrisFolder.ChildAdded:Connect(onDebrisAdded)
    debrisChildRemovingConn = debrisFolder.ChildRemoving:Connect(onDebrisRemoving)
    connectDebrisEnabled = true
end

local function disconnectDebris()
    if debrisChildAddedConn then debrisChildAddedConn:Disconnect(); debrisChildAddedConn = nil end
    if debrisChildRemovingConn then debrisChildRemovingConn:Disconnect(); debrisChildRemovingConn = nil end
    projectiles = {}
    projCount = 0
    connectDebrisEnabled = false
end

connectEnemies()
connectDebris()

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
    Name = "Bring Mob",
    CurrentValue = false,
    Flag = "bringtoggle",
    Callback = function(v)
        bringEnabled = v
        if v then
            choosePrimary()
            if primaryEnemy then bringAllToPrimaryOnce() end
        end
    end
})

MainTab:CreateSlider({
    Name = "Distance to Primary",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = DISTANCE,
    Flag = "disSlider",
    Callback = function(v) DISTANCE = v end
})

MainTab:CreateToggle({
    Name = "Connect Enemies Folder",
    CurrentValue = true,
    Flag = "connectEnemies",
    Callback = function(v)
        if v then connectEnemies() else disconnectEnemies() end
    end
})

MainTab:CreateToggle({
    Name = "Connect Debris Folder",
    CurrentValue = true,
    Flag = "connectDebris",
    Callback = function(v)
        if v then connectDebris() else disconnectDebris() end
    end
})

local cornerOptions = {"Corner 1","Corner 2","Corner 3","Corner 4"}
local selectedCorner = "Corner 1"
MainTab:CreateDropdown({
    Name = "Select Corner",
    Options = cornerOptions,
    CurrentOption = selectedCorner,
    Flag = "cornerDropdown",
    Callback = function(option) selectedCorner = option end
})
MainTab:CreateButton({
    Name = "Save Corner",
    Callback = function()
        local idx = 1
        for i,v in ipairs(cornerOptions) do if v == selectedCorner then idx = i break end end
        if hrp then
            _G.mapCorners = _G.mapCorners or {}
            _G.mapCorners[idx] = hrp.Position
            if #_G.mapCorners >= 4 then
                local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
                local count = 0
                for _, pos in pairs(_G.mapCorners) do
                    if pos then
                        count = count + 1
                        minX = math.min(minX, pos.X); maxX = math.max(maxX, pos.X)
                        minZ = math.min(minZ, pos.Z); maxZ = math.max(maxZ, pos.Z)
                    end
                end
                if count >= 4 then
                    _G.mapBoundsMinX, _G.mapBoundsMaxX, _G.mapBoundsMinZ, _G.mapBoundsMaxZ = minX, maxX, minZ, maxZ
                end
            end
        end
    end
})
MainTab:CreateButton({
    Name = "Clear Corners",
    Callback = function()
        _G.mapCorners = nil
        _G.mapBoundsMinX = nil
        _G.mapBoundsMaxX = nil
        _G.mapBoundsMinZ = nil
        _G.mapBoundsMaxZ = nil
    end
})

player.CharacterAdded:Connect(function(c)
    char = c
    humanoid = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
end)
