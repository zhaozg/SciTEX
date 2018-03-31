 --[[
local lpeg = require("lpeg")
local R, S, V, P
R, S, V, P = lpeg.R, lpeg.S, lpeg.V, lpeg.P
local C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp
C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp = lpeg.C, lpeg.Cs, lpeg.Ct, lpeg.Cmt, lpeg.Cg, lpeg.Cb, lpeg.Cc, lpeg.Cp
local make_string
make_string = function(delim)
  local d = P(delim)
  local inside = (P("\\" .. delim) + "\\\\" + (1 - d)) ^ 0
  return d * inside * d
end
local alphanum = R("az", "AZ", "09")
local num = R("09")
local hex = R("09", "af", "AF")
local white = S(" \t\n") ^ 0
local ident = (alphanum + S("_-")) ^ 1
local string_1 = make_string("'")
local string_2 = make_string('"')
local uri = P("url(") * white * (string_1 + string_2) * white * P(")")
local hash = P("#") * ident
local decimal = P(".") * num ^ 1
local number = decimal + num ^ 1 * (decimal) ^ -1
local dimension = num ^ 1 * ident
local percentage = num ^ 1 * P("%")
local numeric = dimension + percentage + number
local func_open = ident * P("(")
local delim = white * (P(",") * white) ^ -1
local decl_delim = white * P(";") * white
local mark
mark = function(name)
  return function(...)
    return {
      name,
      ...
    }
  end
end
local check_declaration
check_declaration = function(str, pos, chunk, prop, val)
  local type_pattern = allowed_properties[prop]
  if not (type_pattern) then
    return true, ""
  end
  local prop_types = to_type_string(val)
  if not (check_type(prop_types, type_pattern)) then
    return true, ""
  end
  return true, chunk
end
local declaration_list = P({
  V("DeclarationList"),
  Any = numeric / mark("number") + (string_1 + string_2) / mark("string") + uri / mark("url") + hash / mark("hash") + V("Function") / mark("function") + ident / mark("ident"),
  AnyList = V("Any") * (delim * V("Any")) ^ 0,
  Function = func_open * white * V("AnyList") * white * P(")"),
  Declaration = Cmt(C(C(ident) * white * P(":") * white * Ct(V("AnyList"))), check_declaration),
  DeclarationList = Ct(white * V("Declaration") * (decl_delim * V("Declaration")) ^ 0 * P(";") ^ -1)
})
local grammar = P({
  V("Root"),
  DeclarationList = declaration_list,
  Selector = ident,
  RuleSet = V("Selector") * white * P("{") * white * V("DeclarationList") ^ -1 * white * P("}"),
  Root = white * V("RuleSet") * (white * V("RuleSet")) ^ 0 * white * -P(1)
})
local style_pattern = declaration_list * P(-1)
local sanitize_style
sanitize_style = function(style)
  if not (style) then
    return nil, "missing style"
  end
  if style:match("^%s*$") then
    return ""
  end
  local chunks = style_pattern:match(style)
  if not (chunks) then
    return nil, "failed to parse"
  end
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #chunks do
      local chunk = chunks[_index_0]
      if chunk ~= "" then
        _accum_0[_len_0] = chunk
        _len_0 = _len_0 + 1
      end
    end
    chunks = _accum_0
  end
  return table.concat(chunks, "; ")
end
--]]  --[[
local lpeg = require("lpeg")
local R, S, V, P
R, S, V, P = lpeg.R, lpeg.S, lpeg.V, lpeg.P
local C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp
C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp = lpeg.C, lpeg.Cs, lpeg.Ct, lpeg.Cmt, lpeg.Cg, lpeg.Cb, lpeg.Cc, lpeg.Cp


local ws = S(' \t')
local nl = P('\n')
local hex = R('09afAF')
local comment = P("/*") * (1-P("*/"))^0 * P("*/")
local ws_or_nl = ws + nl
local SP = ws_or_nl + comment
local URI = P('url(') * (1-P(')'))^1 * P(')')
local hexcolor = P("#") * hex{6} +  P("#") * hex{3}

stylesheet <- stmt*
stmt <- rule / media
rule <- rule_lhs rule_rhs {(-> `(,a ,b) `(css-rule ,a -> ,@b))}
rule_lhs <- selector more_selector*  {(-> `(,a ,b) (if b `(or ,a ,@b) a))}
more_selector <-  "," S* selector {(-> `(,a ,b ,c) c)}
rule_rhs <- "{" decls  ";"? S* "}" S*  {(-> `(,a ,b ,c ,d ,e ,f) b)}
decls <- S* declaration more_declaration* {(-> `(,a ,b  ,c) `(,b ,@c))}
more_declaration <- ";" S* declaration {(-> `(,a ,b ,c) c)}

selector <- simple_selector selector_trailer? {(->`(,a ,b) (if (or (not b) (eq b 'METAPEG::OPTIONAL)) a `(,(car b) ,a ,(second b))))}
selector_trailer <- selector_trailer_a / selector_trailer_b / selector_trailer_c / selector_trailer_d
selector_trailer_a <- combinator selector
selector_trailer_b <- S+ combinator selector {(-> `(,a ,b ,c) `(,b ,c))}
selector_trailer_c <- S+ selector            {(-> `(,a ,b) `(decendent ,b))}
selector_trailer_d <- S+                     {(-> `(,a) nil)}

simple_selector <- element_name simple_selector_etc* {(-> `(,a ,b) (if b `(path ,a ,@b) a))} / simple_selector_etc+ {(-> `(,a) (if (cdr a) `(path ,@a) (first a)))}
simple_selector_etc <- id_selector / class_selector / attrib_selector / pseudo_selector

element_name <- element_selector / wild_element_selector
element_selector <- IDENT {(-> `(,a) `(element ,a))}
wild_element_selector <- "*" {(-> `(,a) '(element *))}

id_selector     <- "#" IDENT {(-> `(,a ,b) `(id ,b))}
class_selector  <- "." IDENT {(-> `(,a ,b) `(class ,b))}
attrib_selector <- "[" S* IDENT ( ("=" / "~=" / "|=" ) S* ( IDENT / STRING ) S*)? "]"
pseudo_selector <- ":" IDENT {(-> `(,a ,b) `(pseudo ,b))}
tbd_pseudo_selector <- ":" IDENT ( "(" ( IDENT S* )? ")" )?  {(-> `(,a ,b ,c ,d ,e) 'pseudo_selector_tbd)}

combinator <- "+" S* {(-> `(,a ,b) 'adjacent)} / ">" S* {(-> `(,a ,b) 'child)}

declaration <- property ":" S* expr prio?  {(-> `(,a ,b ,c ,d ,e) `(,a ,(if (eq 'metapeg::optional e) d `(priority ,d))))}
property <- IDENT S* { (-> `(,a ,b) a) }
prio <- "!" S* {(-> `(,a ,b) t)}
expr <- term ( operator? term )* {(-> `(,a ,b) (build-expr `(,a ,b)))}
operator <- operator_a S* {(-> `(,a ,b) a)}
operator_a <-  "/" {(-> `(,a) 'divide)} / "," {(-> `(,a) 'comma)}
term <- unary_op measure {(-> `(,a ,b) `(,a ,b))} / measure / other_term
unary_op <- "-" {(-> `(,a) '-)} / "+" {(-> `(,a) '+)}
measure <- mess S* { (-> `(,a ,b) a) }
mess <- em_m / ex_m / px_m / cm_m / mm_m / in_m / pt_m / pc_m / deg_m / rad_m / grad_m / ms_m / s_m / hx_m / khz_m / precent_m / dim_m / raw_m


other_term <- STRING S* {(-> `(,a ,b) a)} / URI S* {(-> `(,a ,b) a)} / IDENT S* {(-> `(,a ,b) a)}  / hexcolor S* {(-> `(,a ,b) a)} / function

function <- IDENT "(" S* expr ")" S* {(-> `(,a ,b ,c ,d ,e ,f) `(funcall ,a ,d))}
STRING <- ["] ( !["] . )* ["] {(-> `(,a ,b ,c) (coerce (mapcar #'second b) 'string))}



medium <- IDENT S* { (-> `(,a ,b) a) }
medium-list <- medium ("," S* medium)* {(-> `(,a ,b) `(,@a ,@(mapcar #'third b)))}
media <- "@media" S* medium "{" S* stylesheet "}"  { (-> `(,a,b,c,d,e,f,g)  `(media (,@c) ,@(rest f))) }

--]]  ------------------------------------------------------------------------------
 local function parse_css (data, light)
  local tbl = {}
  for cls, style in string.gmatch(data, '%s*(.-)%{(.-)%}') do
    if not light then
      style = string.split(style, ';')
    end
    if type(style) == 'table' then
      for k, v in pairs(style) do
        style[k] = v:gsub('%s*(.-)%s*', '%1')
      end
    else
      style = style:gsub('%s*(.-)%s*', '%1')
    end
    tbl[#tbl + 1] = {
      class = cls,
      style = style,

    }
  end
  return tbl
end

local function serialize_css (tbl, thin)
  local n = #tbl
  for i = 1, n do
    if thin then
      if type(tbl[i].style) == 'table' then
        tbl[i].style = table.concat(tbl[i].style, ';')
      end
      tbl[i] = string.format('%s {%s}', tbl[i].class, tbl[i].style)
    else
      if type(tbl[i].style) == 'table' then
        local m = #tbl[i].style
        for j = 1, m do
          tbl[i].style[j] = '\t' .. tbl[i].style[j]
        end
        tbl[i].style = table.concat(tbl[i].style, ';\n')
      end
      tbl[i] = string.format('%s\n{\n%s\n}\n\n', tbl[i].class, tbl[i].style)
    end
  end
  return table.concat(tbl)
end

local function format (input)
  --light = false
  local tab = parse_css(input)
  return serialize_css(tab)
end

return format
