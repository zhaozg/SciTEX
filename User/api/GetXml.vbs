
For each Arg in WScript.Arguments
	WScript.Echo GetXml(Arg)
Next

Function GetXml(sURL)
	' Create an xmlhttp object:
	Dim Xml
	Set Xml = CreateObject("Microsoft.XMLHTTP")
	Xml.open "GET",sURL
	Xml.send
	Do:wscript.sleep 10:Loop While Xml.ReadyState<>4
	GetXml = Xml.responseText
End Function