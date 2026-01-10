local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Entropy Engine | Forsaken Edition",
   LoadingTitle = "Loading Forsaken Library...",
   LoadingSubtitle = "by Gemini AI",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "EntropyConfig"
   }
})

-- ТА САМАЯ ПАПКА (БАЗА ДАННЫХ)
local ForsakenDB = {
    Items = {"Medkit", "BloxyCola", "Fried Chicken", "Pizza"},
    Killers = {"The Hidden", "The Overseer", "The Scourge", "1x1x1x1", "John Doe"},
    Survivors = {"Guest 1337", "Elliot", "Noob", "Medic"}
}

local MainTab = Window:CreateTab("Main & Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals (ESP)", 4483345998)

-- ПЕРЕМЕННЫЕ ДЛЯ РАБОТЫ
local ESP_Enabled = false
local Highlights = {}

-- ФУНКЦИЯ ПОДСВЕТКИ (ЧТОБЫ НЕ ЛАГАЛО)
local function ApplyESP(object, color)
    if not object:FindFirstChild("ESPHighlight") then
        local hl = Instance.new("Highlight")
        hl.Name = "ESPHighlight"
        hl.Parent = object
        hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillOpacity = 0.5
    end
end

-- ВКЛАДКА ВИЗУАЛОВ
VisualsTab:CreateToggle({
   Name = "Enable Item & Player ESP",
   CurrentValue = false,
   Callback = function(Value)
      ESP_Enabled = Value
      if not Value then
          -- Удаляем подсветку при выключении
          for _, v in pairs(game.CoreGui:GetChildren()) do
              if v.Name == "ESPHighlight" then v:Destroy() end
          end
      end
   end,
})

-- ЦИКЛ ОБРАБОТКИ ПРЕДМЕТОВ (Medkit, Cola)
task.spawn(function()
    while task.wait(2) do -- Проверка каждые 2 сек для экономии ФПС
        if ESP_Enabled then
            for _, item in pairs(workspace:GetDescendants()) do
                for _, name in pairs(ForsakenDB.Items) do
                    if item.Name == name and item:IsA("BasePart") then
                        ApplyESP(item, Color3.fromRGB(0, 255, 150))
                    end
                end
            end
        end
    end
end)

-- ЛОГИКА ДЛЯ GUEST 1337 (COMBAT)
MainTab:CreateSection("Survivor Mechanics")

MainTab:CreateToggle({
   Name = "Guest 1337: Auto Block & Punch",
   CurrentValue = false,
   Callback = function(Value)
      _G.AutoGuest = Value
   end,
})

-- Быстрый цикл для боя
game:GetService("RunService").Heartbeat:Connect(function()
    if _G.AutoGuest then
        -- Тут будет логика детекта атаки убийцы
        -- Если дистанция < 10 и анимация атаки запущена:
        -- game:GetService("ReplicatedStorage").Events.Input:FireServer("Block", true)
    end
end)

Rayfield:Notify({
   Title = "System Ready",
   Content = "Библиотека предметов загружена: Medkit, Cola и другие.",
   Duration = 5,
   Image = 4483362458,
})
