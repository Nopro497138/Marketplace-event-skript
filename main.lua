--[[
  Simple Roll-Spammer mit Toggle-GUI
  Funktioniert mit dem angegebenen RemoteEvent-Pfad.
]]

-- Service holen
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Pfad zum RemoteEvent (einmalig cachen)
local RemoteEvent
local success, err = pcall(function()
    RemoteEvent = ReplicatedStorage:WaitForChild("Packages")
        :WaitForChild("_Index")
        :WaitForChild("leifstout_networker@0.3.1")
        :WaitForChild("networker")
        :WaitForChild("_remotes")
        :WaitForChild("Roll")
        :WaitForChild("RemoteEvent")
end)

if not success or not RemoteEvent then
    warn("RemoteEvent nicht gefunden! Bist du im richtigen Spiel?")
    return
end

-- Status-Variablen
local isRunning = false
local loopConnection = nil

-- Funktion, die das Event feuert
local function fireRoll()
    -- args wie gewünscht
    local args = { "Roll" }
    -- FireServer mit allen Argumenten
    RemoteEvent:FireServer(unpack(args))
end

-- Hauptschleife (läuft in einer Coroutine)
local function startLoop()
    if loopConnection then return end  -- schon aktiv
    isRunning = true
    loopConnection = game:GetService("RunService").Heartbeat:Connect(function()
        -- Nur feuern, wenn isRunning true ist
        if isRunning then
            fireRoll()
        end
    end)
    -- Zusätzlich alle 0.1 Sekunden via task.wait (sicherer)
    -- Aber Heartbeat feuert ca. 60x pro Sekunde, das ist zu oft.
    -- Wir verwenden stattdessen eine while-Schleife mit task.wait(0.1)
    -- Besser: eigene while-Schleife in einer Coroutine
    -- Wir beenden die Heartbeat-Verbindung und nutzen eine eigene Schleife
    loopConnection:Disconnect()
    loopConnection = nil

    -- Starte eine neue while-Schleife
    loopConnection = coroutine.create(function()
        while isRunning do
            fireRoll()
            task.wait(0.1)
        end
    end)
    coroutine.resume(loopConnection)
end

local function stopLoop()
    isRunning = false
    -- Coroutine wird sich selbst beenden, da die while-Bedingung false wird
    -- Wir müssen den Coroutine-Referenz zurücksetzen
    if loopConnection then
        loopConnection = nil
    end
end

-- GUI erstellen (ScreenGui)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RollSpammerGUI"
screenGui.ResetOnSpawn = false  -- bleibt beim Respawn erhalten
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Haupt-Frame (klein, transparent)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 60)
frame.Position = UDim2.new(0.5, -90, 0.5, -30)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true  -- zum Verschieben
frame.Parent = screenGui

-- Abgerundete Ecken (optional)
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Beschriftung (Text oben)
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0.4, 0)
label.Position = UDim2.new(0, 0, 0, 0)
label.BackgroundTransparency = 1
label.Text = "Roll Spammer"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Parent = frame

-- Toggle-Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.8, 0, 0.4, 0)
toggleButton.Position = UDim2.new(0.1, 0, 0.5, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
toggleButton.Text = "Start"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.BorderSizePixel = 0
toggleButton.Parent = frame

-- Abrundung für Button
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleButton

-- Button-Klick-Funktion
toggleButton.MouseButton1Click:Connect(function()
    if isRunning then
        -- Stoppen
        stopLoop()
        toggleButton.Text = "Start"
        toggleButton.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
    else
        -- Starten
        startLoop()
        toggleButton.Text = "Stopp"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    end
end)

-- Sicherstellen, dass beim Beenden des Spiels die Schleife aufhört
LocalPlayer.AncestryChanged:Connect(function()
    if not LocalPlayer.Parent then
        stopLoop()
    end
end)

-- Optional: Tastenkürzel (z.B. R) zum Togglen
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.R then
        toggleButton:Click()
    end
end)

print("Roll-Spammer geladen. GUI erscheint in der Mitte. Drücke 'R' oder klicke den Button zum Togglen.")
