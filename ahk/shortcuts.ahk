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

; Win + s: Search files via Everything 1.5a (sorted by Date Modified)
#s:: {
    if WinActive("ahk_class EVERYTHING") || WinActive("ahk_exe Everything.exe") {
        WinMinimize("A")
    } else {
        Run('"C:\Program Files\Everything 1.5a\Everything.exe" -sort "Date Modified" -sort-descending -s ""')
    }
}

#x:: {
    Run("wt.exe")
    WinWait("ahk_exe WindowsTerminal.exe",,5)
    WinActivate("ahk_exe WindowsTerminal.exe")
}

; Win + r: App launcher via Everything 1.5a (.lnk shortcuts only, sorted by Run Count)
#r:: {
    if WinActive("ahk_class EVERYTHING") || WinActive("ahk_exe Everything.exe") {
        WinMinimize("A")
    } else {
        Run('"C:\Program Files\Everything 1.5a\Everything.exe" -sort "Run Count" -sort-descending -s "ext:lnk "')
    }
}

; Minimize Everything when Escape is pressed while it's active
#HotIf WinActive("ahk_class EVERYTHING") || WinActive("ahk_exe Everything.exe")
Esc:: WinMinimize("A")
#HotIf