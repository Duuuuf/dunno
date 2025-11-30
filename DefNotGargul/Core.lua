local DNG = {}
DefNotGargul = DNG
DNG_Saved = DNG_Saved or {}

-- Default settings
DNG_Saved.frameWidth = DNG_Saved.frameWidth or 340
DNG_Saved.frameHeight = DNG_Saved.frameHeight or 420
DNG_Saved.autoAssign = (DNG_Saved.autoAssign ~= false)
DNG_Saved.deTarget = DNG_Saved.deTarget or ""      -- <-- ensure exists

DNG.memory = {}

-- Event frame
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")   -- Only register PLAYER_LOGIN here!

-- AddItem: save item and refresh UI
function DNG:AddItem(itemLink)
    if not itemLink or itemLink == "" then return end

    if not self.memory[itemLink] then
        self.memory[itemLink] = true
        print("|cff00ff00[DefNotGargul]|r Added:", itemLink)
    end

    if self.UpdateMemoryUI then
        self:UpdateMemoryUI()
    end
end


-- Event handling
f:SetScript("OnEvent", function(self, event, ...)

    if event == "PLAYER_LOGIN" then
        print("[DNG Debug] PLAYER_LOGIN")

        ---------------------------------------------------
        -- 1) REGISTER LOOT EVENT *AFTER* SAVED VAR LOAD --
        ---------------------------------------------------
        self:RegisterEvent("LOOT_OPENED")
        print("[DNG Debug] LOOT_OPENED registered AFTER login")


        ---------------------------------------------------
        -- 2) CREATE UI NOW THAT SAVED VARS ARE READY
        ---------------------------------------------------
        if DNG.CreateUI then
            DNG:CreateUI()

            if DNG.UpdateMemoryUI then
                DNG:UpdateMemoryUI()
            end

            if DNG.UpdateDELabel then
                DNG:UpdateDELabel()       -- FIX first-loot DE bug
            end
        end


        ---------------------------------------------------
        -- 3) /DNG toggle UI
        ---------------------------------------------------
        SLASH_DNG1 = "/DNG"
        SlashCmdList["DNG"] = function()
            if not DNG.frame then
                DNG:CreateUI()
            end

            if DNG.frame:IsShown() then
                DNG.frame:Hide()
            else
                DNG.frame:Show()
                if DNG.UpdateMemoryUI then
                    DNG:UpdateMemoryUI()
                end
                if DNG.UpdateDELabel then
                    DNG:UpdateDELabel()
                end
            end
        end


        ---------------------------------------------------
        -- 4) Test command
        ---------------------------------------------------
        SLASH_DNGTEST1 = "/DNGTEST"
        SlashCmdList["DNGTEST"] = function()
            local testItemLink = select(2, GetItemInfo(33831))
                or "|cff9d9d9d|Hitem:33831::::::::60:::::|h[Corroded Mace]|h|r"
            DNG:AddItem(testItemLink)
            local testItemLink = select(2, GetItemInfo(33322))
                or "|cff9d9d9d|Hitem:33322::::::::60:::::|h[Corroded Mace]|h|r"
            DNG:AddItem(testItemLink)
        end

        print("|cff00ff00[DefNotGargul]|r Loaded. Use /DNG to open UI.")

    ---------------------------------------------------
    -- LOOT_OPENED (NOW RUNS AT THE RIGHT TIME)
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

                -- Auto DE for green/blue trash (not whitelisted)
                if quality == 2 or quality == 3 then
                    if DNG.HandleDEAssignmentQueued then
                        DNG:HandleDEAssignmentQueued(slot)
                    end

                    -- Add to UI only if whitelisted
                    local itemID = tonumber(lootLink:match("item:(%d+):"))
                    if DNG.RAID_ITEM_IDS and DNG.RAID_ITEM_IDS[itemID] then
                        DNG:AddItem(lootLink)
                    end
                end


            end
        end
    end
end)

