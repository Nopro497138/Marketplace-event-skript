-- ============================================================
--          ULTIMATIVE WALLBANG + ESP + AIMBOT (Rayfield UI)
--          Kompatibel mit Delta Executor (Roblox)
-- ============================================================

-- Lade Rayfield (falls nicht vorhanden)
local Rayfield
if not getgenv().Rayfield then
    local success, err = pcall(function()
        Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()
    end)
    if not success then
        warn("Rayfield konnte nicht geladen werden – verwende Fallback-UI")
        Rayfield = nil
    end
else
    Rayfield = getgenv().Rayfield
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- ============================================================
--                    EINSTELLUNGEN (GUI)
-- ============================================================
local Settings = {
    ESP = {
        Box = true,
        Skeleton = true,
        Name = true
    },
    Aimbot = {
        Enabled = true,      -- generell aktiv
        FOV = 90,
        Smoothness = 0.3,
        AimKey = Enum.KeyCode.LeftControl
    },
    Wallbang = {
        Enabled = true
    }
}

-- ============================================================
--                    DRAWING-OBJEKTE VERWALTEN
-- ============================================================
local ESPObjects = {}  -- [Player] = {Box, SkeletonLines, NameText}

local function CreateESP(player)
    if ESPObjects[player] then return end
    local obj = {}
    if Settings.ESP.Box then
        obj.Box = Drawing.new("Box")
        obj.Box.Thickness = 1.5
        obj.Box.Color = Color3.new(0, 1, 0)
        obj.Box.Transparency = 1
        obj.Box.Filled = false
    end
    if Settings.ESP.Name then
        obj.NameText = Drawing.new("Text")
        obj.NameText.Size = 16
        obj.NameText.Color = Color3.new(1, 1, 1)
        obj.NameText.Center = true
        obj.NameText.Outline = true
        obj.NameText.OutlineColor = Color3.new(0, 0, 0)
    end
    if Settings.ESP.Skeleton then
        obj.SkeletonLines = {}
        for i = 1, 12 do
            local line = Drawing.new("Line")
            line.Thickness = 1.5
            line.Color = Color3.new(0, 1, 1)
            line.Transparency = 1
            table.insert(obj.SkeletonLines, line)
        end
    end
    ESPObjects[player] = obj
end

local function DestroyESP(player)
    local obj = ESPObjects[player]
    if not obj then return end
    if obj.Box then obj.Box:Remove() end
    if obj.NameText then obj.NameText:Remove() end
    if obj.SkeletonLines then
        for _, line in ipairs(obj.SkeletonLines) do
            line:Remove()
        end
    end
    ESPObjects[player] = nil
end

-- ============================================================
--                    HELFER FÜR SKELETON
-- ============================================================
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
    -- Nur existierende Teile mit Position
    local pos = {}
    for name, part in pairs(parts) do
        if part then pos[name] = part.Position end
    end
    return pos
end

local function DrawSkeleton(player, obj)
    local character = player.Character
    if not character then return end
    local pos = GetBonePositions(character)
    if not pos or not next(pos) then return end
    
    -- Definiere Verbindungen zwischen Knochen (als Paare)
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
    
    local index = 1
    for _, conn in ipairs(connections) do
        local p1 = pos[conn[1]]
        local p2 = pos[conn[2]]
        if p1 and p2 and obj.SkeletonLines[index] then
            local v1, onScreen1 = Camera:WorldToScreenPoint(p1)
            local v2, onScreen2 = Camera:WorldToScreenPoint(p2)
            if onScreen1 and onScreen2 then
                local line = obj.SkeletonLines[index]
                line.From = Vector2.new(v1.X, v1.Y)
                line.To = Vector2.new(v2.X, v2.Y)
                line.Visible = true
            else
                obj.SkeletonLines[index].Visible = false
            end
        else
            if obj.SkeletonLines[index] then
                obj.SkeletonLines[index].Visible = false
            end
        end
        index = index + 1
    end
end

-- ============================================================
--                    ESP UPDATE-LOOP
-- ============================================================
local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local character = player.Character
        if not character then
            DestroyESP(player)
            continue
        end
        
        -- ESP-Objekte erstellen, falls nicht vorhanden
        if not ESPObjects[player] then
            CreateESP(player)
        end
        local obj = ESPObjects[player]
        if not obj then continue end
        
        -- Box (BoundingBox des Modells)
        if Settings.ESP.Box and obj.Box then
            local min, max = character:GetBoundingBox()
            local center = (min + max) / 2
            local size = max - min
            local screenPos, onScreen = Camera:WorldToScreenPoint(center)
            if onScreen then
                -- Größe anpassen (die Kamera-Entfernung berücksichtigen)
                local dist = (Camera.CFrame.Position - center).Magnitude
                local scale = 200 / math.max(dist, 1)
                local width = size.X * scale * 0.5
                local height = size.Y * scale * 0.5
                obj.Box.Size = Vector2.new(width, height)
                obj.Box.Position = Vector2.new(screenPos.X - width/2, screenPos.Y - height/2)
                obj.Box.Visible = true
            else
                obj.Box.Visible = false
            end
        end
        
        -- Name
        if Settings.ESP.Name and obj.NameText then
            local head = character:FindFirstChild("Head")
            if head then
                local pos, onScreen = Camera:WorldToScreenPoint(head.Position + Vector3.new(0, 1.5, 0))
                if onScreen then
                    obj.NameText.Position = Vector2.new(pos.X, pos.Y - 20)
                    obj.NameText.Text = player.Name
                    obj.NameText.Visible = true
                else
                    obj.NameText.Visible = false
                end
            else
                obj.NameText.Visible = false
            end
        end
        
        -- Skeleton
        if Settings.ESP.Skeleton and obj.SkeletonLines then
            DrawSkeleton(player, obj)
        end
    end
    
    -- Entferne ESP für Spieler, die nicht mehr existieren
    for player, _ in pairs(ESPObjects) do
        if not Players:FindFirstChild(player.Name) then
            DestroyESP(player)
        end
    end
end

-- ============================================================
--                    AIMBOT LOGIK
-- ============================================================
local aimbotActive = false
local currentTarget = nil

-- Bestimme nächsten Spieler (nach Distanz zum eigenen Kopf)
local function GetClosestPlayer()
    local ownChar = LocalPlayer.Character
    if not ownChar then return nil end
    local ownHead = ownChar:FindFirstChild("Head")
    if not ownHead then return nil end
    local ownPos = ownHead.Position
    
    local closest = nil
    local minDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end
        local dist = (head.Position - ownPos).Magnitude
        if dist < minDist then
            minDist = dist
            closest = player
        end
    end
    return closest
end

-- Aimbot-Aktion: Kamera auf Kopf ausrichten & Schuss auslösen
local function PerformAimbot(target)
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    local headPos = head.Position
    
    -- Kamera auf Ziel ausrichten (smooth)
    local currentCF = Camera.CFrame
    local targetCF = CFrame.new(currentCF.Position, headPos)
    if Settings.Aimbot.Smoothness > 0 then
        -- Smooth Interpolation (Lerp)
        local newCF = currentCF:Lerp(targetCF, Settings.Aimbot.Smoothness)
        Camera.CFrame = newCF
    else
        Camera.CFrame = targetCF
    end
    
    -- Mausklick simulieren (schießen)
    -- Viele Executoren haben mouse1click() – falls nicht, alternative Methode
    if mouse1click then
        mouse1click()
    else
        -- Fallback: Input simulieren (nicht immer möglich)
        local mouse = LocalPlayer:GetMouse()
        if mouse and mouse.Button1Down then
            mouse.Button1Down()
            wait(0.01)
            mouse.Button1Up()
        end
    end
end

-- ============================================================
--                    WALLBANG-HOOK (FireServer)
-- ============================================================
local function SetupWallbang()
    -- Finde das CheckShotEvent (wie zuvor)
    local CheckShotEvent = nil
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") and (v.Name == "CheckShotEvent" or string.find(v.Name, "Check") and string.find(v.Name, "Shot")) then
            CheckShotEvent = v
            break
        end
    end
    if not CheckShotEvent then
        warn("Wallbang: CheckShotEvent nicht gefunden – Wallbang deaktiviert")
        return
    end
    
    local oldFire = CheckShotEvent.FireServer
    hookfunction(oldFire, function(self, ...)
        local args = {...}
        -- args: AmmoCount, Spread, MaxAmmo, ReloadTime, CamCFrame, Endpoint, HitInstance, NewSeed, BulletId
        -- Position 6 = Endpoint, 7 = HitInstance
        
        if Settings.Wallbang.Enabled and aimbotActive then
            local target = currentTarget or GetClosestPlayer()
            if target and target.Character then
                local head = target.Character:FindFirstChild("Head")
                if head then
                    args[6] = head.Position
                    args[7] = head
                    -- Optional: kleinen Spread hinzufügen für weniger Auffälligkeit
                    -- args[6] = args[6] + Vector3.new(math.random(-50,50)/100, math.random(-50,50)/100, 0)
                end
            end
        end
        
        return oldFire(self, unpack(args))
    end)
    print("Wallbang-Hook aktiviert")
end

-- ============================================================
--                    TASTENABFRAGE (Left Ctrl)
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.Aimbot.AimKey then
        aimbotActive = true
        -- Sofort Ziel finden
        currentTarget = GetClosestPlayer()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Settings.Aimbot.AimKey then
        aimbotActive = false
        currentTarget = nil
    end
end)

-- Kontinuierlicher Aimbot, wenn aktiv
RunService.Heartbeat:Connect(function()
    if aimbotActive and Settings.Aimbot.Enabled then
        local target = GetClosestPlayer()
        if target then
            currentTarget = target
            PerformAimbot(target)
        end
    end
end)

-- ============================================================
--                    ESP UPDATE (jeder Frame)
-- ============================================================
RunService.RenderStepped:Connect(function()
    UpdateESP()
end)

-- ============================================================
--                    SPIELER-HINZUFÜGEN / ENTFERNEN
-- ============================================================
Players.PlayerAdded:Connect(function(player)
    -- ESP wird bei nächstem Update erstellt
end)

Players.PlayerRemoving:Connect(function(player)
    DestroyESP(player)
end)

-- ============================================================
--                    RAYFIELD UI
-- ============================================================
if Rayfield then
    local Window = Rayfield:CreateWindow({
        Name = "Aimbot + ESP",
        LoadingTitle = "Lade...",
        LoadingSubtitle = "by DeinName",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "MyScripts"
        }
    })
    
    local ESPTab = Window:CreateTab("ESP")
    local AimbotTab = Window:CreateTab("Aimbot")
    local MiscTab = Window:CreateTab("Misc")
    
    -- ESP Toggles
    ESPTab:CreateToggle({
        Name = "Box",
        CurrentValue = Settings.ESP.Box,
        Flag = "ESPBox",
        Callback = function(val)
            Settings.ESP.Box = val
        end
    })
    ESPTab:CreateToggle({
        Name = "Skeleton",
        CurrentValue = Settings.ESP.Skeleton,
        Flag = "ESPSkeleton",
        Callback = function(val)
            Settings.ESP.Skeleton = val
        end
    })
    ESPTab:CreateToggle({
        Name = "Name",
        CurrentValue = Settings.ESP.Name,
        Flag = "ESPName",
        Callback = function(val)
            Settings.ESP.Name = val
        end
    })
    
    -- Aimbot Toggle
    AimbotTab:CreateToggle({
        Name = "Aimbot aktivieren",
        CurrentValue = Settings.Aimbot.Enabled,
        Flag = "AimbotEnabled",
        Callback = function(val)
            Settings.Aimbot.Enabled = val
        end
    })
    AimbotTab:CreateSlider({
        Name = "Smoothness (0 = sofort)",
        Range = {0, 1},
        Increment = 0.05,
        CurrentValue = Settings.Aimbot.Smoothness,
        Flag = "AimSmooth",
        Callback = function(val)
            Settings.Aimbot.Smoothness = val
        end
    })
    AimbotTab:CreateKeybind({
        Name = "Aim-Taste",
        CurrentKeybind = "LeftControl",
        Hold = true,
        Flag = "AimKey",
        Callback = function(key)
            -- Key wird als Enum zurückgegeben
            Settings.Aimbot.AimKey = key
        end
    })
    
    -- Wallbang Toggle
    MiscTab:CreateToggle({
        Name = "Wallbang (durch Wände schießen)",
        CurrentValue = Settings.Wallbang.Enabled,
        Flag = "Wallbang",
        Callback = function(val)
            Settings.Wallbang.Enabled = val
        end
    })
    
    print("Rayfield UI erfolgreich erstellt")
else
    print("Rayfield nicht verfügbar – UI fällt aus, aber Funktionen laufen weiter.")
end

-- ============================================================
--                    INITIALISIERUNG
-- ============================================================
SetupWallbang()

-- Sicherstellen, dass ESP für alle aktuellen Spieler erstellt wird
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

print("Skript geladen – Wallbang, ESP und Aimbot sind bereit!")
