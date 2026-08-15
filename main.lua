local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Auto Farm Script",
    LoadingTitle = "Loading Script...",
    LoadingSubtitle = "by Assistant",
    ConfigurationSaving = {
        Enabled = false
    }
})

local Tab = Window:CreateTab("Main", 4483362458)

local _G.AutoFarm = false

Tab:CreateToggle({
    Name = "Auto Farm Loop",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(Value)
        _G.AutoFarm = Value
        
        if Value then
            task.spawn(function()
                local Players = game:GetService("Players")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local LocalPlayer = Players.LocalPlayer

                local function teleportTo(x, y, z)
                    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    local hrp = character:WaitForChild("HumanoidRootPart")
                    hrp.CFrame = CFrame.new(x, y, z)
                end

                while _G.AutoFarm do
                    -- 1. Fake Diamond Ring 5x kaufen
                    for i = 1, 5 do
                        if not _G.AutoFarm then break end
                        local item = workspace:WaitForChild("WorldBuyableItems", 5)
                            and workspace.WorldBuyableItems:WaitForChild("CivilianArea", 5)
                            and workspace.WorldBuyableItems.CivilianArea:WaitForChild("Fake Diamond Ring", 5)
                        
                        if item then
                            ReplicatedStorage:WaitForChild("__remotes")
                                :WaitForChild("WorldBuyableItemService")
                                :WaitForChild("PurchaseWorldBuyableItem")
                                :FireServer(item)
                        end
                        task.wait(0.3)
                    end

                    if not _G.AutoFarm then break end

                    -- 2. Teleport zu Seller4 & Verkaufen
                    teleportTo(209, 18, -44)
                    task.wait(0.5)

                    local seller = workspace:WaitForChild("NPC", 5)
                        and workspace.NPC:WaitForChild("Seller4", 5)
                    
                    if seller then
                        ReplicatedStorage:WaitForChild("__remotes")
                            :WaitForChild("SmuggleService")
                            :WaitForChild("SellSmuggledGoods")
                            :FireServer(seller)
                    end

                    task.wait(0.5)
                    if not _G.AutoFarm then break end

                    -- 3. Teleport zu Launder & Waschen
                    teleportTo(6807, 18, -34)
                    task.wait(0.5)

                    local launderPart = workspace:WaitForChild("LaunderPrompts", 5)
                        and workspace.LaunderPrompts:WaitForChild("LaunderTrigger", 5)
                        and workspace.LaunderPrompts.LaunderTrigger:WaitForChild("PromptPart", 5)

                    if launderPart then
                        ReplicatedStorage:WaitForChild("__remotes")
                            :WaitForChild("SmuggleService")
                            :WaitForChild("LaunderBriefcase")
                            :FireServer(launderPart)
                    end

                    task.wait(1) -- Kurze Pause vor dem nächsten Durchlauf
                end
            end)
        end
    end,
})
