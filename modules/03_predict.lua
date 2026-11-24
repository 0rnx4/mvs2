local GRAV = 196.2
local function VelTrack(p, root)
    local now = os.clock()
    local pos = root.Position
    local raw = Vector3.new(0, 0, 0)
    pcall(function() raw = root.AssemblyLinearVelocity end)
    local e = R.velCache[p]
    if not e or e.root ~= root then
        e = { root = root, buf = {}, vel = raw, acc = Vector3.new(0, 0, 0) }
        R.velCache[p] = e
    end
    local buf = e.buf
    local last = buf[#buf]
    if last and (pos - Vector3.new(last.x, last.y, last.z)).Magnitude > 45 then
        e.buf = {}
        buf = e.buf
        last = nil
        e.turnAt, e.pvx, e.pvz, e.fx, e.fy, e.fz, e.resid, e.cacheTick, e.cacheLast = nil, nil, nil, nil, nil, nil, nil, nil, nil
    end
    if e.cacheTick ~= nil and e.cacheTick == (R.tickId or 0) and last ~= nil and last == e.cacheLast and now - last.t < 0.012 then
        return e.vel, e.acc, buf
    end
    if not last or now - last.t >= 0.012 then
        buf[#buf + 1] = { t = now, x = pos.X, y = pos.Y, z = pos.Z }
        if #buf > 28 then table.remove(buf, 1) end
    end
    if #buf < 3 then
        e.vel, e.acc = raw, Vector3.new(0, 0, 0)
        e.fx, e.fy, e.fz, e.resid = nil, nil, nil, nil
        return raw, e.acc, buf
    end
    local winLen = 0.35
    if e.turnAt and now - e.turnAt < 0.22 then winLen = math.max(0.1, now - e.turnAt + 0.06) end
    local win = now - winLen
    local useW = S.fitRecent and R.loadTier < 2
    local s0, s1, s2, s3, s4 = 0, 0, 0, 0, 0
    local tx0, tx1, tx2 = 0, 0, 0
    local ty0, ty1, ty2 = 0, 0, 0
    local tz0, tz1, tz2 = 0, 0, 0
    local cnt = 0
    for i = 1, #buf do
        local sm = buf[i]
        if sm.t >= win then
            local tau = sm.t - now
            local w = 1
            if useW then w = math.exp(tau / 0.13) end
            local t2 = tau * tau
            s0 = s0 + w s1 = s1 + w * tau s2 = s2 + w * t2 s3 = s3 + w * t2 * tau s4 = s4 + w * t2 * t2
            tx0 = tx0 + w * sm.x tx1 = tx1 + w * sm.x * tau tx2 = tx2 + w * sm.x * t2
            ty0 = ty0 + w * sm.y ty1 = ty1 + w * sm.y * tau ty2 = ty2 + w * sm.y * t2
            tz0 = tz0 + w * sm.z tz1 = tz1 + w * sm.z * tau tz2 = tz2 + w * sm.z * t2
            cnt = cnt + 1
        end
    end
    if cnt < 3 then
        e.vel, e.acc = raw, Vector3.new(0, 0, 0)
        e.fx, e.fy, e.fz, e.resid = nil, nil, nil, nil
        return raw, e.acc, buf
    end
    local vx, vy, vz, ax, ay, az = nil, nil, nil, 0, 0, 0
    local c0x, c0y, c0z = nil, nil, nil
    local det = s0 * (s2 * s4 - s3 * s3) - s1 * (s1 * s4 - s3 * s2) + s2 * (s1 * s3 - s2 * s2)
    if cnt >= 5 and math.abs(det) > 1e-9 then
        local function coef(t0, t1, t2)
            local da = t0 * (s2 * s4 - s3 * s3) - s1 * (t1 * s4 - s3 * t2) + s2 * (t1 * s3 - t2 * s2)
            local db = s0 * (t1 * s4 - s3 * t2) - t0 * (s1 * s4 - s3 * s2) + s2 * (s1 * t2 - t1 * s2)
            local dc = s0 * (s2 * t2 - t1 * s3) - s1 * (s1 * t2 - t1 * s2) + t0 * (s1 * s3 - s2 * s2)
            return da / det, db / det, 2 * dc / det
        end
        c0x, vx, ax = coef(tx0, tx1, tx2)
        c0y, vy, ay = coef(ty0, ty1, ty2)
        c0z, vz, az = coef(tz0, tz1, tz2)
    else
        local den = s0 * s2 - s1 * s1
        if math.abs(den) > 1e-9 then
            vx = (s0 * tx1 - s1 * tx0) / den
            vy = (s0 * ty1 - s1 * ty0) / den
            vz = (s0 * tz1 - s1 * tz0) / den
        end
    end
    if not vx or vx ~= vx or vy ~= vy or vz ~= vz then
        e.vel, e.acc = raw, Vector3.new(0, 0, 0)
        e.fx, e.fy, e.fz, e.resid = nil, nil, nil, nil
        return raw, e.acc, buf
    end
    if c0x then e.fx, e.fy, e.fz = c0x, c0y, c0z else e.fx, e.fy, e.fz = nil, nil, nil end
    if useW and c0x then
        local resSum, resW = 0, 0
        for i = 1, #buf do
            local sm = buf[i]
            if sm.t >= win then
                local tau = sm.t - now
                local w = math.exp(tau / 0.13)
                local px = c0x + vx * tau + 0.5 * ax * tau * tau
                local py = c0y + vy * tau + 0.5 * ay * tau * tau
                local pz = c0z + vz * tau + 0.5 * az * tau * tau
                local dx, dy, dz = sm.x - px, sm.y - py, sm.z - pz
                resSum = resSum + w * (dx * dx + dy * dy + dz * dz)
                resW = resW + w
            end
        end
        if resW > 0 then e.resid = math.sqrt(resSum / resW) end
    else
        e.resid = nil
    end
    local lastSm = buf[#buf]
    if S.resolver and e.pvx and lastSm and e.fitT ~= lastSm.t then
        local pm = math.sqrt(e.pvx * e.pvx + e.pvz * e.pvz)
        local cm = math.sqrt(vx * vx + vz * vz)
        if pm > 4 and cm > 4 and (e.pvx * vx + e.pvz * vz) / (pm * cm) < -0.2 then e.turnAt = now end
    end
    if lastSm and e.fitT ~= lastSm.t then
        e.fitT = lastSm.t
        e.pvx, e.pvz = vx, vz
    end
    local fitW = 0.8
    if S.resolver and (Vector3.new(vx, vy, vz) - raw).Magnitude > 120 then fitW = 0.45 end
    local vel = Vector3.new(vx, vy, vz) * fitW + raw * (1 - fitW)
    local acc = Vector3.new(ax, ay, az)
    if vel.Magnitude > 320 then vel = raw end
    if acc.Magnitude > 400 then acc = acc.Unit * 400 end
    if S.resolver then
        local rd = vel - e.vel
        if rd.Magnitude > 90 then vel = e.vel + rd * 0.45 end
    end
    if vel.Magnitude < 0.75 then vel = Vector3.new(0, 0, 0) end
    e.vel, e.acc = vel, acc
    e.cacheTick, e.cacheLast = R.tickId or 0, buf[#buf]
    return vel, acc, buf
end
local function JitterVec(p, part)
    if not (S.aimJitter and S.aimJitter > 0) then return nil end
    if not R.jitter then R.jitter = {} end
    local je = R.jitter[p]
    local jnow = os.clock()
    if not je or je.part ~= part or jnow - je.at > 0.12 then
        local m = part.Size.Magnitude * 0.5 * (S.aimJitter / 100)
        je = { at = jnow, part = part, vec = Vector3.new((math.random() * 2 - 1) * m, (math.random() * 2 - 1) * m * 0.6, (math.random() * 2 - 1) * m) }
        R.jitter[p] = je
    end
    return je.vec
end
local function IsAirborne(char)
    local hum = HumOf(char)
    if not hum then return false end
    local air = false
    pcall(function()
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping then air = true end
    end)
    return air
end
local function Predict(p, part, char)
    local pos = part.Position
    if not S.prediction then
        R.predVel = nil
        local jv0 = JitterVec(p, part)
        if jv0 then return pos + jv0 end
        return pos
    end
    local root = RootOf(char) or part
    local vel, acc, buf = VelTrack(p, root)
    local veA = R.velCache[p]
    if buf and #buf >= 8 then
        local camS = Cam()
        if camS then
            local axisS = pos - camS.CFrame.Position
            axisS = Vector3.new(axisS.X, 0, axisS.Z)
            if axisS.Magnitude > 1 then
                axisS = axisS.Unit
                local lat = Vector3.new(-axisS.Z, 0, axisS.X)
                local flips, prevS = 0, 0
                for i = 2, #buf do
                    local sa, sb = buf[i - 1], buf[i]
                    local dt2 = sb.t - sa.t
                    if dt2 > 0.001 then
                        local sv = ((sb.x - sa.x) * lat.X + (sb.z - sa.z) * lat.Z) / dt2
                        local sg = (sv > 2 and 1) or (sv < -2 and -1) or 0
                        if sg ~= 0 then
                            if prevS ~= 0 and sg ~= prevS then flips = flips + 1 end
                            prevS = sg
                        end
                    end
                end
                if flips >= 2 then
                    local latV = vel.X * lat.X + vel.Z * lat.Z
                    vel = vel - lat * (latV * 0.65)
                    local latA = acc.X * lat.X + acc.Z * lat.Z
                    acc = acc - lat * (latA * 0.7)
                end
            end
        end
    end
    local t = S.predAmount
    if S.pingComp then
        local pm = PingMs()
        R.pingEma = R.pingEma and (R.pingEma * 0.65 + pm * 0.35) or pm
        t = t + (R.pingEma / 1000) * 0.5
        t = t + math.min(R.dtEma or 0.016, 0.033)
    end
    local cls = WeaponClass()
    local flyT = 0
    if cls == "Knife" then
        local lc = CharOf(LocalPlayer)
        local lroot = lc and RootOf(lc)
        local origin = lroot and lroot.Position or pos
        local spd = S.knifeSpeed
        local ltool = lc and lc:FindFirstChildOfClass("Tool")
        if R.tsTool ~= ltool then
            R.tsTool = ltool
            R.tsVal = nil
            if ltool then
                pcall(function()
                    local a = ltool:GetAttribute("ThrowSpeed")
                    if typeof(a) == "number" and a >= 20 then R.tsVal = a end
                end)
            end
        end
        if R.tsVal then spd = R.tsVal end
        local dist = (pos - origin).Magnitude
        flyT = dist / math.max(spd, 20)
        local guess = pos + vel * flyT
        flyT = (guess - origin).Magnitude / math.max(spd, 20)
        t = t + flyT
        if t > 3.0 then t = 3.0 end
    else
        t = t + S.gunTravel
        if t > 0.5 then t = 0.5 end
    end
    local conf = 1
    if veA and veA.resid and S.fitRecent and R.loadTier < 2 then
        conf = math.clamp(1.15 - veA.resid * 0.55, 0.55, 1)
    end
    local lead = vel * (t * (0.35 + 0.65 * conf)) + acc * (0.5 * t * t * 0.25 * conf)
    local cap = (cls == "Knife") and 80 or 28
    if lead.Magnitude > cap then lead = lead.Unit * cap end
    local basePos = pos
    if veA and veA.fx and S.fitRecent and R.loadTier < 2 then
        local rp = root.Position
        basePos = Vector3.new(veA.fx + (pos.X - rp.X), veA.fy + (pos.Y - rp.Y), veA.fz + (pos.Z - rp.Z))
    end
    local out = basePos + lead
    if IsAirborne(char) then
        local corrY = -0.5 * GRAV * t * t - acc.Y * (0.5 * t * t * 0.25 * conf)
        if corrY < -80 then corrY = -80 elseif corrY > 0 then corrY = 0 end
        out = out + Vector3.new(0, corrY, 0)
    end
    R.predVel = vel + acc * (t * conf)
    if cls == "Knife" and flyT > 0.02 then
        out = out + Vector3.new(0, 0.5 * GRAV * flyT * flyT * (S.knifeDrop / 100), 0)
    end
    local jv = JitterVec(p, part)
    if jv then
        if S.partSurf and R.loadTier < 2 then
            local cf = part.CFrame
            local rv, uv, lv = cf.RightVector, cf.UpVector, cf.LookVector
            local lx = math.clamp(jv:Dot(rv), -part.Size.X * 0.5, part.Size.X * 0.5)
            local ly = math.clamp(jv:Dot(uv), -part.Size.Y * 0.5, part.Size.Y * 0.5)
            local lz = math.clamp(jv:Dot(lv), -part.Size.Z * 0.5, part.Size.Z * 0.5)
            out = out + rv * lx + uv * ly + lv * lz
        else
            out = out + jv
        end
    end
    return out
end
