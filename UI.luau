local Krita = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Configuration
local Font = Enum.Font.Gotham
local TextSize = 14
local AccentColor = Color3.fromRGB(140, 80, 255) -- Purple
local BackgroundColor = Color3.fromRGB(25, 25, 25)
local ElementColor = Color3.fromRGB(35, 35, 35)

function Krita:CreateWindow(options)
    local Title = options.Name or "Krita UI"
    
    local LibraryInstance = Instance.new("ScreenGui")
    LibraryInstance.Name = "KritaLib"
    LibraryInstance.Parent = RunService:IsStudio() and game.Players.LocalPlayer.PlayerGui or CoreGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = LibraryInstance
    MainFrame.BackgroundColor3 = BackgroundColor
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    MainFrame.Size = UDim2.new(0, 500, 0, 350)
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = MainFrame
    
    -- Dragging Logic
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Title Bar
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = MainFrame
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.Size = UDim2.new(1, -30, 0, 40)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = Title
    TitleLabel.TextColor3 = AccentColor
    TitleLabel.TextSize = 18
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Container for Tabs
    local TabContainer = Instance.new("Frame")
    TabContainer.Parent = MainFrame
    TabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TabContainer.BorderSizePixel = 0
    TabContainer.Position = UDim2.new(0, 10, 0, 45)
    TabContainer.Size = UDim2.new(0, 120, 1, -55)
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 4)
    TabCorner.Parent = TabContainer

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabContainer
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)

    local TabListPadding = Instance.new("UIPadding")
    TabListPadding.Parent = TabContainer
    TabListPadding.PaddingTop = UDim.new(0, 5)
    TabListPadding.PaddingLeft = UDim.new(0, 5)
    
    -- Container for Pages (Elements)
    local PageContainer = Instance.new("Frame")
    PageContainer.Parent = MainFrame
    PageContainer.BackgroundTransparency = 1
    PageContainer.Position = UDim2.new(0, 140, 0, 45)
    PageContainer.Size = UDim2.new(1, -150, 1, -55)

    local Window = {}
    local FirstTab = true

    function Window:CreateTab(name)
        -- Create Tab Button
        local TabButton = Instance.new("TextButton")
        TabButton.Parent = TabContainer
        TabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabButton.BackgroundTransparency = 1
        TabButton.Size = UDim2.new(1, -10, 0, 30)
        TabButton.Font = Font
        TabButton.Text = name
        TabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        TabButton.TextSize = TextSize
        
        -- Create Page Frame
        local Page = Instance.new("ScrollingFrame")
        Page.Parent = PageContainer
        Page.BackgroundTransparency = 1
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.ScrollBarThickness = 2
        Page.Visible = false
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = Page
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 5)

        local PagePadding = Instance.new("UIPadding")
        PagePadding.Parent = Page
        PagePadding.PaddingTop = UDim.new(0, 5)
        PagePadding.PaddingLeft = UDim.new(0, 5)
        PagePadding.PaddingRight = UDim.new(0, 5)

        -- Auto Canvas Size
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
        end)

        -- Tab Selection Logic
        if FirstTab then
            Page.Visible = true
            TabButton.TextColor3 = AccentColor
            FirstTab = false
        end

        TabButton.MouseButton1Click:Connect(function()
            for _, v in pairs(PageContainer:GetChildren()) do
                if v:IsA("ScrollingFrame") then v.Visible = false end
            end
            for _, v in pairs(TabContainer:GetChildren()) do
                if v:IsA("TextButton") then v.TextColor3 = Color3.fromRGB(150, 150, 150) end
            end
            Page.Visible = true
            TabButton.TextColor3 = AccentColor
        end)

        local Tab = {}

        function Tab:CreateButton(options)
            local ButtonFrame = Instance.new("TextButton")
            ButtonFrame.Parent = Page
            ButtonFrame.BackgroundColor3 = ElementColor
            ButtonFrame.Size = UDim2.new(1, 0, 0, 35)
            ButtonFrame.Font = Font
            ButtonFrame.Text = ""
            ButtonFrame.AutoButtonColor = false
            
            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 4)
            BtnCorner.Parent = ButtonFrame
            
            local BtnText = Instance.new("TextLabel")
            BtnText.Parent = ButtonFrame
            BtnText.BackgroundTransparency = 1
            BtnText.Position = UDim2.new(0, 10, 0, 0)
            BtnText.Size = UDim2.new(1, -10, 1, 0)
            BtnText.Font = Font
            BtnText.Text = options.Name or "Button"
            BtnText.TextColor3 = Color3.fromRGB(255, 255, 255)
            BtnText.TextSize = TextSize
            BtnText.TextXAlignment = Enum.TextXAlignment.Left

            ButtonFrame.MouseButton1Click:Connect(function()
                local tween = TweenService:Create(ButtonFrame, TweenInfo.new(0.1), {BackgroundColor3 = AccentColor})
                tween:Play()
                tween.Completed:Wait()
                TweenService:Create(ButtonFrame, TweenInfo.new(0.1), {BackgroundColor3 = ElementColor}):Play()
                
                if options.Callback then options.Callback() end
            end)
        end

        function Tab:CreateToggle(options)
            local toggled = options.Default or false
            
            local ToggleFrame = Instance.new("TextButton")
            ToggleFrame.Parent = Page
            ToggleFrame.BackgroundColor3 = ElementColor
            ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
            ToggleFrame.AutoButtonColor = false
            ToggleFrame.Text = ""
            
            local TogCorner = Instance.new("UICorner")
            TogCorner.CornerRadius = UDim.new(0, 4)
            TogCorner.Parent = ToggleFrame

            local TogText = Instance.new("TextLabel")
            TogText.Parent = ToggleFrame
            TogText.BackgroundTransparency = 1
            TogText.Position = UDim2.new(0, 10, 0, 0)
            TogText.Size = UDim2.new(1, -50, 1, 0)
            TogText.Font = Font
            TogText.Text = options.Name or "Toggle"
            TogText.TextColor3 = Color3.fromRGB(255, 255, 255)
            TogText.TextSize = TextSize
            TogText.TextXAlignment = Enum.TextXAlignment.Left

            local CheckBox = Instance.new("Frame")
            CheckBox.Parent = ToggleFrame
            CheckBox.AnchorPoint = Vector2.new(1, 0.5)
            CheckBox.Position = UDim2.new(1, -10, 0.5, 0)
            CheckBox.Size = UDim2.new(0, 20, 0, 20)
            CheckBox.BackgroundColor3 = toggled and AccentColor or Color3.fromRGB(50, 50, 50)
            
            local CheckCorner = Instance.new("UICorner")
            CheckCorner.CornerRadius = UDim.new(0, 4)
            CheckCorner.Parent = CheckBox

            ToggleFrame.MouseButton1Click:Connect(function()
                toggled = not toggled
                local targetColor = toggled and AccentColor or Color3.fromRGB(50, 50, 50)
                TweenService:Create(CheckBox, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
                if options.Callback then options.Callback(toggled) end
            end)
        end

        function Tab:CreateSlider(options)
            local min = options.Min or 0
            local max = options.Max or 100
            local default = options.Default or min
            local callback = options.Callback or function() end
            
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Parent = Page
            SliderFrame.BackgroundColor3 = ElementColor
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
            
            local SlideCorner = Instance.new("UICorner")
            SlideCorner.CornerRadius = UDim.new(0, 4)
            SlideCorner.Parent = SliderFrame
            
            local SlideText = Instance.new("TextLabel")
            SlideText.Parent = SliderFrame
            SlideText.BackgroundTransparency = 1
            SlideText.Position = UDim2.new(0, 10, 0, 5)
            SlideText.Size = UDim2.new(1, -20, 0, 20)
            SlideText.Font = Font
            SlideText.Text = options.Name or "Slider"
            SlideText.TextColor3 = Color3.fromRGB(255, 255, 255)
            SlideText.TextSize = TextSize
            SlideText.TextXAlignment = Enum.TextXAlignment.Left
            
            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Parent = SliderFrame
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Position = UDim2.new(0, 10, 0, 5)
            ValueLabel.Size = UDim2.new(1, -20, 0, 20)
            ValueLabel.Font = Font
            ValueLabel.Text = tostring(default)
            ValueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            ValueLabel.TextSize = TextSize
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            
            local SliderBar = Instance.new("Frame")
            SliderBar.Parent = SliderFrame
            SliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            SliderBar.Position = UDim2.new(0, 10, 0, 30)
            SliderBar.Size = UDim2.new(1, -20, 0, 6)
            
            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(1, 0)
            BarCorner.Parent = SliderBar
            
            local SliderFill = Instance.new("Frame")
            SliderFill.Parent = SliderBar
            SliderFill.BackgroundColor3 = AccentColor
            SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            
            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = SliderFill
            
            local Trigger = Instance.new("TextButton")
            Trigger.Parent = SliderBar
            Trigger.BackgroundTransparency = 1
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.Text = ""
            
            local draggingSlider = false
            
            local function update(input)
                local sizeX = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                SliderFill.Size = UDim2.new(sizeX, 0, 1, 0)
                local value = math.floor(min + ((max - min) * sizeX))
                ValueLabel.Text = tostring(value)
                callback(value)
            end
            
            Trigger.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = true
                    update(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update(input)
                end
            end)
        end

        return Tab
    end

    return Window
end

return Krita
