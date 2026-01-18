# TotemDeck

A lightweight shaman totem management addon for WoW Classic TBC. Hover over any element to see all available totems, then cast or set your active totem with a single click.

## Features

- **Compact totem bar** - 4 buttons, one for each element (Earth, Fire, Water, Air)
- **Hover popup** - Mouse over any element to see all totems of that type
- **Smart filtering** - Only shows totems you have trained
- **Quick casting** - Left-click any totem to cast it instantly
- **Quick dismiss** - Right-click the main element button to dismiss that totem
- **Active totem selection** - Right-click a popup totem to set it as your preferred totem for that element
- **Totem timers** - Duration bars show remaining time on active totems
- **Custom totem order** - Rearrange totems in any order you prefer via the config window
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
- Show Timers toggle
- Lock Bar Position toggle
- Recreate Macros button

**Totem Order Tab:**
- Drag totems up/down to reorder them within each element
- Click "Apply" to update the popup display
- Click "Reset to Default" to restore original order

### Quick Options Menu
Alt+click the bar to access:
- Popup direction
- Timer position
- Show/hide timers
- Lock/unlock position
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
