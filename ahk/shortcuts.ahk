#Requires AutoHotkey v2.0

#Include "utils.ahk"

~LWin:: Send("{Blind}{vkE8}")
~RWin:: Send("{Blind}{vkE8}")

#c:: CloseActiveWindow()
#+c:: KillActiveProcess()

ScrollLock:: RevealTaskbar()

#^WheelUp:: ZoomIn()
#^WheelDown:: ZoomOut()

#WheelUp:: AdjustWindowTransparency(25)
#WheelDown:: AdjustWindowTransparency(-25)

#w:: LaunchApp(EnvGet("LOCALAPPDATA") . "\Programs\VSCodium\VSCodium.exe")
#+w:: LaunchApp(EnvGet("LOCALAPPDATA") . "\Programs\VSCodium\VSCodium.exe", { clip: true })
#x:: LaunchApp("wt.exe", { winTitle: "WindowsTerminal.exe" })
#!x:: LaunchApp("wt.exe -p PowerShell", { winTitle: "WindowsTerminal.exe" })

#+x:: A_Clipboard := ""
#+r:: FileRecycleEmpty

#e:: LaunchApp("C:\Program Files\Explorer++\Explorer++.exe")
#+e:: LaunchApp("C:\Program Files\Explorer++\Explorer++.exe", { clip: true })
#s:: Run('"C:\Program Files\Everything 1.5a\Everything.exe" -sort "Date Modified" -sort-descending -s ""')
#r:: Run('"C:\Program Files\Everything 1.5a\Everything.exe" -sort "Run Count" -sort-descending -s "ext:lnk "')

#HotIf WinActive("ahk_class EVERYTHING") || WinActive("ahk_exe Everything.exe") || WinActive("ahk_exe SystemInformer.exe")
Esc:: WinClose("A")
#HotIf

#HotIf WinActive("ahk_class EVERYTHING") || WinActive("ahk_exe Everything.exe")
#s:: WinMinimize("A")
#r:: WinMinimize("A")
#HotIf

#HotIf WinActive("ahk_exe Explorer++.exe")
#Enter:: {
    dir := ""
    try {
        txt := ControlGetText("Edit1", "A")
        if (txt != "" && DirExist(txt))
            dir := txt
    }
    if (dir = "") {
        try {
            if RegExMatch(WinGetTitle("A"), "([a-zA-Z]:\\[^-\r\n]+)", &m) && DirExist(Trim(m[1]))
                dir := Trim(m[1])
        }
    }
    LaunchApp(dir != "" ? 'wt.exe -d "' . dir . '"' : "wt.exe", { winTitle: "WindowsTerminal.exe" })
}
#HotIf