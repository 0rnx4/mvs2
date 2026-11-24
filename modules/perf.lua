local function FpsCharSet()
    local now = os.clock()
    if not R.fpsCharSet or now - (R.fpsCharAt or 0) > 2 then
        R.fpsCharAt = now
        local t = {}
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then t[p.Character] = true end
            end
        end)
        R.fpsCharSet = t
    end
    return R.fpsCharSet
end
local function FpsIsCharPart(d)
    local set = FpsCharSet()
    local node = d
    for _ = 1, 8 do
        node = node and node.Parent
        if not node then return false end
        if set[node] then return true end
    end
    return false
end
local function FpsTouch(d, ultra)
    local ok, cls = pcall(function() return d.ClassName end)
    if not ok or not cls then return end
    if cls == "ParticleEmitter" or cls == "Trail" or cls == "Beam" or cls == "Fire" or cls == "Smoke" or cls == "Sparkles" then
        if not R.fpsOrig[d] then
            local en = true
            pcall(function() en = d.Enabled end)
            R.fpsOrig[d] = { k = "fx", e = en }
        end
        pcall(function() d.Enabled = false end)
    elseif cls == "Decal" or cls == "Texture" then
        if not R.fpsOrig[d] then
            local tr = 0
            pcall(function() tr = d.Transparency end)
            R.fpsOrig[d] = { k = "dc", t = tr }
        end
        pcall(function() d.Transparency = 1 end)
    elseif ultra then
        local isPart = false
        pcall(function() isPart = d:IsA("BasePart") end)
        if isPart and not FpsIsCharPart(d) then
            if not R.fpsOrig[d] then
                local rec = nil
                pcall(function() rec = { k = "pt", m = d.Material, r = d.Reflectance } end)
                if rec then R.fpsOrig[d] = rec end
            end
            pcall(function()
                d.Material = Enum.Material.SmoothPlastic
                d.Reflectance = 0
            end)
        end
    end
end
local function FpsRestoreKind(kind)
    if not R.fpsOrig then return end
    for d, o in pairs(R.fpsOrig) do
        if o.k == kind then
            if kind == "fx" then pcall(function() d.Enabled = o.e end)
            elseif kind == "dc" then pcall(function() d.Transparency = o.t end)
            elseif kind == "pt" then pcall(function() d.Material = o.m d.Reflectance = o.r end) end
            R.fpsOrig[d] = nil
        end
    end
end
local function FpsRestoreAll()
    FpsRestoreKind("fx")
    FpsRestoreKind("dc")
    FpsRestoreKind("pt")
end
local function FpsApply()
    local on = S.fpsBoost
    pcall(function()
        local L = game:GetService("Lighting")
        if R.fpsLit == nil then
            local fx = {}
            for _, ch in ipairs(L:GetChildren()) do
                if ch:IsA("PostEffect") then fx[ch] = ch.Enabled end
            end
            R.fpsLit = { gs = L.GlobalShadows, fog = L.FogEnd, fx = fx }
        end
        for _, ch in ipairs(L:GetChildren()) do
            if ch:IsA("PostEffect") and R.fpsLit.fx[ch] == nil then
                local en2 = true
                pcall(function() en2 = ch.Enabled end)
                R.fpsLit.fx[ch] = en2
            end
        end
        L.GlobalShadows = on and false or R.fpsLit.gs
        if on then L.FogEnd = 100000 else L.FogEnd = R.fpsLit.fog end
        for fxo, en in pairs(R.fpsLit.fx) do pcall(function() fxo.Enabled = on and false or en end) end
    end)
    pcall(function()
        local T = Workspace.Terrain
        if T then
            if R.fpsTer == nil then R.fpsTer = { wr = T.WaterReflectivity, ws = T.WaterWaveSize, wsp = T.WaterWaveSpeed, dec = T.Decoration } end
            if on then
                T.WaterReflectivity = 0
                T.WaterWaveSize = 0
                T.WaterWaveSpeed = 0
                T.Decoration = false
            else
                T.WaterReflectivity = R.fpsTer.wr
                T.WaterWaveSize = R.fpsTer.ws
                T.WaterWaveSpeed = R.fpsTer.wsp
                T.Decoration = R.fpsTer.dec
            end
        end
    end)
    pcall(function()
        if on then
            if R.fpsQual == nil then R.fpsQual = settings().Rendering.QualityLevel end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        elseif R.fpsQual ~= nil then
            settings().Rendering.QualityLevel = R.fpsQual
        end
    end)
    if on then
        if not R.fpsOrig then R.fpsOrig = setmetatable({}, { __mode = "k" }) end
        for _, d in ipairs(Workspace:GetDescendants()) do pcall(FpsTouch, d, S.fpsUltra) end
        if not S.fpsUltra then FpsRestoreKind("pt") end
        if not R.fpsConn then
            R.fpsConn = Workspace.DescendantAdded:Connect(function(d)
                if S.fpsBoost and not R.dead then pcall(FpsTouch, d, S.fpsUltra) end
            end)
            Conn(R.fpsConn)
        end
        if not R.fpsLitConn then
            pcall(function()
                R.fpsLitConn = game:GetService("Lighting").ChildAdded:Connect(function(ch)
                    if S.fpsBoost and not R.dead and R.fpsLit then
                        pcall(function()
                            if ch:IsA("PostEffect") and R.fpsLit.fx[ch] == nil then
                                R.fpsLit.fx[ch] = ch.Enabled
                                ch.Enabled = false
                            end
                        end)
                    end
                end)
                Conn(R.fpsLitConn)
            end)
        end
    else
        if R.fpsConn then pcall(function() R.fpsConn:Disconnect() end) R.fpsConn = nil end
        if R.fpsLitConn then pcall(function() R.fpsLitConn:Disconnect() end) R.fpsLitConn = nil end
        FpsRestoreAll()
        R.fpsLit = nil
        R.fpsTer = nil
        R.fpsQual = nil
    end
end
local function FpsCapApply()
    pcall(function()
        if typeof(setfpscap) ~= "function" then return end
        if S.fpsUnlock then
            if R.fpsCapPrev == nil then
                R.fpsCapPrev = 60
                if typeof(getfpscap) == "function" then
                    local v = getfpscap()
                    if typeof(v) == "number" and v > 0 then R.fpsCapPrev = v end
                end
            end
            setfpscap(1000)
        elseif R.fpsCapPrev ~= nil then
            setfpscap(R.fpsCapPrev)
        end
    end)
end
