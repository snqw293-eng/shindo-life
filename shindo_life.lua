local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local VIM = game:GetService("VirtualInputManager")
local plr = game:GetService("Players").LocalPlayer
local WS = workspace
local vu = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")

local s = {}
local statNames = {"Health","Chakra","Strength","Defense","Speed","Tai","Nin","Gen"}
local mobCache = {}
local mobCacheT = 0
local statRemote
local combatRemote

local function gc() return plr.Character end
local function ghr()
    local c = gc()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function ghm()
    local c = gc()
    return c and c:FindFirstChildWhichIsA("Humanoid")
end

-- find combat remote dynamically
local function findCombat()
    if combatRemote then return combatRemote end
    local c = gc()
    if c then
        local comb = c:FindFirstChild("combat")
        if comb then
            combatRemote = comb:FindFirstChild("update")
            if combatRemote then return combatRemote end
        end
    end
    for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("RemoteEvent") and (v.Name:lower():find("combat") or v.Name:lower():find("attack") or v.Name:lower():find("damage")) then
            combatRemote = v; return v
        end
    end
end

local function atk()
    local r = findCombat()
    if r then
        for i = 1, 3 do
            pcall(function() r:FireServer("mouse1", true) end)
            pcall(function() r:FireServer("MouseClick", true) end)
            pcall(function() r:FireServer("Attack") end)
            pcall(function() r:FireServer(true) end)
            task.wait(0.02)
            pcall(function() r:FireServer("mouse1", false) end)
            task.wait(0.02)
        end
    end
    pcall(mouse1press)
    task.wait(0.03)
    pcall(mouse1release)
    pcall(function() VIM:SendMouseButtonEvent(0, 0, true, nil, 0) end)
    task.wait(0.03)
    pcall(function() VIM:SendMouseButtonEvent(0, 0, false, nil, 0) end)
end

-- mob finder
local function getMobs(r)
    local t = time()
    if t - mobCacheT < 0.15 and mobCache.r == r then return mobCache.d end
    local h = ghr(); if not h then return {} end
    local hp = h.Position; local out = {}
    local npc = WS:FindFirstChild("npc") or WS:FindFirstChild("NPCs")
    if npc then
        for _, v in pairs(npc:GetChildren()) do
            if v:IsA("Model") and v ~= gc() then
                local vh = v:FindFirstChild("HumanoidRootPart")
                local vm = v:FindFirstChildWhichIsA("Humanoid")
                if vh and vm and vm.Health > 0 and (vh.Position - hp).Magnitude <= (r or 300) then
                    table.insert(out, {m = v, hrp = vh, hum = vm})
                end
            end
        end
    end
    mobCache = {d = out, r = r}; mobCacheT = t
    return out
end

local function getBosses(r)
    local h = ghr(); if not h then return {} end
    local out = {}; local hp = h.Position
    local npc = WS:FindFirstChild("npc")
    if npc then
        for _, v in pairs(npc:GetChildren()) do
            if v:IsA("Model") then
                local vh = v:FindFirstChild("HumanoidRootPart")
                local vm = v:FindFirstChildWhichIsA("Humanoid")
                if vh and vm and vm.Health > 0 then
                    local nb = v.Name:lower() == "npc1" or v.Name:lower():find("boss") or vm.MaxHealth > 5000
                    if nb and (vh.Position - hp).Magnitude <= (r or 500) then
                        table.insert(out, {m = v, hrp = vh, hum = vm})
                    end
                end
            end
        end
    end
    return out
end

local function getDrops(r)
    local h = ghr(); if not h then return {} end
    local hp = h.Position; local out = {}
    for _, v in pairs(WS:GetChildren()) do
        local cd = v:FindFirstChildWhichIsA("ClickDetector")
        if cd then
            local pos = v:IsA("BasePart") and v.Position or (v:IsA("Model") and (v.PrimaryPart or v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")) and (v.PrimaryPart or v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")).Position)
            if pos and (pos - hp).Magnitude <= (r or 100) then
                table.insert(out, {m = v, pos = pos, cd = cd})
            end
        end
    end
    local gt = WS:FindFirstChild("GLOBALTIME")
    if gt then
        for _, v in pairs(gt:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("sh") then
                local sh = v.sh; local inv = sh:FindFirstChild("invoke")
                local cd = sh:FindFirstChildWhichIsA("ClickDetector")
                if (inv or cd) and (sh.Position - hp).Magnitude <= (r or 500) then
                    table.insert(out, {m = v, pos = sh.Position, inv = inv, cd = cd})
                end
            end
        end
    end
    return out
end

local function killM(m)
    if not m or not m.hrp or not m.hum then return end
    local h = ghr()
    if h then h.CFrame = CFrame.new(m.hrp.Position + Vector3.new(0,3,0), m.hrp.Position) end
    atk()
    m.hum.Health = 0
    pcall(function() m.hum.HealthChanged:Connect(function() if m.hum and m.hum.Health > 0 then m.hum.Health = 0 end end) end)
end

-- toggle helpers
local st = {}
local function tog(name, fn)
    st[name] = false
    local con = nil
    return function(on)
        st[name] = on
        if con then con:Disconnect(); con = nil end
        if not on then return end
        con = RS.Heartbeat:Connect(function()
            if not st[name] then con:Disconnect(); con = nil; return end
            fn()
            task.wait(0.1)
        end)
    end
end

-- features
local togGod = tog("god", function()
    local m = ghm()
    if m and m.Health < m.MaxHealth then m.Health = m.MaxHealth end
    task.wait(0.05)
end)

local togKill = tog("kill", function()
    local mobs = getMobs(s.killRad or 200)
    if #mobs > 0 then killM(mobs[1]) end
end)

local togFarm = (function()
    local con; local phase = "quest"; local timer = 0
    return function(on)
        if con then con:Disconnect(); con = nil end
        if not on then s.farm = false; return end
        s.farm = true; phase = "quest"; timer = 0
        if not s.god then togGod(true) end
        con = RS.Heartbeat:Connect(function()
            if not s.farm then con:Disconnect(); con = nil; return end
            local h = ghr(); if not h then return end
            timer = timer + 1
            if phase == "quest" then
                local mgs = WS:FindFirstChild("missiongivers")
                if mgs then
                    for _, v in pairs(mgs:GetChildren()) do
                        if v:IsA("Model") and v.Name == "" and v:FindFirstChild("Head") and v.Head:FindFirstChild("givemission") and v.Head.givemission.Enabled then
                            local ci = v.Head.givemission:FindFirstChild("color")
                            if ci and ci.Image:find("5459241648") then
                                local mgp = v:FindFirstChild("HumanoidRootPart")
                                local ct = v:FindFirstChild("CLIENTTALK")
                                if mgp and ct then
                                    h.CFrame = CFrame.new(mgp.Position + Vector3.new(0,5,0))
                                    ct:FireServer(); task.wait(0.1); ct:FireServer("accept")
                                    phase = "accepting"; timer = 0; break
                                end
                            end
                        end
                    end
                end
            elseif phase == "accepting" then
                local ms = plr.PlayerGui:FindFirstChild("Main") and plr.PlayerGui.Main:FindFirstChild("ingame") and plr.PlayerGui.Main.ingame:FindFirstChild("Missionstory")
                if ms and ms.Visible then phase = "kill"; timer = 0
                elseif timer > 60 then phase = "quest"; timer = 0 end
            elseif phase == "kill" then
                local qm = getMobs(s.farmRad or 150)
                if #qm > 0 then
                    killM(qm[1])
                elseif timer > 600 then
                    local mgs = WS:FindFirstChild("missiongivers")
                    if mgs then
                        local mg = mgs:FindFirstChildWhichIsA("Model")
                        if mg then
                            local mgp = mg:FindFirstChild("HumanoidRootPart")
                            if mgp then h.CFrame = CFrame.new(mgp.Position + Vector3.new(0,5,0)) end
                        end
                    end
                    phase = "quest"; timer = 0
                end
                local ms = plr.PlayerGui:FindFirstChild("Main") and plr.PlayerGui.Main:FindFirstChild("ingame") and plr.PlayerGui.Main.ingame:FindFirstChild("Missionstory")
                if ms and not ms.Visible then phase = "quest"; timer = 0 end
            end
            task.wait(0.12)
        end)
    end
end)()

local togBoss = tog("boss", function()
    local bs = getBosses(s.bossRad or 500)
    if #bs > 0 then killM(bs[1]) end
    task.wait(0.15)
end)

local togLoot = tog("loot", function()
    local h = ghr(); if not h then return end
    for _, d in pairs(getDrops(s.lootRad or 100)) do
        h.CFrame = CFrame.new(d.pos + Vector3.new(0,3,0)); task.wait(0.05)
        if d.inv then pcall(function() d.inv:FireServer(plr) end) end
        if d.cd then pcall(function() fireclickdetector(d.cd) end) end
    end
    task.wait(0.3)
end)

local togRank = tog("rank", function()
    local lvl = plr.statz and plr.statz.lvl and plr.statz.lvl.lvl
    local se = plr:FindFirstChild("startevent")
    if lvl and lvl.Value >= 1000 and se then
        local pres = plr.statz and plr.statz.prestige
        if pres and (pres.maxlvlpres.Value >= 1 or (pres.rank.Value == "Z" and pres.number.Value == "3")) then
            se:FireServer("maxlvlpres")
        else
            se:FireServer("rankup")
        end
    end
    task.wait(2)
end)

local togStat = tog("autoStat", function()
    if not statRemote then
        for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name:lower():find("stat") then statRemote = v; break end
        end
    end
    if not statRemote then return end
    local pts = 0
    local st = plr:FindFirstChild("statz")
    if st then
        for _, v in pairs(st:GetDescendants()) do
            if (v:IsA("NumberValue") or v:IsA("IntValue")) and (v.Name:lower():find("point") or v.Name:lower():find("sp") or v.Name == "Points") then
                pts = v.Value; break end
        end
    end
    if pts and pts > 0 then
        local per = math.max(1, math.floor(pts / #statNames))
        for _, n in ipairs(statNames) do
            pcall(function() statRemote:FireServer(n, per) end) task.wait(0.02)
        end
        pcall(function() statRemote:FireServer("All", pts) end)
    end
    task.wait(1)
end)

local togSkill = tog("skill", function()
    if #getMobs(200) > 0 then
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.One, false, nil) end) task.wait(0.05)
        pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.One, false, nil) end) task.wait(0.05)
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Two, false, nil) end) task.wait(0.05)
        pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.Two, false, nil) end)
    end
    task.wait(0.5)
end)

local togDodge = tog("dodge", function()
    local m = ghm()
    if m and m.Health < m.MaxHealth * 0.6 then
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Q, false, nil) end) task.wait(0.05)
        pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.Q, false, nil) end)
        m.Health = m.MaxHealth
    end
    task.wait(0.3)
end)

local togAfk = (function()
    local con
    return function(on)
        s.afk = on
        if con then con:Disconnect(); con = nil end
        if on then con = plr.Idled:Connect(function() vu:CaptureController(); vu:ClickButton2(Vector2.new()) end) end
    end
end)()

local togSpinB = tog("spinB", function()
    local sp = plr.statz and plr.statz.spins and plr.statz.spins.Value
    local se = plr:FindFirstChild("startevent")
    if se and sp and sp > 0 then
        pcall(function() se:FireServer("spin", "kg1") end) task.wait(0.3)
        pcall(function() se:FireServer("spin", "kg2") end) task.wait(0.3)
    end
end)

local togSpinE = tog("spinE", function()
    local sp = plr.statz and plr.statz.spins and plr.statz.spins.Value
    local se = plr:FindFirstChild("startevent")
    if se and sp and sp > 0 then
        pcall(function() se:FireServer("spin", "element1") end) task.wait(0.3)
        pcall(function() se:FireServer("spin", "element2") end) task.wait(0.3)
    end
end)

local togBuy = tog("buy", function()
    for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and (v.Name:lower():find("buy") or v.Name:lower():find("shop") or v.Name:lower():find("purchase")) then
            pcall(function() v:FireServer("Buy", "Element") end)
            pcall(function() v:FireServer("Buy", "Ability") end)
            pcall(function() v:InvokeServer("BuyAll") end)
        end
    end
    task.wait(3)
end)

-- fly
local fBody, fGyro, flyCon
function togFly(on)
    s.fly = on; if flyCon then flyCon:Disconnect(); flyCon = nil end
    local h = ghr()
    if on and h then
        pcall(function() if fBody then fBody:Destroy() end end)
        fBody = Instance.new("BodyVelocity"); fBody.Name = "F"; fBody.MaxForce = Vector3.new(9e9,9e9,9e9); fBody.P = 1e4; fBody.Parent = h
        pcall(function() if fGyro then fGyro:Destroy() end end)
        fGyro = Instance.new("BodyGyro"); fGyro.Name = "G"; fGyro.MaxTorque = Vector3.new(9e9,9e9,9e9); fGyro.P = 1e4; fGyro.D = 100; fGyro.Parent = h
        local m = ghm(); if m then m.PlatformStand = true end
        flyCon = RS.RenderStepped:Connect(function()
            if not s.fly then if flyCon then flyCon:Disconnect(); flyCon = nil end; return end
            local hrp = ghr(); if not hrp or not fBody then return end
            local d = Vector3.new(); local c = WS.CurrentCamera
            if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + c.CFrame.LookVector * Vector3.new(1,0,1) end
            if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - c.CFrame.LookVector * Vector3.new(1,0,1) end
            if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - c.CFrame.RightVector * Vector3.new(1,0,1) end
            if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + c.CFrame.RightVector * Vector3.new(1,0,1) end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0,1,0) end
            local spd = s.flySpd or 75
            if d.Magnitude > 0 then d = d.Unit * spd end
            fBody.Velocity = d
            if fGyro then fGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + c.CFrame.LookVector * Vector3.new(1,0,1)) end
        end)
    else
        pcall(function() if fBody then fBody:Destroy() end end); fBody = nil
        pcall(function() if fGyro then fGyro:Destroy() end end); fGyro = nil
        local m = ghm(); if m then m.PlatformStand = false end
    end
end

-- speed
local spdCon
function togSpeed(on)
    s.spd = on; if spdCon then spdCon:Disconnect(); spdCon = nil end
    if not on then local m = ghm(); if m then m.WalkSpeed = 16 end; return end
    spdCon = RS.Heartbeat:Connect(function()
        if not s.spd then spdCon:Disconnect(); spdCon = nil; return end
        local m = ghm(); if m then m.WalkSpeed = s.spdAmt or 50 end
        task.wait(0.1)
    end)
end

-- inf jump
UIS.JumpRequest:Connect(function() if s.infJ then local m = ghm(); if m then m:ChangeState(Enum.HumanoidStateType.Jumping) end end end)

-- aimbot
local aimCon
function togAim(on)
    s.aim = on; if aimCon then aimCon:Disconnect(); aimCon = nil end
    if not on then return end
    aimCon = RS.RenderStepped:Connect(function()
        if not s.aim then aimCon:Disconnect(); aimCon = nil; return end
        local mobs = getMobs(s.aimRad or 300)
        if #mobs > 0 then
            local h = ghr()
            if h then
                h.CFrame = CFrame.new(h.Position, Vector3.new(mobs[1].hrp.Position.X, h.Position.Y, mobs[1].hrp.Position.Z))
                if s.aimAtk then atk() end
            end
        end
        task.wait(0.03)
    end)
end

-- esp
local espObjs = {}; local espAddCon
function togESP(on)
    s.esp = on
    if not on then
        for _, v in pairs(espObjs) do pcall(function() v:Destroy() end) end; espObjs = {}
        if espAddCon then espAddCon:Disconnect(); espAddCon = nil end; return
    end
    for _, v in pairs(WS:GetChildren()) do
        if v:IsA("Model") and v ~= gc() and v:FindFirstChild("Humanoid") then
            local hl = Instance.new("Highlight"); hl.FillColor = Color3.fromRGB(255,50,50); hl.FillTransparency = 0.5; hl.OutlineColor = Color3.fromRGB(255,255,255); hl.Parent = v
            table.insert(espObjs, hl)
        end
    end
    espAddCon = WS.ChildAdded:Connect(function(v)
        task.wait(0.5)
        if s.esp and v:IsA("Model") and v ~= gc() and v:FindFirstChild("Humanoid") then
            local hl = Instance.new("Highlight"); hl.FillColor = Color3.fromRGB(255,50,50); hl.FillTransparency = 0.5; hl.OutlineColor = Color3.fromRGB(255,255,255); hl.Parent = v
            table.insert(espObjs, hl)
        end
    end)
end

-- UI
local gui = Instance.new("ScreenGui"); gui.Name = "SnqwSH"; gui.ResetOnSpawn = false; gui.Parent = plr:WaitForChild("PlayerGui")
local bg = Instance.new("Frame"); bg.Size = UDim2.new(0,560,0,480); bg.Position = UDim2.new(0.5,-280,0.5,-240); bg.BackgroundColor3 = Color3.fromRGB(10,10,10); bg.BorderSizePixel = 0; bg.Active = true; bg.Draggable = true; bg.Parent = gui
Instance.new("UICorner", bg).CornerRadius = UDim.new(0,8)
local title = Instance.new("TextLabel", bg); title.Size = UDim2.new(1,0,0,40); title.BackgroundColor3 = Color3.fromRGB(15,15,15); title.BorderSizePixel = 0; title.Text = "SNQW .0GH"; title.TextColor3 = Color3.fromRGB(200,200,200); title.TextSize = 18; title.Font = Enum.Font.GothamBold
Instance.new("UICorner", title).CornerRadius = UDim.new(0,8)
local side = Instance.new("Frame", bg); side.Size = UDim2.new(0,150,1,-66); side.Position = UDim2.new(0,6,0,64); side.BackgroundColor3 = Color3.fromRGB(14,14,14); side.BorderSizePixel = 0
Instance.new("UICorner", side).CornerRadius = UDim.new(0,6)
local ctBg = Instance.new("Frame", bg); ctBg.Size = UDim2.new(1,-170,1,-78); ctBg.Position = UDim2.new(0,164,0,72); ctBg.BackgroundColor3 = Color3.fromRGB(12,12,12); ctBg.BorderSizePixel = 0
Instance.new("UICorner", ctBg).CornerRadius = UDim.new(0,6)
Instance.new("UIListLayout", side).Padding = UDim.new(0,3)
local btns = {}; local conts = {}
for i, n in ipairs({"COMBAT","FARM","MOVE","AIM","VISUAL","AUTO","MISC"}) do
    local b = Instance.new("TextButton", side); b.Size = UDim2.new(1,-6,0,28); b.BackgroundColor3 = i==1 and Color3.fromRGB(25,25,25) or Color3.fromRGB(15,15,15); b.BorderSizePixel = 0; b.Text = n; b.TextColor3 = i==1 and Color3.fromRGB(255,255,255) or Color3.fromRGB(130,130,130); b.TextSize = 10; b.Font = Enum.Font.GothamBold
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,5)
    b.MouseButton1Click:Connect(function()
        for j, v in ipairs(btns) do v.BackgroundColor3 = j==i and Color3.fromRGB(25,25,25) or Color3.fromRGB(15,15,15); v.TextColor3 = j==i and Color3.fromRGB(255,255,255) or Color3.fromRGB(130,130,130) end
        for j, v in ipairs(conts) do v.Visible = j==i end
    end)
    btns[i] = b
    local f = Instance.new("ScrollingFrame", ctBg); f.Size = UDim2.new(1,-10,1,-8); f.Position = UDim2.new(0,5,0,4); f.BackgroundTransparency = 1; f.BorderSizePixel = 0; f.ScrollBarThickness = 2; f.CanvasSize = UDim2.new(0,0,0,0); f.Visible = i==1
    Instance.new("UIListLayout", f).Padding = UDim.new(0,3)
    conts[i] = f
end

local function mb(con, txt, cb)
    local b = Instance.new("TextButton", con); b.Size = UDim2.new(1,0,0,30); b.BackgroundColor3 = Color3.fromRGB(20,20,20); b.BorderSizePixel = 0; b.Text = txt; b.TextColor3 = Color3.fromRGB(200,200,200); b.TextSize = 13; b.Font = Enum.Font.Gotham
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,5)
    b.MouseButton1Click:Connect(cb); return b
end

local function mt(con, txt, get, set)
    local b = Instance.new("TextButton", con); b.Size = UDim2.new(1,0,0,30); b.BackgroundColor3 = Color3.fromRGB(20,20,20); b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,5)
    local l = Instance.new("TextLabel", b); l.Size = UDim2.new(1,-50,1,0); l.Position = UDim2.new(0,10,0,0); l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = Color3.fromRGB(200,200,200); l.TextSize = 13; l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("Frame", b); tb.Size = UDim2.new(0,32,0,18); tb.Position = UDim2.new(1,-40,0.5,-9); tb.BackgroundColor3 = get() and Color3.fromRGB(70,120,70) or Color3.fromRGB(35,35,35); tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0,9)
    local td = Instance.new("Frame", tb); td.Size = UDim2.new(0,14,0,14); td.Position = get() and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7); td.BackgroundColor3 = Color3.fromRGB(255,255,255); td.BorderSizePixel = 0
    Instance.new("UICorner", td).CornerRadius = UDim.new(0,7)
    b.MouseButton1Click:Connect(function()
        set(not get()); tb.BackgroundColor3 = get() and Color3.fromRGB(70,120,70) or Color3.fromRGB(35,35,35)
        td:TweenPosition(get() and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7), "Out", "Quad", 0.12, true)
    end); return b
end

-- COMBAT
mt(conts[1], "Autokill", function() return s.kill end, function(v) s.kill = v; if v then if not s.god then togGod(true) end; togKill(true) else togKill(false) end end)
mt(conts[1], "God Mode", function() return s.god end, function(v) if v then togGod(true) else togGod(false) end end)
mb(conts[1], "Heal", function() local m = ghm(); if m then m.Health = m.MaxHealth end end)
local krb = mb(conts[1], "Range 200", function()
    s.killRad = (s.killRad or 200) + 50; if s.killRad > 500 then s.killRad = 50 end; krb.Text = "Range "..s.killRad
end)

-- FARM
local gb = mb(conts[2], "GOD MODE", function()
    local v = not s.godMode
    s.godMode = v; gb.Text = v and "GOD MODE ON" or "GOD MODE"
    if v then
        for _, fn in pairs({togGod, togKill, togFarm, togBoss, togLoot, togRank, togStat, togSkill, togDodge, togAfk, togSpinB, togSpinE, togBuy}) do
            if type(fn) == "function" then pcall(function() fn(true) end) end
        end
        s.kill = true; s.farm = true; s.boss = true; s.loot = true; s.rank = true; s.autoStat = true; s.skill = true; s.dodge = true; s.afk = true; s.spinB = true; s.spinE = true; s.buy = true; s.god = true
    else
        togGod(false); togKill(false); togFarm(false); togBoss(false); togLoot(false); togRank(false); togStat(false); togSkill(false); togDodge(false); togAfk(false); togSpinB(false); togSpinE(false); togBuy(false)
        s.kill = false; s.farm = false; s.boss = false; s.loot = false; s.rank = false; s.autoStat = false; s.skill = false; s.dodge = false; s.afk = false; s.spinB = false; s.spinE = false; s.buy = false; s.god = false
    end
end)
mt(conts[2], "Auto Farm", function() return s.farm end, function(v) if v then togFarm(true) else togFarm(false) end end)
mt(conts[2], "Auto Boss", function() return s.boss end, function(v) if v then togBoss(true) else togBoss(false) end end)
mt(conts[2], "Auto Loot", function() return s.loot end, function(v) if v then togLoot(true) else togLoot(false) end end)
mt(conts[2], "Auto Rank", function() return s.rank end, function(v) if v then togRank(true) else togRank(false) end end)
local frb = mb(conts[2], "Range 150", function()
    s.farmRad = (s.farmRad or 150) + 50; if s.farmRad > 400 then s.farmRad = 50 end; frb.Text = "Range "..s.farmRad
end)
local brb = mb(conts[2], "Boss 500", function()
    s.bossRad = (s.bossRad or 500) + 100; if s.bossRad > 1500 then s.bossRad = 200 end; brb.Text = "Boss "..s.bossRad
end)

-- MOVE
mt(conts[3], "Fly", function() return s.fly end, function(v) togFly(v) end)
local fsb = mb(conts[3], "FlySpd 75", function()
    s.flySpd = (s.flySpd or 75) + 25; if s.flySpd > 200 then s.flySpd = 25 end; fsb.Text = "FlySpd "..s.flySpd
end)
mt(conts[3], "Speed", function() return s.spd end, function(v) togSpeed(v) end)
local spb = mb(conts[3], "WS 50", function()
    s.spdAmt = (s.spdAmt or 50) + 10; if s.spdAmt > 150 then s.spdAmt = 20 end; spb.Text = "WS "..s.spdAmt
    if s.spd then local m = ghm(); if m then m.WalkSpeed = s.spdAmt end end
end)
mt(conts[3], "Inf Jump", function() return s.infJ end, function(v) s.infJ = v end)

-- AIM
mt(conts[4], "Aimbot", function() return s.aim end, function(v) togAim(v) end)
local arb = mb(conts[4], "Range 300", function()
    s.aimRad = (s.aimRad or 300) + 50; if s.aimRad > 500 then s.aimRad = 50 end; arb.Text = "Range "..s.aimRad
end)
mt(conts[4], "Auto Atk", function() return s.aimAtk end, function(v) s.aimAtk = v end)

-- VISUAL
mt(conts[5], "ESP", function() return s.esp end, function(v) togESP(v) end)
mb(conts[5], "Fullbright", function()
    local l = game:GetService("Lighting"); l.Brightness = 3; l.Ambient = Color3.fromRGB(255,255,255); l.OutdoorAmbient = Color3.fromRGB(255,255,255); l.ClockTime = 14; l.FogEnd = 1e5
end)

-- AUTO
mt(conts[6], "Auto Stat", function() return s.autoStat end, function(v) if v then togStat(true) else togStat(false) end end)
mt(conts[6], "Auto Skill", function() return s.skill end, function(v) if v then togSkill(true) else togSkill(false) end end)
mt(conts[6], "Auto Dodge", function() return s.dodge end, function(v) if v then togDodge(true) else togDodge(false) end end)
mt(conts[6], "Spin BL", function() return s.spinB end, function(v) if v then togSpinB(true) else togSpinB(false) end end)
mt(conts[6], "Spin Element", function() return s.spinE end, function(v) if v then togSpinE(true) else togSpinE(false) end end)
mt(conts[6], "Auto Buy", function() return s.buy end, function(v) if v then togBuy(true) else togBuy(false) end end)

-- MISC
mt(conts[7], "Anti-AFK", function() return s.afk end, function(v) togAfk(v) end)
mb(conts[7], "Copy Loader", function()
    pcall(function() setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/snqw293-eng/shindo-life/main/shindo_life.lua"))()') end)
end)
mb(conts[7], "Quit", function()
    s.godMode = false; togGod(false); togKill(false); togFarm(false); togFly(false); togESP(false); togSpeed(false); togAim(false)
    togSkill(false); togDodge(false); togAfk(false); togStat(false); togRank(false); togBoss(false); togLoot(false); togSpinB(false); togSpinE(false); togBuy(false)
    if gui then gui:Destroy() end
end)

local ft = Instance.new("TextLabel", bg); ft.Size = UDim2.new(1,0,0,18); ft.Position = UDim2.new(0,6,1,-20); ft.BackgroundTransparency = 1; ft.Text = "snqw .0gh on discord"; ft.TextColor3 = Color3.fromRGB(70,70,70); ft.TextSize = 10; ft.Font = Enum.Font.Gotham
bg.Position = UDim2.new(0.5,-280,0.55,-240)
TS:Create(bg, TweenInfo.new(0.35), {Position = UDim2.new(0.5,-280,0.5,-240)}):Play()
