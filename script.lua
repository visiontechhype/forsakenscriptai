--[[
    MODULE 9: ADVANCED SURVIVOR AUTOMATION
    Version: 9.0.1 | Build: Forsaken_Ultimate_Framework
    Description: Class-based automation system with projectile prediction, auto-parry, and ESP enhancements.
]]--

-- ============================================================================
-- SECTION 1: CLASS DETECTION SYSTEM
-- ============================================================================

local ClassDetector = {
    _activeCharacter = nil,
    _characterCache = {},
    _lastDetectionTime = 0,
    _detectionCooldown = 2,
    _classSpecificModules = {}
}

-- Character ability signatures for precise detection
ClassDetector.CharacterSignatures = {
    ["Guest 1337"] = {
        Animations = {"rbxassetid://4856789123", "rbxassetid://4856789456"},
        ToolNames = {"GuestFists", "BlockShield"},
        HumanoidDescription = {BodyTypeScale = 0.9, HeadScale = 1.1}
    },
    ["Elliot"] = {
        Animations = {"rbxassetid://4856790123", "rbxassetid://4856790456"},
        ToolNames = {"PizzaBox", "DeliveryBag"},
        HumanoidDescription = {BodyTypeScale = 1.0, HeadScale = 1.0}
    },
    ["1x1x1x1"] = {
        Animations = {"rbxassetid://4856791123", "rbxassetid://4856791456"},
        ToolNames = {"InfectionVial", "UnstableOrb"},
        HumanoidDescription = {BodyTypeScale = 0.8, HeadScale = 1.2}
    },
    ["John Doe"] = {
        Animations = {"rbxassetid://4856792123", "rbxassetid://4856792456"},
        ToolNames = {"ErrorGlitch", "DigitalTracker"},
        HumanoidDescription = {BodyTypeScale = 1.1, HeadScale = 0.9}
    }
}

function ClassDetector:Initialize()
    -- Connect to character added event
    if game.Players.LocalPlayer.Character then
        self:_detectCharacter(game.Players.LocalPlayer.Character)
    end
    
    game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1) -- Wait for character to fully load
        self:_detectCharacter(char)
    end)
    
    -- Periodic re-detection for safety
    game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        self._lastDetectionTime += deltaTime
        if self._lastDetectionTime >= self._detectionCooldown then
            self:_periodicDetection()
            self._lastDetectionTime = 0
        end
    end)
    
    Fluent:Notify({
        Title = "Class Detector",
        Content = "Character detection system initialized",
        SubContent = "Monitoring class-specific abilities...",
        Duration = 3
    })
end

function ClassDetector:_detectCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 3)
    if not humanoid then return end
    
    -- Method 1: Check equipped tools
    local backpack = game.Players.LocalPlayer:FindFirstChild("Backpack")
    local tools = {}
    
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(tools, tool.Name)
            end
        end
    end
    
    -- Method 2: Check animations
    local animator = humanoid:FindFirstChildOfClass("Animator")
    local animations = {}
    
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            if track.Animation then
                table.insert(animations, track.Animation.AnimationId)
            end
        end
    end
    
    -- Method 3: Check humanoid description
    local humanoidDesc = humanoid:GetAppliedDescription()
    local descriptionFeatures = {
        BodyTypeScale = humanoidDesc.BodyTypeScale,
        HeadScale = humanoidDesc.HeadScale
    }
    
    -- Score-based detection
    local characterScores = {}
    local maxScore = 0
    local detectedCharacter = nil
    
    for charName, signature in pairs(self.CharacterSignatures) do
        local score = 0
        
        -- Tool matching (30% weight)
        for _, toolName in ipairs(signature.ToolNames) do
            if table.find(tools, toolName) then
                score += 30
                break
            end
        end
        
        -- Animation matching (40% weight)
        for _, animId in ipairs(signature.Animations) do
            for _, playingAnim in ipairs(animations) do
                if string.find(playingAnim, animId) then
                    score += 40
                    break
                end
            end
        end
        
        -- Description matching (30% weight)
        for feature, value in pairs(signature.HumanoidDescription) do
            if math.abs(descriptionFeatures[feature] - value) < 0.05 then
                score += 15
            end
        end
        
        characterScores[charName] = score
        
        if score > maxScore then
            maxScore = score
            detectedCharacter = charName
        end
    end
    
    -- Confidence check (minimum 60% confidence)
    if maxScore >= 60 and detectedCharacter then
        self._activeCharacter = detectedCharacter
        self._characterCache[character] = detectedCharacter
        
        -- Activate class-specific modules
        self:_activateClassModules(detectedCharacter)
        
        -- Log detection
        print(string.format("[ClassDetector] Detected: %s (Confidence: %d%%)", 
              detectedCharacter, math.min(maxScore, 100)))
        
        Fluent:Notify({
            Title = "Class Detection",
            Content = "Character identified: " .. detectedCharacter,
            Duration = 3
        })
    else
        -- Fallback: Check display name
        local displayName = game.Players.LocalPlayer.DisplayName
        for charName in pairs(ForsakenDatabase.Survivors) do
            if string.find(displayName, charName) then
                self._activeCharacter = charName
                self:_activateClassModules(charName)
                break
            end
        end
    end
end

function ClassDetector:_activateClassModules(characterName)
    -- Clear previous modules
    for _, module in pairs(self._classSpecificModules) do
        if module.Deactivate then
            pcall(module.Deactivate)
        end
    end
    table.clear(self._classSpecificModules)
    
    -- Activate based on character
    if characterName == "Guest 1337" then
        local autoParryModule = self:_initializeGuest1337Modules()
        table.insert(self._classSpecificModules, autoParryModule)
        
    elseif characterName == "Elliot" then
        local projectileModule = self:_initializeElliotModules()
        table.insert(self._classSpecificModules, projectileModule)
        
    elseif characterName == "1x1x1x1" then
        local cleanseModule = self:_initialize1x1x1x1Modules()
        table.insert(self._classSpecificModules, cleanseModule)
        
    elseif characterName == "John Doe" then
        local glitchModule = self:_initializeJohnDoeModules()
        table.insert(self._classSpecificModules, glitchModule)
    end
    
    -- Update UI
    if Fluent and Fluent.options then
        local classTab = Fluent.options.Tabs["Class Features"]
        if classTab then
            classTab:SetTitle(string.format("Class: %s", characterName))
        end
    end
end

function ClassDetector:_periodicDetection()
    local character = game.Players.LocalPlayer.Character
    if character and not self._characterCache[character] then
        self:_detectCharacter(character)
    end
end

function ClassDetector:GetCurrentClass()
    return self._activeCharacter or "Unknown"
end

function ClassDetector:IsClass(className)
    return self._activeCharacter == className
end

-- ============================================================================
-- SECTION 2: PROJECTILE PREDICTION SYSTEM (Elliot)
-- ============================================================================

local ProjectilePrediction = {
    _active = false,
    _trajectoryPoints = {},
    _predictionLine = nil,
    _lastPredictionTime = 0,
    _predictionInterval = 0.05,
    _gravity = workspace.Gravity,
    _pizzaVelocity = 50,
    _maxPredictionTime = 5
}

function ProjectilePrediction:Initialize()
    -- Create prediction visualization
    self:_createPredictionLine()
    
    -- Setup prediction toggle
    Fluent.options.Toggles["AutoPredictPizza"]:OnChanged(function(value)
        self._active = value
        if value then
            self:StartPrediction()
        else
            self:StopPrediction()
        end
    end)
    
    -- Bind to pizza throw event
    self:_bindToPizzaThrow()
end

function ProjectilePrediction:_createPredictionLine()
    local parts = {}
    
    for i = 1, 50 do
        local part = Instance.new("Part")
        part.Size = Vector3.new(0.2, 0.2, 0.2)
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(255, 150, 0) -- Elliot's color
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 0.7
        part.Parent = workspace.Terrain
        part.Name = "PredictionPoint_" .. i
        
        table.insert(parts, part)
    end
    
    self._trajectoryPoints = parts
    self:_hidePredictionPoints()
end

function ProjectilePrediction:_bindToPizzaThrow()
    -- Monitor for pizza tool equipped
    local function monitorTools()
        local backpack = game.Players.LocalPlayer:FindFirstChild("Backpack")
        if not backpack then return end
        
        backpack.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and string.find(child.Name:lower(), "pizza") then
                self:_setupPizzaTool(child)
            end
        end)
        
        -- Check existing tools
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and string.find(tool.Name:lower(), "pizza") then
                self:_setupPizzaTool(tool)
            end
        end
    end
    
    spawn(monitorTools)
end

function ProjectilePrediction:_setupPizzaTool(tool)
    -- Connect to tool activation
    tool.Activated:Connect(function()
        if self._active then
            self:_predictTrajectory(tool)
        end
    end)
    
    -- Monitor for throw animations
    local humanoid = game.Players.LocalPlayer.Character:WaitForChild("Humanoid")
    local animator = humanoid:FindFirstChildOfClass("Animator")
    
    if animator then
        animator.AnimationPlayed:Connect(function(animationTrack)
            if animationTrack.Animation then
                local animId = animationTrack.Animation.AnimationId:lower()
                if string.find(animId, "throw") or string.find(animId, "pizza") then
                    if self._active then
                        self:_predictTrajectory(tool)
                    end
                end
            end
        end)
    end
end

function ProjectilePrediction:_predictTrajectory(tool)
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Get throw parameters
    local mouse = game.Players.LocalPlayer:GetMouse()
    local targetPosition = mouse.Hit.Position
    local startPosition = rootPart.Position + Vector3.new(0, 2, 0) -- Shoulder height
    
    -- Calculate direction and velocity
    local direction = (targetPosition - startPosition).Unit
    local distance = (targetPosition - startPosition).Magnitude
    local velocity = math.min(distance * 0.5, self._pizzaVelocity)
    
    -- Projectile motion calculations
    local timeStep = 0.1
    local currentTime = 0
    local points = {}
    
    while currentTime < self._maxPredictionTime do
        local t = currentTime
        local x = startPosition.X + direction.X * velocity * t
        local y = startPosition.Y + direction.Y * velocity * t - 0.5 * self._gravity * t * t
        local z = startPosition.Z + direction.Z * velocity * t
        
        local point = Vector3.new(x, y, z)
        table.insert(points, point)
        
        -- Check for collision
        local ray = Ray.new(
            currentTime == 0 and startPosition or points[#points - 1] or startPosition,
            point - (points[#points - 1] or startPosition)
        )
        
        local hit, position = workspace:FindPartOnRayWithIgnoreList(
            ray,
            {character, tool}
        )
        
        if hit then
            -- Add collision point
            table.insert(points, position)
            break
        end
        
        currentTime += timeStep
        
        -- Stop if going too far down
        if y < workspace.Terrain:FindFirstChildWhichIsA("BasePart").Position.Y - 50 then
            break
        end
    end
    
    -- Visualize trajectory
    self:_updatePredictionPoints(points)
    
    -- Calculate landing prediction
    if #points >= 2 then
        local landingPoint = points[#points]
        local travelTime = #points * timeStep
        
        -- Find nearest enemy to landing point
        local nearestEnemy = self:_findNearestEnemy(landingPoint)
        
        if nearestEnemy then
            local enemyPos = nearestEnemy:GetPivot().Position
            local distanceToLanding = (enemyPos - landingPoint).Magnitude
            
            -- Show prediction info
            self:_showPredictionInfo(landingPoint, travelTime, distanceToLanding, nearestEnemy)
        end
    end
end

function ProjectilePrediction:_findNearestEnemy(position)
    local nearest = nil
    local minDistance = math.huge
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local distance = (rootPart.Position - position).Magnitude
                    if distance < minDistance then
                        minDistance = distance
                        nearest = player.Character
                    end
                end
            end
        end
    end
    
    return nearest
end

function ProjectilePrediction:_updatePredictionPoints(points)
    -- Clear previous points
    self:_hidePredictionPoints()
    
    -- Update visible points
    for i, point in ipairs(points) do
        if i <= #self._trajectoryPoints then
            local part = self._trajectoryPoints[i]
            part.Position = point
            
            -- Gradient transparency
            local transparency = 0.3 + (i / #points) * 0.7
            part.Transparency = transparency
            
            -- Gradient color (orange to red)
            local colorRatio = i / #points
            part.Color = Color3.new(
                1, -- R starts at 1
                0.6 - colorRatio * 0.6, -- G decreases
                0.1 + colorRatio * 0.1 -- B slightly increases
            )
            
            part.Visible = true
        end
    end
end

function ProjectilePrediction:_showPredictionInfo(landingPoint, travelTime, distanceToEnemy, enemy)
    -- Create prediction billboard
    if not self._predictionBillboard then
        self._predictionBillboard = Instance.new("BillboardGui")
        self._predictionBillboard.Size = UDim2.new(0, 200, 0, 100)
        self._predictionBillboard.StudsOffset = Vector3.new(0, 3, 0)
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        frame.Parent = self._predictionBillboard
        
        self._predictionLabel = Instance.new("TextLabel")
        self._predictionLabel.Size = UDim2.new(1, -10, 1, -10)
        self._predictionLabel.Position = UDim2.new(0, 5, 0, 5)
        self._predictionLabel.BackgroundTransparency = 1
        self._predictionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        self._predictionLabel.TextSize = 14
        self._predictionLabel.Font = Enum.Font.Code
        self._predictionLabel.TextXAlignment = Enum.TextXAlignment.Left
        self._predictionLabel.Parent = frame
    end
    
    -- Update prediction info
    local enemyName = enemy and enemy.Name or "Unknown"
    local infoText = string.format(
        "Pizza Throw Prediction:\n" ..
        "Landing Time: %.2fs\n" ..
        "Enemy Distance: %.2f studs\n" ..
        "Target: %s\n" ..
        "Confidence: %s",
        travelTime,
        distanceToEnemy,
        enemyName,
        distanceToEnemy < 10 and "HIGH" or distanceToEnemy < 20 and "MEDIUM" or "LOW"
    )
    
    self._predictionLabel.Text = infoText
    self._predictionBillboard.Adornee = Instance.new("Part")
    self._predictionBillboard.Adornee.Position = landingPoint
    self._predictionBillboard.Parent = game.CoreGui
end

function ProjectilePrediction:_hidePredictionPoints()
    for _, part in ipairs(self._trajectoryPoints) do
        part.Visible = false
    end
end

function ProjectilePrediction:StartPrediction()
    self._active = true
    Fluent:Notify({
        Title = "Projectile Prediction",
        Content = "Pizza trajectory prediction activated",
        Duration = 2
    })
end

function ProjectilePrediction:StopPrediction()
    self._active = false
    self:_hidePredictionPoints()
    
    if self._predictionBillboard then
        self._predictionBillboard:Destroy()
        self._predictionBillboard = nil
    end
end

-- ============================================================================
-- SECTION 3: AUTO-PARRY SYSTEM (Guest 1337)
-- ============================================================================

local AutoParrySystem = {
    _active = false,
    _parryCooldown = 0.5,
    _lastParryTime = 0,
    _parryWindow = 0.3,
    _blockDuration = 1.0,
    _detectionRange = 30,
    _animationChecks = {},
    _soundChecks = {},
    _particleChecks = {}
}

function AutoParrySystem:Initialize()
    -- Load attack signatures for each killer
    self:_loadAttackSignatures()
    
    -- Setup auto-parry toggle
    Fluent.options.Toggles["AutoParryEnabled"]:OnChanged(function(value)
        self._active = value
        if value then
            self:StartParrying()
        else
            self:StopParrying()
        end
    end)
    
    -- Parry cooldown slider
    Fluent.options.Sliders["ParryCooldown"]:OnChanged(function(value)
        self._parryCooldown = value / 1000
    end)
    
    -- Detection range slider
    Fluent.options.Sliders["ParryDetectionRange"]:OnChanged(function(value)
        self._detectionRange = value
    end)
end

function AutoParrySystem:_loadAttackSignatures()
    -- Attack patterns for known killers
    self._attackSignatures = {
        ["1x1x1x1"] = {
            Animations = {
                "rbxassetid://4856801123", -- Mass Infection windup
                "rbxassetid://4856801456"  -- Unstable Eye charge
            },
            Sounds = {
                "rbxassetid://4856802123", -- Infection sound
                "rbxassetid://4856802456"  -- Eye beam sound
            },
            Particles = {
                "InfectionCloud",
                "EyeBeamCharge"
            },
            WindupTime = 0.8,
            DamageRadius = 15
        },
        ["John Doe"] = {
            Animations = {
                "rbxassetid://4856803123", -- 404 Error cast
                "rbxassetid://4856803456"  -- Digital Footprint
            },
            Sounds = {
                "rbxassetid://4856804123", -- Glitch sound
                "rbxassetid://4856804456"  -- Digital sound
            },
            Particles = {
                "ErrorParticles",
                "DigitalTrail"
            },
            WindupTime = 0.5,
            DamageRadius = 10
        }
        -- Add more killers as needed
    }
end

function AutoParrySystem:StartParrying()
    -- Start monitoring for attacks
    self._monitoringConnection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        self:_monitorAttacks(deltaTime)
    end)
    
    Fluent:Notify({
        Title = "Auto-Parry",
        Content = "Parry system activated",
        SubContent = "Monitoring for killer attacks...",
        Duration = 3
    })
end

function AutoParrySystem:StopParrying()
    if self._monitoringConnection then
        self._monitoringConnection:Disconnect()
        self._monitoringConnection = nil
    end
    
    Fluent:Notify({
        Title = "Auto-Parry",
        Content = "Parry system deactivated",
        Duration = 2
    })
end

function AutoParrySystem:_monitorAttacks(deltaTime)
    -- Cooldown check
    self._lastParryTime = math.max(0, self._lastParryTime - deltaTime)
    if self._lastParryTime > 0 then return end
    
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Scan for nearby players
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (targetRoot.Position - humanoidRootPart.Position).Magnitude
                
                if distance <= self._detectionRange then
                    -- Check if this player is a killer with attack signatures
                    local killerName = self:_identifyKiller(player)
                    
                    if killerName and self._attackSignatures[killerName] then
                        local isAttacking = self:_detectAttack(player.Character, killerName)
                        
                        if isAttacking then
                            self:_executeParry(killerName, player.Character)
                            self._lastParryTime = self._parryCooldown
                            return
                        end
                    end
                end
            end
        end
    end
end

function AutoParrySystem:_identifyKiller(player)
    -- Check player name against known killers
    for killerName in pairs(ForsakenDatabase.Killers) do
        if string.find(player.Name, killerName) or 
           string.find(player.DisplayName, killerName) then
            return killerName
        end
    end
    
    -- Check equipped tools/abilities
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                for killerName, signature in pairs(self._attackSignatures) do
                    for _, particleName in ipairs(signature.Particles) do
                        if string.find(tool.Name, particleName) then
                            return killerName
                        end
                    end
                end
            end
        end
    end
    
    return nil
end

function AutoParrySystem:_detectAttack(character, killerName)
    local signature = self._attackSignatures[killerName]
    if not signature then return false end
    
    -- Method 1: Check animations
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation then
                    local animId = track.Animation.AnimationId
                    for _, attackAnim in ipairs(signature.Animations) do
                        if string.find(animId, attackAnim) then
                            return true
                        end
                    end
                end
            end
        end
    end
    
    -- Method 2: Check sounds
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("Sound") and descendant.Playing then
            local soundId = descendant.SoundId
            for _, attackSound in ipairs(signature.Sounds) do
                if string.find(soundId, attackSound) then
                    return true
                end
            end
        end
    end
    
    -- Method 3: Check particles
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("ParticleEmitter") and descendant.Enabled then
            for _, particleName in ipairs(signature.Particles) do
                if string.find(descendant.Name, particleName) then
                    return true
                end
            end
        end
    end
    
    return false
end

function AutoParrySystem:_executeParry(killerName, attacker)
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Execute parry sequence
    spawn(function()
        -- Step 1: Auto-Block
        self:_performBlock()
        task.wait(0.1)
        
        -- Step 2: Instant counter-punch
        self:_performCounterPunch(attacker)
        
        -- Visual feedback
        self:_showParryEffect()
        
        -- Audio feedback
        self:_playParrySound()
        
        -- Notify user
        Fluent:Notify({
            Title = "Auto-Parry Executed",
            Content = string.format("Parried %s's attack", killerName),
            Duration = 2
        })
    end)
end

function AutoParrySystem:_performBlock()
    -- Simulate block animation
    local character = game.Players.LocalPlayer.Character
    local humanoid = character:FindFirstChild("Humanoid")
    
    if humanoid then
        -- Load block animation
        local blockAnim = Instance.new("Animation")
        blockAnim.AnimationId = "rbxassetid://4856811123" -- Block animation ID
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            local track = animator:LoadAnimation(blockAnim)
            track:Play()
            
            -- Create visual block shield
            local shield = Instance.new("Part")
            shield.Size = Vector3.new(4, 6, 0.2)
            shield.Material = Enum.Material.ForceField
            shield.Color = Color3.fromRGB(0, 150, 255)
            shield.Transparency = 0.3
            shield.Anchored = true
            shield.CanCollide = false
            shield.CFrame = character:GetPivot() * CFrame.new(0, 0, -2)
            shield.Parent = workspace.Terrain
            
            -- Cleanup after block duration
            task.wait(self._blockDuration)
            shield:Destroy()
            track:Stop()
        end
    end
end

function AutoParrySystem:_performCounterPunch(attacker)
    -- Simulate counter punch
    local character = game.Players.LocalPlayer.Character
    local humanoid = character:FindFirstChild("Humanoid")
    
    if humanoid and attacker then
        -- Load punch animation
        local punchAnim = Instance.new("Animation")
        punchAnim.AnimationId = "rbxassetid://4856812123" -- Punch animation ID
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            local track = animator:LoadAnimation(punchAnim)
            track:Play()
            
            -- Calculate punch direction
            local attackerRoot = attacker:FindFirstChild("HumanoidRootPart")
            local ourRoot = character:FindFirstChild("HumanoidRootPart")
            
            if attackerRoot and ourRoot then
                -- Orient towards attacker
                humanoid:MoveTo(attackerRoot.Position)
                
                -- Create punch impact effect
                task.wait(0.2) -- Punch windup
                
                local punchOrigin = ourRoot.Position + Vector3.new(0, 1, 0)
                local punchDirection = (attackerRoot.Position - punchOrigin).Unit
                
                -- Visual punch effect
                local punchBeam = Instance.new("Part")
                punchBeam.Size = Vector3.new(0.2, 0.2, 5)
                punchBeam.Material = Enum.Material.Neon
                punchBeam.Color = Color3.fromRGB(255, 100, 0)
                punchBeam.Transparency = 0.5
                punchBeam.Anchored = true
                punchBeam.CanCollide = false
                punchBeam.CFrame = CFrame.new(punchOrigin, punchOrigin + punchDirection) * 
                                  CFrame.new(0, 0, -2.5)
                punchBeam.Parent = workspace.Terrain
                
                -- Cleanup
                task.wait(0.1)
                punchBeam:Destroy()
            end
            
            task.wait(0.5)
            track:Stop()
        end
    end
end

function AutoParrySystem:_showParryEffect()
    -- Create parry success effect
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Ring effect
    local ring = Instance.new("Part")
    ring.Size = Vector3.new(8, 0.2, 8)
    ring.Material = Enum.Material.Neon
    ring.Color = Color3.fromRGB(0, 200, 255)
    ring.Transparency = 0.5
    ring.Anchored = true
    ring.CanCollide = false
    ring.CFrame = rootPart.CFrame * CFrame.new(0, -2, 0)
    ring.Parent = workspace.Terrain
    
    -- Tween expansion
    local tweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local goal = {}
    goal.Size = Vector3.new(15, 0.2, 15)
    goal.Transparency = 1
    
    local tween = tweenService:Create(ring, tweenInfo, goal)
    tween:Play()
    
    tween.Completed:Connect(function()
        ring:Destroy()
    end)
end

function AutoParrySystem:_playParrySound()
    -- Play parry sound effect
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://4856813123" -- Parry sound ID
    sound.Volume = 0.5
    sound.Parent = workspace.Terrain
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- ============================================================================
-- SECTION 4: ITEM ESP SYSTEM
-- ============================================================================

local ItemESP = {
    _active = false,
    _highlights = {},
    _itemCache = {},
    _scanInterval = 1,
    _lastScanTime = 0,
    _renderConnection = nil
}

function ItemESP:Initialize()
    -- Load item models
    self:_loadItemModels()
    
    -- Setup ESP toggle
    Fluent.options.Toggles["ItemESPEnabled"]:OnChanged(function(value)
        self._active = value
        if value then
            self:StartESP()
        else
            self:StopESP()
        end
    end)
    
    -- Item color customization
    for itemName, defaultColor in pairs(ForsakenDatabase.Items) do
        local colorPicker = Fluent.options.ColorPickers[itemName .. "Color"]
        if colorPicker then
            colorPicker:OnChanged(function(color)
                self:_updateItemColor(itemName, color)
            end)
        end
    end
end

function ItemESP:_loadItemModels()
    -- Define item model identifiers
    self._itemModels = {
        ["Medkit"] = {
            ModelName = "Medkit",
            PrimaryPart = "Handle",
            BoundingBox = Vector3.new(2, 1, 1),
            GlowColor = ForsakenDatabase.Items["Medkit"]
        },
        ["BloxyCola"] = {
            ModelName = "BloxyCola",
            PrimaryPart = "Can",
            BoundingBox = Vector3.new(0.5, 1, 0.5),
            GlowColor = ForsakenDatabase.Items["BloxyCola"]
        },
        ["FriedChicken"] = {
            ModelName = "FriedChicken",
            PrimaryPart = "Bucket",
            BoundingBox = Vector3.new(1, 1, 1),
            GlowColor = Color3.fromRGB(255, 200, 0)
        }
    }
end

function ItemESP:StartESP()
    -- Start scanning for items
    self._renderConnection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        self:_updateESP(deltaTime)
    end)
    
    -- Initial scan
    self:_scanForItems()
    
    Fluent:Notify({
        Title = "Item ESP",
        Content = "Item highlighting activated",
        SubContent = "Scanning for Medkits, Bloxy Cola, and Fried Chicken...",
        Duration = 3
    })
end

function ItemESP:StopESP()
    if self._renderConnection then
        self._renderConnection:Disconnect()
        self._renderConnection = nil
    end
    
    -- Remove all highlights
    for _, highlight in pairs(self._highlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    table.clear(self._highlights)
    
    Fluent:Notify({
        Title = "Item ESP",
        Content = "Item highlighting deactivated",
        Duration = 2
    })
end

function ItemESP:_scanForItems()
    -- Clear old cache
    for item in pairs(self._itemCache) do
        if not item:IsDescendantOf(workspace) then
            self._itemCache[item] = nil
            if self._highlights[item] then
                self._highlights[item]:Destroy()
                self._highlights[item] = nil
            end
        end
    end
    
    -- Scan workspace for items
    local function scanFolder(folder)
        for _, item in ipairs(folder:GetDescendants()) do
            self:_checkItem(item)
        end
    end
    
    -- Scan specific folders
    scanFolder(workspace)
    
    -- Check for item spawners
    for _, spawner in ipairs(workspace:GetChildren()) do
        if spawner.Name:find("Spawn") and (spawner.Name:find("Medkit") or 
           spawner.Name:find("Cola") or spawner.Name:find("Chicken")) then
            scanFolder(spawner)
        end
    end
end

function ItemESP:_checkItem(item)
    -- Check if item matches our database
    for itemName, modelInfo in pairs(self._itemModels) do
