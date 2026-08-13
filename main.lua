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
end)

-- Die Hauptschleife für den schnellen Ablauf
task.spawn(function()
   while true do
      if farmingActive then
         local itemSpawners = workspace:FindFirstChild("ItemSpawners")
         if itemSpawners then
            for _, parentObj in ipairs(itemSpawners:GetChildren()) do
               if not farmingActive then break end
               
               -- Prüfen ob der Parent (Ordner/Modell) "Cosmic" oder "God" heißt
               if parentObj.Name == "Cosmic" or parentObj.Name == "God" then
                  -- Durchsuche alle Modelle innerhalb dieses Parents
                  for _, model in ipairs(parentObj:GetChildren()) do
                     if not farmingActive then break end
                     
                     if model:IsA("Model") then
                        local targetPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                        
                        if targetPart and humanoidRootPart then
                           -- 1. Zum Modell im Parent teleportieren
                           humanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                           
                           -- 2. Überall im Modell nach ProximityPrompts suchen und sofort auslösen
                           for _, descendant in ipairs(model:GetDescendants()) do
                              if descendant:IsA("ProximityPrompt") then
                                 pcall(function()
                                    fireproximityprompt(descendant)
                                 end)
                              end
                           end
                           
                           -- 3. Zu den Zielkoordinaten teleportieren
                           humanoidRootPart.CFrame = CFrame.new(-170, 4, -116)
                           
                           -- Extrem kurzes Yield für maximale Geschwindigkeit
                           task.wait()
                        end
                     end
                  end
               end
            end
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
   end,
})
