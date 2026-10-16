local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local env = (type(getgenv) == "function" and getgenv()) or _G

local API = "https://scripts4u-faf-api.darscripts.workers.dev"
local KEY_WEBSITE = "https://getkey.scripts4u.site"
local SAVE_FILE = "scripts4u_faf_key.txt"
local KEY_PATTERN = "^S4U%-FREE%-%x+$"

local function getDeviceId()
    local candidates = {
        env.gethwid,
        env.get_hwid,
        (type(gethwid) == "function" and gethwid or nil),
        (type(get_hwid) == "function" and get_hwid or nil)
    }
    for _, fn in pairs(candidates) do
        if type(fn) == "function" then
            local ok, value = pcall(fn)
            if ok and type(value) == "string" and #value >= 8 then
                return value
            end
        end
    end

    -- Fallback client identifier; not a hardware-secure ID.
    local ok, value = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and type(value) == "string" and #value >= 8 then
        return value
    end
    return nil
end

local function post(path, payload)
    local fn = (type(env.request) == "function" and env.request)
        or (type(env.http_request) == "function" and env.http_request)
        or (type(request) == "function" and request)
        or (type(http_request) == "function" and http_request)
        or (type(syn) == "table" and type(syn.request) == "function" and syn.request)
        or (type(http) == "table" and type(http.request) == "function" and http.request)

    local options = {
        Url = API .. path,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload)
    }

    local ok, response
    if fn then
        ok, response = pcall(fn, options)
    else
        ok, response = pcall(function()
            return HttpService:RequestAsync(options)
        end)
    end
    if not ok or type(response) ~= "table" then
        return false, 0, "HTTP POST is unavailable in this executor"
    end

    local status = tonumber(response.StatusCode or response.Status or response.status_code) or 0
    local body = response.Body or response.body or ""
    if type(body) ~= "string" then body = tostring(body) end
    return status >= 200 and status < 300, status, body
end

local function decodeError(body)
    if body == "HTTP POST is unavailable in this executor" then
        return body
    end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if ok and type(data) == "table" then
        return tostring(data.error or data.reason or "verification failed")
    end
    return "verification failed"
end

local function loadSavedKey()
    local reader = (type(env.readfile) == "function" and env.readfile)
        or (type(readfile) == "function" and readfile)
    if reader then
        local ok, value = pcall(reader, SAVE_FILE)
        if ok and type(value) == "string" then
            return value:gsub("%s+", "")
        end
    end
    return type(env.Scripts4USavedKey) == "string" and env.Scripts4USavedKey or ""
end

local function saveKey(key)
    env.Scripts4USavedKey = key
    local writer = (type(env.writefile) == "function" and env.writefile)
        or (type(writefile) == "function" and writefile)
    if writer then pcall(writer, SAVE_FILE, key) end
end

local function forgetKey()
    env.Scripts4USavedKey = nil
    local remover = (type(env.delfile) == "function" and env.delfile)
        or (type(delfile) == "function" and delfile)
    if remover then pcall(remover, SAVE_FILE) end
end

local old = playerGui:FindFirstChild("Scripts4UAuth")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "Scripts4UAuth"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function make(class, props, parent)
    local item = Instance.new(class)
    for k, v in pairs(props) do item[k] = v end
    item.Parent = parent
    return item
end

local bg = Color3.fromRGB(12, 12, 13)
local surface = Color3.fromRGB(24, 24, 26)
local border = Color3.fromRGB(69, 69, 72)
local white = Color3.fromRGB(245, 245, 245)
local muted = Color3.fromRGB(151, 151, 155)

local frame = make("Frame", {
    Name = "KeyWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(440, 260),
    BackgroundColor3 = bg,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    Active = true
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 4)}, frame)
make("UIStroke", {Color = border, Transparency = 0.2, Thickness = 1}, frame)

local scale = make("UIScale", {Scale = 1}, frame)
local function resize()
    local camera = workspace.CurrentCamera
    local size = camera and camera.ViewportSize or Vector2.new(1280, 720)
    scale.Scale = math.clamp(math.min((size.X - 24) / 440, (size.Y - 24) / 260), 0.45, 1)
end
resize()

local banner = make("ImageLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(120, 15),
    Size = UDim2.fromOffset(200, 48),
    Image = "rbxassetid://105601293945742",
    ScaleType = Enum.ScaleType.Fit
}, frame)

make("Frame", {
    Position = UDim2.fromOffset(20, 70),
    Size = UDim2.fromOffset(400, 1),
    BackgroundColor3 = border,
    BackgroundTransparency = 0.45,
    BorderSizePixel = 0
}, frame)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(20, 82),
    Size = UDim2.fromOffset(400, 22),
    Text = "enter your key to continue",
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextColor3 = muted
}, frame)

local input = make("TextBox", {
    Position = UDim2.fromOffset(20, 114),
    Size = UDim2.fromOffset(400, 40),
    BackgroundColor3 = surface,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    PlaceholderText = "S4U-FREE-...",
    PlaceholderColor3 = muted,
    Text = loadSavedKey(),
    TextColor3 = white,
    TextSize = 13,
    Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left
}, frame)
make("UICorner", {CornerRadius = UDim.new(0, 4)}, input)
make("UIStroke", {Color = border, Transparency = 0.35}, input)
make("UIPadding", {
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12)
}, input)

local function button(text, x, color, textColor)
    local b = make("TextButton", {
        Position = UDim2.fromOffset(x, 164),
        Size = UDim2.fromOffset(194, 38),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = textColor,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true
    }, frame)
    make("UICorner", {CornerRadius = UDim.new(0, 4)}, b)
    return b
end

local verifyButton = button("verify key", 20, white, bg)
local getKeyButton = button("get key", 226, surface, white)

local remember = true
local rememberButton = make("TextButton", {
    Position = UDim2.fromOffset(20, 213),
    Size = UDim2.fromOffset(180, 20),
    BackgroundTransparency = 1,
    Text = "remember key: on",
    TextColor3 = muted,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, frame)

local statusLabel = make("TextLabel", {
    Position = UDim2.fromOffset(190, 212),
    Size = UDim2.fromOffset(230, 25),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = muted,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
    TextTruncate = Enum.TextTruncate.AtEnd
}, frame)

local busy = false
local function status(message)
    if gui.Parent then statusLabel.Text = message end
end

local function verify()
    if busy or not gui.Parent then return end
    local key = input.Text:gsub("%s+", ""):upper()
    if #key ~= 57 or not key:match(KEY_PATTERN) then
        status("invalid key format")
        return
    end

    local deviceId = getDeviceId()
    if not deviceId then
        status("device ID unavailable")
        return
    end

    busy = true
    verifyButton.Text = "verifying..."
    status("checking key")

    task.spawn(function()
        local ok, _, body = post("/api/activate", {
            key = key,
            hwid = deviceId
        })
        if not gui.Parent then return end
        if not ok then
            status(decodeError(body))
            verifyButton.Text = "verify key"
            busy = false
            return
        end

        local decoded, result = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if not decoded or type(result) ~= "table" or not result.ok then
            status("invalid server response")
            verifyButton.Text = "verify key"
            busy = false
            return
        end

        status("loading farming and friends")
        local delivered, _, source = post("/api/faf", {
            key = key,
            hwid = deviceId
        })
        if not gui.Parent then return end
        if not delivered then
            status(decodeError(source))
            verifyButton.Text = "verify key"
            busy = false
            return
        end

        if source == "" then
            status("script response was incomplete")
            verifyButton.Text = "verify key"
            busy = false
            return
        end

        local execute, compileError = loadstring(source)
        if not execute then
            status("script compilation failed")
            warn("[scripts4u]", compileError)
            verifyButton.Text = "verify key"
            busy = false
            return
        end

        if remember then saveKey(key) else forgetKey() end
        gui:Destroy()
        local ran, runtimeError = pcall(execute)
        if not ran then warn("[scripts4u] FAF error:", runtimeError) end
    end)
end

verifyButton.MouseButton1Click:Connect(verify)
input.FocusLost:Connect(function(enterPressed)
    if enterPressed then verify() end
end)

getKeyButton.MouseButton1Click:Connect(function()
    local clipboard = (type(env.setclipboard) == "function" and env.setclipboard)
        or (type(setclipboard) == "function" and setclipboard)
    if clipboard then
        local ok = pcall(clipboard, KEY_WEBSITE)
        status(ok and "key link copied" or KEY_WEBSITE)
    else
        status(KEY_WEBSITE)
    end
end)

rememberButton.MouseButton1Click:Connect(function()
    remember = not remember
    rememberButton.Text = "remember key: " .. (remember and "on" or "off")
end)

if input.Text ~= "" then
    task.defer(verify)
end
