-- // Variablen für die Remote-Events
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OnCast = Remotes:WaitForChild("OnCast")         -- RemoteFunction
local FinishRun = Remotes:WaitForChild("FinishRun")   -- RemoteFunction

-- // Einstellungen
local loopInterval = 0.2      -- Zeitabstand zwischen den Wiederholungen (in Sekunden)
local betweenDelay = 0.2     -- Cooldown zwischen OnCast und FinishRun (in Sekunden)

-- // Status der Schleife
local running = false

-- // GUI erstellen
local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0.5, -100, 0.5, -25)
button.Text = "Start"
button.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
button.TextColor3 = Color3.new(1, 1, 1)
button.Parent = screenGui

-- // Toggle-Funktion
local function toggle()
    running = not running
    button.Text = running and "Stop" or "Start"
    button.BackgroundColor3 = running and Color3.fromRGB(170, 0, 0) or Color3.fromRGB(0, 170, 0)

    if running then
        -- Starte die Schleife in einer separaten Koroutine
        task.spawn(function()
            while running do
                -- 1. OnCast mit dem Float-Wert
                local success, result = pcall(function()
                    OnCast:InvokeServer(0.9000930618494749)
                end)
                if not success then
                    warn("Fehler bei OnCast:", result)
                end

                -- 2. Kurze Pause
                task.wait(betweenDelay)

                -- 3. FinishRun mit true
                local success2, result2 = pcall(function()
                    FinishRun:InvokeServer(true)
                end)
                if not success2 then
                    warn("Fehler bei FinishRun:", result2)
                end

                -- 4. Warten bis zur nächsten Runde (Gesamtzeit = loopInterval)
                task.wait(loopInterval - betweenDelay)
            end
        end)
    end
end

button.MouseButton1Click:Connect(toggle)
