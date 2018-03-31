local table = table

 -- map(table,function)
 -- e.g: map({1,2,3},double)    -> {2,4,6}
function table.map(tbl, func)
    local newtbl = {}
    for i,v in pairs(tbl) do
        newtbl[i] = func(v)
    end
    return newtbl
end

 -- filter(table,function)
 -- e.g: filter({1,2,3,4},is_even) -> {2,4}

function table.filter(tbl,func)
    local newtbl= {}
    for i,v in pairs(tbl) do
        if func(v) then
	     newtbl[i]=v
        end
    end
    return newtbl
end
 
local function _is_table_equals(actual, expected)
    if (type(actual) == 'table') and (type(expected) == 'table') then
        if (#actual ~= #expected) then
            return false
        end
        local k,v
        for k,v in pairs(actual) do
            if not _is_table_equals(v, expected[k]) then
                return false
            end
        end
        for k,v in pairs(expected) do
            if not _is_table_equals(v, actual[k]) then
                return false
            end
        end
        return true
    elseif type(actual) ~= type(expected) then
        return false
    elseif actual == expected then
        return true
    end
    return false
end 

table.equals = _is_table_equals

-- Table -----------------------------------------------------------------------
-- TODO: Introduce optional trailing 'resv = onconflict(key, v, newv)'.
function table.union(...)
  local o = {}
  local arg, n = { ... }, select("#", ...)
  for a=1,n do
    for k,v in pairs(arg[a]) do
      if type(o[k]) ~= "nil" then
        error("key '"..tostring(k).."' is not unique among tables to be merged")
      end
      o[k] = v
    end
  end
  return o
end

function table.append(...)
  local o = { }
  local arg, n = { ... }, select("#", ...)
  local c = 0
  for a=1,n do
    local t = arg[a]
    for i=1,#t do
      c = c + 1
      local v = t[i]
      if type(v) == "nil" then
        error("argument #"..a.." is not a proper array: no nil values allowed")
      end
      o[c] = v
    end
  end
  return o
end

-- Exec ------------------------------------------------------------------------
local function testexec(chunk, chunkname, fenv, ok, ...)
  if not ok then
    local err = select(1, ...)
    error("execution error: "..err)
  end
  return ...
end

local function exec(chunk, chunkname, fenv)
  chunkname = chunkname or chunk
  local f, e = loadstring(chunk, chunkname)
  if not f then
    error("parsing error: "..err)
  end
  if fenv then 
    setfenv(f, fenv)
  end
  return testexec(chunk, chunkname, fenv, pcall(f))
end

-- From ------------------------------------------------------------------------
function table.from(what, keystr)
  local keys = split(keystr, ",")
  local o = { }
  for i=1,#keys do
    o[i] = "x."..trim(keys[i])
  end
  o = concat(o, ",")
  local s = "return function(x) return "..o.." end"
  return exec(s, "from<"..keystr..">")(what)
end

function table.clone(tbl,deep)
  local new = {}
  for k,v in pairs(tbl) do
    new[k] = v
  end
  return new
end

function table.exclude(tbl,exclude)
  for k,v in pairs(exclude) do
    tbl[k] = nil
  end
  return tbl
end

return table 
