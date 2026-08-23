-- Rayfield Library Laden
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Item Auto-Farm",
    LoadingTitle = "Delta Executor Script",
    LoadingSubtitle = "by Assistant",
    ConfigurationSaving = { Enabled = false }
})

local Tab = Window:CreateTab("Auto Farm", 4483362458)

-- Variables & State
local running = false
local returnPos = Vector3.new(12, -71, -166)
local keywords = {"Ancient", "Transcendant", "Eternal", "Immortal"}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Hilfsfunktion: Teleportation
local function teleportTo(pos)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
    end
end

-- Hilfsfunktion: Prüft, ob ein Text eines der Keywörter enthält
local function containsKeyword(text)
    if not text then return false end
    for _, kw in ipairs(keywords) do
        if string.find(string.lower(text), string.lower(kw)) then
            return true
        end
    end
    return false
end

-- Hilfsfunktion: Prüft, ob ein Modell ein gesuchtes Item ist
local function isTargetItem(model)
    if not model:IsA("Model") then return false end
    
    -- 1. Name des Modells prüfen
    if containsKeyword(model.Name) then return true end
    
    -- 2. Alle Unterobjekte nach TextLabels / TextMesh / StringValues durchsuchen
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            if containsKeyword(child.Text) then return true end
        elseif child:IsA("StringValue") then
            if containsKeyword(child.Value) then return true end
        end
        
        -- Prüfung benutzerdefinierter/dynamischer Text-Properties
        local success, textProp = pcall(function() return child.Text end)
        if success and type(textProp) == "string" and containsKeyword(textProp) then
            return true
        end
    end
    
    return false
end

-- Hauptschleife
local function startFarming()
    task.spawn(function()
        while running do
            local itemsFolder = workspace:FindFirstChild("Items")
            if itemsFolder then
                for _, item in ipairs(itemsFolder:GetChildren()) do
                    if not running then break end
                    
                    if isTargetItem(item) then
                        local primaryPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)
                        
                        if primaryPart then
                            -- 1. Teleport zum Item
                            teleportTo(primaryPart.Position + Vector3.new(0, 3, 0))
                            task.wait(0.3) -- Kleine Stabilisierung
                            
                            -- 2. ProximityPrompt suchen und auslösen
                            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then
                                fireproximityprompt(prompt, 1.3)
                                task.wait(1.35) -- Warten, bis der Hold fertig ist
                            end
                            
                            -- 3. Teleport zur Home-Position
                            teleportTo(returnPos)
                            task.wait(0.5)
                        end
                    end
                end
            end
            task.wait(1) -- Pause zwischen den Scan-Zyklen
        end
    end)
end

-- Rayfield Toggle
Tab:CreateToggle({
    Name = "Auto-Farm Toggle",
    CurrentValue = false,
    Flag = "ItemFarmToggle",
    Callback = function(Value)
        running = Value
        if running then
            Rayfield:Notify({Title = "Farm Gestartet", Content = "Suche nach Seltenheiten...", Duration = 3})
            startFarming()
        else
            Rayfield:Notify({Title = "Farm Gestoppt", Content = "Auto-Farm wurde deaktiviert.", Duration = 3})
        end
    end,
})
