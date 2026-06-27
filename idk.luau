-- [[ ROBLOX FPS ADVANCED PENTEST SUITE v4.5 This script still has some errors|This script was not written by me]]
-- Bản vá lỗi UI, chuẩn hóa toán tử ưu tiên, tích hợp Ring Buffer cho Replay và Wrapper an toàn cho Drawing API.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ====================================================================
-- [[ INTERFACES & TAB MANAGER ]]
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FpsPentestSuiteV45"
ScreenGui.ResetOnSpawn = false
local success, err = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local function addUICorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 880, 0, 540)
MainFrame.Position = UDim2.new(0.12, 0, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
MainFrame.Active = true MainFrame.Draggable = true MainFrame.Parent = ScreenGui
addUICorner(MainFrame, 6)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "  FPS PENTEST SUITE v4.5 [This script still has some errors|This script was not written by me]"
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.SourceSansBold Title.TextSize = 14
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 25) Title.Parent = MainFrame
addUICorner(Title, 6)

local BenchLabel = Instance.new("TextLabel")
BenchLabel.Size = UDim2.new(0, 350, 0, 45)
BenchLabel.Position = UDim2.new(1, -360, 0, 0)
BenchLabel.BackgroundTransparency = 1
BenchLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
BenchLabel.Font = Enum.Font.Code BenchLabel.TextSize = 11
BenchLabel.TextXAlignment = Enum.TextXAlignment.Right
BenchLabel.Text = "FPS: -- | Ping: -- ms | Pool: 0"
BenchLabel.Parent = MainFrame

local function createCategory(name, posLeft)
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(0, 205, 0, 470)
    frame.Position = UDim2.new(0, posLeft, 0, 55)
    frame.BackgroundTransparency = 1
    frame.CanvasSize = UDim2.new(0, 0, 4, 0)
    frame.ScrollBarThickness = 2 frame.Parent = MainFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Text = "[ " .. name:upper() .. " ]"
    label.TextColor3 = Color3.fromRGB(0, 160, 255)
    label.Font = Enum.Font.SourceSansBold label.TextSize = 12
    label.BackgroundTransparency = 1 label.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = frame layout.Padding = UDim.new(0, 4)
    return frame
end

local MvTab = createCategory("Movement / Stress", 12)
local CbTab = createCategory("Combat / Projectile", 227)
local NtTab = createCategory("Network Pipeline", 442)
local VsTab = createCategory("Visuals / Replay", 657)

-- Configurations State
local States = {
    Fly = false, Noclip = false, Speed = 16, Jump = 50, TargetPlayer = "",
    SilentAim = false, PredictionAim = false, FovRadius = 120, VisibleCheck = false,
    FuzzingActive = false, BurstRate = 10, FakeLag = false, LagPower = 0.2,
    SeatSpam = false, MicroTeleport = false, TeleportDist = 10, TeleportTime = 0.1,
    EspBox = false, EspTracers = false, EspNames = false, EspHealth = false, EspSkeletons = false,
    BulletWarp = false, BulletSpeedMult = 1, ProjectileDup = false, BulletRewind = false,
    TelemetryActive = true, PacketOrderingAbuse = false, Replaying = false, CFrameDesync = false
}

local function createToggle(name, parent, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 195, 0, 28)
    button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    button.Text = name .. ": OFF"
    button.TextColor3 = Color3.fromRGB(240, 80, 80)
    button.Font = Enum.Font.SourceSans button.TextSize = 12 button.Parent = parent
    addUICorner(button, 4)
    local state = false
    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = name .. (state and ": ON" or ": OFF")
        button.TextColor3 = state and Color3.fromRGB(80, 240, 80) or Color3.fromRGB(240, 80, 80)
        callback(state)
    end)
    return button
end

-- Fix Vấn đề hình số 3: Thay thế chính xác biến lỗi từ 'button' thành 'box'
local function createTextBox(placeholder, parent, callback)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 195, 0, 28)
    box.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    box.PlaceholderText = placeholder box.Text = ""
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.SourceSans box.TextSize = 12 box.Parent = parent
    addUICorner(box, 4)
    box.FocusLost:Connect(function(enterPressed) if enterPressed then callback(box.Text) end end)
    return box
end

local function createActionButton(name, parent, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 195, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold btn.TextSize = 12 btn.Parent = parent
    addUICorner(btn, 4)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local CurrentFps = 0
RunService.RenderStepped:Connect(function(dt)
    CurrentFps = math.floor(1 / dt)
end)

-- Safe Wrapper cho Drawing API để tương thích tốt với môi trường Studio
local function safeDestroyDrawing(instance)
    if not instance then return end
    if type(instance.Remove) == "function" then
        instance:Remove()
    elseif type(instance.Destroy) == "function" then
        instance:Destroy()
    end
end

-- FOV Ring UI
local FovRing = Drawing.new("Circle")
FovRing.Thickness = 1
FovRing.Color = Color3.fromRGB(255, 255, 255)
FovRing.Transparency = 0.5
FovRing.Filled = false

RunService.RenderStepped:Connect(function()
    FovRing.Radius = States.FovRadius
    FovRing.Position = UserInputService:GetMouseLocation()
    FovRing.Visible = States.SilentAim
end)

-- ====================================================================
-- [[ MODULE 1: NETWORK LAYER PIPELINE & BUFFER MIDDLEWARES ]]
-- ====================================================================
local NetworkLayer = {}
NetworkLayer.Middlewares = {}

local MAX_LOG = 500
local LogIndex = 1
local TelemetryLog = table.create(MAX_LOG)
local DelayQueue = {}

function NetworkLayer:RegisterMiddleware(name, priority, callback)
    table.insert(self.Middlewares, {Name = name, Priority = priority, Callback = callback})
    table.sort(self.Middlewares, function(a, b) return a.Priority < b.Priority end)
end

function NetworkLayer:Send(remote, ...)
    if not remote or not remote:IsA("RemoteEvent") then return end
    local args = {...}
    local openPipeline = true
    
    for _, middleware in ipairs(self.Middlewares) do
        local success, state, modifiedArgs = pcall(middleware.Callback, remote, args)
        if success then
            if state == false then openPipeline = false; break end
            if modifiedArgs then args = modifiedArgs end
        else
            warn("[PIPELINE ERROR][" .. middleware.Name .. "]: " .. tostring(state))
        end
    end
    
    if not openPipeline then return end
    if States.FakeLag then
        table.insert(DelayQueue, {Remote = remote, Args = args, TargetTime = os.clock() + States.LagPower})
        return
    end
    
    remote:FireServer(unpack(args))
    
    if States.TelemetryActive and not States.Replaying then
        TelemetryLog[LogIndex] = {
            Timestamp = os.clock(),
            Remote = remote.Name,
            Args = args,
            FPS = CurrentFps
        }
        LogIndex = (LogIndex % MAX_LOG) + 1
    end
end

RunService.Heartbeat:Connect(function()
    local now = os.clock()
    for i = #DelayQueue, 1, -1 do
        local packet = DelayQueue[i]
        if now >= packet.TargetTime then
            packet.Remote:FireServer(unpack(packet.Args))
            table.remove(DelayQueue, i)
        end
    end
end)

-- ====================================================================
-- [[ MODULE 2: REGISTRY CACHING ENGINE ]]
-- ====================================================================
local SeatRegistry = {}
local function registerSeat(obj)
    if obj:IsA("Seat") or obj:IsA("VehicleSeat") then table.insert(SeatRegistry, obj) end
end
local function deregisterSeat(obj)
    local idx = table.find(SeatRegistry, obj)
    if idx then table.remove(SeatRegistry, idx) end
end
Workspace.DescendantAdded:Connect(registerSeat)
Workspace.DescendantRemoving:Connect(deregisterSeat)
for _, obj in pairs(Workspace:GetDescendants()) do registerSeat(obj) end

-- ====================================================================
-- [[ MODULE 3: MOTION CONTROL & STRESS TESTING ]]
-- ====================================================================
createToggle("Noclip Physics", MvTab, function(state) States.Noclip = state end)
RunService.Stepped:Connect(function()
    if States.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

local flyV, flyG
createToggle("Fly Core", MvTab, function(state)
    States.Fly = state
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if state then
        flyV = Instance.new("BodyVelocity") flyV.MaxForce = Vector3.new(1e5, 1e5, 1e5) flyV.Parent = hrp
        flyG = Instance.new("BodyGyro") flyG.MaxTorque = Vector3.new(1e5, 1e5, 1e5) flyG.Parent = hrp
        task.spawn(function()
            while States.Fly and char and hrp do
                local camCFrame = Camera.CFrame
                local dir = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCFrame.RightVector end
                flyV.Velocity = dir * (States.Speed * 2) flyG.CFrame = camCFrame
                task.wait()
            end
        end)
    else
        if flyV then flyV:Destroy() end if flyG then flyG:Destroy() end
    end
end)

createTextBox("Blink Distance", MvTab, function(val) States.TeleportDist = tonumber(val) or 10 end)
createTextBox("Blink Delta Time", MvTab, function(val) States.TeleportTime = tonumber(val) or 0.1 end)
createToggle("Blink Packet Abuse", MvTab, function(state)
    States.MicroTeleport = state
    task.spawn(function()
        while States.MicroTeleport do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + (hum.MoveDirection * States.TeleportDist)
            end
            task.wait(States.TeleportTime)
        end
    end)
end)

createToggle("CFrame Data Desync", MvTab, function(state) States.CFrameDesync = state end)
-- Sửa lỗi thứ 1: Cấu trúc tường minh bao bọc toán tử ưu tiên (Grouped Boolean Condition)
NetworkLayer:RegisterMiddleware("CFrameDesync", 10, function(remote, args)
    if States.CFrameDesync and (remote.Name:lower():find("update") or remote.Name:lower():find("pos")) then
        for idx, arg in ipairs(args) do
            if typeof(arg) == "CFrame" then
                args[idx] = arg * CFrame.new(math.random(-5, 5), 0, math.random(-5, 5))
            end
        end
        return true, args
    end
end)

local StressActive = false
createToggle("Equip/Unequip Flood", MvTab, function(state)
    StressActive = state
    task.spawn(function()
        while StressActive do
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if backpack and char and hum then
                local tool = backpack:FindFirstChildOfClass("Tool")
                if tool then hum:EquipTool(tool) task.wait(0.01) hum:UnequipTools() end
            end
            task.wait(0.02)
        end
    end)
end)

createToggle("Seat Control Flood", MvTab, function(state)
    States.SeatSpam = state
    task.spawn(function()
        while States.SeatSpam do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                for _, seat in ipairs(SeatRegistry) do
                    if seat.Parent and not seat.Occupant then
                        seat:Sit(hum) task.wait(0.01) hum.Jump = true break
                    end
                end
            end
            task.wait(0.03)
        end
    end)
end)

-- ====================================================================
-- [[ MODULE 4: ADVANCED COMBAT & PROJECTILE PIPELINE ]]
-- ====================================================================
createTextBox("Target Lock Name", CbTab, function(val) States.TargetPlayer = val end)
createToggle("Silent Aim Injection", CbTab, function(state) States.SilentAim = state end)
createToggle("Motion Prediction", CbTab, function(state) States.PredictionAim = state end)
createToggle("Raycast Wall Check", CbTab, function(state) States.VisibleCheck = state end)

local function getClosestTarget()
    local targetName = States.TargetPlayer:lower()
    if targetName ~= "" then
        local found = Players:FindFirstChild(States.TargetPlayer)
        if found and found.Character and found.Character:FindFirstChild("Head") then return found end
    end
    local closest = nil local shortestDist = States.FovRadius local mousePos = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                if States.VisibleCheck then
                    local parts = Camera:GetPartsObscuringTarget({Camera.CFrame.Position, head.Position}, {LocalPlayer.Character, p.Character})
                    if #parts > 0 then continue end
                end
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < shortestDist then closest = p; shortestDist = dist end
            end
        end
    end
    return closest
end

NetworkLayer:RegisterMiddleware("SilentAimHandler", 20, function(remote, args)
    if States.SilentAim then
        local name = remote.Name:lower()
        if name:find("fire") or name:find("shoot") or name:find("hit") or name:find("damage") then
            local target = getClosestTarget()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                local hitPart = target.Character.Head
                local targetPos = hitPart.Position
                if States.PredictionAim and target.Character:FindFirstChild("HumanoidRootPart") then
                    targetPos = targetPos + (target.Character.HumanoidRootPart.AssemblyLinearVelocity * (LocalPlayer:GetNetworkPing() + 0.03))
                end
                for idx, arg in ipairs(args) do
                    if typeof(arg) == "Vector3" then args[idx] = targetPos
                    elseif typeof(arg) == "Instance" and arg:IsA("BasePart") then args[idx] = hitPart end
                end
                return true, args
            end
        end
    end
    return true
end)

createToggle("Bullet Target Warp", CbTab, function(state) States.BulletWarp = state end)
createToggle("Bullet Duplication", CbTab, function(state) States.ProjectileDup = state end)

local function processProjectile(part)
    if not part:IsA("BasePart") then return end
    local name = part.Name:lower()
    if name:find("bullet") or name:find("projectile") then
        if States.BulletWarp then
            local target = getClosestTarget()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                part.CFrame = target.Character.Head.CFrame
            end
        end
        if States.ProjectileDup then
            local clone = part:Clone()
            clone.Parent = Workspace
            Debris:AddItem(clone, 3)
        end
    end
end
CollectionService:GetInstanceAddedSignal("Projectiles"):Connect(processProjectile)

-- ====================================================================
-- [[ MODULE 5: PACKET ORDERING ATTACK & REMOTE FUZZER ]]
-- ====================================================================
createToggle("Fuzz Remotes Core", NtTab, function(state)
    States.FuzzingActive = state
    if not state then return end
    
    local Payloads = {
        {Data = nil, Meta = "Primitive_Nil"},
        {Data = math.huge, Meta = "Float_Infinity"},
        {Data = 0/0, Meta = "Arithmetic_NaN"},
        {Data = Vector3.new(0/0, 0, 0), Meta = "Vector3_NaN"},
        {Data = string.rep("Z", 15000), Meta = "Buffer_Overflow_String"},
        {Data = {}, Meta = "Empty_Table"},
        {Data = function() end, Meta = "Closure_Injection"}
    }
    
    task.spawn(function()
        while States.FuzzingActive do
            for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") then
                    local name = remote.Name:lower()
                    if name:find("damage") or name:find("hit") or name:find("shoot") then
                        local payload = Payloads[math.random(1, #Payloads)]
                        pcall(function() remote:FireServer(payload.Data, "Head", Vector3.new(0,0,0)) end)
                    end
                end
            end
            task.wait(1 / States.BurstRate)
        end
    end)
end)

createTextBox("Fuzzer Speed Rate", NtTab, function(val) States.BurstRate = tonumber(val) or 10 end)
createToggle("Fake Lag (Delay Gate)", NtTab, function(state) States.FakeLag = state end)
createTextBox("Delay Power (Sec)", NtTab, function(val) States.LagPower = tonumber(val) or 0.2 end)

createToggle("Ordering Sequence Attack", NtTab, function(state) States.PacketOrderingAbuse = state end)
NetworkLayer:RegisterMiddleware("PacketOrdering", 5, function(remote, args)
    if States.PacketOrderingAbuse and remote.Name:lower():find("shoot") then
        local reloadRemote = ReplicatedStorage:FindFirstChild("Reload", true) or ReplicatedStorage:FindFirstChild("Inward", true)
        if reloadRemote and reloadRemote:IsA("RemoteEvent") then
            reloadRemote:FireServer()
            remote:FireServer(unpack(args))
            reloadRemote:FireServer()
            return false
        end
    end
end)

-- ====================================================================
-- [[ MODULE 6: COMPACT ESP POOL SYSTEM ]]
-- ====================================================================
createToggle("ESP Tracking Line", VsTab, function(state) States.EspTracers = state end)
createToggle("ESP Skeletal Frame", VsTab, function(state) States.EspSkeletons = state end)

local DrawingPool = {}
local PoolSize = 0
local MAX_POOL_SIZE = 120

local function getDrawingObject(objType)
    for _, obj in ipairs(DrawingPool) do
        if obj.Type == objType and not obj.InUse then
            obj.InUse = true
            return obj.Instance
        end
    end
    if PoolSize >= MAX_POOL_SIZE then
        for i = #DrawingPool, 1, -1 do
            local item = DrawingPool[i]
            if not item.InUse then
                safeDestroyDrawing(item.Instance)
                table.remove(DrawingPool, i)
                PoolSize = PoolSize - 1
            end
        end
    end
    local newInstance = Drawing.new(objType)
    table.insert(DrawingPool, {Type = objType, Instance = newInstance, InUse = true})
    PoolSize = PoolSize + 1
    return newInstance
end

local function resetDrawingUsage()
    for _, obj in ipairs(DrawingPool) do
        obj.InUse = false
        obj.Instance.Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    resetDrawingUsage()
    if not (States.EspTracers or States.EspSkeletons) then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local char = player.Character
            local hrp = char.HumanoidRootPart
            local head = char:FindFirstChild("Head")
            
            if States.EspTracers and head then
                local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local line = getDrawingObject("Line")
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(hrpPos.X, hrpPos.Y)
                    line.Color = Color3.fromRGB(255, 60, 60)
                    line.Thickness = 1.5
                    line.Visible = true
                end
            end
            
            if States.EspSkeletons and head then
                local bonePairs = {
                    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
                    {"UpperTorso", "LeftUpperArm"}, {"UpperTorso", "RightUpperArm"}
                }
                for _, bone in ipairs(bonePairs) do
                    local p1, p2 = char:FindFirstChild(bone[1]), char:FindFirstChild(bone[2])
                    if p1 and p2 then
                        local pos1, os1 = Camera:WorldToViewportPoint(p1.Position)
                        local pos2, os2 = Camera:WorldToViewportPoint(p2.Position)
                        if os1 and os2 then
                            local line = getDrawingObject("Line")
                            line.From = Vector2.new(pos1.X, pos1.Y)
                            line.To = Vector2.new(pos2.X, pos2.Y)
                            line.Color = Color3.fromRGB(0, 255, 180)
                            line.Thickness = 1
                            line.Visible = true
                        end
                    end
                end
            end
        end
    end
end)

-- ====================================================================
-- [[ MODULE 7: REPLAY SYSTEM RING BUFFER ]]
-- ====================================================================
-- Sửa lỗi thứ 3: Chuyển đổi CapturedFrames thành Ring Buffer hoàn chỉnh tránh chi phí O(n)
local MAX_REPLAY_FRAMES = 1000
local ReplayIndex = 1
local CapturedFrames = table.create(MAX_REPLAY_FRAMES)
local RecordingActive = false

createToggle("Record Replay Frame", VsTab, function(state)
    RecordingActive = state
    if state then 
        table.clear(CapturedFrames) 
        ReplayIndex = 1
    end
end)

RunService.Heartbeat:Connect(function()
    if not RecordingActive or States.Replaying then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        CapturedFrames[ReplayIndex] = {
            CFrame = hrp.CFrame,
            CamCFrame = Camera.CFrame
        }
        ReplayIndex = (ReplayIndex % MAX_REPLAY_FRAMES) + 1
    end
end)

createActionButton("Execute Replay Engine", VsTab, function()
    if #CapturedFrames == 0 or States.Replaying then return end
    States.Replaying = true
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local originalAnchored = hrp.Anchored
        hrp.Anchored = true
        
        -- Sắp xếp và đọc chính xác luồng dữ liệu tuần tự bắt đầu từ vị trí ghi hiện tại của Ring Buffer
        local start = ReplayIndex
        for i = 1, MAX_REPLAY_FRAMES do
            local readIdx = ((start + i - 2) % MAX_REPLAY_FRAMES) + 1
            local frame = CapturedFrames[readIdx]
            if frame then
                hrp.CFrame = frame.CFrame
                Camera.CFrame = frame.CamCFrame
                task.wait(0.015)
            end
        end
        hrp.Anchored = originalAnchored
    end
    States.Replaying = false
end)

task.spawn(function()
    while task.wait(0.5) do
        local ping = tonumber(string.format("%.1f", LocalPlayer:GetNetworkPing() * 1000))
        BenchLabel.Text = string.format("FPS: %d | Ping: %d ms | Pool Size: %d", CurrentFps, ping, PoolSize)
    end
end)

print("[SUITE V4.5 IMPLEMENTED SUCCESS]")
