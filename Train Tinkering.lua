----------------------------------------------------------------------
-- Train Tinkering Assistant Script v0.1.0
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

-- Print Initial Start Up Greeting
Messages.Print("___________________________________", Colors.INFO)
Messages.Print("Train Tinkering Assistant Script v0.1.0", Colors.INFO)
Messages.Print("___________________________________", Colors.INFO)

-- User Settings
local Config = {
	TOOL_ID = 0x1EB8,          -- Tinkers Tools
	GUMP_ID = 2653346093,
	MAKE_LAST_BUTTON_ID = 21  -- "Make Last" button
}

-- Crafting items by skill range
local TINKER_ITEMS = {
    { name = "Fork",        minSkill = 30.0, maxSkill = 49.9, category = 15, craft = 38, final = 37 },
    { name = "Bartap",      minSkill = 50.0, maxSkill = 69.9, category = 8, craft = 24, final = 23 },
    { name = "Spyglass",    minSkill = 70.0, maxSkill = 89.9, category = 22, craft = 38, final = 37 },
    { name = "Scales",      minSkill = 90.0, maxSkill = 100.0, category = 22, craft = 17, final = 16 },
}

-- Helper functions
local function FindTool()
    return Items.FindByType(Config.TOOL_ID, Player.Backpack)
end

local function GetSkill()
    local skill = Skills.GetValue("Tinkering")
    return tonumber(string.format("%.1f", skill))
end

-- Main crafting function
local lastItem = nil
local function CraftItem()
    local tool = FindTool()
    if not tool then
        Messages.Overhead("No Tinker Tools!", Colors.ALERT, Player.Serial)
        return false
    end

    local skill = GetSkill()
    local itemToCraft = nil
    for _, item in ipairs(TINKER_ITEMS) do
        if skill >= item.minSkill and skill <= item.maxSkill then
            itemToCraft = item
            break
        end
    end

    if not itemToCraft then
        Messages.Overhead("No item matches current skill level!", Colors.ALERT, Player.Serial)
        return false
    end

    Player.UseObject(tool.Serial)
    if not Gumps.WaitForGump(Config.GUMP_ID, 1000) then
        Messages.Overhead("Failed to open tinkering menu!", Colors.ALERT, Player.Serial)
        return false
    end

    if lastItem ~= itemToCraft.name then
        Gumps.PressButton(Config.GUMP_ID, itemToCraft.category)
        Pause(600)
        Gumps.PressButton(Config.GUMP_ID, itemToCraft.craft)
        Pause(600)
        Gumps.PressButton(Config.GUMP_ID, itemToCraft.final)
        lastItem = itemToCraft.name
    else
        Pause(500)
        Gumps.PressButton(Config.GUMP_ID, Config.MAKE_LAST_BUTTON_ID)
    end

    Messages.Overhead("Crafting: " .. itemToCraft.name, Colors.ACTION, Player.Serial)
    Pause(3000)
    return true
end

-- Main loop
while true do
    local crafted = CraftItem()
    if not crafted then
        break
    end
end
