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
    totemOrder = { -- Custom totem order per element (empty = use default)
        Earth = {},
        Fire = {},
        Water = {},
        Air = {},
    },
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

-- UI elements
local timerFrame, actionBarFrame
local timerBars = {}
local activeTotemButtons = {}
local popupButtons = {}
local popupContainers = {} -- Container frames for each element, anchored to main bar buttons
local popupBlockers = {} -- Blocker frames to prevent clicks when hidden
local buttonCounter = 0
local popupVisible = false
local popupHideDelay = 0

-- Forward declarations
local RebuildPopupColumns, RebuildTimerFrame, CreateTotemMacros, ShowPopup

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

-- Check if a totem spell is trained
local function IsTotemKnown(totemName)
    local name, _, _, _, _, _, spellID = GetSpellInfo(totemName)
    if not spellID then
        return false
    end
    return IsPlayerSpell(spellID)
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
        local macroBody = "/cast " .. (totemName or "")

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

    EditMacro(macroIndex, macroName, macroIcon, "/cast " .. totemName)
end

-- Set active totem for an element
local function SetActiveTotem(element, totemName)
    if InCombatLockdown() then
        return
    end

    local activeKey = "active" .. element
    TotemDeckDB[activeKey] = totemName

    -- Update active totem button
    UpdateActiveTotemButton(element)

    -- Update macro
    UpdateTotemMacro(element)

    -- Update popup buttons if visible
    if popupButtons[element] then
        for _, btn in ipairs(popupButtons[element]) do
            if btn.totemName == totemName then
                btn.border:SetBackdropBorderColor(0, 1, 0, 1)
            else
                btn.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            end
        end
    end
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
        -- Highlight entire column for this element
        ShowPopup(self.element)
        -- Then highlight this specific button
        self.border:SetBackdropBorderColor(1, 1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.totemName, 1, 1, 1)
        GameTooltip:AddLine("Duration: " .. FormatTime(self.totemDuration), 0.7, 0.7, 0.7)
        local activeKey = "active" .. self.element
        if TotemDeckDB[activeKey] == self.totemName then
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

    -- Hide all blockers so buttons are clickable
    for _, blocker in pairs(popupBlockers) do
        blocker:Hide()
    end

    -- Show all element columns, highlight the hovered one
    for elem, container in pairs(popupContainers) do
        local color = ELEMENT_COLORS[elem]
        container:SetAlpha(1)
        container:SetFrameStrata("DIALOG") -- Use DIALOG so GameTooltip (TOOLTIP strata) is above
        container:Show()

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
            container:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
            -- Dim the buttons in non-hovered columns
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

-- Forward declaration for UpdateTimers
local UpdateTimers

-- Hide all popup columns
local function HidePopup()
    popupVisible = false
    for _, container in pairs(popupContainers) do
        container:SetAlpha(0)
        -- Lower strata so we don't block other UI when hidden
        container:SetFrameStrata("BACKGROUND")
    end
    -- Show all blockers to intercept clicks on hidden buttons
    for _, blocker in pairs(popupBlockers) do
        blocker:Show()
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

    -- Filter to only trained totems
    local totems = {}
    for _, totemData in ipairs(allTotems) do
        if IsTotemKnown(totemData.name) then
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

    -- Create blocker frame (non-secure, can Show/Hide in combat)
    -- Blocks clicks on buttons when popup is hidden
    local blocker = CreateFrame("Frame", nil, container)
    blocker:SetAllPoints(container)
    blocker:SetFrameLevel(container:GetFrameLevel() + 100) -- Above all buttons
    blocker:EnableMouse(true) -- Intercepts mouse events
    blocker:Show() -- Start shown (popup starts hidden)
    popupBlockers[element] = blocker

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
    row:SetSize(170, 22)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * 24))
    row.totemName = totemData.name

    local upBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    upBtn:SetSize(20, 20)
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
    downBtn:SetSize(20, 20)
    downBtn:SetPoint("LEFT", upBtn, "RIGHT", 2, 0)
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
    icon:SetSize(18, 18)
    icon:SetPoint("LEFT", downBtn, "RIGHT", 4, 0)
    icon:SetTexture(GetSpellTexture(totemData.name) or totemData.icon)

    local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    name:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    name:SetJustifyH("LEFT")
    name:SetText(totemData.name:gsub(" Totem", ""))

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
    frame:SetSize(420, 420)
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

    -- Options
    local optionsSection = CreateLayoutSection(layoutContent, "Options", -160, 90)

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

    local sectionWidth = 185
    local sectionHeight = 140
    local sections = {}

    for i, element in ipairs(ELEMENT_ORDER) do
        local color = ELEMENT_COLORS[element]
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)

        local section = CreateFrame("Frame", nil, orderingContent, "BackdropTemplate")
        section:SetSize(sectionWidth, sectionHeight)
        section:SetPoint("TOPLEFT", orderingContent, "TOPLEFT", col * (sectionWidth + 10), -row * (sectionHeight + 10))
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
        for _, element in ipairs(ELEMENT_ORDER) do
            TotemDeckDB.totemOrder[element] = {}
            PopulateConfigSection(sections[element].scrollChild, element)
        end
        print("|cFF00FF00TotemDeck:|r Totem order reset to default")
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
        print("|cFF00FF00TotemDeck:|r Totem order applied")
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

-- Options menu
local optionsMenu = CreateFrame("Frame", "TotemDeckOptionsMenu", UIParent, "UIDropDownMenuTemplate")

local function InitializeOptionsMenu(self, level, menuList)
    level = level or 1
    local info = UIDropDownMenu_CreateInfo()

    if level == 1 then
        -- Title
        info.text = "TotemDeck Options"
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Popup Direction submenu
        info = UIDropDownMenu_CreateInfo()
        info.text = "Popup Direction"
        info.notCheckable = true
        info.hasArrow = true
        info.menuList = "POPUP_DIR"
        UIDropDownMenu_AddButton(info, level)

        -- Timer Position submenu
        info = UIDropDownMenu_CreateInfo()
        info.text = "Timer Position"
        info.notCheckable = true
        info.hasArrow = true
        info.menuList = "TIMER_POS"
        UIDropDownMenu_AddButton(info, level)

        -- Spacer
        info = UIDropDownMenu_CreateInfo()
        info.text = ""
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Show Timers toggle
        info = UIDropDownMenu_CreateInfo()
        info.text = "Show Timers"
        info.checked = TotemDeckDB.showTimers
        info.func = function()
            TotemDeckDB.showTimers = not TotemDeckDB.showTimers
            if not TotemDeckDB.showTimers and timerFrame then
                timerFrame:Hide()
            elseif TotemDeckDB.showTimers then
                UpdateTimers()
            end
        end
        UIDropDownMenu_AddButton(info, level)

        -- Lock Position toggle
        info = UIDropDownMenu_CreateInfo()
        info.text = "Lock Position"
        info.checked = TotemDeckDB.locked
        info.func = function() TotemDeckDB.locked = not TotemDeckDB.locked end
        UIDropDownMenu_AddButton(info, level)

        -- Spacer
        info = UIDropDownMenu_CreateInfo()
        info.text = ""
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Show Full Config
        info = UIDropDownMenu_CreateInfo()
        info.text = "Show Full Config..."
        info.notCheckable = true
        info.func = function()
            CloseDropDownMenus()
            ToggleConfigWindow()
        end
        UIDropDownMenu_AddButton(info, level)

        -- Recreate Macros
        info = UIDropDownMenu_CreateInfo()
        info.text = "Recreate Macros"
        info.notCheckable = true
        info.func = function() CreateTotemMacros(); print("|cFF00FF00TotemDeck:|r Macros recreated") end
        UIDropDownMenu_AddButton(info, level)

        -- Close
        info = UIDropDownMenu_CreateInfo()
        info.text = "Close"
        info.notCheckable = true
        info.func = function() CloseDropDownMenus() end
        UIDropDownMenu_AddButton(info, level)

    elseif level == 2 then
        if menuList == "POPUP_DIR" then
            local directions = { { "Up", "UP" }, { "Down", "DOWN" }, { "Left", "LEFT" }, { "Right", "RIGHT" } }
            for _, dir in ipairs(directions) do
                info = UIDropDownMenu_CreateInfo()
                info.text = dir[1]
                info.checked = (TotemDeckDB.popupDirection == dir[2])
                info.func = function()
                    TotemDeckDB.popupDirection = dir[2]
                    CloseDropDownMenus()
                    RebuildPopupColumns()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        elseif menuList == "TIMER_POS" then
            local positions = { { "Above", "ABOVE" }, { "Below", "BELOW" }, { "Left", "LEFT" }, { "Right", "RIGHT" } }
            for _, pos in ipairs(positions) do
                info = UIDropDownMenu_CreateInfo()
                info.text = pos[1]
                info.checked = (TotemDeckDB.timerPosition == pos[2])
                info.func = function()
                    TotemDeckDB.timerPosition = pos[2]
                    CloseDropDownMenus()
                    RebuildTimerFrame()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end
end

local function OpenOptionsMenu(anchorFrame)
    UIDropDownMenu_Initialize(optionsMenu, InitializeOptionsMenu, "MENU")
    ToggleDropDownMenu(1, nil, optionsMenu, "cursor", 0, 0)
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

    -- Make movable with Ctrl+Click, options menu with Alt+Click
    actionBarFrame:SetMovable(true)
    actionBarFrame:EnableMouse(true)
    actionBarFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and IsAltKeyDown() then
            OpenOptionsMenu(self)
        elseif button == "LeftButton" and IsControlKeyDown() and not TotemDeckDB.locked then
            self:StartMoving()
        end
    end)
    actionBarFrame:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        TotemDeckDB.barPos = { point = point, x = x, y = y }
    end)

    -- Create 4 active totem buttons
    for i, element in ipairs(ELEMENT_ORDER) do
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

        -- Right-click to dismiss totem
        btn:HookScript("PostClick", function(self, button)
            if button == "RightButton" then
                local slot = TOTEM_SLOTS[self.element]
                if slot then
                    DestroyTotem(slot)
                end
            end
        end)

        -- Ctrl+click to move the frame, Alt+click for options
        btn:HookScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and IsAltKeyDown() then
                OpenOptionsMenu(self)
            elseif button == "LeftButton" and IsControlKeyDown() and not TotemDeckDB.locked then
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
            -- Show tooltip
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.totemName then
                GameTooltip:SetText(self.totemName, 1, 1, 1)
            else
                GameTooltip:SetText(self.element .. " Totem", 1, 1, 1)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Left-click to cast", 0.5, 0.5, 0.5)
            GameTooltip:AddLine("Right-click to dismiss", 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end)

        btn:SetScript("OnLeave", function(self)
            self.border:SetBackdropBorderColor(color.r, color.g, color.b, 1)
            GameTooltip:Hide()
            -- Popup hides via OnUpdate check
        end)

        btn.element = element
        btn.color = color
        activeTotemButtons[element] = btn

        -- Create popup column for this element (anchored to this button)
        CreatePopupColumn(element, btn)
    end

    actionBarFrame:Show()
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

    -- Alt+Click for options menu
    timerFrame:EnableMouse(true)
    timerFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and IsAltKeyDown() then
            OpenOptionsMenu(self)
        end
    end)

    -- Create timer bars for each element
    for i, element in ipairs(ELEMENT_ORDER) do
        local bar = CreateTimerBar(timerFrame, element, i)
        bar:SetPoint("BOTTOM", 0, 5 + (i - 1) * 24)
        timerBars[element] = bar
    end

    timerFrame:Hide()
end

-- Update timer bars
UpdateTimers = function()
    local anyActive = false

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

        if element and timerBars[element] then
            local bar = timerBars[element]

            if haveTotem and duration > 0 then
                local remaining = (startTime + duration) - GetTime()

                if remaining > 0 then
                    anyActive = true
                    bar:Show()
                    bar.statusBar:SetMinMaxValues(0, duration)
                    bar.statusBar:SetValue(remaining)
                    bar.text:SetText(totemName:gsub(" Totem", ""))
                    bar.timeText:SetText(FormatTime(math.floor(remaining)))

                else
                    bar:Hide()
                end
            else
                bar:Hide()
            end
        end
    end

    if anyActive and TotemDeckDB.showTimers then
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
        for _, element in ipairs(ELEMENT_ORDER) do
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

eventFrame:SetScript("OnEvent", function(self, event, arg1)
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
        -- Ensure totemOrder has all element keys
        if not TotemDeckDB.totemOrder then
            TotemDeckDB.totemOrder = {}
        end
        for _, element in ipairs(ELEMENT_ORDER) do
            if not TotemDeckDB.totemOrder[element] then
                TotemDeckDB.totemOrder[element] = {}
            end
        end

    elseif event == "PLAYER_LOGIN" then
        if not IsShaman() then
            return
        end

        CreateActionBarFrame()
        CreateTimerFrame()
        SetupPopupSystem()

        -- Create macros after a short delay (needs UI to be ready)
        C_Timer.After(2, function()
            CreateTotemMacros()
        end)

    elseif event == "PLAYER_TOTEM_UPDATE" then
        UpdateTimers()
    end
end)

-- Timer update (runs every 0.1 seconds when timers are shown)
local timerUpdateFrame = CreateFrame("Frame")
local elapsed = 0
timerUpdateFrame:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.1 then
        elapsed = 0
        if timerFrame and timerFrame:IsShown() then
            UpdateTimers()
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
    popupBlockers = {}

    -- Destroy existing action bar buttons
    for element, btn in pairs(activeTotemButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    activeTotemButtons = {}

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
