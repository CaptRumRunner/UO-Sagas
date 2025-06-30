----------------------------------------------------------------------
-- Auto Dexxer Assistant Script v0.1.3
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
Messages.Print("Auto Dexxer Assistant Script v0.1.3", Colors.Info)
Messages.Print("___________________________________", Colors.Info)

-- User Settings
local Config = {
    WeightBuffer           = 25     -- in stones (Edit as needed)
    LastFullHealthMessage  = 0
    LastBandageMessage     = 0
    LastBandagingMessage   = 0
    FullHealthCooldown     = 10     -- in seconds
    NoBandageCooldown      = 6      -- in seconds
    BandagingCooldown      = 6      -- in seconds
    BandageTimeout         = 20000  -- in milliseconds
    BandageInterval        = 100    -- in milliseconds
    CureCooldown           = 2      -- in seconds
    LastCureTime           = 0
    LastHostileMessageTime = 0
    HostileMessageCooldown = 4      -- in seconds
}	

-- Items to Scavenge (Add "--" in front of anything you want to turn off)
itemsToSearchFor = {
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

local AnimalNames = {
    "a deer", "a horse", "a cow", "a dog", "a sheep", "a cat", "a goat", "a pig", "a magpie", "a chicken", 
    "a tropical bird", "a squirrel", "a warbler", "a swallowL", "a woodpecker", "a finch", "a thrush",
    "an eagle", "a rat", "a gorilla", "a raven", "a crow", "a rabbit", "a black bear", "a hind", "a great hart", 
    "a grizzly bear", "a brown bear", "a pack horse", "a kingfisher", "a lapwing", "a timber wolf",
}

-- Check Character Weight
local function GetWeightLimit()
    return Player.MaxWeight - Config.WeightBuffer
end

local function IsOverweight()
    local MaxCharWeight = GetWeightLimit()
    if Player.Weight >= MaxCharWeight + Config.WeightBuffer then
        Messages.Overhead("Overweight!!!!!", Colors.Alert, Player.Serial)
        return true     
     elseif Player.Weight >= MaxCharWeight then
        Messages.Overhead("Nearly Overweight", Colors.Warning, Player.Serial)
        return true    
    end
    return false
end

-- Bandaging
local function AutoBandageSelf()
    if Player.Hits < Player.HitsMax then
        local Bandage = Items.FindByType(3617)
        if Bandage then
            Journal.Clear()
            Player.UseObject(Bandage.Serial)
            if Targeting.WaitForTarget(1000) then
                Targeting.TargetSelf()
                local now = os.clock()
                if now - Config.LastBandagingMessage >= Config.BandagingCooldown then
                    Messages.Overhead("Bandaging", Colors.Action, Player.Serial)
                    Config.LastBandagingMessage = now
                    local elapsed = 0
                    local result = nil
                    while elapsed < Config.BandageTimeout do
                        if Journal.Contains("You finish applying the bandages") then
                            result = "full"
                            Messages.Overhead("Bandage complete!", Colors.Confirm, Player.Serial)
                            break
                        elseif Journal.Contains("You apply the bandages, but they barely help.") then
                            result = "partial"
                            Messages.Overhead("Bandage barely helped", Colors.Warning, Player.Serial)
                            break
                        elseif Journal.Contains("You have failed to cure your target.") then
                            result = "partial"
                            Messages.Overhead("Bandage Failed", Colors.Alert, Player.Serial)
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
            if now - Config.LastBandageMessage >= Config.NoBandageCooldown then
                Messages.Overhead("No bandages found!", Colors.Alert, Player.Serial)
                Config.LastBandageMessage = now
            end
        end
    else
        local now = os.clock()
        if now - Config.LastFullHealthMessage >= Config.FullHealthCooldown then
            Messages.Overhead("Full Health", Colors.Info)
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

-- Determine if it's an animal
local function IdentifyAnimal(mob)
    if not mob or not mob.Name then return false end
    local name = mob.Name:lower()
    for _, animal in ipairs(AnimalNames) do
        if name == animal then return true end
    end
    return false
end

-- Scan for enemies
local function CheckHostileMobs()
    local mobs = Mobiles.FindByFilter({
        range = 15,
        notoriety = 5,
        dead = false,
        human = false
    })

    if mobs then
        for _, mob in ipairs(mobs) do
            if mob and mob.Name and not IdentifyAnimal(mob) then
                local now = os.clock()
                if now - Config.LastHostileMessageTime >= Config.HostileMessageCooldown then
                    Messages.Overhead("Hostile!", Colors.Alert, mob.Serial)
                    Config.LastHostileMessageTime = now
                end
            end
        end
    end
end


-- Main Scavenger Loop
local function Scavenger()
	filter = {onground=true, rangemax=2, graphics=itemsToSearchFor}
	
	list = Items.FindByFilter(filter)
	for index, item in ipairs(list) do
	   -- Messages.Print('Picking up '..item.Name..' at location x:'..item.X..' y:'..item.Y)
	    Player.PickUp(item.Serial, 1000)
	    Pause(100)
	    Player.DropInBackpack()
	    Pause(100)
	end
	-- Important Pause for CPU
	Pause(150)
end

-- Main Loop
while true do
    IsOverweight()
    AutoBandageSelf()
    AutoCure()
    CheckHostileMobs()
    Scavenger()
 
    Pause(150)
end
