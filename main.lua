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

-- Status Label
local StatusLabel = Tab:CreateLabel("Status: Bereit (Left CTRL / L)")

-- Variablen
local targetPlayerName = ""
local followTargetEnabled = false
local isInvisibleUnderground = false
local savedCharacterParts = {}

-- Rayfield UI Elemente
Tab:CreateInput({
   Name = "Target Player Name",
   PlaceholderText = "Spielername...",
   RemoveTextAfterFocusLost = false,
   Callback = function(text) targetPlayerName = text end,
})

Tab:CreateToggle({
   Name = "Vor Target stehen",
   CurrentValue = false,
   Callback = function(value) followTargetEnabled = value end,
})

-- Teleport-Loop
RunService.RenderStepped:Connect(function()
    if not followTargetEnabled then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
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
        root.CFrame = targetChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
    end
end)

-- Workspace Highlighting
local function highlightWorkspaceModels()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character and not obj:FindFirstChildOfClass("Highlight") then
            local highlight = Instance.new("Highlight")
            highlight.FillColor = Color3.fromRGB(0, 255, 0)
            highlight.Adornee = obj
            highlight.Parent = obj
        end
    end
end

highlightWorkspaceModels()
Workspace.ChildAdded:Connect(function(child) if child:IsA("Model") then task.wait(0.1) highlightWorkspaceModels() end end)

-- Closest Model Finden
local function getClosestModel()
    local closest, shortest = nil, math.huge
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local p = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
            if p then
                local dist = (p.Position - root.Position).Magnitude
                if dist < shortest then shortest = dist; closest = obj end
            end
        end
    end
    return closest
end

-- Input Handling
local isExecuting = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Left CTRL: Aim & Klick
    if input.KeyCode == Enum.KeyCode.LeftControl and not isExecuting then
        isExecuting = true
        local target = getClosestModel()
        if target then
            local targetPart = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            for i = 1, 5 do
                StatusLabel:Set("Status: Klick " .. i .. "/5")
                pcall(function() mouse1click() end)
                task.wait(0.2) -- Hier auf 0.2 geändert
            end
        end
        StatusLabel:Set("Status: Bereit")
        isExecuting = false
        
    -- L Knopf: Unsichtbar & Untergrund
    elseif input.KeyCode == Enum.KeyCode.L then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not root then return end
        
        isInvisibleUnderground = not isInvisibleUnderground
        
        if isInvisibleUnderground then
            root.CFrame = root.CFrame + Vector3.new(0, -10, 0)
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    savedCharacterParts[part] = part.Transparency
                    part.Transparency = 1
                end
            end
        else
            root.CFrame = root.CFrame + Vector3.new(0, 10, 0)
            for part, originalTrans in pairs(savedCharacterParts) do
                if part then part.Transparency = originalTrans end
            end
            savedCharacterParts = {}
        end
    end
end)

Rayfield:LoadConfiguration()
