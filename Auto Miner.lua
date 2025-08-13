--[[
--------------------------------------------------------------------
Auto Miner Assistant Script
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

-- Print Initial Start-Up Greeting
Messages.Print("___________________________________", Colors.Info)
Messages.Print("Welcome to the Auto Miner Assistant Script!", Colors.Info)
Messages.Print("Booting up... Initializing systems... ", Colors.Info)
Messages.Print("__________________________________", Colors.Info)

-- User Settings (Feel free to edit this section as needed)
local Config = {
    isMining = false,      -- Tracks whether mining is active
}
	
------------- Main script is below, do not make changes below this line -------------

-- UI Window Setup
local window = UI.CreateWindow('miningAssistant', 'Auto Miner Assistant v1.0.0')
if window then
    window:SetPosition(50, 75)
    window:SetSize(280, 180)
    window:SetResizable(false)

    -- Add title
    window:AddLabel(10, 20, 'Mining Assistant Menu'):SetColor(0.2, 0.8, 1, 1)

    -- Add buttons for mining tasks
    local startButton = window:AddButton(10, 50, 'Start Mining', 160, 30)
    local stopButton = window:AddButton(10, 90, 'Stop Mining', 160, 30)

    -- Add status label
    local statusLabel = window:AddLabel(10, 130, 'Status: Ready')
    statusLabel:SetColor(1, 1, 1, 1)

    -- Function to start mining
    local function StartMining()
        if Config.isMining then
            Messages.Print("Mining is already running.", Colors.Warning)
            return
        end

        Config.isMining = true
        statusLabel:SetText("Status: Mining...")
        statusLabel:SetColor(0, 1, 0, 1) -- Green
        Messages.Print("Mining process started.", Colors.Action)

        -- Mining loop
        while Config.isMining do
            MineWithPickaxe()  -- Call the mining function
            Pause(100)  -- Allow UI updates
        end
    end

    -- Function to stop mining
    local function StopMining()
        if not Config.isMining then
            Messages.Print("Mining is not running.", Colors.Warning)
            return
        end

        Config.isMining = false
        statusLabel:SetText("Status: Stopped")
        statusLabel:SetColor(1, 0, 0, 1) -- Red
        Messages.Print("Mining process stopped.", Colors.Alert)
    end

    -- Set up button event handlers
    startButton:SetOnClick(StartMining)
    stopButton:SetOnClick(StopMining)
end

-- Function to reduce ore piles by combining large and small ore piles in the player's inventory
local function ReduceOre()  -- Define the graphics IDs for large ore piles
    local largeOrePile = { [0x19B9] = true, [0x19B8] = true, [0x19BA] = true } -- Define the graphic ID for small ore piles
    local smallOrePile = 0x19B7 -- Flag to track if any ore was reduced during the process
    local isOreReduced = false -- Repeat the process until no more ore can be reduced
    repeat -- Flag to track if ore was reduced in the current iteration
        local finishedReduceOre = false -- Retrieve a list of all items in the player's inventory
        local itemList = Items.FindByFilter({})

        -- Iterate through the list of items to find large ore piles
        for _, item1 in ipairs(itemList) do -- Check if the item exists, is in the player's inventory, and is a large ore pile
            if item1 and item1.RootContainer == Player.Serial and largeOrePile[item1.Graphic] then                
                for _, item2 in ipairs(itemList) do -- Iterate through the list again to find small ore piles that match the large ore pile                    
                    if item2 and item2.RootContainer == Player.Serial -- Check if the item exists, is in the player's inventory, has the same hue, and is a small ore pile
                    and item1.Hue == item2.Hue
                    and item2.Graphic == smallOrePile then -- Attempt to reduce the ore pair by interacting with the large ore pile
                        Player.UseObject(item1.Serial) -- Wait for the targeting system to activate
                        if Targeting.WaitForTarget(1000) then
                            Targeting.Target(item2.Serial) -- Target the small ore pile to combine it with the large ore pile
                            Pause(500) -- Pause to allow the game to process the combination
                            Messages.Overhead("Reducing ore piles...", Colors.Caution, Player.Serial) -- Display a message indicating that ore piles are being reduced
                            -- Set flags to indicate that ore was reduced
                            finishedReduceOre = true
                            isOreReduced = true
                            -- Break out of the inner loop after successfully reducing ore
                            break
                        end
                    end
                end
            end
            -- Break out of the outer loop if ore was reduced in this iteration
            if finishedReduceOre then break end
        end
    -- Continue the process until no more ore can be reduced
    until not finishedReduceOre

    -- Display a message if any ore was reduced and return true
    if isOreReduced then
        Messages.Overhead("All Ore reduced!", Colors.Confirm, Player.Serial)
        return true
    else
        -- Return false if no ore was reduced
	Messages.Overhead("No Ore to reduce!", Colors.Alert, Player.Serial)
        return false
    end
end

-- Function to check if you have a Pickaxe equip and if not, clear hands and equip a pickaxe
function EquipPickaxe()  -- Check if a pickaxe is already equipped in Layer 1
    local checkEquippedPickaxe = Items.FindByLayer(1)  -- Find the item equipped in Layer 1
    if checkEquippedPickaxe and string.find(string.lower(checkEquippedPickaxe.Name or ""), "pickaxe") then
        -- Return the currently equipped pickaxe if found
        Messages.Overhead("Pickaxe already equipped!", Colors.Info, Player.Serial)
        return checkEquippedPickaxe
    end

    -- Clear the player's hands to prepare for equipping a pickaxe
    Messages.Overhead("Clearing hands...", Colors.Warning, Player.Serial)
    local clearHands = Player.ClearHands("both")  -- Unequip items from both hands
    if clearHands then Pause(500) end  -- Pause to allow the game to process clearing hands

    -- Search the player's inventory for pickaxes
    local items = Items.FindByFilter({ onground = false })  -- Get all items in inventory
    local pickaxes = {}  -- Initialize a table to store found pickaxes
    for _, item in ipairs(items) do
        -- Check if the item is in the player's inventory, not equipped, and is a pickaxe
        if item.RootContainer == Player.Serial and item.Layer ~= 1 and item.Layer ~= 2 then
            if string.find(string.lower(item.Name or ""), "pickaxe") then
                table.insert(pickaxes, item)  -- Add the pickaxe to the list
            end
        end
    end

    -- If no pickaxes are found, display an error message and return nil
    if #pickaxes == 0 then
        Messages.Overhead("No pickaxes found!", Colors.Alert, Player.Serial)
        return nil
    end

    -- Attempt to equip the first pickaxe in the list
    for _, pickaxe in ipairs(pickaxes) do
        Messages.Overhead("Equip: " .. (pickaxe.Name or "Unnamed"), Colors.Info, Player.Serial)
        Player.Equip(pickaxe.Serial)  -- Equip the pickaxe
        Pause(500)  -- Pause to allow the game to process equipping

        -- Check if the pickaxe was successfully equipped
        local timeout = os.clock() + 1.0  -- Set a timeout for 1 second
        while os.clock() < timeout do
            local equipPickaxeNow = Items.FindByLayer(1)  -- Check Layer 1 for the equipped item
            if equipPickaxeNow and equipPickaxeNow.Serial == pickaxe.Serial then
                -- Display success message and return the equipped pickaxe
                Messages.Overhead("Pickaxe equipped!", Colors.Action, Player.Serial)
                return equipPickaxeNow
            end
            Pause(125)  -- Pause briefly before rechecking
        end

        -- Break out of the loop if equipping was successful
        break
    end

    -- If equipping fails, display an error message and return nil
    Messages.Overhead("Failed to equip pickaxe!", Colors.Alert, Player.Serial)
    return nil
end

------------- Mining Functions -------------

function MineWithPickaxe()
    -- List of end messages to check in the journal
    local endMessages = {
        "You are too far away.",
        "There is no metal here to mine.",
        "You can't mine that.",
        "You have no line of sight."
    }

    -- Function to check the journal for end messages
    local function CheckJournalForEndMessage()
        local journalEntries = Journal.GetLines()  -- Get all journal entries
        for _, message in ipairs(endMessages) do
            for _, entry in ipairs(journalEntries) do
                if string.find(string.lower(entry), string.lower(message)) then
                    return true  -- End message found
                end
            end
        end
        return false  -- No end message found
    end

    -- Main mining loop
    while Config.isMining do -- Double-click the pickaxe to bring up the targeting cursor        
        local pickaxe = EquipPickaxe()  -- Find the equipped pickaxe in Layer 1
        if not pickaxe then
            Messages.Overhead("No pickaxe equipped!", Colors.Alert, Player.Serial)
			Config.isMining = false
            return  -- Exit if no pickaxe is equipped
        end

        Player.UseObject(pickaxe.Serial)  -- Double-click the pickaxe to start mining
		local targetSerial = Targeting.GetNewTarget(15000)  -- Wait for the player to select a target
        if not targetSerial then
            Messages.Overhead("No target selected. Restarting mining.", Colors.Warning, Player.Serial)
            break  -- Restart the loop if no target is selected
        end

        -- Check the journal for end messages
        if CheckJournalForEndMessage() then
            Messages.Overhead("No Ore found. Reducing ore piles and restarting mining.", Colors.Warning, Player.Serial)
            ReduceOre()  -- Call the ReduceOre function to reduce ore piles
            Pause(500)  -- Brief pause before restarting
            break -- Exit the loop and restart the mining cycle
        end

        Targeting.SetLastTarget(targetSerial)  -- Save the selected target as the last target

		-- Inner loop: Continue mining the last target until an end message is found
   		while Config.isMining do 
			Player.UseObject(pickaxe.Serial) -- Double-click the pickaxe to activate the targeting system
        	Targeting.TargetLast()  -- Retarget the last clicked location
			Pause(500)  -- Brief pause before continuing
			
       		if CheckJournalForEndMessage() then -- Check the journal for end messages
            	Messages.Overhead("Vein has been depleted. Find a new tile.", Colors.Warning, Player.Serial)
            	break  -- Exit the inner loop to restart the mining cycle
        	end
    end
end


------------- Main loop to keep the script running indefinitely -------------

while true do
	Journal.Clear() -- Clear the journal at the start
    Pause(50)
end



