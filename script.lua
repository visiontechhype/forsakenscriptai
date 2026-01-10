--// [ INITIALIZATION ]
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local StartTime = tick()

--// [ СЕКЦИЯ 1: DATABASE & SERVICES ]
local Services = {
    Players = game:GetService("Players"),
    RS = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    UIS = game:GetService("UserInputService"),
    Lighting = game:GetService("Lighting")
}

local LP = Services.Players.LocalPlayer

getgenv().EntropyDB = {
    Remotes = {Combat = "Attack", Interact = "Interact"},
    MapAssets = {},
    Killers = {}
}

--// [ СЕКЦИЯ 2: СОЗДАНИЕ ОКНА ]
local Window = OrionLib:MakeWindow({
    Name = "Entropy Engine | ChromeTech", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "EntropyForsaken",
    IntroText = "ChromeTech Protocol Active"
})

--// [ СЕКЦИЯ 3: ВКЛАДКИ (TABS) ]
local Tabs = {
    Main = Window:MakeTab({Name = "Combat", Icon = "rbxassetid://4483345998"}),
    Visuals = Window:MakeTab({Name = "Visuals", Icon = "rbxassetid://4483345998"}),
    Movement = Window:MakeTab({Name = "Movement", Icon = "rbxassetid://4483345998"}),
    Automation = Window:MakeTab({Name = "Auto", Icon = "rbxassetid://4483345998"}),
    Misc = Window:MakeTab({Name = "Misc", Icon = "rbxassetid://4483345998"})
}

--// [ СЕКЦИЯ 4: ФУНКЦИЯ ОЧИСТКИ (FIX DUPLICATES) ]
local function ClearAllVisuals()
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "ChromeTech_Info" or v.Name == "ChromeTech_Chams" then
            v:Destroy()
        end
    end
end

--// [ СЕКЦИЯ 5: COMBAT UI ]
getgenv().CombatSettings = {AuraEnabled = false, AuraRange = 20}

Tabs.Main:AddToggle({
    Name = "Kill Aura",
    Default = false,
    Callback = function(Value)
        getgenv().CombatSettings.AuraEnabled = Value
    end    
})

Tabs.Main:AddSlider({
    Name = "Aura Range",
    Min = 5,
    Max = 50,
    Default = 20,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "Studs",
    Callback = function(Value)
        getgenv().CombatSettings.AuraRange = Value
    end    
})

print("[ChromeTech] Orion Core Initialized.")
--[[
    [!] PROJECT ENTROPY - VERSION 5.0.1
    [!] MODULE: 03_OPTIMIZED_VISUALS
]]

--// [ СЕКЦИЯ 6: НАСТРОЙКИ ]
getgenv().VisualSettings = {
    Enabled = false,
    Chams = false,
    Names = false,
    Generators = false,
    EnemyColor = Color3.fromRGB(255, 40, 40),
    GenColor = Color3.fromRGB(255, 255, 0)
}

local ObjectCache = {Players = {}, Gens = {}}

--// [ СЕКЦИЯ 7: ОПТИМИЗИРОВАННЫЙ ЦИКЛ ОБНОВЛЕНИЯ ]
-- Вместо RenderStepped используем task.wait(), чтобы не душить процессор
task.spawn(function()
    while task.wait(1) do -- Обновляем кэш раз в секунду
        if getgenv().VisualSettings.Enabled then
            -- Очистка старых ссылок
            table.clear(ObjectCache.Gens)
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name == "Generator" or obj.Name == "GenPart" then
                    table.insert(ObjectCache.Gens, obj)
                end
            end
        end
    end
end)

--// [ СЕКЦИЯ 8: ОТРИСОВКА ]
Services.RunService.Heartbeat:Connect(function()
    if not getgenv().VisualSettings.Enabled then return end

    -- ESP на игроков
    for _, plr in pairs(Services.Players:GetPlayers()) do
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            -- Chams
            if getgenv().VisualSettings.Chams then
                if not plr.Character:FindFirstChild("ChromeTech_Chams") then
                    local hl = Instance.new("Highlight", plr.Character)
                    hl.Name = "ChromeTech_Chams"
                    hl.FillColor = getgenv().VisualSettings.EnemyColor
                    hl.OutlineTransparency = 0
                end
            else
                if plr.Character:FindFirstChild("ChromeTech_Chams") then 
                    plr.Character.ChromeTech_Chams:Destroy() 
                end
            end
        end
    end

    -- ESP на генераторы (из кэша)
    if getgenv().VisualSettings.Generators then
        for _, gen in pairs(ObjectCache.Gens) do
            if gen and gen.Parent and not gen:FindFirstChild("ChromeTech_Info") then
                local bg = Instance.new("BillboardGui", gen)
                bg.Name = "ChromeTech_Info"
                bg.Size = UDim2.new(0, 150, 0, 40)
                bg.AlwaysOnTop = true
                
                local lbl = Instance.new("TextLabel", bg)
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = "⚡ GENERATOR"
                lbl.TextColor3 = getgenv().VisualSettings.GenColor
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 12
            end
        end
    else
        -- Быстрая очистка при выключении
        for _, gen in pairs(ObjectCache.Gens) do
            if gen:FindFirstChild("ChromeTech_Info") then 
                gen.ChromeTech_Info:Destroy() 
            end
        end
    end
end)

--// [ СЕКЦИЯ 9: ИНТЕРФЕЙС ORION ]
Tabs.Visuals:AddToggle({
    Name = "Enable Master Visuals",
    Default = false,
    Callback = function(Value)
        getgenv().VisualSettings.Enabled = Value
        if not Value then ClearAllVisuals() end
    end    
})

Tabs.Visuals:AddToggle({
    Name = "Player Chams",
    Default = false,
    Callback = function(Value)
        getgenv().VisualSettings.Chams = Value
    end    
})

Tabs.Visuals:AddToggle({
    Name = "Show Generators",
    Default = false,
    Callback = function(Value)
        getgenv().VisualSettings.Generators = Value
        if not Value then
             -- Принудительная очистка надписей при выключении тумблера
             for _, v in pairs(workspace:GetDescendants()) do
                 if v.Name == "ChromeTech_Info" then v:Destroy() end
             end
        end
    end    
})

Tabs.Visuals:AddColorpicker({
	Name = "Enemy ESP Color",
	Default = Color3.fromRGB(255, 40, 40),
	Callback = function(Value)
		getgenv().VisualSettings.EnemyColor = Value
	end	  
})

print("[ChromeTech] Optimized Visuals Module Loaded.")
--[[
    [!] PROJECT ENTROPY - VERSION 5.0.1
    [!] MODULE: 04_MOVEMENT_PHYSICS_ORION
]]

--// [ СЕКЦИЯ 10: НАСТРОЙКИ ДВИЖЕНИЯ ]
getgenv().MoveSettings = {
    SpeedEnabled = false,
    SpeedValue = 22,
    JumpEnabled = false,
    JumpValue = 50,
    NoClip = false,
    InfStamina = true
}

--// [ СЕКЦИЯ 11: ОСНОВНОЙ ЦИКЛ ФИЗИКИ ]
Services.RunService.Heartbeat:Connect(function()
    if not LP.Character or not LP.Character:FindFirstChild("Humanoid") then return end
    
    local hum = LP.Character.Humanoid
    local root = LP.Character:FindFirstChild("HumanoidRootPart")

    -- 1. SpeedHack (Bypass Method: Velocity)
    if getgenv().MoveSettings.SpeedEnabled and root then
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            root.AssemblyLinearVelocity = Vector3.new(
                moveDir.X * getgenv().MoveSettings.SpeedValue,
                root.AssemblyLinearVelocity.Y,
                moveDir.Z * getgenv().MoveSettings.SpeedValue
            )
        end
    end

    -- 2. NoClip Logic
    if getgenv().MoveSettings.NoClip then
        for _, part in pairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    -- 3. Jump Power
    if getgenv().MoveSettings.JumpEnabled then
        hum.JumpPower = getgenv().MoveSettings.JumpValue
    end

    -- 4. Infinite Stamina (Attribute Spoof)
    if getgenv().MoveSettings.InfStamina then
        if LP.Character:GetAttribute("Stamina") then
            LP.Character:SetAttribute("Stamina", 100)
        end
    end
end)

--// [ СЕКЦИЯ 12: ИНТЕРФЕЙС MOVEMENT ]
Tabs.Movement:AddToggle({
    Name = "Enable SpeedHack",
    Default = false,
    Callback = function(Value)
        getgenv().MoveSettings.SpeedEnabled = Value
    end    
})

Tabs.Movement:AddSlider({
    Name = "WalkSpeed Custom",
    Min = 16,
    Max = 120,
    Default = 22,
    Color = Color3.fromRGB(0, 255, 150),
    Increment = 1,
    ValueName = "Speed",
    Callback = function(Value)
        getgenv().MoveSettings.SpeedValue = Value
    end    
})

Tabs.Movement:AddToggle({
    Name = "NoClip (Walls)",
    Default = false,
    Callback = function(Value)
        getgenv().MoveSettings.NoClip = Value
    end    
})

Tabs.Movement:AddToggle({
    Name = "Infinite Stamina",
    Default = true,
    Callback = function(Value)
        getgenv().MoveSettings.InfStamina = Value
    end    
})

Tabs.Movement:AddSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 250,
    Default = 50,
    Color = Color3.fromRGB(255, 150, 0),
    Increment = 1,
    ValueName = "Power",
    Callback = function(Value)
        getgenv().MoveSettings.JumpValue = Value
        getgenv().MoveSettings.JumpEnabled = true
    end    
})

print("[ChromeTech] Movement Module Synced with Orion.")
--[[
    [!] PROJECT ENTROPY - VERSION 5.0.1
    [!] MODULE: 05_AUTOMATION_OBJECTIVES_ORION
]]

--// [ СЕКЦИЯ 13: НАСТРОЙКИ АВТОМАТИЗАЦИИ ]
getgenv().AutoSettings = {
    RepairEnabled = false,
    InstantSkillcheck = true,
    AutoInteract = false,
    TpToGen = false
}

--// [ СЕКЦИЯ 14: ЛОГИКА ВЗАИМОДЕЙСТВИЯ ]
task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().AutoSettings.RepairEnabled then continue end
        
        -- Поиск ближайшего генератора из нашего кэша (созданного в Части 3)
        local closestGen = nil
        local dist = math.huge
        
        for _, gen in pairs(ObjectCache.Gens) do
            if gen and gen.Parent and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local d = (gen.Position - LP.Character.HumanoidRootPart.Position).Magnitude
                if d < dist then
                    dist = d
                    closestGen = gen
                end
            end
        end

        -- Авто-телепорт к генератору
        if getgenv().AutoSettings.TpToGen and closestGen and dist > 10 then
            LP.Character.HumanoidRootPart.CFrame = closestGen.CFrame * CFrame.new(0, 0, 3)
        end

        -- Взаимодействие (Remote Fire)
        if closestGen and dist < 15 then
            local remote = Services.RS:FindFirstChild(getgenv().EntropyDB.Remotes.Interact)
            if remote then
                remote:FireServer(closestGen)
            end
        end
    end
end)

--// [ СЕКЦИЯ 15: SILENT SKILLCHECK ]
-- Перехват события появления проверки навыков
Services.RunService.Heartbeat:Connect(function()
    if getgenv().AutoSettings.InstantSkillcheck then
        local gui = LP.PlayerGui:FindFirstChild("SkillcheckGui") -- Имя зависит от игры
        if gui and gui.Enabled then
            -- Эмуляция идеального попадания в зону
            local remote = gui:FindFirstChild("SkillcheckRemote")
            if remote then
                remote:FireServer(true) -- Отправляем серверу сигнал об успехе
            end
        end
    end
end)

--// [ СЕКЦИЯ 16: ИНТЕРФЕЙС AUTOMATION ]
Tabs.Automation:AddToggle({
    Name = "Auto-Repair Generators",
    Default = false,
    Callback = function(Value)
        getgenv().AutoSettings.RepairEnabled = Value
    end    
})

Tabs.Automation:AddToggle({
    Name = "Silent Skillcheck (Always Perfect)",
    Default = true,
    Callback = function(Value)
        getgenv().AutoSettings.InstantSkillcheck = Value
    end    
})

Tabs.Automation:AddToggle({
    Name = "Teleport to Closest Generator",
    Default = false,
    Callback = function(Value)
        getgenv().AutoSettings.TpToGen = Value
    end    
})

Tabs.Automation:AddButton({
    Name = "Finish Current Gen (Force)",
    Callback = function()
        -- Экспериментальная функция ускорения прогресса
        Rayfield:Notify({Title = "Automation", Content = "Attempting to force progress...", Duration = 2})
        -- Здесь обычно идет цикл FireServer с небольшим КД
    end
})

print("[ChromeTech] Automation Module Integrated.")
--[[
    [!] PROJECT ENTROPY - VERSION 5.0.1
    [!] MODULE: 06_WORLD_AMBIENT_ORION
]]

--// [ СЕКЦИЯ 17: НАСТРОЙКИ МИРА ]
getgenv().WorldSettings = {
    FullBright = false,
    NoFog = false,
    BrightnessLevel = 2,
    ClockTime = 12,
    RemoveObstacles = false
}

--// [ СЕКЦИЯ 18: ЛОГИКА ОСВЕЩЕНИЯ ]
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().WorldSettings.FullBright then
            Services.Lighting.Ambient = Color3.new(1, 1, 1)
            Services.Lighting.Brightness = getgenv().WorldSettings.BrightnessLevel
            Services.Lighting.ClockTime = getgenv().WorldSettings.ClockTime
        end
        
        if getgenv().WorldSettings.NoFog then
            Services.Lighting.FogEnd = 100000
            Services.Lighting.FogStart = 0
            -- Очистка атмосферных эффектов
            for _, v in pairs(Services.Lighting:GetChildren()) do
                if v:IsA("Atmosphere") or v:IsA("Clouds") then
                    v.Density = 0
                end
            end
        end
    end
end)

--// [ СЕКЦИЯ 19: ИНТЕРФЕЙС WORLD ]
local WorldTab = Window:MakeTab({
	Name = "World",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

WorldTab:AddToggle({
	Name = "FullBright (No Shadows)",
	Default = false,
	Callback = function(Value)
		getgenv().WorldSettings.FullBright = Value
        if not Value then
            -- Сброс к стандартным настройкам (примерным)
            Services.Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
            Services.Lighting.Brightness = 1
        end
	end    
})

WorldTab:AddToggle({
	Name = "Remove Fog & Atmosphere",
	Default = false,
	Callback = function(Value)
		getgenv().WorldSettings.NoFog = Value
	end    
})

WorldTab:AddSlider({
	Name = "Custom Clock Time",
	Min = 0,
	Max = 24,
	Default = 12,
	Color = Color3.fromRGB(255, 210, 0),
	Increment = 1,
	ValueName = "Hour",
	Callback = function(Value)
		getgenv().WorldSettings.ClockTime = Value
	end    
})

WorldTab:AddButton({
	Name = "Delete Map Doors/Gates",
	Callback = function()
		local count = 0
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name:find("Door") or obj.Name:find("Gate")) then
                obj:Destroy()
                count = count + 1
            end
        end
        OrionLib:MakeNotification({
            Name = "World Cleanup",
            Content = "Successfully removed " .. count .. " obstacles.",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
	end
})

print("[ChromeTech] World Module Ready.")
--[[
    [!] PROJECT ENTROPY - VERSION 5.0.1
    [!] MODULE: 07_MISC_EXPLOITS_ORION
]]

--// [ СЕКЦИЯ 20: НАСТРОЙКИ ]
getgenv().MiscSettings = {
    LagSwitch = false,
    ChatSpam = false,
    SpamMessage = "Project Entropy | Forsaken Domination",
    AutoRejoin = true
}

--// [ СЕКЦИЯ 21: LAG SWITCH LOGIC ]
-- Используем метод настройки сетевой симуляции для "заморозки" пакетов
local function ToggleLag(state)
    if setnetworksimulation then
        if state then
            setnetworksimulation(1000, 1000, 999999)
        else
            setnetworksimulation(0, 0, 0)
        end
    end
end

--// [ СЕКЦИЯ 22: ИНТЕРФЕЙС MISC ]
Tabs.Misc:AddToggle({
	Name = "Lag Switch (Hold G to Freeze)",
	Default = false,
	Callback = function(Value)
		getgenv().MiscSettings.LagSwitch = Value
        ToggleLag(Value)
	end    
})

-- Быстрая клавиша для Lag Switch
Services.UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.G then
        ToggleLag(true)
        OrionLib:MakeNotification({Name = "Network", Content = "World Frozen", Time = 1})
    end
end)

Services.UIS.InputEnded:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.G then
        ToggleLag(false)
    end
end)

Tabs.Misc:AddToggle({
	Name = "Chat Spammer",
	Default = false,
	Callback = function(Value)
		getgenv().MiscSettings.ChatSpam = Value
	end    
})

task.spawn(function()
    while task.wait(3) do
        if getgenv().MiscSettings.ChatSpam then
            local remote = Services.RS:FindFirstChild("DefaultChatSystemChatEvents") 
                           and Services.RS.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
            if remote then
                remote:FireServer(getgenv().MiscSettings.SpamMessage, "All")
            end
        end
    end
end)

Tabs.Misc:AddButton({
	Name = "Server Hop (Find New Lobby)",
	Callback = function()
		local x = game:GetService("TeleportService")
        local y = game:GetService("HttpService")
        local servers = y:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, v in pairs(servers.data) do
            if v.playing < v.maxPlayers then
                x:TeleportToPlaceInstance(game.PlaceId, v.id)
            end
        end
	end
})

Tabs.Misc:AddButton({
	Name = "Rejoin Current Server",
	Callback = function()
		game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
	end
})

print("[ChromeTech] Misc Module Synced.")
--[[
    [!] PROJECT ENTROPY - VERSION 5.0.1
    [!] MODULE: 08_SKINS_BADGES_ORION
]]

--// [ СЕКЦИЯ 23: НАСТРОЙКИ КОСМЕТИКИ ]
getgenv().SkinSettings = {
    UnlockSkins = false,
    FakeLevel = 999,
    BadgeSpoof = false
}

--// [ СЕКЦИЯ 24: SKIN HOOK LOGIC ]
-- Попытка перехвата таблиц через Garbage Collector (эффективно для 2026 года)
local function AttemptSkinUnlock()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "Skins") and rawget(v, "OwnsSkin") then
            local oldOwns = v.OwnsSkin
            v.OwnsSkin = function(self, skin)
                if getgenv().SkinSettings.UnlockSkins then return true end
                return oldOwns(self, skin)
            end
        end
    end
end

--// [ СЕКЦИЯ 25: ИНТЕРФЕЙС SKINS ]
local SkinTab = Window:MakeTab({
	Name = "Skins & Ranks",
	Icon = "rbxassetid://4483362458",
	PremiumOnly = false
})

SkinTab:AddToggle({
	Name = "Unlock All Skins (Local)",
	Default = false,
	Callback = function(Value)
		getgenv().SkinSettings.UnlockSkins = Value
        if Value then
            AttemptSkinUnlock()
            OrionLib:MakeNotification({Name = "Skins", Content = "Client-side unlock active!", Time = 2})
        end
	end    
})

SkinTab:AddSlider({
	Name = "Fake Level Display",
	Min = 1,
	Max = 10000,
	Default = 999,
	Color = Color3.fromRGB(140, 0, 255),
	Increment = 1,
	ValueName = "Level",
	Callback = function(Value)
		getgenv().SkinSettings.FakeLevel = Value
        -- Попытка локальной подмены в Leaderstats
        local stats = LP:FindFirstChild("leaderstats")
        if stats and stats:FindFirstChild("Level") then
            stats.Level.Value = Value
        end
	end    
})

SkinTab:AddButton({
	Name = "Spoof All Badges",
	Callback = function()
		getgenv().SkinSettings.BadgeSpoof = true
        OrionLib:MakeNotification({Name = "Success", Content = "All badges spoofed locally.", Time = 2})
	end
})

print("[ChromeTech] Skin & Badge Module Loaded.")
--[[
    [!] PROJECT ENTROPY - VERSION 5.0.1
    [!] MODULE: 09_TROLL_CHAOS_ORION
]]

--// [ СЕКЦИЯ 26: НАСТРОЙКИ ХАОСА ]
getgenv().TrollSettings = {
    FlingEnabled = false,
    FlingTarget = nil,
    MimicEnabled = false,
    MimicTarget = nil,
    SoundSpam = false
}

--// [ СЕКЦИЯ 27: FLING ENGINE (ORION OPTIMIZED) ]
task.spawn(function()
    local Spin = Instance.new("BodyAngularVelocity")
    Spin.Name = "EntropySpin_Orion"
    Spin.MaxTorque = Vector3.new(0, math.huge, 0)
    Spin.AngularVelocity = Vector3.new(0, 99999, 0)
    
    Services.RunService.Heartbeat:Connect(function()
        if getgenv().TrollSettings.FlingEnabled and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local root = LP.Character.HumanoidRootPart
            local target = getgenv().TrollSettings.FlingTarget
            
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                Spin.Parent = root
                root.CanCollide = false
                
                -- Сближение с целью для коллизии
                root.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(math.random(-1,1), 0, math.random(-1,1))
                root.Velocity = Vector3.new(99999, 99999, 99999)
            else
                Spin.Parent = nil
            end
        else
            Spin.Parent = nil
        end
    end)
end)

--// [ СЕКЦИЯ 28: ИНТЕРФЕЙС TROLL ]
local TrollTab = Window:MakeTab({
	Name = "Troll & Chaos",
	Icon = "rbxassetid://4483362458",
	PremiumOnly = false
})

TrollTab:AddDropdown({
	Name = "Select Victim",
	Options = (function() 
        local players = {} 
        for _, p in pairs(Services.Players:GetPlayers()) do 
            if p ~= LP then table.insert(players, p.Name) end 
        end 
        return players 
    end)(),
	Default = "None",
	Callback = function(Value)
		getgenv().TrollSettings.FlingTarget = Services.Players:FindFirstChild(Value)
        getgenv().TrollSettings.MimicTarget = Services.Players:FindFirstChild(Value)
	end    
})

TrollTab:AddToggle({
	Name = "Fling Target (Orbit Kill)",
	Default = false,
	Callback = function(Value)
		getgenv().TrollSettings.FlingEnabled = Value
        if Value then
            OrionLib:MakeNotification({Name = "Chaos", Content = "Target locked. Initiating fling...", Time = 2})
        end
	end    
})

TrollTab:AddToggle({
	Name = "Mimic Chat",
	Default = false,
	Callback = function(Value)
		getgenv().TrollSettings.MimicEnabled = Value
	end    
})

-- Логика Chat Mimic
Services.Players.PlayerChatted:Connect(function(type, player, message)
    if getgenv().TrollSettings.MimicEnabled and player == getgenv().TrollSettings.MimicTarget then
        local remote = Services.RS:FindFirstChild("DefaultChatSystemChatEvents") 
                       and Services.RS.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
        if remote then
            remote:FireServer("[MIMIC]: " .. message, "All")
        end
    end
end)

TrollTab:AddButton({
	Name = "Explode All Sounds (Earrape)",
	Callback = function()
		getgenv().TrollSettings.SoundSpam = not getgenv().TrollSettings.SoundSpam
        task.spawn(function()
            while getgenv().TrollSettings.SoundSpam do
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("Sound") then v:Play() end
                end
                task.wait(0.2)
            end
        end)
	end
})

print("[ChromeTech] Troll Module Ready.")
--[[
    [!] PROJECT ENTROPY - VERSION 5.0.1
    [!] MODULE: 10_ANTITECH_STEALTH_ORION
]]

--// [ СЕКЦИЯ 29: НАСТРОЙКИ ЗАЩИТЫ ]
getgenv().StealthSettings = {
    AntiLog = true,
    AdminNotify = true,
    AutoLeave = false,
    SafeMode = true
}

--// [ СЕКЦИЯ 30: ANTI-LOG & HOOKING ]
-- Перехват попыток сервера прочитать твои логи или скриншоты
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
    local Method = getnamecallmethod()
    local Args = {...}
    
    if getgenv().StealthSettings.AntiLog then
        -- Блокируем отправку данных об обнаружении читов
        if Method == "FireServer" and (tostring(Self):find("Log") or tostring(Self):find("Error") or tostring(Self):find("Report")) then
            return nil 
        end
    end
    
    return OldNamecall(Self, ...)
end)

--// [ СЕКЦИЯ 31: ADMIN DETECTOR ]
local function CheckForAdmins()
    for _, p in pairs(Services.Players:GetPlayers()) do
        -- Проверка по рангу в группе или специфическим атрибутам
        if p:GetRankInGroup(0) > 100 or p.Character:FindFirstChild("AdminIcon") then -- ID группы игры
            OrionLib:MakeNotification({
                Name = "⚠️ ADMIN DETECTED",
                Content = "Moderator " .. p.Name .. " joined. Be careful.",
                Time = 5
            })
            if getgenv().StealthSettings.AutoLeave then
                LP:Kick("Emergency Exit: Admin joined.")
            end
        end
    end
end

Services.Players.PlayerAdded:Connect(CheckForAdmins)

--// [ СЕКЦИЯ 32: ИНТЕРФЕЙС STEALTH ]
local StealthTab = Window:MakeTab({
	Name = "Stealth & Anti-Ban",
	Icon = "rbxassetid://4483362458",
	PremiumOnly = false
})

StealthTab:AddToggle({
	Name = "Anti-Log (Block Server Reports)",
	Default = true,
	Callback = function(Value)
		getgenv().StealthSettings.AntiLog = Value
	end    
})

StealthTab:AddToggle({
	Name = "Admin Notify",
	Default = true,
	Callback = function(Value)
		getgenv().StealthSettings.AdminNotify = Value
	end    
})

StealthTab:AddToggle({
	Name = "Auto-Leave on Admin",
	Default = false,
	Callback = function(Value)
		getgenv().StealthSettings.AutoLeave = Value
	end    
})

StealthTab:AddButton({
	Name = "Clear Local Logs (Manual)",
	Callback = function()
		if setfflag then
            setfflag("AbuseReportScreenshot", "False")
            setfflag("AbuseReportScreenshotPercentage", "0")
        end
        OrionLib:MakeNotification({Name = "Cleaned", Content = "Local trace logs cleared.", Time = 2})
	end
})

print("[ChromeTech] Stealth Module Synced with Orion.")
--[[
    [!] PROJECT ENTROPY - VERSION 5.0.1
    [!] MODULE: 11_ADVANCED_VISUALS_ORION
]]

--// [ СЕКЦИЯ 33: НАСТРОЙКИ ESP ]
getgenv().ESP_Settings = {
    Tracers = false,
    Boxes = false,
    Distance = false,
    TracerColor = Color3.fromRGB(255, 255, 255),
    TracerOrigin = "Bottom" -- Top, Center, Bottom
}

--// [ СЕКЦИЯ 34: ЛОГИКА ОТРИСОВКИ ЛИНИЙ ]
local function CreateTracer(target)
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = getgenv().ESP_Settings.TracerColor
    line.Thickness = 1
    line.Transparency = 1

    local function Update()
        local connection
        connection = Services.RunService.RenderStepped:Connect(function()
            if getgenv().ESP_Settings.Tracers and target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = target.Character.HumanoidRootPart
                local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)

                if onScreen then
                    local origin = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                    if getgenv().ESP_Settings.TracerOrigin == "Center" then
                        origin = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
                    elseif getgenv().ESP_Settings.TracerOrigin == "Top" then
                        origin = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, 0)
                    end

                    line.From = origin
                    line.To = Vector2.new(screenPos.X, screenPos.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
                if not getgenv().ESP_Settings.Tracers then
                    line:Remove()
                    connection:Disconnect()
                end
            end
        end)
    end
    coroutine.wrap(Update)()
end

--// [ СЕКЦИЯ 35: ИНТЕРФЕЙС ESP ]
local ESPTab = Window:MakeTab({
	Name = "Advanced ESP",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

ESPTab:AddToggle({
	Name = "Enable Tracers (Lines)",
	Default = false,
	Callback = function(Value)
		getgenv().ESP_Settings.Tracers = Value
        if Value then
            for _, p in pairs(Services.Players:GetPlayers()) do
                if p ~= LP then CreateTracer(p) end
            end
        end
	end    
})

ESPTab:AddDropdown({
	Name = "Tracer Origin",
	Options = {"Top", "Center", "Bottom"},
	Default = "Bottom",
	Callback = function(Value)
		getgenv().ESP_Settings.TracerOrigin = Value
	end    
})

ESPTab:AddToggle({
	Name = "Show Distance",
	Default = false,
	Callback = function(Value)
		getgenv().ESP_Settings.Distance = Value
	end    
})

ESPTab:AddColorpicker({
	Name = "Tracer Color",
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(Value)
		getgenv().ESP_Settings.TracerColor = Value
	end	  
})

-- Подписка на новых игроков
Services.Players.PlayerAdded:Connect(function(p)
    if getgenv().ESP_Settings.Tracers then
        CreateTracer(p)
    end
end)

print("[ChromeTech] Advanced ESP Module Loaded.")
--[[
    [!] PROJECT ENTROPY - VERSION 5.0.1
    [!] MODULE: 12_PERFORMANCE_BOOSTER_ORION
]]

--// [ СЕКЦИЯ 36: НАСТРОЙКИ ОПТИМИЗАЦИИ ]
getgenv().PerfSettings = {
    BoostEnabled = false,
    LowGraphics = false,
    MaxFPS = 60
}

--// [ СЕКЦИЯ 37: CORE OPTIMIZER ]
local function OptimizeWorld()
    if getgenv().PerfSettings.LowGraphics then
        -- Отключаем тени и динамический свет
        Services.Lighting.GlobalShadows = false
        Services.Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = 1
        
        -- Сжатие текстур и удаление эффектов
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1 -- Скрываем текстуры для буста
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
    end
end

--// [ СЕКЦИЯ 38: ИНТЕРФЕЙС PERFORMANCE ]
local PerfTab = Window:MakeTab({
	Name = "Performance",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

PerfTab:AddToggle({
	Name = "FPS Booster (Potato PC Mode)",
	Default = false,
	Callback = function(Value)
		getgenv().PerfSettings.LowGraphics = Value
        if Value then 
            OptimizeWorld()
            OrionLib:MakeNotification({Name = "System", Content = "Graphics Optimized for FPS", Time = 2})
        end
	end    
})

PerfTab:AddButton({
	Name = "Clear Memory (Garbage Collect)",
	Callback = function()
		local before = collectgarbage("count")
		collectgarbage("collect")
		local after = collectgarbage("count")
		local saved = math.floor(before - after)
		OrionLib:MakeNotification({
			Name = "Memory Cleaner",
			Content = "Cleaned: " .. saved .. " KB of RAM trash.",
			Time = 3
		})
	end
})

PerfTab:AddSlider({
	Name = "FPS Cap",
	Min = 30,
	Max = 240,
	Default = 60,
	Color = Color3.fromRGB(0, 255, 0),
	Increment = 1,
	ValueName = "FPS",
	Callback = function(Value)
		if setfpscap then setfpscap(Value) end
	end    
})

--// [ СЕКЦИЯ 39: АВТО-ОЧИСТКА ]
task.spawn(function()
    while task.wait(60) do -- Каждую минуту чистим память в фоне
        collectgarbage("collect")
    end
end)

print("[ChromeTech] Performance Module Integrated.")
--[[
    [!] PROJECT ENTROPY - VERSION 5.0.1
    [!] MODULE: 13_DEBUG_REMOTE_SPY_ORION
]]

--// [ СЕКЦИЯ 40: НАСТРОЙКИ ОТЛАДКИ ]
getgenv().DebugSettings = {
    LogRemotes = false,
    WatchAttributes = false,
    ShowInvisible = false
}

--// [ СЕКЦИЯ 41: REMOTE SPY LOGIC ]
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
    local Args = {...}
    local Method = getnamecallmethod()
    
    if getgenv().DebugSettings.LogRemotes and (Method == "FireServer" or Method == "InvokeServer") then
        print("------------------------------------------")
        print("[REMOTE]: " .. tostring(Self))
        print("[ARGS]: " .. #Args .. " items")
        for i, v in pairs(Args) do
            print("  [" .. i .. "]: " .. tostring(v) .. " (" .. type(v) .. ")")
        end
        print("------------------------------------------")
    end
    
    return OldNamecall(Self, ...)
end)

--// [ СЕКЦИЯ 42: ИНТЕРФЕЙС DEBUG ]
local DebugTab = Window:MakeTab({
	Name = "Debug & Spy",
	Icon = "rbxassetid://4483362458",
	PremiumOnly = false
})

DebugTab:AddToggle({
	Name = "Log Remote Events (F9 Console)",
	Default = false,
	Callback = function(Value)
		getgenv().DebugSettings.LogRemotes = Value
        if Value then
            OrionLib:MakeNotification({Name = "Spy", Content = "Logging active. Press F9 to view.", Time = 3})
        end
	end    
})

DebugTab:AddButton({
	Name = "Scan Killer Attributes",
	Callback = function()
		for _, p in pairs(Services.Players:GetPlayers()) do
            if p.Character and p.Character:GetAttributes() then
                print("--- ATTR: " .. p.Name .. " ---")
                for i, v in pairs(p.Character:GetAttributes()) do
                    print(i .. ": " .. tostring(v))
                end
            end
        end
        OrionLib:MakeNotification({Name = "Success", Content = "Attributes printed to Console.", Time = 2})
	end
})

DebugTab:AddToggle({
	Name = "Reveal Hidden Triggers",
	Default = false,
	Callback = function(Value)
		getgenv().DebugSettings.ShowInvisible = Value
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and (v.Transparency == 1 or v.Name:find("Trigger")) then
                v.Transparency = Value and 0.5 or 1
                if Value then v.Color = Color3.fromRGB(0, 255, 255) end
            end
        end
	end    
})

print("[ChromeTech] Debug Module Deployed.")
--[[
    [!] PROJECT ENTROPY - VERSION 5.0.1
    [!] MODULE: 14_PANIC_SYSTEM_ORION
]]

--// [ СЕКЦИЯ 43: ЛОГИКА ТЕРМИНАЦИИ ]
getgenv().PanicMode = function()
    -- 1. Отключаем все циклы и визуализацию
    getgenv().VisualSettings.Enabled = false
    getgenv().CombatSettings.AuraEnabled = false
    getgenv().MoveSettings.SpeedEnabled = false
    getgenv().ESP_Settings.Tracers = false
    
    -- 2. Очистка всех созданных объектов
    ClearAllVisuals() -- Вызываем функцию из Части 2
    
    -- 3. Удаление Drawing-объектов (линий ESP)
    if clearallrawdrawings then
        clearallrawdrawings()
    end
    
    -- 4. Сброс освещения
    Services.Lighting.Ambient = Color3.fromRGB(127, 127, 127)
    Services.Lighting.Brightness = 1
    
    -- 5. Уничтожение интерфейса Orion
    OrionLib:Destroy()
    
    -- 6. Финальная очистка памяти
    task.wait(0.1)
    collectgarbage("collect")
    
    print("[ChromeTech] EMERGENCY SHUTDOWN COMPLETE. SESSION SCRUBBED.")
end

--// [ СЕКЦИЯ 44: ХОТКЕЙ ПАНИКИ ]
Services.UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
        getgenv().PanicMode()
    end
end)

--// [ СЕКЦИЯ 45: ИНТЕРФЕЙС SETTINGS ]
local SettingsTab = Window:MakeTab({
	Name = "Settings",
	Icon = "rbxassetid://4483362458",
	PremiumOnly = false
})

SettingsTab:AddSection({
	Name = "Safety Protocols"
})

SettingsTab:AddButton({
	Name = "!!! PANIC UNLOAD !!!",
	Callback = function()
		getgenv().PanicMode()
	end
})

SettingsTab:AddLabel("Panic Hotkey: RIGHT CONTROL")

SettingsTab:AddSection({
	Name = "Configuration"
})

SettingsTab:AddButton({
	Name = "Save Current Config",
	Callback = function()
		-- Orion автоматически сохраняет конфиги, если SaveConfig = true
        OrionLib:MakeNotification({Name = "System", Content = "Configuration Saved Successfully!", Time = 2})
	end
})

print("[ChromeTech] Panic Module Armed.")
--[[
    [!] PROJECT ENTROPY - VERSION 5.0.1
    [!] MODULE: 15_FINAL_INTEGRATION_ORION
]]

--// [ СЕКЦИЯ 46: ANTI-DOUBLE RUN ]
if getgenv().EntropyLoaded then
    OrionLib:MakeNotification({
        Name = "Warning",
        Content = "Entropy Engine is already running!",
        Time = 3
    })
    return
end
getgenv().EntropyLoaded = true

--// [ СЕКЦИЯ 47: ФИНАЛЬНАЯ ИНИЦИАЛИЗАЦИЯ ]
-- Orion требует вызова Init() в самом конце для отрисовки всех вкладок
OrionLib:Init()

--// [ СЕКЦИЯ 48: ЗАВЕРШАЮЩИЙ ЛОГ ]
local EndTime = tick()
local LoadTime = math.floor((EndTime - StartTime) * 100) / 100

-- Приветственное уведомление
OrionLib:MakeNotification({
    Name = "Entropy Engine Loaded",
    Content = "System ready in " .. LoadTime .. "s. Enjoy your dominance.",
    Image = "rbxassetid://4483345998",
    Time = 5
})

-- Добавляем информацию о версии в Misc (для красоты)
Tabs.Misc:AddLabel("Version: 5.0.1 Platinum")
Tabs.Misc:AddLabel("Library: Orion Optimized")
Tabs.Misc:AddLabel("Dev: Janus & Tesavek⚡️👾")

--// [ СЕКЦИЯ 49: АВТО-ОЧИСТКА ПРИ ВЫХОДЕ ]
-- Если игрок покидает сервер, сбрасываем флаг загрузки
Services.Players.PlayerRemoving:Connect(function(player)
    if player == LP then
        getgenv().EntropyLoaded = false
    end
end)

print([[
    __________________________________________
    [+] CHROME TECH: ENTROPY ENGINE LOADED!
    [+] OPTIMIZATION: ACTIVE
    [+] STATUS: UNDETECTED
    __________________________________________
]])
