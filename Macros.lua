-- TotemDeck: Macros Module
-- Macro creation and management

local addonName, addon = ...

-- Local references
local TOTEMS = addon.TOTEMS
local ELEMENT_ORDER = addon.ELEMENT_ORDER
local GetTotemData = addon.GetTotemData
local GetElementOrder = addon.GetElementOrder

-- Create or update macros for active totems
function addon.CreateTotemMacros()
    for _, element in ipairs(ELEMENT_ORDER) do
        local macroName = "TD" .. element
        local macroIcon = "INV_Misc_QuestionMark"

        -- Find icon and spell for current active totem
        local activeKey = "active" .. element
        local totemName = TotemDeckDB[activeKey]
        local macroBody = "#showtooltip\n/cast " .. (totemName or "")

        if totemName then
            for _, totem in ipairs(TOTEMS[element]) do
                if totem.name == totemName then
                    macroIcon = totem.icon:gsub("Interface\\Icons\\", "")
                    break
                end
            end
        end

        -- Check if macro exists
        local macroIndex = GetMacroIndexByName(macroName)

        if macroIndex > 0 then
            -- Update existing macro
            EditMacro(macroIndex, macroName, macroIcon, macroBody)
        else
            -- Create new macro (account-wide)
            local numAccountMacros = GetNumMacros()
            if numAccountMacros < 120 then
                CreateMacro(macroName, macroIcon, macroBody, false)
            else
                -- Macro limit reached, silently skip
            end
        end
    end

    -- Create sequence macro (TDAll) - drops all 4 active totems in order
    local sequenceName = "TDAll"
    local sequenceIcon = "INV_Misc_QuestionMark"
    local totemList = {}
    for _, element in ipairs(GetElementOrder()) do
        local activeKey = "active" .. element
        local totemName = TotemDeckDB[activeKey]
        if totemName then
            table.insert(totemList, totemName)
        end
    end
    local sequenceBody = "#showtooltip\n/castsequence reset=5 " .. table.concat(totemList, ", ")

    local sequenceIndex = GetMacroIndexByName(sequenceName)
    if sequenceIndex > 0 then
        EditMacro(sequenceIndex, sequenceName, sequenceIcon, sequenceBody)
    else
        local numAccountMacros = GetNumMacros()
        if numAccountMacros < 120 then
            CreateMacro(sequenceName, sequenceIcon, sequenceBody, false)
        end
    end
end

-- Update a single macro when active totem changes
function addon.UpdateTotemMacro(element)
    local macroName = "TD" .. element
    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex == 0 then return end

    local activeKey = "active" .. element
    local totemName = TotemDeckDB[activeKey]
    if not totemName then return end

    local macroIcon = "INV_Misc_QuestionMark"
    local totemData = GetTotemData(totemName)
    if totemData then
        macroIcon = totemData.icon:gsub("Interface\\Icons\\", "")
    end

    EditMacro(macroIndex, macroName, macroIcon, "#showtooltip\n/cast " .. totemName)

    -- Also update the sequence macro
    local sequenceIndex = GetMacroIndexByName("TDAll")
    if sequenceIndex > 0 then
        local totemList = {}
        for _, elem in ipairs(GetElementOrder()) do
            local ak = "active" .. elem
            local tn = TotemDeckDB[ak]
            if tn then
                table.insert(totemList, tn)
            end
        end
        local sequenceBody = "#showtooltip\n/castsequence reset=5 " .. table.concat(totemList, ", ")
        EditMacro(sequenceIndex, "TDAll", "INV_Misc_QuestionMark", sequenceBody)
    end
end

-- Set active totem for an element
function addon.SetActiveTotem(element, totemName)
    local activeKey = "active" .. element
    TotemDeckDB[activeKey] = totemName

    -- Update popup buttons immediately (visual only, not protected)
    local popupButtons = addon.UI.popupButtons
    local ELEMENT_COLORS = addon.ELEMENT_COLORS
    if popupButtons[element] then
        for _, btn in ipairs(popupButtons[element]) do
            if btn.totemName == totemName then
                btn.border:SetBackdropBorderColor(0, 1, 0, 1)
            else
                btn.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            end
        end
    end

    -- Secure updates (SetAttribute, EditMacro) must wait until out of combat
    if InCombatLockdown() then
        addon.state.pendingActiveUpdates[element] = true
        return
    end

    -- Update active totem button (secure)
    addon.UpdateActiveTotemButton(element)

    -- Update macro
    addon.UpdateTotemMacro(element)
end
