----------------------------------------------------------------------
-- Auto Dexxer Assistant Script v0.1.3
-- Script created by: 

-- ___   _   _   __  __     ___   _   _   _   _   _   _   ____   ___ 
-- | _ \ | | | | |  \/  |   | _ \ | | | | | \ | | | \ | | |  __| | _ \
-- |   / | |_| | | |\/| |   |   / | |_| | |  \| | |  \| | |  _|  |   /
-- |_|_\  \___/  |_|  |_|   |_|_\  \___/  |_|\__| |_|\__| |____| |_|_\

----------------------------------------------------------------------

-- Define Color Scheme
local Colors = {
    ALERT = 33,
    WARNING = 48,
    CAUTION = 53,
    ACTION = 67,
    CONFIRM = 73,
    INFO = 84,
    STATUS = 93
}

-- Print Initial Start Up Greeting
Messages.Print("___________________________________", Colors.INFO)
Messages.Print("Auto Bandage Assistant Script v0.1.3", Colors.INFO)
Messages.Print("Status: Running all functions continuously", Colors.STATUS)
Messages.Print("___________________________________", Colors.INFO)

-- User Settings
local Config = {
	WeightBuffer           = 25     -- in stones (adjust as needed)
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

-- Library of anamal names - Add more names as needed
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
        Messages.Overhead("Overweight!!!!!", Colors.ALERT, Player.Serial)
        return true     
    elseif Player.Weight >= MaxCharWeight then
        Messages.Overhead("Nearly Overweight", Colors.WARNING, Player.Serial)
        return true    
    end
    return false
end

-- Main Bandage Loop
local function AutoBandagePriority()
    local Bandage = Items.FindByType(3617) -- Find bandages in the player's backpack
    if not Bandage then
        Messages.Overhead("No bandages found!", Colors.ALERT, Player.Serial)
        return
    end

    -- Find party members within 2 tiles
    local partyMembers = Mobiles.FindByFilter({
        range = 2,
        notoriety = 1, -- Friendly
        dead = false,
        human = true
    })

    -- Find pets within 2 tiles
    local pets = Mobiles.FindByFilter({
        range = 2,
        notoriety = 1, -- Friendly
        dead = false,
        human = false
    })

    -- Bandage party members first
    for _, member in ipairs(partyMembers) do
        if member.Hits < member.HitsMax then
            Journal.Clear()
            Player.UseObject(Bandage.Serial)
            if Targeting.WaitForTarget(1000) then
                Targeting.TargetObject(member.Serial)

                -- Dynamic color based on health
                local color = Colors.ACTION
                if member.Hits < member.HitsMax * 0.25 then
                    color = Colors.ALERT -- Critical health
                elseif member.Hits < member.HitsMax * 0.75 then
                    color = Colors.WARNING -- Moderate health
                end

                Messages.Overhead("Bandaging party member: " .. member.Name .. " (" .. member.Hits .. "/" .. member.HitsMax .. " HP)", color, Player.Serial)

                -- Overhead timer logic
                local elapsed = 0
                while elapsed < Config.BandageTimeout do
                    local remainingTime = math.ceil((Config.BandageTimeout - elapsed) / 1000)
                    Messages.Overhead("Bandaging " .. member.Name .. " (" .. remainingTime .. "s remaining)", Colors.ACTION, Player.Serial)
                    Pause(1000) -- Wait for 1 second
                    elapsed = elapsed + 1000

                    -- Check journal for success or failure
                    if Journal.Contains("You finish applying the bandages") then
                        Messages.Overhead("Successfully bandaged " .. member.Name, Colors.CONFIRM, Player.Serial)
                        return
                    elseif Journal.Contains("You apply the bandages, but they barely help.") then
                        Messages.Overhead("Bandaged " .. member.Name .. " (partial healing)", Colors.WARNING, Player.Serial)
                        return
                    elseif Journal.Contains("You have failed to cure your target.") then
                        Messages.Overhead("Failed to bandage " .. member.Name, Colors.ALERT, Player.Serial)
                        return
                    end
                end

                -- Timeout message
                Messages.Overhead("Bandaging timed out for " .. member.Name, Colors.ALERT, Player.Serial)
                return
            end
        end
    end

    -- Bandage pets next
    for _, pet in ipairs(pets) do
        if pet.Hits < pet.HitsMax then
            Journal.Clear()
            Player.UseObject(Bandage.Serial)
            if Targeting.WaitForTarget(1000) then
                Targeting.TargetObject(pet.Serial)

                -- Dynamic color based on health
                local color = Colors.ACTION
                if pet.Hits < pet.HitsMax * 0.25 then
                    color = Colors.ALERT -- Critical health
                elseif pet.Hits < pet.HitsMax * 0.75 then
                    color = Colors.WARNING -- Moderate health
                end

                Messages.Overhead("Bandaging pet: " .. pet.Name .. " (" .. pet.Hits .. "/" .. pet.HitsMax .. " HP)", color, Player.Serial)

                -- Overhead timer logic
                local elapsed = 0
                while elapsed < Config.BandageTimeout do
                    local remainingTime = math.ceil((Config.BandageTimeout - elapsed) / 1000)
                    Messages.Overhead("Bandaging " .. pet.Name .. " (" .. remainingTime .. "s remaining)", Colors.ACTION, Player.Serial)
                    Pause(1000) -- Wait for 1 second
                    elapsed = elapsed + 1000

                    -- Check journal for success or failure
                    if Journal.Contains("You finish applying the bandages") then
                        Messages.Overhead("Successfully bandaged " .. pet.Name, Colors.CONFIRM, Player.Serial)
                        return
                    elseif Journal.Contains("You apply the bandages, but they barely help.") then
                        Messages.Overhead("Bandaged " .. pet.Name .. " (partial healing)", Colors.WARNING, Player.Serial)
                        return
                    elseif Journal.Contains("You have failed to cure your target.") then
                        Messages.Overhead("Failed to bandage " .. pet.Name, Colors.ALERT, Player.Serial)
                        return
                    end
                end

                -- Timeout message
                Messages.Overhead("Bandaging timed out for " .. pet.Name, Colors.ALERT, Player.Serial)
                return
            end
        end
    end

    -- Bandage self if no party members or pets need healing
    if Player.Hits < Player.HitsMax then
        Journal.Clear()
        Player.UseObject(Bandage.Serial)
        if Targeting.WaitForTarget(1000) then
            Targeting.TargetSelf()
            Messages.Overhead("Bandaging self (" .. Player.Hits .. "/" .. Player.HitsMax .. " HP)", Colors.ACTION, Player.Serial)

            -- Overhead timer logic
            local elapsed = 0
            while elapsed < Config.BandageTimeout do
                local remainingTime = math.ceil((Config.BandageTimeout - elapsed) / 1000)
                Messages.Overhead("Bandaging self (" .. remainingTime .. "s remaining)", Colors.ACTION, Player.Serial)
                Pause(1000) -- Wait for 1 second
                elapsed = elapsed + 1000

                -- Check journal for success or failure
                if Journal.Contains("You finish applying the bandages") then
                    Messages.Overhead("Successfully bandaged self", Colors.CONFIRM, Player.Serial)
                    return
                elseif Journal.Contains("You apply the bandages, but they barely help.") then
                    Messages.Overhead("Bandaged self (partial healing)", Colors.WARNING, Player.Serial)
                    return
                elseif Journal.Contains("You have failed to cure your target.") then
                    Messages.Overhead("Failed to bandage self", Colors.ALERT, Player.Serial)
                    return
                end
            end

            -- Timeout message
            Messages.Overhead("Bandaging timed out for self", Colors.ALERT, Player.Serial)
        end
    end
end

    -- Bandage pets next
    for _, pet in ipairs(pets) do
        if pet.Hits < pet.HitsMax then
            Journal.Clear()
            Player.UseObject(Bandage.Serial)
            if Targeting.WaitForTarget(1000) then
                Targeting.TargetObject(pet.Serial)

                -- Dynamic color based on health
                local color = Colors.ACTION
                if pet.Hits < pet.HitsMax * 0.25 then
                    color = Colors.ALERT -- Critical health
                elseif pet.Hits < pet.HitsMax * 0.75 then
                    color = Colors.WARNING -- Moderate health
                end

                Messages.Overhead("Bandaging pet: " .. pet.Name .. " (" .. pet.Hits .. "/" .. pet.HitsMax .. " HP)", color, Player.Serial)
                Pause(Config.BandageInterval)

                -- Check journal for success or failure
                if Journal.Contains("You finish applying the bandages") then
                    Messages.Overhead("Successfully bandaged " .. pet.Name, Colors.CONFIRM, Player.Serial)
                elseif Journal.Contains("You apply the bandages, but they barely help.") then
                    Messages.Overhead("Bandaged " .. pet.Name .. " (partial healing)", Colors.WARNING, Player.Serial)
                elseif Journal.Contains("You have failed to cure your target.") then
                    Messages.Overhead("Failed to bandage " .. pet.Name, Colors.ALERT, Player.Serial)
                end

                return -- Exit after bandaging one pet
            end
        end
    end

    -- Bandage self if no party members or pets need healing
    if Player.Hits < Player.HitsMax then
        Journal.Clear()
        Player.UseObject(Bandage.Serial)
        if Targeting.WaitForTarget(1000) then
            Targeting.TargetSelf()
            Messages.Overhead("Bandaging self (" .. Player.Hits .. "/" .. Player.HitsMax .. " HP)", Colors.ACTION, Player.Serial)
            Pause(Config.BandageInterval)

            -- Check journal for success or failure
            if Journal.Contains("You finish applying the bandages") then
                Messages.Overhead("Successfully bandaged self", Colors.CONFIRM, Player.Serial)
            elseif Journal.Contains("You apply the bandages, but they barely help.") then
                Messages.Overhead("Bandaged self (partial healing)", Colors.WARNING, Player.Serial)
            elseif Journal.Contains("You have failed to cure your target.") then
                Messages.Overhead("Failed to bandage self", Colors.ALERT, Player.Serial)
            end
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
    local filter = {onground=true, rangemax=2, graphics=itemsToSearchFor}
    local list = Items.FindByFilter(filter)
    for index, item in ipairs(list) do
        Messages.Print('Picking up '..item.Name..' at location x:'..item.X..' y:'..item.Y)
        Player.PickUp(item.Serial, 1000)
        Pause(100)
        Player.DropInBackpack()
        Pause(100)
    end
    Pause(150) -- Important Pause for CPU
end

-- Logging function used for debugging
local function Log(message, level)
    Messages.Print(message, level or Colors.INFO)
end

Log("Script started!", Colors.STATUS)
Log("Bandaging party member: John", Colors.ACTION)

-- Dynamic pause based on run time
local function DynamicPause(startTime)
    local elapsed = os.clock() - startTime
    local pauseTime = math.max(250 - elapsed * 1000, 0)
    Pause(pauseTime)
end

-- Loop these functions
while true do
    local startTime = os.clock()
    IsOverweight()
    AutoBandagePriority()
    AutoCure()
    CheckHostileMobs()
    Scavenger()
    DynamicPause(startTime)
end
