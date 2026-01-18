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
local timerFrame, actionBarFrame, popupFrame, popupBlocker
local timerBars = {}
local activeTotemButtons = {}
local popupButtons = {}
local popupContainers = {} -- Container frames for each element (non-secure, can show/hide in combat)
local popupContainerBlockers = {} -- Blocker frame per container to prevent clicks on hidden buttons
local buttonCounter = 0
local popupVisible = false
local popupElement = nil
local popupHideDelay = 0

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
local function CreateTotemMacros()
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
        btn:SetAttribute("spell2", totemName)
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

    -- Tooltip (above the totem bar)
    btn:SetScript("OnEnter", function(self)
        self.border:SetBackdropBorderColor(1, 1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint("BOTTOM", popupFrame, "TOP", 0, 5)
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
        -- Restore green border if this is the active totem, otherwise gray
        local activeKey = "active" .. self.element
        if TotemDeckDB[activeKey] == self.totemName then
            self.border:SetBackdropBorderColor(0, 1, 0, 1)
        else
            self.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end
        GameTooltip:Hide()
    end)

    return btn
end

-- Show popup for an element
local function ShowPopup(element, anchorButton)
    popupElement = element
    popupVisible = true

    local totems = TOTEMS[element]
    local color = ELEMENT_COLORS[element]

    -- Size popup to match action bar width, height based on totem count
    local numTotems = #totems
    local rows = math.ceil(numTotems / 4)

    popupFrame:SetSize(200, rows * 40 + 10)
    popupFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1)
    popupHideDelay = 0

    -- Hide timer bars while popup is shown
    if timerFrame then
        timerFrame:Hide()
    end

    -- Lower main blocker so clicks reach buttons
    if popupBlocker then
        popupBlocker:SetFrameLevel(popupFrame:GetFrameLevel() + 1)
    end

    -- Show current element, hide others with alpha
    -- Each hidden container's blocker is raised to block its buttons
    for elem, container in pairs(popupContainers) do
        local blocker = popupContainerBlockers[elem]
        if elem == element then
            container:SetAlpha(1)
            container:SetFrameLevel(popupFrame:GetFrameLevel() + 50)
            container:SetSize(200, rows * 40 + 10)
            -- Lower this container's blocker below its buttons
            if blocker then
                blocker:SetFrameLevel(popupFrame:GetFrameLevel() + 49)
            end
        else
            container:SetAlpha(0)
            container:SetFrameLevel(popupFrame:GetFrameLevel() + 10)
            -- Raise this container's blocker above its buttons to block clicks
            if blocker then
                blocker:SetFrameLevel(popupFrame:GetFrameLevel() + 11)
            end
        end
    end

    -- Update active totem highlights (border frames are non-secure)
    for i, totemData in ipairs(totems) do
        local btn = popupButtons[element][i]
        local activeKey = "active" .. element
        if TotemDeckDB[activeKey] == totemData.name then
            btn.border:SetBackdropBorderColor(0, 1, 0, 1)
        else
            btn.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end
    end

    popupFrame:SetAlpha(1)
end

-- Forward declaration for UpdateTimers
local UpdateTimers

-- Hide popup
local function HidePopup()
    popupVisible = false
    popupElement = nil
    if popupFrame then
        popupFrame:SetAlpha(0)
        -- Raise main blocker to intercept clicks on invisible buttons
        if popupBlocker then
            popupBlocker:SetFrameLevel(popupFrame:GetFrameLevel() + 200)
        end
        -- Raise all container blockers too
        for _, blocker in pairs(popupContainerBlockers) do
            blocker:SetFrameLevel(popupFrame:GetFrameLevel() + 11)
        end
    end
    GameTooltip:Hide()
    -- Show timer bars again
    if UpdateTimers then
        UpdateTimers()
    end
end

-- Check if mouse is over popup or anchor button
local function IsMouseOverPopupArea()
    -- Check popup frame (use popupVisible instead of IsShown since we use alpha)
    if popupFrame and popupVisible and popupFrame:IsMouseOver() then
        return true
    end
    -- Check anchor button
    if popupElement and activeTotemButtons[popupElement] and activeTotemButtons[popupElement]:IsMouseOver() then
        return true
    end
    -- Check element container
    if popupElement and popupContainers[popupElement] and popupContainers[popupElement]:IsMouseOver() then
        return true
    end
    -- Check individual popup buttons (they're always "shown", visibility controlled by container alpha)
    if popupElement and popupButtons[popupElement] then
        for _, btn in ipairs(popupButtons[popupElement]) do
            if btn:IsMouseOver() then
                return true
            end
        end
    end
    return false
end

-- Create the popup frame
local function CreatePopupFrame()
    popupFrame = CreateFrame("Frame", "TotemDeckPopup", UIParent, "BackdropTemplate")
    popupFrame:SetSize(170, 50)
    popupFrame:SetFrameStrata("TOOLTIP")

    popupFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    popupFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    popupFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    popupFrame:EnableMouse(true)

    -- Check periodically if we should hide (with small delay)
    popupFrame:SetScript("OnUpdate", function(self, elapsed)
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

    -- Keep frame shown but invisible (position will be set after actionBarFrame is created)
    popupFrame:Show()
    popupFrame:SetAlpha(0)

    -- Create blocker frame to intercept clicks when popup is hidden
    popupBlocker = CreateFrame("Frame", nil, popupFrame)
    popupBlocker:SetAllPoints(popupFrame)
    popupBlocker:EnableMouse(true) -- Intercepts all mouse clicks
    popupBlocker:SetFrameLevel(popupFrame:GetFrameLevel() + 200) -- Start high to block
    popupBlocker:Show()

    -- Pre-create container frames and buttons for each element (required for combat use)
    -- Use alpha for visibility instead of Show/Hide (works in combat with secure children)
    for _, element in ipairs(ELEMENT_ORDER) do
        -- Create non-secure container for this element
        local container = CreateFrame("Frame", nil, popupFrame)
        container:SetAllPoints(popupFrame)
        container:SetSize(200, 200)
        container:SetAlpha(0) -- Start hidden
        container:SetFrameLevel(popupFrame:GetFrameLevel() + 10) -- Initialize frame level
        container:Show()
        popupContainers[element] = container

        popupButtons[element] = {}
        local totems = TOTEMS[element]
        local numTotems = #totems

        for i, totemData in ipairs(totems) do
            -- Parent buttons to the container (not directly to popupFrame)
            local btn = CreatePopupButton(container, totemData, element, i)

            -- Pre-position visual frame at creation time (btn follows via SetAllPoints)
            local col = (i - 1) % 4
            local row = math.floor((i - 1) / 4)
            local totalCols = math.min(numTotems - (row * 4), 4)
            local rowWidth = totalCols * 40
            local startX = (200 - rowWidth) / 2
            btn.visual:SetPoint("TOPLEFT", container, "TOPLEFT", startX + col * 40, -5 - row * 40)

            -- Show both visual and button
            btn.visual:Show()
            btn:Show()
            popupButtons[element][i] = btn
        end

        -- Create blocker for this container (blocks clicks on hidden buttons)
        local containerBlocker = CreateFrame("Frame", nil, container)
        containerBlocker:SetAllPoints(container)
        containerBlocker:EnableMouse(true)
        containerBlocker:SetFrameLevel(popupFrame:GetFrameLevel() + 11) -- Start above buttons to block
        containerBlocker:Show()
        popupContainerBlockers[element] = containerBlocker

    end

    -- Pre-render all containers so they work in combat (briefly show then hide)
    -- Position will be set properly after actionBarFrame is created
    popupFrame:SetAlpha(1)
    for elem, container in pairs(popupContainers) do
        container:SetAlpha(1)
        container:SetFrameLevel(popupFrame:GetFrameLevel() + 50)
        -- Lower blockers during pre-render
        if popupContainerBlockers[elem] then
            popupContainerBlockers[elem]:SetFrameLevel(popupFrame:GetFrameLevel() + 49)
        end
    end
    C_Timer.After(0.01, function()
        popupFrame:SetAlpha(0)
        for elem, container in pairs(popupContainers) do
            container:SetAlpha(0)
            container:SetFrameLevel(popupFrame:GetFrameLevel() + 10)
            -- Raise blockers after pre-render
            if popupContainerBlockers[elem] then
                popupContainerBlockers[elem]:SetFrameLevel(popupFrame:GetFrameLevel() + 11)
            end
        end
    end)
end

-- Create the action bar with active totem buttons
local function CreateActionBarFrame()
    actionBarFrame = CreateFrame("Frame", "TotemDeckBar", UIParent, "BackdropTemplate")
    actionBarFrame:SetSize(200, 48)
    actionBarFrame:SetPoint(TotemDeckDB.barPos.point, TotemDeckDB.barPos.x, TotemDeckDB.barPos.y)

    actionBarFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    actionBarFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    actionBarFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    -- Make movable with Ctrl+Click anywhere
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
    for i, element in ipairs(ELEMENT_ORDER) do
        local activeKey = "active" .. element
        local totemName = TotemDeckDB[activeKey]
        local totemData = GetTotemData(totemName)
        local color = ELEMENT_COLORS[element]

        local btn = CreateFrame("Button", "TotemDeckActive" .. element, actionBarFrame, "SecureActionButtonTemplate")
        btn:SetSize(40, 40)
        btn:SetPoint("LEFT", 8 + (i - 1) * 48, 0) -- Spaced with buffer

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
        btn:SetAttribute("type2", "spell")
        btn:SetAttribute("ctrl-type1", nil) -- Do nothing on ctrl+click
        btn:SetAttribute("ctrl-type2", nil)
        if totemData then
            btn:SetAttribute("spell1", totemName)
            btn:SetAttribute("spell2", totemName)
            btn.totemName = totemName
        end

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
        end)

        btn:SetScript("OnLeave", function(self)
            self.border:SetBackdropBorderColor(color.r, color.g, color.b, 1)
            -- Popup hides via OnUpdate check
        end)

        btn.element = element
        btn.color = color
        activeTotemButtons[element] = btn
    end

    actionBarFrame:Show()
end

-- Create timer frame (attached above action bar)
local function CreateTimerFrame()
    timerFrame = CreateFrame("Frame", "TotemDeckTimers", actionBarFrame, "BackdropTemplate")
    timerFrame:SetSize(200, 100)
    timerFrame:SetPoint("BOTTOM", actionBarFrame, "TOP", 0, 2)

    timerFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    timerFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    timerFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

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

        -- Reposition visible bars from bottom up
        local yOffset = 5
        for _, element in ipairs(ELEMENT_ORDER) do
            local bar = timerBars[element]
            if bar:IsShown() then
                bar:ClearAllPoints()
                bar:SetPoint("BOTTOM", 0, yOffset)
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

    elseif event == "PLAYER_LOGIN" then
        if not IsShaman() then
            return
        end

        CreatePopupFrame()
        CreateActionBarFrame()
        CreateTimerFrame()

        -- Position popup frame above action bar (must be done after actionBarFrame exists)
        popupFrame:ClearAllPoints()
        popupFrame:SetPoint("BOTTOM", actionBarFrame, "TOP", 0, 0)

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
    else
        print("|cFF00FF00TotemDeck:|r /td show | timers | macros")
    end
end
