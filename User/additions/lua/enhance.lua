---enhance lua and luajit stand library.
require'enhance.core'

local M = {}

 -- curry(f,g)
 -- e.g: printf = curry(io.write, string.format)
 --          -> function(...) return io.write(string.format(unpack(arg))) end
 function M.curry(f,g)
     return function (...)
         return f(g(unpack(arg)))
     end
 end
 
  -- is(checker_function, expected_value)
 -- @brief
 --      check function generator. return the function to return boolean,
 --      if the condition was expected then true, else false.
 -- @example
 --      local is_table = is(type, "table")
 --      local is_even = is(bind2(math.mod, 2), 1)
 --      local is_odd = is(bind2(math.mod, 2), 0)
 M.is = function(check, expected)
     return function (...)
         if (check(unpack(arg)) == expected) then
             return true
         else
             return false
         end
     end
 end
 
 -- Tonumber --------------------------------------------------------------------
local function getton(x)
  return x.__tonumber
end

function M.tonumber(x)
  if type(x) ~= "table" and type(x) ~= "cdata" then
    return tonumber(x)
  else
    local haston, ton = pcall(getton, x)
    return (haston and ton) and ton(x) or tonumber(x)
  end
end


-- Cache library functions.
local insert, concat = table.insert, table.concat
local find, format, sub = string.find, string.format, string.sub


-- Parse verbatim blocks containing template expressions.
local function parse_expression(result, chunk)
  local i, n = 1, #chunk
  while i <= n do
    local s, e, expr = find(chunk, "$(%b{})", i)
    if not s or s > i then
      insert(result, format("_put(%q)", sub(chunk, i, s and s - 1)))
    end
    if not s then break end
    insert(result, format("_put(%s)", sub(expr, 2, -2)))
    i = e + 1
  end
end

-- Parse template statements.
local function parse_statement(result, chunk)
  local i, n = 1, #chunk
  while i <= n do
    local s, e, stmt = find(chunk, "%f[^%z\n]%s*|([^\n]*\n?)", i)
    if not s or s > i then
      parse_expression(result, sub(chunk, i, s and s - 1))
    end
    if not s then break end
    insert(result, stmt)
    i = e + 1
  end
end

-- Lua 5.1 uses setfenv, Lua 5.2 uses _ENV
local setfenv = setfenv

local render_to_function
if setfenv then
  function render_to_function(render, f, env)
    setfenv(render, env)
    local status, err = pcall(render, f)
    if not status then return error(err) end
  end
else
  function render_to_function(render, f, env)
    local status, err = pcall(render, f, env)
    if not status then return error(err) end
  end
end

local function render_to_string(render, env)
  local t = {}
  local f = function(s)
    if s ~= nil then insert(t, tostring(s)) end
  end
  local status, err = pcall(render_to_function, render, f, env)
  if not status then return error(err) end
  return concat(t)
end

--- Lua 5.2 deprecates loadstring
local load = loadstring or load

local function loadtemplate(s, source)
  local result = {"local _put, _ENV = ..."}
  parse_statement(result, s)
  local render, err = load(concat(result), source)
  if not render then return error(err) end
  return function(env, f)
    local env = env or _G
    if not f then
      return render_to_string(render, env)
    else
      return render_to_function(render, f, env)
    end
  end
end

function M.loadstring(s)
  local status, result = pcall(loadtemplate, s, s)
  if not status then return error(result) end
  return result
end

function M.loadfile(filename)
  local f, err = io.open(filename, "r")
  if not f then return error(err) end
  local s = f:read("*a")
  local status, result = pcall(loadtemplate, s, "@" .. filename)
  if not status then return error(result) end
  f:close()
  return result
end

return M
