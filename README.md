# TotemDeck

A lightweight shaman totem management addon for WoW Classic TBC. Hover over any element to see all available totems, then cast or set your active totem with a single click.

## Features

- **Compact totem bar** - 4 buttons, one for each element (Earth, Fire, Water, Air)
- **Hover popup** - Mouse over any element to see all totems of that type
- **Always show option** - Optionally keep popup bars visible at all times
- **Smart filtering** - Only shows totems you have trained
- **Quick casting** - Left-click any totem to cast it instantly
- **Quick dismiss** - Right-click the main element button to dismiss that totem
- **Active totem selection** - Right-click a popup totem to set it as your preferred totem for that element (works in combat)
- **Placed totem indicator** - When a placed totem differs from your active selection, shows the placed totem with a desaturated icon and gray border
- **Totem timers** - Duration display with two styles: traditional bars or compact icon text
- **Timer styles** - Choose between bar timers (separate timer bars) or icon timers (countdown text under each button)
- **Custom element order** - Rearrange element groups (Earth, Fire, Water, Air) in any order
- **Custom totem order** - Rearrange totems within each element via the config window
- **Hide totems** - Hide specific totems you don't use from the popup
- **Full configuration UI** - Tabbed config window with Layout and Totem Order settings
- **Quick options menu** - Alt+click the bar for fast access to common settings
- **Macro support** - Creates macros (TDEarth, TDFire, TDWater, TDAir) that cast your active totems
- **Moveable & lockable** - Ctrl+click to reposition, lock position via options

## Usage

### Main Bar
- **Hover** over an element to see all totems for that type
- **Left-click** to cast your active totem
- **Right-click** to dismiss the active totem of that element
- **Alt+click** to open the quick options menu
- **Ctrl+click** to move the bar (when unlocked)

### Popup Totems
- **Left-click** a totem to cast it
- **Right-click** a totem to set it as active for that element

## Configuration

### Full Config Window
Open with `/td config` or via "Show Full Config..." in the quick menu.

**Layout Tab:**
- Popup Direction (Up/Down/Left/Right)
- Timer Position (Above/Below/Left/Right)
- Timer Style (Bars/Icons)
- Show Timers toggle
- Lock Bar Position toggle
- Always Show Popup toggle
- Recreate Macros button

**Totem Order Tab:**
- Element Order - Rearrange the element groups using arrow buttons
- Totem Order - Reorder totems within each element using up/down buttons
- Hide Totems - Click the X button on any totem to hide it from the popup (O to show again)
- Click "Apply" to update the display
- Click "Reset to Default" to restore original order and show all hidden totems

### Quick Options Menu
Alt+click the bar to access:
- Popup direction
- Timer position
- Timer style
- Show/hide timers
- Lock/unlock position
- Always show popup
- Show full config
- Recreate macros

## Slash Commands

| Command | Description |
|---------|-------------|
| `/td` | Show help |
| `/td show` | Toggle bar visibility |
| `/td timers` | Toggle timer bars |
| `/td config` | Open configuration window |
| `/td timers above/below/left/right` | Set timer position |
| `/td popup up/down/left/right` | Set popup direction |
| `/td macros` | Create/update macros |

## Macros

The addon creates 4 macros you can place on your action bars:

| Macro | Description |
|-------|-------------|
| `TDEarth` | Casts your active Earth totem |
| `TDFire` | Casts your active Fire totem |
| `TDWater` | Casts your active Water totem |
| `TDAir` | Casts your active Air totem |

These macros automatically update their icons when you change your active totem.

## Installation

1. Download and extract to your `Interface/AddOns` folder
2. Restart WoW or `/reload`
3. The totem bar appears automatically for Shaman characters

## License

MIT
