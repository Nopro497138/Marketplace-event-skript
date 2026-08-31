--[[ 
====================================================================
  SUPERMARKET AUTOFARM SKRIPT (Version 3.0 - Maximum Robustness)
====================================================================
  ÄNDERUNGEN:
  - Viel längere Cooldowns nach Teleports (Server-Sync)
  - Anti-Slide (Velocity = 0) hinzugefügt, damit man am Ort stehen bleibt
  - Taste wird nun 1.2 Sekunden gehalten (sicherer als genau 1.0s)
  - Automatisches Scannen nach ProximityPrompts für 100% Hit-Rate
====================================================================
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "SuperMarket AutoFarm",
   LoadingTitle = "Skript wird geladen...",
   LoadingSubtitle = "Delta Executor",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local MainTab = Window:CreateTab("Auto Farm", 4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Vim = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera

_G.AutoFarm = false
_G.InfHealth = false
_G.WalkSpeed = 16

local processedModels = {}

-- Hilfsfunktion: Findet das erste ungesammelte Modell
local function getTargetModel()
    local modelsFolder = workspace:FindFirstChild("SuperMarket")
    if modelsFolder and modelsFolder:FindFirstChild("Plots") and modelsFolder.Plots:FindFirstChild("Models") then
        for _, plot in ipairs(modelsFolder.Plots.Models:GetChildren()) do
            for _, item in ipairs(plot:GetChildren()) do
                if item:IsA("Model") and not processedModels[item] and item:IsDescendantOf(workspace) then
                    local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)
                    if part then 
                        return item, part 
                    end
                end
            end
        end
    end
    return nil, nil
end

-- Hilfsfunktion: Versucht ein ProximityPrompt direkt zu triggern (extrem zuverlässig)
local function tryFirePrompt(instance)
    local prompt = instance:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        fireproximityprompt(prompt)
        return true
    end
    return false
end

MainTab:CreateToggle({
   Name = "Start Auto Farm",
   CurrentValue = false,
   Flag = "AutoFarmToggle",
   Callback = function(Value)
       _G.AutoFarm = Value
       
       if Value then
           task.spawn(function()
               while _G.AutoFarm do
                   local char = LocalPlayer.Character
                   if not char or not char:FindFirstChild("HumanoidRootPart") then 
                       task.wait(1) 
                       continue 
                   end
                   
                   local hrp = char.HumanoidRootPart

                   -- 1. Erstes TP & robuster Cooldown
                   hrp.CFrame = CFrame.new(-382, 10, -408)
                   hrp.Velocity = Vector3.new(0, 0, 0) -- Stoppt herumrutschen
                   task.wait(2.5) -- Erhöht von 2 auf 2.5 Sekunden

                   -- 2. Modell suchen
                   local model, targetPart = getTargetModel()
                   if model and targetPart and model.Parent then
                       local objPos = targetPart.Position
                       
                       -- Offset berechnen
                       local standPos = objPos + Vector3.new(-1, -3, -7)

                       -- Charakter teleportieren und fixieren
                       hrp.CFrame = CFrame.lookAt(standPos, objPos)
                       hrp.Velocity = Vector3.new(0, 0, 0)

                       -- Kamera exakt über dem Kopf platzieren und auf Objekt richten
                       Camera.CameraType = Enum.CameraType.Scriptable
                       Camera.CFrame = CFrame.lookAt(standPos + Vector3.new(0, 1.5, 0), objPos)
                       
                       -- WICHTIG: 1.5 Sekunden warten, damit der Server registriert, dass du da bist
                       -- und das Spiel Zeit hat, das "Y"-UI einzublenden!
                       task.wait(1.5) 

                       -- 3. Interaktion (Pickup)
                       -- Wir versuchen zuerst den 100% sicheren Weg über ProximityPrompts
                       local promptFired = tryFirePrompt(model)
                       
                       if not promptFired then
                           -- Fallback: Z (deutsches Y) gedrückt halten für 1.2 Sekunden
                           Vim:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
                           task.wait(1.2) -- Erhöht auf 1.2s für garantierte 1 Sekunde Haltezeit
                           Vim:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                       else
                           task.wait(1.2) -- Wenn Prompt gefired wurde, trotzdem die Zeit abwarten
                       end
                       
                       task.wait(0.5) -- Kurze Pause nach dem Aufheben

                       -- Modell als verarbeitet markieren
                       processedModels[model] = true

                       -- 4. Zweiter Teleportation-Punkt (Abgeben)
                       Camera.CameraType = Enum.CameraType.Custom
                       hrp.CFrame = CFrame.new(-427, 202, 54)
                       hrp.Velocity = Vector3.new(0, 0, 0)
                       
                       -- Warten, bis der Server den Standortwechsel checkt
                       task.wait(1.5) 

                       -- 5. Z kurz antippen (Abgeben)
                       Vim:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
                       task.wait(0.2) -- Etwas längerer "Klick" (0.2s statt 0.1s)
                       Vim:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                       
                       -- Cooldown vor dem nächsten Zyklus
                       task.wait(2)
                   else
                       -- Falls kein Modell gefunden wurde
                       Camera.CameraType = Enum.CameraType.Custom
                       task.wait(2)
                   end
               end
               -- Bei Deaktivierung Kamera sofort zurücksetzen
               Camera.CameraType = Enum.CameraType.Custom
           end)
       else
           Camera.CameraType = Enum.CameraType.Custom
       end
   end
})

MainTab:CreateButton({
   Name = "Ignorierte Objekte zurücksetzen",
   Callback = function()
       processedModels = {}
       Rayfield:Notify({
          Title = "Zurückgesetzt",
          Content = "Alle Objekte werden wieder angefahren.",
          Duration = 3,
       })
   end,
})

PlayerTab:CreateToggle({
   Name = "Infinite Health",
   CurrentValue = false,
   Flag = "InfHealthToggle",
   Callback = function(Value)
       _G.InfHealth = Value
       if Value then
           task.spawn(function()
               while _G.InfHealth do
                   local char = LocalPlayer.Character
                   if char and char:FindFirstChild("Humanoid") then
                       char.Humanoid.Health = char.Humanoid.MaxHealth
                   end
                   task.wait(0.1)
               end
           end)
       end
   end
})

PlayerTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "WalkSpeedSlider",
   Callback = function(Value)
       _G.WalkSpeed = Value
       local char = LocalPlayer.Character
       if char and char:FindFirstChild("Humanoid") then
           char.Humanoid.WalkSpeed = Value
       end
   end
})

-- Walkspeed Enforcement Loop
task.spawn(function()
    while task.wait(0.5) do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.WalkSpeed ~= _G.WalkSpeed then
            if _G.WalkSpeed > 16 then
                char.Humanoid.WalkSpeed = _G.WalkSpeed
            end
        end
    end
end)
