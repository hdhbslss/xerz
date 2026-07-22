-- === Rivals 超多功能版 (穩定版) ===
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Unnamed Enhancements 2.0",
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Skins = Window:AddTab("Skins"),
    Misc = Window:AddTab("Misc")
}

-- 服務
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

-- 狀態變數
local VoidAuto, VoidRange = true, 400
local Aimbot, SilentAim, TriggerBot, AimFOV, Smooth = true, true, true, 220, 0.2
local ESPon, Box, Name, HP, Dist, Trace, HL = true, true, true, true, true, true, true
local Fly, FlySpd = false, 220
local NoClip, InfJump, AntiKB = false, false, true
local RainbowSkinOn = false

-- 工具函式
local function getClosest(dist, fov)
    local c, s = nil, dist or 9e9
    local sc = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
            local pos, on = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if on then
                local d = (Vector2.new(pos.X,pos.Y)-sc).Magnitude
                if d < s and (not fov or d <= fov) then c, s = p, d end
            end
        end
    end
    return c
end

-- ==================== Combat ====================
local Combat = Tabs.Combat
Combat:AddToggle("VoidAuto", {Text = "虛空自動攻擊", Default = true}):OnChanged(function(v) VoidAuto = v end)
Combat:AddSlider("VoidRange", {Text = "虛空範圍", Default = 400, Min = 50, Max = 1500}):OnChanged(function(v) VoidRange = v end)
Combat:AddToggle("Aimbot", {Text = "Aimbot", Default = true}):OnChanged(function(v) Aimbot = v end)
Combat:AddToggle("SilentAim", {Text = "Silent Aim", Default = true}):OnChanged(function(v) SilentAim = v end)
Combat:AddToggle("TriggerBot", {Text = "Trigger Bot", Default = true}):OnChanged(function(v) TriggerBot = v end)
Combat:AddToggle("AutoShoot", {Text = "Auto Shoot", Default = false})
Combat:AddSlider("AimFOV", {Text = "Aim FOV", Default = 220, Min = 30, Max = 900}):OnChanged(function(v) AimFOV = v end)
Combat:AddSlider("Smoothness", {Text = "Smoothness", Default = 0.2, Min = 0.05, Max = 1}):OnChanged(function(v) Smooth = v end)

-- 虛空攻擊
task.spawn(function()
    while task.wait(0.05) do
        if VoidAuto and LP.Character then
            local r = LP.Character:FindFirstChild("HumanoidRootPart")
            if r then
                for _, p in Players:GetPlayers() do
                    if p ~= LP and p.Character then
                        local t = p.Character:FindFirstChild("HumanoidRootPart")
                        local h = p.Character:FindFirstChildOfClass("Humanoid")
                        if t and h and h.Health > 0 and (r.Position - t.Position).Magnitude <= VoidRange then
                            h:TakeDamage(10)
                        end
                    end
                end
            end
        end
    end
end)

-- Silent Aim
local old
old = hookmetamethod(game, "__index", function(s, k)
    if s == Camera and k == "CFrame" and SilentAim then
        local t = getClosest(AimFOV)
        if t and t.Character and t.Character:FindFirstChild("Head") then
            return CFrame.new(Camera.CFrame.Position, t.Character.Head.Position)
        end
    end
    return old(s, k)
end)

-- Aimbot
RunService.RenderStepped:Connect(function()
    if Aimbot and not SilentAim then
        local t = getClosest(AimFOV)
        if t and t.Character and t.Character:FindFirstChild("Head") then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, t.Character.Head.Position), Smooth)
        end
    end
end)

-- TriggerBot
task.spawn(function()
    while task.wait(0.05) do
        if TriggerBot then
            local t = getClosest(80)
            if t then
                local c = LP.Character
                local tool = c and c:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                    task.wait(0.1)
                    tool:Deactivate()
                end
            end
        end
    end
end)

-- ==================== Visuals ====================
local Visuals = Tabs.Visuals
Visuals:AddToggle("ESP", {Text = "ESP 總開關", Default = true}):OnChanged(function(v) ESPon = v end)
Visuals:AddToggle("BoxESP", {Text = "方框透視", Default = true}):OnChanged(function(v) Box = v end)
Visuals:AddToggle("NameESP", {Text = "名稱", Default = true}):OnChanged(function(v) Name = v end)
Visuals:AddToggle("HealthESP", {Text = "血量條", Default = true}):OnChanged(function(v) HP = v end)
Visuals:AddToggle("DistanceESP", {Text = "距離", Default = true}):OnChanged(function(v) Dist = v end)
Visuals:AddToggle("Tracers", {Text = "彈道線", Default = true}):OnChanged(function(v) Trace = v end)
Visuals:AddToggle("Highlight", {Text = "高亮", Default = true}):OnChanged(function(v)
    HL = v
    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character then
            local hl = p.Character:FindFirstChildOfClass("Highlight")
            if not hl and v then
                hl = Instance.new("Highlight")
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.Parent = p.Character
            elseif hl then
                hl.Enabled = v
            end
        end
    end
end)

-- ESP
local drawings = {}
task.spawn(function()
    while task.wait() do
        for _, p in Players:GetPlayers() do
            if p == LP then continue end
            local c = p.Character
            if not drawings[p] then
                local d = {}
                d.Box = Drawing.new("Square")
                d.Box.Visible = false
                d.Box.Thickness = 2
                d.Box.Filled = false
                d.Name = Drawing.new("Text")
                d.Name.Visible = false
                d.Name.Size = 13
                d.Name.Center = true
                d.Name.Outline = true
                d.HPbg = Drawing.new("Square")
                d.HPbg.Visible = false
                d.HPbg.Filled = true
                d.HPbar = Drawing.new("Square")
                d.HPbar.Visible = false
                d.HPbar.Filled = true
                d.Dist = Drawing.new("Text")
                d.Dist.Visible = false
                d.Dist.Size = 13
                d.Dist.Center = true
                d.Dist.Outline = true
                d.Tracer = Drawing.new("Line")
                d.Tracer.Visible = false
                d.Tracer.Thickness = 1
                drawings[p] = d
            end
            local d = drawings[p]
            local vis = ESPon and c and c:FindFirstChild("Head") and c:FindFirstChild("HumanoidRootPart")
            local root = vis and c.HumanoidRootPart
            local head = vis and c.Head

            if root and Box then
                local pos, on = Camera:WorldToViewportPoint(root.Position)
                if on then
                    local s = 2000 / (Camera.CFrame.Position - root.Position).Magnitude
                    d.Box.Size = Vector2.new(40 * s, 60 * s)
                    d.Box.Position = Vector2.new(pos.X - 20 * s, pos.Y - 60 * s)
                    d.Box.Visible = true
                    d.Box.Color = Color3.fromRGB(255, 255, 255)
                else d.Box.Visible = false end
            else d.Box.Visible = false end

            if head and Name then
                local pos, on = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
                if on then d.Name.Position = Vector2.new(pos.X, pos.Y); d.Name.Text = p.Name; d.Name.Visible = true else d.Name.Visible = false end
            else d.Name.Visible = false end

            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if root and HP and hum then
                local pos, on = Camera:WorldToViewportPoint(root.Position)
                if on then
                    local s = 2000 / (Camera.CFrame.Position - root.Position).Magnitude
                    local x = pos.X - 20 * s - 8
                    local y = pos.Y - 60 * s
                    local h = 60 * s * (hum.Health / hum.MaxHealth)
                    d.HPbg.Position = Vector2.new(x - 1, y - 1)
                    d.HPbg.Size = Vector2.new(4, 60 * s + 2)
                    d.HPbg.Color = Color3.fromRGB(30, 30, 30)
                    d.HPbar.Position = Vector2.new(x, y + 60 * s - h)
                    d.HPbar.Size = Vector2.new(2, h)
                    d.HPbar.Color = Color3.fromRGB(255 * (1 - hum.Health / hum.MaxHealth), 255 * (hum.Health / hum.MaxHealth), 0)
                    d.HPbg.Visible = true
                    d.HPbar.Visible = true
                else d.HPbg.Visible = false; d.HPbar.Visible = false end
            else d.HPbg.Visible = false; d.HPbar.Visible = false end

            if root and Dist then
                local pos, on = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                if on then d.Dist.Position = Vector2.new(pos.X, pos.Y); d.Dist.Text = math.floor((Camera.CFrame.Position - root.Position).Magnitude) .. "m"; d.Dist.Visible = true else d.Dist.Visible = false end
            else d.Dist.Visible = false end

            if root and Trace then
                local pos, on = Camera:WorldToViewportPoint(root.Position)
                if on then d.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y); d.Tracer.To = Vector2.new(pos.X, pos.Y); d.Tracer.Visible = true else d.Tracer.Visible = false end
            else d.Tracer.Visible = false end
        end
        for p, d in pairs(drawings) do
            if not p.Parent then
                for _, v in d do pcall(function() v:Remove() end) end
                drawings[p] = nil
            end
        end
    end
end)

-- ==================== Movement ====================
local Movement = Tabs.Movement
Movement:AddToggle("Fly", {Text = "飛行模式", Default = false}):OnChanged(function(v)
    Fly = v
    local c = LP.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if r and h then
        if v then h.PlatformStand = true else h.PlatformStand = false end
    end
end)
Movement:AddSlider("FlySpeed", {Text = "飛行速度", Default = 220, Min = 50, Max = 800}):OnChanged(function(v) FlySpd = v end)
Movement:AddSlider("WalkSpeed", {Text = "走路速度", Default = 90, Min = 16, Max = 400}):OnChanged(function(v)
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = v end
end)
Movement:AddSlider("JumpPower", {Text = "跳躍力", Default = 160, Min = 50, Max = 500}):OnChanged(function(v)
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.JumpPower = v end
end)
Movement:AddToggle("NoClip", {Text = "穿牆", Default = false}):OnChanged(function(v)
    NoClip = v
    local c = LP.Character
    if c then for _, p in c:GetDescendants() do if p:IsA("BasePart") then p.CanCollide = not v end end end
end)
Movement:AddToggle("InfiniteJump", {Text = "無限跳", Default = false}):OnChanged(function(v) InfJump = v end)
Movement:AddToggle("AntiKnockback", {Text = "防擊退", Default = true}):OnChanged(function(v) AntiKB = v end)

task.spawn(function()
    while task.wait() do
        if Fly then
            local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local vel = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then vel = vel + Camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then vel = vel - Camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then vel = vel - Camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then vel = vel + Camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, 1, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0, 1, 0) end
                r.Velocity = vel.Unit * FlySpd
            end
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if InfJump then
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if AntiKB then
            local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if r then r.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5) end
        end
    end
end)

-- ==================== Skins ====================
local Skins = Tabs.Skins
Skins:AddButton("RandomSkin", {Text = "隨機皮膚", Callback = function()
    local c = LP.Character
    if c then
        local col = Color3.fromRGB(math.random(255), math.random(255), math.random(255))
        for _, p in c:GetChildren() do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.BrickColor = BrickColor.new(col)
            end
        end
    end
    Library:Notify("已套用隨機皮膚", 2)
end})

Skins:AddToggle("RainbowSkin", {Text = "彩虹皮膚", Default = false}):OnChanged(function(v)
    RainbowSkinOn = v
    if v then
        task.spawn(function()
            while RainbowSkinOn do
                local c = LP.Character
                if c then
                    local col = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                    for _, p in c:GetChildren() do
                        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                            p.BrickColor = BrickColor.new(col)
                        end
                    end
                end
                task.wait(0.05)
            end
        end)
    end
end})

-- ==================== Misc ====================
local Misc = Tabs.Misc
Misc:AddToggle("AutoFarm", {Text = "自動農分數", Default = false})
Misc:AddToggle("AntiAFK", {Text = "防AFK", Default = true}):OnChanged(function(v)
    if v then
        LP.Idled:Connect(function()
            game:GetService("VirtualUser"):Button2Down(Vector2.new(), Camera.CFrame)
            task.wait(1)
            game:GetService("VirtualUser"):Button2Up(Vector2.new(), Camera.CFrame)
        end)
    end
end)
Misc:AddButton("ServerHop", {Text = "換伺服器", Callback = function()
    Library:Notify("正在尋找伺服器...", 3)
    local ok, s = pcall(function()
        return game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
    end)
    if ok and s and s.data then
        local ids = {}
        for _, v in s.data do
            if v.playing < v.maxPlayers then table.insert(ids, v.id) end
        end
        if #ids > 0 then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, ids[math.random(#ids)])
        else
            Library:Notify("沒有可用伺服器", 3)
        end
    end
end})
Misc:AddButton("Rejoin", {Text = "重新加入", Callback = function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end})
Misc:AddButton("Unload", {Text = "卸載腳本", Callback = function()
    for _, d in pairs(drawings) do
        for _, v in d do pcall(function() v:Remove() end) end
    end
    drawings = {}
    Library:Unload()
end})

-- ==================== 快捷鍵 ====================
UIS.InputBegan:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.RightShift then Window:Toggle() end
end)

Library:Notify("超多功能版 已載入 | 右Shift 開關面板", 5)
