local DNG = DefNotGargul

local panel = CreateFrame("Frame", "DefNotGargulSettingsPanel")
panel.name = "DefNotGargul"
InterfaceOptions_AddCategory(panel)

-- Title
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("DefNotGargul Settings")

-----------------------------------------------------------
-- HELPERS (No DNG_Saved calls here!)
-----------------------------------------------------------
local function CreateCheckbox(label, savedKey, x, y)
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb._label = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    cb._label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb._label:SetText(label)

    cb:SetScript("OnClick", function(self)
        if DNG_Saved then
            DNG_Saved[savedKey] = self:GetChecked()
            if DNG.ApplyButtonSizes then DNG:ApplyButtonSizes() end
        end
    end)
    return cb
end

local function CreateWidthSlider(label, savedKey, min, max, x, y)
    local s = CreateFrame("Slider", "DNGSlider_"..savedKey, panel, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", x, y)
    s:SetWidth(180)
    s:SetMinMaxValues(min, max)
    s:SetValueStep(1)

    local t = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    t:SetPoint("TOPLEFT", s, "BOTTOMLEFT", 0, -6)
    
    s:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val)
        if DNG_Saved then
            DNG_Saved[savedKey] = val
            t:SetText(label .. ": " .. val)
            if DNG.ApplyButtonSizes then DNG:ApplyButtonSizes() end
        end
    end)
    return s, t
end

-----------------------------------------------------------
-- CREATE CONTROLS
-----------------------------------------------------------
local iconCB  = CreateCheckbox("Show Icon", "iconVisible", 16, -60)
local startCB = CreateCheckbox("Show Start", "startVisible", 140, -60)
local endCB   = CreateCheckbox("Show End", "endVisible", 260, -60)
local delCB   = CreateCheckbox("Show Discard", "delVisible", 380, -60)

local iconSlider, iconLabel   = CreateWidthSlider("Icon Size", "iconSize", 16, 64, 16, -110)
local startSlider, startLabel = CreateWidthSlider("Start Width", "startWidth", 40, 140, 220, -110)

-----------------------------------------------------------
-- REFRESH FUNCTION (This is safe!)
-----------------------------------------------------------
function DNG:RefreshSettingsUI()
    if not DNG_Saved then return end
    
    iconCB:SetChecked(DNG_Saved.iconVisible)
    startCB:SetChecked(DNG_Saved.startVisible)
    endCB:SetChecked(DNG_Saved.endVisible)
    delCB:SetChecked(DNG_Saved.delVisible)
    
    iconSlider:SetValue(DNG_Saved.iconSize or 32)
    startSlider:SetValue(DNG_Saved.startWidth or 70)
end

-- This tells WoW to run the refresh when the options menu is opened
panel.refresh = function() DNG:RefreshSettingsUI() end