-- TotemDeck: Events Module
-- Event handling and initialization

local addonName, addon = ...

-- Local references
local defaults = addon.defaults
local ELEMENT_ORDER = addon.ELEMENT_ORDER
local IsShaman = addon.IsShaman
local GetElementOrder = addon.GetElementOrder
local GetWeaponBuffByName = addon.GetWeaponBuffByName

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
        addon.RestoreSavedWeaponBuffs()

        addon.CreateActionBarFrame()
        addon.CreateTimerFrame()
        addon.SetupPopupSystem()

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
        -- Entering combat: ensure all popup containers are shown (at alpha=0 if hidden)
        -- so we can Show/Hide via alpha during combat
        for _, container in pairs(addon.UI.popupContainers) do
            if not container:IsShown() then
                container:Show()
                container:SetAlpha(0)
                container:SetFrameStrata("BACKGROUND")
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat: apply any pending active totem updates
        for element, _ in pairs(addon.state.pendingActiveUpdates) do
            addon.UpdateActiveTotemButton(element)
            addon.UpdateTotemMacro(element)
        end
        addon.state.pendingActiveUpdates = {}

    elseif event == "BAG_UPDATE" then
        -- Update Ankh count for Reincarnation button
        addon.UpdateReincarnationButton()

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
