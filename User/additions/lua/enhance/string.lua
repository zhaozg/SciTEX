local string = string
local unpack = unpack or table.unpack

if not string.bin2hex then
  if not (string._hextab and string._bintab)  then
    string._hextab = {}
    string._bintab = {}
    for k=0,255 do
        local x = string.format("%02x", k)
        string._hextab[k] = x
        string._bintab[x] = k
    end
  end
end

string.bin2hex = string.bin2hex and string.bin2hex or function(bin,fmt)
  local ret = {}
  for i=1,#bin do
    local b = string.byte(bin,i)
    
    if fmt==nil then
      table.insert(ret,string._hextab[b])
    elseif fmt=='c' then
      table.insert(ret,'0x'..string._hextab[b])
    else
      table.insert(ret,string._hextab[b])
      if(i%32==0) then
        table.insert(ret,'\n')
      elseif(i%4==0) then
        table.insert(ret,' ')
      end
      table.insert(ret,'\n')
    end
  end
  if fmt=='c' then
    return table.concat(ret,',')
  else
    return table.concat(ret)
  end
end

string.hex2bin = string.hex2bin and string.hex2bin  or function(hex)
  local hex = string.lower(hex)
  local ret = {}
  for i=1,#hex,2 do
	sub = string.sub(hex,i,i+1)
	if sub then
        local n = tonumber(sub)
		table.insert(ret,string._bintab[sub])
	end
  end
  return string.char(unpack(ret))
end

-- String ----------------------------------------------------------------------
-- CREDIT: Steve Dovan snippet.
-- TODO: Clarify corner cases, make more robust.
string.split = string.split and string.split or function(s, re)
  local i1, ls = 1, { }
  if not re then re = '%s+' end
  if re == '' then return { s } end
  while true do
    local i2, i3 = s:find(re, i1)
    if not i2 then
      local last = s:sub(i1)
      if last ~= '' then table.insert(ls, last) end
      if #ls == 1 and ls[1] == '' then
        return  { }
      else
        return ls
      end
    end
    table.insert(ls, s:sub(i1, i2 - 1))
    i1 = i3 + 1
  end
end

-- TODO: what = "lr"
function string.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function adjustexp(s)
  if s:sub(-3, -3) == "+" or s:sub(-3, -3) == "-" then
    return s:sub(1, -3).."0"..s:sub(-2)
  else
    return s
  end
end

function string.width(x, chars)
  chars = chars or 9
  if chars < 9 then
    error("at least 9 characters required")
  end
  if type(x) == "nil" then
    return (" "):rep(chars - 3).."nil"
  elseif type(x) == "boolean" then
    local s = tostring(x)
    return (" "):rep(chars - #s)..s
  elseif type(x) == "string" then
    if #x > chars then
      return x:sub(1, chars - 2)..".."
    else
      return (" "):rep(chars - #x)..x
    end
  else
    local formatf = "%+"..chars.."."..(chars - 3).."f"
    local formate = "%+."..(chars - 8).."e"
    x = tonumberx(x) -- Could be cdata.
    local s = format(formatf, x)
    if x ~= x or abs(x) == 1/0 then return s end
    if tonumberx(s:sub(2, chars)) == 0 then -- It's small.
      if abs(x) ~= 0 then -- And not zero.
        s = adjustexp(format(formate, x))
      end
    else
      s = s:sub(1, chars)
      if not s:sub(3, chars - 1):find('%.') then -- It's big.
        s = adjustexp(format(formate, x))
      end
    end
    return s
  end
end

function string.escape(s)
  return (s:gsub('%%', '%%%%')
           :gsub('%^', '%%%^')
           :gsub('%$', '%%%$')
           :gsub('%(', '%%%(')
           :gsub('%)', '%%%)')
           :gsub('%.', '%%%.')
           :gsub('%[', '%%%[')
           :gsub('%]', '%%%]')
           :gsub('%*', '%%%*')
           :gsub('%+', '%%%+')
           :gsub('%-', '%%%-')
           :gsub('%?', '%%%?'))
end

return string
