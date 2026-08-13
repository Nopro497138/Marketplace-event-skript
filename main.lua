local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Player Highlight UI",
   LoadingTitle = "Lade Skript...",
   LoadingSubtitle = "Delta Client",
   ConfigurationSaving = {
      Enabled = false
   },
   Discord = {
      Enabled = false
   },
   KeySystem = false
})

local MainTab = Window:CreateTab("Visuals", 4483362458)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HighlightEnabled = false

-- Funktion zum Anwenden des Highlights auf einen Charakter
local function applyHighlight(player, character)
    if player == LocalPlayer or not character then return end
    
    -- Altes Highlight entfernen, falls vorhanden
    local existingHighlight = character:FindFirstChild("PlayerGreenHighlight")
    if existingHighlight then
        existingHighlight:Destroy()
    end
    
    if HighlightEnabled then
        local highlight = Instance.new("Highlight")
        highlight.Name = "PlayerGreenHighlight"
        highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Grün
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- Weißer Rand
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Adornee = character
        highlight.Parent = character
    end
end

-- Funktion zum Aktualisieren aller Spieler
local function updateHighlights()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character then
                applyHighlight(player, player.Character)
            end
        end
    end
end

-- Event-Listener für nachfolgende/neue Spieler und Respawns
for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        applyHighlight(player, char)
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        applyHighlight(player, char)
    end)
end)

-- Rayfield Toggle UI Component
MainTab:CreateToggle({
   Name = "Spieler grün hervorheben",
   CurrentValue = false,
   Flag = "GreenHighlightToggle",
   Callback = function(Value)
      HighlightEnabled = Value
      updateHighlights()
   end,
})
