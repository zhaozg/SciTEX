' read/change vbs & wsc & wsf "designated editor", jw 05Jul00
'   (motivation: every time we download that blasted browser,
'    or those blasted scripting engines, some arrogant installer
'    messes around with my registry, and my editor-of-choice gets changed
'    to microsoft's "wonder editor").

Option Explicit
Dim oSH  ' as shell object
Dim sFileTypes  ' as variant (string array)
Dim sNewEditor  ' as string
Dim iFT  ' as integer
Dim nAns  ' as long

' potential candidates for scripting editor-of-choice...
Const sTextpad = "C:\Apps\Textpad\textpad.exe ""%L"""
Const sWscite  = "C:\apps\Alt_Edit\wscite\SciTE.exe ""%L"""
Const sMSDevEnv = "C:\Program Files\Microsoft Visual Studio\Common\IDE\IDE98\MSE.EXE ""%1"""
Const sNotePad  = "C:\WINDOWS\NOTEPAD.EXE ""%1"""

' table of RegKeys for the Editors of the scripting file types...
sFileTypes = Array("VBS", "HKCR\VBSFile\Shell\Edit\Command\", _
                   "JS" , "HKCR\JSFile\Shell\Edit\Command\", _
                   "WSC", "HKCR\scriptletfile\Shell\Open\Command\", _
                   "WSF", "HKCR\WSFFile\Shell\Edit\Command\")

sNewEditor = sWscite  ' SET DESIGNATED EDITOR HERE

Set oSH = WScript.CreateObject("WScript.Shell")

  ' loop through for each filetype...
  For iFT =	Lbound(sFileTypes) to UBound(sFileTypes) -1 Step 2

    ChangeDesignatedEditor sFileTypes(iFT), sFileTypes(iFT+1), sNewEditor
  Next  ' iFT

Set oSH = nothing  ' clean up
WScript.Quit


  ' ----------------------------------------------
  ' --- Change Designated Editor for Script File -
  ' ----------------------------------------------

Sub ChangeDesignatedEditor(sEXT, sRegKey, sNewEdit)
Dim sRegEdit  ' as string

  ' read up the designated editor for this type of file...
  sRegEdit = oSH.RegRead(sRegKey)

  ' get permission to change...
  nAns = MsgBox("Current " & sEXT & " file editor: " & vbCrLf _
      & "        " & sRegEdit & vbCrLf & vbCrLf _
      & "Proposed replacement, is that O.K.?  " & vbCrLf _
      & "        " & sNewEdit, vbOKCancel, _
      " << Permission To Change " & sEXT & " File Editor? >> ")

  If  (nAns = vbOK)  then

    oSH.RegWrite sRegKey, sNewEdit

    ' read up the designated editor again (just to confirm the change)...
    sRegEdit = oSH.RegRead(sRegKey)
    MsgBox("After changing it, the " & sEXT & " file editor is now: " & vbCrLf & vbCrLf _
        & "    [" & sRegEdit & "]")

  End If

End Sub
