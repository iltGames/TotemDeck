-- TotemDeck: Config Module
-- Configuration window

local addonName, addon = ...

-- Local references
local ELEMENT_ORDER = addon.ELEMENT_ORDER
local ELEMENT_COLORS = addon.ELEMENT_COLORS
local GetOrderedTotems = addon.GetOrderedTotems
local IsTotemHidden = addon.IsTotemHidden
local GetElementOrder = addon.GetElementOrder

local function SaveTotemOrder(element)
    local configTotemRows = addon.UI.configTotemRows
    local order = {}
    for _, row in ipairs(configTotemRows[element] or {}) do
        if row.totemName then
            table.insert(order, row.totemName)
        end
    end
    TotemDeckDB.totemOrder[element] = order
end

local function RefreshConfigList(element)
    local configTotemRows = addon.UI.configTotemRows
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
    local configTotemRows = addon.UI.configTotemRows
    local rows = configTotemRows[element]
    if rowIndex <= 1 then return end
    rows[rowIndex], rows[rowIndex - 1] = rows[rowIndex - 1], rows[rowIndex]
    RefreshConfigList(element)
    SaveTotemOrder(element)
end

local function MoveTotemDown(element, rowIndex)
    local configTotemRows = addon.UI.configTotemRows
    local rows = configTotemRows[element]
    if rowIndex >= #rows then return end
    rows[rowIndex], rows[rowIndex + 1] = rows[rowIndex + 1], rows[rowIndex]
    RefreshConfigList(element)
    SaveTotemOrder(element)
end

local function CreateTotemRow(parent, totemData, element, index)
    local configTotemRows = addon.UI.configTotemRows
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(200, 20)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * 22))
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
    local configTotemRows = addon.UI.configTotemRows
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

local function CreateDropdown(parent, label, options, currentValue, x, y, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(120, 40)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelText:SetPoint("TOPLEFT", 0, 0)
    labelText:SetText(label)
    labelText:SetTextColor(1, 0.82, 0)

    local btn = CreateFrame("Button", nil, container, "BackdropTemplate")
    btn:SetSize(110, 22)
    btn:SetPoint("TOPLEFT", 0, -14)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
    btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btnText:SetPoint("LEFT", 8, 0)
    btn.text = btnText

    local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetText("v")

    -- Find current label
    local function UpdateText()
        for _, opt in ipairs(options) do
            if opt.value == currentValue then
                btnText:SetText(opt.label)
                return
            end
        end
        btnText:SetText(options[1].label)
    end
    UpdateText()

    -- Dropdown menu
    local menu = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    menu:SetPoint("TOP", btn, "BOTTOM", 0, -2)
    menu:SetSize(110, #options * 20 + 4)
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menu:SetBackdropColor(0.15, 0.15, 0.15, 1)
    menu:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    menu:SetFrameStrata("TOOLTIP")
    menu:Hide()

    for i, opt in ipairs(options) do
        local item = CreateFrame("Button", nil, menu)
        item:SetSize(106, 18)
        item:SetPoint("TOP", menu, "TOP", 0, -2 - (i-1) * 20)
        item:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
        item:GetHighlightTexture():SetVertexColor(0.3, 0.3, 0.5, 0.5)

        local itemText = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        itemText:SetPoint("LEFT", 8, 0)
        itemText:SetText(opt.label)

        item:SetScript("OnClick", function()
            currentValue = opt.value
            btnText:SetText(opt.label)
            menu:Hide()
            onChange(opt.value)
        end)
    end

    btn:SetScript("OnClick", function()
        if menu:IsShown() then
            menu:Hide()
        else
            menu:Show()
        end
    end)

    btn.menu = menu
    btn.currentValue = currentValue
    btn.UpdateValue = function(newValue)
        currentValue = newValue
        UpdateText()
    end

    return btn
end

function addon.CreateConfigWindow()
    if addon.UI.configWindow then
        return addon.UI.configWindow
    end

    local frame = CreateFrame("Frame", "TotemDeckConfigWindow", UIParent, "BackdropTemplate")
    frame:SetSize(560, 360)
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

    local function CreateLayoutSection(parent, sectionTitle, yOffset, height, width, xOffset)
        local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        section:SetSize(width or 510, height)
        if xOffset then
            section:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
        else
            section:SetPoint("TOP", parent, "TOP", 0, yOffset)
        end
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

    -- Settings row with dropdowns
    local settingsSection = CreateLayoutSection(layoutContent, "Settings", 0, 60)

    frame.popupDirDropdown = CreateDropdown(settingsSection, "Popup Direction", {
        { label = "Up", value = "UP" },
        { label = "Down", value = "DOWN" },
        { label = "Left", value = "LEFT" },
        { label = "Right", value = "RIGHT" },
    }, TotemDeckDB.popupDirection or "UP", 10, -20, function(value)
        TotemDeckDB.popupDirection = value
        if not InCombatLockdown() then addon.RebuildPopupColumns() end
    end)

    frame.timerPosDropdown = CreateDropdown(settingsSection, "Timer Position", {
        { label = "Above", value = "ABOVE" },
        { label = "Below", value = "BELOW" },
        { label = "Left", value = "LEFT" },
        { label = "Right", value = "RIGHT" },
    }, TotemDeckDB.timerPosition or "ABOVE", 135, -20, function(value)
        TotemDeckDB.timerPosition = value
        addon.RebuildTimerFrame()
    end)

    frame.timerStyleDropdown = CreateDropdown(settingsSection, "Timer Style", {
        { label = "Bars", value = "bars" },
        { label = "Icons", value = "icons" },
    }, TotemDeckDB.timerStyle or "bars", 260, -20, function(value)
        TotemDeckDB.timerStyle = value
        addon.UpdateTimers()
    end)

    frame.popupModDropdown = CreateDropdown(settingsSection, "Popup Modifier", {
        { label = "None", value = "NONE" },
        { label = "Shift", value = "SHIFT" },
        { label = "Ctrl", value = "CTRL" },
        { label = "Alt", value = "ALT" },
    }, TotemDeckDB.popupModifier or "NONE", 385, -20, function(value)
        TotemDeckDB.popupModifier = value
    end)

    -- Combat warning note
    local warningText = layoutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    warningText:SetPoint("TOPLEFT", layoutContent, "TOPLEFT", 10, -68)
    warningText:SetWidth(500)
    warningText:SetJustifyH("LEFT")
    warningText:SetText("|cFFFFAA00Note:|r In combat, popup bars are invisible but still clickable (Blizzard blocks hiding frames). Enable 'Always Show Popup' to avoid accidental clicks.")
    warningText:SetTextColor(0.7, 0.7, 0.7)

    -- Options (full width, 2-column layout for checkboxes)
    local optionsSection = CreateLayoutSection(layoutContent, "Options", -90, 130)

    -- Left column
    local showTimersCheck = CreateFrame("CheckButton", nil, optionsSection, "UICheckButtonTemplate")
    showTimersCheck:SetPoint("TOPLEFT", 10, -28)
    showTimersCheck:SetChecked(TotemDeckDB.showTimers)
    showTimersCheck:SetScript("OnClick", function(self)
        TotemDeckDB.showTimers = self:GetChecked()
        local timerFrame = addon.UI.timerFrame
        if not TotemDeckDB.showTimers and timerFrame then
            timerFrame:Hide()
        elseif TotemDeckDB.showTimers then
            addon.UpdateTimers()
        end
    end)
    local showTimersLabel = optionsSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    showTimersLabel:SetPoint("LEFT", showTimersCheck, "RIGHT", 4, 0)
    showTimersLabel:SetText("Show Timers")
    frame.showTimersCheck = showTimersCheck

    local lockPosCheck = CreateFrame("CheckButton", nil, optionsSection, "UICheckButtonTemplate")
    lockPosCheck:SetPoint("TOPLEFT", 10, -52)
    lockPosCheck:SetChecked(TotemDeckDB.locked)
    lockPosCheck:SetScript("OnClick", function(self)
        TotemDeckDB.locked = self:GetChecked()
    end)
    local lockPosLabel = optionsSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockPosLabel:SetPoint("LEFT", lockPosCheck, "RIGHT", 4, 0)
    lockPosLabel:SetText("Lock Bar Position")
    frame.lockPosCheck = lockPosCheck

    local alwaysShowCheck = CreateFrame("CheckButton", nil, optionsSection, "UICheckButtonTemplate")
    alwaysShowCheck:SetPoint("TOPLEFT", 10, -76)
    alwaysShowCheck:SetChecked(TotemDeckDB.alwaysShowPopup)
    alwaysShowCheck:SetScript("OnClick", function(self)
        TotemDeckDB.alwaysShowPopup = self:GetChecked()
        if TotemDeckDB.alwaysShowPopup then
            addon.ShowPopup(GetElementOrder()[1])
        else
            addon.state.popupVisible = false
            for _, container in pairs(addon.UI.popupContainers) do
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

    local dimRangeCheck = CreateFrame("CheckButton", nil, optionsSection, "UICheckButtonTemplate")
    dimRangeCheck:SetPoint("TOPLEFT", 10, -100)
    dimRangeCheck:SetChecked(TotemDeckDB.dimOutOfRange)
    dimRangeCheck:SetScript("OnClick", function(self)
        TotemDeckDB.dimOutOfRange = self:GetChecked()
    end)
    local dimRangeLabel = optionsSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dimRangeLabel:SetPoint("LEFT", dimRangeCheck, "RIGHT", 4, 0)
    dimRangeLabel:SetText("Dim out of range")
    frame.dimRangeCheck = dimRangeCheck

    -- Right column
    local showReincCheck = CreateFrame("CheckButton", nil, optionsSection, "UICheckButtonTemplate")
    showReincCheck:SetPoint("TOPLEFT", 260, -28)
    showReincCheck:SetChecked(TotemDeckDB.showReincarnation)
    showReincCheck:SetScript("OnClick", function(self)
        TotemDeckDB.showReincarnation = self:GetChecked()
        if not InCombatLockdown() then
            addon.RebuildPopupColumns()
        else
            print("|cFF00FF00TotemDeck:|r Change will apply after combat")
        end
    end)
    local showReincLabel = optionsSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    showReincLabel:SetPoint("LEFT", showReincCheck, "RIGHT", 4, 0)
    showReincLabel:SetText("Show Reincarnation")
    frame.showReincCheck = showReincCheck

    local showWeaponCheck = CreateFrame("CheckButton", nil, optionsSection, "UICheckButtonTemplate")
    showWeaponCheck:SetPoint("TOPLEFT", 260, -52)
    showWeaponCheck:SetChecked(TotemDeckDB.showWeaponBuffs)
    showWeaponCheck:SetScript("OnClick", function(self)
        TotemDeckDB.showWeaponBuffs = self:GetChecked()
        if not InCombatLockdown() then
            addon.RebuildPopupColumns()
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
    macrosBtn:SetPoint("TOPLEFT", 260, -76)
    macrosBtn:SetText("Recreate Macros")
    macrosBtn:SetScript("OnClick", function()
        addon.CreateTotemMacros()
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
    elementOrderSection:SetSize(520, 45)
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
        btnFrame:SetSize(32, 22)
        btnFrame:SetPoint("LEFT", elementOrderSection, "LEFT", 70 + (i - 1) * 100, -4)
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
    local sectionWidth = 255
    local sectionHeight = 90
    local sections = {}
    local totemSectionTopOffset = -50

    for i, element in ipairs(ELEMENT_ORDER) do
        local color = ELEMENT_COLORS[element]
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)

        local section = CreateFrame("Frame", nil, orderingContent, "BackdropTemplate")
        section:SetSize(sectionWidth, sectionHeight)
        section:SetPoint("TOPLEFT", orderingContent, "TOPLEFT", col * (sectionWidth + 10), totemSectionTopOffset - row * (sectionHeight + 5))
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
        scrollFrame:SetPoint("TOPLEFT", 8, -20)
        scrollFrame:SetPoint("BOTTOMRIGHT", -28, 6)

        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(sectionWidth - 40, 200)
        scrollFrame:SetScrollChild(scrollChild)

        section.scrollChild = scrollChild
        section.element = element
        sections[element] = section
    end

    local orderButtonContainer = CreateFrame("Frame", nil, orderingContent)
    orderButtonContainer:SetSize(520, 26)
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
        addon.RebuildPopupColumns()
        print("|cFF00FF00TotemDeck:|r Order applied")
    end)

    frame.sections = sections
    frame.tabContent = tabContent
    frame:Hide()

    SelectTab("layout")

    addon.UI.configWindow = frame
    return frame
end

local function RefreshConfigWindowState()
    local configWindow = addon.UI.configWindow
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

function addon.ToggleConfigWindow()
    local frame = addon.CreateConfigWindow()

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
