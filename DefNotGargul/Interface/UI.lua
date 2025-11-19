local DNG = DefNotGargul
DNG.activeRolls = {}
local addonName, S = ...

-- Always ensure memory and content tables exist
DNG.memory = DNG.memory or {}
DNG.content = DNG.content or {}

-- ✔ NEW: Apply saved button/icon sizes
function DNG:ApplyButtonSizes()
    -- Default size if not saved
    DNG_Saved.buttonSize = DNG_Saved.buttonSize or 22

    -- Apply size to all memory UI lines
    for _, line in ipairs(self.content) do
        if line.icon then line.icon:SetSize(DNG_Saved.buttonSize, DNG_Saved.buttonSize) end
        if line.startRollBtn then line.startRollBtn:SetSize(DNG_Saved.buttonSize * 3, DNG_Saved.buttonSize) end
        if line.endRollBtn then line.endRollBtn:SetSize(DNG_Saved.buttonSize * 3, DNG_Saved.buttonSize) end
        if line.annBtn then line.annBtn:SetSize(DNG_Saved.buttonSize * 3, DNG_Saved.buttonSize) end
        if line.delBtn then line.delBtn:SetSize(DNG_Saved.buttonSize * 3, DNG_Saved.buttonSize) end
    end
end

function DNG:CreateUI()
    if self.frame then return end

    -- Create main frame
    local frame = CreateFrame("Frame", "DNGFrame", UIParent)
    frame:SetSize(DNG_Saved.frameWidth, DNG_Saved.frameHeight)
    frame:SetResizable(true)
    frame:SetMinResize(216, 200)
    frame:SetMaxResize(800, 600)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    self.frame = frame

    -- Resize handle
    local resizer = CreateFrame("Button", nil, frame)
    resizer:SetSize(16, 16)
    resizer:SetPoint("BOTTOMRIGHT", -4, 4)
    resizer:SetNormalTexture("Interface\\CHATFRAME\\UI-ChatIM-SizeGrabber-Up")
    resizer:SetHighlightTexture("Interface\\CHATFRAME\\UI-ChatIM-SizeGrabber-Highlight")
    resizer:SetPushedTexture("Interface\\CHATFRAME\\UI-ChatIM-SizeGrabber-Down")

    resizer:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            frame:StartSizing("BOTTOMRIGHT")
            frame.isResizing = true
        end
    end)

    resizer:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and frame.isResizing then
            frame:StopMovingOrSizing()
            frame.isResizing = nil
            -- Save new size
            local w, h = frame:GetSize()
            DNG_Saved.frameWidth = w
            DNG_Saved.frameHeight = h
        end
    end)

    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("DefNotGargul")

    -- Create scroll frame
    self.scrollFrame = CreateFrame("ScrollFrame", "DNGScrollFrame", frame, "UIPanelScrollFrameTemplate")
    self.scrollFrame:SetPoint("TOPLEFT", 10, -40)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    -- Create scroll child
    self.scrollChild = CreateFrame("Frame", nil, self.scrollFrame)
    self.scrollChild:SetSize(260, 1)
    self.scrollFrame:SetScrollChild(self.scrollChild)

    -- Access scrollbar if needed
    local sb = self.scrollFrame.ScrollBar

    -- Listen for system rolls
    local rollListener = CreateFrame("Frame")
    rollListener:RegisterEvent("CHAT_MSG_SYSTEM")
    rollListener:SetScript("OnEvent", function(_, _, msg)
        local player, roll, low, high = msg:match("(.+) rolls (%d+) %((%d+)%-(%d+)%)")
        if player and roll and low and high then
            roll = tonumber(roll)
            low = tonumber(low)
            high = tonumber(high)
            for itemLink, rollData in pairs(DNG.activeRolls) do
                if rollData.active and roll >= low and roll <= high then
                    rollData.rolls[player] = roll
                    print("|cff00ff00[DefNotGargul]|r " .. player .. " rolled " .. roll .. " for " .. itemLink)
                end
            end
        end
    end)
    

    -- Start a roll for an item
    function self:StartRoll(itemLink)
    if DNG.activeRolls[itemLink] and DNG.activeRolls[itemLink].active then
        print("|cffff0000[DefNotGargul]|r A roll for this item is already active!")
        return
    end

    -- read timer from settings (default to 30 if missing)
    local time = DNG_Saved.rollTime or 30

    DNG.activeRolls[itemLink] = { active = true, rolls = {} }
    SendChatMessage("ROLL STARTED for " .. itemLink .. " — type /roll! (" .. time .. " seconds)", "RAID_WARNING")

    C_Timer.After(time, function()
        if DNG.activeRolls[itemLink] and DNG.activeRolls[itemLink].active then
            self:EndRoll(itemLink)
        end
    end)
end


    -- End a roll for an item
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
        -- Always announce
        SendChatMessage("WINNER of " .. itemLink .. ": " .. highestPlayer .. " (" .. highestRoll .. ")", "RAID_WARNING")


        -- Auto-assign logic

        if DNG_Saved.autoAssign and DNG.AssignLoot then
        -- Find lootSlot inside memory list
            local lootSlot = nil
            for i = 1, GetNumLootItems() do
            local link = GetLootSlotLink(i)
                if link == itemLink then
                lootSlot = i
                break
            end
        end

        if lootSlot then
        -- Determine candidate index (1–40)
        local winnerIndex = nil
        for i = 1, 40 do
            local cand = GetMasterLootCandidate(lootSlot, i)
            if cand == highestPlayer then
                winnerIndex = i
                break
            end
        end

        if winnerIndex then

            ------------------------------------------------------
            -- 💠 DE HANDLER COMES HERE
            ------------------------------------------------------
            if DNG.HandleDEAssignment and DNG:HandleDEAssignment(lootSlot, highestPlayer, winnerIndex) then
                return -- DE assigned, stop
            end

            ------------------------------------------------------
            -- Normal auto-assign
            ------------------------------------------------------
            DNG:AssignLoot(lootSlot, highestPlayer, winnerIndex)

        else
            print("|cffff0000[DNG]|r Could not auto-assign: winner not found as master loot candidate.")
        end
    else
        print("|cffff0000[DNG]|r Could not auto-assign: lootSlot not found for item.")
    end
else
    print("|cffffff00[DNG]|r Auto-assign disabled. Lootmaster must trade manually.")
end


else
    SendChatMessage("No valid rolls for " .. itemLink, "RAID_WARNING")
end

    end

    -- Update memory UI
    function self:UpdateMemoryUI()
        -- Clear previous UI elements safely
        for _, child in ipairs(self.content) do
            if child then
                if child.Hide then child:Hide() end
                if child.SetParent and type(child.SetParent) == "function" and child:GetObjectType() == "Frame" then
                    child:SetParent(nil)
                end
            end
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

            -- Item icon
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

            -- Start Roll button
            local startRollBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            startRollBtn:SetSize(70, 22)
            startRollBtn:SetPoint("LEFT", 40, 0)
            startRollBtn:SetText("Start Roll")
            startRollBtn:SetScript("OnClick", function()
                self:StartRoll(itemLink)
            end)

            -- End Roll button
            local endRollBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            endRollBtn:SetSize(60, 22)
            endRollBtn:SetPoint("LEFT", 115, 0)
            endRollBtn:SetText("End Roll")
            endRollBtn:SetScript("OnClick", function()
                self:EndRoll(itemLink)
            end)

            -- Announce button
            local annBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            annBtn:SetSize(70, 22)
            annBtn:SetPoint("LEFT", 180, 0)
            annBtn:SetText("Announce")
            annBtn:SetScript("OnClick", function()
                SendChatMessage("Item: " .. itemLink, "RAID_WARNING")
            end)

            -- Discard button
            local delBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            delBtn:SetSize(60, 22)
            delBtn:SetPoint("LEFT", 255, 0)
            delBtn:SetText("Discard")
            delBtn:SetScript("OnClick", function()
                self.memory[itemLink] = nil
                self:UpdateMemoryUI()
                self:CheckIfEmpty()
            end)

            -- ✔ NEW: Store references for resizing
            line.icon = icon
            line.startRollBtn = startRollBtn
            line.endRollBtn = endRollBtn
            line.annBtn = annBtn
            line.delBtn = delBtn

            table.insert(self.content, line)
            y = y - 40
        end

        if count == 0 then
            local placeholder = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            placeholder:SetPoint("TOPLEFT", 0, -5)
            placeholder:SetText("No items in memory yet.")
            table.insert(self.content, placeholder)
        end

        local minHeight = self.scrollFrame:GetHeight()
        local totalHeight = math.max(count * 40 + 5, minHeight)
        self.scrollChild:SetHeight(totalHeight)

        -- ✔ Apply saved button/icon sizes
        DNG:ApplyButtonSizes()
        
    end

    -- Hook shift-clicks in bags to add items to memory
    hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, button)
        if IsShiftKeyDown() and button == "LeftButton" then
            local bag = self:GetParent():GetID()
            local slot = self:GetID()
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                DNG.memory = DNG.memory or {}
                if not DNG.memory[itemLink] then
                    DNG.memory[itemLink] = true
                    DNG:UpdateMemoryUI()
                    --print("|cff00ff00[DefNotGargul]|r Added " .. itemLink .. " via shift-click.")
                else
                    print("|cffffff00[DefNotGargul]|r " .. itemLink .. " is already in memory.")
                end
            end
        end
    end)

    -- DE label (top-right)
    DNG.deLabel = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    DNG.deLabel:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -10, -10)
    DNG.deLabel:SetText("")

    -- Update function
    function DNG:UpdateDELabel()
        if not DNG.deLabel then return end

            if DNG_Saved.deTarget and DNG_Saved.deTarget ~= "" then
                DNG.deLabel:SetText("|cffaaaaaaDE:|r " .. DNG_Saved.deTarget)
            else
         DNG.deLabel:SetText("|cffaaaaaaDE:|r none")
        end
    end

    -- Initial update
    DNG:UpdateDELabel()


end

--remove after trade
local tradeFrame = CreateFrame("Frame")
tradeFrame:RegisterEvent("TRADE_CLOSED")
tradeFrame:SetScript("OnEvent", function(_, event)
    if event == "TRADE_CLOSED" then
        -- Loop over memory to see if player still has items
        for itemLink,_ in pairs(DNG.memory) do
            local found = false
            for bag=0,4 do  -- check bags
                for slot=0,GetContainerNumSlots(bag)-1 do
                    local link = GetContainerItemLink(bag, slot)
                    if link == itemLink then
                        found = true
                        break
                    end
                end
                if found then break end
            end
            if not found then
                DNG.memory[itemLink] = nil
                --print("|cff00ff00[DefNotGargul]|r Removed " .. itemLink .. " after trade.")
            end
        end
        DNG:UpdateMemoryUI()
    end
end)


-- Apply sizes & visibility based on DNG_Saved (safe, uses defaults if missing)
function DNG:ApplyButtonSizes()
    if not self.content then return end

    -- ensure sane defaults if not present
    DNG_Saved.iconSize   = DNG_Saved.iconSize   or 32
    DNG_Saved.startWidth = DNG_Saved.startWidth or 70
    DNG_Saved.endWidth   = DNG_Saved.endWidth   or 60
    DNG_Saved.annWidth   = DNG_Saved.annWidth   or 70
    DNG_Saved.delWidth   = DNG_Saved.delWidth   or 60

    DNG_Saved.iconVisible  = (DNG_Saved.iconVisible == nil)  and true or DNG_Saved.iconVisible
    DNG_Saved.startVisible = (DNG_Saved.startVisible == nil) and true or DNG_Saved.startVisible
    DNG_Saved.endVisible   = (DNG_Saved.endVisible == nil)   and true or DNG_Saved.endVisible
    DNG_Saved.annVisible   = (DNG_Saved.annVisible == nil)   and true or DNG_Saved.annVisible
    DNG_Saved.delVisible   = (DNG_Saved.delVisible == nil)   and true or DNG_Saved.delVisible

    -- fixed heights keep proportions neat
    local defaultButtonHeight = 22

    for _, line in ipairs(self.content) do
        -- Icon
        if line.icon then
            if DNG_Saved.iconVisible then
                line.icon:Show()
                line.icon:SetSize(DNG_Saved.iconSize, DNG_Saved.iconSize)
            else
                line.icon:Hide()
            end
        end

        -- Start
        if line.startRollBtn then
            if DNG_Saved.startVisible then
                line.startRollBtn:Show()
                line.startRollBtn:SetSize(DNG_Saved.startWidth, defaultButtonHeight)
            else
                line.startRollBtn:Hide()
            end
        end

        -- End
        if line.endRollBtn then
            if DNG_Saved.endVisible then
                line.endRollBtn:Show()
                line.endRollBtn:SetSize(DNG_Saved.endWidth, defaultButtonHeight)
            else
                line.endRollBtn:Hide()
            end
        end

        -- Announce
        if line.annBtn then
            if DNG_Saved.annVisible then
                line.annBtn:Show()
                line.annBtn:SetSize(DNG_Saved.annWidth, defaultButtonHeight)
            else
                line.annBtn:Hide()
            end
        end

        -- Delete
        if line.delBtn then
            if DNG_Saved.delVisible then
                line.delBtn:Show()
                line.delBtn:SetSize(DNG_Saved.delWidth, defaultButtonHeight)
            else
                line.delBtn:Hide()
            end
        end
    end
end

function DNG:CheckIfEmpty()
    local hasItems = false
    for _, _ in pairs(self.memory) do
        hasItems = true
        break
    end

    if not hasItems and self.frame and self.frame:IsShown() then
        self.frame:Hide()
    end
end