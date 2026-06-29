--[[
    🔍 PART-ESP MIT UI (FIXED)
    Gib ein Wort ein, und alle Parts mit diesem Wort im Namen werden hervorgehoben.
    GUI erscheint jetzt zuverlässig in PlayerGui.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- ===== 🎨 FARBEN & EINSTELLUNGEN =====
local CONFIG = {
    HighlightColor = Color3.fromRGB(0, 255, 200),
    OutlineColor = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(255, 255, 255),
    TextSize = 18,
    UpdateInterval = 0.15,
    ShowDistance = true,
    OffsetHeight = 2.5,
}

-- ===== INTERNER SPEICHER =====
local activeTerms = {}
local espMap = {}

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

local function createESP(instance)
    if espMap[instance] then return end
    local adornee = getAdornee(instance)
    if not adornee then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Search_Highlight"
    highlight.Adornee = instance
    highlight.FillColor = CONFIG.HighlightColor
    highlight.OutlineColor = CONFIG.OutlineColor
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = instance

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

    espMap[instance] = {
        Highlight = highlight,
        Billboard = billboard,
        TextLabel = textLabel,
        Adornee = adornee,
        DisplayName = instance.Name,
    }

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
            data.TextLabel.Text = (CONFIG.ShowDistance and (data.DisplayName .. "  |  " .. distance)) or data.DisplayName
            task.wait(CONFIG.UpdateInterval)
        end
    end)
end

local function removeESP(instance)
    local data = espMap[instance]
    if data then
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
        espMap[instance] = nil
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
end

local function clearAllESP()
    for instance, _ in pairs(espMap) do
        removeESP(instance)
    end
    activeTerms = {}
    updateStatusLabel()
    print("🧹 Alle ESPs wurden entfernt.")
end

-- ===== UI-STATUS UPDATE =====

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

-- ===== UI ERSTELLEN (in PlayerGui) =====

local function createUI()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        playerGui = Instance.new("PlayerGui")
        playerGui.Parent = LocalPlayer
    end

    -- Alte GUI löschen, falls vorhanden
    local oldGui = playerGui:FindFirstChild("PartSearchESP_GUI")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PartSearchESP_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Haupt-Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 180)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 120)
    mainFrame.ClipsDescendants = true
    mainFrame.Draggable = true
    mainFrame.Active = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    -- Titel
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔍 Part-ESP Suche"
    title.TextColor3 = Color3.fromRGB(220, 220, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = mainFrame

    -- Eingabefeld
    local textBox = Instance.new("TextBox")
    textBox.Name = "SearchBox"
    textBox.Size = UDim2.new(1, -20, 0, 35)
    textBox.Position = UDim2.new(0, 10, 0, 35)
    textBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    textBox.BorderSizePixel = 0
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 16
    textBox.Font = Enum.Font.GothamMedium
    textBox.PlaceholderText = "Wort eingeben (z.B. 'Truhe')"
    textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 180)
    textBox.ClearTextOnFocus = false
    textBox.Parent = mainFrame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = textBox

    -- Button-Container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 0, 40)
    buttonContainer.Position = UDim2.new(0, 0, 0, 75)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = mainFrame

    -- Suchen-Button
    local searchBtn = Instance.new("TextButton")
    searchBtn.Name = "SearchBtn"
    searchBtn.Size = UDim2.new(0.45, -5, 1, 0)
    searchBtn.Position = UDim2.new(0, 0, 0, 0)
    searchBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 140)
    searchBtn.BorderSizePixel = 0
    searchBtn.Text = "➕ Hinzufügen"
    searchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBtn.TextSize = 15
    searchBtn.Font = Enum.Font.GothamBold
    searchBtn.Parent = buttonContainer

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 4)
    searchCorner.Parent = searchBtn

    -- Clear-Button
    local clearBtn = Instance.new("TextButton")
    clearBtn.Name = "ClearBtn"
    clearBtn.Size = UDim2.new(0.45, -5, 1, 0)
    clearBtn.Position = UDim2.new(0.55, 0, 0, 0)
    clearBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    clearBtn.BorderSizePixel = 0
    clearBtn.Text = "🗑️ Alles entfernen"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 15
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.Parent = buttonContainer

    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 4)
    clearCorner.Parent = clearBtn

    -- Status-Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -20, 0, 35)
    statusLabel.Position = UDim2.new(0, 10, 0, 125)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Aktiv: Keine"
    statusLabel.TextColor3 = Color3.fromRGB(180, 180, 210)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextWrapped = true
    statusLabel.Parent = mainFrame

    -- Referenz für Status-Updates
    statusLabelRef = statusLabel

    -- ===== EVENTS =====

    searchBtn.MouseButton1Click:Connect(function()
        local term = textBox.Text
        if string.len(term) > 0 then
            searchAndAdd(term)
            textBox.Text = ""
        else
            print("⚠️ Bitte ein Wort eingeben.")
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

    print("✅ UI erfolgreich in PlayerGui erstellt!")
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

print("🚀 Starte Part-ESP mit UI (PlayerGui)...")
createUI()
print("✅ Fertig. Gib ein Wort ein, um Teile hervorzuheben!")
