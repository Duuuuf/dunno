local DNG = {}
DefNotGargul = DNG
DNG.memory = {}

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_LOOT")
f:RegisterEvent("PLAYER_LOGIN")

function DNG:AddItem(itemLink)
    if not itemLink or itemLink == "" then
        print("[DNG Debug] AddItem called with empty itemLink")
        return
    end

    print("[DNG Debug] AddItem called with:", itemLink)

    if not self.memory[itemLink] then
        self.memory[itemLink] = true
        print("|cff00ff00[DefNotGargul]|r Added: " .. itemLink)
    else
        print("[DNG Debug] Item already in memory:", itemLink)
    end

    if self.UpdateMemoryUI then
        print("[DNG Debug] Calling UpdateMemoryUI()")
        self:UpdateMemoryUI()
    else
        print("[DNG Debug] UpdateMemoryUI not defined yet")
    end
end

f:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_LOOT" then
        local msg = ...
        local item = msg:match("|c%x+|Hitem:.-|h.-|h|r")
        DNG:AddItem(item)

    elseif event == "PLAYER_LOGIN" then
        print("[DNG Debug] PLAYER_LOGIN triggered")

        if DNG.CreateUI then
            print("[DNG Debug] UI module loaded, creating UI...")
            DNG:CreateUI()
        else
            print("[DNG Debug] UI module NOT loaded — check .toc load order!")
        end

        SLASH_DNG1 = "/DNG"
        SlashCmdList["DNG"] = function()
            if not DNG.frame then
                print("[DNG Debug] Frame not created yet, creating...")
                DNG:CreateUI()
            end

            if DNG.frame:IsShown() then
                DNG.frame:Hide()
            else
                DNG.frame:Show()
                DNG:UpdateMemoryUI()
            end
        end

        SLASH_DNGTEST1 = "/DNGTEST"
SlashCmdList["DNGTEST"] = function()
    local testItemLink = select(2, GetItemInfo(25401)) or "|cff9d9d9d|Hitem:25401::::::::60:::::|h[Corroded Mace]|h|r"
    DefNotGargul:AddItem(testItemLink)
end


        print("|cff00ff00[DefNotGargul]|r Loaded. Use /DNG to open UI and /DNGTEST to add test items.")
    end
end)
