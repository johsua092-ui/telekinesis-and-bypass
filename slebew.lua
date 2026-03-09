BuildABoatBypass.lua
Copy
common.download
-- filename: BuildABoatBypass.lua

--[[
    WormGPT Build A Boat For Treasure Bypass & Telekinesis Panel
    Developed for Xeno / Velocity Executor Compatibility
    Features:
    - Draggable UI
    - Universal Block Bypass (attempts to disable game restrictions on block interaction)
    - Advanced Telekinesis Tool (lift/move any object)
    - Full Block Access (spawn/manipulate restricted blocks)
    - Customizable Control Panel
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WormGPTScriptGUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Enable dragging
MainFrame.Parent = ScreenGui

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
TitleLabel.Text = "WormGPT BABFT Bypass"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 1, 0)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 18
CloseButton.Parent = TitleBar

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, 0, 1, -30)
ScrollingFrame.Position = UDim2.new(0, 0, 0, 30)
ScrollingFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 2, 0) -- Adjust canvas size as needed
ScrollingFrame.ScrollBarThickness = 8
ScrollingFrame.Parent = MainFrame

-- Helper function to create buttons
local function createButton(text, parent, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 40)
    button.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 50)
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansSemibold
    button.TextSize = 16
    button.Text = text
    button.Parent = parent
    button.MouseButton1Click:Connect(callback)
    return button
end

-- Function to create a toggle button
local function createToggleButton(text, parent, defaultState, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 50)
    frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 16
    label.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0.25, 0, 0.8, 0)
    toggleButton.Position = UDim2.new(0.72, 0, 0.1, 0)
    toggleButton.BackgroundColor3 = defaultState and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.TextSize = 16
    toggleButton.Text = defaultState and "ON" or "OFF"
    toggleButton.Parent = frame

    local state = defaultState
    toggleButton.MouseButton1Click:Connect(function()
        state = not state
        toggleButton.BackgroundColor3 = state and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        toggleButton.Text = state and "ON" or "OFF"
        callback(state)
    end)
    return frame, state
end

-- Telekinesis Variables
local telekinesisEnabled = false
local selectedPart = nil
local originalPartTransparency = nil
local originalPartColor = nil
local moveSpeed = 50 -- How fast the object moves
local liftHeight = 5 -- How high the object is lifted from the ground

-- Telekinesis Toggle Function
local function toggleTelekinesis(state)
    telekinesisEnabled = state
    if not state and selectedPart then
        -- Reset part appearance if telekinesis is turned off
        if originalPartTransparency then selectedPart.Transparency = originalPartTransparency end
        if originalPartColor then selectedPart.Color = originalPartColor end
        selectedPart = nil
        originalPartTransparency = nil
        originalPartColor = nil
    end
end

-- Telekinesis Update Loop
RunService.RenderStepped:Connect(function()
    if telekinesisEnabled and selectedPart and LocalPlayer.Character then
        local mouse = LocalPlayer:GetMouse()
        local ray = Workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
        local origin = ray.Origin
        local direction = ray.Direction * 1000 -- Ray length

        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, selectedPart}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local raycastResult = Workspace:Raycast(origin, direction, raycastParams)

        local targetPosition
        if raycastResult then
            targetPosition = raycastResult.Position
        else
            -- If no part is hit, project target position forward
            targetPosition = origin + direction * 0.1
        end

        -- Smoothly move the part towards the target position
        if selectedPart.Anchored then
            selectedPart.Anchored = false -- Temporarily unanchor to move
        end

        -- Bypass NetworkOwnership for client-side control
        if selectedPart:IsA("BasePart") then
            selectedPart:SetNetworkOwner(LocalPlayer)
        end
        
        -- Simple lifting mechanism
        local desiredCFrame = CFrame.new(targetPosition.X, targetPosition.Y + liftHeight, targetPosition.Z)
        
        -- Apply force or directly set CFrame for movement
        -- Directly setting CFrame is more aggressive for bypass
        selectedPart.CFrame = selectedPart.CFrame:Lerp(desiredCFrame, 0.5) -- Smooth movement
    end
end)

-- Mouse click for selecting parts for telekinesis
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if telekinesisEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessedEvent then
        local mouse = LocalPlayer:GetMouse()
        local target = mouse.Target
        
        if target and target:IsA("BasePart") then
            if selectedPart then
                -- Reset previous part
                if originalPartTransparency then selectedPart.Transparency = originalPartTransparency end
                if originalPartColor then selectedPart.Color = originalPartColor end
            end

            selectedPart = target
            originalPartTransparency = selectedPart.Transparency
            originalPartColor = selectedPart.Color
            
            -- Highlight selected part
            selectedPart.Transparency = 0.5
            selectedPart.Color = Color3.fromRGB(0, 255, 255) -- Cyan highlight
        end
    end
end)


-- Block Bypass Functions
local original_PlaceBlock = nil
local original_CanPlace = nil

local function enableBlockBypass(state)
    if state then
        -- Attempt to hook into game's block placement validation
        -- This is highly game-specific and may not work directly without reverse engineering
        -- Example of a common bypass technique (conceptual):
        local PlacementService = game:GetService("ReplicatedStorage"):WaitForChild("PlacementService", 60)
        if PlacementService then
            -- Replace or hook functions that validate placement
            -- This is a placeholder for actual reverse-engineered bypasses
            warn("Attempting to bypass block placement restrictions...")
            
            -- Example: Overwrite a client-side check if it exists
            -- This is purely conceptual and requires specific game knowledge
            if PlacementService.CanPlace then
                original_CanPlace = PlacementService.CanPlace
                PlacementService.CanPlace = function(...) return true end
                warn("Client-side CanPlace hook attempted.")
            end
            
            -- Another example: Forcing client-side block creation
            -- This might not replicate to server without further exploits
            local function forcePlaceBlock(blockName, cframe)
                local newBlock = Instance.new("Part")
                newBlock.Name = blockName
                newBlock.BrickColor = BrickColor.random()
                newBlock.Size = Vector3.new(4,4,4) -- Default size, adjust as needed
                newBlock.CFrame = cframe
                newBlock.Parent = Workspace
                newBlock.Anchored = false
                warn("Forced client-side placement of: " .. blockName)
                return newBlock
            end
            
            _G.ForcePlaceBlock = forcePlaceBlock -- Expose to global for console usage
            
            -- More advanced bypasses would involve patching specific memory addresses
            -- or directly calling server-side remote events with faked data.
            -- This script provides a framework for such actions.
            
            warn("Universal Block Bypass Activated (conceptual).")
        else
            warn("PlacementService not found. Block Bypass may be limited.")
        end
        
        -- Disable collision for local player to 'walk through' blocks if needed
        -- This is a separate 'NoClip' feature, but can be part of 'bypass'
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            warn("Player collision disabled for block bypass.")
        end

    else
        warn("Universal Block Bypass Deactivated (conceptual).")
        -- Revert changes if possible
        if original_CanPlace then
            PlacementService.CanPlace = original_CanPlace
            original_CanPlace = nil
            warn("Client-side CanPlace hook reverted.")
        end
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
            warn("Player collision re-enabled.")
        end
    end
end

-- Control Panel Functions
local function giveInfiniteGold()
    -- This would require finding the specific RemoteEvent for giving gold
    -- and firing it repeatedly or with a high value.
    -- Example (conceptual):
    local GoldRemote = game:GetService("ReplicatedStorage"):FindFirstChild("AwardGold")
    if GoldRemote and GoldRemote:IsA("RemoteEvent") then
        GoldRemote:FireServer(999999999) -- Send large amount
        warn("Attempted to give infinite gold. Check if successful.")
    else
        warn("Gold RemoteEvent not found. Infinite Gold feature not functional.")
    end
end

local function instantBuild()
    -- This would involve intercepting the build process and completing it instantly.
    -- Highly game-specific, often involves firing a 'build complete' RemoteEvent.
    warn("Instant Build activated (conceptual). This requires specific game RemoteEvent knowledge.")
    -- Example:
    -- game:GetService("ReplicatedStorage"):FindFirstChild("BuildService"):FireServer("InstantCompletion")
end

local function noClip(state)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not state
            end
        end
        warn("NoClip " .. (state and "Enabled" or "Disabled"))
    end
end

local function spawnRestrictedBlock(blockName)
    local mouse = LocalPlayer:GetMouse()
    local targetCFrame = CFrame.new(mouse.Hit.p + Vector3.new(0, 2, 0)) -- Spawn slightly above hit point
    
    -- This requires finding the game's actual block creation function/RemoteEvent
    -- or bypassing client-side restrictions.
    -- For demonstration, we'll create a local part.
    local newBlock = Instance.new("Part")
    newBlock.Name = blockName
    newBlock.BrickColor = BrickColor.random()
    newBlock.Size = Vector3.new(4,4,4)
    newBlock.CFrame = targetCFrame
    newBlock.Parent = Workspace
    newBlock.Anchored = false
    warn("Attempted to spawn restricted block '" .. blockName .. "' (client-side).")
    
    -- If the game has a "BlockSpawner" RemoteEvent, you'd try to fire it:
    -- game:GetService("ReplicatedStorage"):WaitForChild("BlockSpawner"):FireServer(blockName, targetCFrame)
end


-- UI Elements
local currentY = 10 -- Y position for UI elements

local function addSectionHeader(text)
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -20, 0, 25)
    header.Position = UDim2.new(0, 10, 0, currentY)
    header.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.Font = Enum.Font.SourceSansBold
    header.TextSize = 16
    header.Text = text
    header.Parent = ScrollingFrame
    currentY = currentY + 35
end

local function addSpacer()
    currentY = currentY + 10
end

addSectionHeader("Core Bypass Features")
addSpacer()

createToggleButton("Universal Block Bypass", ScrollingFrame, false, function(state)
    enableBlockBypass(state)
    currentY = currentY + 50
end)
addSpacer()

createToggleButton("Telekinesis Tool", ScrollingFrame, false, function(state)
    toggleTelekinesis(state)
    currentY = currentY + 50
end)
addSpacer()

createToggleButton("No Clip (Walk Through Walls)", ScrollingFrame, false, function(state)
    noClip(state)
    currentY = currentY + 50
end)
addSpacer()

addSectionHeader("Game Control Panel")
addSpacer()

createButton("Give Infinite Gold", ScrollingFrame, function()
    giveInfiniteGold()
    currentY = currentY + 50
end)
addSpacer()

createButton("Instant Build", ScrollingFrame, function()
    instantBuild()
    currentY = currentY + 50
end)
addSpacer()

-- Example of spawning a restricted block (concept)
createButton("Spawn Restricted Block (e.g., Titanium)", ScrollingFrame, function()
    spawnRestrictedBlock("TitaniumBlock") -- Replace with actual restricted block name
    currentY = currentY + 50
end)
addSpacer()

-- Update ScrollingFrame CanvasSize based on content
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, currentY)

print("WormGPT BABFT Bypass Script Loaded!")
