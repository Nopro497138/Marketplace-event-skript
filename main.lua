print("========================================")
print("📦 Marketplace Event Logger (für Executor)")
print("========================================")

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer

if not player then
    print("⏳ Warte auf LocalPlayer...")
    repeat wait() until Players.LocalPlayer
    player = Players.LocalPlayer
end
print("👤 Spieler: " .. player.Name)

-- ========== GUI IN COREGUI ERSTELLEN ==========
local function createGUI()
    print("🛠️ Erstelle GUI in CoreGui...")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MarketplaceLogger"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("CoreGui")  -- CoreGui ist sicher

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    title.BackgroundTransparency = 0
    title.BorderSizePixel = 0
    title.Text = "📦 Marketplace Event Log"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    local logContainer = Instance.new("ScrollingFrame")
    logContainer.Name = "LogContainer"
    logContainer.Size = UDim2.new(1, -20, 1, -100)
    logContainer.Position = UDim2.new(0, 10, 0, 50)
    logContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    logContainer.BackgroundTransparency = 0.5
    logContainer.BorderSizePixel = 0
    logContainer.ScrollBarThickness = 6
    logContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    logContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logContainer.Parent = mainFrame

    local clearButton = Instance.new("TextButton")
    clearButton.Size = UDim2.new(0, 120, 0, 35)
    clearButton.Position = UDim2.new(0, 10, 1, -45)
    clearButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    clearButton.BorderSizePixel = 0
    clearButton.Text = "🗑️ Clear Logs"
    clearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearButton.TextSize = 14
    clearButton.Font = Enum.Font.Gotham
    clearButton.Parent = mainFrame

    local executeButton = Instance.new("TextButton")
    executeButton.Size = UDim2.new(0, 120, 0, 35)
    executeButton.Position = UDim2.new(1, -130, 1, -45)
    executeButton.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
    executeButton.BorderSizePixel = 0
    executeButton.Text = "▶️ Execute Selected"
    executeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    executeButton.TextSize = 14
    executeButton.Font = Enum.Font.Gotham
    executeButton.Parent = mainFrame

    print("✅ GUI erfolgreich erstellt (CoreGui).")
    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        LogContainer = logContainer,
        ClearButton = clearButton,
        ExecuteButton = executeButton
    }
end

-- GUI erstellen
local gui = createGUI()
if not gui then
    warn("❌ GUI konnte nicht erstellt werden – Skript wird beendet.")
    return
end

local logContainer = gui.LogContainer
local logs = {}
local selectedIndex = nil

-- ========== HILFSFUNKTIONEN ==========
local function getTimestamp()
    return os.date("%H:%M:%S")
end

local function addLogToGUI(logEntry, index)
    local label = Instance.new("TextButton")
    label.Name = "LogEntry_" .. index
    label.Size = UDim2.new(1, -10, 0, 30)
    label.Position = UDim2.new(0, 5, 0, (index - 1) * 32)
    label.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    label.BackgroundTransparency = 0.2
    label.BorderSizePixel = 0
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.AutoButtonColor = false

    local productId = logEntry.data and logEntry.data.productId or "?"
    local status = logEntry.executed and "✅" or "⏳"
    label.Text = string.format("[%s] %s | Produkt: %s %s",
        logEntry.timestamp,
        logEntry.eventType,
        productId,
        status
    )

    label.MouseButton1Click:Connect(function()
        selectedIndex = index
        for _, child in pairs(logContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
            end
        end
        label.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
        print("[Logger] Ausgewählt: Index " .. index)
    end)

    label.Parent = logContainer
end

local function updateLogStatus(index)
    local label = logContainer:FindFirstChild("LogEntry_" .. index)
    if label and logs[index] then
        local status = logs[index].executed and "✅" or "⏳"
        local productId = logs[index].data and logs[index].data.productId or "?"
        label.Text = string.format("[%s] %s | Produkt: %s %s",
            logs[index].timestamp,
            logs[index].eventType,
            productId,
            status
        )
    end
end

local function addLog(eventType, data)
    local logEntry = {
        timestamp = getTimestamp(),
        eventType = eventType,
        data = data,
        executed = false
    }
    table.insert(logs, logEntry)
    local index = #logs
    addLogToGUI(logEntry, index)
    print("[Logger] Neuer Log: " .. eventType .. " (Index " .. index .. ")")
end

-- ========== MARKETPLACE SERVICE HOOK ==========
print("🔄 Versuche MarketplaceService.ProcessReceipt zu überschreiben...")

local originalProcessReceipt = MarketplaceService.ProcessReceipt

local hookSuccess = pcall(function()
    MarketplaceService.ProcessReceipt = function(receiptInfo)
        print("[Logger] 🔔 Kauf erkannt! ProductId: " .. tostring(receiptInfo.ProductId))
        local logData = {
            productId = receiptInfo.ProductId,
            purchaseId = receiptInfo.PurchaseId,
            placeId = receiptInfo.PlaceId,
            currencyType = receiptInfo.CurrencyType,
            price = receiptInfo.Price,
            assetId = receiptInfo.AssetId
        }
        addLog("Purchase", logData)
        if originalProcessReceipt then
            return originalProcessReceipt(receiptInfo)
        end
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
end)

if hookSuccess then
    print("✅ ProcessReceipt erfolgreich überschrieben.")
else
    print("⚠️ ProcessReceipt konnte nicht überschrieben werden (möglicherweise schreibgeschützt).")
    print("💡 Trotzdem kannst du manuell Logs hinzufügen (z.B. über eigene Skripte).")
end

-- ========== BUTTON-FUNKTIONEN ==========
gui.ClearButton.MouseButton1Click:Connect(function()
    for _, child in pairs(logContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    logs = {}
    selectedIndex = nil
    print("[Logger] Alle Logs gelöscht.")
end)

gui.ExecuteButton.MouseButton1Click:Connect(function()
    if not selectedIndex then
        print("[Logger] Kein Eintrag ausgewählt!")
        return
    end
    local logEntry = logs[selectedIndex]
    if not logEntry then
        print("[Logger] Eintrag nicht gefunden!")
        return
    end
    if logEntry.executed then
        print("[Logger] Dieser Eintrag wurde bereits ausgeführt!")
        return
    end

    local data = logEntry.data
    if logEntry.eventType == "Purchase" then
        print(string.format("[Logger] ▶️ Führe Kauf erneut aus: Produkt %s", data.productId))
        -- Hier kannst du deine eigene Aktion einfügen (z.B. RemoteEvent feuern)
        local notif = Instance.new("TextLabel")
        notif.Size = UDim2.new(0, 300, 0, 40)
        notif.Position = UDim2.new(0.5, -150, 0.8, 0)
        notif.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        notif.BackgroundTransparency = 0.3
        notif.Text = "✅ Kauf erneut ausgeführt! (Produkt " .. data.productId .. ")"
        notif.TextColor3 = Color3.fromRGB(255, 255, 255)
        notif.TextSize = 16
        notif.Font = Enum.Font.GothamBold
        notif.Parent = gui.ScreenGui
        game:GetService("Debris"):AddItem(notif, 3)
    end

    logEntry.executed = true
    updateLogStatus(selectedIndex)
    print("[Logger] Event ausgeführt (Index " .. selectedIndex .. ")")
end)

-- ========== TEST-EINTRAG HINZUFÜGEN ==========
wait(0.5)
addLog("Purchase", { productId = 123456, price = 100 })
addLog("Purchase", { productId = 789012, price = 200 }) -- zweiter Test

print("✅ Skript vollständig geladen. GUI sollte sichtbar sein!")
print("📌 Test-Logs wurden hinzugefügt. Kaufe etwas im Spiel, um echte Logs zu sehen.")
print("========================================")
