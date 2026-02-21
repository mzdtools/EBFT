-- modules/Factory.lua
-- Factory loop (no lock bug)
-- ============================================

local M = getgenv().MzD

local function factoryToolMatchesRarity(tool)
    local tMut = tool:GetAttribute("Mutation") or "None"
    local lvl = tonumber(tool:GetAttribute("Level")) or 0
    local bName = tool:GetAttribute("BrainrotName")
    local toolRarity = tool:GetAttribute("Rarity")

    if not bName or bName == "" then return false end
    if lvl >= M.S.FactoryMaxLevel then return false end

    if M.S.FactoryMutation == "None" then
        if not (tMut:lower() == "none" or tMut == "") then return false end
    elseif M.S.FactoryMutation ~= "Any" then
        if tMut ~= M.S.FactoryMutation then return false end
    end

    if M.S.FactoryRarity ~= "Any" then
        if toolRarity and toolRarity ~= "" then
            if toolRarity ~= M.S.FactoryRarity then return false end
        else
            local wl = {}
            for _, n in pairs(M.getBrainrotNames(M.S.FactoryRarity)) do
                wl[n] = true
            end
            if not wl[bName] then return false end
        end
    end

    return true
end

function M.startFactoryLoop()
    if M.factoryThread then return end
    M.S.FactoryEnabled = true
    M.Status.factoryCount = 0

    M.factoryThread = task.spawn(function()
        local stopReason = "Idle"
        while M.S.FactoryEnabled do
            local ok, err = pcall(function()
                if not M.baseGUID then M.findBase() end
                if not M.baseGUID then task.wait(2); return end

                local ws = tonumber(M.S.FactorySlot) or 5
                M.tweenToSlot(ws)
                task.wait(0.2)

                if not M.isSlotEmpty(ws) then
                    M.pickUpBrainrot(ws)
                    task.wait(1)
                    pcall(function()
                        M.Player.Character.Humanoid:UnequipTools()
                    end)
                    task.wait(0.5)
                end

                local tool = nil
                local sa = 0
                while not tool and sa < 5 do
                    sa += 1
                    local bp = M.Player:FindFirstChild("Backpack")
                    if bp then
                        for _, t in pairs(bp:GetChildren()) do
                            if t:IsA("Tool") and factoryToolMatchesRarity(t) then
                                tool = t
                                break
                            end
                        end
                    end
                    if not tool and M.Player.Character then
                        local eq = M.Player.Character:FindFirstChildWhichIsA("Tool")
                        if eq and factoryToolMatchesRarity(eq) then tool = eq end
                    end
                    if not tool and sa < 5 then task.wait(0.6) end
                end

                if not tool then
                    stopReason = "Klaar! ✓"
                    M.S.FactoryEnabled = false
                    return
                end

                local bName = tool:GetAttribute("BrainrotName") or "Item"
                local hum = M.Player.Character
                    and M.Player.Character:FindFirstChild("Humanoid")
                if hum then
                    hum:EquipTool(tool)
                    task.wait(0.5)
                end

                M.placeBrainrot(ws)
                task.wait(0.8)
                if M.isSlotEmpty(ws) then
                    pcall(function() if hum then hum:UnequipTools() end end)
                    task.wait(1)
                    return
                end

                local myBase = workspace:FindFirstChild("Bases")
                    and workspace.Bases:FindFirstChild(M.baseGUID)
                local sm = myBase
                    and myBase:FindFirstChild("slot " .. ws .. " brainrot")
                if sm then
                    local cur = tonumber(sm:GetAttribute("Level")) or 0
                    local fails = 0
                    while cur < M.S.FactoryMaxLevel and M.S.FactoryEnabled do
                        M.upgradeBrainrot(ws)
                        task.wait(0.1)
                        local nw = tonumber(sm:GetAttribute("Level")) or cur
                        if nw > cur then
                            fails = 0
                            cur = nw
                            M.Status.factory = bName .. " Lv." .. cur
                                .. "/" .. M.S.FactoryMaxLevel
                        else
                            fails += 1
                            if fails > 60 then
                                stopReason = "Geld op!"
                                M.S.FactoryEnabled = false
                                break
                            end
                        end
                    end
                end

                task.wait(0.5)
                M.pickUpBrainrot(ws)
                task.wait(1.2)
                M.Status.factoryCount += 1
                pcall(function() if hum then hum:UnequipTools() end end)
                task.wait(0.5)
                M.Status.factory = "✓ " .. bName
                    .. " (#" .. M.Status.factoryCount .. ")"
            end)
            if not ok then task.wait(1) end
        end
        M.Status.factory = stopReason
        M.factoryThread = nil
    end)
end

function M.stopFactoryLoop()
    M.S.FactoryEnabled = false
    if M.factoryThread then
        pcall(task.cancel, M.factoryThread)
        M.factoryThread = nil
    end
    if not (string.find(M.Status.factory or "", "✓")
        or string.find(M.Status.factory or "", "Klaar")
        or string.find(M.Status.factory or "", "Geld op")) then
        M.Status.factory = "Idle"
    end
end

print("[MzD Hub] Factory geladen ✓")