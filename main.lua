--[[
    🔍 PART-ESP MIT UI-NAVIGATION (Pfeile) & TOGGLE
    - Suche Parts nach Namen (UI)
    - Highlight + Text + Tracer
    - Pfeile (◀ / ▶) zum Wechseln der Parts (Kamera folgt)
    - Toggle-Button zum Ein-/Ausblenden des gesamten ESPs
]]

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
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
    FocusDistance = 8,
    FocusHeightOffset = 2,
}

-- ===== INTERNER SPEICHER =====
local activeTerms = {}
local espMap = {}
local tracerObjects = {}
local espPartsList = {}
local currentFocusIndex = 0
local espVisible = true  -- Toggle-Status

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
    highlight.Visible = espVisible
    highlight.Parent = instance

    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Search_Billboard"
    billboard.Adornee = adornee
    billboard.Size = UDim2.new(0, 250, 0, 50)
    billboard.StudsOffset = Vector3.new(0, CONFIG.OffsetHeight, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = espVisible
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

    addPartToList(instance)

    espMap[instance] = {
        Highlight = highlight,
        Billboard = billboard,
        TextLabel = textLabel,
        Adornee = adornee,
        DisplayName = instance.Name,
        Tracer = tracer,
    }

    -- Update-Schleife
    task.spawn(function()
        local data = espMap[instance]
        if not data then return end
        
        while instance and instance.Parent and data.TextLabel do
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
            
            if CONFIG.ShowDistance then
                data.TextLabel.Text = data.DisplayName .. "  |  " .. distance
            else
                data.TextLabel.Text = data.DisplayName
            end
            
            -- Tracer nur aktualisieren wenn sichtbar
            if data.Tracer and espVisible then
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
            elseif data.Tracer then
                data.Tracer.Visible = false
            end
            
            task.wait(CONFIG.UpdateInterval)
        end
        
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

-- ===== TOGGLE-FUNKTION =====

local function toggleESP()
    espVisible = not espVisible
    
    -- Alle Highlights und Billboards umschalten
    for instance, data in pairs(espMap) do
        if data.Highlight then
            data.Highlight.Visible = espVisible
        end
        if data.Billboard then
            data.Billboard.Enabled = espVisible
        end
        if data.Tracer then
            if not espVisible then
                data.Tracer.Visible = false
            end
        end
    end
    
    -- Button-Text aktualisieren (wird über UI-Referenz gemacht)
    if toggleButtonRef then
        if espVisible then
            toggleButtonRef.Text = "👁️ ESP ausblenden"
            toggleButtonRef.BackgroundColor3 = Color3.fromRGB(60, 60, 180)
        else
            toggleButtonRef.Text = "🚫 ESP einblenden"
            toggleButtonRef.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        end
    end
    
    print("👁️ ESP " .. (espVisible and "eingeblendet" or "ausgeblendet"))
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
    
    local camPos = Camera.CFrame.Position
    local targetPos = adornee.Position
    local direction = (targetPos - camPos).Unit
    if (targetPos - camPos).Magnitude < 1 then
        direction = Vector3.new(0, 1, 0)
    end
    local newPos = targetPos - direction * CONFIG.FocusDistance
    newPos = newPos + Vector3.new(0, CONFIG.FocusHeightOffset, 0)
    
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
local toggleButtonRef = nil

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
            focusIndicatorLabel.Text = "Kein Part fokussiert (Pfeile nutzen)"
            focusIndicatorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end

-- ===== SUCHFUNKTIONEN =====

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
        focusOnPart(1)
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

    -- Haupt-Frame (etwas höher für neue Buttons)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 380, 0, 290)
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
    title.Text = "🔍 Part-ESP + Navigation"
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

    -- Erste Button-Zeile (Suchen + Löschen)
    local buttonContainer1 = Instance.new("Frame")
    buttonContainer1.Name = "ButtonContainer1"
    buttonContainer1.Size = UDim2.new(1, 0, 0, 42)
    buttonContainer1.Position = UDim2.new(0, 0, 0, 83)
    buttonContainer1.BackgroundTransparency = 1
    buttonContainer1.Parent = mainFrame

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
    searchBtn.Parent = buttonContainer1

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 5)
    searchCorner.Parent = searchBtn

    -- Clear-Button
    local clearBtn = Instance.new("TextButton")
    clearBtn.Name = "ClearBtn"
    clearBtn.Size = UDim2.new(0.45, -5, 1, 0)
    clearBtn.Position = UDim2.new(0.55, 0, 0, 0)
    clearBtn.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
    clearBtn.BorderSizePixel = 0
    clearBtn.Text = "🗑️ Alles entfernen"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 16
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.Parent = buttonContainer1

    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 5)
    clearCorner.Parent = clearBtn

    -- Zweite Button-Zeile (Navigation + Toggle)
    local buttonContainer2 = Instance.new("Frame")
    buttonContainer2.Name = "ButtonContainer2"
    buttonContainer2.Size = UDim2.new(1, 0, 0, 42)
    buttonContainer2.Position = UDim2.new(0, 0, 0, 130)
    buttonContainer2.BackgroundTransparency = 1
    buttonContainer2.Parent = mainFrame

    -- Pfeil links (vorheriges Part)
    local prevBtn = Instance.new("TextButton")
    prevBtn.Name = "PrevBtn"
    prevBtn.Size = UDim2.new(0.15, 0, 1, 0)
    prevBtn.Position = UDim2.new(0, 0, 0, 0)
    prevBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    prevBtn.BorderSizePixel = 0
    prevBtn.Text = "◀"
    prevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    prevBtn.TextSize = 22
    prevBtn.Font = Enum.Font.GothamBold
    prevBtn.Parent = buttonContainer2

    local prevCorner = Instance.new("UICorner")
    prevCorner.CornerRadius = UDim.new(0, 5)
    prevCorner.Parent = prevBtn

    -- Fokus-Status (zentriert zwischen den Pfeilen)
    local focusNavLabel = Instance.new("TextLabel")
    focusNavLabel.Name = "FocusNavLabel"
    focusNavLabel.Size = UDim2.new(0.5, 0, 1, 0)
    focusNavLabel.Position = UDim2.new(0.2, 0, 0, 0)
    focusNavLabel.BackgroundTransparency = 1
    focusNavLabel.Text = "Part 1/5"
    focusNavLabel.TextColor3 = Color3.fromRGB(200, 200, 230)
    focusNavLabel.TextSize = 16
    focusNavLabel.Font = Enum.Font.GothamBold
    focusNavLabel.TextXAlignment = Enum.TextXAlignment.Center
    focusNavLabel.Parent = buttonContainer2

    -- Pfeil rechts (nächstes Part)
    local nextBtn = Instance.new("TextButton")
    nextBtn.Name = "NextBtn"
    nextBtn.Size = UDim2.new(0.15, 0, 1, 0)
    nextBtn.Position = UDim2.new(0.85, 0, 0, 0)
    nextBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    nextBtn.BorderSizePixel = 0
    nextBtn.Text = "▶"
    nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    nextBtn.TextSize = 22
    nextBtn.Font = Enum.Font.GothamBold
    nextBtn.Parent = buttonContainer2

    local nextCorner = Instance.new("UICorner")
    nextCorner.CornerRadius = UDim.new(0, 5)
    nextCorner.Parent = nextBtn

    -- Dritte Zeile: Toggle-Button (zentriert)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.new(0.6, 0, 0, 38)
    toggleBtn.Position = UDim2.new(0.2, 0, 0, 177)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 180)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "👁️ ESP ausblenden"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 16
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = mainFrame
    toggleButtonRef = toggleBtn

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 5)
    toggleCorner.Parent = toggleBtn

    -- Status (aktive Begriffe)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -20, 0, 28)
    statusLabel.Position = UDim2.new(0, 10, 0, 220)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Aktiv: Keine"
    statusLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextWrapped = true
    statusLabel.Parent = mainFrame
    statusLabelRef = statusLabel

    -- Fokus-Status (Parts-Anzahl + aktueller Fokus)
    local focusLabel = Instance.new("TextLabel")
    focusLabel.Name = "FocusLabel"
    focusLabel.Size = UDim2.new(1, -20, 0, 22)
    focusLabel.Position = UDim2.new(0, 10, 0, 250)
    focusLabel.BackgroundTransparency = 1
    focusLabel.Text = "Parts: 0 | Fokus: -"
    focusLabel.TextColor3 = Color3.fromRGB(200, 200, 230)
    focusLabel.TextSize = 13
    focusLabel.Font = Enum.Font.GothamMedium
    focusLabel.TextXAlignment = Enum.TextXAlignment.Left
    focusLabel.Parent = mainFrame
    focusStatusLabel = focusLabel

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

    -- Navigation: Vorheriges Part
    prevBtn.MouseButton1Click:Connect(function()
        focusPrevious()
        updateNavLabel(focusNavLabel)
    end)

    -- Navigation: Nächstes Part
    nextBtn.MouseButton1Click:Connect(function()
        focusNext()
        updateNavLabel(focusNavLabel)
    end)

    -- Toggle-Button
    toggleBtn.MouseButton1Click:Connect(function()
        toggleESP()
    end)

    -- Nav-Label initial aktualisieren
    updateNavLabel(focusNavLabel)
    updateFocusStatus()
    print("✅ UI erstellt. Nutze die Pfeile zum Navigieren, Toggle zum Ein-/Ausblenden.")
end

-- ===== NAV-LABEL UPDATE =====

local function updateNavLabel(label)
    if label then
        if #espPartsList == 0 then
            label.Text = "Keine Parts"
        else
            local current = (currentFocusIndex > 0 and currentFocusIndex) or 1
            label.Text = "Part " .. current .. "/" .. #espPartsList
        end
    end
end

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

print("🚀 Starte Part-ESP mit UI-Navigation & Toggle...")
createUI()
print("✅ Fertig. Nutze die Pfeile (◀/▶) zum Wechseln, Toggle zum Ein-/Ausblenden.")
