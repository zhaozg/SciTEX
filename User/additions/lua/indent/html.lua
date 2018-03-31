local htmltidy = require "htmltidy"
local io = require'enhance.io'

local function fix_raw(node, sep)
  return node[1]
end

function tohaml (tab, indent, space)
  local indent = indent or 0
  local space = space or '  '
  local sub, attr, strs = {}, {}, {}
  local n, k = #tab
  if n > 0 then
    local isstr = true
    for i = 1, n do
      if type(tab[i]) == 'table' then
        isstr = false
      end
    end
    if isstr then
      sub = {
        table.concat(tab, ' '):gsub('\r', ''):gsub('\n', ''):gsub('%s+', ' '):trim(),
      }
    else
      n = #tab
      for i = 1, n do
        if type(tab[i]) == 'table' then
          local tag = tab[i].tag
          local sep = '\n' .. string.rep(space, indent + 1)
          if tag == 'script' then
            if #tab[i] == 0 then
              sub[i] = '\n' .. tohaml(tab[i], indent + 1, space)
            else
              io.print_r(tab[i])
              sub[i] = sep .. ':javascript\n' .. fix_raw(tab[i], sep .. space)
            end
          elseif tag == 'style' then
            if #tab[i] == 0 then
              sub[i] = '\n' .. tohaml(tab[i], indent + 1, space)
            else
              sub[i] = sep .. ':css\n' .. fix_raw(tab[i], sep .. space)
            end
          elseif tag == 'textarea' then
            sub[i] = sep .. ':textarea' .. sep .. space .. ':preserve\n' .. fix_raw(tab[i], sep .. space .. space)
          else
            sub[i] = '\n' .. tohaml(tab[i], indent + 1, space)
          end
        else
          sub[i] = tab[i]:gsub('\r', ''):gsub('\n', ''):gsub('%s+', ' '):trim()
          if #sub[i] > 0 and i > 1 then
            sub[i] = '\n' .. string.rep(space, indent + 1) .. sub[i]
          end
        end
      end
    end
  end
  n = tab.attr and #tab.attr or 0
  if n > 0 then
    for i = 1, n do
      k = tab.attr[i]
      attr[i] = string.format('%s="%s"', k, tab.attr[k])
    end
    if #sub > 0 then
      sub = table.concat(sub)
      if sub:byte(1) ~= 10 then
        sub = ' ' .. sub
      end
      return string.rep(space, indent) .. string.format('%%%s(%s)', tab.tag, table.concat(attr, ' ')) .. sub
    else
      return string.rep(space, indent) .. string.format('%%%s(%s)', tab.tag, table.concat(attr, ' '))
    end
  else
    if #sub > 0 then
      sub = table.concat(sub)
      if sub:byte(1) ~= 10 then
        sub = ' ' .. sub
      end
      return string.rep(space, indent) .. string.format('%%%s%s', tab.tag, sub)
    else
      return string.rep(space, indent) .. string.format('%%%s/', tab.tag)
    end
  end
end

return function (text, ext)
  local tidy = htmltidy.new()
  tidy:setOpt(htmltidy.opt.WrapLen, 0)
  local t = assert(tidy:parse(text))
  print('errorSummary', tidy:errorSummary())
  print('generalInfo', tidy:generalInfo())
  print('accessWarningCount', tidy:accessWarningCount())
  local t = tidy:toTable()
  if #t == 1 and (not t.tag) then
    t = t[1]
  end
  return tohaml(t)
end
