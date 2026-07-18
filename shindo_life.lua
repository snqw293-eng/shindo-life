local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local VIM = game:GetService("VirtualInputManager")
local plr = game:GetService("Players").LocalPlayer
local WS = workspace

local fState = {}
local cConns = {}

local function gC() return plr.Character end
local function gH()
    local c = gC()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function gHum()
    local c = gC()
    return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function cUp(n, fn)
    if cConns[n] then cConns[n]:Disconnect() end
    if fn then cConns[n] = fn() end
end

local function safePos()
    local h = gH()
    return h and h.Position or Vector3.new()
end

-- click combat
local function doAtk()
    local ok, e = pcall(function() VIM:SendMouseButtonEvent(0, 0, 0, true) end)
    if not ok then
        pcall(function() mouse1press() end)
    end
    task.wait(0.03)
    pcall(function() VIM:SendMouseButtonEvent(0, 0, 0, false) end)
    pcall(function() mouse1release() end)
end

-- Autokill (throttled)
local killCon
function togKill(on)
    fState.kill = on
    if killCon then killCon:Disconnect(); killCon = nil end
    if not on then return end
    killCon = RS.Heartbeat:Connect(function()
        if not fState.kill then killCon:Disconnect(); killCon = nil; return end
        local h = gH()
        if not h then return end
        local hp = h.Position
        local r = fState.killRad or 200
        for _, v in pairs(WS:GetChildren()) do
            if v:IsA("Model") and v ~= gC() then
                local vh = v:FindFirstChild("HumanoidRootPart")
                local vm = v:FindFirstChildWhichIsA("Humanoid")
                if vh and vm and vm.Health > 0 and (vh.Position - hp).Magnitude <= r then
                    vm.Health = 0
                end
            end
        end
        task.wait(0.1)
    end)
end

-- God mode (throttled)
local godCon
function togGod(on)
    fState.god = on
    if godCon then godCon:Disconnect(); godCon = nil end
    if not on then return end
    godCon = RS.Heartbeat:Connect(function()
        if not fState.god then godCon:Disconnect(); godCon = nil; return end
        local m = gHum()
        if m and m.Health < m.MaxHealth then m.Health = m.MaxHealth end
        task.wait(0.05)
    end)
end

-- Auto farm (throttled)
local farmCon
function togFarm(on)
    fState.farm = on
    if farmCon then farmCon:Disconnect(); farmCon = nil end
    if not on then return end
    farmCon = RS.Heartbeat:Connect(function()
        if not fState.farm then farmCon:Disconnect(); farmCon = nil; return end
        local h = gH()
        if not h then return end
        local hp = h.Position
        local best, bd = nil, fState.farmRad or 150
        for _, v in pairs(WS:GetChildren()) do
            if v:IsA("Model") and v ~= gC() then
                local vh = v:FindFirstChild("HumanoidRootPart")
                local vm = v:FindFirstChildWhichIsA("Humanoid")
                if vh and vm and vm.Health > 0 then
                    local d = (vh.Position - hp).Magnitude
                    if d < bd then bd = d; best = v end
                end
            end
        end
        if best then
            local bt = best:FindFirstChild("HumanoidRootPart")
            if bt then
                h.CFrame = CFrame.new(bt.Position + Vector3.new(0, 5, 0), bt.Position)
                doAtk()
            end
        end
        task.wait(0.08)
    end)
end

-- Fly
local fBody, fGyro
local flyCon
function togFly(on)
    fState.fly = on
    if flyCon then flyCon:Disconnect(); flyCon = nil end
    local h = gH()
    if on and h then
        if fBody then pcall(function() fBody:Destroy() end) end
        fBody = Instance.new("BodyVelocity")
        fBody.Name = "SnqwFlyV"
        fBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        fBody.P = 1e4
        fBody.Parent = h
        if fGyro then pcall(function() fGyro:Destroy() end) end
        fGyro = Instance.new("BodyGyro")
        fGyro.Name = "SnqwFlyG"
        fGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        fGyro.P = 1e4
        fGyro.D = 100
        fGyro.Parent = h
        local hum = gHum()
        if hum then hum.PlatformStand = true end
        flyCon = RS.RenderStepped:Connect(function()
            if not fState.fly then if flyCon then flyCon:Disconnect(); flyCon = nil end; return end
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
            local s = fState.flySpd or 75
            if d.Magnitude > 0 then d = d.Unit * s end
            fBody.Velocity = d
            fGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + c.CFrame.LookVector * Vector3.new(1,0,1))
        end)
    else
        if fBody then pcall(function() fBody:Destroy() end); fBody = nil end
        if fGyro then pcall(function() fGyro:Destroy() end); fGyro = nil end
        local hum = gHum()
        if hum then hum.PlatformStand = false end
    end
end

-- Speed
local spdCon
function togSpeed(on)
    fState.spd = on
    if spdCon then spdCon:Disconnect(); spdCon = nil end
    if not on then
        local m = gHum()
        if m then m.WalkSpeed = 16 end
        return
    end
    spdCon = RS.Heartbeat:Connect(function()
        if not fState.spd then spdCon:Disconnect(); spdCon = nil; return end
        local m = gHum()
        if m then m.WalkSpeed = fState.spdAmt or 50 end
        task.wait(0.1)
    end)
end

-- Inf Jump
UIS.JumpRequest:Connect(function()
    if fState.infJ then
        local m = gHum()
        if m then m:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ESP
local espObjs = {}
local espAddCon
function togESP(on)
    fState.esp = on
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
        if fState.esp and v:IsA("Model") and v ~= gC() and v:FindFirstChild("Humanoid") then
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255,50,50)
            hl.FillTransparency = 0.5
            hl.OutlineColor = Color3.fromRGB(255,255,255)
            hl.Parent = v
            table.insert(espObjs, hl)
        end
    end)
end

-- tp
local tpLocs = {
    {"Spawn", Vector3.new(0,50,0)},
    {"Village", Vector3.new(-500,50,200)},
    {"Ember", Vector3.new(2000,50,1500)},
    {"Ravine", Vector3.new(-1000,50,-500)},
    {"Forest", Vector3.new(1500,50,-1000)},
    {"Ocean", Vector3.new(3000,50,0)},
}

-- UI
local gui = Instance.new("ScreenGui"); gui.Name = "SnqwSH"; gui.ResetOnSpawn = false; gui.Parent = plr:WaitForChild("PlayerGui")
local bg = Instance.new("Frame"); bg.Size = UDim2.new(0,560,0,460); bg.Position = UDim2.new(0.5,-280,0.5,-230); bg.BackgroundColor3 = Color3.fromRGB(10,10,10); bg.BorderSizePixel = 0; bg.Active = true; bg.Draggable = true; bg.Parent = gui
Instance.new("UICorner", bg).CornerRadius = UDim.new(0,8)
local st = Instance.new("TextLabel", bg); st.Size = UDim2.new(1,-16,0,22); st.Position = UDim2.new(0,8,0,40); st.BackgroundTransparency = 1; st.Text = ""; st.TextColor3 = Color3.fromRGB(0,200,0); st.TextSize = 10; st.Font = Enum.Font.GothamBold; st.TextXAlignment = Enum.TextXAlignment.Left

local title = Instance.new("TextLabel", bg); title.Size = UDim2.new(1,0,0,40); title.BackgroundColor3 = Color3.fromRGB(15,15,15); title.BorderSizePixel = 0; title.Text = "SNQW .0GH"; title.TextColor3 = Color3.fromRGB(200,200,200); title.TextSize = 18; title.Font = Enum.Font.GothamBold
Instance.new("UICorner", title).CornerRadius = UDim.new(0,8)

local side = Instance.new("Frame", bg); side.Size = UDim2.new(0,150,1,-66); side.Position = UDim2.new(0,6,0,64); side.BackgroundColor3 = Color3.fromRGB(14,14,14); side.BorderSizePixel = 0
Instance.new("UICorner", side).CornerRadius = UDim.new(0,6)

local ctBg = Instance.new("Frame", bg); ctBg.Size = UDim2.new(1,-170,1,-78); ctBg.Position = UDim2.new(0,164,0,72); ctBg.BackgroundColor3 = Color3.fromRGB(12,12,12); ctBg.BorderSizePixel = 0
Instance.new("UICorner", ctBg).CornerRadius = UDim.new(0,6)
Instance.new("UIListLayout", side).Padding = UDim.new(0,3)

local btns = {}; local conts = {}
local tabs = {"COMBAT","FARM","MOVE","VISUAL","AUTO","MISC"}
for i, n in ipairs(tabs) do
    local b = Instance.new("TextButton", side); b.Size = UDim2.new(1,-6,0,30); b.BackgroundColor3 = i==1 and Color3.fromRGB(25,25,25) or Color3.fromRGB(15,15,15); b.BorderSizePixel = 0; b.Text = n; b.TextColor3 = i==1 and Color3.fromRGB(255,255,255) or Color3.fromRGB(130,130,130); b.TextSize = 11; b.Font = Enum.Font.GothamBold
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

local function upSt()
    st.Text = "K:"..tostring(fState.kill and "ON" or "OFF").." G:"..tostring(fState.god and "ON" or "OFF").." F:"..tostring(fState.farm and "ON" or "OFF").." E:"..tostring(fState.esp and "ON" or "OFF").." FL:"..tostring(fState.fly and "ON" or "OFF")
end

-- populate
mkTog(conts[1], "Autokill", function() return fState.kill end, function(v) togKill(v); upSt() end)
mkTog(conts[1], "God Mode", function() return fState.god end, function(v) togGod(v); upSt() end)
mkBtn(conts[1], "Heal Now", function() local m = gHum(); if m then m.Health = m.MaxHealth end end)
local krBtn
krBtn = mkBtn(conts[1], "Kill Range: 200", function()
    fState.killRad = (fState.killRad or 200) + 50; if fState.killRad > 500 then fState.killRad = 50 end
    krBtn.Text = "Kill Range: "..fState.killRad
end)

mkTog(conts[2], "Auto Farm", function() return fState.farm end, function(v) togFarm(v); upSt() end)
local frBtn
frBtn = mkBtn(conts[2], "Farm Range: 150", function()
    fState.farmRad = (fState.farmRad or 150) + 50; if fState.farmRad > 400 then fState.farmRad = 50 end
    frBtn.Text = "Farm Range: "..fState.farmRad
end)

mkTog(conts[3], "Fly", function() return fState.fly end, function(v) togFly(v); upSt() end)
local fsBtn
fsBtn = mkBtn(conts[3], "Fly Speed: 75", function()
    fState.flySpd = (fState.flySpd or 75) + 25; if fState.flySpd > 200 then fState.flySpd = 25 end
    fsBtn.Text = "Fly Speed: "..fState.flySpd
end)
mkTog(conts[3], "Speed", function() return fState.spd end, function(v) togSpeed(v); upSt() end)
local spBtn
spBtn = mkBtn(conts[3], "Speed Amt: 50", function()
    fState.spdAmt = (fState.spdAmt or 50) + 10; if fState.spdAmt > 150 then fState.spdAmt = 20 end
    spBtn.Text = "Speed Amt: "..fState.spdAmt
    if fState.spd then local m = gHum(); if m then m.WalkSpeed = fState.spdAmt end end
end)
mkTog(conts[3], "Inf Jump", function() return fState.infJ end, function(v) fState.infJ = v end)

mkTog(conts[4], "ESP", function() return fState.esp end, function(v) togESP(v); upSt() end)
mkBtn(conts[4], "Fullbright", function()
    local l = game:GetService("Lighting")
    l.Brightness = 3; l.Ambient = Color3.fromRGB(255,255,255); l.OutdoorAmbient = Color3.fromRGB(255,255,255); l.ClockTime = 14; l.FogEnd = 1e5
end)

for _, loc in ipairs(tpLocs) do
    mkBtn(conts[5], "TP "..loc[1], function()
        local h = gH()
        if h then h.CFrame = CFrame.new(loc[2]) end
    end)
end

mkBtn(conts[6], "Copy Loader", function()
    pcall(function()
        setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/snqw293-eng/shindo-life/main/shindo_life.lua"))()')
    end)
end)
mkBtn(conts[6], "Quit", function()
    for _, v in pairs(cConns) do pcall(function() v:Disconnect() end) end
    cConns = {}
    togKill(false); togGod(false); togFarm(false); togFly(false); togESP(false); togSpeed(false)
    if gui then gui:Destroy() end
end)

local ft = Instance.new("TextLabel", bg); ft.Size = UDim2.new(1,0,0,18); ft.Position = UDim2.new(0,6,1,-20); ft.BackgroundTransparency = 1; ft.Text = "snqw .0gh on discord"; ft.TextColor3 = Color3.fromRGB(70,70,70); ft.TextSize = 10; ft.Font = Enum.Font.Gotham
upSt()
bg.Position = UDim2.new(0.5,-280,0.55,-230)
TS:Create(bg, TweenInfo.new(0.35), {Position = UDim2.new(0.5,-280,0.5,-230)}):Play()
print("Snqw SH loaded - no lag")
