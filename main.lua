-- Rayfield Library laden
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Celestial Farm | Delta (Fix)",
   LoadingTitle = "Celestial Auto-Farm",
   LoadingSubtitle = "Model Search Fixed",
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

-- Hilfsfunktion: Teleportiert sicher zum Ziel
local function safeTeleport(targetCFrame)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if not root or not targetCFrame then return end

    -- Noclip aktivieren, damit man nicht im Modell feststeckt
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

    root.CFrame = targetCFrame
    task.wait(0.1)
    
    if noclipConn then noclipConn:Disconnect() end
end

-- Funktion: Prüft gründlich, ob ein Objekt oder dessen Kinder den Text "Celestial" enthalten
local function containsCelestialText(obj)
    if not obj then return false end

    -- 1. Name des Objekts
    if string.find(string.lower(obj.Name), "celestial") then
        return true
    end

    -- 2. Falls ValueBase (StringValue)
    if obj:IsA("StringValue") and string.find(string.lower(obj.Value), "celestial") then
        return true
    end

    -- 3. Falls Text-Property vorhanden ist (TextLabel, TextButton, TextBox, etc.)
    local success, textValue = pcall(function()
        return obj.Text
    end)
    if success and typeof(textValue) == "string" and string.find(string.lower(textValue), "celestial") then
        return true
    end

    return false
end

-- Funktion: Findet die genaue Position/CFrame eines Modells
local function getModelCFrame(model)
    if model:IsA("Model") then
        if model.PrimaryPart then
            return model.PrimaryPart.CFrame
        end
        return model:GetPivot()
    elseif model:IsA("BasePart") then
        return model.CFrame
    end

    -- Fallback: Erstes Part im Modell suchen
    local part = model:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.CFrame
    end

    return nil
end

-- Hauptschleife für die Suche und Interaktion
local function runCelestialRoutine()
    local entitiesFolder = workspace:FindFirstChild("EntitiesFolder")
    if not entitiesFolder then return end

    -- Gehe jedes Modell/Objekt im EntitiesFolder durch
    for _, model in ipairs(entitiesFolder:GetChildren()) do
        if not _G.CelestialFarm then break end

        local isMatch = false

        -- Prüfe das Modell selbst
        if containsCelestialText(model) then
            isMatch = true
        else
            -- Durchsuche ALLE Unterobjekte im Modell (UI, Values, Parts, etc.)
            for _, descendant in ipairs(model:GetDescendants()) do
                if containsCelestialText(descendant) then
                    isMatch = true
                    break
                end
            end
        end

        -- Wenn "Celestial" im Modell gefunden wurde
        if isMatch then
            local targetCFrame = getModelCFrame(model)

            if targetCFrame then
                -- 1. Teleportiere direkt zum Modell (leicht erhöht + Offset)
                safeTeleport(targetCFrame * CFrame.new(0, 2, 0))
                task.wait(0.2)

                -- 2. Suche nach "TakeBrainrotPrompt" im Modell und drücke ihn
                local prompt = model:FindFirstChild("TakeBrainrotPrompt", true)
                if not prompt then
                    -- Fallback: Nimm irgendeinen ProximityPrompt im Modell
                    prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                end

                if prompt and prompt:IsA("ProximityPrompt") then
                    prompt.Enabled = true
                    prompt.HoldDuration = 0
                    prompt.MaxActivationDistance = math.huge
                    
                    pcall(function()
                        fireproximityprompt(prompt)
                    end)
                    task.wait(0.2)
                end

                -- 3. Teleportiere zur Zielkoordinate (19, 4, -847)
                safeTeleport(CFrame.new(19, 4, -847))
                task.wait(0.3)

                -- Schleife abbrechen, um von vorne neu im EntitiesFolder zu scannen
                break
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

-- Button: Loop PlaceStand Remote
local isPlacingStand = false

local Button = Tab:CreateButton({
   Name = "Loop PlaceStand Remote",
   Callback = function()
      if isPlacingStand then return end

      task.spawn(function()
          isPlacingStand = true
          
          local utilities = ReplicatedStorage:WaitForChild("Utilities", 5)
          local typedRemote = utilities and utilities:WaitForChild("TypedRemote", 5)
          local placeStand = typedRemote and typedRemote:WaitForChild("PlaceStand", 5)

          if not placeStand then
              Rayfield:Notify({
                  Title = "Fehler",
                  Content = "PlaceStand Remote nicht gefunden!",
                  Duration = 4,
                  Image = 4483362458,
              })
              isPlacingStand = false
              return
          end

          Rayfield:Notify({
              Title = "PlaceStand Loop",
              Content = "Starte Schleife ab 1...",
              Duration = 3,
              Image = 4483362458,
          })

          local currentNum = 1
          while true do
              local success, result = pcall(function()
                  return placeStand:InvokeServer(currentNum)
              end)

              if not success then
                  Rayfield:Notify({
                      Title = "Schleife Gestoppt",
                      Content = "Error bei Zahl " .. tostring(currentNum) .. "!",
                      Duration = 5,
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
