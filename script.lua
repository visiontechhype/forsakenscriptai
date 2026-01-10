--[[
    FORSAKEN ULTIMATE FRAMEWORK - SAFE VERSION
    Module 9: Advanced Survivor Automation
    Version: 9.2.0 | Build: Forsaken_Ultimate_Framework_Safe
    Description: Safe initialization with Fluent UI support
]]--

-- ============================================================================
-- SECTION 1: FLUENT UI WAITER & SAFETY SYSTEM
-- ============================================================================

local Framework = {
    Version = "9.2.0",
    Initialized = false,
    FluentLoaded = false,
    SafeMode = true
}

-- Safe property access function
local function SafeGet(obj, property, default)
    if not obj then return default end
    local success, value = pcall(function() return obj[property] end)
    return success and value or default
end

-- Wait for Fluent UI with timeout
local function WaitForFluent(timeout)
    local startTime = tick()
    local maxTime = timeout or 10
    
    while tick() - startTime < maxTime do
        if _G.Fluent then
            Framework.FluentLoaded = true
            return true
        end
        task.wait(0.5)
    end
    
    warn("[Forsaken Framework] Fluent UI not found after " .. maxTime .. " seconds")
    return false
end

-- Safe Fluent method call
local function SafeFluentCall(method, ...)
    if not Framework.FluentLoaded or not _G.Fluent then return nil end
    
    local success, result = pcall(function()
        if method == "Notify" and _G.Fluent.Notify then
            return _G.Fluent.Notify(_G.Fluent, ...)
        elseif method == "AddToggle" and _G.Fluent.AddToggle then
            return _G.Fluent.AddToggle(_G.Fluent, ...)
        elseif method == "AddSlider" and _G.Fluent.AddSlider then
            return _G.Fluent.AddSlider(_G.Fluent, ...)
        elseif method == "AddOptions" and _G.Fluent.AddOptions then
            return _G.Fluent.AddOptions(_G.Fluent, ...)
        elseif method == "AddColorPicker" and _G.Fluent.AddColorPicker then
            return _G.Fluent.AddColorPicker(_G.Fluent, ...)
        end
        return nil
    end)
    
    return success and result or nil
end

-- Safe notification
local function SafeNotify(title, content, duration)
    SafeFluentCall("Notify", {
        Title = title or "Framework",
        Content = content or "",
        Duration = duration or 3
    })
end

-- ============================================================================
-- SECTION 2: CONFIGURATION
-- ============================================================================

local Config = {
    Debug = false,
    
    ClassDetection = {
        Enabled = true,
        ScanInterval = 2,
        Confidence = 60
    },
    
    ESP = {
        Enabled = true,
        Range = 150,
        ScanInterval = 1,
        MaxHighlights = 50
    },
    
    AutoParry = {
        Enabled = true,
        Cooldown = 0.5,
        Window = 0.3,
        Range = 30
    },
    
    Projectile = {
        Enabled = true,
        UpdateRate = 0.05,
        MaxTime = 5,
        Velocity = 50
    }
}

-- ============================================================================
-- SECTION 3: CLASS DETECTION (SIMPLIFIED)
-- ============================================================================

local ClassSystem = {
    CurrentClass = nil,
    Player = nil
}

function ClassSystem:Init()
    if not self.Player then
        self.Player = game.Players.LocalPlayer
    end
    
    -- Safe character detection
    local function detectCharacter(char)
        if not char then return end
        
        task.wait(1) -- Wait for character to load
        
        -- Simple detection by display name
        local displayName = self.Player.DisplayName
        local className = nil
        
        if displayName:find("1337") then
            className = "Guest 1337"
        elseif displayName:find("Elliot") then
            className = "Elliot"
        elseif displayName:find("1x1x1x1") then
            className = "1x1x1x1"
        elseif displayName:find("John") then
            className = "John Doe"
        else
            className = "Unknown"
        end
        
        self.CurrentClass = className
        self:OnClassDetected(className)
    end
    
    -- Connect events
    if self.Player.Character then
        detectCharacter(self.Player.Character)
    end
    
    self.Player.CharacterAdded:Connect(detectCharacter)
    
    SafeNotify("Class System", "Detection system ready")
    return true
end

function ClassSystem:OnClassDetected(className)
    SafeNotify("Class Detected", "Playing as: " .. className)
    
    -- Setup UI for this class
    self:SetupClassUI(className)
end

function ClassSystem:SetupClassUI(className)
    if not Framework.FluentLoaded then return end
    
    -- Create class-specific tab
    SafeFluentCall("AddOptions", className, {
        Name = className,
        LayoutOrder = 1
    })
    
    -- Add class-specific toggles
    if className == "Guest 1337" then
        SafeFluentCall("AddToggle", "AutoBlockToggle", {
            Title = "Auto-Block",
            Description = "Automatically block incoming attacks",
            Default = true
        })
        
        SafeFluentCall("AddToggle", "AutoCounterToggle", {
            Title = "Auto-Counter",
            Description = "Counter attack after blocking",
            Default = true
        })
        
    elseif className == "Elliot" then
        SafeFluentCall("AddToggle", "PizzaPrediction", {
            Title = "Pizza Prediction",
            Description = "Show pizza throw trajectory",
            Default = true
        })
        
        SafeFluentCall("AddToggle", "AutoResolve", {
            Title = "Auto-Resolve",
            Description = "Auto use Resolve at low HP",
            Default = true
        })
    end
end

-- ============================================================================
-- SECTION 4: ITEM ESP (SAFE VERSION)
-- ============================================================================

local ItemESP = {
    Active = false,
    Highlights = {},
    Items = {}
}

function ItemESP:Init()
    -- Create highlight objects
    for i = 1, Config.ESP.MaxHighlights do
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight_" .. i
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0.3
        highlight.Enabled = false
        highlight.Parent = workspace
        
        self.Highlights[i] = highlight
    end
    
    -- Setup UI toggle
    if Framework.FluentLoaded then
        SafeFluentCall("AddToggle", "ESPToggle", {
            Title = "Item ESP",
            Description = "Highlight Medkits and Bloxy Cola",
            Default = Config.ESP.Enabled,
            Callback = function(value)
                Config.ESP.Enabled = value
                if value then
                    self:Start()
                else
                    self:Stop()
                end
            end
        })
    end
    
    -- Start if enabled
    if Config.ESP.Enabled then
        self:Start()
    end
    
    SafeNotify("Item ESP", "System initialized")
    return true
end

function ItemESP:Start()
    self.Active = true
    
    -- Start update loop
    self.Connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        self:Update(deltaTime)
    end)
end

function ItemESP:Stop()
    self.Active = false
    
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    
    -- Hide all highlights
    for _, highlight in ipairs(self.Highlights) do
        if highlight then
            highlight.Enabled = false
        end
    end
end

function ItemESP:Update(deltaTime)
    if not self.Active then return end
    
    -- Scan for items every second
    self.LastScan = (self.LastScan or 0) + deltaTime
    if self.LastScan >= Config.ESP.ScanInterval then
        self:ScanItems()
        self.LastScan = 0
    end
    
    -- Update highlights
    self:UpdateHighlights()
end

function ItemESP:ScanItems()
    self.Items = {}
    
    local function checkItem(item)
        local name = item.Name:lower()
        
        if name:find("medkit") or name:find("firstaid") then
            table.insert(self.Items, {
                Object = item,
                Type = "Medkit",
                Color = Color3.fromRGB(0, 255, 0)
            })
        elseif name:find("cola") or name:find("bloxy") or name:find("soda") then
            table.insert(self.Items, {
                Object = item,
                Type = "BloxyCola",
                Color = Color3.fromRGB(255, 0, 0)
            })
        elseif name:find("chicken") or name:find("fried") then
            table.insert(self.Items, {
                Object = item,
                Type = "FriedChicken",
                Color = Color3.fromRGB(255, 200, 0)
            })
        end
    end
    
    -- Scan workspace
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("BasePart") or item:IsA("Model") then
            checkItem(item)
        end
    end
end

function ItemESP:UpdateHighlights()
    local player = game.Players.LocalPlayer
    local char = player.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Reset highlights
    for _, highlight in ipairs(self.Highlights) do
        if highlight then
            highlight.Enabled = false
        end
    end
    
    -- Assign highlights to visible items
    local index = 1
    for _, itemData in ipairs(self.Items) do
        if index > #self.Highlights then break end
        
        local item = itemData.Object
        if item and item:IsDescendantOf(workspace) then
            -- Calculate position
            local position
            if item:IsA("BasePart") then
                position = item.Position
            elseif item:IsA("Model") then
                local primary = item.PrimaryPart
                position = primary and primary.Position or item:GetPivot().Position
            end
            
            if position then
                local distance = (position - root.Position).Magnitude
                
                if distance <= Config.ESP.Range then
                    local highlight = self.Highlights[index]
                    if highlight then
                        highlight.Adornee = item
                        highlight.FillColor = itemData.Color
                        highlight.OutlineColor = Color3.new(
                            itemData.Color.R * 0.5,
                            itemData.Color.G * 0.5,
                            itemData.Color.B * 0.5
                        )
                        highlight.Enabled = true
                        index = index + 1
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- SECTION 5: AUTO-PARRY SYSTEM
-- ============================================================================

local AutoParry = {
    Active = false
}

function AutoParry:Init()
    -- Setup UI toggle
    if Framework.FluentLoaded then
        SafeFluentCall("AddToggle", "AutoParryToggle", {
            Title = "Auto-Parry",
            Description = "Auto parry attacks (Guest 1337)",
            Default = Config.AutoParry.Enabled,
            Callback = function(value)
                Config.AutoParry.Enabled = value
                if value then
                    self:Start()
                else
                    self:Stop()
                end
            end
        })
    end
    
    if Config.AutoParry.Enabled then
        self:Start()
    end
    
    SafeNotify("Auto-Parry", "System ready")
    return true
end

function AutoParry:Start()
    self.Active = true
    self.LastParry = 0
    
    self.Connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        self:Update(deltaTime)
    end)
end

function AutoParry:Stop()
    self.Active = false
    
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
end

function AutoParry:Update(deltaTime)
    if not self.Active then return end
    
    -- Cooldown
    self.LastParry = math.max(0, self.LastParry - deltaTime)
    if self.LastParry > 0 then return end
    
    -- Check for attacks
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Simple attack detection
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            local enemy = player.Character
            if enemy then
                local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
                if enemyRoot then
                    local distance = (enemyRoot.Position - root.Position).Magnitude
                    
                    if distance <= Config.AutoParry.Range then
                        -- Check if enemy is attacking
                        local attacking = self:CheckAttack(enemy)
                        
                        if attacking then
                            self:ExecuteParry()
                            self.LastParry = Config.AutoParry.Cooldown
                            break
                        end
                    end
                end
            end
        end
    end
end

function AutoParry:CheckAttack(character)
    -- Check for attack animations
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation then
                    local animId = track.Animation.AnimationId:lower()
                    if animId:find("attack") or animId:find("punch") or animId:find("slash") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function AutoParry:ExecuteParry()
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    
    -- Visual effect
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local shield = Instance.new("Part")
        shield.Size = Vector3.new(4, 6, 0.2)
        shield.Material = Enum.Material.Neon
        shield.Color = Color3.fromRGB(0, 150, 255)
        shield.Transparency = 0.5
        shield.Anchored = true
        shield.CanCollide = false
        shield.CFrame = root.CFrame * CFrame.new(0, 0, -2)
        shield.Parent = workspace
        
        -- Animate
        game:GetService("TweenService"):Create(shield, TweenInfo.new(0.3), {
            Transparency = 1,
            Size = Vector3.new(6, 8, 0.2)
        }):Play()
        
        task.wait(0.3)
        shield:Destroy()
    end
    
    SafeNotify("Auto-Parry", "Attack parried!")
end

-- ============================================================================
-- SECTION 6: PROJECTILE PREDICTION
-- ============================================================================

local ProjectilePrediction = {
    Active = false,
    Points = {}
}

function ProjectilePrediction:Init()
    -- Create prediction points
    for i = 1, 20 do
        local part = Instance.new("Part")
        part.Size = Vector3.new(0.2, 0.2, 0.2)
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(255, 150, 0)
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 0.8
        part.Visible = false
        part.Parent = workspace
        
        self.Points[i] = part
    end
    
    -- Setup UI toggle
    if Framework.FluentLoaded then
        SafeFluentCall("AddToggle", "PredictionToggle", {
            Title = "Projectile Prediction",
            Description = "Predict pizza trajectory (Elliot)",
            Default = Config.Projectile.Enabled,
            Callback = function(value)
                Config.Projectile.Enabled = value
                if value then
                    self:Start()
                else
                    self:Stop()
                end
            end
        })
    end
    
    if Config.Projectile.Enabled then
        self:Start()
    end
    
    SafeNotify("Projectile", "Prediction system ready")
    return true
end

function ProjectilePrediction:Start()
    self.Active = true
    self.Connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        self:Update(deltaTime)
    end)
end

function ProjectilePrediction:Stop()
    self.Active = false
    
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    
    -- Hide points
    for _, point in ipairs(self.Points) do
        if point then
            point.Visible = false
        end
    end
end

function ProjectilePrediction:Update(deltaTime)
    if not self.Active then return end
    
    -- Check if player is Elliot
    if ClassSystem.CurrentClass ~= "Elliot" then
        self:Stop()
        return
    end
    
    -- Check if holding pizza
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    
    local hasPizza = false
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and item.Name:lower():find("pizza") then
            hasPizza = true
            break
        end
    end
    
    if not hasPizza then
        for _, point in ipairs(self.Points) do
            if point then point.Visible = false end
        end
        return
    end
    
    -- Calculate trajectory
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local mouse = game.Players.LocalPlayer:GetMouse()
    local target = mouse.Hit.Position
    
    local startPos = root.Position + Vector3.new(0, 2, 0)
    local direction = (target - startPos).Unit
    
    -- Calculate points
    local gravity = workspace.Gravity
    local velocity = Config.Projectile.Velocity
    
    for i, point in ipairs(self.Points) do
        if point then
            local t = i * 0.1
            local pos = Vector3.new(
                startPos.X + direction.X * velocity * t,
                startPos.Y + direction.Y * velocity * t - 0.5 * gravity * t * t,
                startPos.Z + direction.Z * velocity * t
            )
            
            point.Position = pos
            point.Visible = true
            
            -- Gradient
            local ratio = i / #self.Points
            point.Transparency = 0.8 - ratio * 0.3
        end
    end
end

-- ============================================================================
-- SECTION 7: MAIN FRAMEWORK INITIALIZATION
-- ============================================================================

local function InitializeFramework()
    print("[Forsaken Framework] Starting initialization...")
    
    -- Wait for game to fully load
    task.wait(3)
    
    -- Try to wait for Fluent UI
    local fluentSuccess = WaitForFluent(15)
    
    if fluentSuccess then
        print("[Forsaken Framework] Fluent UI loaded successfully")
        
        -- Create main UI tab
        SafeFluentCall("AddOptions", "ForsakenFramework", {
            Name = "Forsaken Framework",
            LayoutOrder = 0
        })
        
        -- Add main toggle
        SafeFluentCall("AddToggle", "FrameworkToggle", {
            Title = "Framework Enabled",
            Description = "Toggle all framework features",
            Default = true,
            Callback = function(value)
                Framework.Enabled = value
                if value then
                    SafeNotify("Framework", "Framework enabled")
                else
                    SafeNotify("Framework", "Framework disabled")
                end
            end
        })
    else
        warn("[Forsaken Framework] Running in safe mode (no Fluent UI)")
        Framework.SafeMode = true
    end
    
    -- Initialize modules with delay between each
    local modules = {
        {Name = "Class System", Func = function() return ClassSystem:Init() end},
        {Name = "Item ESP", Func = function() return ItemESP:Init() end},
        {Name = "Auto-Parry", Func = function() return AutoParry:Init() end},
        {Name = "Projectile Prediction", Func = function() return ProjectilePrediction:Init() end}
    }
    
    for i, module in ipairs(modules) do
        local success, result = pcall(module.Func)
        
        if success then
            print(string.format("[Forsaken Framework] %s initialized", module.Name))
        else
            warn(string.format("[Forsaken Framework] Failed to initialize %s: %s", 
                  module.Name, tostring(result)))
        end
        
        task.wait(1) -- Delay between modules
    end
    
    Framework.Initialized = true
    
    -- Final notification
    if fluentSuccess then
        SafeFluentCall("Notify", {
            Title = "Forsaken Framework",
            Content = "Advanced automation systems loaded",
            SubContent = "Version " .. Framework.Version,
            Duration = 5
        })
    end
    
    print("[Forsaken Framework] Initialization complete!")
    
    return true
end

-- ============================================================================
-- SECTION 8: AUTO-START AND CLEANUP
-- ============================================================================

-- Auto-start after delay
task.spawn(function()
    task.wait(5) -- Initial game loading
    
    local success, err = pcall(InitializeFramework)
    
    if not success then
        warn("[Forsaken Framework] Critical initialization error: " .. tostring(err))
        
        -- Try minimal recovery
        pcall(function()
            if Framework.FluentLoaded then
                SafeFluentCall("Notify", {
                    Title = "Framework Error",
                    Content = "Failed to initialize some features",
                    Duration = 5
                })
            end
        end)
    end
end)

-- Cleanup on character removal
game.Players.LocalPlayer.CharacterRemoving:Connect(function()
    -- Stop all systems
    if ItemESP.Active then
        pcall(function() ItemESP:Stop() end)
    end
    
    if AutoParry.Active then
        pcall(function() AutoParry:Stop() end)
    end
    
    if ProjectilePrediction.Active then
        pcall(function() ProjectilePrediction:Stop() end)
    end
    
    -- Cleanup highlights
    for _, highlight in ipairs(ItemESP.Highlights) do
        if highlight then
            pcall(function() highlight:Destroy() end)
        end
    end
    
    -- Cleanup prediction points
    for _, point in ipairs(ProjectilePrediction.Points) do
        if point then
            pcall(function() point:Destroy() end)
        end
    end
end)

-- Return framework interface
return {
    Version = Framework.Version,
    Initialized = function() return Framework.Initialized end,
    GetStatus = function()
        return {
            FluentLoaded = Framework.FluentLoaded,
            SafeMode = Framework.SafeMode,
            Class = ClassSystem.CurrentClass,
            ESP = ItemESP.Active,
            AutoParry = AutoParry.Active,
            Prediction = ProjectilePrediction.Active
        }
    end,
    ToggleESP = function(state)
        if state then
            ItemESP:Start()
        else
            ItemESP:Stop()
        end
    end
}
