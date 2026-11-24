local function UpdateStatus()
    local hookOk = R.hookMouse or R.hookRay
    local clsTx = R.myClass == "Knife" and "刀" or R.myClass == "Gun" and "銃" or "素手"
    local stx = (hookOk and "フック有効" or (typeof(hookmetamethod) == "function" and "フック未確認" or "フック不可")) .. "・" .. clsTx
    if R.statusText ~= stx then
        R.statusText = stx
        if R.statusPara then pcall(function() R.statusPara:SetDesc(stx) end) end
    end
    local ftx = string.format("現在 %d FPS", math.floor((R.fpsNow or 0) + 0.5))
    pcall(function()
        if typeof(getfpscap) == "function" then
            local cap = getfpscap()
            if typeof(cap) == "number" and cap > 0 then ftx = ftx .. string.format("（上限 %d）", math.floor(cap)) end
        end
    end)
    if R.fpsText ~= ftx then
        R.fpsText = ftx
        if R.fpsPara then pcall(function() R.fpsPara:SetDesc(ftx) end) end
    end
    if R.fpsHud then
        local hv = S.showFpsHud == true
        if R.fpsHud.Visible ~= hv then R.fpsHud.Visible = hv end
        if hv and R.fpsHud.Text ~= ftx then R.fpsHud.Text = ftx end
    end
end
local function SpinStep(dt)
    if not S.spinBot or R.charDead then return end
    local char = CharOf(LocalPlayer)
    local root = RootOf(char)
    if not char or not root then return end
    R.spinAng = (R.spinAng or 0) + math.rad(S.spinSpeed) * (dt or 0.016)
    local pos = root.Position
    local ang = R.spinAng % (math.pi * 2)
    pcall(function()
        root.CFrame = CFrame.new(pos) * CFrame.Angles(0, ang, 0)
    end)
end
local function TriggerStep()
    if not (S.trigger or S.multiFire) or R.charDead then return end
    if not R.part or not R.target or not R.rawPos then return end
    if S.silent and not RollChance() then return end
    local c = Cam()
    if not c then return end
    local now = os.clock()
    if not S.multiFire and S.instantFire then
        if R.warmP ~= R.target or R.warmTick == nil or (R.tickId or 0) - R.warmTick > 1 then return end
        local charT = CharOf(R.target)
        local humT = HumOf(charT)
        if not charT or not humT or humT.Health <= 0 or R.part.Parent ~= charT or not IsEnemy(R.target) or InHidden(charT) or (S.ffCheck and HasFF(charT)) then return end
        if S.wallCheck and not Visible(R.target, R.part, charT) then return end
    end
    local dist = (R.rawPos - c.CFrame.Position).Magnitude
    local cls = WeaponClass()
    local char = CharOf(LocalPlayer)
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return end
    if not S.multiFire and not S.instantFire and now - (R.targetSince or 0) < S.triggerDelay / 1000 then return end
    local cdFloor = S.instantFire and 10 or 50
    if now - (R.lastTrigger or 0) < math.max(S.triggerCooldown, cdFloor) / 1000 then return end
    local function markFired()
        R.lastTrigger = now
        R.triggerPulse = now
    end
    if cls == "Knife" and dist > S.stabRange then
        if not S.triggerThrow then return end
        if not S.multiFire and dist > S.triggerRange then return end
        if R.throwBackoff and now < R.throwBackoff then return end
        local remote = nil
        pcall(function()
            for _, ch in ipairs(tool:GetChildren()) do
                if ch:IsA("RemoteEvent") and string.find(string.lower(ch.Name), "throw", 1, true) then remote = ch return end
            end
        end)
        if remote then
            markFired()
            pcall(function() remote:FireServer() end)
            return
        end
        local kp = nil
        pcall(function() if typeof(keypress) == "function" then kp = keypress end end)
        if not kp and not VIM then
            R.throwBackoff = now + 1
            return
        end
        markFired()
        local hold = 0.025 + math.random() * 0.02
        if kp then
            pcall(function()
                kp(Enum.KeyCode.E.Value)
                task.delay(hold, function() pcall(function() if typeof(keyrelease) == "function" then keyrelease(Enum.KeyCode.E.Value) end end) end)
            end)
        else
            pcall(function()
                VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.delay(hold, function() pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end) end)
            end)
        end
        return
    end
    if not S.multiFire and dist > S.triggerRange and cls ~= "Knife" then return end
    if not S.multiFire and cls == "Knife" and dist > S.triggerRange then return end
    local hasPress, hasClick = false, false
    if not R.touchOnly then
        pcall(function() hasPress = (typeof(mouse1press) == "function" and typeof(mouse1release) == "function") end)
        pcall(function() hasClick = (typeof(mouse1click) == "function") end)
    end
    markFired()
    pcall(function() tool:Activate() end)
    if R.touchOnly then
        local ap = R.aimPoint
        local remote = nil
        pcall(function()
            for _, ch in ipairs(tool:GetDescendants()) do
                if ch:IsA("RemoteEvent") then
                    local nm = string.lower(ch.Name)
                    if string.find(nm, "shoot", 1, true) or string.find(nm, "fire", 1, true) then remote = ch return end
                end
            end
        end)
        if remote then pcall(function() remote:FireServer() end) end
        local sent = false
        if VIM then
            pcall(function()
                local bs = Enum.UserInputState.Begin.Value
                VIM:SendTouchEvent(977001, bs, ap.X, ap.Y)
                sent = true
            end)
            pcall(function()
                local bs = Enum.UserInputState.Begin.Value
                VIM:SendTouchEvent(977001, ap.X, ap.Y, bs)
                sent = true
            end)
            if sent then
                task.delay(0.03, function()
                    pcall(function() VIM:SendTouchEvent(977001, Enum.UserInputState.End.Value, ap.X, ap.Y) end)
                    pcall(function() VIM:SendTouchEvent(977001, ap.X, ap.Y, Enum.UserInputState.End.Value) end)
                end)
            end
        end
        if not sent and VIM then
            pcall(function()
                VIM:SendMouseButtonEvent(ap.X, ap.Y, 0, true, game, 0)
                task.delay(0.03, function() pcall(function() VIM:SendMouseButtonEvent(ap.X, ap.Y, 0, false, game, 0) end) end)
            end)
        end
        task.delay(0.02, RestoreTouch)
    elseif hasPress then
        pcall(function()
            mouse1press()
            task.delay(0.03, function() pcall(mouse1release) end)
        end)
    elseif hasClick then
        pcall(mouse1click)
    elseif VIM then
        local ap = R.aimPoint
        pcall(function()
            VIM:SendMouseButtonEvent(ap.X, ap.Y, 0, true, game, 0)
            task.delay(0.03, function() pcall(function() VIM:SendMouseButtonEvent(ap.X, ap.Y, 0, false, game, 0) end) end)
        end)
    end
end
local function PulseTool(tool)
    if not tool then return end
    local okT = false
    pcall(function() okT = tool:IsA("Tool") end)
    if not okT then return end
    if not R.pulsedTools then R.pulsedTools = {} end
    if R.pulsedTools[tool] then return end
    R.pulsedTools[tool] = true
    pcall(function()
        tool.Activated:Connect(function()
            R.triggerPulse = os.clock()
        end)
    end)
end
local DiedConn = nil
local function BindLocalCharacter(char)
    R.target, R.part, R.pos, R.rawPos = nil, nil, nil, nil
    VisFilterChar = nil
    if DiedConn then pcall(function() DiedConn:Disconnect() end) DiedConn = nil end
    if R.actChildConn then pcall(function() R.actChildConn:Disconnect() end) R.actChildConn = nil end
    R.pulsedTools = {}
    pcall(function()
        for _, ch in ipairs(char:GetChildren()) do PulseTool(ch) end
        R.actChildConn = char.ChildAdded:Connect(function(ch) PulseTool(ch) end)
    end)
    local hum = HumOf(char)
    if hum then
        R.charDead = hum.Health <= 0
        DiedConn = hum.Died:Connect(function()
            R.charDead = true
            R.target, R.part, R.pos, R.rawPos = nil, nil, nil, nil
        end)
    else
        R.charDead = true
        task.spawn(function()
            local h = nil
            pcall(function() h = char:WaitForChild("Humanoid", 5) end)
            if h and not R.dead and CharOf(LocalPlayer) == char then BindLocalCharacter(char) end
        end)
    end
end
pcall(function() R.touchOnly = UserInputService.TouchEnabled end)
pcall(function()
    Conn(UserInputService.LastInputTypeChanged:Connect(function(t)
        if R.touchOnly and t ~= Enum.UserInputType.Touch then RestoreTouch() end
    end))
end)
Conn(RunService.RenderStepped:Connect(function(dt)
    if R.dead then return end
    R.tickId = (R.tickId or 0) + 1
    if dt and dt > 0 and dt < 0.25 then R.dtEma = R.dtEma * 0.95 + dt * 0.05 end
    if dt and dt > 0.001 then local fi = 1 / dt if fi < 5000 then R.fpsNow = (R.fpsNow or 60) * 0.95 + fi * 0.05 end end
    if R.dtEma > 0.028 then R.loadTier = 2 elseif R.dtEma > 0.02 then R.loadTier = 1 else R.loadTier = 0 end
    R.visTtl = 0.1 + R.loadTier * 0.05
    R.rayMax = R.loadTier == 2 and 2 or 3
    R.aimPoint = AimPoint()
    if os.clock() > (R.errPause or 0) then
        local okA, okB = true, true
        if S.silent or S.trigger or S.showLine or S.multiFire then okA = pcall(SelectTarget) end
        if okA and not R.target and (S.silent or S.multiFire) and IsFiring() then pcall(FireAcquire) end
        okB = pcall(TriggerStep)
        if okA and okB then
            R.errStreak = 0
        else
            R.errStreak = (R.errStreak or 0) + 1
            if R.errStreak > 30 then
                R.errPause = os.clock() + 2
                R.errStreak = 0
            end
        end
    end
    pcall(SpinStep, dt)
    R.espFrame = R.espFrame + 1
    local espEvery = R.loadTier == 2 and 8 or (R.loadTier == 1 and 3 or 2)
    if R.espFrame % espEvery == 0 then pcall(RefreshESP) end
    local c = Cam()
    R.camObj = c
    FovRing.Visible = S.showFov and S.silent
    if FovRing.Visible then
        local effFov = S.fov * (R.part and 1.4 or 1)
        if R.ringX ~= R.aimPoint.X or R.ringY ~= R.aimPoint.Y or R.ringF ~= effFov then
            R.ringX, R.ringY, R.ringF = R.aimPoint.X, R.aimPoint.Y, effFov
            FovRing.Position = UDim2.new(0, R.aimPoint.X, 0, R.aimPoint.Y)
            FovRing.Size = UDim2.new(0, effFov * 2, 0, effFov * 2)
        end
        local wantCol = R.part and R.colGreen or R.colWhite
        if R.ringCol ~= wantCol then
            R.ringCol = wantCol
            FovStroke.Color = wantCol
        end
    end
    if S.showLine and R.part and R.pos and c then
        local sp, on = c:WorldToViewportPoint(R.pos)
        if on then
            local from = R.aimPoint
            local to = Vector2.new(sp.X, sp.Y)
            local diff = to - from
            LineF.Visible = true
            LineF.Position = UDim2.new(0, from.X, 0, from.Y)
            LineF.Size = UDim2.new(0, diff.Magnitude, 0, 1)
            LineF.Rotation = math.deg(math.atan2(diff.Y, diff.X))
        else
            LineF.Visible = false
        end
    else
        LineF.Visible = false
    end
end))
task.spawn(function()
    local tick = 0
    while not R.dead do
        tick = tick + 1
        UpdateStatus()
        pcall(function() R.touchUi = UserInputService.TouchEnabled end)
        if R.touchOnly then
            local lt = nil
            pcall(function() lt = UserInputService:GetLastInputType() end)
            if lt ~= nil and lt ~= Enum.UserInputType.Touch then
                R.guardStuck = (R.guardStuck or 0) + 1
                if R.guardStuck >= 4 then
                    R.guardStuck = 2
                    task.spawn(function()
                        local pm2 = ControlsModule()
                        if pm2 then
                            pcall(function() pm2:Disable() end)
                            task.wait(0.05)
                            local okE2 = pcall(function() pm2:Enable() end)
                            if not okE2 then R.pmCache = nil end
                        end
                        R.restoreAt = nil
                        RestoreTouch(true)
                    end)
                elseif R.guardStuck == 2 then
                    RestoreTouch(true)
                else
                    RestoreTouch()
                end
            else
                R.guardStuck = 0
            end
        end
        if R.inputDown and os.clock() - (R.inputStamp or 0) > 3 then
            R.inputs = {}
            R.inputDown = false
        end
        if tick % 3 == 0 then RefreshClasses() end
        task.wait(0.15)
    end
end)
local function WatchPlayer(p)
    if p == LocalPlayer then return end
    CharConn(p, p.CharacterAdded:Connect(function()
        R.classCache[p] = nil
        R.velCache[p] = nil
        R.visCache[p] = nil
        R.bboxCache[p] = nil
        R.partsCache[p] = nil
        R.teamCache[p] = nil
        R.classTool[p] = nil
        R.className[p] = nil
        if R.jitter then R.jitter[p] = nil end
    end))
end
for _, p in ipairs(Players:GetPlayers()) do WatchPlayer(p) end
Conn(Players.PlayerAdded:Connect(function(p) R.playerList = nil WatchPlayer(p) end))
Conn(Players.PlayerRemoving:Connect(function(p)
    ClearESP(p)
    R.classCache[p] = nil
    R.velCache[p] = nil
    R.visCache[p] = nil
    R.bboxCache[p] = nil
    R.partsCache[p] = nil
    R.teamCache[p] = nil
    R.classTool[p] = nil
    R.className[p] = nil
    if R.jitter then R.jitter[p] = nil end
    if R.multiCurP == p then R.multiCurP = nil end
    R.playerList = nil
    local t = R.charConns[p]
    if t then
        for _, cn in ipairs(t) do pcall(function() cn:Disconnect() end) end
        R.charConns[p] = nil
    end
    if R.target == p then R.target, R.part, R.pos, R.rawPos = nil, nil, nil, nil end
end))
Conn(LocalPlayer.CharacterAdded:Connect(function(char)
    task.spawn(function()
        task.wait(0.1)
        if not R.dead then BindLocalCharacter(char) end
    end)
end))
local function Unload()
    if R.dead then return end
    R.dead = true
    if CTL.Key then Env[CTL.Key] = nil end
    S.silent = false
    S.esp = false
    S.fpsBoost = false
    S.fpsUnlock = false
    pcall(FpsApply)
    pcall(FpsCapApply)
    for p in pairs(R.espObjs) do ClearESP(p) end
    for _, t in pairs(R.charConns) do
        for _, cn in ipairs(t) do pcall(function() cn:Disconnect() end) end
    end
    R.charConns = {}
    if DiedConn then pcall(function() DiedConn:Disconnect() end) DiedConn = nil end
    if R.actChildConn then pcall(function() R.actChildConn:Disconnect() end) R.actChildConn = nil end
    for _, c in ipairs(R.conns) do pcall(function() c:Disconnect() end) end
    if R.fpsConn then pcall(function() R.fpsConn:Disconnect() end) R.fpsConn = nil end
    pcall(function() if R.windWindow then R.windWindow:Destroy() end end)
    pcall(function() Overlay:Destroy() end)
end
CTL.Unload = Unload
LoadConfig(true)
pcall(BuildGui)
if S.silent then InstallHooks() end
if S.fpsBoost then FpsApply() end
if S.fpsUnlock then FpsCapApply() end
RefreshClasses()
do
    local char = CharOf(LocalPlayer)
    if char then BindLocalCharacter(char) end
end
UpdateStatus()
Notify("読み込み完了")
