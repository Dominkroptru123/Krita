--[[ 
    KRITA UI LIBRARY - Night Replica (Purple Edition)
    "100% Visual Replica of Night UI with Simplified Code"
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Krita = {}

--// Theme Configuration
local Theme = {
    Main = Color3.fromRGB(18, 18, 18),       -- Dark Background
    Sidebar = Color3.fromRGB(12, 12, 12),    -- Darker Sidebar
    Accent = Color3.fromRGB(155, 80, 255),   -- Purple (Krita)
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(120, 120, 120),
    ItemBG = Color3.fromRGB(25, 25, 25),     -- Module Background
    ItemStroke = Color3.fromRGB(40, 40, 40)
}

--// Utility
local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

local function CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.ItemStroke
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

function Krita:CreateWindow(options)
    local WindowName = options.Name or "Krita"
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KritaNightReplica"
    ScreenGui.Parent = RunService:IsStudio() and game.Players.LocalPlayer.PlayerGui or CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Container
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Theme.Main
    MainFrame.Position = UDim2.new(0.5, -350, 0.5, -225)
    MainFrame.Size = UDim2.new(0, 700, 0, 450)
    MainFrame.ClipsDescendants = true
    CreateCorner(MainFrame, 10)

    -- Dragging Logic
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Sidebar (Left)
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Parent = MainFrame
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.Size = UDim2.new(0, 180, 1, 0)
    Sidebar.BorderSizePixel = 0
    CreateCorner(Sidebar, 10)
    
    -- Fix Sidebar Corner (Left side rounded only logic visually masked by container)
    local SidebarCover = Instance.new("Frame") -- Covers right corners of sidebar
    SidebarCover.Parent = Sidebar
    SidebarCover.BackgroundColor3 = Theme.Sidebar
    SidebarCover.BorderSizePixel = 0
    SidebarCover.Position = UDim2.new(1, -10, 0, 0)
    SidebarCover.Size = UDim2.new(0, 10, 1, 0)
    SidebarCover.ZIndex = 0

    -- Logo
    local Logo = Instance.new("TextLabel")
    Logo.Name = "Logo"
    Logo.Parent = Sidebar
    Logo.BackgroundTransparency = 1
    Logo.Position = UDim2.new(0, 20, 0, 20)
    Logo.Size = UDim2.new(0, 140, 0, 30)
    Logo.Font = Enum.Font.GothamBold
    Logo.Text = WindowName
    Logo.TextColor3 = Theme.Text
    Logo.TextSize = 22
    Logo.TextXAlignment = Enum.TextXAlignment.Left

    -- Tabs Container
    local TabButtonContainer = Instance.new("Frame")
    TabButtonContainer.Parent = Sidebar
    TabButtonContainer.BackgroundTransparency = 1
    TabButtonContainer.Position = UDim2.new(0, 10, 0, 70)
    TabButtonContainer.Size = UDim2.new(1, -20, 1, -80)

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabButtonContainer
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 8)

    -- Content Area (Right)
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Parent = MainFrame
    ContentArea.BackgroundColor3 = Theme.Main
    ContentArea.BackgroundTransparency = 1
    ContentArea.Position = UDim2.new(0, 190, 0, 10)
    ContentArea.Size = UDim2.new(1, -200, 1, -20)
    
    local Window = {
        Tabs = {}
    }

    local firstTab = true

    function Window:Tab(name, iconId)
        local Tab = {
            Name = name,
            Items = {}
        }

        -- Tab Button
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name
        TabBtn.Parent = TabButtonContainer
        TabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabBtn.BackgroundTransparency = 1 -- Default hidden
        TabBtn.Size = UDim2.new(1, 0, 0, 40)
        TabBtn.AutoButtonColor = false
        TabBtn.Text = ""
        CreateCorner(TabBtn, 8)

        local TabTitle = Instance.new("TextLabel")
        TabTitle.Parent = TabBtn
        TabTitle.BackgroundTransparency = 1
        TabTitle.Position = UDim2.new(0, 15, 0, 0)
        TabTitle.Size = UDim2.new(1, -15, 1, 0)
        TabTitle.Font = Enum.Font.GothamMedium
        TabTitle.Text = name
        TabTitle.TextColor3 = Theme.TextDim
        TabTitle.TextSize = 14
        TabTitle.TextXAlignment = Enum.TextXAlignment.Left
        TabTitle.ZIndex = 2

        -- Selected Indicator (The blue/purple background)
        local TabBG = Instance.new("Frame")
        TabBG.Parent = TabBtn
        TabBG.BackgroundColor3 = Theme.Accent
        TabBG.Size = UDim2.new(1, 0, 1, 0)
        TabBG.BackgroundTransparency = 1
        TabBG.ZIndex = 1
        CreateCorner(TabBG, 8)

        -- Tab Content Page
        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Parent = ContentArea
        Page.BackgroundTransparency = 1
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Theme.Accent
        Page.Visible = false

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = Page
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 10)

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
        end)

        -- Tab Selection Logic
        local function Activate()
            -- Reset all tabs
            for _, btn in pairs(TabButtonContainer:GetChildren()) do
                if btn:IsA("TextButton") then
                    TweenService:Create(btn.Frame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                    TweenService:Create(btn.TextLabel, TweenInfo.new(0.2), {TextColor3 = Theme.TextDim}):Play()
                end
            end
            for _, p in pairs(ContentArea:GetChildren()) do
                if p:IsA("ScrollingFrame") then p.Visible = false end
            end

            -- Activate this tab
            Page.Visible = true
            TweenService:Create(TabBG, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            TweenService:Create(TabTitle, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end

        TabBtn.MouseButton1Click:Connect(Activate)

        if firstTab then
            Activate()
            firstTab = false
        end

        -- ELEMENTS --

        function Tab:Toggle(options)
            local toggleName = options.Name or "Toggle"
            local default = options.Default or false
            local callback = options.Callback or function() end
            
            local Toggled = default

            local ToggleFrame = Instance.new("TextButton")
            ToggleFrame.Name = toggleName
            ToggleFrame.Parent = Page
            ToggleFrame.BackgroundColor3 = Theme.ItemBG
            ToggleFrame.Size = UDim2.new(1, -5, 0, 45)
            ToggleFrame.AutoButtonColor = false
            ToggleFrame.Text = ""
            CreateCorner(ToggleFrame, 6)
            CreateStroke(ToggleFrame, Theme.ItemStroke, 1)

            local Title = Instance.new("TextLabel")
            Title.Parent = ToggleFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 15, 0, 0)
            Title.Size = UDim2.new(0.7, 0, 1, 0)
            Title.Font = Enum.Font.GothamMedium
            Title.Text = toggleName
            Title.TextColor3 = Theme.Text
            Title.TextSize = 14
            Title.TextXAlignment = Enum.TextXAlignment.Left

            -- Switch Graphic
            local Switch = Instance.new("Frame")
            Switch.Parent = ToggleFrame
            Switch.BackgroundColor3 = Toggled and Theme.Accent or Color3.fromRGB(50, 50, 50)
            Switch.Position = UDim2.new(1, -50, 0.5, -10)
            Switch.Size = UDim2.new(0, 40, 0, 20)
            CreateCorner(Switch, 20)

            local Circle = Instance.new("Frame")
            Circle.Parent = Switch
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Circle.Position = Toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            Circle.Size = UDim2.new(0, 16, 0, 16)
            CreateCorner(Circle, 16)

            ToggleFrame.MouseButton1Click:Connect(function()
                Toggled = not Toggled
                callback(Toggled)
                
                local targetColor = Toggled and Theme.Accent or Color3.fromRGB(50, 50, 50)
                local targetPos = Toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                
                TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
                TweenService:Create(Circle, TweenInfo.new(0.2), {Position = targetPos}):Play()
            end)
        end

        function Tab:Slider(options)
            local sliderName = options.Name or "Slider"
            local min = options.Min or 0
            local max = options.Max or 100
            local default = options.Default or min
            local callback = options.Callback or function() end

            local SliderFrame = Instance.new("Frame")
            SliderFrame.Name = sliderName
            SliderFrame.Parent = Page
            SliderFrame.BackgroundColor3 = Theme.ItemBG
            SliderFrame.Size = UDim2.new(1, -5, 0, 60)
            CreateCorner(SliderFrame, 6)
            CreateStroke(SliderFrame, Theme.ItemStroke, 1)

            local Title = Instance.new("TextLabel")
            Title.Parent = SliderFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 15, 0, 10)
            Title.Size = UDim2.new(1, -30, 0, 20)
            Title.Font = Enum.Font.GothamMedium
            Title.Text = sliderName
            Title.TextColor3 = Theme.Text
            Title.TextSize = 14
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local ValueDisplay = Instance.new("TextLabel")
            ValueDisplay.Parent = SliderFrame
            ValueDisplay.BackgroundTransparency = 1
            ValueDisplay.Position = UDim2.new(0, 15, 0, 10)
            ValueDisplay.Size = UDim2.new(1, -30, 0, 20)
            ValueDisplay.Font = Enum.Font.Gotham
            ValueDisplay.Text = tostring(default)
            ValueDisplay.TextColor3 = Theme.TextDim
            ValueDisplay.TextSize = 14
            ValueDisplay.TextXAlignment = Enum.TextXAlignment.Right

            local SliderBar = Instance.new("Frame")
            SliderBar.Parent = SliderFrame
            SliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            SliderBar.Position = UDim2.new(0, 15, 0, 40)
            SliderBar.Size = UDim2.new(1, -30, 0, 6)
            CreateCorner(SliderBar, 3)

            local Fill = Instance.new("Frame")
            Fill.Parent = SliderBar
            Fill.BackgroundColor3 = Theme.Accent
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            CreateCorner(Fill, 3)

            local Trigger = Instance.new("TextButton")
            Trigger.Parent = SliderBar
            Trigger.BackgroundTransparency = 1
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.Text = ""

            local dragging = false

            local function Update(input)
                local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local val = math.floor(min + ((max - min) * pos))
                
                TweenService:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
                ValueDisplay.Text = tostring(val)
                callback(val)
            end

            Trigger.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    Update(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    Update(input)
                end
            end)
        end

        function Tab:Button(options)
            local btnName = options.Name or "Button"
            local callback = options.Callback or function() end

            local BtnFrame = Instance.new("TextButton")
            BtnFrame.Parent = Page
            BtnFrame.BackgroundColor3 = Theme.ItemBG
            BtnFrame.Size = UDim2.new(1, -5, 0, 40)
            BtnFrame.AutoButtonColor = false
            BtnFrame.Font = Enum.Font.GothamMedium
            BtnFrame.Text = btnName
            BtnFrame.TextColor3 = Theme.Text
            BtnFrame.TextSize = 14
            CreateCorner(BtnFrame, 6)
            CreateStroke(BtnFrame, Theme.ItemStroke, 1)

            BtnFrame.MouseButton1Click:Connect(function()
                callback()
                TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent}):Play()
                task.wait(0.1)
                TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3 = Theme.ItemBG}):Play()
            end)
        end

        return Tab
    end

    return Window
end

return Krita
