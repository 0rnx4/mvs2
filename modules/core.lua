local Env = (typeof(getgenv) == "function" and getgenv()) or _G
local function FindCtl()
    for _, v in pairs(Env) do
        if typeof(v) == "table" and typeof(v.Settings) == "table" and typeof(v.Runtime) == "table" and not v.Runtime.dead then return v end
    end
    return nil
end
local PrevCtl = FindCtl()
if PrevCtl and PrevCtl.Unload then pcall(PrevCtl.Unload) end
local function CRef(x)
    if typeof(cloneref) == "function" then
        local ok, r = pcall(cloneref, x)
        if ok and r then return r end
    end
    return x
end
local Players = CRef(game:GetService("Players"))
local RunService = CRef(game:GetService("RunService"))
local UserInputService = CRef(game:GetService("UserInputService"))
local TweenService = CRef(game:GetService("TweenService"))
local HttpService = CRef(game:GetService("HttpService"))
local Stats = CRef(game:GetService("Stats"))
local Workspace = CRef(game:GetService("Workspace"))
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.2)
    LocalPlayer = Players.LocalPlayer
end
local Mouse = nil
pcall(function() Mouse = LocalPlayer:GetMouse() end)
local S = {
    silent = true,
    silentMouse = true,
    silentRay = true,
    silentCamRay = true,
    fireGate = true,
    weaponMode = "Auto",
    knifeSpeed = 130,
    knifeDrop = 50,
    gunTravel = 0.03,
    priority = "Screen",
    maxDist = 3000,
    maxBend = 0,
    trigger = false,
    multiFire = false,
    triggerDelay = 0,
    triggerCooldown = 380,
    instantFire = true,
    triggerRange = 300,
    triggerThrow = false,
    spinBot = false,
    spinSpeed = 720,
    stabRange = 14,
    espRoleColor = true,
    fov = 140,
    showFov = true,
    hitChance = 100,
    prediction = true,
    predAmount = 0.08,
    pingComp = true,
    targetMode = "Closest",
    sticky = false,
    predSelect = true,
    ffCheck = true,
    airTorso = true,
    fitRecent = true,
    wallCheck = true,
    teamCheck = true,
    resolver = true,
    esp = true,
    espChams = true,
    espName = true,
    espHealth = true,
    espDistance = true,
    espColor = "Red",
    espSkeleton = false,
    espTracer = false,
    espBoxStyle = "Box",
    espFill = false,
    espHeadDot = false,
    espArrows = true,
    espTargetCol = true,
    espDim = true,
    espOutline = true,
    espVisCol = true,
    espDistFade = true,
    espHpSmooth = true,
    espSkelMode = "Health",
    espSkelCol = "White",
    espSkelOutline = true,
    espSkelJoints = false,
    espSkelThick = 1,
    espWeaponName = false,
    showFpsHud = false,
    espMaxDist = 800,
    fpsBoost = false,
    fpsUltra = false,
    fpsUnlock = false,
    theme = "Dark",
    guiKey = "RightShift",
}
local R = {
    dead = false,
    charDead = true,
    target = nil,
    part = nil,
    pos = nil,
    rawPos = nil,
    aimPoint = Vector2.new(0, 0),
    chanceOk = true,
    chanceAt = 0,
    inputs = {},
    inputDown = false,
    myClass = nil,
    classCache = {},
    velCache = {},
    visCache = {},
    bboxCache = {},
    targetSince = 0,
    targetKey = math.huge,
    holdUntil = 0,
    lastTrigger = 0,
    triggerPulse = 0,
    espFrame = 0,
    espFailAt = 0,
    toastN = 0,
    selfRay = false,
    hookMouse = false,
    hookRay = false,
    conns = {},
    charConns = {},
    espObjs = {},
    hbOrig = {},
    partsCache = {},
    teamCache = {},
    classTool = {},
    className = {},
    myTeamKey = "",
    rootCache = setmetatable({}, { __mode = "k" }),
    stickyEnt = {},
    emptyParts = {},
    cmpFn = function(a, b) return a.key < b.key end,
    multiIdx = 1,
    multiCur = nil,
    touchUi = false,
    playerList = nil,
    playerListAt = 0,
    dtEma = 1 / 60,
    loadTier = 0,
    visTtl = 0.1,
    rayMax = 3,
}

local NameRng = Random.new()
local NameChars = "abcdefghijklmnopqrstuvwxyz0123456789"
local function RName()
    local out = {}
    for i = 1, 12 do
        local n = NameRng:NextInteger(1, #NameChars)
        out[i] = string.sub(NameChars, n, n)
    end
    return table.concat(out)
end
local CTL = { Settings = S, Runtime = R, Unload = function() R.dead = true end }
local CTLKey = RName()
Env[CTLKey] = CTL
CTL.Key = CTLKey
local function Conn(c)
    R.conns[#R.conns + 1] = c
    return c
end
local function CharConn(p, c)
    local t = R.charConns[p]
    if not t then t = {} R.charConns[p] = t end
    t[#t + 1] = c
    return c
end
local function Cam()
    return Workspace.CurrentCamera
end
local PingCache = { v = 60, at = 0 }
local function PingMs()
    local now = os.clock()
    if now - PingCache.at < 0.5 then return PingCache.v end
    PingCache.at = now
    local v = nil
    pcall(function() v = LocalPlayer:GetNetworkPing() * 1000 end)
    if not v or v <= 0 then
        pcall(function()
            local item = Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
            if item then v = item:GetValue() end
        end)
    end
    if v and v > 0 and v < 2000 then PingCache.v = PingCache.v * 0.6 + v * 0.4 end
    return PingCache.v
end
