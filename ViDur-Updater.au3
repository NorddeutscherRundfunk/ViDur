#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Icons\update-prog.ico
#AutoIt3Wrapper_Res_Comment=Erneuert ViDur. Ziel ist der Shortcut auf dem Desktop.
#AutoIt3Wrapper_Res_Description=Erneuert ViDur. Ziel ist der Shortcut auf dem Desktop.
#AutoIt3Wrapper_Res_Fileversion=1.0.0.4
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_LegalCopyright=Conrad Zelck
#AutoIt3Wrapper_Res_Language=1031
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <TrayCox.au3>

#cs ; ######################################## TESTEN
If @UserName "vpn" Then
	#RequireAdmin
EndIf
#ce ; ######################################## TESTEN

If ProcessExists("ViDur.exe") > 0 Then Exit MsgBox($MB_TOPMOST, "Achtung", "ViDur muss erst beendet werden.")
FileChangeDir(@DesktopDir) ; setzt WorkingDir auf Desktop, wo der Link immer liegen soll
Local $sViDurLinkAll = FileFindFirstFile("vidur*.lnk")
Local $sViDurLink = FileFindNextFile($sViDurLinkAll)
If @error Then
	MsgBox(0, 'Fehler', "Es existiert kein Link auf dem Desktop zu ViDur.")
	Exit
EndIf
FileClose($sViDurLinkAll)
Local $sViDurPathLink = FileGetLongName($sViDurLink, 1)
Local $aViDurPathLinkDetails = FileGetShortcut($sViDurPathLink)
If Not @error Then
	Local $sViDurDestPath = $aViDurPathLinkDetails[0]
Else
	MsgBox(0, 'Fehler', "Kein Ziel von ViDur auf dem Rechner gefunden.")
	Exit
EndIf
Local $sViDurDestFolderDelim = StringInStr($sViDurDestPath, "\", 0, -1)
Local $sViDurDestFolder = StringLeft($sViDurDestPath, $sViDurDestFolderDelim)
Local $sVersDest = FileGetVersion($sViDurDestPath)
Local $sVersOrig = FileGetVersion(@ScriptDir & "\ViDur.exe")
If $sVersOrig = "0.0.0.0" Then
	MsgBox(0, 'Fehler', "Es befindet sich kein ViDur im selben Verzeichnis wie der Updater.")
	ShellExecute(@ScriptDir)
	Exit
EndIf
If $sVersDest = "0.0.0.0" Then ; ist auch das Ergebnis, wenn das File nicht vorhanden ist
	ShellExecute($sViDurDestFolder)
	Local $msg = MsgBox(4, 'Achtung', "Am Zielort ist kein ViDur vorhanden." & @CRLF & "Soll es dort hin kopiert werden?")
	Switch $msg
		Case 6 ; Ja
			FileCopy(@ScriptDir & "\ViDur.exe", $sViDurDestPath, 1)
			If @error Then
				MsgBox(0, 'Fehler', "ViDur konnte nicht überschrieben werden.")
				ShellExecute($sViDurDestFolder)
				Exit
			EndIf
		Case 7 ; Nein
			Exit
	EndSwitch
	ElseIf 	_StringCompareVersions($sVersOrig, $sVersDest) = 0 Then
	If @error Then
		MsgBox(0, 'Fehler', "Beide Versionen lassen sich nicht vergleichen." & @CRLF & "Der Updater wird beendet.")
		Exit
	EndIf
	MsgBox(0, 'Achtung', "Beide Versionen von ViDur  sind identisch: " & $sVersDest)
	ShellExecute($sViDurDestFolder)
	Exit
ElseIf _StringCompareVersions($sVersOrig, $sVersDest) = -1 Then
	MsgBox(0, 'Achtung', "ViDur auf dem Ziel mit Version " & @TAB & $sVersDest & @CRLF & "ist höher als die Quelle" & @TAB & $sVersOrig & @CRLF & "und wird somit NICHT upgedatet.")
	ShellExecute($sViDurDestFolder)
	Exit
Else
	FileCopy(@ScriptDir & "\ViDur.exe", $sViDurDestPath, 1)
	If @error Then
		MsgBox(0, 'Fehler', "ViDur konnte nicht überschrieben werden.")
		ShellExecute($sViDurDestFolder)
		Exit
	EndIf
EndIf
Local $sVersSource = FileGetVersion($sViDurDestPath)
MsgBox(0, 'Ergebnis', "ViDur wurde von Version " & @TAB & $sVersDest & @CRLF & @TAB & "     auf Version " & @TAB & $sVersSource & @CRLF & "upgedatet.")
ShellExecute($sViDurDestFolder)
Exit

Func _StringCompareVersions($s_Version1, $s_Version2 = "0.0.0.0") ; Return Value(s):  0 - Strings are the same (if @error=0), -1 - First string is (<) older than second string, 1 - First string is (>) newer than second string
; Confirm strings are of correct basic format. Set @error to 1,2 or 3 if not.
    SetError((StringIsDigit(StringReplace($s_Version1, ".", ""))=0) + 2 * (StringIsDigit(StringReplace($s_Version2, ".", ""))=0))
    If @error>0 Then Return 0; Ought to Return something!
    Local $i_Index, $i_Result, $ai_Version1, $ai_Version2
; Split into arrays by the "." separator
    $ai_Version1 = StringSplit($s_Version1, ".")
    $ai_Version2 = StringSplit($s_Version2, ".")
    $i_Result = 0; Assume strings are equal
; Ensure strings are of the same (correct) format:
;  Short strings are padded with 0s. Extraneous components of long strings are ignored. Values are Int.
    If $ai_Version1[0] <> 4 Then ReDim $ai_Version1[5]
    For $i_Index = 1 To 4
        $ai_Version1[$i_Index] = Int($ai_Version1[$i_Index])
    Next
    If $ai_Version2[0] <> 4 Then ReDim $ai_Version2[5]
    For $i_Index = 1 To 4
        $ai_Version2[$i_Index] = Int($ai_Version2[$i_Index])
    Next
    For $i_Index = 1 To 4
        If $ai_Version1[$i_Index] < $ai_Version2[$i_Index] Then; Version1 older than Version2
            $i_Result = -1
        ElseIf $ai_Version1[$i_Index] > $ai_Version2[$i_Index] Then; Version1 newer than Version2
            $i_Result = 1
        EndIf
   ; Bail-out if they're not equal
        If $i_Result <> 0 Then ExitLoop
    Next
    Return $i_Result
EndFunc ;==>_StringCompareVersions