--[[ 
--------------------------------------------------------------------
Stat Trainer Assistant Script with UI
--------------------------------------------------------------------
Version History:
v0.1.0 - Initial release
--------------------------------------------------------------------
Script created by: 
  ___   _   _   __  __     ___   _   _   _   _   _   _   ____   ___ 
 | _ \ | | | | |  \/  |   | _ \ | | | | | \ | | | \ | | |  __| | _ \
 |   / | |_| | | |\/| |   |   / | |_| | |  \| | |  \| | |  _|  |   /
 |_|_\  \___/  |_|  |_|   |_|_\  \___/  |_|\__| |_|\__| |____| |_|_\

--------------------------------------------------------------------
This script is designed to be used within the UO Sagas environment.
--------------------------------------------------------------------
Script Description: 
Dynamically trains Strength, Dexterity, or Intelligence from a UI.
--------------------------------------------------------------------
Script Notes:
1) Script uses a UI interface so you do not need to edit the script.
2) Skills used:
   - Dexterity: Hiding
   - Intelligence: Evaluating Intelligence
   - Strength: Arms Lore
3) To start:
   - Update the `Goal` value to your target stat level.
   - Press the training button to begin.
4) If you dont want the skills above to go up, keep it locked. 
Even if that skill is 0.0 and locked, the stat will still rise.
5) Rinse repeat for each stat. Hit the stop button, update goal
and select new stat to start training.
--------------------------------------------------------------------
]]

-- Define Color Scheme
local Colors = {
    Alert   = 33,       -- Red
    Warning = 48,       -- Orange
    Caution = 53,       -- Yellow
    Action  = 67,       -- Green
    Confirm = 73,       -- Light Green
    Info    = 84,       -- Light Blue
    Status  = 93        -- Blue
}

-- Print Initial Start-Up Greeting
Messages.Print("___________________________________", Colors.Info)
Messages.Print("Welcome to a Stat Trainer Assistant Script!", Colors.Info)
Messages.Print("Booting up... Initializing systems... ", Colors.Info)
Messages.Print("___________________________________", Colors.Info)

-- User Settings
local Config = {
    Goal = 100,            -- Default goal for stat training
    SelectedStat = nil,    -- Selected stat to train (Strength, Dexterity, Intelligence)
    Active = false         -- Added: control switch
}

------------- Main script is below, do not make changes below this line -------------


-- UI Window Setup
local window = UI.CreateWindow('statTrainer', 'Rum Runners UI Assistant')
window:SetPosition(50, 75)
window:SetSize(250, 300)
window:SetResizable(false)

-- Add title
window:AddLabel(10, 20, 'Stat Trainer'):SetColor(0.2, 0.8, 1, 1)

-- Stat selection buttons
local strButton = window:AddButton(10, 50, 'Start Training Strength', 200, 30)
local dexButton = window:AddButton(10, 90, 'Start Training Dexterity', 200, 30)
local intButton = window:AddButton(10, 130, 'Start Training Intelligence', 200, 30)

-- Goal input
window:AddLabel(10, 180, 'Goal:'):SetColor(1, 1, 1, 1)
local goalTextBox = window:AddTextBox(55, 175, 50, tostring(Config.Goal))
goalTextBox:SetOnTextChanged(function(newText)
    local goal = tonumber(newText)
    if goal and goal > 0 then
        Config.Goal = goal
        Messages.Print("Goal updated to: " .. goal)
    else
        Messages.Print("Invalid goal entered. Please enter a positive number.")
    end
end)

-- Status label (Main)
local statusLabel = window:AddLabel(10, 220, 'Status: Ready')
statusLabel:SetColor(1, 1, 1, 1)

-- Status label (Details)
local detailLabel = window:AddLabel(10, 240, 'Action: Idle')
detailLabel:SetColor(0.8, 0.8, 0.8, 1)


-- Stop button
local stopButton = window:AddButton(10, 240, 'Stop Training', 140, 30)
stopButton:SetOnClick(function()
    Config.Active = false
    Config.SelectedStat = nil
    statusLabel:SetText("Status: Training Stopped")
    statusLabel:SetColor(1, 0, 0, 1) -- Red
    Messages.Print("Training paused/stopped.")
end)

-- Button Handlers
strButton:SetOnClick(function()
    Config.SelectedStat = 'Strength'
    Config.Active = true
    statusLabel:SetText('Status: Training Strength')
    statusLabel:SetColor(0, 1, 0, 1)
    Messages.Print("Selected stat: Strength")
end)

dexButton:SetOnClick(function()
    Config.SelectedStat = 'Dexterity'
    Config.Active = true
    statusLabel:SetText('Status: Training Dexterity')
    statusLabel:SetColor(0, 1, 0, 1)
    Messages.Print("Selected stat: Dexterity")
end)

intButton:SetOnClick(function()
    Config.SelectedStat = 'Intelligence'
    Config.Active = true
    statusLabel:SetText('Status: Training Intelligence')
    statusLabel:SetColor(0, 1, 0, 1)
    Messages.Print("Selected stat: Intelligence")
end)

-- Helper Functions

local function TrainStrength()
    detailLabel:SetText('Action: Searching equipped items...')
    local layersToCheck = {1, 2, 3, 4, 5, 6, 7, 13, 17, 19, 20, 22, 23, 24}
    local validItems = {}
    for _, layer in ipairs(layersToCheck) do
        local item = Items.FindByLayer(layer)
        if item then table.insert(validItems, item) end
    end
    if #validItems == 0 then
        Messages.Overhead("No weapon or armor found!", Colors.Alert, Player.Serial)
        detailLabel:SetText('Action: No items found!')
        return false
    end
    local targetItem = validItems[1]
    detailLabel:SetText('Action: Using Arms Lore...')
    Messages.Overhead("Using Arms Lore on: " .. (targetItem.Name or "Unknown"), Colors.Action, targetItem.Serial)
    Skills.Use('Arms Lore')
    if Targeting.WaitForTarget(1000) then
        Targeting.Target(targetItem.Serial)
    end
    Pause(1000)
    detailLabel:SetText('Action: Idle')
    return true
end

local function TrainDexterity()
    detailLabel:SetText('Action: Using Hiding...')
    Skills.Use('Hiding')
    for i = 10, 1, -1 do
        detailLabel:SetText('Action: Pausing ' .. i .. 's...')
        Pause(1000)
    end
    detailLabel:SetText('Action: Idle')
end


local function TrainIntelligence()
    detailLabel:SetText('Action: Searching for friendly NPC...')
    local mobiles = Mobiles.FindByFilter({
        rangemax = 8,
        notorieties = {1, 7}
    })
    if #mobiles == 0 then
        Messages.Overhead("No friendly mobiles nearby!", Colors.Alert, Player.Serial)
        detailLabel:SetText('Action: No mobile found')
        return false
    end
    table.sort(mobiles, function(a, b) return a.Distance < b.Distance end)
    local target = mobiles[1]
    detailLabel:SetText('Action: Using Eval Int...')
    Messages.Overhead("Using Eval Int on: " .. (target.Name or "Unknown"), Colors.Action, target.Serial)
    Skills.Use('Evaluating Intelligence')
    if Targeting.WaitForTarget(1000) then
        Targeting.Target(target.Serial)
    end
    Pause(1000)
    detailLabel:SetText('Action: Idle')
    return true
end


-- Main Training Loop
while true do
    if Config.Active then
        if Config.SelectedStat == 'Strength' and Player.Str < Config.Goal then
            TrainStrength()
        elseif Config.SelectedStat == 'Dexterity' and Player.Dex < Config.Goal then
            TrainDexterity()
        elseif Config.SelectedStat == 'Intelligence' and Player.Int < Config.Goal then
            TrainIntelligence()
        end
    end
    Pause(50)
end