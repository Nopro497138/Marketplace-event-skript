-- // ---- EINSTELLUNGEN ----
local TARGET_COORDS = CFrame.new(-126, 13, -182) -- Zielkoordinaten
local LOOP_WAIT = 1 -- Wartezeit zwischen zwei Durchläufen (Sekunden)
local HOLD_TIME = 2 -- Wie lange der PickupPrompt gedrückt wird (Sekunden)

-- // ---- SERVICE ----
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- // ---- STATUS ----
local running = false
local shutdown = false
local loopCoroutine = nil

-- // ---- HILFSFUNKTION: Erkennen des Keywords mit Priorität ----
local function findKeyword(text)
    local lower = string.lower(text)
    if string.find(lower, "god") then return "god" end
    if string.find(lower, "og") then return "og" end
    if string.find(lower, "secret") then return "secret" end
    return nil
end

local function getPriority(keyword)
    if keyword == "god" or keyword == "og" then return 1 end
    if keyword == "secret" then return 2 end
    return 3
end

-- // ---- GUI ERSTELLEN (unverändert) ----
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarmGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 160)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -80)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 120)
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -70, 1, 0)
titleText.Position = UDim2.new(0, 5, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "🤖 Auto Farm (Brainrots)"
titleText.TextColor3 = Color3.new(1, 1, 1)
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamBold
titleText.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 1, -4)
minBtn.Position = UDim2.new(1, -65, 0, 2)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
minBtn.Text = "_"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.TextSize = 20
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
minBtn.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 1, -4)
closeBtn.Position = UDim2.new(1, -32, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 15)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "⏸ Gestoppt"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = contentFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 120, 0, 40)
toggleBtn.Position = UDim2.new(0.5, -60, 0, 70)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleBtn.Text = "▶ Start"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.TextSize = 16
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = contentFrame

-- // ---- DRAG ----
local dragging = false
local dragStart = nil
local startPos = nil

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- // ---- MINIMIEREN ----
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        contentFrame.Visible = false
        mainFrame.Size = UDim2.new(0, 280, 0, 30)
        minBtn.Text = "□"
    else
        contentFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 280, 0, 160)
        minBtn.Text = "_"
    end
end)

-- // ---- HARD-SHUTDOWN ----
closeBtn.MouseButton1Click:Connect(function()
    shutdown = true
    running = false
    if loopCoroutine then
        task.cancel(loopCoroutine)
        loopCoroutine = nil
    end
    screenGui:Destroy()
    print("🔴 Skript wurde vollständig beendet.")
end)

-- // ---- MODELL-SUCHE MIT PRIORITÄT ----
local function findBestModel()
    local folder = workspace:FindFirstChild("Brainrots")
    if not folder then
        statusLabel.Text = "❌ Ordner 'Brainrots' nicht gefunden!"
        return nil, nil
    end

    local bestModel = nil
    local bestPriority = 3
    local foundKeyword = nil

    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            local currentPriority = 3
            local keywordFound = nil

            local kw = findKeyword(model.Name)
            if kw then
                local prio = getPriority(kw)
                if prio < currentPriority then
                    currentPriority = prio
                    keywordFound = kw
                end
            end

            if currentPriority > 1 then
                for _, child in ipairs(model:GetDescendants()) do
                    if child:IsA("StringValue") or child:IsA("ObjectValue") or 
                       child:IsA("IntValue") or child:IsA("BoolValue") or child:IsA("NumberValue") then
                        local val = tostring(child.Value)
                        kw = findKeyword(val)
                        if kw then
                            local prio = getPriority(kw)
                            if prio < currentPriority then
                                currentPriority = prio
                                keywordFound = kw
                                if currentPriority == 1 then break end
                            end
                        end
                    end
                    if child:IsA("BasePart") then
                        kw = findKeyword(child.Name)
                        if kw then
                            local prio = getPriority(kw)
                            if prio < currentPriority then
                                currentPriority = prio
                                keywordFound = kw
                                if currentPriority == 1 then break end
                            end
                        end
                    end
                end
            end

            if currentPriority > 1 then
                for _, attrValue in pairs(model:GetAttributes()) do
                    local val = tostring(attrValue)
                    kw = findKeyword(val)
                    if kw then
                        local prio = getPriority(kw)
                        if prio < currentPriority then
                            currentPriority = prio
                            keywordFound = kw
                            if currentPriority == 1 then break end
                        end
                    end
                end
            end

            if currentPriority < bestPriority then
                bestPriority = currentPriority
                bestModel = model
                foundKeyword = keywordFound
                if bestPriority == 1 then break end
            end
        end
    end

    if bestModel then
        return bestModel, foundKeyword
    else
        return nil, nil
    end
end

-- // ---- HILFSFUNKTION: Part im Modell finden ----
local function getModelPart(model)
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    return model:FindFirstChildWhichIsA("BasePart")
end

-- // ---- PROMPT FINDEN (unter "Mesh" nach "PickupPrompt") ----
local function getPrompt(model)
    local meshContainer = model:FindFirstChild("Mesh")
    if meshContainer then
        local prompt = meshContainer:FindFirstChildWhichIsA("PickupPrompt")
        if prompt then return prompt end
        prompt = meshContainer:FindFirstChild("PickupPrompt")
        if prompt then return prompt end
    end
    local prompt = model:FindFirstChildWhichIsA("PickupPrompt")
    if prompt then return prompt end
    return model:FindFirstChild("PickupPrompt")
end

-- // ---- HAUPT-SCHLEIFE ----
local function startLoop()
    if loopCoroutine then
        task.cancel(loopCoroutine)
        loopCoroutine = nil
    end

    loopCoroutine = task.spawn(function()
        while not shutdown do
            if running then
                statusLabel.Text = "🔄 Suche bestes Modell..."
                local targetModel, keyword = findBestModel()

                if targetModel then
                    statusLabel.Text = "📍 Modell gefunden: " .. targetModel.Name .. " (" .. (keyword or "?") .. ")"

                    local part = getModelPart(targetModel)
                    if part then
                        hrp.CFrame = part.CFrame + Vector3.new(0, 2.5, 0)
                        task.wait(0.15)
                    else
                        statusLabel.Text = "⚠️ Kein Part im Modell!"
                        task.wait(LOOP_WAIT)
                        continue
                    end

                    local prompt = getPrompt(targetModel)
                    if prompt then
                        statusLabel.Text = "⌨️ Halte PickupPrompt (" .. HOLD_TIME .. "s)..."
                        prompt:InputHoldBegin()
                        task.wait(HOLD_TIME)          -- 1,5 Sekunden gedrückt halten
                        prompt:InputHoldEnd()
                        task.wait(0.3)                 -- kurze Pause nach dem Loslassen
                    else
                        statusLabel.Text = "⚠️ Kein PickupPrompt unter 'Mesh' gefunden!"
                        task.wait(LOOP_WAIT)
                        continue
                    end

                    statusLabel.Text = "🚀 Teleporte zu Ziel..."
                    hrp.CFrame = TARGET_COORDS
                    task.wait(0.2)

                    statusLabel.Text = "✅ Durchlauf abgeschlossen. Warte..."
                else
                    statusLabel.Text = "❌ Kein Modell mit 'God'/'OG'/'Secret' gefunden!"
                end

                task.wait(LOOP_WAIT)   -- nur 0,5 Sekunden Pause
            else
                statusLabel.Text = "⏸ Gestoppt"
                task.wait(0.5)
            end
        end
    end)
end

-- // ---- TOGGLE ----
local function toggle()
    if shutdown then return end
    running = not running
    if running then
        toggleBtn.Text = "⏹ Stop"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        statusLabel.Text = "▶ Läuft..."
        if not loopCoroutine or loopCoroutine.Status == "Dead" then
            startLoop()
        end
    else
        toggleBtn.Text = "▶ Start"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        statusLabel.Text = "⏸ Gestoppt"
    end
end

toggleBtn.MouseButton1Click:Connect(toggle)

-- // ---- START ----
print("✅ GUI geladen. PickupPrompt wird " .. HOLD_TIME .. "s gedrückt.")
statusLabel.Text = "⏸ Gestoppt"
