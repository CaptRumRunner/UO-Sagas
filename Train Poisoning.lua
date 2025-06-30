----------------------------------------------------------------------
-- Train Poisoning Assistant Script v0.1.1
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
    Status  = 93		-- Blue
}

-- Print Initial Start Up Greeting
Messages.Print("___________________________________", Colors.Info)
Messages.Print("Train Poisoning Assistant Script Running", Colors.Info)
Messages.Print("___________________________________", Colors.Info)

-- User Settings
local Config = {
    POISON_SKILL   = "Poisoning",
    COOLDOWN 	   = 10000,           -- Wait time between uses (ms)
	TARGET_TIMEOUT = 2000  			 -- Max wait for targeting
}	

-- Define Important Items to Track
local ImportantGear = {
    CURE_POTION_ID = 0x0F07  -- Cure potion 
}

------------- Main script is below, do not make changes below this line -------------

-- Use a cure potion if poisoned
local function CheckAndCurePoison()
    if Journal.Contains("* You feel a bit nauseous! *") or Journal.Contains("* You feel disoriented and nauseous! *") then
        local cure = Items.FindByType(ImportantGear.CURE_POTION_ID, Player.Backpack)
        if cure then
            Messages.Overhead("Poisoned! Drinking cure...", Colors.Alert, Player.Serial)
            Player.UseObject(cure.Serial)
            Pause(1000)
            Journal.Clear()
            return true
        else
            Messages.Overhead("Poisoned and no Cure Potion!", Colors.Alert, Player.Serial)
        end
    end
    return false
end

-- Main Loop
while true do
    CheckAndCurePoison()
    poison = Items.FindByType(3850)   -- Poison
    kryss = Items.FindByType(5121)    -- Kryss

    if not poison then
        Messages.Overhead("No Poison found!", Colors.Alert, Player.Serial)
        break
    end

    if not kryss then
        Messages.Overhead("No Kryss found!", Colors.Alert, Player.Serial)
        break
    end

    Journal.Clear()
    Skills.Use(Config.POISON_SKILL)

    -- Target the poison potion
    if Targeting.WaitForTarget(Config.TARGET_TIMEOUT) then
        Targeting.Target(poison.Serial)
    else
        Messages.Overhead("Failed to target poison!", Colors.Alert, Player.Serial)
        Pause(Config.COOLDOWN)
        goto continue
    end

    -- Target the kryss
    if Targeting.WaitForTarget(Config.TARGET_TIMEOUT) then
        Targeting.Target(kryss.Serial)
        Messages.Overhead("Applying poison to Kryss...", Colors.Action, Player.Serial)
    else
        Messages.Overhead("Failed to target Kryss!", Colors.Alert, Player.Serial)
    end

    ::continue::
    CheckAndCurePoison()
    Pause(Config.COOLDOWN)
end