-- TotemDeck: Events Module
-- Event handling and initialization

local addonName, addon = ...

-- Local references
local defaults = addon.defaults
local ELEMENT_ORDER = addon.ELEMENT_ORDER
local IsShaman = addon.IsShaman
local GetElementOrder = addon.GetElementOrder
local GetWeaponBuffByName = addon.GetWeaponBuffByName

-- Migration: Map old English totem names to spell IDs
local NAME_TO_SPELLID = {
    -- Earth
    ["Earthbind Totem"] = 2484,
    ["Stoneclaw Totem"] = 5730,
    ["Stoneskin Totem"] = 8071,
    ["Strength of Earth Totem"] = 8075,
    ["Tremor Totem"] = 8143,
    ["Earth Elemental Totem"] = 2062,
    -- Fire
    ["Fire Nova Totem"] = 1535,
    ["Flametongue Totem"] = 8227,
    ["Frost Resistance Totem"] = 8181,
    ["Magma Totem"] = 8190,
    ["Searing Totem"] = 3599,
    ["Totem of Wrath"] = 30706,
    ["Fire Elemental Totem"] = 2894,
    -- Water
    ["Disease Cleansing Totem"] = 8170,
    ["Fire Resistance Totem"] = 8184,
    ["Healing Stream Totem"] = 5394,
    ["Mana Spring Totem"] = 5675,
    ["Mana Tide Totem"] = 16190,
    ["Poison Cleansing Totem"] = 8166,
    -- Air
    ["Grace of Air Totem"] = 8835,
    ["Grounding Totem"] = 8177,
    ["Nature Resistance Totem"] = 10595,
    ["Sentry Totem"] = 6495,
    ["Tranquil Air Totem"] = 25908,
    ["Windfury Totem"] = 8512,
    ["Windwall Totem"] = 15107,
    ["Wrath of Air Totem"] = 3738,
}

-- Migrate old string-based active totem to spell ID
local function MigrateTotemNameToID(name)
    if not name or type(name) ~= "string" then
        return nil
    end
    return NAME_TO_SPELLID[name]
end

-- Migrate old string-based totem order/hidden lists to spell IDs
local function MigrateTotemListToIDs(list)
    if not list or type(list) ~= "table" then
        return {}
    end
    local migrated = {}
    for _, item in ipairs(list) do
        if type(item) == "string" then
            local spellID = NAME_TO_SPELLID[item]
            if spellID then
                table.insert(migrated, spellID)
            end
        elseif type(item) == "number" then
            -- Already a spell ID
            table.insert(migrated, item)
        end
    end
    return migrated
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
eventFrame:RegisterEvent("UNIT_AURA") -- For out-of-range detection via buff checking

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

        -- Migration: Convert old string-based active totems to spell IDs
        if type(TotemDeckDB.activeEarth) == "string" then
            TotemDeckDB.activeEarth = MigrateTotemNameToID(TotemDeckDB.activeEarth) or defaults.activeEarth
        end
        if type(TotemDeckDB.activeFire) == "string" then
            TotemDeckDB.activeFire = MigrateTotemNameToID(TotemDeckDB.activeFire) or defaults.activeFire
        end
        if type(TotemDeckDB.activeWater) == "string" then
            TotemDeckDB.activeWater = MigrateTotemNameToID(TotemDeckDB.activeWater) or defaults.activeWater
        end
        if type(TotemDeckDB.activeAir) == "string" then
            TotemDeckDB.activeAir = MigrateTotemNameToID(TotemDeckDB.activeAir) or defaults.activeAir
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
            else
                -- Migration: Convert old string-based totem order to spell IDs
                local first = TotemDeckDB.totemOrder[element][1]
                if first and type(first) == "string" then
                    TotemDeckDB.totemOrder[element] = MigrateTotemListToIDs(TotemDeckDB.totemOrder[element])
                end
            end
        end
        -- Ensure hiddenTotems has all element keys
        if not TotemDeckDB.hiddenTotems then
            TotemDeckDB.hiddenTotems = {}
        end
        for _, element in ipairs(ELEMENT_ORDER) do
            if not TotemDeckDB.hiddenTotems[element] then
                TotemDeckDB.hiddenTotems[element] = {}
            else
                -- Migration: Convert old string-based hidden totems to spell IDs
                local first = TotemDeckDB.hiddenTotems[element][1]
                if first and type(first) == "string" then
                    TotemDeckDB.hiddenTotems[element] = MigrateTotemListToIDs(TotemDeckDB.hiddenTotems[element])
                end
            end
        end

        -- Ensure customMacros exists
        if not TotemDeckDB.customMacros then
            TotemDeckDB.customMacros = {}
        end

        -- Ensure defaultMacrosEnabled has all keys
        if not TotemDeckDB.defaultMacrosEnabled then
            TotemDeckDB.defaultMacrosEnabled = {}
        end
        local defaultMacroNames = { "TDEarth", "TDFire", "TDWater", "TDAir", "TDAll" }
        for _, macroName in ipairs(defaultMacroNames) do
            if TotemDeckDB.defaultMacrosEnabled[macroName] == nil then
                TotemDeckDB.defaultMacrosEnabled[macroName] = true
            end
        end

    elseif event == "PLAYER_LOGIN" then
        if not IsShaman() then
            return
        end

        -- Restore saved weapon buff info before creating UI
        addon.RestoreSavedWeaponBuffs()

        addon.CreateActionBarFrame()
        addon.CreateTimerFrame()
        addon.SetupPopupSystem()
        addon.CreateMinimapButton()

        -- Show popup if always show is enabled
        if TotemDeckDB.alwaysShowPopup then
            addon.ShowPopup(GetElementOrder()[1])
        end

        -- Create macros after a short delay (needs UI to be ready)
        C_Timer.After(2, function()
            addon.CreateTotemMacros()
        end)

    elseif event == "PLAYER_TOTEM_UPDATE" then
        addon.UpdateTimers()

    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat
        if TotemDeckDB.disablePopupInCombat then
            -- If disable popup in combat is enabled, hide them completely before combat lockdown
            addon.state.popupVisible = false
            for elem, container in pairs(addon.UI.popupContainers) do
                container:SetAlpha(0)
                container:SetFrameStrata("BACKGROUND")
                container:EnableMouse(false)
                -- Disable mouse on all popup buttons
                for _, btn in ipairs(addon.UI.popupButtons[elem] or {}) do
                    btn:EnableMouse(false)
                    btn.visual:EnableMouse(false)
                end
                container:Hide()
            end
        else
            -- Normal behavior: ensure all popup containers are shown (at alpha=0 if hidden)
            -- so we can Show/Hide via alpha during combat
            for elem, container in pairs(addon.UI.popupContainers) do
                if not container:IsShown() then
                    container:Show()
                    container:SetAlpha(0)
                    container:SetFrameStrata("BACKGROUND")
                end
                -- Ensure mouse is enabled on all buttons (may have been disabled from HidePopup)
                container:EnableMouse(true)
                for _, btn in ipairs(addon.UI.popupButtons[elem] or {}) do
                    btn:EnableMouse(true)
                    btn.visual:EnableMouse(true)
                end
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat: apply any pending active totem updates
        for element, _ in pairs(addon.state.pendingActiveUpdates) do
            addon.UpdateActiveTotemButton(element)
            addon.UpdateTotemMacro(element)
        end
        addon.state.pendingActiveUpdates = {}
        -- Also update custom macros (in case active totems changed during combat)
        addon.UpdateCustomMacros()

        -- Restore proper popup state after combat
        -- During combat, mouse was enabled for alpha-based visibility; now properly hide if needed
        if not addon.state.popupVisible and not TotemDeckDB.alwaysShowPopup then
            for elem, container in pairs(addon.UI.popupContainers) do
                container:EnableMouse(false)
                for _, btn in ipairs(addon.UI.popupButtons[elem] or {}) do
                    btn:EnableMouse(false)
                    btn.visual:EnableMouse(false)
                end
                container:Hide()
            end
        end

        -- Apply any pending element visibility updates
        if addon.state.pendingVisibilityUpdate then
            addon.state.pendingVisibilityUpdate = false
            addon.UpdateElementVisibility()
        end

    elseif event == "BAG_UPDATE" then
        -- Update Ankh count for Reincarnation button
        addon.UpdateReincarnationButton()
        -- Update element visibility based on totem items in inventory
        addon.UpdateElementVisibility()

    elseif event == "UNIT_INVENTORY_CHANGED" then
        -- Update weapon buff button when equipment changes
        if arg1 == "player" then
            addon.UpdateWeaponBuffButton()
        end

    elseif event == "SPELL_UPDATE_COOLDOWN" then
        -- Update Reincarnation cooldown display
        addon.UpdateReincarnationButton()

    elseif event == "UNIT_AURA" then
        -- Update totem dimming when player buffs change (for out-of-range detection)
        if arg1 == "player" then
            addon.UpdateTimers()
        end

    elseif event == "UNIT_SPELLCAST_START" then
        -- Track enchant state before casting a weapon buff
        if arg1 == "player" and arg3 then
            local spellName = GetSpellInfo(arg3)
            if spellName and GetWeaponBuffByName(spellName) then
                addon.TrackPreCastEnchantState()
            end
        end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- Detect when player casts a weapon buff
        -- In Classic/TBC: UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
        if arg1 == "player" and arg3 then
            local spellName = GetSpellInfo(arg3)
            if spellName then
                addon.OnWeaponBuffCast(spellName)
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
        -- Update totem timers (always run if timers enabled, for both bar and icon styles)
        if TotemDeckDB and TotemDeckDB.showTimers then
            addon.UpdateTimers()
        end
        -- Update weapon buff timer
        if addon.UI.weaponBuffButton then
            addon.UpdateWeaponBuffButton()
        end
    end
end)
