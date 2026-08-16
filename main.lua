-- ============================================================
--          DELTA HUB ULTIMATE (ESP + AIMBOT + WALLBANG)
-- ============================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Aktuelle Kamera immer aktuell halten
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
end)

-- Rayfield laden (Multi-Mirror)
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
            if raw and #raw > 100 then return loadstring(raw)() end
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
    warn("Rayfield konnte nicht geladen werden.")
    return
end

-- ============================================================
--                         EINSTELLUNGEN
-- ============================================================
local Settings = {
    Aimbot = {
        Enabled = true,
        FOV = 150,
        Smoothness = 0.3,
        AimKey = Enum.KeyCode.LeftControl,
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
        Skeleton = true,
        SkeletonColor = Color3.fromRGB(0, 200, 255),
        TeamCheck = true
    },
    Wallbang = {
        Enabled = true
    }
}

-- FOV Circle (Drawing)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = Settings.FOVCircle.Thickness
FOVCircle.Color = Settings.FOVCircle.Color
FOVCircle.Transparency = Settings.FOVCircle.Transparency
FOVCircle.Filled = Settings.FOVCircle.Filled
FOVCircle.Visible = false

-- ESP Cache
local ESPObjects = {}

-- ============================================================
--                         ESP FUNKTIONEN
-- ============================================================
local function CreateESP(player)
    if ESPObjects[player] or player == LocalPlayer then return end
    local obj = {
        Box = Drawing.new("Square"),
        NameText = Drawing.new("Text"),
        SkeletonLines = {}
    }
    -- Box
    obj.Box.Thickness = 1.5
    obj.Box.Color = Settings.ESP.BoxColor
    obj.Box.Filled = false
    obj.Box.Visible = false
    -- Name
    obj.NameText.Size = 14
    obj.NameText.Color = Settings.ESP.NameColor
    obj.NameText.Center = true
    obj.NameText.Outline = true
    obj.NameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    obj.NameText.Visible = false
    -- Skeleton (14 Linien)
    for i = 1, 14 do
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Color = Settings.ESP.SkeletonColor
        line.Visible = false
        table.insert(obj.SkeletonLines, line)
    end
    ESPObjects[player] = obj
end

local function DestroyESP(player)
    local obj = ESPObjects[player]
    if not obj then return end
    pcall(function() obj.Box:Remove() end)
    pcall(function() obj.NameText:Remove() end)
    for _, line in ipairs(obj.SkeletonLines) do pcall(function() line:Remove() end) end
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

-- Hilfsfunktion: Gelenkpositionen für Skeleton
local function GetBonePositions(character)
    local parts = {
        Head = character:FindFirstChild("Head"),
        UpperTorso = character:FindFirstChild("UpperTorso"),
        LowerTorso = character:FindFirstChild("LowerTorso"),
        LeftUpperArm = character:FindFirstChild("LeftUpperArm"),
        LeftLowerArm = character:FindFirstChild("LeftLowerArm"),
        LeftHand = character:FindFirstChild("LeftHand"),
        RightUpperArm = character:FindFirstChild("RightUpperArm"),
        RightLowerArm = character:FindFirstChild("RightLowerArm"),
        RightHand = character:FindFirstChild("RightHand"),
        LeftUpperLeg = character:FindFirstChild("LeftUpperLeg"),
        LeftLowerLeg = character:FindFirstChild("LeftLowerLeg"),
        LeftFoot = character:FindFirstChild("LeftFoot"),
        RightUpperLeg = character:FindFirstChild("RightUpperLeg"),
        RightLowerLeg = character:FindFirstChild("RightLowerLeg"),
        RightFoot = character:FindFirstChild("RightFoot")
    }
    local pos = {}
    for name, part in pairs(parts) do
        if part then pos[name] = part.Position end
    end
    return pos
end

local function UpdateESP()
    for player, obj in pairs(ESPObjects) do
        if not Players:FindFirstChild(player.Name) or not IsAlive(player) or not IsEnemy(player) or not Settings.ESP.Enabled then
            obj.Box.Visible = false
            obj.NameText.Visible = false
            for _, line in ipairs(obj.SkeletonLines) do line.Visible = false end
            continue
        end

        local char = player.Character
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
        if not hrp or not Camera then
            obj.Box.Visible = false
            obj.NameText.Visible = false
            for _, line in ipairs(obj.SkeletonLines) do line.Visible = false end
            continue
        end

        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            obj.Box.Visible = false
            obj.NameText.Visible = false
            for _, line in ipairs(obj.SkeletonLines) do line.Visible = false end
            continue
        end

        -- ---- BOX ----
        if Settings.ESP.Box then
            local head = char:FindFirstChild("Head")
            local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or pos
            local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            local height = math.abs(headPos.Y - legPos.Y)
            local width = height * 0.65
            obj.Box.Size = Vector2.new(width, height)
            obj.Box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
            obj.Box.Color = Settings.ESP.BoxColor
            obj.Box.Visible = true
        else
            obj.Box.Visible = false
        end

        -- ---- NAME ----
        if Settings.ESP.Name then
            obj.NameText.Position = Vector2.new(pos.X, pos.Y - (obj.Box.Size.Y / 2) - 15)
            obj.NameText.Text = player.DisplayName or player.Name
            obj.NameText.Color = Settings.ESP.NameColor
            obj.NameText.Visible = true
        else
            obj.NameText.Visible = false
        end

        -- ---- SKELETON ----
        if Settings.ESP.Skeleton then
            local bonePos = GetBonePositions(char)
            local connections = {
                {"Head", "UpperTorso"},
                {"UpperTorso", "LowerTorso"},
                {"UpperTorso", "LeftUpperArm"},
                {"LeftUpperArm", "LeftLowerArm"},
                {"LeftLowerArm", "LeftHand"},
                {"UpperTorso", "RightUpperArm"},
                {"RightUpperArm", "RightLowerArm"},
                {"RightLowerArm", "RightHand"},
                {"LowerTorso", "LeftUpperLeg"},
                {"LeftUpperLeg", "LeftLowerLeg"},
                {"LeftLowerLeg", "LeftFoot"},
                {"LowerTorso", "RightUpperLeg"},
                {"RightUpperLeg", "RightLowerLeg"},
                {"RightLowerLeg", "RightFoot"}
            }
            for idx, conn in ipairs(connections) do
                local p1 = bonePos[conn[1]]
                local p2 = bonePos[conn[2]]
                local line = obj.SkeletonLines[idx]
                if p1 and p2 then
                    local v1, on1 = Camera:WorldToViewportPoint(p1)
                    local v2, on2 = Camera:WorldToViewportPoint(p2)
                    if on1 and on2 then
                        line.From = Vector2.new(v1.X, v1.Y)
                        line.To = Vector2.new(v2.X, v2.Y)
                        line.Color = Settings.ESP.SkeletonColor
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
        else
            for _, line in ipairs(obj.SkeletonLines) do line.Visible = false end
        end
    end
end

-- ============================================================
--                         AIMBOT
-- ============================================================
local aimbotActive = false
local currentTarget = nil

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
    local closest = nil
    local shortestDist = Settings.Aimbot.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) and IsEnemy(player) then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - originPos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

-- Tasten: Linke Strg zum Aktivieren
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Settings.Aimbot.AimKey then
        aimbotActive = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Settings.Aimbot.AimKey then
        aimbotActive = false
        currentTarget = nil
    end
end)

-- Hauptloop
RunService.RenderStepped:Connect(function(delta)
    -- FOV Kreis aktualisieren
    FOVCircle.Position = GetFOVPosition()
    FOVCircle.Radius = Settings.Aimbot.FOV
    FOVCircle.Color = Settings.FOVCircle.Color
    FOVCircle.Thickness = Settings.FOVCircle.Thickness
    FOVCircle.Filled = Settings.FOVCircle.Filled
    FOVCircle.Transparency = Settings.FOVCircle.Transparency
    FOVCircle.Visible = Settings.FOVCircle.Visible and Settings.Aimbot.Enabled

    -- ESP aktualisieren
    UpdateESP()

    -- Aimbot
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
--                         WALLBANG (Sicherer Hook)
-- ============================================================
local function SetupWallbang()
    local CheckShotEvent = nil
    -- Durchsuche das gesamte Spiel nach dem Event
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
        warn("Wallbang: CheckShotEvent nicht gefunden.")
        return
    end

    local oldFire = CheckShotEvent.FireServer
    -- Überschreibe die Funktion direkt (kein Metamethod-Hook)
    CheckShotEvent.FireServer = function(self, ...)
        local args = {...}
        if Settings.Wallbang.Enabled and aimbotActive then
            local target = currentTarget or GetClosestTarget()
            if target and target.Character then
                local head = target.Character:FindFirstChild("Head")
                if head then
                    -- Ersetze Endpoint (Index 6) und HitInstance (Index 7)
                    if #args >= 7 then
                        args[6] = head.Position
                        args[7] = head
                    end
                end
            end
        end
        return oldFire(self, unpack(args))
    end
    print("Wallbang-Hook aktiviert (CheckShotEvent)")
end

pcall(SetupWallbang)

-- ============================================================
--                         SPIELER-VERWALTUNG
-- ============================================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then CreateESP(player) end
end)
Players.PlayerRemoving:Connect(DestroyESP)

-- ============================================================
--                         RAYFIELD UI
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "Delta Hub Ultimate",
    LoadingTitle = "Lade ...",
    LoadingSubtitle = "V6.0",
    ConfigurationSaving = { Enabled = false }
})

local AimbotTab = Window:CreateTab("Aimbot", 4483345998)
local FOVTab = Window:CreateTab("FOV", 4483345998)
local ESPTab = Window:CreateTab("ESP", 4483345998)
local MiscTab = Window:CreateTab("Misc", 4483345998)

-- Aimbot
AimbotTab:CreateToggle({
    Name = "Aimbot aktivieren",
    CurrentValue = Settings.Aimbot.Enabled,
    Callback = function(v) Settings.Aimbot.Enabled = v end
})
AimbotTab:CreateSlider({
    Name = "Smoothness",
    Range = {0, 0.95},
    Increment = 0.05,
    CurrentValue = Settings.Aimbot.Smoothness,
    Callback = function(v) Settings.Aimbot.Smoothness = v end
})
AimbotTab:CreateDropdown({
    Name = "Aim-Taste",
    Options = {"Linke Strg", "Rechte Maustaste", "Linkes Alt", "E"},
    CurrentOption = "Linke Strg",
    Callback = function(opt)
        if opt == "Linke Strg" then Settings.Aimbot.AimKey = Enum.KeyCode.LeftControl
        elseif opt == "Rechte Maustaste" then Settings.Aimbot.AimKey = Enum.UserInputType.MouseButton2
        elseif opt == "Linkes Alt" then Settings.Aimbot.AimKey = Enum.KeyCode.LeftAlt
        elseif opt == "E" then Settings.Aimbot.AimKey = Enum.KeyCode.E end
    end
})
AimbotTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Settings.Aimbot.TeamCheck,
    Callback = function(v) Settings.Aimbot.TeamCheck = v end
})

-- FOV
FOVTab:CreateToggle({
    Name = "FOV Kreis anzeigen",
    CurrentValue = Settings.FOVCircle.Visible,
    Callback = function(v) Settings.FOVCircle.Visible = v end
})
FOVTab:CreateToggle({
    Name = "Am Bildschirmzentrum fixieren",
    CurrentValue = Settings.FOVCircle.CenterScreen,
    Callback = function(v) Settings.FOVCircle.CenterScreen = v end
})
FOVTab:CreateSlider({
    Name = "FOV Radius",
    Range = {30, 500},
    Increment = 5,
    CurrentValue = Settings.Aimbot.FOV,
    Callback = function(v)
        Settings.Aimbot.FOV = v
        Settings.FOVCircle.Radius = v
    end
})
FOVTab:CreateSlider({
    Name = "Linienstärke",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = Settings.FOVCircle.Thickness,
    Callback = function(v) Settings.FOVCircle.Thickness = v end
})
FOVTab:CreateColorPicker({
    Name = "Kreis Farbe",
    Color = Settings.FOVCircle.Color,
    Callback = function(c) Settings.FOVCircle.Color = c end
})
FOVTab:CreateToggle({
    Name = "Gefüllt",
    CurrentValue = Settings.FOVCircle.Filled,
    Callback = function(v) Settings.FOVCircle.Filled = v end
})

-- ESP
ESPTab:CreateToggle({
    Name = "ESP aktivieren",
    CurrentValue = Settings.ESP.Enabled,
    Callback = function(v) Settings.ESP.Enabled = v end
})
ESPTab:CreateToggle({
    Name = "Box",
    CurrentValue = Settings.ESP.Box,
    Callback = function(v) Settings.ESP.Box = v end
})
ESPTab:CreateColorPicker({
    Name = "Box Farbe",
    Color = Settings.ESP.BoxColor,
    Callback = function(c) Settings.ESP.BoxColor = c end
})
ESPTab:CreateToggle({
    Name = "Name",
    CurrentValue = Settings.ESP.Name,
    Callback = function(v) Settings.ESP.Name = v end
})
ESPTab:CreateColorPicker({
    Name = "Name Farbe",
    Color = Settings.ESP.NameColor,
    Callback = function(c) Settings.ESP.NameColor = c end
})
ESPTab:CreateToggle({
    Name = "Skeleton",
    CurrentValue = Settings.ESP.Skeleton,
    Callback = function(v) Settings.ESP.Skeleton = v end
})
ESPTab:CreateColorPicker({
    Name = "Skeleton Farbe",
    Color = Settings.ESP.SkeletonColor,
    Callback = function(c) Settings.ESP.SkeletonColor = c end
})
ESPTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Settings.ESP.TeamCheck,
    Callback = function(v) Settings.ESP.TeamCheck = v end
})

-- Misc (Wallbang)
MiscTab:CreateToggle({
    Name = "Wallbang (durch Wände schießen)",
    CurrentValue = Settings.Wallbang.Enabled,
    Callback = function(v) Settings.Wallbang.Enabled = v end
})

print("Delta Hub Ultimate geladen – viel Spaß!")
