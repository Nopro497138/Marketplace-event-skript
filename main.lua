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
local runningPickup = false
local runningCollect = false
local runningUpgrade = false

local upgradeAmount = 5 -- Standardwert für Upgrades pro Slot

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

local IgnoredItems = {"carpet", "coil", "grapple", "fly", "speed", "potion", "hammer", "sword", "reset"}

-- Hilfsfunktionen
local function teleportTo(pos)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
    end
end

local function unequipAllTools()
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:UnequipTools()
        end
    end
end

local function isIgnoredTool(toolName)
    local lowerName = string.lower(toolName or "")
    for _, name in ipairs(IgnoredItems) do
        if string.find(lowerName, name) then return true end
    end
    return false
end

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
                if SuffixMultipliers[s2] then mult = SuffixMultipliers[s2]
                elseif SuffixMultipliers[s1] then mult = SuffixMultipliers[s1] end
            end
            local total = num * mult
            if total > maxDetectedVal then maxDetectedVal = total end
        end
    end
    return maxDetectedVal
end

local function getBestBrainrot()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    local allTools = {}
    
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then table.insert(allTools, item) end
        end
    end
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then table.insert(allTools, item) end
        end
    end

    local bestTool = nil
    local highestValue = -1

    for _, tool in ipairs(allTools) do
        local toolVal = 0
        if not isIgnoredTool(tool.Name) then
            pcall(function()
                for _, attrVal in pairs(tool:GetAttributes()) do
                    if type(attrVal) == "number" and attrVal > toolVal then toolVal = attrVal
                    elseif type(attrVal) == "string" then
                        local parsed = parseMoneyString(attrVal)
                        if parsed > toolVal then toolVal = parsed end
                    end
                end
            end)
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
            local nameParsed = parseMoneyString(tool.Name)
            if nameParsed > toolVal then toolVal = nameParsed end
        end

        if toolVal > highestValue then
            highestValue = toolVal
            bestTool = tool
        end
    end

    if not bestTool and #allTools > 0 then
        for _, t in ipairs(allTools) do
            if not isIgnoredTool(t.Name) then bestTool = t break end
        end
        if not bestTool then bestTool = allTools[1] end
    end

    return bestTool
end

local function ensureEquipped(tool)
    if not tool or not tool:IsA("Tool") then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and tool.Parent ~= char then
        humanoid:UnequipTools()
        task.wait(0.05)
        humanoid:EquipTool(tool)
        task.wait(0.2)
    end
end

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
        pcall(function() fireproximityprompt(prompt) fired = true end)
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

-- Triggert den UpgradeButton (ProximityPrompt, ClickDetector oder TextButton)
local function triggerUpgradeButton(upgradeObj)
    if not upgradeObj then return end

    local prompt = upgradeObj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        safeFirePrompt(prompt)
        return
    end

    local cd = upgradeObj:FindFirstChildWhichIsA("ClickDetector", true)
    if cd and fireclickdetector then
        fireclickdetector(cd)
        return
    end

    local btn = upgradeObj:FindFirstChildWhichIsA("TextButton", true) or upgradeObj:FindFirstChildWhichIsA("ImageButton", true)
    if btn then
        if firesignal then
            pcall(function() firesignal(btn.MouseButton1Click) end)
            pcall(function() firesignal(btn.Activated) end)
        elseif getconnections then
            pcall(function()
                for _, conn in pairs(getconnections(btn.MouseButton1Click)) do conn:Fire() end
                for _, conn in pairs(getconnections(btn.Activated)) do conn:Fire() end
            end)
        end
    end
end

-- ==========================================
-- SCHLEIFEN-LOGIKEN
-- ==========================================

-- 1. Plot Auto Place
local function startPlotPlacement()
    task.spawn(function()
        local playerName = LocalPlayer.Name
        local plotFolder = workspace:FindFirstChild("Plot_" .. playerName)
        if not plotFolder then runningPlot = false return end
        
        local floorIndex = 1
        while runningPlot do
            local currentFloor = plotFolder:FindFirstChild("Floor" .. floorIndex)
            if not currentFloor then runningPlot = false break end
            
            local slotsFolder = currentFloor:FindFirstChild("Slots")
            if slotsFolder then
                local slotIndex = 1
                while runningPlot do
                    local currentSlot = slotsFolder:FindFirstChild("Slot" .. slotIndex)
                    if not currentSlot then break end
                    
                    local spawnPart = currentSlot:FindFirstChild("Spawn", true) or currentSlot.PrimaryPart or currentSlot:FindFirstChildWhichIsA("BasePart", true)
                    if spawnPart then
                        teleportTo(spawnPart.Position + Vector3.new(0, 2, 0))
                        task.wait(0.15)
                        
                        local bestTool = getBestBrainrot()
                        if bestTool then ensureEquipped(bestTool) end
                        
                        local prompt = currentSlot:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then safeFirePrompt(prompt) end
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

-- 2. Pickup All (Ohne Items in der Hand)
local function startPickupAll()
    task.spawn(function()
        local playerName = LocalPlayer.Name
        local plotFolder = workspace:FindFirstChild("Plot_" .. playerName)
        if not plotFolder then runningPickup = false return end

        local floorIndex = 1
        while runningPickup do
            local currentFloor = plotFolder:FindFirstChild("Floor" .. floorIndex)
            if not currentFloor then runningPickup = false break end

            local slotsFolder = currentFloor:FindFirstChild("Slots")
            if slotsFolder then
                local slotIndex = 1
                while runningPickup do
                    local currentSlot = slotsFolder:FindFirstChild("Slot" .. slotIndex)
                    if not currentSlot then break end

                    unequipAllTools()

                    local spawnPart = currentSlot:FindFirstChild("Spawn", true) or currentSlot.PrimaryPart or currentSlot:FindFirstChildWhichIsA("BasePart", true)
                    if spawnPart then
                        teleportTo(spawnPart.Position + Vector3.new(0, 2, 0))
                        task.wait(0.15)

                        local prompt = currentSlot:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then safeFirePrompt(prompt) end
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

-- 3. Cash Auto-Collect (Teleport zu CollectTouch)
local function startAutoCollect()
    task.spawn(function()
        local playerName = LocalPlayer.Name
        local plotFolder = workspace:FindFirstChild("Plot_" .. playerName)
        if not plotFolder then runningCollect = false return end

        local floorIndex = 1
        while runningCollect do
            local currentFloor = plotFolder:FindFirstChild("Floor" .. floorIndex)
            if not currentFloor then runningCollect = false break end

            local slotsFolder = currentFloor:FindFirstChild("Slots")
            if slotsFolder then
                local slotIndex = 1
                while runningCollect do
                    local currentSlot = slotsFolder:FindFirstChild("Slot" .. slotIndex)
                    if not currentSlot then break end

                    unequipAllTools()

                    local collectTouch = currentSlot:FindFirstChild("CollectTouch", true)
                    if collectTouch and collectTouch:IsA("BasePart") then
                        teleportTo(collectTouch.Position)
                        task.wait(0.15)
                    end

                    slotIndex = slotIndex + 1
                    task.wait(0.15)
                end
            end
            floorIndex = floorIndex + 1
            task.wait(0.3)
        end
    end)
end

-- 4. Auto-Upgrade Slots
local function startAutoUpgrade()
    task.spawn(function()
        local playerName = LocalPlayer.Name
        local plotFolder = workspace:FindFirstChild("Plot_" .. playerName)
        if not plotFolder then runningUpgrade = false return end

        local floorIndex = 1
        while runningUpgrade do
            local currentFloor = plotFolder:FindFirstChild("Floor" .. floorIndex)
            if not currentFloor then runningUpgrade = false break end

            local slotsFolder = currentFloor:FindFirstChild("Slots")
            if slotsFolder then
                local slotIndex = 1
                while runningUpgrade do
                    local currentSlot = slotsFolder:FindFirstChild("Slot" .. slotIndex)
                    if not currentSlot then break end

                    unequipAllTools()

                    local upgradeObj = currentSlot:FindFirstChild("UpgradeButton", true)
                    if upgradeObj then
                        local targetPos = upgradeObj:IsA("BasePart") and upgradeObj.Position or (upgradeObj.PrimaryPart and upgradeObj.PrimaryPart.Position)
                        if not targetPos then
                            local p = upgradeObj:FindFirstChildWhichIsA("BasePart", true)
                            if p then targetPos = p.Position end
                        end

                        if targetPos then
                            teleportTo(targetPos + Vector3.new(0, 2, 0))
                            task.wait(0.15)
                        end

                        -- Klickt den UpgradeButton x-mal
                        for _ = 1, upgradeAmount do
                            if not runningUpgrade then break end
                            triggerUpgradeButton(upgradeObj)
                            task.wait(0.08)
                        end
                    end

                    slotIndex = slotIndex + 1
                    task.wait(0.2)
                end
            end
            floorIndex = floorIndex + 1
            task.wait(0.3)
        end
    end)
end

-- 5. Spawn 11 Farm
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
                        if prompt then safeFirePrompt(prompt) end

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
-- RAYFIELD UI STEUERUNG
-- ==========================================

Tab:CreateToggle({
    Name = "Spawn '11' Auto-Farm",
    CurrentValue = false,
    Flag = "Spawn11FarmToggle",
    Callback = function(Value)
        runningSpawn = Value
        if runningSpawn then startSpawnFarm() end
    end,
})

Tab:CreateToggle({
    Name = "Plot Best-Brainrot Auto-Place",
    CurrentValue = false,
    Flag = "PlotAutoPlaceToggle",
    Callback = function(Value)
        runningPlot = Value
        if runningPlot then startPlotPlacement() end
    end,
})

Tab:CreateToggle({
    Name = "Plot Pickup-All (Keine Items halten)",
    CurrentValue = false,
    Flag = "PlotPickupAllToggle",
    Callback = function(Value)
        runningPickup = Value
        if runningPickup then startPickupAll() end
    end,
})

Tab:CreateToggle({
    Name = "Plot Cash Auto-Collect (CollectTouch)",
    CurrentValue = false,
    Flag = "PlotAutoCollectToggle",
    Callback = function(Value)
        runningCollect = Value
        if runningCollect then startAutoCollect() end
    end,
})

Tab:CreateSlider({
    Name = "Upgrades pro Slot",
    Range = {1, 50},
    Increment = 1,
    Suffix = "x Klicks",
    CurrentValue = 5,
    Flag = "UpgradeAmountSlider",
    Callback = function(Value)
        upgradeAmount = Value
    end,
})

Tab:CreateToggle({
    Name = "Plot Auto-Upgrade (UpgradeButton)",
    CurrentValue = false,
    Flag = "PlotAutoUpgradeToggle",
    Callback = function(Value)
        runningUpgrade = Value
        if runningUpgrade then startAutoUpgrade() end
    end,
})
