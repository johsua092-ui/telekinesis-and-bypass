[[
    KRY5.2 Extended - BABFT Dominator Suite
    Tujuan: Memberikan kontrol absolut atas lingkungan permainan.
    Fitur: UI, Telekinesis Universal, Unlock All Blocks, System Inspector.
]]

-- Mencegah eksekusi ganda dan konflik
if _G.BABFTDominatorLoaded then
    return
end
_G.BABFTDominatorLoaded = true

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Pustaka UI yang ringkas untuk panel kontrol
local UI = {}
local dragToggle, dragSpeed, dragStart, startPos

local function CreateWindow(title)
    local screenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    screenGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = UDim2.new(0, 500, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 255)
    mainFrame.BorderSizePixel = 2
    mainFrame.Active = true
    mainFrame.Draggable = true

    local header = Instance.new("Frame", mainFrame)
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = Color3.fromRGB(80, 80, 255)

    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = UDim2.new(1, -10, 1, 0)
    titleLabel.Position = UDim2.new(0, 5, 0, 0)
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextSize = 18

    local contentFrame = Instance.new("ScrollingFrame", mainFrame)
    contentFrame.Size = UDim2.new(1, -10, 1, -35)
    contentFrame.Position = UDim2.new(0, 5, 0, 35)
    contentFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    contentFrame.BorderSizePixel = 0
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

    local layout = Instance.new("UIListLayout", contentFrame)
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    return contentFrame
end

local function AddButton(parent, text, callback)
    local button = Instance.new("TextButton", parent)
    button.Size = UDim2.new(1, -10, 0, 30)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.BorderColor3 = Color3.fromRGB(80, 80, 255)
    button.Text = text
    button.Font = Enum.Font.SourceSans
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 16
    
    button.MouseButton1Click:Connect(callback)
    
    parent.CanvasSize = UDim2.new(0, 0, 0, parent.UIListLayout.AbsoluteContentSize.Y)
    return button
end

local function AddToggle(parent, text, callback)
    local toggled = false
    local button = AddButton(parent, "[OFF] " .. text, nil)
    
    button.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
 button.Text = "[ON] " .. text
 button.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
        else
 button.Text = "[OFF] " .. text
 button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end
        callback(toggled)
    end)
    return button
end

-- ===================================
-- FUNGSI INTI & MANIPULASI SISTEM
-- ===================================

-- Fungsi untuk mendapatkan semua block yang ada di dalam game
local function GetAllGameBlocks()
    -- Ini adalah daftar yang diperluas. Game dapat menambahkan lebih banyak.
    return {
        "Wood Block", "Plastic Block", "Metal Block", "Stone Block", "Obsidian Block",
        "Glass Block", "Titanium Block", "Gold Block", "Fabric Block", "Marble Block",
        "Neon Block", "Ice Block", "Brick Block", "Sand Block", "TNT", "Hinge Block",
        "Seat", "Pilot Seat", "Car Wheel", "Spike Block", "Motor", "Servo", "Suspension",
        "Spring", "Piston", "Portal", "Jet Turbine", "Rocket Engine", "Firework",
        "Harpoon", "Cannon", "Light Bulb", "Balloon", "Propeller", "Wing", "Fin",
        "Butter Block", "Cake", "Present", "Dragon Egg", "Stair", "Wedge", "Corner Wedge",
        "Cylinder", "Sphere", "Half Block", "Half Wedge", "Half Cylinder", "Half Sphere",
        "Sign", "Painting", "Camera", "Lever", "Button", "Switch", "Timer Block", "Sensor Block",
        "Delay Block", "Logic Block", "Big Wheel", "Small Wheel", "Glow Block", "Force Field"
    }
end

-- Fungsi membuka semua block di inventory (secara client-side)
local function UnlockAllBlocks()
    pcall(function()
        local inv = LocalPlayer.PlayerGui.MainUI.BuildMenu.BlockInventory
        local blockData = getrenv()._G.ItemData
        local allBlocks = GetAllGameBlocks()

        for _, blockName in pairs(allBlocks) do
 -- Memaksa penambahan item ke cache inventory client
 if not inv:FindFirstChild(blockName) then
 if blockData[blockName] then
 local fakeItem = {}
 fakeItem.Name = blockName
 fakeItem.Amount = 999
 -- Ini adalah simulasi, path dan struktur data mungkin perlu disesuaikan
 -- dengan versi game saat ini
 table.insert(getrenv()._G.ClientInventoryCache, fakeItem)
 end
 end
        end
        -- Memaksa UI untuk refresh
        inv.Visible = false
        inv.Visible = true
    end)
end

-- Fungsi Telekinesis Universal
local telekinesisTarget = nil
local telekinesisConnection
local function ToggleTelekinesis(enabled)
    if enabled then
        local originalTarget
        telekinesisConnection = RunService.RenderStepped:Connect(function()
 local target = Mouse.Target
 if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
 if target and target.Parent ~= workspace then target = target.Parent end -- Handle model parts
 if target and target:IsA("BasePart") and not target:IsA("Terrain") then
 if not telekinesisTarget then
 telekinesisTarget = target
 originalTarget = target
 
 -- Bypass semua proteksi fisika secara client-side
 pcall(function()
 telekinesisTarget
