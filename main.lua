-- === Rivals 超多功能版 (優化載入) ===
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Unnamed Enhancements 2.0 | 多功能版",
    Center = true,
    AutoShow = false,
})

local Tabs = {}

-- 先建立第一個 Tab 讓視窗有內容
Tabs.Combat = Window:AddTab("Combat")
Window:Show()

-- 延遲建立其他 Tab
task.wait(0.2)
Tabs.Visuals = Window:AddTab("Visuals")
task.wait(0.15)
Tabs.Movement = Window:AddTab("Movement")
task.wait(0.15)
Tabs.Skins = Window:AddTab("Skins")
task.wait(0.15)
Tabs.Misc = Window:AddTab("Misc")

-- ==================== 服務 ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ==================== 狀態變數 ====================
local ESP_Objects = {}

-- ==================== 工具函式 ====================
local function getClosestEnemy(maxDist, fov)
    local closest = nil
    local shortestDist = maxDist or math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)

            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if dist < shortestDist and (not fov or dist <= fov) then
                    shortestDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

local function getCharacter(player)
    return player and player.Character
end

-- ==================== Combat Tab ====================
local Combat = Tabs.Combat
local VoidAutoEnabled = false
local VoidRange = 400
local AimbotEnabled = false
local SilentAimEnabled = false
local TriggerBotEnabled = false
local AimFOV = 220
local Smoothness = 0.2

Combat:AddToggle("VoidAuto", {Text = "虛空自動攻擊", Default = true}):OnChanged(function(v) VoidAutoEnabled = v end)
Combat:AddSlider("VoidRange", {Text = "虛空範圍", Default = 400, Min = 50, Max = 1500}):OnChanged(function(v) VoidRange = v end)
Combat:AddToggle("Aimbot", {Text = "Aimbot", Default = true}):OnChanged(function(v) AimbotEnabled = v end)
Combat:AddToggle("SilentAim", {Text = "Silent Aim", Default = true}):OnChanged(function(v) SilentAimEnabled = v end)
Combat:AddToggle("TriggerBot", {Text = "Trigger Bot", Default = true}):OnChanged(function(v) TriggerBotEnabled = v end)
Combat:AddToggle("AutoShoot", {Text = "Auto Shoot", Default = false})
Combat:AddSlider("AimFOV", {Text = "Aim FOV", Default = 220, Min = 30, Max = 900}):OnChanged(function(v) AimFOV = v end)
Combat:AddSlider("Smoothness", {Text = "Smoothness", Default = 0.2, Min = 0.05, Max = 1}):OnChanged(function(v) Smoothness = v end)

-- 虛空自動攻擊 (非同步啟動)
task.spawn(function()
    while true do
        if VoidAutoEnabled then
            local localChar = getCharacter(LocalPlayer)
            if localChar then
                local localRoot = localChar:FindFirstChild("HumanoidRootPart")
                if localRoot then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            local targetChar = getCharacter(player)
                            if targetChar then
                                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                                local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
                                if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                                    local dist = (localRoot.Position - targetRoot.Position).Magnitude
                                    if dist <= VoidRange then
                                        local tool = localChar:FindFirstChildOfClass("Tool")
                                        if tool and tool:FindFirstChild("Handle") then
                                            firetouchinterest(tool.Handle, targetRoot, 0)
                                            firetouchinterest(tool.Handle, targetRoot, 1)
                                        end
                                        targetHumanoid:TakeDamage(10)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.05)
    end
end)

-- Silent Aim
local oldIndex = nil
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if self == Camera and key == "CFrame" and SilentAimEnabled then
        local target = getClosestEnemy(AimFOV)
        if target and target.Character and target.Character:FindFirstChild("Head") then
            return CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        end
    end
    return oldIndex(self, key)
end)

-- Aimbot (平滑)
RunService.RenderStepped:Connect(function(deltaTime)
    if AimbotEnabled and not SilentAimEnabled then
        local target = getClosestEnemy(AimFOV)
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local headPos = target.Character.Head.Position
            local targetCFrame = CFrame.new(Camera.CFrame.Position, headPos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Smoothness)
        end
    end
end)

-- TriggerBot
task.spawn(function()
    while true do
        if TriggerBotEnabled then
            local target = getClosestEnemy(80)
            if target then
                local localChar = getCharacter(LocalPlayer)
                local tool = localChar and localChar:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("Handle") then
                    tool:Activate()
                    task.wait(0.1)
                    tool:Deactivate()
                end
            end
        end
        task.wait(0.05)
    end
end)

-- ==================== Visuals Tab ====================
local Visuals = Tabs.Visuals
local ESPEnabled = false
local BoxESP = false
local NameESP = false
local HealthESP = false
local DistanceESP = false
local Skeleton = false
local Tracers = false
local Highlight = false

Visuals:AddToggle("ESP", {Text = "ESP 總開關", Default = true}):OnChanged(function(v) ESPEnabled = v end)
Visuals:AddToggle("BoxESP", {Text = "方框透視", Default = true}):OnChanged(function(v) BoxESP = v end)
Visuals:AddToggle("NameESP", {Text = "名稱", Default = true}):OnChanged(function(v) NameESP = v end)
Visuals:AddToggle("HealthESP", {Text = "血量條", Default = true}):OnChanged(function(v) HealthESP = v end)
Visuals:AddToggle("DistanceESP", {Text = "距離", Default = true}):OnChanged(function(v) DistanceESP = v end)
Visuals:AddToggle("Skeleton", {Text = "骨架", Default = true}):OnChanged(function(v) Skeleton = v end)
Visuals:AddToggle("Tracers", {Text = "彈道線", Default = true}):OnChanged(function(v) Tracers = v end)
Visuals:AddToggle("Highlight", {Text = "高亮", Default = true}):OnChanged(function(v)
    Highlight = v
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = getCharacter(player)
            if char then
                local hl = char:FindFirstChildOfClass("Highlight")
                if not hl and v then
                    hl = Instance.new("Highlight")
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.Parent = char
                elseif hl then
                    hl.Enabled = v
                end
            end
        end
    end
end)

-- ESP 建立函式
local function createESP(player)
    local box = Drawing.new("Square")
    box.Visible = false; box.Thickness = 2
    box.Color = Color3.fromRGB(255, 255, 255); box.Filled = false

    local name = Drawing.new("Text")
    name.Visible = false; name.Size = 13; name.Center = true
    name.Color = Color3.fromRGB(255, 255, 255); name.Outline = true
    name.OutlineColor = Color3.fromRGB(0, 0, 0); name.Text = player.Name

    local healthBg = Drawing.new("Square")
    healthBg.Visible = false; healthBg.Thickness = 1
    healthBg.Color = Color3.fromRGB(50, 50, 50); healthBg.Filled = true

    local healthBar = Drawing.new("Square")
    healthBar.Visible = false; healthBar.Thickness = 1
    healthBar.Color = Color3.fromRGB(0, 255, 0); healthBar.Filled = true

    local distText = Drawing.new("Text")
    distText.Visible = false; distText.Size = 13; distText.Center = true
    distText.Color = Color3.fromRGB(255, 255, 255); distText.Outline = true
    distText.OutlineColor = Color3.fromRGB(0, 0, 0)

    local tracer = Drawing.new("Line")
    tracer.Visible = false; tracer.Thickness = 1
    tracer.Color = Color3.fromRGB(255, 255, 255)

    local bonePairs = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    }
    local skeletonLines = {}
    for i, pair in ipairs(bonePairs) do
        local line = Drawing.new("Line")
        line.Visible = false; line.Thickness = 1
        line.Color = Color3.fromRGB(255, 255, 255)
        skeletonLines[i] = {Line = line, Bone1 = pair[1], Bone2 = pair[2]}
    end

    return {Box = box, Name = name, HealthBg = healthBg, HealthBar = healthBar, Distance = distText, Tracer = tracer, Skeleton = skeletonLines}
end

-- ESP 更新循環
task.spawn(function()
    while true do
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = getCharacter(player)
            local drawings = ESP_Objects[player]
            if not drawings then
                drawings = createESP(player)
                ESP_Objects[player] = drawings
            end

            local visible = ESPEnabled and char and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart")
            local head, root = nil, nil
            if visible then
                head = char.Head
                root = char.HumanoidRootPart
                visible = visible and head and root
            end

            -- Box
            if drawings.Box then
                drawings.Box.Visible = visible and BoxESP
                if visible and BoxESP and root then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local scale = 2000 / (Camera.CFrame.Position - root.Position).Magnitude
                        local sizeX, sizeY = 40 * scale, 60 * scale
                        drawings.Box.Size = Vector2.new(sizeX, sizeY)
                        drawings.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY)
                    else
                        drawings.Box.Visible = false
                    end
                end
            end

            -- Name
            if drawings.Name then
                drawings.Name.Visible = visible and NameESP
                if visible and NameESP and head then
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    if onScreen then
                        drawings.Name.Position = Vector2.new(pos.X, pos.Y)
                        drawings.Name.Text = player.Name
                    else
                        drawings.Name.Visible = false
                    end
                end
            end

            -- Health
            if drawings.HealthBar and drawings.HealthBg then
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                local showHealth = visible and HealthESP and humanoid
                drawings.HealthBar.Visible = showHealth
                drawings.HealthBg.Visible = showHealth
                if showHealth and root then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local scale = 2000 / (Camera.CFrame.Position - root.Position).Magnitude
                        local sizeX, sizeY = 40 * scale, 60 * scale
                        local barX = pos.X - sizeX / 2 - 6
                        local barY = pos.Y - sizeY
                        local barH = sizeY * (humanoid.Health / humanoid.MaxHealth)
                        drawings.HealthBg.Position = Vector2.new(barX - 1, barY - 1)
                        drawings.HealthBg.Size = Vector2.new(4, sizeY + 2)
                        drawings.HealthBar.Position = Vector2.new(barX, barY + sizeY - barH)
                        drawings.HealthBar.Size = Vector2.new(2, barH)
                        local ratio = humanoid.Health / humanoid.MaxHealth
                        drawings.HealthBar.Color = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
                    else
                        drawings.HealthBar.Visible = false
                        drawings.HealthBg.Visible = false
                    end
                end
            end

            -- Distance
            if drawings.Distance then
                drawings.Distance.Visible = visible and DistanceESP
                if visible and DistanceESP and root then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                    if onScreen then
                        local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
                        drawings.Distance.Position = Vector2.new(pos.X, pos.Y)
                        drawings.Distance.Text = dist .. "m"
                    else
                        drawings.Distance.Visible = false
                    end
                end
            end

            -- Tracer
            if drawings.Tracer then
                drawings.Tracer.Visible = visible and Tracers
                if visible and Tracers and root then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        drawings.Tracer.To = Vector2.new(pos.X, pos.Y)
                    else
                        drawings.Tracer.Visible = false
                    end
                end
            end

            -- Skeleton
            local showSkel = visible and Skeleton and drawings.Skeleton
            if showSkel then
                for _, skel in ipairs(drawings.Skeleton) do
                    local b1 = char:FindFirstChild(skel.Bone1)
                    local b2 = char:FindFirstChild(skel.Bone2)
                    if b1 and b2 then
                        local p1, on1 = Camera:WorldToViewportPoint(b1.Position)
                        local p2, on2 = Camera:WorldToViewportPoint(b2.Position)
                        if on1 and on2 then
                            skel.Line.Visible = true
                            skel.Line.From = Vector2.new(p1.X, p1.Y)
                            skel.Line.To = Vector2.new(p2.X, p2.Y)
                        else
                            skel.Line.Visible = false
                        end
                    else
                        skel.Line.Visible = false
                    end
                end
            elseif drawings.Skeleton then
                for _, skel in ipairs(drawings.Skeleton) do
                    skel.Line.Visible = false
                end
            end
        end

        -- 清除離線玩家的 ESP
        for player, drawings in pairs(ESP_Objects) do
            if not player.Parent then
                for _, v in pairs(drawings) do
                    if type(v) == "table" then
                        for _, item in ipairs(v) do
                            if item.Line then item.Line:Remove() end
                        end
                    elseif type(v) == "userdata" then
                        pcall(function() v:Remove() end)
                    end
                end
                ESP_Objects[player] = nil
            end
        end
        task.wait()
    end
end)

-- ==================== Movement Tab ====================
local Movement = Tabs.Movement
local FlyEnabled = false
local FlySpeed = 220
local WalkSpeedVal = 90
local JumpPowerVal = 160
local NoClipEnabled = false
local InfiniteJumpEnabled = false
local AntiKnockbackEnabled = true

Movement:AddToggle("Fly", {Text = "飛行模式", Default = false}):OnChanged(function(v)
    FlyEnabled = v
    local char = getCharacter(LocalPlayer)
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if root and humanoid then
        if v then
            root.Anchored = false
            humanoid.PlatformStand = true
        else
            humanoid.PlatformStand = false
        end
    end
end)
Movement:AddSlider("FlySpeed", {Text = "飛行速度", Default = 220, Min = 50, Max = 800}):OnChanged(function(v) FlySpeed = v end)
Movement:AddSlider("WalkSpeed", {Text = "走路速度", Default = 90, Min = 16, Max = 400}):OnChanged(function(v)
    WalkSpeedVal = v
    local humanoid = getCharacter(LocalPlayer) and getCharacter(LocalPlayer):FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.WalkSpeed = v end
end)
Movement:AddSlider("JumpPower", {Text = "跳躍力", Default = 160, Min = 50, Max = 500}):OnChanged(function(v)
    JumpPowerVal = v
    local humanoid = getCharacter(LocalPlayer) and getCharacter(LocalPlayer):FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.JumpPower = v end
end)
Movement:AddToggle("NoClip", {Text = "穿牆", Default = false}):OnChanged(function(v)
    NoClipEnabled = v
    local char = getCharacter(LocalPlayer)
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not v
            end
        end
    end
end)
Movement:AddToggle("InfiniteJump", {Text = "無限跳", Default = false}):OnChanged(function(v)
    InfiniteJumpEnabled = v
end)
Movement:AddToggle("AntiKnockback", {Text = "防擊退", Default = true}):OnChanged(function(v)
    AntiKnockbackEnabled = v
    local root = getCharacter(LocalPlayer) and getCharacter(LocalPlayer):FindFirstChild("HumanoidRootPart")
    if root then root.CustomPhysicalProperties = v and PhysicalProperties.new(100, 0.3, 0.5) or PhysicalProperties.new(0.7, 0.3, 0.5) end
end)

-- 飛行控制
task.spawn(function()
    while true do
        if FlyEnabled then
            local char = getCharacter(LocalPlayer)
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local vel = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0, 1, 0) end
                root.Velocity = vel.Unit * FlySpeed
            end
        end
        task.wait()
    end
end)

-- 無限跳
UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local humanoid = getCharacter(LocalPlayer) and getCharacter(LocalPlayer):FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- 防擊退持續更新
task.spawn(function()
    while true do
        if AntiKnockbackEnabled then
            local root = getCharacter(LocalPlayer) and getCharacter(LocalPlayer):FindFirstChild("HumanoidRootPart")
            if root then
                root.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
            end
        end
        task.wait(1)
    end
end)

-- ==================== Skins Tab ====================
local Skins = Tabs.Skins
Skins:AddButton("隨機皮膚", {Text = "隨機皮膚", Callback = function()
    local char = getCharacter(LocalPlayer)
    if char then
        local colors = {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255), Color3.fromRGB(255,255,0), Color3.fromRGB(255,0,255)}
        local color = colors[math.random(#colors)]
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.BrickColor = BrickColor.new(color)
            end
        end
    end
    Library:Notify("隨機皮膚已套用", 3)
end})
Skins:AddToggle("RainbowSkin", {Text = "彩虹皮膚", Default = false}):OnChanged(function(v)
    if v then
        task.spawn(function()
            while Skins.RainbowSkin and Skins.RainbowSkin.Value do
                local char = getCharacter(LocalPlayer)
                if char then
                    local hue = tick() % 5 / 5
                    local color = Color3.fromHSV(hue, 1, 1)
                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            part.BrickColor = BrickColor.new(color)
                        end
                    end
                end
                task.wait(0.05)
            end
        end)
    end
end)

-- ==================== Misc Tab ====================
local Misc = Tabs.Misc
Misc:AddToggle("AutoFarm", {Text = "自動農分數", Default = false})
Misc:AddToggle("AntiAFK", {Text = "防AFK", Default = true}):OnChanged(function(v)
    if v then
        local connection = LocalPlayer.Idled:Connect(function()
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
        end)
        pcall(function()
            table.insert(Connections, connection)
        end)
    end
end)
Misc:AddButton("Server Hop", {Text = "換伺服器", Callback = function()
    Library:Notify("換服中...", 3)
    local servers = {}
    local Http = game:GetService("HttpService")
    local success, result = pcall(function()
        return Http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
    end)
    if success and result and result.data then
        for _, server in ipairs(result.data) do
            if server.playing < server.maxPlayers then
                table.insert(servers, server.id)
            end
        end
        if #servers > 0 then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)])
        end
    end
end})
Misc:AddButton("Rejoin", {Text = "重新加入", Callback = function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end})
Misc:AddButton("Unload Script", {Text = "卸載腳本", Callback = function()
    for _, drawing in pairs(ESP_Objects) do
        for _, v in pairs(drawing) do
            if type(v) == "table" then
                for _, item in ipairs(v) do
                    if item.Line then item.Line:Remove() end
                end
            elseif type(v) == "userdata" then
                pcall(function() v:Remove() end)
            end
        end
    end
    ESP_Objects = {}
    Library:Unload()
end})

-- ==================== 快捷鍵 ====================
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        Window:Toggle()
    end
end)

-- ==================== 完成提示 ====================
Library:Notify("超多功能版 已載入\n按右Shift 開關面板", 10)
