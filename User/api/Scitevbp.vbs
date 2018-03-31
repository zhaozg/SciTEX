' Script for opening VB project file set within SciTE
' By Alex Angelopoulos <aka(at)mvps.org>
' special thanks for debug work above and beyond the call of duty
' to Bob O'Brien <bobdice2e(at)obob.com>
' Works on Windows XP

Option Explicit
Dim Arg ' marker for each file passed to the script

For Each Arg in WScript.Arguments
	OpenWithSciTE aVbFiles(Arg)
Next


Function SciTEStartCommand
	' Finds path to SciTE in the registry
	' makes it "safe" for use in a command
	Dim EndMarker, Sh, SciTeRoot, sBase, lSciTEPath, sArgs, sSciTEPath
	EndMarker = ".exe" ' we use this to find end of the TP exe path
	Set Sh = CreateObject("WScript.Shell")
	SciTeRoot = "HKCR\properties_auto_file\shell\open\command\"
	' this is our base command
	' Everything is quote-delimited, so grab element 1 after splitting
	sBase = Split(Lcase(Sh.RegRead(SciTeRoot)), """")(1)
	' ugly hack - let's verify where SciTE is
	' we think this is the length of the SciTE path
	' this simply looks for the first "-" from the END of the command line
	' then splist before that.
	lSciTEPath = InStrRev(sBase, EndMarker) + Len(EndMarker) - 1
	sArgs = Mid(sBase, lSciTEPath + 1)
	sSciTEPath = Chr(34) & Left(sBase, lSciTEPath) & Chr(34)
	' this is the original SciTE execution line returned with quotes
	' around the executable path
	SciTEStartCommand = sSciTEPath & sArgs
End Function

Sub OpenWithSciTE(aryFiles)
	' takes an array of files/switches
	' finds local SciTE path and opens them
	' with SciTE after concatenation
	Dim Sh, sCmd, i
	Set Sh = CreateObject("WScript.Shell")
	' SciTEStartCommand is a function that space-safes the
	' registry path for SciTE derived from the .tws file association
	sCmd = SciTEStartCommand
	For i = 0 to UBound(aryFiles)
		On Error Resume Next
		' check every file for spaces in the name
		' If found, wrap it in quotes
		' error control on since no spaces returns a null value
		If InStr(aryFiles(i), " ") Then
			aryFiles(i) = """" & aryFiles(i) & """"
		End If
		On Error Goto 0
		' filename is prepped, append it to the SciTE command line
		sCmd = sCmd & " " & aryFiles(i)
	Next
	' Run the command here, with all files concatenated.
	Sh.Run sCmd
End Sub



Function aVbFiles(filProject)
	' Given the full path to a VBP file
	' returns array containing full paths to its files
	' only returns vbp, bas, and cls files at present
	' DEPENDENCY: fRead function
	Dim folProject, aData, aTmp(), i, _
		ModuleTag, ModuleTags, MiscTag, MiscTags
	folProject = Left(filProject, InstrRev(filProject, "\"))
	aData = Split(fRead(filProject), vbCrLf)
	Redim aTmp(0): aTmp(0) = filProject
	ModuleTags = Array("Class","Module")
	MiscTags = Array("UserControl","Form", "PropertyPage", "UserDocument")
	For i = 0 to UBound(aData)
		For each ModuleTag in ModuleTags
			If Left(aData(i), Len(ModuleTag)) = ModuleTag Then
				Redim Preserve aTmp(UBound(aTmp) + 1)
				aTmp(UBound(aTmp)) = folProject _
					& Trim(Mid(aData(i), InStr(aData(i), ";")+1))
			End If
		Next
		For each MiscTag in MiscTags
			If Left(aData(i), Len(MiscTag)) = MiscTag Then
				Redim Preserve aTmp(UBound(aTmp) + 1)
				aTmp(UBound(aTmp)) = folProject _
					& Trim(Mid(aData(i), InStr(aData(i), "=")+1))
			End If
		Next
	Next
	aVbFiles = aTmp
End Function

Function fRead(FilePath)
	'Given the path to a file, will return entire contents
	' works with either ANSI or Unicode
	Dim FSO, CurrentFile
	Const ForReading = 1, TristateUseDefault = -2, _
		DoNotCreateFile = False
	Set FSO = createobject("Scripting.FileSystemObject")
	If FSO.FileExists(FilePath) Then
		If FSO.GetFile(FilePath).Size>0 Then
			Set CurrentFile = FSO.OpenTextFile(FilePath, ForReading, _
				False, TristateUseDefault)
			fRead = CurrentFile.ReadAll: CurrentFile.Close
		End If
	End If
End Function