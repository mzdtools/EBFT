-- modules/Events.lua
-- Doom, Valentine (v12.2 fixed), Arcade
-- ============================================

local M = getgenv().MzD

-- ============================================
-- DOOM EVENT COLLECTOR
-- ============================================
local function scanDoomParts()
    M._doomCachedParts = {}
    local folder = workspace:FindFirstChild("DoomEventParts")
    if folder then
        for _, obj in pairs(folder:GetDescendants()) do
            if obj:IsA("BasePart") then
                table.insert(M._doomCachedParts, obj)
            end
            if obj:IsA("ProximityPrompt") then
                pcall(function()
                    obj.HoldDuration = 0
                    obj.MaxActivationDistance = 99999
                    obj.RequiresLineOfSight = false
                end)
            end
        end
    end
    local tower = M.findTower()
    if tower then
        for _, obj in pairs(tower:GetDescendants()) do
            if obj:IsA("BasePart") and obj:FindFirstChild("TouchInterest") then
                local found = false
                for _, c in pairs(M._doomCachedParts) do
                    if c == obj then found = true; break end
                end
                if not found then
                    table.insert(M._doomCachedParts, obj)
                end
            end
            if obj:IsA("ProximityPrompt") then
                pcall(function()
                    obj.HoldDuration = 0
                    obj.MaxActivationDistance = 99999
                    obj.RequiresLineOfSight = false
                end)
            end
        end
    end
    M._doomLastScan = tick()
    return #M._doomCachedParts
end

local function fireAllDoomPrompts(parent)
    if not parent then return end
    for _, d in pairs(parent:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            pcall(function()
                d.HoldDuration = 0
                d.MaxActivationDistance = 99999
                d.RequiresLineOfSight = false
            end)
            pcall(function() fireproximityprompt(d) end)
        end
    end
end

local function handleDoomNewDesc(d)
    if not M.S.DoomEnabled then return end
    if d:IsA("BasePart") then
        table.insert(M._doomCachedParts, d)
        pcall(function()
            local hrp = M.Player.Character
                and M.Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                firetouchinterest(hrp, d, 0)
                firetouchinterest(hrp, d, 1)
            end
        end)
    end
    if d:IsA("ProximityPrompt") then
        pcall(function()
            d.HoldDuration = 0
            d.MaxActivationDistance = 99999
            d.RequiresLineOfSight = false
        end)
        pcall(function() fireproximityprompt(d) end)
    end
end

function M.startDoomCollector()
    if M.S.DoomEnabled then return end
    M.S.DoomEnabled = true
    M._doomCollected = 0
    M.Status.doomCount = 0
    local partCount = scanDoomParts()

    local folder = workspace:FindFirstChild("DoomEventParts")
    if not folder then
        task.spawn(function()
            folder = workspace:WaitForChild("DoomEventParts", 30)
            if folder and M.S.DoomEnabled then
                scanDoomParts()
                M._doomDescConn = folder.DescendantAdded:Connect(handleDoomNewDesc)
            end
        end)
    else
        if M._doomDescConn then
            pcall(function() M._doomDescConn:Disconnect() end)
        end
        M._doomDescConn = folder.DescendantAdded:Connect(handleDoomNewDesc)
    end

    local tower = M.findTower()
    if tower then
        if M._doomTowerDescConn then
            pcall(function() M._doomTowerDescConn:Disconnect() end)
        end
        M._doomTowerDescConn = tower.DescendantAdded:Connect(handleDoomNewDesc)
    end

    M._doomConn = M.RunService.Heartbeat:Connect(function()
        if not M.S.DoomEnabled then return end
        pcall(function()
            local hrp = M.Player.Character
                and M.Player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            if tick() - M._doomLastScan > 10 then
                local alive = {}
                for _, p in pairs(M._doomCachedParts) do
                    if p and p.Parent then table.insert(alive, p) end
                end
                M._doomCachedParts = alive

                local folder2 = workspace:FindFirstChild("DoomEventParts")
                if folder2 then
                    for _, obj in pairs(folder2:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            local found = false
                            for _, cached in pairs(M._doomCachedParts) do
                                if cached == obj then found = true; break end
                            end
                            if not found then
                                table.insert(M._doomCachedParts, obj)
                            end
                        end
                    end
                end

                local tw = M.findTower()
                if tw then
                    for _, obj in pairs(tw:GetDescendants()) do
                        if obj:IsA("BasePart")
                            and obj:FindFirstChild("TouchInterest") then
                            local found = false
                            for _, cached in pairs(M._doomCachedParts) do
                                if cached == obj then found = true; break end
                            end
                            if not found then
                                table.insert(M._doomCachedParts, obj)
                            end
                        end
                    end
                end
                M._doomLastScan = tick()
            end

            local collected = 0
            for _, p in pairs(M._doomCachedParts) do
                if p and p.Parent then
                    pcall(function()
                        firetouchinterest(hrp, p, 0)
                        firetouchinterest(hrp, p, 1)
                    end)
                    collected += 1
                end
            end

            local folder3 = workspace:FindFirstChild("DoomEventParts")
            if folder3 then fireAllDoomPrompts(folder3) end
            local tw2 = M.findTower()
            if tw2 then fireAllDoomPrompts(tw2) end
            M._doomCollected = collected
        end)
    end)

    M.Status.doom = "Aan ✓ (" .. partCount .. " parts)"
end

function M.stopDoomCollector()
    M.S.DoomEnabled = false
    if M._doomConn then
        pcall(function() M._doomConn:Disconnect() end)
        M._doomConn = nil
    end
    if M._doomDescConn then
        pcall(function() M._doomDescConn:Disconnect() end)
        M._doomDescConn = nil
    end
    if M._doomTowerDescConn then
        pcall(function() M._doomTowerDescConn:Disconnect() end)
        M._doomTowerDescConn = nil
    end
    M._doomCachedParts = {}
    M._doomCollected = 0
    M.Status.doom = "Uit"
end

-- ============================================
-- VALENTINE v12.2 - FIXED
-- Rent naar brainrots, bij 100 hearts → station
-- ============================================
function M.getHeartCount()
    local count = 0
    pcall(function()
        local ls = M.Player:FindFirstChild("leaderstats")
        if ls then
            for _, v in pairs(ls:GetChildren()) do
                local n = v.Name:lower()
                if n:find("heart") or n:find("candy")
                    or n:find("valentine") or n:find("gram") then
                    count = tonumber(v.Value) or 0
                    return
                end
            end
        end
    end)
    if count == 0 then
        pcall(function()
            local attrs = {
                "Hearts","Candy","CandyGrams",
                "Valentines","Love","CandyHearts"
            }
            for _, a in pairs(attrs) do
                local v = M.Player:GetAttribute(a)
                if v and tonumber(v) and tonumber(v) > 0 then
                    count = tonumber(v)
                    return
                end
            end
        end)
    end
    return count
end

function M.refreshValentineCache()
    M._valentineCachedParts = {}
    M._valentineLastCacheScan = tick()
    local kw = {
        "heart","candy","valentine","love",
        "gram","pickup","collect","token"
    }
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            local m = false
            for _, k in pairs(kw) do
                if n:find(k) then m = true; break end
            end
            if not m and obj:FindFirstChild("TouchInterest") then
                m = true
            end
            if m then
                table.insert(M._valentineCachedParts, obj)
            end
        end
    end
end

function M.findValentineStation()
    local kw = {
        "candygram","station","submit","deposit",
        "exchange","mailbox","postbox","valentine"
    }
    local best = nil
    local bestDist = math.huge

    for _, obj in pairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        local match = false
        for _, k in pairs(kw) do
            if n:find(k) then match = true; break end
        end

        if match then
            local hasPrompt = false
            if obj:IsA("BasePart") or obj:IsA("Model") then
                for _, d in pairs(obj:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        hasPrompt = true; break
                    end
                end
                if not hasPrompt
                    and obj:FindFirstChildWhichIsA("ProximityPrompt") then
                    hasPrompt = true
                end
            end
            if obj:IsA("ProximityPrompt") then hasPrompt = true end

            if hasPrompt then
                local pos = nil
                if obj:IsA("BasePart") then
                    pos = obj.Position
                elseif obj:IsA("Model") then
                    pcall(function() pos = obj:GetPivot().Position end)
                    if not pos then
                        for _, d in pairs(obj:GetDescendants()) do
                            if d:IsA("BasePart") then
                                pos = d.Position; break
                            end
                        end
                    end
                elseif obj:IsA("ProximityPrompt")
                    and obj.Parent and obj.Parent:IsA("BasePart") then
                    pos = obj.Parent.Position
                end

                if pos then
                    local hrp = M.Player.Character
                        and M.Player.Character:FindFirstChild("HumanoidRootPart")
                    local dist = hrp and (hrp.Position - pos).Magnitude or 0
                    if not best or dist < bestDist then
                        best = obj
                        bestDist = dist
                        M._valentineStationCF = CFrame.new(pos)
                    end
                end
            end
        end
    end
    return best
end

function M.submitAtStation()
    local station = M.findValentineStation()
    if not station then return false end

    local targetCF = M._valentineStationCF
    if targetCF then
        M.safePathTo(targetCF * CFrame.new(0, 3, 0))
        task.wait(0.5)
    end

    local fired = false
    local function firePrompts(obj)
        if obj:IsA("ProximityPrompt") then
            pcall(function()
                obj.HoldDuration = 0
                obj.MaxActivationDistance = 99999
                obj.RequiresLineOfSight = false
            end)
            pcall(function() fireproximityprompt(obj) end)
            fired = true
        end
        for _, d in pairs(obj:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                pcall(function()
                    d.HoldDuration = 0
                    d.MaxActivationDistance = 99999
                    d.RequiresLineOfSight = false
                end)
                pcall(function() fireproximityprompt(d) end)
                fired = true
            end
        end
    end

    firePrompts(station)
    if station.Parent then firePrompts(station.Parent) end

    local hrp = M.Player.Character
        and M.Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local function touchAll(obj)
            if obj:IsA("BasePart") then
                pcall(function()
                    firetouchinterest(hrp, obj, 0)
                    firetouchinterest(hrp, obj, 1)
                end)
            end
            for _, d in pairs(obj:GetDescendants()) do
                if d:IsA("BasePart") then
                    pcall(function()
                        firetouchinterest(hrp, d, 0)
                        firetouchinterest(hrp, d, 1)
                    end)
                end
            end
        end
        touchAll(station)
        if station.Parent and not station.Parent:IsA("Workspace") then
            touchAll(station.Parent)
        end
    end

    task.wait(0.5)

    if not fired and hrp then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                if obj.Parent and obj.Parent:IsA("BasePart") then
                    local dist = (obj.Parent.Position - hrp.Position).Magnitude
                    if dist < 20 then
                        pcall(function()
                            obj.HoldDuration = 0
                            obj.MaxActivationDistance = 99999
                            obj.RequiresLineOfSight = false
                        end)
                        pcall(function() fireproximityprompt(obj) end)
                        fired = true
                    end
                end
            end
        end
    end

    return fired
end

-- ========== VALENTINE v12.2 ==========
-- FLOW: Rent naar brainrots (common→secret), collect hearts
--       Bij 100 hearts → station → submit → terug rennen
function M.startValentine()
    if M.valentineThread then return end
    M.S.ValentineEnabled = true
    M.Status.valentineCount = 0
    M._valentineCollecting = true
    M.refreshValentineCache()
    M.setHomePosition()
    M.enableGod()

    -- Watch for new valentine parts
    if M._valentineDescAddedConn then
        pcall(function() M._valentineDescAddedConn:Disconnect() end)
    end
    M._valentineDescAddedConn = workspace.DescendantAdded:Connect(function(d)
        if not M.S.ValentineEnabled then return end
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            local kw = {"heart","candy","valentine","gram"}
            for _, k in pairs(kw) do
                if n:find(k) then
                    table.insert(M._valentineCachedParts, d)
                    pcall(function()
                        local hrp = M.Player.Character
                            and M.Player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            firetouchinterest(hrp, d, 0)
                            firetouchinterest(hrp, d, 1)
                        end
                    end)
                    break
                end
            end
        end
        if d:IsA("ProximityPrompt") then
            pcall(function()
                d.HoldDuration = 0
                d.MaxActivationDistance = 99999
            end)
        end
    end)

    -- Heartbeat collector: touch all cached parts continu
    M.valentineCollectorConn = M.RunService.Heartbeat:Connect(function()
        if not M.S.ValentineEnabled or not M._valentineCollecting then return end
        pcall(function()
            local hrp = M.Player.Character
                and M.Player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if tick() - M._valentineLastCacheScan > 10 then
                local a = {}
                for _, p in pairs(M._valentineCachedParts) do
                    if p and p.Parent then table.insert(a, p) end
                end
                M._valentineCachedParts = a
                M._valentineLastCacheScan = tick()
            end
            for _, p in pairs(M._valentineCachedParts) do
                if p and p.Parent then
                    firetouchinterest(hrp, p, 0)
                    firetouchinterest(hrp, p, 1)
                end
            end
        end)
    end)

    M.valentineThread = task.spawn(function()
        while M.S.ValentineEnabled do
            local ok = pcall(function()
                if M.isDead() then
                    M.waitForRespawn()
                    task.wait(1)
                    M.setHomePosition()
                    M.enableGod()
                    return
                end

                local h = M.getHeartCount()
                M.Status.valentine = "♥:" .. h
                    .. " P:" .. #M._valentineCachedParts
                    .. " #" .. M.Status.valentineCount

                if h >= 100 then
                    -- SUBMIT MODE: naar station
                    M._valentineCollecting = false
                    task.wait(0.3)

                    local prevH = h
                    for attempt = 1, 5 do
                        if not M.S.ValentineEnabled then break end
                        local submitted = M.submitAtStation()
                        task.wait(1)
                        local newH = M.getHeartCount()
                        if newH < prevH or newH == 0 then
                            M.Status.valentineCount += 1
                            break
                        end
                        task.wait(1)
                    end

                    M.refreshValentineCache()
                    M._valentineCollecting = true
                else
                    -- COLLECT MODE: ren naar brainrots op de map
                    if not M.ActiveBrainrots then
                        M.ActiveBrainrots = workspace:FindFirstChild("ActiveBrainrots")
                    end
                    if M.ActiveBrainrots then
                        local found = false
                        -- Loop door rarities van laag naar hoog
                        local rarityOrder = {
                            "Common","Uncommon","Rare","Epic",
                            "Legendary","Mythical","Cosmic","Secret"
                        }
                        for _, rarity in pairs(rarityOrder) do
                            if not M.S.ValentineEnabled or M.isDead() then break end
                            local folder = M.ActiveBrainrots:FindFirstChild(rarity)
                            if folder and folder:IsA("Folder") then
                                for _, b in pairs(folder:GetChildren()) do
                                    if not M.S.ValentineEnabled or M.isDead() then break end
                                    local root = M.findBrainrotRoot(b)
                                    if root and root.Parent then
                                        found = true
                                        M.Status.valentine = "→ " .. rarity
                                            .. " ♥:" .. h
                                        M.safePathTo(root.CFrame * CFrame.new(0, 3, 0))
                                        M.forceGrabPrompt(root)
                                        M.forceGrabPrompt(b)
                                        task.wait(0.3)
                                        M.safeUnequip()

                                        -- Check na elke pickup of we 100 hebben
                                        local newH = M.getHeartCount()
                                        if newH >= 100 then break end
                                        break -- volgende iteratie
                                    end
                                end
                            end
                            if found then break end
                        end
                        if not found then
                            M.Status.valentine = "Wacht... ♥:" .. h
                            task.wait(2)
                        end
                    else
                        task.wait(3)
                    end
                end
            end)
            task.wait(0.3)
        end
        M.disableGod()
        M.Status.valentine = "Idle"
        M.valentineThread = nil
    end)
end

function M.stopValentine()
    M.S.ValentineEnabled = false
    M._valentineCollecting = false
    if M.valentineThread then
        pcall(task.cancel, M.valentineThread)
        M.valentineThread = nil
    end
    if M.valentineCollectorConn then
        pcall(function() M.valentineCollectorConn:Disconnect() end)
        M.valentineCollectorConn = nil
    end
    if M._valentineDescAddedConn then
        pcall(function() M._valentineDescAddedConn:Disconnect() end)
        M._valentineDescAddedConn = nil
    end
    M._valentineCachedParts = {}
    M.disableGod()
    M.Status.valentine = "Idle"
end

-- ============================================
-- ARCADE
-- ============================================
function M.startArcade()
    if M.arcadeThread then return end
    M.S.ArcadeEnabled = true
    M.Status.arcadeCount = 0
    M.arcadeThread = task.spawn(function()
        while M.S.ArcadeEnabled do
            pcall(function()
                local hrp = M.Player.Character
                    and M.Player.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                for _, fn in pairs({"ArcadeEventConsoles","ArcadeEventTickets"}) do
                    local f = workspace:FindFirstChild(fn)
                    if f then
                        for _, item in pairs(f:GetChildren()) do
                            for _, d in pairs(item:GetDescendants()) do
                                if d:IsA("BasePart")
                                    and d:FindFirstChild("TouchInterest") then
                                    pcall(function()
                                        firetouchinterest(hrp, d, 0)
                                        task.wait(0.01)
                                        firetouchinterest(hrp, d, 1)
                                    end)
                                    M.Status.arcadeCount += 1
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.05)
        end
        M.Status.arcade = "Idle"
        M.arcadeThread = nil
    end)
end

function M.stopArcade()
    M.S.ArcadeEnabled = false
    if M.arcadeThread then
        pcall(task.cancel, M.arcadeThread)
        M.arcadeThread = nil
    end
    M.Status.arcade = "Idle"
end

-- ========== MONEY (THROTTLED) ==========
function M.startMoney()
    if M.moneyThread then return end
    M.S.AutoCollectMoney = true
    M.Status.money = "Actief"
    if not M.baseGUID then M.findBase() end

    M.moneyThread = task.spawn(function()
        while M.S.AutoCollectMoney do
            pcall(function()
                if not M.baseGUID then M.findBase() end
                if not M.baseGUID then return end
                local mb = workspace:FindFirstChild("Bases")
                    and workspace.Bases:FindFirstChild(M.baseGUID)
                local hrp = M.Player.Character
                    and M.Player.Character:FindFirstChild("HumanoidRootPart")
                if not mb or not hrp then return end
                for i = 1, 40 do
                    local sm = mb:FindFirstChild("slot " .. i .. " brainrot")
                    if sm and sm:GetAttribute("BrainrotName")
                        and sm:GetAttribute("BrainrotName") ~= "" then
                        for _, d in pairs(sm:GetDescendants()) do
                            if d:IsA("BasePart") then
                                pcall(function()
                                    firetouchinterest(hrp, d, 0)
                                    firetouchinterest(hrp, d, 1)
                                end)
                            end
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
        M.Status.money = "Idle"
    end)

    M.moneyRemoteThread = task.spawn(function()
        while M.S.AutoCollectMoney do
            pcall(function()
                if M.baseGUID and M.PlotAction then
                    for i = 1, 40 do
                        if not M.S.AutoCollectMoney then break end
                        M.throttledPlotAction(
                            "Collect Money", M.baseGUID, tostring(i)
                        )
                    end
                end
            end)
            task.wait(5)
        end
    end)
end

function M.stopMoney()
    M.S.AutoCollectMoney = false
    if M.moneyThread then
        pcall(task.cancel, M.moneyThread)
        M.moneyThread = nil
    end
    if M.moneyRemoteThread then
        pcall(task.cancel, M.moneyRemoteThread)
        M.moneyRemoteThread = nil
    end
    M.Status.money = "Idle"
end

-- ========== AUTO UPGRADE ==========
function M.startAutoUpgrade()
    if M.upgradeThread then return end
    M.S.AutoUpgrade = true
    M.Status.upgradeCount = 0
    M.upgradeThread = task.spawn(function()
        while M.S.AutoUpgrade do
            pcall(function()
                for _, info in pairs(M.findOccupiedSlots()) do
                    if not M.S.AutoUpgrade then break end
                    if info.level < M.S.MaxLevel then
                        M.upgradeSlotToMax(info.slot)
                    end
                end
                M.Status.upgrade = "Klaar (#" .. M.Status.upgradeCount .. ")"
            end)
            task.wait(5)
        end
        M.Status.upgrade = "Idle"
    end)
end

function M.stopAutoUpgrade()
    M.S.AutoUpgrade = false
    if M.upgradeThread then
        pcall(task.cancel, M.upgradeThread)
        M.upgradeThread = nil
    end
    M.Status.upgrade = "Idle"
end

print("[MzD Hub] Events geladen ✓")