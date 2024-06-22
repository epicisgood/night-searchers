#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_ScriptDir%\lib\json.ahk
#Include %A_ScriptDir%\joinserver.ahk

SetWorkingDir A_ScriptDir
CoordMode "Pixel", "Screen"

global GameUrl := ""


GetRobloxClientPos(hwnd?) {
    global windowX, windowY, windowWidth, windowHeight
    if !IsSet(hwnd)
        hwnd := GetRobloxHWND()

    try
        WinGetClientPos &windowX, &windowY, &windowWidth, &windowHeight, "ahk_id " hwnd
    catch TargetError
        return windowX := windowY := windowWidth := windowHeight := 0
    else
        return 1
}

GetRobloxHWND() {
    if (hwnd := WinExist("Roblox ahk_exe RobloxPlayerBeta.exe"))
        return hwnd
    else if (WinExist("Roblox ahk_exe ApplicationFrameHost.exe"))
    {
        try
            hwnd := ControlGetHwnd("ApplicationFrameInputSinkWindow1")
        catch TargetError
            hwnd := 0
        return hwnd
    }
    else
        return 0
}

ActivateRoblox() {
    try
        WinActivate "Roblox"
    catch
        return 0
    else
        return 1
}

; Read settings from settings.ini
url := IniRead("settings.ini", "Settings", "url")
discordID := IniRead("settings.ini", "Settings", "discordID")
RobloxUsername := IniRead("settings.ini", "Settings", "RobloxUsername")


postdata :=
    (
        '
{
"content": "<@' discordID '> ' RobloxUsername ' FOUND A Night time Server !!!",
"embeds": [{
"title": "Vicious bee detected!!",
"description": "{GameUrl}", 
"color": "14052794"
}]
}
'
    )


    

DoubleClick(x, y) {
    MouseClick("left", x, y)
    Sleep 50
    MouseClick("left", x, y)
}


ZoomOut() {
    Loop 5 {
        Send "{o down}"
        Sleep 100
        Send "{o up}"
    }
}


CheckForNight() {
    hwnd := GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    centerX := windowX + (windowWidth // 2 - 200)
    MouseMove centerX, 100
    color := PixelGetColor(centerX, 150)
    return color
}

DetectLoading(loadingColor, timeout) {
    startTime := A_TickCount
    Loop {
        color := PixelGetColor(458, 151)
        if (color = loadingColor)
            break
        if (A_TickCount - startTime >= timeout)
            return false ; Timeout reached
        Sleep 100
    }

    startTime := A_TickCount
    Loop {
        color := PixelGetColor(458, 151)
        if (color != loadingColor)
            break
        Sleep 100
    }

    return true ; Loading completed within the timeout
}


MyGui := Gui()
MyGui.AddText("x10 y40 w80 h20", "Webhook URL:")
URLEdit := MyGui.AddEdit("x100 y40 w300 h20", url)
MyGui.AddText("x10 y70 w80 h20", "Discord ID:")
DiscordIDEdit := MyGui.AddEdit("x100 y70 w300 h20", discordID)
MyGui.AddText("x10 y100 w80 h35", "Roblox Username:")
RobloxUsernameEdit := MyGui.AddEdit("x100 y100 w300 h20", RobloxUsername)
button := MyGui.AddButton("Default x100 y130 w100 h30", "Save")
button.OnEvent('click', SaveSettings)
MyGui.Show("w420 h200")

SaveSettings(*) {
    MyGui.Submit("NoHide")
    IniWrite(URLEdit.Value, "settings.ini", "Settings", "url")
    IniWrite(DiscordIDEdit.Value, "settings.ini", "Settings", "discordID")
    IniWrite(RobloxUsernameEdit.Value, "settings.ini", "Settings", "RobloxUsername")
    url := URLEdit.Value
    discordID := DiscordIDEdit.Value
    RobloxUsername := RobloxUsernameEdit.Value
    MsgBox "Settings saved!"
}

F1:: {
    Loop {
        RunWait("taskkill /F /IM RobloxPlayerBeta.exe", , "Hide")
        GameUrl := joinrandomserver()
        if (DetectLoading(0x2257A8, 40000)) {
            Sleep 3000
        }
        DoubleClick(458, 63)
        Send("{PgDn}")
        Send("{PgDn}")
        ZoomOut()
        nightColor := CheckForNight()
        if (nightColor == 0x000000 || nightColor == 0x404040) {
            postdatasend := StrReplace(postdata, "{GameUrl}", GameUrl)
            WebRequest := ComObject("WinHttp.WinHttpRequest.5.1")
            WebRequest.Open("POST", url, false)
            WebRequest.SetRequestHeader("Content-Type", "application/json")
            WebRequest.Send(postdatasend)
            Sleep 5000
        }
        else {
            Sleep 100
        }
    }
}