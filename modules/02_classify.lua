local KNIFE_WORDS = { "knife", "dagger", "blade", "katana", "sword", "kunai", "scythe", "axe", "shank", "shiv" }
local GUN_WORDS = { "gun", "revolver", "pistol", "sheriff", "blaster", "rifle", "shooter" }
local function NameHas(n, words)
    local low = string.lower(n)
    for _, w in ipairs(words) do
        if string.find(low, w, 1, true) then return true end
    end
    return false
end
local function ToolClass(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    if NameHas(tool.Name, KNIFE_WORDS) then return "Knife" end
    if NameHas(tool.Name, GUN_WORDS) then return "Gun" end
    for _, ch in ipairs(tool:GetChildren()) do
        if NameHas(ch.Name, KNIFE_WORDS) then return "Knife" end
        if NameHas(ch.Name, GUN_WORDS) then return "Gun" end
    end
    return nil
end
local function CharOf(p)
    local ok, c = pcall(function() return p.Character end)
    if ok then return c end
    return nil
end
local function PlayerList()
    local now = os.clock()
    if R.playerList and now - R.playerListAt < 0.3 then return R.playerList end
    R.playerList = Players:GetPlayers()
    R.playerListAt = now
    return R.playerList
end
local function RefreshClasses()
    local lt, lc = nil, nil
    pcall(function() lt = LocalPlayer.Team end)
    pcall(function() lc = LocalPlayer.TeamColor end)
    local tkey = tostring(lt) .. "/" .. tostring(lc)
    if tkey ~= R.myTeamKey then
        R.myTeamKey = tkey
        R.teamCache = {}
    end
    for _, p in ipairs(PlayerList()) do
        local char = CharOf(p)
        local tool = nil
        if char then pcall(function() tool = char:FindFirstChildOfClass("Tool") end) end
        if R.classTool[p] ~= tool or R.className[p] ~= (tool and tool.Name or nil) then
            R.classTool[p] = tool
            R.className[p] = tool and tool.Name or nil
            local cls = tool and ToolClass(tool) or nil
            if p == LocalPlayer then R.myClass = cls else R.classCache[p] = cls end
        end
    end
end
local function IsEnemy(p)
    if p == LocalPlayer then return false end
    if not S.teamCheck then return true end
    local tc = R.teamCache[p]
    if tc and tc.key == R.myTeamKey then
        local vt, vc, va = nil, nil, nil
        pcall(function() vt = p.Team end)
        pcall(function() vc = p.TeamColor end)
        pcall(function() va = p:GetAttribute("Team") end)
        if tc.team == vt and tc.color == vc and tc.attr == va then return tc.enemy end
    end
    local enemy = true
    local lt, pt, pc2, pa = nil, nil, nil, nil
    pcall(function() lt = LocalPlayer.Team end)
    pcall(function() pt = p.Team end)
    pcall(function() pc2 = p.TeamColor end)
    pcall(function() pa = p:GetAttribute("Team") end)
    if lt ~= nil and pt ~= nil then
        enemy = (lt ~= pt)
    else
        local la = nil
        pcall(function() la = LocalPlayer:GetAttribute("Team") end)
        if la ~= nil and pa ~= nil then
            enemy = (la ~= pa)
        else
            local lc = nil
            pcall(function() lc = LocalPlayer.TeamColor end)
            if lc ~= nil and pc2 ~= nil then enemy = (lc ~= pc2) end
        end
    end
    R.teamCache[p] = { enemy = enemy, key = R.myTeamKey, team = pt, color = pc2, attr = pa }
    return enemy
end
local RSRef = nil
local function InHidden(char)
    if not char then return false end
    local now = os.clock()
    if now - (R.hiddenAt or 0) > 3 then
        R.hiddenAt = now
        R.hiddenFolder = nil
        if RSRef == nil then
            local ok, rs = pcall(function() return game:GetService("ReplicatedStorage") end)
            if ok and rs then RSRef = rs end
        end
        if RSRef then pcall(function() R.hiddenFolder = RSRef:FindFirstChild("HiddenCharacters") end) end
    end
    local hc = R.hiddenFolder
    if hc and char:IsDescendantOf(hc) then return true end
    return false
end
local function HasFF(char)
    if not char then return false end
    local ff = nil
    pcall(function() ff = char:FindFirstChildOfClass("ForceField") end)
    return ff ~= nil
end
local function HumOf(c)
    if not c then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end
local function PartOf(c, name)
    if not c then return nil end
    local p = c:FindFirstChild(name)
    if p and p:IsA("BasePart") then return p end
    return nil
end
local function RootOf(c)
    if not c then return nil end
    local r = R.rootCache[c]
    if r and r.Parent == c then return r end
    r = PartOf(c, "HumanoidRootPart") or PartOf(c, "Torso") or PartOf(c, "Head")
    if r then R.rootCache[c] = r end
    return r
end
local function WeaponClass()
    local cls = S.weaponMode
    if cls == "Auto" then return R.myClass end
    return cls
end
