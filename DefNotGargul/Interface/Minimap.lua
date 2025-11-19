local DNG = DefNotGargul
DNG_Saved.MinimapIcon = DNG_Saved.MinimapIcon or {}

local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("DefNotGargul", {
    type = "launcher",
    text = "DefNotGargul",
    icon = "Interface\\Icons\\INV_Misc_QuestionMark", -- change to your icon
    OnClick = function(_, button)
        if button == "LeftButton" then
            if DNG.frame:IsShown() then
                DNG.frame:Hide()
            else
                DNG.frame:Show()
                DNG:UpdateMemoryUI()
            end
        elseif button == "RightButton" then
    InterfaceOptionsFrame_OpenToCategory("DefNotGargul")
    InterfaceOptionsFrame_OpenToCategory("DefNotGargul") -- Blizzard bug fix
end

    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("DefNotGargul")
        tooltip:AddLine("Left click: Open main UI")
        tooltip:AddLine("Right click: Open settings")
    end,
})

LibStub("LibDBIcon-1.0"):Register("DefNotGargul", LDB, DNG_Saved.MinimapIcon)
