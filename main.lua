-- ============================================================
--          DELTA EXECUTOR - CRASH-PROOF AIMBOT + ESP + WALLBANG
-- ============================================================

-- 1. WARTEN BIS SPIEL VOLLSTÄNDIG GELADEN IST
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Rayfield UI (Mit Auto-Fallback gegen 404-Fehler)
local Rayfield
local urls = {
    "https://sirius.menu/rayfield",
    "https://raw.githubusercontent.com/SiriusMenu/Rayfield/main/source.lua",
    "https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"
}

for _, url in ipairs(urls) do
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if success and result then
        Rayfield = result
        break
    end
end

if not Rayfield then
    warn("Rayfield konnte über keine der Quellen geladen werden.")
    return
end

-- Kamera-Referenz automatisch erneuern
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
end)

-- Einstellungen
local Settings = {
    ESP = {
        Enabled = true,
        Box = true,
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

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 0.7
FOVCircle.Filled = false
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
    obj.Box.Color = Color3.fromRGB(0, 255, 128)
    obj.Box.Filled = false
    obj.Box.Visible = false

    obj.NameText.Size = 14
    obj.NameText.Color = Color3.fromRGB(255, 255, 255)
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

-- Helfer
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
    if not Camera then return nil end
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

-- ESP Loop
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
                    obj.Box.Visible = true
                else
                    if obj.Box then obj.Box.Visible = false end
                end

                if Settings.ESP.Name and obj.NameText then
                    obj.NameText.Position = Vector2.new(pos.X, pos.Y - (obj.Box.Size.Y / 2) - 15)
                    obj.NameText.Text = player.DisplayName or player.Name
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

-- Aimbot State
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
    if FOVCircle then
        local mouseLoc = UserInputService:GetMouseLocation()
        FOVCircle.Position = mouseLoc
        FOVCircle.Radius = Settings.Aimbot.FOV
        FOVCircle.Visible = Settings.Aimbot.Enabled
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

-- SICHERER WALLBANG HOOK VIA METATABLE
local function SetupWallbang()
    if not hookmetamethod then return end

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        
        if Settings.Wallbang.Enabled and aimbotActive and not checkcaller() then
            if method == "FireServer" or method == "fireServer" then
                if typeof(self) == "Instance" and self:IsA("RemoteEvent") then
                    local name = self.Name:lower()
                    if name:find("shot") or name:find("bullet") or name:find("check") or name:find("hit") or name:find("damage") then
                        local target = currentTarget or GetClosestTarget()
                        if target and target.Character then
                            local head = target.Character:FindFirstChild("Head")
                            if head then
                                local args = {...}
                                for i = 1, #args do
                                    if typeof(args[i]) == "Vector3" then
                                        args[i] = head.Position
                                    elseif typeof(args[i]) == "Instance" and args[i]:IsA("BasePart") then
                                        args[i] = head
                                    end
                                end
                                return oldNamecall(self, unpack(args))
                            end
                        end
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end

pcall(SetupWallbang)

-- Player Management
for _, player in ipairs(Players:GetPlayers()) do
    CreateESP(player)
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(DestroyESP)

-- UI Creation
local Window = Rayfield:CreateWindow({
    Name = "Delta Hub | Wallbang + ESP",
    LoadingTitle = "Lade Skript...",
    LoadingSubtitle = "V4.1 Fix 404",
    ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Aimbot")
local ESPTab = Window:CreateTab("ESP")
local MiscTab = Window:CreateTab("Misc")

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
    Name = "Smoothness",
    Range = {0.01, 0.95},
    Increment = 0.05,
    CurrentValue = Settings.Aimbot.Smoothness,
    Callback = function(v) Settings.Aimbot.Smoothness = v end
})

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
    Name = "Name ESP",
    CurrentValue = Settings.ESP.Name,
    Callback = function(v) Settings.ESP.Name = v end
})

ESPTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Settings.ESP.TeamCheck,
    Callback = function(v) Settings.ESP.TeamCheck = v end
})

MiscTab:CreateToggle({
    Name = "Wallbang (Durch Wände)",
    CurrentValue = Settings.Wallbang.Enabled,
    Callback = function(v) Settings.Wallbang.Enabled = v end
})
