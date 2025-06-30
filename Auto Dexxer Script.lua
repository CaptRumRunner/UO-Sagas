----------------------------------------------------------------------
-- Auto Dexxer Assistant Script v0.2.0
-- Script created by: 

--  ___   _   _   __  __     ___   _   _   _   _   _   _   ____   ___ 
-- | _ \ | | | | |  \/  |   | _ \ | | | | | \ | | | \ | | |  __| | _ \
-- |   / | |_| | | |\/| |   |   / | |_| | |  \| | |  \| | |  _|  |   /
-- |_|_\  \___/  |_|  |_|   |_|_\  \___/  |_|\__| |_|\__| |____| |_|_\

----------------------------------------------------------------------

-- Define Color Scheme
local Colors = {
    Alert   = 33,      	-- Red
    Warning = 48,       -- Orange
    Caution = 53,       -- Yellow
    Action  = 67,       -- Green
    Confirm = 73,       -- Light Green
    Info    = 84,       -- Light Blue
    Status  = 93	-- Blue
}

-- Print Initial Start Up Greeting
Messages.Print("___________________________________", Colors.Info)
Messages.Print("Auto Dexxer Assistant Script Running", Colors.Info)
Messages.Print("___________________________________", Colors.Info)

-- User Settings
local Config = {
    WeightBuffer           = 25,     -- in stones (Edit as needed)
    LastFullHealthMessage  = 0,
    LastBandageMessage     = 0,
    LastBandagingMessage   = 0,
    FullHealthCooldown     = 10,     -- in seconds
    NoBandageCooldown      = 6,      -- in seconds
    BandagingCooldown      = 6,      -- in seconds
    BandageTimeout         = 20000,  -- in milliseconds
    BandageInterval        = 100,    -- in milliseconds
    CureCooldown           = 2,      -- in seconds
    LastCureTime           = 0,
    LastHostileMessageTime = 0,
    HostileMessageCooldown = 4      -- in seconds
}	

-- Define Important Items to Track
local ImportantGear = {
    Bandage 	  = 0x0E21,       -- Bandages
    Cure Potion   = 0x0F0E,  	  -- Cure Potions
    Poison Potion = 0x0F0A	  -- Poison Potions
}

-- Items to Scavenge (Add "--" in front of anything you want to turn off)
local ItemsToSearchFor = {
        0x0f7a, -- Black Pearl
        0x0f7b, -- Blood Moss
        0x0f86, -- Mandrake Root
        0x0f84, -- Garlic
        0x0f85, -- Ginseng
        0x0f88, -- Nightshade
        0x0f8d, -- Spider's Silk
        0x0f8c, -- Sulphurous Ash
        0x0F3F, -- Arrow
        0x1BFB, -- Crossbolt
        0x0E21, -- Bandage
        0x0F0E, -- Empty Bottle
       }

-- Feel free to add animal names here and notify author. Follow same convention as shown
local AnimalNamesToIgnore = {
    ["a deer"] = true, ["a horse"] = true, ["a cow"] = true, ["a dog"] = true, ["a sheep"] = true,
    ["a cat"] = true, ["a goat"] = true, ["a pig"] = true, ["a magpie"] = true, ["a chicken"] = true,
    ["a tropical bird"] = true, ["a squirrel"] = true, ["a warbler"] = true, ["a swallow"] = true,
    ["a woodpecker"] = true, ["a finch"] = true, ["a thrush"] = true, ["an eagle"] = true, ["a rat"] = true,
    ["a gorilla"] = true, ["a raven"] = true, ["a crow"] = true, ["a rabbit"] = true, ["a black bear"] = true,
    ["a hind"] = true, ["a great hart"] = true, ["a grizzly bear"] = true, ["a brown bear"] = true,
    ["a pack horse"] = true, ["a kingfisher"] = true, ["a lapwing"] = true, ["a timber wolf"] = true,
}

----------------------------- Main script is below, do not make changes below this line -----------------------------

-- Function to Check for Important Gear
local function CheckImportantGear()
    local missingItems = {} -- Table to store missing items
    for _, item in ipairs(ImportantGear) do
        local foundItems = Items.FindByType(item.ID, Player.Backpack)
        if not foundItems or #foundItems == 0 then
            table.insert(missingItems, item.Name) -- Add missing item to the list
        end
    end
    if #missingItems > 0 then    -- Display Message for Missing Items
        for _, itemName in ipairs(missingItems) do
            Messages.Overhead("Missing: " .. itemName, Colors.Alert, Player.Serial)
        end
    end
end

-- Check character weight to alert user to weight issue
local function CheckWeight()
    local SafeCharWeight = Player.MaxWeight - Config.WeightBuffer
    if Player.Weight >= SafeCharWeight + Config.WeightBuffer then
        Messages.Overhead("Overweight - Cant Move!!", Colors.Alert, Player.Serial)
        return true
    elseif Player.Weight >= SafeCharWeight then
        Messages.Overhead("Nearly Overweight!", Colors.Warning, Player.Serial)
        return true
    end
    return false
end

-- Main Bandaging Loop based on priority
local function AutoBandage()
    local Bandage = Items.FindByType(3617) -- Find bandages in inventory
    if not Bandage then
        local now = os.clock()
        if now - Config.LastBandageMessage >= Config.NoBandageCooldown then
            Messages.Overhead("No bandages found!", Colors.Alert, Player.Serial)
            Config.LastBandageMessage = now
        end
        return
    end

    Journal.Clear()

    -- Find friends within 2 tiles
    local friends = Mobiles.FindByFilter({
        range = 2,
        notoriety = 1, -- Friendly notoriety
	human = true,		
        dead = false, 
        hits = function(mob) return mob.Hits < mob.HitsMax end -- Only injured friends
    })

    -- Find pets within 2 tiles
    local pets = Mobiles.FindByFilter({
        range = 2,
        notoriety = 1, -- Friendly notoriety
        human = false,
	dead = false, 
        hits = function(mob) return mob.Hits < mob.HitsMax end, -- Only injured pets
        ispet = true -- Ensure they are pets
    })

    -- Determine target priority
    local target = nil
    local bandageTime = nil
    if #friends > 0 then
        target = friends[1] -- Prioritize the first injured friend
	local healingSkill = Player.Skills.Healing or 0 -- Healing skill level
        local dexterity = Player.Stats.Dexterity or 0 -- Dexterity attribute	
        bandageTime = math.max(baseTime - (healingSkill / 10) - (dexterity / 10), 2) 
    elseif #pets > 0 then
        target = pets[1] -- If no friends, prioritize the first injured pet
        local baseTime = 10 -- Base bandaging time in seconds
        local healingSkill = Player.Skills.Healing or 0 -- Healing skill level
        local dexterity = Player.Stats.Dexterity or 0 -- Dexterity attribute
        bandageTime = math.max(baseTime - (healingSkill / 10) - (dexterity / 10), 2) -- Minimum bandage time is 2 seconds
    elseif Player.Hits < Player.HitsMax then
        target = Player -- If no friends or pets, heal self
        local baseTime = 10 -- Base bandaging time in seconds
        local healingSkill = Player.Skills.Healing or 0 -- Healing skill level
        local dexterity = Player.Stats.Dexterity or 0 -- Dexterity attribute
        bandageTime = math.max(baseTime - (healingSkill / 10) - (dexterity / 10), 2) -- Minimum bandage time is 2 seconds
    end

    -- Perform bandaging if a target is found
    if target then
        Player.UseObject(Bandage.Serial)
        if Targeting.WaitForTarget(1000) then
            Targeting.TargetObject(target.Serial)
            local now = os.clock()
            if now - Config.LastBandagingMessage >= Config.BandagingCooldown then
                Messages.Overhead("Bandaging " .. (target.Name or "self"), Colors.Action, Player.Serial)
                Config.LastBandagingMessage = now

                local elapsed = 0
                local result = nil
                local initialHits = target.Hits -- Record initial health
                while elapsed < bandageTime * 1000 do
                    local remainingTime = math.ceil((bandageTime * 1000 - elapsed) / 1000) -- Calculate seconds remaining
                    Messages.Overhead("Bandaging... " .. remainingTime .. "s remaining", Colors.Info, Player.Serial)
                    if Journal.Contains("You finish applying the bandages") then
                        result = "full"
                        local healedAmount = target.Hits - initialHits -- Calculate amount healed
                        Messages.Overhead("Healed " .. healedAmount .. " HP", Colors.Confirm, target.Serial) -- Display healed amount over the target
                        break
                    elseif Journal.Contains("You apply the bandages, but they barely help.") then
                        result = "partial"
                        local healedAmount = target.Hits - initialHits -- Calculate amount healed
                        Messages.Overhead("Healed " .. healedAmount .. " HP (barely helped)", Colors.Warning, target.Serial) -- Display healed amount over the target
                        break
                    elseif Journal.Contains("You have failed to cure your target.") then
                        result = "failed"
                        Messages.Overhead("Bandage Failed", Colors.Alert, target.Serial) -- Display failure message over the target
                        break
                    end
                    Pause(Config.BandageInterval)
                    elapsed = elapsed + Config.BandageInterval
                end

                if not result then
                    Messages.Overhead("Bandage timed out", Colors.Alert, Player.Serial)
                end
            end
        end
    else
        local now = os.clock()
        if now - Config.LastFullHealthMessage >= Config.FullHealthCooldown then
            Messages.Overhead("No injured targets found", Colors.Info)
            Config.LastFullHealthMessage = now
        end
    end
end

-- Cure Poison
local function AutoCure()
    local now = os.clock()
    if now - Config.LastCureTime < Config.CureCooldown then return end
    if Journal.Contains("You feel a bit nauseous") then
        local CurePotion = Items.FindByType(3847, Player.Backpack)
        if CurePotion then
            Player.UseObject(CurePotion.Serial)
            Messages.Overhead("Curing Poison", Colors.Action, Player.Serial)
            Config.LastCureTime = now
            Journal.Clear()
        else
            Messages.Overhead("No Cure Potion Found!", Colors.Alert, Player.Serial)
            Config.LastCureTime = now
        end
    end
end

-- Scan for enemies
local function CheckHostileMobs()
    local mobs = Mobiles.FindByFilter({range = 12, notoriety = 5, dead = false, human = false})
    if mobs then
        for _, mob in ipairs(mobs) do
            if mob and mob.Name then
                local name = mob.Name:lower()                
                if not AnimalNamesToIgnore[name] then   -- Check if the mob is an animal using the set
                    local now = os.clock()
                    if now - Config.LastHostileMessageTime >= Config.HostileMessageCooldown then
                        Messages.Overhead("Hostile!", Colors.Alert, mob.Serial)
                        Config.LastHostileMessageTime = now
                    end
                end
            end
        end
    end
end

-- Scavenger Loop
local function Scavenger()
	local filter = {onground=true, rangemax=2, graphics=ItemsToSearchFor}	
	list = Items.FindByFilter(filter)
	for index, item in ipairs(list) do
	    Messages.Print('Picking up '..item.Name..' at location x:'..item.X..' y:'..item.Y)
	    Player.PickUp(item.Serial, 1000)
	    Pause(100)
	    Player.DropInBackpack()
	    Pause(100)
	end
end

-- Main Loop
while true do
    CheckImportantGear()
    CheckWeight()
    AutoBandage()
    AutoCure()
    CheckHostileMobs()
    Scavenger() 
    Pause(150)
end
