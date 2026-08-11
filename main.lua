-- // ---- EINSTELLUNGEN ----
local TARGET_COORDS = CFrame.new(-150, 6, -597) -- Zielkoordinaten
local LOOP_WAIT = 0.05 -- Minimale Pause zwischen Runs
local HOLD_TIME = 0.8 -- Haltezeit des Prompts (Sekunden)
local FIRE_INTERVAL = 0.05 -- Intervall für wiederholtes Feuern

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

-- // ---- HILFSFUNKTION: Keyword im Text erkennen ----
local function findKeyword(text)
    local lower = string.lower(text)
    if string.find(lower, "celestial") then return "celestial" end
    if string.find(lower, "og") then return "og" end
    return nil
end

-- // ---- GUI ERSTELLEN ----
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BaseFarmGUI"
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
titleText.Text = "🏠 Base Farm (Celestial/OG)"
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
        loopCoroutine = nil -- Coroutine wird beim nächsten Durchlauf beendet
    end
    screenGui:Destroy()
    print("🔴 Skript wurde vollständig beendet.")
end)

-- // ---- MODELL-SUCHE (durchsucht Name, Werte, Attribute) ----
local function findBestModel()
    local folder = workspace:FindFirstChild("Bases")
    if not folder then
        statusLabel.Text = "❌ Ordner 'Bases' nicht gefunden!"
        return nil, nil
    end

    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            local keywordFound = nil

            -- 1. Modellname
            local kw = findKeyword(model.Name)
            if kw then keywordFound = kw end

            -- 2. Werte in Descendants (StringValue, IntValue, ...)
            if not keywordFound then
                for _, child in ipairs(model:GetDescendants()) do
                    if child:IsA("StringValue") or child:IsA("ObjectValue") or
                       child:IsA("IntValue") or child:IsA("BoolValue") or child:IsA("NumberValue") then
                        local val = tostring(child.Value)
                        kw = findKeyword(val)
                        if kw then
                            keywordFound = kw
                            break
                        end
                    end
                end
            end

            -- 3. Attribute
            if not keywordFound then
                for _, attrValue in pairs(model:GetAttributes()) do
                    local val = tostring(attrValue)
                    kw = findKeyword(val)
                    if kw then
                        keywordFound = kw
                        break
                    end
                end
            end

            if keywordFound then
                return model, keywordFound
            end
        end
    end

    return nil, nil
end

-- // ---- HILFSFUNKTION: Part im Modell finden ----
local function getModelPart(model)
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    return model:FindFirstChildWhichIsA("BasePart")
end

-- // ---- PROMPT FINDEN (ProximityPrompt oder PickupPrompt) ----
local function getPrompt(model)
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("ProximityPrompt") or child:IsA("PickupPrompt") then
            return child
        end
    end
    return nil
end

-- // ---- PROMPT HALTEN (robust) ----
local function holdPrompt(prompt)
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        elseif firepickupprompt then
            firepickupprompt(prompt)
        elseif prompt.Fire then
            prompt:Fire()
        else
            prompt:InputHoldBegin()
            wait(0.05)
            prompt:InputHoldEnd()
        end
    end)
end

-- // ---- HAUPT-SCHLEIFE (ohne task) ----
local function startLoop()
    if loopCoroutine then
        loopCoroutine = nil
    end

    loopCoroutine = coroutine.wrap(function()
        while not shutdown do
            if running then
                statusLabel.Text = "🔄 Suche bestes Modell..."
                local targetModel, keyword = findBestModel()

                if targetModel then
                    statusLabel.Text = "📍 Modell: " .. targetModel.Name .. " (" .. (keyword or "?") .. ")"

                    local part = getModelPart(targetModel)
                    if part then
                        hrp.CFrame = part.CFrame + Vector3.new(0, 2.5, 0)
                        wait(0.1)
                    else
                        statusLabel.Text = "⚠️ Kein Part im Modell!"
                        wait(LOOP_WAIT)
                        goto continue
                    end

                    local prompt = getPrompt(targetModel)
                    if prompt then
                        statusLabel.Text = "⌨️ Halte Prompt (" .. HOLD_TIME .. "s)..."
                        local startTime = tick()
                        while tick() - startTime < HOLD_TIME do
                            holdPrompt(prompt)
                            wait(FIRE_INTERVAL)
                        end
                        wait(0.1)
                    else
                        statusLabel.Text = "⚠️ Kein Prompt im Modell!"
                        wait(LOOP_WAIT)
                        goto continue
                    end

                    statusLabel.Text = "🚀 Teleporte zu Ziel..."
                    hrp.CFrame = TARGET_COORDS
                    wait(0.1)

                    statusLabel.Text = "✅ Durchlauf abgeschlossen. Warte..."
                else
                    statusLabel.Text = "❌ Kein Modell mit 'Celestial' oder 'OG' gefunden!"
                end

                ::continue::
                wait(LOOP_WAIT)
            else
                statusLabel.Text = "⏸ Gestoppt"
                wait(0.5)
            end
        end
    end)

    loopCoroutine() -- starten
end

-- // ---- TOGGLE ----
local function toggle()
    if shutdown then return end
    running = not running
    if running then
        toggleBtn.Text = "⏹ Stop"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        statusLabel.Text = "▶ Läuft..."
        if not loopCoroutine then
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
print("✅ Base-Farm GUI geladen. Modell mit 'Celestial' oder 'OG' wird gesucht, Prompt gehalten und teleportiert.")
statusLabel.Text = "⏸ Gestoppt"
