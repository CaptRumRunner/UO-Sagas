----------------------------------------------------------------------
-- Alchemy Assistant Script v0.2.0
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
Messages.Print("Alchemy Assistant Script Running", Colors.Info)
Messages.Print("___________________________________", Colors.Info)

-- User Settings
local Config = {
    GUMP_ID       = 2653346093,
    lastPotionKey = nil
}	

-- Define Important Items to Track
local ImportantGear = {
    MORTAR_ID      = 0x0E9B,        -- Mortar and Pestle tool
    BOTTLE_ID      = 0x0F0E,        -- Empty Bottle
}

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

----------------------------- Main script is below, do not make changes below this line -----------------------------

-- Match reagent type and quantity to each potion
local POTION_REAGENTS = {
    REFRESH =           { {ID = REAGENTS.BLACK_PEARL,    Quantity = 1} },
    TOTAL_REFRESH =     { {ID = REAGENTS.BLACK_PEARL,    Quantity = 2} },
    AGILITY =           { {ID = REAGENTS.BLOOD_MOSS,     Quantity = 1} },
    GREATER_AGILITY =   { {ID = REAGENTS.BLOOD_MOSS,     Quantity = 2} },
    NIGHTSIGHT =        { {ID = REAGENTS.SPIDERS_SILK,   Quantity = 1} },
    LESSER_HEAL =       { {ID = REAGENTS.GINSENG,        Quantity = 1} },
    HEAL =              { {ID = REAGENTS.GINSENG,        Quantity = 2} },
    GREATER_HEAL =      { {ID = REAGENTS.GINSENG,        Quantity = 3} },
    STRENGTH =          { {ID = REAGENTS.MANDRAKE_ROOT,  Quantity = 1} },
    GREATER_STRENGTH =  { {ID = REAGENTS.MANDRAKE_ROOT,  Quantity = 2} },
    LESSER_POISON =     { {ID = REAGENTS.NIGHTSHADE,     Quantity = 1} },
    POISON =            { {ID = REAGENTS.NIGHTSHADE,     Quantity = 2} },
    GREATER_POISON =    { {ID = REAGENTS.NIGHTSHADE,     Quantity = 3} },
    DEADLY_POISON =     { {ID = REAGENTS.NIGHTSHADE,     Quantity = 4} },
    LETHAL_POISON =     { {ID = REAGENTS.NIGHTSHADE,     Quantity = 5} },
    LESSER_CURE =       { {ID = REAGENTS.GARLIC,         Quantity = 1} },
    CURE =              { {ID = REAGENTS.GARLIC,         Quantity = 2} },
    GREATER_CURE =      { {ID = REAGENTS.GARLIC,         Quantity = 3} },
    LESSER_EXPLOSION =  { {ID = REAGENTS.SULPHUROUS_ASH, Quantity = 1} },
    EXPLOSION =         { {ID = REAGENTS.SULPHUROUS_ASH, Quantity = 2} },
    GREATER_EXPLOSION = { {ID = REAGENTS.SULPHUROUS_ASH, Quantity = 3} },
}

-- Gump button mappings for each potion
local GUMP_BUTTONS = {
    -- Refresh
    REFRESH =           {category = 1, craft = 3, final = 2},
    TOTAL_REFRESH =     {category = 1, craft =10, final = 9},
    -- Agility
    AGILITY =           {category = 8, craft = 3, final = 2},
    GREATER_AGILITY =   {category = 8, craft = 10, final = 9},
    -- Nightsight 
    NIGHTSIGHT =        {category = 15, craft = 3, final = 2},
    -- Heals
    LESSER_HEAL =       {category = 23, craft = 3, final = 2},
    HEAL =              {category = 22, craft = 10, final = 9},
    GREATER_HEAL =      {category = 22, craft = 17, final = 16},
    -- Strength
    STRENGTH =          {category = 29, craft = 3, final = 2},
    GREATER_STRENGTH =  {category = 29, craft = 10, final = 9},
    -- Poisons
    LESSER_POISON =     {category = 36, craft = 3, final = 2},
    POISON =            {category = 36, craft = 10, final = 9},
    GREATER_POISON =    {category = 36, craft = 17, final = 16},
    DEADLY_POISON =     {category = 36, craft = 24, final = 23},
    LETHAL_POISON =     {category = 36, craft = 31, final = 30},
    -- Cures
    LESSER_CURE =       {category = 43, craft = 3, final = 2},
    CURE =              {category = 43, craft = 10, final = 9},
    GREATER_CURE =      {category = 43, craft = 17, final = 16},
    -- Explosions
    LESSER_EXPLOSION =  {category = 50, craft = 3, final = 2},
    EXPLOSION =         {category = 50, craft = 10, final = 9},
    GREATER_EXPLOSION = {category = 50, craft = 17, final = 16},
}

-- Find alchemy items
local function FindMortar()
    return Items.FindByType(ImportantGear.MORTAR_ID, Player.Backpack)
end

local function FindBottles()
    return Items.FindByType(ImportantGear.BOTTLE_ID, Player.Backpack)
end

local function FindReagents(reagents)
    for _, reagent in ipairs(reagents) do
        local foundItems = Items.FindByType(reagent.ID, Player.Backpack)
        local totalQuantity = 0

        if foundItems then
            for _, item in ipairs(foundItems) do
                totalQuantity = totalQuantity + item.Count
            end
        end

        if totalQuantity < reagent.Quantity then
            local reagentName = nil
            for name, id in pairs(REAGENTS) do
                if id == reagent.ID then
                    reagentName = name
                    break
                end
            end
            Messages.Overhead("Not enough " .. reagentName .. "! Need " .. reagent.Quantity .. ", have " .. totalQuantity, Colors.Alert, Player.Serial)
            return false
        end
    end
    return true
end

local function CraftPotion(potionKey)
    local mortar = FindMortar()
    if not mortar then
        Messages.Overhead("No Mortar & Pestle!", Colors.Alert, Player.Serial)
        return false
    end

    if not FindBottles() then
        Messages.Overhead("No Bottles!", Colors.Alert, Player.Serial)
        return false
    end

    if not FindReagents(POTION_REAGENTS[potionKey]) then
        Messages.Overhead("Missing or insufficient reagents for " .. potionKey:gsub("_", " ") .. "!", Colors.Alert, Player.Serial)
        return false
    end

    local buttons = GUMP_BUTTONS[potionKey]
    if not buttons then
        Messages.Overhead("No button mapping for " .. potionKey:gsub("_", " ") .. "!", Colors.Alert, Player.Serial)
        return false
    end

    Player.UseObject(mortar.Serial)
    if not Gumps.WaitForGump(Config.GUMP_ID, 1000) then
        Messages.Overhead("Gump failed to open!", Colors.Alert, Player.Serial)
        return false
    end

    -- First time for this potion, navigate the full menu
    if Config.lastPotionKey ~= potionKey then
        Gumps.PressButton(Config.GUMP_ID, buttons.category)
        Pause(750)
        Gumps.PressButton(Config.GUMP_ID, buttons.craft)
        Pause(750)
        Gumps.PressButton(Config.GUMP_ID, buttons.final)
        Config.lastPotionKey = potionKey
    else
        -- Use "Make Last" button for repeated crafting
        Pause(500)
        Gumps.PressButton(Config.GUMP_ID, 21)
    end

    Messages.Overhead("Crafting " .. potionKey:gsub("_", " ") .. "!", Colors.Action, Player.Serial)
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
        Messages.Overhead("No enabled potions to craft or stopped.", Colors.Alert, Player.Serial)
        break
    end
end
