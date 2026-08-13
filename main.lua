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

-- Aktualisiere Character-Referenzen falls der Spieler stirbt
player.CharacterAdded:Connect(function(newChar)
   character = newChar
   humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
   print("[Log] Character neu geladen.")
end)

-- Die Hauptschleife für den schnellen Ablauf
task.spawn(function()
   while true do
      if farmingActive then
         local itemSpawners = workspace:FindFirstChild("ItemSpawners")
         if itemSpawners then
            local foundAny = false
            for _, parentObj in ipairs(itemSpawners:GetChildren()) do
               if not farmingActive then break end
               
               -- Prüfen ob der Parent (Ordner/Modell) "Cosmic" oder "God" heißt
               if parentObj.Name == "Cosmic" or parentObj.Name == "God" then
                  foundAny = true
                  -- Durchsuche alle Modelle innerhalb dieses Parents
                  for _, model in ipairs(parentObj:GetChildren()) do
                     if not farmingActive then break end
                     
                     if model:IsA("Model") then
                        local targetPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                        
                        if targetPart and humanoidRootPart then
                           print("[Log] Teleportiere zu Modell in Parent: " .. parentObj.Name)
                           -- 1. Zum Modell im Parent teleportieren
                           humanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                           
                           -- 2. Überall im Modell nach ProximityPrompts suchen und sofort auslösen
                           local promptFound = false
                           for _, descendant in ipairs(model:GetDescendants()) do
                              if descendant:IsA("ProximityPrompt") then
                                 promptFound = true
                                 pcall(function()
                                    fireproximityprompt(descendant)
                                    print("[Log] ProximityPrompt ausgelöst!")
                                 end)
                              end
                           end
                           
                           if not promptFound then
                              print("[Log] Kein ProximityPrompt in diesem Modell gefunden.")
                           end
                           
                           -- 3. Zu den Zielkoordinaten teleportieren
                           print("[Log] Teleportiere zu Zielkoordinaten (-170, 4, -116)")
                           humanoidRootPart.CFrame = CFrame.new(-170, 4, -116)
                           
                           task.wait()
                        else
                           print("[Log] Modell hat kein gültiges BasePart/PrimaryPart: " .. model.Name)
                        end
                     end
                  end
               end
            end
            if not foundAny then
               -- Gibt alle 2 Sekunden eine Info aus, falls keine passenden Parents gefunden werden
               print("[Log] Wache: Keine 'Cosmic' oder 'God' Ordner in workspace.ItemSpawners gefunden.")
               task.wait(2)
            end
         else
            print("[Log] Fehler: workspace.ItemSpawners nicht gefunden!")
            task.wait(2)
         end
      end
      task.wait(0.05)
   end
end)

-- Toggle in Rayfield erstellen
Tab:CreateToggle({
   Name = "Auto Farm (Cosmic / God)",
   CurrentValue = false,
   Flag = "AutoFarmToggle",
   Callback = function(Value)
      farmingActive = Value
      print("[Log] Auto Farm Status geändert zu: " .. tostring(Value))
   end,
})
