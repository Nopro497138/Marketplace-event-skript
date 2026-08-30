-- Rayfield UI Library laden länger
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Fenster erstellen
local Window = Rayfield:CreateWindow({
   Name = "Auto Farm Hub",
   LoadingTitle = "Lade Skript...",
   LoadingSubtitle = "Delta Executor",
   ConfigurationSaving = {
      Enabled = false,
   },
   KeySystem = false
})

-- Tab erstellen
local Tab = Window:CreateTab("Farming", 4483362458)

-- Globale Variablen
local initialTpDelay = 10 -- 10 Sekunden warten nach dem TP zu den Objekten
local finalTpDelay = 2    -- 2 Sekunden warten nach dem TP zurück
local finalTP = Vector3.new(301, 14595, -2707)
_G.AutoFarm = false

-- Funktion zum Teleportieren
local function teleport(pos)
    local player = game.Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

-- Hauptfunktion für einen "Farming-Schritt"
local function processPhase(startPos, itemName)
    -- 1. Zum Startpunkt TP'en
    teleport(startPos)
    task.wait(initialTpDelay) -- Hier sind jetzt die 10 Sekunden Delay

    -- Prüfen, ob der Pfad existiert
    local spawners = workspace:FindFirstChild("DropperParts")
    if spawners then
        spawners = spawners:FindFirstChild("ItemSpawners")
    end

    if not spawners then return end

    local targetItem = spawners:FindFirstChild(itemName)
    local modelFound = false

    if targetItem then
        -- 2. Nach einem Modell im Objekt suchen
        for _, child in ipairs(targetItem:GetChildren()) do
            if child:IsA("Model") then
                -- Zum Modell TP'en (nimmt das erste BasePart des Modells)
                local partToTP = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart", true)
                if partToTP then
                    teleport(partToTP.Position)
                    task.wait(0.5) -- Kurzer Delay, damit das Spiel den TP registriert und den Prompt lädt

                    -- 3. Nach dem ProximityPrompt suchen und für 0.6 Sekunden halten
                    local prompt = child:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        fireproximityprompt(prompt) -- Delta Executor löst das direkt aus
                        task.wait(0.6) -- Die gewünschten 0.6 Sekunden abwarten
                    end
                    
                    modelFound = true
                    break -- Sobald ein Modell gefunden und gelootet wurde, Schleife abbrechen
                end
            end
        end
    end

    -- 4. Wenn ein Modell gefunden wurde -> Zum finalen Zielpunkt TP'en
    if modelFound then
        teleport(finalTP)
        task.wait(finalTpDelay) -- Hier bleibt es bei 2 Sekunden Delay
    end
    -- Wenn kein Modell gefunden wurde, springt das Skript direkt zum nächsten Ziel
end

-- Toggle in der UI erstellen
Tab:CreateToggle({
   Name = "Start Auto Farm",
   CurrentValue = false,
   Flag = "AutoFarmToggle",
   Callback = function(Value)
        _G.AutoFarm = Value
        
        if _G.AutoFarm then
            task.spawn(function()
                while _G.AutoFarm do
                    -- Phase 1: Abyssal
                    if not _G.AutoFarm then break end
                    processPhase(Vector3.new(-159, -1897, -2364), "Abyssal")
                    
                    -- Phase 2: Transcendent
                    if not _G.AutoFarm then break end
                    processPhase(Vector3.new(-229, -6920, -2460), "Transcendent")
                    
                    -- Phase 3: Supreme
                    if not _G.AutoFarm then break end
                    processPhase(Vector3.new(-224, -11012, -2463), "Supreme")
                end
            end)
        end
   end,
})
