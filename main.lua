-- Rayfield sicher laden mit Fehlerbehandlung
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Rayfield konnte nicht geladen werden! Überprüfe deine Internetverbindung oder den Executor.")
    return
end

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Speicherung für geloggte Käufe/Prompts
local purchaseLogs = {}

-- Rayfield Fenster erstellen
local Window = Rayfield:CreateWindow({
   Name = "Delta Purchase Logger",
   LoadingTitle = "Client Überwachung",
   LoadingSubtitle = "by Assistant",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

local LogTab = Window:CreateTab("Logs", 4483362458)
local LogSection = LogTab:CreateSection("Kauf-Historie")

-- Paragraph für die Logs
local LogDisplay = LogTab:CreateParagraph({
   Title = "Bisherige Prompts & Käufe",
   Content = "Noch keine Käufe oder Prompts erkannt."
})

-- Funktion zum Aktualisieren der UI-Anzeige
local function updateLogDisplay()
   if #purchaseLogs == 0 then
      LogDisplay:Set({Title = "Bisherige Prompts & Käufe", Content = "Noch keine Käufe oder Prompts erkannt."})
      return
   end
   
   local text = ""
   for i, log in ipairs(purchaseLogs) do
      text = string.format("[%s] Typ: %s | ID: %s | Status: %s\n", log.Time, log.Type, tostring(log.Id), log.Status) .. text
   end
   
   LogDisplay:Set({Title = "Bisherige Prompts & Käufe (" .. #purchaseLogs .. ")", Content = text})
end

-- Funktion zum Hinzufügen eines Logs
local function addLog(pType, pId, status)
   table.insert(purchaseLogs, {
      Type = pType,
      Id = pId,
      Status = status,
      Time = os.date("%H:%M:%S")
   })
   updateLogDisplay()
end

-- Überwachung für Produkt-Käufe
if MarketplaceService.PromptProductPurchaseFinished then
   MarketplaceService.PromptProductPurchaseFinished:Connect(function(player, productId, wasPurchased)
      if player == LocalPlayer then
         addLog("Developer Product", productId, wasPurchased and "Gekauft" or "Abgebrochen")
      end
   end)
end

-- Überwachung für Gamepass-Käufe
if MarketplaceService.PromptGamePassPurchaseFinished then
   MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
      if player == LocalPlayer then
         addLog("GamePass", gamePassId, wasPurchased and "Gekauft" or "Abgebrochen")
      end
   end)
end

-- Control Buttons
LogTab:CreateButton({
   Name = "Logs leeren",
   Callback = function()
      purchaseLogs = {}
      updateLogDisplay()
      Rayfield:Notify({Title = "Gelöscht", Content = "Die Log-Liste wurde geleert.", Duration = 2})
   end,
})

Rayfield:Notify({
   Title = "Delta Logger Aktiv",
   Content = "Überwache Produkt- und Gamepass-Prompts...",
   Duration = 3,
})
