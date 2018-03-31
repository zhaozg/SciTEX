'=============================================================
' SCRIPT INFORMATION
'=============================================================
' WordCheck.vbs
' v.2002.11.17
' Requires Microsoft Word 97 or higher installed (and of course WSH)
' Author: Alex K. Angelopoulos
' Comments to alexangelopoulos@hotmail.com
' Purpose: Allows use of the Microsoft Word spelling and grammer checker
' 		with an arbitrary text file; can be used via drag-drop or integrated
'			into the Tools menu of a flexible text editor such as SciTE.

'=============================================================
' PURPOSE
'=============================================================
' Allows easy drag-drop or



'=============================================================
' USING WITH SCITE
'=============================================================
	' To get SciTE to auto-reload, you need to set the following property
	' in SciTEGlobal.properties or SciTEUser.properties (available under the Options
	' menu as "Open Global Options File" and "Open User Options File" respectively).
		'load.on.activate=1

	'#Word Grammar and Spelling Checker
	' Following is an example of setting this script as a Tools choice (via Ctrl+9 in this case).
	' Note that this is based on the assumption that you have this script saved as
	' WordCheck.vbs under a scripts\ subfolder of the SciTE home directory.		'command.name.9.*=Grammar and Spelling Check		'command.9.*=wscript "$(SciteDefaultHome)\scripts\WordCheck.vbs" "$(FilePath)"		'command.subsystem.1.*=2
'=============================================================
' SCRIPT BODY
'=============================================================
' Check that 1 and only 1 argument is supplied on the command line
' If not, then exit
' this allows correct operation if used externally

' FSO constants - necessary since they are in an external typelib
  CONST ForReading = 1, ForWriting = 2




For Each Arg in Args

	' Step 1: Read the file text
	checkText = InFileText(Arg)

	'Step 2: Fire up Microsoft Word and check the text
	CheckText = Spelling_Grammar(CheckText)

	'Step 3: Save it back to the file.
	WriteFile Args(0),CheckText

Next


Function InFileText(FilePath)
	' Reads content of text file FilePath
	 Dim fso, f
  Set fso = CreateObject("Scripting.FileSystemObject")
  Set f = fso.OpenTextFile(FilePath, ForReading)
  InFileText =   f.ReadAll

End Function



Sub modWriteToFile(ToWrite,FilePath)

 'ToWrite is data written to file FilePath
 CONST ForReading = 1, ForWriting = 2, ForAppending = 8
 Set FSO = CreateObject("Scripting.FileSystemObject")
 Set fileRef = FSO.OpenTextFile(FilePath, ForAppending, True)
 fileRef.WriteLine(ToWrite)

End Sub



function Spelling_Grammar(TextValue)

	Dim Word, Document, ReturnValue

	Set Word = CreateObject("Word.Application")
	Word.WindowState = 2
	Word.Visible = False

	'Create a new instance of Document
	Set Document = Word.Documents.Add( , , 1, True)
	Document.Content=TextValue
	Document.CheckSpelling
	Document.CheckGrammar

	'Return checked text and quit Word
	ReturnValue = Document.Content
	Document.Close False ' this forces close without prompt to save as a Word doc
	Word.Application.Quit True

	Spelling_Grammar=ReturnValue

End function



Sub WriteFile(FilePath,Data)

  'Given the path to a file and a data string, this function writes the data to the file
	Dim fso, f
  Set fso = CreateObject("Scripting.FileSystemObject")
  Set f = fso.OpenTextFile(FilePath, ForWriting)
  f.Write Data

End Sub

