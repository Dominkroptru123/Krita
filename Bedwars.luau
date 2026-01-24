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
local LocalPlayer = game.Players.LocalPlayer
local KillAuraTarget = {}
local NetManaged = ReplicatedStorage.rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged
local Knit = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"].knit.src).KnitClient
local GameUtils = {
    InventoryUtil = require(ReplicatedStorage.TS.inventory["inventory-util"]).InventoryUtil,
    BlockBreaker = Knit.Controllers.BlockBreakController.blockBreaker,
    Knockback = require(ReplicatedStorage.TS.damage["knockback-util"]).KnockbackUtil
}
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
local function GetNearestEntity(range: number)
    local nearestCharacter = nil
    local shortestDistance = range
    local Root
    local entityType = "NPCs" -- default

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    for _, v in CollectionService:GetTagged("entity") do
        local player = Players:GetPlayerFromCharacter(v)
        if player then
            if player.Team == LocalPlayer.Team then
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

    return nearestCharacter, shortestDistance, Root, entityType
end
local function GetInventory(Player)
    Player = Player or LocalPlayer
    return GameUtils.InventoryUtil.getInventory(Player)
end
local function SwitchTo(Item)
    if not Item then
        return
    end
    local CurrentItem: ObjectValue? = LocalPlayer.Character:FindFirstChild("HandInvItem")
    if CurrentItem and CurrentItem:IsA("ObjectValue") then
        CurrentItem = CurrentItem.Value
    else
        local Inventory = GetInventory()
        if Inventory and Inventory.hand then
            CurrentItem = Inventory.hand.tool
        end
    end
    if CurrentItem == Item then
        return
    end
    NetManaged.SetInvItem:InvokeServer({hand = Item})
end
--Fluent
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
    Max = 29,
    Rounding = 0.1
})
local KillAuraAutoSwitch = Tabs.Combat:AddToggle("KillAuraAutoSwitch", {Title = "Kill Aura Auto Switch", Default = false })
local KillAuraTargets = Tabs.Combat:AddDropdown("KillAuraTargets", {
    Title = "Kill Aura Targets",
    Description = "",
    Values = {"Players", "NPCs"},
    Multi = true,
    Default = {"Players", "NPCs"}
})
KillAuraTargets:OnChanged(function(target)
    table.clear(KillAuraTarget)
    for i, isSelected in pairs(target) do
        if isSelected then
            table.insert(KillAuraTarget, i)
        end
    end
end)
local KillAuraKey = Tabs.Combat:AddKeybind("KillAuraKey", {Title = "Set keybind for Kill Aura", Mode = "Toggle", Default = ""})
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
                local NearestEntity, Distance, Root, EntityType = GetNearestEntity(tonumber(KillAuraRange.Value))
                if NearestEntity and Root and IsExistInTable(EntityType, KillAuraTarget) then
                    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    local sword = nil
                    for _, i in ipairs(ReplicatedStorage.Inventories:FindFirstChild(LocalPlayer.Name):GetChildren()) do
                        if string.find(string.lower(i.Name), "sword") then
                            sword = i
                            break
                        end
                    end
                    if hrp and sword then
                        local Hand = GetInventory().hand
                        if KillAuraAutoSwitch.Value and (not Hand or Hand and (not Hand.tool or Hand.tool ~= sword)) then
                            SwitchTo(sword)
                        end
                        local HrpPos = hrp.Position
                        local HitPos = (math.clamp(Distance - 14.4, 10, 30) * (Root.Position - HrpPos).Unit) + HrpPos
                        NetManaged.SwordHit:FireServer({
                            entityInstance = NearestEntity,
                            chargedAttack = {
                                chargeRatio = 0
                            },
                            validate = {
                                targetPosition = {
                                    value = Root.Position
                                },
                                raycast = {
                                    cursorDirection = {value = CFrame.lookAlong(HitPos, Root.Position).LookVector},
                                    cameraPosition = {value = HitPos}
                                },
                                selfPosition = {
                                    value = HitPos
                                }
                            },
                            weapon = sword
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
--Knockback
local OldApply = nil
local Knockback = Tabs.Utility:AddToggle("Knockback", {Title = "Knockback", Default = false })
local KnockbackValue = Tabs.Utility:AddSlider("KnockbackValue", {
    Title = "Knockback Value",
    Description = "Set value for Knockback",
    Default = 0,
    Min = 0.01,
    Max = 30,
    Rounding = 1
})
Knockback:OnChanged(function()
    local enabled = Knockback.Value
    if enabled then
        OldApply = GameUtils.Knockback.applyKnockback
        GameUtils.Knockback.applyKnockback = function(Part: BasePart, RealKnockback: number, ...)
            if KnockbackValue.Value == 0 then return end
            return OldApply(Part, KnockbackValue.Value, ...)
        end
    else
        if OldApply then
            GameUtils.Knockback.applyKnockback = OldApply
        end
    end
end)
--No Fall
local FallRay: RaycastParams, Power: number = RaycastParams.new(), 0
local function Physics(Delta: number)
    local Root: BasePart = LocalPlayer.Character.PrimaryPart
    local Velocity: Vector3 = Root.AssemblyLinearVelocity
    Root.AssemblyLinearVelocity = Vector3.new(Velocity.X, -85, Velocity.Z)
    Root.CFrame += Vector3.new(0, Delta * Power, 0)
    Power -= Delta * workspace.Gravity
end
local function MakeRay(Char: Model)
    repeat task.wait() until IsAlive(LocalPlayer,false)
    FallRay.FilterType = Enum.RaycastFilterType.Exclude
    FallRay.CollisionGroup = Char.PrimaryPart.CollisionGroup
    FallRay.FilterDescendantsInstances = {Char, workspace.CurrentCamera}
end
local NoFall = Tabs.Utility:AddToggle("NoFall", {Title = "No Fall", Default = false })
NoFall:OnChanged(function()
    local enabled = NoFall.Value
    if enabled then
        if not CharConnection then
            CharConnection = LocalPlayer.CharacterAdded:Connect(MakeRay)
        end
        if IsAlive(LocalPlayer, false) then
            MakeRay(LocalPlayer.Character)
        end
        if not connection2 then
            connection2 = RunService.PreRender:Connect(function(delta)
                if not IsAlive(LocalPlayer,false) then return end
                local Char = LocalPlayer.Character
                local Root = Char.PrimaryPart
                if Root.AssemblyLinearVelocity.Y >= -80 then
                    Power = 0
                    return
                end
                local _, Size: Vector3 = Char:GetBoundingBox()
                local Raycast: RaycastResult = workspace:Raycast(Root.Position, Vector3.new(0, -(Size.Y / 2), 0), FallRay)
                if not Raycast then
                    Physics(delta)
                else
                    Power = 0
                end
            end)
        end
    else
        if connection2 then
            connection2:Disconnect()
            connection2 = nil
        end
    end
end)
--Fast Break
local FastBreak = Tabs.Utility:AddToggle("FastBreak", {Title = "Fast Break", Default = false })
local FastBreakCooldown = Tabs.Utility:AddSlider("FastBreakCooldown", {
    Title = "Fast Break Cooldown",
    Description = "Set cooldown for Fast Break",
    Default = 0.2,
    Min = 0.01,
    Max = 0.3,
    Rounding = 10
})
local FastBreakKey = Tabs.Utility:AddKeybind("FastBreakKey", {Title = "Set keybind for Fast Break", Mode = "Toggle", Default = ""})
FastBreakKey:OnClick(function()
    Options.FastBreak:SetValue(FastBreakKey:GetState())
    Fluent:Notify({
        Title = "Fast Break",
        Content = "Fast Break has been " .. (FastBreakKey:GetState() and "enabled" or "disabled"),
        Duration = 1
    })
end)
FastBreak:OnChanged(function()
    local enabled = FastBreak.Value
    if enabled then
        repeat
            GameUtils.BlockBreaker.cooldown = tonumber(FastBreakCooldown.Value)
            task.wait(0.5)
        until not FastBreak.Value
    else
        GameUtils.BlockBreaker.cooldown = 0.3
    end
end)
--Far Break
local FarBreak = Tabs.Utility:AddToggle("FarBreak", {Title = "Far Break", Default = false })
local FarBreakRange = Tabs.Utility:AddSlider("FarBreakRange", {
    Title = "Far Break Range",
    Description = "Set range for Fast Break",
    Default = 25,
    Min = 18,
    Max = 50,
    Rounding = 0.1
})
local FarBreakKey = Tabs.Utility:AddKeybind("FarBreakKey", {Title = "Set keybind for Far Break", Mode = "Toggle", Default = ""})
FarBreakKey:OnClick(function()
    Options.FarBreak:SetValue(FarBreakKey:GetState())
    Fluent:Notify({
        Title = "Far Break",
        Content = "Far Break has been " .. (FarBreakKey:GetState() and "enabled" or "disabled"),
        Duration = 1
    })
end)
FarBreak:OnChanged(function()
    local enabled = FarBreak.Value
    if enabled then
        repeat
            GameUtils.BlockBreaker.range = tonumber(FarBreakRange.Value)
            task.wait(0.5)
        until not FarBreak.Value
    else
        GameUtils.BlockBreaker.range = 18
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
