-- ============================================================
--          DELTA EXECUTOR - CRASH-PROOF AIMBOT + ESP + WALLBANG
--                   (NATIVE UI - ZERO HTTP / NO 404)
-- ============================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
end)

-- Einstellungen
local Settings = {
    ESP = { Enabled = true, Box = true, Name = true, TeamCheck = true },
    Aimbot = { Enabled = true, FOV = 120, Smoothness = 0.2, AimKey = Enum.KeyCode.LeftControl, TeamCheck = true },
    Wallbang = { Enabled = true }
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

-- Aimbot Loop
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

-- Wallbang Hook
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

for _, player in ipairs(Players:GetPlayers()) do CreateESP(player) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(DestroyESP)

-- NATIVES SCREEN-GUI ERSTELLEN (KEIN DOWNLOAD ERFORDERLICH)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaHubNativeUI"
ScreenGui.ResetOnSpawn = false

pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 280)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
Title.Text = " Delta Hub (Native) "
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -20, 1, -45)
Container.Position = UDim2.new(0, 10, 0, 40)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 8)
UIList.Parent = Container

local function CreateToggleButton(text, defaultState, callback)
    local state = defaultState
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 90) or Color3.fromRGB(50, 50, 58)
    btn.Text = text .. ": " .. (state and "AN" or "AUS")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextSize = 14
    btn.Parent = Container

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 90) or Color3.fromRGB(50, 50, 58)
        btn.Text = text .. ": " .. (state and "AN" or "AUS")
        callback(state)
    end)
end

CreateToggleButton("Aimbot", Settings.Aimbot.Enabled, function(v) Settings.Aimbot.Enabled = v end)
CreateToggleButton("ESP Box", Settings.ESP.Box, function(v) Settings.ESP.Box = v end)
CreateToggleButton("ESP Name", Settings.ESP.Name, function(v) Settings.ESP.Name = v end)
CreateToggleButton("Team Check", Settings.ESP.TeamCheck, function(v) Settings.ESP.TeamCheck = v end)
CreateToggleButton("Wallbang", Settings.Wallbang.Enabled, function(v) Settings.Wallbang.Enabled = v end)
