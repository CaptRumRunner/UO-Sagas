--[[ 
--------------------------------------------------------------------
Train Inscription Assistant Script
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
Dynamically crafts Recall, level 7, or level 8 spells.
--------------------------------------------------------------------
Script Notes:
1) Ensure you have a Scribe's Pen, blank scrolls and regs in your backpack.
2) Script does not restock from a bank (yet)
3) Users can enable specific level 7 or level 8 spells to craft so you
can make what you want or keep switching spells so you have some of each.
4) Please select one spell at a time. Update that below, save script and run.
5) No need to select a spell until you get to 65 as you will only craft recall.
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
Messages.Print("_________________________________________", Colors.Info)
Messages.Print("Welcome to the Train Inscription Assistant Script!", Colors.Info)
Messages.Print("Booting up... Initializing systems... ", Colors.Info)
Messages.Print("_________________________________________", Colors.Info)

-- User Settings (Feel free to edit this section as needed)
local Config = {
    GUMP_ID = 2653346093,       -- Gump ID for Inscription (change if different)
    MAKE_LAST_BUTTON_ID = 21    -- Button ID for "Make Last"
}

-- Define Important Items to Track
local ImportantGear = {
    TOOL_ID = 0x0FBF,           -- Scribe's Pen
    SCROLL_ID = 0x0EF3          -- Blank Scroll
}

-- User Configuration: Enable specific level 7 and level 8 spells to craft
local SPELLS_ENABLED = {
    -- Level 7 Spells
    CHAIN_LIGHTNING       = 0,         -- Enable crafting Chain Lightning (1 to enable, 0 to disable)
    ENERGY_FIELD          = 0,         -- Enable crafting Energy Field
    FLAME_STRIKE          = 0,         -- Enable crafting Flame Strike
    GATE_TRAVEL           = 0,         -- Enable crafting Gate Travel
    MANA_VAMPIRE          = 0,         -- Enable crafting Mana Vampire
    MASS_DISPEL           = 0,         -- Enable crafting Mass Dispel
    METEOR_SWARM          = 0,         -- Enable crafting Meteor Swarm
    POLYMORPH             = 0,         -- Enable crafting Polymorph

    -- Level 8 Spells
    EARTHQUAKE            = 0,         -- Enable crafting Earthquake
    ENERGY_VORTEX         = 0,         -- Enable crafting Energy Vortex
    RESURRECTION          = 0,         -- Enable crafting Resurrection
    AIR_ELEMENTAL         = 0,         -- Enable crafting Air Elemental
    SUMMON_DAEMON         = 0,         -- Enable crafting Summon Daemon
    EARTH_ELEMENTAL       = 0,         -- Enable crafting Earth Elemental
    FIRE_ELEMENTAL        = 0,         -- Enable crafting Fire Elemental
    WATER_ELEMENTAL       = 0          -- Enable crafting Water Elemental
}

local GUMP_BUTTONS = {
    -- Level 4 Spell
    RECALL =                {name = "Recall", category = 22, craft = 52, final = 2},

    -- Level 7 Spells
    CHAIN_LIGHTNING =       {name = "Chain Lightning", category = 57, craft = 3, final = 2},
    ENERGY_FIELD =          {name = "Energy Field", category = 57, craft = 10, final = 9},
    FLAME_STRIKE =          {name = "Flame Strike", category = 57, craft = 17, final = 16},
    GATE_TRAVEL =           {name = "Gate Travel", category = 57, craft = 24, final = 23},
    MANA_VAMPIRE =          {name = "Mana Vampire", category = 57, craft = 31, final = 30},
    MASS_DISPEL =           {name = "Mass Dispel", category = 57, craft = 38, final = 37},
    METEOR_SWARM =          {name = "Meteor Swarm", category = 57, craft = 45, final = 44},
    POLYMORPH =             {name = "Polymorph", category = 57, craft = 52, final = 51},

    -- Level 8 Spells
    EARTHQUAKE =            {name = "Earthquake", category = 64, craft = 3, final = 2},
    ENERGY_VORTEX =         {name = "Energy Vortex", category = 64, craft = 10, final = 9},
    RESURRECTION =          {name = "Resurrection", category = 64, craft = 17, final = 16},
    AIR_ELEMENTAL =         {name = "Air Elemental", category = 64, craft = 24, final = 23},
    SUMMON_DAEMON =         {name = "Summon Daemon", category = 64, craft = 31, final = 30},
    EARTH_ELEMENTAL =       {name = "Earth Elemental", category = 64, craft = 38, final = 37},
    FIRE_ELEMENTAL =        {name = "Fire Elemental", category = 64, craft = 45, final = 44},
    WATER_ELEMENTAL =       {name = "Water Elemental", category = 64, craft = 52, final = 51}
}

------------- Main script is below, do not make changes below this line -------------

-- Helper Functions
local function CheckImportantGear()
    local pen = Items.FindByType(ImportantGear.TOOL_ID, Player.Backpack)
    local scrolls = Items.FindByType(ImportantGear.SCROLL_ID, Player.Backpack)

    if not pen then
        Messages.Overhead("No Scribe's Pen found in backpack!", Colors.Alert, Player.Serial)
        return false
    end

    if not scrolls or scrolls.Amount < 1 then
        Messages.Overhead("No Blank Scrolls found in backpack!", Colors.Alert, Player.Serial)
        return false
    end

    return true
end

local function GetSkill()
    local skill = Skills.GetValue("Inscription")
    return tonumber(string.format("%.1f", skill))
end

-- Main Crafting Function
local lastItem = nil
local function CraftScroll()
    -- Check for sufficient mana
    if Player.Mana < 40 then
        Messages.Overhead("Not enough mana! Meditating...", Colors.Warning, Player.Serial)
        Skills.Use("Meditation")
        Pause(25000)
    end

    -- Check for important gear
    if not CheckImportantGear() then
        return false
    end

    local skill = GetSkill()
    local scroll = nil

    -- Determine which scrolls or spells to craft based on skill level
    if skill >= 20.0 and skill < 65.0 then
        scroll = GUMP_BUTTONS.RECALL -- Recall scroll
    elseif skill >= 65.0 and skill <= 85.0 then
        for spellName, enabled in pairs(SPELLS_ENABLED) do
            if enabled == 1 and GUMP_BUTTONS[spellName] then
                scroll = GUMP_BUTTONS[spellName]
                break
            end
        end
    elseif skill > 85.0 and skill < 100.0 then
        for spellName, enabled in pairs(SPELLS_ENABLED) do
            if enabled == 1 and GUMP_BUTTONS[spellName] then
                scroll = GUMP_BUTTONS[spellName]
                break
            end
        end
    elseif skill == 100.0 then
        Messages.Overhead("Inscription skill has reached 100.0! Script ending.", Colors.Confirm, Player.Serial)
        return false    
    else
        Messages.Overhead("Skill too low to craft Recall, level 7, or level 8 spells!", Colors.Alert, Player.Serial)
        return false
    end

    if not scroll then
        Messages.Overhead("No enabled spell matches current skill level!", Colors.Alert, Player.Serial)
        return false
    end

    Player.UseObject(Items.FindByType(ImportantGear.TOOL_ID, Player.Backpack).Serial)
    if not Gumps.WaitForGump(Config.GUMP_ID, 1000) then
        Messages.Overhead("Failed to open Inscription menu!", Colors.Alert, Player.Serial)
        return false
    end

    if lastItem ~= scroll.name then
        Gumps.PressButton(Config.GUMP_ID, scroll.category)
        Pause(600)
        Gumps.PressButton(Config.GUMP_ID, scroll.craft)
        Pause(600)
        lastItem = scroll.name
    else
        Pause(600)
        Gumps.PressButton(Config.GUMP_ID, Config.MAKE_LAST_BUTTON_ID)
    end

    Messages.Overhead("Scribing: " .. scroll.name, Colors.Action, Player.Serial)
    Pause(4000)
    return true
end

-- Main Loop
while true do
    local crafted = CraftScroll()
    if not crafted then break end
end
