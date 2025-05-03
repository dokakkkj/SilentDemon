local player = game:GetService("Players").LocalPlayer
local runService = game:GetService("RunService")

-- CONFIGURAÇÕES
getgenv().settings = {
    enabled = true,
    maxDistance = 600,
    onlyCriminals = false,
    showTracer = true,
    ignoreTeam = true
}

-- TRACER
local tracerPart, beam
local function createTracer()
    if tracerPart then tracerPart:Destroy() end
    
    tracerPart = Instance.new("Part")
    tracerPart.Name = "AimTracer"
    tracerPart.Anchored = true
    tracerPart.CanCollide = false
    tracerPart.Transparency = 1
    tracerPart.Color = Color3.fromRGB(255, 0, 0)
    tracerPart.Size = Vector3.new(0.1, 0.1, 1)
    tracerPart.Material = Enum.Material.Neon
    tracerPart.Parent = workspace

    beam = Instance.new("Beam")
    beam.Attachment0 = Instance.new("Attachment")
    beam.Attachment1 = Instance.new("Attachment")
    beam.Width0 = 0.2
    beam.Width1 = 0.2
    beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
    beam.Parent = tracerPart
    beam.Enabled = false
end

local function updateTracer(target)
    if not tracerPart or not beam then return end
    
    if not settings.showTracer or not settings.enabled or not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        beam.Enabled = false
        return
    end

    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    beam.Attachment0.Parent = root
    beam.Attachment1.Parent = target.Character.HumanoidRootPart
    beam.Enabled = true
end

-- SILENT AIM CORE
getgenv().old = getgenv().old or require(game:GetService("ReplicatedStorage").Module.RayCast).RayIgnoreNonCollideWithIgnoreList

local function getNearestTarget()
    local nearestDist = math.huge
    local nearestPlayer = nil
    
    for _, target in pairs(game:GetService("Players"):GetPlayers()) do
        if target ~= player and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            if not settings.ignoreTeam or target.Team ~= player.Team then
                if not settings.onlyCriminals or target.Character:FindFirstChild("Criminal") then
                    local dist = (target.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if dist < nearestDist and dist <= settings.maxDistance then
                        nearestDist = dist
                        nearestPlayer = target
                    end
                end
            end
        end
    end
    
    return nearestPlayer
end

local function updateSilent()
    if settings.enabled then
        require(game:GetService("ReplicatedStorage").Module.RayCast).RayIgnoreNonCollideWithIgnoreList = function(...)
            local target = getNearestTarget()
            local args = {getgenv().old(...)}
            
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                if tostring(getfenv(2).script):find("Bullet") or tostring(getfenv(2).script):find("Taser") then
                    args[1] = target.Character.HumanoidRootPart
                    args[2] = target.Character.HumanoidRootPart.Position
                    if settings.showTracer then
                        updateTracer(target)
                    end
                end
            else
                updateTracer(nil)
            end
            return unpack(args)
        end
    else
        require(game:GetService("ReplicatedStorage").Module.RayCast).RayIgnoreNonCollideWithIgnoreList = getgenv().old
        updateTracer(nil)
    end
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 200)
frame.Position = UDim2.new(0.5, -100, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local function createBtn(text, ypos, setting)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, ypos, 0)
    btn.Text = text..": "..(settings[setting] and "ON" or "OFF")
    btn.BackgroundColor3 = settings[setting] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.Parent = frame
    
    btn.MouseButton1Click:Connect(function()
        settings[setting] = not settings[setting]
        btn.Text = text..": "..(settings[setting] and "ON" or "OFF")
        btn.BackgroundColor3 = settings[setting] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        updateSilent()
    end)
    
    return btn
end

createBtn("SILENT AIM", 0.05, "enabled")
createBtn("SÓ CRIMINOSOS", 0.2, "onlyCriminals")
createBtn("TRACER", 0.35, "showTracer")
createBtn("IGNORAR TIME", 0.5, "ignoreTeam")

local distBox = Instance.new("TextBox")
distBox.Size = UDim2.new(0.9, 0, 0, 25)
distBox.Position = UDim2.new(0.05, 0, 0.7, 0)
distBox.Text = tostring(settings.maxDistance)
distBox.PlaceholderText = "Distância"
distBox.Parent = frame

distBox.FocusLost:Connect(function()
    settings.maxDistance = math.clamp(tonumber(distBox.Text) or 600, 50, 5000)
    distBox.Text = tostring(settings.maxDistance)
end)

-- INICIALIZAÇÃO
createTracer()
updateSilent()

-- ATUALIZAÇÃO CONTÍNUA
runService.Heartbeat:Connect(function()
    if settings.enabled and settings.showTracer then
        updateTracer(getNearestTarget())
    end
end)
