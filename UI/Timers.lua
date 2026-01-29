-- TotemDeck: Timers Module
-- Timer bars and icon timers

local addonName, addon = ...

-- Local references
local ELEMENT_COLORS = addon.ELEMENT_COLORS
local TOTEM_SLOTS = addon.TOTEM_SLOTS
local GetElementOrder = addon.GetElementOrder
local FormatTime = addon.FormatTime
local HasTotemBuff = addon.HasTotemBuff

-- Create timer bar
function addon.CreateTimerBar(parent, element, index)
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
    local fontFile, fontSize = GameFontNormalSmall:GetFont()
    text:SetFont(fontFile, (fontSize or 10) + 1, "OUTLINE")
    bar.text = text

    -- Time text (on statusBar so it renders above the progress color)
    local timeText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetPoint("RIGHT", -2, 0)
    timeText:SetTextColor(1, 1, 1)
    timeText:SetFont(fontFile, (fontSize or 10) + 1, "OUTLINE")
    bar.timeText = timeText

    bar.element = element
    bar:Hide()

    return bar
end

local function StartBarFlash(bar)
    if bar.flashOn then return end
    bar.flashOn = true
    bar.flashStart = GetTime()
    bar:SetScript("OnUpdate", function(self)
        local t = GetTime() - (self.flashStart or 0)
        local phase = math.abs(math.sin(t * 6))
        self:SetAlpha(0.3 + 0.7 * phase)
    end)
end

local function StopBarFlash(bar)
    if not bar.flashOn then return end
    bar.flashOn = false
    bar:SetScript("OnUpdate", nil)
    bar:SetAlpha(1)
end

local function StartIconFlash(btn)
    if not btn or not btn.iconTimer or btn.iconFlashOn then return end
    btn.iconFlashOn = true
    btn.iconFlashStart = GetTime()
    btn.iconTimer:SetScript("OnUpdate", function()
        local t = GetTime() - (btn.iconFlashStart or 0)
        local phase = math.abs(math.sin(t * 6))
        local alpha = 0.3 + 0.7 * phase
        btn.icon:SetAlpha(alpha)
        btn.iconTimer:SetAlpha(alpha)
        if btn.iconTimerDots then
            btn.iconTimerDots:SetAlpha(alpha)
        end
    end)
end

local function StopIconFlash(btn)
    if not btn or not btn.iconTimer or not btn.iconFlashOn then return end
    btn.iconFlashOn = false
    btn.iconTimer:SetScript("OnUpdate", nil)
    btn.iconTimer:SetAlpha(1)
    btn.icon:SetAlpha(1)
    if btn.iconTimerDots then
        btn.iconTimerDots:SetAlpha(1)
    end
end

local DOT_SIZE = 11
local DOT_SPACING = -3
local DOT_POSITIONS = {
    [1] = { x = -1, y = 1 },
    [2] = { x = 0, y = 1 },
    [3] = { x = 1, y = 1 },
    [4] = { x = -1, y = 0 },
    [5] = { x = 0, y = 0 },
    [6] = { x = 1, y = 0 },
    [7] = { x = -1, y = -1 },
    [8] = { x = 0, y = -1 },
    [9] = { x = 1, y = -1 },
}

local DICE_PIPS = {
    [0] = {},
    [1] = { 5 },
    [2] = { 1, 9 },
    [3] = { 1, 5, 9 },
    [4] = { 1, 3, 7, 9 },
    [5] = { 1, 3, 5, 7, 9 },
    [6] = { 1, 3, 4, 6, 7, 9 },
}

local function EnsureIconDotGrid(btn)
    if not btn or not btn.iconTimerDots then return end
    if btn.iconTimerDots.gridBuilt then return end

    btn.iconTimerDots.dots = {}
    for i = 1, 9 do
        local tex = btn.iconTimerDots:CreateTexture(nil, "OVERLAY")
        tex:SetSize(DOT_SIZE, DOT_SIZE)
        local pos = DOT_POSITIONS[i]
        tex:SetPoint("CENTER", btn.iconTimerDots, "CENTER", pos.x * (DOT_SIZE + DOT_SPACING), pos.y * (DOT_SIZE + DOT_SPACING))
        tex:Hide()
        btn.iconTimerDots.dots[i] = tex
    end
    btn.iconTimerDots.gridBuilt = true
end

local function UpdateIconDots(btn, buffed, total)
    if not btn or not btn.iconTimerDots then return end
    EnsureIconDotGrid(btn)

    if not buffed or not total or total <= 0 then
        btn.iconTimerDots:Hide()
        return
    end

    local totalPips = DICE_PIPS[math.min(total, 6)] or {}
    local buffedPips = DICE_PIPS[math.min(buffed, 6)] or {}
    local buffedMap = {}
    for _, idx in ipairs(buffedPips) do
        buffedMap[idx] = true
    end

    for i = 1, 9 do
        local tex = btn.iconTimerDots.dots[i]
        if tex then
            tex:Hide()
        end
    end

    for _, idx in ipairs(totalPips) do
        local tex = btn.iconTimerDots.dots[idx]
        if tex then
            if buffedMap[idx] then
                tex:SetTexture("Interface\\COMMON\\Indicator-Green")
            else
                tex:SetTexture("Interface\\COMMON\\Indicator-Gray")
            end
            tex:Show()
        end
    end

    btn.iconTimerDots:Show()
end

local function HideIconDots(btn)
    if not btn or not btn.iconTimerDots then return end
    btn.iconTimerDots:Hide()
end

-- Create timer frame (position based on timerPosition setting)
function addon.CreateTimerFrame()
    local actionBarFrame = addon.UI.actionBarFrame
    local timerPos = TotemDeckDB.timerPosition or "ABOVE"

    local timerFrame = CreateFrame("Frame", "TotemDeckTimers", actionBarFrame, "BackdropTemplate")
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

    addon.UI.timerFrame = timerFrame

    -- Create timer bars for each element
    for i, element in ipairs(GetElementOrder()) do
        local bar = addon.CreateTimerBar(timerFrame, element, i)
        bar:SetPoint("BOTTOM", 0, 5 + (i - 1) * 24)
        addon.UI.timerBars[element] = bar
    end

    timerFrame:Hide()
end

-- Update timer bars
function addon.UpdateTimers()
    local timerFrame = addon.UI.timerFrame
    local timerBars = addon.UI.timerBars
    local activeTotemButtons = addon.UI.activeTotemButtons

    -- Guard: UI not initialized yet
    if not timerFrame then return end

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

        -- Reset sound flag if no totem in slot
        if not haveTotem then
            addon.state.totemSoundPlayed[slot] = false
        end

        if element then
            local bar = timerBars[element]
            local btn = activeTotemButtons[element]
            local activeSpellID = TotemDeckDB["active" .. element]
            local activeTotemName = addon.GetTotemName(activeSpellID)

            if haveTotem and duration > 0 then
                local remaining = (startTime + duration) - GetTime()

                if remaining > 0 then
                    anyActive = true

                    if startTime and addon.state.totemLastStart[slot] ~= startTime then
                        addon.state.totemLastStart[slot] = startTime
                        if btn and btn.iconPulse then
                            btn.iconPulse:Stop()
                            btn.iconPulse:Play()
                        end
                    end

                    -- Totem expiry sound alert
                    if remaining <= 5 then
                        if TotemDeckDB.totemExpirySound and not addon.state.totemSoundPlayed[slot] then
                            local soundID = TotemDeckDB.totemExpirySoundIDs and TotemDeckDB.totemExpirySoundIDs[element] or 8959
                            if soundID and soundID > 0 then
                                PlaySound(soundID, "Master")
                            end
                            addon.state.totemSoundPlayed[slot] = true
                        end
                    else
                        -- Reset flag when totem has more than 5 seconds (handles new totem placement)
                        addon.state.totemSoundPlayed[slot] = false
                    end

                    local expiringWindow = 10
                    local expiringProgress = 0
                    if remaining <= expiringWindow then
                        expiringProgress = (expiringWindow - remaining) / expiringWindow
                    end
                    local isExpiring = remaining <= 5
                    local red = 1
                    local green = 1 - (0.8 * expiringProgress)
                    local blue = 1 - (0.8 * expiringProgress)

                    -- Update bar timer (bars mode)
                    if bar and timerStyle == "bars" then
                        bar:Show()
                        bar.statusBar:SetMinMaxValues(0, duration)
                        bar.statusBar:SetValue(remaining)
                        -- totemName may be nil in some WoW versions
                        if totemName then
                            local baseTotemName = totemName:gsub("%s+[IVXLCDM]+$", "")
                            bar.text:SetText(baseTotemName:gsub(" Totem", ""))
                        else
                            bar.text:SetText(element)
                        end
                        local timeText = FormatTime(math.floor(remaining))
                        if TotemDeckDB.showGroupBuffCount ~= false then
                            local totemIdentifier = activeSpellID or totemName
                            local buffed, total = addon.GetGroupTotemBuffCount(totemIdentifier)
                            local buffText, wrap = addon.FormatGroupBuffCount(buffed, total)
                            if buffText then
                                if not wrap and timerStyle == "bars" then
                                    buffText = buffText:gsub("\n", "")
                                end
                                if wrap then
                                    timeText = timeText .. " (" .. buffText .. ")"
                                else
                                    timeText = timeText .. " " .. buffText
                                end
                            end
                        end
                        bar.timeText:SetText(timeText)

                        bar.timeText:SetTextColor(red, green, blue)

                        if isExpiring then
                            StartBarFlash(bar)
                        else
                            StopBarFlash(bar)
                        end
                    elseif bar then
                        bar:Hide()
                        StopBarFlash(bar)
                    end

                    -- Update icon timer (icons mode)
                    if btn and btn.iconTimer then
                        if timerStyle == "icons" and showTimers then
                            local timeText = FormatTime(math.floor(remaining))
                            local buffed, total = nil, nil
                            if TotemDeckDB.showGroupBuffCount ~= false then
                                local totemIdentifier = activeSpellID or totemName
                                buffed, total = addon.GetGroupTotemBuffCount(totemIdentifier)
                            end

                            if TotemDeckDB.showGroupBuffStyle == "dots" and TotemDeckDB.showGroupBuffCount ~= false then
                                UpdateIconDots(btn, buffed, total)
                            else
                                local buffText, wrap = addon.FormatGroupBuffCount(buffed, total)
                                if buffText then
                                    if wrap then
                                        timeText = timeText .. " (" .. buffText .. ")"
                                    else
                                        timeText = timeText .. " " .. buffText
                                    end
                                end
                                HideIconDots(btn)
                            end

                            btn.iconTimerText:SetText(timeText)
                            btn.iconTimerText:SetTextColor(red, green, blue)
                            btn.iconTimer:Show()
                            if isExpiring then
                                StartIconFlash(btn)
                            else
                                StopIconFlash(btn)
                            end
                        else
                            btn.iconTimer:Hide()
                            HideIconDots(btn)
                            StopIconFlash(btn)
                        end
                    end

                    -- Update button to show placed totem (if different from active)
                    if btn and totemName then
                        -- Strip rank suffix for comparison (e.g., "Searing Totem VII" -> "Searing Totem")
                        local baseTotemName = totemName:gsub("%s+[IVXLCDM]+$", "")
                        -- Compare localized names (activeTotemName is also localized now)
                        if activeTotemName and baseTotemName ~= activeTotemName then
                            -- Placed totem differs from active - show with visual indicator
                            local placedIcon = GetSpellTexture(baseTotemName) or GetSpellTexture(totemName)
                            if placedIcon then
                                btn.icon:SetTexture(placedIcon)
                                -- Only grey out if setting is enabled
                                if TotemDeckDB.greyOutPlacedTotem then
                                    btn.icon:SetDesaturated(true)
                                    btn.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                                end
                                btn.showingPlaced = true
                                btn.placedTotemName = totemName
                                -- Try to get spell ID for the placed totem for tooltip
                                local _, _, _, _, _, _, placedSpellID = GetSpellInfo(baseTotemName)
                                btn.placedSpellID = placedSpellID
                            end
                        elseif btn.showingPlaced then
                            -- Placed totem matches active - revert to normal display
                            local activeIcon = addon.GetTotemIcon(activeSpellID)
                            if activeIcon then
                                btn.icon:SetTexture(activeIcon)
                            end
                            btn.icon:SetDesaturated(false)
                            btn.border:SetBackdropBorderColor(btn.color.r, btn.color.g, btn.color.b, 1)
                            btn.showingPlaced = false
                            btn.placedTotemName = nil
                            btn.placedSpellID = nil
                        end

                        -- Check if player is out of range (buff-based detection)
                        if TotemDeckDB.dimOutOfRange then
                            local hasBuff = HasTotemBuff(totemName)
                            if hasBuff == false then
                                -- Totem is placed but player doesn't have the buff = out of range
                                btn.icon:SetAlpha(0.4)
                            else
                                -- Has buff (in range) OR totem doesn't provide buffs
                                btn.icon:SetAlpha(1.0)
                            end
                        else
                            btn.icon:SetAlpha(1.0)
                        end
                    end
                else
                    if bar then bar:Hide() end
                    if bar then StopBarFlash(bar) end
                    if btn and btn.iconTimer then btn.iconTimer:Hide() end
                    if btn then HideIconDots(btn) end
                    if btn then StopIconFlash(btn) end
                    if bar and bar.timeText then bar.timeText:SetTextColor(1, 1, 1) end
                    if btn and btn.iconTimerText then btn.iconTimerText:SetTextColor(1, 1, 1) end
                    -- Revert button display when totem expires
                    if btn and btn.showingPlaced then
                        local activeIcon = addon.GetTotemIcon(activeSpellID)
                        if activeIcon then
                            btn.icon:SetTexture(activeIcon)
                        end
                        btn.icon:SetDesaturated(false)
                        btn.border:SetBackdropBorderColor(btn.color.r, btn.color.g, btn.color.b, 1)
                        btn.showingPlaced = false
                        btn.placedTotemName = nil
                        btn.placedSpellID = nil
                    end
                    -- Reset alpha when totem expires
                    if btn then
                        btn.icon:SetAlpha(1.0)
                    end
                end
            else
                if bar then bar:Hide() end
                if bar then StopBarFlash(bar) end
                if btn and btn.iconTimer then btn.iconTimer:Hide() end
                if btn then HideIconDots(btn) end
                if btn then StopIconFlash(btn) end
                if bar and bar.timeText then bar.timeText:SetTextColor(1, 1, 1) end
                if btn and btn.iconTimerText then btn.iconTimerText:SetTextColor(1, 1, 1) end
                -- Revert button display when no totem placed
                if btn and btn.showingPlaced then
                    local activeIcon = addon.GetTotemIcon(activeSpellID)
                    if activeIcon then
                        btn.icon:SetTexture(activeIcon)
                    end
                    btn.icon:SetDesaturated(false)
                    btn.border:SetBackdropBorderColor(btn.color.r, btn.color.g, btn.color.b, 1)
                    btn.showingPlaced = false
                    btn.placedTotemName = nil
                    btn.placedSpellID = nil
                end
                -- Reset alpha when no totem placed
                if btn then
                    btn.icon:SetAlpha(1.0)
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
