--[[
--------------------------------------------------------------------
Auto Miner Assistant Script
--------------------------------------------------------------------
Version History:
v0.2.0 - Initial release
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
Auto Miner assistant with continuous mining on a single tile until depleted,
automatic ore combining when node is depleted,
and automatic re-targeting with no timeout until user selects new mining tile.

--------------------------------------------------------------------
Script Notes:
  
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

-- Ore Hue Table
local OreHues = {
    { name = "Shadow",    hue = 0x044E },  -- Dark gray/black
    { name = "Copper",    hue = 0x06C2 },  -- Coppery orange
    { name = "Bronze",    hue = 0x0973 },  -- Bronze-like brown
    { name = "Gold",      hue = 0x08A5 },  -- Golden yellow
    { name = "Agapite",   hue = 0x097D },  -- Light reddish-brown
    { name = "Verite",    hue = 0x089F },  -- Greenish hue
    { name = "Valorite",  hue = 0x05B6 },  -- Deep blue
}

-- Journal messages while mining
local endMessages = {
     "You are too far away.",
     "There is no metal here to mine.",
     "You can't mine that.",
     "You have no line of sight."
    }

-- Print Initial Start-Up Greeting
Messages.Print("___________________________________", Colors.Info)
Messages.Print("Welcome to the Auto Miner Assistant Script!", Colors.Info)
Messages.Print("Booting up... Initializing systems... ", Colors.Info)
Messages.Print("__________________________________", Colors.Info)

-- User Settings (Feel free to edit this section as needed)
local Config = {
    isMining = false,           -- Tracks whether mining is active
    firstRun = true,            -- Tracks valid mining tile to decrease clicking
    miningMode = "Solo",        -- Default mining mode
    smallIronOreID = 0x19B7     -- Small iron ore graphic ID
}

------------- Main script is below, do not make changes below this line -------------

------------------------- UI Window Setup -------------------------

local window = UI.CreateWindow('miningOptions', 'Auto Miner Assistant v1.0.0')
if window then
    window:SetPosition(50, 75)
    window:SetSize(400, 200)
    window:SetResizable(false)

    -- Add title
    window:AddLabel(10, 20, 'Mining Assistant Menu'):SetColor(0.2, 0.8, 1, 1)

    -- Add buttons for mining tasks
    local startButton = window:AddButton(10, 50, 'Start Mining', 160, 30)
    local stopButton = window:AddButton(10, 90, 'Stop Mining', 160, 30)

    -- Add radio buttons for mining mode (to the right of the buttons)
    local soloMiningCheckbox = window:AddCheckbox(200, 50, "Solo Mining", true)  -- Default to Solo Mining
    local packhorseMiningCheckbox = window:AddCheckbox(200, 75, "Packhorse Mining", false)

     -- Ensure mutual exclusivity for radio buttons
    soloMiningCheckbox:SetOnCheckedChanged(function(isChecked)
        if isChecked then
            packhorseMiningCheckbox:SetChecked(false)
            Config.miningMode = "Solo"
            Messages.Print("Mining mode set to: Solo Mining")
        else
            soloMiningCheckbox:SetChecked(true)  -- Prevent unchecking both
        end
    end)

    packhorseMiningCheckbox:SetOnCheckedChanged(function(isChecked)
        if isChecked then
            soloMiningCheckbox:SetChecked(false)
            Config.miningMode = "Packhorse"
            Messages.Print("Mining mode set to: Packhorse Mining")
        else
            packhorseMiningCheckbox:SetChecked(true)  -- Prevent unchecking both
        end
    end)
  
    -- Add status label
    local statusLabel = window:AddLabel(10, 130, 'Status: Ready')
    statusLabel:SetColor(1, 1, 1, 1)

    local detailLabel = window:AddLabel(10, 160, 'Action: Idle')
    detailLabel:SetColor(0.8, 0.8, 0.8, 1)

    -- Button handlers
    startButton:SetOnClick(function()
        Config.isMining = true
        statusLabel:SetText('Status: Mining Start')
        statusLabel:SetColor(0, 1, 0, 1)
        Messages.Print("Mining started.")
    end)

    stopButton:SetOnClick(function()
        Config.isMining = false
        statusLabel:SetText('Status: Mining Stopped')
        statusLabel:SetColor(0, 1, 0, 1)
        Messages.Print("Mining stopped.")
    end)
end

------------------------- Primary Functions Setup -------------------------

-- Function to pick up dropped ore if player weight is below max weight
local function PickUpDroppedOre()
    local maxCarryWeight = Player.MaxWeight - Player.Weight  -- Calculate remaining weight capacity
    local oreWeight = 2  -- Each ore weighs 2 stones

    if maxCarryWeight <= 0 then
        Messages.Overhead("Cannot pick up more ore! Stopping mining.", Colors.Alert, Player.Serial)
        Config.isMining = false  -- Stop mining if player cannot carry more ore
        return
    end

    local oreList = Items.FindByFilter({ type = Config.smallIronOreID, onground = true })
    local pickedUpWeight = 0

    for _, ore in ipairs(oreList) do
        local maxOreToPickUp = math.floor((maxCarryWeight - pickedUpWeight) / oreWeight)  -- Calculate how many ore pieces can be picked up
        if maxOreToPickUp <= 0 then
            break  -- Stop if no more ore can be picked up
        end

        local oreToPickUp = math.min(ore.Count, maxOreToPickUp)  -- Pick up only what's needed
        Player.PickUp(ore.Serial, oreToPickUp)  -- Pick up the required number of ore pieces
        Pause(500)
        pickedUpWeight = pickedUpWeight + (oreToPickUp * oreWeight)  -- Update the total weight picked up

        Messages.Overhead("Picked up " .. oreToPickUp .. " ore(s).", Colors.Action, Player.Serial)

        -- Check if player has reached max weight
        if Player.Weight >= Player.MaxWeight then
            Messages.Overhead("Player is at max weight! Stopping picking up ore.", Colors.Alert, Player.Serial)
            Config.isMining = false  -- Stop mining if player cannot carry more ore
            return
        end
    end

    if pickedUpWeight == 0 then
        Messages.Overhead("No ore to pick up!", Colors.Warning, Player.Serial)
    end
end

-- Function to check journal for mining messahes
local function CheckJournalForEndMessage()
    for _, message in ipairs(endMessages) do
        if Journal.Contains(message) then
             return true
        end
    end
    return false
end

-- Function to check journal for ore hues and display overhead messages
local function CheckOreHuesInJournal()
    for _, ore in ipairs(OreHues) do
        if Journal.Contains(ore.name) then
            Messages.Overhead("Found " .. ore.name .. " Ore!", Colors.Action, Player.Serial)
            Journal.Clear()  -- Clear the journal to avoid duplicate messages
            return true
        end
    end
    return false
end

-- Function to reduce ore piles by combining large and small ore piles
local function ReduceOre()  -- Define the graphics IDs for large ore piles
    local largeOrePile = { [0x19B9] = true, [0x19B8] = true, [0x19BA] = true } -- Large ore pile IDs
    local smallOrePile = 0x19B7 -- Small ore pile ID
    local isOreReduced = false

    repeat
        local finishedReduceOre = false
        local itemList = Items.FindByFilter({})

        for _, item1 in ipairs(itemList) do
            if item1 and item1.RootContainer == Player.Serial and largeOrePile[item1.Graphic] then
                for _, item2 in ipairs(itemList) do
                    if item2 and item2.RootContainer == Player.Serial
                    and item1.Hue == item2.Hue
                    and item2.Graphic == smallOrePile then
                        Player.UseObject(item1.Serial)
                        if Targeting.WaitForTarget(1000) then
                            Targeting.Target(item2.Serial)
                            Pause(500)
                            Messages.Overhead("Reducing ore piles...", Colors.Caution, Player.Serial)
                            finishedReduceOre = true
                            isOreReduced = true
                            break
                        end
                    end
                end
            end
            if finishedReduceOre then break end
        end
    until not finishedReduceOre

    if isOreReduced then
        Messages.Overhead("All Ore reduced!", Colors.Confirm, Player.Serial)
        return true
    else
        Messages.Overhead("No Ore to reduce!", Colors.Alert, Player.Serial)
        return false
    end
end

-- Function to equip pickaxe
function EquipPickaxe()
    local checkEquippedPickaxe = Items.FindByLayer(1)
    if checkEquippedPickaxe and string.find(string.lower(checkEquippedPickaxe.Name or ""), "pickaxe") then
        Messages.Overhead("Pickaxe already equipped!", Colors.Info, Player.Serial)
        return checkEquippedPickaxe
    end

    Messages.Overhead("Clearing hands...", Colors.Warning, Player.Serial)
    local clearHands = Player.ClearHands("both")
    if clearHands then Pause(500) end

    local items = Items.FindByFilter({ onground = false })
    local pickaxes = {}
    for _, item in ipairs(items) do
        if item.RootContainer == Player.Serial and item.Layer ~= 1 and item.Layer ~= 2 then
            if string.find(string.lower(item.Name or ""), "pickaxe") then
                table.insert(pickaxes, item)
            end
        end
    end

    if #pickaxes == 0 then
        Messages.Overhead("No pickaxes found!", Colors.Alert, Player.Serial)
        return nil
    end

    for _, pickaxe in ipairs(pickaxes) do
        Messages.Overhead("Equip: " .. (pickaxe.Name or "Unnamed"), Colors.Info, Player.Serial)
        Player.Equip(pickaxe.Serial)
        Pause(500)

        local timeout = os.clock() + 1.0
        while os.clock() < timeout do
            local equipPickaxeNow = Items.FindByLayer(1)
            if equipPickaxeNow and equipPickaxeNow.Serial == pickaxe.Serial then
                Messages.Overhead("Pickaxe equipped!", Colors.Action, Player.Serial)
                return equipPickaxeNow
            end
            Pause(125)
        end
        break
    end

    Messages.Overhead("Failed to equip pickaxe!", Colors.Alert, Player.Serial)
    return nil
end

------------------------- Primary Script Loop -------------------------

function MineWithPickaxe()
    local pickaxe = EquipPickaxe() -- Equip a pickaxe first
    if not pickaxe then
        Messages.Overhead("No pickaxe equipped!", Colors.Alert, Player.Serial)
        Config.isMining = false
        return
    end

    -- Prompt user to select an intial mining target
    Player.UseObject(pickaxe.Serial)
    Messages.Overhead("Select initial tile...", Colors.Info, Player.Serial)

    local lastMiningTile = nil
    if Targeting.GetNewTarget(30000) then
        lastMiningTile = Targeting.LastTarget.Serial  -- Store the selected target's serial
        Config.firstRun = false
        Pause(150)
    end

    -- Check immediately if intial tile has a end message in the journal
    if CheckJournalForEndMessage() then
        Messages.Overhead("No ore found, restarting...", Colors.Warning, Player.Serial)
        Pause(300)
        return
    end

    CheckOreHuesInJournal() -- Check for ore hues in the journal
  
    -- Inner loop: continue mining last target until vein is depleted
    while Config.firstRun == false do
        Player.UseObject(pickaxe.Serial)        -- Activate pickaxe

        -- Handle pickaxe break
        if Journal.Contains("You have worn out your tool!") then
            Messages.Overhead("Pickaxe broke! Equipping a new one...", Colors.Alert, Player.Serial)
             pickaxe = EquipPickaxe()  -- Auto-equip a new pickaxe
            if not pickaxe then
                 Messages.Overhead("No pickaxe available! Stopping mining.", Colors.Alert, Player.Serial)
                Config.firstRun = true
                Journal.Clear()
            break -- Exit inner loop
            end
        end

        if Targeting.WaitForTarget(1000) then
            Targeting.Target(lastMiningTile)  -- Use the stored target serial
            Pause(150)
            Messages.Overhead("Auto mining vein!", Colors.Info, Player.Serial)
        end

        if CheckJournalForEndMessage() then     -- Check for depletion or invalid target
            Messages.Overhead("Vein has been depleted. Select a new tile...", Colors.Warning, Player.Serial)
            ReduceOre()
            Journal.Clear()
            Pause(150)                
  
            -- Check player weight and drop ore if overweight
            if Config.miningMode == "Solo" and Player.Weight > Player.MaxWeight then
                local excessWeight = Player.Weight - Player.MaxWeight
                local oreToDrop = math.ceil(excessWeight / 2)  -- Each ore weighs 2 stones

                 Messages.Overhead("Overweight! Dropping " .. oreToDrop .. " ore(s).", Colors.Warning, Player.Serial)

                local oreList = Items.FindByFilter({ type = 0x19B7, container = Player.Backpack })  -- Small ore pile ID
                local droppedOreCount = 0
        
                for _, ore in ipairs(oreList) do
                    if droppedOreCount >= oreToDrop then
                        break
                    end

                    local dropCount = math.min(ore.Count, oreToDrop - droppedOreCount)  -- Drop only what's needed
                     Player.PickUp(ore.Serial, dropCount)  -- Pick up the required number of ore pieces
                    Pause(150)
                    Player.DropOnGround()
                    Pause(400)
                    droppedOreCount = droppedOreCount + dropCount          
                end

                if droppedOreCount < oreToDrop then
                    Messages.Overhead("Not enough ore to drop!", Colors.Alert, Player.Serial)
                else
                    Messages.Overhead("Dropped " .. droppedOreCount .. " ore(s).", Colors.Confirm, Player.Serial)
                end
             end

             break -- Exit inner loop
        end
    
        CheckOreHuesInJournal() -- Check for ore hues in the journal
       end   
      
       -- Attempt to pick up dropped ore if weight is below max
       PickUpDroppedOre()
end


------------- Main loop to keep the script running indefinitely -------------

while true do
    Journal.Clear()                -- Clear old journal messages
    if Config.isMining then
        MineWithPickaxe()
    end
    Pause(250)
end


