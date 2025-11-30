local addonName, S = ...

S.SoftRes = {
    players = {},
    items = {},
}

------------------------------------------------------------
-- CSV Import
------------------------------------------------------------
function S:ImportSoftResCSV(csv)
    wipe(S.SoftRes.players)
    wipe(S.SoftRes.items)

    local countLines = 0
    for line in csv:gmatch("[^\r\n]+") do
        if not line:match("^Item,") then -- skip header
            countLines = countLines + 1
            local fields = {}
            for field in line:gmatch('([^,]+)') do
                field = field:gsub('^%"', ''):gsub('%"$', '') -- strip quotes
                table.insert(fields, field)
            end

            local itemName, itemId, boss, playerName = fields[1], tonumber(fields[2]), fields[3], fields[4]
            if not itemId or not playerName then
                print("|cffff0000[SoftRes]|r Skipping invalid line: " .. line)
            else
                -- store by player
                S.SoftRes.players[playerName] = S.SoftRes.players[playerName] or {}
                table.insert(S.SoftRes.players[playerName], itemId)

                -- store by item
                S.SoftRes.items[itemId] = S.SoftRes.items[itemId] or {}
                table.insert(S.SoftRes.items[itemId], playerName)

                print("|cff00ff00[SoftRes]|r Imported SR: " .. playerName .. " -> " .. itemName .. " (ID: " .. itemId .. ")")
            end
        end
    end

    print("|cff00ff00SoftRes CSV imported! Lines processed: " .. countLines .. "|r")
end


------------------------------------------------------------
-- Popup window to paste SoftRes CSV
------------------------------------------------------------
function S:ShowSoftResImportWindow()
    if S.SoftResImportFrame then
        S.SoftResImportFrame:Show()
        return
    end

    local f = CreateFrame("Frame", "DNGSoftResFrame", UIParent, "UIPanelDialogTemplate")
    f:SetSize(450, 350)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetToplevel(true)

    f:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then self:StartMoving() end
    end)
    f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText("Import SoftRes CSV Data")

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOP", f, "TOP", 0, -40)
    scroll:SetSize(400, 220)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject("ChatFontNormal")
    edit:SetWidth(380)
    edit:SetAutoFocus(true)

    scroll:SetScrollChild(edit)

    local importBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    importBtn:SetSize(120, 26)
    importBtn:SetPoint("BOTTOMLEFT", 20, 20)
    importBtn:SetText("Import CSV")

    importBtn:SetScript("OnClick", function()
        S:ImportSoftResCSV(edit:GetText())
        f:Hide()
    end)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetSize(120, 26)
    closeBtn:SetPoint("BOTTOMRIGHT", -20, 20)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    S.SoftResImportFrame = f
end

------------------------------------------------------------
-- Slash command
------------------------------------------------------------
SLASH_DNGSR1 = "/dngsr"
SlashCmdList["DNGSR"] = function()
    S:ShowSoftResImportWindow()
end

-- DEBUG: expose SoftRes globally for testing
_G["DNG_SoftRes"] = S.SoftRes
