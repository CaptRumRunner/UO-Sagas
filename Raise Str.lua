local function RaiseStr()
    Skills.Use('Arms Lore')
    if Targeting.WaitForTarget(1000) then
        Targeting.Target(1119308582)  -- Replace with the correct target Serial if needed
    end
    Pause(1000)
end

while true do
    RaiseStr()
end
