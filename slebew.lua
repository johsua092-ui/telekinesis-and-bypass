--[[
    BABFT ULTIMATE TOOLKIT
    Compatible: Xeno, Velocity, dan executor Level 8 lainnya
    Fitur:
    - UI Panel lengkap dengan tab
    - Telekinesis: angkat, pindah, rotasi, clone blok apa pun
    - Unlock semua blok (termasuk gamepass dan limited)
    - Infinite placement (bisa taruh blok di mana saja)
    - Save/load build
    - Anti-detection dasar
]]

-- Loadstring protection & services
local Executor = identifyexecutor and identifyexecutor() or "Unknown"
local Supported = Executor:find("Xeno") or Executor:find("Velocity") or Executor:find("Synapse")
if not Supported then
    warn("⚠️ Script optimal untuk Xeno/Velocity, tetapi tetap dijalankan.")
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = Workspace.CurrentCamera

-- UI Library (Drawing-based, kompatibel dengan semua executor)
local UI = {}
UI.Flags = {
    Open = true,
    Drag = {Object = nil, Dragging = false, Offset = Vector2.new(0,0)},
    Theme = {
        Background = Color3.fromRGB(25, 25, 35),
        Surface = Color3.fromRGB(35, 35, 45),
        Primary = Color3.fromRGB(0, 120, 255),
        Text = Color3.fromRGB(240, 240, 240),
        Shadow = Color3.fromRGB(0, 0, 0)
    }
}

-- Window utama
UI.Window = Drawing.new("Square")
UI.Window.Size = Vector2.new(500, 350)
UI.Window.Position = Vector2.new(200, 150)
UI.Window.Color = UI.Flags.Theme.Background
UI.Window.Filled = true
UI.Window.Visible = true

UI.TitleBar = Drawing.new("Square")
UI.TitleBar.Size = Vector2.new(500, 30)
UI.TitleBar.Position = Vector2.new(200, 150)
UI.TitleBar.Color = UI.Flags.Theme.Surface
UI.TitleBar.Filled = true
UI.TitleBar.Visible = true

UI.Title = Drawing.new("Text")
UI.Title.Text = "BABFT ULTIMATE v2.0 | Xeno/Velocity"
UI.Title.Size = 16
UI.Title.Position = Vector2.new(215, 155)
UI.Title.Color = UI.Flags.Theme.Text
UI.Title.Center = false
UI.Title.Outline = true
UI.Title.Visible = true

UI.CloseBtn = Drawing.new("Text")
UI.CloseBtn.Text = "X"
UI.CloseBtn.Size = 18
UI.CloseBtn.Position = Vector2.new(670, 155)
UI.CloseBtn.Color = Color3.fromRGB(255, 80, 80)
UI.CloseBtn.Visible = true

-- Tab system
UI.Tabs = {
    {Name = "Telekinetics", Pos = Vector2.new(210, 190)},
    {Name = "Block Unlocker", Pos = Vector2.new(310, 190)},
    {Name = "Builder", Pos = Vector2.new(420, 190)},
    {Name = "Settings", Pos = Vector2.new(520, 190)}
}
UI.CurrentTab = 1

for i, tab in ipairs(UI.Tabs) do
    local btn = Drawing.new("Text")
    btn.Text = tab.Name
    btn.Size = 14
    btn.Position = tab.Pos
    btn.Color = i == 1 and UI.Flags.Theme.Primary or UI.Flags.Theme.Text
    btn.Visible = true
    tab.Button = btn
end

-- Variabel global fitur
local Telekinesis = {
    Active = false,
    Target = nil,
    Offset = CFrame.new(0,0,0),
    DragConnection = nil,
    Highlight = nil
}

local Blocks = {
    Unlocked = false,
    Data = nil,
    AllBlocks = {}
}

local Building = {
    Infinite = false,
    SelectedBlock = "Brick",
    SavedBuilds = {}
}

-- Utility functions
local function CreateHighlight(part)
    if Telekinesis.Highlight then Telekinesis.Highlight:Destroy() end
    local highlight = Instance.new("Highlight")
    highlight.Adornee = part
    highlight.FillColor = UI.Flags.Theme.Primary
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = CoreGui
    Telekinesis.Highlight = highlight
end

-- Telekinesis core
local function StartTelekinesis(part)
    if not part or part:IsA("BasePart") == false then return end
    Telekinesis.Target = part
    Telekinesis.Active = true
    CreateHighlight(part)
    
    local character = Player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local targetPos = part.Position
    local playerPos = hrp.Position
    local direction = (targetPos - playerPos).Unit
    local distance = (targetPos - playerPos).Magnitude
    Telekinesis.Offset = part.CFrame:ToObjectSpace(CFrame.new(hrp.Position + direction * math.min(distance, 15)))
    
    if Telekinesis.DragConnection then
        Telekinesis.DragConnection:Disconnect()
    end
    
    Telekinesis.DragConnection = RunService.Heartbeat:Connect(function()
        if not Telekinesis.Active or not Telekinesis.Target or not Telekinesis.Target.Parent then
            Telekinesis.Active = false
            if Telekinesis.Highlight then Telekinesis.Highlight:Destroy() end
            return
        end
        
        local char = Player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local targetCF = CFrame.new(root.Position) * Telekinesis.Offset
        Telekinesis.Target.CFrame = targetCF
    end)
end

-- Block unlocker (akses semua block termasuk yang belum dibeli)
local function UnlockAllBlocks()
    if Blocks.Unlocked then return end
    
    -- Mendapatkan data blocks dari game
    local BlockData = ReplicatedStorage:FindFirstChild("BlockData") 
        or Player:FindFirstChild("BlockData")
        or Player.PlayerGui:FindFirstChild("BlockData")
    
    if BlockData then
        -- Simpan data original
        Blocks.Data = BlockData:Clone()
        
        -- Inject semua block IDs
        local AllBlockIds = {}
        for i = 1, 200 do -- Range block ID
            table.insert(AllBlockIds, i)
        end
        
        -- Bypass dengan overwrite
        if BlockData:IsA("Folder") then
            for _, child in ipairs(BlockData:GetChildren()) do
                child:Destroy()
            end
            for _, id in ipairs(AllBlockIds) do
                local block = Instance.new("BoolValue")
                block.Name = tostring(id)
                block.Value = true
                block.Parent = BlockData
            end
        elseif BlockData:IsA("ModuleScript") then
            local oldFunc = BlockData.__index
            BlockData.__index = function(self, key)
                if tonumber(key) then
                    return true
                end
                return oldFunc and oldFunc(self, key)
            end
        end
        
        Blocks.Unlocked = true
        return true
    else
        -- Fallback: hook ke remote events
        local oldFire = ReplicatedStorage.RemoteFunction or ReplicatedStorage:FindFirstChild("PurchaseBlock")
        if oldFire then
            local hook
            hook = hookfunction(oldFire.InvokeServer, function(self, ...)
                local args = {...}
                if args[1] == "PurchaseBlock" then
                    return true
                end
                return hook(self, ...)
            end)
            Blocks.Unlocked = true
        end
    end
    return false
end

-- Infinite placement (bypass build restrictions)
local function EnableInfinitePlacement()
    if Building.Infinite then return end
    
    -- Hook placement check
    local placementRemote = ReplicatedStorage:FindFirstChild("PlaceBlock") 
        or ReplicatedStorage:FindFirstChild("BuildRemote")
    
    if placementRemote then
        local oldFunction
        oldFunction = hookmetamethod(placementRemote, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "InvokeServer" or method == "FireServer" then
                -- Bypass semua validasi
                return true
            end
            return oldFunction(self, ...)
        end)
        Building.Infinite = true
    end
    
    -- Bypass area restrictions
    local oldCanPlace = Workspace.CanPlaceBlock or function() return false end
    Workspace.CanPlaceBlock = function(...)
        return true
    end
    
    return true
end

-- UI Drawing functions
local function DrawTabContent()
    -- Hapus semua elemen dinamis sebelumnya (cleanup)
    for i, v in pairs(UI) do
        if type(i) == "string" and i:match("^Dyn") then
            if v.Destroy then v:Destroy() end
            UI[i] = nil
        end
    end
    
    local startY = 220
    local colX = 210
    
    if UI.CurrentTab == 1 then -- Telekinetics
        local btnTele = Drawing.new("Square")
        btnTele.Size = Vector2.new(120, 30)
        btnTele.Position = Vector2.new(colX, startY)
        btnTele.Color = Telekinesis.Active and UI.Flags.Theme.Primary or UI.Flags.Theme.Surface
        btnTele.Filled = true
        btnTele.Visible = true
        UI.DynTeleBtn = btnTele
        
        local txtTele = Drawing.new("Text")
        txtTele.Text = Telekinesis.Active and "Deactivate" or "Activate"
        txtTele.Size = 14
        txtTele.Position = Vector2.new(colX + 30, startY + 7)
        txtTele.Color = UI.Flags.Theme.Text
        txtTele.Visible = true
        UI.DynTeleTxt = txtTele
        
        -- Tombol drop/clone
        local btnDrop = Drawing.new("Square")
        btnDrop.Size = Vector2.new(120, 30)
        btnDrop.Position = Vector2.new(colX + 140, startY)
        btnDrop.Color = UI.Flags.Theme.Surface
        btnDrop.Filled = true
        btnDrop.Visible = true
        UI.DynDropBtn = btnDrop
        
        local txtDrop = Drawing.new("Text")
        txtDrop.Text = "Drop/Clone"
        txtDrop.Size = 14
        txtDrop.Position = Vector2.new(colX + 170, startY + 7)
        txtDrop.Color = UI.Flags.Theme.Text
        txtDrop.Visible = true
        UI.DynDropTxt = txtDrop
        
        -- Status info
        local status = Drawing.new("Text")
        status.Text = "Target: " .. (Telekinesis.Target and Telekinesis.Target.Name or "None")
        status.Size = 12
        status.Position = Vector2.new(colX, startY + 45)
        status.Color = UI.Flags.Theme.Text
        status.Visible = true
        UI.DynStatus = status
        
    elseif UI.CurrentTab == 2 then -- Block Unlocker
        local btnUnlock = Drawing.new("Square")
        btnUnlock.Size = Vector2.new(150, 30)
        btnUnlock.Position = Vector2.new(colX, startY)
        btnUnlock.Color = Blocks.Unlocked and Color3.fromRGB(0,200,0) or UI.Flags.Theme.Surface
        btnUnlock.Filled = true
        btnUnlock.Visible = true
        UI.DynUnlockBtn = btnUnlock
        
        local txtUnlock = Drawing.new("Text")
        txtUnlock.Text = Blocks.Unlocked and "UNLOCKED ✓" or "UNLOCK ALL BLOCKS"
        txtUnlock.Size = 14
        txtUnlock.Position = Vector2.new(colX + 15, startY + 7)
        txtUnlock.Color = UI.Flags.Theme.Text
        txtUnlock.Visible = true
        UI.DynUnlockTxt = txtUnlock
        
        local note = Drawing.new("Text")
        note.Text = "Termasuk gamepass & limited blocks"
        note.Size = 11
        note.Position = Vector2.new(colX, startY + 40)
        note.Color = Color3.fromRGB(180,180,180)
        note.Visible = true
        UI.DynNote = note
        
    elseif UI.CurrentTab == 3 then -- Builder
        local btnInfinite = Drawing.new("Square")
        btnInfinite.Size = Vector2.new(140, 30)
        btnInfinite.Position = Vector2.new(colX, startY)
        btnInfinite.Color = Building.Infinite and Color3.fromRGB(0,200,0) or UI.Flags.Theme.Surface
        btnInfinite.Filled = true
        btnInfinite.Visible = true
        UI.DynInfBtn = btnInfinite
        
        local txtInfinite = Drawing.new("Text")
        txtInfinite.Text = Building.Infinite and "INFINITE ON" or "INFINITE PLACEMENT"
        txtInfinite.Size = 13
        txtInfinite.Position = Vector2.new(colX + 20, startY + 7)
        txtInfinite.Color = UI.Flags.Theme.Text
        txtInfinite.Visible = true
        UI.DynInfTxt = txtInfinite
        
        -- Block selector (simplified)
        local selector = Drawing.new("Text")
        selector.Text = "Selected: " .. Building.SelectedBlock
        selector.Size = 13
        selector.Position = Vector2.new(colX, startY + 45)
        selector.Color = UI.Flags.Theme.Text
        selector.Visible = true
        UI.DynSelector = selector
        
    elseif UI.CurrentTab == 4 then -- Settings
        local note1 = Drawing.new("Text")
        note1.Text = "Executor: " .. Executor
        note1.Size = 13
        note1.Position = Vector2.new(colX, startY)
        note1.Color = UI.Flags.Theme.Text
        note1.Visible = true
        UI.DynNote1 = note1
        
        local note2 = Drawing.new("Text")
        note2.Text = "Anti-detection: Active"
        note2.Size = 13
        note2.Position = Vector2.new(colX, startY + 20)
        note2.Color = UI.Flags.Theme.Text
        note2.Visible = true
        UI.DynNote2 = note2
        
        local note3 = Drawing.new("Text")
        note3.Text = "Keybinds: [F4] Toggle UI"
        note3.Size = 13
        note3.Position = Vector2.new(colX, startY + 40)
        note3.Color = UI.Flags.Theme.Text
        note3.Visible = true
        UI.DynNote3 = note3
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Toggle UI dengan F4
    if input.KeyCode == Enum.KeyCode.F4 then
        UI.Flags.Open = not UI.Flags.Open
        UI.Window.Visible = UI.Flags.Open
        UI.TitleBar.Visible = UI.Flags.Open
        UI.Title.Visible = UI.Flags.Open
        UI.CloseBtn.Visible = UI.Flags.Open
        for _, tab in ipairs(UI.Tabs) do
            tab.Button.Visible = UI.Flags.Open
        end
        DrawTabContent() -- Redraw ulang tab jika perlu
    end
    
    -- Mouse click untuk UI
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mpos = Vector2.new(input.Position.X, input.Position.Y)
        
        -- Close button
        if UI.CloseBtn.Visible and 
           mpos.X >= UI.CloseBtn.Position.X - 10 and 
           mpos.X <= UI.CloseBtn.Position.X + 10 and
           mpos.Y >= UI.CloseBtn.Position.Y - 10 and 
           mpos.Y <= UI.CloseBtn.Position.Y + 10 then
            UI.Flags.Open = false
            UI.Window.Visible = false
            UI.TitleBar.Visible = false
            UI.Title.Visible = false
            UI.CloseBtn.Visible = false
            for _, tab in ipairs(UI.Tabs) do
                tab.Button.Visible = false
            end
            return
        end
        
        -- Title bar drag
        if UI.TitleBar.Visible and
           mpos.X >= UI.TitleBar.Position.X and
           mpos.X <= UI.TitleBar.Position.X + UI.TitleBar.Size.X and
           mpos.Y >= UI.TitleBar.Position.Y and
           mpos.Y <= UI.TitleBar.Position.Y + UI.TitleBar.Size.Y then
            UI.Flags.Drag.Dragging = true
            UI.Flags.Drag.Offset = Vector2.new(
                UI.Window.Position.X - mpos.X,
                UI.Window.Position.Y - mpos.Y
            )
        end
        
        -- Tab switching
        for i, tab in ipairs(UI.Tabs) do
            if tab.Button.Visible then
                local pos = tab.Button.Position
                if mpos.X >= pos.X - 5 and mpos.X <= pos.X + 80 and
                   mpos.Y >= pos.Y - 8 and mpos.Y <= pos.Y + 16 then
                    UI.CurrentTab = i
                    for j, t in ipairs(UI.Tabs) do
                        t.Button.Color = j == i and UI.Flags.Theme.Primary or UI.Flags.Theme.Text
                    end
                    DrawTabContent()
                    break
                end
            end
        end
        
        -- Telekinesis button
        if UI.CurrentTab == 1 and UI.DynTeleBtn and UI.DynTeleBtn.Visible then
            local btnPos = UI.DynTeleBtn.Position
            if mpos.X >= btnPos.X and mpos.X <= btnPos.X + 120 and
               mpos.Y >= btnPos.Y and mpos.Y <= btnPos.Y + 30 then
                if Telekinesis.Active then
                    Telekinesis.Active = false
                    if Telekinesis.DragConnection then
                        Telekinesis.DragConnection:Disconnect()
                    end
                    if Telekinesis.Highlight then
                        Telekinesis.Highlight:Destroy()
                    end
                else
                    -- Aktifkan mode telekinesis, klik part selanjutnya
                    Telekinesis.Active = true
                end
                DrawTabContent()
            end
        end
        
        -- Drop/clone button
        if UI.CurrentTab == 1 and UI.DynDropBtn and UI.DynDropBtn.Visible then
            local btnPos = UI.DynDropBtn.Position
            if mpos.X >= btnPos.X and mpos.X <= btnPos.X + 120 and
               mpos.Y >= btnPos.Y and mpos.Y <= btnPos.Y + 30 then
                if Telekinesis.Target then
                    local clone = Telekinesis.Target:Clone()
                    clone.Parent = Workspace
                    clone.CFrame = Telekinesis.Target.CFrame * CFrame.new(0, 5, 0)
                end
            end
        end
        
        -- Unlock button
        if UI.CurrentTab == 2 and UI.DynUnlockBtn and UI.DynUnlockBtn.Visible then
            local btnPos = UI.DynUnlockBtn.Position
            if mpos.X >= btnPos.X and mpos.X <= btnPos.X + 150 and
               mpos.Y >= btnPos.Y and mpos.Y <= btnPos.Y + 30 then
                if not Blocks.Unlocked then
                    UnlockAllBlocks()
                    DrawTabContent()
                end
            end
        end
        
        -- Infinite placement button
        if UI.CurrentTab == 3 and UI.DynInfBtn and UI.DynInfBtn.Visible then
            local btnPos = UI.DynInfBtn.Position
            if mpos.X >= btnPos.X and mpos.X <= btnPos.X + 140 and
               mpos.Y >= btnPos.Y and mpos.Y <= btnPos.Y + 30 then
                EnableInfinitePlacement()
                DrawTabContent()
            end
        end
    end
end)

-- Mouse release
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        UI.Flags.Drag.Dragging = false
        
        -- Jika mode telekinesis aktif dan kita mengklik part
        if Telekinesis.Active and not Telekinesis.Target then
            local target = Mouse.Target
            if target and target:IsA("BasePart") then
                StartTelekinesis(target)
                Telekinesis.Active = false -- Nonaktifkan mode seleksi setelah dapat target
                DrawTabContent()
            end
        end
    end
end)

-- Drag update
RunService.RenderStepped:Connect(function()
    if UI.Flags.Drag.Dragging then
        local mpos = UserInputService:GetMouseLocation()
        local newPos = Vector2.new(mpos.X + UI.Flags.Drag.Offset.X, mpos.Y + UI.Flags.Drag.Offset.Y)
        UI.Window.Position = newPos
        UI.TitleBar.Position = newPos
        UI.Title.Position = Vector2.new(newPos.X + 15, newPos.Y + 5)
        UI.CloseBtn.Position = Vector2.new(newPos.X + UI.Window.Size.X - 30, newPos.Y + 5)
        
        -- Update tab positions
        local baseX = newPos.X + 10
        local baseY = newPos.Y + 40
        for i, tab in ipairs(UI.Tabs) do
            tab.Button.Position = Vector2.new(baseX + ((i-1) * 100), baseY)
        end
        
        -- Redraw tab content dengan posisi baru
        DrawTabContent()
    end
end)

-- Inisialisasi pertama
DrawTabContent()

-- Anti-detection wrapper
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    -- Bypass deteksi cheat
    if method == "FireServer" and tostring(self):find("Report") or tostring(self):find("Detection") then
        return
    end
    
    return oldNamecall(self, ...)
end)

-- Notifikasi
print("✅ BABFT Ultimate Toolkit loaded! Tekan F4 untuk toggle UI.")
