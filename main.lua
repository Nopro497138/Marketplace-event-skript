-- Rayfield UI laden
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "ItemSpawner Farmer",
   LoadingTitle = "Lade Skript...",
   LoadingSubtitle = "by AI",
   ConfigurationSaving = {
      Enabled = false,
   },
   KeySystem = false,
})

local Tab = Window:CreateTab("AutoFarm", 4483362458)

local farmingActive = false
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Koordinaten als Konstanten definiert
local POS_1 = Vector3.new(25, 13, 6136)
local POS_2 = Vector3.new(37, 9, 10002)

-- Aktualisiere Character-Referenzen, falls der Spieler stirbt
player.CharacterAdded:Connect(function(newChar)
   character = newChar
   humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
   print("[Log] Character neu geladen.")
end)

-- Funktion, die nur nach Modellen sucht und diese abfarmt
local function searchAndFarmAtPosition(pos)
   if not farmingActive or not humanoidRootPart then return false end
   
   -- 1. Zu den Start-Koordinaten teleportieren
   humanoidRootPart.CFrame = CFrame.new(pos)
   task.wait(2.0) -- Erhöhter Cooldown nach dem Teleport zur Koordinate
   
   local itemSpawners = workspace:FindFirstChild("ItemSpawners")
   if not itemSpawners then
      print("[Log] Fehler: workspace.ItemSpawners nicht gefunden!")
      return false
   end
   
   local foundAny = false
   
   -- Durchsuchung des gesamten Ordners nach Modellen
   for _, obj in ipairs(itemSpawners:GetDescendants()) do
      if not farmingActive then break end
      
      -- WICHTIG: Wir prüfen jetzt NUR noch nach Modellen, deren Name "Cosmic" oder "God" ist 
      -- (oder deren Elternteil so heißt, falls das Modell selbst so benannt ist)
      local isTargetModel = false
      
      if obj:IsA("Model") then
         if obj.Name == "Cosmic" or obj.Name == "God" then
            isTargetModel = true
         elseif obj.Parent and (obj.Parent.Name == "Cosmic" or obj.Parent.Name == "God") then
            isTargetModel = true
         end
      end
      
      if isTargetModel then
         foundAny = true
         print("[Log] Ziel-Modell entdeckt: " .. tostring(obj.Name))
         
         -- Exakte Bestimmung des Parts NUR im Modell
         local targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
         
         if targetPart then
            -- Zum Modell teleportieren
            humanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
            task.wait(1.2) -- Erhöhter Cooldown vor dem Auslösen des Prompts
            
            -- ProximityPrompt im Modell suchen und auslösen
            local promptFound = false
            for _, descendant in ipairs(obj:GetDescendants()) do
               if descendant:IsA("ProximityPrompt") then
                  promptFound = true
                  pcall(function()
                     fireproximityprompt(descendant)
                     print("[Log] ProximityPrompt ausgelöst für Modell: " .. tostring(obj.Name))
                  end)
               end
            end
            
            if not promptFound then
               print("[Log] Kein ProximityPrompt in diesem Modell gefunden.")
            end
            
            task.wait(1.2) -- Erhöhter Cooldown nach dem Auslösen
            
            -- Zurück zur alten Koordinate
            humanoidRootPart.CFrame = CFrame.new(pos)
            print("[Log] Zurück zur Koordinate, warte 2.5 Sekunden...")
            task.wait(2.5) -- Erhöhte Pause an der alten Koordinate wie gewünscht
         else
            print("[Log] Modell hat kein gültiges BasePart/PrimaryPart: " .. tostring(obj.Name))
         end
      end
   end
   
   return foundAny
end

-- Die Hauptschleife mit deutlich mehr Cooldown
task.spawn(function()
   while true do
      if farmingActive and humanoidRootPart then
         
         -- SCHRITT 1: Koordinate 1
         print("[Log] Gehe zu Koordinate 1: (25, 13, 6136)")
         searchAndFarmAtPosition(POS_1)
         
         if not farmingActive then break end
         task.wait(1.5) -- Cooldown zwischen den Positionen
         
         -- SCHRITT 2: Koordinate 2
         print("[Log] Gehe zu Koordinate 2: (37, 9, 10002)")
         searchAndFarmAtPosition(POS_2)
         
         if not farmingActive then break end
         task.wait(1.5) -- Cooldown vor dem Wiederholen der Schleife
         
      end
      task.wait(1.5)
   end
end)

-- Toggle in Rayfield erstellen
Tab:CreateToggle({
   Name = "Auto Farm Routen-Modus (Langsam & Sicher)",
   CurrentValue = false,
   Flag = "AutoFarmToggle",
   Callback = function(Value)
      farmingActive = Value
      print("[Log] Auto Farm Status geändert zu: " .. tostring(Value))
   end,
})
