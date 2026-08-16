-- ============================================================
--          STABILES WALLBANG + ESP + AIMBOT (Rayfield UI)
--          Optimiert für Delta Executor (Keine Crashes mehr)
-- ============================================================

-- 1. RAYFIELD DIRECT LOAD
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Kamera-Referenz halten
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
end)

-- ============================================================
--                    EINSTELLUNGEN (SETTINGS)
-- ============================================================
local Settings = {
    ESP = {
        Enabled = true,
        Box = true,
        Skeleton = false, -- Standardmäßig AUS zur FPS-Schonung auf Mobilgeräten
        Name = true,
        TeamCheck = true
    },
    Aimbot = {
        Enabled = true,
        FOV = 120,
        Smoothness = 0.2,
        AimKey = Enum.KeyCode.LeftControl,
        TeamCheck = true
    },
    Wallbang = {
        Enabled = true
    }
}

-- ============================================================
--                 DRAWING FOV CIRCLE & ESP CACHE
-- ============================================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 0.7
FOVCircle.Filled = false
FOVCircle.Visible = false

local ESPObjects = {} -- [Player] = {Box, NameText, SkeletonLines = {}}

local function CreateESP(player)
    if ESPObjects[player] then return end
    
    local obj = {
        Box = Drawing.new("Square"),
        NameText = Drawing.new("Text"),
        SkeletonLines = {}
    }

    obj.Box.Thickness = 1.5
    obj.Box.Color = Color3.fromRGB(0, 255, 128)
    obj.Box.Filled = false
    obj.Box.Visible = false

    obj.NameText.Size = 14
    obj.NameText.Color = Color3.fromRGB(255, 255, 255)
    obj.NameText.Center = true
    obj.NameText.Outline = true
    obj.NameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    obj.NameText.Visible = false

    -- Skeleton-Linien dynamisch erst bei Aktivierung erzeugen
    ESPObjects[player] = obj
end

local function DestroyESP(player)
    local obj = ESPObjects[player]
    if not obj then return end

    if obj.Box then pcall(function() obj.Box:Remove() end) end
    if obj.NameText then pcall(function() obj.NameText:Remove() end) end
    if obj.SkeletonLines then
        for _, line in ipairs(obj.SkeletonLines) do
            pcall(function() line:Remove() end)
        end
    end

    ESPObjects[player] = nil
end

-- ============================================================
--                    HELFER-FUNKTIONEN
-- ============================================================
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

local function GetClosestTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local closestPlayer = nil
    local shortestDistance = Settings.Aimbot.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) and IsEnemy(player) then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distScreen = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
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

-- ============================================================
--                    ESP RENDERING
-- ============================================================
local SkeletonConnections = {
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

        if hrp then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                -- Bounding Box
                if Settings.ESP.Box then
                    local head = char:FindFirstChild("Head")
                    local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or pos
                    local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                    local height = math.abs(headPos.Y - legPos.Y)
                    local width = height * 0.65

                    obj.Box.Size = Vector2.new(width, height)
                    obj.Box.Position = Vector2.new(pos.X - width / 2, pos.Y - height / 2)
                    obj.Box.Visible = true
                else
                    obj.Box.Visible = false
                end

                -- Name ESP
                if Settings.ESP.Name then
                    obj.NameText.Position = Vector2.new(pos.X, pos.Y - (obj.Box.Size.Y / 2) - 15)
                    obj.NameText.Text = player.DisplayName or player.Name
                    obj.NameText.Visible = true
                else
                    obj.NameText.Visible = false
                end

                -- Skeleton ESP (Erzeugung nur bei Bedarf)
                if Settings.ESP.Skeleton then
                    if #obj.SkeletonLines == 0 then
                        for i = 1, #SkeletonConnections do
                            local line = Drawing.new("Line")
                            line.Thickness = 1.5
                            line.Color = Color3.fromRGB(0, 200, 255)
                            line.Visible = false
                            table.insert(obj.SkeletonLines, line)
                        end
                    end

                    for index, conn in ipairs(SkeletonConnections) do
                        local part1 = char:FindFirstChild(conn[1])
                        local part2 = char:FindFirstChild(conn[2])

                        if part1 and part2 and obj.SkeletonLines[index] then
                            local v1, vis1 = Camera:WorldToViewportPoint(part1.Position)
                            local v2, vis2 = Camera:WorldToViewportPoint(part2.Position)

                            if vis1 and vis2 then
                                local line = obj.SkeletonLines[index]
                                line.From = Vector2.new(v1.X, v1.Y)
                                line.To = Vector2.new(v2.X, v2.Y)
                                line.Visible = true
                            else
                                obj.SkeletonLines[index].Visible = false
                            end
                        end
                    end
                else
                    for _, line in ipairs(obj.SkeletonLines) do line.Visible = false end
                end

            else
                obj.Box.Visible = false
                obj.NameText.Visible = false
                for _, line in ipairs(obj.SkeletonLines) do line.Visible = false end
            end
        end
    end
end

-- ============================================================
--                    AIMBOT LOGIK
-- ============================================================
local aimbotActive = false
local currentTarget = nil

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Settings.Aimbot.AimKey or input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimbotActive = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Settings.Aimbot.AimKey or input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimbotActive = false
        currentTarget = nil
    end
end)

RunService.RenderStepped:Connect(function(delta)
    local mouseLoc = UserInputService:GetMouseLocation()
    FOVCircle.Position = mouseLoc
    FOVCircle.Radius = Settings.Aimbot.FOV
    FOVCircle.Visible = Settings.Aimbot.Enabled

    UpdateESP()

    if aimbotActive and Settings.Aimbot.Enabled then
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
--           SICHERER WALLBANG HOOK (Gezieltes Hooking)
-- ============================================================
local function InitWallbang()
    -- Suche gezielt nach dem RemoteEvent im Spiel
    local targetRemote = nil
    for _, desc in ipairs(game:GetDescendants()) do
        if desc:IsA("RemoteEvent") then
            local n = desc.Name:lower()
            if n:find("shot") or n:find("bullet") or n:find("checkshot") then
                targetRemote = desc
                break
            end
        end
    end

    if not targetRemote then
        warn("Wallbang: Kein Schuss-Event im Spiel gefunden.")
        return
    end

    -- Hooke NUR die FireServer-Methode dieser speziellen Instanz anstatt des gesamten Spiels
    if typeof(hookfunction) == "function" then
        local oldFireServer
        oldFireServer = hookfunction(targetRemote.FireServer, function(self, ...)
            local args = {...}
            if Settings.Wallbang.Enabled and aimbotActive then
                local target = currentTarget or GetClosestTarget()
                if target and target.Character then
                    local head = target.Character:FindFirstChild("Head")
                    if head then
                        for i, arg in ipairs(args) do
                            if typeof(arg) == "Vector3" then
                                args[i] = head.Position
                            elseif typeof(arg) == "Instance" and arg:IsA("BasePart") then
                                args[i] = head
                            end
                        end
                    end
                end
            end
            return oldFireServer(self, unpack(args))
        end)
    end
end

-- Asynchrone Ausführung des Wallbang-Hooks verhindert Einfrieren des Haupt-Threads
task.defer(InitWallbang)

-- ============================================================
--                 SPIELER-HANDLING
-- ============================================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then CreateESP(player) end
end)

Players.PlayerRemoving:Connect(function(player)
    DestroyESP(player)
end)

-- ============================================================
--                 RAYFIELD UI INITIALISIERUNG
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "Delta Hub | Wallbang + ESP",
    LoadingTitle = "Lade Skript...",
    LoadingSubtitle = "V3.0 Stability Patch",
    ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Aimbot")
local ESPTab = Window:CreateTab("ESP")
local MiscTab = Window:CreateTab("Misc")

-- Aimbot Controls
MainTab:CreateToggle({
    Name = "Aimbot Aktivieren",
    CurrentValue = Settings.Aimbot.Enabled,
    Callback = function(v) Settings.Aimbot.Enabled = v end
})

MainTab:CreateSlider({
    Name = "Aimbot FOV Radius",
    Range = {30, 400},
    Increment = 5,
    CurrentValue = Settings.Aimbot.FOV,
    Callback = function(v) Settings.Aimbot.FOV = v end
})

MainTab:CreateSlider({
    Name = "Smoothness (Höher = Langsamer)",
    Range = {0.01, 0.95},
    Increment = 0.05,
    CurrentValue = Settings.Aimbot.Smoothness,
    Callback = function(v) Settings.Aimbot.Smoothness = v end
})

-- ESP Controls
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

ESPTab:CreateToggle({
    Name = "Skeleton ESP",
    CurrentValue = Settings.ESP.Skeleton,
    Callback = function(v) Settings.ESP.Skeleton = v end
})

ESPTab:CreateToggle({
    Name = "Name ESP",
    CurrentValue = Settings.ESP.Name,
    Callback = function(v) Settings.ESP.Name = v end
})

ESPTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Settings.ESP.TeamCheck,
    Callback = function(v) Settings.ESP.TeamCheck = v end
})

-- Wallbang Control
MiscTab:CreateToggle({
    Name = "Wallbang (Durch Wände)",
    CurrentValue = Settings.Wallbang.Enabled,
    Callback = function(v) Settings.Wallbang.Enabled = v end
})
