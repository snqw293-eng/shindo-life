local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local VIM = game:GetService("VirtualInputManager")
local plr = game:GetService("Players").LocalPlayer
local WS = workspace
local vu = game:GetService("VirtualUser")

local state = {}
local macroCfg = nil
local macroCfgT = 0

local function pullCfg()
    local t = time()
    if t - macroCfgT < 1 then return macroCfg end
    macroCfgT = t
    local s, r = pcall(function()
        return game:HttpGet("http://127.0.0.1:18723/config")
    end)
    if s and r and r ~= "" then
        local d = pcall(function() macroCfg = game:GetService("HttpService"):JSONDecode(r) end)
        return macroCfg
    end
    macroCfg = nil
    return nil
end

local function cfgBool(k, fallback)
    local c = pullCfg()
    if c and c[k] ~= nil then return c[k] end
    return fallback
end

local function gC() return plr.Character end
local function gH()
    local c = gC()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function gHum()
    local c = gC()
    return c and c:FindFirstChildWhichIsA("Humanoid")
end

local statNames = {"Health","Chakra","Strength","Defense","Speed","Tai","Nin","Gen"}
local mobCache = {}
local mobCacheT = 0
local statRemote
local misGui

local function getMobs(r)
    local t = time()
    if t - mobCacheT < 0.15 and mobCache.r == r then return mobCache.d end
    local h = gH(); if not h then return {} end
    local hp = h.Position; local out = {}
    local folders = {WS:FindFirstChild("npc"), WS:FindFirstChild("NPCs")}
    for _, f in pairs(folders) do
        if f then
            for _, v in pairs(f:GetChildren()) do
                if v:IsA("Model") and v ~= gC() then
                    local vh = v:FindFirstChild("HumanoidRootPart")
                    local vm = v:FindFirstChildWhichIsA("Humanoid")
                    if vh and vm and vm.Health > 0 and (vh.Position - hp).Magnitude <= (r or 300) then
                        table.insert(out, {m = v, hrp = vh, hum = vm})
                    end
                end
            end
        end
    end
    mobCache = {d = out, r = r}
    mobCacheT = t
    return out
end

local function getBosses(r)
    local h = gH(); if not h then return {} end
    local hp = h.Position; local out = {}
    local npc = WS:FindFirstChild("npc")
    if npc then
        for _, v in pairs(npc:GetChildren()) do
            if v:IsA("Model") then
                local vh = v:FindFirstChild("HumanoidRootPart")
                local vm = v:FindFirstChildWhichIsA("Humanoid")
                local n = v.Name:lower()
                if vh and vm and vm.Health > 0 then
                    local isBoss = n == "npc1" or n:find("boss") or n:find("mini") or vm.MaxHealth > 5000
                    if isBoss and (vh.Position - hp).Magnitude <= (r or 500) then
                        table.insert(out, {m = v, hrp = vh, hum = vm})
                    end
                end
            end
        end
    end
    return out
end

local function getDrops(r)
    local h = gH(); if not h then return {} end
    local hp = h.Position; local out = {}
    for _, v in pairs(WS:GetChildren()) do
        local cd = v:FindFirstChildWhichIsA("ClickDetector")
        if cd then
            local pos
            if v:IsA("BasePart") then
                pos = v.Position
            elseif v:IsA("Model") then
                local pp = v.PrimaryPart or v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
                if pp then pos = pp.Position end
            end
            if pos and (pos - hp).Magnitude <= (r or 100) then
                table.insert(out, {m = v, pos = pos, cd = cd})
            end
        end
    end
    local gt = WS:FindFirstChild("GLOBALTIME")
    if gt then
        for _, v in pairs(gt:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("sh") then
                local sh = v.sh
                local invoke = sh:FindFirstChild("invoke")
                local cd = sh:FindFirstChildWhichIsA("ClickDetector")
                if (invoke or cd) and (sh.Position - hp).Magnitude <= (r or 500) then
                    table.insert(out, {m = v, pos = sh.Position, invoke = invoke, cd = cd})
                end
            end
        end
    end
    return out
end

local function doAtk()
    pcall(function()
        local c = gC()
        if c and c:FindFirstChild("combat") and c.combat:FindFirstChild("update") then
            for i = 1, 3 do
                c.combat.update:FireServer("mouse1", true)
                task.wait(0.02)
                c.combat.update:FireServer("mouse1", false)
                task.wait(0.02)
            end
        end
    end)
    pcall(mouse1press)
    task.wait(0.03)
    pcall(mouse1release)
    task.wait(0.03)
    pcall(function() VIM:SendMouseButtonEvent(0, 0, true, nil, 0) end)
    task.wait(0.03)
    pcall(function() VIM:SendMouseButtonEvent(0, 0, false, nil, 0) end)
end

local function killMob(m)
    if not m or not m.hrp or not m.hum then return end
    local h = gH()
    if h then
        h.CFrame = CFrame.new(m.hrp.Position + Vector3.new(0,3,0), m.hrp.Position)
    end
    doAtk()
    m.hum.Health = 0
    pcall(function()
        m.hum.HealthChanged:Connect(function()
            if m.hum and m.hum.Health > 0 then m.hum.Health = 0 end
        end)
    end)
end

function togGod(on)
    state.god = on
    if godCon then godCon:Disconnect(); godCon = nil end
    if not on then return end
    godCon = RS.Heartbeat:Connect(function()
        if not state.god then godCon:Disconnect(); godCon = nil; return end
        local m = gHum()
        if m and m.Health < m.MaxHealth then m.Health = m.MaxHealth end
        task.wait(0.05)
    end)
end

local killCon
function togKill(on)
    state.kill = on
    if killCon then killCon:Disconnect(); killCon = nil end
    if not on then return end
    if not state.god then togGod(true) end
    killCon = RS.Heartbeat:Connect(function()
        if not state.kill then killCon:Disconnect(); killCon = nil; return end
        local h = gH()
        if not h then return end
        local mobs = getMobs(state.killRad or 200)
        if #mobs > 0 then
            killMob(mobs[1])
        end
        task.wait(0.1)
    end)
end

local rankCon
function togRank(on)
    state.rank = on; if rankCon then rankCon:Disconnect(); rankCon = nil end
    if not on then return end
    rankCon = RS.Heartbeat:Connect(function()
        if not state.rank then rankCon:Disconnect(); rankCon = nil; return end
        local lvl = plr.statz and plr.statz.lvl and plr.statz.lvl.lvl
        if lvl and lvl.Value >= 1000 then
            local pres = plr.statz and plr.statz.prestige
            local se = plr:FindFirstChild("startevent")
            if se then
                if pres and (pres.maxlvlpres.Value >= 1 or (pres.rank.Value == "Z" and pres.number.Value == "3")) then
                    se:FireServer("maxlvlpres")
                else
                    se:FireServer("rankup")
                end
            end
        end
        task.wait(2)
    end)
end

local farmCon
local farmPhase = "quest"
local farmTimer = 0
local mission

local function findMis()
    local m = plr.PlayerGui:FindFirstChild("Main")
    if m then
        local ig = m:FindFirstChild("ingame")
        if ig then return ig:FindFirstChild("Missionstory") end
    end
end

local function getQTarget()
    local ms = findMis()
    if not ms or not ms.Visible then return nil end
    local bg = ms:FindFirstChild("bg")
    if not bg then return nil end
    local nm = bg:FindFirstChild("name")
    if not nm then return nil end
    local txt = nm.Text
    local t = txt:match("Defeat (.+) %(") or txt:match("Defeat (.+)")
    if t then return t:gsub("%(s%)",""):lower() end
    return nil
end

local function findQMobs(target, r)
    local h = gH(); if not h or not target then return {} end
    local hp = h.Position; local out = {}
    local npc = WS:FindFirstChild("npc")
    if npc then
        for _, v in pairs(npc:GetChildren()) do
            if v:IsA("Model") then
                local vh = v:FindFirstChild("HumanoidRootPart")
                local vm = v:FindFirstChildWhichIsA("Humanoid")
                local n = v.Name:lower()
                if vh and vm and vm.Health > 0 and (vh.Position - hp).Magnitude <= (r or 400) then
                    if n:find(target) or target:find(n) then
                        table.insert(out, {m = v, hrp = vh, hum = vm})
                    end
                end
            end
        end
    end
    return out
end

function togFarm(on)
    state.farm = on; if farmCon then farmCon:Disconnect(); farmCon = nil end
    if not on then farmPhase = "quest"; farmTimer = 0; return end
    if not state.god then togGod(true) end
    farmCon = RS.Heartbeat:Connect(function()
        if not state.farm then farmCon:Disconnect(); farmCon = nil; return end
        local h = gH(); if not h then return end
        farmTimer = farmTimer + 1
        local mgs = WS:FindFirstChild("missiongivers")

        if farmPhase == "quest" then
            if mgs then
                local found
                for _, v in pairs(mgs:GetChildren()) do
                    if v:IsA("Model") and v.Name == "" and v:FindFirstChild("Head") and v.Head:FindFirstChild("givemission") and v.Head.givemission.Enabled then
                        local colorImg = v.Head.givemission:FindFirstChild("color") and v.Head.givemission.color.Image
                        if colorImg and (colorImg:find("5459241648") or colorImg:find("5459241799")) then
                            local mgp = v:FindFirstChild("HumanoidRootPart")
                            local ct = v:FindFirstChild("CLIENTTALK")
                            if mgp and ct then
                                h.CFrame = CFrame.new(mgp.Position + Vector3.new(0,5,0))
                                ct:FireServer()
                                task.wait(0.1)
                                ct:FireServer("accept")
                                found = true
                                break
                            end
                        end
                    end
                end
                if found then
                    farmPhase = "accepting"
                    farmTimer = 0
                end
            end
        elseif farmPhase == "accepting" then
            local ms = findMis()
            if ms and ms.Visible then
                farmPhase = "kill"
                farmTimer = 0
            elseif farmTimer > 60 then
                farmPhase = "quest"
                farmTimer = 0
            end
        elseif farmPhase == "kill" then
            local target = getQTarget()
            local qmobs = target and findQMobs(target, state.farmRad or 200)
            if #qmobs > 0 then
                killMob(qmobs[1])
            else
                -- no quest mobs found, stay near mission givers
                if mgs and farmTimer < 30 then
                    local mg = mgs:FindFirstChildWhichIsA("Model")
                    if mg then
                        local mgp = mg:FindFirstChild("HumanoidRootPart")
                        if mgp and (h.Position - mgp.Position).Magnitude > 100 then
                            h.CFrame = CFrame.new(mgp.Position + Vector3.new(0,5,0))
                        end
                    end
                end
            end
            local ms = findMis()
            if ms and not ms.Visible then
                farmPhase = "turnin"
                farmTimer = 0
            end
            if farmTimer > 900 then
                farmPhase = "turnin"
                farmTimer = 0
            end
        elseif farmPhase == "turnin" then
            if mgs then
                for _, v in pairs(mgs:GetChildren()) do
                    if v:IsA("Model") then
                        local mgp = v:FindFirstChild("HumanoidRootPart")
                        local ct = v:FindFirstChild("CLIENTTALK")
                        if mgp and ct then
                            h.CFrame = CFrame.new(mgp.Position + Vector3.new(0,5,0))
                            ct:FireServer()
                            task.wait(0.1)
                            ct:FireServer("accept")
                            break
                        end
                    end
                end
            end
            task.wait(0.3)
            farmPhase = "quest"
            farmTimer = 0
        end
        task.wait(0.12)
    end)
end

local bossCon
function togBoss(on)
    state.boss = on; if bossCon then bossCon:Disconnect(); bossCon = nil end
    if not on then return end
    if not state.god then togGod(true) end
    bossCon = RS.Heartbeat:Connect(function()
        if not state.boss then bossCon:Disconnect(); bossCon = nil; return end
        local h = gH(); if not h then return end
        local bosses = getBosses(state.bossRad or 500)
        if #bosses > 0 then
            killMob(bosses[1])
        end
        task.wait(0.15)
    end)
end

local lootCon
function togLoot(on)
    state.loot = on; if lootCon then lootCon:Disconnect(); lootCon = nil end
    if not on then return end
    lootCon = RS.Heartbeat:Connect(function()
        if not state.loot then lootCon:Disconnect(); lootCon = nil; return end
        local h = gH(); if not h then return end
        local drops = getDrops(state.lootRad or 100)
        for _, d in pairs(drops) do
            h.CFrame = CFrame.new(d.pos + Vector3.new(0,3,0))
            task.wait(0.05)
            if d.invoke then
                pcall(function() d.invoke:FireServer(plr) end)
            end
            if d.cd then
                pcall(function() fireclickdetector(d.cd) end)
            end
        end
        task.wait(0.3)
    end)
end

local statCon
function togAutoStat(on)
    state.autoStat = on; if statCon then statCon:Disconnect(); statCon = nil end
    if not on then return end
    if not statRemote then
        for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name:lower():find("stat") then statRemote = v; break end
        end
    end
    statCon = RS.Heartbeat:Connect(function()
        if not state.autoStat then statCon:Disconnect(); statCon = nil; return end
        if not statRemote then return end
        local points = 0
        local statz = plr:FindFirstChild("statz") or plr:FindFirstChild("Stats")
        if statz then
            for _, v in pairs(statz:GetDescendants()) do
                if (v:IsA("NumberValue") or v:IsA("IntValue")) then
                    local n = v.Name:lower()
                    if n == "statpoints" or n == "points" or n == "sp" or n == "skillpoints" then
                        points = v.Value; break
                    end
                end
            end
        end
        if points and points > 0 then
            local per = math.max(1, math.floor(points / #statNames))
            for _, s in ipairs(statNames) do
                pcall(function() statRemote:FireServer(s, per) end) task.wait(0.02)
            end
            pcall(function() statRemote:FireServer("All", points) end)
        end
        task.wait(1)
    end)
end

local skillCon
function togSkill(on)
    state.skill = on; if skillCon then skillCon:Disconnect(); skillCon = nil end
    if not on then return end
    skillCon = RS.Heartbeat:Connect(function()
        if not state.skill then skillCon:Disconnect(); skillCon = nil; return end
        if #getMobs(200) > 0 then
            pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.One, false, nil) end) task.wait(0.08)
            pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.One, false, nil) end) task.wait(0.08)
            pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Two, false, nil) end) task.wait(0.08)
            pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.Two, false, nil) end)
        end
        task.wait(0.5)
    end)
end

local dodgeCon
function togDodge(on)
    state.dodge = on; if dodgeCon then dodgeCon:Disconnect(); dodgeCon = nil end
    if not on then return end
    dodgeCon = RS.Heartbeat:Connect(function()
        if not state.dodge then dodgeCon:Disconnect(); dodgeCon = nil; return end
        local m = gHum()
        if m and m.Health < m.MaxHealth * 0.6 then
            pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Q, false, nil) end) task.wait(0.05)
            pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.Q, false, nil) end)
            m.Health = m.MaxHealth
        end
        task.wait(0.3)
    end)
end

local afkCon
function togAfk(on)
    state.afk = on; if afkCon then afkCon:Disconnect(); afkCon = nil end
    if not on then return end
    afkCon = plr.Idled:Connect(function()
        vu:CaptureController(); vu:ClickButton2(Vector2.new())
    end)
end

local aimCon
function togAim(on)
    state.aim = on; if aimCon then aimCon:Disconnect(); aimCon = nil end
    if not on then return end
    aimCon = RS.RenderStepped:Connect(function()
        if not state.aim then aimCon:Disconnect(); aimCon = nil; return end
        local mobs = getMobs(state.aimRad or 300)
        if #mobs > 0 then
            local h = gH()
            if h then
                local lp = mobs[1].hrp.Position
                h.CFrame = CFrame.new(h.Position, Vector3.new(lp.X, h.Position.Y, lp.Z))
                if state.aimAtk then
                    pcall(function() VIM:SendMouseButtonEvent(0, 0, true, nil, 0) end) task.wait(0.05)
                    pcall(function() VIM:SendMouseButtonEvent(0, 0, false, nil, 0) end)
                end
            end
        end
        task.wait(0.03)
    end)
end

local fBody, fGyro
local flyCon
function togFly(on)
    state.fly = on
    if flyCon then flyCon:Disconnect(); flyCon = nil end
    local h = gH()
    if on and h then
        pcall(function() if fBody then fBody:Destroy() end end)
        fBody = Instance.new("BodyVelocity")
        fBody.Name = "SnqwFlyV"
        fBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        fBody.P = 1e4; fBody.Parent = h
        pcall(function() if fGyro then fGyro:Destroy() end end)
        fGyro = Instance.new("BodyGyro")
        fGyro.Name = "SnqwFlyG"
        fGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        fGyro.P = 1e4; fGyro.D = 100; fGyro.Parent = h
        local hum = gHum()
        if hum then hum.PlatformStand = true end
        flyCon = RS.RenderStepped:Connect(function()
            if not state.fly then if flyCon then flyCon:Disconnect(); flyCon = nil end; return end
            local hrp = gH()
            if not hrp or not fBody or not fGyro then return end
            local d = Vector3.new()
            local c = WS.CurrentCamera
            if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + c.CFrame.LookVector * Vector3.new(1,0,1) end
            if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - c.CFrame.LookVector * Vector3.new(1,0,1) end
            if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - c.CFrame.RightVector * Vector3.new(1,0,1) end
            if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + c.CFrame.RightVector * Vector3.new(1,0,1) end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0,1,0) end
            local s = state.flySpd or 75
            if d.Magnitude > 0 then d = d.Unit * s end
            fBody.Velocity = d
            fGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + c.CFrame.LookVector * Vector3.new(1,0,1))
        end)
    else
        pcall(function() if fBody then fBody:Destroy() end end); fBody = nil
        pcall(function() if fGyro then fGyro:Destroy() end end); fGyro = nil
        local hum = gHum()
        if hum then hum.PlatformStand = false end
    end
end

local spdCon
function togSpeed(on)
    state.spd = on
    if spdCon then spdCon:Disconnect(); spdCon = nil end
    if not on then
        local m = gHum(); if m then m.WalkSpeed = 16 end; return
    end
    spdCon = RS.Heartbeat:Connect(function()
        if not state.spd then spdCon:Disconnect(); spdCon = nil; return end
        local m = gHum()
        if m then m.WalkSpeed = state.spdAmt or 50 end
        task.wait(0.1)
    end)
end

UIS.JumpRequest:Connect(function()
    if state.infJ then
        local m = gHum()
        if m then m:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local espObjs = {}
local espAddCon
function togESP(on)
    state.esp = on
    if not on then
        for _, v in pairs(espObjs) do pcall(function() v:Destroy() end) end
        espObjs = {}
        if espAddCon then espAddCon:Disconnect(); espAddCon = nil end
        return
    end
    for _, v in pairs(WS:GetChildren()) do
        if v:IsA("Model") and v ~= gC() and v:FindFirstChild("Humanoid") then
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255,50,50)
            hl.FillTransparency = 0.5
            hl.OutlineColor = Color3.fromRGB(255,255,255)
            hl.Parent = v
            table.insert(espObjs, hl)
        end
    end
    espAddCon = WS.ChildAdded:Connect(function(v)
        task.wait(0.5)
        if state.esp and v:IsA("Model") and v ~= gC() and v:FindFirstChild("Humanoid") then
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255,50,50)
            hl.FillTransparency = 0.5
            hl.OutlineColor = Color3.fromRGB(255,255,255)
            hl.Parent = v
            table.insert(espObjs, hl)
        end
    end)
end

local tpLocs = {
    {"Spawn", Vector3.new(0,50,0)},
    {"Village", Vector3.new(-500,50,200)},
    {"Ember", Vector3.new(2000,50,1500)},
    {"Ravine", Vector3.new(-1000,50,-500)},
    {"Forest", Vector3.new(1500,50,-1000)},
    {"Ocean", Vector3.new(3000,50,0)},
    {"Warrior", Vector3.new(-2000,50,1000)},
    {"Akuma", Vector3.new(2500,50,-500)},
}

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
local tabs = {"COMBAT","FARM","MOVE","AIM","VISUAL","AUTO","MISC"}
for i, n in ipairs(tabs) do
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

local function mkBtn(con, txt, cb)
    local b = Instance.new("TextButton", con); b.Size = UDim2.new(1,0,0,30); b.BackgroundColor3 = Color3.fromRGB(20,20,20); b.BorderSizePixel = 0; b.Text = txt; b.TextColor3 = Color3.fromRGB(200,200,200); b.TextSize = 13; b.Font = Enum.Font.Gotham
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,5)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function mkTog(con, txt, get, set)
    local b = Instance.new("TextButton", con); b.Size = UDim2.new(1,0,0,30); b.BackgroundColor3 = Color3.fromRGB(20,20,20); b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,5)
    local l = Instance.new("TextLabel", b); l.Size = UDim2.new(1,-50,1,0); l.Position = UDim2.new(0,10,0,0); l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = Color3.fromRGB(200,200,200); l.TextSize = 13; l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("Frame", b); tb.Size = UDim2.new(0,32,0,18); tb.Position = UDim2.new(1,-40,0.5,-9); tb.BackgroundColor3 = get() and Color3.fromRGB(70,120,70) or Color3.fromRGB(35,35,35); tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0,9)
    local td = Instance.new("Frame", tb); td.Size = UDim2.new(0,14,0,14); td.Position = get() and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7); td.BackgroundColor3 = Color3.fromRGB(255,255,255); td.BorderSizePixel = 0
    Instance.new("UICorner", td).CornerRadius = UDim.new(0,7)
    b.MouseButton1Click:Connect(function()
        set(not get())
        tb.BackgroundColor3 = get() and Color3.fromRGB(70,120,70) or Color3.fromRGB(35,35,35)
        td:TweenPosition(get() and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7), "Out", "Quad", 0.12, true)
    end)
    return b
end

-- COMBAT
mkTog(conts[1], "Autokill", function() return state.kill end, function(v) togKill(v) end)
mkTog(conts[1], "God Mode", function() return state.god end, function(v) togGod(v) end)
mkBtn(conts[1], "Heal", function() local m = gHum(); if m then m.Health = m.MaxHealth end end)
local krBtn
krBtn = mkBtn(conts[1], "Range: 200", function()
    state.killRad = (state.killRad or 200) + 50; if state.killRad > 500 then state.killRad = 50 end
    krBtn.Text = "Range: "..state.killRad
end)

-- FARM
local sleepBtn
sleepBtn = mkBtn(conts[2], "SLEEP MODE OFF", function()
    state.sleep = not state.sleep
    sleepBtn.Text = state.sleep and "SLEEP MODE ON" or "SLEEP MODE OFF"
    if state.sleep then
        togGod(true); togFarm(true); togRank(true); togAutoStat(true)
        togSkill(true); togDodge(true); togAfk(true); togKill(true)
        togBoss(true); togLoot(true); togSpinB(true); togSpinE(true); togBuy(true)
    else
        togGod(false); togFarm(false); togRank(false); togAutoStat(false)
        togSkill(false); togDodge(false); togAfk(false); togKill(false)
        togBoss(false); togLoot(false); togSpinB(false); togSpinE(false); togBuy(false)
    end
end)
mkTog(conts[2], "Auto Farm", function() return state.farm end, function(v) togFarm(v) end)
mkTog(conts[2], "Auto Boss", function() return state.boss end, function(v) togBoss(v) end)
mkTog(conts[2], "Auto Loot", function() return state.loot end, function(v) togLoot(v) end)
mkTog(conts[2], "Auto Rank", function() return state.rank end, function(v) togRank(v) end)
local frBtn
frBtn = mkBtn(conts[2], "Range: 150", function()
    state.farmRad = (state.farmRad or 150) + 50; if state.farmRad > 400 then state.farmRad = 50 end
    frBtn.Text = "Range: "..state.farmRad
end)
local bossRadBtn
bossRadBtn = mkBtn(conts[2], "Boss Range: 500", function()
    state.bossRad = (state.bossRad or 500) + 100; if state.bossRad > 1500 then state.bossRad = 200 end
    bossRadBtn.Text = "Boss Range: "..state.bossRad
end)

-- MOVE
mkTog(conts[3], "Fly", function() return state.fly end, function(v) togFly(v) end)
local fsBtn
fsBtn = mkBtn(conts[3], "Speed: 75", function()
    state.flySpd = (state.flySpd or 75) + 25; if state.flySpd > 200 then state.flySpd = 25 end
    fsBtn.Text = "Speed: "..state.flySpd
end)
mkTog(conts[3], "WalkSpeed", function() return state.spd end, function(v) togSpeed(v) end)
local spBtn
spBtn = mkBtn(conts[3], "WS: 50", function()
    state.spdAmt = (state.spdAmt or 50) + 10; if state.spdAmt > 150 then state.spdAmt = 20 end
    spBtn.Text = "WS: "..state.spdAmt
    if state.spd then local m = gHum(); if m then m.WalkSpeed = state.spdAmt end end
end)
mkTog(conts[3], "Inf Jump", function() return state.infJ end, function(v) state.infJ = v end)

-- AIM
mkTog(conts[4], "Aimbot", function() return state.aim end, function(v) togAim(v) end)
local arBtn = mkBtn(conts[4], "Range: 300", function()
    state.aimRad = (state.aimRad or 300) + 50; if state.aimRad > 500 then state.aimRad = 50 end
    arBtn.Text = "Range: "..state.aimRad
end)
mkTog(conts[4], "Auto Atk", function() return state.aimAtk end, function(v) state.aimAtk = v end)

-- VISUAL
mkTog(conts[5], "ESP", function() return state.esp end, function(v) togESP(v) end)
mkBtn(conts[5], "Fullbright", function()
    local l = game:GetService("Lighting")
    l.Brightness = 3; l.Ambient = Color3.fromRGB(255,255,255); l.OutdoorAmbient = Color3.fromRGB(255,255,255); l.ClockTime = 14; l.FogEnd = 1e5
end)

-- AUTO SPIN BLOODLINE
local spinCon
function togSpinB(on)
    state.spinB = on; if spinCon then spinCon:Disconnect(); spinCon = nil end
    if not on then return end
    spinCon = RS.Heartbeat:Connect(function()
        if not state.spinB then spinCon:Disconnect(); spinCon = nil; return end
        local sp = plr.statz and plr.statz.spins and plr.statz.spins.Value
        local se = plr:FindFirstChild("startevent")
        if se and sp and sp > 0 then
            pcall(function() se:FireServer("spin", "kg1") end) task.wait(0.3)
            pcall(function() se:FireServer("spin", "kg2") end) task.wait(0.3)
        end
        task.wait(0.5)
    end)
end

-- AUTO SPIN ELEMENT
local spinECon
function togSpinE(on)
    state.spinE = on; if spinECon then spinECon:Disconnect(); spinECon = nil end
    if not on then return end
    spinECon = RS.Heartbeat:Connect(function()
        if not state.spinE then spinECon:Disconnect(); spinECon = nil; return end
        local sp = plr.statz and plr.statz.spins and plr.statz.spins.Value
        local se = plr:FindFirstChild("startevent")
        if se and sp and sp > 0 then
            pcall(function() se:FireServer("spin", "element1") end) task.wait(0.3)
            pcall(function() se:FireServer("spin", "element2") end) task.wait(0.3)
        end
        task.wait(0.5)
    end)
end

-- AUTO BUY ABILITIES
local buyCon
function togBuy(on)
    state.buy = on; if buyCon then buyCon:Disconnect(); buyCon = nil end
    if not on then return end
    buyCon = RS.Heartbeat:Connect(function()
        if not state.buy then buyCon:Disconnect(); buyCon = nil; return end
        local h = gH(); if not h then return end
        for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                local n = v.Name:lower()
                if n:find("buy") or n:find("shop") or n:find("purchase") or n:find("element") or n:find("ability") then
                    pcall(function() v:FireServer("Buy", "Element") end)
                    pcall(function() v:FireServer("Buy", "Ability") end)
                    pcall(function() v:FireServer("Purchase", "All") end)
                    pcall(function() v:InvokeServer("BuyAll") end)
                end
            end
        end
        task.wait(3)
    end)
end
mkTog(conts[6], "Auto Stat", function() return state.autoStat end, function(v) togAutoStat(v) end)
mkTog(conts[6], "Auto Skill", function() return state.skill end, function(v) togSkill(v) end)
mkTog(conts[6], "Auto Dodge", function() return state.dodge end, function(v) togDodge(v) end)
mkTog(conts[6], "Spin BL", function() return state.spinB end, function(v) togSpinB(v) end)
mkTog(conts[6], "Spin Element", function() return state.spinE end, function(v) togSpinE(v) end)
mkTog(conts[6], "Auto Buy", function() return state.buy end, function(v) togBuy(v) end)


-- MISC
mkTog(conts[7], "Anti-AFK", function() return state.afk end, function(v) togAfk(v) end)

for _, loc in ipairs(tpLocs) do
    mkBtn(conts[7], "TP "..loc[1], function()
        local h = gH()
        if h then h.CFrame = CFrame.new(loc[2]) end
    end)
end

mkBtn(conts[7], "Copy Loader", function()
    pcall(function()
        setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/snqw293-eng/shindo-life/main/shindo_life.lua"))()')
    end)
end)
mkBtn(conts[7], "Quit", function()
    state.sleep = false
    togKill(false); togGod(false); togFarm(false); togFly(false); togESP(false); togSpeed(false); togAim(false)
    togSkill(false); togDodge(false); togAfk(false); togAutoStat(false); togRank(false)
    togBoss(false); togLoot(false); togSpinB(false); togSpinE(false); togBuy(false)
    if gui then gui:Destroy() end
end)

local ft = Instance.new("TextLabel", bg); ft.Size = UDim2.new(1,0,0,18); ft.Position = UDim2.new(0,6,1,-20); ft.BackgroundTransparency = 1; ft.Text = "snqw .0gh on discord"; ft.TextColor3 = Color3.fromRGB(70,70,70); ft.TextSize = 10; ft.Font = Enum.Font.Gotham
bg.Position = UDim2.new(0.5,-280,0.55,-240)
TS:Create(bg, TweenInfo.new(0.35), {Position = UDim2.new(0.5,-280,0.5,-240)}):Play()
print("Snqw SH loaded")
