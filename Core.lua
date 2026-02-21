-- modules/Core.lua
-- Basis: settings, state, services, helpers
-- ============================================

getgenv().MzD = getgenv().MzD or {}
local M = getgenv().MzD

-- Services (1x gedefinieerd, overal beschikbaar)
M.Players = game:GetService("Players")
M.TweenService = game:GetService("TweenService")
M.RunService = game:GetService("RunService")
M.UserInputService = game:GetService("UserInputService")
M.Player = M.Players.LocalPlayer

-- ========== INIT ==========
M.ActiveBrainrots = workspace:FindFirstChild("ActiveBrainrots")
if not M.ActiveBrainrots then
    task.spawn(function()
        M.ActiveBrainrots = workspace:WaitForChild("ActiveBrainrots", 15)
    end)
end

M.ActiveLuckyBlocks = workspace:FindFirstChild("ActiveLuckyBlocks")
if not M.ActiveLuckyBlocks then
    task.spawn(function()
        M.ActiveLuckyBlocks = workspace:WaitForChild("ActiveLuckyBlocks", 15)
    end)
end

M.PlotAction = nil
pcall(function()
    M.PlotAction = game:GetService("ReplicatedStorage")
        :WaitForChild("Packages", 10)
        :WaitForChild("Net", 10)
        :WaitForChild("RF/Plot.PlotAction", 10)
end)

-- ========== SETTINGS ==========
M.S = {
    Farming = false,
    SelectedBrainrots = {},
    TargetMutation = "None",
    TargetRarity = {"Common"},
    TweenSpeed = 9999,
    CorridorSpeed = 1500,
    AutoCollectMoney = false,
    InstantPickup = true,
    AntiAFK = false,
    AutoUpgrade = false,
    MaxLevel = 250,
    FactoryEnabled = false,
    FactorySlot = "5",
    FactoryRarity = "Common",
    FactoryMutation = "None",
    FactoryMaxLevel = 250,
    FarmMode = "Collect, Place & Max",
    FarmSlot = "5",
    ValentineEnabled = false,
    ArcadeEnabled = false,
    MapFixerEnabled = false,
    LuckyBlockEnabled = false,
    LuckyBlockRarity = {"Common"},
    LuckyBlockMutation = "Any",
    GodEnabled = false,
    GodWalkY = -2,
    GodFloorY = -5,
    DoomEnabled = false,
    DoomTowerEnabled = false,
    DoomTowerOffset = 0,
    -- v12.2: Kleur settings
    WallColor = Color3.fromRGB(0, 0, 0),
    FloorColor = Color3.fromRGB(0, 0, 0),
    StripeColor = Color3.fromRGB(255, 200, 50),
    WallTheme = "Dark",
}

M.Status = {
    farm = "Idle", farmCount = 0,
    money = "Idle",
    afk = "Uit",
    placeCount = 0, upgradeCount = 0,
    upgrade = "Idle",
    factory = "Idle", factoryCount = 0,
    valentine = "Idle", valentineCount = 0,
    arcade = "Idle", arcadeCount = 0,
    mapFixer = "Uit",
    luckyBlock = "Idle", luckyBlockCount = 0,
    god = "Uit",
    doom = "Uit", doomCount = 0,
    doomTower = "Uit",
}

-- ========== STATE ==========
M.baseGUID = nil
M.baseCFrame = nil
M.homePosition = nil
M.farmThread = nil
M.factoryThread = nil
M.moneyThread = nil
M.moneyRemoteThread = nil
M.afkThread = nil
M._afkSteppedConn = nil
M._instantConn = nil
M.upgradeThread = nil
M.valentineThread = nil
M.valentineCollectorConn = nil
M._valentineDescAddedConn = nil
M.arcadeThread = nil
M.mapFixerThread = nil
M.lastMapName = ""
M._valentineCachedParts = {}
M._valentineLastCacheScan = 0
M._valentineStationCF = nil
M.luckyBlockThread = nil
M._isGod = false
M._godLoopThread = nil
M._godHealthConn = nil
M._godDiedConn = nil
M._godOriginalFloors = {}
M._godCreatedParts = {}
M._godKillParts = {}
M._godKillWatchThread = nil
M._godFloorCacheTime = 0
M._towerMoved = false
M._towerOriginalCF = nil
M._towerOriginalY = nil
M._towerWatchThread = nil
M._towerLastTargetY = nil
M._towerDetectedFloorY = nil
M._towerDetectedSource = nil
M._doomConn = nil
M._doomDescConn = nil
M._doomTowerDescConn = nil
M._doomCachedParts = {}
M._doomLastScan = 0
M._doomCollected = 0
M._wallZ_front = 207
M._wallZ_back = -207

-- ========== CONSTANTS ==========
M.HIGH_RARITIES = {
    ["Celestial"] = true,
    ["Divine"] = true,
    ["Infinity"] = true,
}

-- v12.2: Kleur thema's
M.WALL_THEMES = {
    Dark = {
        wall = Color3.fromRGB(20, 20, 30),
        floor = Color3.fromRGB(15, 15, 20),
        stripe = Color3.fromRGB(255, 200, 50),
        glow = Color3.fromRGB(255, 215, 0),
    },
    Doom = {
        wall = Color3.fromRGB(60, 10, 10),
        floor = Color3.fromRGB(40, 5, 5),
        stripe = Color3.fromRGB(255, 60, 0),
        glow = Color3.fromRGB(255, 80, 20),
    },
    Valentine = {
        wall = Color3.fromRGB(80, 20, 40),
        floor = Color3.fromRGB(60, 15, 30),
        stripe = Color3.fromRGB(255, 100, 150),
        glow = Color3.fromRGB(255, 130, 180),
    },
    UFO = {
        wall = Color3.fromRGB(10, 40, 10),
        floor = Color3.fromRGB(5, 30, 5),
        stripe = Color3.fromRGB(0, 255, 80),
        glow = Color3.fromRGB(50, 255, 100),
    },
    Bright = {
        wall = Color3.fromRGB(200, 200, 210),
        floor = Color3.fromRGB(180, 180, 190),
        stripe = Color3.fromRGB(50, 50, 200),
        glow = Color3.fromRGB(80, 80, 255),
    },
    Auto = nil, -- wordt runtime bepaald
}

function M.getThemeColors()
    local theme = M.S.WallTheme or "Dark"

    if theme == "Auto" then
        local mapName = (M.lastMapName or ""):lower()
        if mapName:find("doom") then
            return M.WALL_THEMES.Doom
        elseif mapName:find("valentine") or mapName:find("candy") then
            return M.WALL_THEMES.Valentine
        elseif mapName:find("ufo") or mapName:find("radioactive") then
            return M.WALL_THEMES.UFO
        elseif mapName:find("bright") or mapName:find("white") then
            return M.WALL_THEMES.Bright
        else
            return M.WALL_THEMES.Dark
        end
    end

    return M.WALL_THEMES[theme] or M.WALL_THEMES.Dark
end

-- ========== THROTTLED PLOT ACTION ==========
M._lastPlotCall = 0
M.PLOT_COOLDOWN = 0.15

function M.throttledPlotAction(...)
    local now = tick()
    if now - M._lastPlotCall < M.PLOT_COOLDOWN then
        task.wait(M.PLOT_COOLDOWN - (now - M._lastPlotCall))
    end
    M._lastPlotCall = tick()
    if not M.PlotAction then return false end
    return pcall(function() M.PlotAction:InvokeServer(...) end)
end

-- ========== HELPER: Is MzD eigen part? ==========
function M.isMzDPart(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    local n = obj.Name
    if n == "MzDGodFloor" or n == "MzDGodCatchFloor" or n == "MzDGodFloorStripe" then
        return true
    end
    local p = obj.Parent
    while p do
        if p.Name == "MzDHubWalls" or p.Name == "MzDGodPreview" then return true end
        p = p.Parent
    end
    return false
end

-- ========== BASIC HELPERS ==========
function M.isHighRarity(r)
    return M.HIGH_RARITIES[r] == true
end

function M.isHighRarityTool(tool)
    if not tool then return false end
    return M.HIGH_RARITIES[tool:GetAttribute("Rarity") or ""] == true
end

function M.isDead()
    local ch = M.Player.Character
    if not ch then return true end
    local hum = ch:FindFirstChild("Humanoid")
    if not hum then return true end
    return hum.Health <= 0
end

function M.waitForRespawn()
    if not M.isDead() then return true end
    local timeout = tick() + 15
    while M.isDead() and tick() < timeout do task.wait(0.2) end
    task.wait(1)
    return not M.isDead()
end

-- ========== EQUIP ==========
function M.safeEquip(tool)
    if not tool then return end
    local ch = M.Player.Character
    if not ch then return end
    local hum = ch:FindFirstChild("Humanoid")
    if not hum then return end
    pcall(function() hum:EquipTool(tool) end)
    task.wait(0.4)
end

function M.safeUnequip()
    local ch = M.Player.Character
    if not ch then return end
    local hum = ch:FindFirstChild("Humanoid")
    if not hum then return end
    pcall(function() hum:UnequipTools() end)
    task.wait(0.2)
end

-- ========== FORCE GRAB ==========
function M.forceGrabPrompt(target)
    if not target then return end
    local prompts = {}
    if target:IsA("ProximityPrompt") then
        table.insert(prompts, target)
    else
        for _, d in pairs(target:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                table.insert(prompts, d)
            end
        end
    end
    for _, p in pairs(prompts) do
        pcall(function()
            p.MaxActivationDistance = 99999
            p.HoldDuration = 0
            p.RequiresLineOfSight = false
        end)
        pcall(function() fireproximityprompt(p) end)
        task.wait(0.02)
        pcall(function() fireproximityprompt(p) end)
    end
    local hrp = M.Player.Character
        and M.Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local parent = target
        if parent:IsA("ProximityPrompt") then parent = parent.Parent end
        if parent and parent:IsA("BasePart") then
            pcall(function() firetouchinterest(hrp, parent, 0) end)
            pcall(function() firetouchinterest(hrp, parent, 1) end)
        end
    end
    task.wait(0.02)
end

-- ========== RARITY HELPERS ==========
function M.getTargetRarities()
    return type(M.S.TargetRarity) == "table" and M.S.TargetRarity or {M.S.TargetRarity}
end

function M.rarityMatches(fn)
    for _, r in pairs(M.getTargetRarities()) do
        if r == "Any" or r == fn then return true end
    end
    return false
end

function M.getBrainrotNames(rarity)
    local names, seen = {}, {}
    if not M.ActiveBrainrots then
        M.ActiveBrainrots = workspace:FindFirstChild("ActiveBrainrots")
    end
    if not M.ActiveBrainrots then return names end
    for _, f in pairs(M.ActiveBrainrots:GetChildren()) do
        if f:IsA("Folder") and (rarity == "Any" or f.Name == rarity) then
            for _, b in pairs(f:GetChildren()) do
                local n = nil
                if b:FindFirstChild("RenderedBrainrot") then
                    n = b.RenderedBrainrot:GetAttribute("BrainrotName")
                elseif b.Name == "RenderedBrainrot" then
                    n = b:GetAttribute("BrainrotName")
                else
                    n = b:GetAttribute("BrainrotName") or b.Name
                end
                if n and n ~= "" and not seen[n] then
                    seen[n] = true
                    table.insert(names, n)
                end
            end
        end
    end
    table.sort(names)
    return names
end

function M.getBrainrotNamesMulti(rarities)
    if type(rarities) ~= "table" then return M.getBrainrotNames(rarities) end
    local names, seen = {}, {}
    for _, r in pairs(rarities) do
        if r == "Any" then return M.getBrainrotNames("Any") end
    end
    for _, r in pairs(rarities) do
        for _, n in pairs(M.getBrainrotNames(r)) do
            if not seen[n] then
                seen[n] = true
                table.insert(names, n)
            end
        end
    end
    table.sort(names)
    return names
end

function M.matchesFilter(b, folderRarity)
    if not M.rarityMatches(folderRarity) then return false end
    if M.isHighRarity(folderRarity) then return true end
    local mut = b:GetAttribute("Mutation") or "None"
    local isNone = (mut:lower() == "none" or mut == "")
    if M.S.TargetMutation == "None" then
        if not isNone then return false end
    elseif M.S.TargetMutation ~= "Any" then
        if mut ~= M.S.TargetMutation then return false end
    end
    if #M.S.SelectedBrainrots > 0 then
        local bName = b:GetAttribute("BrainrotName") or ""
        local found = false
        for _, sel in pairs(M.S.SelectedBrainrots) do
            if sel == bName then found = true break end
        end
        if not found then return false end
    end
    return true
end

function M.toolMatchesRarity(tool, targetRarity, targetMutation)
    local tMut = tool:GetAttribute("Mutation") or "None"
    local lvl = tonumber(tool:GetAttribute("Level")) or 0
    local bName = tool:GetAttribute("BrainrotName")
    local toolRarity = tool:GetAttribute("Rarity")
    if not bName or bName == "" then return false end
    if lvl >= M.S.MaxLevel then return false end
    if toolRarity and M.isHighRarity(toolRarity) then
        local tR = type(targetRarity) == "table" and targetRarity or {targetRarity}
        for _, r in pairs(tR) do
            if r == "Any" or r == toolRarity then return true end
        end
        return false
    end
    if targetMutation == "None" then
        if not (tMut:lower() == "none" or tMut == "") then return false end
    elseif targetMutation ~= "Any" then
        if tMut ~= targetMutation then return false end
    end
    local tR = type(targetRarity) == "table" and targetRarity or {targetRarity}
    local isAny = false
    for _, r in pairs(tR) do
        if r == "Any" then isAny = true break end
    end
    if not isAny then
        if toolRarity and toolRarity ~= "" then
            local m2 = false
            for _, r in pairs(tR) do
                if toolRarity == r then m2 = true break end
            end
            if not m2 then return false end
        else
            local wl = {}
            for _, r in pairs(tR) do
                for _, n in pairs(M.getBrainrotNames(r)) do wl[n] = true end
            end
            if not wl[bName] then return false end
        end
    end
    return true
end

-- ========== MUTATIONS / RARITIES DETECTION ==========
function M.getAvailableMutations()
    local muts = {"Any", "None"}
    local seen = {["Any"] = true, ["None"] = true}
    pcall(function()
        local mutFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
        if mutFolder then
            mutFolder = mutFolder:FindFirstChild("Mutations")
            if mutFolder then
                for _, m in pairs(mutFolder:GetChildren()) do
                    if not seen[m.Name] then
                        seen[m.Name] = true
                        table.insert(muts, m.Name)
                    end
                end
            end
        end
    end)
    local defaults = {
        "Emerald","Gold","Blood","Diamond","Rainbow",
        "Shadow","Crystal","Void","Doom"
    }
    for _, m in pairs(defaults) do
        if not seen[m] then
            seen[m] = true
            table.insert(muts, m)
        end
    end
    return muts
end

function M.getAvailableRarities()
    local rars, seen = {}, {}
    local base = {
        "Any","Common","Uncommon","Rare","Epic","Legendary",
        "Mythical","Cosmic","Secret","Celestial","Divine","Infinity"
    }
    for _, r in pairs(base) do
        if not seen[r] then
            seen[r] = true
            table.insert(rars, r)
        end
    end
    pcall(function()
        if M.ActiveBrainrots then
            for _, f in pairs(M.ActiveBrainrots:GetChildren()) do
                if f:IsA("Folder") and not seen[f.Name] then
                    seen[f.Name] = true
                    table.insert(rars, f.Name)
                end
            end
        end
    end)
    return rars
end

-- ========== BASE ==========
function M.findBase()
    local bases = workspace:FindFirstChild("Bases")
    if not bases then return end
    for _, base in pairs(bases:GetChildren()) do
        pcall(function()
            local pn = base.Title.TitleGui.Frame.PlayerName
            if pn.Text == M.Player.Name or pn.Text == M.Player.DisplayName then
                M.baseGUID = base.Name
                local s1 = base:FindFirstChild("slot 1 brainrot")
                if s1 and s1:FindFirstChild("Root") then
                    M.baseCFrame = s1.Root.CFrame
                end
            end
        end)
    end
    if not M.homePosition then M.setHomePosition() end
end

function M.setHomePosition()
    local ch = M.Player.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    M.homePosition = hrp.CFrame
end

function M.getHomePosition()
    if M.homePosition then return M.homePosition end
    if M.baseCFrame then return M.baseCFrame end
    return CFrame.new(124, 3.8, 22)
end

-- ========== SLOTS ==========
function M.isSlotEmpty(s)
    if not M.baseGUID then M.findBase() end
    if not M.baseGUID then return true end
    local mb = workspace:FindFirstChild("Bases")
        and workspace.Bases:FindFirstChild(M.baseGUID)
    if not mb then return true end
    local sm = mb:FindFirstChild("slot " .. s .. " brainrot")
    if not sm then return true end
    local bn = sm:GetAttribute("BrainrotName")
    return not bn or bn == ""
end

function M.findOccupiedSlots()
    if not M.baseGUID then M.findBase() end
    if not M.baseGUID then return {} end
    local mb = workspace:FindFirstChild("Bases")
        and workspace.Bases:FindFirstChild(M.baseGUID)
    if not mb then return {} end
    local o = {}
    for i = 1, 40 do
        local sm = mb:FindFirstChild("slot " .. i .. " brainrot")
        if sm then
            local bn = sm:GetAttribute("BrainrotName")
            local lv = sm:GetAttribute("Level")
            if bn and bn ~= "" then
                table.insert(o, {slot = i, name = bn, level = lv or 1})
            end
        end
    end
    return o
end

-- ========== REMOTES ==========
function M.placeBrainrot(s)
    if not M.baseGUID then return false end
    local ok = M.throttledPlotAction("Place Brainrot", M.baseGUID, tostring(s))
    if ok then M.Status.placeCount += 1 end
    return ok
end

function M.pickUpBrainrot(s)
    if not M.baseGUID then return false end
    return M.throttledPlotAction("Pick Up Brainrot", M.baseGUID, tostring(s))
end

function M.clearSlot(s)
    if not M.baseGUID then return end
    M.throttledPlotAction("Pick Up Brainrot", M.baseGUID, tostring(s))
    task.wait(0.5)
    M.safeUnequip()
    task.wait(0.3)
end

function M.upgradeBrainrot(s)
    if not M.baseGUID then return false end
    return M.throttledPlotAction("Upgrade Brainrot", M.baseGUID, tostring(s))
end

function M.tweenToSlot(sn)
    if not M.baseGUID then M.findBase() end
    if not M.baseGUID then return false end
    local mb = workspace:FindFirstChild("Bases")
        and workspace.Bases:FindFirstChild(M.baseGUID)
    if not mb then return false end
    local sm = mb:FindFirstChild("slot " .. sn .. " brainrot")
    if not sm then return false end
    local root = sm:FindFirstChild("Root")
    if root and root:IsA("BasePart") then
        return M.tweenTo(root.CFrame * CFrame.new(0, 3, 0))
    end
    local ok, pos = pcall(function() return sm:GetPivot() end)
    if ok and pos then
        return M.tweenTo(pos * CFrame.new(0, 3, 0))
    end
    return false
end

function M.upgradeSlotToMax(slot)
    if not M.baseGUID then M.findBase() end
    if not M.baseGUID then return end
    local mb = workspace:FindFirstChild("Bases")
        and workspace.Bases:FindFirstChild(M.baseGUID)
    if not mb then return end
    local sm = mb:FindFirstChild("slot " .. slot .. " brainrot")
    if not sm then return end
    local cur = tonumber(sm:GetAttribute("Level")) or 1
    local fails = 0
    while cur < M.S.MaxLevel and M.S.AutoUpgrade do
        M.upgradeBrainrot(slot)
        task.wait(0.15)
        local nw = tonumber(sm:GetAttribute("Level")) or cur
        if nw > cur then
            fails = 0
            cur = nw
            M.Status.upgradeCount += 1
        else
            fails += 1
            if fails >= 60 then break end
        end
    end
end

function M.findTargetToolInBackpack()
    local bp = M.Player:FindFirstChild("Backpack")
    if bp then
        for _, t in pairs(bp:GetChildren()) do
            if t:IsA("Tool") and M.toolMatchesRarity(t, M.S.TargetRarity, M.S.TargetMutation) then
                return t
            end
        end
    end
    local ch = M.Player.Character
    if ch then
        local eq = ch:FindFirstChildWhichIsA("Tool")
        if eq and M.toolMatchesRarity(eq, M.S.TargetRarity, M.S.TargetMutation) then
            return eq
        end
    end
    return nil
end

function M.findBrainrotRoot(b)
    local root = b:FindFirstChild("Root")
    if root and root:IsA("BasePart") then return root end
    local rendered = b:FindFirstChild("RenderedBrainrot")
    if rendered then
        local rr = rendered:FindFirstChild("Root")
        if rr and rr:IsA("BasePart") then return rr end
    end
    for _, desc in pairs(b:GetDescendants()) do
        if desc:IsA("BasePart") then return desc end
    end
    if b:IsA("BasePart") then return b end
    return nil
end

-- ========== INSTANT PICKUP ==========
function M.setupInstant()
    for _, o in pairs(workspace:GetDescendants()) do
        if o:IsA("ProximityPrompt") then
            pcall(function() o.HoldDuration = 0 end)
        end
    end
    if not M._instantConn then
        M._instantConn = workspace.DescendantAdded:Connect(function(o)
            if o:IsA("ProximityPrompt") then
                pcall(function() o.HoldDuration = 0 end)
            end
        end)
    end
end

-- ========== ANTI AFK ==========
function M.startAFK()
    if M.afkThread then return end
    M.S.AntiAFK = true
    M.Status.afk = "Actief"
    pcall(function()
        for _, c in pairs(getconnections(M.Player.Idled)) do c:Disable() end
    end)
    pcall(function()
        local vu = game:GetService("VirtualUser")
        M._afkSteppedConn = M.RunService.Stepped:Connect(function()
            if M.S.AntiAFK then
                pcall(function()
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end)
            end
        end)
    end)
    M.afkThread = task.spawn(function()
        while M.S.AntiAFK do
            pcall(function()
                for _, c in pairs(getconnections(M.Player.Idled)) do
                    c:Disable()
                end
            end)
            task.wait(300)
        end
        M.Status.afk = "Uit"
    end)
end

function M.stopAFK()
    M.S.AntiAFK = false
    if M.afkThread then
        pcall(task.cancel, M.afkThread)
        M.afkThread = nil
    end
    if M._afkSteppedConn then
        pcall(function() M._afkSteppedConn:Disconnect() end)
        M._afkSteppedConn = nil
    end
    M.Status.afk = "Uit"
end

-- ========== INIT ==========
task.spawn(function()
    task.wait(3)
    M.findBase()
end)

M.setupInstant()
print("[MzD Hub] Core geladen ✓")