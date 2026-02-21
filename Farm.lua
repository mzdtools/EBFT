-- modules/Farm.lua
-- Auto Farm + Lucky Blocks
-- ============================================

local M = getgenv().MzD

-- ========== FARMING ==========
function M.startFarming()
    if M.farmThread then return end
    M.S.Farming = true
    M.Status.farmCount = 0
    M.setHomePosition()
    M.detectWallZ()
    M.returnToBase()
    M.enableGod()

    M.farmThread = task.spawn(function()
        while M.S.Farming do
            local ok, err = pcall(function()
                if M.isDead() then
                    M.waitForRespawn()
                    task.wait(1)
                    M.setHomePosition()
                    M.enableGod()
                    task.wait(0.5)
                    return
                end

                local ch = M.Player.Character
                local hum = ch and ch:FindFirstChild("Humanoid")
                if not ch or not hum then task.wait(1); return end
                if not M.baseGUID then M.findBase() end
                if not M.baseGUID then task.wait(2); return end

                local ws = tonumber(M.S.FarmSlot) or 5

                if M.S.FarmMode == "Collect" then
                    if not M.ActiveBrainrots then
                        M.ActiveBrainrots = workspace:FindFirstChild("ActiveBrainrots")
                    end
                    if M.ActiveBrainrots then
                        for _, folder in pairs(M.ActiveBrainrots:GetChildren()) do
                            if not M.S.Farming then break end
                            if folder:IsA("Folder") and M.rarityMatches(folder.Name) then
                                for _, b in pairs(folder:GetChildren()) do
                                    if not M.S.Farming or M.isDead() then break end
                                    if M.matchesFilter(b, folder.Name) then
                                        local root = M.findBrainrotRoot(b)
                                        if not root then continue end
                                        M.safePathTo(root.CFrame * CFrame.new(0, 3, 0))
                                        for attempt = 1, 5 do
                                            if not M.S.Farming then break end
                                            if M.isDead() then
                                                M.waitForRespawn()
                                                task.wait(1)
                                                M.setHomePosition()
                                                M.enableGod()
                                                if root and root.Parent then
                                                    M.safePathTo(root.CFrame * CFrame.new(0, 3, 0))
                                                else break end
                                            end
                                            if root and root.Parent then
                                                M.forceGrabPrompt(root)
                                                M.forceGrabPrompt(b)
                                                task.wait(0.3)
                                                M.Status.farmCount += 1
                                                break
                                            else break end
                                        end
                                        M.safeUnequip()
                                        task.wait(0.1)
                                        M.safeReturnToBase()
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                    return
                end

                -- Collect, Place & Max mode
                if not M.isSlotEmpty(ws) then
                    M.pickUpBrainrot(ws)
                    task.wait(0.5)
                    M.safeUnequip()
                    task.wait(0.3)
                end

                local tool = M.findTargetToolInBackpack()
                if tool and M.isHighRarityTool(tool) then
                    M.Status.farm = "✓ " .. (tool:GetAttribute("Rarity") or "High")
                    M.Status.farmCount += 1
                    task.wait(0.5)
                    tool = nil
                end

                if not tool then
                    local found = false
                    if not M.ActiveBrainrots then
                        M.ActiveBrainrots = workspace:FindFirstChild("ActiveBrainrots")
                    end
                    if M.ActiveBrainrots then
                        for _, folder in pairs(M.ActiveBrainrots:GetChildren()) do
                            if not M.S.Farming then break end
                            if folder:IsA("Folder") and M.rarityMatches(folder.Name) then
                                for _, b in pairs(folder:GetChildren()) do
                                    if not M.S.Farming or M.isDead() then break end
                                    if M.matchesFilter(b, folder.Name) then
                                        local root = M.findBrainrotRoot(b)
                                        if not root then continue end
                                        found = true
                                        M.Status.farm = "Ophalen " .. folder.Name
                                        M.safePathTo(root.CFrame * CFrame.new(0, 3, 0))
                                        for attempt = 1, 5 do
                                            if not M.S.Farming then break end
                                            if M.isDead() then
                                                M.waitForRespawn()
                                                task.wait(1)
                                                M.setHomePosition()
                                                M.enableGod()
                                                if not M.S.Farming then break end
                                                if root and root.Parent then
                                                    M.safePathTo(root.CFrame * CFrame.new(0, 3, 0))
                                                else
                                                    found = false
                                                    break
                                                end
                                            end
                                            if root and root.Parent then
                                                M.forceGrabPrompt(root)
                                                M.forceGrabPrompt(b)
                                                task.wait(0.3)
                                                M.Status.farmCount += 1
                                                break
                                            else
                                                found = false
                                                break
                                            end
                                        end
                                        M.safeUnequip()
                                        task.wait(0.1)
                                        M.safeReturnToBase()
                                        break
                                    end
                                end
                            end
                            if found then break end
                        end
                    end
                    if not found then
                        M.Status.farm = "Wachten..."
                        task.wait(2)
                        return
                    end
                    task.wait(0.3)
                    tool = M.findTargetToolInBackpack()
                    if not tool then task.wait(1); return end
                end

                if M.isHighRarityTool(tool) then
                    M.Status.farm = "✓ High"
                    M.Status.farmCount += 1
                    task.wait(0.5)
                    return
                end

                local bName = tool:GetAttribute("BrainrotName") or "Brainrot"
                M.tweenToSlot(ws)
                task.wait(0.3)
                M.safeEquip(tool)
                task.wait(0.5)
                M.placeBrainrot(ws)
                task.wait(0.8)
                if M.isSlotEmpty(ws) then
                    M.safeUnequip()
                    task.wait(1)
                    return
                end

                local mb = workspace:FindFirstChild("Bases")
                    and workspace.Bases:FindFirstChild(M.baseGUID)
                local sm = mb and mb:FindFirstChild("slot " .. ws .. " brainrot")
                if sm then
                    local cur = tonumber(sm:GetAttribute("Level")) or 0
                    local fails = 0
                    while cur < M.S.MaxLevel and M.S.Farming do
                        M.upgradeBrainrot(ws)
                        task.wait(0.15)
                        local nw = tonumber(sm:GetAttribute("Level")) or cur
                        if nw > cur then
                            fails = 0
                            cur = nw
                            M.Status.upgradeCount += 1
                            M.Status.farm = bName .. " Lv." .. cur
                                .. "/" .. M.S.MaxLevel
                        else
                            fails += 1
                            if fails > 60 then break end
                        end
                    end
                end

                task.wait(0.3)
                M.pickUpBrainrot(ws)
                task.wait(0.8)
                M.safeUnequip()
                task.wait(0.3)
                if not M.isSlotEmpty(ws) then
                    M.pickUpBrainrot(ws)
                    task.wait(0.5)
                    M.safeUnequip()
                    task.wait(0.3)
                end
            end)
            if not ok then task.wait(1) end
            task.wait(0.3)
        end
        M.disableGod()
        M.Status.farm = "Idle"
        M.farmThread = nil
    end)
end

function M.stopFarming()
    M.S.Farming = false
    if M.farmThread then
        pcall(task.cancel, M.farmThread)
        M.farmThread = nil
    end
    M.disableGod()
    M.Status.farm = "Idle"
end

-- ========== LUCKY BLOCKS ==========
function M.getLuckyBlockRarities()
    return type(M.S.LuckyBlockRarity) == "table"
        and M.S.LuckyBlockRarity or {M.S.LuckyBlockRarity}
end

function M.luckyBlockRarityMatches(bn)
    for _, r in pairs(M.getLuckyBlockRarities()) do
        if r == "Any" or bn:find(r) or bn == r then return true end
    end
    return false
end

function M.luckyBlockMutationMatches(block)
    local mut = block:GetAttribute("Mutation") or "None"
    local isNone = (mut:lower() == "none" or mut == "")
    if M.S.LuckyBlockMutation == "Any" then return true end
    if M.S.LuckyBlockMutation == "None" then return isNone end
    return mut == M.S.LuckyBlockMutation
end

function M.findLuckyBlockRoot(block)
    local r = block:FindFirstChild("Root")
    if r and r:IsA("BasePart") then return r end
    if block:IsA("BasePart") then return block end
    local p = nil
    pcall(function() p = block.PrimaryPart end)
    if p then return p end
    for _, d in pairs(block:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
    return nil
end

function M.grabLuckyBlock(block, rootPart)
    if not block or not rootPart then return end
    for _, d in pairs(block:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            pcall(function()
                d.MaxActivationDistance = 99999
                d.HoldDuration = 0
                d.RequiresLineOfSight = false
            end)
            pcall(function() fireproximityprompt(d) end)
        end
    end
    local hrp = M.Player.Character
        and M.Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        if rootPart:IsA("BasePart") then
            pcall(function()
                firetouchinterest(hrp, rootPart, 0)
                firetouchinterest(hrp, rootPart, 1)
            end)
        end
        for _, d in pairs(block:GetDescendants()) do
            if d:IsA("BasePart") then
                pcall(function()
                    firetouchinterest(hrp, d, 0)
                    firetouchinterest(hrp, d, 1)
                end)
            end
        end
    end
end

function M.startLuckyBlockFarm()
    if M.luckyBlockThread then return end
    M.S.LuckyBlockEnabled = true
    M.Status.luckyBlockCount = 0
    M.setHomePosition()
    M.enableGod()

    M.luckyBlockThread = task.spawn(function()
        while M.S.LuckyBlockEnabled do
            local ok = pcall(function()
                if M.isDead() then
                    M.waitForRespawn()
                    task.wait(1)
                    M.setHomePosition()
                    M.enableGod()
                    return
                end
                if not M.ActiveLuckyBlocks then
                    M.ActiveLuckyBlocks = workspace:FindFirstChild("ActiveLuckyBlocks")
                end
                if not M.ActiveLuckyBlocks then task.wait(3); return end

                local foundBlock = false
                for _, block in pairs(M.ActiveLuckyBlocks:GetChildren()) do
                    if not M.S.LuckyBlockEnabled or M.isDead() then break end
                    if M.luckyBlockRarityMatches(block.Name)
                        and M.luckyBlockMutationMatches(block) then
                        local rootPart = M.findLuckyBlockRoot(block)
                        if not rootPart then continue end
                        foundBlock = true
                        M.safePathTo(rootPart.CFrame * CFrame.new(0, 3, 0))
                        M.grabLuckyBlock(block, rootPart)
                        local t = tick()
                        while tick() - t < 0.2 do
                            if not block.Parent or not rootPart.Parent then break end
                            task.wait(0.02)
                        end
                        if not block.Parent or not rootPart.Parent then
                            M.Status.luckyBlockCount += 1
                        end
                        M.safeUnequip()
                        M.safeReturnToBase()
                        break
                    end
                end
                if not foundBlock then task.wait(2) end
            end)
            task.wait(0.1)
        end
        M.disableGod()
        M.Status.luckyBlock = "Idle"
        M.luckyBlockThread = nil
    end)
end

function M.stopLuckyBlockFarm()
    M.S.LuckyBlockEnabled = false
    if M.luckyBlockThread then
        pcall(task.cancel, M.luckyBlockThread)
        M.luckyBlockThread = nil
    end
    M.disableGod()
    M.Status.luckyBlock = "Idle"
end

print("[MzD Hub] Farm geladen ✓")