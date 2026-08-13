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

-- Funktion, die an einer bestimmten Position nach "Cosmic" / "God" (bzw. Fallback) sucht und einsammelt
local function searchAndFarmAtPosition(pos)
   if not farmingActive or not humanoidRootPart then return false end
   
   -- 1. Zu den Koordinaten teleportieren
   humanoidRootPart.CFrame = CFrame.new(pos)
   task.wait(0.15) -- Minimaler Yield, damit der Client/Server die Position und geladene Objekte verarbeitet
   
   local itemSpawners = workspace:FindFirstChild("ItemSpawners")
   if not itemSpawners then return false end
   
   local targetParents = {}
   
   -- Suche nach "Cosmic" oder "God"
   for _, child in ipairs(itemSpawners:GetChildren()) do
      if child.Name == "Cosmic" or child.Name == "God" then
         table.insert(targetParents, child)
      end
   end
   
   -- Fallback auf "Legendary" und "Epic", falls nichts da ist
   if #targetParents == 0 then
      for _, child in ipairs(itemSpawners:GetChildren()) do
         if child.Name == "Legendary" or child.Name == "Epic" then
            table.insert(targetParents, child)
         end
      end
   end
   
   if #targetParents > 0 then
      for _, parentObj in ipairs(targetParents) do
         if not farmingActive then break end
         
         for _, model in ipairs(parentObj:GetChildren()) do
            if not farmingActive then break end
            
            if model:IsA("Model") then
               local targetPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
               
               if targetPart then
                  print("[Log] Gefunden (" .. parentObj.Name .. "), hole Item...")
                  
                  -- Zum Modell teleportieren, um den Prompt auszulösen
                  humanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                  
                  -- ProximityPrompt suchen und sofort feuern
                  for _, descendant in ipairs(model:GetDescendants()) do
                     if descendant:IsA("ProximityPrompt") then
                        pcall(function()
                           fireproximityprompt(descendant)
                           print("[Log] ProximityPrompt erfolgreich ausgelöst!")
                        end)
                     end
                  end
                  
                  -- Nach dem Einsammeln sofort zurück zur Ursprungskoordinate (pos)
                  humanoidRootPart.CFrame = CFrame.new(pos)
                  task.wait(0.05)
               end
            end
         end
      end
      return true
   end
   
   return false
end

-- Die Hauptschleife steuert den genauen Ablauf
task.spawn(function()
   while true do
      if farmingActive and humanoidRootPart then
         
         -- SCHRITT 1: Zu Koordinate 1 teleportieren und dort suchen/einsammeln
         print("[Log] Gehe zu Koordinate 1: (25, 13, 6136)")
         searchAndFarmAtPosition(POS_1)
         
         if not farmingActive then break end
         
         -- SCHRITT 2: Zu Koordinate 2 teleportieren und dort suchen/einsammeln
         print("[Log] Gehe zu Koordinate 2: (37, 9, 10002)")
         searchAndFarmAtPosition(POS_2)
         
      end
      task.wait(0.1)
   end
end)

-- Toggle in Rayfield erstellen
Tab:CreateToggle({
   Name = "Auto Farm Routen-Modus",
   CurrentValue = false,
   Flag = "AutoFarmToggle",
   Callback = function(Value)
      farmingActive = Value
      print("[Log] Auto Farm Status geändert zu: " .. tostring(Value))
   end,
})
