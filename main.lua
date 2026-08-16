-- ============================================================
--          DELTA EXECUTOR - ADVANCED RAYFIELD HUB
-- ============================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
end)

-- MULTI-MIRROR LOADER MIT RETRY-LOGIK FOR RAYFIELD
local Rayfield = nil
local sources = {
    "https://sirius.menu/rayfield",
    "https://raw.githubusercontent.com/SiriusMenu/Rayfield/main/source.lua",
    "https://raw.githubusercontent.com/UI-Libraries/Rayfield/main/source.lua",
    "https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"
}

for _, url in ipairs(sources) do
    for attempt = 1, 2 do
        local success, result = pcall(function()
            local raw = game:HttpGet(url, true)
            if raw and #raw > 100 then
                return loadstring(raw)()
            end
        end)
        if success and type(result) == "table" and result.CreateWindow then
            Rayfield = result
            break
        end
        task.wait(0.2)
    end
    if Rayfield then break end
end

if not Rayfield then
    warn("Fehler: Rayfield konnte über keinen der verfügbaren Server geladen werden.")
    return
end

-- Einstellungen
local Settings = {
    Aimbot = {
        Enabled = true,
        FOV = 150,
        Smoothness = 0.2,
        AimKey = Enum.UserInputType.MouseButton2,
        TeamCheck = true
    },
    FOVCircle = {
        Visible = true,
        CenterScreen = true,
        Radius = 150,
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 1.5,
        Filled = false,
        Transparency = 0.7
    },
    ESP = {
        Enabled = true,
        Box = true,
        BoxColor = Color3.fromRGB(0, 255, 128),
        Name = true,
        NameColor = Color3.fromRGB(255, 255, 255),
        TeamCheck = true
    },
    Wallbang = {
        Enabled = true
    }
}

-- FOV Circle Drawing
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = Settings.FOVCircle.Thickness
FOVCircle.Color = Settings.FOVCircle.Color
FOVCircle.Transparency = Settings.FOVCircle.Transparency
FOVCircle.Filled = Settings.FOVCircle.Filled
FOVCircle.Visible = false

-- ESP Cache
local ESPObjects = {}

local function CreateESP(player)
    if ESPObjects[player] or player == LocalPlayer then return end
    
    local obj = {
        Box = Drawing.new("Square"),
        NameText = Drawing.new("Text")
    }

    obj.Box.Thickness = 1.5
    obj.Box.Color = Settings.ESP.BoxColor
    obj.Box.Filled = false
    obj.Box.Visible = false

    obj.NameText.Size = 14
    obj.NameText.Color = Settings.ESP.NameColor
    obj.NameText.Center = true
    obj.NameText.Outline = true
    obj.NameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    obj.NameText.Visible = false

    ESPObjects[player] = obj
end

local function DestroyESP(player)
    local obj = ESPObjects[player]
    if not obj then return end

    pcall(function() if obj.Box then obj.Box:Remove() end end)
    pcall(function() if obj.NameText then obj.NameText:Remove() end end)

    ESPObjects[player] = nil
end

local function IsAlive(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function IsEnemy(player)
    if not Settings.ESP.TeamCheck then return true end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    return true
end

local function GetFOVPosition()
    if Settings.FOVCircle.CenterScreen and Camera then
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else
        return UserInputService:GetMouseLocation()
    end
end

local function GetClosestTarget()
    if not Camera then return nil end
    local originPos = GetFOVPosition()
    local closestPlayer = nil
    local shortestDistance = Settings.Aimbot.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) and IsEnemy(player) then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distScreen = (Vector2.new(screenPos.X, screenPos.Y) - originPos).Magnitude
                    if distScreen < shortestDistance then
                        shortestDistance = distScreen
                        closestPlayer = player
                    end
                end
            end
        end
    end

    return closestPlayer
end

local function UpdateESP()
    for player, obj in pairs(ESPObjects) do
        if not Players:FindFirstChild(player.Name) or not IsAlive(player) or not IsEnemy(player) or not Settings.ESP.Enabled then
            if obj.Box then obj.Box.Visible = false end
            if obj.NameText then obj.NameText.Visible = false end
            continue
        end

        local char = player.Character
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")

        if hrp and Camera then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                if Settings.ESP.Box and obj.Box then
                    local head = char:FindFirstChild("Head")
                    local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or pos
                    local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                    local height = math.abs(headPos.Y - legPos.Y)
                    local width = height * 0.65

                    obj.Box.Size = Vector2.new(width, height)
                    obj.Box.Position = Vector2.new(pos.X - width / 2, pos.Y - height / 2)
                    obj.Box.Color = Settings.ESP.BoxColor
                    obj.Box.Visible = true
                else
                    if obj.Box then obj.Box.Visible = false end
                end

                if Settings.ESP.Name and obj.NameText then
                    obj.NameText.Position = Vector2.new(pos.X, pos.Y - (obj.Box.Size.Y / 2) - 15)
                    obj.NameText.Text = player.DisplayName or player.Name
                    obj.NameText.Color = Settings.ESP.NameColor
                    obj.NameText.Visible = true
                else
                    if obj.NameText then obj.NameText.Visible = false end
                end
            else
                if obj.Box then obj.Box.Visible = false end
                if obj.NameText then obj.NameText.Visible = false end
            end
        end
    end
end

-- Aimbot Loop
local aimbotActive = false
local currentTarget = nil

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Settings.Aimbot.AimKey or input.KeyCode == Settings.Aimbot.AimKey then
        aimbotActive = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Settings.Aimbot.AimKey or input.KeyCode == Settings.Aimbot.AimKey then
        aimbotActive = false
        currentTarget = nil
    end
end)

RunService.RenderStepped:Connect(function(delta)
    if FOVCircle then
        FOVCircle.Position = GetFOVPosition()
        FOVCircle.Radius = Settings.Aimbot.FOV
        FOVCircle.Color = Settings.FOVCircle.Color
        FOVCircle.Thickness = Settings.FOVCircle.Thickness
        FOVCircle.Filled = Settings.FOVCircle.Filled
        FOVCircle.Transparency = Settings.FOVCircle.Transparency
        FOVCircle.Visible = Settings.FOVCircle.Visible and Settings.Aimbot.Enabled
    end

    UpdateESP()

    if aimbotActive and Settings.Aimbot.Enabled and Camera then
        if not currentTarget or not IsAlive(currentTarget) then
            currentTarget = GetClosestTarget()
        end

        if currentTarget and currentTarget.Character then
            local head = currentTarget.Character:FindFirstChild("Head")
            if head then
                local targetCF = CFrame.new(Camera.CFrame.Position, head.Position)
                local alpha = math.clamp((1 - Settings.Aimbot.Smoothness) * (delta * 60), 0.05, 1)
                Camera.CFrame = Camera.CFrame:Lerp(targetCF, alpha)
            end
        end
    end
end)

-- ============================================================
--                 GEZIELTER WALLBANG-HOOK (OHNE METAMETHODEN)
-- ============================================================
local function SetupWallbang()
    local CheckShotEvent = nil
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local name = v.Name:lower()
            if name:find("checkshot") or (name:find("check") and name:find("shot")) then
                CheckShotEvent = v
                break
            end
        end
    end

    if not CheckShotEvent then
        warn("Wallbang: CheckShotEvent nicht gefunden")
        return
    end

    local oldFire = CheckShotEvent.FireServer
    CheckShotEvent.FireServer = function(self, ...)
        local args = {...}
        if Settings.Wallbang.Enabled and aimbotActive then
            local target = currentTarget or GetClosestTarget()
            if target and target.Character then
                local head = target.Character:FindFirstChild("Head")
                if head then
                    -- Ersetze Endpoint (Index 6) und HitInstance (Index 7)
                    if #args >= 7 then
                        args[6] = head.Position   -- Endpoint
                        args[7] = head            -- getroffene Instanz
                    end
                end
            end
        end
        return oldFire(self, unpack(args))
    end
    print("Wallbang-Hook aktiviert (gezielt auf CheckShotEvent)")
end

pcall(SetupWallbang)

for _, player in ipairs(Players:GetPlayers()) do CreateESP(player) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(DestroyESP)

-- ============================================================
--                   RAYFIELD UI INTERFACE
-- ============================================================

local Window = Rayfield:CreateWindow({
    Name = "Delta Hub | Advanced Customization",
    LoadingTitle = "Lade Rayfield...",
    LoadingSubtitle = "V5.0 Ultra Robust",
    ConfigurationSaving = { Enabled = false }
})

local AimbotTab = Window:CreateTab("Aimbot", 4483345998)
local FOVTab = Window:CreateTab("FOV Circle", 4483345998)
local ESPTab = Window:CreateTab("ESP Settings", 4483345998)
local MiscTab = Window:CreateTab("Misc", 4483345998)

-- AIMBOT TAB
AimbotTab:CreateToggle({
    Name = "Aimbot Aktivieren",
    CurrentValue = Settings.Aimbot.Enabled,
    Callback = function(v) Settings.Aimbot.Enabled = v end
})

AimbotTab:CreateSlider({
    Name = "Smoothness (Glättung)",
    Range = {0.01, 0.95},
    Increment = 0.05,
    CurrentValue = Settings.Aimbot.Smoothness,
    Callback = function(v) Settings.Aimbot.Smoothness = v end
})

AimbotTab:CreateDropdown({
    Name = "Aimbot Taste",
    Options = {"Rechte Maustaste (MB2)", "Linkes Alt", "Linkes Control", "Taste E"},
    CurrentOption = "Rechte Maustaste (MB2)",
    Callback = function(option)
        if option == "Rechte Maustaste (MB2)" then
            Settings.Aimbot.AimKey = Enum.UserInputType.MouseButton2
        elseif option == "Linkes Alt" then
            Settings.Aimbot.AimKey = Enum.KeyCode.LeftAlt
        elseif option == "Linkes Control" then
            Settings.Aimbot.AimKey = Enum.KeyCode.LeftControl
        elseif option == "Taste E" then
            Settings.Aimbot.AimKey = Enum.KeyCode.E
        end
    end
})

AimbotTab:CreateToggle({
    Name = "Aimbot Team Check",
    CurrentValue = Settings.Aimbot.TeamCheck,
    Callback = function(v) Settings.Aimbot.TeamCheck = v end
})

-- FOV TAB
FOVTab:CreateToggle({
    Name = "FOV Kreis Anzeigen",
    CurrentValue = Settings.FOVCircle.Visible,
    Callback = function(v) Settings.FOVCircle.Visible = v end
})

FOVTab:CreateToggle({
    Name = "In Bildschirmmitte Fixieren",
    CurrentValue = Settings.FOVCircle.CenterScreen,
    Callback = function(v) Settings.FOVCircle.CenterScreen = v end
})

FOVTab:CreateSlider({
    Name = "FOV Kreis Größe (Radius)",
    Range = {30, 500},
    Increment = 5,
    CurrentValue = Settings.Aimbot.FOV,
    Callback = function(v) 
        Settings.Aimbot.FOV = v 
        Settings.FOVCircle.Radius = v
    end
})

FOVTab:CreateSlider({
    Name = "Linienstärke (Thickness)",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = Settings.FOVCircle.Thickness,
    Callback = function(v) Settings.FOVCircle.Thickness = v end
})

FOVTab:CreateColorPicker({
    Name = "FOV Kreis Farbe",
    Color = Settings.FOVCircle.Color,
    Callback = function(color) Settings.FOVCircle.Color = color end
})

FOVTab:CreateToggle({
    Name = "Ausgefüllter Kreis (Filled)",
    CurrentValue = Settings.FOVCircle.Filled,
    Callback = function(v) Settings.FOVCircle.Filled = v end
})

-- ESP TAB
ESPTab:CreateToggle({
    Name = "ESP Aktivieren",
    CurrentValue = Settings.ESP.Enabled,
    Callback = function(v) Settings.ESP.Enabled = v end
})

ESPTab:CreateToggle({
    Name = "Box ESP",
    CurrentValue = Settings.ESP.Box,
    Callback = function(v) Settings.ESP.Box = v end
})

ESPTab:CreateColorPicker({
    Name = "Box ESP Farbe",
    Color = Settings.ESP.BoxColor,
    Callback = function(color) Settings.ESP.BoxColor = color end
})

ESPTab:CreateToggle({
    Name = "Name ESP",
    CurrentValue = Settings.ESP.Name,
    Callback = function(v) Settings.ESP.Name = v end
})

ESPTab:CreateColorPicker({
    Name = "Name ESP Farbe",
    Color = Settings.ESP.NameColor,
    Callback = function(color) Settings.ESP.NameColor = color end
})

ESPTab:CreateToggle({
    Name = "ESP Team Check",
    CurrentValue = Settings.ESP.TeamCheck,
    Callback = function(v) Settings.ESP.TeamCheck = v end
})

-- MISC TAB
MiscTab:CreateToggle({
    Name = "Wallbang (Schüsse durch Wände)",
    CurrentValue = Settings.Wallbang.Enabled,
    Callback = function(v) Settings.Wallbang.Enabled = v end
})
