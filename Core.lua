-- TotemDeck: Core Module
-- Addon namespace, constants, data tables, and utility functions

local addonName, addon = ...

-- Export addon table for other modules
addon.addonName = addonName

-- Default saved variables
addon.defaults = {
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
    dimOutOfRange = true, -- Dim totem icons when player is out of range
    popupModifier = "NONE", -- Modifier key required to show popup (NONE, SHIFT, CTRL, ALT)
}

-- Totem data: name, duration in seconds, icon
addon.TOTEMS = {
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
addon.ELEMENT_COLORS = {
    Earth = { r = 0.6, g = 0.4, b = 0.2 },
    Fire = { r = 1.0, g = 0.3, b = 0.1 },
    Water = { r = 0.2, g = 0.5, b = 1.0 },
    Air = { r = 0.7, g = 0.7, b = 0.9 },
}

-- Map totem names to their player buff names (for out-of-range detection)
addon.TOTEM_BUFFS = {
    ["Windfury Totem"] = "Windfury Totem",
    ["Grace of Air Totem"] = "Grace of Air",
    ["Tranquil Air Totem"] = "Tranquil Air",
    ["Wrath of Air Totem"] = "Wrath of Air",
    ["Windwall Totem"] = "Windwall",
    ["Strength of Earth Totem"] = "Strength of Earth",
    ["Stoneskin Totem"] = "Stoneskin",
    ["Mana Spring Totem"] = "Mana Spring",
    ["Fire Resistance Totem"] = "Fire Resistance",
    ["Frost Resistance Totem"] = "Frost Resistance",
    ["Nature Resistance Totem"] = "Nature Resistance",
    ["Flametongue Totem"] = "Flametongue Totem",
    ["Totem of Wrath"] = "Totem of Wrath",
}

-- Element order for display
addon.ELEMENT_ORDER = { "Earth", "Fire", "Water", "Air" }

-- Totem slot indices (for tracking active totems)
addon.TOTEM_SLOTS = {
    Fire = 1,
    Earth = 2,
    Water = 3,
    Air = 4,
}

-- Weapon buff data
addon.WEAPON_BUFFS = {
    { name = "Rockbiter Weapon", icon = "Interface\\Icons\\Spell_Nature_RockBiter" },
    { name = "Flametongue Weapon", icon = "Interface\\Icons\\Spell_Fire_FlameToungue" },
    { name = "Frostbrand Weapon", icon = "Interface\\Icons\\Spell_Frost_FrostBrand" },
    { name = "Windfury Weapon", icon = "Interface\\Icons\\Spell_Nature_Cyclone" },
}

-- Ankh item ID for Reincarnation
addon.ANKH_ITEM_ID = 17030

-- Shared UI state
addon.UI = {
    actionBarFrame = nil,
    timerFrame = nil,
    timerBars = {},
    activeTotemButtons = {},
    popupButtons = {},
    popupContainers = {},
    reincarnationButton = nil,
    weaponBuffButton = nil,
    weaponBuffPopup = nil,
    weaponBuffPopupButtons = {},
    buttonCounter = 0,
    configWindow = nil,
    configTotemRows = {},
}

addon.state = {
    popupVisible = false,
    popupHideDelay = 0,
    weaponBuffPopupVisible = false,
    activeMainHandBuff = nil,
    activeOffHandBuff = nil,
    pendingActiveUpdates = {},
    preCastMainHandEnchant = false,
    preCastOffHandEnchant = false,
}

-- Utility: Check if player is a Shaman
function addon.IsShaman()
    local _, class = UnitClass("player")
    return class == "SHAMAN"
end

-- Utility: Get totem data by name
function addon.GetTotemData(totemName)
    for element, totems in pairs(addon.TOTEMS) do
        for _, totem in ipairs(totems) do
            if totem.name == totemName then
                return totem, element
            end
        end
    end
    return nil, nil
end

-- Get element order (saved or default)
function addon.GetElementOrder()
    if TotemDeckDB and TotemDeckDB.elementOrder then
        return TotemDeckDB.elementOrder
    end
    return addon.ELEMENT_ORDER
end

-- Check if a totem spell is trained
function addon.IsTotemKnown(totemName)
    local name, _, _, _, _, _, spellID = GetSpellInfo(totemName)
    if not spellID then
        return false
    end
    return IsPlayerSpell(spellID)
end

-- Check if a totem is hidden by the user
function addon.IsTotemHidden(element, totemName)
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

-- Check if the required popup modifier key is pressed
function addon.IsPopupModifierPressed()
    local modifier = TotemDeckDB and TotemDeckDB.popupModifier or "NONE"
    if modifier == "NONE" then
        return true
    elseif modifier == "SHIFT" then
        return IsShiftKeyDown()
    elseif modifier == "CTRL" then
        return IsControlKeyDown()
    elseif modifier == "ALT" then
        return IsAltKeyDown()
    end
    return true
end

-- Check if player has the buff from a totem (for out-of-range detection)
-- Returns: true = has buff (in range), false = no buff (out of range), nil = totem doesn't provide a buff
function addon.HasTotemBuff(totemName)
    local baseName = totemName:gsub("%s+[IVXLCDM]+$", "") -- Strip rank suffix
    local buffName = addon.TOTEM_BUFFS[baseName]
    if not buffName then
        return nil -- Totem doesn't provide a player buff
    end

    -- Check if player has the buff
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        if name == buffName or name:find(baseName, 1, true) then
            return true
        end
    end
    return false
end

-- Check if a weapon buff spell is known
function addon.IsWeaponBuffKnown(buffName)
    local name, _, _, _, _, _, spellID = GetSpellInfo(buffName)
    if not spellID then
        return false
    end
    return IsPlayerSpell(spellID)
end

-- Get list of known weapon buffs
function addon.GetKnownWeaponBuffs()
    local known = {}
    for _, buff in ipairs(addon.WEAPON_BUFFS) do
        if addon.IsWeaponBuffKnown(buff.name) then
            table.insert(known, buff)
        end
    end
    return known
end

-- Get current weapon enchant info and match to weapon buff name
function addon.GetCurrentWeaponBuff()
    local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID,
          hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()

    -- Clear tracked buffs if enchant is gone
    if not hasMainHandEnchant then
        addon.state.activeMainHandBuff = nil
    end
    if not hasOffHandEnchant then
        addon.state.activeOffHandBuff = nil
    end

    -- Return info about current enchants
    return {
        mainHand = hasMainHandEnchant and mainHandEnchantID or nil,
        mainHandTime = hasMainHandEnchant and mainHandExpiration or nil,
        mainHandBuff = addon.state.activeMainHandBuff,
        offHand = hasOffHandEnchant and offHandEnchantID or nil,
        offHandTime = hasOffHandEnchant and offHandExpiration or nil,
        offHandBuff = addon.state.activeOffHandBuff,
    }
end

-- Check if a spell name is a weapon buff and return the buff data
function addon.GetWeaponBuffByName(spellName)
    for _, buff in ipairs(addon.WEAPON_BUFFS) do
        if spellName == buff.name then
            return buff
        end
    end
    return nil
end

-- Get totems for an element in custom order (if set)
function addon.GetOrderedTotems(element)
    local savedOrder = TotemDeckDB and TotemDeckDB.totemOrder and TotemDeckDB.totemOrder[element]
    if not savedOrder or #savedOrder == 0 then
        return addon.TOTEMS[element] -- Use default order
    end

    -- Build ordered list from saved names
    local ordered = {}
    for _, name in ipairs(savedOrder) do
        for _, totem in ipairs(addon.TOTEMS[element]) do
            if totem.name == name then
                table.insert(ordered, totem)
                break
            end
        end
    end

    -- Add any totems not in saved order (e.g., newly added)
    for _, totem in ipairs(addon.TOTEMS[element]) do
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
function addon.FormatTime(seconds)
    if seconds >= 60 then
        return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
    else
        return string.format("%d", seconds)
    end
end
