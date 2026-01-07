local DNG = DefNotGargul

------------------------------------------------------------
-- TEST COMMAND: /dnghistorytest
------------------------------------------------------------
SLASH_DNGHISTORYTEST1 = "/dnghistorytest"
SlashCmdList["DNGHISTORYTEST"] = function()
    -- Safety check: ensure history table exists
    if not DNG or not DNG.History then
        print("|cffff0000[DNG]|r History system not loaded yet.")
        return
    end

    -- 1) Create a UNIQUE name for this test run so it doesn't overwrite
    -- This uses the current time so every click adds a NEW raid to the list.
    local testRaidName = "Naxxramas (" .. date("%H:%M:%S") .. ")"

    -- 2) Add the data to the table
    DNG.History.raids[testRaidName] = {
        timestamp = time(),
        items = {
            {
                itemID = 33831,
                winner = "Fatchicken",
                winnerClass = "Druid",
                rolls = {
                    { player = "Fatchicken", roll = 98, class = "Druid" },
                    { player = "Dubmass", roll = 76, class = "Mage" },
                }
            },
            {
                itemID = 28773,
                winner = "Dubmass",
                winnerClass = "Mage",
                rolls = {
                    { player = "Dubmass", roll = 100, class = "Mage" },
                }
            }
        }
    }

    print("|cff00ff00[DNG]|r Added new test data for: " .. testRaidName)
    
    -- 3) Show the UI
    if DNG.ShowHistory then
        DNG:ShowHistory()
    end
end