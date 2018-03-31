-- Extman is a Lua script manager for SciTE. It enables multiple scripts to capture standard events
-- without interfering with each other. For instance, scite_OnDoubleClick() will register handlers
-- for scripts that need to know when a double-click event has happened. (To know whether it
-- was in the output or editor pane, just test editor.Focus).  It provides a useful function scite_Command
-- which allows you to define new commands without messing around with property files (see the
-- examples in the scite_lua directory.)
-- extman defines three new convenience handlers as well:
--scite_OnWord (called when user has entered a word)
--scite_OnEditorLine (called when a line is entered into the editor)
--scite_OnOutputLine (called when a line is entered into the output pane)

-- this is an opportunity for you to make regular Lua packages available to SciTE
--~ package.path = package.path..';C:\\lang\\lua\\lua\\?.lua'
--~ package.cpath = package.cpath..';c:\\lang\\lua\\?.dll'

-- useful function for getting a property, or a default if not present.
function scite_GetProp(key,default)
   local val = props[key]
   if val and val ~= '' then return val
   else return default end
end

function scite_GetPropBool(key,default)
    local res = scite_GetProp(key,default)
    if not res or res == '0' or res == 'false' then return false
    else return true
    end
end

local GTK = scite_GetProp('PLAT_GTK')

--[[
  For some of these events, SciTE will pass one or more arguments to the event
handler function: OnOpen, OnClose, OnSwitchFile, OnSave, and OnBeforeSave will
receive the filename of the affected buffer as their first argument.
  An OnChar handler should expect a single-character string argument. An OnKey
handler should expect an integer keycode and boolean shift, control, and alt
arguments. The keycode is currently a platform specific value but this may
change in future. OnDwellStart will receive the position of the mouse and the
word under the mouse as arguments and the word will be empty when the mouse
starts moving.
  OnUserListSelection receives two arguments: a number indicating the list type,
and a string indicating the selected item text. The other event handlers will
not be passed any arguments.
--]]

local _Word,_LineEd,_LineOut = {},{},{}

-- with filename
local _Open, _Close, _SwitchFile, _Save, _BeforeSave = {},{},{},{},{}
-- Char and Key
local _Char,_Key = {},{}
-- without
local _MarginClick,_DoubleClick,_SavePointLeft, SavePointReached = {},{},{},{}
local _OpenSwitch,_UpdateUI = {},{}
-- special
local _UserListSelection
local _DwellStart = {}

-- need to check
local _Activate,_SendEditor = {},{}


local _remove = {}
local append = table.insert
local find = string.find
local size = table.getn
local sub = string.sub
local gsub = string.gsub


-- file must be quoted if it contains spaces!
function quote_if_needed(target)
    local quote = '"'
    if find(target,'%s') and sub(target,1,1) ~= quote then
        target = quote..target..quote
    end
    return target
end

local function DispatchOne(handlers,arg)
  if not handlers then return false end
  for i,handler in pairs(handlers) do
    local fn = handler
    if _remove[fn] then
        handlers[i] = nil
       _remove[fn] = nil
    end
    local ret = fn(arg)
    if ret then return ret end
  end
  return false
end

local function Dispatch4(handlers,arg1,arg2,arg3,arg4)
    for i,handler in pairs(handlers) do
        local fn = handler
        if _remove[fn] then
            handlers[i] = nil
            _remove[fn] = nil
        end
        local ret = fn(arg1,arg2,arg3,arg4)
        if ret then return ret end
    end
    return false
end

DoDispatchOne = DispatchOne -- export this!

-- these are the standard SciTE Lua callbacks  - we use them to call installed handlers!

-- OnOpen, OnClose, OnSwitchFile, OnSave, OnBeforeSave
-- will receive the filename of the affected buffer as their first argument.
function OnOpen(file)
  return DispatchOne(_Open,file)
end

function OnClose(file)
  return DispatchOne(_Close,file)
end

function OnSwitchFile(file)
  return DispatchOne(_SwitchFile,file)
end

function OnSave(file)
  return DispatchOne(_Save,file)
end

function OnBeforeSave(file)
  return DispatchOne(_BeforeSave,file)
end

-- OnChar, OnKey
-- An OnChar handler should expect a single-character string argument.
-- An OnKey handler should expect an integer keycode and boolean shift, control,
-- and alt arguments. The keycode is currently a platform specific value but
-- this may change in future.
function OnChar(ch)
  return DispatchOne(_Char,ch)
end

function OnKey(key,shift,ctrl,alt)
    return Dispatch4(_Key,key,shift,ctrl,alt)
end

-- OnDwellStart
-- OnDwellStart will receive the position of the mouse and the word under the
-- mouse as arguments and the word will be empty when the mouse starts moving.
function OnDwellStart(pos,s)
    return Dispatch4(_DwellStart,pos,s)
end

-- OnUserListSelection
-- OnUserListSelection receives two arguments: a number indicating the list
-- type, and a string indicating the selected item text.
function OnUserListSelection(tp,str)
  if _UserListSelection then
     local callback = _UserListSelection
     _UserListSelection = nil
     return callback(str)
  else return false end
end

-- OnDoubleClick, OnMarginClick, OnUpdateUI, OnSavePointReached, OnSavePointLeft
-- The other event handlers will not be passed any arguments.
function OnDoubleClick()
  return DispatchOne(_DoubleClick)
end

function OnMarginClick()
  return DispatchOne(_MarginClick)
end

function OnUpdateUI()
  if editor.Focus then
    return DispatchOne(_UpdateUI)
  else
    return false
  end
end

function OnSavePointLeft()
  return DispatchOne(_SavePointLeft)
end

function OnSavePointReached()
  return DispatchOne(_SavePointReached)
end
-- end of globle event
-- need to check
function OnActivate(...)
    return Dispatch4(_Activate,...)
end
function OnSendEditor(...)
    return Dispatch4(_SendEditor,...)
end

-- may optionally ask that this handler be immediately
-- removed after it's called
local function append_unique(tbl,fn,rem)
  local once_only
  if type(fn) == 'string' then
     once_only = fn == 'once'
     fn = rem
     rem = nil
     if once_only then
        _remove[fn] = fn
    end
  else
    if type(_remove)=='table' and fn then
        _remove[fn] = nil
    end
  end
  local idx
  for i,handler in pairs(tbl) do
     if handler == fn then idx = i; break end
  end
  if idx then
    if rem then
      table.remove(tbl,idx)
    end
  else
    if not rem then
      append(tbl,fn)
    end
  end
end
ex_append_unique = append_unique

-- this is how you register your own handlers with extman
-- begin filename
function scite_OnOpen(fn,rem)
  append_unique(_Open,fn,rem)
end

function scite_OnClose(fn,rem)
    append_unique(_Close,fn,rem)
end

function scite_OnSwitchFile(fn,rem)
  append_unique(_SwitchFile,fn,rem)
end

function scite_OnBeforeSave(fn,rem)
  append_unique(_BeforeSave,fn,rem)
end

function scite_OnOpenSwitch(fn,rem)
  append_unique(_OpenSwitch,fn,rem)
end

function scite_OnSave(fn,rem)
  append_unique(_Save,fn,rem)
end
-- end filename

function scite_OnMarginClick(fn,rem)
  append_unique(_MarginClick,fn,rem)
end

function scite_OnDoubleClick(fn,rem)
  append_unique(_DoubleClick,fn,rem)
end

function scite_OnSavePointLeft(fn,rem)
  append_unique(_SavePointLeft,fn,rem)
end

function scite_OnSavePointReached(fn,rem)
  append_unique(_SavePointReached,fn,rem)
end

function scite_OnUpdateUI(fn,rem)
  append_unique(_UpdateUI,fn,rem)
end

function scite_OnChar(fn,rem)
  append_unique(_Char,fn,rem)
end

function scite_OnKey(fn,rem)
    append_unique(_Key,fn,rem)
end

function scite_OnDwellStart(fn,rem)
    append_unique(_DwellStart,fn,rem)
end

--merge eventmanager

function scite_OnActivate(fn,rem)
    append_unique(_Activate,fn,rem)
end
function scite_OnSendEditor(fn,rem)
    append_unique(_SendEditor,fn,rem)
end

local function buffer_switch(f)
--- OnOpen() is also called if we move to a new folder
   if not find(f,'[\\/]$') then
      DispatchOne(_OpenSwitch,f)
   end
end

scite_OnOpen(buffer_switch)
scite_OnSwitchFile(buffer_switch)

local next_user_id = 13 -- arbitrary

-- the handler is always reset!
function scite_UserListShow(list,start,fn)
  local separators = {' ', ';', '@', '?', '~', ':'}
  local separator
  local s = table.concat(list)
  for i, sep in ipairs(separators) do
    if not string.find(s, sep, 1, true) then
      s = table.concat(list, sep, start)
      separator = sep
      break
    end
  end
  -- we could not find a good separator, set it arbitrarily
  if not separator then
    separator = '@'
    s = table.concat(list, separator, start)
  end
  _UserListSelection = fn
  local pane = editor
  if not pane.Focus then pane = output end
  pane.AutoCSeparator = string.byte(separator)
  pane:UserListShow(next_user_id,s)
  pane.AutoCSeparator = string.byte(' ')
  return true
end

 local word_start,in_word,current_word
-- (Nicolas) this is in Ascii as SciTE always passes chars in this "encoding" to OnChar
local wordchars = '[A-Za-z�-��-�]'  -- wuz %w

 local function on_word_char(s)
     if not in_word then
        if find(s,wordchars) then
      -- we have hit a word!
         word_start = editor.CurrentPos
         in_word = true
         current_word = s
      end
    else -- we're in a word
   -- and it's another word character, so collect
     if find(s,wordchars) then
       current_word = current_word..s
     else
       -- leaving a word; call the handler
       local word_end = editor.CurrentPos
       DispatchOne(_Word, {word=current_word,
               startp=word_start,endp=editor.CurrentPos,
               ch = s
            })
       in_word = false
     end
    end
  -- don't interfere with usual processing!
    return false
  end

function scite_OnWord(fn,rem)
  append_unique(_Word,fn,rem)
  if not rem then
     scite_OnChar(on_word_char)
  else
     scite_OnChar(on_word_char,'remove')
  end
end

local last_pos = 0

function get_line(pane,lineno)
    if not pane then pane = editor end
    if not lineno then
        local line_pos = pane.CurrentPos
        lineno = pane:LineFromPosition(line_pos)-1
    end
    -- strip linefeeds (Windows is a special case as usual!)
    local endl = 2
    if pane.EOLMode == 0 then endl = 3 end
    local line = pane:GetLine(lineno)
    if not line then return nil end
    return string.sub(line,1,-endl)
end

-- export this useful function...
scite_Line = get_line

local function on_line_char(ch,was_output)
    if ch == '\n' then
        local in_editor = editor.Focus
        if in_editor and not was_output then
            DispatchOne(_LineEd,get_line(editor))
            return false -- DO NOT interfere with any editor processing!
        elseif not in_editor and was_output then
            DispatchOne(_LineOut,get_line(output))
            return true -- prevent SciTE from trying to evaluate the line
        end
    end
    return false
end

local function on_line_editor_char(ch)
  return on_line_char(ch,false)
end

local function on_line_output_char(ch)
  return on_line_char(ch,true)
end

local function set_line_handler(fn,rem,handler,on_char)
  append_unique(handler,fn,rem)
  if not rem then
    scite_OnChar(on_char)
  else
    scite_OnChar(on_char,'remove')
  end
end

function scite_OnEditorLine(fn,rem)
  set_line_handler(fn,rem,_LineEd,on_line_editor_char)
end

-- with this scheme, there is a primary handler, and secondary prompt handlers
-- can temporarily take charge of input. There is only one prompt in charge
-- at any particular time, however.
local primary_handler

function scite_OnOutputLine(fn,rem)
    if not rem then
        if not primary_handler then primary_handler = fn end
    end
    _LineOut = {}
    set_line_handler(fn,rem,_LineOut,on_line_output_char)
    if rem and fn ~= primary_handler then
        set_line_handler(primary_handler,false,_LineOut,on_line_output_char)
    end
end

local path_pattern
local tempfile
local dirsep

if GTK then
    tempfile = '/tmp/.scite-temp-files'
    path_pattern = '(.*)/[^%./]+%.%w+$'
    dirsep = '/'
else
    tempfile = os.getenv 'TMP' .. '\\scite_temp1'
    path_pattern = '(.*)[\\/][^%.\\/]+%.%w+$'
    dirsep = '\\'
end

function path_of(s)
    local _,_,res = find(s,path_pattern)
    if _ then return res else return s end
end

local function extman_path()
    local debug = require'debug'
    local d = debug.getinfo(1)
    local p = d.source --  @full path of lua file
    p = string.sub(p,2,-1)
    return string.gsub(p, "extman.lua", "")
end


local lua_path = scite_GetProp('ext.lua.directory',extman_path()..'scite_lua')

pcall(require,'gui')
if not gui then
    print('GUI is missing')
end

function extman_Path()
    return extman_path
end

-- p = globtopattern(g)
--
-- Converts glob string (g) into Lua pattern string (p).
-- Always succeeds.
--
-- Warning: could be better tested.
--
-- (c) 2008 D.Manura, Licensed under the same terms as Lua (MIT License).
local function globtopattern(g)
  -- Some useful references:
  -- - apr_fnmatch in Apache APR.  For example,
  --   http://apr.apache.org/docs/apr/1.3/group__apr__fnmatch.html
  --   which cites POSIX 1003.2-1992, section B.6.

  local p = "^"  -- pattern being built
  local i = 0    -- index in g
  local c        -- char at index i in g.

  -- unescape glob char
  local function unescape()
    if c == '\\' then
      i = i + 1; c = g:sub(i,i)
      if c == '' then
        p = '[^]'
        return false
      end
    end
    return true
  end

  -- escape pattern char
  local function escape(c)
    return c:match("^%w$") and c or '%' .. c
  end

  -- Convert tokens at end of charset.
  local function charset_end()
    while 1 do
      if c == '' then
        p = '[^]'
        break
      elseif c == ']' then
        p = p .. ']'
        break
      else
        if not unescape() then break end
        local c1 = c
        i = i + 1; c = g:sub(i,i)
        if c == '' then
          p = '[^]'
          break
        elseif c == '-' then
          i = i + 1; c = g:sub(i,i)
          if c == '' then
            p = '[^]'
            break
          elseif c == ']' then
            p = p .. escape(c1) .. '%-]'
            break
          else
            if not unescape() then break end
            p = p .. escape(c1) .. '-' .. escape(c)
          end
        elseif c == ']' then
          p = p .. escape(c1) .. ']'
          break
        else
          p = p .. escape(c1)
          i = i - 1 -- put back
        end
      end
      i = i + 1; c = g:sub(i,i)
    end
  end

  -- Convert tokens in charset.
  local function charset()
    p = p .. '['
    i = i + 1; c = g:sub(i,i)
    if c == '' or c == ']' then
      p = p .. '[^]'
    elseif c == '^' or c == '!' then
      p = p .. '^'
      i = i + 1; c = g:sub(i,i)
      if c == ']' then
        -- ignored
      else
        charset_end()
      end
    else
      charset_end()
    end
  end

  -- Convert tokens.
  while 1 do
    i = i + 1; c = g:sub(i,i)
    if c == '' then
      p = p .. '$'
      break
    elseif c == '?' then
      p = p .. '.'
    elseif c == '*' then
      p = p .. '.*'
    elseif c == '[' then
      charset()
    elseif c == '\\' then
      i = i + 1; c = g:sub(i,i)
      if c == '' then
        p = p .. '\\$'
        break
      end
      p = p .. escape(c)
    else
      p = p .. escape(c)
    end
  end
  return p
end

-- use luafilesystem replace os.execute to filter files
local lfs = require"lfs"

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function scite_Files(path, ext)
    local files = {}
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")

            if attr.mode ~= "directory" and string.ends(file,ext) then
                files[#files+1] = f
            end
        end
    end
    return files
end

-- grab all directories in @path, excluding anything that matches @exclude_path
-- As a special exception, will also any directory called 'examples' ;)
function scite_Directories(path,exclude_pat)
    local files = {}
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")

            if not string.find(file,exclude_pat) then
                files[#files+1] = f
            end
        end
    end
    return files
end

function scite_FileExists(f)
    local attr = lfs.attributes (f)
    return attr
end

function scite_CurrentFile()
    return props['FilePath']
end

-- (Nicolas)
if GTK then
    function scite_DirectoryExists(path)
        return os.execute('test -d "'..path..'"') == 0
    end
else
    -- what is the Win32 equivalent??
    function scite_DirectoryExists(path)
        return true
    end
end

function split(s,delim)
    res = {}
    while true do
        p = find(s,delim)
        if not p then
            append(res,s)
            return res
        end
        append(res,sub(s,1,p-1))
        s = sub(s,p+1)
    end
end

function splitv(s,delim)
    return unpack(split(s,delim))
end

local idx = 10
local shortcuts_used = {}
local alt_letter_map = {}
local alt_letter_map_init = false
local name_id_map = {}

local function set_command(name,cmd,mode)
     local _,_,pattern,md = find(mode,'(.+){(.+)}')
     if not _ then
        pattern = mode
        md = 'savebefore:no'
     end
     local which = '.'..idx..pattern
     props['command.name'..which] = name
     props['command'..which] = cmd
     props['command.subsystem'..which] = '3'
     props['command.mode'..which] = md
     name_id_map[name] = 1100+idx
     return which
end

local function check_gtk_alt_shortcut(shortcut,name)
   -- Alt+<letter> shortcuts don't work for GTK, so handle them directly...
   local _,_,letter = shortcut:find('Alt%+([A-Z])$')
   if _ then
        alt_letter_map[letter:lower()] = name
        if not alt_letter_map_init then
            alt_letter_map_init = true
            scite_OnKey(function(key,shift,ctrl,alt)
                if alt and key < 255 then
                    local ch = string.char(key)
                    if alt_letter_map[ch] then
                        scite_MenuCommand(alt_letter_map[ch])
                    end
                end
            end)
        end
    end
end

local function set_shortcut(shortcut,name,which)
    if shortcut == 'Context' then
        local usr = 'user.context.menu'
        if props[usr] == '' then -- force a separator
            props[usr] = '|'
        end
        props[usr] = props[usr]..'|'..name..'|'..(1100+idx)..'|'
    else
       local cmd = shortcuts_used[shortcut]
       if cmd then
            print('Error: shortcut already used in "'..cmd..'"')
       else
           shortcuts_used[shortcut] = name
           if GTK then check_gtk_alt_shortcut(shortcut,name) end
           props['command.shortcut'..which] = shortcut
       end
     end
end

-- allows you to bind given Lua functions to shortcut keys
-- without messing around in the properties files!
-- Either a string or a table of strings; the string format is either
--      menu text|Lua command|shortcut
-- or
--      menu text|Lua command|mode|shortcut
-- where 'mode' is the file extension which this command applies to,
-- e.g. 'lua' or 'c', optionally followed by {mode specifier}, where 'mode specifier'
-- is the same as documented under 'command.mode'
-- 'shortcut' can be a usual SciTE key specifier, like 'Alt+R' or 'Ctrl+Shift+F1',
-- _or_ it can be 'Context', meaning that the menu item should also be added
-- to the right-hand click context menu.
function scite_Command(tbl)
  if type(tbl) == 'string' then
     tbl = {tbl}
  end
  for i,v in pairs(tbl) do
     local name,cmd,mode,shortcut = splitv(v,'|')
     if not shortcut then
        shortcut = mode
        mode = '.*'
     else
        mode = '.'..mode
     end
     -- has this command been defined before?
     local old_idx = 0
     local ii=0
     repeat
        if props['command.name.'..ii..mode] == name then
            old_idx = ii
            --print('*** Found', ii, name, props['command.name.'..ii..mode])
        end
        ii = ii + 1
     until old_idx==0 and ii<100

     --print('TRY add',old_idx,name)
     --print(name, old_idx, idx)
     if old_idx == 0 then
        local which = set_command(name,cmd,mode)
        if shortcut then
            set_shortcut(shortcut,name,which)
        end
        idx = idx + 1
    end
  end
end


-- use this to launch Lua Tool menu commands directly by name
-- (commands are not guaranteed to work properly if you just call the Lua function)
function scite_MenuCommand(cmd)
    if type(cmd) == 'string' then
        cmd = name_id_map[cmd]
        if not cmd then return end
    end
    scite.MenuCommand(cmd)
end

local loaded = {}
local current_filepath

-- this will quietly fail....
local function silent_dofile(f)
    if scite_FileExists(f) then
        if not loaded[f] then
            _ = dofile(f)
            loaded[f] = _ and _ or false
        end
        return loaded[f]
    else
        print('Not Exist:' .. f)
        print(debug.traceback(2))
    end
    return false
end

function scite_dofile(f)
    f = extman_path()..'/'..f
    silent_dofile(f)
end

function scite_require(f)
    local path = lua_path..dirsep..f
    local mod = silent_dofile(path)
    if not mod then
        mod = silent_dofile(current_filepath..dirsep..f)
    end
    return mod
end

if not scite_DirectoryExists(lua_path) then
    print('Error: directory '..lua_path..' not found')
    return
end

function load_script_list(script_list,path)
    if not script_list then
      print('Error: no files found in '..path)
    else
      current_filepath = path
      for i,file in pairs(script_list) do
        silent_dofile(file)
      end
    end
end

-- Load all scripts in the lua_path (usually 'scite_lua'), including within any subdirectories
-- that aren't 'examples' or begin with a '_'
local script_list = scite_Files(lua_path..dirsep, '.lua')
load_script_list(script_list,lua_path)
local dirs = scite_Directories(lua_path,'^_')
for i,dir in ipairs(dirs) do
    load_script_list(scite_Files(dir..dirsep, '.lua'),dir)
end

function scite_WordAtPos(pos)
    if not pos then pos = editor.CurrentPos end
    local p2 = editor:WordEndPosition(pos,true)
    local p1 = editor:WordStartPosition(pos,true)
    if p2 > p1 then
        return editor:textrange(p1,p2)
    end
end

function scite_GetSelOrWord()
    local s = editor:GetSelText()
    if s == '' then
        return scite_WordAtPos()
    else
        return s
    end
end

--~ scite_Command 'Reload Script|reload_script|Shift+Ctrl+R'

--~ function reload_script()
--~    current_file = scite_CurrentFile()
--~    print('Reloading... '..current_file)
--~    loaded[current_file] = false
--~    silent_dofile(current_file)
--~ end

--~ require"remdebug.engine"
--~ remdebug.engine.start()
