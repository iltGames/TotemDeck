-- TotemDeck: Shaman Totem Management Addon for TBC Classic
-- Allows selecting active totems, creates macros, and tracks timers

local addonName, addon = ...

-- Default saved variables
local defaults = {
    activeEarth = "Strength of Earth Totem",
    activeFire = "Searing Totem",
    activeWater = "Mana Spring Totem",
    activeAir = "Windfury Totem",
    barPos = { point = "CENTER", x = 0, y = -200 },
    showTimers = true,
    locked = false,
    popupDirection = "UP", -- UP, DOWN, LEFT, RIGHT
    timerPosition = "ABOVE", -- ABOVE, BELOW, LEFT, RIGHT
    timerStyle = "bars", -- "bars" or "icons"
    alwaysShowPopup = false, -- Always show popup bars instead of on hover
    elementOrder = { "Earth", "Fire", "Water", "Air" }, -- Order of element groups
    totemOrder = { -- Custom totem order per element (empty = use default)
        Earth = {},
        Fire = {},
        Water = {},
        Air = {},
    },
    hiddenTotems = { -- Totems hidden from popup
        Earth = {},
        Fire = {},
        Water = {},
        Air = {},
    },
    showReincarnation = true, -- Show Reincarnation tracker button
    showWeaponBuffs = true, -- Show Weapon Buffs button
}

-- Totem data: name, duration in seconds, icon
local TOTEMS = {
    Earth = {
        { name = "Earthbind Totem", duration = 45, icon = "Interface\\Icons\\Spell_Nature_StrengthOfEarthTotem02" },
        { name = "Stoneclaw Totem", duration = 15, icon = "Interface\\Icons\\Spell_Nature_StoneClawTotem" },
        { name = "Stoneskin Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_StoneSkinTotem" },
        { name = "Strength of Earth Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_EarthBindTotem" },
        { name = "Tremor Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_TremorTotem" },
        { name = "Earth Elemental Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_EarthElemental_Totem" },
    },
    Fire = {
        { name = "Fire Nova Totem", duration = 5, icon = "Interface\\Icons\\Spell_Fire_SealOfFire" },
        { name = "Flametongue Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_GuardianWard" },
        { name = "Frost Resistance Totem", duration = 120, icon = "Interface\\Icons\\Spell_FrostResistanceTotem_01" },
        { name = "Magma Totem", duration = 20, icon = "Interface\\Icons\\Spell_Fire_SelfDestruct" },
        { name = "Searing Totem", duration = 60, icon = "Interface\\Icons\\Spell_Fire_SearingTotem" },
        { name = "Totem of Wrath", duration = 120, icon = "Interface\\Icons\\Spell_Fire_TotemOfWrath" },
        { name = "Fire Elemental Totem", duration = 120, icon = "Interface\\Icons\\Spell_Fire_Elemental_Totem" },
    },
    Water = {
        { name = "Disease Cleansing Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_DiseaseCleansingTotem" },
        { name = "Fire Resistance Totem", duration = 120, icon = "Interface\\Icons\\Spell_FireResistanceTotem_01" },
        { name = "Healing Stream Totem", duration = 120, icon = "Interface\\Icons\\INV_Spear_04" },
        { name = "Mana Spring Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_ManaRegenTotem" },
        { name = "Mana Tide Totem", duration = 12, icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental" },
        { name = "Poison Cleansing Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_PoisonCleansingTotem" },
    },
    Air = {
        { name = "Grace of Air Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_InvisibilityTotem" },
        { name = "Grounding Totem", duration = 45, icon = "Interface\\Icons\\Spell_Nature_GroundingTotem" },
        { name = "Nature Resistance Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_NatureResistanceTotem" },
        { name = "Sentry Totem", duration = 300, icon = "Interface\\Icons\\Spell_Nature_RemoveCurse" },
        { name = "Tranquil Air Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_Brilliance" },
        { name = "Windfury Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_Windfury" },
        { name = "Windwall Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_EarthBind" },
        { name = "Wrath of Air Totem", duration = 120, icon = "Interface\\Icons\\Spell_Nature_SlowingTotem" },
    },
}

-- Element colors
local ELEMENT_COLORS = {
    Earth = { r = 0.6, g = 0.4, b = 0.2 },
    Fire = { r = 1.0, g = 0.3, b = 0.1 },
    Water = { r = 0.2, g = 0.5, b = 1.0 },
    Air = { r = 0.7, g = 0.7, b = 0.9 },
}

-- Element order for display
local ELEMENT_ORDER = { "Earth", "Fire", "Water", "Air" }

-- Totem slot indices (for tracking active totems)
local TOTEM_SLOTS = {
    Fire = 1,
    Earth = 2,
    Water = 3,
    Air = 4,
}

-- Weapon buff data
local WEAPON_BUFFS = {
    { name = "Rockbiter Weapon", icon = "Interface\\Icons\\Spell_Nature_RockBiter" },
    { name = "Flametongue Weapon", icon = "Interface\\Icons\\Spell_Fire_FlameToungue" },
    { name = "Frostbrand Weapon", icon = "Interface\\Icons\\Spell_Frost_FrostBrand" },
    { name = "Windfury Weapon", icon = "Interface\\Icons\\Spell_Nature_Cyclone" },
}

-- Ankh item ID for Reincarnation
local ANKH_ITEM_ID = 17030

-- UI elements
local timerFrame, actionBarFrame
local timerBars = {}
local activeTotemButtons = {}
local popupButtons = {}
local popupContainers = {} -- Container frames for each element, anchored to main bar buttons
local buttonCounter = 0
local popupVisible = false
local popupHideDelay = 0
local reincarnationButton = nil -- Reincarnation tracker button
local weaponBuffButton = nil -- Weapon buff button
local weaponBuffPopup = nil -- Weapon buff popup container
local weaponBuffPopupButtons = {} -- Buttons inside the weapon buff popup
local weaponBuffPopupVisible = false
local activeMainHandBuff = nil -- Track which weapon buff is on main hand
local activeOffHandBuff = nil -- Track which weapon buff is on off hand

-- Forward declarations
local RebuildPopupColumns, RebuildTimerFrame, CreateTotemMacros, ShowPopup
local UpdateReincarnationButton, UpdateWeaponBuffButton, CreateReincarnationButton, CreateWeaponBuffButton

-- Utility: Check if player is a Shaman
local function IsShaman()
    local _, class = UnitClass("player")
    return class == "SHAMAN"
end

-- Utility: Get totem data by name
local function GetTotemData(totemName)
    for element, totems in pairs(TOTEMS) do
        for _, totem in ipairs(totems) do
            if totem.name == totemName then
                return totem, element
            end
        end
    end
    return nil, nil
end

-- Get element order (saved or default)
local function GetElementOrder()
    if TotemDeckDB and TotemDeckDB.elementOrder then
        return TotemDeckDB.elementOrder
    end
    return ELEMENT_ORDER
end

-- Check if a totem spell is trained
local function IsTotemKnown(totemName)
    local name, _, _, _, _, _, spellID = GetSpellInfo(totemName)
    if not spellID then
        return false
    end
    return IsPlayerSpell(spellID)
end

-- Check if a totem is hidden by the user
local function IsTotemHidden(element, totemName)
    if not TotemDeckDB or not TotemDeckDB.hiddenTotems or not TotemDeckDB.hiddenTotems[element] then
        return false
    end
    for _, hidden in ipairs(TotemDeckDB.hiddenTotems[element]) do
        if hidden == totemName then
            return true
        end
    end
    return false
end

-- Check if a weapon buff spell is known
local function IsWeaponBuffKnown(buffName)
    local name, _, _, _, _, _, spellID = GetSpellInfo(buffName)
    if not spellID then
        return false
    end
    return IsPlayerSpell(spellID)
end

-- Get list of known weapon buffs
local function GetKnownWeaponBuffs()
    local known = {}
    for _, buff in ipairs(WEAPON_BUFFS) do
        if IsWeaponBuffKnown(buff.name) then
            table.insert(known, buff)
        end
    end
    return known
end

-- Get current weapon enchant info and match to weapon buff name
local function GetCurrentWeaponBuff()
    local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID,
          hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()

    -- Clear tracked buffs if enchant is gone
    if not hasMainHandEnchant then
        activeMainHandBuff = nil
    end
    if not hasOffHandEnchant then
        activeOffHandBuff = nil
    end

    -- Return info about current enchants
    return {
        mainHand = hasMainHandEnchant and mainHandEnchantID or nil,
        mainHandTime = hasMainHandEnchant and mainHandExpiration or nil,
        mainHandBuff = activeMainHandBuff,
        offHand = hasOffHandEnchant and offHandEnchantID or nil,
        offHandTime = hasOffHandEnchant and offHandExpiration or nil,
        offHandBuff = activeOffHandBuff,
    }
end

-- Check if a spell name is a weapon buff and return the buff data
local function GetWeaponBuffByName(spellName)
    for _, buff in ipairs(WEAPON_BUFFS) do
        if spellName == buff.name then
            return buff
        end
    end
    return nil
end

-- Track enchant state before cast to detect which slot changed
local preCastMainHandEnchant = false
local preCastOffHandEnchant = false

-- Called when a weapon buff is successfully cast
local function OnWeaponBuffCast(spellName)
    local buff = GetWeaponBuffByName(spellName)
    if not buff then return end

    -- Capture pre-cast state
    local preMain = preCastMainHandEnchant
    local preOff = preCastOffHandEnchant

    -- Check which weapon got the buff by comparing enchant state
    -- We need a slight delay because GetWeaponEnchantInfo may not update immediately
    C_Timer.After(0.1, function()
        local hasMainHandEnchant, mainExp, _, _,
              hasOffHandEnchant, offExp = GetWeaponEnchantInfo()

        -- Detect which slot changed or was refreshed
        -- If main hand now has enchant (and didn't before, or has fresh duration), it's main hand
        -- If off hand now has enchant (and didn't before, or has fresh duration), it's off hand
        if hasMainHandEnchant then
            -- Main hand has enchant - assume this cast went to main hand
            -- (most common case - weapon buffs default to main hand)
            activeMainHandBuff = buff
            -- Save to DB for persistence across reloads
            if TotemDeckDB then
                TotemDeckDB.lastMainHandBuff = buff.name
            end
        end

        -- If only off hand has enchant and main doesn't, it went to off hand
        if hasOffHandEnchant and not hasMainHandEnchant then
            activeOffHandBuff = buff
            if TotemDeckDB then
                TotemDeckDB.lastOffHandBuff = buff.name
            end
        end

        -- If both have enchants and off hand is the "new" one (main was already enchanted)
        if hasOffHandEnchant and hasMainHandEnchant and preMain and not preOff then
            activeOffHandBuff = buff
            if TotemDeckDB then
                TotemDeckDB.lastOffHandBuff = buff.name
            end
        end

        UpdateWeaponBuffButton()
    end)
end

-- Restore saved weapon buff info on login (if enchant is still active)
local function RestoreSavedWeaponBuffs()
    local hasMainHandEnchant, _, _, _,
          hasOffHandEnchant = GetWeaponEnchantInfo()

    if hasMainHandEnchant and TotemDeckDB and TotemDeckDB.lastMainHandBuff then
        local buff = GetWeaponBuffByName(TotemDeckDB.lastMainHandBuff)
        if buff then
            activeMainHandBuff = buff
        end
    end

    if hasOffHandEnchant and TotemDeckDB and TotemDeckDB.lastOffHandBuff then
        local buff = GetWeaponBuffByName(TotemDeckDB.lastOffHandBuff)
        if buff then
            activeOffHandBuff = buff
        end
    end
end

-- Pre-cast hook to track enchant state before casting
local function TrackPreCastEnchantState()
    local hasMainHandEnchant, _, _, _,
          hasOffHandEnchant = GetWeaponEnchantInfo()
    preCastMainHandEnchant = hasMainHandEnchant
    preCastOffHandEnchant = hasOffHandEnchant
end

-- Get totems for an element in custom order (if set)
local function GetOrderedTotems(element)
    local savedOrder = TotemDeckDB and TotemDeckDB.totemOrder and TotemDeckDB.totemOrder[element]
    if not savedOrder or #savedOrder == 0 then
        return TOTEMS[element] -- Use default order
    end

    -- Build ordered list from saved names
    local ordered = {}
    for _, name in ipairs(savedOrder) do
        for _, totem in ipairs(TOTEMS[element]) do
            if totem.name == name then
                table.insert(ordered, totem)
                break
            end
        end
    end

    -- Add any totems not in saved order (e.g., newly added)
    for _, totem in ipairs(TOTEMS[element]) do
        local found = false
        for _, name in ipairs(savedOrder) do
            if totem.name == name then
                found = true
                break
            end
        end
        if not found then
            table.insert(ordered, totem)
        end
    end

    return ordered
end

-- Format time for display
local function FormatTime(seconds)
    if seconds >= 60 then
        return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
    else
        return string.format("%d", seconds)
    end
end

-- Forward declaration
local UpdateActiveTotemButton

-- Create or update macros for active totems
CreateTotemMacros = function()
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
local function UpdateTotemMacro(element)
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

-- Queue for pending updates after combat
local pendingActiveUpdates = {}

-- Set active totem for an element
local function SetActiveTotem(element, totemName)
    local activeKey = "active" .. element
    TotemDeckDB[activeKey] = totemName

    -- Update popup buttons immediately (visual only, not protected)
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
        pendingActiveUpdates[element] = true
        return
    end

    -- Update active totem button (secure)
    UpdateActiveTotemButton(element)

    -- Update macro
    UpdateTotemMacro(element)
end

-- Create timer bar
local function CreateTimerBar(parent, element, index)
    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetSize(190, 20)

    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    bar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    local color = ELEMENT_COLORS[element]
    bar:SetBackdropBorderColor(color.r, color.g, color.b, 1)

    -- Status bar
    local statusBar = CreateFrame("StatusBar", nil, bar)
    statusBar:SetPoint("TOPLEFT", 2, -2)
    statusBar:SetPoint("BOTTOMRIGHT", -2, 2)
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    statusBar:SetStatusBarColor(color.r, color.g, color.b, 0.8)
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(1)
    bar.statusBar = statusBar

    -- Text (on statusBar so it renders above the progress color)
    local text = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", 4, 0)
    text:SetTextColor(1, 1, 1)
    bar.text = text

    -- Time text (on statusBar so it renders above the progress color)
    local timeText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetPoint("RIGHT", -2, 0)
    timeText:SetTextColor(1, 1, 1)
    bar.timeText = timeText

    bar.element = element
    bar:Hide()

    return bar
end

-- Update an active totem button's spell binding
UpdateActiveTotemButton = function(element)
    local btn = activeTotemButtons[element]
    if not btn then return end

    local activeKey = "active" .. element
    local totemName = TotemDeckDB[activeKey]
    local totemData = GetTotemData(totemName)

    if totemData then
        btn:SetAttribute("spell1", totemName)
        btn.icon:SetTexture(totemData.icon)
        btn.totemName = totemName
    end
end

-- Create popup button for the hover menu
local function CreatePopupButton(parent, totemData, element, index)
    buttonCounter = buttonCounter + 1
    local btnName = "TotemDeckPopupButton" .. buttonCounter

    -- Create a visual frame (non-secure) first
    local visual = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    visual:SetSize(36, 36)
    visual:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    visual:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    visual:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- Icon on the visual frame (non-secure, should always render)
    local icon = visual:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("CENTER")
    local spellIcon = GetSpellTexture(totemData.name)
    icon:SetTexture(spellIcon or totemData.icon)
    icon:Show()
    visual.icon = icon

    -- Create the secure button on top of visual
    local btn = CreateFrame("Button", btnName, parent, "SecureActionButtonTemplate")
    btn:SetSize(36, 36)
    btn:SetAllPoints(visual)
    btn:SetFrameLevel(visual:GetFrameLevel() + 1)

    -- Store references
    btn.visual = visual
    btn.border = visual -- Use visual as border (has SetBackdropBorderColor)
    btn.icon = icon

    -- Store data
    btn.totemName = totemData.name
    btn.totemDuration = totemData.duration
    btn.element = element
    -- Get spell ID for tooltip
    local _, _, _, _, _, _, spellID = GetSpellInfo(totemData.name)
    btn.spellID = spellID

    -- Register for clicks
    btn:RegisterForClicks("AnyDown", "AnyUp")

    -- Left click = cast
    btn:SetAttribute("type1", "spell")
    btn:SetAttribute("spell1", totemData.name)

    -- Right click = set active
    btn:HookScript("PostClick", function(self, button)
        if button == "RightButton" then
            SetActiveTotem(self.element, self.totemName)
        end
    end)

    -- Tooltip (to the right of the button)
    btn:SetScript("OnEnter", function(self)
        -- Only respond if popup is already visible (user hovered main bar first)
        -- This prevents invisible buttons from triggering popup during combat
        if not popupVisible then
            return
        end
        -- Highlight entire column for this element
        ShowPopup(self.element)
        -- Then highlight this specific button
        self.border:SetBackdropBorderColor(1, 1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.spellID then
            GameTooltip:SetSpellByID(self.spellID)
        else
            GameTooltip:SetText(self.totemName, 1, 1, 1)
        end
        local activeKey = "active" .. self.element
        if TotemDeckDB[activeKey] == self.totemName then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("(Active)", 0, 1, 0)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click to cast", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Right-click to set active", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function(self)
        -- Restore border color based on active state (ShowPopup will have set element colors)
        local activeKey = "active" .. self.element
        local color = ELEMENT_COLORS[self.element]
        if TotemDeckDB[activeKey] == self.totemName then
            self.border:SetBackdropBorderColor(0, 1, 0, 1)
        else
            self.border:SetBackdropBorderColor(color.r, color.g, color.b, 0.8)
        end
        GameTooltip:Hide()
    end)

    return btn
end

-- Show all popup columns (called when hovering any main bar button or popup button)
ShowPopup = function(hoveredElement)
    popupVisible = true
    popupHideDelay = 0

    -- Show all element columns, highlight the hovered one
    for elem, container in pairs(popupContainers) do
        local color = ELEMENT_COLORS[elem]
        if not InCombatLockdown() then
            container:Show() -- Only call Show() outside combat (secure frame restriction)
        end
        container:SetAlpha(1)
        container:SetFrameStrata("DIALOG") -- Use DIALOG so GameTooltip (TOOLTIP strata) is above

        -- Highlight hovered element, dim others
        if elem == hoveredElement then
            container:SetBackdropBorderColor(color.r, color.g, color.b, 1)
            -- Update active totem highlights for this element
            local activeKey = "active" .. elem
            for _, btn in ipairs(popupButtons[elem]) do
                if TotemDeckDB[activeKey] == btn.totemName then
                    btn.border:SetBackdropBorderColor(0, 1, 0, 1)
                else
                    btn.border:SetBackdropBorderColor(color.r, color.g, color.b, 0.8)
                end
            end
        else
            -- When always show popup, keep element color; otherwise dim to gray
            if TotemDeckDB.alwaysShowPopup then
                container:SetBackdropBorderColor(color.r, color.g, color.b, 0.5)
                for _, btn in ipairs(popupButtons[elem]) do
                    local activeKey = "active" .. elem
                    if TotemDeckDB[activeKey] == btn.totemName then
                        btn.border:SetBackdropBorderColor(0, 0.8, 0, 0.8)
                    else
                        btn.border:SetBackdropBorderColor(color.r * 0.6, color.g * 0.6, color.b * 0.6, 0.6)
                    end
                end
            else
                container:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
                for _, btn in ipairs(popupButtons[elem]) do
                    local activeKey = "active" .. elem
                    if TotemDeckDB[activeKey] == btn.totemName then
                        btn.border:SetBackdropBorderColor(0, 0.6, 0, 0.8)
                    else
                        btn.border:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
                    end
                end
            end
        end
    end
end

-- Forward declaration for UpdateTimers
local UpdateTimers

-- Hide all popup columns (or just dim them if always show is enabled)
local function HidePopup()
    -- If always show is enabled, just dim all columns instead of hiding
    if TotemDeckDB.alwaysShowPopup then
        for elem, container in pairs(popupContainers) do
            local color = ELEMENT_COLORS[elem]
            container:SetBackdropBorderColor(color.r, color.g, color.b, 0.5)
            -- Dim all buttons
            for _, btn in ipairs(popupButtons[elem] or {}) do
                local activeKey = "active" .. elem
                if TotemDeckDB[activeKey] == btn.totemName then
                    btn.border:SetBackdropBorderColor(0, 0.8, 0, 0.8)
                else
                    btn.border:SetBackdropBorderColor(color.r * 0.6, color.g * 0.6, color.b * 0.6, 0.6)
                end
            end
        end
        return
    end
    popupVisible = false
    for _, container in pairs(popupContainers) do
        if InCombatLockdown() then
            -- In combat: can't Hide() frames with secure children, use alpha instead
            container:SetAlpha(0)
            container:SetFrameStrata("BACKGROUND")
        else
            -- Out of combat: actually hide for clean mouse passthrough
            container:Hide()
        end
    end
    GameTooltip:Hide()
    -- Show timer bars again
    if UpdateTimers then
        UpdateTimers()
    end
end

-- Check if mouse is over any popup column or main bar button
local function IsMouseOverPopupArea()
    if not popupVisible then
        return false
    end
    -- Check all main bar buttons
    for _, btn in pairs(activeTotemButtons) do
        if btn:IsMouseOver() then
            return true
        end
    end
    -- Check all element containers
    for _, container in pairs(popupContainers) do
        if container:IsMouseOver() then
            return true
        end
    end
    -- Check all popup buttons
    for _, buttons in pairs(popupButtons) do
        for _, btn in ipairs(buttons) do
            if btn:IsMouseOver() then
                return true
            end
        end
    end
    return false
end

-- Create popup column/row for a specific element (called after main bar button exists)
local function CreatePopupColumn(element, anchorButton)
    local allTotems = GetOrderedTotems(element) -- Use custom order if set
    local color = ELEMENT_COLORS[element]
    local direction = TotemDeckDB.popupDirection or "UP"
    local isHorizontal = (direction == "LEFT" or direction == "RIGHT")

    -- Filter to only trained totems that aren't hidden
    local totems = {}
    for _, totemData in ipairs(allTotems) do
        if IsTotemKnown(totemData.name) and not IsTotemHidden(element, totemData.name) then
            table.insert(totems, totemData)
        end
    end
    local numTotems = #totems

    -- If no totems trained for this element, don't create a popup
    if numTotems == 0 then
        return nil
    end

    -- Create container anchored to the main bar button
    local container = CreateFrame("Frame", nil, anchorButton, "BackdropTemplate")

    -- Size based on direction
    if isHorizontal then
        container:SetSize(numTotems * 40 + 8, 44) -- Horizontal row
    else
        container:SetSize(44, numTotems * 40 + 8) -- Vertical column
    end

    -- Anchor based on direction
    if direction == "UP" then
        container:SetPoint("BOTTOM", anchorButton, "TOP", 0, 2)
    elseif direction == "DOWN" then
        container:SetPoint("TOP", anchorButton, "BOTTOM", 0, -2)
    elseif direction == "LEFT" then
        container:SetPoint("RIGHT", anchorButton, "LEFT", -2, 0)
    else -- RIGHT
        container:SetPoint("LEFT", anchorButton, "RIGHT", 2, 0)
    end

    container:SetFrameStrata("BACKGROUND") -- Start low, raised when shown

    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    container:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    container:SetBackdropBorderColor(color.r, color.g, color.b, 1)

    container:SetAlpha(0) -- Start hidden
    container:Show()
    popupContainers[element] = container

    -- Create buttons
    popupButtons[element] = {}
    for i, totemData in ipairs(totems) do
        local btn = CreatePopupButton(container, totemData, element, i)

        if direction == "UP" then
            -- Vertical: first totem at bottom, last at top
            local yOffset = 4 + (i - 1) * 40
            btn.visual:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 4, yOffset)
        elseif direction == "DOWN" then
            -- Vertical: first totem at top, last at bottom
            local yOffset = 4 + (i - 1) * 40
            btn.visual:SetPoint("TOPLEFT", container, "TOPLEFT", 4, -yOffset)
        elseif direction == "LEFT" then
            -- Horizontal: first totem closest to bar (right side), last at left
            local xOffset = 4 + (i - 1) * 40
            btn.visual:SetPoint("TOPRIGHT", container, "TOPRIGHT", -xOffset, -4)
        else -- RIGHT
            -- Horizontal: first totem closest to bar (left side), last at right
            local xOffset = 4 + (i - 1) * 40
            btn.visual:SetPoint("TOPLEFT", container, "TOPLEFT", xOffset, -4)
        end

        btn.visual:Show()
        btn:Show()
        popupButtons[element][i] = btn
    end

    return container
end

-- Setup popup system (OnUpdate handler for hide delay)
local function SetupPopupSystem()
    -- Create a helper frame for the OnUpdate handler
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        if popupVisible then
            if IsMouseOverPopupArea() then
                popupHideDelay = 0
            else
                popupHideDelay = popupHideDelay + elapsed
                if popupHideDelay > 0.15 then -- 150ms grace period
                    HidePopup()
                end
            end
        end
    end)
end

-- Configuration Window for totem reordering and layout settings
local configWindow = nil
local configTotemRows = {} -- Stores row frames for each element

local function SaveTotemOrder(element)
    local order = {}
    for _, row in ipairs(configTotemRows[element] or {}) do
        if row.totemName then
            table.insert(order, row.totemName)
        end
    end
    TotemDeckDB.totemOrder[element] = order
end

local function RefreshConfigList(element)
    local rows = configTotemRows[element]
    if not rows then return end

    for i, row in ipairs(rows) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", row:GetParent(), "TOPLEFT", 0, -((i - 1) * 24))
        row.upBtn:SetEnabled(i > 1)
        row.downBtn:SetEnabled(i < #rows)
    end
end

local function MoveTotemUp(element, rowIndex)
    local rows = configTotemRows[element]
    if rowIndex <= 1 then return end
    rows[rowIndex], rows[rowIndex - 1] = rows[rowIndex - 1], rows[rowIndex]
    RefreshConfigList(element)
    SaveTotemOrder(element)
end

local function MoveTotemDown(element, rowIndex)
    local rows = configTotemRows[element]
    if rowIndex >= #rows then return end
    rows[rowIndex], rows[rowIndex + 1] = rows[rowIndex + 1], rows[rowIndex]
    RefreshConfigList(element)
    SaveTotemOrder(element)
end

local function CreateTotemRow(parent, totemData, element, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(140, 22)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * 24))
    row.totemName = totemData.name
    row.element = element

    local upBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    upBtn:SetSize(16, 16)
    upBtn:SetPoint("LEFT", 0, 0)
    upBtn:SetText("^")
    upBtn:SetScript("OnClick", function()
        for i, r in ipairs(configTotemRows[element]) do
            if r == row then
                MoveTotemUp(element, i)
                break
            end
        end
    end)
    row.upBtn = upBtn

    local downBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    downBtn:SetSize(16, 16)
    downBtn:SetPoint("LEFT", upBtn, "RIGHT", 1, 0)
    downBtn:SetText("v")
    downBtn:SetScript("OnClick", function()
        for i, r in ipairs(configTotemRows[element]) do
            if r == row then
                MoveTotemDown(element, i)
                break
            end
        end
    end)
    row.downBtn = downBtn

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", downBtn, "RIGHT", 2, 0)
    icon:SetTexture(GetSpellTexture(totemData.name) or totemData.icon)
    row.icon = icon

    local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("LEFT", icon, "RIGHT", 2, 0)
    name:SetPoint("RIGHT", row, "RIGHT", -18, 0)
    name:SetJustifyH("LEFT")
    name:SetText(totemData.name:gsub(" Totem", ""))
    row.nameText = name

    -- Hide/show toggle button
    local hideBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    hideBtn:SetSize(16, 16)
    hideBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    local function UpdateHideState()
        if IsTotemHidden(element, totemData.name) then
            hideBtn:SetText("O")
            row.icon:SetAlpha(0.4)
            row.nameText:SetAlpha(0.4)
        else
            hideBtn:SetText("X")
            row.icon:SetAlpha(1)
            row.nameText:SetAlpha(1)
        end
    end

    hideBtn:SetScript("OnClick", function()
        local hidden = TotemDeckDB.hiddenTotems[element]
        if IsTotemHidden(element, totemData.name) then
            -- Remove from hidden list
            for i, hiddenName in ipairs(hidden) do
                if hiddenName == totemData.name then
                    table.remove(hidden, i)
                    break
                end
            end
        else
            -- Add to hidden list
            table.insert(hidden, totemData.name)
        end
        UpdateHideState()
    end)

    hideBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if IsTotemHidden(element, totemData.name) then
            GameTooltip:SetText("Click to show in popup")
        else
            GameTooltip:SetText("Click to hide from popup")
        end
        GameTooltip:Show()
    end)
    hideBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdateHideState()
    row.hideBtn = hideBtn

    return row
end

local function PopulateConfigSection(parent, element)
    if configTotemRows[element] then
        for _, row in ipairs(configTotemRows[element]) do
            row:Hide()
            row:SetParent(nil)
        end
    end
    configTotemRows[element] = {}

    local totems = GetOrderedTotems(element)
    for i, totemData in ipairs(totems) do
        local row = CreateTotemRow(parent, totemData, element, i)
        configTotemRows[element][i] = row
    end
    RefreshConfigList(element)
end

local function CreateConfigWindow()
    if configWindow then
        return configWindow
    end

    local frame = CreateFrame("Frame", "TotemDeckConfigWindow", UIParent, "BackdropTemplate")
    frame:SetSize(420, 480)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("TotemDeck Configuration")

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Tab system
    local tabs = {}
    local tabContent = {}

    local function SelectTab(tabName)
        for name, tab in pairs(tabs) do
            if name == tabName then
                tab:SetBackdropColor(0.2, 0.2, 0.2, 1)
                tab.text:SetTextColor(1, 1, 1)
                tabContent[name]:Show()
            else
                tab:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
                tab.text:SetTextColor(0.6, 0.6, 0.6)
                tabContent[name]:Hide()
            end
        end
        frame.activeTab = tabName
    end

    local function CreateTab(name, displayName, xOffset)
        local tab = CreateFrame("Button", nil, frame, "BackdropTemplate")
        tab:SetSize(100, 28)
        tab:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, -32)
        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        tab:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

        local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText(displayName)
        tab.text = text

        tab:SetScript("OnClick", function() SelectTab(name) end)
        tabs[name] = tab
        return tab
    end

    CreateTab("layout", "Layout", 15)
    CreateTab("ordering", "Totem Order", 120)

    local contentFrame = CreateFrame("Frame", nil, frame)
    contentFrame:SetPoint("TOPLEFT", 15, -65)
    contentFrame:SetPoint("BOTTOMRIGHT", -15, 15)

    --------------------------
    -- LAYOUT TAB
    --------------------------
    local layoutContent = CreateFrame("Frame", nil, contentFrame)
    layoutContent:SetAllPoints()
    tabContent["layout"] = layoutContent

    local function CreateLayoutSection(parent, sectionTitle, yOffset, height)
        local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        section:SetSize(380, height)
        section:SetPoint("TOP", parent, "TOP", 0, yOffset)
        section:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        section:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
        section:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        local label = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 10, -8)
        label:SetText(sectionTitle)
        label:SetTextColor(1, 0.82, 0)

        return section
    end

    local function CreateRadioGroup(parent, options, currentValue, yOffset, onChange)
        local buttons = {}
        for i, opt in ipairs(options) do
            local btn = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
            btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 10 + ((i-1) % 4) * 90, yOffset)
            btn:SetScript("OnClick", function(self)
                for _, b in ipairs(buttons) do b:SetChecked(false) end
                self:SetChecked(true)
                onChange(opt.value)
            end)

            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            text:SetPoint("LEFT", btn, "RIGHT", 2, 0)
            text:SetText(opt.label)
            btn.label = text
            btn:SetChecked(currentValue == opt.value)
            buttons[i] = btn
        end
        return buttons
    end

    -- Popup Direction
    local popupSection = CreateLayoutSection(layoutContent, "Popup Direction", 0, 70)
    frame.popupDirButtons = CreateRadioGroup(popupSection, {
        { label = "Up", value = "UP" },
        { label = "Down", value = "DOWN" },
        { label = "Left", value = "LEFT" },
        { label = "Right", value = "RIGHT" },
    }, TotemDeckDB.popupDirection or "UP", -28, function(value)
        TotemDeckDB.popupDirection = value
        if not InCombatLockdown() then RebuildPopupColumns() end
    end)

    -- Timer Position
    local timerSection = CreateLayoutSection(layoutContent, "Timer Position", -80, 70)
    frame.timerPosButtons = CreateRadioGroup(timerSection, {
        { label = "Above", value = "ABOVE" },
        { label = "Below", value = "BELOW" },
        { label = "Left", value = "LEFT" },
        { label = "Right", value = "RIGHT" },
    }, TotemDeckDB.timerPosition or "ABOVE", -28, function(value)
        TotemDeckDB.timerPosition = value
        RebuildTimerFrame()
    end)

    -- Timer Style
    local timerStyleSection = CreateLayoutSection(layoutContent, "Timer Style", -160, 50)
    frame.timerStyleButtons = CreateRadioGroup(timerStyleSection, {
        { label = "Bars", value = "bars" },
        { label = "Icons", value = "icons" },
    }, TotemDeckDB.timerStyle or "bars", -28, function(value)
        TotemDeckDB.timerStyle = value
        UpdateTimers()
    end)

    -- Options
    local optionsSection = CreateLayoutSection(layoutContent, "Options", -220, 167)

    local showTimersCheck = CreateFrame("CheckButton", nil, optionsSection, "UICheckButtonTemplate")
    showTimersCheck:SetPoint("TOPLEFT", 10, -28)
    showTimersCheck:SetChecked(TotemDeckDB.showTimers)
    showTimersCheck:SetScript("OnClick", function(self)
        TotemDeckDB.showTimers = self:GetChecked()
        if not TotemDeckDB.showTimers and timerFrame then
            timerFrame:Hide()
        elseif TotemDeckDB.showTimers then
            UpdateTimers()
        end
    end)
    local showTimersLabel = optionsSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    showTimersLabel:SetPoint("LEFT", showTimersCheck, "RIGHT", 4, 0)
    showTimersLabel:SetText("Show Timers")
    frame.showTimersCheck = showTimersCheck

    local lockPosCheck = CreateFrame("CheckButton", nil, optionsSection, "UICheckButtonTemplate")
    lockPosCheck:SetPoint("TOPLEFT", 10, -54)
    lockPosCheck:SetChecked(TotemDeckDB.locked)
    lockPosCheck:SetScript("OnClick", function(self)
        TotemDeckDB.locked = self:GetChecked()
    end)
    local lockPosLabel = optionsSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockPosLabel:SetPoint("LEFT", lockPosCheck, "RIGHT", 4, 0)
    lockPosLabel:SetText("Lock Bar Position")
    frame.lockPosCheck = lockPosCheck

    local alwaysShowCheck = CreateFrame("CheckButton", nil, optionsSection, "UICheckButtonTemplate")
    alwaysShowCheck:SetPoint("TOPLEFT", 10, -78)
    alwaysShowCheck:SetChecked(TotemDeckDB.alwaysShowPopup)
    alwaysShowCheck:SetScript("OnClick", function(self)
        TotemDeckDB.alwaysShowPopup = self:GetChecked()
        if TotemDeckDB.alwaysShowPopup then
            -- Show popups immediately
            ShowPopup(GetElementOrder()[1])
        else
            -- Hide popups
            popupVisible = false
            for _, container in pairs(popupContainers) do
                if not InCombatLockdown() then
                    container:Hide()
                else
                    container:SetAlpha(0)
                    container:SetFrameStrata("BACKGROUND")
                end
            end
        end
    end)
    local alwaysShowLabel = optionsSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    alwaysShowLabel:SetPoint("LEFT", alwaysShowCheck, "RIGHT", 4, 0)
    alwaysShowLabel:SetText("Always Show Popup")
    frame.alwaysShowCheck = alwaysShowCheck

    -- Show Reincarnation Tracker checkbox
    local showReincCheck = CreateFrame("CheckButton", nil, optionsSection, "UICheckButtonTemplate")
    showReincCheck:SetPoint("TOPLEFT", 10, -104)
    showReincCheck:SetChecked(TotemDeckDB.showReincarnation)
    showReincCheck:SetScript("OnClick", function(self)
        TotemDeckDB.showReincarnation = self:GetChecked()
        if not InCombatLockdown() then
            RebuildPopupColumns()
        else
            print("|cFF00FF00TotemDeck:|r Change will apply after combat")
        end
    end)
    local showReincLabel = optionsSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    showReincLabel:SetPoint("LEFT", showReincCheck, "RIGHT", 4, 0)
    showReincLabel:SetText("Show Reincarnation Tracker")
    frame.showReincCheck = showReincCheck

    -- Show Weapon Buffs checkbox
    local showWeaponCheck = CreateFrame("CheckButton", nil, optionsSection, "UICheckButtonTemplate")
    showWeaponCheck:SetPoint("TOPLEFT", 10, -130)
    showWeaponCheck:SetChecked(TotemDeckDB.showWeaponBuffs)
    showWeaponCheck:SetScript("OnClick", function(self)
        TotemDeckDB.showWeaponBuffs = self:GetChecked()
        if not InCombatLockdown() then
            RebuildPopupColumns()
        else
            print("|cFF00FF00TotemDeck:|r Change will apply after combat")
        end
    end)
    local showWeaponLabel = optionsSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    showWeaponLabel:SetPoint("LEFT", showWeaponCheck, "RIGHT", 4, 0)
    showWeaponLabel:SetText("Show Weapon Buffs")
    frame.showWeaponCheck = showWeaponCheck

    local macrosBtn = CreateFrame("Button", nil, optionsSection, "UIPanelButtonTemplate")
    macrosBtn:SetSize(120, 22)
    macrosBtn:SetPoint("TOPRIGHT", optionsSection, "TOPRIGHT", -10, -30)
    macrosBtn:SetText("Recreate Macros")
    macrosBtn:SetScript("OnClick", function()
        CreateTotemMacros()
        print("|cFF00FF00TotemDeck:|r Macros recreated")
    end)

    --------------------------
    -- ORDERING TAB
    --------------------------
    local orderingContent = CreateFrame("Frame", nil, contentFrame)
    orderingContent:SetAllPoints()
    tabContent["ordering"] = orderingContent

    -- Element Order Section (at the top)
    local elementOrderSection = CreateFrame("Frame", nil, orderingContent, "BackdropTemplate")
    elementOrderSection:SetSize(380, 50)
    elementOrderSection:SetPoint("TOP", orderingContent, "TOP", 0, 0)
    elementOrderSection:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    elementOrderSection:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    elementOrderSection:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local elementOrderLabel = elementOrderSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    elementOrderLabel:SetPoint("TOP", 0, -4)
    elementOrderLabel:SetText("Element Order")

    local elementOrderButtons = {}
    local function RefreshElementOrderButtons()
        local order = GetElementOrder()
        for i, btn in ipairs(elementOrderButtons) do
            local element = order[i]
            local color = ELEMENT_COLORS[element]
            btn.element = element
            btn.text:SetText(element:sub(1, 1))
            btn.text:SetTextColor(color.r, color.g, color.b)
            btn:SetBackdropBorderColor(color.r, color.g, color.b, 1)
            btn.leftBtn:SetEnabled(i > 1)
            btn.rightBtn:SetEnabled(i < 4)
        end
    end

    local function SwapElements(idx1, idx2)
        local order = TotemDeckDB.elementOrder
        order[idx1], order[idx2] = order[idx2], order[idx1]
        RefreshElementOrderButtons()
    end

    for i = 1, 4 do
        local btnFrame = CreateFrame("Frame", nil, elementOrderSection, "BackdropTemplate")
        btnFrame:SetSize(32, 24)
        btnFrame:SetPoint("LEFT", elementOrderSection, "LEFT", 55 + (i - 1) * 75, -6)
        btnFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btnFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)

        local text = btnFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        btnFrame.text = text

        local leftBtn = CreateFrame("Button", nil, btnFrame, "UIPanelButtonTemplate")
        leftBtn:SetSize(18, 18)
        leftBtn:SetPoint("RIGHT", btnFrame, "LEFT", -2, 0)
        leftBtn:SetText("<")
        leftBtn:SetScript("OnClick", function() SwapElements(i, i - 1) end)
        btnFrame.leftBtn = leftBtn

        local rightBtn = CreateFrame("Button", nil, btnFrame, "UIPanelButtonTemplate")
        rightBtn:SetSize(18, 18)
        rightBtn:SetPoint("LEFT", btnFrame, "RIGHT", 2, 0)
        rightBtn:SetText(">")
        rightBtn:SetScript("OnClick", function() SwapElements(i, i + 1) end)
        btnFrame.rightBtn = rightBtn

        elementOrderButtons[i] = btnFrame
    end

    RefreshElementOrderButtons()
    frame.RefreshElementOrderButtons = RefreshElementOrderButtons

    -- Totem Order Sections (shifted down)
    local sectionWidth = 185
    local sectionHeight = 120
    local sections = {}
    local totemSectionTopOffset = -55

    for i, element in ipairs(ELEMENT_ORDER) do
        local color = ELEMENT_COLORS[element]
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)

        local section = CreateFrame("Frame", nil, orderingContent, "BackdropTemplate")
        section:SetSize(sectionWidth, sectionHeight)
        section:SetPoint("TOPLEFT", orderingContent, "TOPLEFT", col * (sectionWidth + 10), totemSectionTopOffset - row * (sectionHeight + 10))
        section:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        section:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
        section:SetBackdropBorderColor(color.r, color.g, color.b, 1)

        local label = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOP", 0, -4)
        label:SetText(element)
        label:SetTextColor(color.r, color.g, color.b)

        local scrollFrame = CreateFrame("ScrollFrame", nil, section, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 8, -22)
        scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)

        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(sectionWidth - 40, 200)
        scrollFrame:SetScrollChild(scrollChild)

        section.scrollChild = scrollChild
        section.element = element
        sections[element] = section
    end

    local orderButtonContainer = CreateFrame("Frame", nil, orderingContent)
    orderButtonContainer:SetSize(380, 30)
    orderButtonContainer:SetPoint("BOTTOM", orderingContent, "BOTTOM", 0, 0)

    local resetBtn = CreateFrame("Button", nil, orderButtonContainer, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 24)
    resetBtn:SetPoint("RIGHT", orderButtonContainer, "CENTER", 65, 0)
    resetBtn:SetText("Reset to Default")
    resetBtn:SetScript("OnClick", function()
        -- Reset element order
        TotemDeckDB.elementOrder = { "Earth", "Fire", "Water", "Air" }
        RefreshElementOrderButtons()
        -- Reset totem order and hidden totems within each element
        for _, element in ipairs(ELEMENT_ORDER) do
            TotemDeckDB.totemOrder[element] = {}
            TotemDeckDB.hiddenTotems[element] = {}
            PopulateConfigSection(sections[element].scrollChild, element)
        end
        print("|cFF00FF00TotemDeck:|r Order reset to default")
    end)

    local applyBtn = CreateFrame("Button", nil, orderButtonContainer, "UIPanelButtonTemplate")
    applyBtn:SetSize(100, 24)
    applyBtn:SetPoint("RIGHT", resetBtn, "LEFT", -10, 0)
    applyBtn:SetText("Apply")
    applyBtn:SetScript("OnClick", function()
        if InCombatLockdown() then
            print("|cFF00FF00TotemDeck:|r Cannot apply changes in combat")
            return
        end
        RebuildPopupColumns()
        print("|cFF00FF00TotemDeck:|r Order applied")
    end)

    frame.sections = sections
    frame.tabContent = tabContent
    frame:Hide()

    SelectTab("layout")

    configWindow = frame
    return frame
end

local function RefreshConfigWindowState()
    if not configWindow then return end

    local popupDir = TotemDeckDB.popupDirection or "UP"
    local popupDirValues = { "UP", "DOWN", "LEFT", "RIGHT" }
    for i, btn in ipairs(configWindow.popupDirButtons or {}) do
        btn:SetChecked(popupDirValues[i] == popupDir)
    end

    local timerPos = TotemDeckDB.timerPosition or "ABOVE"
    local timerPosValues = { "ABOVE", "BELOW", "LEFT", "RIGHT" }
    for i, btn in ipairs(configWindow.timerPosButtons or {}) do
        btn:SetChecked(timerPosValues[i] == timerPos)
    end

    if configWindow.showTimersCheck then
        configWindow.showTimersCheck:SetChecked(TotemDeckDB.showTimers)
    end
    if configWindow.lockPosCheck then
        configWindow.lockPosCheck:SetChecked(TotemDeckDB.locked)
    end
    if configWindow.alwaysShowCheck then
        configWindow.alwaysShowCheck:SetChecked(TotemDeckDB.alwaysShowPopup)
    end
    if configWindow.showReincCheck then
        configWindow.showReincCheck:SetChecked(TotemDeckDB.showReincarnation)
    end
    if configWindow.showWeaponCheck then
        configWindow.showWeaponCheck:SetChecked(TotemDeckDB.showWeaponBuffs)
    end
end

local function ToggleConfigWindow()
    local frame = CreateConfigWindow()

    if frame:IsShown() then
        frame:Hide()
    else
        RefreshConfigWindowState()
        for element, section in pairs(frame.sections) do
            PopulateConfigSection(section.scrollChild, element)
        end
        frame:Show()
    end
end

-- Create the action bar with active totem buttons
local function CreateActionBarFrame()
    local direction = TotemDeckDB.popupDirection or "UP"
    local isVertical = (direction == "LEFT" or direction == "RIGHT")

    actionBarFrame = CreateFrame("Frame", "TotemDeckBar", UIParent, "BackdropTemplate")
    if isVertical then
        actionBarFrame:SetSize(48, 200) -- Vertical bar
    else
        actionBarFrame:SetSize(200, 48) -- Horizontal bar
    end
    actionBarFrame:SetPoint(TotemDeckDB.barPos.point, TotemDeckDB.barPos.x, TotemDeckDB.barPos.y)

    actionBarFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    actionBarFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    actionBarFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    -- Make movable with Ctrl+Click
    actionBarFrame:SetMovable(true)
    actionBarFrame:EnableMouse(true)
    actionBarFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and IsControlKeyDown() and not TotemDeckDB.locked then
            self:StartMoving()
        end
    end)
    actionBarFrame:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        TotemDeckDB.barPos = { point = point, x = x, y = y }
    end)

    -- Create 4 active totem buttons
    for i, element in ipairs(GetElementOrder()) do
        local activeKey = "active" .. element
        local totemName = TotemDeckDB[activeKey]
        local totemData = GetTotemData(totemName)
        local color = ELEMENT_COLORS[element]

        local btn = CreateFrame("Button", "TotemDeckActive" .. element, actionBarFrame, "SecureActionButtonTemplate")
        btn:SetSize(40, 40)
        if isVertical then
            btn:SetPoint("TOP", 0, -8 - (i - 1) * 48) -- Stacked vertically
        else
            btn:SetPoint("LEFT", 8 + (i - 1) * 48, 0) -- Spaced horizontally
        end

        -- Add backdrop manually
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

        btn.border = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        btn.border:SetPoint("TOPLEFT", -2, 2)
        btn.border:SetPoint("BOTTOMRIGHT", 2, -2)
        btn.border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
        })
        btn.border:SetBackdropBorderColor(color.r, color.g, color.b, 1)
        btn.border:EnableMouse(false) -- Don't intercept clicks

        -- Icon
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(36, 36)
        icon:SetPoint("CENTER")
        if totemData then
            icon:SetTexture(totemData.icon)
        end
        btn.icon = icon

        -- Register for clicks BEFORE setting attributes
        btn:RegisterForClicks("AnyDown", "AnyUp")

        -- Set up secure casting (but not when ctrl is held)
        btn:SetAttribute("type1", "spell")
        btn:SetAttribute("ctrl-type1", nil) -- Do nothing on ctrl+click
        if totemData then
            btn:SetAttribute("spell1", totemName)
            btn.totemName = totemName
        end

        -- Shift+right-click to cast Totemic Call (recall all totems)
        btn:SetAttribute("shift-type2", "spell")
        btn:SetAttribute("shift-spell2", "Totemic Call")

        -- Right-click to dismiss totem (but not when shift is held)
        btn:HookScript("PostClick", function(self, button)
            if button == "RightButton" and not IsShiftKeyDown() then
                local slot = TOTEM_SLOTS[self.element]
                if slot then
                    DestroyTotem(slot)
                end
            end
        end)

        -- Ctrl+click to move the frame
        btn:HookScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and IsControlKeyDown() and not TotemDeckDB.locked then
                actionBarFrame:StartMoving()
            end
        end)
        btn:HookScript("OnMouseUp", function(self, button)
            actionBarFrame:StopMovingOrSizing()
            local point, _, _, x, y = actionBarFrame:GetPoint()
            TotemDeckDB.barPos = { point = point, x = x, y = y }
        end)

        -- Show popup on hover
        btn:SetScript("OnEnter", function(self)
            self.border:SetBackdropBorderColor(1, 1, 1, 1)
            ShowPopup(self.element, self)
            -- Show tooltip using spell info
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.showingPlaced and self.placedTotemName then
                -- Show placed totem info
                local _, _, _, _, _, _, spellID = GetSpellInfo(self.placedTotemName)
                if spellID then
                    GameTooltip:SetSpellByID(spellID)
                else
                    GameTooltip:SetText(self.placedTotemName, 1, 1, 1)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Currently placed (not your active totem)", 0.7, 0.7, 0.7)
            elseif self.totemName then
                local _, _, _, _, _, _, spellID = GetSpellInfo(self.totemName)
                if spellID then
                    GameTooltip:SetSpellByID(spellID)
                else
                    GameTooltip:SetText(self.totemName, 1, 1, 1)
                end
            else
                GameTooltip:SetText(self.element .. " Totem", 1, 1, 1)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Left-click to cast", 0.5, 0.5, 0.5)
            GameTooltip:AddLine("Right-click to dismiss", 0.5, 0.5, 0.5)
            GameTooltip:AddLine("Shift+Right-click for Totemic Call", 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end)

        btn:SetScript("OnLeave", function(self)
            if self.showingPlaced then
                self.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
            else
                self.border:SetBackdropBorderColor(color.r, color.g, color.b, 1)
            end
            GameTooltip:Hide()
            -- Popup hides via OnUpdate check
        end)

        btn.element = element
        btn.color = color
        activeTotemButtons[element] = btn

        -- Icon timer display (shown when timerStyle == "icons")
        local iconTimer = CreateFrame("Frame", nil, btn)
        iconTimer:SetSize(40, 16)
        iconTimer:SetPoint("TOP", btn, "BOTTOM", 0, -2)

        local iconTimerText = iconTimer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        iconTimerText:SetPoint("CENTER")
        iconTimerText:SetTextColor(1, 1, 1)

        btn.iconTimer = iconTimer
        btn.iconTimerText = iconTimerText
        iconTimer:Hide()

        -- Create popup column for this element (anchored to this button)
        CreatePopupColumn(element, btn)
    end

    -- Create Reincarnation tracker button (left/top side)
    CreateReincarnationButton(isVertical)

    -- Create Weapon Buff button (right/bottom side)
    CreateWeaponBuffButton(isVertical)

    actionBarFrame:Show()
end

-- Create Reincarnation tracker button
CreateReincarnationButton = function(isVertical)
    if not TotemDeckDB.showReincarnation then return end

    local btn = CreateFrame("Button", "TotemDeckReincarnation", actionBarFrame)
    btn:SetSize(28, 28)

    if isVertical then
        btn:SetPoint("BOTTOM", actionBarFrame, "TOP", 0, 4)
    else
        btn:SetPoint("RIGHT", actionBarFrame, "LEFT", -4, 0)
        btn:SetPoint("BOTTOM", actionBarFrame, "BOTTOM", 0, 2)
    end

    -- Background
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

    -- Border
    btn.border = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    btn.border:SetPoint("TOPLEFT", -1, 1)
    btn.border:SetPoint("BOTTOMRIGHT", 1, -1)
    btn.border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn.border:SetBackdropBorderColor(0.5, 0.3, 0.6, 1) -- Purple for Reincarnation
    btn.border:EnableMouse(false)

    -- Icon (Reincarnation spell)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("CENTER")
    local reincIcon = GetSpellTexture("Reincarnation")
    icon:SetTexture(reincIcon or "Interface\\Icons\\Spell_Nature_Reincarnation")
    btn.icon = icon

    -- Ankh count text (bottom-right corner)
    local countText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    countText:SetPoint("BOTTOMRIGHT", -1, 1)
    countText:SetTextColor(1, 1, 1)
    btn.countText = countText

    -- Cooldown frame
    local cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetDrawSwipe(true)
    cooldown:SetDrawEdge(false)
    btn.cooldown = cooldown

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        self.border:SetBackdropBorderColor(1, 1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local _, _, _, _, _, _, spellID = GetSpellInfo("Reincarnation")
        if spellID then
            GameTooltip:SetSpellByID(spellID)
        else
            GameTooltip:SetText("Reincarnation", 1, 1, 1)
        end
        local ankhCount = GetItemCount(ANKH_ITEM_ID)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Ankhs: " .. ankhCount, 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function(self)
        -- Restore border color based on Ankh count
        local ankhCount = GetItemCount(ANKH_ITEM_ID)
        if ankhCount == 0 then
            self.border:SetBackdropBorderColor(0.8, 0.2, 0.2, 1) -- Red when no Ankhs
        else
            self.border:SetBackdropBorderColor(0.5, 0.3, 0.6, 1) -- Purple normally
        end
        GameTooltip:Hide()
    end)

    reincarnationButton = btn
    UpdateReincarnationButton()
end

-- Update Reincarnation button state (Ankh count, cooldown)
UpdateReincarnationButton = function()
    if not reincarnationButton then return end

    local ankhCount = GetItemCount(ANKH_ITEM_ID)
    reincarnationButton.countText:SetText(ankhCount > 0 and ankhCount or "")

    -- Update cooldown
    local start, duration, enabled = GetSpellCooldown("Reincarnation")
    if start and duration and duration > 1.5 then
        reincarnationButton.cooldown:SetCooldown(start, duration)
    else
        reincarnationButton.cooldown:Clear()
    end

    -- Dim if no Ankhs or on cooldown
    local onCooldown = start and duration and duration > 1.5
    if ankhCount == 0 or onCooldown then
        reincarnationButton.icon:SetDesaturated(true)
        reincarnationButton.icon:SetAlpha(0.5)
    else
        reincarnationButton.icon:SetDesaturated(false)
        reincarnationButton.icon:SetAlpha(1)
    end

    -- Update border color based on Ankh count
    if ankhCount == 0 then
        reincarnationButton.border:SetBackdropBorderColor(0.8, 0.2, 0.2, 1) -- Red when no Ankhs
    else
        reincarnationButton.border:SetBackdropBorderColor(0.5, 0.3, 0.6, 1) -- Purple normally
    end
end

-- Create Weapon Buff button and popup
CreateWeaponBuffButton = function(isVertical)
    if not TotemDeckDB.showWeaponBuffs then return end

    local knownBuffs = GetKnownWeaponBuffs()
    if #knownBuffs == 0 then return end -- No weapon buffs known

    -- Use SecureActionButtonTemplate so we can cast spells
    local btn = CreateFrame("Button", "TotemDeckWeaponBuff", actionBarFrame, "SecureActionButtonTemplate")
    btn:SetSize(28, 28)

    if isVertical then
        btn:SetPoint("TOP", actionBarFrame, "BOTTOM", 0, -4)
    else
        btn:SetPoint("LEFT", actionBarFrame, "RIGHT", 4, 0)
        btn:SetPoint("BOTTOM", actionBarFrame, "BOTTOM", 0, 2)
    end

    -- Register for clicks
    btn:RegisterForClicks("AnyDown", "AnyUp")

    -- Set up default spell (first known buff, will be updated by UpdateWeaponBuffButton)
    local defaultBuff = knownBuffs[1].name
    btn:SetAttribute("type1", "spell")
    btn:SetAttribute("spell1", defaultBuff)
    btn:SetAttribute("type2", "macro")
    btn:SetAttribute("macrotext2", "/use 17\n/cast " .. defaultBuff)

    -- Background
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

    -- Border
    btn.border = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    btn.border:SetPoint("TOPLEFT", -1, 1)
    btn.border:SetPoint("BOTTOMRIGHT", 1, -1)
    btn.border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn.border:SetBackdropBorderColor(0.4, 0.6, 0.8, 1) -- Blue-ish for weapons
    btn.border:EnableMouse(false)

    -- Icon (show first known weapon buff icon by default)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("CENTER")
    local defaultIcon = GetSpellTexture(knownBuffs[1].name) or knownBuffs[1].icon
    icon:SetTexture(defaultIcon)
    btn.icon = icon
    btn.currentBuffName = defaultBuff -- Track current buff for casting

    -- Timer text (shows remaining weapon buff duration) - overlay on button
    local timerText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    timerText:SetPoint("BOTTOM", btn, "BOTTOM", 0, 1)
    timerText:SetTextColor(1, 1, 1)
    timerText:SetShadowOffset(1, -1)
    timerText:SetShadowColor(0, 0, 0, 1)
    btn.timerText = timerText

    -- Create popup for weapon buffs
    local direction = TotemDeckDB.popupDirection or "UP"
    local popupIsHorizontal = (direction == "LEFT" or direction == "RIGHT")

    local popup = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    if popupIsHorizontal then
        popup:SetSize(#knownBuffs * 40 + 8, 44)
    else
        popup:SetSize(44, #knownBuffs * 40 + 8)
    end

    -- Anchor based on popup direction
    if direction == "UP" then
        popup:SetPoint("BOTTOM", btn, "TOP", 0, 2)
    elseif direction == "DOWN" then
        popup:SetPoint("TOP", btn, "BOTTOM", 0, -2)
    elseif direction == "LEFT" then
        popup:SetPoint("RIGHT", btn, "LEFT", -2, 0)
    else -- RIGHT
        popup:SetPoint("LEFT", btn, "RIGHT", 2, 0)
    end

    popup:SetFrameStrata("DIALOG")
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    popup:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    popup:SetBackdropBorderColor(0.4, 0.6, 0.8, 1)
    popup:Hide()
    weaponBuffPopup = popup

    -- Create popup buttons for each weapon buff
    weaponBuffPopupButtons = {}
    for i, buffData in ipairs(knownBuffs) do
        buttonCounter = buttonCounter + 1
        local btnName = "TotemDeckWeaponBuffPopup" .. buttonCounter

        -- Visual frame
        local visual = CreateFrame("Frame", nil, popup, "BackdropTemplate")
        visual:SetSize(36, 36)
        visual:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        visual:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        visual:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        local buffIcon = visual:CreateTexture(nil, "ARTWORK")
        buffIcon:SetSize(32, 32)
        buffIcon:SetPoint("CENTER")
        local spellIcon = GetSpellTexture(buffData.name)
        buffIcon:SetTexture(spellIcon or buffData.icon)
        visual.icon = buffIcon

        -- Secure button on top
        local popupBtn = CreateFrame("Button", btnName, popup, "SecureActionButtonTemplate")
        popupBtn:SetSize(36, 36)
        popupBtn:SetAllPoints(visual)
        popupBtn:SetFrameLevel(visual:GetFrameLevel() + 1)

        popupBtn.visual = visual
        popupBtn.border = visual
        popupBtn.buffName = buffData.name

        -- Get spell ID for tooltip
        local _, _, _, _, _, _, spellID = GetSpellInfo(buffData.name)
        popupBtn.spellID = spellID

        -- Register for clicks
        popupBtn:RegisterForClicks("AnyDown", "AnyUp")

        -- Left click = cast on main hand
        popupBtn:SetAttribute("type1", "spell")
        popupBtn:SetAttribute("spell1", buffData.name)

        -- Right click = cast on offhand (uses macro approach)
        popupBtn:SetAttribute("type2", "macro")
        popupBtn:SetAttribute("macrotext2", "/use 17\n/cast " .. buffData.name)

        -- Position in popup
        if direction == "UP" then
            local yOffset = 4 + (i - 1) * 40
            visual:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 4, yOffset)
        elseif direction == "DOWN" then
            local yOffset = 4 + (i - 1) * 40
            visual:SetPoint("TOPLEFT", popup, "TOPLEFT", 4, -yOffset)
        elseif direction == "LEFT" then
            local xOffset = 4 + (i - 1) * 40
            visual:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -xOffset, -4)
        else -- RIGHT
            local xOffset = 4 + (i - 1) * 40
            visual:SetPoint("TOPLEFT", popup, "TOPLEFT", xOffset, -4)
        end

        -- Tooltip
        popupBtn:SetScript("OnEnter", function(self)
            self.border:SetBackdropBorderColor(1, 1, 1, 1)
            weaponBuffPopupVisible = true -- Keep popup visible
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.spellID then
                GameTooltip:SetSpellByID(self.spellID)
            else
                GameTooltip:SetText(self.buffName, 1, 1, 1)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Left-click: Apply to main hand", 0.5, 0.5, 0.5)
            GameTooltip:AddLine("Right-click: Apply to off-hand", 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end)

        popupBtn:SetScript("OnLeave", function(self)
            self.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            GameTooltip:Hide()
            -- Delay hiding popup to allow moving to other buttons
            C_Timer.After(0.15, function()
                if weaponBuffPopup and weaponBuffButton then
                    local overAnyBtn = weaponBuffPopup:IsMouseOver() or weaponBuffButton:IsMouseOver()
                    if not overAnyBtn then
                        for _, pb in ipairs(weaponBuffPopupButtons) do
                            if pb:IsMouseOver() then
                                overAnyBtn = true
                                break
                            end
                        end
                    end
                    if not overAnyBtn then
                        if not InCombatLockdown() then
                            weaponBuffPopup:Hide()
                        end
                        weaponBuffPopupVisible = false
                    end
                end
            end)
        end)

        visual:Show()
        popupBtn:Show()
        weaponBuffPopupButtons[i] = popupBtn
    end

    -- Main button hover shows popup
    btn:SetScript("OnEnter", function(self)
        self.border:SetBackdropBorderColor(1, 1, 1, 1)
        if not InCombatLockdown() then
            weaponBuffPopup:Show()
        end
        weaponBuffPopupVisible = true

        -- Show tooltip with current weapon enchant info
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Weapon Buffs", 1, 1, 1)

        local enchantInfo = GetCurrentWeaponBuff()
        if enchantInfo.mainHand and enchantInfo.mainHandBuff then
            GameTooltip:AddLine("Main Hand: " .. enchantInfo.mainHandBuff.name, 0, 1, 0)
        elseif enchantInfo.mainHand then
            GameTooltip:AddLine("Main Hand: Enchanted", 0, 1, 0)
        else
            GameTooltip:AddLine("Main Hand: None", 0.5, 0.5, 0.5)
        end
        if enchantInfo.offHand and enchantInfo.offHandBuff then
            GameTooltip:AddLine("Off Hand: " .. enchantInfo.offHandBuff.name, 0, 1, 0)
        elseif enchantInfo.offHand then
            GameTooltip:AddLine("Off Hand: Enchanted", 0, 1, 0)
        else
            GameTooltip:AddLine("Off Hand: None", 0.5, 0.5, 0.5)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: Apply to main hand", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Right-click: Apply to off-hand", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function(self)
        -- Restore border color based on enchant state
        local enchantInfo = GetCurrentWeaponBuff()
        if enchantInfo.mainHand then
            self.border:SetBackdropBorderColor(0.2, 0.8, 0.2, 1) -- Green when buffed
        else
            self.border:SetBackdropBorderColor(0.8, 0.2, 0.2, 1) -- Red when no buff
        end
        GameTooltip:Hide()
        -- Delay hiding popup to allow moving to it
        C_Timer.After(0.15, function()
            if weaponBuffPopup and not weaponBuffPopup:IsMouseOver() and not btn:IsMouseOver() then
                if not InCombatLockdown() then
                    weaponBuffPopup:Hide()
                end
                weaponBuffPopupVisible = false
            end
        end)
    end)

    -- Popup mouse leave handler
    popup:SetScript("OnLeave", function(self)
        C_Timer.After(0.15, function()
            if weaponBuffPopup and not weaponBuffPopup:IsMouseOver() and not btn:IsMouseOver() then
                local overAnyBtn = false
                for _, popBtn in ipairs(weaponBuffPopupButtons) do
                    if popBtn:IsMouseOver() then
                        overAnyBtn = true
                        break
                    end
                end
                if not overAnyBtn then
                    if not InCombatLockdown() then
                        weaponBuffPopup:Hide()
                    end
                    weaponBuffPopupVisible = false
                end
            end
        end)
    end)

    weaponBuffButton = btn
    UpdateWeaponBuffButton()
end

-- Update Weapon Buff button to show current main-hand enchant icon
UpdateWeaponBuffButton = function()
    if not weaponBuffButton then return end

    local enchantInfo = GetCurrentWeaponBuff()
    local buffToUse = nil

    -- Update icon to show active buff
    if enchantInfo.mainHand and enchantInfo.mainHandBuff then
        -- Show the active buff icon
        local buffIcon = GetSpellTexture(enchantInfo.mainHandBuff.name) or enchantInfo.mainHandBuff.icon
        weaponBuffButton.icon:SetTexture(buffIcon)
        weaponBuffButton.icon:SetDesaturated(false)
        weaponBuffButton.icon:SetAlpha(1)
        weaponBuffButton.border:SetBackdropBorderColor(0.2, 0.8, 0.2, 1) -- Green when buffed
        buffToUse = enchantInfo.mainHandBuff.name
    elseif enchantInfo.mainHand then
        -- Has enchant but we don't know which one (e.g., on login)
        -- Keep current icon but show green border
        weaponBuffButton.icon:SetDesaturated(false)
        weaponBuffButton.icon:SetAlpha(1)
        weaponBuffButton.border:SetBackdropBorderColor(0.2, 0.8, 0.2, 1) -- Green when buffed
    else
        -- No enchant - show last used buff or first known, dimmed with red border
        local knownBuffs = GetKnownWeaponBuffs()
        if #knownBuffs > 0 then
            -- Use saved buff if available, otherwise first known
            local savedBuff = TotemDeckDB and TotemDeckDB.lastMainHandBuff
            local buffData = savedBuff and GetWeaponBuffByName(savedBuff) or knownBuffs[1]
            local defaultIcon = GetSpellTexture(buffData.name) or buffData.icon
            weaponBuffButton.icon:SetTexture(defaultIcon)
            buffToUse = buffData.name
        end
        weaponBuffButton.icon:SetDesaturated(true)
        weaponBuffButton.icon:SetAlpha(0.5)
        weaponBuffButton.border:SetBackdropBorderColor(0.8, 0.2, 0.2, 1) -- Red when no buff
    end

    -- Update spell attributes for clicking (only outside combat)
    if buffToUse and buffToUse ~= weaponBuffButton.currentBuffName and not InCombatLockdown() then
        weaponBuffButton:SetAttribute("spell1", buffToUse)
        weaponBuffButton:SetAttribute("macrotext2", "/use 17\n/cast " .. buffToUse)
        weaponBuffButton.currentBuffName = buffToUse
    end

    -- Update timer text
    if weaponBuffButton.timerText then
        if enchantInfo.mainHandTime then
            -- mainHandTime is in milliseconds
            local seconds = math.floor(enchantInfo.mainHandTime / 1000)
            if seconds >= 60 then
                weaponBuffButton.timerText:SetText(string.format("%d:%02d", math.floor(seconds / 60), seconds % 60))
            else
                weaponBuffButton.timerText:SetText(string.format("%d", seconds))
            end
            weaponBuffButton.timerText:Show()
        else
            weaponBuffButton.timerText:SetText("")
            weaponBuffButton.timerText:Hide()
        end
    end
end

-- Create timer frame (position based on timerPosition setting)
local function CreateTimerFrame()
    local timerPos = TotemDeckDB.timerPosition or "ABOVE"

    timerFrame = CreateFrame("Frame", "TotemDeckTimers", actionBarFrame, "BackdropTemplate")
    timerFrame:SetSize(200, 100)
    timerFrame:SetFrameStrata("MEDIUM") -- Below popups (DIALOG) so they render on top

    -- Position based on timerPosition setting
    if timerPos == "ABOVE" then
        timerFrame:SetPoint("BOTTOM", actionBarFrame, "TOP", 0, 2)
    elseif timerPos == "BELOW" then
        timerFrame:SetPoint("TOP", actionBarFrame, "BOTTOM", 0, -2)
    elseif timerPos == "LEFT" then
        timerFrame:SetPoint("RIGHT", actionBarFrame, "LEFT", -2, 0)
    else -- RIGHT
        timerFrame:SetPoint("LEFT", actionBarFrame, "RIGHT", 2, 0)
    end

    timerFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    timerFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    timerFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    -- Create timer bars for each element
    for i, element in ipairs(GetElementOrder()) do
        local bar = CreateTimerBar(timerFrame, element, i)
        bar:SetPoint("BOTTOM", 0, 5 + (i - 1) * 24)
        timerBars[element] = bar
    end

    timerFrame:Hide()
end

-- Update timer bars
UpdateTimers = function()
    local anyActive = false
    local timerStyle = TotemDeckDB.timerStyle or "bars"
    local showTimers = TotemDeckDB.showTimers

    for slot = 1, 4 do
        local haveTotem, totemName, startTime, duration = GetTotemInfo(slot)
        local element = nil

        -- Map slot to element
        for elem, slotNum in pairs(TOTEM_SLOTS) do
            if slotNum == slot then
                element = elem
                break
            end
        end

        if element then
            local bar = timerBars[element]
            local btn = activeTotemButtons[element]
            local activeTotemName = TotemDeckDB["active" .. element]

            if haveTotem and duration > 0 then
                local remaining = (startTime + duration) - GetTime()

                if remaining > 0 then
                    anyActive = true

                    -- Update bar timer (bars mode)
                    if bar and timerStyle == "bars" then
                        bar:Show()
                        bar.statusBar:SetMinMaxValues(0, duration)
                        bar.statusBar:SetValue(remaining)
                        bar.text:SetText(totemName:gsub(" Totem", ""))
                        bar.timeText:SetText(FormatTime(math.floor(remaining)))
                    elseif bar then
                        bar:Hide()
                    end

                    -- Update icon timer (icons mode)
                    if btn and btn.iconTimer then
                        if timerStyle == "icons" and showTimers then
                            btn.iconTimerText:SetText(FormatTime(math.floor(remaining)))
                            btn.iconTimer:Show()
                        else
                            btn.iconTimer:Hide()
                        end
                    end

                    -- Update button to show placed totem (if different from active)
                    if btn then
                        -- Strip rank suffix for comparison (e.g., "Searing Totem VII" -> "Searing Totem")
                        local baseTotemName = totemName:gsub("%s+[IVXLCDM]+$", "")
                        if baseTotemName ~= activeTotemName then
                            -- Placed totem differs from active - show with visual indicator
                            local placedIcon = GetSpellTexture(baseTotemName) or GetSpellTexture(totemName)
                            if placedIcon then
                                btn.icon:SetTexture(placedIcon)
                                btn.icon:SetDesaturated(true)
                                btn.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                                btn.showingPlaced = true
                                btn.placedTotemName = totemName
                            end
                        elseif btn.showingPlaced then
                            -- Placed totem matches active - revert to normal display
                            local activeIcon = GetSpellTexture(activeTotemName)
                            if activeIcon then
                                btn.icon:SetTexture(activeIcon)
                            end
                            btn.icon:SetDesaturated(false)
                            btn.border:SetBackdropBorderColor(btn.color.r, btn.color.g, btn.color.b, 1)
                            btn.showingPlaced = false
                            btn.placedTotemName = nil
                        end
                    end
                else
                    if bar then bar:Hide() end
                    if btn and btn.iconTimer then btn.iconTimer:Hide() end
                    -- Revert button display when totem expires
                    if btn and btn.showingPlaced then
                        local activeIcon = GetSpellTexture(activeTotemName)
                        if activeIcon then
                            btn.icon:SetTexture(activeIcon)
                        end
                        btn.icon:SetDesaturated(false)
                        btn.border:SetBackdropBorderColor(btn.color.r, btn.color.g, btn.color.b, 1)
                        btn.showingPlaced = false
                        btn.placedTotemName = nil
                    end
                end
            else
                if bar then bar:Hide() end
                if btn and btn.iconTimer then btn.iconTimer:Hide() end
                -- Revert button display when no totem placed
                if btn and btn.showingPlaced then
                    local activeIcon = GetSpellTexture(activeTotemName)
                    if activeIcon then
                        btn.icon:SetTexture(activeIcon)
                    end
                    btn.icon:SetDesaturated(false)
                    btn.border:SetBackdropBorderColor(btn.color.r, btn.color.g, btn.color.b, 1)
                    btn.showingPlaced = false
                    btn.placedTotemName = nil
                end
            end
        end
    end

    -- Show/hide bar timer frame
    if anyActive and showTimers and timerStyle == "bars" then
        timerFrame:Show()
        -- Resize timer frame based on visible bars
        local visibleCount = 0
        for _, bar in pairs(timerBars) do
            if bar:IsShown() then
                visibleCount = visibleCount + 1
            end
        end
        timerFrame:SetHeight(10 + visibleCount * 24)

        -- Reposition visible bars based on timer position
        local timerPos = TotemDeckDB.timerPosition or "ABOVE"
        local yOffset = 5
        for _, element in ipairs(GetElementOrder()) do
            local bar = timerBars[element]
            if bar:IsShown() then
                bar:ClearAllPoints()
                -- ABOVE, LEFT, RIGHT stack from bottom; BELOW stacks from top
                if timerPos == "BELOW" then
                    bar:SetPoint("TOP", 0, -yOffset)
                else
                    bar:SetPoint("BOTTOM", 0, yOffset)
                end
                yOffset = yOffset + 24
            end
        end
    else
        timerFrame:Hide()
    end
end

-- Event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_TOTEM_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Leaving combat
eventFrame:RegisterEvent("BAG_UPDATE") -- For Ankh count updates
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED") -- For weapon enchant updates
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN") -- For Reincarnation cooldown
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED") -- For detecting weapon buff casts
eventFrame:RegisterEvent("UNIT_SPELLCAST_START") -- For tracking pre-cast enchant state

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize saved variables
        if not TotemDeckDB then
            TotemDeckDB = {}
        end
        for key, value in pairs(defaults) do
            if TotemDeckDB[key] == nil then
                TotemDeckDB[key] = value
            end
        end
        -- Ensure elementOrder has all 4 elements
        if not TotemDeckDB.elementOrder or #TotemDeckDB.elementOrder ~= 4 then
            TotemDeckDB.elementOrder = { "Earth", "Fire", "Water", "Air" }
        end
        -- Ensure totemOrder has all element keys
        if not TotemDeckDB.totemOrder then
            TotemDeckDB.totemOrder = {}
        end
        for _, element in ipairs(ELEMENT_ORDER) do
            if not TotemDeckDB.totemOrder[element] then
                TotemDeckDB.totemOrder[element] = {}
            end
        end
        -- Ensure hiddenTotems has all element keys
        if not TotemDeckDB.hiddenTotems then
            TotemDeckDB.hiddenTotems = {}
        end
        for _, element in ipairs(ELEMENT_ORDER) do
            if not TotemDeckDB.hiddenTotems[element] then
                TotemDeckDB.hiddenTotems[element] = {}
            end
        end

    elseif event == "PLAYER_LOGIN" then
        if not IsShaman() then
            return
        end

        -- Restore saved weapon buff info before creating UI
        RestoreSavedWeaponBuffs()

        CreateActionBarFrame()
        CreateTimerFrame()
        SetupPopupSystem()

        -- Show popup if always show is enabled
        if TotemDeckDB.alwaysShowPopup then
            ShowPopup(GetElementOrder()[1])
        end

        -- Create macros after a short delay (needs UI to be ready)
        C_Timer.After(2, function()
            CreateTotemMacros()
        end)

    elseif event == "PLAYER_TOTEM_UPDATE" then
        UpdateTimers()

    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat: ensure all popup containers are shown (at alpha=0 if hidden)
        -- so we can Show/Hide via alpha during combat
        for _, container in pairs(popupContainers) do
            if not container:IsShown() then
                container:Show()
                container:SetAlpha(0)
                container:SetFrameStrata("BACKGROUND")
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat: apply any pending active totem updates
        for element, _ in pairs(pendingActiveUpdates) do
            UpdateActiveTotemButton(element)
            UpdateTotemMacro(element)
        end
        pendingActiveUpdates = {}

    elseif event == "BAG_UPDATE" then
        -- Update Ankh count for Reincarnation button
        UpdateReincarnationButton()

    elseif event == "UNIT_INVENTORY_CHANGED" then
        -- Update weapon buff button when equipment changes
        if arg1 == "player" then
            UpdateWeaponBuffButton()
        end

    elseif event == "SPELL_UPDATE_COOLDOWN" then
        -- Update Reincarnation cooldown display
        UpdateReincarnationButton()

    elseif event == "UNIT_SPELLCAST_START" then
        -- Track enchant state before casting a weapon buff
        if arg1 == "player" and arg3 then
            local spellName = GetSpellInfo(arg3)
            if spellName and GetWeaponBuffByName(spellName) then
                TrackPreCastEnchantState()
            end
        end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- Detect when player casts a weapon buff
        -- In Classic/TBC: UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
        if arg1 == "player" and arg3 then
            local spellName = GetSpellInfo(arg3)
            if spellName then
                OnWeaponBuffCast(spellName)
            end
        end
    end
end)

-- Timer update (runs every 0.1 seconds)
local timerUpdateFrame = CreateFrame("Frame")
local elapsed = 0
timerUpdateFrame:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.1 then
        elapsed = 0
        -- Update totem timers
        if timerFrame and timerFrame:IsShown() then
            UpdateTimers()
        end
        -- Update weapon buff timer
        if weaponBuffButton then
            UpdateWeaponBuffButton()
        end
    end
end)

-- Rebuild entire UI (needed when direction changes - affects bar layout)
RebuildPopupColumns = function()
    if InCombatLockdown() then
        print("|cFF00FF00TotemDeck:|r Cannot change direction in combat")
        return false
    end

    -- Hide popup first
    HidePopup()

    -- Destroy existing popup containers
    for element, container in pairs(popupContainers) do
        container:Hide()
        container:SetParent(nil)
    end
    popupContainers = {}
    popupButtons = {}

    -- Destroy existing action bar buttons
    for element, btn in pairs(activeTotemButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    activeTotemButtons = {}

    -- Destroy reincarnation button
    if reincarnationButton then
        reincarnationButton:Hide()
        reincarnationButton:SetParent(nil)
        reincarnationButton = nil
    end

    -- Destroy weapon buff button and popup
    if weaponBuffPopup then
        weaponBuffPopup:Hide()
        weaponBuffPopup:SetParent(nil)
        weaponBuffPopup = nil
    end
    if weaponBuffButton then
        weaponBuffButton:Hide()
        weaponBuffButton:SetParent(nil)
        weaponBuffButton = nil
    end
    weaponBuffPopupButtons = {}

    -- Destroy and recreate action bar frame with new layout
    local savedPos = nil
    if actionBarFrame then
        local point, _, _, x, y = actionBarFrame:GetPoint()
        savedPos = { point = point, x = x, y = y }
        actionBarFrame:Hide()
        actionBarFrame:SetParent(nil)
        actionBarFrame = nil
    end

    -- Recreate action bar (which also recreates popup columns)
    CreateActionBarFrame()

    -- Restore position
    if savedPos then
        actionBarFrame:ClearAllPoints()
        actionBarFrame:SetPoint(savedPos.point, savedPos.x, savedPos.y)
    end

    -- Rebuild timer frame to match new layout
    RebuildTimerFrame()

    -- Show popup if always show is enabled
    if TotemDeckDB.alwaysShowPopup then
        ShowPopup(GetElementOrder()[1])
    end

    return true
end

-- Rebuild timer frame (needed when position changes)
RebuildTimerFrame = function()
    if timerFrame then
        timerFrame:Hide()
        timerFrame:SetParent(nil)
        timerFrame = nil
    end
    timerBars = {}
    CreateTimerFrame()
    UpdateTimers()
end

-- Slash commands
SLASH_TOTEMDECK1 = "/td"

SlashCmdList["TOTEMDECK"] = function(msg)
    local cmd = msg:lower():trim()

    if cmd == "show" then
        if actionBarFrame then
            if actionBarFrame:IsShown() then
                actionBarFrame:Hide()
            else
                actionBarFrame:Show()
            end
        end
    elseif cmd == "timers" then
        TotemDeckDB.showTimers = not TotemDeckDB.showTimers
        if not TotemDeckDB.showTimers and timerFrame then
            timerFrame:Hide()
        elseif TotemDeckDB.showTimers then
            UpdateTimers()
        end
    elseif cmd == "macros" then
        CreateTotemMacros()
    elseif cmd == "config" then
        ToggleConfigWindow()
    elseif cmd == "popup up" then
        TotemDeckDB.popupDirection = "UP"
        if RebuildPopupColumns() then
            print("|cFF00FF00TotemDeck:|r Popup direction set to UP")
        end
    elseif cmd == "popup down" then
        TotemDeckDB.popupDirection = "DOWN"
        if RebuildPopupColumns() then
            print("|cFF00FF00TotemDeck:|r Popup direction set to DOWN")
        end
    elseif cmd == "popup left" then
        TotemDeckDB.popupDirection = "LEFT"
        if RebuildPopupColumns() then
            print("|cFF00FF00TotemDeck:|r Popup direction set to LEFT")
        end
    elseif cmd == "popup right" then
        TotemDeckDB.popupDirection = "RIGHT"
        if RebuildPopupColumns() then
            print("|cFF00FF00TotemDeck:|r Popup direction set to RIGHT")
        end
    elseif cmd == "timers above" then
        TotemDeckDB.timerPosition = "ABOVE"
        RebuildTimerFrame()
        print("|cFF00FF00TotemDeck:|r Timers position set to ABOVE")
    elseif cmd == "timers below" then
        TotemDeckDB.timerPosition = "BELOW"
        RebuildTimerFrame()
        print("|cFF00FF00TotemDeck:|r Timers position set to BELOW")
    elseif cmd == "timers left" then
        TotemDeckDB.timerPosition = "LEFT"
        RebuildTimerFrame()
        print("|cFF00FF00TotemDeck:|r Timers position set to LEFT")
    elseif cmd == "timers right" then
        TotemDeckDB.timerPosition = "RIGHT"
        RebuildTimerFrame()
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
