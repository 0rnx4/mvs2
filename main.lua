local PIN = "2e3e5215d6ecc17a4629b3a2239fc4340a300d5b"
local BASE = "https://raw.githubusercontent.com/0rnx4/mvs2/" .. PIN .. "/modules/"
local MODS = { "01_core", "02_classify", "03_predict", "04_target", "05_silent", "06_esp", "07_perf", "08_gui", "09_build", "10_main" }
local EXPECTED = 121186
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
