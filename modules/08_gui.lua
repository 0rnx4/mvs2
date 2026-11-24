local GuiParent = nil
pcall(function() if typeof(gethui) == "function" then GuiParent = gethui() end end)
if not GuiParent then pcall(function() GuiParent = game:GetService("CoreGui") end) end
if not GuiParent then GuiParent = LocalPlayer:WaitForChild("PlayerGui") end
local Overlay = Instance.new("ScreenGui")
Overlay.Name = RName()
Overlay.ResetOnSpawn = false
Overlay.DisplayOrder = 40 + math.random(0, 8)
Overlay.IgnoreGuiInset = true
if typeof(protectgui) == "function" then pcall(protectgui, Overlay) end
if not pcall(function() Overlay.Parent = GuiParent end) then
    pcall(function() Overlay.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
end
local function Mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then o[k] = v end
    end
    o.Parent = parent
    return o
end
R.colWhite = Color3.fromRGB(255, 255, 255)
R.colGreen = Color3.fromRGB(52, 211, 153)
local FovRing = Mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, Overlay)
Mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, FovRing)
local FovStroke = Mk("UIStroke", { Color = R.colWhite, Thickness = 1.5, Transparency = 0.35 }, FovRing)
local LineF = Mk("Frame", { AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = R.colWhite, BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = false, Size = UDim2.new(0, 0, 0, 1) }, Overlay)
local FpsHud = Mk("TextLabel", { AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(0, 150, 0, 22), BackgroundTransparency = 1, BorderSizePixel = 0, TextColor3 = R.colWhite, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Visible = false, Text = "" }, Overlay)
R.fpsHud = FpsHud
pcall(function() FpsHud.Font = Enum.Font.SourceSansBold end)
local WindUI = nil
do
    local src = nil
    pcall(function() src = game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/d2c9bac5f96f997418d680d19cb759892542e492/dist/main.lua") end)
    if src and typeof(loadstring) == "function" then
        local fn = nil
        pcall(function() fn = loadstring(src) end)
        if fn then pcall(function() WindUI = fn() end) end
    end
end
R.windUI = WindUI
local function Notify(text)
    if WindUI then
        pcall(function() WindUI:Notify({ Title = "MVS2", Content = text, Duration = 3, Icon = "crosshair" }) end)
    end
end
local DEFAULTS = {}
for k, v in pairs(S) do DEFAULTS[k] = v end
local CLAMPS = {
    fov = { 40, 400 }, hitChance = { 10, 100 }, predAmount = { 0, 0.3 },
    knifeSpeed = { 60, 300 }, knifeDrop = { 0, 100 }, gunTravel = { 0, 0.15 },
    maxDist = { 100, 1200 }, maxBend = { 0, 120 }, triggerDelay = { 0, 600 },
    triggerCooldown = { 10, 1500 }, triggerRange = { 30, 600 }, stabRange = { 6, 30 },
    spinSpeed = { 180, 3600 },
    espMaxDist = { 50, 1500 }, aimJitter = { 0, 50 }, espSkelThick = { 1, 3 },
}
local ENUMS = {
    weaponMode = { Auto = true, Knife = true, Gun = true },
    priority = { Screen = true, Distance = true, Health = true },
    targetMode = { Closest = true, Head = true, Torso = true },
    espColor = { Red = true, Green = true, Blue = true, Purple = true, White = true, Orange = true, Cyan = true, Pink = true },
    espSkelMode = { Role = true, Health = true, Custom = true },
    espSkelCol = { Red = true, Green = true, Blue = true, Purple = true, White = true, Orange = true, Cyan = true, Pink = true },
    espBoxStyle = { Box = true, Corner = true },
    theme = { Dark = true, Indigo = true, Emerald = true, Rose = true, Amber = true, Sky = true, Midnight = true, Violet = true },
    guiKey = { RightShift = true, Insert = true, LeftAlt = true, RightControl = true },
}
local function SanitizeConfig()
    for k, range in pairs(CLAMPS) do
        local v = S[k]
        if typeof(v) ~= "number" or v ~= v then S[k] = DEFAULTS[k]
        else S[k] = math.clamp(v, range[1], range[2]) end
    end
    for k, set in pairs(ENUMS) do
        if typeof(S[k]) ~= "string" or not set[S[k]] then S[k] = DEFAULTS[k] end
    end
    for k in pairs(S) do
        if typeof(S[k]) ~= typeof(DEFAULTS[k]) then S[k] = DEFAULTS[k] end
    end
end
local CFG_FILE = "settings_cache.json"
local function SaveConfig()
    local ok = pcall(function()
        if typeof(writefile) ~= "function" then error("no writefile") end
        local data = {}
        for k, v in pairs(S) do data[k] = v end
        writefile(CFG_FILE, HttpService:JSONEncode(data))
    end)
    if ok then Notify("設定を保存した") else Notify("保存できない環境です") end
end
local function LoadConfig(silentLoad)
    local ok = pcall(function()
        if typeof(readfile) ~= "function" then error("no readfile") end
        local raw = readfile(CFG_FILE)
        local data = HttpService:JSONDecode(raw)
        if typeof(data) == "table" then
            for k, v in pairs(data) do
                if S[k] ~= nil and typeof(S[k]) == typeof(v) then S[k] = v end
            end
        end
    end)
    SanitizeConfig()
    if ok then
        if R.guiSyncFns then for _, f in ipairs(R.guiSyncFns) do pcall(f) end end
        if WindUI then pcall(function() WindUI:SetTheme(S.theme) end) end
        pcall(FpsApply)
        pcall(FpsCapApply)
        if S.silent then pcall(InstallHooks) end
        if R.windWindow then
            pcall(function()
                local kc = Enum.KeyCode[S.guiKey]
                if kc and R.windWindow.SetToggleKey then R.windWindow:SetToggleKey(kc) end
            end)
        end
        if not silentLoad then Notify("設定を読み込んだ") end
    elseif not silentLoad then
        Notify("保存された設定がありません")
    end
    return ok
end
local function ApplyPreset()
    local P = { silent = true, fireGate = true, instantFire = true, wallCheck = true, teamCheck = true, prediction = true, predSelect = true, fitRecent = true, partSurf = true, resolver = true, esp = true, espChams = true, espSkeleton = true, espSkelOutline = true, espVisCol = true, espDim = true, espDistFade = true, espHpSmooth = true, espArrows = true, espName = true, espHealth = true, espDistance = true, showFov = true }
    for k, v in pairs(P) do S[k] = v end
    SanitizeConfig()
    if R.guiSyncFns then for _, f in ipairs(R.guiSyncFns) do pcall(f) end end
    if S.silent then pcall(InstallHooks) end
    Notify("推奨プリセットを適用した")
end
local function ResetConfig()
    for k, v in pairs(DEFAULTS) do S[k] = v end
    SanitizeConfig()
    if R.guiSyncFns then for _, f in ipairs(R.guiSyncFns) do pcall(f) end end
    if WindUI then pcall(function() WindUI:SetTheme(S.theme) end) end
    pcall(FpsApply)
    pcall(FpsCapApply)
    if S.silent then pcall(InstallHooks) end
    Notify("初期設定に戻した")
end
