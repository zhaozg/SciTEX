 --scite_Command('Last Command|do_command_list|Ctrl+Alt+P')

 local prompt = '> '
 local history_len = 4
 local prompt_len = string.len(prompt)
 print 'Scite/Lua'
 trace(prompt)

 function load(file)
	if not file then file = props['FilePath'] end
	dofile(file)
 end

 function edit(file)
	scite.Open(file)
 end

 local sub = string.sub
 local commands = {}

 local function strip_prompt(line)
   if sub(line,1,prompt_len) == prompt then
        line = sub(line,prompt_len+1)
    end
	return line
 end

 scite_OnOutputLine (function (line)
   line = strip_prompt(line)
    table.insert(commands,1,line)
    if table.getn(commands) > history_len then
        table.remove(commands,history_len+1)
    end
    if sub(line,1,1) == '=' then
        line = 'print('..sub(line,2)..')'
    end
    print('LINE',line)
    if(_G[line]) then
     local f,err = loadstring(line,'local')
     if not f then
       print(err)
     else
       local ok,res = pcall(f)
       if ok then
          if res then print('result= '..res) end
       else
          print(res)
       end
     end
     trace(prompt)
    else
     print('EXTERN',line)
     runfile(string.format('additions\\extman\\cmd\\%s.lua',line))
    end
    return true
end)

function insert_command(cmd)
	output:AppendText(cmd)
	output:GotoPos(output.Length)
end

function do_command_list()
 if table.getn(commands) > 1 then
  scite_UserListShow(commands,1,insert_command)
 end
end
