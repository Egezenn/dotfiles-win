#Requires AutoHotkey v2.0

; Suppress bare Windows key (Start menu won't appear, Win hotkeys still work)
~LWin::Send("{Blind}{vkE8}")
~RWin::Send("{Blind}{vkE8}")

; Win + c: Close active window
#c:: {
    try {
        hwnd := WinExist("A")
        if (!hwnd)
            return
        cls := WinGetClass(hwnd)
        if (cls == "Shell_TrayWnd" || cls == "Progman" || cls == "WorkerW")
            return
        WinClose(hwnd)
    }
}

; Win + Shift + c: Kill active/focused process
#+c:: {
    try {
        hwnd := WinExist("A")
        if (!hwnd)
            return
        cls := WinGetClass(hwnd)
        if (cls == "Shell_TrayWnd" || cls == "Progman" || cls == "WorkerW")
            return
        pid := WinGetPID(hwnd)
        if (pid) {
            if !ProcessClose(pid)
                Run('taskkill.exe /F /PID ' pid, , 'Hide')
        }
    }
}

#w:: LaunchApp("C:\Users\" . A_UserName . "\AppData\Local\Programs\VSCodium\VSCodium.exe")
#x:: LaunchApp("wt.exe", { winTitle: "WindowsTerminal.exe" })
#!x:: LaunchApp("wt.exe -p PowerShell", { winTitle: "WindowsTerminal.exe" })

#+x:: A_Clipboard := ""
#+r:: FileRecycleEmpty

#s:: Run('"C:\Program Files\Everything 1.5a\Everything.exe" -sort "Date Modified" -sort-descending -s ""')
#r:: Run('"C:\Program Files\Everything 1.5a\Everything.exe" -sort "Run Count" -sort-descending -s "ext:lnk "')

#HotIf WinActive("ahk_class EVERYTHING") || WinActive("ahk_exe Everything.exe")
Esc:: WinMinimize("A")
#s:: WinMinimize("A")
#r:: WinMinimize("A")
#HotIf