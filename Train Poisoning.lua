----------------------------------------------------------------------
-- Train Poisoning Assistant Script v0.1.0
-- Script created by: 

--  ___   _   _   __  __     ___   _   _   _   _   _   _   ____   ___ 
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

local POISON_SKILL = "Poisoning"
local COOLDOWN = 10000         -- Wait time between uses (ms)
local TARGET_TIMEOUT = 2000   -- Max wait for targeting
local CURE_POTION_ID = 0x0F07  -- Cure potion (adjust if using Greater Cure, etc.)

-- Helper: Use a cure potion if poisoned
local function CheckAndCurePoison()
    if Journal.Contains("* You feel a bit nauseous! *") or Journal.Contains("* You feel disoriented and nauseous! *") then
        local cure = Items.FindByType(CURE_POTION_ID, Player.Backpack)
        if cure then
            Messages.Overhead("Poisoned! Drinking cure...", Colors.ALERT, Player.Serial)
            Player.UseObject(cure.Serial)
            Pause(1000)
            Journal.Clear()
            return true
        else
            Messages.Overhead("Poisoned and no Cure Potion!", Colors.ALERT, Player.Serial)
        end
    end
    return false
end

-- Main Loop
while true do
    CheckAndCurePoison()
    local poison = Items.FindByType(3850)   -- Poison
    local kryss = Items.FindByType(5121)    -- Kryss

    if not poison then
        Messages.Overhead("No Poison found!", Colors.ALERT, Player.Serial)
        break
    end

    if not kryss then
        Messages.Overhead("No Kryss found!", Colors.ALERT, Player.Serial)
        break
    end

    Journal.Clear()
    Skills.Use(POISON_SKILL)

    -- Target the poison potion
    if Targeting.WaitForTarget(TARGET_TIMEOUT) then
        Targeting.Target(poison.Serial)
    else
        Messages.Overhead("Failed to target poison!", Colors.ALERT, Player.Serial)
        Pause(COOLDOWN)
        goto continue
    end

    -- Target the kryss
    if Targeting.WaitForTarget(TARGET_TIMEOUT) then
        Targeting.Target(kryss.Serial)
        Messages.Overhead("Applying poison to Kryss...", Colors.ACTION, Player.Serial)
    else
        Messages.Overhead("Failed to target Kryss!", Colors.ALERT, Player.Serial)
    end

    ::continue::
    CheckAndCurePoison()
    Pause(COOLDOWN)
end
