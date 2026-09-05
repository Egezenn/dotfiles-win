#Requires AutoHotkey v2.0
#SingleInstance Force

ProcessSetPriority("Realtime")

SetWorkingDir(A_ScriptDir)
SetCapsLockState("AlwaysOff")
SetNumLockState("AlwaysOff")
SetScrollLockState("AlwaysOff")
A_MenuMaskKey := "vkE8"

#Include "sswm.ahk"
#Include "shortcuts.ahk"

try WinSetTransparent 63, "ahk_class Shell_TrayWnd"

<^>!CapsLock:: Reload
