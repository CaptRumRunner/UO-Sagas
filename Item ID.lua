-- Item ID everything
-- UO Sagas
-- Found in the scripting discord: https://discord.com/channels/903311689112518708/1372217132586111046/1372217132586111046
-- Edited by: Jase Owns
-- ===============================
-- Last Updated: 5/28/2025
-- Updated to make sure all items are identified (even if they are in a bag)
-- ===============================
Messages.Overhead("Starting ID Script", 89, Player.Serial)

local items = Items.FindByFilter(
    { 
        name = "Unidentified",
        hues = {0},
    }
)

local totalItems = 0

for i, item in ipairs(items) do 
    --Messages.Overhead(i, Player.Serial)
    if item.RootContainer == Player.Serial then
        totalItems = totalItems + 1
        repeat
            if item.Name ~= nil then
                Messages.Overhead(item.Name, Player.Serial)
            else
                Messages.Overhead("No name item, lets try anyway", 214, Player.Serial)
            end
            Skills.Use('Item Identification') 
            Targeting.WaitForTarget(500) 
            Targeting.Target(item.Serial) 
            Pause(1000) 
            if not string.find(item.Name,"Unidentified") then
                Messages.Overhead(item.Name, 89, Player.Serial)
            end
        until item.Name ~= nil and not string.find(item.Name,"Unidentified")
    end 
end 

Messages.Overhead(string.format("Done IDing %d items", totalItems), 64, Player.Serial)