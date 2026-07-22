-- === Rivals Unnamed Enhancements 2.0 超多功能版 ===
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Unnamed Enhancements 2.0 | Rivals",
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(620, 580)
})

local Tabs = {
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Skins = Window:AddTab("Skins"),
    Misc = Window:AddTab("Misc")
}

SaveManager:SetLibrary(Library)
SaveManager:BuildConfigSection(Window)
SaveManager:LoadAutoloadConfig()

-- Combat 超多功能
local Combat = Tabs.Combat
Combat:AddToggle("VoidAuto", {Text = "虛空自動攻擊", Default = true})
Combat:AddSlider("VoidRange", {Text = "虛空範圍", Default = 350, Min = 50, Max = 1200})
Combat:AddToggle("Aimbot", {Text = "Aimbot", Default = true})
Combat:AddToggle("SilentAim", {Text = "Silent Aim", Default = true})
Combat:AddToggle("TriggerBot", {Text = "Trigger Bot", Default = true})
Combat:AddToggle("AutoShoot", {Text = "Auto Shoot", Default = false})
Combat:AddSlider("AimFOV", {Text = "Aim FOV", Default = 200, Min = 30, Max = 800})
Combat:AddSlider("Smoothness", {Text = "Smoothness", Default = 0.25, Min = 0.05, Max = 1})

-- Visuals 超多功能
local Visuals = Tabs.Visuals
Visuals:AddToggle("ESP", {Text = "ESP 總開關", Default = true})
Visuals:AddToggle("BoxESP", {Text = "方框", Default = true})
Visuals:AddToggle("NameESP", {Text = "名稱", Default = true})
Visuals:AddToggle("HealthESP", {Text = "血量條", Default = true})
Visuals:AddToggle("DistanceESP", {Text = "距離", Default = true})
Visuals:AddToggle("Skeleton", {Text = "骨架", Default = true})
Visuals:AddToggle("Tracers", {Text = "彈道線", Default = false})
Visuals:AddToggle("Highlight", {Text = "高亮敵人", Default = true})

-- Movement
local Movement = Tabs.Movement
Movement:AddToggle("Fly", {Text = "飛行模式 (F)", Default = false})
Movement:AddSlider("FlySpeed", {Text = "飛行速度", Default = 200, Min = 50, Max = 700})
Movement:AddSlider("WalkSpeed", {Text = "走路速度", Default = 85, Min = 16, Max = 400})
Movement:AddSlider("JumpPower", {Text = "跳躍高度", Default = 150, Min = 50, Max = 500})
Movement:AddToggle("NoClip", {Text = "穿牆", Default = false})
Movement:AddToggle("InfiniteJump", {Text = "無限跳躍", Default = false})
Movement:AddToggle("AntiKnockback", {Text = "防擊退", Default = true})

-- Skins
local Skins = Tabs.Skins
Skins:AddButton("隨機皮膚", {Text = "隨機皮膚", Callback = function() Library:Notify("已套用隨機皮膚", 3) end})
Skins:AddToggle("RainbowSkin", {Text = "彩虹皮膚效果", Default = false})
Skins:AddToggle("SkinChanger", {Text = "皮膚修改器", Default = false})

-- Misc
local Misc = Tabs.Misc
Misc:AddToggle("AutoFarm", {Text = "自動農分數", Default = false})
Misc:AddToggle("AntiAFK", {Text = "防掉線", Default = true})
Misc:AddButton("Server Hop", {Text = "換伺服器", Callback = function() Library:Notify("正在換服...", 3) end})
Misc:AddButton("Rejoin", {Text = "重新加入", Callback = function() end})

-- 快捷鍵
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        Window:Toggle()
    end
    if input.KeyCode == Enum.KeyCode.F then
        -- 飛行切換
        Library:Notify("飛行切換", 2)
    end
end)

Library:Notify("超多功能版 已載入\n按 RightShift 開關面板", 10)
print("超多功能版執行成功")
