-- Rayfield Library Laden lol
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

-- Werkzeuge, die keine Geld-Brainrots sind
local IgnoredItems = {"carpet", "coil", "grapple", "fly", "speed", "potion", "hammer", "sword", "reset"}

-- Hilfsfunktion: Sicheres Teleportieren
local function teleportTo(pos)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
    end
end

-- Prüft, ob ein Tool-Name in der Blacklist steht
local function isIgnoredTool(toolName)
    local lowerName = string.lower(toolName or "")
    for _, name in ipairs(IgnoredItems) do
        if string.find(lowerName, name) then
            return true
        end
    end
    return false
end

-- Parst Strings wie "$100.5M/s", "100,000,000", "Level 1 (+500k)"
local function parseMoneyString(str)
    if not str or type(str) ~= "string" then return 0 end
    
    local cleaned = string.lower(string.gsub(str, ",", ""))
    local maxDetectedVal = 0
    
    for numStr, suffix in string.gmatch(cleaned, "(%d+%.?%d*)%s*([a-z]*)") do
        local num = tonumber(numStr)
        if num then
            local mult = 1
            if suffix and suffix ~= "" then
                local s2 = string.sub(suffix, 1, 2)
                local s1 = string.sub(suffix, 1, 1)
                
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

-- Scannt ALLE Items im Backpack & Character vollständig
local function getBestBrainrot()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    
    local allTools = {}
    
    -- 1. Alle Tools im Backpack sammeln
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(allTools, item)
            end
        end
    end
    
    -- 2. Alle aktuell ausgerüsteten Tools im Character sammeln
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(allTools, item)
            end
        end
    end

    local bestTool = nil
    local highestValue = -1

    -- 3. Jedes einzelne Item bewerten
    for _, tool in ipairs(allTools) do
        local toolVal = 0
        
        if not isIgnoredTool(tool.Name) then
            -- Attributes prüfen
            pcall(function()
                for _, attrVal in pairs(tool:GetAttributes()) do
                    if type(attrVal) == "number" and attrVal > toolVal then
                        toolVal = attrVal
                    elseif type(attrVal) == "string" then
                        local parsed = parseMoneyString(attrVal)
                        if parsed > toolVal then toolVal = parsed end
                    end
                end
            end)

            -- Value-Objekte & UI-Texte durchsuchen
            for _, descendant in ipairs(tool:GetDescendants()) do
                if descendant:IsA("NumberValue") or descendant:IsA("IntValue") then
                    if descendant.Value > toolVal then toolVal = descendant.Value end
                elseif descendant:IsA("StringValue") then
                    local parsed = parseMoneyString(descendant.Value)
                    if parsed > toolVal then toolVal = parsed end
                elseif descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
                    local parsed = parseMoneyString(descendant.Text)
                    if parsed > toolVal then toolVal = parsed end
                end
            end

            -- Tool-Name prüfen
            local nameParsed = parseMoneyString(tool.Name)
            if nameParsed > toolVal then toolVal = nameParsed end
        else
            toolVal = 0 -- Ignorierte Items (Carpet etc.) werden auf 0 gesetzt
        end

        print("[Scan Item] " .. tool.Name .. " | Wert: " .. tostring(toolVal))

        if toolVal > highestValue then
            highestValue = toolVal
            bestTool = tool
        end
    end

    -- Fallback: Wenn alle Werte 0 sind, nimm das erste nicht-ignorierte Tool
    if not bestTool and #allTools > 0 then
        for _, t in ipairs(allTools) do
            if not isIgnoredTool(t.Name) then
                bestTool = t
                break
            end
        end
        if not bestTool then bestTool = allTools[1] end
    end

    if bestTool then
        print("[Selected Best Item] " .. bestTool.Name .. " (Wert: " .. tostring(highestValue) .. ")")
    end

    return bestTool
end

-- Zwingt das Anlegen des besten Tools
local function ensureEquipped(tool)
    if not tool or not tool:IsA("Tool") then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        -- Wenn das gefundene Tool nicht bereits ausgerüstet ist
        if tool.Parent ~= char then
            humanoid:UnequipTools() -- Legt z. B. den Carpet ab
            task.wait(0.1)
            humanoid:EquipTool(tool)
            task.wait(0.2)
        end
    end
end

-- Proximity Prompt Execution
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

-- Hauptschleife für Plot Auto-Placement
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
                        
                        -- Erst ALLE Items scannen & bestes Item ausrüsten
                        local bestTool = getBestBrainrot()
                        if bestTool then
                            ensureEquipped(bestTool)
                        end
                        
                        -- Danach ProximityPrompt drücken
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

-- Hauptschleife für Spawn 11 Farm
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

-- Rayfield UI Toggles
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
            Rayfield:Notify({Title = "Plot-Farm Aktiviert", Content = "Scannt Backpack & platziert bestes Item...", Duration = 3})
            startPlotPlacement()
        else
            Rayfield:Notify({Title = "Plot-Farm Deaktiviert", Content = "Platzierung gestoppt.", Duration = 3})
        end
    end,
})
