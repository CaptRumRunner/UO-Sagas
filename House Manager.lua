--[[ 
--------------------------------------------------------------------
House Manager Script with UI
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
Provides a UI for managing house-related tasks such as securing items,
releasing items, locking down items, placing a trash barrel, and banning players.
--------------------------------------------------------------------
Script Notes:
1) Ensure you are inside your house to use this script effectively.
2) Use the UI window to perform house management tasks.
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
Messages.Print("__________________________________", Colors.Info)
Messages.Print("Welcome to the House Manager Script!", Colors.Info)
Messages.Print("Booting up... Initializing systems... ", Colors.Info)
Messages.Print("__________________________________", Colors.Info)

------------- Main script is below, do not make changes below this line -------------

-- UI Window Setup
local window = UI.CreateWindow('houseManager', 'Rum Runners House Manager v0.1.0')
if window then
    window:SetPosition(50, 75)
    window:SetSize(280, 280)
    window:SetResizable(false)

    -- Add title
    window:AddLabel(10, 20, 'House Manager Menu'):SetColor(0.2, 0.8, 1, 1)

    -- Add buttons for house management tasks
    local secureButton = window:AddButton(10, 40, 'Secure Item', 160, 30)
    local releaseButton = window:AddButton(10, 80, 'Release Item', 160, 30)
    local lockdownButton = window:AddButton(10, 120, 'Lock Down Item', 160, 30)
    local trashButton = window:AddButton(10, 160, 'Place Trash Barrel', 160, 30)
    local banButton = window:AddButton(10, 200, 'Ban Player', 160, 30)

    -- Add status label
    local statusLabel = window:AddLabel(10, 240, 'Status: Ready')
    statusLabel:SetColor(1, 1, 1, 1)

    -- Helper Functions
    local function SecureItem()
        Player.Say("I wish to secure this")
       -- if Targeting.WaitForTarget(2000) then
          --  local targetSerial = Targeting.GetNewTarget()
          --  if targetSerial then
              --  Targeting.Target(targetSerial)
              --  Messages.Overhead("Item secured!", Colors.Action, targetSerial.Serial)
             --   statusLabel:SetText("Status: Item secured")
           -- else
              --  Messages.Print("Failed to secure item.")
              --  statusLabel:SetText("Status: Failed to secure item")
          --  end
       -- end
    end

    local function ReleaseItem()
        Player.Say("I wish to release this")
        if Targeting.WaitForTarget(2000) then
            local targetSerial = Targeting.GetNewTarget()
            if targetSerial then
                Targeting.Target(targetSerial)
                Messages.Overhead("Item released!", Colors.Action, targetSerial)
                statusLabel:SetText("Status: Item released")
            else
                Messages.Print("Failed to release item.")
                statusLabel:SetText("Status: Failed to release item")
            end
        end
    end

    local function LockDownItem()
        Player.Say("I wish to lock this down")
        if Targeting.WaitForTarget(2000) then
            local targetSerial = Targeting.GetNewTarget()
            if targetSerial then
                Targeting.Target(targetSerial)
                Messages.Overhead("Item locked down!", Colors.Action, targetSerial)
                statusLabel:SetText("Status: Item locked down")
            else
                Messages.Print("Failed to lock down item.")
                statusLabel:SetText("Status: Failed to lock down item")
            end
        end
    end

    local function PlaceTrashBarrel()
        Player.Say("I wish to place a trash barrel")
        Messages.Print("Trash barrel placed.")
        statusLabel:SetText("Status: Trash barrel placed")
    end

    local function BanPlayer()
        Player.Say("I ban thee")
        if Targeting.WaitForTarget(2000) then
            local targetSerial = Targeting.GetNewTarget()
            if targetSerial then
                Targeting.Target(targetSerial)
                Messages.Overhead("Player banned!", Colors.Alert, targetSerial)
                statusLabel:SetText("Status: Player banned")
            else
                Messages.Print("Failed to ban player.")
                statusLabel:SetText("Status: Failed to ban player")
            end
        end
    end

    -- Set up button event handlers
    secureButton:SetOnClick(SecureItem)
    releaseButton:SetOnClick(ReleaseItem)
    lockdownButton:SetOnClick(LockDownItem)
    trashButton:SetOnClick(PlaceTrashBarrel)
    banButton:SetOnClick(BanPlayer)
end

-- Main Loop
while true do
    Pause(50) -- Allow UI updates
end