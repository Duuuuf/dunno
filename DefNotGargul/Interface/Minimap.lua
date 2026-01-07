local DNG = DefNotGargul

local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("DefNotGargul", {
    type = "launcher",
    text = "DefNotGargul",
    icon = "Interface\\Icons\\INV_Misc_QuestionMark",
    OnClick = function(_, button)
        if button == "LeftButton" then
            if DNG.frame then
                if DNG.frame:IsShown() then
                    DNG.frame:Hide()
                else
                    DNG.frame:Show()
                    if DNG.UpdateMemoryUI then DNG:UpdateMemoryUI() end
                end
            end
        elseif button == "RightButton" then
            InterfaceOptionsFrame_OpenToCategory("DefNotGargul")
            InterfaceOptionsFrame_OpenToCategory("DefNotGargul")
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("DefNotGargul")
        tooltip:AddLine("|cffFFFFFFLeft click:|r Open main UI")
        tooltip:AddLine("|cffFFFFFFRight click:|r Open settings")
    end,
})

-- We wrap the registration so it doesn't run immediately
function DNG:InitMinimap()
    -- Now it's safe to touch DNG_Saved
    DNG_Saved.MinimapIcon = DNG_Saved.MinimapIcon or {}
    LibStub("LibDBIcon-1.0"):Register("DefNotGargul", LDB, DNG_Saved.MinimapIcon)
end