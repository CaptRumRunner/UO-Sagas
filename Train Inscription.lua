--[[ 
--------------------------------------------------------------------
Train Inscription Assistant Script
--------------------------------------------------------------------
Version History:
v1.0.0 - Initial release
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
Dynamically crafts spells based on skill ranges. Can be used for crafting
even when gaining skill is not a priority.
--------------------------------------------------------------------
Script Notes:
1) Ensure you have a Scribes Pen, blank scrolls and regs in your backpack.
2) Script does not restock from a bank
3) Users can enable specific level spells to craft so you can make what 
you want or keep switching spells so you have some of each.
4) Please select one spell at a time. Update spell below, save script and run.
5) No need to select a spell until you get to 65 as you will only craft recall.
--------------------------------------------------------------------
]]

-- Color Scheme
local Colors = {
    Alert   = 33,  -- Red
    Warning = 48,  -- Orange
    Caution = 53,  -- Yellow
    Action  = 67,  -- Green
    Confirm = 73,  -- Light Green
    Info    = 84,  -- Light Blue
    Status  = 93   -- Blue
}

-- Start Message
Messages.Print("___________________________________", Colors.Info)
Messages.Print("Welcome to the Train Inscription Assistant Script!", Colors.Info)
Messages.Print("Booting up... Initializing systems... ", Colors.Info)
Messages.Print("___________________________________", Colors.Info)

-- Config
local Config = {
    GUMP_ID = 2653346093,
    MAKE_LAST_BUTTON_ID = 21,
    lastSpellKey = nil
}

-- Items
local ImportantGear = {
    TOOL_ID   = 0x0FBF,  -- Scribe's Pen
    SCROLL_ID = 0x0EF3   -- Blank Scroll
}

-- Spells to Enable
local SPELLS_ENABLED = {
    -- Level 6
    MARK                  = 1,         -- Enable crafting Mark (1 to enable, 0 to disable)
 
    -- Level 7 Spells 
    CHAIN_LIGHTNING       = 0,         -- Enable crafting Chain Lightning
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

-- Gump Buttons
local GUMP_BUTTONS = {
    -- Level 4
    RECALL          = {name = "Recall", category = 22, craft = 52, final = 51},

    -- Level 6
    MARK            = {name = "Mark", category = 36, craft = 31, final = 30},
    
    -- Level 7
    CHAIN_LIGHTNING = {name = "Chain Lightning", category = 43, craft = 3, final = 2},
    ENERGY_FIELD    = {name = "Energy Field", category = 43, craft = 10, final = 9},
    FLAME_STRIKE    = {name = "Flame Strike", category = 43, craft = 17, final = 16},
    GATE_TRAVEL     = {name = "Gate Travel", category = 43, craft = 24, final = 23},
    MANA_VAMPIRE    = {name = "Mana Vampire", category = 43, craft = 31, final = 30},
    MASS_DISPEL     = {name = "Mass Dispel", category = 43, craft = 38, final = 37},
    METEOR_SWARM    = {name = "Meteor Swarm", category = 43, craft = 45, final = 44},
    POLYMORPH       = {name = "Polymorph", category = 43, craft = 52, final = 51},

    -- Level 8
    EARTHQUAKE      = {name = "Earthquake", category = 50, craft = 3, final = 2},
    ENERGY_VORTEX   = {name = "Energy Vortex", category = 50, craft = 10, final = 9},
    RESURRECTION    = {name = "Resurrection", category = 50, craft = 17, final = 16},
    AIR_ELEMENTAL   = {name = "Air Elemental", category = 50, craft = 24, final = 23},
    SUMMON_DAEMON   = {name = "Summon Daemon", category = 50, craft = 31, final = 30},
    EARTH_ELEMENTAL = {name = "Earth Elemental", category = 50, craft = 38, final = 37},
    FIRE_ELEMENTAL  = {name = "Fire Elemental", category = 50, craft = 45, final = 44},
    WATER_ELEMENTAL = {name = "Water Elemental", category = 50, craft = 52, final = 51}
}

-- Helper: Gear check
local function CheckImportantGear()
    local pen = Items.FindByType(ImportantGear.TOOL_ID, Player.Backpack)
    local scrolls = Items.FindByType(ImportantGear.SCROLL_ID, Player.Backpack)

    if not pen then
        Messages.Overhead("No Scribe's Pen found!", Colors.Alert, Player.Serial)
        return false
    end

    if not scrolls or scrolls.Amount < 1 then
        Messages.Overhead("No Blank Scrolls!", Colors.Alert, Player.Serial)
        return false
    end

    return true
end

-- Helper: Skill
local function GetSkill()
    return tonumber(string.format("%.1f", Skills.GetValue("Inscription")))
end

-- Crafting
local function CraftScroll()
    -- Mana check
    if Player.Mana < 40 then
        Messages.Overhead("Not enough mana! Meditating...", Colors.Warning, Player.Serial)
        Skills.Use("Meditation")
        Pause(25000)
    end

    -- Gear check
    if not CheckImportantGear() then return false end

    local skill = GetSkill()
    local scroll = nil
    local selectedKey = nil

    if skill < 20.0 then
        Messages.Overhead("Skill too low - Please visit a NPC and buy Inscription.", Colors.Alert, Player.Serial)
        return false
    elseif skill >= 20.0 and skill < 65.0 then
        scroll = GUMP_BUTTONS.RECALL
        selectedKey = "RECALL"
    elseif skill >= 65.0 and skill < 100.0 then
        for spellName, enabled in pairs(SPELLS_ENABLED) do
            if enabled == 1 and GUMP_BUTTONS[spellName] then
                -- Check if it's a Level 8 spell and block it if skill is under 75
                local isLevel8 = GUMP_BUTTONS[spellName].category == 50
                if isLevel8 and skill < 75.0 then
                    Messages.Overhead("Skill is not high enough for level 8", Colors.Warning, Player.Serial)
                    -- Skip level 8 spell until skill is 75.0+
                else
                    scroll = GUMP_BUTTONS[spellName]
                    selectedKey = spellName
                    break
                end
            end
        end
    else
        Messages.Overhead("Skill too low to craft scrolls!", Colors.Alert, Player.Serial)
        return false
    end

    if not scroll then
        Config.lastSpellKey = nil
        Messages.Overhead("No spell enabled for this skill level!", Colors.Alert, Player.Serial)
        return false
    end

    Player.UseObject(Items.FindByType(ImportantGear.TOOL_ID, Player.Backpack).Serial)
    if not Gumps.WaitForGump(Config.GUMP_ID, 1000) then
        Messages.Overhead("Failed to open Inscription menu!", Colors.Alert, Player.Serial)
        return false
    end

    -- Navigate menu or make last
    if Config.lastSpellKey ~= selectedKey then
        Gumps.PressButton(Config.GUMP_ID, scroll.category)
        Pause(750)
        Gumps.PressButton(Config.GUMP_ID, scroll.craft)
        Pause(750)
        Gumps.PressButton(Config.GUMP_ID, scroll.final)
        Config.lastSpellKey = selectedKey
    else
        Pause(500)
        Gumps.PressButton(Config.GUMP_ID, Config.MAKE_LAST_BUTTON_ID)
    end

    Messages.Overhead("Scribing: " .. scroll.name, Colors.Action, Player.Serial)
    Pause(3000)
    return true
end

-- Loop
while true do
    if not CraftScroll() then break end
end
