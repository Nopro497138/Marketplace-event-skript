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

-- Multiplikatoren für Geldbeträge
local SuffixMultipliers = {
    k = 1e3, m = 1e6, b = 1e9, t = 1e12,
    qa = 1e15, qi = 1e18, sx = 1e21, sp = 1e24,
    oc = 1e27, no = 1e30, dc = 1e33
}

-- Hilfsfunktion: Sicheres Teleportieren
local function teleportTo(pos)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
    end
end

-- ==========================================
-- ERWEITERTE GELD-ANALYSE & EVALUIERUNG
-- ==========================================

-- Parst Strings wie "$100.5M/s", "100,000,000", "Level 1 (+500k)"
local function parseMoneyString(str)
    if not str or type(str) ~= "string" then return 0 end
    
    -- Kommas entfernen und Kleinbuchstaben erzwingen
    local cleaned = string.lower(string.gsub(str, ",", ""))
    local maxDetectedVal = 0
    
    -- Durchsucht JEDE Zahl inklusive folgendem Text im String
    for numStr, word in string.gmatch(cleaned, "(%d+%.?%d*)%s*([a-z]*)") do
        local num = tonumber(numStr)
        if num then
            local mult = 1
            if word ~= "" then
                local s2 = string.sub(word, 1, 2)
                local s1 = string.sub(word, 1, 1)
                
                if SuffixMultipliers[s2] then
                    mult = SuffixMultipliers[s2]
                elseif SuffixMultipliers[s1] then
                    mult = SuffixMultipliers[s1]
                end
            end
            
            local total = num * mult
            if total > maxDetectedVal then
                maxDetectedVal = total
            end
        end
    end
    
    return maxDetectedVal
end

-- Berechnet den absoluten Höchstwert eines Tools
local function getToolValue(tool)
    if not tool or not tool:IsA("Tool") then return 0 end
    local maxVal = 0

    -- 1. Attributes scannen
    pcall(function()
        for _, attrVal in pairs(tool:GetAttributes()) do
            if type(attrVal) == "number" and attrVal > maxVal then
                maxVal = attrVal
            elseif type(attrVal) == "string" then
                local parsed = parseMoneyString(attrVal)
                if parsed > maxVal then maxVal = parsed end
            end
        end
    end)

    -- 2. Value-Objekte & UI-Texte durchsuchen
    for _, descendant in ipairs(tool:GetDescendants()) do
        if descendant:IsA("NumberValue") or descendant:IsA("IntValue") then
            if descendant.Value > maxVal then maxVal = descendant.Value end
        elseif descendant:IsA("StringValue") then
            local parsed = parseMoneyString(descendant.Value)
            if parsed > maxVal then maxVal = parsed end
        elseif descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
            local parsed = parseMoneyString(descendant.Text)
            if parsed > maxVal then maxVal = parsed end
        end
    end

    -- 3. Tool-Namen prüfen
    local nameParsed = parseMoneyString(tool.Name)
    if nameParsed > maxVal then maxVal = nameParsed end

    return maxVal
end

-- Sucht das wertvollste Brainrot in Backpack & Character
local function getBestBrainrot()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    
    local bestTool = nil
    local highestValue = -1
    
    local function checkContainer(container)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local toolValue = getToolValue(tool)
                if toolValue > highestValue then
                    highestValue = toolValue
                    bestTool = tool
                end
            end
        end
    end

    checkContainer(backpack)
    checkContainer(character)
    
    if bestTool then
        print("[Auto-Place] Ausgewähltes Item: " .. bestTool.Name .. " | Wert: " .. tostring(highestValue))
    end
    
    return bestTool
end

-- Zwingt das Anlegen des Tools
local function ensureEquipped(tool)
    if not tool or not tool:IsA("Tool") then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        if tool.Parent ~= char then
            humanoid:UnequipTools()
            task.wait(0.05)
            humanoid:EquipTool(tool)
            task.wait(0.2)
        end
    end
end

-- ==========================================
-- PROXIMITY PROMPT TRIGGER
-- ==========================================
local function safeFirePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end

    local oldHold = prompt.HoldDuration
    local oldLOS = prompt.RequiresLineOfSight
    local oldDist = prompt.MaxActivationDistance

    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 30
    prompt.Enabled = true

    local parentPart = prompt.Parent
    if parentPart and parentPart:IsA("BasePart") then
        teleportTo(parentPart.Position + Vector3.new(0, 2, 0))
    end
    task.wait(0.1)

    local fired = false
    if fireproximityprompt then
        pcall(function()
            fireproximityprompt(prompt)
            fired = true
        end)
    end

    if not fired then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.05)
            prompt:InputHoldEnd()
        end)
    end

    task.wait(0.1)
    prompt.HoldDuration = oldHold
    prompt.RequiresLineOfSight = oldLOS
    prompt.MaxActivationDistance = oldDist

    return true
end

-- ==========================================
-- PLOT AUTO-PLACE SCHLEIFE
-- ==========================================
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
                    
                    local spawnPart = currentSlot:FindFirstChild("Spawn", true) or currentSlot.PrimaryPart or currentSlot:FindFirstChildWhichIsA("BasePart", true)
                    
                    if spawnPart then
                        -- Teleport zum Slot
                        teleportTo(spawnPart.Position + Vector3.new(0, 2, 0))
                        task.wait(0.15)
                        
                        -- Höchstwertiges Item suchen & vor Prompt ausrüsten
                        local bestTool = getBestBrainrot()
                        if bestTool then
                            ensureEquipped(bestTool)
                        end
                        
                        -- Prompt auslösen
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
-- SPAWN 11 FARM SCHLEIFE
-- ==========================================
local function startSpawnFarm()
    task.spawn(function()
        while runningSpawn do
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
                        teleportTo(targetPart.Position + Vector3.new(0, 2, 0))
                        task.wait(0.2)

                        local prompt = targetModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            safeFirePrompt(prompt)
                        end

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
            Rayfield:Notify({Title = "Farm Aktiviert", Content = "Starte Item-Farm...", Duration = 3})
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
            Rayfield:Notify({Title = "Plot-Farm Aktiviert", Content = "Wählt wertvollstes Item & platziert...", Duration = 3})
            startPlotPlacement()
        else
            Rayfield:Notify({Title = "Plot-Farm Deaktiviert", Content = "Platzierung gestoppt.", Duration = 3})
        end
    end,
})
