-- Rayfield UI Library laden
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Status Variablen
getgenv().AutoFarmRunning = false
local TargetPosition = Vector3.new(-150, 6, -597)

-- Rayfield Fenster erstellen
local Window = Rayfield:CreateWindow({
   Name = "Celestial & OG Automatisierung",
   LoadingTitle = "Delta Executor",
   LoadingSubtitle = "by Assistant",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "CelestialConfig"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvite",
      RememberJoins = true
   },
   KeySystem = false,
})

-- Tab erstellen
local MainTab = Window:CreateTab("Automation", 4483362458) -- Icon ID

-- Sektion
local MainSection = MainTab:CreateSection("Steuerung")

-- Toggle für Automatisierung
MainTab:CreateToggle({
   Name = "Automatisierung aktivieren",
   CurrentValue = false,
   Flag = "AutoFarmToggle",
   Callback = function(Value)
      getgenv().AutoFarmRunning = Value
      if Value then
         Rayfield:Notify({
            Title = "Aktiviert",
            Content = "Suche nach Bases gestartet...",
            Duration = 3,
            Image = 4483362458,
         })
      end
   end,
})

-- Funktion zum Überprüfen von Objekten auf Text oder Name
local function matchesCriteria(model)
    if not model:IsA("Model") then return false end
    
    -- Prüfe Modellnamen
    if string.find(model.Name, "Celestial") or string.find(model.Name, "OG") then
        return true
    end
    
    -- Prüfe alle Nachkommen auf Text-Objekte (TextLabel, TextButton, etc.) oder Properties
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
            if string.find(descendant.Text, "Celestial") or string.find(descendant.Text, "OG") then
                return true
            end
        end
    end
    
    return false
end

-- Teleportier-Funktion
local function teleportTo(position)
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(position)
    end
end

-- Hauptschleife für die Automatisierung
task.spawn(function()
    while true do
        if getgenv().AutoFarmRunning then
            pcall(function()
                local basesFolder = Workspace:FindFirstChild("Bases")
                if basesFolder then
                    for _, model in ipairs(basesFolder:GetChildren()) do
                        if not getgenv().AutoFarmRunning then break end
                        
                        if matchesCriteria(model) then
                            -- Suche nach ProximityPrompt im Modell
                            for _, descendant in ipairs(model:GetDescendants()) do
                                if descendant:IsA("ProximityPrompt") then
                                    local character = LocalPlayer.Character
                                    if character and character:FindFirstChild("HumanoidRootPart") then
                                        -- Zum Prompt bewegen (optional für Reichweite)
                                        local promptPart = descendant.Parent
                                        if promptPart and promptPart:IsA("BasePart") then
                                            character.HumanoidRootPart.CFrame = promptPart.CFrame + Vector3.new(0, 3, 0)
                                            task.wait(0.2)
                                        end
                                    end
                                    
                                    -- Prompt auslösen und 0.8 Sekunden halten
                                    fireproximityprompt(descendant, 0.8)
                                    task.wait(0.85)
                                    
                                    -- Teleport zu Zielkoordinaten (-150, 6, -597)
                                    teleportTo(TargetPosition)
                                    task.wait(0.5)
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)
