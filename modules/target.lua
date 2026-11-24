local VisParams = RaycastParams.new()
VisParams.FilterType = Enum.RaycastFilterType.Exclude
VisParams.IgnoreWater = true
local VisFilterChar = nil
local function SyncVisFilter()
    local lc = CharOf(LocalPlayer)
    if lc == VisFilterChar then return end
    VisFilterChar = lc
    local filt = {}
    if lc then filt[#filt + 1] = lc end
    local c = Cam()
    if c then filt[#filt + 1] = c end
    VisParams.FilterDescendantsInstances = filt
end
local RayBudget = { n = 0, at = 0 }
local function Visible(p, part, char)
    if not S.wallCheck then return true end
    local now = os.clock()
    if now - RayBudget.at > 0.05 then RayBudget.at = now RayBudget.n = 0 end
    local e = R.visCache[p]
    if e and now - e.at < (e.v and R.visTtl or 0.04) and (part.Position - e.pos).Magnitude < 2.5 then return e.v end
    if RayBudget.n >= R.rayMax then
        if e then return e.v end
        return true
    end
    local c = Cam()
    if not c then return true end
    SyncVisFilter()
    local origin = c.CFrame.Position
    RayBudget.n = RayBudget.n + 1
    R.selfRay = true
    local res = Workspace:Raycast(origin, part.Position - origin, VisParams)
    R.selfRay = false
    local v = true
    if res and not (char and res.Instance and res.Instance:IsDescendantOf(char)) then v = false end
    R.visCache[p] = { v = v, at = now, pos = part.Position }
    return v
end
local function AimPoint()
    local c = Cam()
    if R.touchOnly and c then return Vector2.new(c.ViewportSize.X / 2, c.ViewportSize.Y / 2) end
    local p = nil
    pcall(function() p = UserInputService:GetMouseLocation() end)
    if p then return p end
    if c then return Vector2.new(c.ViewportSize.X / 2, c.ViewportSize.Y / 2) end
    return Vector2.new(0, 0)
end
local function RollChance()
    local now = os.clock()
    if now - R.chanceAt > 0.15 then
        R.chanceAt = now
        R.chanceOk = (math.random(1, 100) <= S.hitChance)
    end
    return R.chanceOk
end
local CANDS = { "Head", "UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso" }
local PART_BONUS = { Head = 0, UpperTorso = 16, Torso = 16, HumanoidRootPart = 10, LowerTorso = 12 }
local function PartsFor(p, char)
    local pc = R.partsCache[p]
    local stale = false
    if pc and pc.char == char then
        for _, pt in ipairs(pc.list) do
            if pt.Parent ~= char then stale = true break end
        end
        if not stale and #pc.list < 3 and os.clock() - (pc.at or 0) > 1 then stale = true end
    end
    if not pc or pc.char ~= char or stale then
        pc = { char = char, at = os.clock() }
        local list = {}
        for _, n in ipairs(CANDS) do
            local pt = PartOf(char, n)
            if pt then list[#list + 1] = pt pc[n] = pt end
        end
        if #list < 2 then
            pcall(function()
                for _, d in ipairs(char:GetDescendants()) do
                    if #list >= 24 then break end
                    if d:IsA("BasePart") and d.Name ~= "Handle" and not pc[d.Name] then
                        local ln = string.lower(d.Name)
                        if string.find(ln, "torso", 1, true) or string.find(ln, "root", 1, true) or string.find(ln, "head", 1, true) or string.find(ln, "arm", 1, true) or string.find(ln, "leg", 1, true) or string.find(ln, "body", 1, true) then
                            list[#list + 1] = d
                            pc[d.Name] = d
                        end
                    end
                end
            end)
        end
        pc.list = list
        R.partsCache[p] = pc
    end
    if S.targetMode == "Head" then
        local h = pc.Head or pc.HumanoidRootPart
        if h then
            local o = pc.one
            if not o then o = {} pc.one = o end
            o[1] = h
            return o
        end
        return R.emptyParts
    elseif S.targetMode == "Torso" then
        local t = pc.UpperTorso or pc.Torso or pc.HumanoidRootPart
        if t then
            local o = pc.one
            if not o then o = {} pc.one = o end
            o[1] = t
            return o
        end
        return R.emptyParts
    end
    return pc.list
end
local CandBuf = {}
local CommitSt = { c = nil, aim = nil, fovLim = 0, done = false }
local function CommitTgt(e, lax)
    local st = CommitSt
    local pred = Predict(e.p, e.part, e.char)
    local sp, on = st.c:WorldToViewportPoint(pred)
    local lim = lax and (st.fovLim * 1.4) or st.fovLim
    local cdx, cdy = sp.X - st.aim.X, sp.Y - st.aim.Y
    if on and math.sqrt(cdx * cdx + cdy * cdy) > lim then return false end
    if R.target ~= e.p then R.targetSince = os.clock() end
    R.target, R.part = e.p, e.part
    R.pos = pred
    R.posAt = os.clock()
    R.rawPos = e.part.Position
    R.targetKey = e.key
    R.warmP, R.warmTick = e.p, R.tickId or 0
    st.done = true
    return true
end
local function TryCommitVisible(e)
    if Visible(e.p, e.part, e.char) then return CommitTgt(e) end
    local c, aim = CommitSt.c, CommitSt.aim
    if not c or not aim then return false end
    for _, part in ipairs(PartsFor(e.p, e.char)) do
        if part ~= e.part then
            local sp, on = c:WorldToViewportPoint(part.Position)
            if on and sp.Z > 0 then
                local dx, dy = sp.X - aim.X, sp.Y - aim.Y
                if math.sqrt(dx * dx + dy * dy) <= CommitSt.fovLim * 1.25 and Visible(e.p, part, e.char) then
                    local old = e.part
                    e.part = part
                    if CommitTgt(e) then return true end
                    e.part = old
                end
            end
        end
    end
    return false
end
local function FireAcquire()
    if R.charDead then return end
    local c = Cam()
    if not c then return end
    local aim = R.aimPoint
    local camPos = c.CFrame.Position
    local wide = math.max(S.fov * 3, 300)
    local n = 0
    for _, p in ipairs(PlayerList()) do
        if IsEnemy(p) then
            local char = CharOf(p)
            local hum = HumOf(char)
            if char and hum and hum.Health > 0 and not InHidden(char) and not (S.ffCheck and HasFF(char)) then
                local bestPart, bestKey = nil, math.huge
                for _, part in ipairs(PartsFor(p, char)) do
                    local sp, on = c:WorldToViewportPoint(part.Position)
                    if on and sp.Z > 0 then
                        local dx, dy = sp.X - aim.X, sp.Y - aim.Y
                        local d = math.sqrt(dx * dx + dy * dy)
                        local key = d - (PART_BONUS[part.Name] or 0)
                        if d <= wide and key < bestKey and (part.Position - camPos).Magnitude <= S.maxDist then
                            bestKey = key
                            bestPart = part
                        end
                    end
                end
                if bestPart then
                    n = n + 1
                    local e = CandBuf[n]
                    if not e then e = {} CandBuf[n] = e end
                    e.p, e.char, e.part, e.key = p, char, bestPart, bestKey
                end
            end
        end
    end
    for i = n + 1, #CandBuf do CandBuf[i] = nil end
    if n == 0 then return end
    table.sort(CandBuf, R.cmpFn)
    CommitSt.c, CommitSt.aim, CommitSt.fovLim = c, aim, wide
    for i = 1, n do
        if TryCommitVisible(CandBuf[i]) then return end
    end
end
local function SelectTarget()
    local c = Cam()
    if not c or R.charDead then R.target, R.part, R.pos, R.rawPos = nil, nil, nil, nil return end
    local aim = R.aimPoint
    local camPos = c.CFrame.Position
    local fovLim = S.multiFire and 1000000 or S.fov
    local distLim = S.multiFire and 1000000 or S.maxDist
    if S.multiFire and R.multiKeepAt and os.clock() - R.multiKeepAt < 0.03 and R.target and R.part then
        local kchar = CharOf(R.target)
        local khum = HumOf(kchar)
        if kchar and khum and khum.Health > 0 and R.part.Parent == kchar and IsEnemy(R.target) and not InHidden(kchar) and not (S.ffCheck and HasFF(kchar)) then
            R.pos = Predict(R.target, R.part, kchar)
            R.posAt = os.clock()
            R.rawPos = R.part.Position
            R.warmP, R.warmTick = R.target, R.tickId or 0
            return
        end
    end
    if not S.multiFire and R.loadTier == 2 and R.scanKeepAt and os.clock() - R.scanKeepAt < 0.02 and R.target and R.part then
        local kchar = CharOf(R.target)
        local khum = HumOf(kchar)
        if kchar and khum and khum.Health > 0 and R.part.Parent == kchar and IsEnemy(R.target) and not InHidden(kchar) and not (S.ffCheck and HasFF(kchar)) then
            R.pos = Predict(R.target, R.part, kchar)
            R.posAt = os.clock()
            R.rawPos = R.part.Position
            R.warmP, R.warmTick = R.target, R.tickId or 0
            return
        end
    end
    R.scanKeepAt = os.clock()
    local n = 0
    for _, p in ipairs(PlayerList()) do
        if IsEnemy(p) then
            local char = CharOf(p)
            local hum = HumOf(char)
            if char and hum and hum.Health > 0 and not InHidden(char) and not (S.ffCheck and HasFF(char)) then
                local root0 = RootOf(char)
                local skip = false
                if root0 and p ~= R.target then
                    local rp, ron = c:WorldToViewportPoint(root0.Position)
                    local pdx, pdy = rp.X - aim.X, rp.Y - aim.Y
                    if not ron or rp.Z <= 0 or math.sqrt(pdx * pdx + pdy * pdy) > fovLim * 1.25 + 90 then skip = true end
                end
                local bestPart, bestKey = nil, math.huge
                local farB = 0
                if root0 and (root0.Position - camPos).Magnitude > 150 then farB = 30 end
                local airP = S.airTorso and IsAirborne(char)
                if not skip then for _, part in ipairs(PartsFor(p, char)) do
                    local aimPos = part.Position
                    if S.predSelect and S.prediction and R.loadTier < 2 then aimPos = Predict(p, part, char) end
                    local sp, on = c:WorldToViewportPoint(aimPos)
                    if on and sp.Z > 0 then
                        local sdx, sdy = sp.X - aim.X, sp.Y - aim.Y
                        local d = math.sqrt(sdx * sdx + sdy * sdy)
                        local key = d - (PART_BONUS[part.Name] or 0)
                        if airP and part.Name == "Head" then key = key + 25 end
                        if farB > 0 and (part.Name == "UpperTorso" or part.Name == "Torso" or part.Name == "HumanoidRootPart") then key = key - farB end
                        if d <= fovLim * 1.25 and key < bestKey then bestKey = key bestPart = part end
                    end
                end
                end
                if bestPart then
                    local wd = (bestPart.Position - camPos).Magnitude
                    if wd <= distLim then
                        local key = bestKey
                        if S.priority == "Distance" then key = wd
                        elseif S.priority == "Health" then key = (hum.Health / math.max(hum.MaxHealth, 1)) * 1000 + bestKey * 0.1 end
                        n = n + 1
                        local e = CandBuf[n]
                        if not e then e = {} CandBuf[n] = e end
                        e.p, e.char, e.part, e.key = p, char, bestPart, key
                    end
                end
            end
        end
    end
    for i = n + 1, #CandBuf do CandBuf[i] = nil end
    table.sort(CandBuf, R.cmpFn)
    CommitSt.c, CommitSt.aim, CommitSt.fovLim, CommitSt.done = c, aim, fovLim, false
    local now = os.clock()
    if not S.multiFire and R.target and R.part and (S.sticky or now < R.holdUntil) then
        local char = CharOf(R.target)
        local hum = HumOf(char)
        local stickyOk = char and hum and hum.Health > 0 and R.part.Parent == char and IsEnemy(R.target) and not InHidden(char) and not (S.ffCheck and HasFF(char))
        if stickyOk then
            local sroot = RootOf(char)
            if sroot and (sroot.Position - camPos).Magnitude > distLim then stickyOk = false end
        end
        if stickyOk then
            local bestPart, bestKey = R.part, math.huge
            for _, part in ipairs(PartsFor(R.target, char)) do
                local sp2, on2 = c:WorldToViewportPoint(part.Position)
                if on2 and sp2.Z > 0 then
                    local ddx, ddy = sp2.X - aim.X, sp2.Y - aim.Y
                    local d2 = math.sqrt(ddx * ddx + ddy * ddy)
                    local k2 = d2 - (PART_BONUS[part.Name] or 0)
                    if R.rawPos and (R.rawPos - camPos).Magnitude > 150 and (part.Name == "UpperTorso" or part.Name == "Torso" or part.Name == "HumanoidRootPart") then k2 = k2 - 30 end
                    if d2 <= S.fov * 1.4 and k2 < bestKey then bestKey = k2 bestPart = part end
                end
            end
            local sp, on = c:WorldToViewportPoint(bestPart.Position)
            local kdx, kdy = sp.X - aim.X, sp.Y - aim.Y
            if on and math.sqrt(kdx * kdx + kdy * kdy) <= S.fov * 1.4 and Visible(R.target, bestPart, char) then
                local e0 = R.stickyEnt
                e0.p, e0.char, e0.part, e0.key = R.target, char, bestPart, R.targetKey
                if CommitTgt(e0, true) then return end
            end
        end
    end
    if S.multiFire then
        R.multiKeepAt = os.clock()
        if n == 0 then R.target, R.part, R.pos, R.rawPos = nil, nil, nil, nil R.multiCurP = nil return end
        local start = 1
        if R.multiCurP then
            for i = 1, n do
                if CandBuf[i].p == R.multiCurP then start = i + 1 break end
            end
        end
        for k = 0, n - 1 do
            local idx = (start - 1 + k) % n + 1
            local e = CandBuf[idx]
            if TryCommitVisible(e) then
                R.multiCur = idx
                R.multiCurP = e.p
                return
            end
        end
        R.target, R.part, R.pos, R.rawPos = nil, nil, nil, nil
        return
    end
    local holdT = S.sticky and 0.12 or 0.05
    local holdK = S.sticky and 0.8 or 0.9
    for i = 1, n do
        local e = CandBuf[i]
        if R.target and e.p ~= R.target and now < R.holdUntil and e.key > R.targetKey * holdK then
        elseif TryCommitVisible(e) then
            R.holdUntil = now + holdT
            return
        end
    end
    if not CommitSt.done and R.target and R.part then
        local char = CharOf(R.target)
        local hum = HumOf(char)
        local keep = false
        if char and hum and hum.Health > 0 and R.part.Parent == char and IsEnemy(R.target) and not InHidden(char) and not (S.ffCheck and HasFF(char)) then
            local sp, on = c:WorldToViewportPoint(R.part.Position)
            local fdx, fdy = sp.X - aim.X, sp.Y - aim.Y
            if on and math.sqrt(fdx * fdx + fdy * fdy) <= S.fov * 1.4 and (R.part.Position - camPos).Magnitude <= distLim then keep = true end
        end
        if keep then
            R.pos = Predict(R.target, R.part, char)
            R.posAt = os.clock()
            R.rawPos = R.part.Position
            R.warmP, R.warmTick = R.target, R.tickId or 0
        else
            R.target, R.part, R.pos, R.rawPos = nil, nil, nil, nil
        end
    end
end
