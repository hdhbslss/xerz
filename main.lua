-- language: Luau, target: Roblox Rivals (GameId 6035872082)
-- 通用：PC (YuB-X/Xeno/Solara/Volt/Wave) + Android (Delta/Arceus X Neo)
-- 每个特有能力先探测再挂；支持的自动全开，不支持的静默跳过，不砍功能。

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local HttpService      = game:GetService("HttpService")
local Camera           = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end
local isRivals = game.GameId == 6035872082

-- ============================================================
-- 特性探测
-- ============================================================
local Cap = {
    drawing    = (typeof(Drawing) == "table" and typeof(Drawing.new) == "function"),
    hook       = (typeof(hookmetamethod) == "function"),
    file       = (typeof(writefile) == "function" and typeof(readfile) == "function"),
    isfile     = (typeof(isfile) == "function"),
    makefolder = (typeof(makefolder) == "function"),
    namecall   = (typeof(getnamecallmethod) == "function"),
    queue      = (typeof(task) == "table"),
    touch      = UserInputService.TouchEnabled,
}

-- Drawing 圆环的安全包装
local fovCircle = nil
if Cap.drawing then
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1.5
        fovCircle.Color = Color3.fromRGB(0, 200, 255)
        fovCircle.Filled = false
        fovCircle.Transparency = 0.8
        fovCircle.Visible = true
    end)
end

-- ============================================================
-- PART 1 — SKIN CHANGER（hook 不可用则整段跳过，不降级）
-- ============================================================
local SkinChanger = nil
if Cap.hook and Cap.namecall and isRivals then
    SkinChanger = (function()
        local plrs, reps, http = Players, ReplicatedStorage, HttpService
        local lp = LocalPlayer
        local lps = lp:WaitForChild("PlayerScripts")
        local ctrls = lps:WaitForChild("Controllers")
        local rmods = reps:WaitForChild("Modules")

        local ok_mod, elib = pcall(function() return require(rmods:WaitForChild("EnumLibrary", 10)) end)
        if ok_mod and elib then pcall(function() elib:WaitForEnumBuilder() end) end
        local ok_c, clib = pcall(function() return require(rmods:WaitForChild("CosmeticLibrary", 10)) end)
        local ok_i, ilib = pcall(function() return require(rmods:WaitForChild("ItemLibrary", 10)) end)
        local ok_d, dctrl = pcall(function() return require(ctrls:WaitForChild("PlayerDataController", 10)) end)
        if not (ok_c and ok_i and ok_d) then return nil end
        local coss = clib.Cosmetics

        local cdata = dctrl.CurrentData
        if not cdata then
            task.spawn(function()
                repeat task.wait() until dctrl.CurrentData
                cdata = dctrl.CurrentData
            end)
        end

        local equip, favs = {}, {}
        local cwep, vprof, lwep
        local fcache = {}

        local function banned(n)
            if type(n) ~= "string" then return true end
            return n:find("MISSING_") or n:find("Bubblegum") or n:find("Ragdoll")
                or n:find("Fall Apart") or n:find("Every Finisher Ever")
        end

        local function toenum(n)
            if not elib then return nil end
            local ok, id = pcall(elib.ToEnum, elib, n)
            return ok and id or nil
        end

        local function clonecos(name, ctype, inv, favonly)
            if banned(name) then return nil end
            local base = coss[name]
            if not base then return nil end
            local d = table.clone(base)
            d.Name = name; d.Type = d.Type or ctype
            d.Seed = d.Seed or math.random(1, 1000000)
            local eid = toenum(name)
            if eid then d.Enum = eid; d.ObjectID = d.ObjectID or eid end
            if inv ~= nil then d.Inverted = inv end
            if favonly ~= nil then d.OnlyUseFavorites = favonly end
            return d
        end

        local savef = "SkinChanger/config.json"

        local function savecfg()
            if not Cap.file or not Cap.makefolder then return end
            pcall(function()
                local cfg = { equipped = {}, favorites = favs }
                for wep, cos in equip do
                    local slot = {}
                    cfg.equipped[wep] = slot
                    for ct, cd in cos do
                        if cd and cd.Name and not banned(cd.Name) then
                            slot[ct] = { name = cd.Name, seed = cd.Seed, inverted = cd.Inverted }
                        end
                    end
                end
                makefolder("SkinChanger")
                writefile(savef, http:JSONEncode(cfg))
            end)
        end

        local function loadcfg()
            if not Cap.file or not Cap.isfile or not isfile(savef) then return end
            pcall(function()
                local cfg = http:JSONDecode(readfile(savef))
                if cfg.equipped then
                    for wep, cos in cfg.equipped do
                        equip[wep] = {}
                        for ct, cd in cos do
                            if not banned(cd.name) then
                                local cl = clonecos(cd.name, ct, cd.inverted)
                                if cl then cl.Seed = cd.seed; equip[wep][ct] = cl end
                            end
                        end
                    end
                end
                favs = cfg.favorites or {}
            end)
        end

        local finv = {}
        local function rebuildinv()
            table.clear(finv)
            for name in coss do if not banned(name) then finv[name] = true end end
            for _, cos in equip do
                for _, cd in cos do
                    if cd and cd.Name and not banned(cd.Name) then finv[cd.Name] = true end
                end
            end
        end
        rebuildinv()

        local oget = dctrl.Get
        dctrl.Get = function(self, key)
            local data = oget(self, key)
            if key == "CosmeticInventory" then
                local proxy = {}
                if data then for k, v in data do if not banned(k) then proxy[k] = v end end end
                for name in finv do proxy[name] = true end
                return proxy
            end
            if key == "FavoritedCosmetics" then
                local res = data and table.clone(data) or {}
                for wep, fv in favs do
                    local slot = res[wep] or {}
                    res[wep] = slot
                    for name, isfav in fv do
                        if not banned(name) then slot[name] = isfav end
                    end
                end
                return res
            end
            return data
        end

        local ogetwep = dctrl.GetWeaponData
        dctrl.GetWeaponData = function(self, wname)
            local data = ogetwep(self, wname)
            if not data then return nil end
            local merged = table.clone(data)
            merged.Name = wname
            local weq = equip[wname]
            if weq then for ct, cd in weq do merged[ct] = cd end end
            return merged
        end

        local function saferep(key)
            pcall(function()
                if not cdata and dctrl.CurrentData then cdata = dctrl.CurrentData end
                if cdata then cdata:Replicate(key) end
            end)
        end

        local fctrl
        pcall(function() fctrl = require(ctrls:WaitForChild("FighterController", 10)) end)

        local function getewep()
            if not fctrl then return nil end
            local fighter = fctrl:GetFighter(lp)
            if not fighter or not fighter.Items then return nil end
            for _, item in fighter.Items do
                if item.IsEquipped then return item.Name end
            end
            return nil
        end

        local rems = reps:FindFirstChild("Remotes")
        local drems = rems and rems:FindFirstChild("Data")
        local eqrem = drems and drems:FindFirstChild("EquipCosmetic")
        local favrem = drems and drems:FindFirstChild("FavoriteCosmetic")
        local rrems = rems and rems:FindFirstChild("Replication")
        local frems = rrems and rrems:FindFirstChild("Fighter")
        local uirem = frems and frems:FindFirstChild("UseItem")

        if eqrem then
            local oncall
            oncall = hookmetamethod(game, "__namecall", function(self, ...)
                if getnamecallmethod() ~= "FireServer" then return oncall(self, ...) end
                local args = { ... }
                if uirem and self == uirem and fctrl then
                    pcall(function()
                        local fighter = fctrl:GetFighter(lp)
                        if fighter and fighter.Items then
                            local oid = args[1]
                            for _, item in fighter.Items do
                                if item:Get("ObjectID") == oid then lwep = item.Name; break end
                            end
                        end
                    end)
                end
                if self == eqrem then
                    local wname, ctype, cname, opts = args[1], args[2], args[3], args[4] or {}
                    if not cname or cname == "None" or cname == "" then
                        equip[wname] = equip[wname] or {}
                        equip[wname][ctype] = nil
                        if not next(equip[wname]) then equip[wname] = nil end
                        rebuildinv()
                        task.defer(function() saferep("WeaponInventory"); task.wait(0.2); savecfg() end)
                        return oncall(self, ...)
                    end
                    if banned(cname) then return oncall(self, ...) end
                    local rdata = oget(dctrl, "CosmeticInventory")
                    if rdata and type(rdata[cname]) ~= "boolean" and rdata[cname] ~= nil then
                        return oncall(self, ...)
                    end
                    equip[wname] = equip[wname] or {}
                    local cloned = clonecos(cname, ctype, opts.IsInverted, opts.OnlyUseFavorites)
                    if cloned then equip[wname][ctype] = cloned end
                    if ctype == "Finisher" then fcache[wname] = cname end
                    rebuildinv()
                    task.defer(function() saferep("WeaponInventory"); task.wait(0.2); savecfg() end)
                    return
                end
                if self == favrem then
                    local fwep, fname, fstate = args[1], args[2], args[3]
                    if not fname or fname == "None" or fname == "" then return oncall(self, ...) end
                    if banned(fname) then return oncall(self, ...) end
                    favs[fwep] = favs[fwep] or {}
                    favs[fwep][fname] = fstate or nil
                    savecfg()
                    task.spawn(saferep, "FavoritedCosmetics")
                    return
                end
                return oncall(self, ...)
            end)
        end

        local citem
        pcall(function() citem = require(lps.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)
        if citem and citem._CreateViewModel then
            local ocvm = citem._CreateViewModel
            citem._CreateViewModel = function(self, vmref)
                local wname = self.Name
                local wplr = self.ClientFighter and self.ClientFighter.Player
                cwep = (wplr == lp) and wname or nil
                if wplr == lp and equip[wname] and equip[wname].Skin and vmref then
                    local skin = equip[wname].Skin
                    local dk = self:ToEnum("Data")
                    if vmref[dk] then
                        vmref[dk][self:ToEnum("Skin")] = skin
                        vmref[dk][self:ToEnum("Name")] = skin.Name
                    elseif vmref.Data then
                        vmref.Data.Skin = skin; vmref.Data.Name = skin.Name
                    end
                end
                local res = ocvm(self, vmref); cwep = nil; return res
            end
        end

        local vmmod = lps.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
        if vmmod then
            local cvm = require(vmmod)
            if cvm.GetWrap then
                local ogw = cvm.GetWrap
                cvm.GetWrap = function(self)
                    local ci = self.ClientItem
                    local wname = ci and ci.Name
                    local wplr = ci and ci.ClientFighter and ci.ClientFighter.Player
                    local weq = wname and wplr == lp and equip[wname]
                    return (weq and weq.Wrap) or ogw(self)
                end
            end
            local onew = cvm.new
            cvm.new = function(rdata, cliitm)
                local wplr = cliitm.ClientFighter and cliitm.ClientFighter.Player
                local wname = cwep or cliitm.Name
                if wplr == lp and equip[wname] then
                    local rcls = require(reps.Modules.ReplicatedClass)
                    local dk = rcls:ToEnum("Data")
                    rdata[dk] = rdata[dk] or {}
                    local cos = equip[wname]; local slot = rdata[dk]
                    if cos.Skin  then slot[rcls:ToEnum("Skin")]  = cos.Skin  end
                    if cos.Wrap  then slot[rcls:ToEnum("Wrap")]  = cos.Wrap  end
                    if cos.Charm then slot[rcls:ToEnum("Charm")] = cos.Charm end
                end
                local res = onew(rdata, cliitm)
                if wplr == lp and equip[wname] and equip[wname].Wrap and res._UpdateWrap then
                    res:_UpdateWrap()
                    task.delay(0.1, function() if not res._destroyed then res:_UpdateWrap() end end)
                end
                return res
            end
        end

        local ogvi = ilib.GetViewModelImageFromWeaponData
        ilib.GetViewModelImageFromWeaponData = function(self, wdata, hires)
            if not wdata then return ogvi(self, wdata, hires) end
            local wname = wdata.Name
            local weq = equip[wname]
            if weq and weq.Skin and (wdata.Skin == weq.Skin or vprof == lp) then
                local sinfo = self.ViewModels[weq.Skin.Name]
                if sinfo then return sinfo[hires and "ImageHighResolution" or "Image"] or sinfo.Image end
            end
            return ogvi(self, wdata, hires)
        end

        pcall(function()
            local vpmod = require(lps.Modules.Pages.ViewProfile)
            if vpmod and vpmod.Fetch then
                local ofetch = vpmod.Fetch
                vpmod.Fetch = function(self, tplr) vprof = tplr; return ofetch(self, tplr) end
            end
        end)

        local cent
        pcall(function() cent = require(lps.Modules.ClientReplicatedClasses.ClientEntity) end)
        if cent and cent._PlayFinisher then
            local ofin = cent._PlayFinisher
            cent._PlayFinisher = function(self, fname, ...)
                local ewep = getewep()
                local tfin = ewep and (fcache[ewep] or (equip[ewep] and equip[ewep].Finisher and equip[ewep].Finisher.Name))
                return ofin(self, tfin or fname, ...)
            end
        end

        loadcfg(); rebuildinv()
        for wname, wdata in equip do
            if wdata.Finisher and wdata.Finisher.Name then fcache[wname] = wdata.Finisher.Name end
        end

        return { equip = equip, coss = coss, ilib = ilib }
    end)()
end

-- ============================================================
-- PART 2 — ATTACK SPEED
-- ============================================================
local AttackSpeed = (function()
    if not isRivals or not SkinChanger or not SkinChanger.ilib then
        return { apply = function() end, tiers = { { label = "N/A", value = -1 } } }
    end
    local Items = SkinChanger.ilib.Items
    local snap = {}
    for name, data in pairs(Items) do
        if typeof(data) == "table" then
            local s = {}
            for k, v in pairs(data) do if typeof(v) == "number" then s[k] = v end end
            snap[name] = s
        end
    end
    local tiers = {
        { label = "Off",       value = -1    },
        { label = "微快 0.15", value = 0.15  },
        { label = "快 0.05",   value = 0.05  },
        { label = "极快 0.02", value = 0.02  },
        { label = "无冷却",    value = 0.001 },
    }
    local gunEx = { ["Sniper"]=true, ["Crossbow"]=true, ["Bow"]=true, ["RPG"]=true }
    local keys = { "ShootCooldown","ShootBurstCooldown","AttackCooldown","SwingCooldown",
                   "MeleeCooldown","Cooldown","RecoveryTime","ResetTime" }
    local function apply(v)
        if v < 0 then
            for name, s in pairs(snap) do
                local d = Items[name]
                if typeof(d) == "table" then for k, val in pairs(s) do d[k] = val end end
            end
            return
        end
        for name, d in pairs(Items) do
            if typeof(d) == "table" and not gunEx[name] then
                for _, key in ipairs(keys) do
                    if d[key] then d[key] = v end
                end
            end
        end
    end
    return { apply = apply, tiers = tiers }
end)()

-- ============================================================
-- PART 3 — AIMBOT + FLY
-- ============================================================
local Config = {
    AimEnabled=true, AimKey=Enum.UserInputType.MouseButton2, FOV=120, Smooth=0.18,
    TargetPart="Head", TeamCheck=true, VisibleCheck=true,
    FlyEnabled=false, FlySpeed=60,
}

local function isAlive(p)
    local c = p.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function sameTeam(p)
    if not Config.TeamCheck then return false end
    return p.Team == LocalPlayer.Team
end
local function getPart(p)
    local c = p.Character
    if not c then return nil end
    return c:FindFirstChild(Config.TargetPart) or c:FindFirstChild("HumanoidRootPart")
end
local function visible(part)
    if not Config.VisibleCheck then return true end
    local o = Camera.CFrame.Position
    local pr = RaycastParams.new()
    pr.FilterType = Enum.RaycastFilterType.Exclude
    pr.FilterDescendantsInstances = { LocalPlayer.Character, Camera }
    local hit = Workspace:Raycast(o, part.Position - o, pr)
    if not hit then return true end
    return hit.Instance:IsDescendantOf(part.Parent)
end
local function findTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best, bd = nil, Config.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isAlive(p) and not sameTeam(p) then
            local part = getPart(p)
            if part and visible(part) then
                local sc, on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local d = (Vector2.new(sc.X, sc.Y) - center).Magnitude
                    if d < bd then bd = d; best = part end
                end
            end
        end
    end
    return best
end

local aiming = false
if Cap.touch then
    -- 移动端：用屏幕按钮触发的虚拟输入不便，改为「按住屏幕任意处」瞄准
    UserInputService.TouchStarted:Connect(function() aiming = true end)
    UserInputService.TouchEnded:Connect(function() aiming = false end)
else
    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.UserInputType == Config.AimKey then aiming = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Config.AimKey then aiming = false end
    end)
end

RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        fovCircle.Radius = Config.FOV
    end
    if not Config.AimEnabled or not aiming then return end
    local t = findTarget()
    if not t then return end
    local goal = CFrame.new(Camera.CFrame.Position, t.Position)
    Camera.CFrame = Camera.CFrame:Lerp(goal, 1 - Config.Smooth)
end)

-- Fly（BodyMover 路径；不可用则跳过，不降级逻辑）
local flyGyro, flyVel, flyConn
local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyGyro then flyGyro:Destroy(); flyGyro = nil end
    if flyVel then flyVel:Destroy(); flyVel = nil end
end
local function startFly()
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    stopFly()
    flyGyro = Instance.new("BodyGyro")
    flyGyro.P = 9e4
    flyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
    flyGyro.CFrame = hrp.CFrame
    flyGyro.Parent = hrp
    flyVel = Instance.new("BodyVelocity")
    flyVel.Velocity = Vector3.zero
    flyVel.MaxForce = Vector3.new(9e9,9e9,9e9)
    flyVel.Parent = hrp
    flyConn = RunService.Heartbeat:Connect(function()
        if not hrp.Parent then stopFly(); return end
        local camCF = Camera.CFrame
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
        -- 移动端：摇杆方向用相机相对，若 executor 不提供摇杆则只支持升降
        flyVel.Velocity = move.Magnitude > 0 and move.Unit * Config.FlySpeed or Vector3.zero
        flyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
    end)
end

-- ============================================================
-- PART 4 — 面板（GUI，跨平台都可用）
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "LunarRivals"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 470)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(18,18,22)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 34)
title.BackgroundColor3 = Color3.fromRGB(30,30,38)
title.BorderSizePixel = 0
title.Text = "  Lunar — Rivals"
title.TextColor3 = Color3.fromRGB(200,220,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local function makeToggle(text, y, getter, setter)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, -20, 0, 30)
    row.Position = UDim2.new(0, 10, 0, y)
    row.BackgroundColor3 = Color3.fromRGB(28,28,36)
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = frame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220,220,230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 36, 0, 18)
    dot.Position = UDim2.new(1, -46, 0.5, -9)
    dot.BackgroundColor3 = getter() and Color3.fromRGB(0,200,120) or Color3.fromRGB(60,60,70)
    dot.Parent = row
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    row.MouseButton1Click:Connect(function()
        setter(not getter())
        dot.BackgroundColor3 = getter() and Color3.fromRGB(0,200,120) or Color3.fromRGB(60,60,70)
    end)
end

local function makeSlider(text, y, mn, mx, getter, setter)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 46)
    row.Position = UDim2.new(0, 10, 0, y)
    row.BackgroundColor3 = Color3.fromRGB(28,28,36)
    row.BorderSizePixel = 0
    row.Parent = frame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = text..": "..tostring(math.floor(getter()))
    lbl.TextColor3 = Color3.fromRGB(220,220,230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0, 30)
    bar.BackgroundColor3 = Color3.fromRGB(50,50,60)
    bar.Parent = row
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((getter()-mn)/(mx-mn), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0,200,255)
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = mn + (mx - mn) * rel
        setter(v)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text..": "..tostring(math.floor(v))
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function makeDropdown(text, y, options, onSelect)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 40)
    row.Position = UDim2.new(0, 10, 0, y)
    row.BackgroundColor3 = Color3.fromRGB(28,28,36)
    row.BorderSizePixel = 0
    row.Parent = frame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -130, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220,220,230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 24)
    btn.Position = UDim2.new(1, -120, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    btn.TextColor3 = Color3.fromRGB(200,220,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.Text = options[1].label
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local list = Instance.new("Frame")
    list.Size = UDim2.new(0, 140, 0, #options * 24)
    list.Position = UDim2.new(1, -130, 0, y + 42)
    list.BackgroundColor3 = Color3.fromRGB(24,24,30)
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 5
    list.Parent = frame
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
    local sel = 1
    local function build()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, opt in ipairs(options) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 24)
            b.Position = UDim2.new(0, 0, 0, (i-1)*24)
            b.BackgroundColor3 = (i==sel) and Color3.fromRGB(0,200,255) or Color3.fromRGB(30,30,38)
            b.Text = opt.label
            b.TextColor3 = Color3.fromRGB(220,220,230)
            b.Font = Enum.Font.Gotham
            b.TextSize = 12
            b.ZIndex = 6
            b.Parent = list
            b.MouseButton1Click:Connect(function()
                sel = i; btn.Text = opt.label; list.Visible = false
                onSelect(opt); build()
            end)
        end
    end
    btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
    build()
end

makeToggle("Aimbot",         44, function() return Config.AimEnabled end,  function(v) Config.AimEnabled = v end)
makeToggle("Team Check",     78, function() return Config.TeamCheck end,   function(v) Config.TeamCheck = v end)
makeToggle("Visible Check", 112, function() return Config.VisibleCheck end,function(v) Config.VisibleCheck = v end)
makeSlider("FOV",           146, 20, 500, function() return Config.FOV end,    function(v) Config.FOV = v end)
makeSlider("Smooth",        196, 0, 1,    function() return Config.Smooth end, function(v) Config.Smooth = v end)
makeToggle("Fly",           246, function() return Config.FlyEnabled end,  function(v)
    Config.FlyEnabled = v
    if v then startFly() else stopFly() end
end)
makeSlider("Fly Speed",     280, 10, 200, function() return Config.FlySpeed end, function(v) Config.FlySpeed = v end)
makeDropdown("Attack Speed",330, AttackSpeed.tiers, function(opt) AttackSpeed.apply(opt.value) end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if Config.FlyEnabled then startFly() end
end)
