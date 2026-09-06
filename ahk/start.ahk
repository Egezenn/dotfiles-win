#Requires AutoHotkey v2.0
#SingleInstance Force

ProcessSetPriority("Realtime")

SetWorkingDir(A_ScriptDir)
SetCapsLockState("AlwaysOff")
SetNumLockState("AlwaysOff")
SetScrollLockState("AlwaysOff")
CoordMode("Mouse", "Screen")
CoordMode("Pixel", "Screen")

A_MenuMaskKey := "vkE8"

#Include "utils.ahk"
#Include "sswm.ahk"
#Include "shortcuts.ahk"
#Include "oddities.ahk"

try WinSetTransparent 0, "ahk_class Shell_TrayWnd"
try WinSetTransparent 0, "ahk_class Shell_SecondaryTrayWnd"

<^>!CapsLock:: Reload