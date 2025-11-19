-- SoftRes.lua
local addonName, S = ...

-- storage table
S.SoftRes = {
    players = {},
    items = {},
}

-- import GUI frame
S.SoftResImportFrame = nil

-- forward declarations
local DecodeSoftResString, ProcessSoftResData

-- Libs
local LibDeflate = LibStub("LibDeflate")
local LibJSON = LibStub("LibJSON-1.0") -- make sure the hyphen is a normal dash!
if not LibJSON then
    error("LibJSON-1.0 is required for SoftRes import JSON decoding.")
end

-- decode base64 + zlib + JSON
function DecodeSoftResString(str)
    local decoded = LibDeflate:DecodeForPrint(str)
    if not decoded then return nil end

    local decompressed = LibDeflate:DecompressZlib(decoded)
    if not decompressed then return nil end

    local success, data = pcall(LibJSON.Deserialize, decompressed)
    if not success then return nil end

    return data
end

function ProcessSoftResData(data)
    wipe(S.SoftRes.players)
    wipe(S.SoftRes.items)

    if not data or not data.players then
        print("|cffff0000Invalid SR data.|r")
        return
    end

    for player, items in pairs(data.players) do
        S.SoftRes.players[player] = {}

        for _, itemID in ipairs(items) do
            table.insert(S.SoftRes.players[player], itemID)
            S.SoftRes.items[itemID] = S.SoftRes.items[itemID] or {}
            table.insert(S.SoftRes.items[itemID], player)
        end
    end
end

function S:ImportSoftRes(str)
    if not str or str:trim() == "" then
        print("|cffff0000No soft-res string provided!|r")
        return
    end

    local data = DecodeSoftResString(str)
    if not data then
        print("|cffff0000SoftRes import failed (decode error).|r")
        return
    end

    ProcessSoftResData(data)
    print("|cff00ff00SoftRes data imported successfully.|r")
end

function S:ShowSoftResImportWindow()
    if S.SoftResImportFrame then
        S.SoftResImportFrame:Show()
        return
    end

    local f = CreateFrame("Frame", "DNGSoftResFrame", UIParent, "UIPanelDialogTemplate")
    f:SetSize(400, 300)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetToplevel(true)
    f:SetFrameStrata("DIALOG")

    f:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then self:StartMoving() end
    end)
    f:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
    end)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText("Import SoftRes.it Data")

    local edit = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    edit:SetMultiLine(true)
    edit:SetSize(360, 200)
    edit:SetPoint("TOP", 0, -40)
    edit:SetAutoFocus(false)
    edit:EnableMouse(true)
    edit:SetFontObject("GameFontHighlight")
    edit:SetMaxLetters(99999)
    edit:SetTextInsets(5, 5, 5, 5)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    edit:SetScript("OnEnterPressed", nil) -- allow multiline

    local importBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    importBtn:SetSize(100, 24)
    importBtn:SetPoint("BOTTOMLEFT", 20, 20)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function()
        S:ImportSoftRes(edit:GetText())
        f:Hide()
    end)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetSize(100, 24)
    closeBtn:SetPoint("BOTTOMRIGHT", -20, 20)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    S.SoftResImportFrame = f
end

-- Slash command
SLASH_DNGSR1 = "/dngsr"
SlashCmdList["DNGSR"] = function()
    S:ShowSoftResImportWindow()
end
