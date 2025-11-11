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
local CollectionService = game:GetService("CollectionService")
--Variables
local localplayer = game.Players.LocalPlayer
local KillAuraTarget = {}
local NetManaged = ReplicatedStorage.rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged
--Functions
local function IsExistInTable(var, table)
    for _, v in ipairs(table) do
        if v == var then
            return true
        end
    end
    return false
end
local function IsAlive(Player, IsCharacter)
    if (not IsCharacter and Player and Player.Character) or IsCharacter then
        local Char = Player
        if not IsCharacter then
            Char = Char.Character
        end
        local Humanoid = Char:FindFirstChild("Humanoid") :: Humanoid
        if Humanoid and (Humanoid:GetState() ~= Enum.HumanoidStateType.Dead or Humanoid.Health > 0.05) then
            if Char.PrimaryPart then
                return true
            end
        end
    end
    return false
end
local function getNearestEntity(range: number)
    local nearestCharacter = nil
    local shortestDistance = range
    local Root
    local entityType = "NPCs" -- default value

    local character = localplayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    for _, v in CollectionService:GetTagged("entity") do
        local player = Players:GetPlayerFromCharacter(v)
        if player then
            if player.Team == localplayer.Team then
                continue
            end
            if not IsAlive(player, false) then
                continue -- skip dead players
            end
        end

        local myPosition = character.HumanoidRootPart.Position

        if player then
            local distance = (v.PrimaryPart.Position - myPosition).Magnitude
            if distance <= shortestDistance then
                shortestDistance = distance
                nearestCharacter = v
                Root = v.PrimaryPart
                entityType = "Players"
            end
        else
            if not IsAlive(v, true) then
                continue -- skip dead NPCs
            end

            local part
            for _, v2 in v:GetChildren() do
                if v2:IsA("BasePart") then
                    part = v2
                    break
                end
            end

            if part then
                local distance = (part.Position - myPosition).Magnitude
                if distance <= shortestDistance then
                    shortestDistance = distance
                    nearestCharacter = v
                    Root = part
                    entityType = "NPCs"
                end
            end
        end
    end

    return nearestCharacter, Root, entityType
end
local Window = Fluent:CreateWindow({
    Title = "Krita " .. "1.0",
    SubTitle = "by Dominkroptru123",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.RightShift
})
local Tabs = {
    Combat = Window:AddTab({ Title = "Combat", Icon = "sword" }),
    Utility = Window:AddTab({ Title = "Utility", Icon = "wrench" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
--KillAura
local KillAura = Tabs.Combat:AddToggle("KillAura", {Title = "Kill Aura", Default = false })
local KillAuraRange = Tabs.Combat:AddSlider("KillAuraRange", {
    Title = "Kill Aura Range",
    Description = "Set max range for Kill Aura",
    Default = 27,
    Min = 16,
    Max = 32,
    Rounding = 0.1,
})
local KillAuraTargets = Tabs.Combat:AddDropdown("KillAuraTargets", {
    Title = "Kill Aura Targets",
    Description = "",
    Values = {"Players", "NPCs"},
    Multi = true,
    Default = {"Players", "NPCs"},
})
KillAuraTargets:OnChanged(function(target)
    table.clear(KillAuraTarget)
    for i, isSelected in pairs(target) do
        if isSelected then
            table.insert(KillAuraTarget, i)
        end
    end
end)
local KillAuraKey = Tabs.Combat:AddKeybind("KillAuraKey", {Title = "Set keybind for Kill Aura", Mode = "Toggle", Default = "",})
KillAuraKey:OnClick(function()
    Options.KillAura:SetValue(KillAuraKey:GetState())
    Fluent:Notify({
        Title = "Kill Aura",
        Content = "Kill Aura has been " .. (KillAuraKey:GetState() and "enabled" or "disabled"),
        Duration = 1
    })
end)
KillAura:OnChanged(function()
    local enabled = KillAura.Value
    if enabled then
        if not connection then
            connection = RunService.PreRender:Connect(function()
                local enemy, root, entityType = getNearestEntity(tonumber(KillAuraRange.Value))
                if enemy and root and IsExistInTable(entityType, KillAuraTarget) then
                    local character = localplayer.Character or localplayer.CharacterAdded:Wait()
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    local hand1 = nil
                    for _, i in ipairs(ReplicatedStorage.Inventories:FindFirstChild(localplayer.Name):GetChildren()) do
                        if string.find(string.lower(i.Name), "sword") then
                            hand1 = i
                        end
                    end
                    if hrp and hand1 then
                        --NetManaged.SetInvItem:InvokeServer({{hand = hand1}})
                        local hrppos = hrp.Position
                        local HitPos = root.Position
                        NetManaged.SwordHit:FireServer({
                            entityInstance = enemy,
                            chargedAttack = {
                                chargeRatio = 0
                            },
                            validate = {
                                targetPosition = {
                                    value = HitPos
                                },
                                raycast = {
                                    cursorDirection = {value = CFrame.lookAlong(hrppos, HitPos).LookVector},
                                    cameraPosition = {value = hrppos}
                                },
                                selfPosition = {
                                    value = hrppos
                                }
                            },
                            weapon = hand1
                        })
                    end
                end
            end)
        end
    else
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
end)
--Anti AFK
local AntiAFK = Tabs.Utility:AddToggle("AntiAFK", {Title = "Anti AFK", Default = false })
AntiAFK:OnChanged(function()
    local enabled = AntiAFK.Value
    if enabled then
        repeat
            NetManaged.AfkInfo:FireServer({afk = false})
            task.wait(5)
        until not AntiAFK.Value
    end
end)
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("Krita")
SaveManager:SetFolder("Krita/Bedwars")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
local elapsed = os.clock() - loadstart
Fluent:Notify({
    Title = "Krita",
    Content = "The script has been loaded in " .. string.format("%.2f", elapsed) .. "seconds",
    Duration = 5
})
SaveManager:LoadAutoloadConfig()
