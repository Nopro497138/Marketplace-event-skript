local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Delta | Visuals & Combat",
   LoadingTitle = "Lade Skript...",
   LoadingSubtitle = "Keybind Customization",
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false },
   KeySystem = false
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Einstellungen
local Settings = {
    ESP = {
        Enabled = false,
        ShowNames = true,
        ShowDistance = true,
        HighlightColor = Color3.fromRGB(0, 255, 0),
        TextColor = Color3.fromRGB(255, 255, 255)
    },
    Aimbot = {
        Enabled = false,
        Smoothness = 0.2,
        TargetPart = "Head",
        Keybind = Enum.KeyCode.LeftAlt -- Standard Keybind
    }
}

-- Tabs
local VisualsTab = Window:CreateTab("Visuals (ESP)", 4483362458)
local CombatTab = Window:CreateTab("Combat (Aimbot)", 4483362458)

---------------------------------------------------------
-- ESP LOGIK
---------------------------------------------------------

local function applyESP(player, character)
    if player == LocalPlayer or not character then return end
    
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    -- Highlight (Chams)
    local highlight = character:FindFirstChild("ESPHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.Adornee = character
        highlight.Parent = character
    end
    
    highlight.Enabled = Settings.ESP.Enabled
    highlight.FillColor = Settings.ESP.HighlightColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    
    -- Text Billboard (Name & Distanz)
    local billboard = head:FindFirstChild("ESPBillboard")
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPBillboard"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "ESPLabel"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextSize = 14
        textLabel.TextStrokeTransparency = 0
        textLabel.Parent = billboard
    end
    
    local textLabel = billboard:FindFirstChild("ESPLabel")
    if textLabel then
        textLabel.TextColor3 = Settings.ESP.TextColor
        
        if Settings.ESP.Enabled then
            billboard.Enabled = true
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local targetRoot = character:FindFirstChild("HumanoidRootPart")
            
            local textParts = {}
            if Settings.ESP.ShowNames then
                table.insert(textParts, player.DisplayName or player.Name)
            end
            
            if Settings.ESP.ShowDistance and myRoot and targetRoot then
                local studs = (targetRoot.Position - myRoot.Position).Magnitude
                local meters = math.floor(studs * 0.28)
                table.insert(textParts, string.format("[%dm]", meters))
            end
            
            textLabel.Text = table.concat(textParts, " ")
        else
            billboard.Enabled = false
        end
    end
end

local function cleanESP(character)
    if not character then return end
    local highlight = character:FindFirstChild("ESPHighlight")
    if highlight then highlight:Destroy() end
    
    local head = character:FindFirstChild("Head")
    if head then
        local billboard = head:FindFirstChild("ESPBillboard")
        if billboard then billboard:Destroy() end
    end
end

---------------------------------------------------------
-- AIMBOT LOGIK
---------------------------------------------------------

local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local targetPart = player.Character:FindFirstChild(Settings.Aimbot.TargetPart)
            
            if humanoid and humanoid.Health > 0 and targetPart then
                local distance = (targetPart.Position - myRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

---------------------------------------------------------
-- RENDER BINDINGS
---------------------------------------------------------

-- ESP Loop
RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if Settings.ESP.Enabled then
                applyESP(player, player.Character)
            else
                cleanESP(player.Character)
            end
        end
    end
end)

-- First-Person Aimbot Binding
RunService:BindToRenderStep("FirstPersonAimbot", Enum.RenderPriority.Camera.Value + 1, function()
    if Settings.Aimbot.Enabled and Settings.Aimbot.Keybind then
        -- Prüfe, ob die im Keybind eingestellte Taste gedrückt gehalten wird
        local isKeyPressed = UserInputService:IsKeyDown(Settings.Aimbot.Keybind)
        if isKeyPressed then
            local targetPlayer = getClosestPlayer()
            if targetPlayer and targetPlayer.Character then
                local targetPart = targetPlayer.Character:FindFirstChild(Settings.Aimbot.TargetPart)
                if targetPart then
                    local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                    
                    if Settings.Aimbot.Smoothness > 0 and Settings.Aimbot.Smoothness < 1 then
                        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.Aimbot.Smoothness)
                    else
                        Camera.CFrame = targetCFrame
                    end
                end
            end
        end
    end
end)

---------------------------------------------------------
-- UI CONTROLS: VISUALS
---------------------------------------------------------

VisualsTab:CreateToggle({
   Name = "ESP Aktivieren",
   CurrentValue = false,
   Flag = "ESPMasterToggle",
   Callback = function(Value)
      Settings.ESP.Enabled = Value
      if not Value then
          for _, player in ipairs(Players:GetPlayers()) do
              if player.Character then cleanESP(player.Character) end
          end
      end
   end,
})

VisualsTab:CreateToggle({
   Name = "Namen anzeigen",
   CurrentValue = true,
   Flag = "ESPShowNames",
   Callback = function(Value)
      Settings.ESP.ShowNames = Value
   end,
})

VisualsTab:CreateToggle({
   Name = "Distanz (Meter) anzeigen",
   CurrentValue = true,
   Flag = "ESPShowDistance",
   Callback = function(Value)
      Settings.ESP.ShowDistance = Value
   end,
})

VisualsTab:CreateColorPicker({
    Name = "Highlight Farbe",
    Color = Color3.fromRGB(0, 255, 0),
    Flag = "ESPHighlightColor",
    Callback = function(Value)
        Settings.ESP.HighlightColor = Value
    end,
})

VisualsTab:CreateColorPicker({
    Name = "Text Farbe",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "ESPTextColor",
    Callback = function(Value)
        Settings.ESP.TextColor = Value
    end,
})

---------------------------------------------------------
-- UI CONTROLS: COMBAT
---------------------------------------------------------

CombatTab:CreateToggle({
   Name = "Aimbot Aktivieren",
   CurrentValue = false,
   Flag = "AimbotMasterToggle",
   Callback = function(Value)
      Settings.Aimbot.Enabled = Value
   end,
})

CombatTab:CreateKeybind({
   Name = "Aimbot Hold Keybind",
   CurrentKeybind = "LeftAlt",
   HoldToInteract = true,
   Flag = "AimbotKeybind",
   Callback = function(Keybind)
      -- Speichert den ausgewählten Keycode dynamisch ab
      Settings.Aimbot.Keybind = Enum.KeyCode[Keybind] or Enum.KeyCode.LeftAlt
   end,
})

CombatTab:CreateSlider({
   Name = "Aimbot Smoothness (Sanftheit)",
   Range = {0.05, 1},
   Increment = 0.05,
   Suffix = "Speed",
   CurrentValue = 0.2,
   Flag = "AimbotSmoothness",
   Callback = function(Value)
      Settings.Aimbot.Smoothness = Value
   end,
})

CombatTab:CreateDropdown({
   Name = "Zielkörperteil",
   Options = {"Head", "HumanoidRootPart"},
   CurrentOption = "Head",
   Flag = "AimbotTargetPart",
   Callback = function(Option)
      Settings.Aimbot.TargetPart = Option
   end,
})

Rayfield:Notify({
   Title = "Script Geladen!",
   Content = "Keybinds sind jetzt im Combat-Tab anpassbar.",
   Duration = 3,
   Image = 4483362458,
})
