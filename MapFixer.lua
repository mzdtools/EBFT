-- modules/MapFixer.lua
-- Map Fixer met dynamische kleuren
-- ============================================

local M = getgenv().MzD

local MF = {
    W = 420,
    WH = 80,
    WT = 6,
    INT = 8,
}
MF.SZ = MF.W / 2
MF.WY = MF.WH / 2 - 10

local MAP_FOLDERS_REMOVE = {
    "RightWalls","LeftWalls","Gaps","VIPWalls",
    "SideWalls","Barriers","Fences","Walls","Decorations"
}
local EVENT_MAPS = {
    "ValentinesMap","ArcadeMap","CandyMap","HalloweenMap",
    "ChristmasMap","EasterMap","SummerMap","SpringMap",
    "WinterMap","DoomMap"
}

local function safeDestroyFolder(parent, fn)
    if not parent then return end
    local f = parent:FindFirstChild(fn)
    if not f or f.Name == "MzDHubWalls" then return end
    pcall(function()
        for _, d in pairs(f:GetDescendants()) do
            if d:IsA("BasePart") then d:Destroy() end
        end
        f:Destroy()
    end)
end

local function isWallPart(p)
    if not p:IsA("BasePart") then return false end
    if M.isMzDPart(p) then return false end
    local n = p.Name:lower()
    local wallNames = {"vipwall","sidewall","barrier","fence","blocker","border"}
    for _, k in pairs(wallNames) do
        if n == k or n:find("^" .. k) then return true end
    end
    if p.Size.Y > 15 and p.Size.Y > p.Size.X * 3
        and p.Size.Y > p.Size.Z * 3 then
        if math.abs(p.Position.Z) > 60 then return true end
    end
    return false
end

function M.mapFindShared(mn)
    return workspace:FindFirstChild(mn .. "_SharedInstances")
end

function M.mapDetectXRange(map, si)
    local minX, maxX = math.huge, -math.huge
    local found = false
    local function chk(p)
        if not p:IsA("BasePart") or M.isMzDPart(p) then return end
        if p.Size.Y > p.Size.X and p.Size.Y > p.Size.Z then return end
        if p.Position.Y > 50 or p.Position.Y < -30 or p.Size.X < 5 then return end
        local l = p.Position.X - p.Size.X / 2
        local r = p.Position.X + p.Size.X / 2
        if l < minX then minX = l end
        if r > maxX then maxX = r end
        found = true
    end
    for _, c in pairs(map:GetChildren()) do
        if c:IsA("BasePart") then chk(c) end
    end
    local sp = map:FindFirstChild("Spawners")
    if sp then
        for _, s in pairs(sp:GetChildren()) do chk(s) end
    end
    if si then
        for _, c in pairs(si:GetChildren()) do
            if c:IsA("BasePart") then chk(c) end
        end
        local sf = si:FindFirstChild("Floors")
        if sf then
            for _, f in pairs(sf:GetChildren()) do chk(f) end
        end
    end
    if found and maxX > minX then return minX - 5, maxX + 5 end
    return -15, 4385
end

local function getFloorParts(map, si)
    local fl = {}
    local function af(p)
        if not p:IsA("BasePart") or M.isMzDPart(p) then return end
        if p.Size.Y > p.Size.X and p.Size.Y > p.Size.Z then return end
        if p.Position.Y > 30 or p.Position.Y < -20 or p.Size.X < 5 then return end
        for _, f in pairs(fl) do if f == p then return end end
        table.insert(fl, p)
    end
    local ff = map:FindFirstChild("FirstFloor")
    if ff and ff:IsA("BasePart") then af(ff) end
    local gr = map:FindFirstChild("Ground")
    if gr and gr:IsA("BasePart") then af(gr) end
    local sp = map:FindFirstChild("Spawners")
    if sp then
        for _, s in pairs(sp:GetChildren()) do
            if s:IsA("BasePart") then af(s) end
        end
    end
    for _, c in pairs(map:GetChildren()) do
        if c:IsA("BasePart") then
            local n = c.Name:lower()
            if n == "firstfloor" or n == "ground" or n == "bridgefloor"
                or n == "floor" or n == "grass" or n == "path"
                or n == "road" or n == "platform" then
                af(c)
            elseif c.Size.X > 50 and c.Size.Z > 10 and c.Size.Y < 10 then
                af(c)
            end
        end
    end
    if si then
        local sf = si:FindFirstChild("Floors")
        if sf then
            for _, f in pairs(sf:GetChildren()) do
                if f:IsA("BasePart") then af(f) end
            end
        end
        for _, c in pairs(si:GetChildren()) do
            if c:IsA("BasePart") and c.Size.X > 50
                and c.Size.Z > 10 and c.Size.Y < 10 then
                af(c)
            end
        end
    end
    return fl
end

function M.mapCleanup(map)
    for _, n in pairs(MAP_FOLDERS_REMOVE) do
        safeDestroyFolder(map, n)
    end
    for _, d in pairs(map:GetDescendants()) do
        if d.Parent and not M.isMzDPart(d)
            and d:IsA("BasePart") and isWallPart(d) then
            pcall(function() d:Destroy() end)
        end
    end
end

function M.mapCleanupShared(si)
    if not si then return end
    for _, n in pairs(MAP_FOLDERS_REMOVE) do
        safeDestroyFolder(si, n)
    end
    for _, d in pairs(si:GetDescendants()) do
        if d:IsA("BasePart") and not M.isMzDPart(d) and isWallPart(d) then
            pcall(function() d:Destroy() end)
        end
    end
end

function M.mapCleanupMisc()
    local misc = workspace:FindFirstChild("Misc")
    if misc then
        for _, c in pairs(misc:GetChildren()) do
            if c.Name == "BrickAddition" or c.Name == "Roof" then
                pcall(function() c:Destroy() end)
            end
        end
    end
end

function M.cleanupEventMaps()
    for _, mn in pairs(EVENT_MAPS) do
        local em = workspace:FindFirstChild(mn)
        if em then
            for _, fn in pairs(MAP_FOLDERS_REMOVE) do
                safeDestroyFolder(em, fn)
            end
            for _, d in pairs(em:GetDescendants()) do
                if d:IsA("BasePart") and not M.isMzDPart(d) and isWallPart(d) then
                    pcall(function() d:Destroy() end)
                end
            end
        end
    end
end

function M.mapWidenFloors(map, si)
    for _, p in pairs(getFloorParts(map, si)) do
        pcall(function()
            if math.abs(p.Size.Z - MF.W) > 1 then
                p.Size = Vector3.new(p.Size.X, p.Size.Y, MF.W)
                p.Position = Vector3.new(p.Position.X, p.Position.Y, 0)
            end
        end)
    end
end

function M.mapFillGaps(map, sx, ex)
    local ref = nil
    local ff = map:FindFirstChild("FirstFloor")
    if ff and ff:IsA("BasePart") then ref = ff end
    if not ref then
        local g = map:FindFirstChild("Ground")
        if g and g:IsA("BasePart") then ref = g end
    end
    if not ref then
        local sp = map:FindFirstChild("Spawners")
        if sp then
            for _, s in pairs(sp:GetChildren()) do
                if s:IsA("BasePart") then ref = s; break end
            end
        end
    end
    if not ref then
        for _, c in pairs(map:GetChildren()) do
            if c:IsA("BasePart") and not M.isMzDPart(c)
                and c.Size.X > 50 and c.Size.Y < 10
                and c.Position.Y < 20 then
                ref = c; break
            end
        end
    end
    if not ref then return end

    local fY, fH, fC, fM = ref.Position.Y, ref.Size.Y, ref.Color, ref.Material
    for _, c in pairs(map:GetChildren()) do
        if c:IsA("BasePart") and c.Name == "BridgeFloor" then
            pcall(function() c:Destroy() end)
        end
    end

    local maxSeg = 2000
    local curX = sx
    while curX < ex do
        local segLen = math.min(maxSeg, ex - curX)
        local b = Instance.new("Part")
        b.Name = "BridgeFloor"
        b.Size = Vector3.new(segLen, fH, MF.W)
        b.Position = Vector3.new(curX + segLen / 2, fY, 0)
        b.Anchored = true
        b.CanCollide = true
        b.Color = fC
        b.Material = fM
        b.TopSurface = Enum.SurfaceType.Smooth
        b.BottomSurface = Enum.SurfaceType.Smooth
        b.Parent = map
        curX = curX + segLen
    end
end

function M.mapBuildWalls(map, sx, ex)
    local mf = map:FindFirstChild("MzDHubWalls")
    if mf then
        local fw = mf:FindFirstChild("FrontWall_1")
        if fw and math.abs(fw.Size.Y - MF.WH) < 1
            and math.abs(fw.Position.Y - MF.WY) < 1 then
            M._wallZ_front = MF.SZ - 3
            M._wallZ_back = -MF.SZ + 3
            return
        end
        pcall(function() mf:Destroy() end)
    end

    mf = Instance.new("Folder")
    mf.Name = "MzDHubWalls"
    mf.Parent = map

    -- v12.2: Dynamische kleuren
    local theme = M.getThemeColors()
    local wallColor = theme.wall
    local stripeColor = theme.stripe
    local glowColor = theme.glow

    local function mw(nm, sz, ps)
        local w = Instance.new("Part")
        w.Name = nm
        w.Size = sz
        w.Position = ps
        w.Anchored = true
        w.CanCollide = true
        w.Color = wallColor
        w.Material = Enum.Material.SmoothPlastic
        w.TopSurface = Enum.SurfaceType.Smooth
        w.BottomSurface = Enum.SurfaceType.Smooth
        w.Parent = mf
        return w
    end

    local function ms(nm, sz, ps)
        local s = Instance.new("Part")
        s.Name = nm
        s.Size = sz
        s.Position = ps
        s.Anchored = true
        s.CanCollide = false
        s.Color = stripeColor
        s.Material = Enum.Material.Neon
        s.Parent = mf
    end

    local function at(w, f)
        local sg = Instance.new("SurfaceGui")
        sg.Face = f
        sg.CanvasSize = Vector2.new(800, 400)
        sg.Parent = w
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, 0, 0.5, 0)
        t.Position = UDim2.new(0, 0, 0.1, 0)
        t.BackgroundTransparency = 1
        t.Text = "MzD Hub"
        t.TextColor3 = glowColor
        t.TextScaled = true
        t.Font = Enum.Font.GothamBold
        t.Parent = sg
        local s2 = Instance.new("TextLabel")
        s2.Size = UDim2.new(0.6, 0, 0.2, 0)
        s2.Position = UDim2.new(0.2, 0, 0.6, 0)
        s2.BackgroundTransparency = 1
        s2.Text = "v12.2"
        s2.TextColor3 = Color3.fromRGB(200, 200, 200)
        s2.TextScaled = true
        s2.Font = Enum.Font.Gotham
        s2.Parent = sg
    end

    local segs = {}
    local sl = 2000
    local p = sx
    while p < ex do
        local l = math.min(sl, ex - p)
        table.insert(segs, {s = p, l = l})
        p = p + l
    end

    for i, s in pairs(segs) do
        local cx = s.s + s.l / 2

        local fw = mw("FrontWall" .. i,
            Vector3.new(s.l, MF.WH, MF.WT),
            Vector3.new(cx, MF.WY, MF.SZ + MF.WT / 2))
        at(fw, Enum.NormalId.Front)
        at(fw, Enum.NormalId.Back)

        ms("FS_t" .. i, Vector3.new(s.l, 1.5, 0.3),
            Vector3.new(cx, 20, MF.SZ + MF.WT + 0.2))
        ms("FS_b" .. i, Vector3.new(s.l, 1.5, 0.3),
            Vector3.new(cx, 2, MF.SZ + MF.WT + 0.2))
        ms("FS_m" .. i, Vector3.new(s.l, 0.5, 0.3),
            Vector3.new(cx, 10, MF.SZ + MF.WT + 0.2))

        local bw = mw("BackWall" .. i,
            Vector3.new(s.l, MF.WH, MF.WT),
            Vector3.new(cx, MF.WY, -MF.SZ - MF.WT / 2))
        at(bw, Enum.NormalId.Front)
        at(bw, Enum.NormalId.Back)

        ms("BS_t" .. i, Vector3.new(s.l, 1.5, 0.3),
            Vector3.new(cx, 20, -MF.SZ - MF.WT - 0.2))
        ms("BS_b" .. i, Vector3.new(s.l, 1.5, 0.3),
            Vector3.new(cx, 2, -MF.SZ - MF.WT - 0.2))
        ms("BS_m" .. i, Vector3.new(s.l, 0.5, 0.3),
            Vector3.new(cx, 10, -MF.SZ - MF.WT - 0.2))
    end

    mw("LeftWall", Vector3.new(MF.WT, MF.WH, MF.SZ * 2 + MF.WT * 2 + 2),
        Vector3.new(sx - MF.WT / 2, MF.WY, 0))
    mw("RightWall", Vector3.new(MF.WT, MF.WH, MF.SZ * 2 + MF.WT * 2 + 2),
        Vector3.new(ex + MF.WT / 2, MF.WY, 0))

    M._wallZ_front = MF.SZ - 3
    M._wallZ_back = -MF.SZ + 3
end

function M.mapFixCollision(map, si)
    for _, p in pairs(getFloorParts(map, si)) do
        if M._isGod then
            pcall(function() p.CanCollide = false; p.Transparency = 1 end)
        else
            pcall(function() p.CanCollide = true; p.Transparency = 0 end)
        end
    end
    for _, c in pairs(map:GetChildren()) do
        if c:IsA("BasePart") and c.Name == "BridgeFloor" then
            if M._isGod then
                pcall(function() c.CanCollide = false; c.Transparency = 1 end)
            else
                pcall(function() c.CanCollide = true end)
            end
        end
    end
    local wallFolder = map:FindFirstChild("MzDHubWalls")
    if wallFolder then
        for _, w in pairs(wallFolder:GetChildren()) do
            if w:IsA("BasePart") then
                if w.Name:find("FS") or w.Name:find("BS") then
                    w.CanCollide = false
                else
                    w.CanCollide = true
                    w.Anchored = true
                end
            end
        end
    end
end

M._lastFixedMapName = ""

function M.mapRunFix()
    local map = M.mapFindCurrentMap()
    if not map then return end
    local si = M.mapFindShared(map.Name)
    local mapChanged = map.Name ~= M._lastFixedMapName

    if mapChanged then
        M._lastFixedMapName = map.Name
        M.lastMapName = map.Name
    end

    local sx, ex = M.mapDetectXRange(map, si)

    if mapChanged then
        pcall(function() M.mapCleanup(map) end)
        pcall(function() M.mapCleanupShared(si) end)
        pcall(function() M.mapCleanupMisc() end)
        pcall(function() M.cleanupEventMaps() end)
        task.wait(0.1)
        pcall(function() M.mapWidenFloors(map, si) end)
        pcall(function() M.mapFillGaps(map, sx, ex) end)
        pcall(function() M.mapBuildWalls(map, sx, ex) end)
        M.Status.mapFixer = "Gefixed: " .. map.Name
        if M.S.DoomTowerEnabled then
            task.wait(0.5)
            M.enableTowerDrop()
        end
    end

    pcall(function() M.mapFixCollision(map, si) end)
end

function M.startMapFixer()
    if M.mapFixerThread then return end
    M.S.MapFixerEnabled = true
    M._lastFixedMapName = ""
    pcall(function() M.mapRunFix() end)
    M.mapFixerThread = task.spawn(function()
        while M.S.MapFixerEnabled do
            pcall(function() M.mapRunFix() end)
            M.Status.mapFixer = "Actief"
            task.wait(MF.INT)
        end
        M.Status.mapFixer = "Uit"
        M.mapFixerThread = nil
    end)
end

function M.stopMapFixer()
    M.S.MapFixerEnabled = false
    if M.mapFixerThread then
        pcall(task.cancel, M.mapFixerThread)
        M.mapFixerThread = nil
    end
    M.Status.mapFixer = "Uit"
end

-- Expose MF for debug
M._MF = MF

print("[MzD Hub] MapFixer geladen ✓")