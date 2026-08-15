-- Warten, bis das Spiel vollständig geladen ist
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Sicheres Laden der Rayfield Library
local Success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not Success or not Rayfield then
    warn("Rayfield konnte nicht geladen werden!")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Auto Farm Script",
    LoadingTitle = "Initializing...",
    LoadingSubtitle = "Delta Executor Ready",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local Tab = Window:CreateTab("Main", 4483362458)

local AutoFarm = false

-- Safe-Get Helper Funktion um Nil-Errors im Workspace zu verhindern
local function getObject(path)
    local current = workspace
    for _, name in ipairs(path) do
        current = current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

-- Safe Teleport
local function teleportTo(x, y, z)
    local player = game:GetService("Players").LocalPlayer
    if player and player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(x, y, z)
        end
    end
end

Tab:CreateToggle({
    Name = "Auto Farm Loop",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(Value)
        AutoFarm = Value

        if AutoFarm then
            task.spawn(function()
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local Remotes = ReplicatedStorage:WaitForChild("__remotes", 5)

                if not Remotes then
                    Rayfield:Notify({ Title = "Fehler", Content = "Remotes nicht gefunden!", Duration = 3 })
                    AutoFarm = false
                    return
                end

                while AutoFarm do
                    -- 1. Fake Diamond Ring 5x kaufen
                    for i = 1, 5 do
                        if not AutoFarm then break end
                        
                        local ring = getObject({"WorldBuyableItems", "CivilianArea", "Fake Diamond Ring"})
                        local buyRemote = Remotes:FindFirstChild("WorldBuyableItemService") 
                            and Remotes.WorldBuyableItemService:FindFirstChild("PurchaseWorldBuyableItem")

                        if ring and buyRemote then
                            buyRemote:FireServer(ring)
                        end
                        task.wait(0.3)
                    end

                    if not AutoFarm then break end

                    -- 2. Teleport zu Seller4 & Verkaufen
                    teleportTo(209, 18, -44)
                    task.wait(0.6)

                    local seller = getObject({"NPC", "Seller4"})
                    local sellRemote = Remotes:FindFirstChild("SmuggleService") 
                        and Remotes.SmuggleService:FindFirstChild("SellSmuggledGoods")

                    if seller and sellRemote then
                        sellRemote:FireServer(seller)
                    end

                    task.wait(0.6)
                    if not AutoFarm then break end

                    -- 3. Teleport zu Launder & Waschen
                    teleportTo(6807, 18, -34)
                    task.wait(0.6)

                    local launderPart = getObject({"LaunderPrompts", "LaunderTrigger", "PromptPart"})
                    local launderRemote = Remotes:FindFirstChild("SmuggleService") 
                        and Remotes.SmuggleService:FindFirstChild("LaunderBriefcase")

                    if launderPart and launderRemote then
                        launderRemote:FireServer(launderPart)
                    end

                    task.wait(1) -- Wartezeit vor dem nächsten Loop
                end
            end)
        end
    end,
})

Rayfield:Notify({
    Title = "Script Geladen",
    Content = "UI wurde erfolgreich gestartet!",
    Duration = 3
})
