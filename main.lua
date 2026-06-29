--[[
    🔍 PART-ESP MIT TRACERN, KAMERA-FOKUS & PART-WECHSEL
    - Suche Parts nach Namen (UI)
    - Highlight + Text + Tracer
    - F: Kamera auf aktuelles Part fokussieren
    - Q / E: Durch Parts blättern
]]

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- ===== KONFIGURATION =====
local CONFIG = {
    HighlightColor = Color3.fromRGB(0, 255, 200),
    OutlineColor = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(0, 200, 255),
    TracerThickness = 1.5,
    TextSize = 18,
    UpdateInterval = 0.1,
    ShowDistance = true,
    OffsetHeight = 2.5,
    FocusDistance = 8,          -- Abstand der Kamera vom Part
    FocusHeightOffset = 2,      -- Zusätzliche Höhe über dem Part
}

-- ===== INTERNER SPEICHER =====
local activeTerms = {}
local espMap = {}               -- Part -> ESP-Daten
local tracerObjects = {}        -- Part -> Tracer-Linie
local espPartsList = {}         -- Geordnete Liste aller ge-ESPten Parts
local currentFocusIndex = 0     -- 0 = keiner fokussiert
local isFocusing = false        -- Verhindert doppelte Fokussierung

-- ===== DRAWING API (Tracer) =====
local function createTracer(part)
    if tracerObjects[part] then return end
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = CONFIG.TracerColor
    tracer.Thickness = CONFIG.TracerThickness
    tracer.Transparency = 1
    tracerObjects[part] = tracer
    return tracer
end

local function removeTracer(part)
    local tracer = tracerObjects[part]
    if tracer then
        tracer:Remove()
        tracerObjects[part] = nil
    end
end

-- ===== HILFSFUNKTIONEN =====

local function matchesActiveTerms(instance)
    local lowerName = string.lower(instance.Name)
    for _, term in ipairs(activeTerms) do
        if string.find(lowerName, string.lower(term), 1, true) then
            return true
        end
    end
    return false
end

local function getAdornee(instance)
    if instance:IsA("BasePart") then
        return instance
    elseif instance:IsA("Model") then
        local primary = instance.PrimaryPart
        if primary then return primary end
        for _, child in ipairs(instance:GetChildren()) do
            if child:IsA("BasePart") then
                return child
            end
        end
    end
    return nil
end

-- ===== ESP KERN =====

local function addPartToList(part)
    for i, p in ipairs(espPartsList) do
        if p == part then return end
    end
    table.insert(espPartsList, part)
    updateFocusStatus()
end

local function removePartFromList(part)
    for i, p in ipairs(espPartsList) do
        if p == part then
            table.remove(espPartsList, i)
            if currentFocusIndex == i then
                currentFocusIndex = 0
            elseif currentFocusIndex > i then
                currentFocusIndex = currentFocusIndex - 1
            end
            break
        end
    end
    updateFocusStatus()
end

local function createESP(instance)
    if espMap[instance] then return end
    local adornee = getAdornee(instance)
    if not adornee then return end

    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Search_Highlight"
    highlight.Adornee = instance
    highlight.FillColor = CONFIG.HighlightColor
    highlight.OutlineColor = CONFIG.OutlineColor
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = instance

    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Search_Billboard"
    billboard.Adornee = adornee
    billboard.Size = UDim2.new(0, 250, 0, 50)
    billboard.StudsOffset = Vector3.new(0, CONFIG.OffsetHeight, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = instance

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ESP_Search_Text"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = CONFIG.TextColor
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextScaled = false
    textLabel.TextSize = CONFIG.TextSize
    textLabel.Text = "Lade..."
    textLabel.Parent = billboard

    -- Tracer
    local tracer = createTracer(instance)

    -- In Liste aufnehmen
    addPartToList(instance)

    -- Daten speichern
    espMap[instance] = {
        Highlight = highlight,
        Billboard = billboard,
        TextLabel = textLabel,
        Adornee = adornee,
        DisplayName = instance.Name,
        Tracer = tracer,
    }

    -- Update-Schleife für Distanz & Tracer
    task.spawn(function()
        local data = espMap[instance]
        if not data then return end
        
        while instance and instance.Parent and data.TextLabel do
            -- Distanz
            local distance = "?"
            if CONFIG.ShowDistance then
                local localChar = LocalPlayer.Character
                if localChar then
                    local head = localChar:FindFirstChild("Head")
                    if head and data.Adornee then
                        local dist = (data.Adornee.Position - head.Position).Magnitude
                        distance = string.format("%.1f", dist) .. "m"
                    end
                end
            end
            
            -- Text
            if CONFIG.ShowDistance then
                data.TextLabel.Text = data.DisplayName .. "  |  " .. distance
            else
                data.TextLabel.Text = data.DisplayName
            end
            
            -- Tracer
            if data.Tracer then
                local localChar = LocalPlayer.Character
                if localChar and data.Adornee then
                    local head = localChar:FindFirstChild("Head")
                    if head then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(data.Adornee.Position)
                        if onScreen then
                            data.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            data.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                            data.Tracer.Visible = true
                        else
                            data.Tracer.Visible = false
                        end
                    end
                end
            end
            
            task.wait(CONFIG.UpdateInterval)
        end
        
        -- Aufräumen
        if instance then
            removeTracer(instance)
            removePartFromList(instance)
        end
    end)
end

local function removeESP(instance)
    local data = espMap[instance]
    if data then
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
        removeTracer(instance)
        espMap[instance] = nil
        removePartFromList(instance)
    end
end

-- ===== KAMERA-FOKUS =====

local function focusOnPart(index)
    if #espPartsList == 0 then
        print("⚠️ Keine Parts zum Fokussieren vorhanden.")
        return
    end
    if index < 1 then index = 1 end
    if index > #espPartsList then index = #espPartsList end
    
    currentFocusIndex = index
    local part = espPartsList[index]
    if not part or not part.Parent then
        print("⚠️ Part existiert nicht mehr.")
        return
    end
    
    local adornee = getAdornee(part)
    if not adornee then return end
    
    -- Kamera-Position berechnen: von aktueller Kamera-Position aus in Richtung Part
    local camPos = Camera.CFrame.Position
    local targetPos = adornee.Position
    local direction = (targetPos - camPos).Unit
    -- Falls Kamera zu nah am Part, nimm Standard-Richtung
    if (targetPos - camPos).Magnitude < 1 then
        direction = Vector3.new(0, 1, 0)  -- von oben
    end
    -- Neue Kameraposition: Part-Position - Richtung * Distanz + Höhenoffset
    local newPos = targetPos - direction * CONFIG.FocusDistance
    newPos = newPos + Vector3.new(0, CONFIG.FocusHeightOffset, 0)
    
    -- Kamera setzen
    Camera.CFrame = CFrame.new(newPos, targetPos)
    
    print("📷 Fokussiert auf: " .. part.Name .. " (" .. index .. "/" .. #espPartsList .. ")")
    updateFocusStatus()
end

local function focusNext()
    if #espPartsList == 0 then return end
    local newIndex = (currentFocusIndex % #espPartsList) + 1
    focusOnPart(newIndex)
end

local function focusPrevious()
    if #espPartsList == 0 then return end
    local newIndex = ((currentFocusIndex - 2) % #espPartsList) + 1
    focusOnPart(newIndex)
end

-- ===== UI-STATUS UPDATE =====

local focusStatusLabel = nil
local focusIndicatorLabel = nil

local function updateFocusStatus()
    if focusStatusLabel then
        if #espPartsList == 0 then
            focusStatusLabel.Text = "Parts: 0 | Fokus: -"
        else
            local focusName = "Kein"
            if currentFocusIndex > 0 and espPartsList[currentFocusIndex] then
                focusName = espPartsList[currentFocusIndex].Name
            end
            focusStatusLabel.Text = "Parts: " .. #espPartsList .. " | Fokus: " .. focusName
        end
    end
    if focusIndicatorLabel then
        if currentFocusIndex > 0 and espPartsList[currentFocusIndex] then
            focusIndicatorLabel.Text = "▶ Fokussiert: " .. espPartsList[currentFocusIndex].Name
            focusIndicatorLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
        else
            focusIndicatorLabel.Text = "Kein Part fokussiert (drücke F)"
            focusIndicatorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end

-- ===== SUCHFUNKTIONEN =====

local function searchAndAdd(term)
    if not term or string.len(term) == 0 then return end
    local cleanTerm = string.lower(term)
    for _, existing in ipairs(activeTerms) do
        if existing == cleanTerm then
            print("⚠️ Begriff '" .. term .. "' ist bereits aktiv.")
            return
        end
    end
    table.insert(activeTerms, cleanTerm)
    print("🔍 Suche nach: '" .. term .. "'")
    
    local count = 0
    for _, instance in ipairs(Workspace:GetDescendants()) do
        if (instance:IsA("BasePart") or instance:IsA("Model")) then
            if not espMap[instance] and matchesActiveTerms(instance) then
                createESP(instance)
                count = count + 1
            end
        end
    end
    updateStatusLabel()
    print("✅ " .. count .. " neue Objekte wurden zu ESP hinzugefügt.")
    if count > 0 and currentFocusIndex == 0 then
        focusOnPart(1)  -- Automatisch erstes Part fokussieren
    end
end

local function clearAllESP()
    for instance, _ in pairs(espMap) do
        removeESP(instance)
    end
    activeTerms = {}
    currentFocusIndex = 0
    updateStatusLabel()
    updateFocusStatus()
    print("🧹 Alle ESPs wurden entfernt.")
end

-- ===== UI-STATUS UPDATE (für Suchbegriffe) =====

local statusLabelRef = nil

local function updateStatusLabel()
    if statusLabelRef then
        if #activeTerms == 0 then
            statusLabelRef.Text = "Aktiv: Keine"
        else
            statusLabelRef.Text = "Aktiv: " .. table.concat(activeTerms, ", ")
        end
    end
end

-- ===== UI ERSTELLEN =====

local function createUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local oldGui = playerGui:FindFirstChild("PartSearchESP_GUI")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PartSearchESP_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    screenGui.Enabled = true

    -- Haupt-Frame (etwas größer für mehr Infos)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 360, 0, 250)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 130)
    mainFrame.ClipsDescendants = true
    mainFrame.Draggable = true
    mainFrame.Active = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    -- Titel
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔍 Part-ESP + Tracer + Kamera"
    title.TextColor3 = Color3.fromRGB(220, 220, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = mainFrame

    -- Eingabefeld
    local textBox = Instance.new("TextBox")
    textBox.Name = "SearchBox"
    textBox.Size = UDim2.new(1, -20, 0, 38)
    textBox.Position = UDim2.new(0, 10, 0, 40)
    textBox.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    textBox.BorderSizePixel = 0
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 16
    textBox.Font = Enum.Font.GothamMedium
    textBox.PlaceholderText = "Wort eingeben (z.B. 'Truhe')"
    textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 190)
    textBox.ClearTextOnFocus = false
    textBox.Parent = mainFrame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 5)
    boxCorner.Parent = textBox

    -- Button-Container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 0, 42)
    buttonContainer.Position = UDim2.new(0, 0, 0, 83)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = mainFrame

    -- Suchen-Button
    local searchBtn = Instance.new("TextButton")
    searchBtn.Name = "SearchBtn"
    searchBtn.Size = UDim2.new(0.45, -5, 1, 0)
    searchBtn.Position = UDim2.new(0, 0, 0, 0)
    searchBtn.BackgroundColor3 = Color3.fromRGB(0, 190, 150)
    searchBtn.BorderSizePixel = 0
    searchBtn.Text = "➕ Hinzufügen"
    searchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBtn.TextSize = 16
    searchBtn.Font = Enum.Font.GothamBold
    searchBtn.Parent = buttonContainer

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 5)
    searchCorner.Parent = searchBtn

    -- Clear-Button
    local clearBtn = Instance.new("TextButton")
    clearBtn.Name = "ClearBtn"
    clearBtn.Size = UDim.new(0.45, -5, 1, 0)
    clearBtn.Position = UDim.new(0.55, 0, 0, 0)
    clearBtn.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
    clearBtn.BorderSizePixel = 0
    clearBtn.Text = "🗑️ Alles entfernen"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 16
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.Parent = buttonContainer

    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 5)
    clearCorner.Parent = clearBtn

    -- Status (aktive Begriffe)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -20, 0, 30)
    statusLabel.Position = UDim2.new(0, 10, 0, 130)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Aktiv: Keine"
    statusLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextWrapped = true
    statusLabel.Parent = mainFrame
    statusLabelRef = statusLabel

    -- Trennlinie
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -20, 0, 1)
    line.Position = UDim2.new(0, 10, 0, 165)
    line.BackgroundColor3 = Color3.fromRGB(80, 80, 130)
    line.BackgroundTransparency = 0.5
    line.Parent = mainFrame

    -- Fokus-Status (Parts-Anzahl + aktueller Fokus)
    local focusLabel = Instance.new("TextLabel")
    focusLabel.Name = "FocusLabel"
    focusLabel.Size = UDim2.new(1, -20, 0, 25)
    focusLabel.Position = UDim2.new(0, 10, 0, 175)
    focusLabel.BackgroundTransparency = 1
    focusLabel.Text = "Parts: 0 | Fokus: -"
    focusLabel.TextColor3 = Color3.fromRGB(200, 200, 230)
    focusLabel.TextSize = 14
    focusLabel.Font = Enum.Font.GothamMedium
    focusLabel.TextXAlignment = Enum.TextXAlignment.Left
    focusLabel.Parent = mainFrame
    focusStatusLabel = focusLabel

    -- Fokus-Indikator (welches Part)
    local indicator = Instance.new("TextLabel")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(1, -20, 0, 30)
    indicator.Position = UDim2.new(0, 10, 0, 205)
    indicator.BackgroundTransparency = 1
    indicator.Text = "Kein Part fokussiert (drücke F)"
    indicator.TextColor3 = Color3.fromRGB(200, 200, 200)
    indicator.TextSize = 14
    indicator.Font = Enum.Font.GothamMedium
    indicator.TextXAlignment = Enum.TextXAlignment.Left
    indicator.TextWrapped = true
    indicator.Parent = mainFrame
    focusIndicatorLabel = indicator

    -- ===== EVENTS =====

    searchBtn.MouseButton1Click:Connect(function()
        local term = textBox.Text
        if string.len(term) > 0 then
            searchAndAdd(term)
            textBox.Text = ""
        end
    end)

    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local term = textBox.Text
            if string.len(term) > 0 then
                searchAndAdd(term)
                textBox.Text = ""
            end
        end
    end)

    clearBtn.MouseButton1Click:Connect(function()
        clearAllESP()
    end)

    updateFocusStatus()
    print("✅ UI erstellt. Steuerung: F = Fokus, Q/E = Part wechseln")
end

-- ===== TASTATUR-STEUERUNG =====

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        if #espPartsList > 0 then
            if currentFocusIndex == 0 then
                focusOnPart(1)
            else
                focusOnPart(currentFocusIndex)
            end
        end
    elseif input.KeyCode == Enum.KeyCode.E then
        focusNext()
    elseif input.KeyCode == Enum.KeyCode.Q then
        focusPrevious()
    end
end)

-- ===== NEUE OBJEKTE ÜBERWACHEN =====

Workspace.DescendantAdded:Connect(function(instance)
    task.wait(0.05)
    if (instance:IsA("BasePart") or instance:IsA("Model")) then
        if not espMap[instance] and matchesActiveTerms(instance) then
            createESP(instance)
        end
    end
end)

-- ===== START =====

print("🚀 Starte Part-ESP mit Tracern, Kamera & Wechselfunktion...")
createUI()
print("✅ Fertig. Steuerung: F = Fokussieren, Q/E = Wechseln")
