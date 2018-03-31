print(string.rep('-',80))
SciTEX = SciTEX or require'SciTEX'
props["APIPath"]               =props["SciteUserHome"].."api"

package.path    =   props['SciteUserHome']..'/additions/lua/?.lua;'

print("SciteHome           :"..props["SciteHome"])
print("SciteDefaultHome    :"..props["SciteDefaultHome"])
print("SciteUserHome       :"..props["SciteUserHome"])
print("APIPath             :"..props["APIPath"])
print("package.path        :"..package.path)

-- extman
dofile (props["SciteUserHome"].."\\additions\\extman\\extman.lua")

-- SideBar
dofile (props["SciteUserHome"].."\\additions\\SideBar.lua")

--scite_Command('Calculator|Calculator|Ctrl+8')
--print(d)
--AutoComplete
--dofile (props["SciteUserHome"].."\\additions\\AutoComplete.lua")
--SmartHighlight
--dofile (props["SciteUserHome"].."\\additions\\SmartHighlight.lua")
