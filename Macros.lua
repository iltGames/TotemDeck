-- TotemDeck: Macros Module
-- Macro creation and management

local addonName, addon = ...

-- Local references
local TOTEMS = addon.TOTEMS
local ELEMENT_ORDER = addon.ELEMENT_ORDER
local GetTotemData = addon.GetTotemData
local GetElementOrder = addon.GetElementOrder

-- Check if a default macro is enabled
local function IsDefaultMacroEnabled(macroName)
    if not TotemDeckDB.defaultMacrosEnabled then
        return true -- Default to enabled if setting doesn't exist
    end
    local enabled = TotemDeckDB.defaultMacrosEnabled[macroName]
    if enabled == nil then
        return true -- Default to enabled if not specified
    end
    return enabled
end

-- Delete a macro by name if it exists
local function DeleteMacroIfExists(macroName)
    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex > 0 then
        DeleteMacro(macroIndex)
    end
end

-- Create or update macros for active totems
function addon.CreateTotemMacros()
    for _, element in ipairs(ELEMENT_ORDER) do
        local macroName = "TD" .. element

        -- Check if this macro is enabled
        if not IsDefaultMacroEnabled(macroName) then
            -- Delete macro if it exists and is disabled
            DeleteMacroIfExists(macroName)
        else
            local macroIcon = "INV_Misc_QuestionMark"

            -- Find icon and spell for current active totem (using spell ID)
            local activeKey = "active" .. element
            local spellID = TotemDeckDB[activeKey]
            local totemName = addon.GetTotemName(spellID)  -- Get localized name
            local macroBody = "#showtooltip\n/cast " .. (totemName or "")

            if spellID then
                -- Get icon from spell ID (returns texture ID number in modern WoW)
                local icon = addon.GetTotemIcon(spellID)
                if icon then
                    macroIcon = icon
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
    end

    -- Create sequence macro (TDAll) - drops all 4 active totems in order
    local sequenceName = "TDAll"

    if not IsDefaultMacroEnabled(sequenceName) then
        DeleteMacroIfExists(sequenceName)
    else
        local sequenceIcon = "INV_Misc_QuestionMark"
        local totemList = {}
        for _, element in ipairs(GetElementOrder()) do
            local activeKey = "active" .. element
            local spellID = TotemDeckDB[activeKey]
            local totemName = addon.GetTotemName(spellID)  -- Get localized name
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

    -- Also create/update custom macros
    addon.UpdateCustomMacros()
end

-- Update a single macro when active totem changes
function addon.UpdateTotemMacro(element)
    local macroName = "TD" .. element

    -- Skip if macro is disabled
    if not IsDefaultMacroEnabled(macroName) then return end

    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex == 0 then return end

    local activeKey = "active" .. element
    local spellID = TotemDeckDB[activeKey]
    if not spellID then return end

    local totemName = addon.GetTotemName(spellID)  -- Get localized name
    if not totemName then return end

    local macroIcon = "INV_Misc_QuestionMark"
    local icon = addon.GetTotemIcon(spellID)
    if icon then
        -- GetSpellTexture returns a number (texture ID) in modern WoW
        macroIcon = icon
    end

    local macroBody = "#showtooltip\n/cast " .. totemName
    EditMacro(macroIndex, macroName, macroIcon, macroBody)

    -- Also update the sequence macro (if enabled)
    if IsDefaultMacroEnabled("TDAll") then
        local sequenceIndex = GetMacroIndexByName("TDAll")
        if sequenceIndex > 0 then
            local totemList = {}
            for _, elem in ipairs(GetElementOrder()) do
                local ak = "active" .. elem
                local sid = TotemDeckDB[ak]
                local tn = addon.GetTotemName(sid)  -- Get localized name
                if tn then
                    table.insert(totemList, tn)
                end
            end
            local sequenceBody = "#showtooltip\n/castsequence reset=5 " .. table.concat(totemList, ", ")
            EditMacro(sequenceIndex, "TDAll", "INV_Misc_QuestionMark", sequenceBody)
        end
    end

    -- Also update custom macros
    addon.UpdateCustomMacros()
end

-- Create or update all custom macros from templates
function addon.UpdateCustomMacros()
    if not TotemDeckDB.customMacros then return end

    for _, customMacro in ipairs(TotemDeckDB.customMacros) do
        if customMacro.enabled and customMacro.name and customMacro.template then
            local macroName = customMacro.name
            local macroBody = addon.ProcessMacroTemplate(customMacro.template)
            local macroIcon = "INV_Misc_QuestionMark"

            local macroIndex = GetMacroIndexByName(macroName)
            if macroIndex > 0 then
                EditMacro(macroIndex, macroName, macroIcon, macroBody)
            else
                local numAccountMacros = GetNumMacros()
                if numAccountMacros < 120 then
                    CreateMacro(macroName, macroIcon, macroBody, false)
                end
            end
        end
    end
end

-- Delete a custom macro
function addon.DeleteCustomMacro(macroName)
    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex > 0 then
        DeleteMacro(macroIndex)
    end
end

-- Toggle a default macro on/off
function addon.SetDefaultMacroEnabled(macroName, enabled)
    if not TotemDeckDB.defaultMacrosEnabled then
        TotemDeckDB.defaultMacrosEnabled = {}
    end
    TotemDeckDB.defaultMacrosEnabled[macroName] = enabled

    if enabled then
        -- Recreate the macro
        addon.CreateTotemMacros()
    else
        -- Delete the macro
        local macroIndex = GetMacroIndexByName(macroName)
        if macroIndex > 0 then
            DeleteMacro(macroIndex)
        end
    end
end

-- Set active totem for an element (now takes spell ID instead of name)
function addon.SetActiveTotem(element, spellID)
    local activeKey = "active" .. element
    TotemDeckDB[activeKey] = spellID

    -- Update popup buttons immediately (visual only, not protected)
    local popupButtons = addon.UI.popupButtons
    local ELEMENT_COLORS = addon.ELEMENT_COLORS
    if popupButtons[element] then
        for _, btn in ipairs(popupButtons[element]) do
            if btn.spellID == spellID then
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
