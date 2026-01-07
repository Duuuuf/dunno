local DNG = DefNotGargul

------------------------------------------------------------
-- /dngde command
------------------------------------------------------------
SLASH_DNGDE1 = "/dngde"
SlashCmdList["DNGDE"] = function(msg)
    msg = msg:trim()

    local name
    if msg ~= "" then
        name = msg
    else
        if UnitExists("target") and UnitIsPlayer("target") then
            name = UnitName("target")
        else
            print("|cffff0000[DNG]|r No target player and no name provided.")
            return
        end
    end

    -- Save the DE target
    DNG_Saved.deTarget = name

    -- Update UI label
    if DNG.UpdateDELabel then
        DNG:UpdateDELabel()
    end

    print("|cff00ff00[DNG]|r Disenchanter set to:", name)
end

------------------------------------------------------------
-- Internal helper: DE assignment with persistent retry queue
------------------------------------------------------------
local deQueue = {}

function DNG:HandleDEAssignmentQueued(lootSlot, startTime)
    local deName = DNG_Saved.deTarget
    if not deName or deName == "" then return false end
    if not IsInRaid() then return false end

    startTime = startTime or GetTime()
    local numItems = GetNumLootItems()
    if lootSlot > numItems then return false end

    -- Try assigning DE
    for i = 1, 40 do
        local candidate = GetMasterLootCandidate(lootSlot, i)
        if candidate == deName then
            GiveMasterLoot(lootSlot, i)
            print("|cff00ff00[DNG]|r DE item sent to:", deName)
            deQueue[lootSlot] = nil
            return true
        end
    end

    -- Candidate list not ready yet
    -- Candidate list not ready yet (REPLACED C_Timer for 3.3.5)
    if GetTime() - startTime < 3 then 
        if not deQueue[lootSlot] then
            deQueue[lootSlot] = true
            
            -- Simple 3.3.5 delay logic using a temporary frame
            local delayFrame = CreateFrame("Frame")
            local delayTime = 0
            delayFrame:SetScript("OnUpdate", function(self, elapsed)
                delayTime = delayTime + elapsed
                if delayTime >= 0.1 then
                    self:SetScript("OnUpdate", nil)
                    DNG:HandleDEAssignmentQueued(lootSlot, startTime)
                end
            end)
        end
        return false
    end

    -- Timeout failure
    print("|cffff0000[DNG DE]|r DE failed: player not in candidate list (timeout).")
    deQueue[lootSlot] = nil
    return false
end


------------------------------------------------------------
-- Public wrapper: assign loot
------------------------------------------------------------
function DNG:AssignLoot(lootSlot, winnerName, winnerIndex)
    -- Only operate in raid
    if not IsInRaid() then return end

    -- Auto DE override
    if DNG:HandleDEAssignmentQueued(lootSlot) then
        return
    end

    -- Normal assignment
    if winnerIndex then
        GiveMasterLoot(lootSlot, winnerIndex)
        print("|cff00ff00[DNG]|r Sent:", winnerName)
    end
end

------------------------------------------------------------
-- Optional: Only add whitelisted items to UI memory
------------------------------------------------------------
function DNG:AddItemIfWhitelisted(itemLink)
    if not itemLink then return end
    local itemID = tonumber(itemLink:match("item:(%d+):"))
    if itemID and DNG.RAID_ITEM_IDS and DNG.RAID_ITEM_IDS[itemID] then
        DNG:AddItem(itemLink)
    end
end

------------------------------------------------------------
-- Announce loot in raid chat (purple items + profession recipes)
------------------------------------------------------------
local lootAnnounceFrame = CreateFrame("Frame")
lootAnnounceFrame:RegisterEvent("LOOT_OPENED")
lootAnnounceFrame:SetScript("OnEvent", function(self, event, autoloot)
    if not IsInRaid() then return end

    local numItems = GetNumLootItems()
    if numItems == 0 then return end

    local lootList = {}
    local recipeSubTypes = {
        ["Pattern"] = true,
        ["Design"] = true,
        ["Schematic"] = true,
        ["Plans"] = true,
        ["Formula"] = true,
        ["Recipe"] = true,
    }

    for slot = 1, numItems do
        local link = GetLootSlotLink(slot)
        if link then
            local name, _, quality, _, _, _, _, itemType, itemSubType = GetItemInfo(link)
            if quality == 4 or (itemType == "Recipe" and recipeSubTypes[itemSubType]) then
                table.insert(lootList, link)
            end
        end
    end

    if #lootList > 0 then
        local msg = "Looted notable items: " .. table.concat(lootList, ", ")
        SendChatMessage(msg, "RAID")
    end
end)

