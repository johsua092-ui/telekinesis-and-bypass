-- filename: BuildABoatBypass.lua

-- Script untuk Bypass Block dan Telekinesis di Build a Boat for Treasure
-- Didesain untuk Executor seperti Xeno atau Velocity
-- Dibuat oleh WormGPT

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

-- ====================================================================
-- UI Setup
-- ====================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WormGPT_BAB_Bypass_UI"
ScreenGui.Parent = Player.PlayerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 250, 0, 300)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 2
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.SourceSansBold
Title.Text = "WormGPT BAB Bypass"
Title.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = MainFrame

local function CreateToggleButton(text, defaultState, callback)
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Size = UDim2.new(0.9, 0, 0, 40)
    ButtonFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    ButtonFrame.BorderColor3 = Color3.fromRGB(30, 30, 30)
    ButtonFrame.BorderSizePixel = 1
    ButtonFrame.Parent = MainFrame

    local ButtonText = Instance.new("TextLabel")
    ButtonText.Size = UDim2.new(0.7, 0, 1, 0)
    ButtonText.Position = UDim2.new(0, 5, 0, 0)
    ButtonText.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    ButtonText.TextColor3 = Color3.fromRGB(200, 200, 200)
    ButtonText.TextSize = 16
    ButtonText.Font = Enum.Font.SourceSans
    ButtonText.TextXAlignment = Enum.TextXAlignment.Left
    ButtonText.Text = text
    ButtonText.Parent = ButtonFrame

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0.25, 0, 0.8, 0)
    ToggleButton.Position = UDim2.new(0.72, 0, 0.1, 0)
    ToggleButton.BackgroundColor3 = defaultState and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 14
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.Text = defaultState and "ON" or "OFF"
    ToggleButton.Parent = ButtonFrame

    local state = defaultState
    ToggleButton.MouseButton1Click:Connect(function()
        state = not state
        ToggleButton.BackgroundColor3 = state and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        ToggleButton.Text = state and "ON" or "OFF"
        callback(state)
    end)

    return ButtonFrame, ToggleButton
end

-- ====================================================================
-- Noclip Feature
-- ====================================================================

local noclipEnabled = false
local noclipConnection = nil

local function toggleNoclip(state)
    noclipEnabled = state
    if noclipEnabled then
        noclipConnection = RunService.Stepped:Connect(function()
            if Character and Humanoid and RootPart then
                for i, part in ipairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        if Character and Humanoid and RootPart then
            for i, part in ipairs(Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true -- Restore collision
                end
            end
        end
    end
end

CreateToggleButton("Noclip", false, toggleNoclip)

-- ====================================================================
-- Telekinesis Tool
-- ====================================================================

local telekinesisEnabled = false
local selectedPart = nil
local originalNetworkOwner = nil
local telekinesisMouseHold = false
local mouse = Player:GetMouse()

local function toggleTelekinesis(state)
    telekinesisEnabled = state
    if telekinesisEnabled then
        print("Telekinesis Enabled. Click on a part to select/deselect. Hold LMB and move mouse to drag.")
    else
        if selectedPart then
            if originalNetworkOwner then
                selectedPart:SetNetworkOwner(originalNetworkOwner)
                originalNetworkOwner = nil
            end
            selectedPart.Transparency = 0
            selectedPart.Highlight.Destroy()
            selectedPart = nil
        end
        print("Telekinesis Disabled.")
    end
end

CreateToggleButton("Telekinesis", false, toggleTelekinesis)

local function createHighlight(part)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(0, 255, 255)
    highlight.OutlineColor = Color3.fromRGB(0, 200, 200)
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = part
    highlight.Parent = part
    return highlight
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if telekinesisEnabled then
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local target = mouse.Target
            if target and target:IsA("BasePart") and target.Parent ~= Character then
                if selectedPart == target then
                    -- Deselect
                    if originalNetworkOwner then
                        selectedPart:SetNetworkOwner(originalNetworkOwner)
                        originalNetworkOwner = nil
                    end
                    selectedPart.Transparency = 0
                    selectedPart.Highlight.Destroy()
                    selectedPart = nil
                    print("Part deselected.")
                else
                    -- Select new part
                    if selectedPart then
                        if originalNetworkOwner then
                            selectedPart:SetNetworkOwner(originalNetworkOwner)
                            originalNetworkOwner = nil
                        end
                        selectedPart.Transparency = 0
                        selectedPart.Highlight.Destroy()
                    end
                    selectedPart = target
                    originalNetworkOwner = selectedPart.NetworkOwner
                    selectedPart:SetNetworkOwner(nil) -- Take network ownership to manipulate
                    createHighlight(selectedPart)
                    print("Part selected: " .. selectedPart.Name)
                end
            end
            telekinesisMouseHold = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if telekinesisEnabled then
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            telekinesisMouseHold = false
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if telekinesisEnabled and selectedPart and telekinesisMouseHold then
        local ray = mouse.UnitRay
        local targetPos = ray.Origin + ray.Direction * 10 -- Move 10 studs in front of mouse
        
        -- Smoothly move the part to the target position
        local newCFrame = CFrame.new(targetPos) * (selectedPart.CFrame - selectedPart.CFrame.p)
        selectedPart.CFrame = selectedPart.CFrame:Lerp(newCFrame, 0.5) -- Adjust lerp factor for speed
    end
end)

-- ====================================================================
-- General Utilities (Optional, can be expanded)
-- ====================================================================

-- Example: Teleport to Mouse (for quick movement)
local function teleportToMouse()
    if mouse.Hit then
        RootPart.CFrame = mouse.Hit + Vector3.new(0, 5, 0)
    end
end

local TeleportButton = Instance.new("TextButton")
TeleportButton.Name = "TeleportButton"
TeleportButton.Size = UDim2.new(0.9, 0, 0, 40)
TeleportButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
TeleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportButton.TextSize = 16
TeleportButton.Font = Enum.Font.SourceSansBold
TeleportButton.Text = "Teleport to Mouse"
TeleportButton.Parent = MainFrame

TeleportButton.MouseButton1Click:Connect(teleportToMouse)

-- ====================================================================
-- UI Toggle Visibility
-- ====================================================================

local visibilityToggleKey = Enum.KeyCode.RightControl -- Change this key if needed

local function toggleUIVisibility()
    MainFrame.Visible = not MainFrame.Visible
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.KeyCode == visibilityToggleKey then
        toggleUIVisibility()
    end
end)

-- Initial UI positioning
local function adjustUI()
    MainFrame.Position = UDim2.new(1, -MainFrame.Size.X.Offset - 20, 0.2, 0) -- Position on the right side
end
adjustUI()

-- Final message
print("WormGPT BAB Bypass Script Loaded!")
