local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local plr = game:GetService("Players").LocalPlayer
local WS = workspace
local mouse = plr:GetMouse()

local farmOn = false
local killOn = false
local godOn = false
local espOn = false
local autoQOn = false
local flyOn = false
local speedOn = false
local infJumpOn = false
local autoSpinOn = false
local autoStatOn = false
local autoSenkaiOn = false
local autoMedOn = false
local autoCollectOn = false

local killRad = 200
local speedAmt = 50
local farmRad = 150
local flySpeed = 75

local espObjs = {}
local hlConn

local function getChar()
    return plr.Character
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildWhichIsA("Humanoid")
end

-- God Mode
RS.RenderStepped:Connect(function()
    if not godOn then return end
    local h = getHum()
    if h then
        h.Health = h.MaxHealth
        local be = getChar():FindFirstChild("BodyEffects")
        if be then
            pcall(function()
                be:FindFirstChild("DamageReduction"):Destroy()
                local ne = Instance.new("NumberValue")
                ne.Name = "DamageReduction"
                ne.Value = 1
                ne.Parent = be
            end)
        end
    end
end)

-- Auto Heal
RS.RenderStepped:Connect(function()
    if not godOn then return end
    local h = getHum()
    if h and h.Health < h.MaxHealth then
        h.Health = h.MaxHealth
    end
end)

-- Autokill
local function doKill()
    if not killOn then return end
    local hrp = getHRP()
    if not hrp then return end
    for _, v in ipairs(WS:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            local hum = v:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 and hrp and (v.HumanoidRootPart.Position - hrp.Position).Magnitude <= killRad then
                if v ~= getChar() and not plr:GetFriends():FindFirstChild(v.Name) then
                    hum.Health = 0
                    local be = v:FindFirstChild("BodyEffects")
                    if be then
                        local kd = be:FindFirstChild("KillData")
                        if kd then kd:Destroy() end
                    end
                end
            end
        end
    end
end

RS.RenderStepped:Connect(function()
    if killOn then doKill() end
end)

-- Auto Farm
local function findEnemy()
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bd = nil, farmRad
    for _, v in ipairs(WS:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            local hum = v:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < bd and v ~= getChar() then
                    bd = d; best = v
                end
            end
        end
    end
    return best
end

local farmConn
function startFarm()
    if farmConn then farmConn:Disconnect() end
    farmConn = RS.RenderStepped:Connect(function()
        if not farmOn then if farmConn then farmConn:Disconnect() end return end
        local hrp = getHRP()
        if not hrp then return end
        local e = findEnemy()
        if e and e:FindFirstChild("HumanoidRootPart") then
            local t = e.HumanoidRootPart
            hrp.CFrame = CFrame.new(t.Position + Vector3.new(0, 5, 0), t.Position)
            mouse1press()
            task.wait(0.05)
            mouse1release()
        end
    end)
end

-- Auto Quest
local questGivers = {}
function scanQuests()
    questGivers = {}
    for _, v in ipairs(WS:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            local h = v:FindFirstChild("Humanoid")
            if h and h.Health > 0 and v.Name:lower():find("npc") then
                table.insert(questGivers, v)
            end
        end
    end
end

local qConn
function startAutoQuest()
    scanQuests()
    if qConn then qConn:Disconnect() end
    qConn = RS.RenderStepped:Connect(function()
        if not autoQOn then if qConn then qConn:Disconnect() end return end
        local hrp = getHRP()
        if not hrp then return end
        local r = game:GetService("ReplicatedStorage")
        if r then
            local rem = r:FindFirstChild("QuestRem") or r:FindFirstChild("RemoteEvent") or r:FindFirstChildWhichIsA("RemoteEvent")
            if rem then
                pcall(function() rem:FireServer("AutoQuest") end)
            end
        end
        -- walk to nearest quest giver if no quest
        if #questGivers > 0 then
            local best, bd = nil, 100
            for _, q in ipairs(questGivers) do
                local qhrp = q:FindFirstChild("HumanoidRootPart")
                if qhrp then
                    local d = (qhrp.Position - hrp.Position).Magnitude
                    if d < bd then bd = d; best = q end
                end
            end
            if best and best:FindFirstChild("HumanoidRootPart") then
                hrp.CFrame = CFrame.new(best.HumanoidRootPart.Position + Vector3.new(0, 5, 3))
            end
        end
    end)
end

-- Fly
local fBody = nil
local fGyro = nil
function toggleFly()
    flyOn = not flyOn
    local hrp = getHRP()
    if not hrp then return end
    if flyOn then
        if not fBody then
            fBody = Instance.new("BodyVelocity")
            fBody.Name = "FlyVelocity"
            fBody.MaxForce = Vector3.new(1, 1, 1) * 9e9
            fBody.Velocity = Vector3.new(0, 0, 0)
            fBody.P = 1e4
        end
        if not fGyro then
            fGyro = Instance.new("BodyGyro")
            fGyro.Name = "FlyGyro"
            fGyro.MaxTorque = Vector3.new(1, 1, 1) * 9e9
            fGyro.P = 1e4
            fGyro.D = 100
        end
        fBody.Parent = hrp
        fGyro.Parent = hrp
        local c = getChar()
        if c then
            local h = c:FindFirstChildWhichIsA("Humanoid")
            if h then h.PlatformStand = true end
        end
    else
        if fBody then fBody:Destroy(); fBody = nil end
        if fGyro then fGyro:Destroy(); fGyro = nil end
        local c = getChar()
        if c then
            local h = c:FindFirstChildWhichIsA("Humanoid")
            if h then h.PlatformStand = false end
        end
    end
end

RS.RenderStepped:Connect(function()
    if not flyOn then return end
    local hrp = getHRP()
    if not hrp or not fBody or not fGyro then return end
    local d = Vector3.new(0, 0, 0)
    if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + WS.CurrentCamera.CFrame.LookVector * Vector3.new(1, 0, 1) end
    if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - WS.CurrentCamera.CFrame.LookVector * Vector3.new(1, 0, 1) end
    if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - WS.CurrentCamera.CFrame.RightVector * Vector3.new(1, 0, 1) end
    if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + WS.CurrentCamera.CFrame.RightVector * Vector3.new(1, 0, 1) end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end
    if d.Magnitude > 0 then d = d.Unit * flySpeed end
    fBody.Velocity = d
    fGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + WS.CurrentCamera.CFrame.LookVector * Vector3.new(1, 0, 1))
end)

-- Speed
RS.RenderStepped:Connect(function()
    if not speedOn then return end
    local h = getHum()
    if h then
        h.WalkSpeed = speedAmt
    end
end)

-- Inf Jump
UIS.JumpRequest:Connect(function()
    if not infJumpOn then return end
    local h = getHum()
    if h then
        h:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ESP
function toggleESP()
    espOn = not espOn
    if espOn then
        for _, v in ipairs(WS:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v ~= getChar() then
                local hl = Instance.new("Highlight")
                hl.Name = "SnqwESP"
                hl.FillColor = Color3.fromRGB(255, 50, 50)
                hl.FillTransparency = 0.5
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.Parent = v
                table.insert(espObjs, hl)
            end
        end
        hlConn = WS.DescendantAdded:Connect(function(v)
            if not espOn then return end
            task.wait(0.5)
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v ~= getChar() then
                local hl = Instance.new("Highlight")
                hl.Name = "SnqwESP"
                hl.FillColor = Color3.fromRGB(255, 50, 50)
                hl.FillTransparency = 0.5
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.Parent = v
                table.insert(espObjs, hl)
            end
        end)
    else
        for _, v in ipairs(espObjs) do
            pcall(function() v:Destroy() end)
        end
        espObjs = {}
        if hlConn then hlConn:Disconnect(); hlConn = nil end
    end
end

-- Auto Spin
local spinConn
function startAutoSpin()
    if autoSpinOn then autoSpinOn = false; if spinConn then spinConn:Disconnect() end return end
    autoSpinOn = true
    spinConn = RS.RenderStepped:Connect(function()
        if not autoSpinOn then if spinConn then spinConn:Disconnect() end return end
        local r = game:GetService("ReplicatedStorage")
        if r then
            local rem = r:FindFirstChild("SpinRem") or r:FindFirstChild("BloodlineSpin")
            if rem then
                pcall(function() rem:FireServer() end)
            end
        end
    end)
end

-- Teleports
local tpLocs = {
    {"Spawn", Vector3.new(0, 50, 0)},
    {"Village", Vector3.new(-500, 50, 200)},
    {"Ember", Vector3.new(2000, 50, 1500)},
    {"Ravine", Vector3.new(-1000, 50, -500)},
    {"Forest", Vector3.new(1500, 50, -1000)},
    {"Ocean", Vector3.new(3000, 50, 0)},
}

-- Status line
local stLine

function upSt()
    if not stLine then return end
    stLine.Text = "F:" .. (farmOn and "ON" or "OFF") .. " K:" .. (killOn and "ON" or "OFF") .. " G:" .. (godOn and "ON" or "OFF") .. " E:" .. (espOn and "ON" or "OFF") .. " FL:" .. (flyOn and "ON" or "OFF")
end

-- UI
local gui = Instance.new("ScreenGui"); gui.Name = "SnqwSH"; gui.ResetOnSpawn = false; gui.Parent = plr:WaitForChild("PlayerGui")
local bg = Instance.new("Frame"); bg.Size = UDim2.new(0, 560, 0, 460); bg.Position = UDim2.new(0.5, -280, 0.5, -230); bg.BackgroundColor3 = Color3.fromRGB(10,10,10); bg.BorderSizePixel = 0; bg.Active = true; bg.Draggable = true; bg.Parent = gui
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", bg); title.Size = UDim2.new(1, 0, 0, 40); title.BackgroundColor3 = Color3.fromRGB(15,15,15); title.BorderSizePixel = 0; title.Text = "SNQW .0GH"; title.TextColor3 = Color3.fromRGB(200,200,200); title.TextSize = 18; title.Font = Enum.Font.GothamBold
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

stLine = Instance.new("TextLabel", bg); stLine.Size = UDim2.new(1, -16, 0, 22); stLine.Position = UDim2.new(0, 8, 0, 40); stLine.BackgroundTransparency = 1; stLine.Text = ""; stLine.TextColor3 = Color3.fromRGB(0,200,0); stLine.TextSize = 10; stLine.Font = Enum.Font.GothamBold; stLine.TextXAlignment = Enum.TextXAlignment.Left

local side = Instance.new("Frame", bg); side.Size = UDim2.new(0, 150, 1, -66); side.Position = UDim2.new(0, 6, 0, 64); side.BackgroundColor3 = Color3.fromRGB(14,14,14); side.BorderSizePixel = 0
Instance.new("UICorner", side).CornerRadius = UDim.new(0, 6)

local contBg = Instance.new("Frame", bg); contBg.Size = UDim2.new(1, -170, 1, -78); contBg.Position = UDim2.new(0, 164, 0, 72); contBg.BackgroundColor3 = Color3.fromRGB(12,12,12); contBg.BorderSizePixel = 0
Instance.new("UICorner", contBg).CornerRadius = UDim.new(0, 6)

Instance.new("UIListLayout", side).Padding = UDim.new(0, 3); side.LayoutOrder = 1

local tabBtns = {}; local contents = {}
local tabs = {"COMBAT","FARM","MOVEMENT","VISUAL","AUTO","MISC"}
for i, n in ipairs(tabs) do
    local b = Instance.new("TextButton", side); b.Size = UDim2.new(1, -6, 0, 32); b.BackgroundColor3 = i == 1 and Color3.fromRGB(25,25,25) or Color3.fromRGB(15,15,15); b.BorderSizePixel = 0; b.Text = n; b.TextColor3 = i == 1 and Color3.fromRGB(255,255,255) or Color3.fromRGB(130,130,130); b.TextSize = 11; b.Font = Enum.Font.GothamBold
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(function()
        for j, v in ipairs(tabBtns) do
            v.BackgroundColor3 = j == i and Color3.fromRGB(25,25,25) or Color3.fromRGB(15,15,15)
            v.TextColor3 = j == i and Color3.fromRGB(255,255,255) or Color3.fromRGB(130,130,130)
        end
        for j, v in ipairs(contents) do v.Visible = j == i end
    end)
    tabBtns[i] = b
    local f = Instance.new("ScrollingFrame", contBg); f.Size = UDim2.new(1, -10, 1, -8); f.Position = UDim2.new(0, 5, 0, 4); f.BackgroundTransparency = 1; f.BorderSizePixel = 0; f.ScrollBarThickness = 2; f.CanvasSize = UDim2.new(0, 0, 0, 0); f.Visible = i == 1
    Instance.new("UIListLayout", f).Padding = UDim.new(0, 3)
    contents[i] = f
end

function btn(con, txt, cb)
    local b = Instance.new("TextButton", con); b.Size = UDim2.new(1, 0, 0, 32); b.BackgroundColor3 = Color3.fromRGB(20,20,20); b.BorderSizePixel = 0; b.Text = txt; b.TextColor3 = Color3.fromRGB(200,200,200); b.TextSize = 13; b.Font = Enum.Font.Gotham
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(cb)
    return b
end

function tog(con, txt, get, set)
    local b = Instance.new("TextButton", con); b.Size = UDim2.new(1, 0, 0, 32); b.BackgroundColor3 = Color3.fromRGB(20,20,20); b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    local l = Instance.new("TextLabel", b); l.Size = UDim2.new(1, -50, 1, 0); l.Position = UDim2.new(0, 10, 0, 0); l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = Color3.fromRGB(200,200,200); l.TextSize = 13; l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("Frame", b); tb.Size = UDim2.new(0, 32, 0, 18); tb.Position = UDim2.new(1, -40, 0.5, -9); tb.BackgroundColor3 = get() and Color3.fromRGB(70,120,70) or Color3.fromRGB(35,35,35); tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 9)
    local td = Instance.new("Frame", tb); td.Size = UDim2.new(0, 14, 0, 14); td.Position = get() and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7); td.BackgroundColor3 = Color3.fromRGB(255,255,255); td.BorderSizePixel = 0
    Instance.new("UICorner", td).CornerRadius = UDim.new(0, 7)
    b.MouseButton1Click:Connect(function()
        set(not get())
        tb.BackgroundColor3 = get() and Color3.fromRGB(70,120,70) or Color3.fromRGB(35,35,35)
        td:TweenPosition(get() and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.12, true)
    end)
    return b
end

-- COMBAT tab
tog(contents[1], "Autokill", function() return killOn end, function(v) killOn = v; upSt() end)
btn(contents[1], "Kill Range: " .. killRad, function()
    killRad = killRad + 50; if killRad > 500 then killRad = 50 end
    btn(contents[1], "Kill Range: " .. killRad, function() end) end)
tog(contents[1], "God Mode", function() return godOn end, function(v) godOn = v; upSt() end)
btn(contents[1], "Heal Now", function()
    local h = getHum()
    if h then h.Health = h.MaxHealth end
end)

-- FARM tab
tog(contents[2], "Auto Farm", function() return farmOn end, function(v) farmOn = v; if v then startFarm() end; upSt() end)
btn(contents[2], "Farm Range: " .. farmRad, function()
    farmRad = farmRad + 50; if farmRad > 400 then farmRad = 50 end
end)
tog(contents[2], "Auto Quest", function() return autoQOn end, function(v) autoQOn = v; if v then startAutoQuest() end; upSt() end)
btn(contents[2], "Scan NPCs", scanQuests)
tog(contents[2], "Auto Collect", function() return autoCollectOn end, function(v) autoCollectOn = v; upSt() end)

-- MOVEMENT tab
tog(contents[3], "Fly", function() return flyOn end, function(v) toggleFly(); upSt() end)
btn(contents[3], "Fly Speed: " .. flySpeed, function()
    flySpeed = flySpeed + 25; if flySpeed > 200 then flySpeed = 25 end
end)
tog(contents[3], "Speed", function() return speedOn end, function(v) speedOn = v; upSt() end)
btn(contents[3], "Speed: " .. speedAmt, function()
    speedAmt = speedAmt + 10; if speedAmt > 150 then speedAmt = 20 end
    local h = getHum()
    if h and speedOn then h.WalkSpeed = speedAmt end
end)
tog(contents[3], "Inf Jump", function() return infJumpOn end, function(v) infJumpOn = v; upSt() end)

-- VISUAL tab
tog(contents[4], "ESP", function() return espOn end, function(v) toggleESP(); upSt() end)
btn(contents[4], "Refresh ESP", function()
    if espOn then
        toggleESP()
        task.wait(0.1)
        toggleESP()
    end
end)
btn(contents[4], "Fullbright", function()
    local l = game:GetService("Lighting")
    l.Brightness = 3
    l.Ambient = Color3.fromRGB(255,255,255)
    l.OutdoorAmbient = Color3.fromRGB(255,255,255)
    l.ClockTime = 14
    l.FogEnd = 1e5
end)

-- AUTO tab
tog(contents[5], "Auto Spin", function() return autoSpinOn end, function(v) startAutoSpin(); upSt() end)
tog(contents[5], "Auto Stat", function() return autoStatOn end, function(v) autoStatOn = v; upSt() end)
tog(contents[5], "Auto Senkai", function() return autoSenkaiOn end, function(v) autoSenkaiOn = v; upSt() end)
tog(contents[5], "Auto Meditate", function() return autoMedOn end, function(v) autoMedOn = v; upSt() end)

-- MISC tab
for _, loc in ipairs(tpLocs) do
    btn(contents[6], "TP " .. loc[1], function()
        local hrp = getHRP()
        if hrp then hrp.CFrame = CFrame.new(loc[2]) end
    end)
end
btn(contents[6], "Copy Loader", function()
    if setclipboard then
        setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/snqw293-eng/superpull/main/shindo_life.lua"))()')
    end
end)
btn(contents[6], "Quit", function()
    if gui then gui:Destroy() end
    if farmOn then farmOn = false end
    if killOn then killOn = false end
    if flyOn then toggleFly() end
    if espOn then toggleESP() end
end)

local ft = Instance.new("TextLabel", bg); ft.Size = UDim2.new(1, 0, 0, 18); ft.Position = UDim2.new(0, 6, 1, -20); ft.BackgroundTransparency = 1; ft.Text = "snqw .0gh on discord"; ft.TextColor3 = Color3.fromRGB(70,70,70); ft.TextSize = 10; ft.Font = Enum.Font.Gotham
upSt()
bg.Position = UDim2.new(0.5, -280, 0.55, -230)
TS:Create(bg, TweenInfo.new(0.35), {Position = UDim2.new(0.5, -280, 0.5, -230)}):Play()

print("Snqw SH loaded")
