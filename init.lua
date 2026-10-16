if not game:IsLoaded() then
    game.Loaded:Wait()
end

local BASE_URL = "https://raw.githubusercontent.com/scriptss4u/r7x4m2/main/"

local Games = {
    [1001911915] = "core/0x7A2F.lua"
}

local selectedScript = Games[game.GameId]

if not selectedScript then
    warn("[scripts4u] unsupported game")
    return
end

local success, err = pcall(function()
    local source = game:HttpGet(BASE_URL .. selectedScript)

    if not source or source == "" then
        error("failed to download script")
    end

    local execute, compileError = loadstring(source)

    if not execute then
        error(compileError or "failed to compile script")
    end

    execute()
end)

if not success then
    warn("[scripts4u] " .. tostring(err))
end
