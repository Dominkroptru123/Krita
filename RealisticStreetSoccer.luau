if not game:IsLoaded() then
    game.Loaded:Wait()
end
local loadstart = os.clock()
--GUI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local Options = Fluent.Options
--Services
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
--Variables
local LocalPlayer = Players.LocalPlayer
--RS
local DiveRS
local TackleRS
local DekeRS
--Functions
local function IsLookingAt(partA, partB, maxDistance, angle)
    maxDistance = maxDistance or 20
    local origin = partA.Position
    local target = partB.Position
    if (target - origin).Magnitude > maxDistance then return false end
    return partA.CFrame.LookVector:Dot((target - origin).Unit) >= math.cos(math.rad(angle))
end
local function IsTackling(model)
    if model.HumanoidRootPart.AssemblyLinearVelocity.X^2 + model.HumanoidRootPart.AssemblyLinearVelocity.Z^2 >= 1600 then
        return true
    end
    return false
end
local function Dive(ball, player)
    local hrp = player:FindFirstChild("Hitbox") or player:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local ballPos = ball.Position
    local ballVel = ball.AssemblyLinearVelocity
    if ballVel.Magnitude < 1 then return end
    local gkPos = hrp.Position
    local gkForward = hrp.CFrame.LookVector
    if (ballPos - gkPos).Magnitude >= 50 then return end
    local relativePos = ballPos - gkPos
    local denominator = ballVel:Dot(gkForward)
    if math.abs(denominator) < 0.01 then return end
    local timeToPlane = -relativePos:Dot(gkForward) / denominator
    if timeToPlane <= 0 then return end
    local predictedPos = ballPos + ballVel * timeToPlane + 0.5 * Vector3.new(0, -workspace.Gravity, 0) * (timeToPlane ^ 2)
    local offset = (predictedPos - gkPos):Dot(hrp.CFrame.RightVector)
    local diveThreshold = 8
    local jumpThreshold = 8
    if offset > diveThreshold then
        VirtualInputManager:SendKeyEvent(true, "E", false, game)
        VirtualInputManager:SendKeyEvent(false, "E", false, game)
    elseif offset < -diveThreshold then
        VirtualInputManager:SendKeyEvent(true, "Q", false, game)
        VirtualInputManager:SendKeyEvent(false, "Q", false, game)
    else return end
    if predictedPos.Y - gkPos.Y > jumpThreshold then
        VirtualInputManager:SendKeyEvent(true, "Space", false, game)
        VirtualInputManager:SendKeyEvent(false, "Space", false, game)
    end
end
--Fluent
local Window = Fluent:CreateWindow({
    Title = "Krita " .. "1.0",
    SubTitle = "by Dominkroptru123",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.K
})
local Tabs = {
    Combat = Window:AddTab({ Title = "Main", Icon = "volleyball" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
--Auto Dive
local AutoDive = Tabs.Combat:AddToggle("AutoDive", {Title = "Auto Dive", Default = false })
AutoDive:OnChanged(function()
    if AutoDive.Value then
        if not DiveRS then
            DiveRS = RunService.PreRender:Connect(function()
                if LocalPlayer.Team and LocalPlayer.Team.Name ~= "Fans" and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local ball = workspace:FindFirstChild("ball")
                    if ball and ball.AssemblyLinearVelocity.Magnitude >= math.sqrt(2500) and (workspace.Bools.APG.Value == LocalPlayer or workspace.Bools.HPG.Value == LocalPlayer) then
                        Dive(ball, LocalPlayer.Character)
                    end
                end
            end)
        end
    else
        if DiveRS then
            DiveRS:Disconnect()
            DiveRS = nil
        end
    end
end)
--Auto Tackle
local AutoTackle = Tabs.Combat:AddToggle("AutoTackle", {Title = "Auto Tackle", Default = false })
AutoTackle:OnChanged(function()
    if AutoTackle.Value then
        if not TackleRS then
            TackleRS = RunService.PreRender:Connect(function()
                if LocalPlayer.Team and LocalPlayer.Team.Name ~= "Fans" and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local ball = workspace:FindFirstChild("ball")
                    if ball and not ball.Shot.Value and ball.creator.Value.Team ~= LocalPlayer.Team and ball.creator.Value.Character then
                        local hb1 = ball.creator.Value.Character.PrimaryPart
                        local hb2 = LocalPlayer.Character.PrimaryPart
                        if hb1 and hb2 and IsLookingAt(hb2,hb1,25,15) then
                            --ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Action"):FireServer("TackIe")
                            if (workspace.Bools.APG.Value == LocalPlayer or workspace.Bools.HPG.Value == LocalPlayer) then
                                VirtualInputManager:SendKeyEvent(true, "X", false, game)
                                VirtualInputManager:SendKeyEvent(false, "X", false, game)
                            else
                                VirtualInputManager:SendKeyEvent(true, "E", false, game)
                                VirtualInputManager:SendKeyEvent(false, "E", false, game)
                            end
                        end
                    end
                end
            end)
        end
    else
        if TackleRS then
            TackleRS:Disconnect()
            TackleRS = nil
        end
    end
end)
local AutoDeke = Tabs.Combat:AddToggle("AutoDeke", {Title = "Auto Deke", Default = false })
AutoDeke:OnChanged(function()
    if AutoDeke.Value then
        if not DekeRS then
            DekeRS = RunService.PreRender:Connect(function()
                if LocalPlayer.Team and LocalPlayer.Team.Name ~= "Fans" and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local ball = workspace:FindFirstChild("ball")
                    if ball and not ball.Shot.Value and ball.creator.Value == LocalPlayer and not (workspace.Bools.APG.Value == LocalPlayer or workspace.Bools.HPG.Value == LocalPlayer) then
                        for _, i in Players:GetChildren() do
                            if i ~= LocalPlayer and i.Character and i.Character:FindFirstChild("HumanoidRootPart") then
                                if IsLookingAt(i.Character.PrimaryPart,LocalPlayer.Character.PrimaryPart,35,30) and IsTackling(i.Character) then
                                    ReplicatedStorage.Remotes.Action:FireServer("Deke")
                                end
                            end
                        end
                    end
                end
            end)
        end
    else
        if DekeRS then
            DekeRS:Disconnect()
            DekeRS = nil
        end
    end
end)
local AntiAFK = Tabs.Combat:AddToggle("AntiAFK", {Title = "Anti AFK", Default = false })
AntiAFK:OnChanged(function()
    if AntiAFK.Value then
        repeat task.wait(20)
            if LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity.X < 1 and LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity.Z < 1 then
                VirtualInputManager:SendKeyEvent(true, "W", false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, "W", false, game)
            end
        until not AntiAFK.Value
    end
end)
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("Krita")
SaveManager:SetFolder("Krita/RealisticStreetSoccer")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
Fluent:Notify({
    Title = "Krita",
    Content = "The script has been loaded in " .. string.format("%.2f", os.clock() - loadstart) .. "seconds",
    Duration = 5
})
SaveManager:LoadAutoloadConfig()
