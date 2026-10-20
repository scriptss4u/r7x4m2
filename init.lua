local URL = "https://scripts4u-admin.darscripts.workers.dev/s/loader.lua"

local success, err = pcall(function()
    local source = game:HttpGet(URL)
    assert(loadstring(source))()
end)

if not success then
    warn("[scripts4u] " .. tostring(err))
end
