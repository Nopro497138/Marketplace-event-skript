-- Rayfield Library laden
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Celestial Farm | Delta (Robust)",
   LoadingTitle = "Celestial Auto-Farm",
   LoadingSubtitle = "v2.0 Enhanced",
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false },
   KeySystem = false
})

local Tab = Window:CreateTab("Main", 4483362458)

-- Variablen & Steuerung
local _G = _G or {}
_G.CelestialFarm = false

-- Dienste
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Hilfsfunktion: Robuster Teleport mit Noclip-Schutz
local function safeTeleport(targetPosition)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if not root then return end

    -- Kurzzeitiges Noclip aktivieren, um nicht festzustecken
    local noclipConn
    noclipConn = RunService.Stepped:Connect(function()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)

    -- Teleport durchführen
    if typeof(targetPosition) == "Vector3" then
        root.CFrame = CFrame.new(targetPosition)
    elseif typeof(targetPosition) == "CFrame" then
        root.CFrame = targetPosition
    end

    task.wait(0.1)
    if noclipConn then noclipConn:Disconnect() end
end

-- Hilfsfunktion: Robuster Text-Check
local function isCelestial(instance)
    if not instance then return false end

    -- Textlabels / TextButtons / TextInputs
    local success, text = pcall(function() return instance.Text end)
    if success and typeof(text) == "string" and text:lower():find("celestial") then
        return true
    end

    -- ValueBases (StringValue, ObjectValue Name, etc.)
    if instance:IsA("StringValue") and instance.Value:lower():find("celestial") then
        return true
    end

    -- Name des Objekts selbst prüfen
    if instance.Name:lower():find("celestial") then
        return true
    end

    return false
end

-- Hilfsfunktion: CFrame/Position eines Models sicher ermitteln
local function getModelCFrame(model)
    if model:IsA("Model") then
        if model.PrimaryPart then
            return model.PrimaryPart.CFrame
        end
        local pivot = model:GetPivot()
        if pivot ~= CFrame.new(0, 0, 0) then
            return pivot
        end
    end
    
    -- Fallback: Suche erstes BasePart im Model
    local part = model:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.CFrame
    end

    return nil
end

-- Hilfsfunktion: ProximityPrompt zuverlässig drücken
local function triggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end

    -- Prompt-Sicherheiten erzwingen
    prompt.Enabled = true
    prompt.MaxActivationDistance = math.huge
    prompt.HoldDuration = 0

    -- Interaktionsversuch 1: Executor-Funktion
    pcall(function()
        fireproximityprompt(prompt)
    end)

    task.wait(0.05)

    -- Interaktionsversuch 2: Fallback Event
    pcall(function()
        if prompt.InputHoldBegan then
            prompt:InputHoldBegan()
            task.wait(0.05)
            prompt:InputHoldEnded()
        end
    end)
end

-- Hauptlogik für Auto-Farm
local function runCelestialRoutine()
    local entitiesFolder = workspace:FindFirstChild("EntitiesFolder")
    if not entitiesFolder then 
        warn("EntitiesFolder nicht in Workspace gefunden!")
        return 
    end

    for _, entity in ipairs(entitiesFolder:GetChildren()) do
        if not _G.CelestialFarm then break end

        local foundCelestial = false

        -- Prüfe das Model selbst und alle Unterobjekte
        if isCelestial(entity) then
            foundCelestial = true
        else
            for _, descendant in ipairs(entity:GetDescendants()) do
                if isCelestial(descendant) then
                    foundCelestial = true
                    break
                end
            end
        end

        if foundCelestial then
            local targetCFrame = getModelCFrame(entity)
            if targetCFrame then
                -- 1. Teleport zum Model (etwas angehoben, um nicht im Boden zu sein)
                safeTeleport(targetCFrame + Vector3.new(0, 3, 0))
                task.wait(0.2)

                -- 2. Nach "TakeBrainrotPrompt" suchen und auslösen
                local prompt = entity:FindFirstChild("TakeBrainrotPrompt", true)
                if not prompt then
                    -- Fallback: Falls der Name leicht abweicht oder es irgendein Prompt ist
                    for _, p in ipairs(entity:GetDescendants()) do
                        if p:IsA("ProximityPrompt") then
                            prompt = p
                            break
                        end
                    end
                end

                if prompt then
                    triggerPrompt(prompt)
                    task.wait(0.25)
                end

                -- 3. Teleport zur Zielkoordinate
                safeTeleport(Vector3.new(19, 4, -847))
                task.wait(0.4)
                
                break -- Nach Erfolg Schleife neu starten für das nächste Item
            end
        end
    end
end

-- Toggle: Auto Celestial Farm
local Toggle = Tab:CreateToggle({
   Name = "Auto Celestial Farm",
   CurrentValue = false,
   Flag = "CelestialToggle",
   Callback = function(Value)
      _G.CelestialFarm = Value

      if Value then
          task.spawn(function()
              while _G.CelestialFarm do
                  runCelestialRoutine()
                  task.wait(0.1)
              end
          end)
      end
   end,
})

-- Button: Auto PlaceStand Loop
local isPlacingStand = false

local Button = Tab:CreateButton({
   Name = "Loop PlaceStand Remote",
   Callback = function()
      if isPlacingStand then
          Rayfield:Notify({
              Title = "PlaceStand Loop",
              Content = "Prozess läuft bereits!",
              Duration = 3,
              Image = 4483362458,
          })
          return
      end

      task.spawn(function()
          isPlacingStand = true
          
          local utilities = ReplicatedStorage:WaitForChild("Utilities", 5)
          local typedRemote = utilities and utilities:WaitForChild("TypedRemote", 5)
          local placeStand = typedRemote and typedRemote:WaitForChild("PlaceStand", 5)

          if not placeStand then
              Rayfield:Notify({
                  Title = "Fehler",
                  Content = "PlaceStand Remote nicht gefunden!",
                  Duration = 5,
                  Image = 4483362458,
              })
              isPlacingStand = false
              return
          end

          Rayfield:Notify({
              Title = "PlaceStand Loop",
              Content = "Starte Remote-Schleife ab 1...",
              Duration = 3,
              Image = 4483362458,
          })

          local currentNum = 1
          while true do
              local success, result = pcall(function()
                  return placeStand:InvokeServer(currentNum)
              end)

              if not success then
                  warn("Abbruch bei Zahl " .. tostring(currentNum) .. " mit Fehler: " .. tostring(result))
                  
                  Rayfield:Notify({
                      Title = "Schleife Gestoppt",
                      Content = "Error bei Zahl " .. tostring(currentNum) .. "!",
                      Duration = 6,
                      Image = 4483362458,
                  })
                  break
              end

              currentNum = currentNum + 1
              task.wait(0.05)
          end

          isPlacingStand = false
      end)
   end,
})
