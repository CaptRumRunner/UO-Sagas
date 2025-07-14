-- Train Inscription Assistant Script v0.1.0
-- Script created by: Rum Runner (adapted for UO Sagas)

-- Define Color Scheme
local Colors = {
    ALERT   = 33,
    WARNING = 48,
    ACTION  = 67,
    CONFIRM = 73,
    INFO    = 84,
}

-- Print Initial Start Up Greeting
Messages.Print("___________________________________", Colors.INFO)
Messages.Print("Train Inscription Assistant Script v0.1.0", Colors.INFO)
Messages.Print("___________________________________", Colors.INFO)

-- User Settings
local Config = {
    TOOL_ID = 0x0FBF,           -- Scribe's Pen
    GUMP_ID = 2653346093,       -- Gump ID for Inscription (change if different)
    MAKE_LAST_BUTTON_ID = 21    -- Button ID for "Make Last"
}

-- Spell crafting by skill level
local SCROLLS = {
    { name = "Recall", minSkill = 30.0, maxSkill = 100.0, circleButton = 22, spellButton = 52 }
}

-- Helper Functions
local function FindTool()
    return Items.FindByType(Config.TOOL_ID, Player.Backpack)
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
        Messages.Overhead("Not enough mana! Meditating...", Colors.WARNING, Player.Serial)
        Skills.Use("Meditation")
        Pause(20000)
    end

    local tool = FindTool()
    if not tool then
        Messages.Overhead("No Scribe's Pen!", Colors.ALERT, Player.Serial)
        return false
    end

    local skill = GetSkill()
    local scroll = nil
    for _, item in ipairs(SCROLLS) do
        if skill >= item.minSkill and skill <= item.maxSkill then
            scroll = item
            break
        end
    end

    if not scroll then
        Messages.Overhead("No scroll matches current skill level!", Colors.ALERT, Player.Serial)
        return false
    end

    Player.UseObject(tool.Serial)
    if not Gumps.WaitForGump(Config.GUMP_ID, 1000) then
        Messages.Overhead("Failed to open Inscription menu!", Colors.ALERT, Player.Serial)
        return false
    end

    if lastItem ~= scroll.name then
        Gumps.PressButton(Config.GUMP_ID, scroll.circleButton)
        Pause(600)
        Gumps.PressButton(Config.GUMP_ID, scroll.spellButton)
        Pause(600)
        lastItem = scroll.name
    else
        Pause(600)
        Gumps.PressButton(Config.GUMP_ID, Config.MAKE_LAST_BUTTON_ID)
    end

    Messages.Overhead("Scribing: " .. scroll.name, Colors.ACTION, Player.Serial)
    Pause(4000)
    return true
end

-- Main Loop
while true do
    local crafted = CraftScroll()
    if not crafted then break end
end
