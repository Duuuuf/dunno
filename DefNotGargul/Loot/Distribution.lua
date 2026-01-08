local DNG = DefNotGargul

------------------------------------------------------------
-- 1) /dngde command (Standardized)
------------------------------------------------------------
SLASH_DNGDE1 = "/dngde"
SlashCmdList["DNGDE"] = function(msg)
    msg = msg:trim()
    local name
    
    if msg ~= "" then
        name = msg
    elseif UnitExists("target") and UnitIsPlayer("target") then
        name = UnitName("target")
    else
        print("|cffff0000[DNG]|r No target and no name provided.")
        return
    end

    -- Standardize name: First letter Upper, rest Lower
    name = name:lower():gsub("^%l", string.upper)
    DNG_Saved.deTarget = name

    if DNG.UpdateDELabel then DNG:UpdateDELabel() end
    print("|cff00ff00[DNG]|r Disenchanter set to: " .. name)
end

------------------------------------------------------------
-- 2) Internal Logic: Auto-DE Assignment
------------------------------------------------------------
local deRetryQueue = {} -- Tracks slots currently trying to assign

function DNG:HandleDEAssignmentQueued(lootSlot, startTime)
    local lootLink = GetLootSlotLink(lootSlot)
    if not lootLink then return end
    
    local _, _, quality, _, _, itemType = GetItemInfo(lootLink)
    
    -- Safety Exception: Skip Recipes and Quest items
    if itemType == "Recipe" or itemType == "Quest" then 
        return false 
    end
    
    -- Check if we are the Master Looter
    local method, mlParty, mlRaid = GetLootMethod()
    if method ~= "master" or mlRaid ~= UnitInRaid("player") then return end

    startTime = startTime or GetTime()

    -- Try to find the DE player in the candidate list
    local candidateIndex = nil
    for i = 1, 40 do
        local candidate = GetMasterLootCandidate(lootSlot, i)
        if candidate == deName then
            candidateIndex = i
            break
        end
    end

    if candidateIndex then
        -- SUCCESS: Assign the loot
        GiveMasterLoot(lootSlot, candidateIndex)
        deRetryQueue[lootSlot] = nil
        -- print("|cff00ff00[DNG]|r Sent trash to DE: " .. deName)
    else
        -- RETRY: If not found, wait and try again (Server-side candidate list delay)
        if GetTime() - startTime < 3 then -- Retry for 3 seconds max
            if not deRetryQueue[lootSlot] then
                deRetryQueue[lootSlot] = true
                
                -- 3.3.5 Delay logic (Self-cleaning Frame)
                local f = CreateFrame("Frame")
                local elapsed = 0
                f:SetScript("OnUpdate", function(self, e)
                    elapsed = elapsed + e
                    if elapsed >= 0.1 then -- Retry every 0.1s
                        self:SetScript("OnUpdate", nil)
                        DNG:HandleDEAssignmentQueued(lootSlot, startTime)
                    end
                end)
            end
        else
            -- TIMEOUT
            print("|cffff0000[DNG]|r Failed to Auto-DE: " .. deName .. " not in candidate list.")
            deRetryQueue[lootSlot] = nil
        end
    end
end

------------------------------------------------------------
-- 3) Manual/Roll Assignment
------------------------------------------------------------
function DNG:AssignLoot(lootSlot, winnerName, winnerIndex)
    if not IsInRaid() or not winnerIndex then return end

    -- Verify we are still ML
    local method, _, mlRaid = GetLootMethod()
    if method == "master" and mlRaid == UnitInRaid("player") then
        GiveMasterLoot(lootSlot, winnerIndex)
        print("|cff00ff00[DNG]|r Assigned to " .. winnerName)
    end
end

------------------------------------------------------------
-- 4) Notable Loot Announcer (Epics & Recipes)
------------------------------------------------------------
local lootAnnounceFrame = CreateFrame("Frame")
lootAnnounceFrame:RegisterEvent("LOOT_OPENED")
lootAnnounceFrame:SetScript("OnEvent", function(self, event)
    if not IsInRaid() then return end
    local numItems = GetNumLootItems()
    if numItems == 0 then return end

    local notables = {}
    local recipes = {["Pattern"]=true, ["Design"]=true, ["Schematic"]=true, ["Plans"]=true, ["Formula"]=true, ["Recipe"]=true}

    for slot = 1, numItems do
        local link = GetLootSlotLink(slot)
        if link then
            local _, _, quality, _, _, _, _, _, itemSubType = GetItemInfo(link)
            -- Quality 4 = Epic, or it's a Recipe
            if quality >= 4 or recipes[itemSubType] then
                table.insert(notables, link)
            end
        end
    end

    if #notables > 0 then
        SendChatMessage("Notable Loot: " .. table.concat(notables, ", "), "RAID")
    end
end)