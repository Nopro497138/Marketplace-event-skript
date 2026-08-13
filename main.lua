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

-- Ziel- und Zwischenkoordinaten
local POS_1 = Vector3.new(25, 13, 6136)
local POS_2 = Vector3.new(37, 9, 10002)
local HOME_POS = Vector3.new(-170, 4, -116) -- Die Rückkehr-Koordinate nach dem Aufnehmen

-- Character-Referenzen erneuern, falls der Spieler stirbt
player.CharacterAdded:Connect(function(newChar)
   character = newChar
   humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
   print("[Log] Character neu geladen.")
end)

-- Funktion für das Suchen, Einsammeln und den Teleport zu HOME_POS
local function searchAndFarmAtPosition(pos)
   if not farmingActive or not humanoidRootPart then return false end
   
   -- 1. Zur Checkpoint-Koordinate teleportieren
   humanoidRootPart.CFrame = CFrame.new(pos)
   task.wait(1.5) -- Warten, damit der Client die Umgebung an dieser Position laden kann
   
   local itemSpawners = workspace:FindFirstChild("ItemSpawners")
   if not itemSpawners then
      print("[Log] Fehler: workspace.ItemSpawners nicht gefunden!")
      return false
   end
   
   local foundAny = false
   
   -- Durchsuche den Ordner explizit nach Modellen unter Cosmic/God
   for _, obj in ipairs(itemSpawners:GetDescendants()) do
      if not farmingActive then break end
      
      local isTargetModel = false
      
      -- Es MUSS ein Modell sein und der Name oder der des Parents ist "Cosmic" oder "God"
      if obj:IsA("Model") then
         if obj.Name == "Cosmic" or obj.Name == "God" then
            isTargetModel = true
         elseif obj.Parent and (obj.Parent.Name == "Cosmic" or obj.Parent.Name == "God") then
            isTargetModel = true
         end
      end
      
      if isTargetModel then
         foundAny = true
         print("[Log] Ziel-Modell gefunden: " .. tostring(obj.Name))
         
         -- Exaktes Part im Modell holen
         local targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
         
         if targetPart then
            -- A) Zum Modell teleportieren
            humanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.8)
            
            -- B) ProximityPrompt suchen und auslösen
            for _, descendant in ipairs(obj:GetDescendants()) do
               if descendant:IsA("ProximityPrompt") then
                  pcall(function()
                     fireproximityprompt(descendant)
                     print("[Log] ProximityPrompt ausgelöst!")
                  end)
               end
            end
            
            task.wait(0.8)
            
            -- C) Teleport zu -170, 4, -116
            print("[Log] Teleportiere zur Ziel-Koordinate (-170, 4, -116)...")
            humanoidRootPart.CFrame = CFrame.new(HOME_POS)
            
            -- D) 1 Sekunde Pause an der Ziel-Koordinate
            task.wait(1.0)
         else
            print("[Log] Modell hat kein gültiges BasePart: " .. tostring(obj.Name))
         end
      end
   end
   
   return foundAny
end

-- Hauptschleife
task.spawn(function()
   while true do
      if farmingActive and humanoidRootPart then
         
         -- SCHRITT 1: Erste Koordinate (25, 13, 6136)
         print("[Log] Anfahrt Koordinate 1: (25, 13, 6136)")
         searchAndFarmAtPosition(POS_1)
         
         if not farmingActive then break end
         task.wait(1.0)
         
         -- SCHRITT 2: Zweite Koordinate (37, 9, 10002)
         print("[Log] Anfahrt Koordinate 2: (37, 9, 10002)")
         searchAndFarmAtPosition(POS_2)
         
         if not farmingActive then break end
         task.wait(1.0)
         
      end
      task.wait(1.0)
   end
end)

-- Toggle in Rayfield UI
Tab:CreateToggle({
   Name = "Auto Farm (Inkl. Home Teleport)",
   CurrentValue = false,
   Flag = "AutoFarmToggle",
   Callback = function(Value)
      farmingActive = Value
      print("[Log] Auto Farm Status geändert zu: " .. tostring(Value))
   end,
})
