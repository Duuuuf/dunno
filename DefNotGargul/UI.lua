local DNG = DefNotGargul
DNG.activeRolls = {}
local addonName, S = ...

function DNG:CreateUI()
    if self.frame then return end

    local frame = CreateFrame("Frame", "DNGFrame", UIParent)
    frame:SetSize(340, 420)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    self.frame = frame
    self.content = {}

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("DefNotGargul")

    self.scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    
    self.scrollFrame:SetPoint("TOPLEFT", 10, -40)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    self.scrollChild = CreateFrame("Frame")
    self.scrollChild:SetSize(280, 1)
    self.scrollFrame:SetScrollChild(self.scrollChild)

    -- Listen for rolls
    local rollListener = CreateFrame("Frame")
    rollListener:RegisterEvent("CHAT_MSG_SYSTEM")
    rollListener:SetScript("OnEvent", function(_, _, msg)
        local player, roll, low, high = msg:match("(.+) rolls (%d+) %((%d+)%-(%d+)%)")
        if player and roll and low and high then
            roll = tonumber(roll)
            low = tonumber(low)
            high = tonumber(high)
            for itemLink, rollData in pairs(DNG.activeRolls) do
                if rollData.active then
                    -- Store player's roll
                    if roll >= low and roll <= high then
                        rollData.rolls[player] = roll
                        print("|cff00ff00[DefNotGargul]|r " .. player .. " rolled " .. roll .. " for " .. itemLink)
                    end
                end
            end
        end
    end)

    function self:StartRoll(itemLink)
        if DNG.activeRolls[itemLink] and DNG.activeRolls[itemLink].active then
            print("|cffff0000[DefNotGargul]|r A roll for this item is already active!")
            return
        end

        DNG.activeRolls[itemLink] = { active = true, rolls = {} }
        SendChatMessage("ROLL STARTED for " .. itemLink .. " — type /roll! (30 seconds)", "RAID_WARNING")

        -- Automatically end after 30s
        C_Timer.After(30, function()
            if DNG.activeRolls[itemLink] and DNG.activeRolls[itemLink].active then
                self:EndRoll(itemLink)
            end
        end)
    end

    function self:EndRoll(itemLink)
        local rollData = DNG.activeRolls[itemLink]
        if not rollData or not rollData.active then
            print("|cffff0000[DefNotGargul]|r No active roll for " .. itemLink)
            return
        end

        rollData.active = false
        local highestPlayer, highestRoll = nil, -1

        for player, roll in pairs(rollData.rolls) do
            if roll > highestRoll then
                highestRoll = roll
                highestPlayer = player
            end
        end

        if highestPlayer then
            SendChatMessage("WINNER of " .. itemLink .. ": " .. highestPlayer .. " (" .. highestRoll .. ")", "RAID_WARNING")
        else
            SendChatMessage("No valid rolls for " .. itemLink, "RAID_WARNING")
        end
    end

    function self:UpdateMemoryUI()
        for _, child in ipairs(self.content) do
            child:Hide()
            child:SetParent(nil)
        end
        self.content = {}

        local y = -5
        local count = 0

        for itemLink, _ in pairs(self.memory) do
            count = count + 1
            local line = CreateFrame("Frame", nil, self.scrollChild)
            line:SetSize(260, 40)
            line:SetPoint("TOPLEFT", 0, y)

            local itemTexture = GetItemIcon(itemLink) or "Interface\\Icons\\INV_Misc_QuestionMark"

            local icon = CreateFrame("Button", nil, line)
            icon:SetSize(32, 32)
            icon:SetPoint("LEFT", 0, 0)
            icon.icon = icon:CreateTexture(nil, "BACKGROUND")
            icon.icon:SetAllPoints()
            icon.icon:SetTexture(itemTexture)

            icon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(itemLink)
                GameTooltip:Show()
            end)
            icon:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            -- START ROLL
            local startRoll = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            startRoll:SetSize(70, 22)
            startRoll:SetPoint("LEFT", 40, 0)
            startRoll:SetText("Start Roll")
            startRoll:SetScript("OnClick", function()
                self:StartRoll(itemLink)
            end)

            -- END ROLL
            local endRoll = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            endRoll:SetSize(60, 22)
            endRoll:SetPoint("LEFT", 115, 0)
            endRoll:SetText("End Roll")
            endRoll:SetScript("OnClick", function()
                self:EndRoll(itemLink)
            end)

            -- ANNOUNCE
            local ann = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            ann:SetSize(70, 22)
            ann:SetPoint("LEFT", 180, 0)
            ann:SetText("Announce")
            ann:SetScript("OnClick", function()
                SendChatMessage("Item: " .. itemLink, "RAID_WARNING")
            end)

            -- DISCARD
            local del = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            del:SetSize(60, 22)
            del:SetPoint("LEFT", 255, 0)
            del:SetText("Discard")
            del:SetScript("OnClick", function()
                self.memory[itemLink] = nil
                self:UpdateMemoryUI()
            end)

            table.insert(self.content, line)
            y = y - 40
        end

        if count == 0 then
            local placeholder = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            placeholder:SetPoint("TOPLEFT", 0, -5)
            placeholder:SetText("No items in memory yet.")
            table.insert(self.content, placeholder)
        end
    end
end

