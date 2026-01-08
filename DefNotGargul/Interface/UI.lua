local DNG = DefNotGargul
DNG.activeRolls = {}
local addonName, S = ...

DNG.CLASS_COLORS = {
    ["DRUID"]   = "|cffFF7D0A",
    ["HUNTER"]  = "|cffABD473",
    ["MAGE"]    = "|cff69CCF0",
    ["PALADIN"] = "|cffF58CBA",
    ["PRIEST"]  = "|cffFFFFFF",
    ["ROGUE"]   = "|cffFFF569",
    ["SHAMAN"]  = "|cff0070DE",
    ["WARLOCK"] = "|cff9482C9",
    ["WARRIOR"] = "|cffC79C6E",
    ["DEATHKNIGHT"] = "|cffC41F3B",
    ["NONE"]    = "|cffAAAAAA", -- Gray for LC notes
}


-- Format SR player names (light blue for now, can be class colored later)
local function FormatSRNames(players)
    if not players or #players == 0 then return "none" end
    local names = {}
    for _, playerName in ipairs(players) do
        table.insert(names, "|cff66ccff"..playerName.."|r") -- light blue
    end
    return table.concat(names, ", ")
end


-- Always ensure memory and content tables exist
DNG.memory = DNG.memory or {}
DNG.content = DNG.content or {}

-- Apply saved button/icon sizes
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
    title:SetText("u suck")

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
        if player and roll then
            roll = tonumber(roll)
            -- Iterate through all active rolls to see which one this roll belongs to
            for dropID, rollData in pairs(DNG.activeRolls) do
                if rollData.active then
                    rollData.rolls[player] = roll
                    -- print("|cff00ff00[DNG]|r " .. player .. " rolled " .. roll .. " for item.")
                end
            end
        end
    end)
    

    -- Start a roll for an item
    function self:StartRoll(itemLink, dropID)
        -- Use dropID to check if this specific instance is already rolling
        if DNG.activeRolls[dropID] and DNG.activeRolls[dropID].active then
            print("|cffff0000[DefNotGargul]|r A roll for this specific item is already active!")
            return
        end

        local timeLimit = DNG_Saved.rollTime or 30
        
        -- Store the roll data using dropID as the key
        DNG.activeRolls[dropID] = { 
            active = true, 
            rolls = {}, 
            itemLink = itemLink -- store the link inside for easy access
        }

        local itemID = tonumber(itemLink:match("item:(%d+)"))
        local srText = "none"

        -- Soft Reserve Check (Using your existing SoftRes logic)
        if itemID and DNG_SoftRes and DNG_SoftRes.items[itemID] then
            local srPlayers = DNG_SoftRes.items[itemID]
            if #srPlayers > 0 then
                local countTable = {}
                for _, entry in ipairs(srPlayers) do
                    if entry.name then countTable[entry.name] = (countTable[entry.name] or 0) + 1 end
                end
                local output = {}
                for playerName, count in pairs(countTable) do
                    table.insert(output, playerName .. (count > 1 and (" x" .. count) or ""))
                end
                srText = table.concat(output, ", ")
            end
        end

        SendChatMessage("ROLL STARTED for " .. itemLink .. " — SR = " .. srText .. " — (" .. timeLimit .. "s)", "RAID_WARNING")

        -- 3.3.5 Timer Logic
        local timerFrame = CreateFrame("Frame")
        local elapsed = 0
        timerFrame:SetScript("OnUpdate", function(sf, e)
            elapsed = elapsed + e
            if elapsed >= timeLimit then
                sf:SetScript("OnUpdate", nil)
                if DNG.activeRolls[dropID] and DNG.activeRolls[dropID].active then
                    self:EndRoll(itemLink, dropID)
                end
            end
        end)
    end

    -- End a roll for an item
    function self:EndRoll(itemLink, dropID)
        local rollData = DNG.activeRolls[dropID]
        if not rollData or not rollData.active then return end

        rollData.active = false
        local highestPlayer, highestRoll = nil, -1

        -- 1. Find the Winner
        for player, roll in pairs(rollData.rolls) do
            if roll > highestRoll then
                highestRoll = roll
                highestPlayer = player
            end
        end

        if highestPlayer then
            local _, englishClass = UnitClass(highestPlayer)
            
            -- Prepare rolls for History
            local historyRolls = {}
            for name, val in pairs(rollData.rolls) do
                local _, pClass = UnitClass(name)
                table.insert(historyRolls, { player = name, roll = val, class = pClass or "NONE" })
            end

            -- 2. LOG TO HISTORY
            if DNG.LogLootAssignment then
                DNG:LogLootAssignment(itemLink, highestPlayer, englishClass or "NONE", historyRolls, "Roll Won", dropID)
            end

            SendChatMessage("WINNER of " .. itemLink .. ": " .. highestPlayer .. " (" .. highestRoll .. ")", "RAID_WARNING")

            -- 3. AUTO-ASSIGN (Master Loot)
            if DNG_Saved.autoAssign and DNG.AssignLoot then
                local lootSlot = nil
                for i = 1, GetNumLootItems() do
                    if GetLootSlotLink(i) == itemLink then
                        lootSlot = i
                        break
                    end
                end

                if lootSlot then
                    local winnerIndex = nil
                    for i = 1, 40 do
                        if GetMasterLootCandidate(lootSlot, i) == highestPlayer then
                            winnerIndex = i
                            break
                        end
                    end
                    if winnerIndex then
                        DNG:AssignLoot(lootSlot, highestPlayer, winnerIndex)
                    end
                end
            end
            
            -- NOTE: We removed the cleanup code here so the item stays in the list!
        else
            SendChatMessage("No valid rolls for " .. itemLink, "RAID_WARNING")
        end
    end

    -- Update memory UI
    function self:UpdateMemoryUI()
        for _, child in ipairs(self.content) do
            if child then
                if child.Hide then child:Hide() end
                if child.SetParent then child:SetParent(nil) end
            end
        end
        self.content = {}

        local y = -5
        local count = 0

        for index, itemData in ipairs(DNG.memory) do
            local itemLink = itemData.link
            local dropID = itemData.id 

            count = count + 1
            local line = CreateFrame("Frame", nil, self.scrollChild)
            line:SetSize(400, 40) -- Increased width for more buttons
            line:SetPoint("TOPLEFT", 0, y)

            -- Item icon
            local icon = CreateFrame("Button", nil, line)
            icon:SetSize(32, 32)
            icon:SetPoint("LEFT", 0, 0)
            icon.icon = icon:CreateTexture(nil, "BACKGROUND")
            icon.icon:SetAllPoints()
            icon.icon:SetTexture(GetItemIcon(itemLink) or "Interface\\Icons\\INV_Misc_QuestionMark")
            icon:SetScript("OnEnter", function(s) GameTooltip:SetOwner(s, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(itemLink); GameTooltip:Show() end)
            icon:SetScript("OnLeave", function() GameTooltip:Hide() end)

            -- 1. Start Roll (X: 35)
            local startBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            startBtn:SetSize(65, 22)
            startBtn:SetPoint("LEFT", 37, 0)
            startBtn:SetText("Start Roll")
            startBtn:SetScript("OnClick", function() self:StartRoll(itemLink, dropID) end)

            -- 2. End Roll (X: 100)
            local endBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            endBtn:SetSize(60, 22)
            endBtn:SetPoint("LEFT", 110, 0)
            endBtn:SetText("End Roll")
            endBtn:SetScript("OnClick", function() self:EndRoll(itemLink, dropID) end)

            -- 3. Announce (X: 160)
            local annBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            annBtn:SetSize(55, 22)
            annBtn:SetPoint("LEFT", 173, 0)
            annBtn:SetText("Announce")
            annBtn:SetScript("OnClick", function() SendChatMessage("LOOT: " .. itemLink .. "  ", "RAID_WARNING") end)

            -- 4. LC (X: 215)
            local lcBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            lcBtn:SetSize(40, 22)
            lcBtn:SetPoint("LEFT", 232, 0)
            lcBtn:SetText("LC")
            lcBtn:SetScript("OnClick", function()
                local dialog = StaticPopup_Show("DNG_LC_CONFIRM", itemLink)
                if dialog then dialog.data = { itemLink = itemLink, dropID = dropID } end
            end)

            -- 5. DE (X: 255) - THE MISSING BUTTON
            local deBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            deBtn:SetSize(40, 22)
            deBtn:SetPoint("LEFT", 275, 0)
            deBtn:SetText("DE")
            deBtn:SetScript("OnClick", function()
                if DNG.LogLootAssignment then
                    DNG:LogLootAssignment(itemLink, "Disenchanted", "NONE", {}, "DE", dropID)
                end
                for i, data in ipairs(DNG.memory) do if data.id == dropID then table.remove(DNG.memory, i); break end end
                self:UpdateMemoryUI()
                self:CheckIfEmpty()
            end)

            -- 6. Discard (X: 300)
            local delBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
            delBtn:SetSize(65, 22)
            delBtn:SetPoint("LEFT", 318, 0)
            delBtn:SetText("Discard")
            delBtn:SetScript("OnClick", function()
                for i, data in ipairs(DNG.memory) do if data.id == dropID then table.remove(DNG.memory, i); break end end
                self:UpdateMemoryUI()
                self:CheckIfEmpty()
            end)

            -- Store for resizing
            line.icon, line.startRollBtn, line.endRollBtn, line.annBtn, line.lcBtn, line.deBtn, line.delBtn = icon, startBtn, endBtn, annBtn, lcBtn, deBtn, delBtn

            table.insert(self.content, line)
            y = y - 40
        end

        local totalHeight = math.max(count * 40 + 5, self.scrollFrame:GetHeight())
        self.scrollChild:SetHeight(totalHeight)
        DNG:ApplyButtonSizes()
    end

    -- Hook shift-clicks in bags to add items to memory
    hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, button)
        if IsShiftKeyDown() and button == "RightButton" then
            local bag = self:GetParent():GetID()
            local slot = self:GetID()
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                DNG.memory = DNG.memory or {}
                if not DNG.memory[itemLink] then
                    DNG.memory[itemLink] = true
                    DNG:UpdateMemoryUI()
                    
                    if DNG.frame then
                        DNG.frame:Show()
                    end
                    
                    --print("|cff00ff00[DefNotGargul]|r Added " .. itemLink .. " via shift-click.")
                else
                    print("|cffffff00[DefNotGargul]|r " .. itemLink .. " is already in memory.")
                end
            end
        end
    end)

    -- DE label (top-right)
    DNG.deLabel = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    DNG.deLabel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 60, -12)
    DNG.deLabel:SetText("")

    --  create the "Set DE" Button
    local setDEBtn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    setDEBtn:SetSize(50, 18)
    -- Position it to the left of the label in the top right
    setDEBtn:SetPoint("TOPRIGHT", self.frame, "TOPLEFT", 60, -8) 
    setDEBtn:SetText("Set DE")
    
    setDEBtn:SetScript("OnClick", function()
        -- Logic: If you have a player targeted, set them. 
        -- If no target, it clears the DE.
        if UnitExists("target") and UnitIsPlayer("target") then
            local name = UnitName("target")
            DNG_Saved.deTarget = name:lower():gsub("^%l", string.upper)
            print("|cff00ff00[DNG]|r Disenchanter set to: " .. DNG_Saved.deTarget)
        else
            DNG_Saved.deTarget = ""
            print("|cffff0000[DNG]|r Disenchanter cleared.")
        end
        
        DNG:UpdateDELabel() -- Refresh the text immediately
    end)

    -- Optional Tooltip for the button
    setDEBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Set Disenchanter")
        GameTooltip:AddLine("Target a player and click to assign.", 1, 1, 1)
        GameTooltip:AddLine("Click with no target to clear.", 1, 1, 1)
        GameTooltip:Show()
    end)
    setDEBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Update function
    function DNG:UpdateDELabel()
        if not self.deLabel then return end

        -- Check if target exists and is not an empty string
        if DNG_Saved.deTarget and DNG_Saved.deTarget ~= "" then
            self.deLabel:SetText("|cffaaaaaaDE:|r |cff00ff00" .. DNG_Saved.deTarget .. "|r")
        else
            self.deLabel:SetText("|cffaaaaaaDE:|r |cffff0000none|r")
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