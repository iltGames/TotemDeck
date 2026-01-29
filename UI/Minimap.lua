-- TotemDeck: Minimap Button Module
-- Quick access to config

local addonName, addon = ...

local function UpdateMinimapButtonPosition(button)
    local angle = TotemDeckDB.minimapButtonPos or 220
    local radius = 80
    local rad = math.rad(angle)
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function addon.CreateMinimapButton()
    if TotemDeckDB.showMinimapButton == false
        or TotemDeckDB.showMinimapButton == 0
        or TotemDeckDB.showMinimapButton == "0"
        or TotemDeckDB.showMinimapButton == "false" then
        return
    end
    if addon.UI.minimapButton then
        addon.UpdateMinimapButton()
        return
    end

    local btn = CreateFrame("Button", "TotemDeckMinimapButton", Minimap)
    btn:SetSize(33, 33)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("AnyUp")

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetSize(24, 24)
    btn.bg:SetPoint("CENTER")
    btn.bg:SetTexture("Interface\\Minimap\\MiniMap-TrackingBackground")

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetSize(18, 18)
    btn.icon:SetPoint("CENTER", -1, 1)
    btn.icon:SetTexture(addon.GetTotemIcon(8075) or 136097)
    btn.icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")

    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn.border:SetSize(52, 52)
    btn.border:SetPoint("CENTER", btn, "CENTER", 11, -11)

    local highlight = btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    if highlight then
        highlight:SetBlendMode("ADD")
        highlight:SetAllPoints(btn)
    end

    btn:SetScript("OnClick", function()
        addon.ToggleConfigWindow()
    end)

    btn:SetScript("OnShow", function(self)
        if TotemDeckDB.showMinimapButton == false
            or TotemDeckDB.showMinimapButton == 0
            or TotemDeckDB.showMinimapButton == "0"
            or TotemDeckDB.showMinimapButton == "false" then
            self:Hide()
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("TotemDeck", 1, 1, 1)
        GameTooltip:AddLine("Click to open options", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    btn:SetScript("OnDragStart", function(self)
        self.isDragging = true
        self:SetScript("OnUpdate", function(s)
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = UIParent:GetScale()
            cx, cy = cx / scale, cy / scale
            local angle = math.deg(math.atan2(cy - my, cx - mx))
            TotemDeckDB.minimapButtonPos = angle
            UpdateMinimapButtonPosition(s)
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self.isDragging = false
        self:SetScript("OnUpdate", nil)
    end)

    btn:RegisterForDrag("LeftButton")

    addon.UI.minimapButton = btn
    addon.UpdateMinimapButton()
end

function addon.UpdateMinimapButton()
    local btn = addon.UI.minimapButton
    if not btn then
        if TotemDeckDB.showMinimapButton == false
            or TotemDeckDB.showMinimapButton == 0
            or TotemDeckDB.showMinimapButton == "0"
            or TotemDeckDB.showMinimapButton == "false" then
            return
        end
        addon.CreateMinimapButton()
        return
    end

    if TotemDeckDB.showMinimapButton == false
        or TotemDeckDB.showMinimapButton == 0
        or TotemDeckDB.showMinimapButton == "0"
        or TotemDeckDB.showMinimapButton == "false" then
        btn:Hide()
        btn:SetParent(nil)
        btn:ClearAllPoints()
        addon.UI.minimapButton = nil
        return
    end

    UpdateMinimapButtonPosition(btn)
    btn:Show()
end
