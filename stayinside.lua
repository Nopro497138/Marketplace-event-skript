--[[ 
====================================================================
  SUPERMARKET AUTOFARM SKRIPT (Version 2.0 - Fixed Offset & Camera)
====================================================================
  ABLAUF DER AUTOFARM-SCHLEIFE:
  1. Teleport zu Position 1 (-382, 10, -408)
  2. Wartezeit von genau 2 Sekunden
  3. Scanne 'workspace.SuperMarket.Plots.Models' nach nicht verarbeiteten Modellen
  4. Falls Modell gefunden:
     a) Berechne Relativ-Position (Objektpos - Vector3(1, 3, 7)) -> Standposition
     b) Teleportiere Spieler-Charakter (HumanoidRootPart) dorthin
     c) Setze Kamera-Typ auf Scriptable und richte Fokus direkt auf das Zielobjekt
     d) Halte Taste 'Z' (englisches Layout = deutsches Y) für 0.7s gedrückt
     e) Markiere Modell in 'processedModels', damit es ignoriert wird, solange es existiert
  5. Teleport zu Position 2 (-427, 202, 54)
  6. Setze Kamera-Typ zurück auf 'Custom'
  7. Drücke Taste 'Z' einmal kurz (0.1s)
  8. Warte 1 Sekunde vor dem nächsten Durchlauf
====================================================================
--]]

-- Rayfield UI Library laden
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "SuperMarket AutoFarm",
   LoadingTitle = "Skript wird geladen...",
   LoadingSubtitle = "Delta Executor",
   ConfigurationSaving = {
      Enabled = false,
   },
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

                   -- 1. Erstes TP & 2 Sekunden warten
                   hrp.CFrame = CFrame.new(-382, 10, -408)
                   task.wait(2)

                   -- 2. Modell suchen
                   local model, targetPart = getTargetModel()
                   if model and targetPart then
                       local objPos = targetPart.Position
                       
                       -- Exakte Versatz-Berechnung entsprechend deines Beispiels:
                       -- Objekt: (-430, 205, 64) -> Ziel: (-431, 202, 57)
                       -- Offset = Vector3(-1, -3, -7)
                       local standPos = objPos + Vector3.new(-1, -3, -7)

                       -- Charakter teleportieren und zum Objekt ausrichten
                       hrp.CFrame = CFrame.lookAt(standPos, objPos)

                       -- Kamera erzwingen und direkt auf das Objekt richten
                       Camera.CameraType = Enum.CameraType.Scriptable
                       Camera.CFrame = CFrame.lookAt(standPos + Vector3.new(0, 2, 0), objPos)
                       task.wait(0.3)

                       -- 3. Z (deutsches Y) gedrückt halten (0.7s)
                       Vim:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
                       task.wait(0.7)
                       Vim:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                       task.wait(0.3)

                       -- Modell als verarbeitet markieren
                       processedModels[model] = true

                       -- Kamera wieder auf Normalmodus zurückstellen
                       Camera.CameraType = Enum.CameraType.Custom

                       -- 4. Zweiter Teleportation-Punkt
                       hrp.CFrame = CFrame.new(-427, 202, 54)
                       task.wait(0.5)

                       -- 5. Z kurz antippen
                       Vim:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
                       task.wait(0.1)
                       Vim:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                       task.wait(1)
                   else
                       -- Falls kein unbearbeitetes Modell da ist
                       Camera.CameraType = Enum.CameraType.Custom
                       task.wait(1)
                   end
               end
               -- Bei Deaktivierung Kamera zurücksetzen
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
