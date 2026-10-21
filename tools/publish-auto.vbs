' Runs publish.ps1 -Auto without showing a window (started every few minutes by the scheduled task).
Set sh = CreateObject("WScript.Shell")
dir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & dir & "publish.ps1"" -Auto", 0, False
