-- 1. Warten bis das Spiel geladen ist
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 2. Rayfield Library laden
local Rayfield
local success, err = pcall(function()
    local rawCode = game:HttpGet('https://sirius.menu/rayfield')
    Rayfield = loadstring(rawCode)()
end)

if not success or not Rayfield then
    warn("Rayfield Download fehlgeschlagen: " .. tostring(err))
    local rawCodeFallback = game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source')
    Rayfield = loadstring(rawCodeFallback)()
end

-- 3. Window & Tab Erstellung
local Window = Rayfield:CreateWindow({
    Name = "Auto Farm Script",
    LoadingTitle = "Initializing...",
    LoadingSubtitle = "Delta Executor",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local Tab = Window:CreateTab("Main", 4483362458)

local AutoFarm = false

-- Safe Teleport mit anschließender Wartezeit
local function teleportTo(x, y, z, waitTime)
    local player = game:GetService("Players").LocalPlayer
    if player and player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(x, y, z)
            task.wait(waitTime or 1.5) -- Warten nach dem Teleportieren
        end
    end
end

-- Safe Get mit WaitForChild
local function waitForPath(parent, pathTable, timeout)
    local current = parent
    for _, name in ipairs(pathTable) do
        current = current:WaitForChild(name, timeout or 5)
        if not current then return nil end
    end
    return current
end

-- Toggle Button
Tab:CreateToggle({
    Name = "Auto Farm Loop",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(Value)
        AutoFarm = Value

        if AutoFarm then
            task.spawn(function()
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local Remotes = ReplicatedStorage:WaitForChild("__remotes", 10)

                if not Remotes then
                    warn("Remotes Ordner nicht gefunden!")
                    AutoFarm = false
                    return
                end

                while AutoFarm do
                    -- 1. Fake Diamond Ring 5x KAUFEN
                    local ring = waitForPath(workspace, {"WorldBuyableItems", "CivilianArea", "Fake Diamond Ring"}, 5)
                    local buyService = Remotes:WaitForChild("WorldBuyableItemService", 5)
                    local buyRemote = buyService and buyService:WaitForChild("PurchaseWorldBuyableItem", 5)

                    if ring and buyRemote then
                        for i = 1, 5 do
                            if not AutoFarm then break end
                            buyRemote:FireServer(ring)
                            task.wait(0.3) -- Kurze Pause zwischen den 5 Klicks
                        end
                    else
                        warn("Konnte Fake Diamond Ring oder Remote nicht finden!")
                    end

                    if not AutoFarm then break end

                    -- 2. TELEPORT ZU SELLER4 & PAUSE
                    teleportTo(209, 18, -44, 1.5) -- 1.5 Sekunden Warten nach TP

                    if not AutoFarm then break end

                    local seller = waitForPath(workspace, {"NPC", "Seller4"}, 5)
                    local smuggleService = Remotes:WaitForChild("SmuggleService", 5)
                    local sellRemote = smuggleService and smuggleService:WaitForChild("SellSmuggledGoods", 5)

                    if seller and sellRemote then
                        sellRemote:FireServer(seller)
                    else
                        warn("Konnte Seller4 oder Sell Remote nicht finden!")
                    end

                    task.wait(0.5)
                    if not AutoFarm then break end

                    -- 3. TELEPORT ZU LAUNDER & PAUSE
                    teleportTo(6807, 18, -34, 1.5) -- 1.5 Sekunden Warten nach TP

                    if not AutoFarm then break end

                    local launderPart = waitForPath(workspace, {"LaunderPrompts", "LaunderTrigger", "PromptPart"}, 5)
                    local launderRemote = smuggleService and smuggleService:WaitForChild("LaunderBriefcase", 5)

                    if launderPart and launderRemote then
                        launderRemote:FireServer(launderPart)
                    else
                        warn("Konnte LaunderPart oder Launder Remote nicht finden!")
                    end

                    task.wait(1.5) -- Pause vor dem nächsten Schleifendurchlauf
                end
            end)
        end
    end,
})
