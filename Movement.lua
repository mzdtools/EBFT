-- modules/Movement.lua
-- Tween, safePath, corridor, returnToBase
-- ============================================

local M = getgenv().MzD

-- ========== MAP HELPERS ==========
function M.mapFindCurrentMap()
    local best, bc = nil, 0
    for _, c in pairs(workspace:GetChildren()) do
        if c:IsA("Model") and c.Name:find("Map")
            and not c.Name:find("SharedInstances") then
            if c:FindFirstChild("Spawners") or c:FindFirstChild("Gaps")
                or c:FindFirstChild("RightWalls")
                or c:FindFirstChild("FirstFloor")
                or c:FindFirstChild("Ground") then
                return c
            end
            local cnt = 0
            for _, d in pairs(c:GetDescendants()) do
                if d:IsA("BasePart") then cnt += 1 end
                if cnt > 10 then return c end
            end
            if cnt > bc then bc = cnt; best = c end
        end
    end
    return best
end

function M.detectWallZ()
    local map = M.mapFindCurrentMap()
    if not map then return end
    local mzwalls = map:FindFirstChild("MzDHubWalls")
    if not mzwalls then return end
    local fw = mzwalls:FindFirstChild("FrontWall_1")
    local bw = mzwalls:FindFirstChild("BackWall_1")
    if fw then M._wallZ_front = fw.Position.Z - fw.Size.Z / 2 - 3 end
    if bw then M._wallZ_back = bw.Position.Z + bw.Size.Z / 2 + 3 end
end

function M.getCorridorZ()
    M.detectWallZ()
    local homePos = M.getHomePosition().Position
    if homePos.Z >= 0 then
        return M._wallZ_front
    else
        return M._wallZ_back
    end
end

-- ========== TWEEN ==========
function M.tweenTo(cf)
    local ch = M.Player.Character
    if not ch then return false end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local targetCF = cf
    if M._isGod then
        targetCF = CFrame.new(cf.Position.X, M.S.GodWalkY, cf.Position.Z)
    end
    local d = (hrp.Position - targetCF.Position).Magnitude
    local t = math.max(d / M.S.TweenSpeed, 0.01)
    local tw = M.TweenService:Create(
        hrp,
        TweenInfo.new(t, Enum.EasingStyle.Linear),
        {CFrame = targetCF}
    )
    tw:Play()
    tw.Completed:Wait()
    return true
end

function M.fastTween(cf)
    local ch = M.Player.Character
    if not ch then return false end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local targetCF = cf
    if M._isGod then
        targetCF = CFrame.new(cf.Position.X, M.S.GodWalkY, cf.Position.Z)
    end
    local d = (hrp.Position - targetCF.Position).Magnitude
    local t = math.max(d / 99999, 0.005)
    local tw = M.TweenService:Create(
        hrp,
        TweenInfo.new(t, Enum.EasingStyle.Linear),
        {CFrame = targetCF}
    )
    tw:Play()
    tw.Completed:Wait()
    return true
end

function M.corridorTween(cf)
    local ch = M.Player.Character
    if not ch then return false end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local targetCF = cf
    if M._isGod then
        targetCF = CFrame.new(cf.Position.X, M.S.GodWalkY, cf.Position.Z)
    end
    local d = (hrp.Position - targetCF.Position).Magnitude
    local spd = math.max(M.S.CorridorSpeed or 1500, 50)
    local t = math.max(d / spd, 0.01)
    local tw = M.TweenService:Create(
        hrp,
        TweenInfo.new(t, Enum.EasingStyle.Linear),
        {CFrame = targetCF}
    )
    tw:Play()
    tw.Completed:Wait()
    return true
end

-- ========== SAFE PATH ==========
function M.safePathTo(targetCFrame)
    local ch = M.Player.Character
    if not ch then return false end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local startPos = hrp.Position
    local endPos = targetCFrame.Position
    local SAFE_Z = M.getCorridorZ()
    local SAFE_Y = M._isGod and M.S.GodWalkY
        or (M.getHomePosition().Position.Y + 8)
    M.fastTween(CFrame.new(startPos.X, SAFE_Y, startPos.Z))
    task.wait(0.05)
    M.corridorTween(CFrame.new(startPos.X, SAFE_Y, SAFE_Z))
    task.wait(0.05)
    M.corridorTween(CFrame.new(endPos.X, SAFE_Y, SAFE_Z))
    task.wait(0.05)
    M.corridorTween(CFrame.new(endPos.X, SAFE_Y, endPos.Z))
    task.wait(0.05)
    local finalCF = M._isGod
        and CFrame.new(endPos.X, M.S.GodWalkY, endPos.Z)
        or targetCFrame
    M.tweenTo(finalCF)
    task.wait(0.05)
    return true
end

function M.safeReturnToBase()
    local ch = M.Player.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local curPos = hrp.Position
    local homePos = M.getHomePosition().Position
    M.detectWallZ()
    local SAFE_Z = M.getCorridorZ()
    local SAFE_Y = M._isGod and M.S.GodWalkY
        or (homePos.Y + 8)
    M.fastTween(CFrame.new(curPos.X, SAFE_Y, curPos.Z))
    task.wait(0.05)
    M.corridorTween(CFrame.new(curPos.X, SAFE_Y, SAFE_Z))
    task.wait(0.05)
    M.corridorTween(CFrame.new(homePos.X, SAFE_Y, SAFE_Z))
    task.wait(0.05)
    M.corridorTween(CFrame.new(homePos.X, SAFE_Y, homePos.Z))
    task.wait(0.05)
    M.tweenTo(CFrame.new(
        homePos.X,
        M._isGod and M.S.GodWalkY or homePos.Y,
        homePos.Z
    ))
    task.wait(0.05)
end

function M.returnToBase()
    if M._isGod then
        local hp = M.getHomePosition().Position
        M.tweenTo(CFrame.new(hp.X, M.S.GodWalkY, hp.Z))
    else
        M.tweenTo(M.getHomePosition())
    end
    task.wait(0.1)
end

print("[MzD Hub] Movement geladen ✓")