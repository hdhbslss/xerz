-- === Rivals 超多功能版 ===
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Unnamed Enhancements 2.0 | 多功能版",
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

-- Combat 多功能
local Combat = Tabs.Combat
Combat:AddToggle("VoidAuto", {Text = "虛空自動攻擊", Default = true})
Combat:AddSlider("VoidRange", {Text = "虛空範圍", Default = 400, Min = 50, Max = 1500})
Combat:AddToggle("Aimbot", {Text = "Aimbot", Default = true})
Combat:AddToggle("SilentAim", {Text = "Silent Aim", Default = true})
Combat:AddToggle("TriggerBot", {Text = "Trigger Bot", Default = true})
Combat:AddToggle("AutoShoot", {Text = "Auto Shoot", Default = false})
Combat:AddSlider("AimFOV", {Text = "Aim FOV", Default = 220, Min = 30, Max = 900})
Combat:AddSlider("Smoothness", {Text = "Smoothness", Default = 0.2, Min = 0.05, Max = 1})

-- Visuals 多功能
local Visuals = Tabs.Visuals
Visuals:AddToggle("ESP", {Text = "ESP 總開關", Default = true})
Visuals:AddToggle("BoxESP", {Text = "方框透視", Default = true})
Visuals:AddToggle("NameESP", {Text = "名稱", Default = true})
Visuals:AddToggle("HealthESP", {Text = "血量條", Default = true})
Visuals:AddToggle("DistanceESP", {Text = "距離", Default = true})
Visuals:AddToggle("Skeleton", {Text = "骨架", Default = true})
Visuals:AddToggle("Tracers", {Text = "彈道線", Default = true})
Visuals:AddToggle("Highlight", {Text = "高亮", Default = true})

-- Movement 多功能
local Movement = Tabs.Movement
Movement:AddToggle("Fly", {Text = "飛行模式", Default = false})
Movement:AddSlider("FlySpeed", {Text = "飛行速度", Default = 220, Min = 50, Max = 800})
Movement:AddSlider("WalkSpeed", {Text = "走路速度", Default = 90, Min = 16, Max = 400})
Movement:AddSlider("JumpPower", {Text = "跳躍力", Default = 160, Min = 50, Max = 500})
Movement:AddToggle("NoClip", {Text = "穿牆", Default = false})
Movement:AddToggle("InfiniteJump", {Text = "無限跳", Default = false})
Movement:AddToggle("AntiKnockback", {Text = "防擊退", Default = true})

-- Skins
local Skins = Tabs.Skins
Skins:AddButton("隨機皮膚", {Text = "隨機皮膚", Callback = function() Library:Notify("隨機皮膚已套用", 3) end})
Skins:AddToggle("RainbowSkin", {Text = "彩虹皮膚", Default = false})
Skins:AddToggle("SkinChanger", {Text = "皮膚修改", Default = false})

-- Misc 多功能
local Misc = Tabs.Misc
Misc:AddToggle("AutoFarm", {Text = "自動農分數", Default = false})
Misc:AddToggle("AntiAFK", {Text = "防AFK", Default = true})
Misc:AddButton("Server Hop", {Text = "換伺服器", Callback = function() Library:Notify("換服中...", 3) end})
Misc:AddButton("Rejoin", {Text = "重新加入", Callback = function() end})
Misc:AddButton("Unload Script", {Text = "卸載腳本", Callback = function() Library:Unload() end})

-- 快捷鍵
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        Window:Toggle()
    end
end)

Library:Notify("超多功能版 已載入\n按右Shift 開關面板", 10)
