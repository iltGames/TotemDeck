-- TotemDeck: Commands Module
-- Slash commands and UI rebuilds

local addonName, addon = ...

-- Local references
local GetElementOrder = addon.GetElementOrder

-- Rebuild entire UI (needed when direction changes - affects bar layout)
function addon.RebuildPopupColumns()
    if InCombatLockdown() then
        print("|cFF00FF00TotemDeck:|r Cannot change direction in combat")
        return false
    end

    -- Hide popup first
    addon.HidePopup()

    -- Destroy existing popup containers
    for element, container in pairs(addon.UI.popupContainers) do
        container:Hide()
        container:SetParent(nil)
    end
    addon.UI.popupContainers = {}
    addon.UI.popupButtons = {}

    -- Destroy existing action bar buttons
    for element, btn in pairs(addon.UI.activeTotemButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    addon.UI.activeTotemButtons = {}

    -- Destroy reincarnation button
    if addon.UI.reincarnationButton then
        addon.UI.reincarnationButton:Hide()
        addon.UI.reincarnationButton:SetParent(nil)
        addon.UI.reincarnationButton = nil
    end

    -- Destroy weapon buff button and popup
    if addon.UI.weaponBuffPopup then
        addon.UI.weaponBuffPopup:Hide()
        addon.UI.weaponBuffPopup:SetParent(nil)
        addon.UI.weaponBuffPopup = nil
    end
    if addon.UI.weaponBuffButton then
        addon.UI.weaponBuffButton:Hide()
        addon.UI.weaponBuffButton:SetParent(nil)
        addon.UI.weaponBuffButton = nil
    end
    addon.UI.weaponBuffPopupButtons = {}

    -- Destroy and recreate action bar frame with new layout
    local savedPos = nil
    if addon.UI.actionBarFrame then
        local point, _, _, x, y = addon.UI.actionBarFrame:GetPoint()
        savedPos = { point = point, x = x, y = y }
        addon.UI.actionBarFrame:Hide()
        addon.UI.actionBarFrame:SetParent(nil)
        addon.UI.actionBarFrame = nil
    end

    -- Recreate action bar (which also recreates popup columns)
    addon.CreateActionBarFrame()

    -- Restore position
    if savedPos then
        addon.UI.actionBarFrame:ClearAllPoints()
        addon.UI.actionBarFrame:SetPoint(savedPos.point, savedPos.x, savedPos.y)
    end

    -- Rebuild timer frame to match new layout
    addon.RebuildTimerFrame()

    -- Show popup if always show is enabled
    if TotemDeckDB.alwaysShowPopup then
        addon.ShowPopup(GetElementOrder()[1])
    end

    return true
end

-- Rebuild timer frame (needed when position changes)
function addon.RebuildTimerFrame()
    if addon.UI.timerFrame then
        addon.UI.timerFrame:Hide()
        addon.UI.timerFrame:SetParent(nil)
        addon.UI.timerFrame = nil
    end
    addon.UI.timerBars = {}
    addon.CreateTimerFrame()
    -- Update icon timer positions for all buttons
    for _, btn in pairs(addon.UI.activeTotemButtons) do
        if btn.UpdateIconTimerPosition then
            btn.UpdateIconTimerPosition()
        end
    end
    addon.UpdateTimers()
end

-- Slash commands
SLASH_TOTEMDECK1 = "/td"

SlashCmdList["TOTEMDECK"] = function(msg)
    local cmd = msg:lower():trim()

    if cmd == "show" then
        if addon.UI.actionBarFrame then
            if addon.UI.actionBarFrame:IsShown() then
                addon.UI.actionBarFrame:Hide()
            else
                addon.UI.actionBarFrame:Show()
            end
        end
    elseif cmd == "timers" then
        TotemDeckDB.showTimers = not TotemDeckDB.showTimers
        if not TotemDeckDB.showTimers and addon.UI.timerFrame then
            addon.UI.timerFrame:Hide()
        elseif TotemDeckDB.showTimers then
            addon.UpdateTimers()
        end
    elseif cmd == "macros" then
        addon.CreateTotemMacros()
    elseif cmd == "config" then
        addon.ToggleConfigWindow()
    elseif cmd == "popup up" then
        TotemDeckDB.popupDirection = "UP"
        if addon.RebuildPopupColumns() then
            print("|cFF00FF00TotemDeck:|r Popup direction set to UP")
        end
    elseif cmd == "popup down" then
        TotemDeckDB.popupDirection = "DOWN"
        if addon.RebuildPopupColumns() then
            print("|cFF00FF00TotemDeck:|r Popup direction set to DOWN")
        end
    elseif cmd == "popup left" then
        TotemDeckDB.popupDirection = "LEFT"
        if addon.RebuildPopupColumns() then
            print("|cFF00FF00TotemDeck:|r Popup direction set to LEFT")
        end
    elseif cmd == "popup right" then
        TotemDeckDB.popupDirection = "RIGHT"
        if addon.RebuildPopupColumns() then
            print("|cFF00FF00TotemDeck:|r Popup direction set to RIGHT")
        end
    elseif cmd == "timers above" then
        TotemDeckDB.timerPosition = "ABOVE"
        addon.RebuildTimerFrame()
        print("|cFF00FF00TotemDeck:|r Timers position set to ABOVE")
    elseif cmd == "timers below" then
        TotemDeckDB.timerPosition = "BELOW"
        addon.RebuildTimerFrame()
        print("|cFF00FF00TotemDeck:|r Timers position set to BELOW")
    elseif cmd == "timers left" then
        TotemDeckDB.timerPosition = "LEFT"
        addon.RebuildTimerFrame()
        print("|cFF00FF00TotemDeck:|r Timers position set to LEFT")
    elseif cmd == "timers right" then
        TotemDeckDB.timerPosition = "RIGHT"
        addon.RebuildTimerFrame()
        print("|cFF00FF00TotemDeck:|r Timers position set to RIGHT")
    else
        print("|cFF00FF00TotemDeck:|r Commands:")
        print("  /td show - Toggle bar visibility")
        print("  /td timers - Toggle timer display")
        print("  /td macros - Recreate macros")
        print("  /td config - Open configuration window")
        print("  /td popup up|down|left|right - Set popup direction")
        print("  /td timers above|below|left|right - Set timer position")
    end
end
