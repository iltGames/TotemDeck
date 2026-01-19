# TotemDeck

A lightweight shaman totem management addon for WoW Classic. Streamlined totem bar with hover popups, weapon buff management, and Reincarnation tracking.

## Features

### Totem Bar
- **4-button bar** for Earth, Fire, Water, Air totems
- **Hover popup** shows all trained totems for each element
- **Left-click** to cast, **Right-click** to set as active or dismiss
- **Shift+Right-click** to recall all totems (Totemic Call)
- **Custom ordering** for both elements and individual totems
- **Hide unused totems** from the popup

### Timers
- **Bar style** - Traditional timer bars above/below/beside the bar
- **Icon style** - Compact countdown text under each button
- **Placed totem indicator** - Shows when placed totem differs from active selection

### Reincarnation Tracker
- Small button showing Reincarnation with Ankh count overlay
- Cooldown sweep display
- **Green border** when ready, **Red border** when no Ankhs

### Weapon Buffs
- Quick access to all weapon enchants (Rockbiter, Flametongue, Frostbrand, Windfury)
- Hover popup with all known weapon buffs
- **Left-click** applies to main hand, **Right-click** applies to off-hand
- **Green border** when buffed, **Red border** when no enchant active
- Icon updates to show currently active buff with remaining duration

### Macros
Creates 5 macros for your action bars:

| Macro | Description |
|-------|-------------|
| `TDEarth` | Cast active Earth totem |
| `TDFire` | Cast active Fire totem |
| `TDWater` | Cast active Water totem |
| `TDAir` | Cast active Air totem |
| `TDAll` | Cast all 4 totems in sequence |

## Controls

| Action | Main Bar | Popup Totems |
|--------|----------|--------------|
| **Left-click** | Cast active totem | Cast totem |
| **Right-click** | Dismiss totem | Set as active |
| **Shift+Right-click** | Totemic Call | - |
| **Ctrl+drag** | Move bar | - |

## Configuration

**Open config:** `/td config`

| Setting | Options |
|---------|---------|
| Popup Direction | Up / Down / Left / Right |
| Timer Position | Above / Below / Left / Right |
| Timer Style | Bars / Icons |
| Show Timers | On / Off |
| Lock Position | On / Off |
| Always Show Popup | On / Off |
| Show Reincarnation | On / Off |
| Show Weapon Buffs | On / Off |

## Commands

| Command | Description |
|---------|-------------|
| `/td` | Show help |
| `/td config` | Open config window |
| `/td show` | Toggle visibility |
| `/td timers` | Toggle timers |
| `/td macros` | Recreate macros |

## Installation

1. Extract to `Interface/AddOns/TotemDeck`
2. Restart WoW or `/reload`
3. Bar appears automatically for Shaman characters

## License

MIT
