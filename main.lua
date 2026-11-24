local PIN = "d9c8fdceddd33ab9f18c1bd0d7dbacc978529f3c"
local BASE = "https://raw.githubusercontent.com/0rnx4/mvs2/" .. PIN .. "/modules/"
local MODS = { "core", "classify", "predict", "target", "silent", "esp", "perf", "gui", "build", "main" }
local EXPECTED = 120489
local parts = {}
local total = 0
for i, m in ipairs(MODS) do
    local src = nil
    for _ = 1, 2 do
        local ok, r = pcall(function() return game:HttpGet(BASE .. m .. ".lua") end)
        if ok and type(r) == "string" and #r > 0 then src = r break end
    end
    if not src then error("MVS2: module load failed: " .. m) end
    parts[i] = src
    total = total + #src
end
if total ~= EXPECTED then error("MVS2: module size mismatch: " .. total) end
local fn, err = loadstring(table.concat(parts))
if not fn then error("MVS2: compile failed: " .. tostring(err)) end
return fn()
