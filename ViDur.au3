#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Icons\time.ico
#AutoIt3Wrapper_UseX64=y ; necessary because the mediainfo.dll is for 64bit only
#AutoIt3Wrapper_Res_Comment=Looks for video and audio duration and adds them together.
#AutoIt3Wrapper_Res_Description=Looks for video and audio duration and adds them together.
#AutoIt3Wrapper_Res_Fileversion=1.1.0.24
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_LegalCopyright=Conrad Zelck
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_Language=1031
#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <_SendTo.au3>
#include <Array.au3>
#include <ButtonConstants.au3>
#include <File.au3>
#include <FileConstants.au3>
#include <GUIConstantsEx.au3>
#include <TrayCox.au3>

; Paramter --debug programmieren?

$g_iParamterHelpStartIndex = _ArrayAdd($g_aParameterHelpfile, "--noexclude;complete scan and there are no files excluded", 0, ";")
_ArrayAdd($g_aParameterHelpfile, "--includelowres;if you do --noexclude you can exclude all lowres files anyway", 0, ";")
_ShowHelp($g_iParamterHelpStartIndex, 1) ; diese Zeile erst nach Eintragung aller zusätzlichen Parameter schreiben - 1 beendet das Hauptscript nach dem Ausgeben aller Parameter


If @Compiled Then
	_SendTo_Install() ; make a shortcut in shell:sendto
EndIf

Opt("GuiCoordMode", 0) ;relative position to the start of the last control with "-1"
Local $sVersion = FileGetVersion(@ScriptFullPath)
Global $g_iCounterNotProvedFiles = 0
Global $g_iCounterSkippedFiles = 0
Global $g_sNotProvedFiles
Global $g_sSkippedFiles
Global $g_hDll
Global $g_hHandleDll

Local $bNoExclude = 0
Local $sLowResFiles = "*.mpl;*.lrv;*.xml"
Local $sExcludeFiles = "*.DS_Store;._*;Thumbs.db;*.lnk;*.thm;*.jpg;*.jpeg;*.tif;*.tiff;*.tga;*.png;*.psd;*.exe;*.zip;*.txt;*.rtf;*.csv;*.edl;*.ini;*.pdf;*.arr;*.xls;*.xlsx;*.doc;*.docx;*.pptx;*.aep;*.srt;*.prproj;*.xmp;*.aaf;*.omf;*.html;*.part"
If StringInStr($cmdlineraw, "--noexclude") Then
	$bNoExclude = 1
	If StringInStr($cmdlineraw, "--includelowres") Then
		$sExcludeFiles = $sLowResFiles
		ConsoleWrite("--noexclude" & @CRLF)
		ConsoleWrite("--includelowres" & @CRLF)
	Else
		$sExcludeFiles = ""
		ConsoleWrite("--noexclude" & @CRLF)
	EndIf
Else
	$sExcludeFiles &= $sLowResFiles
EndIf

FileSetAttrib ( @ScriptDir & "\ViDur Release Notes.txt", "-RA") ; prepares for deleting
FileInstall("H:\_Conrad lokal\Downloads\AutoIt3\_COX\ReleaseNotes\ViDur Release Notes.txt",@ScriptDir & "\ViDur Release Notes.txt",1) ; rewrites release notes
FileSetAttrib ( @ScriptDir & "\ViDur Release Notes.txt", "+R")

Local $aCmdLineCopy = $CmdLine
Local $sAttrib
If $CmdLine[0] > 0 Then
	For $i = $CmdLine[0] To 1 Step - 1
		$sAttrib = FileGetAttrib($CmdLine[$i])
		If $sAttrib = "" Then ; all parameter not having an attribute are deleted (files and directories stay)
			_ArrayDelete($aCmdLineCopy, $i)
		EndIf
	Next
	$aCmdLineCopy[0] = UBound($aCmdLineCopy) - 1
EndIf

Local $sChoosenMedia
Local $aOneFolderFileList
Local $aFileList[0]
If $aCmdLineCopy[0] > 0 Then ; if already Files exist
	$sChoosenMedia = _ArrayToString($aCmdLineCopy," | ")
	For $i = 1 to $aCmdLineCopy[0]
		$sAttrib = FileGetAttrib($aCmdLineCopy[$i])
		If StringInStr($sAttrib, "D") Then
			$aOneFolderFileList = _FileListToArrayRec($aCmdLineCopy[$i], "*.*|" & $sExcludeFiles, $FLTAR_FILES + $FLTAR_NOSYSTEM + $FLTAR_NOLINK, $FLTAR_RECUR, $FLTAR_SORT, $FLTAR_FULLPATH)
			_ArrayDelete($aOneFolderFileList, 0) ; delete Index
			_ArrayAdd($aFileList, $aOneFolderFileList)
		Else
			_ArrayAdd($aFileList, $aCmdLineCopy[$i])
		EndIf
	Next
	_ArrayInsert($aFileList, 0, UBound($aFileList))
Else ; no file in $CmdLine
	Local $hGUI = GUICreate("ViDur " & $sVersion & " - Auswahl",258,63)
	GUISetFont(10)
	GUICtrlCreateButton ("Ordner auswählen",10,20,-1,-1,$BS_DEFPUSHBUTTON)
	GUICtrlCreateButton ("Dateien auswählen",121,-1)
	GUISetState()
	Local $msg
	While 1
        $msg = GUIGetMsg()
        If $msg = $GUI_EVENT_CLOSE Then _Beenden() ; defined at TrayCox.au3
		If $msg = 3 Then ExitLoop
		If $msg = 4 Then ExitLoop
	WEnd
	GUIDelete()
	Switch $msg
		Case 3 ; choose folder
			$sChoosenMedia = FileSelectFolder ( "ViDur " & $sVersion & " - Ordner aussuchen", "")
			If @error Then
				MsgBox(262144,"ViDur " & $sVersion & " - Abbruch","Keine Datei(en) ausgewählt")
				Exit
			EndIf
			$aFileList = _FileListToArrayRec($sChoosenMedia, "*.*|" & $sExcludeFiles, $FLTAR_FILES + $FLTAR_NOSYSTEM + $FLTAR_NOLINK, $FLTAR_RECUR, $FLTAR_SORT, $FLTAR_FULLPATH)
			If @error Then
				MsgBox(262144,"ViDur " & $sVersion & " - Abbruch","Der gewählte Ordner enthält keine Datei(en)")
				Exit
			EndIf
		Case 4 ; choose files
			$sChoosenMedia = FileOpenDialog("ViDur " & $sVersion,"", "Alle (*.*)","4")
			If @error Then
				MsgBox(262144,"ViDur " & $sVersion & " - Abbruch","Keine Datei(en) ausgewählt")
				Exit
			EndIf
			$aFileList = StringSplit($sChoosenMedia, "|")
			If $aFileList[0] > 1 Then
				For $i = 2 To $aFileList[0]
					$aFileList[$i] = $aFileList[1] & "\" & $aFileList[$i]
				Next
				_ArrayDelete($aFileList, 1)
				$aFileList[0] = UBound($aFileList) - 1
			EndIf
	EndSwitch
EndIf

Opt("GuiOnEventMode", 1)
Local $iWidthLabel = 400
$hGUI = GUICreate("ViDur " & $sVersion & " - Scan",$iWidthLabel + 40,150)
GUISetFont(10)
GUISetOnEvent($GUI_EVENT_CLOSE, "_Beenden") ; defined at TrayCox.au3
GUICtrlCreateLabel("Dateien werden untersucht:", 20, 20, $iWidthLabel)
Local $hProgress = GUICtrlCreateProgress(-1, 25, $iWidthLabel)
Local $sLabelFile = GUICtrlCreateLabel(".", -1, 32, $iWidthLabel, 80) ; label has to have some text
GUICtrlSetFont(-1,9)
GUISetState()
Local $hTimerStart = TimerInit()
If UBound($aFileList) > 0 Then
	Local $iOnePercentOfFileCount = 100 / ($aFileList[0] - 1)
	Local $iActualPercentOfDoneFiles = $iOnePercentOfFileCount
	If Not FileExists (@ScriptDir & "\MediaInfo.dll") Then
		FileInstall("H:\_Conrad lokal\Downloads\AutoIt3\_COX\MediaInfoDLL\MediaInfo.dll",@ScriptDir & "\MediaInfo.dll")
		FileSetAttrib(@ScriptDir & "\MediaInfo.dll", "+H")
	EndIf
    $g_hDll = DllOpen(@ScriptDir & "\MediaInfo.dll")
	$g_hHandleDll = DllCall($g_hDll, "ptr", "MediaInfo_New" )
	Local $bRecycle, $bSysVol, $bLowResDJIDrohne
	Local $aInfoArray
	Local $sInfoDuration, $sInfoBitRate
	Local $bDurationProved
	Local $iDurationGesamt = 0, $iAnzahlGesamt = 0
	For $i = 1 To $aFileList[0]
		GUICtrlSetData($hProgress,$iActualPercentOfDoneFiles)
		$iActualPercentOfDoneFiles += $iOnePercentOfFileCount
		$bRecycle = StringInStr($aFileList[$i],"recycle",0,1,1,12) ; keep hidden trash folder out
		$bSysVol = StringInStr($aFileList[$i],"system volume",0,1,1,17) ; keep hidden system volume log out
		If $bNoExclude = 0 Then
			$bLowResDJIDrohne = StringRegExp($aFileList[$i],"(?im).*\\MISC\\THM\\[0-9]*\\DJI.*MOV$", $STR_REGEXPMATCH) ; der ausgewiesene Pfad zum DJI-LowRes als movs
		EndIf
		If $bRecycle = 0 And $bSysVol = 0 And $bLowResDJIDrohne = 0 Then
			GUICtrlSetData($sLabelFile, _WordWrapTextForLabel($aFileList[$i], 59))
			$aInfoArray = _CallMediaInfo ($aFileList[$i])
			$sInfoDuration = $aInfoArray[0]
			$sInfoBitRate = $aInfoArray[1]
			$bDurationProved = ""
			If $sInfoDuration = "" Then
				; do not prove duration
			ElseIf $sInfoBitRate = "" Then ; can't read bitrate
				$bDurationProved = 2 ;  so marked it later will count in "not proved"-files and duration is written in logfile
			Else
				$bDurationProved = _ProveDuration($sInfoDuration, $aFileList[$i], $sInfoBitRate)
			EndIf
			If $bDurationProved = 2 Then
				_ProveDuration(1, $aFileList[$i], -1) ; bitrate -1 marks files w/o bitrate, so they can't proved but written in logfile
			EndIf
			If IsInt($bDurationProved) Then ConsoleWrite("DurationProved: " & $bDurationProved & @CRLF)
			If $sInfoDuration <> "" And $bDurationProved > 0 Then
				$iDurationGesamt += $sInfoDuration
				$iAnzahlGesamt += 1
			Else
				$sAttrib = FileGetAttrib($aFileList[$i])
				If Not StringInStr($sAttrib,"H") Then ; if file is not hidden
					$g_sSkippedFiles &= @CRLF & $aFileList[$i]
					$g_iCounterSkippedFiles += 1
				EndIf
			EndIf
		EndIf
	Next
	DllCall($g_hDll, "none", "MediaInfo_Delete", "ptr", $g_hHandleDll[0]) ; Delete Handle
	DllClose($g_hDll)
	GUIDelete()
	$sChoosenMedia = StringReplace($sChoosenMedia, " | ", @CRLF)
	$sChoosenMedia = StringReplace($sChoosenMedia, "|", @CRLF)
	$sChoosenMedia = "Auswahl:" & @CRLF & $sChoosenMedia
	Local $sLogMessage = "ViDur " & $sVersion & " - Ergebnis" & @CRLF & "Anzahl der Videos + Töne: " & @TAB & $iAnzahlGesamt & @CRLF & "Gesamtlänge der Videos + Töne: " & @TAB & _Zeit($iDurationGesamt) & @CRLF & @CRLF
	$sLogMessage &=	$sChoosenMedia & @CRLF & _LogMessageSkippedFiles() & _LogMessageProveDuration() & @CRLF & @CRLF & "Dauer der Pr" & Chr(0xFC) & "fung: " & _Zeit(TimerDiff($hTimerStart), True)
	ClipPut(StringReplace($sLogMessage, ChrW(8239), " ")) ; ersetzt ChrW(8239) - schmales Leerzeichen - mit normalem Leerzeichen für den Zwischenspeicher
	Local $sMessageBoxMessage = "Anzahl der Videos + Töne: " & @TAB & @TAB & $iAnzahlGesamt & @CRLF & "Gesamtlänge der Videos + Töne: " & @TAB & _Zeit($iDurationGesamt) & @CRLF & @CRLF & "Dateien ohne Angabe: " & @TAB & @TAB & $g_iCounterSkippedFiles & @CRLF & @CRLF
	$sMessageBoxMessage &= "Händisch zu prüfende Files: " & @TAB & @TAB & $g_iCounterNotProvedFiles & @CRLF & @CRLF & "Genaue Angaben sind im Windows-Zwischenspeicher zu finden." & @CRLF
	$sMessageBoxMessage &= "Dauer der Pr" & Chr(0xFC) & "fung: " & _Zeit(TimerDiff($hTimerStart), True) & @CRLF &  @CRLF & Chr(169) & " Conrad Zelck -6675"
	If @UserName = "zelckc" Then Beep(500, 150)
	MsgBox (262144,"ViDur " & $sVersion & " - Ergebnis", $sMessageBoxMessage)
	Local $hLog = FileOpen(@ScriptDir & "\ViDur-Ergebnis.txt", 2)
	_FileWriteLog($hLog, @CRLF & $sLogMessage)
	FileClose($hLog)
	If $g_iCounterNotProvedFiles > 0 Or $g_iCounterSkippedFiles > 0 Then
		ShellExecute(@ScriptDir & "\ViDur-Ergebnis.txt")
	EndIf
Else
	MsgBox(262144,"ViDur " & $sVersion & " - Abbruch","Keine gültigen Datei(en) gefunden")
EndIf
FileDelete(@ScriptDir & "\MediaInfo.dll")
Exit
; ###############################################################################################
#region - Func
Func _CallMediaInfo ( $_MediaFilePath ) ; erstellt ein komplettes Array der MediaInfoDaten
	Local $aResult[2]
	DllCall ( $g_hDll, "int", "MediaInfo_Open", "ptr", $g_hHandleDll[0], "wstr", $_MediaFilePath )
	Local $sDuration = DllCall($g_hDll, "wstr", "MediaInfo_Get", "ptr", $g_hHandleDll[0], "int", 0, "int", 0, "wstr", "Duration", "int", 1, "int", 0)
	$aResult[0] = $sDuration[0]
	Local $sOverallBitRate = DllCall($g_hDll, "wstr", "MediaInfo_Get", "ptr", $g_hHandleDll[0], "int", 0, "int", 0, "wstr", "OverallBitRate", "int", 1, "int", 0)
    $aResult[1] = $sOverallBitRate[0]
	Return $aResult
EndFunc

Func _ProveDuration($iDurationReadout, $iFile, $iBitRate)
	If StringRight($iFile, 3) = "mp3" Then Return 1 ; mp3 often include cover pictures that will exceed filesize enourmous so no proof
	$iDurationReadout = Int($iDurationReadout)
	If $iBitRate = -1 Then ; that is the mark for "no bitrate readable"
		$g_sNotProvedFiles &= @CRLF & "(2) " & _Zeit($iDurationReadout) & @TAB & $iFile
		$g_iCounterNotProvedFiles += 1
		Return 1 ; do measure, too
	EndIf
	$iBitRate = Int($iBitRate)
	ConsoleWrite("DurationReadOut: " & $iDurationReadout & "   " & @TAB & "BitRate: " & $iBitRate & @TAB & "File: " & $iFile & @CRLF)
	Local $iFileSize = FileGetSize($iFile)
	Local $iDurationReadoutOnePercent = Round($iDurationReadout / 100) ; 1% of the read out duration
	Local $iDurationChecked = $iFileSize * 8 / $iBitRate * 1000 ;  second duration from filesize and bitrate
	$iDurationChecked = Int($iDurationChecked)
	ConsoleWrite("DurationChecked: " & $iDurationChecked & @CRLF)
	Local $iDifference = Round(Abs($iDurationReadout - $iDurationChecked)) ; difference between both durations
	ConsoleWrite("Difference: " & $iDifference & @CRLF)
	If $iDifference > $iDurationReadoutOnePercent Then ; is difference more that 1% of read duration
		$g_sNotProvedFiles &= @CRLF & "(1) " & _Zeit($iDurationReadout) & @TAB & $iFile
		$g_iCounterNotProvedFiles += 1
		Return 0 ; failure more than 1%
	EndIf
	Return 1
EndFunc

Func _LogMessageSkippedFiles()
	Local $sMsg
	If $g_iCounterSkippedFiles > 0 Then
		$sMsg = @CRLF & $g_iCounterSkippedFiles & " ignorierte(s) File(s):" & $g_sSkippedFiles & @CRLF
		Return $sMsg
	EndIf
	Return ""
EndFunc

Func _LogMessageProveDuration()
	Local $sMsg
	If $g_iCounterNotProvedFiles > 0 Then
		$sMsg = @CRLF & "davon " & $g_iCounterNotProvedFiles & " händisch zu prüfende(s) File(s):" & @CRLF & "(1) - ausgelesene und errechnete Länge differiert > 1% - File wird ignoriert" & @CRLF
		$sMsg &= "(2) - File konnte nicht gegengeprüft werden, wird aber zur Gesamtsumme addiert" & $g_sNotProvedFiles
		Return $sMsg
	EndIf
	Return ""
EndFunc

Func _Zeit($iMs, $bComfortView = False) ; from ms to a format: "12h 36m 56s 13f" (with special space between - ChrW(8239))
	Local $sReturn
    $iMs = Int($iMs)
    Local $iFrames, $iMSec, $iSec, $iMin, $iHour, $sSign
    If $iMs < 0 Then
        $iMs = Abs($iMs)
        $sSign = '-'
    EndIf
	$iMSec = StringRight($iMs, 3)
	$iFrames = $iMSec / 40
    $iSec = $iMs / 1000
    $iMin = $iSec / 60
    $iHour = $iMin / 60
    $iMin -= Int($iHour) * 60
    $iSec -= Int($iMin) * 60
	If $bComfortView Then ; no hours if not present and no frames
		If Not Int($iHour) = 0 Then $sReturn &= StringRight('0' & Int($iHour), 2) & 'h' & ChrW(8239)
		$sReturn &= StringRight('0' & Int($iMin), 2) & 'm' & ChrW(8239) & StringRight('0' & Int($iSec), 2) & 's'
	Else
		$sReturn = $sSign & StringRight('0' & Int($iHour), 2) & 'h' & ChrW(8239) & StringRight('0' & Int($iMin), 2) & 'm' & ChrW(8239) & StringRight('0' & Int($iSec), 2) & 's' & ChrW(8239) & StringRight('0' & Int($iFrames), 2) & 'f'
	EndIf
	Return $sReturn
EndFunc

Func _WordWrapTextForLabel($sText, $iCounter)
	Local $sResult
	Local $iTotalChar = StringLen($sText)
	For $i = 1 To Ceiling($iTotalChar / $iCounter)
		$sResult &= StringLeft($sText, $iCounter) & " "
		$sText = StringTrimLeft($sText, $iCounter)
	Next
	$sResult = StringTrimRight($sResult, 1) ; cut last " "
	Return $sResult
EndFunc