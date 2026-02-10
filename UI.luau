local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Krita = {
    Flags = {},
    Theme = {
        Accent = Color3.fromRGB(160, 100, 255), -- Purple Krita Theme
        Background = Color3.fromRGB(20, 20, 20),
        Section = Color3.fromRGB(25, 25, 25),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(150, 150, 150),
        Outline = Color3.fromRGB(50, 50, 50)
    },
    Folder = "KritaConfig"
}

local Library = Krita
local Connections = {}

--// Utility //--
local function MakeDraggable(topbarObject, object)
    local Dragging, DragInput, DragStart, StartPos
    table.insert(Connections, topbarObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            DragStart = input.Position
            StartPos = object.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then Dragging = false end
            end)
        end
    end))
    table.insert(Connections, topbarObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then DragInput = input end
    end))
    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local Delta = input.Position - DragStart
            object.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end))
end

--// Config System //--
function Library:SaveConfig(name)
    if not isfolder(Library.Folder) then makefolder(Library.Folder) end
    local json = HttpService:JSONEncode(Library.Flags)
    writefile(Library.Folder .. "/" .. name .. ".json", json)
end

function Library:LoadConfig(name)
    if isfile(Library.Folder .. "/" .. name .. ".json") then
        local data = HttpService:JSONDecode(readfile(Library.Folder .. "/" .. name .. ".json"))
        for flag, value in pairs(data) do
            if Library.Flags[flag] ~= nil then
                -- Here you would trigger the callback, simplified for this replica to just set value
                Library.Flags[flag] = value
                -- Note: In a full replica, you'd need to find the element and update its visual state here
            end
        end
    end
end

function Library:Unload()
    for _, conn in pairs(Connections) do conn:Disconnect() end
    if game.CoreGui:FindFirstChild("KritaUI") then
        game.CoreGui.KritaUI:Destroy()
    end
end

--// Main UI //--
function Library:Window(options)
    local Name = options.Name or "Krita"
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KritaUI"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Library.Theme.Background
    Main.BorderColor3 = Library.Theme.Accent
    Main.BorderSizePixel = 1
    Main.Position = UDim2.new(0.5, -275, 0.5, -175)
    Main.Size = UDim2.new(0, 550, 0, 350)
    
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = Main
    TopBar.BackgroundColor3 = Library.Theme.Section
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 30)
    
    local Title = Instance.new("TextLabel")
    Title.Parent = TopBar
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.Size = UDim2.new(0, 200, 1, 0)
    Title.Font = Enum.Font.Code
    Title.Text = Name
    Title.TextColor3 = Library.Theme.Accent
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- Decoration Line
    local Line = Instance.new("Frame")
    Line.Parent = TopBar
    Line.BackgroundColor3 = Library.Theme.Accent
    Line.BorderSizePixel = 0
    Line.Position = UDim2.new(0, 0, 1, 0)
    Line.Size = UDim2.new(1, 0, 0, 1)

    MakeDraggable(TopBar, Main)

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "Tabs"
    TabContainer.Parent = Main
    TabContainer.Active = true
    TabContainer.BackgroundColor3 = Library.Theme.Section
    TabContainer.BorderSizePixel = 0
    TabContainer.Position = UDim2.new(0, 0, 0, 31)
    TabContainer.Size = UDim2.new(0, 120, 1, -31)
    TabContainer.ScrollBarThickness = 0

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabContainer
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 0)

    local PageContainer = Instance.new("Frame")
    PageContainer.Name = "Pages"
    PageContainer.Parent = Main
    PageContainer.BackgroundTransparency = 1
    PageContainer.Position = UDim2.new(0, 130, 0, 40)
    PageContainer.Size = UDim2.new(1, -140, 1, -50)

    local WindowLogic = {}
    local FirstTab = true

    function WindowLogic:Tab(name)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = name
        TabButton.Parent = TabContainer
        TabButton.BackgroundColor3 = Library.Theme.Section
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(1, 0, 0, 35)
        TabButton.Font = Enum.Font.Code
        TabButton.Text = name
        TabButton.TextColor3 = Library.Theme.TextDim
        TabButton.TextSize = 13

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "_Page"
        Page.Parent = PageContainer
        Page.BackgroundTransparency = 1
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.ScrollBarThickness = 2
        Page.Visible = false
        
        -- Two columns (Left/Right) logic simplified to single list for "simpler replica" 
        -- but styled to look like Groupboxes
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = Page
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 10)
        
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
        end)

        if FirstTab then
            Page.Visible = true
            TabButton.TextColor3 = Library.Theme.Text
            TabButton.BackgroundColor3 = Library.Theme.Background -- Visual indicator
            FirstTab = false
        end

        TabButton.MouseButton1Click:Connect(function()
            for _, p in pairs(PageContainer:GetChildren()) do p.Visible = false end
            for _, t in pairs(TabContainer:GetChildren()) do 
                if t:IsA("TextButton") then 
                    t.TextColor3 = Library.Theme.TextDim 
                    t.BackgroundColor3 = Library.Theme.Section
                end 
            end
            
            Page.Visible = true
            TabButton.TextColor3 = Library.Theme.Text
            TabButton.BackgroundColor3 = Library.Theme.Background
        end)

        local TabLogic = {}

        function TabLogic:Section(name)
            local Groupbox = Instance.new("Frame")
            Groupbox.Name = name
            Groupbox.Parent = Page
            Groupbox.BackgroundColor3 = Library.Theme.Background
            Groupbox.BorderColor3 = Library.Theme.Outline
            Groupbox.Size = UDim2.new(1, -5, 0, 0) -- Auto sized
            
            local GroupTitle = Instance.new("TextLabel")
            GroupTitle.Parent = Groupbox
            GroupTitle.BackgroundColor3 = Library.Theme.Background
            GroupTitle.BorderColor3 = Library.Theme.Outline -- To hide line behind text
            GroupTitle.BorderSizePixel = 0
            GroupTitle.Position = UDim2.new(0, 10, 0, -8)
            GroupTitle.Size = UDim2.new(0, 0, 0, 15) -- Auto width would require textbounds
            GroupTitle.Font = Enum.Font.Code
            GroupTitle.Text = " " .. name .. " "
            GroupTitle.TextColor3 = Library.Theme.Accent
            GroupTitle.TextSize = 12
            GroupTitle.AutomaticSize = Enum.AutomaticSize.X

            local GroupContent = Instance.new("Frame")
            GroupContent.Parent = Groupbox
            GroupContent.BackgroundTransparency = 1
            GroupContent.Position = UDim2.new(0, 10, 0, 15)
            GroupContent.Size = UDim2.new(1, -20, 1, -20)
            
            local GroupLayout = Instance.new("UIListLayout")
            GroupLayout.Parent = GroupContent
            GroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
            GroupLayout.Padding = UDim.new(0, 5)

            GroupLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Groupbox.Size = UDim2.new(1, -5, 0, GroupLayout.AbsoluteContentSize.Y + 25)
            end)

            local SectionLogic = {}

            function SectionLogic:Toggle(options)
                local tname = options.Name
                local def = options.Default or false
                local callback = options.Callback or function() end
                
                Library.Flags[tname] = def

                local ToggleFrame = Instance.new("TextButton")
                ToggleFrame.Parent = GroupContent
                ToggleFrame.BackgroundTransparency = 1
                ToggleFrame.Size = UDim2.new(1, 0, 0, 20)
                ToggleFrame.Text = ""

                local Label = Instance.new("TextLabel")
                Label.Parent = ToggleFrame
                Label.BackgroundTransparency = 1
                Label.Position = UDim2.new(0, 20, 0, 0)
                Label.Size = UDim2.new(1, -20, 1, 0)
                Label.Font = Enum.Font.Code
                Label.Text = tname
                Label.TextColor3 = Library.Theme.TextDim
                Label.TextSize = 13
                Label.TextXAlignment = Enum.TextXAlignment.Left

                local Box = Instance.new("Frame")
                Box.Parent = ToggleFrame
                Box.BackgroundColor3 = Library.Theme.Section
                Box.BorderColor3 = Library.Theme.Outline
                Box.Size = UDim2.new(0, 14, 0, 14)
                Box.Position = UDim2.new(0, 0, 0.5, -7)

                local Indicator = Instance.new("Frame")
                Indicator.Parent = Box
                Indicator.BackgroundColor3 = Library.Theme.Accent
                Indicator.BorderSizePixel = 0
                Indicator.Position = UDim2.new(0, 2, 0, 2)
                Indicator.Size = UDim2.new(1, -4, 1, -4)
                Indicator.Visible = def
                
                if def then Label.TextColor3 = Library.Theme.Text end

                ToggleFrame.MouseButton1Click:Connect(function()
                    Library.Flags[tname] = not Library.Flags[tname]
                    Indicator.Visible = Library.Flags[tname]
                    Label.TextColor3 = Library.Flags[tname] and Library.Theme.Text or Library.Theme.TextDim
                    callback(Library.Flags[tname])
                end)
            end

            function SectionLogic:Button(options)
                local bname = options.Name
                local callback = options.Callback or function() end

                local ButtonFrame = Instance.new("TextButton")
                ButtonFrame.Parent = GroupContent
                ButtonFrame.BackgroundColor3 = Library.Theme.Section
                ButtonFrame.BorderColor3 = Library.Theme.Outline
                ButtonFrame.Size = UDim2.new(1, 0, 0, 22)
                ButtonFrame.Font = Enum.Font.Code
                ButtonFrame.Text = bname
                ButtonFrame.TextColor3 = Library.Theme.Text
                ButtonFrame.TextSize = 13

                ButtonFrame.MouseButton1Click:Connect(function()
                    callback()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.1), {BackgroundColor3 = Library.Theme.Accent}):Play()
                    task.wait(0.1)
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.1), {BackgroundColor3 = Library.Theme.Section}):Play()
                end)
            end

            function SectionLogic:Slider(options)
                local sname = options.Name
                local min = options.Min or 0
                local max = options.Max or 100
                local def = options.Default or min
                local callback = options.Callback or function() end

                Library.Flags[sname] = def

                local SliderFrame = Instance.new("Frame")
                SliderFrame.Parent = GroupContent
                SliderFrame.BackgroundTransparency = 1
                SliderFrame.Size = UDim2.new(1, 0, 0, 35)

                local Label = Instance.new("TextLabel")
                Label.Parent = SliderFrame
                Label.BackgroundTransparency = 1
                Label.Size = UDim2.new(1, 0, 0, 15)
                Label.Font = Enum.Font.Code
                Label.Text = sname
                Label.TextColor3 = Library.Theme.Text
                Label.TextSize = 13
                Label.TextXAlignment = Enum.TextXAlignment.Left

                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.Parent = SliderFrame
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.Size = UDim2.new(1, 0, 0, 15)
                ValueLabel.Font = Enum.Font.Code
                ValueLabel.Text = tostring(def)
                ValueLabel.TextColor3 = Library.Theme.TextDim
                ValueLabel.TextSize = 13
                ValueLabel.TextXAlignment = Enum.TextXAlignment.Right

                local SlideBG = Instance.new("TextButton") -- Using TextButton for input
                SlideBG.Parent = SliderFrame
                SlideBG.BackgroundColor3 = Library.Theme.Section
                SlideBG.BorderColor3 = Library.Theme.Outline
                SlideBG.Position = UDim2.new(0, 0, 0, 20)
                SlideBG.Size = UDim2.new(1, 0, 0, 10)
                SlideBG.Text = ""
                SlideBG.AutoButtonColor = false

                local Fill = Instance.new("Frame")
                Fill.Parent = SlideBG
                Fill.BackgroundColor3 = Library.Theme.Accent
                Fill.BorderSizePixel = 0
                Fill.Size = UDim2.new((def - min)/(max - min), 0, 1, 0)

                local dragging = false
                local function UpdateSlide(input)
                    local pos = math.clamp((input.Position.X - SlideBG.AbsolutePosition.X) / SlideBG.AbsoluteSize.X, 0, 1)
                    local val = math.floor(min + ((max - min) * pos))
                    
                    Fill.Size = UDim2.new(pos, 0, 1, 0)
                    ValueLabel.Text = tostring(val)
                    Library.Flags[sname] = val
                    callback(val)
                end

                SlideBG.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        UpdateSlide(input)
                    end
                end)

                table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end))

                table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateSlide(input)
                    end
                end))
            end

            return SectionLogic
        end

        return TabLogic
    end
    
    return WindowLogic
end

return Krita
