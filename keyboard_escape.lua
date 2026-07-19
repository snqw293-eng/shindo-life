-- Keyboard Escape Hub v2
-- Auto Win, Auto Speed, Auto Rebirth, Auto Collect, Fly, Noclip, TP

local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local plr = game:GetService("Players").LocalPlayer
local WS = workspace
local cam = WS.CurrentCamera
local Tween = game:GetService("TweenService")

-- load ui
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ccdushii/DASDASDASDASDA/refs/heads/main/AAAAA"))()
local Win = UI:CreateWindow({Name = "Keyboard Escape Hub | snqw", HideKey = Enum.KeyCode.Insert})

-- state
local st = {fly = false, noclip = false, infJ = false, autoWin = false, autoSpd = false, autoReb = false, autoCol = false}
local fcon, ncon, wcon

-- helpers
local function ghr()
    local c = plr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function ghm()
    local c = plr.Character
    return c and c:FindFirstChildWhichIsA("Humanoid")
end

-- find win parts
local function findWins()
    local out = {}
    for _, v in pairs(WS:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("win") or n:find("finish") or n:find("reward") or n:find("end") then
                table.insert(out, v)
            end
        end
    end
    return out
end

-- find collectibles
local function findCols()
    local out = {}
    for _, v in pairs(WS:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide == false and v.Transparency < 0.5 then
            local n = v.Name:lower()
            if n:find("candy") or n:find("chocolate") or n:find("coin") or n:find("gift") or n:find("collect") then
                table.insert(out, v)
            end
        end
    end
    return out
end

-- tabs
local FarmTab = Win:CreateTab("Auto Farm")
local MoveTab = Win:CreateTab("Movement")
local PlayerTab = Win:CreateTab("Player")
local MiscTab = Win:CreateTab("Misc")

-- AUTO WIN - smooth travel
local awCon
FarmTab:CreateToggle({
    Name = "Auto Win",
    CurrentValue = false,
    Callback = function(v)
        st.autoWin = v
        if awCon then awCon:Disconnect(); awCon = nil end
        if not v then return end
        if not st.noclip then
            -- auto enable noclip
        end
        awCon = RS.Heartbeat:Connect(function()
            if not st.autoWin then awCon:Disconnect(); awCon = nil; return end
            local h = ghr()
            if not h then return end
            local wins = findWins()
            if #wins == 0 then return end
            local closest; local best = math.huge
            for _, w in pairs(wins) do
                local d = (h.Position - w.Position).Magnitude
                if d < best then best = d; closest = w end
            end
            if closest and best > 5 then
                local dir = (closest.Position - h.Position).Unit
                local spd = 250
                local hum = ghm()
                if hum then
                    hum:MoveTo(closest.Position)
                    hum.WalkSpeed = spd
                    local ray = Ray.new(h.Position, dir * 5)
                    local hit = WS:FindPartOnRay(ray, plr.Character)
                    if hit then hum.Jump = true end
                end
            end
        end)
    end
})

-- AUTO SPEED
local asCon
FarmTab:CreateToggle({
    Name = "Auto Speed",
    CurrentValue = false,
    Callback = function(v)
        st.autoSpd = v
        if asCon then asCon:Disconnect(); asCon = nil end
        if not v then return end
        -- find speed remote
        local spdRemote
        for _, r in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if r:IsA("RemoteEvent") and (r.Name:lower():find("speed") or r.Name:lower():find("update") or r.Name:lower():find("walk")) then
                spdRemote = r; break
            end
        end
        asCon = RS.Heartbeat:Connect(function()
            if not st.autoSpd then asCon:Disconnect(); asCon = nil; return end
            local h = ghr(); local hum = ghm()
            if h and hum then
                hum:Move(Vector3.new(0, 0, -1), true)
                if spdRemote then pcall(function() spdRemote:FireServer() end) end
            end
        end)
    end
})

-- AUTO REBIRTH
FarmTab:CreateButton({
    Name = "Auto Rebirth (Loop)",
    Callback = function()
        st.autoReb = not st.autoReb
        UI:Notify({Title = "Rebirth", Content = st.autoReb and "Looping..." or "Stopped", Duration = 2})
        local rebRemote
        for _, r in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if r:IsA("RemoteEvent") and (r.Name:lower():find("rebirth") or r.Name:lower():find("reb") or r.Name:lower():find("prestige")) then
                rebRemote = r; break
            end
        end
        if not rebRemote then
            -- try firing startevent
            local se = plr:FindFirstChild("startevent") or plr:FindFirstChild("RemoteEvent")
            if se then rebRemote = se end
        end
        task.spawn(function()
            while st.autoReb do
                if rebRemote then
                    pcall(function() rebRemote:FireServer("rebirth") end)
                    pcall(function() rebRemote:FireServer("Rebirth") end)
                    pcall(function() rebRemote:FireServer() end)
                end
                task.wait(0.5)
            end
        end)
    end
})

-- AUTO COLLECT
FarmTab:CreateToggle({
    Name = "Auto Collect",
    CurrentValue = false,
    Callback = function(v)
        st.autoCol = v
        task.spawn(function()
            while st.autoCol do
                local h = ghr()
                if h then
                    for _, c in pairs(findCols()) do
                        if not st.autoCol then break end
                        if c.Parent then
                            h.CFrame = CFrame.new(c.Position + Vector3.new(0, 2, 0))
                            task.wait(0.02)
                        end
                    end
                end
                task.wait(0.3)
            end
        end)
    end
})

FarmTab:CreateSeparator({Text = "Teleports"})

-- TP to specific positions
local tpBtns = {
    {"TP to Spawn", function()
        local h = ghr()
        if h then h.CFrame = CFrame.new(0, 50, 0) end
    end},
    {"TP to Win", function()
        local wins = findWins()
        if #wins > 0 then
            local h = ghr()
            if h then h.CFrame = CFrame.new(wins[1].Position + Vector3.new(0, 3, 0)) end
        end
    end},
}
for _, b in ipairs(tpBtns) do
    FarmTab:CreateButton({Name = b[1], Callback = b[2]})
end

-- MOVEMENT TAB
-- Fly
local flyCon; local bv; local bg
MoveTab:CreateToggle({
    Name = "Fly (WASD + Space/Ctrl)",
    CurrentValue = false,
    Callback = function(v)
        st.fly = v
        if flyCon then flyCon:Disconnect(); flyCon = nil end
        if not v then
            if bv then bv:Destroy(); bv = nil end
            if bg then bg:Destroy(); bg = nil end
            local hum = ghm()
            if hum then hum.PlatformStand = false end
            return
        end
        local h = ghr(); local hum = ghm()
        if not h or not hum then return end
        hum.PlatformStand = true
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.P = 1e4
            bv.Parent = h
        end
        if not bg then
            bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 1e4
            bg.D = 100
            bg.CFrame = h.CFrame
            bg.Parent = h
        end
        local spd = st.flySpd or 150
        flyCon = RS.RenderStepped:Connect(function()
            if not st.fly then return end
            local hrp = ghr()
            if not hrp then return end
            local v = Vector3.new()
            local c = cam.CFrame
            if UIS:IsKeyDown(Enum.KeyCode.W) then v = v + c.LookVector * spd end
            if UIS:IsKeyDown(Enum.KeyCode.S) then v = v - c.LookVector * spd end
            if UIS:IsKeyDown(Enum.KeyCode.A) then v = v - c.RightVector * spd end
            if UIS:IsKeyDown(Enum.KeyCode.D) then v = v + c.RightVector * spd end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then v = v + Vector3.new(0, spd, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then v = v - Vector3.new(0, spd, 0) end
            bv.Velocity = v
            bg.CFrame = c
        end)
    end
})

MoveTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 2000},
    Increment = 10,
    CurrentValue = 150,
    Callback = function(v) st.flySpd = v end
})

MoveTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        st.noclip = v
        if ncon then ncon:Disconnect(); ncon = nil end
        if not v then return end
        ncon = RS.Stepped:Connect(function()
            if not st.noclip then ncon:Disconnect(); ncon = nil; return end
            local c = plr.Character
            if c then
                for _, p in pairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
})

-- click tp
local ctCon; local ctEnabled
MoveTab:CreateToggle({
    Name = "Click TP (Ctrl + Click)",
    CurrentValue = false,
    Callback = function(v)
        ctEnabled = v
        if ctCon then ctCon:Disconnect(); ctCon = nil end
        if not v then return end
        ctCon = UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if ctEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                local h = ghr()
                if h then
                    local m = plr:GetMouse()
                    if m and m.Hit then
                        h.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 3, 0))
                    end
                end
            end
        end)
    end
})

-- PLAYER TAB
PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 1000},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        local hum = ghm()
        if hum then hum.WalkSpeed = v end
        task.spawn(function()
            while wcon and hum and hum.WalkSpeed ~= v do
                hum.WalkSpeed = v
                task.wait(0.5)
            end
        end)
    end
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v)
        local hum = ghm()
        if hum then hum.UseJumpPower = true; hum.JumpPower = v end
    end
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v) st.infJ = v end
})

UIS.JumpRequest:Connect(function()
    if st.infJ then
        local hum = ghm()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- MISC TAB
MiscTab:CreateButton({
    Name = "Anti-AFK",
    Callback = function()
        local vu = game:GetService("VirtualUser")
        plr.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0, 0), cam.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0, 0), cam.CFrame)
        end)
        UI:Notify({Title = "Anti-AFK", Content = "Active", Duration = 3})
    end
})

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        local ts = game:GetService("TeleportService")
        ts:Teleport(game.PlaceId, plr)
    end
})

MiscTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local ts = game:GetService("TeleportService")
        local _, id = pcall(function() return ts:ReserveServer(game.PlaceId) end)
        if id then ts:TeleportToPrivateServer(game.PlaceId, id, {plr}) end
    end
})

-- persist walkspeed
wcon = RS.Stepped:Connect(function()
    local hum = ghm()
    if not hum then return end
    if st.noclip then
        local c = plr.Character
        if c then
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

UI:Notify({Title = "Keyboard Escape Hub", Content = "Loaded. Press INSERT", Duration = 4})
