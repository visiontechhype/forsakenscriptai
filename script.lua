--[[
    FORSAKEN ULTIMATE FRAMEWORK
    Module 9: Advanced Survivor Automation
    Version: 9.1.0 | Build: Forsaken_Ultimate_Framework
    Description: Complete rewrite with safety systems
]]--

-- ============================================================================
-- SECTION 1: SAFETY CORE SYSTEM
-- ============================================================================

local SafetyCore = {
    Enabled = true,
    DebugMode = false,
    ErrorLog = {},
    MaxErrors = 50
}

-- Safe function wrapper
function SafetyCore:Try(func, errorContext)
    if not self.Enabled then
        return func()
    end
    
    local success, result = pcall(func)
    
    if not success then
        self:LogError(result, errorContext)
        
        if self.DebugMode then
            warn(string.format("[SafetyCore] Error in %s: %s", errorContext or "unknown", result))
        end
    end
    
    return success, result
end

-- Safe property access
function SafetyCore:GetProperty(obj, property, defaultValue)
    if not obj then return defaultValue end
    
    local success, value = pcall(function()
        return obj[property]
    end)
    
    if success then
        return value
    end
    
    return defaultValue
end

-- Safe method call
function SafetyCore:CallMethod(obj, method, ...)
    if not obj then return nil end
    
    local success, result = pcall(function()
        if obj[method] then
            return obj[method](obj, ...)
        end
        return nil
    end)
    
    if not success and self.DebugMode then
        warn(string.format("[SafetyCore] Method %s failed: %s", method, result))
    end
    
    return success, result
end

-- Error logging
function SafetyCore:LogError(message, context)
    table.insert(self.ErrorLog, {
        Message = tostring(message),
        Context = context or "unknown",
        Time = os.time(),
        Stack = debug.traceback()
    })
    
    -- Keep log manageable
    if #self.ErrorLog > self.MaxErrors then
        table.remove(self.ErrorLog, 1)
    end
end

-- Get service safely
function SafetyCore:GetService(serviceName)
    return self:Try(function()
        return game:GetService(serviceName)
    end, "GetService:" .. serviceName)
end

-- ============================================================================
-- SECTION 2: DATABASE & CONFIGURATION
-- ============================================================================

local ForsakenDatabase = {
    Survivors = {
        ["Guest 1337"] = {
            Color = Color3.fromRGB(255, 255, 255),
            Abilities = {"Charge", "Block", "Punch"}
        },
        ["Elliot"] = {
            Color = Color3.fromRGB(255, 150, 0),
            Abilities = {"Pizza Throw", "Deliverer's Resolve"}
        }
    },
    Killers = {
        ["1x1x1x1"] = {
            Color = Color3.fromRGB(0, 255, 0),
            Abilities = {"Mass Infection", "Unstable Eye"}
        },
        ["John Doe"] = {
            Color = Color3.fromRGB(0, 255, 255),
            Abilities = {"404 Error", "Digital Footprint"}
        }
    },
    Items = {
        ["Medkit"] = Color3.fromRGB(0, 255, 0),
        ["BloxyCola"] = Color3.fromRGB(255, 0, 0),
        ["Fried Chicken"] = Color3.fromRGB(255, 200, 0)
    }
}

local Configuration = {
    ClassDetection = {
        Enabled = true,
        ScanInterval = 2,
        ConfidenceThreshold = 60
    },
    ESP = {
        Enabled = true,
        ScanRange = 150,
        ScanInterval = 1,
        MaxItems = 100
    },
    AutoParry = {
        Enabled = true,
        Cooldown = 0.5,
        ParryWindow = 0.3,
        DetectionRange = 30
    },
    ProjectilePrediction = {
        Enabled = true,
        UpdateInterval = 0.05,
        MaxPredictionTime = 5,
        PizzaVelocity = 50
    }
}

-- ============================================================================
-- SECTION 3: CLASS DETECTION SYSTEM
-- ============================================================================

local ClassDetector = {
    CurrentClass = nil,
    LastDetection = 0,
    DetectionCooldown = 2,
    ClassModules = {},
    Player = nil
}

function ClassDetector:Initialize()
    local success = SafetyCore:Try(function()
        self.Player = game.Players.LocalPlayer
        
        -- Connect character events
        if self.Player.Character then
            self:DetectCharacter(self.Player.Character)
        end
        
        self.Player.CharacterAdded:Connect(function(char)
            task.wait(1)
            self:DetectCharacter(char)
        end)
        
        -- Setup periodic detection
        game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
            self.LastDetection = self.LastDetection + deltaTime
            if self.LastDetection >= self.DetectionCooldown then
                self:PeriodicDetection()
                self.LastDetection = 0
            end
        end)
        
        -- Notify success
        self:Notify("Class Detector", "Character detection system initialized")
        
        return true
    end, "ClassDetector.Initialize")
    
    return success
end

function ClassDetector:DetectCharacter(character)
    SafetyCore:Try(function()
        -- Wait for humanoid
        local humanoid = character:WaitForChild("Humanoid", 5)
        if not humanoid then return end
        
        -- Get detection data
        local detectionData = self:CollectDetectionData(character, humanoid)
        
        -- Score characters
        local bestMatch = self:CalculateBestMatch(detectionData)
        
        -- Apply if confident
        if bestMatch.Score >= Configuration.ClassDetection.ConfidenceThreshold then
            self:SetCurrentClass(bestMatch.Name, bestMatch.Score)
        end
        
    end, "ClassDetector.DetectCharacter")
end

function ClassDetector:CollectDetectionData(character, humanoid)
    local data = {
        Tools = {},
        Animations = {},
        Description = {}
    }
    
    -- Check backpack tools
    local backpack = self.Player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(data.Tools, item.Name)
            end
        end
    end
    
    -- Check character tools
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(data.Tools, item.Name)
        end
    end
    
    -- Check animations
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            if track.Animation then
                table.insert(data.Animations, track.Animation.AnimationId)
            end
        end
    end
    
    -- Check humanoid description
    local desc = humanoid:GetAppliedDescription()
    data.Description = {
        BodyTypeScale = desc.BodyTypeScale,
        HeadScale = desc.HeadScale,
        HeightScale = desc.HeightScale
    }
    
    return data
end

function ClassDetector:CalculateBestMatch(data)
    local bestMatch = {Name = "Unknown", Score = 0}
    
    -- Define character signatures
    local signatures = {
        ["Guest 1337"] = {
            ToolPatterns = {"Fist", "Block", "Shield"},
            AnimationPatterns = {"punch", "block", "charge"},
            DescriptionMatch = {BodyTypeScale = 0.9, HeadScale = 1.1}
        },
        ["Elliot"] = {
            ToolPatterns = {"Pizza", "Box", "Delivery"},
            AnimationPatterns = {"throw", "pizza", "deliver"},
            DescriptionMatch = {BodyTypeScale = 1.0, HeadScale = 1.0}
        },
        ["1x1x1x1"] = {
            ToolPatterns = {"Infection", "Vial", "Eye", "Orb"},
            AnimationPatterns = {"infect", "beam", "unstable"},
            DescriptionMatch = {BodyTypeScale = 0.8, HeadScale = 1.2}
        },
        ["John Doe"] = {
            ToolPatterns = {"Error", "Glitch", "Digital", "Tracker"},
            AnimationPatterns = {"error", "glitch", "digital"},
            DescriptionMatch = {BodyTypeScale = 1.1, HeadScale = 0.9}
        }
    }
    
    -- Score each character
    for charName, signature in pairs(signatures) do
        local score = 0
        
        -- Tool matching (40 points)
        for _, tool in ipairs(data.Tools) do
            for _, pattern in ipairs(signature.ToolPatterns) do
                if string.find(tool:lower(), pattern:lower()) then
                    score = score + 10
                    break
                end
            end
        end
        
        -- Animation matching (30 points)
        for _, anim in ipairs(data.Animations) do
            for _, pattern in ipairs(signature.AnimationPatterns) do
                if string.find(anim:lower(), pattern:lower()) then
                    score = score + 10
                    break
                end
            end
        end
        
        -- Description matching (30 points)
        for feature, targetValue in pairs(signature.DescriptionMatch) do
            local actualValue = data.Description[feature]
            if actualValue then
                local diff = math.abs(actualValue - targetValue)
                if diff < 0.1 then
                    score = score + 10
                end
            end
        end
        
        -- Check for best match
        if score > bestMatch.Score then
            bestMatch.Name = charName
            bestMatch.Score = score
        end
    end
    
    return bestMatch
end

function ClassDetector:SetCurrentClass(className, confidence)
    if self.CurrentClass == className then return end
    
    self.CurrentClass = className
    
    -- Deactivate old modules
    for _, module in pairs(self.ClassModules) do
        if module.Deactivate then
            SafetyCore:Try(module.Deactivate, "ClassModule.Deactivate")
        end
    end
    
    -- Clear modules
    self.ClassModules = {}
    
    -- Activate new modules based on class
    if className == "Guest 1337" then
        self:ActivateGuest1337()
    elseif className == "Elliot" then
        self:ActivateElliot()
    elseif className == "1x1x1x1" then
        self:Activate1x1x1x1()
    elseif className == "John Doe" then
        self:ActivateJohnDoe()
    end
    
    -- Notify
    self:Notify("Class Detection", 
        string.format("Detected: %s (Confidence: %d%%)", className, confidence))
end

function ClassDetector:ActivateGuest1337()
    SafetyCore:Try(function()
        -- Auto-Parry module will be activated here
        local module = {
            Name = "AutoParry",
            Active = true
        }
        
        table.insert(self.ClassModules, module)
        
        -- Create UI options for Guest 1337
        self:CreateClassUI("Guest 1337", {
            {Type = "Toggle", Name = "AutoBlock", Title = "Auto-Block", Default = true},
            {Type = "Toggle", Name = "AutoCounter", Title = "Auto-Counter", Default = true},
            {Type = "Slider", Name = "ParryWindow", Title = "Parry Window", Min = 100, Max = 500, Default = 300}
        })
        
    end, "ClassDetector.ActivateGuest1337")
end

function ClassDetector:ActivateElliot()
    SafetyCore:Try(function()
        -- Projectile Prediction module
        local module = {
            Name = "ProjectilePrediction",
            Active = true
        }
        
        table.insert(self.ClassModules, module)
        
        -- Create UI options for Elliot
        self:CreateClassUI("Elliot", {
            {Type = "Toggle", Name = "PredictPizza", Title = "Pizza Prediction", Default = true},
            {Type = "Toggle", Name = "AutoResolve", Title = "Auto-Resolve", Default = true},
            {Type = "Slider", Name = "ResolveHP", Title = "Resolve HP %", Min = 10, Max = 50, Default = 25}
        })
        
    end, "ClassDetector.ActivateElliot")
end

function ClassDetector:Activate1x1x1x1()
    SafetyCore:Try(function()
        -- Infection cleanse module
        local module = {
            Name = "AutoCleanse",
            Active = true
        }
        
        table.insert(self.ClassModules, module)
        
        -- Create UI options
        self:CreateClassUI("1x1x1x1", {
            {Type = "Toggle", Name = "CleanseInfection", Title = "Auto-Cleanse", Default = true},
            {Type = "Toggle", Name = "DodgeBeam", Title = "Dodge Beam", Default = true},
            {Type = "Slider", Name = "DodgeSpeed", Title = "Dodge Speed", Min = 50, Max = 500, Default = 200}
        })
        
    end, "ClassDetector.Activate1x1x1x1")
end

function ClassDetector:ActivateJohnDoe()
    SafetyCore:Try(function()
        -- Glitch removal module
        local module = {
            Name = "GlitchRemoval",
            Active = true
        }
        
        table.insert(self.ClassModules, module)
        
        -- Create UI options
        self:CreateClassUI("John Doe", {
            {Type = "Toggle", Name = "RemoveGlitches", Title = "Remove Glitches", Default = true},
            {Type = "Toggle", Name = "EraseFootprints", Title = "Erase Footprints", Default = true},
            {Type = "Toggle", Name = "GlitchESP", Title = "Glitch ESP", Default = false}
        })
        
    end, "ClassDetector.ActivateJohnDoe")
end

function ClassDetector:CreateClassUI(className, options)
    SafetyCore:Try(function()
        -- Check if Fluent exists
        if not Fluent then return end
        
        -- Create tab
        Fluent:AddOptions(className, {
            Name = className,
            LayoutOrder = 1
        })
        
        -- Add options
        for _, option in ipairs(options) do
            if option.Type == "Toggle" then
                Fluent:AddToggle(option.Name, {
                    Title = option.Title,
                    Default = option.Default or false
                })
            elseif option.Type == "Slider" then
                Fluent:AddSlider(option.Name, {
                    Title = option.Title,
                    Default = option.Default or option.Min,
                    Min = option.Min,
                    Max = option.Max,
                    Rounding = 0
                })
            end
        end
        
    end, "ClassDetector.CreateClassUI")
end

function ClassDetector:PeriodicDetection()
    SafetyCore:Try(function()
        local character = self.Player.Character
        if character and not self.CurrentClass then
            self:DetectCharacter(character)
        end
    end, "ClassDetector.PeriodicDetection")
end

function ClassDetector:Notify(title, content)
    SafetyCore:Try(function()
        if Fluent and Fluent.Notify then
            Fluent:Notify({
                Title = title,
                Content = content,
                Duration = 3
            })
        end
    end, "ClassDetector.Notify")
end

-- ============================================================================
-- SECTION 4: ITEM ESP SYSTEM
-- ============================================================================

local ItemESP = {
    Active = false,
    Highlights = {},
    ItemCache = {},
    LastScan = 0
}

function ItemESP:Initialize()
    SafetyCore:Try(function()
        -- Create highlight pool
        self:CreateHighlightPool()
        
        -- Start scanning if enabled
        if Configuration.ESP.Enabled then
            self:Start()
        end
        
        -- Setup UI toggle if Fluent exists
        if Fluent then
            Fluent:AddToggle("ItemESPEnabled", {
                Title = "Item ESP",
                Description = "Highlight items in the world",
                Default = Configuration.ESP.Enabled,
                Callback = function(value)
                    Configuration.ESP.Enabled = value
                    if value then
                        self:Start()
                    else
                        self:Stop()
                    end
                end
            })
        end
        
        self:Notify("Item ESP", "System initialized")
        
    end, "ItemESP.Initialize")
end

function ItemESP:CreateHighlightPool()
    SafetyCore:Try(function()
        self.HighlightPool = {}
        
        for i = 1, Configuration.ESP.MaxItems do
            local highlight = Instance.new("Highlight")
            highlight.Name = "ESP_Highlight_" .. i
            highlight.FillTransparency = 0.7
            highlight.OutlineTransparency = 0.3
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Enabled = false
            highlight.Parent = workspace
            
            table.insert(self.HighlightPool, highlight)
        end
        
    end, "ItemESP.CreateHighlightPool")
end

function ItemESP:Start()
    SafetyCore:Try(function()
        self.Active = true
        
        -- Start update loop
        self.Connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
            self:Update(deltaTime)
        end)
        
    end, "ItemESP.Start")
end

function ItemESP:Stop()
    SafetyCore:Try(function()
        self.Active = false
        
        -- Disconnect loop
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        
        -- Hide all highlights
        for _, highlight in ipairs(self.HighlightPool) do
            highlight.Enabled = false
            highlight.Adornee = nil
        end
        
        -- Clear cache
        self.ItemCache = {}
        
    end, "ItemESP.Stop")
end

function ItemESP:Update(deltaTime)
    if not self.Active then return end
    
    SafetyCore:Try(function()
        self.LastScan = self.LastScan + deltaTime
        
        -- Scan at intervals
        if self.LastScan >= Configuration.ESP.ScanInterval then
            self:ScanForItems()
            self.LastScan = 0
        end
        
        -- Update existing highlights
        self:UpdateHighlights()
        
    end, "ItemESP.Update")
end

function ItemESP:ScanForItems()
    SafetyCore:Try(function()
        -- Clear old cache entries
        for item, data in pairs(self.ItemCache) do
            if not item:IsDescendantOf(workspace) then
                self.ItemCache[item] = nil
            end
        end
        
        -- Scan workspace
        self:ScanFolder(workspace)
        
        -- Scan specific spawn locations
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name:find("Spawn") or child.Name:find("Item") then
                self:ScanFolder(child)
            end
        end
        
    end, "ItemESP.ScanForItems")
end

function ItemESP:ScanFolder(folder)
    SafetyCore:Try(function()
        for _, item in ipairs(folder:GetDescendants()) do
            self:CheckItem(item)
        end
    end, "ItemESP.ScanFolder")
end

function ItemESP:CheckItem(item)
    SafetyCore:Try(function()
        -- Check if item is a collectible
        local itemType = self:IdentifyItemType(item)
        
        if itemType then
            -- Add to cache
            self.ItemCache[item] = {
                Type = itemType,
                LastSeen = tick(),
                Position = self:GetItemPosition(item)
            }
        end
        
    end, "ItemESP.CheckItem")
end

function ItemESP:IdentifyItemType(item)
    -- Check name patterns
    local name = item.Name:lower()
    local parentName = item.Parent and item.Parent.Name:lower() or ""
    
    if name:find("medkit") or parentName:find("medkit") then
        return "Medkit"
    elseif name:find("cola") or name:find("bloxy") then
        return "BloxyCola"
    elseif name:find("chicken") or name:find("fried") then
        return "Fried Chicken"
    end
    
    return nil
end

function ItemESP:GetItemPosition(item)
    if item:IsA("BasePart") then
        return item.Position
    elseif item:IsA("Model") then
        local primary = item.PrimaryPart
        if primary then
            return primary.Position
        end
    end
    
    return item:GetPivot().Position
end

function ItemESP:UpdateHighlights()
    SafetyCore:Try(function()
        local player = game.Players.LocalPlayer
        local character = player.Character
        local playerPos = character and character:GetPivot().Position or Vector3.zero
        
        -- Reset highlight pool
        for _, highlight in ipairs(self.HighlightPool) do
            highlight.Enabled = false
        end
        
        local highlightIndex = 1
        
        -- Assign highlights to visible items
        for item, data in pairs(self.ItemCache) do
            if item:IsDescendantOf(workspace) then
                -- Check distance
                local distance = (data.Position - playerPos).Magnitude
                
                if distance <= Configuration.ESP.ScanRange then
                    -- Get highlight from pool
                    local highlight = self.HighlightPool[highlightIndex]
                    if highlight then
                        -- Configure highlight
                        highlight.Adornee = item
                        highlight.Enabled = true
                        
                        -- Set color based on item type
                        local color = ForsakenDatabase.Items[data.Type] or Color3.new(1, 1, 1)
                        highlight.FillColor = color
                        highlight.OutlineColor = Color3.new(
                            color.R * 0.5,
                            color.G * 0.5,
                            color.B * 0.5
                        )
                        
                        -- Adjust transparency based on distance
                        local alpha = 1 - (distance / Configuration.ESP.ScanRange)
                        highlight.FillTransparency = 0.7 - (alpha * 0.4)
                        highlight.OutlineTransparency = 0.3 - (alpha * 0.2)
                        
                        highlightIndex = highlightIndex + 1
                        
                        -- Stop if pool is full
                        if highlightIndex > #self.HighlightPool then
                            break
                        end
                    end
                end
            else
                -- Item removed from workspace
                self.ItemCache[item] = nil
            end
        end
        
    end, "ItemESP.UpdateHighlights")
end

function ItemESP:Notify(title, content)
    SafetyCore:Try(function()
        if Fluent and Fluent.Notify then
            Fluent:Notify({
                Title = title,
                Content = content,
                Duration = 2
            })
        end
    end, "ItemESP.Notify")
end

-- ============================================================================
-- SECTION 5: AUTO-PARRY SYSTEM (Guest 1337)
-- ============================================================================

local AutoParry = {
    Active = false,
    LastParry = 0,
    ParryCooldown = 0.5
}

function AutoParry:Initialize()
    SafetyCore:Try(function()
        -- Setup UI if Fluent exists
        if Fluent then
            Fluent:AddToggle("AutoParryEnabled", {
                Title = "Auto-Parry",
                Description = "Automatically parry incoming attacks",
                Default = Configuration.AutoParry.Enabled,
                Callback = function(value)
                    Configuration.AutoParry.Enabled = value
                    if value then
                        self:Start()
                    else
                        self:Stop()
                    end
                end
            })
        end
        
        self:Notify("Auto-Parry", "System ready")
        
    end, "AutoParry.Initialize")
end

function AutoParry:Start()
    SafetyCore:Try(function()
        self.Active = true
        
        -- Start detection loop
        self.Connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
            self:Update(deltaTime)
        end)
        
    end, "AutoParry.Start")
end

function AutoParry:Stop()
    SafetyCore:Try(function()
        self.Active = false
        
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        
    end, "AutoParry.Stop")
end

function AutoParry:Update(deltaTime)
    if not self.Active then return end
    
    SafetyCore:Try(function()
        -- Update cooldown
        self.LastParry = math.max(0, self.LastParry - deltaTime)
        
        -- Check for attacks if not on cooldown
        if self.LastParry <= 0 then
            local attackDetected = self:DetectAttack()
            
            if attackDetected then
                self:ExecuteParry()
                self.LastParry = self.ParryCooldown
            end
        end
        
    end, "AutoParry.Update")
end

function AutoParry:DetectAttack()
    local character = game.Players.LocalPlayer.Character
    if not character then return false end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    -- Check nearby players
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            local targetChar = player.Character
            if targetChar then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    -- Check distance
                    local distance = (targetRoot.Position - root.Position).Magnitude
                    
                    if distance <= Configuration.AutoParry.DetectionRange then
                        -- Check for attack animations
                        local isAttacking = self:CheckForAttack(targetChar)
                        
                        if isAttacking then
                            return true
                        end
                    end
                end
            end
        end
    end
    
    return false
end

function AutoParry:CheckForAttack(character)
    -- Check animations
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation then
                    local animId = track.Animation.AnimationId:lower()
                    
                    -- Attack animation patterns
                    if animId:find("attack") or 
                       animId:find("punch") or 
                       animId:find("slash") or
                       animId:find("hit") then
                        return true
                    end
                end
            end
        end
    end
    
    -- Check for weapon effects
    for _, child in ipairs(character:GetDescendants()) do
        if child:IsA("ParticleEmitter") and child.Enabled then
            if child.Name:find("Attack") or 
               child.Name:find("Swing") or
               child.Name:find("Hit") then
                return true
            end
        end
    end
    
    return false
end

function AutoParry:ExecuteParry()
    SafetyCore:Try(function()
        local character = game.Players.LocalPlayer.Character
        if not character then return end
        
        -- Play block animation
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            -- Load animation
            local animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://94701048" -- Generic block animation
            
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local track = animator:LoadAnimation(animation)
                track:Play()
                
                -- Create visual effect
                self:CreateParryEffect(character)
                
                -- Stop animation after duration
                task.wait(0.5)
                track:Stop()
            end
        end
        
        -- Counter attack
        task.wait(0.1)
        self:ExecuteCounter()
        
    end, "AutoParry.ExecuteParry")
end

function AutoParry:CreateParryEffect(character)
    SafetyCore:Try(function()
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        -- Create shield effect
        local shield = Instance.new("Part")
        shield.Size = Vector3.new(5, 7, 0.2)
        shield.Material = Enum.Material.Neon
        shield.Color = Color3.fromRGB(0, 150, 255)
        shield.Transparency = 0.5
        shield.Anchored = true
        shield.CanCollide = false
        shield.CFrame = root.CFrame * CFrame.new(0, 0, -2)
        shield.Parent = workspace
        
        -- Animate
        local tweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        local goal = {
            Transparency = 1,
            Size = Vector3.new(8, 10, 0.2)
        }
        
        local tween = tweenService:Create(shield, tweenInfo, goal)
        tween:Play()
        
        tween.Completed:Connect(function()
            shield:Destroy()
        end)
        
    end, "AutoParry.CreateParryEffect")
end

function AutoParry:ExecuteCounter()
    SafetyCore:Try(function()
        local character = game.Players.LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            -- Load punch animation
            local animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://94701047" -- Generic punch animation
            
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local track = animator:LoadAnimation(animation)
                track:Play()
                
                -- Create punch effect
                self:CreatePunchEffect(character)
                
                task.wait(0.3)
                track:Stop()
            end
        end
        
    end, "AutoParry.ExecuteCounter")
end

function AutoParry:CreatePunchEffect(character)
    SafetyCore:Try(function()
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        -- Create punch shockwave
        local shockwave = Instance.new("Part")
        shockwave.Shape = Enum.PartType.Ball
        shockwave.Size = Vector3.new(1, 1, 1)
        shockwave.Material = Enum.Material.Neon
        shockwave.Color = Color3.fromRGB(255, 100, 0)
        shockwave.Transparency = 0.5
        shockwave.Anchored = true
        shockwave.CanCollide = false
        shockwave.CFrame = root.CFrame * CFrame.new(0, 0, -3)
        shockwave.Parent = workspace
        
        -- Animate expansion
        local tweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        local goal = {
            Transparency = 1,
            Size = Vector3.new(8, 8, 8)
        }
        
        local tween = tweenService:Create(shockwave, tweenInfo, goal)
        tween:Play()
        
        tween.Completed:Connect(function()
            shockwave:Destroy()
        end)
        
    end, "AutoParry.CreatePunchEffect")
end

function AutoParry:Notify(title, content)
    SafetyCore:Try(function()
        if Fluent and Fluent.Notify then
            Fluent:Notify({
                Title = title,
                Content = content,
                Duration = 2
            })
        end
    end, "AutoParry.Notify")
end

-- ============================================================================
-- SECTION 6: PROJECTILE PREDICTION (Elliot)
-- ============================================================================

local ProjectilePrediction = {
    Active = false,
    PredictionPoints = {},
    LastUpdate = 0
}

function ProjectilePrediction:Initialize()
    SafetyCore:Try(function()
        -- Create prediction visuals
        self:CreatePredictionVisuals()
        
        -- Setup UI if Fluent exists
        if Fluent then
            Fluent:AddToggle("ProjectilePredictionEnabled", {
                Title = "Projectile Prediction",
                Description = "Predict pizza throw trajectory",
                Default = Configuration.ProjectilePrediction.Enabled,
                Callback = function(value)
                    Configuration.ProjectilePrediction.Enabled = value
                    if value then
                        self:Start()
                    else
                        self:Stop()
                    end
                end
            })
        end
        
        self:Notify("Projectile Prediction", "System ready")
        
    end, "ProjectilePrediction.Initialize")
end

function ProjectilePrediction:CreatePredictionVisuals()
    SafetyCore:Try(function()
        self.PredictionPoints = {}
        
        for i = 1, 30 do
            local part = Instance.new("Part")
            part.Size = Vector3.new(0.3, 0.3, 0.3)
            part.Material = Enum.Material.Neon
            part.Color = Color3.fromRGB(255, 150, 0) -- Elliot orange
            part.Anchored = true
            part.CanCollide = false
            part.Transparency = 0.8
            part.Visible = false
            part.Parent = workspace
            
            table.insert(self.PredictionPoints, part)
        end
        
    end, "ProjectilePrediction.CreatePredictionVisuals")
end

function ProjectilePrediction:Start()
    SafetyCore:Try(function()
        self.Active = true
        
        -- Start update loop
        self.Connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
            self:Update(deltaTime)
        end)
        
    end, "ProjectilePrediction.Start")
end

function ProjectilePrediction:Stop()
    SafetyCore:Try(function()
        self.Active = false
        
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        
        -- Hide points
        for _, point in ipairs(self.PredictionPoints) do
            point.Visible = false
        end
        
    end, "ProjectilePrediction.Stop")
end

function ProjectilePrediction:Update(deltaTime)
    if not self.Active then return end
    
    SafetyCore:Try(function()
        self.LastUpdate = self.LastUpdate + deltaTime
        
        if self.LastUpdate >= Configuration.ProjectilePrediction.UpdateInterval then
            self:UpdatePrediction()
            self.LastUpdate = 0
        end
        
    end, "ProjectilePrediction.Update")
end

function ProjectilePrediction:UpdatePrediction()
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Check if holding pizza
    local holdingPizza = false
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:find("Pizza") then
            holdingPizza = true
            break
        end
    end
    
    if not holdingPizza then
        -- Hide points if not holding pizza
        for _, point in ipairs(self.PredictionPoints) do
            point.Visible = false
        end
        return
    end
    
    -- Calculate trajectory
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local mouse = game.Players.LocalPlayer:GetMouse()
    local target = mouse.Hit.Position
    
    -- Start position (shoulder height)
    local startPos = root.Position + Vector3.new(0, 2, 0)
    local direction = (target - startPos).Unit
    
    -- Calculate points
    local points = self:CalculateTrajectory(startPos, direction)
    
    -- Update visualization
    self:VisualizeTrajectory(points)
end

function ProjectilePrediction:CalculateTrajectory(startPos, direction)
    local points = {}
    local gravity = workspace.Gravity
    local velocity = Configuration.ProjectilePrediction.PizzaVelocity
    
    local timeStep = 0.1
    local currentTime = 0
    
    for i = 1, #self.PredictionPoints do
        local t = currentTime
        
        -- Calculate position
        local x = startPos.X + direction.X * velocity * t
        local y = startPos.Y + direction.Y * velocity * t - 0.5 * gravity * t * t
        local z = startPos.Z + direction.Z * velocity * t
        
        local point = Vector3.new(x, y, z)
        table.insert(points, point)
        
        -- Check for collision
        local rayOrigin = i == 1 and startPos or points[i-1]
        local rayDirection = point - rayOrigin
        
        local raycastResult = workspace:Raycast(
            rayOrigin,
            rayDirection,
            {game.Players.LocalPlayer.Character}
        )
        
        if raycastResult then
            -- Add collision point
            table.insert(points, raycastResult.Position)
            break
        end
        
        currentTime = currentTime + timeStep
        
        -- Stop if going too far
        if t > Configuration.ProjectilePrediction.MaxPredictionTime then
            break
        end
    end
    
    return points
end

function ProjectilePrediction:VisualizeTrajectory(points)
    -- Hide all points first
    for _, point in ipairs(self.PredictionPoints) do
        point.Visible = false
    end
    
    -- Show points for trajectory
    for i, position in ipairs(points) do
        if i <= #self.PredictionPoints then
            local point = self.PredictionPoints[i]
            point.Position = position
            point.Visible = true
            
            -- Gradient color and transparency
            local ratio = i / #points
            point.Transparency = 0.8 - (ratio * 0.5)
            
            -- Color gradient (orange to red)
            point.Color = Color3.new(
                1, -- R stays high
                0.6 - (ratio * 0.5), -- G decreases
                0.1 + (ratio * 0.1) -- B slightly increases
            )
        end
    end
end

function ProjectilePrediction:Notify(title, content)
    SafetyCore:Try(function()
        if Fluent and Fluent.Notify then
            Fluent:Notify({
                Title = title,
                Content = content,
                Duration = 2
            })
        end
    end, "ProjectilePrediction.Notify")
end

-- ============================================================================
-- SECTION 7: MAIN INITIALIZATION
-- ============================================================================

local ForsakenFramework = {
    Initialized = false,
    Modules = {}
}

function ForsakenFramework:Initialize()
    if self.Initialized then return end
    
    print("[Forsaken Framework] Starting initialization...")
    
    -- Wait for game to load
    task.wait(2)
    
    -- Initialize Safety Core
    SafetyCore:Try(function()
        SafetyCore.Enabled = true
        SafetyCore.DebugMode = false
    end, "SafetyCore.Initialize")
    
    -- Wait for Fluent UI
    local fluentLoaded = false
    for i = 1, 10 do
        if Fluent then
            fluentLoaded = true
            break
        end
        task.wait(1)
    end
    
    if not fluentLoaded then
        warn("[Forsaken Framework] Fluent UI not found, continuing without UI...")
    end
    
    -- Initialize modules
    local modules = {
        {Name = "ClassDetector", Module = ClassDetector},
        {Name = "ItemESP", Module = ItemESP},
        {Name = "AutoParry", Module = AutoParry},
        {Name = "ProjectilePrediction", Module = ProjectilePrediction}
    }
    
    for _, moduleData in ipairs(modules) do
        local success = SafetyCore:Try(function()
            if moduleData.Module.Initialize then
                moduleData.Module:Initialize()
            end
            return true
        end, moduleData.Name .. ".Initialize")
        
        if success then
            self.Modules[moduleData.Name] = moduleData.Module
            print(string.format("[Forsaken Framework] %s initialized", moduleData.Name))
        else
            warn(string.format("[Forsaken Framework] Failed to initialize %s", moduleData.Name))
        end
        
        task.wait(0.5) -- Stagger initialization
    end
    
    -- Final setup
    SafetyCore:Try(function()
        -- Create main UI tab if Fluent exists
        if Fluent then
            Fluent:AddOptions("ForsakenFramework", {
                Name = "Forsaken Framework",
                LayoutOrder = 0
            })
            
            -- Add status toggle
            Fluent:AddToggle("FrameworkEnabled", {
                Title = "Framework Enabled",
                Description = "Toggle all framework features",
                Default = true,
                Callback = function(value)
                    self:SetEnabled(value)
                end
            })
        end
        
        self.Initialized = true
        
        -- Success notification
        SafetyCore:Try(function()
            if Fluent and Fluent.Notify then
                Fluent:Notify({
                    Title = "Forsaken Framework",
                    Content = "Advanced Survivor Automation loaded",
                    SubContent = "All systems operational",
                    Duration = 5
                })
            end
        end, "SuccessNotification")
        
        print("[Forsaken Framework] Initialization complete")
        
    end, "ForsakenFramework.FinalSetup")
    
    return self.Initialized
end

function ForsakenFramework:SetEnabled(enabled)
    SafetyCore:Try(function()
        -- Enable/disable all modules
        if ClassDetector then
            if enabled then
                ClassDetector:Initialize()
            end
        end
        
        if ItemESP then
            if enabled and Configuration.ESP.Enabled then
                ItemESP:Start()
            else
                ItemESP:Stop()
            end
        end
        
        if AutoParry then
            if enabled and Configuration.AutoParry.Enabled then
                AutoParry:Start()
            else
                AutoParry:Stop()
            end
        end
        
        if ProjectilePrediction then
            if enabled and Configuration.ProjectilePrediction.Enabled then
                ProjectilePrediction:Start()
            else
                ProjectilePrediction:Stop()
            end
        end
        
    end, "ForsakenFramework.SetEnabled")
end

function ForsakenFramework:GetStatus()
    return {
        Initialized = self.Initialized,
        SafetyCore = {
            Enabled = SafetyCore.Enabled,
            ErrorCount = #SafetyCore.ErrorLog
        },
        Modules = {
            ClassDetector = ClassDetector.CurrentClass or "Not detected",
            ItemESP = ItemESP.Active,
            AutoParry = AutoParry.Active,
            ProjectilePrediction = ProjectilePrediction.Active
        },
        Configuration = Configuration
    }
end

-- ============================================================================
-- SECTION 8: AUTO-START AND CLEANUP
-- ============================================================================

-- Auto-start the framework
task.spawn(function()
    task.wait(5) -- Wait for game to fully load
    
    local success = ForsakenFramework:Initialize()
    
    if success then
        -- Periodic status check
        game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
            -- Every 60 seconds, check system health
            if tick() % 60 < deltaTime then
                local status = ForsakenFramework:GetStatus()
                
                -- Log status
                print(string.format(
                    "[Forsaken Framework] Status: Class=%s, ESP=%s, Parry=%s, Prediction=%s",
                    status.Modules.ClassDetector,
                    status.Modules.ItemESP and "On" or "Off",
                    status.Modules.AutoParry and "On" or "Off",
                    status.Modules.ProjectilePrediction and "On" or "Off"
                ))
                
                -- Check for errors
                if status.SafetyCore.ErrorCount > 10 then
                    warn(string.format(
                        "[Forsaken Framework] High error count: %d",
                        status.SafetyCore.ErrorCount
                    ))
                end
            end
        end)
    else
        warn("[Forsaken Framework] Failed to initialize framework")
    end
end)

-- Cleanup on leave
game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
    SafetyCore:Try(function()
        -- Stop all active systems
        if ItemESP.Active then ItemESP:Stop() end
        if AutoParry.Active then AutoParry:Stop() end
        if ProjectilePrediction.Active then ProjectilePrediction:Stop() end
        
        -- Cleanup visuals
        for _, point in ipairs(ProjectilePrediction.PredictionPoints or {}) do
            point:Destroy()
        end
        
        for _, highlight in ipairs(ItemESP.HighlightPool or {}) do
            highlight:Destroy()
        end
        
    end, "Cleanup")
end)

-- Return framework for external use
return ForsakenFramework
