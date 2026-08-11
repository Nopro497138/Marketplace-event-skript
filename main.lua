--[[
    Auto Celestial/OG – Delta Executor (fixierte UI)
    - Durchsucht workspace.Bases nach Modellen mit "Celestial" oder "OG"
    - Teleportiert Spieler zum Modell, feuert ProximityPrompt (0.8s), teleportiert zu -150, 6, -597
    - Wiederholt im Loop
    - GUI mit sichtbaren Buttons: Toggle, Minimize, Close, Drag
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

if not fireproximityprompt then
    warn("⚠️  fireproximityprompt nicht gefunden – bitte Delta Executor verwenden!")
end

-- ============================
-- UI Erstellung (komplett überarbeitet)
-- ============================
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoCelestialOG"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Hauptframe (undurchsichtig)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 180)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -90)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 40, 60) -- dunkles Blaugrau
    mainFrame.BackgroundTransparency = 0 -- voll deckend
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    -- Abrundung
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- Schatten
    local shadow = Instance.new("UIShadow")
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Offset = Vector2.new(3, 3)
    shadow.BlurRadius = 10
    shadow.Transparency = 0.5
    shadow.Parent = mainFrame

    -- Titelzeile (dragbar)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = Color3.fromRGB(50, 65, 90)
    titleBar.BackgroundTransparency = 0
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    -- Titeltext
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -70, 1, 0)
    titleLabel.Position = UDim2.new(0, 8, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⚡ Auto Celestial / OG"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Minimize Button (sichtbar)
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 28, 0, 26)
    minimizeBtn.Position = UDim2.new(1, -60, 0, 3)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(70, 85, 110)
    minimizeBtn.BackgroundTransparency = 0
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Text = "─"
    minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeBtn.TextSize = 20
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = titleBar

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = minimizeBtn

    -- Close Button (sichtbar)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 26)
    closeBtn.Position = UDim2.new(1, -30, 0, 3)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.BackgroundTransparency = 0
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    -- Content (unterhalb der TitleBar)
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -32)
    content.Position = UDim2.new(0, 0, 0, 32)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame

    -- Toggle Button (groß, auffällig)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 200, 0, 44)
    toggleBtn.Position = UDim2.new(0.5, -100, 0.5, -30)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 220) -- kräftiges Blau
    toggleBtn.BackgroundTransparency = 0
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "▶ Start"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 20
    toggleBtn.Font = Enum.Font.GothamSemibold
    toggleBtn.Parent = content

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 10)
    toggleCorner.Parent = toggleBtn

    -- Status Label (deutlich sichtbar)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 30)
    statusLabel.Position = UDim2.new(0, 0, 1, -32)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Idle"
    statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    statusLabel.TextSize = 15
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.Parent = content

    -- Drag-Funktion
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    -- Minimize / Maximize
    local minimized = false
    local originalSize = mainFrame.Size
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            mainFrame.Size = UDim2.new(0, 320, 0, 32) -- nur Titelzeile
            content.Visible = false
            minimizeBtn.Text = "□"
        else
            mainFrame.Size = originalSize
            content.Visible = true
            minimizeBtn.Text = "─"
        end
    end)

    -- Close
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        isRunning = false
    end)

    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        ToggleBtn = toggleBtn,
        StatusLabel = statusLabel,
        Content = content,
        MinimizeBtn = minimizeBtn,
        CloseBtn = closeBtn
    }
end

-- ============================
-- Hilfsfunktionen (unverändert)
-- ============================
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

-- ============================
-- Hauptlogik
-- ============================
local ui = createUI()
local toggleBtn = ui.ToggleBtn
local statusLabel = ui.StatusLabel
local isRunning = false

local function updateStatus(text, color)
    statusLabel.Text = "Status: " .. text
    statusLabel.TextColor3 = color or Color3.fromRGB(220, 220, 220)
end

local function executeCycle()
    local bases = workspace:FindFirstChild("Bases")
    if not bases then
        warn("❌ workspace.Bases nicht gefunden!")
        return false
    end

    local targetModels = {}
    for _, child in ipairs(bases:GetChildren()) do
        if child:IsA("Model") then
            if textContains(child, "Celestial") or textContains(child, "OG") then
                table.insert(targetModels, child)
            end
        end
    end

    if #targetModels == 0 then
        warn("⚠️  Kein Modell mit 'Celestial' oder 'OG' gefunden.")
        return false
    end

    for _, model in ipairs(targetModels) do
        if not isRunning then break end

        local modelPos = getModelPosition(model)
        if not modelPos then
            warn("❌ Keine gültige Position für Modell: " .. model.Name)
            continue
        end

        local character = LocalPlayer.Character
        if not character then
            warn("❌ Charakter nicht vorhanden.")
            return false
        end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            warn("❌ HumanoidRootPart nicht gefunden.")
            return false
        end

        -- 1. Teleport zum Modell
        local teleportPos = modelPos + Vector3.new(0, 3, 0)
        hrp.CFrame = CFrame.new(teleportPos)
        task.wait(0.1)

        -- 2. Prompt suchen und feuern
        local prompt = findPrompt(model)
        if prompt and fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(0.8) -- 0.8 Sekunden halten
        else
            warn("⚠️  Kein ProximityPrompt oder fireproximityprompt nicht verfügbar in: " .. model.Name)
        end

        -- 3. Teleport zur Zielposition
        hrp.CFrame = CFrame.new(-150, 6, -597)
        task.wait(0.2)
    end

    return true
end

local function startLoop()
    isRunning = true
    toggleBtn.Text = "⏹ Stop"
    toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70) -- rot für Stop
    updateStatus("Running...", Color3.fromRGB(100, 255, 100))

    task.spawn(function()
        while isRunning do
            local success = pcall(executeCycle)
            if not success then
                warn("❌ Fehler im Zyklus.")
            end
            if isRunning then
                task.wait(1) -- Pause zwischen Zyklen
            end
        end
        updateStatus("Stopped", Color3.fromRGB(255, 100, 100))
        toggleBtn.Text = "▶ Start"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 220)
    end)
end

-- Toggle
toggleBtn.MouseButton1Click:Connect(function()
    if isRunning then
        isRunning = false
        updateStatus("Stopping...", Color3.fromRGB(255, 200, 100))
    else
        startLoop()
    end
end)

-- Initialer Status
updateStatus("Idle", Color3.fromRGB(220, 220, 220))

-- Bei Schließen der GUI stoppen
ui.CloseBtn.MouseButton1Click:Connect(function()
    isRunning = false
end)
