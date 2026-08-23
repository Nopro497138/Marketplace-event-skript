-- Rayfield Library Laden
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Item Spawns Farm",
    LoadingTitle = "Delta Executor Script",
    LoadingSubtitle = "by Assistant",
    ConfigurationSaving = { Enabled = false }
})

local Tab = Window:CreateTab("Auto Farm", 4483362458)

-- Variablen & Positionen
local running = false
local startPos = Vector3.new(-104, 2673, 2163)
local returnPos = Vector3.new(155, 3, -86)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Hilfsfunktion: Sicheres Teleportieren
local function teleportTo(pos)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
    end
end

-- Hauptschleife
local function startSpawnFarm()
    task.spawn(function()
        while running do
            -- 1. Start-Teleport zur Überwachungsposition (IMMER als allererstes)
            teleportTo(startPos)
            task.wait(0.5) -- Genau 0.5 Sekunden warten

            if not running then break end

            local itemSpawns = workspace:FindFirstChild("ItemSpawns")
            local folder11 = itemSpawns and itemSpawns:FindFirstChild("11")

            if folder11 then
                -- Suche nach einem Modell im Ordner "11"
                local targetModel = folder11:FindFirstChildWhichIsA("Model")

                if targetModel then
                    local targetPart = targetModel.PrimaryPart or targetModel:FindFirstChildWhichIsA("BasePart", true)

                    if targetPart then
                        -- 2. Teleport zum Objekt in Spawn "11"
                        teleportTo(targetPart.Position + Vector3.new(0, 3, 0))
                        task.wait(0.2)

                        -- 3. ProximityPrompt / PickupPrompt suchen und auslösen
                        local prompt = targetModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            fireproximityprompt(prompt)
                            task.wait(0.2)
                        end

                        -- 4. Teleport zur Ziel-Position (155, 3, -86)
                        teleportTo(returnPos)
                        task.wait(0.5)
                    end
                end
            end

            task.wait(0.3) -- Kurze Pause vor dem nächsten Ablauf
        end
    end)
end

-- Rayfield Toggle
Tab:CreateToggle({
    Name = "Spawn '11' Auto-Farm",
    CurrentValue = false,
    Flag = "Spawn11FarmToggle",
    Callback = function(Value)
        running = Value
        if running then
            Rayfield:Notify({Title = "Farm Aktiviert", Content = "Starte mit Überwachungsposition...", Duration = 3})
            startSpawnFarm()
        else
            Rayfield:Notify({Title = "Farm Deaktiviert", Content = "Auto-Farm gestoppt.", Duration = 3})
        end
    end,
})
