-- modules/God.lua
-- God Mode v23 + Tower Mover
-- ============================================

local M = getgenv().MzD

-- ========== TOWER HELPERS ==========
function M.findTower()
    local ok, tower = pcall(function()
        return workspace.GameObjects.PlaceSpecific.root.Tower
    end)
    if ok and tower then return tower end
    for _, c in pairs(workspace:GetDescendants()) do
        if c.Name == "Tower" and c:IsA("Model") then
            local count = 0
            for _, d in pairs(c:GetDescendants()) do
                if d:IsA("BasePart") then count += 1 end
                if count > 5 then return c end
            end
        end
    end
    return nil
end

function M.getTowerY()
    local tower = M.findTower()
    if not tower then return nil end
    local ok, pivot = pcall(function() return tower:GetPivot() end)
    if ok and pivot then return pivot.Position.Y end
    return nil
end

function M.getTowerBottomY()
    local tower = M.findTower()
    if not tower then return nil end
    local minY = math.huge
    for _, part in pairs(tower:GetDescendants()) do
        if part:IsA("BasePart") then
            local bottom = part.Position.Y - part.Size.Y / 2
            if bottom < minY then minY = bottom end
        end
    end
    if minY == math.huge then return nil end
    return minY
end

function M.detectFloorY()
    local floors = {}

    for _, c in pairs(workspace:GetChildren()) do
        if c:IsA("BasePart") and c.Name == "MzDGodFloor" then
            table.insert(floors, {
                y = c.Position.Y + c.Size.Y / 2,
                source = "GodFloor",
            })
        end
    end

    local map = nil
    for _, c in pairs(workspace:GetChildren()) do
        if c:IsA("Model") and c.Name:find("Map")
            and not c.Name:find("SharedInstances") then
            if c:FindFirstChild("Spawners") or c:FindFirstChild("Gaps")
                or c:FindFirstChild("FirstFloor")
                or c:FindFirstChild("Ground") then
                map = c
                break
            end
            local cnt = 0
            for _, d in pairs(c:GetDescendants()) do
                if d:IsA("BasePart") then cnt += 1 end
                if cnt > 10 then map = c; break end
            end
            if map then break end
        end
    end

    if map then
        for _, name in pairs({"FirstFloor","Ground","Floor","BridgeFloor"}) do
            local f = map:FindFirstChild(name)
            if f and f:IsA("BasePart") then
                table.insert(floors, {
                    y = f.Position.Y + f.Size.Y / 2,
                    source = "Map:" .. name,
                })
            end
        end
        local sp = map:FindFirstChild("Spawners")
        if sp then
            for _, s in pairs(sp:GetChildren()) do
                if s:IsA("BasePart") and s.Size.X > 15
                    and s.Size.Z > 5 and s.Size.Y < 20
                    and s.Position.Y > -15 and s.Position.Y < 30 then
                    table.insert(floors, {
                        y = s.Position.Y + s.Size.Y / 2,
                        source = "Spawner",
                    })
                end
            end
        end
        for _, c in pairs(map:GetChildren()) do
            if c:IsA("BasePart") and not M.isMzDPart(c)
                and c.Size.X > 30 and c.Size.Z > 15 and c.Size.Y < 15
                and c.Position.Y > -15 and c.Position.Y < 30 then
                table.insert(floors, {
                    y = c.Position.Y + c.Size.Y / 2,
                    source = "MapPart",
                })
            end
        end
    end

    for _, c in pairs(workspace:GetChildren()) do
        if c.Name:find("SharedInstances") then
            local fl = c:FindFirstChild("Floors")
            if fl then
                for _, f in pairs(fl:GetChildren()) do
                    if f:IsA("BasePart") and f.Size.X > 15 and f.Size.Z > 5 then
                        table.insert(floors, {
                            y = f.Position.Y + f.Size.Y / 2,
                            source = "Shared",
                        })
                    end
                end
            end
        end
    end

    local hrp = M.Player.Character
        and M.Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local excludeList = {}
        local tower = M.findTower()
        if tower then table.insert(excludeList, tower) end
        params.FilterDescendantsInstances = excludeList
        local result = workspace:Raycast(
            hrp.Position, Vector3.new(0, -100, 0), params
        )
        if result then
            table.insert(floors, {y = result.Position.Y, source = "Raycast"})
        end
    end

    if #floors == 0 then
        if hrp then return hrp.Position.Y - 3, "PlayerFallback" end
        return 0, "Default"
    end

    table.sort(floors, function(a, b) return a.y > b.y end)
    return floors[1].y, floors[1].source
end

-- ========== TOWER MOVER ==========
local function moveTowerToFloor(floorTopY, offset)
    local tower = M.findTower()
    if not tower then return false end
    if not M._towerOriginalCF then
        pcall(function()
            M._towerOriginalCF = tower:GetPivot()
            M._towerOriginalY = M._towerOriginalCF.Position.Y
        end)
    end
    local towerBottomY = M.getTowerBottomY()
    if not towerBottomY then return false end
    local targetBottom = floorTopY + offset
    local deltaY = targetBottom - towerBottomY
    if math.abs(deltaY) < 0.3 then return true end
    local pivot = tower:GetPivot()
    pcall(function() tower:PivotTo(pivot * CFrame.new(0, deltaY, 0)) end)
    pcall(function()
        for _, part in pairs(tower:GetDescendants()) do
            if part:IsA("BasePart") then part.Anchored = true end
        end
    end)
    M._towerMoved = true
    M._towerLastTargetY = targetBottom
    M._towerDetectedFloorY = floorTopY
    return true
end

local function restoreTower()
    if not M._towerOriginalCF then return false end
    local tower = M.findTower()
    if not tower then return false end
    pcall(function() tower:PivotTo(M._towerOriginalCF) end)
    M._towerMoved = false
    M._towerOriginalCF = nil
    M._towerOriginalY = nil
    M._towerLastTargetY = nil
    return true
end

local function startTowerWatcher()
    if M._towerWatchThread then
        pcall(task.cancel, M._towerWatchThread)
    end
    M._towerWatchThread = task.spawn(function()
        while M.S.DoomTowerEnabled and M._towerMoved do
            pcall(function()
                local tower = M.findTower()
                if tower and M._towerLastTargetY then
                    local bottomY = M.getTowerBottomY()
                    if bottomY and math.abs(bottomY - M._towerLastTargetY) > 3 then
                        local floorY = M._towerDetectedFloorY or M.detectFloorY()
                        moveTowerToFloor(floorY, M.S.DoomTowerOffset)
                    end
                    for _, part in pairs(tower:GetDescendants()) do
                        if part:IsA("BasePart") then part.Anchored = true end
                    end
                end
            end)
            task.wait(3)
        end
    end)
end

local function stopTowerWatcher()
    if M._towerWatchThread then
        pcall(task.cancel, M._towerWatchThread)
        M._towerWatchThread = nil
    end
end

function M.enableTowerDrop()
    M.S.DoomTowerEnabled = true
    local floorY, source = M.detectFloorY()
    M._towerDetectedFloorY = floorY
    M._towerDetectedSource = source
    local ok = moveTowerToFloor(floorY, M.S.DoomTowerOffset)
    if ok then
        startTowerWatcher()
        M.Status.doomTower = "Aan ✓ (floor:"
            .. string.format("%.0f", floorY)
            .. " off:" .. M.S.DoomTowerOffset .. ")"
    else
        M.Status.doomTower = "Tower niet gevonden"
    end
    return ok
end

function M.disableTowerDrop()
    M.S.DoomTowerEnabled = false
    stopTowerWatcher()
    restoreTower()
    M._towerMoved = false
    M.Status.doomTower = "Uit"
end

-- ========== GOD MODE INTERNALS ==========
local function godFindFloorParts()
    local floors = {}
    local map = nil
    for _, c in pairs(workspace:GetChildren()) do
        if c:IsA("Model") and c.Name:find("Map")
            and not c.Name:find("SharedInstances") then
            if c:FindFirstChild("Spawners") or c:FindFirstChild("Gaps")
                or c:FindFirstChild("FirstFloor")
                or c:FindFirstChild("Ground") then
                map = c
                break
            end
        end
    end
    if not map then
        for _, c in pairs(workspace:GetChildren()) do
            if c:IsA("Model") and c.Name:find("Map") then
                local cnt = 0
                for _, d in pairs(c:GetDescendants()) do
                    if d:IsA("BasePart") then cnt += 1 end
                    if cnt > 10 then map = c; break end
                end
                if map then break end
            end
        end
    end
    local function checkPart(p)
        if not p:IsA("BasePart") then return end
        if M.isMzDPart(p) then return end
        if p.Size.X > 15 and p.Size.Z > 5 and p.Size.Y < 20
            and p.Position.Y > -10 and p.Position.Y < 30 then
            table.insert(floors, p)
        end
    end
    if map then
        for _, c in pairs(map:GetChildren()) do
            if c:IsA("BasePart") and not M.isMzDPart(c) then
                local n = c.Name:lower()
                if n == "firstfloor" or n == "ground" or n == "floor"
                    or n == "grass" or n == "path" or n == "road"
                    or n == "platform" or n == "bridgefloor" then
                    table.insert(floors, c)
                else
                    checkPart(c)
                end
            end
        end
        local sp = map:FindFirstChild("Spawners")
        if sp then
            for _, s in pairs(sp:GetChildren()) do checkPart(s) end
        end
    end
    for _, c in pairs(workspace:GetChildren()) do
        if c.Name:find("SharedInstances") then
            local fl = c:FindFirstChild("Floors")
            if fl then
                for _, f in pairs(fl:GetChildren()) do checkPart(f) end
            end
            for _, f in pairs(c:GetChildren()) do checkPart(f) end
        end
    end
    return floors, map
end

local function godDetectMapXRange(map)
    local minX, maxX = math.huge, -math.huge
    local found = false
    local function chk(p)
        if not p:IsA("BasePart") then return end
        if M.isMzDPart(p) then return end
        if p.Size.Y > p.Size.X and p.Size.Y > p.Size.Z then return end
        if p.Position.Y > 50 or p.Position.Y < -30 then return end
        if p.Size.X < 5 then return end
        local l = p.Position.X - p.Size.X / 2
        local r = p.Position.X + p.Size.X / 2
        if l < minX then minX = l end
        if r > maxX then maxX = r end
        found = true
    end
    if map then
        for _, c in pairs(map:GetChildren()) do
            if c:IsA("BasePart") then chk(c) end
        end
        local sp = map:FindFirstChild("Spawners")
        if sp then
            for _, s in pairs(sp:GetChildren()) do chk(s) end
        end
    end
    for _, c in pairs(workspace:GetChildren()) do
        if c.Name:find("SharedInstances") then
            for _, f in pairs(c:GetChildren()) do
                if f:IsA("BasePart") then chk(f) end
            end
            local fl = c:FindFirstChild("Floors")
            if fl then
                for _, f in pairs(fl:GetChildren()) do chk(f) end
            end
        end
    end
    if found and maxX > minX then return minX - 20, maxX + 20 end
    return -50, 4500
end

local function godFindAllKillParts()
    local kills, seen = {}, {}
    for _, c in pairs(workspace:GetDescendants()) do
        if c:IsA("BasePart") and not seen[c] and not M.isMzDPart(c) then
            local ok, isKillStrip = pcall(function()
                return c.Size.Y < 1 and c.Size.Z > 50
                    and c.Position.Y < 5 and c.Position.Y > -5
                    and c.Size.X < 5
            end)
            if ok and isKillStrip and not seen[c] then
                seen[c] = true
                table.insert(kills, c)
            end
            if not seen[c] then
                local n = c.Name:lower()
                if n:find("kill") or n:find("tsunamikill")
                    or n:find("deathzone") or n:find("damagezone")
                    or n:find("killbrick") or n:find("killpart") then
                    seen[c] = true
                    table.insert(kills, c)
                end
            end
        end
    end
    return kills
end

local function godDisableKillParts()
    M._godKillParts = {}
    local kills = godFindAllKillParts()
    for _, p in pairs(kills) do
        table.insert(M._godKillParts, {
            part = p,
            canCollide = p.CanCollide,
            canTouch = p.CanTouch,
            size = p.Size,
            position = p.Position,
            transparency = p.Transparency,
        })
        pcall(function()
            p.CanCollide = false
            p.CanTouch = false
            p.Transparency = 1
            p.Size = Vector3.new(0, 0, 0)
            p.Position = Vector3.new(0, -9999, 0)
        end)
    end
    return #kills
end

local function godRestoreKillParts()
    for _, data in pairs(M._godKillParts) do
        pcall(function()
            if data.part and data.part.Parent then
                data.part.Size = data.size
                data.part.Position = data.position
                data.part.CanCollide = data.canCollide
                data.part.CanTouch = data.canTouch
                data.part.Transparency = data.transparency
            end
        end)
    end
    M._godKillParts = {}
end

local function godStartKillWatcher()
    if M._godKillWatchThread then
        pcall(task.cancel, M._godKillWatchThread)
    end
    M._godKillWatchThread = task.spawn(function()
        while M._isGod do
            pcall(function()
                for _, data in pairs(M._godKillParts) do
                    if data.part and data.part.Parent then
                        data.part.CanCollide = false
                        data.part.CanTouch = false
                        data.part.Size = Vector3.new(0, 0, 0)
                        data.part.Position = Vector3.new(0, -9999, 0)
                    end
                end
            end)
            pcall(function()
                for _, c in pairs(workspace:GetDescendants()) do
                    if c:IsA("BasePart") and not M.isMzDPart(c) then
                        local isKill = false
                        pcall(function()
                            if c.Size.Y < 1 and c.Size.Z > 50
                                and c.Position.Y < 5 and c.Position.Y > -5
                                and c.Size.X < 5 then
                                isKill = true
                            end
                        end)
                        if not isKill then
                            local n = c.Name:lower()
                            if n:find("kill") or n:find("deathzone")
                                or n:find("damagezone") then
                                isKill = true
                            end
                        end
                        if isKill then
                            local already = false
                            for _, data in pairs(M._godKillParts) do
                                if data.part == c then
                                    already = true
                                    break
                                end
                            end
                            if not already then
                                table.insert(M._godKillParts, {
                                    part = c,
                                    canCollide = c.CanCollide,
                                    canTouch = c.CanTouch,
                                    size = c.Size,
                                    position = c.Position,
                                    transparency = c.Transparency,
                                })
                                pcall(function()
                                    c.CanCollide = false
                                    c.CanTouch = false
                                    c.Transparency = 1
                                    c.Size = Vector3.new(0, 0, 0)
                                    c.Position = Vector3.new(0, -9999, 0)
                                end)
                            end
                        end
                    end
                end
            end)
            task.wait(3)
        end
    end)
end

local function godBuildEgaleVloer(map)
    for _, p in pairs(M._godCreatedParts) do
        pcall(function()
            if p and p.Parent then p:Destroy() end
        end)
    end
    M._godCreatedParts = {}

    local startX, endX = godDetectMapXRange(map)
    local floorY = M.S.GodFloorY
    local floorWidth = 420
    local floorThickness = 4

    local theme = M.getThemeColors()
    local floorColor = theme.floor
    local stripeColor = theme.stripe

    local maxSeg = 2000
    local curX = startX
    while curX < endX do
        local segLen = math.min(maxSeg, endX - curX)
        local centerX = curX + segLen / 2

        local floor = Instance.new("Part")
        floor.Name = "MzDGodFloor"
        floor.Size = Vector3.new(segLen, floorThickness, floorWidth)
        floor.Position = Vector3.new(centerX, floorY, 0)
        floor.Anchored = true
        floor.CanCollide = true
        floor.Color = floorColor
        floor.Material = Enum.Material.SmoothPlastic
        floor.Transparency = 0
        floor.TopSurface = Enum.SurfaceType.Smooth
        floor.BottomSurface = Enum.SurfaceType.Smooth
        floor.Parent = workspace
        table.insert(M._godCreatedParts, floor)

        local topY = floorY + floorThickness / 2 + 0.1
        for _, zPos in pairs({floorWidth / 2 - 5, -floorWidth / 2 + 5}) do
            local s = Instance.new("Part")
            s.Name = "MzDGodFloorStripe"
            s.Size = Vector3.new(segLen, 0.2, 2)
            s.Position = Vector3.new(centerX, topY, zPos)
            s.Anchored = true
            s.CanCollide = false
            s.Color = stripeColor
            s.Material = Enum.Material.Neon
            s.Parent = workspace
            table.insert(M._godCreatedParts, s)
        end

        local sm = Instance.new("Part")
        sm.Name = "MzDGodFloorStripe"
        sm.Size = Vector3.new(segLen, 0.2, 1)
        sm.Position = Vector3.new(centerX, topY, 0)
        sm.Anchored = true
        sm.CanCollide = false
        sm.Color = stripeColor
        sm.Material = Enum.Material.Neon
        sm.Parent = workspace
        table.insert(M._godCreatedParts, sm)

        curX = curX + segLen
    end

    local catch = Instance.new("Part")
    catch.Name = "MzDGodCatchFloor"
    catch.Size = Vector3.new(
        math.abs(endX - startX) + 200, 2, floorWidth + 100
    )
    catch.Position = Vector3.new((startX + endX) / 2, floorY - 15, 0)
    catch.Anchored = true
    catch.CanCollide = true
    catch.Transparency = 1
    catch.Parent = workspace
    table.insert(M._godCreatedParts, catch)
    return true
end

local function godHideOriginalFloors()
    local floors, map = godFindFloorParts()
    M._godOriginalFloors = {}
    for _, p in pairs(floors) do
        table.insert(M._godOriginalFloors, {
            part = p, size = p.Size, position = p.Position,
            canCollide = p.CanCollide, transparency = p.Transparency,
            color = p.Color, material = p.Material, anchored = p.Anchored,
        })
        pcall(function()
            p.CanCollide = false
            p.Transparency = 1
        end)
    end
    if map then
        for _, c in pairs(map:GetChildren()) do
            if c:IsA("BasePart") and c.Name == "BridgeFloor"
                and not M.isMzDPart(c) then
                table.insert(M._godOriginalFloors, {
                    part = c, size = c.Size, position = c.Position,
                    canCollide = c.CanCollide, transparency = c.Transparency,
                    color = c.Color, material = c.Material, anchored = c.Anchored,
                })
                pcall(function()
                    c.CanCollide = false
                    c.Transparency = 1
                end)
            end
        end
    end
    return map
end

local function godRestoreFloors()
    for _, data in pairs(M._godOriginalFloors) do
        pcall(function()
            if data.part and data.part.Parent then
                data.part.Size = data.size
                data.part.Position = data.position
                data.part.CanCollide = data.canCollide
                data.part.Transparency = data.transparency
                data.part.Color = data.color
                data.part.Material = data.material
                data.part.Anchored = data.anchored
            end
        end)
    end
    M._godOriginalFloors = {}
    for _, f in pairs(M._godCreatedParts) do
        pcall(function()
            if f and f.Parent then f:Destroy() end
        end)
    end
    M._godCreatedParts = {}
end

local function godTeleportUnder()
    local hrp = M.Player.Character
        and M.Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.CFrame = CFrame.new(hrp.Position.X, M.S.GodWalkY, hrp.Position.Z)
end
-- expose for GUI
M.godTeleportUnder = godTeleportUnder

local function godStartLoop()
    if M._godLoopThread then
        pcall(task.cancel, M._godLoopThread)
    end
    M._godLoopThread = task.spawn(function()
        while M._isGod do
            pcall(function()
                local ch = M.Player.Character
                if not ch then return end
                local hrp = ch:FindFirstChild("HumanoidRootPart")
                if tick() - M._godFloorCacheTime > 5 then
                    for _, data in pairs(M._godOriginalFloors) do
                        if data.part and data.part.Parent then
                            data.part.CanCollide = false
                            data.part.Transparency = 1
                        end
                    end
                    M._godFloorCacheTime = tick()
                end
                if hrp then
                    if hrp.Position.Y < M.S.GodWalkY - 30 then
                        hrp.Velocity = Vector3.new(0, 0, 0)
                        hrp.CFrame = CFrame.new(
                            hrp.Position.X, M.S.GodWalkY, hrp.Position.Z
                        )
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end

local function godSetupHealth(char)
    if M._godHealthConn then
        pcall(function() M._godHealthConn:Disconnect() end)
    end
    if M._godDiedConn then
        pcall(function() M._godDiedConn:Disconnect() end)
    end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    pcall(function()
        hum.MaxHealth = math.huge
        hum.Health = math.huge
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end)
    for _, ff in pairs(char:GetChildren()) do
        if ff:IsA("ForceField") then ff:Destroy() end
    end
    local ff = Instance.new("ForceField")
    ff.Visible = false
    ff.Parent = char
    M._godHealthConn = hum:GetPropertyChangedSignal("Health"):Connect(function()
        if not M._isGod then return end
        pcall(function()
            if hum.Health ~= math.huge then hum.Health = math.huge end
        end)
    end)
    M._godDiedConn = hum.Died:Connect(function()
        if not M._isGod then return end
        task.defer(function()
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                hum.MaxHealth = math.huge
                hum.Health = math.huge
            end)
        end)
    end)
end

-- ========== PUBLIC GOD API ==========
function M.enableGod()
    if M._isGod then return end
    M._isGod = true
    M.S.GodEnabled = true
    M._godFloorCacheTime = 0
    local killCount = godDisableKillParts()
    godStartKillWatcher()
    task.wait(0.1)
    local map = godHideOriginalFloors()
    task.wait(0.1)
    godBuildEgaleVloer(map)
    task.wait(0.2)
    godStartLoop()
    task.wait(0.1)
    godTeleportUnder()
    task.wait(0.1)
    if M.Player.Character then godSetupHealth(M.Player.Character) end
    local towerStatus = ""
    if M.S.DoomTowerEnabled then
        local tOk = M.enableTowerDrop()
        towerStatus = tOk and " | Tower ✓" or " | Tower ✗"
    end
    M.Status.god = "Aan 🛡️ (Y=" .. M.S.GodWalkY
        .. " K:" .. killCount
        .. " V:" .. #M._godCreatedParts
        .. towerStatus .. ")"
end

function M.disableGod()
    M._isGod = false
    M.S.GodEnabled = false
    if M._godLoopThread then
        pcall(task.cancel, M._godLoopThread)
        M._godLoopThread = nil
    end
    if M._godKillWatchThread then
        pcall(task.cancel, M._godKillWatchThread)
        M._godKillWatchThread = nil
    end
    if M._godHealthConn then
        pcall(function() M._godHealthConn:Disconnect() end)
        M._godHealthConn = nil
    end
    if M._godDiedConn then
        pcall(function() M._godDiedConn:Disconnect() end)
        M._godDiedConn = nil
    end
    godRestoreFloors()
    godRestoreKillParts()
    local hrp = M.Player.Character
        and M.Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.CFrame = CFrame.new(hrp.Position.X, 10, hrp.Position.Z)
    end
    local ch = M.Player.Character
    if ch then
        for _, ff2 in pairs(ch:GetChildren()) do
            if ff2:IsA("ForceField") then ff2:Destroy() end
        end
        local hum = ch:FindFirstChild("Humanoid")
        if hum then
            pcall(function()
                hum.MaxHealth = 100
                hum.Health = 100
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            end)
        end
    end
    M.Status.god = "Uit"
end

-- ========== RESPAWN HANDLER ==========
M.Player.CharacterAdded:Connect(function(character)
    task.wait(1.5)
    if M.S.InstantPickup then M.setupInstant() end
    task.wait(0.5)
    M.detectWallZ()
    if M._isGod then
        if M._godHealthConn then
            pcall(function() M._godHealthConn:Disconnect() end)
            M._godHealthConn = nil
        end
        if M._godDiedConn then
            pcall(function() M._godDiedConn:Disconnect() end)
            M._godDiedConn = nil
        end
        task.wait(0.5)
        godSetupHealth(character)
        godDisableKillParts()
        pcall(function()
            for _, data in pairs(M._godOriginalFloors) do
                if data.part and data.part.Parent then
                    data.part.CanCollide = false
                    data.part.Transparency = 1
                end
            end
        end)
        task.wait(0.3)
        godTeleportUnder()
        if M.S.DoomTowerEnabled and M._towerDetectedFloorY then
            task.wait(0.5)
            moveTowerToFloor(M._towerDetectedFloorY, M.S.DoomTowerOffset)
        end
    end
end)

print("[MzD Hub] God geladen ✓")