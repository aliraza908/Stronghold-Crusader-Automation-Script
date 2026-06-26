<div align="center">
  <h1>🏰 Stronghold Crusader Automation Suite</h1>
  <p>A powerful, safe, and intelligent macro suite for automating unit and siege equipment production in Stronghold Crusader.</p>
</div>

---

## ✨ Why Use This Suite?

Stronghold Crusader is an amazing game, but late-game army production can be exhausting. Clicking 50 times just to build a handful of catapults distracts you from actually enjoying the strategy and battles.

This script acts as your personal quartermaster. It handles the repetitive clicking for you, utilizing **AutoHotkey v2** to safely simulate human inputs without injecting into the game's memory. It features an intelligent calibration wizard to adapt to any screen resolution and an advanced grid-placement engine for siege weapons!

## 🚀 Key Features

*   🎛️ **Full Interactive GUI:** A beautiful, easy-to-use dashboard to manage your macros without ever touching a line of code.
*   ⚔️ **16 Supported Units:** Full coverage across 5 categories: Shields (Swordsmen, Knights), Ranged (Archers, Crossbows), Infantry, Siege, and Arabian mercenaries.
*   🎯 **Intelligent Siege Placement:** Unlike normal troops, Siege equipment (Catapults, Trebuchets) must be placed on the ground. When batch-building siege equipment, the macro automatically calculates a spatial grid and neatly places the tents side-by-side so they don't overlap!
*   ⚡ **Lightning Fast Batching:** Need 70 Catapults instantly? Set your batch size, press your hotkey once, and watch the script instantly snap back and forth, holding the mouse for precisely 20ms to guarantee the game's isometric engine registers every single click.
*   📐 **Auto-Calibration Wizard:** Stronghold Crusader scales UI elements based on resolution. The built-in wizard lets you teach the script exactly where your buttons are simply by hovering over them and pressing `SPACE`.
*   💾 **Persistent State:** All hotkeys, batch sizes, settings, and calibration coordinates are automatically saved to a `config.ini` file.

## 🛠️ Installation & Setup

1.  **Install AutoHotkey:** Download and install the latest **v2** release from [AutoHotkey.com](https://www.autohotkey.com/).
2.  **Download:** Clone or download this repository.
3.  **Launch:** Double-click `stronghold_macro.ahk`. The GUI will open and an icon will appear in your system tray.

## 🕹️ How to Use

### 1. The Crucial First Step: Calibration
Because every monitor is different, the macro needs to know where the buttons are on your screen.
1.  Launch *Stronghold Crusader* and enter a skirmish or campaign.
2.  Open the Macro Suite and go to the **Calibrate** tab.
3.  Click **Start Full Calibration**.
4.  Alt-Tab back into the game. A tooltip will ask you to hover over a specific unit's icon.
5.  Hover your mouse over the requested icon in the bottom game menu and press `SPACE`.
6.  The script automatically detects your active game window title and saves the coordinates!

### 2. Configure Your Army
1.  Navigate to the **Macros** tab.
2.  Double-click any unit in the list to configure its settings.
3.  Assign a custom **Hotkey** (e.g., `F1`, `F2`, `Numpad1`).
4.  Set your desired **Batch Size** (how many units to produce per single press).

### 3. Unleash the Macros
1.  Go to the **Dashboard** tab and click **START**.
2.  Return to your game.
3.  **For Normal Units:** Simply press your hotkey, and the script will instantly queue them up.
4.  **For Siege Units:** Have your favorite Engineer's Guild menu open, point your mouse at an empty patch of ground, and press your hotkey. The macro will instantly dart back and forth, constructing a perfect grid of siege tents!

*Need to type in chat? Press `F12` (configurable) to instantly pause the macros!*

## ⚙️ Advanced Settings

In the **Settings** tab, you can fine-tune the engine:
*   **Game Window Title:** Auto-detected during calibration, but can be manually overridden.
*   **Click Delay:** The macro's speed. Decrease this to make the macro run faster, or increase it if your PC is dropping clicks and missing units.
*   **Return Mouse:** When enabled, the macro will instantly teleport your cursor back to where it was after producing units.

## ⚠️ Disclaimer

This tool purely simulates standard mouse inputs and does not interact with the game's memory or files. However, it is strictly recommended for **single-player use only**. Using macros in multiplayer games may violate community rules or ruin the fun for others. Use responsibly and enjoy building your empire!
