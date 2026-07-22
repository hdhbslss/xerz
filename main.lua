-- === Rivals Opiumware 優化版 ===
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Unnamed Enhancements 2.0 | Opiumware",
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

SaveManager:SetLibrary(Library)
SaveManager:BuildConfigSection(Window)
SaveManager:LoadAutoloadConfig()

-- Combat
local Combat = Tabs.Combat
Combat:AddToggle("VoidAuto", {Text = "虛空自動攻擊", Default = true})
Combat:AddToggle("Aimbot", {Text = "Aimbot", Default = true})
Combat:AddToggle("SilentAim", {Text = "Silent Aim", Default = true})
Combat:AddSlider("AimFOV", {Text = "Aim FOV", Default = 180, Min = 30, Max = 800})

-- Visuals
local Visuals = Tabs.Visuals
Visuals:AddToggle("ESP", {Text = "ESP 透視", Default = true})
Visuals:AddToggle("Box", {Text = "方框", Default = true})
Visuals:AddToggle("Name", {Text = "名稱", Default = true})

-- Movement
local Movement = Tabs.Movement
Movement:AddToggle("Fly", {Text = "飛行 (F)", Default = false})
Movement:AddSlider("FlySpeed", {Text = "飛行速度", Default = 200, Min = 50, Max = 600})

-- Misc
local Misc = Tabs.Misc
Misc:AddToggle("AutoFarm", {Text = "自動農分", Default = false})

-- 快捷鍵
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        Window:Toggle()
    end
end)

Library:Notify("Opiumware 版本 已載入\n按右Shift 開面板", 8)
