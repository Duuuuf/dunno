local addonName, S = ...

-- Ensure global addon table exists
if not S then
    S = {}
    _G[addonName] = S
end

-- Master SavedVariable (persisted by WoW)
DNG_Saved = DNG_Saved or {}

-- Ensure SoftRes table lives inside DNG_Saved so it persists
DNG_Saved.SoftRes = DNG_Saved.SoftRes or {
    players = {},
    items = {},
}

S.SoftRes = DNG_Saved.SoftRes
DNG.SoftRes = DNG_Saved.SoftRes 

_G["DNG_SoftRes"] = S.SoftRes
