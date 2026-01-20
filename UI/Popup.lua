-- TotemDeck: Popup Module
-- Popup columns/rows for totem selection

local addonName, addon = ...

-- Local references
local ELEMENT_COLORS = addon.ELEMENT_COLORS
local GetOrderedTotems = addon.GetOrderedTotems
local IsTotemKnown = addon.IsTotemKnown
local IsTotemHidden = addon.IsTotemHidden
local SetActiveTotem = addon.SetActiveTotem

-- Create popup button for the hover menu
function addon.CreatePopupButton(parent, totemData, element, index)
    addon.UI.buttonCounter = addon.UI.buttonCounter + 1
    local btnName = "TotemDeckPopupButton" .. addon.UI.buttonCounter

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
        if not addon.state.popupVisible then
            return
        end
        -- Highlight entire column for this element
        addon.ShowPopup(self.element)
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
function addon.ShowPopup(hoveredElement)
    addon.state.popupVisible = true
    addon.state.popupHideDelay = 0

    local popupContainers = addon.UI.popupContainers
    local popupButtons = addon.UI.popupButtons

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

-- Hide all popup columns (or just dim them if always show is enabled)
function addon.HidePopup()
    local popupContainers = addon.UI.popupContainers
    local popupButtons = addon.UI.popupButtons

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
    addon.state.popupVisible = false
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
    if addon.UpdateTimers then
        addon.UpdateTimers()
    end
end

-- Check if mouse is over any popup column or main bar button
function addon.IsMouseOverPopupArea()
    if not addon.state.popupVisible then
        return false
    end
    local activeTotemButtons = addon.UI.activeTotemButtons
    local popupContainers = addon.UI.popupContainers
    local popupButtons = addon.UI.popupButtons

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
function addon.CreatePopupColumn(element, anchorButton)
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
    addon.UI.popupContainers[element] = container

    -- Create buttons
    addon.UI.popupButtons[element] = {}
    for i, totemData in ipairs(totems) do
        local btn = addon.CreatePopupButton(container, totemData, element, i)

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
        addon.UI.popupButtons[element][i] = btn
    end

    return container
end

-- Setup popup system (OnUpdate handler for hide delay)
function addon.SetupPopupSystem()
    -- Create a helper frame for the OnUpdate handler
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        if addon.state.popupVisible then
            if addon.IsMouseOverPopupArea() then
                addon.state.popupHideDelay = 0
            else
                addon.state.popupHideDelay = addon.state.popupHideDelay + elapsed
                if addon.state.popupHideDelay > 0.15 then -- 150ms grace period
                    addon.HidePopup()
                end
            end
        end
    end)
end
