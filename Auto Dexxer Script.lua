--=====================================
-- Auto Dexxer Assistant Script v0.1.3
-- By: Rum Runner
--=====================================

-- Define Color Scheme
local ALERT   = 33       -- Red
local WARNING = 48       -- Orange
local CAUTION = 53       -- Yellow
local ACTION  = 67       -- Green
local CONFIRM = 73       -- Light Green
local INFO    = 84       -- Light Blue
local STATUS  = 93       -- Blue

-- Print Initial Start Up Greeting
Messages.Print("___________________________________", INFO)
Messages.Print("Auto Bandage Assistant Script v0.1.3", INFO)
Messages.Print("Status: Running all functions continuously", STATUS)
Messages.Print("___________________________________", INFO)

-- User Settings
local WeightBuffer           = 25     -- in stones
local LastFullHealthMessage  = 0
local LastBandageMessage     = 0
local LastBandagingMessage   = 0
local FullHealthCooldown     = 10     -- in seconds
local NoBandageCooldown      = 6      -- in seconds
local BandagingCooldown      = 6      -- in seconds
local BandageTimeout         = 20000  -- in milliseconds
local BandageInterval        = 100    -- in milliseconds
local CureCooldown           = 2      -- in seconds
local LastCureTime           = 0
local LastHostileMessageTime = 0
local HostileMessageCooldown = 4      -- in seconds

-- Items to Scavenger
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

-- Check Weight
local function GetWeightLimit()
    return Player.MaxWeight - WeightBuffer
end

local function IsOverweight()
    local MaxCharWeight = GetWeightLimit()
    if Player.Weight >= MaxCharWeight + WeightBuffer then
        Messages.Overhead("Overweight!!!!!", ALERT, Player.Serial)
        return true     
     elseif Player.Weight >= MaxCharWeight then
        Messages.Overhead("Nearly Overweight", WARNING, Player.Serial)
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
                if now - LastBandagingMessage >= BandagingCooldown then
                    Messages.Overhead("Bandaging", ACTION, Player.Serial)
                    LastBandagingMessage = now
                    local elapsed = 0
                    local result = nil
                    while elapsed < BandageTimeout do
                        if Journal.Contains("You finish applying the bandages") then
                            result = "full"
                            Messages.Overhead("Bandage complete!", CONFIRM, Player.Serial)
                            break
                        elseif Journal.Contains("You apply the bandages, but they barely help.") then
                            result = "partial"
                            Messages.Overhead("Bandage barely helped", WARNING, Player.Serial)
                            break
                        elseif Journal.Contains("You have failed to cure your target.") then
                            result = "partial"
                            Messages.Overhead("Bandage Failed", ALERT, Player.Serial)
                            break
                        end
                        Pause(BandageInterval)
                        elapsed = elapsed + BandageInterval
                    end

                    if not result then
                        Messages.Overhead("Bandage timed out", ALERT, Player.Serial)
                    end
                end
            end
        else
            local now = os.clock()
            if now - LastBandageMessage >= NoBandageCooldown then
                Messages.Overhead("No bandages found!", ALERT, Player.Serial)
                LastBandageMessage = now
            end
        end
    else
        local now = os.clock()
        if now - LastFullHealthMessage >= FullHealthCooldown then
            Messages.Overhead("Full Health", INFO)
            LastFullHealthMessage = now
        end
    end
end

-- Cure Poison
local function AutoCure()
    local now = os.clock()
    if now - LastCureTime < CureCooldown then return end

    if Journal.Contains("You feel a bit nauseous") then
        local CurePotion = Items.FindByType(3847, Player.Backpack)
        if CurePotion then
            Player.UseObject(CurePotion.Serial)
            Messages.Overhead("Curing Poison", ACTION, Player.Serial)
            LastCureTime = now
            Journal.Clear()
        else
            Messages.Overhead("No Cure Potion Found!", ALERT, Player.Serial)
            LastCureTime = now
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
                if now - LastHostileMessageTime >= HostileMessageCooldown then
                    Messages.Overhead("Hostile!", ALERT, mob.Serial)
                    LastHostileMessageTime = now
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
	    Messages.Print('Picking up '..item.Name..' at location x:'..item.X..' y:'..item.Y)
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
    IdentifyAnimal(mob)
    CheckHostileMobs()
    Scavenger()
 
    Pause(250)
end
