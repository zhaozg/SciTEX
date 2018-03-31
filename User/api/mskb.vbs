'mskbintegrated.vbs
' v 2002.07.24a

FetchMSKB WScript.Arguments(0)

Sub FetchMSKB(sArticleID)
	sStart = "Microsoft Knowledge Base Article - "
	' Takes a "raw" article ID as argument
	' Will clean "q" and "/" elements if needed
	' MSKB.vbs
	' direct-to-article Q-note browser
	'kills off Q/q if left in
	If sArticleID = "" Then WScript.Quit
	sArticleID = Replace(sArticleID,"Q","",1,-1,1)
	sArticleID = Replace(sArticleID,".asp","",1,-1,1)
	'if ID grabbed from old split URL, this joins it
	sArticleID = Replace(sArticleID,"/","")
	Set oIE = CreateObject("InternetExplorer.Application")
	oIE.Navigate "http://support.microsoft.com/?" _
	& "scid=kb;en-us;Q" & sArticleID
	'wait until browser has completed article download
	Do Until oIE.ReadyState = 4
		WScript.Sleep 10
	Loop
	On Error Resume Next
	sData = oIE.Document.Body.InnerText
	StartPos = Instr(sData, sStart)
	sData = Mid(sData, StartPos)
	sData = Replace(sData,vbCrLf & vbCrLf _
		& "  Send     Print     Help   ","")
	EndPos = Instr(sData,"c 2002 Microsoft Corporation")
	sData = Mid(sData,1,EndPos - 1)
	WScript.Echo sData
	WScript.Echo oIE.LocationName
	WScript.Echo  oIE.LocationURL
	WScript.Echo String(20, "-")
	WScript.Echo Replace(oIE.LocationName, " - ", vbTab, 1) 
	'show the article
	oIE.Quit
End Sub