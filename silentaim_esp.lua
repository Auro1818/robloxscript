if game.PlaceId ~= 286090429 then
    return warn("Not Arsenal, script stopped.")
end

local Players, RunService = game:GetService("Players"), game:GetService("RunService")
local LocalPlayer, Camera = Players.LocalPlayer, workspace.CurrentCamera
local ESPEnabled, SilentAimEnabled = true, true
local espCache = {}

-- GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 160, 0, 140)
Frame.Position = UDim2.new(0, 20, 0, 200)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BackgroundTransparency = 0.3

local function createToggle(text, default, posY, callback)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Position = UDim2.new(0, 0, 0, posY)
    btn.Text = text .. ": " .. (default and "ON" or "OFF")
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.BackgroundTransparency = 0.2
    btn.MouseButton1Click:Connect(function()
        default = not default
        btn.Text = text .. ": " .. (default and "ON" or "OFF")
        callback(default)
    end)
end

createToggle("Silent Aim", SilentAimEnabled, 0, function(v) SilentAimEnabled = v end)
createToggle("ESP", ESPEnabled, 35, function(v) ESPEnabled = v end)

-- Anti Kick & Hook
hookfunction(Players.LocalPlayer.Kick, function(...) return end)
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall
mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    if tostring(self) == "Workspace" and method == "FindPartOnRayWithIgnoreList" and SilentAimEnabled then
        return nil
    end
    if method == "Kick" and self == LocalPlayer then
        return
    end
    return oldNamecall(self, ...)
end

-- Silent Aim Hook
local mouse = LocalPlayer:GetMouse()
local oldIndex = mt.__index
mt.__index = function(t, k)
    if SilentAimEnabled and t == mouse and (k == "Hit" or k == "Target") then
        local closest, dist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character and p.Character:FindFirstChild("Head") then
                local head = p.Character.Head.Position
                local screenPos, visible = Camera:WorldToViewportPoint(head)
                local mag = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if mag < dist then
                    dist = mag
                    closest = p
                end
            end
        end
        if closest and closest.Character and closest.Character:FindFirstChild("Head") then
            return k == "Hit" and closest.Character.Head.CFrame or closest.Character.Head
        end
    end
    return oldIndex(t, k)
end

-- Kiểm tra sau tường
local function isBehindWall(char)
    if not char or not char:FindFirstChild("Head") then return false end
    local origin = Camera.CFrame.Position
    local direction = (char.Head.Position - origin)
    local result = workspace:Raycast(origin, direction)
    if result and result.Instance and not char:IsAncestorOf(result.Instance) then
        return true
    end
    return false
end

-- ESP tạo
local function createESP(player)
    if not player.Character or not player.Character:FindFirstChild("Head") then return end
    if espCache[player] then espCache[player].Gui:Destroy() end

    local tag = Instance.new("BillboardGui", player.Character)
    tag.Name = "ESPTag"
    tag.Size = UDim2.new(0, 100, 0, 40)
    tag.AlwaysOnTop = true
    tag.Adornee = player.Character.Head

    local label = Instance.new("TextLabel", tag)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.5
    label.TextScaled = true
    label.Text = player.Name

    espCache[player] = {Gui = tag, Label = label}
end

local function removeESP(player)
    if espCache[player] then
        espCache[player].Gui:Destroy()
        espCache[player] = nil
    end
end

-- Auto Update ESP mọi frame
RunService.RenderStepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if ESPEnabled and not espCache[p] then
                createESP(p)
            elseif not ESPEnabled and espCache[p] then
                removeESP(p)
            end
            if ESPEnabled and espCache[p] then
                local isHidden = isBehindWall(p.Character)
                espCache[p].Label.TextColor3 = isHidden and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
            end
        end
    end
end)

-- Auto cập nhật player mới và hồi sinh
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        wait(1)
        if ESPEnabled then createESP(p) end
    end)
end)

Players.PlayerRemoving:Connect(removeESP)

-- Gọi lại cho tất cả player hiện có (hồi sinh cũ)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function()
            wait(1)
            if ESPEnabled then createESP(p) end
        end)
    end
end

print("[✅ Arsenal Hack Loaded: SilentAim + Wallbang + ESP + AntiKick + AutoUpdate Players]")
