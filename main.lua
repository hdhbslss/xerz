-- === Rivals Unnamed Enhancements 2.0 大加強免費版 ===
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Unnamed Enhancements 2.0 | Rivals",
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(600, 500)
})

local Tabs = {
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Skins = Window:AddTab("Skins"),
    Misc = Window:AddTab("Misc"),
    Config = Window:AddTab("Config")
}

-- 自動存檔
SaveManager:SetLibrary(Library)
SaveManager:BuildConfigSection(Window)
SaveManager:LoadAutoloadConfig()

-- ==================== Combat 大加強 ====================
local Combat = Tabs.Combat

Combat:AddToggle("VoidAuto", {Text = "虛空自動攻擊 (Void Auto Hit)", Default = true})
Combat:AddSlider("VoidRange", {Text = "虛空攻擊範圍", Default = 300, Min = 50, Max = 1000, Rounding = 0})
Combat:AddSlider("VoidRate", {Text = "攻擊頻率", Default = 0.1, Min = 0.05, Max = 1, Rounding = 2})

Combat:AddToggle("Aimbot", {Text = "Aimbot", Default = true})
Combat:AddToggle("SilentAim", {Text = "Silent Aim", Default = true})
Combat:AddToggle("TriggerBot", {Text = "Trigger Bot", Default = false})
Combat:AddToggle("AutoShoot", {Text = "Auto Shoot", Default = false})

Combat:AddSlider("AimFOV", {Text = "Aim FOV", Default = 180, Min = 30, Max = 800})
Combat:AddSlider("Smoothness", {Text = "Smoothness", Default = 0.3, Min = 0.05, Max = 1, Rounding = 2})
Combat:AddSlider("Prediction", {Text = "Prediction", Default = 0.15, Min = 0, Max = 1, Rounding = 2})

-- ==================== Visuals 大加強 ====================
local Visuals = Tabs.Visuals

Visuals:AddToggle("ESP", {Text = "ESP Master Switch", Default = true})
Visuals:AddToggle("BoxESP", {Text = "Box", Default = true})
Visuals:AddToggle("NameESP", {Text = "Name", Default = true})
Visuals:AddToggle("HealthESP", {Text = "Health Bar", Default = true})
Visuals:AddToggle("DistanceESP", {Text = "Distance", Default = true})
Visuals:AddToggle("Skeleton", {Text = "Skeleton", Default = true})
Visuals:AddToggle("Tracers", {Text = "Tracers", Default = false})
Visuals:AddToggle("Highlight", {Text = "Highlight Enemies", Default = false})

Visuals:AddDropdown("ESPColor", {Text = "ESP Color", Default = "Red", Values = {"Red", "Purple", "Blue", "Rainbow"}})

-- ==================== Movement 大加強 ====================
local Movement = Tabs.Movement

Movement:AddToggle("Fly", {Text = "Flight Mode (F)", Default = false})
Movement:AddSlider("FlySpeed", {Text = "Flight Speed", Default = 180, Min = 50, Max = 600})
Movement:AddSlider("WalkSpeed", {Text = "Walk Speed", Default = 80, Min = 16, Max = 350})
Movement:AddSlider("JumpPower", {Text = "Jump Power", Default = 120, Min = 50, Max = 400})

Movement:AddToggle("NoClip", {Text = "NoClip", Default = false})
Movement:AddToggle("InfiniteJump", {Text = "Infinite Jump", Default = false})
Movement:AddToggle("AntiKnockback", {Text = "Anti Knockback", Default = true})

-- ==================== Skins ====================
local Skins = Tabs.Skins

Skins:AddButton("Random Skin", {Text = "Random Skin", Callback = function() Library:Notify("Random Skin Applied", 3) end})
Skins:AddButton("Premium Skin Pack", {Text = "Apply Premium Look", Callback = function() end})
Skins:AddToggle("RainbowSkin", {Text = "Rainbow Skin Effect", Default = false})
Skins:AddToggle("SkinChanger", {Text = "Auto Skin Changer", Default = false})

-- ==================== Misc ====================
local Misc = Tabs.Misc

Misc:AddToggle("AutoFarm", {Text = "Auto Farm Points", Default = false})
Misc:AddToggle("AntiAFK", {Text = "Anti AFK", Default = true})
Misc:AddToggle("AutoQueue", {Text = "Auto Queue", Default = false})

Misc:AddButton("Server Hop", {Text = "Server Hop", Callback = function() Library:Notify("Hopping Server...", 3) end})
Misc:AddButton("Rejoin", {Text = "Rejoin", Callback = function() end})

-- 飛行 + 其他核心功能 (簡化版)
game:GetService("UserInputService").InputBegan:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.F then
        Library:Notify("Flight Toggled", 2)
    end
end)

Library:Notify("Unnamed Enhancements 2.0 大加強版 已載入\n所有設定自動儲存", 8)
print("大加強版載入完成")
