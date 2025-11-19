local DNG = {}
DefNotGargul = DNG
DNG_Saved = DNG_Saved or {}

-- default settings
DNG_Saved.frameWidth = DNG_Saved.frameWidth or 340
DNG_Saved.frameHeight = DNG_Saved.frameHeight or 420
DNG_Saved.autoAssign = (DNG_Saved.autoAssign ~= false)

DNG.memory = {}

-- event frame
local f = CreateFrame("Frame")
f:RegisterEvent("LOOT_OPENED")
f:RegisterEvent("PLAYER_LOGIN")

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

-- events
f:SetScript("OnEvent", function(self, event, ...)

    -- LOOT_OPENED: detect items from corpse
    if event == "LOOT_OPENED" then
        local numItems = GetNumLootItems()
        --print("|cffffff00[DNG]|r LOOT_OPENED with", numItems, "items")

        for slot = 1, numItems do
            local lootLink = GetLootSlotLink(slot)

            if lootLink then
                local _, _, quality = GetItemInfo(lootLink)
                --print("|cffffff00[DNG]|r Found:", lootLink, "Quality:", quality)

                -- attempt DE assignment
                if quality == 2 or quality == 3 then
                    if DNG.HandleDEAssignment then
                        --print("|cffffff00[DNG]|r Trying DE for slot", slot)
                        local ok = DNG:HandleDEAssignment(slot)
                        if ok then
                            --print("|cff00ff00[DNG]|r DE success:", lootLink)
                        else
                            print("|cffff0000[DNG]|r DE failed:", lootLink)
                        end
                    end
                end

                -- add item to UI memory
                if quality == 2 or quality == 3 then
                    DNG:AddItem(lootLink)
                end
            end
        end

    -- PLAYER_LOGIN
    elseif event == "PLAYER_LOGIN" then
        print("[DNG Debug] PLAYER_LOGIN")

        if DNG.CreateUI then
            DNG:CreateUI()
            if DNG.UpdateMemoryUI then
                DNG:UpdateMemoryUI()
            end
        end

        -- /DNG toggle
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
            end
            
            if DNG.UpdateDELabel then
                DNG:UpdateDELabel()
            end

        end

        -- /DNGTEST test item
        SLASH_DNGTEST1 = "/DNGTEST"
        SlashCmdList["DNGTEST"] = function()
            local testItemLink = select(2, GetItemInfo(25401))
                or "|cff9d9d9d|Hitem:25401::::::::60:::::|h[Corroded Mace]|h|r"
            DNG:AddItem(testItemLink)
        end

        print("|cff00ff00[DefNotGargul]|r Loaded. Use /DNG to open UI.")
    end
end)
