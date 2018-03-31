--encoding: utf-8
local io = require 'enhance.io'
local string = require 'enhance.string'
--css

---html2haml

local function fix_raw (tab, sep)
  local s = #tab > 0 and table.concat(tab) or ''
  if #s > 0 then
    if tab.tag == 'style' then
      local css = parse_css(s)
      s = serialize_css(css)
    end
  end
  return sep:gsub('\n', '') .. s:gsub('\n', sep) .. '\n'
end


-------------------
local function getExtAlias (ext)
  local htmls = {
    ['html'] = true,
    ['lhtml'] = true,
    ['jsp'] = true,
    ['haml'] = true
  }
  if htmls[ext] then
    return 'html'
  end
  return ext
end

function indent_code ()
  local ext = props['FileExt']
  if ext == '' then
    return
  end
  ext = getExtAlias(ext)
  local formater = require('indent.' .. ext)
  print('indent.' .. ext, formater)

  if formater and type(formater) == 'function' then
    local text = editor:GetSelText()
    local partial = true
    if text == '' then
      text = editor:GetText()
      partial = false
    end

    local text, err = formater(text)
    if not text then
      print('indent error:' .. (err or 'unknown'))
      return
    end
    if partial then
      editor:ReplaceSel(text .. '\n')
    else
      editor:SetText(text)
    end
  end
end

scite_Command '代码_格式化|indent_code|Ctrl+Shift+I'
