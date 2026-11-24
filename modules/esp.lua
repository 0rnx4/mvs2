local ESP_COLORS = {
    Red = Color3.fromRGB(255, 70, 70),
    Green = Color3.fromRGB(70, 255, 120),
    Blue = Color3.fromRGB(80, 150, 255),
    Purple = Color3.fromRGB(190, 110, 255),
    White = Color3.fromRGB(245, 245, 245),
    Orange = Color3.fromRGB(255, 150, 50),
    Cyan = Color3.fromRGB(60, 230, 230),
    Pink = Color3.fromRGB(255, 110, 190),
}
local GOLD_COL = Color3.fromRGB(255, 210, 60)
local SKEL_OUT_COL = Color3.fromRGB(5, 5, 8)
local function ShadeCol(c, f) return Color3.new(c.R * f, c.G * f, c.B * f) end
local function DesatCol(c) return Color3.new(c.R * 0.45 + 0.18, c.G * 0.45 + 0.18, c.B * 0.5 + 0.2) end
local KNIFE_COL = Color3.fromRGB(255, 80, 110)
local GUN_COL = Color3.fromRGB(80, 170, 255)
local DrawingOk = false
pcall(function()
    if typeof(Drawing) == "table" or typeof(Drawing) == "userdata" then
        local probe = Drawing.new("Square")
        probe:Remove()
        DrawingOk = true
    end
end)
pcall(function()
    if DrawingOk then
        local probe2 = Drawing.new("Text")
        probe2:Remove()
        R.drawText = true
    end
end)
pcall(function()
    if DrawingOk then
        local probe3 = Drawing.new("Line")
        probe3:Remove()
        local probe4 = Drawing.new("Circle")
        probe4:Remove()
        R.drawLine = true
    end
end)
local BONES = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local BONE_TIER = { 1, 1, 2, 2, 3, 2, 2, 3, 2, 2, 3, 2, 2, 3 }
local function ClearESP(p)
    local o = R.espObjs[p]
    if o then
        for _, d in pairs(o.draws) do
            if type(d) == "table" and d[1] ~= nil then
                for _, sd in ipairs(d) do pcall(function() sd:Remove() end) end
            else
                pcall(function() d:Remove() end)
            end
        end
        R.espObjs[p] = nil
    end
end
local function HideESP(o)
    if o.hidden then return end
    o.hidden = true
    for _, d in pairs(o.draws) do
        if type(d) == "table" and d[1] ~= nil then
            for _, sd in ipairs(d) do pcall(function() sd.Visible = false end) end
        else
            pcall(function() d.Visible = false end)
        end
    end
end
local function BuildESP(p)
    local ok, o = pcall(function()
        local box = Drawing.new("Square")
        box.Thickness = 1
        box.Filled = false
        box.Transparency = 1
        box.ZIndex = 5
        box.Visible = false
        local fill = Drawing.new("Square")
        fill.Thickness = 0
        fill.Filled = true
        fill.Transparency = 0.3
        fill.ZIndex = 4
        fill.Visible = false
        local hpBg = Drawing.new("Square")
        hpBg.Thickness = 0
        hpBg.Filled = true
        hpBg.Transparency = 0.7
        hpBg.Color = Color3.fromRGB(10, 10, 14)
        hpBg.ZIndex = 5
        hpBg.Visible = false
        local hp = Drawing.new("Square")
        hp.Thickness = 0
        hp.Filled = true
        hp.Transparency = 1
        hp.ZIndex = 6
        hp.Visible = false
        local nameT, infoT = nil, nil
        if R.drawText then
            nameT = Drawing.new("Text")
            nameT.Center = true
            nameT.Outline = true
            nameT.Size = 13
            nameT.Transparency = 1
            nameT.ZIndex = 5
            nameT.Visible = false
            pcall(function() nameT.Font = Drawing.Fonts.UI end)
            infoT = Drawing.new("Text")
            infoT.Center = true
            infoT.Outline = true
            infoT.Size = 12
            infoT.Transparency = 1
            infoT.ZIndex = 5
            infoT.Visible = false
            pcall(function() infoT.Font = Drawing.Fonts.UI end)
        end
        local boxOut = Drawing.new("Square")
        boxOut.Thickness = 3
        boxOut.Filled = false
        boxOut.Transparency = 1
        boxOut.Color = SKEL_OUT_COL
        boxOut.ZIndex = 4
        boxOut.Visible = false
        local draws = { box = box, hp = hp, hpBg = hpBg, fill = fill, name = nameT, info = infoT, boxOut = boxOut }
        if R.drawLine then
            local lok, lg = pcall(function()
                local tracer = Drawing.new("Line")
                tracer.Thickness = 1
                tracer.Transparency = 0.7
                tracer.ZIndex = 4
                tracer.Visible = false
                local dot = Drawing.new("Circle")
                dot.Thickness = 1
                dot.Filled = true
                dot.Transparency = 1
                dot.ZIndex = 6
                dot.Visible = false
                local skel = {}
                for i = 1, #BONES do
                    local ln = Drawing.new("Line")
                    ln.Thickness = 1
                    ln.Transparency = 1
                    ln.ZIndex = 5
                    ln.Visible = false
                    skel[i] = ln
                end
                local skelOut = {}
                for i = 1, #BONES do
                    local ln = Drawing.new("Line")
                    ln.Thickness = 3
                    ln.Transparency = 1
                    ln.Color = SKEL_OUT_COL
                    ln.ZIndex = 4
                    ln.Visible = false
                    skelOut[i] = ln
                end
                local skelJt = {}
                for i = 1, 5 do
                    local jt = Drawing.new("Circle")
                    jt.Thickness = 1
                    jt.Filled = true
                    jt.Transparency = 1
                    jt.ZIndex = 6
                    jt.Visible = false
                    skelJt[i] = jt
                end
                local corner = {}
                for i = 1, 8 do
                    local ln = Drawing.new("Line")
                    ln.Thickness = 1
                    ln.Transparency = 1
                    ln.ZIndex = 5
                    ln.Visible = false
                    corner[i] = ln
                end
                return { tracer = tracer, dot = dot, skel = skel, skelOut = skelOut, skelJt = skelJt, corner = corner }
            end)
            if lok and lg then
                draws.tracer = lg.tracer
                draws.dot = lg.dot
                draws.skel = lg.skel
                draws.skelOut = lg.skelOut
                draws.skelJt = lg.skelJt
                draws.corner = lg.corner
            end
        end
        local aok, av = pcall(function()
            local tri = Drawing.new("Triangle")
            tri.Filled = true
            tri.Transparency = 0.9
            tri.ZIndex = 5
            tri.Visible = false
            return tri
        end)
        if aok and av then draws.arrow = av end
        return { draws = draws, hidden = true, nameKey = false }
    end)
    if ok and o then
        R.espObjs[p] = o
        return o
    end
    R.espFailAt = os.clock()
    return nil
end
local function RefreshESP()
    if not DrawingOk or not S.esp then
        for p, o in pairs(R.espObjs) do HideESP(o) end
        return
    end
    local c = Cam()
    if not c then return end
    local lc = CharOf(LocalPlayer)
    local vpSz = c.ViewportSize
    local lroot = lc and RootOf(lc)
    local now = os.clock()
    for _, p in ipairs(PlayerList()) do
        if p ~= LocalPlayer then
            local o = R.espObjs[p]
            local show = false
            if IsEnemy(p) then
                local char = CharOf(p)
                local hum = HumOf(char)
                local root = char and RootOf(char)
                local distW = root and (root.Position - (lroot and lroot.Position or c.CFrame.Position)).Magnitude or math.huge
                if char and hum and hum.Health > 0 and root and not InHidden(char) and distW <= S.espMaxDist then
                    if S.espArrows then
                        if not o and now - R.espFailAt > 2 then o = BuildESP(p) end
                        if o and o.draws.arrow then
                            local spA, onA = c:WorldToViewportPoint(root.Position)
                            local vp = c.ViewportSize
                            if spA.Z <= 0 or not onA or spA.X < 0 or spA.Y < 0 or spA.X > vp.X or spA.Y > vp.Y then
                                HideESP(o)
                                local ccx, ccy = vp.X / 2, vp.Y / 2
                                local dx, dy = spA.X - ccx, spA.Y - ccy
                                if spA.Z <= 0 then dx, dy = -dx, -dy end
                                local len = math.sqrt(dx * dx + dy * dy)
                                if len < 1 then dx, dy, len = 0, -1, 1 end
                                dx, dy = dx / len, dy / len
                                local rr = math.min(vp.X, vp.Y) * 0.40
                                local ax, ay = ccx + dx * rr, ccy + dy * rr
                                local distA = (root.Position - c.CFrame.Position).Magnitude
                                local sf = 1.25 - math.clamp(distA / 800, 0, 1) * 0.55
                                local isTgtA = (p == R.target)
                                if isTgtA and S.espTargetCol then sf = sf * 1.25 end
                                local tri = o.draws.arrow
                                tri.PointA = Vector2.new(ax + dx * 16 * sf, ay + dy * 16 * sf)
                                tri.PointB = Vector2.new(ax - dx * 8 * sf - dy * 8 * sf, ay - dy * 8 * sf + dx * 8 * sf)
                                tri.PointC = Vector2.new(ax - dx * 8 * sf + dy * 8 * sf, ay - dy * 8 * sf - dx * 8 * sf)
                                local acol = ESP_COLORS[S.espColor] or ESP_COLORS.Red
                                local acls = R.classCache[p]
                                if S.espRoleColor and acls == "Knife" then acol = KNIFE_COL
                                elseif S.espRoleColor and acls == "Gun" then acol = GUN_COL end
                                if isTgtA and S.espTargetCol then acol = GOLD_COL end
                                tri.Color = acol
                                tri.Transparency = isTgtA and 1 or 0.85
                                tri.Visible = true
                                o.hidden = false
                                show = true
                            end
                        end
                    end
                    local bc = nil
                    if not show then bc = R.bboxCache[p] end
                    if not show and (not bc or bc.char ~= char or now - bc.at > 0.5) then
                        local okB, cf, size = pcall(function() return char:GetBoundingBox() end)
                        if okB and cf then
                            bc = { char = char, size = size, off = root.CFrame:ToObjectSpace(cf), at = now }
                            R.bboxCache[p] = bc
                        else
                            bc = nil
                        end
                    end
                    if bc then
                        local cf, size = root.CFrame * bc.off, bc.size
                        local topW = (cf * CFrame.new(0, size.Y / 2, 0)).Position
                        local botW = (cf * CFrame.new(0, -size.Y / 2, 0)).Position
                        local tsp = c:WorldToViewportPoint(topW)
                        local bsp = c:WorldToViewportPoint(botW)
                        if tsp.Z > 0 and bsp.Z > 0 and bsp.Y > tsp.Y and (bsp.Y - tsp.Y) >= 6 then
                            local rsp = tsp
                            if not o and now - R.espFailAt > 2 then o = BuildESP(p) end
                            if o then
                                local h = bsp.Y - tsp.Y
                                local w = h * 0.55
                                local tlS = c:WorldToViewportPoint((cf * CFrame.new(-size.X / 2, size.Y / 2, 0)).Position)
                                local trS = c:WorldToViewportPoint((cf * CFrame.new(size.X / 2, size.Y / 2, 0)).Position)
                                local cx = rsp.X
                                if tlS.Z > 0 and trS.Z > 0 then
                                    local w2 = math.abs(trS.X - tlS.X)
                                    if w2 >= 8 then w = w2 end
                                    cx = (tlS.X + trS.X) / 2
                                end
                                local col = ESP_COLORS[S.espColor] or ESP_COLORS.Red
                                local pcls = R.classCache[p]
                                if S.espRoleColor and pcls == "Knife" then col = KNIFE_COL
                                elseif S.espRoleColor and pcls == "Gun" then col = GUN_COL end
                                local isTgt = (p == R.target)
                                if isTgt and S.espTargetCol then col = GOLD_COL end
                                local alpha = 1
                                local visKnown, visOk = false, true
                                do
                                    local ve = R.visCache[p]
                                    if ve and now - ve.at < 0.6 then visKnown, visOk = true, ve.v end
                                end
                                if S.espDim and visKnown and not visOk then alpha = 0.45 end
                                if S.espDistFade then
                                    local fade = 1.15 - (distW / math.max(S.espMaxDist, 1)) * 0.55
                                    if fade < 0.45 then fade = 0.45 elseif fade > 1 then fade = 1 end
                                    alpha = alpha * fade
                                end
                                if S.espVisCol and visKnown and not visOk then
                                    col = DesatCol(col)
                                end
                                local d = o.draws
                                if (o.boneChar ~= char or o.boneParts == nil or (o.bonePartial and now - (o.boneAt or 0) > 1)) and (S.espSkeleton or S.espSkelJoints or S.espHeadDot or S.espTargetCol) then
                                    o.boneChar = char
                                    o.boneAt = now
                                    local bp, bl, seen, partial = {}, {}, {}, false
                                    for i = 1, #BONES do
                                        local pa, pb = PartOf(char, BONES[i][1]), PartOf(char, BONES[i][2])
                                        if not pa or not pb then partial = true end
                                        bp[i] = { pa, pb }
                                        if pa and not seen[pa] then seen[pa] = true bl[#bl + 1] = pa end
                                        if pb and not seen[pb] then seen[pb] = true bl[#bl + 1] = pb end
                                    end
                                    o.boneParts, o.boneList, o.bonePartial = bp, bl, partial
                                    o.headPart = PartOf(char, "Head")
                                    if not o.projP then o.projP, o.projOn = {}, {} end
                                end
                                if d.arrow then d.arrow.Visible = false end
                                local frac = 0
                                if hum.MaxHealth > 0 then frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1) end
                                if S.espHpSmooth then
                                    local pf = o.hpFrac
                                    if pf == nil or math.abs(frac - pf) > 0.5 then pf = frac else pf = pf + (frac - pf) * 0.35 end
                                    o.hpFrac = pf
                                    frac = pf
                                end
                                if o.hpCol == nil or math.abs(frac - (o.hpColF or -1)) > 0.02 then
                                    o.hpColF = frac
                                    if frac < 0.5 then
                                        local u2 = frac * 2
                                        o.hpCol = Color3.fromRGB(255, math.floor(59 + 131 * u2), math.floor(48 - 8 * u2))
                                    else
                                        local u2 = (frac - 0.5) * 2
                                        o.hpCol = Color3.fromRGB(math.floor(255 - 203 * u2), math.floor(190 + 21 * u2), math.floor(40 + 50 * u2))
                                    end
                                end
                                local hpCol = o.hpCol
                                if d.fill then
                                    d.fill.Visible = S.espChams and S.espFill
                                    if d.fill.Visible then
                                        d.fill.Position = Vector2.new(cx - w / 2, tsp.Y)
                                        d.fill.Size = Vector2.new(w, h)
                                        d.fill.Color = col
                                        d.fill.Transparency = 0.22 * alpha
                                    end
                                end
                                local pad = 2
                                local bx, by = cx - w / 2 - pad, tsp.Y - pad
                                local bw, bh = w + pad * 2, h + pad * 2
                                local cornerMode = S.espBoxStyle == "Corner" and d.corner ~= nil
                                if d.boxOut then
                                    d.boxOut.Visible = S.espChams and not cornerMode and S.espOutline
                                    if d.boxOut.Visible then
                                        d.boxOut.Position = Vector2.new(bx, by)
                                        d.boxOut.Size = Vector2.new(bw, bh)
                                        d.boxOut.Transparency = alpha
                                    end
                                end
                                d.box.Visible = S.espChams and not cornerMode
                                if d.box.Visible then
                                    d.box.Position = Vector2.new(bx, by)
                                    d.box.Size = Vector2.new(bw, bh)
                                    d.box.Color = col
                                    d.box.Transparency = alpha
                                    d.box.Thickness = isTgt and 2 or 1
                                end
                                if d.corner then
                                    local cl = math.min(w, h) * 0.28
                                    local xl, xr = cx - w / 2, cx + w / 2
                                    for i = 1, 8 do
                                        local ln = d.corner[i]
                                        ln.Visible = S.espChams and cornerMode
                                        if ln.Visible then
                                            local fx, fy, tx2, ty2
                                            if i == 1 then fx, fy, tx2, ty2 = xl, tsp.Y, xl + cl, tsp.Y
                                            elseif i == 2 then fx, fy, tx2, ty2 = xr, tsp.Y, xr - cl, tsp.Y
                                            elseif i == 3 then fx, fy, tx2, ty2 = xl, tsp.Y, xl, tsp.Y + cl
                                            elseif i == 4 then fx, fy, tx2, ty2 = xr, tsp.Y, xr, tsp.Y + cl
                                            elseif i == 5 then fx, fy, tx2, ty2 = xl, bsp.Y, xl + cl, bsp.Y
                                            elseif i == 6 then fx, fy, tx2, ty2 = xr, bsp.Y, xr - cl, bsp.Y
                                            elseif i == 7 then fx, fy, tx2, ty2 = xl, bsp.Y, xl, bsp.Y - cl
                                            else fx, fy, tx2, ty2 = xr, bsp.Y, xr, bsp.Y - cl end
                                            ln.From = Vector2.new(fx, fy)
                                            ln.To = Vector2.new(tx2, ty2)
                                            ln.Color = col
                                            ln.Thickness = isTgt and 2 or 1
                                            ln.Transparency = alpha
                                        end
                                    end
                                end
                                if d.hpBg then
                                    d.hpBg.Visible = S.espHealth
                                    if d.hpBg.Visible then
                                        d.hpBg.Position = Vector2.new(bx - 6, by)
                                        d.hpBg.Size = Vector2.new(5, bh)
                                    end
                                end
                                d.hp.Visible = S.espHealth
                                if d.hp.Visible then
                                    d.hp.Position = Vector2.new(bx - 5, by + bh * (1 - frac))
                                    d.hp.Size = Vector2.new(3, bh * frac)
                                    d.hp.Color = hpCol
                                end
                                if d.tracer then
                                    d.tracer.Visible = S.espTracer
                                    if d.tracer.Visible then
                                        d.tracer.From = Vector2.new(vpSz.X / 2, vpSz.Y)
                                        d.tracer.To = Vector2.new(cx, bsp.Y)
                                        d.tracer.Color = col
                                        d.tracer.Transparency = 0.7 * alpha
                                    end
                                end
                                if d.dot then
                                    d.dot.Visible = S.espHeadDot or (isTgt and S.espTargetCol)
                                    if d.dot.Visible then
                                        local headP = o.headPart or PartOf(char, "Head")
                                        local hsp = headP and c:WorldToViewportPoint(headP.Position) or tsp
                                        d.dot.Position = Vector2.new(hsp.X, hsp.Y)
                                        d.dot.Radius = math.clamp(h * 0.09, 2, 9) * ((isTgt and S.espTargetCol) and 1.35 or 1)
                                        d.dot.Color = col
                                        d.dot.Transparency = alpha
                                    end
                                end
                                if d.skel then
                                    local showSkel = S.espSkeleton and R.loadTier < 2 and o.boneParts ~= nil
                                    if showSkel or o.skelVis then
                                    local skC1, skC2, skC3 = col, col, col
                                    local skTh = 1
                                    if showSkel then
                                        local skBase = col
                                        if S.espSkelMode == "Health" then
                                            skBase = hpCol
                                        elseif S.espSkelMode == "Custom" then
                                            skBase = ESP_COLORS[S.espSkelCol] or col
                                        end
                                        if S.espSkelMode ~= "Role" then
                                            if isTgt and S.espTargetCol then skBase = GOLD_COL end
                                            if S.espVisCol and visKnown and not visOk then skBase = DesatCol(skBase) end
                                        end
                                        skC1 = skBase
                                        skC2 = ShadeCol(skBase, 0.84)
                                        skC3 = ShadeCol(skBase, 0.68)
                                        skTh = math.clamp(math.floor(h / 70 + 0.5), 1, 3) * S.espSkelThick
                                        if skTh > 4 then skTh = 4 end
                                        for _, pt in ipairs(o.boneList) do
                                            local sp5, on5 = c:WorldToViewportPoint(pt.Position)
                                            o.projP[pt] = sp5
                                            o.projOn[pt] = on5
                                        end
                                    end
                                    for i = 1, #BONES do
                                        local ln = d.skel[i]
                                        local lo = d.skelOut and d.skelOut[i]
                                        local vis = false
                                        if showSkel then
                                            local bp = o.boneParts[i]
                                            local pa, pb = bp[1], bp[2]
                                            if pa and pb then
                                                local sa, sb = o.projP[pa], o.projP[pb]
                                                if sa and sb and o.projOn[pa] and o.projOn[pb] and sa.Z > 0 and sb.Z > 0 then
                                                    local tier = BONE_TIER[i]
                                                    ln.From = Vector2.new(sa.X, sa.Y)
                                                    ln.To = Vector2.new(sb.X, sb.Y)
                                                    ln.Color = tier == 1 and skC1 or tier == 2 and skC2 or skC3
                                                    ln.Transparency = alpha * (tier == 1 and 1 or tier == 2 and 0.94 or 0.88)
                                                    ln.Thickness = (i == 1) and (skTh + 1) or skTh
                                                    vis = true
                                                    if lo and S.espSkelOutline then
                                                        lo.From = ln.From
                                                        lo.To = ln.To
                                                        lo.Thickness = ln.Thickness + 2
                                                        lo.Transparency = alpha * 0.9
                                                    end
                                                end
                                            end
                                        end
                                        ln.Visible = vis
                                        if lo then lo.Visible = vis and S.espSkelOutline == true end
                                    end
                                    if d.skelJt then
                                        local jvis = showSkel and S.espSkelJoints
                                        for j = 1, 5 do
                                            local jt = d.skelJt[j]
                                            local jv2 = false
                                            if jvis then
                                                local jp = nil
                                                if j == 1 then jp = o.headPart
                                                elseif j == 2 then jp = o.boneParts[5][2]
                                                elseif j == 3 then jp = o.boneParts[8][2]
                                                elseif j == 4 then jp = o.boneParts[11][2]
                                                else jp = o.boneParts[14][2] end
                                                local sp6 = jp and o.projP[jp]
                                                if sp6 and o.projOn[jp] and sp6.Z > 0 then
                                                    jt.Position = Vector2.new(sp6.X, sp6.Y)
                                                    jt.Radius = math.clamp(h * 0.05, 1.5, 5)
                                                    jt.Color = skC1
                                                    jt.Transparency = alpha
                                                    jv2 = true
                                                end
                                            end
                                            jt.Visible = jv2
                                        end
                                    end
                                    o.skelVis = showSkel
                                    end
                                end
                                if d.name then
                                    d.name.Visible = S.espName
                                    if S.espName then
                                        local ns = math.clamp(math.floor(h * 0.13 + 0.5), 11, 14)
                                        if o.nameSize ~= ns then o.nameSize = ns d.name.Size = ns end
                                        d.name.Position = Vector2.new(cx, tsp.Y - 17)
                                        if o.nameKey ~= pcls then
                                            o.nameKey = pcls
                                            d.name.Text = (pcls == "Knife" and "[刀] " or pcls == "Gun" and "[銃] " or "") .. p.DisplayName
                                        end
                                        d.name.Color = col
                                        d.name.Transparency = alpha
                                    end
                                end
                                if d.info then
                                    d.info.Visible = S.espDistance
                                    if S.espDistance then
                                        local isz = math.clamp(math.floor(h * 0.115 + 0.5), 10, 13)
                                        if o.infoSize ~= isz then o.infoSize = isz d.info.Size = isz end
                                        d.info.Position = Vector2.new(cx, bsp.Y + 3)
                                        local dist = math.floor(distW)
                                        local wname = S.espWeaponName and R.className[p] or nil
                                        local ikey = dist * 100000 + math.floor(hum.Health) * 10 + (S.espHealth and 1 or 0)
                                        if o.infoKey ~= ikey or o.infoKeyW ~= wname then
                                            o.infoKey = ikey
                                            o.infoKeyW = wname
                                            local tx = S.espHealth and string.format("%dm  %d", dist, math.floor(hum.Health)) or string.format("%dm", dist)
                                            if wname then tx = tx .. "  " .. wname end
                                            d.info.Text = tx
                                        end
                                        if isTgt and S.espTargetCol then d.info.Color = GOLD_COL
                                        elseif dist < 60 then d.info.Color = Color3.fromRGB(255, 120, 120)
                                        elseif dist < 200 then d.info.Color = Color3.fromRGB(235, 235, 240)
                                        else d.info.Color = Color3.fromRGB(170, 180, 200) end
                                        d.info.Transparency = alpha
                                    end
                                end
                                o.hidden = false
                                show = true
                            end
                        end
                    end
                end
            end
            if o and not show then HideESP(o) end
        end
    end
end
