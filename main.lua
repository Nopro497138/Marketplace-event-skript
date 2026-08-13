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

-- Funktion, die den gesamten Ordner nach "Cosmic" oder "God" durchsucht (inkl. TextObjekte, Properties etc.)
local function searchAndFarmAtPosition(pos)
   if not farmingActive or not humanoidRootPart then return false end
   
   -- 1. Zu den Koordinaten teleportieren
   humanoidRootPart.CFrame = CFrame.new(pos)
   task.wait(0.4) -- Etwas langsamer gemacht, damit der Server/Client die Objekte laden kann
   
   local itemSpawners = workspace:FindFirstChild("ItemSpawners")
   if not itemSpawners then
      print("[Log] Fehler: workspace.ItemSpawners nicht gefunden!")
      return false
   end
   
   local foundAny = false
   
   -- Rekursive Durchsuchung des gesamten Ordners nach Namen oder Text-Properties
   for _, obj in ipairs(itemSpawners:GetDescendants()) do
      if not farmingActive then break end
      
      local matchFound = false
      
      -- Prüfen, ob der Name "Cosmic" oder "God" ist
      if obj.Name == "Cosmic" or obj.Name == "God" then
         matchFound = true
      -- Alternativ prüfen, ob es ein Text-Objekt ist (z.B. TextLabel / Textbox) und der Text passt
      elseif (obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton")) and (obj.Text == "Cosmic" or obj.Text == "God") then
         matchFound = true
      end
      
      if matchFound then
         foundAny = true
         print("[Log] Gefundenes Ziel entdeckt: " .. obj.Name .. " (" .. obj.ClassName .. ")")
         
         -- Ziel-Part ermitteln (entweder das Objekt selbst, wenn es ein BasePart/Model ist, oder das Parent)
         local targetPart = nil
         if obj:IsA("BasePart") then
            targetPart = obj
         elseif obj:IsA("Model") then
            targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
         elseif obj.Parent and obj.Parent:IsA("Model") then
            targetPart = obj.Parent.PrimaryPart or obj.Parent:FindFirstChildWhichIsA("BasePart")
         elseif obj.Parent and obj.Parent:IsA("BasePart") then
            targetPart = obj.Parent
         end
         
         if targetPart then
            -- Zum Ziel teleportieren
            humanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.2) -- Kurzer Stopp zum Laden
            
            -- ProximityPrompt im selben Objekt oder dessen Elternteil suchen und auslösen
            local function checkAndFirePrompts(container)
               for _, descendant in ipairs(container:GetDescendants()) do
                  if descendant:IsA("ProximityPrompt") then
                     pcall(function()
                        fireproximityprompt(descendant)
                        print("[Log] ProximityPrompt erfolgreich ausgelöst!")
                     end)
                  end
               end
            end
            
            checkAndFirePrompts(obj)
            if obj.Parent then
               checkAndFirePrompts(obj.Parent)
            end
            
            -- Nach dem Einsammeln kurz warten und zurück zur Startposition
            task.wait(0.2)
            humanoidRootPart.CFrame = CFrame.new(pos)
            task.wait(0.2)
         end
      end
   end
   
   return foundAny
end

-- Die Hauptschleife steuert den genauen Ablauf
task.spawn(function()
   while true do
      if farmingActive and humanoidRootPart then
         
         -- SCHRITT 1: Zu Koordinate 1 teleportieren und dort suchen
         print("[Log] Gehe zu Koordinate 1: (25, 13, 6136)")
         searchAndFarmAtPosition(POS_1)
         
         if not farmingActive then break end
         task.wait(0.5)
         
         -- SCHRITT 2: Zu Koordinate 2 teleportieren und dort suchen
         print("[Log] Gehe zu Koordinate 2: (37, 9, 10002)")
         searchAndFarmAtPosition(POS_2)
         
      end
      task.wait(0.5)
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
