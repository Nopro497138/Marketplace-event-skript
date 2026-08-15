-- 1. Warten bis das Spiel geladen ist
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 2. Rayfield Library laden (Delta-optimiert)
local Rayfield
local success, err = pcall(function()
    local rawCode = game:HttpGet('https://sirius.menu/rayfield')
    Rayfield = loadstring(rawCode)()
end)

if not success or not Rayfield then
    warn("Rayfield Download fehlgeschlagen: " .. tostring(err))
    -- Fallback auf Kovo / Orion Library für Delta Executor
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

-- Safe-Get Helper
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
                local Remotes = ReplicatedStorage:WaitForChild("__remotes", 5)

                if not Remotes then
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

                    task.wait(1)
                end
            end)
        end
    end,
})
