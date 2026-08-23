-- Rayfield Library Laden
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Item Spawns & Plot Farm",
    LoadingTitle = "Delta Executor Script",
    LoadingSubtitle = "by Assistant",
    ConfigurationSaving = { Enabled = false }
})

local Tab = Window:CreateTab("Auto Farm", 4483362458)

-- Global State & Positionen
local runningSpawn = false
local runningPlot = false

local startPos = Vector3.new(-104, 2673, 2163)
local returnPos = Vector3.new(155, 3, -86)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Hilfsfunktion: Sicheres Teleportieren
local function teleportTo(pos)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
    end
end

-- ==========================================
-- ROBUSTER PROXIMITY PROMPT TRIGGER
-- ==========================================
local function safeFirePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end

    -- 1. Prompt-Eigenschaften temporär für Bypassing anpassen
    local oldHold = prompt.HoldDuration
    local oldLOS = prompt.RequiresLineOfSight
    local oldDist = prompt.MaxActivationDistance

    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 30
    prompt.Enabled = true

    -- 2. Charakter direkt zum Prompt/Parent ausrichten
    local parentPart = prompt.Parent
    if parentPart and parentPart:IsA("BasePart") then
        teleportTo(parentPart.Position + Vector3.new(0, 2, 0))
    end
    task.wait(0.1)

    -- 3. Executor-Funktion mit Fallback-Mechanismus
    local fired = false
    if fireproximityprompt then
        pcall(function()
            fireproximityprompt(prompt)
            fired = true
        end)
    end

    -- Fallback via Roblox Input-Events (falls fireproximityprompt fehlschlägt)
    if not fired then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.05)
            prompt:InputHoldEnd()
        end)
    end

    -- Restoration
    task.wait(0.1)
    prompt.HoldDuration = oldHold
    prompt.RequiresLineOfSight = oldLOS
    prompt.MaxActivationDistance = oldDist

    return true
end

-- ==========================================
-- BRAINROT WERT-BERECHNUNG & AUTOPLACE
-- ==========================================
local function parseValue(str)
    if not str then return 0 end
    local text = string.lower(str)
    local numStr, suffix = string.match(text, "([%d%.]+)%s*([a-z]*)")
    if not numStr then return 0 end
    
    local num = tonumber(numStr) or 0
    local multipliers = {
        k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, qi = 1e18
    }
    
    if suffix and multipliers[suffix] then
        return num * multipliers[suffix]
    end
    return num
end

local function getBestBrainrot()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return nil end
    
    local bestTool = nil
    local highestValue = -1
    
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local toolMaxVal = 0
            
            for _, descendant in ipairs(tool:GetDescendants()) do
                local textVal = ""
                if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
                    textVal = descendant.Text
                elseif descendant:IsA("StringValue") then
                    textVal = descendant.Value
                end
                
                if textVal ~= "" then
                    local val = parseValue(textVal)
                    if val > toolMaxVal then toolMaxVal = val end
                end
            end
            
            if toolMaxVal > highestValue then
                highestValue = toolMaxVal
                bestTool = tool
            end
        end
    end
    
    return bestTool
end

local function startPlotPlacement()
    task.spawn(function()
        local playerName = LocalPlayer.Name
        local plotName = "Plot_" .. playerName
        local plotFolder = workspace:FindFirstChild(plotName)
        
        if not plotFolder then
            Rayfield:Notify({Title = "Fehler", Content = plotName .. " nicht gefunden!", Duration = 4})
            runningPlot = false
            return
        end
        
        local floorIndex = 1
        
        while runningPlot do
            local currentFloor = plotFolder:FindFirstChild("Floor" .. floorIndex)
            
            if not currentFloor then
                Rayfield:Notify({Title = "Fertig", Content = "Alle Floors verarbeitet!", Duration = 3})
                runningPlot = false
                break
            end
            
            local slotsFolder = currentFloor:FindFirstChild("Slots")
            if slotsFolder then
                local slotIndex = 1
                
                while runningPlot do
                    local currentSlot = slotsFolder:FindFirstChild("Slot" .. slotIndex)
                    if not currentSlot then break end
                    
                    -- Bestes Brainrot wählen und ausrüsten
                    local bestTool = getBestBrainrot()
                    if bestTool then
                        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                        if humanoid then
                            humanoid:EquipTool(bestTool)
                            task.wait(0.15)
                        end
                    end
                    
                    -- Spawn Part & Prompt Ausführung
                    local spawnPart = currentSlot:FindFirstChild("Spawn", true) or currentSlot.PrimaryPart or currentSlot:FindFirstChildWhichIsA("BasePart", true)
                    
                    if spawnPart then
                        teleportTo(spawnPart.Position + Vector3.new(0, 2, 0))
                        task.wait(0.2)
                        
                        local prompt = currentSlot:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            safeFirePrompt(prompt)
                        end
                    end
                    
                    slotIndex = slotIndex + 1
                    task.wait(0.25)
                end
            end
            
            floorIndex = floorIndex + 1
            task.wait(0.3)
        end
    end)
end

-- ==========================================
-- SPAWN 11 FARM LOGIK
-- ==========================================
local function startSpawnFarm()
    task.spawn(function()
        while runningSpawn do
            -- 1. Start-Teleport zur Überwachungsposition
            teleportTo(startPos)
            task.wait(0.5)

            if not runningSpawn then break end

            local itemSpawns = workspace:FindFirstChild("ItemSpawns")
            local folder11 = itemSpawns and itemSpawns:FindFirstChild("11")

            if folder11 then
                local targetModel = folder11:FindFirstChildWhichIsA("Model")

                if targetModel then
                    local targetPart = targetModel.PrimaryPart or targetModel:FindFirstChildWhichIsA("BasePart", true)

                    if targetPart then
                        -- 2. Teleport zum Objekt in Spawn "11"
                        teleportTo(targetPart.Position + Vector3.new(0, 2, 0))
                        task.wait(0.2)

                        -- 3. Robusten Prompt-Trigger ausführen
                        local prompt = targetModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            safeFirePrompt(prompt)
                        end

                        -- 4. Teleport zur Ziel-Position (155, 3, -86)
                        task.wait(0.2)
                        teleportTo(returnPos)
                        task.wait(0.5)
                    end
                end
            end

            task.wait(0.3)
        end
    end)
end

-- ==========================================
-- RAYFIELD UI TOGGLES
-- ==========================================
Tab:CreateToggle({
    Name = "Spawn '11' Auto-Farm",
    CurrentValue = false,
    Flag = "Spawn11FarmToggle",
    Callback = function(Value)
        runningSpawn = Value
        if runningSpawn then
            Rayfield:Notify({Title = "Farm Aktiviert", Content = "Starte robuste Item-Farm...", Duration = 3})
            startSpawnFarm()
        else
            Rayfield:Notify({Title = "Farm Deaktiviert", Content = "Auto-Farm gestoppt.", Duration = 3})
        end
    end,
})

Tab:CreateToggle({
    Name = "Plot Best-Brainrot Auto-Place",
    CurrentValue = false,
    Flag = "PlotAutoPlaceToggle",
    Callback = function(Value)
        runningPlot = Value
        if runningPlot then
            Rayfield:Notify({Title = "Plot-Farm Aktiviert", Content = "Starte robuste Slot-Platzierung...", Duration = 3})
            startPlotPlacement()
        else
            Rayfield:Notify({Title = "Plot-Farm Deaktiviert", Content = "Platzierung gestoppt.", Duration = 3})
        end
    end,
})
