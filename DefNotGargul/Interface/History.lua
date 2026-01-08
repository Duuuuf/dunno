local DNG = DefNotGargul
DNG.historyView = "Raids"
DNG._raidButtons = {}
DNG._expandedRaids = DNG._expandedRaids or {}
DNG.historyView = "Raids" -- Options: "Raids", "Summary"
DNG.summarySortMode = "Loot" -- Options: "Loot", "Class"


function DNG:InitializeHistory()
    -- 1) Ensure the main saved variable exists
    DNG_Saved = DNG_Saved or {}

    -- 2) Ensure the History sub-table exists inside the saved variable
    if not DNG_Saved.History then
        DNG_Saved.History = { raids = {} }
    end

    -- 3) Point DNG.History to the saved version
    -- Now, whenever you change DNG.History, it automatically changes DNG_Saved.History
    self.History = DNG_Saved.History
end

------------------------------------------------------------
-- Create History UI
------------------------------------------------------------
function DNG:CreateHistoryUI()
    if self.historyFrame then return end

    local f = CreateFrame("Frame", "DNGHistoryFrame", UIParent)
    f:SetSize(500, 400)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16
    })
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    -- CLOSE BUTTON (The Red X)
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)

    -- Sorting Toggle Button (Replacing the BiS Filter)
    local sortBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    sortBtn:SetSize(100, 22)
    sortBtn:SetPoint("TOPRIGHT", -30, -10) -- Right side of the window
    sortBtn:SetText("Sort: Loot")
    
    sortBtn:SetScript("OnClick", function(self)
        if DNG.summarySortMode == "Loot" then
            DNG.summarySortMode = "Class"
            self:SetText("Sort: Class")
        else
            DNG.summarySortMode = "Loot"
            self:SetText("Sort: Loot")
        end
        DNG:UpdateHistoryUI() -- Refresh the view
    end)
    
    -- Store reference so we can hide it when not in Summary view
    self.sortBtn = sortBtn

    -- View Toggle Button (Summary vs Raids)
    local viewBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    viewBtn:SetSize(100, 22)
    viewBtn:SetPoint("TOPLEFT", 10, -10) -- Top left corner
    viewBtn:SetText("View: Raids")
    
    viewBtn:SetScript("OnClick", function(self)
        if DNG.historyView == "Raids" then
            DNG.historyView = "Summary"
            self:SetText("View: Summary")
        else
            DNG.historyView = "Raids"
            self:SetText("View: Raids")
        end
        DNG:UpdateHistoryUI()
    end)

    -- 1) Clear History Button (for Raid View)
    local clearHistoryBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearHistoryBtn:SetSize(100, 22)
    clearHistoryBtn:SetPoint("TOPRIGHT", -130, -10) 
    clearHistoryBtn:SetText("Clear History")
    clearHistoryBtn:SetScript("OnClick", function() StaticPopup_Show("DNG_CONFIRM_CLEAR_HISTORY") end)
    self.clearHistoryBtn = clearHistoryBtn -- Store reference

    -- 2) Clear Roster Button (for Summary View)
    local clearRosterBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearRosterBtn:SetSize(100, 22)
    clearRosterBtn:SetPoint("TOPRIGHT", -130, -10) -- SAME POSITION AS ABOVE
    clearRosterBtn:SetText("Clear Roster")
    clearRosterBtn:SetScript("OnClick", function() StaticPopup_Show("DNG_CONFIRM_CLEAR_ROSTER") end)
    self.clearRosterBtn = clearRosterBtn -- Store reference

    -- Export Button
    local exportBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    exportBtn:SetSize(80, 22)
    -- Position it next to Clear History
    exportBtn:SetPoint("TOPLEFT", 125, -10) 
    exportBtn:SetText("Export")
    
    exportBtn:SetScript("OnClick", function()
        local data = DNG:GenerateCSV()
        DNG:ShowExportWindow(data)
    end)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", -10, -10)
    title:SetText("=^..^=")

    local scroll = CreateFrame("ScrollFrame", "DNGHistoryScrollFrame", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -40)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)

    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(scroll:GetWidth(), 1)
    scroll:SetScrollChild(scrollChild)
    scroll:SetScript("OnSizeChanged", function(_, width)
        scrollChild:SetWidth(width)
    end)

    self.historyFrame = f
    self.historyScrollFrame = scroll
    self.historyScrollChild = scrollChild

    -- (Mr. Bigglesworth) 
    local mascot = CreateFrame("Button", nil, f)
    mascot:SetSize(32, 32)
    mascot:SetPoint("TOPRIGHT", f, "TOPRIGHT", -50, -6) 
    
    -- This ensures it stays on top of the background texture
    mascot:SetFrameLevel(f:GetFrameLevel() + 20)
    mascot:SetFrameStrata("HIGH")

    mascot:SetNormalTexture("Interface\\AddOns\\DefNotGargul\\Media\\Void.tga")
    


    mascot:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Mr. Bigglesworth")
        GameTooltip:AddLine("|cff00ff00'Meow!'|r", 1, 1, 1)
        GameTooltip:AddLine("Naxxramas Loot Supervisor", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    mascot:SetScript("OnLeave", function() GameTooltip:Hide() end)

    mascot:SetScript("OnClick", function()
        PlaySoundFile("Sound\\Creature\\Cat\\CatMeow.wav")
        print("|cff66ccff[Void]:|r Meow! (Kel'Thuzad is watching your loot choices!)")
    end)

    self.historyMascot = mascot
end


-- Update History UI
function DNG:UpdateHistoryUI()
    if not self.historyScrollChild then return end

    ------------------------------------------------------------
    -- 1) FULL CLEANUP (Moved to top so we start with a blank slate)
    ------------------------------------------------------------
    for _, btn in pairs(self._raidButtons or {}) do
        btn:Hide()
        if btn._itemLines then
            for _, line in ipairs(btn._itemLines) do line:Hide() end
        end
    end

    -- Hide Summary headers and Mascot
    if self._summaryHeader then self._summaryHeader:Hide() end
    if self._othersHeader then self._othersHeader:Hide() end
    if self.historyMascot then self.historyMascot:Hide() end -- Hide cat here first

    -- Hide all Summary Player Lines
    if self._playerLines then
        for _, line in ipairs(self._playerLines) do line:Hide() end
    end


    ------------------------------------------------------------
    -- 2) RESET UI VIEW STATE (Now we show only what is needed)
    ------------------------------------------------------------
    if self.historyView == "Raids" then
        if self.clearHistoryBtn then self.clearHistoryBtn:Show() end
        if self.clearRosterBtn then self.clearRosterBtn:Hide() end
        
        -- NOW the cat will stay visible because the cleanup is finished
        if self.historyMascot then 
            self.historyMascot:Show() 
        end
    else
        if self.clearHistoryBtn then self.clearHistoryBtn:Hide() end
        if self.clearRosterBtn then self.clearRosterBtn:Show() end
        
        if self.historyMascot then self.historyMascot:Hide() end
    end
    
    -- Show/Hide Sort button based on view
    if self.sortBtn then
        if self.historyView == "Summary" then self.sortBtn:Show() else self.sortBtn:Hide() end
    end

    local y = -5

    ------------------------------------------------------------
    -- 2) DRAW RAIDS VIEW
    ------------------------------------------------------------
    if self.historyView == "Raids" then
        local raids = self.History.raids or {}
        
        -- Sort: Newest Raid at the top
        local sortedRaids = {}
        for name, data in pairs(raids) do table.insert(sortedRaids, {name = name, data = data}) end
        table.sort(sortedRaids, function(a,b) return (a.data.timestamp or 0) > (b.data.timestamp or 0) end)

        for _, raidInfo in ipairs(sortedRaids) do
            local raidName = raidInfo.name
            local raidData = raidInfo.data
            local headerButton = self._raidButtons[raidName]

            if not headerButton then
                headerButton = CreateFrame("Button", nil, self.historyScrollChild)
                headerButton:SetSize(self.historyScrollChild:GetWidth(), 20)
                headerButton:SetScript("OnClick", function()
                    self._expandedRaids[raidName] = not self._expandedRaids[raidName]
                    self:UpdateHistoryUI()
                end)
                local headerText = headerButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                headerText:SetPoint("LEFT", 4, 0)
                headerText:SetText(raidName)
                headerText:SetTextColor(1, 0.82, 0)
                headerButton._itemLines = {}
                self._raidButtons[raidName] = headerButton
            end

            headerButton:SetPoint("TOPLEFT", 0, y)
            headerButton:Show()
            y = y - 20

            if self._expandedRaids[raidName] then
                local lines = headerButton._itemLines
                local visibleLineIndex = 0

                for _, item in ipairs(raidData.items or {}) do
                    -- Filter Logic
                    local itemID = item.itemID or (item.itemLink and tonumber(item.itemLink:match("item:(%d+)")))
                    local isBiS = false
                    local whitelistEntry = (itemID and DNG.RAID_ITEM_IDS) and DNG.RAID_ITEM_IDS[itemID]
                    if type(whitelistEntry) == "table" and whitelistEntry.bis then isBiS = true end

                    local shouldShow = true
                    if DNG.currentHistoryFilter == "BiSeS" and not isBiS then shouldShow = false end

                    if shouldShow then
                        visibleLineIndex = visibleLineIndex + 1
                        local line = lines[visibleLineIndex]
                        if not line then
                            line = CreateFrame("Button", nil, self.historyScrollChild)
                            line:SetSize(self.historyScrollChild:GetWidth() - 20, 18)
                            line._itemText = line:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                            line._itemText:SetPoint("LEFT", 0, 0)

                            -- ROBUST TOOLTIP LOGIC
                            line:SetScript("OnEnter", function(s)
                                GameTooltip:SetOwner(s, "ANCHOR_CURSOR") -- Changed to ANCHOR_CURSOR
                                local data = s._itemData
                                if not data then return end

                                -- 1. Show Item Tooltip
                                if data.link and data.link ~= "" then
                                    GameTooltip:SetHyperlink(data.link)
                                elseif data.name then
                                    GameTooltip:SetText(data.name)
                                end

                                -- 2. Append Rolls
                                if data.rolls and #data.rolls > 0 then
                                    GameTooltip:AddLine(" ")
                                    GameTooltip:AddLine("Rolls:")
                                    for _, r in ipairs(data.rolls) do
                                        local rClassKey = (r.class or "NONE"):upper()
                                        local rColor = DNG.CLASS_COLORS[rClassKey] or "|cffFFFFFF"

                                        GameTooltip:AddLine(rColor .. r.player .. "|r — " .. r.roll)
                                    end
                                end
                                GameTooltip:Show()
                            end)
                            line:SetScript("OnLeave", function() GameTooltip:Hide() end)

                            lines[visibleLineIndex] = line
                        end

                        -- GET PROPER LINK AND NAME
                        local iName, iLink, iQuality
                        if item.itemLink then
                            iLink = item.itemLink
                            iName, _, iQuality = GetItemInfo(iLink)
                        elseif item.itemID then
                            iName, iLink, iQuality = GetItemInfo(item.itemID)
                        end

                        -- STORE FOR TOOLTIP
                        line._itemData = { 
                            link = iLink, 
                            name = iName or "Item", 
                            rolls = item.rolls 
                        }

                        local winnerName = item.winner or "Unknown"
                        local classKey = (item.winnerClass or "NONE"):upper()
                        local classColor = DNG.CLASS_COLORS[classKey] or "|cffFFFFFF"
                        local disp = iLink or iName or ("Item:"..itemID)
                        if isBiS then disp = disp .. " |cffffd100[BiS]|r" end

                        line._itemText:SetText(disp .. " — " .. classColor .. winnerName .. "|r")
                        
                        local r, g, b = 1,1,1
                        if iQuality and iQuality > 0 then r, g, b = GetItemQualityColor(iQuality) end
                        line._itemText:SetTextColor(r, g, b)

                        line:SetPoint("TOPLEFT", 20, y)
                        line:Show()
                        y = y - 18
                    end
                end
            end
        end

    ------------------------------------------------------------
    -- 3) DRAW SUMMARY VIEW (ROSTER + OTHERS)
    ------------------------------------------------------------
    else
        local mainSummary = {}
        local otherSummary = {}
        
        -- 1. Pre-fill the Main Roster with 0 items
        if DNG_Saved.Roster then
            for name, class in pairs(DNG_Saved.Roster) do
                mainSummary[name] = { count = 0, items = {}, class = class, isMain = true }
            end
        end

        -- 2. Aggregate Data from History
        for _, raidData in pairs(self.History.raids or {}) do
            for _, item in ipairs(raidData.items or {}) do
                local name = item.winner or "Unknown"
                
                -- Determine which list they belong to
                local targetList = mainSummary[name] and mainSummary or otherSummary
                
                if not targetList[name] then
                    targetList[name] = { count = 0, items = {}, class = item.winnerClass }
                end
                
                targetList[name].count = targetList[name].count + 1
                table.insert(targetList[name].items, item.itemLink or item.itemID)
            end
        end

        if not self._summaryHeader then
            self._summaryHeader = self.historyScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            self._summaryHeader:SetPoint("TOPLEFT", 10, -5)
            self._summaryHeader:SetText("Main Roster Loot")
        end
        self._summaryHeader:Show()
        y = -35

        self._playerLines = self._playerLines or {}
        local pIndex = 0

        -- Helper function to draw lines with dynamic sorting
        local function DrawPlayerLines(dataList, isMainGroup)
            local sorted = {}
            for name, data in pairs(dataList) do table.insert(sorted, {name = name, data = data}) end

            -- NEW SORTING LOGIC
            table.sort(sorted, function(a, b)
                if DNG.summarySortMode == "Class" then
                    -- Primary Sort: Class Name
                    if a.data.class ~= b.data.class then
                        return (a.data.class or "") < (b.data.class or "")
                    end
                    -- Secondary Sort: Player Name (Alphabetical)
                    return a.name < b.name
                else
                    -- Primary Sort: Items Won (Highest first)
                    if a.data.count ~= b.data.count then
                        return a.data.count > b.data.count
                    end
                    -- Secondary Sort: Player Name
                    return a.name < b.name
                end
            end)

            for _, pInfo in ipairs(sorted) do
                pIndex = pIndex + 1
                local line = self._playerLines[pIndex]
                
                if not line then
                    line = CreateFrame("Button", nil, self.historyScrollChild)
                    line:SetSize(self.historyScrollChild:GetWidth() - 20, 20)
                    line._text = line:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    line._text:SetPoint("LEFT", 10, 0)
                    self._playerLines[pIndex] = line
                end

                local cCol = DNG.CLASS_COLORS[pInfo.data.class] or "|cffFFFFFF"
                line._text:SetText(cCol .. pInfo.name .. "|r: " .. pInfo.data.count .. " items won")
                
                line:SetScript("OnEnter", function(s)
                    GameTooltip:SetOwner(s, "ANCHOR_CURSOR")
                    GameTooltip:AddLine(pInfo.name .. "'s Total Loot", 1, 1, 1)
                    if pInfo.data.count == 0 then
                        GameTooltip:AddLine("No items won yet.", 0.5, 0.5, 0.5)
                    else
                        for _, link in ipairs(pInfo.data.items) do GameTooltip:AddLine(link) end
                    end
                    GameTooltip:Show()
                end)
                line:SetScript("OnLeave", function() GameTooltip:Hide() end)

                line:SetPoint("TOPLEFT", 0, y)
                line:Show()
                y = y - 20
            end
        end

        -- DRAW MAIN ROSTER
        DrawPlayerLines(mainSummary, true)

        -- DRAW SEPARATOR & OTHERS
        y = y - 10
        if not self._othersHeader then
            self._othersHeader = self.historyScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self._othersHeader:SetText("|cffaaaaaa--- Non-Roster / LC Notes ---|r")
        end
        self._othersHeader:SetPoint("TOPLEFT", 10, y)
        self._othersHeader:Show()
        y = y - 20

        DrawPlayerLines(otherSummary, false)
    end

    self.historyScrollChild:SetHeight(math.max(-y + 10, self.historyScrollFrame:GetHeight()))


end

------------------------------------------------------------
-- Slash command: /dnghistory
------------------------------------------------------------
SLASH_DNGHISTORY1 = "/dnghistory"
SlashCmdList["DNGHISTORY"] = function()
    if not DNG.historyFrame then 
        DNG:CreateHistoryUI() 
    end
    
    if DNG.historyFrame:IsShown() then
        DNG.historyFrame:Hide()
    else
        -- THE FIX: Update the UI before showing it
        DNG:UpdateHistoryUI() 
        DNG.historyFrame:Show()
    end
end

-- Also update the ShowHistory function for consistency
function DNG:ShowHistory()
    if not self.historyFrame then self:CreateHistoryUI() end
    self:UpdateHistoryUI() -- Ensure data is drawn
    self.historyFrame:Show()
end

function DNG:LogManualLoot(itemLink, note)
    local raidName = GetInstanceInfo() or "Manual Log"
    local raidKey = raidName .. " (" .. date("%m/%d/%y") .. ")"
    
    -- Ensure the raid entry exists
    self.History.raids[raidKey] = self.History.raids[raidKey] or { items = {}, timestamp = time() }
    
    local entry = {
        itemLink = itemLink,
        winner = note, -- We save the note as the winner
        winnerClass = "NONE", -- Gray color for LC notes
        rolls = {},
        time = time()
    }
    
    table.insert(self.History.raids[raidKey].items, entry)
    print("|cff00ff00[DNG]|r Recorded " .. itemLink .. " for " .. note)
end

StaticPopupDialogs["DNG_CONFIRM_CLEAR_HISTORY"] = {
    text = "Are you sure you want to clear ALL raid history? This cannot be undone.",
    button1 = "Yes, Clear It",
    button2 = "Cancel",
    OnAccept = function()
        -- The "wipe" function is the safest way to empty a table 
        -- while keeping the link to DNG_Saved intact.
        wipe(DNG.History.raids)
        
        -- Refresh the UI so it shows an empty list immediately
        DNG:UpdateHistoryUI()
        
        print("|cff00ff00[DNG]|r History has been cleared.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true, -- Adds the yellow triangle exclamation icon
}

function DNG:ShowExportWindow(text)
    if not self.exportFrame then
        local f = CreateFrame("Frame", "DNGExportFrame", UIParent)
        f:SetSize(450, 300)
        f:SetPoint("CENTER")
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 16,
        })
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetFrameStrata("DIALOG")

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Export CSV (Ctrl+C to Copy)")

        -- Multi-line EditBox for the CSV data
        local scroll = CreateFrame("ScrollFrame", "DNGExportScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 15, -45)
        scroll:SetPoint("BOTTOMRIGHT", -35, 45)

        local eb = CreateFrame("EditBox", nil, scroll)
        eb:SetMultiLine(true)
        eb:SetMaxLetters(99999)
        eb:SetFontObject("ChatFontNormal")
        eb:SetWidth(380)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        scroll:SetScrollChild(eb)

        -- Close Button
        local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        close:SetSize(100, 25)
        close:SetPoint("BOTTOM", 0, 15)
        close:SetText("Close")
        close:SetScript("OnClick", function() f:Hide() end)

        self.exportFrame = f
        self.exportEditBox = eb
    end

    self.exportEditBox:SetText(text)
    self.exportFrame:Show()
    self.exportEditBox:HighlightText() -- Auto-highlight everything for easy copying
    self.exportEditBox:SetFocus()
end

function DNG:GenerateCSV()
    -- Updated Header to include ItemName
    local csv = "Raid,Date,Winner,ItemID,ItemName\n" 
    
    for raidName, raidData in pairs(self.History.raids or {}) do
        local dateStr = date("%Y-%m-%d", raidData.timestamp or time())
        
        for _, item in ipairs(raidData.items or {}) do
            local winner = item.winner or "Unknown"
            
            -- 1) Get the Item ID
            local itemID = item.itemID or (item.itemLink and item.itemLink:match("item:(%d+)")) or "0"
            
            -- 2) Get the Item Name
            -- We try to get it from the link first, then ID
            local itemName = GetItemInfo(item.itemLink or item.itemID) or "Unknown Item"
            
            -- 3) Sanitization (CRITICAL for CSV)
            -- Remove commas from Raid Name and Item Name so they don't break columns
            local cleanRaidName = raidName:gsub(",", "") 
            local cleanItemName = itemName:gsub(",", "")
            
            -- 4) Format: Raid, Date, Winner, ItemID, ItemName
            csv = csv .. cleanRaidName .. "," .. dateStr .. "," .. winner .. "," .. itemID .. "," .. cleanItemName .. "\n"
        end
    end
    
    return csv
end

StaticPopupDialogs["DNG_CONFIRM_CLEAR_ROSTER"] = {
    text = "Are you sure you want to wipe the ENTIRE 25-man roster? This will not delete loot history, only the list of players.",
    button1 = "Yes, Clear Roster",
    button2 = "Cancel",
    OnAccept = function()
        -- Wipe the roster table
        wipe(DNG_Saved.Roster)
        
        -- Refresh the UI
        DNG:UpdateHistoryUI()
        print("|cff00ff00[DNG]|r Roster has been cleared.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
}

function DNG:LogLootAssignment(itemLink, winnerName, winnerClass, rolls, note, dropID)
    local raidName = GetRealZoneText() or "Unknown Raid"
    local raidKey = raidName .. " (" .. date("%m/%d/%y") .. ")"

    if not self.History.raids[raidKey] then
        self.History.raids[raidKey] = { timestamp = time(), items = {} }
    end

    local itemsList = self.History.raids[raidKey].items
    local existingEntry = nil

    -- Check if this specific drop instance (dropID) already exists
    if dropID then
        for _, entry in ipairs(itemsList) do
            if entry.dropID == dropID then
                existingEntry = entry
                break
            end
        end
    end

    if existingEntry then
        -- Update existing (Re-roll)
        existingEntry.winner = winnerName
        existingEntry.winnerClass = winnerClass
        existingEntry.rolls = rolls
    else
        -- Create new (New item or first time logging)
        table.insert(itemsList, {
            dropID = dropID, -- Save the unique ID here
            itemLink = itemLink,
            winner = winnerName,
            winnerClass = winnerClass,
            rolls = rolls,
            time = time()
        })
    end
    
    
end