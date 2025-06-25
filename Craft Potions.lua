--=====================================
-- Alchemy Assistant Script v0.1.0
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
Messages.Print("Alchemy Assistant Script v0.1.0", INFO)
Messages.Print("Status: Running all functions continuously", STATUS)
Messages.Print("___________________________________", INFO)

-- User Settings
local MORTAR_ID = 0x0E9B        -- Mortar and Pestle item type
local BOTTLE_ID = 0x0F0E        -- Empty Bottle
local REAGENTS = {
    BLACK_PEARL = 0x0F7A,
    BLOOD_MOSS = 0x0F7B,
    GARLIC = 0x0F84,
    GINSENG = 0x0F85,
    MANDRAKE_ROOT = 0x0F86,
    NIGHTSHADE = 0x0F88,
    SPIDERS_SILK = 0x0F8D,
    SULPHUROUS_ASH = 0x0F8C
}
local lastPotionKey = nil

-- Enable potions to craft (set to 1 to enable, 0 to disable)
local POTIONS = {
    -- Refresh
    REFRESH = 0,
    TOTAL_REFRESH = 0,

    -- Agility
    AGILITY = 0,
    GREATER_AGILITY = 0,

    -- Nightsight
    NIGHTSIGHT = 0,

    -- Heals
    LESSER_HEAL = 0,
    HEAL = 0,
    GREATER_HEAL = 0,

    -- Strength
    STRENGTH = 0,
    GREATER_STRENGTH = 0,

    -- Poisons
    LESSER_POISON = 0,
    POISON = 1,
    GREATER_POISON = 0,
    DEADLY_POISON = 0,
    LETHAL_POISON = 0,

    -- Cures
    LESSER_CURE = 0,
    CURE = 0,
    GREATER_CURE = 0,

    -- Explosions
    LESSER_EXPLOSION = 0,
    EXPLOSION = 0,
    GREATER_EXPLOSION = 0,
}

-- Match reagents to potions
local POTION_REAGENTS = {
    REFRESH = { REAGENTS.BLACK_PEARL },
    TOTAL_REFRESH = { REAGENTS.BLACK_PEARL },

    AGILITY = { REAGENTS.BLOOD_MOSS },
    GREATER_AGILITY = { REAGENTS.BLOOD_MOSS },

    NIGHTSIGHT = { REAGENTS.SPIDERS_SILK },

    LESSER_HEAL = { REAGENTS.GINSENG },
    HEAL = { REAGENTS.GINSENG },
    GREATER_HEAL = { REAGENTS.GINSENG },

    STRENGTH = { REAGENTS.MANDRAKE_ROOT },
    GREATER_STRENGTH = { REAGENTS.MANDRAKE_ROOT },

    LESSER_POISON = { REAGENTS.NIGHTSHADE },
    POISON = { REAGENTS.NIGHTSHADE },
    GREATER_POISON = { REAGENTS.NIGHTSHADE },
    DEADLY_POISON = { REAGENTS.NIGHTSHADE },
    LETHAL_POISON = { REAGENTS.NIGHTSHADE },

    LESSER_CURE = { REAGENTS.GARLIC },
    CURE = { REAGENTS.GARLIC },
    GREATER_CURE = { REAGENTS.GARLIC },

    LESSER_EXPLOSION = { REAGENTS.SULPHUROUS_ASH },
    EXPLOSION = { REAGENTS.SULPHUROUS_ASH },
    GREATER_EXPLOSION = { REAGENTS.SULPHUROUS_ASH },
}

-- Gump button mappings (example buttons per category and potion)
local GUMP_ID = 2653346093
local GUMP_BUTTONS = {
    -- Refresh
    REFRESH =         {category = 1, craft = 3, final = 2},
    TOTAL_REFRESH =   {category = 1, craft =10, final = 9},

    -- Agility
    AGILITY =         {category = 8, craft = 3, final = 2},
    GREATER_AGILITY = {category = 8, craft = 10, final = 9},

    -- Nightsight 
    NIGHTSIGHT =      {category = 15, craft = 3, final = 2},

    -- Heals
    LESSER_HEAL =     {category = 23, craft = 3, final = 2},
    HEAL =            {category = 22, craft = 10, final = 9},
    GREATER_HEAL =    {category = 22, craft = 17, final = 16},

    -- Strength
    STRENGTH =        {category = 29, craft = 3, final = 2},
    GREATER_STRENGTH = {category = 29, craft = 10, final = 9},

    -- Poisons
    LESSER_POISON =   {category = 36, craft = 3, final = 2},
    POISON =          {category = 36, craft = 10, final = 9},
    GREATER_POISON =  {category = 36, craft = 17, final = 16},
    DEADLY_POISON =   {category = 36, craft = 24, final = 23},
    LETHAL_POISON =   {category = 36, craft = 31, final = 30},

    -- Cures
    LESSER_CURE =     {category = 43, craft = 3, final = 2},
    CURE =            {category = 43, craft = 10, final = 9},
    GREATER_CURE =    {category = 43, craft = 17, final = 16},

    -- Explosions
    LESSER_EXPLOSION =  {category = 50, craft = 3, final = 2},
    EXPLOSION =         {category = 50, craft = 10, final = 9},
    GREATER_EXPLOSION = {category = 50, craft = 17, final = 16},
}

-- Helper functions
local function FindMortar()
    return Items.FindByType(MORTAR_ID, Player.Backpack)
end

local function HasBottles()
    return Items.FindByType(BOTTLE_ID, Player.Backpack) ~= nil
end

local function CraftPotion(potionKey)
    local mortar = FindMortar()
    if not mortar then
        Messages.Overhead("No Mortar & Pestle!", ALERT, Player.Serial)
        return false
    end

    if not HasBottles() then
        Messages.Overhead("No Bottles!", ALERT, Player.Serial)
        return false
    end

    local buttons = GUMP_BUTTONS[potionKey]
    if not buttons then return false end

    Player.UseObject(mortar.Serial)
    if not Gumps.WaitForGump(GUMP_ID, 1000) then
        Messages.Overhead("Gump failed to open!", ALERT, Player.Serial)
        return false
    end

    -- First time for this potion, navigate the full menu
    if lastPotionKey ~= potionKey then
        Gumps.PressButton(GUMP_ID, buttons.category)
        Pause(750)
        Gumps.PressButton(GUMP_ID, buttons.craft)
        Pause(750)
        Gumps.PressButton(GUMP_ID, buttons.final)
        lastPotionKey = potionKey
    else
        -- Use "Make Last" for repeated crafting
        Pause(500)
        Gumps.PressButton(GUMP_ID, 21)
    end

    Messages.Overhead("Crafting " .. potionKey:gsub("_", " ") .. "!", ACTION, Player.Serial)
    Pause(3000)
    return true
end


-- Main training loop
while true do
    local crafted = false
    for key, enabled in pairs(POTIONS) do
        if enabled == 1 then
            crafted = CraftPotion(key) or crafted
        end
    end
    if not crafted then
        Messages.Overhead("No enabled potions to craft or stopped.", ALERT, Player.Serial)
        break
    end
end
