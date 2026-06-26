; ═══════════════════════════════════════════════════════════════════════════
;  STRONGHOLD CRUSADER — MACRO AUTOMATION SUITE v1.0
;  Automates unit recruitment & siege equipment production
;
;  ✔ Safe — simulates mouse clicks only
;  ✔ No memory injection or game file modification
;  ✔ Single-player use recommended
;
;  Requires: AutoHotkey v2.0+
;  Download: https://www.autohotkey.com/
; ═══════════════════════════════════════════════════════════════════════════

#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 1
Persistent
SetTitleMatchMode(2)
CoordMode("Mouse", "Client")
CoordMode("ToolTip", "Screen")
SetMouseDelay(0)

; ─── CONSTANTS ────────────────────────────────────────────────────────────
global APP_NAME    := "Stronghold Crusader Macro Suite"
global APP_VERSION := "1.0.0"
global CONFIG_FILE := A_ScriptDir "\config.ini"

; ─── GLOBAL STATE ─────────────────────────────────────────────────────────
global gRunning       := false
global gPaused        := false
global gExecuting     := false
global gCalibrating   := false
global gCalibIndex    := 0
global gCalibQueue    := []
global gTotalProduced := 0

; GUI Controls (assigned during BuildGui)
global gMainGui      := ""
global gLogCtrl      := ""
global gStatusText   := ""
global gStatsText    := ""
global gMacroList    := ""
global gCalibStatus  := ""
global gDelayText    := ""

; ─── SETTINGS (overridden by config.ini if present) ───────────────────────
global gGameTitle   := "Stronghold"
global gClickDelay  := 150
global gReturnMouse := true
global gPlaySound   := true
global gPauseKey    := "F12"
global gAlwaysOnTop := true

; ─── UNIT DATA STORES ─────────────────────────────────────────────────────
global gUnitDefs := []
global gHotkeys  := Map()
global gBatches  := Map()
global gEnabled  := Map()
global gCoordX   := Map()
global gCoordY   := Map()


; ═══════════════════════════════════════════════════════════════════════════
;  AUTO-EXECUTE — Runs on startup
; ═══════════════════════════════════════════════════════════════════════════
DefineUnits()
LoadConfig()
BuildGui()
SetupTrayMenu()
return


; ═══════════════════════════════════════════════════════════════════════════
;  UNIT DEFINITIONS
;  Covers all recruitable units in Stronghold Crusader:
;    • Shield Units (Barracks — require armoury + weapons)
;    • Ranged       (Barracks — require fletcher/armoury)
;    • Infantry     (Barracks — require armoury)
;    • Siege        (Engineer's Guild)
;    • Arabian      (Mercenary Post — gold only)
; ═══════════════════════════════════════════════════════════════════════════

DefineUnits() {
    ; ── Shield Units ──
    AddUnit("Swordsman",        "Shield Units", "swordsman",        "F1")
    AddUnit("Pikeman",          "Shield Units", "pikeman",          "F2")
    AddUnit("Knight",           "Shield Units", "knight",           "F3")

    ; ── Ranged ──
    AddUnit("Archer",           "Ranged",       "archer",           "F4")
    AddUnit("Crossbowman",      "Ranged",       "crossbowman",     "F5")

    ; ── Infantry ──
    AddUnit("Spearman",         "Infantry",     "spearman",         "F6")

    ; ── Siege ──
    AddUnit("Engineer",         "Siege",        "engineer",         "F7")
    AddUnit("Catapult",         "Siege",        "catapult",         "F8")
    AddUnit("Fire Ballista",    "Siege",        "fire_ballista",    "F9")
    AddUnit("Trebuchet",        "Siege",        "trebuchet",        "F10")
    AddUnit("Portable Shield",  "Siege",        "portable_shield",  "F11")

    ; ── Arabian ──
    AddUnit("Arab Swordsman",   "Arabian",      "arab_sword",       "Numpad1")
    AddUnit("Horse Archer",     "Arabian",      "horse_archer",     "Numpad2")
    AddUnit("Assassin",         "Arabian",      "assassin",         "Numpad3")
    AddUnit("Fire Thrower",     "Arabian",      "fire_thrower",     "Numpad4")
    AddUnit("Slave",            "Arabian",      "slave",            "Numpad5")
}

AddUnit(name, category, id, defaultKey) {
    gUnitDefs.Push({name: name, cat: category, id: id, defKey: defaultKey})
    gHotkeys[id]  := defaultKey
    gBatches[id]  := 1
    gEnabled[id]  := true
    gCoordX[id]   := 0
    gCoordY[id]   := 0
}


; ═══════════════════════════════════════════════════════════════════════════
;  GUI CONSTRUCTION
; ═══════════════════════════════════════════════════════════════════════════

BuildGui() {
    global gMainGui, gLogCtrl, gStatusText, gStatsText, gMacroList, gCalibStatus, gDelayText
    g := Gui("+Resize", APP_NAME . " v" . APP_VERSION)
    g.SetFont("s10", "Segoe UI")
    g.OnEvent("Close", OnGuiClose)
    gMainGui := g

    if gAlwaysOnTop
        g.Opt("+AlwaysOnTop")

    ; ── Tab control ──
    tab := g.Add("Tab3", "vTabs w660 h510",
        ["Dashboard", "Macros", "Calibrate", "Settings"])

    ; ═══════════════════════════════════
    ;  TAB 1 — DASHBOARD
    ; ═══════════════════════════════════
    tab.UseTab(1)

    g.SetFont("s16 Bold")
    g.Add("Text", "w640 Center", "STRONGHOLD CRUSADER MACRO SUITE")
    g.SetFont("s10 norm")
    g.Add("Text", "w640 Center cGray",
        "Automate unit recruitment with configurable hotkeys")

    g.Add("Text", "w640 h2 0x10 y+12")

    ; Status row
    g.SetFont("s12 Bold")
    gStatusText := g.Add("Text", "w300 y+10 cRed", "STOPPED")
    g.SetFont("s10 norm")
    gStatsText  := g.Add("Text", "x+20 w300 Right yp+2", "Session: 0 units produced")

    ; Control buttons
    g.Add("Button", "xm y+15 w150 h38", "START").OnEvent("Click", OnStart)
    g.Add("Button", "x+10 w150 h38",    "PAUSE").OnEvent("Click", OnPause)
    g.Add("Button", "x+10 w150 h38",    "STOP").OnEvent("Click",  OnStop)

    ; Activity log
    g.Add("Text", "xm y+20 Section", "Activity Log:")
    g.Add("Button", "x+370 yp w100 h24", "Clear Log").OnEvent("Click", OnClearLog)
    gLogCtrl := g.Add("Edit", "xm y+5 w640 h180 ReadOnly Multi VScroll -WantReturn")

    AddLog("Script loaded. Configure macros and click START.")
    AddLog("Press " . gPauseKey . " in-game to toggle pause.")

    ; ═══════════════════════════════════
    ;  TAB 2 — MACROS
    ; ═══════════════════════════════════
    tab.UseTab(2)

    g.Add("Text", "w640 Section",
        "Configure which units to automate. Double-click a row to edit.")

    gMacroList := g.Add("ListView",
        "vMacroList xm y+10 w640 h360 Checked Grid -Multi",
        ["Unit Name", "Category", "Hotkey", "Batch", "Calibrated"])
    gMacroList.OnEvent("DoubleClick", OnMacroDoubleClick)
    gMacroList.OnEvent("ItemCheck",   OnMacroCheck)

    RefreshMacroList()

    ; Action buttons
    g.Add("Button", "xm y+10 w160 h32", "Edit Selected").OnEvent("Click", OnEditMacro)
    g.Add("Button", "x+10  w140 h32",   "Enable All").OnEvent("Click",    OnEnableAll)
    g.Add("Button", "x+10  w140 h32",   "Disable All").OnEvent("Click",   OnDisableAll)

    ; ═══════════════════════════════════
    ;  TAB 3 — CALIBRATION
    ; ═══════════════════════════════════
    tab.UseTab(3)

    g.SetFont("s12 Bold")
    g.Add("Text", "w640", "Coordinate Calibration")
    g.SetFont("s10 norm")

    g.Add("Text", "w640 y+10",
        "Each unit's button position in the game needs to be recorded once.`n"
        . "This only needs to be done once per screen resolution.")

    g.Add("Text", "w640 h2 0x10 y+10")

    g.SetFont("s10 Bold")
    g.Add("Text", "w640 y+8", "HOW TO CALIBRATE:")
    g.SetFont("s10 norm")

    g.Add("Text", "w640 y+5",
        "  1.  Launch Stronghold Crusader and start or load a game`n"
        . "  2.  Click 'Start Full Calibration' below`n"
        . "  3.  Alt+Tab to the game window`n"
        . "  4.  Hover your mouse over the unit icon shown in the tooltip`n"
        . "  5.  Press SPACE to record the position`n"
        . "  6.  Repeat for each unit — press ESC to cancel anytime")

    g.Add("Text", "w640 h2 0x10 y+12")

    g.Add("Button", "xm y+10 w200 h38",
        "Start Full Calibration").OnEvent("Click", OnStartCalibration)
    g.Add("Button", "x+10 w200 h38",
        "Calibrate Selected").OnEvent("Click", OnCalibrateSingle)
    g.Add("Button", "x+10 w200 h38",
        "Test Click Position").OnEvent("Click", OnTestClick)

    g.Add("Text", "xm y+15 w640 h2 0x10")

    gCalibStatus := g.Add("Text", "xm y+10 w640 cBlue", GetCalibrationStatus())

    g.Add("Text", "xm y+15 w640 cRed",
        "WARNING: Recalibrate if you change your screen resolution or window size!")

    ; ═══════════════════════════════════
    ;  TAB 4 — SETTINGS
    ; ═══════════════════════════════════
    tab.UseTab(4)

    g.SetFont("s12 Bold")
    g.Add("Text", "w640", "Settings")
    g.SetFont("s10 norm")

    ; ── Game Window Detection ──
    g.Add("GroupBox", "xm y+10 w640 h80", "Game Window Detection")
    g.Add("Text", "xp+15 yp+28", "Window title contains:")
    g.Add("Edit", "vGameTitle x+10 w300 yp-3", gGameTitle)
    g.Add("Text", "xm+15 y+8 w600 cGray",
        "(Partial match — e.g. 'Stronghold' matches 'Stronghold Crusader HD')")

    ; ── Click Timing ──
    g.Add("GroupBox", "xm y+20 w640 h90", "Click Timing")
    g.Add("Text", "xp+15 yp+28", "Delay between clicks:")
    slider := g.Add("Slider",
        "vDelaySlider x+10 w280 Range50-500 TickInterval50 Page50 yp-3",
        gClickDelay)
    slider.OnEvent("Change", OnDelayChange)
    gDelayText := g.Add("Text", "x+10 w80 yp+3", gClickDelay . " ms")
    g.Add("Text", "xm+15 y+8 w600 cGray",
        "(Increase if the game misses clicks. 100–200 ms works for most PCs)")

    ; ── Options ──
    g.Add("GroupBox", "xm y+20 w640 h140", "Options")
    y0 := "xp+15 yp+28"
    g.Add("CheckBox", y0 . " vChkReturnMouse Checked" . (gReturnMouse ? 1 : 0),
        " Return mouse to original position after macro")
    g.Add("CheckBox", "xp y+8 vChkPlaySound Checked" . (gPlaySound ? 1 : 0),
        " Play beep on macro execution")
    g.Add("CheckBox", "xp y+8 vChkAlwaysOnTop Checked" . (gAlwaysOnTop ? 1 : 0),
        " Keep this window always on top")
    g.Add("Text", "xp y+12", "Pause / Resume toggle key:")
    g.Add("Edit", "vPauseKeyEdit x+10 w100 yp-3", gPauseKey)

    ; ── Save / Reset ──
    g.Add("Button", "xm y+25 w160 h38",
        "Save Settings").OnEvent("Click", OnSaveSettings)
    g.Add("Button", "x+15 w160 h38",
        "Reset Defaults").OnEvent("Click", OnResetDefaults)

    ; ── About ──
    g.Add("Text", "xm y+25 w640 h2 0x10")
    g.SetFont("s9")
    g.Add("Text", "xm y+10 w640 Center cGray",
        APP_NAME . " v" . APP_VERSION . "`n"
        . "Safe for single-player use — simulates mouse clicks only`n"
        . "No memory injection · No game file modification")
    g.SetFont("s10")

    ; ── Finalise ──
    tab.UseTab()

    gMacroList.ModifyCol(1, 150)
    gMacroList.ModifyCol(2, 100)
    gMacroList.ModifyCol(3, 80)
    gMacroList.ModifyCol(4, 60)
    gMacroList.ModifyCol(5, 110)

    g.Show("w690 h550")
}


; ═══════════════════════════════════════════════════════════════════════════
;  GUI EVENT HANDLERS
; ═══════════════════════════════════════════════════════════════════════════

OnGuiClose(thisGui) {
    SaveConfig()
    ExitApp()
}

; ── Dashboard buttons ─────────────────────────────────────────────────────

OnStart(*) {
    if gRunning
        return

    calibrated := 0
    enabled    := 0
    for unit in gUnitDefs {
        if gEnabled[unit.id] {
            enabled++
            if (gCoordX[unit.id] != 0) || (gCoordY[unit.id] != 0)
                calibrated++
        }
    }

    if enabled = 0 {
        MsgBox("No macros are enabled!`n`nEnable at least one unit in the Macros tab.",
            APP_NAME, "Icon!")
        return
    }

    if calibrated = 0 {
        res := MsgBox(
            "No units have been calibrated yet!`n`n"
            . "Calibrate positions in the Calibrate tab first.`n`n"
            . "Start anyway? (macros won't fire until calibrated)",
            APP_NAME, "YesNo Icon!")
        if res = "No"
            return
    }

    global gRunning, gPaused
    gRunning := true
    gPaused  := false
    RegisterAllHotkeys()
    UpdateStatus()
    AddLog("Started — " . calibrated . "/" . enabled . " macros ready")
    SaveConfig()
}

OnPause(*) {
    if !gRunning
        return
    global gPaused
    gPaused := !gPaused
    UpdateStatus()
    AddLog(gPaused ? "Paused" : "Resumed")
}

OnStop(*) {
    if !gRunning
        return
    global gRunning, gPaused
    gRunning := false
    gPaused  := false
    UnregisterAllHotkeys()
    UpdateStatus()
    AddLog("Stopped")
}

OnClearLog(*) {
    gLogCtrl.Value := ""
}

; ── Macro list events ─────────────────────────────────────────────────────

OnMacroDoubleClick(lv, rowNum) {
    if rowNum > 0
        ShowEditDialog(rowNum)
}

OnMacroCheck(lv, rowNum, checked) {
    if rowNum < 1 || rowNum > gUnitDefs.Length
        return
    unit := gUnitDefs[rowNum]
    gEnabled[unit.id] := checked ? true : false
}

OnEditMacro(*) {
    rowNum := gMacroList.GetNext(0, "F")
    if rowNum > 0
        ShowEditDialog(rowNum)
    else
        MsgBox("Select a unit from the list first.", APP_NAME)
}

OnEnableAll(*) {
    Loop gMacroList.GetCount() {
        gMacroList.Modify(A_Index, "Check")
        if A_Index <= gUnitDefs.Length
            gEnabled[gUnitDefs[A_Index].id] := true
    }
}

OnDisableAll(*) {
    Loop gMacroList.GetCount() {
        gMacroList.Modify(A_Index, "-Check")
        if A_Index <= gUnitDefs.Length
            gEnabled[gUnitDefs[A_Index].id] := false
    }
}

; ── Settings events ───────────────────────────────────────────────────────

OnDelayChange(ctrl, *) {
    global gClickDelay
    gClickDelay := ctrl.Value
    gDelayText.Value := gClickDelay . " ms"
}

OnSaveSettings(*) {
    saved := gMainGui.Submit(false)

    global gGameTitle, gReturnMouse, gPlaySound, gAlwaysOnTop, gPauseKey, gClickDelay
    gGameTitle   := saved.GameTitle
    gReturnMouse := saved.ChkReturnMouse ? true : false
    gPlaySound   := saved.ChkPlaySound   ? true : false
    gAlwaysOnTop := saved.ChkAlwaysOnTop  ? true : false
    gPauseKey    := saved.PauseKeyEdit
    gClickDelay  := saved.DelaySlider

    gMainGui.Opt(gAlwaysOnTop ? "+AlwaysOnTop" : "-AlwaysOnTop")

    SaveConfig()
    AddLog("Settings saved")
    MsgBox("Settings saved successfully!", APP_NAME, "Iconi")
}

OnResetDefaults(*) {
    res := MsgBox(
        "Reset all settings to defaults?`n`nCalibration data will NOT be cleared.",
        APP_NAME, "YesNo Icon!")
    if res = "No"
        return

    global gGameTitle, gClickDelay, gReturnMouse, gPlaySound, gPauseKey, gAlwaysOnTop
    gGameTitle   := "Stronghold"
    gClickDelay  := 150
    gReturnMouse := true
    gPlaySound   := true
    gPauseKey    := "F12"
    gAlwaysOnTop := true

    for unit in gUnitDefs {
        gHotkeys[unit.id] := unit.defKey
        gBatches[unit.id] := 1
        gEnabled[unit.id] := true
    }

    ; Push to GUI controls
    gMainGui["GameTitle"].Value    := gGameTitle
    gMainGui["DelaySlider"].Value  := gClickDelay
    gDelayText.Value               := gClickDelay . " ms"
    gMainGui["ChkReturnMouse"].Value := 1
    gMainGui["ChkPlaySound"].Value   := 1
    gMainGui["ChkAlwaysOnTop"].Value := 1
    gMainGui["PauseKeyEdit"].Value   := gPauseKey
    gMainGui.Opt("+AlwaysOnTop")

    RefreshMacroList()
    SaveConfig()
    AddLog("Settings reset to defaults")
}


; ═══════════════════════════════════════════════════════════════════════════
;  EDIT DIALOG  (popup for a single unit)
; ═══════════════════════════════════════════════════════════════════════════

ShowEditDialog(rowNum) {
    if rowNum < 1 || rowNum > gUnitDefs.Length
        return

    unit := gUnitDefs[rowNum]

    ed := Gui("+Owner" . gMainGui.Hwnd, "Edit — " . unit.name)
    ed.SetFont("s10", "Segoe UI")

    ed.Add("Text", "w320", "Unit:  " . unit.name . "   (" . unit.cat . ")")
    ed.Add("Text", "w320 h2 0x10 y+10")

    ed.Add("Text", "y+10", "Hotkey:")
    ed.Add("Edit", "vHotkeyEdit x+10 w160 yp-3", gHotkeys[unit.id])

    ed.Add("Text", "xm y+12", "Batch size:")
    ed.Add("Edit", "vBatchEdit x+10 w60 Number yp-3", gBatches[unit.id])
    ed.Add("UpDown", "Range1-50", gBatches[unit.id])

    ; Show calibration status
    ed.Add("Text", "xm y+12", "Position:")
    coordLabel := (gCoordX[unit.id] = 0 && gCoordY[unit.id] = 0)
        ? "Not calibrated"
        : "X=" . gCoordX[unit.id] . "  Y=" . gCoordY[unit.id]
    ed.Add("Text", "x+10 w200 cBlue yp", coordLabel)

    ed.Add("Text", "xm y+15 w320 h2 0x10")

    ; Store references for callback
    ed.unitId  := unit.id
    ed.rowNum  := rowNum

    ed.Add("Button", "xm y+10 w100 h32 Default", "OK").OnEvent("Click",
        OnEditOK.Bind(ed))
    ed.Add("Button", "x+10 w100 h32", "Cancel").OnEvent("Click",
        (*) => ed.Destroy())

    ed.Show()
}

OnEditOK(ed, *) {
    saved  := ed.Submit()
    unitId := ed.unitId

    gHotkeys[unitId] := saved.HotkeyEdit

    newBatch := 1
    try newBatch := Integer(saved.BatchEdit)
    newBatch := Max(1, Min(50, newBatch))
    gBatches[unitId] := newBatch

    RefreshMacroList()

    ; Re-register hotkeys if running
    if gRunning {
        UnregisterAllHotkeys()
        RegisterAllHotkeys()
    }

    AddLog("Updated " . unitId . ": key=" . gHotkeys[unitId] . " batch=" . gBatches[unitId])
    ed.Destroy()
}


; ═══════════════════════════════════════════════════════════════════════════
;  MACRO EXECUTION ENGINE
; ═══════════════════════════════════════════════════════════════════════════

ExecuteMacro(unitId, *) {
    global gExecuting, gTotalProduced

    ; Guard: prevent overlapping executions
    if gExecuting
        return

    if gPaused {
        ShowTooltip("Macro paused — press " . gPauseKey . " to resume")
        return
    }

    if !IsGameActive() {
        ShowTooltip("Game window not active")
        return
    }

    x := gCoordX[unitId]
    y := gCoordY[unitId]

    if (x = 0) && (y = 0) {
        ShowTooltip(unitId . " not calibrated!")
        return
    }

    gExecuting := true
    batch := gBatches[unitId]

    ; Find display name and category
    unitName := unitId
    unitCat := ""
    for unit in gUnitDefs {
        if unit.id = unitId {
            unitName := unit.name
            unitCat := unit.cat
            break
        }
    }

    ; Save current mouse position (ground target)
    MouseGetPos(&origX, &origY)

    ; Calculate grid dimensions for siege placement
    cols := Ceil(Sqrt(batch))
    spacing := 50 ; Pixels between placements to avoid overlap

    ; Click the unit icon (repeat for batch)
    Loop batch {
        if (unitCat = "Siege") {
            ; 1. Move to menu icon and wait briefly
            MouseMove(x, y, 0)
            Sleep(15)
            Click("Down")
            Sleep(20)
            Click("Up")
            Sleep(15) ; Quick snap to next action

            ; 2. Calculate ground placement offset
            c := Mod(A_Index - 1, cols)
            r := (A_Index - 1) // cols
            placeX := origX + (c * spacing)
            placeY := origY + (r * spacing)

            ; 3. Move to ground and WAIT for game to register the tile
            MouseMove(placeX, placeY, 0)
            Sleep(gClickDelay) ; Critical for Stronghold: controlled by Settings slider

            ; 4. Click ground to place
            Click("Down")
            Sleep(20)
            Click("Up")
            
            if (A_Index < batch)
                Sleep(15) ; Quick snap back to menu
        } else {
            ; Normal unit — move to icon and click
            MouseMove(x, y, 0)
            Sleep(15)
            Click("Down")
            Sleep(20)
            Click("Up")
            if (A_Index < batch)
                Sleep(gClickDelay)
        }
    }

    ; Restore mouse position
    if gReturnMouse
        MouseMove(origX, origY, 0)

    ; Audio feedback
    if gPlaySound
        SoundBeep(800, 40)

    gTotalProduced += batch
    gExecuting := false

    UpdateStats()
    AddLog("Produced " . batch . "x " . unitName)
}

IsGameActive(hk := "") {
    return WinActive(gGameTitle) ? true : false
}


; ═══════════════════════════════════════════════════════════════════════════
;  HOTKEY MANAGEMENT
; ═══════════════════════════════════════════════════════════════════════════

RegisterAllHotkeys() {
    ; Unit macros — only fire when game window is active
    HotIf IsGameActive
    for unit in gUnitDefs {
        if !gEnabled[unit.id]
            continue
        try {
            fn := ExecuteMacro.Bind(unit.id)
            Hotkey(gHotkeys[unit.id], fn, "On")
        } catch as e {
            AddLog("Failed to register " . gHotkeys[unit.id]
                . " for " . unit.name . ": " . e.Message)
        }
    }
    HotIf()

    ; Pause toggle — always active
    try Hotkey(gPauseKey, TogglePauseHK, "On")
    catch as e
        AddLog("Failed to register pause key: " . e.Message)
}

UnregisterAllHotkeys() {
    HotIf IsGameActive
    for unit in gUnitDefs {
        try Hotkey(gHotkeys[unit.id], "Off")
    }
    HotIf()

    try Hotkey(gPauseKey, "Off")
}

TogglePauseHK(*) {
    OnPause()
}


; ═══════════════════════════════════════════════════════════════════════════
;  CALIBRATION SYSTEM
; ═══════════════════════════════════════════════════════════════════════════

OnStartCalibration(*) {
    if gCalibrating {
        CancelCalibration()
        return
    }

    global gCalibQueue, gCalibIndex, gCalibrating

    gCalibQueue := []
    for unit in gUnitDefs {
        if gEnabled[unit.id]
            gCalibQueue.Push(unit)
    }

    if gCalibQueue.Length = 0 {
        MsgBox("No units are enabled!`nEnable units in the Macros tab first.",
            APP_NAME, "Icon!")
        return
    }

    gCalibrating := true
    gCalibIndex  := 1

    ; Temporary hotkeys for calibration
    Hotkey("Space",  RecordCalibPoint, "On")
    Hotkey("Escape", CancelCalibHK,    "On")

    AddLog("Calibration started — " . gCalibQueue.Length . " units to calibrate")
    AddLog("Alt+Tab to the game, hover over each icon, press SPACE")
    ShowCalibStep()
}

OnCalibrateSingle(*) {
    if gCalibrating {
        CancelCalibration()
        return
    }

    rowNum := gMacroList.GetNext(0, "F")
    if rowNum < 1 || rowNum > gUnitDefs.Length {
        MsgBox("Select a unit in the Macros tab first.", APP_NAME)
        return
    }

    global gCalibQueue, gCalibIndex, gCalibrating

    gCalibQueue  := [gUnitDefs[rowNum]]
    gCalibIndex  := 1
    gCalibrating := true

    Hotkey("Space",  RecordCalibPoint, "On")
    Hotkey("Escape", CancelCalibHK,    "On")

    AddLog("Calibrating: " . gUnitDefs[rowNum].name)
    ShowCalibStep()
}

ShowCalibStep() {
    unit := gCalibQueue[gCalibIndex]
    tip  := "══════ CALIBRATION MODE ══════`n`n"
        . "  Unit:  " . unit.name . "  (" . unit.cat . ")`n"
        . "  Step " . gCalibIndex . " of " . gCalibQueue.Length . "`n`n"
        . "  → Hover over the  [" . unit.name . "]  icon`n"
        . "     in the game's bottom panel`n`n"
        . "  Press SPACE to record`n"
        . "  Press ESC   to cancel"
    ToolTip(tip, 30, 30)
}

RecordCalibPoint(*) {
    global gCalibIndex, gCalibrating, gGameTitle

    if !gCalibrating
        return

    ; Auto-detect game window title during calibration
    activeTitle := WinGetTitle("A")
    myTitle := APP_NAME . " v" . APP_VERSION
    
    if (activeTitle != "" && activeTitle != myTitle) {
        if !IsGameActive() {
            gGameTitle := activeTitle
            try gMainGui["GameTitle"].Value := gGameTitle
            AddLog("Auto-detected game window: " . gGameTitle)
        }
    } else if !IsGameActive() {
        ToolTip("Switch to the game window first!`nHover over the icon, then press SPACE.", 30, 30)
        return
    }

    MouseGetPos(&x, &y)
    unit := gCalibQueue[gCalibIndex]
    gCoordX[unit.id] := x
    gCoordY[unit.id] := y

    AddLog("Calibrated " . unit.name . " -> X=" . x . "  Y=" . y)
    SoundBeep(1000, 40)

    gCalibIndex++
    if gCalibIndex > gCalibQueue.Length
        FinishCalibration()
    else
        ShowCalibStep()
}

FinishCalibration() {
    global gCalibrating
    gCalibrating := false
    ToolTip()

    try Hotkey("Space",  "Off")
    try Hotkey("Escape", "Off")

    SaveConfig()
    RefreshMacroList()
    UpdateCalibStatus()

    cnt := gCalibQueue.Length
    AddLog("Calibration complete! " . cnt . " unit(s) recorded")
    SoundBeep(800, 80)
    Sleep(100)
    SoundBeep(1000, 80)

    MsgBox("Calibration complete!`n`n"
        . cnt . " unit position(s) recorded and saved.",
        APP_NAME, "Iconi")
}

CancelCalibration() {
    global gCalibrating
    gCalibrating := false
    ToolTip()
    try Hotkey("Space",  "Off")
    try Hotkey("Escape", "Off")
    AddLog("Calibration cancelled")
}

CancelCalibHK(*) {
    CancelCalibration()
}

OnTestClick(*) {
    rowNum := gMacroList.GetNext(0, "F")
    if rowNum < 1 || rowNum > gUnitDefs.Length {
        MsgBox("Select a unit in the Macros tab first.", APP_NAME)
        return
    }

    unit := gUnitDefs[rowNum]
    x := gCoordX[unit.id]
    y := gCoordY[unit.id]

    if (x = 0) && (y = 0) {
        MsgBox(unit.name . " has not been calibrated yet!", APP_NAME, "Icon!")
        return
    }

    res := MsgBox(
        "Test click for  " . unit.name . "  at  X=" . x . "  Y=" . y . "?`n`n"
        . "You have 3 seconds to switch to the game after clicking Yes.",
        APP_NAME, "YesNo Iconi")

    if res = "Yes" {
        MouseGetPos(&origX, &origY)
        Sleep(3000)
        MouseClick("Left", x, y)
        if gReturnMouse
            MouseMove(origX, origY, 0)
        AddLog("Test click: " . unit.name . " at X=" . x . " Y=" . y)
    }
}


; ═══════════════════════════════════════════════════════════════════════════
;  CONFIGURATION PERSISTENCE (INI)
; ═══════════════════════════════════════════════════════════════════════════

LoadConfig() {
    if !FileExist(CONFIG_FILE)
        return

    global gGameTitle, gClickDelay, gReturnMouse, gPlaySound, gPauseKey, gAlwaysOnTop

    gGameTitle   := IniRead(CONFIG_FILE, "General", "GameTitle",   "Stronghold")
    gClickDelay  := SafeInt(IniRead(CONFIG_FILE, "General", "ClickDelay",  "150"), 150)
    gReturnMouse := SafeInt(IniRead(CONFIG_FILE, "General", "ReturnMouse", "1"),   1) ? true : false
    gPlaySound   := SafeInt(IniRead(CONFIG_FILE, "General", "PlaySound",   "1"),   1) ? true : false
    gPauseKey    := IniRead(CONFIG_FILE, "General", "PauseKey",    "F12")
    gAlwaysOnTop := SafeInt(IniRead(CONFIG_FILE, "General", "AlwaysOnTop", "1"),   1) ? true : false

    for unit in gUnitDefs {
        id := unit.id
        gHotkeys[id] := IniRead(CONFIG_FILE, "Hotkeys", id, unit.defKey)
        gBatches[id] := SafeInt(IniRead(CONFIG_FILE, "Batches", id, "1"), 1)
        gEnabled[id] := SafeInt(IniRead(CONFIG_FILE, "Enabled", id, "1"), 1) ? true : false
        gCoordX[id]  := SafeInt(IniRead(CONFIG_FILE, "CoordX",  id, "0"), 0)
        gCoordY[id]  := SafeInt(IniRead(CONFIG_FILE, "CoordY",  id, "0"), 0)
    }
}

SaveConfig() {
    IniWrite(gGameTitle,              CONFIG_FILE, "General", "GameTitle")
    IniWrite(gClickDelay,             CONFIG_FILE, "General", "ClickDelay")
    IniWrite(gReturnMouse ? 1 : 0,    CONFIG_FILE, "General", "ReturnMouse")
    IniWrite(gPlaySound   ? 1 : 0,    CONFIG_FILE, "General", "PlaySound")
    IniWrite(gPauseKey,               CONFIG_FILE, "General", "PauseKey")
    IniWrite(gAlwaysOnTop ? 1 : 0,    CONFIG_FILE, "General", "AlwaysOnTop")

    for unit in gUnitDefs {
        id := unit.id
        IniWrite(gHotkeys[id],            CONFIG_FILE, "Hotkeys", id)
        IniWrite(gBatches[id],             CONFIG_FILE, "Batches", id)
        IniWrite(gEnabled[id] ? 1 : 0,    CONFIG_FILE, "Enabled", id)
        IniWrite(gCoordX[id],              CONFIG_FILE, "CoordX",  id)
        IniWrite(gCoordY[id],              CONFIG_FILE, "CoordY",  id)
    }
}


; ═══════════════════════════════════════════════════════════════════════════
;  UI HELPER FUNCTIONS
; ═══════════════════════════════════════════════════════════════════════════

RefreshMacroList() {
    gMacroList.Delete()
    for unit in gUnitDefs {
        calibrated := ((gCoordX[unit.id] != 0) || (gCoordY[unit.id] != 0))
            ? "Ready" : "Not Set"
        opts := gEnabled[unit.id] ? "Check" : ""
        gMacroList.Add(opts,
            unit.name, unit.cat, gHotkeys[unit.id], gBatches[unit.id], calibrated)
    }
}

UpdateStatus() {
    if !gRunning {
        gStatusText.Value := "STOPPED"
        try gStatusText.SetFont("cRed s12 Bold")
    } else if gPaused {
        gStatusText.Value := "PAUSED"
        try gStatusText.SetFont("cFF8800 s12 Bold")
    } else {
        gStatusText.Value := "RUNNING"
        try gStatusText.SetFont("c008800 s12 Bold")
    }
}

UpdateStats() {
    gStatsText.Value := "Session: " . gTotalProduced . " units produced"
}

UpdateCalibStatus() {
    gCalibStatus.Value := GetCalibrationStatus()
}

GetCalibrationStatus() {
    total      := 0
    calibrated := 0
    for unit in gUnitDefs {
        if gEnabled[unit.id] {
            total++
            if (gCoordX[unit.id] != 0) || (gCoordY[unit.id] != 0)
                calibrated++
        }
    }
    return "Calibration Status:  " . calibrated . " / " . total
        . "  enabled units have positions set"
}

AddLog(msg) {
    timestamp := FormatTime(, "HH:mm:ss")
    entry := "[" . timestamp . "]  " . msg

    if gLogCtrl.Value != ""
        gLogCtrl.Value .= "`n" . entry
    else
        gLogCtrl.Value := entry

    ; Scroll to bottom
    try SendMessage(0x0115, 7, 0, , "ahk_id " . gLogCtrl.Hwnd)
}

ShowTooltip(msg, duration := 2000) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), duration * -1)
}

SafeInt(val, fallback := 0) {
    try return Integer(val)
    return fallback
}


; ═══════════════════════════════════════════════════════════════════════════
;  SYSTEM TRAY MENU
; ═══════════════════════════════════════════════════════════════════════════

SetupTrayMenu() {
    tray := A_TrayMenu
    tray.Delete()
    tray.Add("Show Window", (*) => gMainGui.Show())
    tray.Add("Start Macros", (*) => OnStart())
    tray.Add("Stop Macros",  (*) => OnStop())
    tray.Add()
    tray.Add("Exit", (*) => (SaveConfig(), ExitApp()))
    tray.Default := "Show Window"
}
