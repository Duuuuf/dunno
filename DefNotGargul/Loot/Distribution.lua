local DNG = DefNotGargul

-- Store who is the disenchanter
DNG_Saved.deTarget = DNG_Saved.deTarget or nil

------------------------------------------------------------
-- /dngde command
------------------------------------------------------------
SLASH_DNGDE1 = "/dngde"
SlashCmdList["DNGDE"] = function(msg)
    msg = msg:trim()

    local name

    -- Case 1: argument provided ⇒ /dngde Mageplayer
    if msg ~= "" then
        name = msg

    -- Case 2: no argument ⇒ use target player
    else
        if UnitExists("target") and UnitIsPlayer("target") then
            name = UnitName("target")
        else
            print("|cffff0000[DNG]|r No target player and no name provided.")
            return
        end
    end

    -- SAVE the new DE target
    DNG_Saved.deTarget = name

    -- NOW update the label (after saving)
    if DNG.UpdateDELabel then
        DNG:UpdateDELabel()
    end

    print("|cff00ff00[DNG]|r Disenchanter set to:", name)
end

------------------------------------------------------------
-- Internal helper: returns true if DE handled
------------------------------------------------------------
function DNG:HandleDEAssignment(lootSlot)
    --print("|cffffff00[DNG DE]|r HandleDEAssignment called. LootSlot:", lootSlot)

    if not DNG_Saved.deTarget then 
        print("|cffff0000[DNG DE]|r No DE target set!") 
        return false 
    end

    --print("|cffffff00[DNG DE]|r DE target is", DNG_Saved.deTarget)

    local numCandidates = GetNumLootItems()
    if lootSlot > numCandidates then 
        print("|cffff0000[DNG DE]|r Invalid loot slot:", lootSlot)
        return false 
    end

    local deName = DNG_Saved.deTarget

    -- Find the DE player index in master-loot candidate list
    for i = 1, 40 do
        local candidate = GetMasterLootCandidate(lootSlot, i)
        if candidate then
            --print("|cffffff00[DNG DE]|r Candidate", i, ":", candidate)
        end
        if candidate == deName then
            GiveMasterLoot(lootSlot, i)
            --print("|cff00ff00[DNG]|r DE item sent to:", deName)
            return true
        end
    end

    print("|cffff0000[DNG DE]|r DE target not found in candidate list!")
    return false
end

------------------------------------------------------------
-- Public wrapper: assign loot
------------------------------------------------------------
function DNG:AssignLoot(lootSlot, winnerName, winnerIndex)
    -- Auto DE override
    if DNG:HandleDEAssignment(lootSlot) then
        return
    end

    -- Normal assignment
    if winnerIndex then
        GiveMasterLoot(lootSlot, winnerIndex)
        print("|cff00ff00[DNG]|r Sent:", winnerName)
    end
end
