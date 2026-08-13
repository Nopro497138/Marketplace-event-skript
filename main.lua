-- Rayfield UI laden
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Workspace Model Highlighter",
   LoadingTitle = "Delta Script",
   LoadingSubtitle = "by AI",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local Tab = Window:CreateTab("Main", 4483362458)

-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Status Label im Rayfield UI
local StatusLabel = Tab:CreateLabel("Status: Bereit (Drücke Left CTRL)")

-- Variablen für die Target-Funktion
local targetPlayerName = ""
local followTargetEnabled = false

-- Rayfield UI Elemente
Tab:CreateInput({
   Name = "Target Player Name",
   PlaceholderText = "Spielername eingeben...",
   RemoveTextAfterFocusLost = false,
   Callback = function(text)
      targetPlayerName = text
   end,
})

Tab:CreateToggle({
   Name = "Vor Target stehen",
   CurrentValue = false,
   Flag = "FollowToggle",
   Callback = function(value)
      followTargetEnabled = value
      if value then
         StatusLabel:Set("Status: Folge " .. (targetPlayerName ~= "" and targetPlayerName or "Niemand") .. "...")
      else
         StatusLabel:Set("Status: Bereit (Drücke Left CTRL)")
      end
   end,
})

-- Loop der dich vor das Target setzt, solange aktiv
RunService.RenderStepped:Connect(function()
    if not followTargetEnabled then return end
    
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Finde den Spieler anhand des Namens (auch Teilnamen funktionieren)
    local targetChar = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Name:lower():sub(1, #targetPlayerName) == targetPlayerName:lower() then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                targetChar = player.Character
                break
            end
        end
    end
    
    if targetChar then
        local targetRoot = targetChar.HumanoidRootPart
        -- Setze den Charakter direkt vor das Target (z.B. 3 Studs vor dessen Blickrichtung)
        rootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -3)
    end
end)

-- Funktion zum Markieren von direkten Workspace Models
local function highlightWorkspaceModels()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            -- Prüfen ob bereits ein Highlight existiert
            if not obj:FindFirstChildOfClass("Highlight") then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
                highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.Adornee = obj
                highlight.Parent = obj
            end
        end
    end
end

-- Initial ausführen und auf neue Workspace-Kinder lauschen
highlightWorkspaceModels()
Workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") then
        task.wait(0.1)
        highlightWorkspaceModels()
    end
end)

-- Nächstes direktes Workspace Model finden
local function getClosestModel()
    local closest = nil
    local shortestDistance = math.huge
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not rootPart then return nil end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= character then
            local targetPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
            if targetPart then
                local distance = (targetPart.Position - rootPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closest = obj
                end
            end
        end
    end
    
    return closest
end

-- Keybind Logik für Left CTRL
local isExecuting = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.LeftControl and not isExecuting then
        isExecuting = true
        StatusLabel:Set("Status: Ziel anvisieren...")
        
        local target = getClosestModel()
        if target then
            local targetPart = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
            if targetPart and Camera then
                -- Direkt auf das Model aimen
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                
                -- 5 mal klicken mit 0.5 Sekunden Pause dazwischen
                for i = 1, 5 do
                    StatusLabel:Set("Status: Klick " .. i .. "/5")
                    pcall(function()
                        mouse1click()
                    end)
                    task.wait(0.5)
                end
            end
        else
            StatusLabel:Set("Status: Kein Ziel gefunden!")
            task.wait(1)
        end
        
        if not followTargetEnabled then
            StatusLabel:Set("Status: Bereit (Drücke Left CTRL)")
        end
        isExecuting = false
    end
end)

Rayfield:LoadConfiguration()
