local DNG = {}
DefNotGargul = DNG

-- Initialize internal tables
DNG.memory = {}

-- Create the main event frame
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED") -- Required for saving data
f:RegisterEvent("PLAYER_LOGIN") -- Required for UI setup

-- Function to add items to the UI list
function DNG:AddItem(itemLink)
    if not itemLink or itemLink == "" then return end

    if not self.memory[itemLink] then
        self.memory[itemLink] = true
        -- print("|cff00ff00[DefNotGargul]|r Added:", itemLink)
    end

    if self.UpdateMemoryUI then
        self:UpdateMemoryUI()
    end
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

        -- Roster thing
        DNG_Saved.Roster = DNG_Saved.Roster or {}
        
        -- Link History: This makes sure DNG.History points to the Save File
        DNG_Saved.History = DNG_Saved.History or { raids = {} }
        DNG.History = DNG_Saved.History 

        -- Load or Set Default Settings
        DNG_Saved.frameWidth = DNG_Saved.frameWidth or 340
        DNG_Saved.frameHeight = DNG_Saved.frameHeight or 420
        DNG_Saved.autoAssign = (DNG_Saved.autoAssign ~= false)
        DNG_Saved.deTarget = DNG_Saved.deTarget or ""
        
        -- Initialize the Minimap Icon if that module is loaded
        if DNG.InitMinimap then
            DNG:InitMinimap()
        end

        -- print("|cff00ff00[DNG]|r Data successfully loaded and History linked.")

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

        -- Only operate in raid groups
        if not IsInRaid() then return end

        for slot = 1, numItems do
            local lootLink = GetLootSlotLink(slot)
            if lootLink then
                local itemID = tonumber(lootLink:match("item:(%d+):"))
                local _, _, quality = GetItemInfo(lootLink)

                -- Check whitelist
                local isWhitelisted = DNG.RAID_ITEM_IDS and DNG.RAID_ITEM_IDS[itemID]

                -- Add to UI if whitelisted
                if isWhitelisted then
                    DNG:AddItem(lootLink)
                end

                -- Auto DE for green/blue trash
                if quality == 2 or quality == 3 then
                    if DNG.HandleDEAssignmentQueued then
                        DNG:HandleDEAssignmentQueued(slot)
                    end

                    -- Check whitelist again in case a blue item is on it
                    if DNG.RAID_ITEM_IDS and DNG.RAID_ITEM_IDS[itemID] then
                        DNG:AddItem(lootLink)
                    end
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
            -- We call a new function to log this manually
            DNG:LogManualLoot(data.itemLink, text)
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