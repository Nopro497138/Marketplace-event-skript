-- // ---- EINSTELLUNGEN ----
local TARGET_COORDS = CFrame.new(-150, 6, -597)
local LOOP_WAIT = 0.05
local HOLD_TIME = 0.8
local FIRE_INTERVAL = 0.05

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

-- // ---- HILFSFUNKTIONEN (Text-Suche) ----
local function textContains(instance, searchText)
    if not instance then return false end
    if instance.Name and string.find(instance.Name, searchText, 1, true) then
        return true
    end
    local attrs = instance:GetAttributes()
    for _, v in pairs(attrs) do
        if type(v) == "string" and string.find(v, searchText, 1, true) then
            return true
        end
    end
    for _, child in ipairs(instance:GetChildren()) do
        if child:IsA("StringValue") and child.Value and string.find(child.Value, searchText, 1, true) then
            return true
        end
        if child:IsA("TextLabel") and child.Text and string.find(child.Text, searchText, 1, true) then
            return true
        end
        if child:IsA("TextButton") and child.Text and string.find(child.Text, searchText, 1, true) then
            return true
        end
        if child:IsA("TextBox") and child.Text and string.find(child.Text, searchText, 1, true) then
            return true
        end
        if textContains(child, searchText) then
            return true
        end
    end
    return false
end

local function findPrompt(instance)
    if instance:IsA("ProximityPrompt") then
        return instance
    end
    for _, child in ipairs(instance:GetChildren()) do
        local found = findPrompt(child)
        if found then
            return found
        end
    end
    return nil
end

local function getModelPosition(model)
    if model:IsA("Model") then
        if model.PrimaryPart then
            return model.PrimaryPart.Position
        end
        for _, child in ipairs(model:GetDescendants()) do
            if child:IsA("BasePart") then
                return child.Position
            end
        end
        return model:GetPivot().Position
    end
    return nil
end

-- // ---- GUI ERSTELLEN (exakt wie vorgegeben, nur Text angepasst) ----
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
titleText.Text = "⚡ Auto Celestial / OG"
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

-- // ---- MODELL-SUCHE (nach Celestial/OG in Name, Attributen oder Text-Kindern) ----
local function findBestModel()
    local folder = workspace:FindFirstChild("Bases")
    if not folder then
        statusLabel.Text = "❌ Ordner 'Bases' nicht gefunden!"
        return nil
    end

    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            if textContains(model, "Celestial") or textContains(model, "OG") then
                return model
            end
        end
    end
    return nil
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
                local targetModel = findBestModel()

                if targetModel then
                    statusLabel.Text = "📍 Modell gefunden: " .. targetModel.Name

                    local modelPos = getModelPosition(targetModel)
                    if modelPos then
                        hrp.CFrame = CFrame.new(modelPos + Vector3.new(0, 3, 0))
                        task.wait(0.1)
                    else
                        statusLabel.Text = "⚠️ Keine Position im Modell!"
                        task.wait(LOOP_WAIT)
                        goto continue
                    end

                    local prompt = findPrompt(targetModel)
                    if prompt then
                        statusLabel.Text = "⌨️ Halte ProximityPrompt (" .. HOLD_TIME .. "s)..."
                        local startTime = tick()
                        while tick() - startTime < HOLD_TIME do
                            if fireproximityprompt then
                                fireproximityprompt(prompt)
                            else
                                warn("❌ fireproximityprompt nicht verfügbar!")
                                break
                            end
                            task.wait(FIRE_INTERVAL)
                        end
                        task.wait(0.1)
                    else
                        statusLabel.Text = "⚠️ Kein ProximityPrompt im Modell!"
                        task.wait(LOOP_WAIT)
                        goto continue
                    end

                    statusLabel.Text = "🚀 Teleporte zu Ziel..."
                    hrp.CFrame = TARGET_COORDS
                    task.wait(0.1)

                    statusLabel.Text = "✅ Durchlauf abgeschlossen. Warte..."
                else
                    statusLabel.Text = "❌ Kein Modell mit 'Celestial' oder 'OG' gefunden!"
                end

                ::continue::
                task.wait(LOOP_WAIT)
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
print("✅ GUI geladen. Es werden Modelle in workspace.Bases mit 'Celestial' oder 'OG' gesucht.")
statusLabel.Text = "⏸ Gestoppt"
