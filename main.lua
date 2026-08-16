-- Rayfield Library laden
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Celestial Farm | Delta",
   LoadingTitle = "Celestial Auto-Farm",
   LoadingSubtitle = "by Assistant",
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false },
   KeySystem = false
})

local Tab = Window:CreateTab("Main", 4483362458) -- Tab-Icon

-- Variablen & Steuerung
local _G = _G or {}
_G.CelestialFarm = false

-- Dienste & Hilfsfunktionen
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local function getRoot()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:FindFirstChild("HumanoidRootPart")
end

local function teleportTo(cframeOrPosition)
    local root = getRoot()
    if root then
        if typeof(cframeOrPosition) == "Vector3" then
            root.CFrame = CFrame.new(cframeOrPosition)
        elseif typeof(cframeOrPosition) == "CFrame" then
            root.CFrame = cframeOrPosition
        end
    end
end

-- Funktion: Prüft, ob ein Text-Objekt den Begriff "Celestial" enthält
local function hasCelestialText(instance)
    local success, text = pcall(function()
        return instance.Text
    end)
    if success and typeof(text) == "string" and text:find("Celestial") then
        return true
    end

    if instance:IsA("StringValue") and instance.Value:find("Celestial") then
        return true
    end

    return false
end

-- Hauptschleife für Celestial Auto-Farm
local function runCelestialRoutine()
    local entitiesFolder = workspace:FindFirstChild("EntitiesFolder")
    if not entitiesFolder then return end

    for _, entity in ipairs(entitiesFolder:GetChildren()) do
        if not _G.CelestialFarm then break end

        local foundCelestial = false

        for _, descendant in ipairs(entity:GetDescendants()) do
            if hasCelestialText(descendant) then
                foundCelestial = true
                break
            end
        end

        if foundCelestial then
            -- 1. Teleport zum Model
            local targetCFrame = entity:GetPivot()
            teleportTo(targetCFrame)
            task.wait(0.15)

            -- 2. "TakeBrainrotPrompt" suchen und drücken
            local prompt = entity:FindFirstChild("TakeBrainrotPrompt", true)
            if prompt and prompt:IsA("ProximityPrompt") then
                fireproximityprompt(prompt)
                task.wait(0.2)
            end

            -- 3. Teleport zur Zielkoordinate
            teleportTo(Vector3.new(19, 4, -847))
            task.wait(0.3)
            
            break
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
              Content = "Der Prozess läuft bereits!",
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
                  Content = "PlaceStand Remote konnte nicht gefunden werden!",
                  Duration = 5,
                  Image = 4483362458,
              })
              isPlacingStand = false
              return
          end

          Rayfield:Notify({
              Title = "PlaceStand Loop",
              Content = "Starte Remote-Schleife ab Zahl 1...",
              Duration = 3,
              Image = 4483362458,
          })

          local currentNum = 1
          while true do
              -- InvokeServer mit pcall abfangen, um Fehler abzufangen
              local success, result = pcall(function()
                  return placeStand:InvokeServer(currentNum)
              end)

              -- Wenn InvokeServer fehlschlägt oder nil/false zurückgibt (je nach Spiel-Logik)
              if not success then
                  warn("PlaceStand abgebrochen bei Zahl " .. tostring(currentNum) .. " mit Fehler: " .. tostring(result))
                  
                  Rayfield:Notify({
                      Title = "Schleife Gestoppt",
                      Content = "Error bei Zahl " .. tostring(currentNum) .. "! Abbruch.",
                      Duration = 6,
                      Image = 4483362458,
                  })
                  break
              end

              currentNum = currentNum + 1
              task.wait(0.05) -- Kurze Verzögerung zur Vermeidung von Remote-Spam-Kicks
          end

          isPlacingStand = false
      end)
   end,
})
