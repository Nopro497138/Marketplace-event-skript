-- Rayfield UI Library laden yo
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

-- Tabelle für bereits bearbeitete Modelle
local processedModels = {}

-- Hilfsfunktion: Findet ein Ziel-Modell und dessen Hauptteil
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

                   -- 1. Teleport zum ersten Punkt und 2 Sekunden warten
                   hrp.CFrame = CFrame.new(-382, 10, -408)
                   task.wait(2)

                   -- 2. Ungesammeltes Modell suchen
                   local model, targetPart = getTargetModel()
                   if model and targetPart then
                       -- Charakter positionieren (ausgerichtet auf das Objekt)
                       local targetPos = targetPart.Position
                       local standPos = targetPos + Vector3.new(3, 0, 3)
                       
                       hrp.CFrame = CFrame.lookAt(standPos, targetPos)
                       
                       -- Kamera direkt auf das Objekt ausrichten
                       Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
                       task.wait(0.5)

                       -- 3. Z (deutsches Y) gedrückt halten (0.7s)
                       Vim:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
                       task.wait(0.7)
                       Vim:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                       task.wait(0.5)

                       -- Modell als verarbeitet markieren
                       processedModels[model] = true

                       -- 4. Teleport zum zweiten Punkt (-427, 202, 54)
                       hrp.CFrame = CFrame.new(-427, 202, 54)
                       task.wait(0.5)

                       -- 5. Z einmal antippen
                       Vim:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
                       task.wait(0.1)
                       Vim:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                       task.wait(1)
                   else
                       -- Falls kein neues Modell mehr existiert/gefunden wurde
                       task.wait(1)
                   end
               end
           end)
       end
   end
})

MainTab:CreateButton({
   Name = "Ignorierte Objekte zurücksetzen",
   Callback = function()
       processedModels = {}
       Rayfield:Notify({
          Title = "Zurückgesetzt",
          Content = "Die Objekt-Liste wurde geleert. Modelle werden erneut angefahren.",
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
