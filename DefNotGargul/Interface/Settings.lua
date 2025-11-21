-- Interface/Settings.lua (simple, safe version)
local DNG = DefNotGargul

-- Create settings panel for Interface Options
local panel = CreateFrame("Frame", "DefNotGargulSettingsPanel")
panel.name = "DefNotGargul"
InterfaceOptions_AddCategory(panel)

DNG_Saved.rollTime = DNG_Saved.rollTime or 30

-- Title
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("DefNotGargul Settings")

local slider = CreateFrame("Slider", "DNGRollTimerSlider", panel, "OptionsSliderTemplate")
slider:SetPoint("TOPLEFT", 20, -300)
slider:SetMinMaxValues(10, 30)
slider:SetValueStep(5)
slider:SetValue(DNG_Saved.rollTime)

DNGRollTimerSliderLow:SetText("10s")
DNGRollTimerSliderHigh:SetText("30s")
DNGRollTimerSliderText:SetText("Roll Timer: " .. DNG_Saved.rollTime .. "s")

slider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value)
    DNG_Saved.rollTime = value
    DNGRollTimerSliderText:SetText("Roll Timer: " .. value .. "s")
end)


-- helper to create a manual checkbox (works in Wrath)
local function CreateCheckbox(label, savedKey, x, y)
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)

    -- create label text manually (safe)
    cb._label = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    cb._label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb._label:SetText(label)

    -- ensure saved default true if nil
    if DNG_Saved[savedKey] == nil then DNG_Saved[savedKey] = true end
    cb:SetChecked(DNG_Saved[savedKey])

    cb:SetScript("OnClick", function(self)
        DNG_Saved[savedKey] = self:GetChecked()
        if DNG.ApplyButtonSizes then DNG:ApplyButtonSizes() end
    end)

    return cb
end

-- helper to create a simple width slider (value displayed)
local function CreateWidthSlider(label, savedKey, min, max, x, y, default)
    local s = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", x, y)
    s:SetWidth(200)
    s:SetMinMaxValues(min, max)
    s:SetValueStep(1)
    if DNG_Saved[savedKey] == nil then DNG_Saved[savedKey] = default end
    s:SetValue(DNG_Saved[savedKey])

    -- label and value display below the slider (compact)
    local t = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    t:SetPoint("TOPLEFT", s, "BOTTOMLEFT", 0, -6)
    t:SetText(label .. ": " .. DNG_Saved[savedKey])

    s:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val)
        DNG_Saved[savedKey] = val
        t:SetText(label .. ": " .. val)
        if DNG.ApplyButtonSizes then DNG:ApplyButtonSizes() end
    end)

    return s, t
end

-- Defaults (keep these the same as your UI defaults)
local defaults = {
    iconSize = 32,
    startWidth = 70,
    endWidth = 60,
    annWidth = 70,
    delWidth = 60,
}

-- Icon slider + checkbox
local iconCB = CreateCheckbox("Show Item Icon", "iconVisible", 16, -60)
local iconSlider, iconLabel = CreateWidthSlider("Icon Size", "iconSize", 16, 64, 16, -100, defaults.iconSize)

-- Start Roll slider + checkbox
local startCB = CreateCheckbox("Show Start Roll", "startVisible", 260, -60)
local startSlider, startLabel = CreateWidthSlider("Start Width", "startWidth", 40, 140, 260, -100, defaults.startWidth)

-- End Roll slider + checkbox
local endCB = CreateCheckbox("Show End Roll", "endVisible", 500, -60)
local endSlider, endLabel = CreateWidthSlider("End Width", "endWidth", 40, 140, 500, -100, defaults.endWidth)

-- Announce slider + checkbox
local annCB = CreateCheckbox("Show Announce", "annVisible", 16, -160)
local annSlider, annLabel = CreateWidthSlider("Announce Width", "annWidth", 40, 140, 16, -200, defaults.annWidth)

-- Discard slider + checkbox
local delCB = CreateCheckbox("Show Discard", "delVisible", 260, -160)
local delSlider, delLabel = CreateWidthSlider("Discard Width", "delWidth", 40, 140, 260, -200, defaults.delWidth)

-- Reset to defaults button
local defaultBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
defaultBtn:SetSize(140, 24)
defaultBtn:SetPoint("BOTTOMLEFT", 16, 16)
defaultBtn:SetText("Reset to Defaults")

defaultBtn:SetScript("OnClick", function()
    -- restore saved values
    DNG_Saved.iconSize   = defaults.iconSize
    DNG_Saved.startWidth = defaults.startWidth
    DNG_Saved.endWidth   = defaults.endWidth
    DNG_Saved.annWidth   = defaults.annWidth
    DNG_Saved.delWidth   = defaults.delWidth

    DNG_Saved.iconVisible  = true
    DNG_Saved.startVisible = true
    DNG_Saved.endVisible   = true
    DNG_Saved.annVisible   = true
    DNG_Saved.delVisible   = true

    -- update sliders and checkboxes
    iconSlider:SetValue(DNG_Saved.iconSize)
    startSlider:SetValue(DNG_Saved.startWidth)
    endSlider:SetValue(DNG_Saved.endWidth)
    annSlider:SetValue(DNG_Saved.annWidth)
    delSlider:SetValue(DNG_Saved.delWidth)

    iconCB:SetChecked(true)
    startCB:SetChecked(true)
    endCB:SetChecked(true)
    annCB:SetChecked(true)
    delCB:SetChecked(true)

    if DNG.frame then
        DNG.frame:SetSize(DNG_Saved.frameWidth or 340, DNG_Saved.frameHeight or 420)
        if DNG.ApplyButtonSizes then DNG:ApplyButtonSizes() end
        if DNG.UpdateMemoryUI then DNG:UpdateMemoryUI() end
    end
end)
