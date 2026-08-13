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
local StatusLabel = Tab:CreateLabel("Status: Bereit (Left CTRL / Right CTRL)")

-- Variablen für die Target-Funktion & Unsichtbarkeit
local targetPlayerName = ""
local followTargetEnabled = false
local isInvisibleUnderground = false
local savedCharacterParts = {}

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
         StatusLabel:Set("Status: Bereit")
      end
   end,
})

-- Loop der dich vor das Target setzt, solange aktiv
RunService.RenderStepped:Connect(function()
    if not followTargetEnabled then return end
    
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
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
        rootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -3)
    end
end)

-- Funktion zum Markieren von direkten Workspace Models
local function highlightWorkspaceModels()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
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

-- Keybind Logik für Left CTRL & Right CTRL
local isExecuting = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Left CTRL: Aim und 5 Klicks mit 0.3s Cooldown
    if input.KeyCode == Enum.KeyCode.LeftControl and not isExecuting then
        isExecuting = true
        StatusLabel:Set("Status: Ziel anvisieren...")
        
        local target = getClosestModel()
        if target then
            local targetPart = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
            if targetPart and Camera then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                
                for i = 1, 5 do
                    StatusLabel:Set("Status: Klick " .. i .. "/5")
                    pcall(function()
                        mouse1click()
                    end)
                    task.wait(0.3)
                end
            end
        else
            StatusLabel:Set("Status: Kein Ziel gefunden!")
            task.wait(1)
        end
        
        if not followTargetEnabled then
            StatusLabel:Set("Status: Bereit")
        end
        isExecuting = false
        
    -- Right CTRL: Unsichtbar machen & 10 Studs runter (bzw. wieder zurück)
    elseif input.KeyCode == Enum.KeyCode.RightControl then
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        
        if character and rootPart then
            isInvisibleUnderground = not isInvisibleUnderground
            
            if isInvisibleUnderground then
                StatusLabel:Set("Status: Unsichtbar & Getaucht")
                -- 10 Studs nach unten teleportieren
                rootPart.CFrame = rootPart.CFrame + Vector3.new(0, -10, 0)
                
                -- Unsichtbar machen (Transparenz auf 1 für alle Teile)
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        savedCharacterParts[part] = part.Transparency
                        part.Transparency = 1
                    end
                end
            else
                StatusLabel:Set("Status: Sichtbar & Zurück")
                -- 10 Studs nach oben zurückteleportieren
                rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 10, 0)
                
                -- Wieder sichtbar machen
                for part, originalTransparency in pairs(savedCharacterParts) do
                    if part and part.Parent then
                        part.Transparency = originalTransparency
                    end
                end
                savedCharacterParts = {}
            end
        end
    end
end)

Rayfield:LoadConfiguration()
