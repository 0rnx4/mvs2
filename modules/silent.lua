local function IsFiring()
    if os.clock() - (R.triggerPulse or 0) < 0.3 then return true end
    if R.inputDown then return true end
    local ok1, r1 = pcall(function() return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end)
    if ok1 then return r1 == true end
    local ok2, r2 = pcall(function() return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end)
    if ok2 and r2 then return true end
    return false
end
local function BendAllowedRaw()
    if S.maxBend and S.maxBend > 0 and R.pos then
        local c = Cam()
        if c then
            local fwd = c.CFrame.LookVector
            local dir = R.pos - c.CFrame.Position
            if dir.Magnitude > 0.01 then
                local ang = math.deg(math.acos(math.clamp(fwd:Dot(dir.Unit), -1, 1)))
                if ang > S.maxBend then return false end
            end
        end
    end
    return true
end
local function BendAllowed()
    local nowB = os.clock()
    if R.bendAt and nowB - R.bendAt < 0.008 then return R.bendVal end
    local v = BendAllowedRaw()
    R.bendAt, R.bendVal = nowB, v
    return v
end
local function BendPos()
    local p = R.pos
    if not p then return nil end
    local v = R.predVel
    if v and R.posAt then
        local dt = os.clock() - R.posAt
        if dt > 0 and dt < 0.06 then return p + v * dt end
    end
    return p
end
local function SilentReady()
    if R.dead or R.charDead or not S.silent then return false end
    if not R.part or not R.pos then return false end
    if S.fireGate and not IsFiring() then return false end
    if not BendAllowed() then return false end
    return RollChance()
end
local function OriginNear(origin)
    local c = Cam()
    if c and (origin - c.CFrame.Position).Magnitude <= 30 then return true end
    local lc = CharOf(LocalPlayer)
    local root = lc and RootOf(lc)
    if root and (origin - root.Position).Magnitude <= 30 then return true end
    return false
end
local function ControlsModule()
    if R.pmCache then return R.pmCache end
    local ok, pm = pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        local mod = ps and ps:FindFirstChild("PlayerModule")
        if not mod then return nil end
        local m = require(mod)
        return m and m:GetControls()
    end)
    if ok and pm then R.pmCache = pm return pm end
    return nil
end
local function CornerTouch()
    if not VIM then return end
    local id = 91237
    pcall(function()
        local b = Enum.UserInputState.Begin.Value
        VIM:SendTouchEvent(id, b, 3, 3)
        VIM:SendTouchEvent(id, 3, 3, b)
    end)
    pcall(function()
        local e = Enum.UserInputState.End.Value
        VIM:SendTouchEvent(id, e, 3, 3)
        VIM:SendTouchEvent(id, 3, 3, e)
    end)
end
local function RestoreTouch(full)
    if not R.touchOnly or R.dead then return end
    local now = os.clock()
    if R.restoreAt and now - R.restoreAt < 0.03 then return end
    R.restoreAt = now
    local cache = R.tgCache
    if not cache or now - cache.at > 1 or (cache.tg and not cache.tg.Parent) then
        cache = { at = now }
        R.tgCache = cache
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                cache.tg = pg:FindFirstChild("TouchGui")
                cache.tcf = cache.tg and cache.tg:FindFirstChild("TouchControlFrame")
                cache.controls = pg:FindFirstChild("Controls")
                cache.mob = cache.controls and cache.controls:FindFirstChild("Mobile")
            end
        end)
    end
    pcall(function()
        local tg = cache.tg
        if tg then
            if tg:IsA("ScreenGui") and not tg.Enabled then tg.Enabled = true end
            local tcf = cache.tcf
            if tcf and tcf:IsA("GuiObject") and not tcf.Visible then tcf.Visible = true end
        end
        local controls = cache.controls
        if controls then
            if controls:IsA("ScreenGui") and not controls.Enabled then controls.Enabled = true end
            local mob = cache.mob
            if mob and mob:IsA("GuiObject") and not mob.Visible then mob.Visible = true end
        end
    end)
    if full then
        local pm = ControlsModule()
        if pm then
            local okE = pcall(function() pm:Enable() end)
            if not okE then R.pmCache = nil end
        end
    end
    CornerTouch()
end
local function Wrap(fn)
    if typeof(newcclosure) == "function" then
        local ok, r = pcall(newcclosure, fn)
        if ok and r then return r end
    end
    return fn
end
local function CallerIsGame()
    local nowG = os.clock()
    if R.callerAt and nowG - R.callerAt < 0.008 then return R.callerVal end
    local v = true
    if typeof(checkcaller) == "function" then
        local ok, r = pcall(checkcaller)
        if ok then v = not r end
    end
    R.callerAt, R.callerVal = nowG, v
    return v
end
local function InstallHooks()
    if R.hookMouse and R.hookRay then return end
    if typeof(hookmetamethod) ~= "function" then return end
    R.hasGnc = (typeof(getnamecallmethod) == "function")
    if S.silentMouse and Mouse and not R.hookMouse then
        local ok = pcall(function()
            local oldIndex
            oldIndex = hookmetamethod(game, "__index", Wrap(function(self, key)
                if self ~= Mouse or R.dead or not S.silent or not S.silentMouse then return oldIndex(self, key) end
                local isAimKey = (key == "Hit" or key == "Target" or key == "UnitRay")
                if not isAimKey or not CallerIsGame() or not SilentReady() then
                    return oldIndex(self, key)
                end
                if key == "Hit" then
                    local orig = oldIndex(self, key)
                    local bp = BendPos() or R.pos
                    if typeof(orig) == "CFrame" then
                        return CFrame.new(bp) * (orig - orig.Position)
                    end
                    return CFrame.new(bp)
                elseif key == "Target" then
                    return R.part
                elseif key == "UnitRay" then
                    local orig = oldIndex(self, key)
                    if typeof(orig) == "Ray" then
                        local dir = (BendPos() or R.pos) - orig.Origin
                        if dir.Magnitude > 0.01 then return Ray.new(orig.Origin, dir.Unit) end
                    end
                    local c = Cam()
                    if c then
                        local dir = (BendPos() or R.pos) - c.CFrame.Position
                        if dir.Magnitude > 0.01 then return Ray.new(c.CFrame.Position, dir.Unit) end
                    end
                    return oldIndex(self, key)
                end
                return oldIndex(self, key)
            end))
            R.hookMouse = true
        end)
        if not ok then R.hookMouse = false end
    end
    if (S.silentRay or S.silentCamRay) and not R.hookRay then
    local ok2 = pcall(function()
        local oldName
        oldName = hookmetamethod(game, "__namecall", Wrap(function(self, ...)
            if R.dead or R.selfRay or not S.silent then return oldName(self, ...) end
            local isWs = (self == Workspace)
            local isCam = (not isWs) and (self == R.camObj)
            if not isWs and not isCam then return oldName(self, ...) end
            if isWs and not S.silentRay then return oldName(self, ...) end
            if isCam and not S.silentCamRay then return oldName(self, ...) end
            local method = nil
            if R.hasGnc then
                local okM, m = pcall(getnamecallmethod)
                if okM then method = m end
            end
            if not method then return oldName(self, ...) end
            local isWsRay = isWs and (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist")
            local isCamRay = isCam and (method == "ScreenPointToRay" or method == "ViewportPointToRay" or method == "ScreenPointToRayWithoutInset" or method == "ViewportPointToRayWithoutInset")
            if not isWsRay and not isCamRay then return oldName(self, ...) end
            if not CallerIsGame() or not SilentReady() then return oldName(self, ...) end
            if isCamRay then
                local ray = oldName(self, ...)
                if typeof(ray) == "Ray" then
                    local dir = (BendPos() or R.pos) - ray.Origin
                    if dir.Magnitude > 0.01 then return Ray.new(ray.Origin, dir.Unit * ray.Direction.Magnitude) end
                end
                return ray
            end
            local args = { ... }
            local nargs = select("#", ...)
            if isWsRay then
                if method == "Raycast" and typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" and OriginNear(args[1]) then
                    local len = args[2].Magnitude
                    local dir = (BendPos() or R.pos) - args[1]
                    if dir.Magnitude > 0 then args[2] = dir.Unit * len end
                    return oldName(self, table.unpack(args, 1, nargs))
                elseif method ~= "Raycast" and typeof(args[1]) == "Ray" and OriginNear(args[1].Origin) then
                    local r = args[1]
                    local dir = (BendPos() or R.pos) - r.Origin
                    if dir.Magnitude > 0 then dir = dir.Unit * r.Direction.Magnitude end
                    args[1] = Ray.new(r.Origin, dir)
                    return oldName(self, table.unpack(args, 1, nargs))
                end
                return oldName(self, ...)
            end
            return oldName(self, ...)
        end))
        R.hookRay = true
    end)
    if not ok2 then R.hookRay = false end
    end
    R.hooksDone = (R.hookMouse or R.hookRay) == true
end
