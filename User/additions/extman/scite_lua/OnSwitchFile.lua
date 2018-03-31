-- encoding: utf-8

local function toBoolean(v1,v2)
  v1 = props[v1]:gsub(' ','')
  v2 = v2 and props[v2]:gsub(' ','') or false
  if v1==1 or v1=='1' or v1=='true' then
    return 'true'
  elseif v2==1 or v2=='1' or v2=='true' then
    return 'true'
  else
    return 'false'
  end
end

local function toNumber(v1,v2)
  v1 = props[v1]:gsub(' ','')
  v2 = v2 and props[v2]:gsub(' ','') or ''
  if #v1>0 then
    return v1
  else
    return v2
  end
end

function update_StatusBar()
  local filepatterns='*.'..props['FileExt']

  local tips = ' 移除尾部空白:'..toBoolean('strip.trailing.spaces.'..filepatterns,'strip.trailing.spaces')
             ..' Tab长度:'.. toNumber('tab.size.'..filepatterns, 'tabsize')
             ..' 缩进[长度:'.. toNumber('indent.size.'..filepatterns, 'indent.size')
                .. ' 自动:'..toBoolean('indent.auto')
                .. ' Tab:'..toBoolean('tab.indents')
                .. ' Backspace回退:'..toBoolean('backspace.unindents')
             ..'] 使用Tab:'..toBoolean('use.tabs.'..filepatterns,'use.tabs')

  props["statusbar.text.2"]=filepatterns..tips
end

scite_OnSwitchFile(update_StatusBar)
