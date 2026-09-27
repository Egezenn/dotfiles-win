#Requires AutoHotkey v2.0

!+F3:: MPD.InitAndRandomize()

#HotIf ProcessExist("mpd.exe")
!F1:: MPD.Next()
!F2:: MPD.TogglePlay()
!F3:: MPD.Prev()
!+F1:: MPD.Volume("+5")
!+F2:: MPD.Volume("-5")
!+F4:: MPD.Kill()
#HotIf

class MPD {
    static sock := 0
    static wsaInit := false
    static host := "127.0.0.1"
    static port := 6600
    static exePath := "C:\Users\" . A_UserName . "\bin\mpd.exe"

    static EnsureWSA() {
        if (!this.wsaInit) {
            wsaData := Buffer(408, 0)
            if (DllCall("ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", wsaData, "Int") == 0)
                this.wsaInit := true
        }
        return this.wsaInit
    }

    static Connect() {
        if (this.sock)
            return true

        if (!this.EnsureWSA())
            return false

        s := DllCall("ws2_32\socket", "Int", 2, "Int", 1, "Int", 6, "UPtr")
        if (s == -1 || s == 0xFFFFFFFF || s == 0xFFFFFFFFFFFFFFFF)
            return false

        ; TCP_NODELAY = 1 for lowest latency
        opt := Buffer(4, 0)
        NumPut("UInt", 1, opt)
        DllCall("ws2_32\setsockopt", "UPtr", s, "Int", 6, "Int", 1, "Ptr", opt, "Int", 4)

        ; Socket timeout (1000ms)
        tv := Buffer(4, 0)
        NumPut("UInt", 1000, tv)
        DllCall("ws2_32\setsockopt", "UPtr", s, "Int", 0xFFFF, "Int", 0x1006, "Ptr", tv, "Int", 4)
        DllCall("ws2_32\setsockopt", "UPtr", s, "Int", 0xFFFF, "Int", 0x1005, "Ptr", tv, "Int", 4)

        ; Connect to 127.0.0.1:6600
        sockAddr := Buffer(16, 0)
        NumPut("Short", 2, sockAddr, 0)
        NumPut("UShort", DllCall("ws2_32\htons", "UShort", this.port, "UShort"), sockAddr, 2)
        NumPut("UInt", DllCall("ws2_32\inet_addr", "AStr", this.host, "UInt"), sockAddr, 4)

        if (DllCall("ws2_32\connect", "UPtr", s, "Ptr", sockAddr, "Int", 16, "Int") != 0) {
            DllCall("ws2_32\closesocket", "UPtr", s)
            return false
        }

        this.sock := s
        greeting := this.ReadResponse()
        if (!InStr(greeting, "OK MPD")) {
            this.Disconnect()
            return false
        }

        return true
    }

    static Disconnect() {
        if (this.sock) {
            try DllCall("ws2_32\closesocket", "UPtr", this.sock)
            this.sock := 0
        }
    }

    static ReadResponse() {
        if (!this.sock)
            return ""
        resp := ""
        buf := Buffer(4096, 0)
        while true {
            bytes := DllCall("ws2_32\recv", "UPtr", this.sock, "Ptr", buf, "Int", 4096, "Int", 0, "Int")
            if (bytes <= 0)
                break
            resp .= StrGet(buf, bytes, "UTF-8")
            if (InStr(resp, "OK MPD") || RegExMatch(resp, "(\r?\n|^)(OK|ACK[^\r\n]*)\r?\n$"))
                break
        }
        return resp
    }

    static Send(cmd) {
        if (!this.sock && !this.Connect()) {
            if (!ProcessExist("mpd.exe"))
                this.StartDaemon()
            if (!this.Connect())
                return ""
        }

        raw := cmd . "`n"
        len := StrPut(raw, "UTF-8")
        buf := Buffer(len, 0)
        StrPut(raw, buf, "UTF-8")

        sent := DllCall("ws2_32\send", "UPtr", this.sock, "Ptr", buf, "Int", len - 1, "Int", 0, "Int")
        if (sent <= 0) {
            this.Disconnect()
            if (!this.Connect())
                return ""
            sent := DllCall("ws2_32\send", "UPtr", this.sock, "Ptr", buf, "Int", len - 1, "Int", 0, "Int")
            if (sent <= 0) {
                this.Disconnect()
                return ""
            }
        }

        return this.ReadResponse()
    }

    static StartDaemon() {
        if (!ProcessExist("mpd.exe")) {
            try {
                Run('"' . this.exePath . '"', , "Hide")
                Sleep(300)
            }
        }
    }

    static GetCurrentTrack() {
        resp := this.Send("currentsong")
        artist := "", title := "", file := ""
        if RegExMatch(resp, "`mi)^Artist:\s*(.*?)\r?$", &m)
            artist := m[1]
        if RegExMatch(resp, "`mi)^Title:\s*(.*?)\r?$", &m)
            title := m[1]
        if RegExMatch(resp, "`mi)^file:\s*(.*?)\r?$", &m)
            file := m[1]

        if (artist != "" && title != "")
            return artist . " - " . title
        if (title != "")
            return title
        if (file != "") {
            SplitPath(file, &name)
            return name
        }
        return "No Track"
    }

    static Next() {
        this.Send("next")
        ShowTooltip("MPD: Next`n`n" . this.GetCurrentTrack())
    }

    static Prev() {
        this.Send("previous")
        ShowTooltip("MPD: Previous`n`n" . this.GetCurrentTrack())
    }

    static TogglePlay() {
        this.Send("pause")
        ShowTooltip("MPD: Play / Pause`n`n" . this.GetCurrentTrack())
    }

    static Volume(delta) {
        this.Send("volume " . delta)
        volStr := ""
        if RegExMatch(this.Send("status"), "`mi)^volume:\s*(\d+)", &m)
            volStr := ": " . m[1] . "%"
        else
            volStr := " (" . delta . ")"
        ShowTooltip("MPD: Volume" . volStr . "`n`n" . this.GetCurrentTrack())
    }

    static InitAndRandomize() {
        this.Send('command_list_begin`nclear`nadd ""`nrandom 1`nshuffle`nplay`ncommand_list_end')
        ShowTooltip("MPD: Initialized & Randomized`n`n" . this.GetCurrentTrack())
    }

    static Kill() {
        if (ProcessExist("mpd.exe")) {
            this.Send("kill")
            this.Disconnect()
            if (ProcessExist("mpd.exe"))
                try ProcessClose("mpd.exe")
            ShowTooltip("MPD: Killed")
        }
    }
}