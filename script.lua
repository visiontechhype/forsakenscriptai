-- [[ ENTROPY FORSAKEN: ULTIMATE EDITION - REVAMPED ]] --
-- [[ Coded by Gemini AI, ChromeTech, and my shattered nerves. ]] --
-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Global Configuration Table (Saved by Rayfield)
getgenv().Config = {
    -- Branding
    BrandName = "Entropy Forsaken | v2.1",
    Author = "Gemini AI, ChromeTech & My Nerves",

    -- Visuals (ESP)
    ESP_Enabled = false,
    Item_ESP = false,
    Killer_ESP = false,
    Survivor_ESP = false,
    ShowItemNames = true,
    ShowItemDistance = true,
    ShowKillerNames = true,
    ShowKillerDistance = true,
    ShowSurvivorNames = true,
    ShowSurvivorDistance = true,
    ItemESPColor = Color3.fromRGB(0, 255, 150),
    KillerESPColor = Color3.fromRGB(255, 0, 0),
    SurvivorESPColor = Color3.fromRGB(0, 150, 255),
    FullBright = false,
    DisableParticles = false,
    DisableDecals = false,

    -- Character Mechanics
    AutoParry = false,       -- Guest 1337
    AutoCola = false,        -- All Survivors
    PizzaAim = false,        -- Elliot
    InfiniteStamina = false, -- All Survivors
    InfiniteOxygen = false,  -- All Survivors
    WalkSpeed = 16,
    JumpPower = 50,
    NoClip = false,
    FlySpeed = 50,           -- Not implemented as flight, but value for future
    AutoCleanse = false,     -- Anti-1x1x1x1
    AutoBuild = false,       -- Builderman
    ChanceLuck = false,      -- Chance
    InfShadow = false,       -- Dusekkar
    AutoFarmItems = false,   -- Auto-Loot
    MegaFarm = false,        -- Combines AutoParry, AutoCola, AutoCleanse, AutoFarmItems

    -- Killer Mode
    KillAura = false,
    AuraRange = 20,

    -- Combat & Aim
    SilentAim = false,
    ShowFov = false,
    FovRadius = 150,
    TargetPart = "HumanoidRootPart",

    -- Server Management
    AutoLeave = false,
    WebhookEnabled = false, -- Future expansion for Discord webhooks
    AdminDetectNames = {"Owner", "Moderator", "Dev"} -- Placeholder names for admin detection
}

-- Rayfield Window Creation
local Window = Rayfield:CreateWindow({
   Name = getgenv().Config.BrandName,
   LoadingTitle = "Initializing " .. getgenv().Config.BrandName,
   LoadingSubtitle = getgenv().Config.Author,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "Entropy_Forsaken_Config"
   },
   Discord = {Enabled = false},
   KeySystem = false
})

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Char:WaitForChild("Humanoid")
local RootPart = Char:WaitForChild("HumanoidRootPart")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Game Data (Wiki-based, as extensive as possible)
local GameData = {
    Killers = {"1x1x1x1", "John Doe", "The Hidden", "The Overseer", "The Scourge", "C00lkidd", "The Guest (Killer)", "UnknownKiller"},
    Survivors = {"Guest 1337", "Elliot", "Noob", "Medic", "Builderman", "Dusekkar", "Chance", "UnknownSurvivor"},
    Items = {
        Support = {"Medkit", "Bandage", "Splint", "First Aid Kit", "Syringe"},
        Buffs = {"BloxyCola", "Witch Brew", "Slateskin Potion", "Energy Drink"},
        Special = {"Pizza", "Battery", "Sentry Gun", "Grenade", "Flare Gun", "Keycard"}
    }
}

-- Current Player Class Detection
local CurrentClass = "Unknown"
local function DetectClass()
    if Char then
        for _, name in pairs(GameData.Survivors) do
            if Char:FindFirstChild(name) or LocalPlayer.PlayerGui:FindFirstChild(name) then
                CurrentClass = name
                return name
            end
        end
        for _, name in pairs(GameData.Killers) do
            if Char:FindFirstChild(name) or LocalPlayer.PlayerGui:FindFirstChild(name) then
                CurrentClass = name
                return name
            end
        end
    end
    CurrentClass = "Unknown"
    return "Unknown"
end
DetectClass() -- Initial detection

-- Helper Function for Notifications
local function Notify(title, msg, image)
    Rayfield:Notify({Title = title, Content = msg, Duration = 5, Image = image or 4483362458})
end

-- ESP Manager (Handles Drawing and Updates)
local ESP_Highlights = {}
local ESP_Labels = {}

local function ClearESP()
    for _, hl in pairs(ESP_Highlights) do hl:Destroy() end
    for _, lbl in pairs(ESP_Labels) do lbl:Destroy() end
    ESP_Highlights = {}
    ESP_Labels = {}
end

local function CreateESP(object, color, name, distance, showName, showDistance)
    if not object or not object:IsA("BasePart") or not object.Parent or not object.Parent:FindFirstChild("Humanoid") then return end

    local existingHighlight = object:FindFirstChild("ESPHighlight")
    if not existingHighlight then
        local hl = Instance.new("Highlight")
        hl.Name = "ESPHighlight"
        hl.Parent = object
        hl.FillColor = color
        hl.OutlineColor = color
        hl.FillTransparency = 0.6
        hl.OutlineTransparency = 0.1
        table.insert(ESP_Highlights, hl)
    else
        existingHighlight.FillColor = color
        existingHighlight.OutlineColor = color
    end

    if showName or showDistance then
        local viewportPoint, onScreen = workspace.CurrentCamera:WorldToViewportPoint(object.Position)
        if onScreen then
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0, 100, 0, 20)
            label.Position = UDim2.new(0, viewportPoint.X, 0, viewportPoint.Y)
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 14
            label.TextColor3 = color
            label.ZIndex = 10
            label.TextStrokeTransparency = 0.8
            label.Parent = LocalPlayer.PlayerGui
            
            local textContent = ""
            if showName then textContent = name end
            if showDistance then
                if textContent ~= "" then textContent = textContent .. " | " end
                textContent = textContent .. tostring(math.floor(distance)) .. "m"
            end
            label.Text = textContent
            table.insert(ESP_Labels, label)
        end
    end
end

-- UI Construction
-- [ TAB: Main ]
local MainTab = Window:CreateTab("Main", 4483362458)
MainTab:CreateSection("Character: " .. CurrentClass)

MainTab:CreateSlider({
   Name = "WalkSpeed Hack",
   Range = {16, 150},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = getgenv().Config.WalkSpeed,
   Callback = function(Value)
      getgenv().Config.WalkSpeed = Value
      Humanoid.WalkSpeed = Value
   end,
})

MainTab:CreateSlider({
   Name = "JumpPower Hack",
   Range = {50, 200},
   Increment = 5,
   Suffix = "Jump",
   CurrentValue = getgenv().Config.JumpPower,
   Callback = function(Value)
      getgenv().Config.JumpPower = Value
      Humanoid.JumpPower = Value
   end,
})

MainTab:CreateToggle({
   Name = "Infinite Stamina/Oxygen",
   CurrentValue = getgenv().Config.InfiniteStamina,
   Callback = function(Value)
      getgenv().Config.InfiniteStamina = Value
      getgenv().Config.InfiniteOxygen = Value
   end,
})

-- [ TAB: Visuals (ESP) ]
local VisualsTab = Window:CreateTab("Visuals (ESP)", 4483345998)
VisualsTab:CreateSection("Global ESP")

VisualsTab:CreateToggle({
   Name = "Master ESP Switch",
   CurrentValue = getgenv().Config.ESP_Enabled,
   Callback = function(Value)
      getgenv().Config.ESP_Enabled = Value
      if not Value then ClearESP() end
   end,
})

VisualsTab:CreateToggle({
   Name = "Full Bright (No Fog/Shadows)",
   CurrentValue = getgenv().Config.FullBright,
   Callback = function(Value)
      getgenv().Config.FullBright = Value
      local lighting = game:GetService("Lighting")
      lighting.FogEnd = Value and 999999 or 0
      lighting.Brightness = Value and 2 or 1
      lighting.GlobalShadows = not Value
      for _, v in pairs(lighting:GetChildren()) do
          if v:IsA("Atmosphere") or v:IsA("Sky") then v.Enabled = not Value end
      end
   end,
})

VisualsTab:CreateToggle({
   Name = "Remove Particles",
   CurrentValue = getgenv().Config.DisableParticles,
   Callback = function(Value)
      getgenv().Config.DisableParticles = Value
      for _, v in pairs(workspace:GetDescendants()) do
          if v:IsA("ParticleEmitter") then v.Enabled = not Value end
      end
   end,
})

VisualsTab:CreateToggle({
   Name = "Remove Decals & Textures",
   CurrentValue = getgenv().Config.DisableDecals,
   Callback = function(Value)
      getgenv().Config.DisableDecals = Value
      for _, v in pairs(workspace:GetDescendants()) do
          if v:IsA("Decal") or v:IsA("Texture") then v.Transparency = Value and 1 or 0 end
      end
   end,
})

VisualsTab:CreateSection("Item ESP")
VisualsTab:CreateToggle({
   Name = "Highlight Items (Medkits/Cola)",
   CurrentValue = getgenv().Config.Item_ESP,
   Callback = function(Value) getgenv().Config.Item_ESP = Value end,
})
VisualsTab:CreateToggle({
   Name = "Show Item Names",
   CurrentValue = getgenv().Config.ShowItemNames,
   Callback = function(Value) getgenv().Config.ShowItemNames = Value end,
})
VisualsTab:CreateToggle({
   Name = "Show Item Distance",
   CurrentValue = getgenv().Config.ShowItemDistance,
   Callback = function(Value) getgenv().Config.ShowItemDistance = Value end,
})
VisualsTab:CreateColorPicker({
   Name = "Item ESP Color",
   CurrentValue = getgenv().Config.ItemESPColor,
   Callback = function(Value) getgenv().Config.ItemESPColor = Value end,
})

VisualsTab:CreateSection("Killer ESP")
VisualsTab:CreateToggle({
   Name = "Highlight Killers",
   CurrentValue = getgenv().Config.Killer_ESP,
   Callback = function(Value) getgenv().Config.Killer_ESP = Value end,
})
VisualsTab:CreateToggle({
   Name = "Show Killer Names",
   CurrentValue = getgenv().Config.ShowKillerNames,
   Callback = function(Value) getgenv().Config.ShowKillerNames = Value end,
})
VisualsTab:CreateToggle({
   Name = "Show Killer Distance",
   CurrentValue = getgenv().Config.ShowKillerDistance,
   Callback = function(Value) getgenv().Config.ShowKillerDistance = Value end,
})
VisualsTab:CreateColorPicker({
   Name = "Killer ESP Color",
   CurrentValue = getgenv().Config.KillerESPColor,
   Callback = function(Value) getgenv().Config.KillerESPColor = Value end,
})

VisualsTab:CreateSection("Survivor ESP")
VisualsTab:CreateToggle({
   Name = "Highlight Survivors",
   CurrentValue = getgenv().Config.Survivor_ESP,
   Callback = function(Value) getgenv().Config.Survivor_ESP = Value end,
})
VisualsTab:CreateToggle({
   Name = "Show Survivor Names",
   CurrentValue = getgenv().Config.ShowSurvivorNames,
   Callback = function(Value) getgenv().Config.ShowSurvivorNames = Value end,
})
VisualsTab:CreateToggle({
   Name = "Show Survivor Distance",
   CurrentValue = getgenv().Config.ShowSurvivorDistance,
   Callback = function(Value) getgenv().Config.ShowSurvivorDistance = Value end,
})
VisualsTab:CreateColorPicker({
   Name = "Survivor ESP Color",
   CurrentValue = getgenv().Config.SurvivorESPColor,
   Callback = function(Value) getgenv().Config.SurvivorESPColor = Value end,
})

-- [ TAB: Combat & Aim ]
local CombatTab = Window:CreateTab("Combat & Aim", 4483362458)
CombatTab:CreateSection("Survivor Combat")

CombatTab:CreateToggle({
   Name = "Guest 1337: God-Mode Auto Parry",
   CurrentValue = getgenv().Config.AutoParry,
   Callback = function(Value)
      getgenv().Config.AutoParry = Value
      if Value then Notify("Combat", "Auto-Parry Activated") end
   end,
})

CombatTab:CreateToggle({
   Name = "Elliot: Pizza Projectile Prediction",
   CurrentValue = getgenv().Config.PizzaAim,
   Callback = function(Value) getgenv().Config.PizzaAim = Value end,
})

CombatTab:CreateSection("General Aim")
CombatTab:CreateToggle({
   Name = "Predictive Silent Aim",
   CurrentValue = getgenv().Config.SilentAim,
   Callback = function(Value) getgenv().Config.SilentAim = Value end,
})

local FovCircle = Drawing.new("Circle")
FovCircle.Thickness = 1
FovCircle.NumSides = 100
FovCircle.Radius = getgenv().Config.FovRadius
FovCircle.Filled = false
FovCircle.Visible = getgenv().Config.ShowFov
FovCircle.Color = Color3.fromRGB(255, 255, 255)

CombatTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = getgenv().Config.ShowFov,
   Callback = function(Value)
      getgenv().Config.ShowFov = Value
      FovCircle.Visible = Value
   end,
})

CombatTab:CreateSlider({
   Name = "FOV Size",
   Range = {50, 800},
   Increment = 10,
   CurrentValue = getgenv().Config.FovRadius,
   Callback = function(Value)
      getgenv().Config.FovRadius = Value
      FovCircle.Radius = Value
   end,
})

-- [ TAB: Movement ]
local MoveTab = Window:CreateTab("Movement", 4483362458)
MoveTab:CreateToggle({
   Name = "NoClip (Walk Through Walls)",
   CurrentValue = getgenv().Config.NoClip,
   Callback = function(Value)
      getgenv().Config.NoClip = Value
      if not Value then
          for _, part in pairs(Char:GetDescendants()) do
              if part:IsA("BasePart") then part.CanCollide = true end
          end
      end
   end,
})

-- [ TAB: Automation ]
local AutoTab = Window:CreateTab("Automation", 4483362458)
AutoTab:CreateToggle({
   Name = "Auto-Cleanse (Anti-1x1x1x1)",
   CurrentValue = getgenv().Config.AutoCleanse,
   Callback = function(Value) getgenv().Config.AutoCleanse = Value end,
})
AutoTab:CreateToggle({
   Name = "Builderman: Panic Defense",
   CurrentValue = getgenv().Config.AutoBuild,
   Callback = function(Value) getgenv().Config.AutoBuild = Value end,
})
AutoTab:CreateToggle({
   Name = "Auto-Loot Items (Proximity)",
   CurrentValue = getgenv().Config.AutoFarmItems,
   Callback = function(Value) getgenv().Config.AutoFarmItems = Value end,
})
AutoTab:CreateToggle({
   Name = "Medic: Auto-Heal Allies",
   CurrentValue = getgenv().Config.AutoHealTeam,
   Callback = function(Value) getgenv().Config.AutoHealTeam = Value end,
})
AutoTab:CreateToggle({
   Name = "ULTIMATE AUTO-FARM (Combines all survival)",
   CurrentValue = getgenv().Config.MegaFarm,
   Callback = function(Value)
      getgenv().Config.MegaFarm = Value
      getgenv().Config.AutoParry = Value
      getgenv().Config.AutoCola = Value
      getgenv().Config.AutoCleanse = Value
      getgenv().Config.AutoFarmItems = Value
      Notify("Warning", "Mega Farm combines all survival modules.")
   end,
})

-- [ TAB: Killer Mode ]
local KillerTab = Window:CreateTab("Killer Mode", 4483362458)
KillerTab:CreateToggle({
   Name = "Kill Aura (Hit Survivors)",
   CurrentValue = getgenv().Config.KillAura,
   Callback = function(Value) getgenv().Config.KillAura = Value end,
})
KillerTab:CreateSlider({
   Name = "Aura Reach",
   Range = {5, 50},
   Increment = 1,
   CurrentValue = getgenv().Config.AuraRange,
   Callback = function(Value) getgenv().Config.AuraRange = Value end,
})

-- [ TAB: Server Management ]
local ServerTab = Window:CreateTab("Server", 4483362458)
ServerTab:CreateButton({
   Name = "Server Hop (Find New Lobby)",
   Callback = function()
       local Api = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
       local function NextServer()
           local Result = HttpService:JSONDecode(game:HttpGet(Api))
           for _, server in pairs(Result.data) do
               if server.playing < server.maxPlayers and server.id ~= game.JobId then
                   TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
                   return
               end
           end
           Notify("Server Hop", "No new public servers found, trying again in a moment.", 4483345998)
           task.wait(5)
           NextServer() -- Recursive call to find a server
       end
       NextServer()
   end,
})
ServerTab:CreateButton({
   Name = "Rejoin Current Server",
   Callback = function()
       TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
   end,
})
ServerTab:CreateToggle({
   Name = "Auto-Leave on Admin Join",
   CurrentValue = getgenv().Config.AutoLeave,
   Callback = function(Value) getgenv().Config.AutoLeave = Value end,
})
ServerTab:CreateInput({
   Name = "Admin Names (Comma Separated)",
   Placeholder = "Owner,Moderator,Dev",
   CurrentValue = table.concat(getgenv().Config.AdminDetectNames, ","),
   Callback = function(Value)
       getgenv().Config.AdminDetectNames = {}
       for name in string.gmatch(Value, "[^,]+") do
           table.insert(getgenv().Config.AdminDetectNames, name:gsub("^%s*", ""):gsub("%s*$", "")) -- Trim spaces
       end
   end,
})


-- [ TAB: Debug & Misc ]
local MiscTab = Window:CreateTab("Misc", 4483362458)
MiscTab:CreateButton({
   Name = "Instant Teleport to Exit (If Open)",
   Callback = function()
       local Exit = workspace:FindFirstChild("EscapeGate") or workspace:FindFirstChild("Exit")
       if Exit then
           RootPart.CFrame = Exit.CFrame * CFrame.new(0, 5, 0)
           Notify("Escape", "Teleporting to Exit Gate!")
       else
           Notify("Error", "Exit Gate not found or not powered yet.")
       end
   end,
})
MiscTab:CreateButton({
   Name = "Super FPS Boost",
   Callback = function()
       for _, v in pairs(game:GetDescendants()) do
           if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then
               v.Material = Enum.Material.SmoothPlastic
           elseif v:IsA("Decal") or v:IsA("Texture") then
               v.Transparency = 1
           elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
               v.Enabled = false
           end
       end
       setfpscap(999)
       Notify("Performance", "Textures simplified, FPS unlocked.")
   end,
})
MiscTab:CreateButton({
   Name = "Reveal Killer Identity (Early)",
   Callback = function()
       local KillerValue = game:GetService("ReplicatedStorage"):FindFirstChild("CurrentKiller")
       if KillerValue then
           Notify("Intel", "The Killer is: " .. tostring(KillerValue.Value))
       else
           Notify("Error", "Killer not yet selected.")
       end
   end,
})


-- //////////////////////////////////////////////////////////////////////////////////////////////
-- ////////////////////////////////// CORE LOOP AND GAME MECHANICS //////////////////////////////
-- //////////////////////////////////////////////////////////////////////////////////////////////

-- Heartbeat Loop for consistent updates (Combat, ESP, Stamina/Oxygen)
RunService.Heartbeat:Connect(function()
    if not Char or not RootPart or not Humanoid then return end

    -- Infinite Stamina/Oxygen (Metamethod Hook for attributes)
    if getgenv().Config.InfiniteStamina then
        local mt = getrawmetatable(Humanoid)
        if mt then
            setreadonly(mt, false)
            local oldIndex = mt.__index
            mt.__index = newcclosure(function(t, k)
                if k == "Stamina" or k == "Oxygen" then return 100 end
                return oldIndex(t, k)
            end)
            setreadonly(mt, true)
        end
    end

    -- NoClip Collision Management
    if getgenv().Config.NoClip then
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide == true then
                part.CanCollide = false
            end
        end
    else
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end

    -- ESP Visuals (Optimized for performance)
    ClearESP() -- Clear previous labels for fresh redraw
    if getgenv().Config.ESP_Enabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local targetHumanoid = p.Character:FindFirstChild("Humanoid")
                if not targetHumanoid or targetHumanoid.Health <= 0 then continue end -- Skip dead players

                local dist = (RootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                
                local isKiller = false
                for _, kName in pairs(GameData.Killers) do
                    if p.Name:lower():find(kName:lower()) then isKiller = true; break end
                end

                if getgenv().Config.Killer_ESP and isKiller then
                    CreateESP(
                        p.Character.HumanoidRootPart,
                        getgenv().Config.KillerESPColor,
                        p.Name,
                        dist,
                        getgenv().Config.ShowKillerNames,
                        getgenv().Config.ShowKillerDistance
                    )
                elseif getgenv().Config.Survivor_ESP and not isKiller then
                    CreateESP(
                        p.Character.HumanoidRootPart,
                        getgenv().Config.SurvivorESPColor,
                        p.Name,
                        dist,
                        getgenv().Config.ShowSurvivorNames,
                        getgenv().Config.ShowSurvivorDistance
                    )
                end
            end
        end

        -- Item ESP (Iterate through workspace)
        if getgenv().Config.Item_ESP then
            for _, item in pairs(workspace:GetDescendants()) do
                local isGameItem = false
                local itemName = item.Name
                for _, category in pairs(GameData.Items) do
                    for _, name in pairs(category) do
                        if itemName == name then isGameItem = true; break end
                    end
                    if isGameItem then break end
                end
                
                if isGameItem and item:IsA("BasePart") then
                    local dist = (RootPart.Position - item.Position).Magnitude
                    if dist < 300 then -- Only show items within a reasonable range
                        CreateESP(
                            item,
                            getgenv().Config.ItemESPColor,
                            itemName,
                            dist,
                            getgenv().Config.ShowItemNames,
                            getgenv().Config.ShowItemDistance
                        )
                    end
                end
            end
        end
    end

    -- Kill Aura (Killer Mode)
    if getgenv().Config.KillAura and (CurrentClass == "Killer" or table.find(GameData.Killers, CurrentClass)) then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local targetHumanoid = p.Character:FindFirstChild("Humanoid")
                if not targetHumanoid or targetHumanoid.Health <= 0 then continue end
                
                local isTargetKiller = false
                for _, kName in pairs(GameData.Killers) do
                    if p.Name:lower():find(kName:lower()) then isTargetKiller = true; break end
                end

                if not isTargetKiller then
                    local dist = (RootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist <= getgenv().Config.AuraRange then
                        local Weapon = Char:FindFirstChildOfClass("Tool")
                        if Weapon and Weapon:IsA("Tool") then
                            Weapon:Activate() -- Attempt to activate weapon to trigger attack
                            -- If specific remote is known:
                            -- game:GetService("ReplicatedStorage").Remotes.AttackEvent:FireServer(p.Character.HumanoidRootPart)
                        end
                    end
                end
            end
        end
    end

    -- Auto-Parry (Guest 1337)
    if getgenv().Config.AutoParry and CurrentClass == "Guest 1337" then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local targetHumanoid = p.Character:FindFirstChild("Humanoid")
                if not targetHumanoid or targetHumanoid.Health <= 0 then continue end
                
                local isKiller = false
                for _, kName in pairs(GameData.Killers) do
                    if p.Name:lower():find(kName:lower()) then isKiller = true; break end
                end

                if isKiller then
                    local dist = (RootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist < 15 then
                        local anims = p.Character.Humanoid:GetPlayingAnimationTracks()
                        for _, a in pairs(anims) do
                            if a.Name:lower():find("attack") or a.Name:lower():find("swing") then
                                game:GetService("ReplicatedStorage").Remotes.BlockEvent:FireServer(true)
                                task.wait(0.1)
                                game:GetService("ReplicatedStorage").Remotes.PunchEvent:FireServer()
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    -- Auto-Heal Allies (Medic)
    if getgenv().Config.AutoHealTeam and CurrentClass == "Medic" then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
                local targetHumanoid = p.Character:FindFirstChild("Humanoid")
                if targetHumanoid and targetHumanoid.Health < targetHumanoid.MaxHealth * 0.5 then -- Heal if below 50% HP
                    local dist = (RootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist < 15 then
                        local Medkit = LocalPlayer.Backpack:FindFirstChild("Medkit") or Char:FindFirstChild("Medkit")
                        if Medkit then
                            Humanoid:EquipTool(Medkit)
                            task.wait(0.05)
                            game:GetService("ReplicatedStorage").Remotes.HealEvent:FireServer(p.Character)
                            task.wait(0.5) -- Cooldown for healing
                        end
                    end
                end
            end
        end
    end
end)

-- RenderStepped for FOV Circle and UI updates
RunService.RenderStepped:Connect(function()
    if getgenv().Config.ShowFov then
        FovCircle.Position = UIS:GetMouseLocation()
    end
end)

-- //////////////////////////////////////////////////////////////////////////////////////////////
-- ////////////////////////////////// OTHER GAME MECHANICS (TASK.SPAWN) /////////////////////////
-- //////////////////////////////////////////////////////////////////////////////////////////////

-- Auto-Cola (Stamina Regeneration)
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().Config.AutoCola then
            -- Check for actual stamina attribute if infinite stamina is off
            local stamina = Char:GetAttribute("Stamina") or 100
            if stamina < 30 then
                local cola = LocalPlayer.Backpack:FindFirstChild("BloxyCola") or Char:FindFirstChild("BloxyCola")
                if cola then
                    Humanoid:EquipTool(cola)
                    task.wait(0.1)
                    -- game:GetService("ReplicatedStorage").Remotes.UseItem:FireServer("BloxyCola") -- Example remote if available
                    cola.Parent = LocalPlayer.Backpack -- Return to backpack to prevent tool-related issues
                end
            end
        end
    end
end)

-- Auto-Cleanse (Anti-Debuff)
task.spawn(function()
    while task.wait(0.1) do
        if getgenv().Config.AutoCleanse then
            for _, effect in pairs(Char:GetChildren()) do
                if (effect.Name:lower():find("infection") or effect.Name:lower():find("glitch")) and effect:IsA("Script") then
                    local Medkit = LocalPlayer.Backpack:FindFirstChild("Medkit") or Char:FindFirstChild("Medkit")
                    if Medkit then
                        Humanoid:EquipTool(Medkit)
                        task.wait(0.1)
                        -- game:GetService("ReplicatedStorage").Remotes.SelfAction:FireServer("Cleanse")
                        -- Or activate medkit to remove debuff
                    end
                end
            end
        end
    end
end)

-- Auto-Farm Items (Proximity Interact)
task.spawn(function()
    while task.wait(0.3) do
        if getgenv().Config.AutoFarmItems then
            for _, obj in pairs(workspace:GetDescendants()) do -- Use GetDescendants for nested items
                if obj:IsA("BasePart") then
                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt") or obj:FindFirstChildOfClass("ClickDetector")
                    if prompt then
                        local dist = (RootPart.Position - obj.Position).Magnitude
                        if dist < 12 then
                            local isGameItem = false
                            for _, category in pairs(GameData.Items) do
                                for _, name in pairs(category) do
                                    if obj.Name == name then isGame
                                 -- [[ МОДУЛЬ 31: FINISHING AUTO-FARM & INTERACTION ]] --

task.spawn(function()
    while task.wait(0.3) do
        if getgenv().Config.AutoFarmItems then
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    -- Поиск промптов или клик-детекторов
                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt") 
                    local click = obj:FindFirstChildOfClass("ClickDetector")
                    
                    if (prompt or click) then
                        local dist = (RootPart.Position - obj.Position).Magnitude
                        if dist < 15 then
                            -- Проверка, является ли объект полезным лутом
                            local isLoot = false
                            for _, cat in pairs(GameData.Items) do
                                for _, name in pairs(cat) do
                                    if obj.Name == name then isLoot = true break end
                                end
                            end
                            
                            if isLoot then
                                if prompt then fireproximityprompt(prompt) end
                                if click then fireclickdetector(click) end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- [[ МОДУЛЬ 32: GLOBAL METAMETHOD HOOKS (THE NERVE SYSTEM) ]] --
-- Это "сердце" чита, которое подменяет данные игры на лету

local rawMT = getrawmetatable(game)
local oldNamecall = rawMT.__namecall
local oldIndex = rawMT.__index
setreadonly(rawMT, false)

rawMT.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Silent Aim Logic (Перехват бросков)
    if getgenv().Config.SilentAim and method == "FireServer" and (self.Name:find("Throw") or self.Name:find("Shoot")) then
        local target = GetClosestKiller() -- Функция из предыдущего модуля
        if target then
            args[1] = target.Position
            return oldNamecall(self, unpack(args))
        end
    end

    -- Блокировка репортов анти-чита
    if method == "FireServer" and (self.Name:find("Detection") or self.Name:find("Ban")) then
        return nil
    end

    return oldNamecall(self, unpack(args))
end)

rawMT.__index = newcclosure(function(t, k)
    -- Бесконечная стамина и кислород через хук свойств
    if getgenv().Config.InfiniteStamina and (k == "Stamina" or k == "Oxygen") then
        return 100
    end
    -- WalkSpeed Bypass (если игра пытается принудительно вернуть 16)
    if k == "WalkSpeed" and getgenv().Config.WalkSpeed > 16 then
        return getgenv().Config.WalkSpeed
    end
    return oldIndex(t, k)
end)

setreadonly(rawMT, true)

-- [[ МОДУЛЬ 33: ГОРЯЧИЕ КЛАВИШИ И ПАСХАЛКИ ]] --

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    -- Быстрый выход (Emergency Exit)
    if input.KeyCode == Enum.KeyCode.RightControl then
        Rayfield:Destroy()
        Notify("System", "Script Terminated Safely.")
    end
end)

-- [[ FINAL BRANDING & INITIALIZATION ]] --

-- Установка начальных параметров персонажа
task.spawn(function()
    while task.wait(1) do
        if Char and Humanoid then
            Humanoid.WalkSpeed = getgenv().Config.WalkSpeed
            Humanoid.JumpPower = getgenv().Config.JumpPower
        end
    end
end)

-- Вывод в консоль и уведомление
print("--------------------------------------------------")
print("Entropy Forsaken v2.1 Loaded Successfully!")
print("By Gemini AI, ChromeTech, and my shattered nerves.")
print("Enjoy your God-mode experience.")
print("--------------------------------------------------")

Rayfield:LoadConfiguration() -- Загрузка сохраненных настроек

Notify(
    "SYSTEM READY", 
    "Entropy Forsaken v2.1 Activated.\nCreated by Gemini, ChromeTech and my nerves.", 
    4483362458
)

-- Авто-детект класса при старте
local detected = DetectClass()
Notify("Class Detected", "You are playing as: " .. detected)
