
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local env = (type(getgenv) == "function" and getgenv()) or _G

local API = "https://api.scripts4u.site"
local KEY_WEBSITE = "https://getkey.scripts4u.site"
local SAVE_FILE = "scripts4u_faf_key.txt"

local function getDeviceId()
    local candidates = {
        env.gethwid,
        env.get_hwid,
        gethwid,
        get_hwid
    }

    for _, fn in pairs(candidates) do
        if type(fn) == "function" then
            local ok, result = pcall(fn)

            if ok and type(result) == "string" and #result >= 8 then
                return result
            end
        end
    end

    local ok, result = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)

    if ok and type(result) == "string" and #result >= 8 then
        return result
    end

    return nil
end

local function getRequest()
    local candidates = {
        env.request,
        env.http_request,
        request,
        http_request,
        syn and syn.request,
        http and http.request
    }

    for _, fn in pairs(candidates) do
        if type(fn) == "function" then
            return fn
        end
    end

    return nil
end

local function post(path, data)
    local requestFn = getRequest()

    if not requestFn then
        return false, 0, "executor does not support HTTP requests"
    end

    local ok, response = pcall(requestFn, {
        Url = API .. path,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(data)
    })

    if not ok or type(response) ~= "table" then
        return false, 0, "connection failed"
    end

    local code = tonumber(
        response.StatusCode or response.Status or response.status_code
    ) or 0

    local body = response.Body or response.body or ""

    if type(body) ~= "string" then
        body = tostring(body)
    end

    return code >= 200 and code < 300, code, body
end

local function getError(body)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if ok and type(data) == "table" then
        return tostring(data.error or data.reason or "verification failed")
    end

    return body ~= "" and body or "connection failed"
end

local function readSavedKey()
    local reader = env.readfile or readfile

    if type(reader) == "function" then
        local ok, value = pcall(reader, SAVE_FILE)

        if ok and type(value) == "string" then
            return value:gsub("%s+", "")
        end
    end

    return type(env.Scripts4USavedKey) == "string"
        and env.Scripts4USavedKey or ""
end

local function saveKey(key)
    env.Scripts4USavedKey = key

    local writer = env.writefile or writefile

    if type(writer) == "function" then
        pcall(writer, SAVE_FILE, key)
    end
end

local function deleteSavedKey()
    env.Scripts4USavedKey = nil

    local remover = env.delfile or delfile

    if type(remover) == "function" then
        pcall(remover, SAVE_FILE)
    end
end

local previous = playerGui:FindFirstChild("Scripts4UAuth")

if previous then
    previous:Destroy()
end

local function create(class, properties, parent)
    local instance = Instance.new(class)

    for property, value in pairs(properties) do
        instance[property] = value
    end

    instance.Parent = parent

    return instance
end

local colors = {
    background = Color3.fromRGB(13, 13, 14),
    surface = Color3.fromRGB(25, 25, 27),
    border = Color3.fromRGB(67, 67, 70),
    white = Color3.fromRGB(245, 245, 245),
    muted = Color3.fromRGB(151, 151, 155)
}

local gui = create("ScreenGui", {
    Name = "Scripts4UAuth",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 2000,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, playerGui)

local frame = create("Frame", {
    Name = "KeyWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(440, 270),
    BackgroundColor3 = colors.background,
    BackgroundTransparency = 0.06,
    BorderSizePixel = 0,
    Active = true
}, gui)

create("UICorner", {
    CornerRadius = UDim.new(0, 5)
}, frame)

create("UIStroke", {
    Color = colors.border,
    Transparency = 0.25,
    Thickness = 1
}, frame)

local uiScale = create("UIScale", {
    Scale = 1
}, frame)

local function updateScale()
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    uiScale.Scale = math.clamp(
        math.min(
            (viewport.X - 24) / 440,
            (viewport.Y - 24) / 270
        ),
        0.45,
        1
    )
end

updateScale()

create("ImageLabel", {
    Name = "Scripts4UBanner",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(120, 14),
    Size = UDim2.fromOffset(200, 50),
    Image = "rbxassetid://105601293945742",
    ScaleType = Enum.ScaleType.Fit
}, frame)

create("Frame", {
    Position = UDim2.fromOffset(20, 73),
    Size = UDim2.fromOffset(400, 1),
    BackgroundColor3 = colors.border,
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0
}, frame)

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(20, 84),
    Size = UDim2.fromOffset(400, 22),
    Text = "enter your key to continue",
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextColor3 = colors.muted,
    TextXAlignment = Enum.TextXAlignment.Center
}, frame)

local keyInput = create("TextBox", {
    Name = "KeyInput",
    Position = UDim2.fromOffset(20, 117),
    Size = UDim2.fromOffset(400, 42),
    BackgroundColor3 = colors.surface,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    PlaceholderText = "S4U-FREE-...",
    PlaceholderColor3 = colors.muted,
    Text = readSavedKey(),
    TextColor3 = colors.white,
    TextSize = 13,
    Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left
}, frame)

create("UICorner", {
    CornerRadius = UDim.new(0, 4)
}, keyInput)

create("UIStroke", {
    Color = colors.border,
    Transparency = 0.35,
    Thickness = 1
}, keyInput)

create("UIPadding", {
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12)
}, keyInput)

local function createButton(label, x, background, foreground)
    local button = create("TextButton", {
        Position = UDim2.fromOffset(x, 169),
        Size = UDim2.fromOffset(194, 40),
        BackgroundColor3 = background,
        BorderSizePixel = 0,
        Text = label,
        TextColor3 = foreground,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true
    }, frame)

    create("UICorner", {
        CornerRadius = UDim.new(0, 4)
    }, button)

    return button
end

local verifyButton = createButton(
    "verify key",
    20,
    colors.white,
    colors.background
)

local getKeyButton = createButton(
    "get key",
    226,
    colors.surface,
    colors.white
)

create("UIStroke", {
    Color = colors.border,
    Transparency = 0.4,
    Thickness = 1
}, getKeyButton)

local rememberKey = true

local rememberButton = create("TextButton", {
    Position = UDim2.fromOffset(20, 220),
    Size = UDim2.fromOffset(170, 22),
    BackgroundTransparency = 1,
    Text = "remember key: on",
    TextColor3 = colors.muted,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, frame)

local statusLabel = create("TextLabel", {
    Position = UDim2.fromOffset(190, 220),
    Size = UDim2.fromOffset(230, 22),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = colors.muted,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
    TextTruncate = Enum.TextTruncate.AtEnd
}, frame)

create("TextLabel", {
    Position = UDim2.fromOffset(20, 247),
    Size = UDim2.fromOffset(400, 15),
    BackgroundTransparency = 1,
    Text = "free keys last 24 hours after activation",
    TextColor3 = colors.muted,
    TextTransparency = 0.25,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Center
}, frame)

local busy = false

local function setStatus(message)
    if gui.Parent then
        statusLabel.Text = message
    end
end

local function verifyKey()
    if busy or not gui.Parent then
        return
    end

    local key = keyInput.Text:gsub("%s+", ""):upper()

    if #key ~= 57 or not key:match("^S4U%-FREE%-%x+$") then
        setStatus("invalid key format")
        return
    end

    local deviceId = getDeviceId()

    if not deviceId then
        setStatus("device ID unavailable")
        return
    end

    busy = true
    verifyButton.Text = "verifying..."
    setStatus("checking key")

    task.spawn(function()
        local success, _, body = post("/api/activate", {
            key = key,
            hwid = deviceId
        })

        if not gui.Parent then
            return
        end

        if not success then
            setStatus(getError(body))
            verifyButton.Text = "verify key"
            busy = false
            return
        end

        local decoded, result = pcall(function()
            return HttpService:JSONDecode(body)
        end)

        if not decoded or type(result) ~= "table" or not result.ok then
            setStatus("invalid server response")
            verifyButton.Text = "verify key"
            busy = false
            return
        end

        setStatus("loading farming and friends")

        local delivered, _, source = post("/api/faf", {
            key = key,
            hwid = deviceId
        })

        if not gui.Parent then
            return
        end

        if not delivered then
            setStatus(getError(source))
            verifyButton.Text = "verify key"
            busy = false
            return
        end

        if source == "" then
            setStatus("script unavailable")
            verifyButton.Text = "verify key"
            busy = false
            return
        end

        local execute, compileError = loadstring(source)

        if not execute then
            setStatus("failed to compile script")
            warn("[scripts4u] " .. tostring(compileError))
            verifyButton.Text = "verify key"
            busy = false
            return
        end

        if rememberKey then
            saveKey(key)
        else
            deleteSavedKey()
        end

        gui:Destroy()

        local ran, runtimeError = pcall(execute)

        if not ran then
            warn("[scripts4u] " .. tostring(runtimeError))
        end
    end)
end

verifyButton.MouseButton1Click:Connect(verifyKey)

keyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        verifyKey()
    end
end)

getKeyButton.MouseButton1Click:Connect(function()
    local clipboard = env.setclipboard or setclipboard

    if type(clipboard) == "function" then
        local ok = pcall(clipboard, KEY_WEBSITE)

        if ok then
            setStatus("key link copied")
        else
            setStatus(KEY_WEBSITE)
        end
    else
        setStatus(KEY_WEBSITE)
    end
end)

rememberButton.MouseButton1Click:Connect(function()
    rememberKey = not rememberKey

    rememberButton.Text = "remember key: "
        .. (rememberKey and "on" or "off")
end)

if keyInput.Text ~= "" then
    task.defer(verifyKey)
end
