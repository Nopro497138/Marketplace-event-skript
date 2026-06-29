--[[
    ROBLOX - PART / OBJEKT ESP (Text + Highlight)
    Hebt bestimmte Teile (z.B. Truhen, Türen, Items) hervor und zeigt Namen + Distanz an.
    Keine Spieler-ESP!
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- ===== 📝 KONFIGURATION =====
local CONFIG = {
    -- Modus: "WHITELIST" (bestimmte Namen), "ATTRIBUTE" (Teile mit einem bestimmten Attribut), "ALL" (ALLE Teile - Vorsicht bei Performance!)
    Mode = "WHITELIST",
    
    -- Für WHITELIST: Teile/Modelle, die diesen Text im Namen enthalten (Groß-/Kleinschreibung egal)
    TargetNames = {"Chest", "Truhe", "Loot", "Door", "Tür", "Button", "Schalter", "Item"},
    
    -- Für ATTRIBUTE: Name des Attributes, das das Teil haben muss (z.B. "DisplayName" oder "Text")
    -- Wenn gesetzt, wird der Wert dieses Attributes als Anzeigetext verwendet.
    TargetAttribute = "ESP_Text",
    
    -- 🎨 Farben
    HighlightColor = Color3.fromRGB(0, 255, 200),  -- Türkis-Glow
    OutlineColor = Color3.fromRGB(255, 255, 255),  -- Weiße Umrandung
    TextColor = Color3.fromRGB(255, 255, 255),     -- Weißer Text
    TextSize = 18,                                 -- Schriftgröße
    
    -- Einstellungen
    ShowDistance = true,        -- Soll die Entfernung angezeigt werden?
    UpdateInterval = 0.15,      -- Wie oft die Distanz aktualisiert wird (Sekunden)
}

-- ===== INTERNE VARIABLEN =====
local ESPedObjects = {}  -- Tabelle, um bereits behandelte Objekte zu speichern

-- ===== HILFSFUNKTIONEN =====

-- Prüft, ob ein Objekt ge-ESPt werden soll
local function IsTarget(instance)
    -- Nur BaseParts (Teile) oder Modelle (Gruppen von Teilen) beachten
    if not (instance:IsA("BasePart") or instance:IsA("Model")) then return false end
    
    -- Terrain ausschließen (Performance)
    if instance:IsA("BasePart") and instance.Name == "Terrain" then return false end
    
    -- Versteckte/ungefährliche Teile ignorieren (optional)
    if instance:IsA("BasePart") and instance.Material == Enum.Material.Water then return false end

    if CONFIG.Mode == "ALL" then
        return true
    end
    
    if CONFIG.Mode == "WHITELIST" then
        local lowerName = string.lower(instance.Name)
        for _, target in ipairs(CONFIG.TargetNames) do
            if string.find(lowerName, string.lower(target)) then
                return true
            end
        end
        return false
    end
    
    if CONFIG.Mode == "ATTRIBUTE" then
        return instance:GetAttribute(CONFIG.TargetAttribute) ~= nil
    end
    
    return false
end

-- Holt den anzuzeigenden Text für ein Objekt
local function GetDisplayText(instance)
    if CONFIG.Mode == "ATTRIBUTE" then
        local attr = instance:GetAttribute(CONFIG.TargetAttribute)
        if attr then return tostring(attr) end
    end
    return instance.Name  -- Fallback: Der Name des Parts
end

-- Findet einen "Adornee"-Part für das Billboard (braucht einen konkreten Part)
local function GetAdornee(instance)
    if instance:IsA("BasePart") then
        return instance
    elseif instance:IsA("Model") then
        -- Versuche zuerst den PrimaryPart, sonst nimm den ersten Part
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

-- ===== ESP ERSTELLEN & ENTFERNEN =====

local function CreateESP(instance)
    if ESPedObjects[instance] then return end  -- Schon vorhanden
    local adornee = GetAdornee(instance)
    if not adornee then return end

    -- 1. HIGHLIGHT (Glow um das ganze Modell / Part)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Part_Highlight"
    highlight.Adornee = instance  -- Kann ein Part oder Model sein
    highlight.FillColor = CONFIG.HighlightColor
    highlight.OutlineColor = CONFIG.OutlineColor
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = instance

    -- 2. BILLBOARD (Text über dem Objekt)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Part_Billboard"
    billboard.Adornee = adornee
    billboard.Size = UDim2.new(0, 250, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)  -- Höhe über dem Objekt
    billboard.AlwaysOnTop = true
    billboard.Parent = instance

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ESP_Part_Text"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = CONFIG.TextColor
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)  -- Schwarze Kontur
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextScaled = false
    textLabel.TextSize = CONFIG.TextSize
    textLabel.Text = "Lade..."
    textLabel.Parent = billboard

    -- Objekt in der Tabelle speichern
    ESPedObjects[instance] = {
        Highlight = highlight,
        Billboard = billboard,
        TextLabel = textLabel,
        Adornee = adornee,
        DisplayName = GetDisplayText(instance)
    }

    -- 3. UPDATE-SCHLEIFE für Distanz und Text
    task.spawn(function()
        local data = ESPedObjects[instance]
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
            
            task.wait(CONFIG.UpdateInterval)
        end
    end)
end

local function RemoveESP(instance)
    local data = ESPedObjects[instance]
    if data then
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
        ESPedObjects[instance] = nil
    end
end

-- ===== WELT-SCANNER (Findet Objekte) =====

-- Durchsucht das gesamte Workspace nach neuen Zielen
local function ScanForTargets()
    for _, instance in ipairs(Workspace:GetDescendants()) do
        if IsTarget(instance) and not ESPedObjects[instance] then
            CreateESP(instance)
        end
    end
end

-- ===== NEUE OBJEKTE ÜBERWACHEN =====

-- Wenn neue Teile in die Welt eingefügt werden
Workspace.DescendantAdded:Connect(function(instance)
    task.wait(0.1)  -- Kurze Verzögerung, damit das Teil vollständig geladen ist
    if IsTarget(instance) and not ESPedObjects[instance] then
        CreateESP(instance)
    end
end)

-- Wenn Teile gelöscht werden
Workspace.DescendantRemoving:Connect(function(instance)
    if ESPedObjects[instance] then
        RemoveESP(instance)
    end
end)

-- ===== START =====

print("🔍 Scanne nach Parts mit Text-ESP...")
ScanForTargets()
print("✅ Part-ESP erfolgreich geladen!")
print("📦 Es werden Objekte mit Namen wie 'Chest', 'Door', 'Loot' etc. hervorgehoben.")
print("⚙️  Passe die 'TargetNames'-Liste in der Config an, um eigene Objekte zu targetieren.")
