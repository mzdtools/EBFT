-- modules/GUI.lua
-- Fluent GUI interface
-- ============================================

local M = getgenv().MzD

-- Clean old GUI
pcall(function()
    for _, gui in pairs(M.Player.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            for _, d in pairs(gui:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text == "MzD Hub" then
                    gui:Destroy()
                    break
                end
            end
        end
    end
end)
task.wait(0.3)

local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
))()
local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
))()

-- Dropdown values
local RAR = M.getAvailableRarities()
local MUT = M.getAvailableMutations()
local FM = {"Collect", "Collect, Place & Max"}
local FR = RAR
local LBR = {
    "Any","Common","Uncommon","Rare","Epic","Legendary",
    "Mythical","Cosmic","Secret","Celestial","Divine",
    "Infinity","Admin","UFO","Candy","Money"
}
local SL = {}
for i = 1, 40 do table.insert(SL, tostring(i)) end
local SPD = {"200","400","600","800","1000","1500","2000","3000","4000","INSTANT"}
local SPM = {
    ["200"]=200,["400"]=400,["600"]=600,["800"]=800,
    ["1000"]=1000,["1500"]=1500,["2000"]=2000,
    ["3000"]=3000,["4000"]=4000,["INSTANT"]=9999
}
local CSPD = {"100","200","300","400","500","600","800","1000","1500","2000"}
local GODWALKY = {"0","-1","-2","-3","-5","-8","-10","-15"}
local GODFLOORY = {"-3","-5","-8","-10","-15","-20"}
local TOWEROFFSET = {"-5","-3","-2","-1","0","1","2","3","5"}
local THEMES = {"Auto","Dark","Doom","Valentine","UFO","Bright"}

local W = Fluent:CreateWindow({
    Title = "MzD Hub",
    SubTitle = "v12.2 Modules",
    TabWidth = 160,
    Size = UDim2.fromOffset(620, 520),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})

-- ========== FARM TAB ==========
local FT = W:AddTab({Title = "Farm", Icon = "swords"})
FT:AddParagraph({Title = "🌾 Filters", Content = "Dynamisch gedetecteerd"})

local BDD = nil
local RDD = FT:AddDropdown("FarmRarity", {
    Title = "Rarity", Values = RAR, Default = {"Common"}, Multi = true
})
RDD:OnChanged(function(v)
    local s = {}
    for n, on in pairs(v) do if on then table.insert(s, n) end end
    if #s == 0 then s = {"Common"} end
    local any = false
    for _, r in pairs(s) do if r == "Any" then any = true; break end end
    M.S.TargetRarity = any and "Any" or s
    M.S.SelectedBrainrots = {}
    pcall(function()
        BDD:SetValues(M.getBrainrotNamesMulti(M.S.TargetRarity))
        BDD:SetValue({})
    end)
end)

BDD = FT:AddDropdown("FarmBrainrots", {
    Title = "Brainrots", Description = "Leeg=alle",
    Values = M.getBrainrotNamesMulti(M.S.TargetRarity),
    Default = {}, Multi = true
})
BDD:OnChanged(function(v)
    local s = {}
    for n, on in pairs(v) do if on then table.insert(s, n) end end
    M.S.SelectedBrainrots = s
end)

FT:AddDropdown("FarmMutation", {
    Title = "Mutatie", Values = MUT, Default = "None", Multi = false
}):OnChanged(function(v) M.S.TargetMutation = v end)

FT:AddDropdown("FarmMode", {
    Title = "Mode", Values = FM, Default = M.S.FarmMode, Multi = false
}):OnChanged(function(v) M.S.FarmMode = v end)

FT:AddDropdown("FarmSlot", {
    Title = "Slot", Values = SL, Default = M.S.FarmSlot, Multi = false
}):OnChanged(function(v) M.S.FarmSlot = v end)

FT:AddSlider("FarmMaxLevel", {
    Title = "Max Level", Default = M.S.MaxLevel, Min = 1, Max = 500, Rounding = 0
}):OnChanged(function(v) M.S.MaxLevel = math.floor(v) end)

local FSP = FT:AddParagraph({Title = "Status", Content = "Idle"})
local FPP = FT:AddParagraph({Title = "Stats", Content = "P:0|U:0"})

local FTG = FT:AddToggle("FarmToggle", {Title = "🚀 Auto Farm", Default = false})
FTG:OnChanged(function(v)
    if v then M.findBase(); M.startFarming()
    else M.stopFarming() end
end)

-- Lucky Blocks
FT:AddParagraph({Title = "🎲 Lucky Blocks", Content = ""})
FT:AddDropdown("LBRarity", {
    Title = "Rarity", Values = LBR, Default = {"Common"}, Multi = true
}):OnChanged(function(v)
    local s = {}
    for n, on in pairs(v) do if on then table.insert(s, n) end end
    if #s == 0 then s = {"Common"} end
    M.S.LuckyBlockRarity = s
end)

FT:AddDropdown("LBMutation", {
    Title = "Mutatie", Values = MUT, Default = "Any", Multi = false
}):OnChanged(function(v) M.S.LuckyBlockMutation = v end)

local LBSP = FT:AddParagraph({Title = "LB Status", Content = "Idle"})
local LBTG = FT:AddToggle("LBToggle", {Title = "🎲 Auto LB", Default = false})
LBTG:OnChanged(function(v)
    if v then M.findBase(); M.startLuckyBlockFarm()
    else M.stopLuckyBlockFarm() end
end)

-- ========== FACTORY TAB ==========
local FCT = W:AddTab({Title = "Factory", Icon = "hammer"})
FCT:AddDropdown("FactoryRarity", {
    Title = "Rarity", Values = FR, Default = M.S.FactoryRarity, Multi = false
}):OnChanged(function(v) M.S.FactoryRarity = v end)

FCT:AddDropdown("FactoryMutation", {
    Title = "Mutatie", Values = MUT, Default = M.S.FactoryMutation, Multi = false
}):OnChanged(function(v) M.S.FactoryMutation = v end)

FCT:AddDropdown("FactorySlot", {
    Title = "Slot", Values = SL, Default = M.S.FactorySlot, Multi = false
}):OnChanged(function(v) M.S.FactorySlot = v end)

FCT:AddSlider("FactoryMaxLevel", {
    Title = "Max Level", Default = M.S.FactoryMaxLevel,
    Min = 1, Max = 500, Rounding = 0
}):OnChanged(function(v) M.S.FactoryMaxLevel = math.floor(v) end)

local FCSP = FCT:AddParagraph({Title = "Status", Content = "Idle"})
local FCTG = FCT:AddToggle("FactoryToggle", {Title = "🔁 Factory", Default = false})
FCTG:OnChanged(function(v)
    if v then M.findBase(); M.startFactoryLoop()
    else M.stopFactoryLoop() end
end)

-- ========== EVENTS TAB ==========
local ET = W:AddTab({Title = "Events", Icon = "party-popper"})

-- Doom
ET:AddParagraph({Title = "🔥 Doom Event", Content = "Coins + Tower"})
local DMSP = ET:AddParagraph({Title = "🪙 Doom Coins", Content = "Uit"})
local DMTG = ET:AddToggle("DoomToggle", {Title = "🪙 Doom Coins", Default = false})
DMTG:OnChanged(function(v)
    if v then M.startDoomCollector() else M.stopDoomCollector() end
end)

ET:AddParagraph({Title = "🗼 Doom Tower", Content = "Auto floor detect"})
ET:AddDropdown("TowerOffset", {
    Title = "Tower Offset", Description = "0=exact op vloer",
    Values = TOWEROFFSET, Default = "0", Multi = false
}):OnChanged(function(v)
    M.S.DoomTowerOffset = tonumber(v) or 0
    if M.S.DoomTowerEnabled and M._towerDetectedFloorY then
        -- re-apply
        M.enableTowerDrop()
    end
end)

local DTSP = ET:AddParagraph({Title = "Tower Status", Content = "Uit"})
local DTTG = ET:AddToggle("DoomTowerToggle", {
    Title = "🗼 Tower → Vloer", Default = false
})
DTTG:OnChanged(function(v)
    if v then M.enableTowerDrop() else M.disableTowerDrop() end
end)

ET:AddButton({Title = "🔍 Detect Info", Callback = function()
    local y, source = M.detectFloorY()
    local tY = M.getTowerY()
    local bY = M.getTowerBottomY()
    local info = "Vloer: Y=" .. string.format("%.1f", y) .. " (" .. source .. ")"
    if tY then info = info .. "\nTower: Y=" .. string.format("%.1f", tY) end
    if bY then info = info .. "\nBottom: Y=" .. string.format("%.1f", bY) end
    Fluent:Notify({Title = "Detection", Content = info, Duration = 8})
end})

ET:AddButton({Title = "⚡ Doom Alles Aan", Callback = function()
    if not M.S.DoomTowerEnabled then
        M.enableTowerDrop()
        pcall(function() DTTG:SetValue(true) end)
    end
    if not M.S.DoomEnabled then
        M.startDoomCollector()
        pcall(function() DMTG:SetValue(true) end)
    end
end})

ET:AddButton({Title = "⏹ Doom Alles Uit", Callback = function()
    if M.S.DoomEnabled then
        M.stopDoomCollector()
        pcall(function() DMTG:SetValue(false) end)
    end
    if M.S.DoomTowerEnabled then
        M.disableTowerDrop()
        pcall(function() DTTG:SetValue(false) end)
    end
end})

-- Valentine
ET:AddParagraph({
    Title = "💝 Valentine v12.2",
    Content = "Rent naar brainrots, bij 100♥ → station"
})
local VSP = ET:AddParagraph({Title = "💝 Status", Content = "Idle"})
local VTG = ET:AddToggle("ValentineToggle", {Title = "💝 Valentine", Default = false})
VTG:OnChanged(function(v)
    if v then M.startValentine() else M.stopValentine() end
end)

ET:AddButton({Title = "💝 Find Station", Callback = function()
    local s = M.findValentineStation()
    if s then
        local pos = M._valentineStationCF and M._valentineStationCF.Position
            or Vector3.new(0, 0, 0)
        Fluent:Notify({
            Title = "Station", Content = s.Name .. "\n" .. tostring(pos), Duration = 5
        })
    else
        Fluent:Notify({Title = "Station", Content = "Niet gevonden!", Duration = 3})
    end
end})

ET:AddButton({Title = "💝 Submit Nu", Callback = function()
    local ok = M.submitAtStation()
    Fluent:Notify({
        Title = "Submit", Content = ok and "✓" or "✗", Duration = 3
    })
end})

-- Arcade
local ASP = ET:AddParagraph({Title = "🕹️ Arcade", Content = "Idle"})
local ATG = ET:AddToggle("ArcadeToggle", {Title = "🕹️ Arcade", Default = false})
ATG:OnChanged(function(v)
    if v then M.startArcade() else M.stopArcade() end
end)

-- ========== AUTO TAB ==========
local AT2 = W:AddTab({Title = "Auto", Icon = "rocket"})

local MSP = AT2:AddParagraph({Title = "💰 Money", Content = "Idle"})
local MTG = AT2:AddToggle("MoneyToggle", {Title = "💰 Money", Default = false})
MTG:OnChanged(function(v)
    if v then M.findBase(); M.startMoney() else M.stopMoney() end
end)

local USP = AT2:AddParagraph({Title = "⬆️ Upgrade", Content = "Idle"})
local UTG = AT2:AddToggle("UpgradeToggle", {Title = "⬆️ Upgrade All", Default = false})
UTG:OnChanged(function(v)
    if v then M.findBase(); M.startAutoUpgrade() else M.stopAutoUpgrade() end
end)

local MFSP = AT2:AddParagraph({Title = "🗺️ Map Fixer", Content = "Uit"})
local MFTG = AT2:AddToggle("MapToggle", {Title = "🗺️ Map Fixer", Default = false})
MFTG:OnChanged(function(v)
    if v then M.startMapFixer() else M.stopMapFixer() end
end)

AT2:AddButton({Title = "🗺️ Fix 1x", Callback = function()
    M._lastFixedMapName = ""
    pcall(function() M.mapRunFix() end)
end})

-- God Mode
AT2:AddParagraph({Title = "🛡️ God Mode v23", Content = "Throttled"})
AT2:AddDropdown("GodWalkY", {
    Title = "Loop Y", Values = GODWALKY, Default = "-2", Multi = false
}):OnChanged(function(v)
    M.S.GodWalkY = tonumber(v) or -2
    if M._isGod then M.godTeleportUnder() end
end)

AT2:AddDropdown("GodFloorY", {
    Title = "Vloer Y", Values = GODFLOORY, Default = "-5", Multi = false
}):OnChanged(function(v)
    M.S.GodFloorY = tonumber(v) or -5
end)

local GDSP = AT2:AddParagraph({Title = "God Status", Content = "Uit"})
local GDTG = AT2:AddToggle("GodToggle", {Title = "🛡️ God Mode", Default = false})
GDTG:OnChanged(function(v)
    if v then M.enableGod() else M.disableGod() end
end)

AT2:AddButton({Title = "📍 Teleport Onder", Callback = function()
    if M._isGod then M.godTeleportUnder() end
end})

AT2:AddToggle("InstantToggle", {
    Title = "⚡ Instant Pickup", Default = true
}):OnChanged(function(v)
    M.S.InstantPickup = v
    if v then M.setupInstant() end
end)

local AFKSP = AT2:AddParagraph({Title = "AFK", Content = "Uit"})
local AFKTG = AT2:AddToggle("AFKToggle", {Title = "🛡️ Anti-AFK", Default = false})
AFKTG:OnChanged(function(v)
    if v then M.startAFK() else M.stopAFK() end
end)

-- ========== CONFIG TAB ==========
local CT = W:AddTab({Title = "Config", Icon = "settings"})

CT:AddDropdown("TweenSpeed", {
    Title = "Speed", Values = SPD, Default = "INSTANT", Multi = false
}):OnChanged(function(v) M.S.TweenSpeed = SPM[v] or 9999 end)

CT:AddDropdown("CorridorSpeed", {
    Title = "Corridor", Values = CSPD, Default = "1500", Multi = false
}):OnChanged(function(v) M.S.CorridorSpeed = tonumber(v) or 1500 end)

-- v12.2: Kleur Thema
CT:AddDropdown("WallTheme", {
    Title = "🎨 Muur/Vloer Thema",
    Description = "Auto past aan per map",
    Values = THEMES,
    Default = "Dark",
    Multi = false,
}):OnChanged(function(v)
    M.S.WallTheme = v
    -- Force rebuild walls
    M._lastFixedMapName = ""
    pcall(function() M.mapRunFix() end)
    -- Rebuild god floor als actief
    if M._isGod then
        M.disableGod()
        task.wait(0.3)
        M.enableGod()
    end
end)

CT:AddButton({Title = "🔄 Herlaad Brainrots", Callback = function()
    M.S.SelectedBrainrots = {}
    pcall(function()
        BDD:SetValues(M.getBrainrotNamesMulti(M.S.TargetRarity))
        BDD:SetValue({})
    end)
end})

CT:AddButton({Title = "🏠 Zoek Base", Callback = function()
    M.findBase()
    Fluent:Notify({Title = "Base", Content = M.baseGUID or "?", Duration = 3})
end})

CT:AddButton({Title = "📍 Home Op", Callback = function()
    M.setHomePosition()
end})

CT:AddButton({Title = "📋 Slots", Callback = function()
    M.findBase()
    local o = M.findOccupiedSlots()
    local i = ""
    for _, s in pairs(o) do
        i = i .. "S" .. s.slot .. ":" .. s.name .. " L" .. s.level .. "\n"
    end
    Fluent:Notify({
        Title = "Slots(" .. #o .. ")",
        Content = #o > 0 and i or "Leeg!",
        Duration = 8
    })
end})

CT:AddButton({Title = "🗑️ Leeg Slot", Callback = function()
    M.findBase()
    M.clearSlot(tonumber(M.S.FarmSlot) or 5)
end})

CT:AddButton({Title = "🏠 Ga Base", Callback = function()
    M.findBase()
    M.returnToBase()
end})

CT:AddButton({Title = "🛡️ Debug Info", Callback = function()
    local MF = M._MF or {W = 420, WH = 80}
    local i = "God:" .. (M._isGod and "AAN" or "UIT")
        .. "\nWalk:" .. M.S.GodWalkY .. " Floor:" .. M.S.GodFloorY
    i = i .. "\nOrig:" .. #M._godOriginalFloors
        .. " God:" .. #M._godCreatedParts
        .. " Kill:" .. #M._godKillParts
    i = i .. "\nThema:" .. (M.S.WallTheme or "Dark")
    i = i .. "\nDoom: " .. (M.S.DoomEnabled and "AAN" or "UIT")
        .. " Parts:" .. #M._doomCachedParts
    i = i .. "\nTower: " .. (M._towerMoved and "Moved" or "Off")
    local tY = M.getTowerY()
    if tY then i = i .. " Y:" .. string.format("%.1f", tY) end
    if M._towerDetectedFloorY then
        i = i .. "\nFloor: Y=" .. string.format("%.1f", M._towerDetectedFloorY)
    end
    local hrp = M.Player.Character
        and M.Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        i = i .. "\nPlayer Y:" .. string.format("%.1f", hrp.Position.Y)
    end
    Fluent:Notify({Title = "Debug v12.2", Content = i, Duration = 12})
end})

local IP = CT:AddParagraph({Title = "Info", Content = "..."})

-- ========== SETTINGS TAB ==========
local ST2 = W:AddTab({Title = "Settings", Icon = "shield"})
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:SetFolder("MzDHub")
InterfaceManager:SetFolder("MzDHub")
InterfaceManager:BuildInterfaceSection(ST2)
SaveManager:BuildConfigSection(ST2)

-- ========== STATUS UPDATER ==========
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            FSP:SetDesc(
                (M.S.Farming and M.Status.farm or "Idle")
                .. " | #" .. M.Status.farmCount
            )
            FPP:SetDesc("P:" .. M.Status.placeCount .. " U:" .. M.Status.upgradeCount)
            if not M.S.Farming then
                pcall(function()
                    if FTG.Value then FTG:SetValue(false) end
                end)
            end

            LBSP:SetDesc(
                (M.S.LuckyBlockEnabled and M.Status.luckyBlock or "Idle")
                .. " #" .. M.Status.luckyBlockCount
            )
            if not M.S.LuckyBlockEnabled then
                pcall(function()
                    if LBTG.Value then LBTG:SetValue(false) end
                end)
            end

            FCSP:SetDesc(
                (M.Status.factory or "Idle") .. " #" .. M.Status.factoryCount
            )
            if not M.S.FactoryEnabled then
                pcall(function()
                    if FCTG.Value then FCTG:SetValue(false) end
                end)
            end

            if M.S.DoomEnabled then
                local folder = workspace:FindFirstChild("DoomEventParts")
                local fc = folder and #folder:GetChildren() or 0
                DMSP:SetDesc(
                    "AAN ✓ | Parts:" .. #M._doomCachedParts .. " | Folder:" .. fc
                )
            else
                DMSP:SetDesc("Uit")
            end
            if not M.S.DoomEnabled then
                pcall(function()
                    if DMTG.Value then DMTG:SetValue(false) end
                end)
            end

            if M.S.DoomTowerEnabled then
                local tY = M.getTowerY()
                local bY = M.getTowerBottomY()
                DTSP:SetDesc(
                    "AAN ✓ | Y:" .. (tY and string.format("%.0f", tY) or "?")
                    .. " Bot:" .. (bY and string.format("%.0f", bY) or "?")
                    .. " Off:" .. M.S.DoomTowerOffset
                )
            else
                DTSP:SetDesc("Uit")
            end
            if not M.S.DoomTowerEnabled then
                pcall(function()
                    if DTTG.Value then DTTG:SetValue(false) end
                end)
            end

            VSP:SetDesc(
                (M.S.ValentineEnabled and M.Status.valentine or "Idle")
                .. " #" .. M.Status.valentineCount
            )
            if not M.S.ValentineEnabled then
                pcall(function()
                    if VTG.Value then VTG:SetValue(false) end
                end)
            end

            ASP:SetDesc(
                M.S.ArcadeEnabled
                    and ("Actief #" .. M.Status.arcadeCount)
                    or "Idle"
            )
            if not M.S.ArcadeEnabled then
                pcall(function()
                    if ATG.Value then ATG:SetValue(false) end
                end)
            end

            MSP:SetDesc(M.S.AutoCollectMoney and "Actief (throttled)" or "Idle")
            if not M.S.AutoCollectMoney then
                pcall(function()
                    if MTG.Value then MTG:SetValue(false) end
                end)
            end

            USP:SetDesc(
                (M.S.AutoUpgrade and M.upgradeThread and M.Status.upgrade or "Idle")
                .. " #" .. M.Status.upgradeCount
            )
            if not (M.S.AutoUpgrade and M.upgradeThread) then
                pcall(function()
                    if UTG.Value then UTG:SetValue(false) end
                end)
            end

            MFSP:SetDesc(M.S.MapFixerEnabled and M.Status.mapFixer or "Uit")
            if not M.S.MapFixerEnabled then
                pcall(function()
                    if MFTG.Value then MFTG:SetValue(false) end
                end)
            end

            AFKSP:SetDesc("AFK:" .. M.Status.afk)
            if not M.S.AntiAFK then
                pcall(function()
                    if AFKTG.Value then AFKTG:SetValue(false) end
                end)
            end

            GDSP:SetDesc(M.Status.god)
            if not M._isGod then
                pcall(function()
                    if GDTG.Value then GDTG:SetValue(false) end
                end)
            end

            local hrp = M.Player.Character
                and M.Player.Character:FindFirstChild("HumanoidRootPart")
            local curY = hrp and string.format("%.1f", hrp.Position.Y) or "?"
            IP:SetDesc(
                "Player:" .. M.Player.Name
                .. "\nBase:" .. (M.baseGUID or "?")
                .. "\nGod:" .. (M._isGod and "AAN" or "UIT")
                .. " Thema:" .. (M.S.WallTheme or "Dark")
                .. "\nY:" .. curY
            )
        end)
    end
end)

-- ========== STARTUP ==========
task.spawn(function()
    task.wait(1)
    M.findBase()
    task.wait(0.5)
    M.detectWallZ()
    Fluent:Notify({
        Title = "MzD Hub v12.2",
        Content = "🔧 Modulair geladen\n💝 Valentine: rent + submit\n🎨 Kleur thema's\n✅ Alle fixes v12.1",
        Duration = 8,
    })
end)

W:SelectTab(1)
print("[MzD Hub] GUI geladen ✓")
print("[MzD Hub] v12.2 VOLLEDIG GELADEN ✓")