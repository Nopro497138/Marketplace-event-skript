-- // ---- EINSTELLUNGEN ----
local TARGET_COORDS = CFrame.new(-126, 13, -182) -- Zielkoordinaten
local LOOP_WAIT = 2.0 -- Wartezeit zwischen zwei Durchläufen (Sekunden)

-- // ---- SERVICE ----
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- // ---- STATUS ----
local running = false      -- Toggle-Status
local shutdown = false     -- Hard-Shutdown durch X-Knopf
local loopCoroutine = nil

-- // ---- HILFSFUNKTION: Prüft, ob ein Text eines der Keywords enthält ----
local function containsKeyword(text)
    local lower = string.lower(text)
    return string.find(lower, "og") or string.find(lower, "secret") or string.find(lower, "god")
end

-- // ---- GUI ERSTELLEN ----
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

-- // Titelbalken (Drag-Bereich)
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

-- // Minimieren-Knopf (_)
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

-- // Schließen-Knopf (X)
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

-- // Content-Bereich (wird beim Minimieren ausgeblendet)
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- // Status-Label
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

-- // Toggle-Button (Start/Stop)
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

-- // ---- DRAG-FUNKTION (GUI verschieben) ----
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
local oldSize = mainFrame.Size

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

-- // ---- HARD-SHUTDOWN (X-Knopf) ----
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

-- // ---- HILFSFUNKTION: Modell mit "OG", "Secret" oder "God" finden ----
local function findTargetModel()
    local folder = workspace:FindFirstChild("Brainrots")
    if not folder then
        statusLabel.Text = "❌ Ordner 'Brainrots' nicht gefunden!"
        return nil
    end

    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            local found = false
            
            -- 1. Name des Modells prüfen
            if containsKeyword(model.Name) then
                found = true
            end

            -- 2. Alle Nachkommen (StringValue, ObjectValue, Part-Namen, etc.) prüfen
            if not found then
                for _, child in ipairs(model:GetDescendants()) do
                    -- Prüfe Werte von Value-Objekten
                    if child:IsA("StringValue") or child:IsA("ObjectValue") or 
                       child:IsA("IntValue") or child:IsA("BoolValue") or child:IsA("NumberValue") then
                        local val = tostring(child.Value)
                        if containsKeyword(val) then
                            found = true
                            break
                        end
                    end
                    -- Prüfe Namen von Parts
                    if child:IsA("BasePart") then
                        if containsKeyword(child.Name) then
                            found = true
                            break
                        end
                    end
                end
            end

            -- 3. Attribute des Modells prüfen
            if not found then
                for _, attrValue in pairs(model:GetAttributes()) do
                    local val = tostring(attrValue)
                    if containsKeyword(val) then
                        found = true
                        break
                    end
                end
            end

            if found then
                return model
            end
        end
    end
    return nil
end

-- // ---- HILFSFUNKTION: Nächstbesten Part im Modell finden ----
local function getModelPart(model)
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    return model:FindFirstChildWhichIsA("BasePart")
end

-- // ---- HAUPT-SCHLEIFE (wird in einer Koroutine gestartet) ----
local function startLoop()
    if loopCoroutine then
        task.cancel(loopCoroutine)
        loopCoroutine = nil
    end

    loopCoroutine = task.spawn(function()
        while not shutdown do
            if running then
                statusLabel.Text = "🔄 Suche Modell..."
                local targetModel = findTargetModel()

                if targetModel then
                    statusLabel.Text = "📍 Modell gefunden: " .. targetModel.Name

                    -- 1. Teleport zum Modell
                    local part = getModelPart(targetModel)
                    if part then
                        hrp.CFrame = part.CFrame + Vector3.new(0, 2.5, 0)
                        task.wait(0.15)
                    else
                        statusLabel.Text = "⚠️ Kein Part im Modell!"
                        task.wait(LOOP_WAIT)
                        continue
                    end

                    -- 2. ProximityPrompt finden und auslösen
                    local prompt = targetModel:FindFirstChildWhichIsA("ProximityPrompt")
                    if not prompt then
                        prompt = targetModel:FindFirstChild("ProximityPrompt") -- fallback
                    end

                    if prompt then
                        statusLabel.Text = "⌨️ Drücke Prompt..."
                        prompt:InputHoldBegin()
                        task.wait(0.2)
                        prompt:InputHoldEnd()
                        task.wait(0.3)
                    else
                        statusLabel.Text = "⚠️ Kein ProximityPrompt gefunden!"
                        task.wait(LOOP_WAIT)
                        continue
                    end

                    -- 3. Zur Zielkoordinate teleportieren
                    statusLabel.Text = "🚀 Teleporte zu Ziel..."
                    hrp.CFrame = TARGET_COORDS
                    task.wait(0.2)

                    statusLabel.Text = "✅ Durchlauf abgeschlossen. Warte..."
                else
                    statusLabel.Text = "❌ Kein Modell mit 'OG'/'Secret'/'God' gefunden!"
                end

                -- Warten bis zum nächsten Durchlauf
                task.wait(LOOP_WAIT)
            else
                -- Wenn running == false, einfach warten und Status aktualisieren
                statusLabel.Text = "⏸ Gestoppt"
                task.wait(0.5)
            end
        end
    end)
end

-- // ---- TOGGLE-FUNKTION ----
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
print("✅ GUI geladen. Drücke 'Start' um die Automatisierung zu beginnen.")
statusLabel.Text = "⏸ Gestoppt"
