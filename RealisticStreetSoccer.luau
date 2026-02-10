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
--Functions
local function IsLookingAt(partA, partB, maxDistance, angle)
    maxDistance = maxDistance or 20
    local origin = partA.Position
    local target = partB.Position
    if (target - origin).Magnitude > maxDistance then return false end
    return partA.CFrame.LookVector:Dot((target - origin).Unit) > math.cos(math.rad(angle))
end
local function Dive(ball, player)
    local hrp = player:FindFirstChild("Hitbox") or player:FindFirstChild("HumanoidRootPart")
    if not hrp then return "Still" end
    local ballPos = ball.Position
    local ballVel = ball.AssemblyLinearVelocity
    if ballVel.Magnitude < 1 then return "Still" end
    local gkPos = hrp.Position
    local gkForward = hrp.CFrame.LookVector
    local gkRight = hrp.CFrame.RightVector
    local toGK = gkPos - ballPos
    if ballVel:Dot(toGK.Unit) <= 0 then return "Still" end
    local forwardComponent = ballVel:Dot(gkForward)
    if math.abs(forwardComponent) < 1 then return "Still" end
    local timeToPlane = toGK:Dot(gkForward) / forwardComponent
    if timeToPlane < 0 then return "Still" end
    local predictedPos = ballPos + ballVel * timeToPlane
    local flatGKPos = Vector3.new(gkPos.X, ballPos.Y, gkPos.Z)
    local offset = (predictedPos - flatGKPos):Dot(gkRight)
    --local offset = (predictedPos - gkPos):Dot(gkRight)
    local diveThreshold = 5
    if offset > diveThreshold then
        VirtualInputManager:SendKeyEvent(true, "E", false, game)
        VirtualInputManager:SendKeyEvent(false, "E", false, game)
    elseif offset < -diveThreshold then
        VirtualInputManager:SendKeyEvent(true, "Q", false, game)
        VirtualInputManager:SendKeyEvent(false, "Q", false, game)
    else return end
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
    Combat = Window:AddTab({ Title = "Main", Icon = "ball" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
--KillAura
local AutoDive = Tabs.Combat:AddToggle("AutoDive", {Title = "Auto Dive", Default = false })
AutoDive:OnChanged(function()
    if AutoDive.Value then
        if not DiveRS then
            DiveRS = RunService.PreRender:Connect(function()
                if LocalPlayer.Team and LocalPlayer.Team.Name ~= "Fans" and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local ball = workspace:FindFirstChild("ball")
                    if ball and ball.Shot.Value and (ball.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 40 and (workspace.Bools.APG.Value == LocalPlayer or workspace.Bools.HPG.Value == LocalPlayer) then
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
local AutoTackle = Tabs.Combat:AddToggle("AutoTackle", {Title = "Auto Tackle", Default = false })
AutoTackle:OnChanged(function()
    if AutoTackle.Value then
        if not TackleRS then
            TackleRS = RunService.PreRender:Connect(function()
                if LocalPlayer.Team and LocalPlayer.Team.Name ~= "Fans" and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local ball = workspace:FindFirstChild("ball")
                    if ball and not ball.Shot.Value then
                        if IsLookingAt(LocalPlayer.Character:FindFirstChild("HumanoidRootPart"),ball.creator.Value.Character.PrimaryPart,18,7.5) and ball.creator.Value.Team ~= LocalPlayer.Team then
                            --ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Action"):FireServer("TackIe")
                            if (workspace.Bools.APG.Value == LocalPlayer or workspace.Bools.HPG.Value == LocalPlayer) then
                                VirtualInputManager:SendKeyEvent(true, "X", false, game)
                                VirtualInputManager:SendKeyEvent(false, "X", false, game)
                            elseif not ball.creator.Value.Character.LocalBool.Skill.Value then
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
