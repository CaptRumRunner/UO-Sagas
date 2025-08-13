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

-- User Settings (feel free to edit this section if needed)
local Config = {
    lastTileSerial = nil,     -- Saved mining tile serial
    firstRun       = true     -- 
}

------------- Main script is below, do not make changes below this line -------------

-- Function to reduce ore piles by combining large and small ore piles in the player's inventory
local function ReduceOre()
    -- Define the graphics IDs for large ore piles
    local largeOrePile = { [0x19B9] = true, [0x19B8] = true, [0x19BA] = true }
    -- Define the graphic ID for small ore piles
    local smallOrePile = 0x19B7
    -- Flag to track if any ore was reduced during the process
    local isOreReduced = false
    -- Repeat the process until no more ore can be reduced
    repeat
        -- Flag to track if ore was reduced in the current iteration
        local finishedReduceOre = false
        -- Retrieve a list of all items in the player's inventory
        local itemList = Items.FindByFilter({})

        -- Iterate through the list of items to find large ore piles
        for _, item1 in ipairs(itemList) do
            -- Check if the item exists, is in the player's inventory, and is a large ore pile
            if item1 and item1.RootContainer == Player.Serial and largeOrePile[item1.Graphic] then
                -- Iterate through the list again to find small ore piles that match the large ore pile
                for _, item2 in ipairs(itemList) do
                    -- Check if the item exists, is in the player's inventory, has the same hue, and is a small ore pile
                    if item2 and item2.RootContainer == Player.Serial
                    and item1.Hue == item2.Hue
                    and item2.Graphic == smallOrePile then
                        -- Attempt to reduce the ore pair by interacting with the large ore pile
                        Player.UseObject(item1.Serial)
                        -- Wait for the targeting system to activate
                        if Targeting.WaitForTarget(1000) then
                            -- Target the small ore pile to combine it with the large ore pile
                            Targeting.Target(item2.Serial)
                            -- Pause to allow the game to process the combination
                            Pause(500)
                            -- Display a message indicating that ore piles are being reduced
                            Messages.Overhead("Reducing ore piles...", Colors.Caution, Player.Serial)
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


------------- Pickaxe Functions -------------

function GetEquippedPickaxe()
    local pickaxe = Items.FindByLayer(1)
    if pickaxe and string.find(string.lower(pickaxe.Name or ""), "pickaxe") then
        return pickaxe
    end
    return nil
end

function EquipPickaxe()
    local function ClearHands()
        Messages.Overhead("Clearing hands...", Colors.Warning, Player.Serial)
        local cleared = Player.ClearHands("both")
        if cleared then Pause(500) end
    end

    local function FindPickaxes()
        local items = Items.FindByFilter({ onground = false })
        local result = {}
        for _, item in ipairs(items) do
            if item.RootContainer == Player.Serial and item.Layer ~= 1 and item.Layer ~= 2 then
                if string.find(string.lower(item.Name or ""), "pickaxe") then
                    table.insert(result, item)
                end
            end
        end
        return result
    end

    ClearHands()
    local pickaxes = FindPickaxes()
    if #pickaxes == 0 then
        Messages.Overhead("No pickaxes", Colors.Alert, Player.Serial)
        return nil
    end

    for _, pickaxe in ipairs(pickaxes) do
        Messages.Overhead("Equip: " .. (pickaxe.Name or "Unnamed"), Colors.Info, Player.Serial)
        Player.Equip(pickaxe.Serial)
        Pause(500)

        local timeout = os.clock() + 1.0
        while os.clock() < timeout do
            local equippedNow = Items.FindByLayer(1)
            if equippedNow and equippedNow.Serial == pickaxe.Serial then
                Messages.Overhead("Equipped!", Colors.Action, Player.Serial)
                return equippedNow
            end
            Pause(125)
        end
    end

    Messages.Overhead("Equip failed", Colors.Alert, Player.Serial)
    return nil
end

------------- Mining Functions -------------

local function UsePickaxe(pickaxe)
    Player.UseObject(pickaxe.Serial)
    Pause(100)
    Messages.Overhead("Using pickaxe", Colors.Action, Player.Serial)
end

local function WaitForValidTarget()
    while true do
        Messages.Overhead("Please target a mining tile...", Colors.Info, Player.Serial)
        local pickaxe = GetEquippedPickaxe()
        if not pickaxe then
            pickaxe = EquipPickaxe()
            if not pickaxe then
                Messages.Overhead("No pickaxe available to use for targeting!", Colors.Alert, Player.Serial)
                Pause(3000)
                goto continue_wait -- retry loop
            end
        end

        Player.UseObject(pickaxe.Serial) -- open targeting cursor with pickaxe double click
        Pause(200)

        if not Targeting.WaitForTarget(60000) then -- wait indefinitely up to 60 sec
            Messages.Overhead("Timeout waiting for target", Colors.Alert, Player.Serial)
            goto continue_wait
        else
            local serial = Targeting.LastTarget
            if serial then
                Config.lastTileSerial = serial
                Messages.Overhead("Mining tile selected: " .. tostring(serial), Colors.Info, Player.Serial)
                return serial
            end
        end
        ::continue_wait::
        Pause(100)
    end
end

local function CheckMiningEnd()
    if Journal.Contains("There is no metal here to mine.") then
        Messages.Overhead("Tile depleted", Colors.Warning, Player.Serial)
        CombineOrePiles()        
        Config.lastTileSerial = nil
    elseif Journal.Contains("too far") then
        Messages.Overhead("Too far from mining tile", Colors.Warning, Player.Serial)
        CombineOrePiles()
        Config.lastTileSerial = nil
    elseif Journal.Contains("cannot be seen") then
        Messages.Overhead("Mining tile not visible", Colors.Warning, Player.Serial)
        CombineOrePiles()
        Config.lastTileSerial = nil
    elseif Journal.Contains("can't mine") or Journal.Contains("cannot mine that") then
        Messages.Overhead("Cannot mine that", Colors.Warning, Player.Serial)
        CombineOrePiles()
        Config.lastTileSerial = nil
    end
    return nil
end

local function PerformMining(firstRun)
    local pickaxe = GetEquippedPickaxe()
    if not pickaxe then
        Messages.Overhead("No pickaxe equipped!", Colors.Alert, Player.Serial)
        pickaxe = EquipPickaxe()
        if not pickaxe then
            Pause(3000)
            return nil, firstRun
        end
    end

    if firstRun or Config.lastTileSerial == nil then
        WaitForValidTarget()
    end

    Journal.Clear()
    UsePickaxe(pickaxe)

    if not Targeting.WaitForTarget(1000) then
        Messages.Overhead("Failed to get target cursor", Colors.Warning, Player.Serial)
        Config.lastTileSerial = nil
        return nil, true -- reset targeting
    end

    Targeting.SetLastTarget(Config.lastTileSerial)
    if not Targeting.TargetLast() then
        Messages.Overhead("TargetLast failed", Colors.Warning, Player.Serial)
        Config.lastTileSerial = nil
        return nil, true -- reset targeting
    end

    local timeout = os.clock() + 3.0
    while os.clock() < timeout do
        local miningResult = CheckMiningEnd()
        if miningResult == "NoOre" then
            CombineOrePiles()
            Config.lastTileSerial = nil
            return nil, true -- reset targeting
        elseif miningResult == "TooFar" or miningResult == "NotVisible" or miningResult == "CannotMine" then
            Config.lastTileSerial = nil
            return nil, true -- reset targeting
        end
        Pause(100)
    end

    return true, false
end


------------- Main Loop -------------

local firstRun = true
Journal.Clear()

while true do
    if not GetEquippedPickaxe() then
        EquipPickaxe()
    end

    local success, updatedFirstRun = PerformMining(firstRun)
    if not success then
        Messages.Overhead("Mining stopped or node depleted.", Colors.Alert, Player.Serial)
        firstRun = true -- reset for new manual targeting
    else
        firstRun = updatedFirstRun
    end

    Pause(1500)
end

