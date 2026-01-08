local DNG = {}
DefNotGargul = DNG



-- Create the main event frame
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED") -- Required for saving data
f:RegisterEvent("PLAYER_LOGIN") -- Required for UI setup

-- Function to add items to the UI list
function DNG:AddItem(itemLink)
    -- Create the unique ID
    local uniqueID = time() .. "_" .. math.random(100, 999)

    
    table.insert(self.memory, { id = uniqueID, link = itemLink })

    if self.UpdateMemoryUI then self:UpdateMemoryUI() end
end


    
-- Main Event Handler
f:SetScript("OnEvent", function(self, event, ...)
    local arg1 = ...

    ---------------------------------------------------
    -- 1) ADDON_LOADED: Runs when data is read from disk
    ---------------------------------------------------
    if event == "ADDON_LOADED" and arg1 == "DefNotGargul" then
        -- Initialize the master SavedVariable table
        DNG_Saved = DNG_Saved or {}

        ---------------------------------------------------
        -- 1) PERSISTENT TABLES (HISTORY, ROSTER, MEMORY)
        ---------------------------------------------------
        
        -- Roster (The 25 players)
        DNG_Saved.Roster = DNG_Saved.Roster or {}

        -- History (Old raids)
        DNG_Saved.History = DNG_Saved.History or { raids = {} }
        DNG.History = DNG_Saved.History 

        -- Memory (The Active Loot window - NEW)
        DNG_Saved.Memory = DNG_Saved.Memory or {}
        DNG.memory = DNG_Saved.Memory 

        ---------------------------------------------------
        -- 2) SETTINGS & UI DEFAULTS
        ---------------------------------------------------
        DNG_Saved.frameWidth = DNG_Saved.frameWidth or 420
        DNG_Saved.frameHeight = DNG_Saved.frameHeight or 420
        DNG_Saved.autoAssign = (DNG_Saved.autoAssign ~= false)
        DNG_Saved.deTarget = DNG_Saved.deTarget or ""
        
        -- Initialize the Minimap Icon if that module is loaded
        if DNG.InitMinimap then
            DNG:InitMinimap()
        end
        
        -- print("|cff00ff00[DNG]|r All data modules successfully linked.")

    ---------------------------------------------------
    -- 2) PLAYER_LOGIN: Runs when you enter the world
    ---------------------------------------------------
    elseif event == "PLAYER_LOGIN" then
        -- Register Loot event
        self:RegisterEvent("LOOT_OPENED")

        -- Create the UI
        if DNG.CreateUI then
            DNG:CreateUI()
            if DNG.UpdateMemoryUI then DNG:UpdateMemoryUI() end
            if DNG.UpdateDELabel then DNG:UpdateDELabel() end
        end

        -- Slash Command: /DNG
        SLASH_DNG1 = "/DNG"
        SlashCmdList["DNG"] = function()
            if not DNG.frame then DNG:CreateUI() end
            if DNG.frame:IsShown() then
                DNG.frame:Hide()
            else
                DNG.frame:Show()
                if DNG.UpdateMemoryUI then DNG:UpdateMemoryUI() end
                if DNG.UpdateDELabel then DNG:UpdateDELabel() end
            end
        end

        -- Slash Command: /DNGTEST
        SLASH_DNGTEST1 = "/DNGTEST"
        SlashCmdList["DNGTEST"] = function()
            local testItemLink = select(2, GetItemInfo(33831))
                or "|cff9d9d9d|Hitem:33831::::::::60:::::|h[Corroded Mace]|h|r"
            DNG:AddItem(testItemLink)
            local testItemLink2 = select(2, GetItemInfo(33322))
                or "|cff9d9d9d|Hitem:33322::::::::60:::::|h[Corroded Mace]|h|r"
            DNG:AddItem(testItemLink2)
        end

        print("|cff00ff00[DefNotGargul]|r Loaded. Use /DNG or /dnghistory.")

    ---------------------------------------------------
    -- 3) LOOT_OPENED: Logic for detecting items
    ---------------------------------------------------
    elseif event == "LOOT_OPENED" then
        local numItems = GetNumLootItems()
        if not IsInRaid() then return end

        local method, mlPartyID, mlRaidID = GetLootMethod()
        local isML = (method == "master" and mlRaidID == UnitInRaid("player"))

        for slot = 1, numItems do
            local lootLink = GetLootSlotLink(slot)
            if lootLink then
                local itemID = tonumber(lootLink:match("item:(%d+):"))
                -- itemType is the 6th value (we use _ to skip the ones we don't need)
                local _, _, quality, _, _, itemType = GetItemInfo(lootLink)

                ---------------------------------------------------
                -- 1) AUTO-DE CHECK (Greens/Blues)
                ---------------------------------------------------
                if isML and (quality == 2 or quality == 3) then
                    -- EXCEPTION: Do not DE if it is a Recipe
                    if itemType ~= "Recipe" then
                        if DNG.HandleDEAssignmentQueued then
                            DNG:HandleDEAssignmentQueued(slot)
                        end
                    else
                        -- Optional: Add recipes to the UI so you can roll them out
                        DNG:AddItem(lootLink)
                    end
                end

                ---------------------------------------------------
                -- 2) WHITELIST CHECK (Epics/Raid Items)
                ---------------------------------------------------
                local isWhitelisted = DNG.RAID_ITEM_IDS and DNG.RAID_ITEM_IDS[itemID]
                if isWhitelisted then
                    DNG:AddItem(lootLink)
                end
            end
        end
    end 
end)

StaticPopupDialogs["DNG_LC_CONFIRM"] = {
    text = "Enter winner name or LC Note for %s:",
    button1 = "Save",
    button2 = "Cancel",
    hasEditBox = 1,
    OnAccept = function(self, data)
        local text = self.editBox:GetText()
        if text ~= "" then
            local _, englishClass = UnitClass(text)

            if DNG.LogLootAssignment then
                DNG:LogLootAssignment(data.itemLink, text, englishClass or "NONE", {}, "Loot Council", data.dropID)
            end

            -- NEW: Manually remove the item from the list after LC is confirmed
            for i, itemData in ipairs(DNG.memory) do
                if itemData.id == data.dropID then
                    table.remove(DNG.memory, i)
                    break
                end
            end
            
            -- Refresh the UI
            if DNG.UpdateMemoryUI then DNG:UpdateMemoryUI() end
            if DNG.CheckIfEmpty then DNG:CheckIfEmpty() end
            
            print("|cff00ff00[DNG]|r Recorded " .. data.itemLink .. " for " .. text)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

SLASH_DNGROSTER1 = "/dngroster"
SlashCmdList["DNGROSTER"] = function(msg)
    local name, class = msg:match("^(%S+)%s+(%S+)$")
    if name and class then
        -- Class needs to be capitalized correctly for colors (e.g., "Mage")
        class = class:gsub("^%l", string.upper)
        DNG_Saved.Roster[name] = class
        print("|cff00ff00[DNG]|r Added to Roster: " .. name .. " (" .. class .. ")")
    else
        print("|cffff0000[DNG]|r Usage: /dngroster Name Class (e.g., /dngroster Fatchicken Druid)")
    end
end
-- REMOVE PLAYER FROM ROSTER: /dngrosterdel Name
SLASH_DNGROSTERDEL1 = "/dngrosterdel"
SlashCmdList["DNGROSTERDEL"] = function(msg)
    local name = msg:trim() -- remove any accidental spaces
    
    if name ~= "" then
        -- Standardize name (First letter upper, the rest lower)
        name = name:lower():gsub("^%l", string.upper)
        
        if DNG_Saved.Roster and DNG_Saved.Roster[name] then
            DNG_Saved.Roster[name] = nil
            print("|cff00ff00[DNG]|r Removed from Roster: " .. name)
            
            -- Refresh the History window immediately if it's open
            if DNG.historyFrame and DNG.historyFrame:IsShown() and DNG.UpdateHistoryUI then
                DNG:UpdateHistoryUI()
            end
        else
            print("|cffff0000[DNG]|r Player '" .. name .. "' not found in roster.")
        end
    else
        print("|cffff0000[DNG]|r Usage: /dngrosterdel Name")
    end
end

SLASH_DNGTESTDUP1 = "/dngtestdup"
SlashCmdList["DNGTESTDUP"] = function()
    -- We use Betrayer of Humanity (a famous Naxx item)
    local testLink = "|cffff8000|Hitem:40384::::::::80:::::::::|h[Betrayer of Humanity]|h|r"
    
    print("|cff00ff00[DNG Test]|r Simulating 2x drops of the same item...")
    
    -- Add the first one
    DNG:AddItem(testLink)
    -- Add the second one (identical link)
    DNG:AddItem(testLink)
    
    if DNG.frame then DNG.frame:Show() end
end