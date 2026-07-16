local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Killer Mixa - Sky Changer",
    LoadingTitle = "Killer Mixa",
    LoadingSubtitle = "by Grok 🇷🇸",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "KillerMixa",
        FileName = "SkyConfig"
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

local Tab = Window:CreateTab("Skies", 4483362458)

-- === DOBRODOŠLICA ===
local function ShowWelcomeScreen()
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local welcomeGui = Instance.new("ScreenGui")
    welcomeGui.Name = "KillerWelcome"
    welcomeGui.ResetOnSpawn = false
    welcomeGui.Parent = playerGui
    
    local blackFrame = Instance.new("Frame")
    blackFrame.Size = UDim2.new(1, 0, 1, 0)
    blackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blackFrame.BorderSizePixel = 0
    blackFrame.Parent = welcomeGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.8, 0, 0.3, 0)
    title.Position = UDim2.new(0.1, 0, 0.35, 0)
    title.BackgroundTransparency = 1
    title.Text = "DOBRO DOŠAO NA\nKILLER MIXA SCRIPT"
    title.TextColor3 = Color3.fromRGB(255, 255, 100)
    title.TextScaled = true
    title.Font = Enum.Font.Arcade
    title.TextStrokeTransparency = 0
    title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    title.TextWrapped = true
    title.Parent = blackFrame
    
    local flag = Instance.new("TextLabel")
    flag.Size = UDim2.new(0.8, 0, 0.1, 0)
    flag.Position = UDim2.new(0.1, 0, 0.55, 0)
    flag.BackgroundTransparency = 1
    flag.Text = "🇷🇸"
    flag.TextColor3 = Color3.fromRGB(255, 255, 255)
    flag.TextScaled = true
    flag.Font = Enum.Font.Arcade
    flag.TextStrokeTransparency = 0
    flag.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    flag.Parent = blackFrame
    
    wait(3)
    for i = 1, 30 do
        blackFrame.BackgroundTransparency = i/30
        title.TextTransparency = i/30
        flag.TextTransparency = i/30
        wait(0.03)
    end
    welcomeGui:Destroy()
end

-- === GLOBAL MINECRAFT FONT ===
local function ApplyMinecraftFontToAll()
    spawn(function()
        while wait(1) do
            pcall(function()
                for _, gui in pairs(game:GetDescendants()) do
                    if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
                        gui.Font = Enum.Font.Arcade
                        gui.TextStrokeTransparency = 0
                        gui.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        if gui.TextColor3 == Color3.fromRGB(255,255,255) then
                            gui.TextColor3 = Color3.fromRGB(255, 255, 100)
                        end
                    end
                end
            end)
        end
    end)
end

-- === GALAXY SKY ===
local function SetGalaxySky()
    local lighting = game:GetService("Lighting")
    
    for _, v in pairs(lighting:GetChildren()) do
        if v:IsA("Sky") then
            v:Destroy()
        end
    end
    
    local sky = Instance.new("Sky")
    sky.SkyboxBk = "http://www.roblox.com/asset/?id=159454299"
    sky.SkyboxDn = "http://www.roblox.com/asset/?id=159454296"
    sky.SkyboxFt = "http://www.roblox.com/asset/?id=159454293"
    sky.SkyboxLf = "http://www.roblox.com/asset/?id=159454286"
    sky.SkyboxRt = "http://www.roblox.com/asset/?id=159454300"
    sky.SkyboxUp = "http://www.roblox.com/asset/?id=159454288"
    sky.StarCount = 5000
    sky.SunAngularSize = 0
    sky.MoonAngularSize = 0
    sky.Parent = lighting
    
    Rayfield:Notify({
        Title = "Killer Mixa",
        Content = "🌌 GALAXY SKY AKTIVIRAN!",
        Duration = 5
    })
end

-- === MINECRAFT SKY ===
local function SetMinecraftSky()
    local lighting = game:GetService("Lighting")
    
    -- Brišemo stari Sky
    for _, v in pairs(lighting:GetChildren()) do
        if v:IsA("Sky") then
            v:Destroy()
        end
    end
    
    local sky = Instance.new("Sky")
    sky.SkyboxBk = "rbxassetid://271042596"   -- popularan Minecraft-style
    sky.SkyboxDn = "rbxassetid://271042597"
    sky.SkyboxFt = "rbxassetid://271042598"
    sky.SkyboxLf = "rbxassetid://271042599"
    sky.SkyboxRt = "rbxassetid://271042600"
    sky.SkyboxUp = "rbxassetid://271042601"
    
    sky.StarCount = 3000
    sky.SunAngularSize = 15
    sky.MoonAngularSize = 11
    sky.Parent = lighting
    
    Rayfield:Notify({
        Title = "Killer Mixa",
        Content = "⛏️ MINECRAFT SKY AKTIVIRAN!",
        Duration = 5
    })
end

-- === ULTRA CRNE LINIJE ===
local function ChangeToUltraBlackLines()
    local count = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Part") then
            local color = obj.Color
            if color.R >= 0.65 and color.G >= 0.65 and color.B >= 0.65 then
                local size = obj.Size
                if (size.Y < 2.5 and (size.X > 5 or size.Z > 5)) or math.min(size.X, size.Z) < 3 then
                    obj.Color = Color3.fromRGB(0, 0, 0)
                    obj.Material = Enum.Material.Plastic
                    obj.Reflectance = 0
                    obj.Transparency = 0
                    obj.CanCollide = false
                    count += 1
                end
            end
        end
        
        if obj:IsA("Decal") or obj:IsA("Texture") then
            if obj.Color3 and obj.Color3.R >= 0.7 then
                obj.Color3 = Color3.fromRGB(0, 0, 0)
                count += 1
            end
        end
    end
    Rayfield:Notify({Title="Killer Mixa", Content="ULTRA CRNE LINIJE AKTIVIRANE! ("..count..")", Duration=5})
end

-- === CRNE LINIJE ZA EMERGENCY HAMBURG ===
local function ChangeToEmergencyHamburgBlackLines()
    local count = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Part") then
            local color = obj.Color
            local size = obj.Size
            
            if (color.R >= 0.55 and color.G >= 0.55 and color.B >= 0.55) then
                if size.Y < 4 or math.min(size.X, size.Z) < 4 or (size.Y > 8 and math.min(size.X, size.Z) > 15) then
                    obj.Color = Color3.fromRGB(0, 0, 0)
                    obj.Material = Enum.Material.Plastic
                    obj.Reflectance = 0
                    obj.Transparency = 0
                    obj.CanCollide = false
                    count += 1
                end
            end
        end
        
        if obj:IsA("Decal") or obj:IsA("Texture") then
            if obj.Color3 and obj.Color3.R >= 0.6 then
                obj.Color3 = Color3.fromRGB(0, 0, 0)
                count += 1
            end
        end
    end
    Rayfield:Notify({Title="Killer Mixa", Content="EMERGENCY HAMBURG CRNE LINIJE AKTIVIRANE! ("..count..")", Duration=5})
end

-- === OSTALE FUNKCIJE ===
local function ToggleTransparency(enable) 
    -- tvoj kod...
end

local function ToggleJumpShoot(enable)
    -- tvoj kod...
end

-- === POČETAK SKRIPTE ===
ShowWelcomeScreen()
ApplyMinecraftFontToAll()

Tab:CreateSection("Killer Mixa Skies")

Tab:CreateButton({
    Name = "🌌 Galaxy Sky",
    Callback = function()
        SetGalaxySky()
    end
})

Tab:CreateButton({
    Name = "⛏️ Minecraft Sky",
    Callback = function()
        SetMinecraftSky()
    end
})

Tab:CreateSection("Ostalo")

Tab:CreateButton({
    Name = "⚫ Ultra Crne Linije",
    Callback = function()
        ChangeToUltraBlackLines()
    end
})

Tab:CreateButton({
    Name = "🚨 Crne Linije - Emergency Hamburg",
    Callback = function()
        ChangeToEmergencyHamburgBlackLines()
    end
})

Tab:CreateToggle({
    Name = "👁️ Auto Prozirljivost",
    CurrentValue = false,
    Callback = ToggleTransparency
})

Tab:CreateToggle({
    Name = "🔫 Jump + Shoot",
    CurrentValue = false,
    Callback = ToggleJumpShoot
})

Tab:CreateButton({
    Name = "🌤️ Reset to Default",
    Callback = function()
        local lighting = game:GetService("Lighting")
        for _, v in pairs(lighting:GetChildren()) do
            if v:IsA("Sky") then v:Destroy() end
        end
        Rayfield:Notify({Title="Killer Mixa", Content="Sky resetovan na default!", Duration=5})
    end
})

Rayfield:LoadConfiguration()

print("Killer Mixa Script učitan - Dobro došao brate! 🇷🇸")
