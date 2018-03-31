local lpeg = require "lpeg"

local concat = table.concat

local V, R, S, P, C, Ct = lpeg.V, lpeg.R, lpeg.S, lpeg.P, lpeg.C, lpeg.Ct
lpeg.locale(lpeg)

------------------------------------
-- alnum, alpha, cntrl, digit, graph, lower, print, punct, space, upper, xdigit
-- *: 0 or more
-- +: 1 or more
-- ?: 0 or 1
-- |: separates alternatives
-- [ ]: grouping

local digit = lpeg.digit
local nmstart = lpeg.alpha + P('_')
local nmchar = lpeg.alnum + S('_-.')
local minus = S('-')
local IDENT = nmstart * nmchar^0
local NUMBER = digit^1 * digit^0 * P(".") * digit^1
local ws = S(' \t')
local nl = P('\n')
local comment = P("/*") * (1-P("*/"))^0 * P("*/")
local ws_or_nl = ws + nl
local SP = ws_or_nl + comment
local STRING = C(P('"') * ( 1-P('"') )^0 * P('"'))
local URI = C(P("url(") * ( 1-P(")") )^0 * P(")"))

local hex = lpeg.xdigit
local hexcolor = "#" * hex^-6  + "#" * hex^3
local medium = IDENT * SP^0
local medium_list = medium * (P(",") * SP^0 * medium)^0

local function FLATTEN (pattern)
  return Ct(pattern) / concat;
end

local css = P {
  V('program'),

  program = SP^0 * V('stylesheet'),
  stylesheet = V('stmt')^0,
  stmt = V('rule') + V('media'),
  rule = V('rule_lhs') * V('rule_rhs'),
  rule_lhs = V('selector') * V('more_selector')^0,
  more_selector = P(",") * SP^0 * V('selector'),
  rule_rhs = SP^0,
  decls = SP^0 * V('declaration') * V('more_declaration')^0,
  more_declaration = P(";") * SP^0 * V('declaration'),

  selector = FLATTEN(V('simple_selector') *  V('selector_trailer')^-1),
  selector_trailer = V('selector_trailer_a') + V('selector_trailer_b') + V('selector_trailer_c') + V('selector_trailer_d'),
  selector_trailer_a = V('combinator') * V('selector'),
  selector_trailer_b = SP^1 * V('combinator') * V('selector'),
  selector_trailer_c = SP^1 * V('selector'),
  selector_trailer_d = SP^1,

  simple_selector = V('element_name') * V('simple_selector_etc')^0 + V('simple_selector_etc')^1,
  simple_selector_etc = V('id_selector') + V('class_selector') + V('attrib_selector') + V('pseudo_selector'),

  element_name = V('element_selector') + V('wild_element_selector'),
  element_selector = IDENT,
  wild_element_selector = P("*"),

  id_selector     = P("#") * IDENT,
  class_selector  = P(".") * IDENT,
  attrib_selector = P("[") * SP^0 * IDENT * ( (P("=") + P("~=") + P("|=") ) * SP^0 * ( IDENT + STRING ) * SP^0)^-1 * P("]"),
  pseudo_selector = P(":") * IDENT,
  tbd_pseudo_selector = P(":") * IDENT * ( P("(") * ( IDENT * SP^0 )^-1 * P(")") )^-1,

  combinator = P("+") * SP^0 + P(">") * SP^0,

  declaration = V('property') * P(":") * SP^0 * V('expr') * V('prio')^-1,
  property = IDENT * SP^0,
  prio = P("!") * SP^0,
  expr = V('term') * ( V('operator')^-1 * V('term') )^0,
  operator = V('operator_a') * SP^0,
  operator_a =  P("/") + P(","),
  term = V('unary_op') * V('measure') + V('measure') + V('other_term'),
  unary_op = P("-") + P("+"),
  measure = V('mess') * SP^0,
  mess =  V('em_m') + V('ex_m') + V('px_m') + V('cm_m') + V('mm_m') + V('in_m')
        + V('pt_m') + V('pc_m') + V('deg_m') + V('rad_m') + V('grad_m')
        + V('ms_m') + V('s_m') + V('hx_m') + V('khz_m') + V('precent_m')
        + V('dim_m') + V('raw_m'),
  em_m = NUMBER * "em",
  ex_m = NUMBER * "ex",
  px_m = NUMBER * "px",
  cm_m = NUMBER * "cm",
  mm_m = NUMBER * "mm",
  in_m = NUMBER * "in",
  pt_m = NUMBER * "pt",
  pc_m = NUMBER * "pc",
  deg_m = NUMBER * "deg",
  rad_m = NUMBER * "rad",
  grad_m = NUMBER * "grad",
  ms_m = NUMBER * "ms",
  s_m = NUMBER * "s",
  hx_m = NUMBER * "hz",
  khz_m = NUMBER * "khz",
  precent_m = NUMBER * "%",
  dim_m = NUMBER * IDENT,
  raw_m = NUMBER,

  other_term = STRING * SP^0  + URI * SP^0  + IDENT * SP^0  + hexcolor * SP^0  + V('function_def'),

  function_def = IDENT * "(" * SP^0 * V('expr') * ")" * SP^0,
  media = P("@media") * SP^0 * medium * "{" *  SP^0 * V('stylesheet') * "}"
}

--error handle
--[[
local function verify(subject, position, captures)
    print(subject, position, captures)
	if position < #subject then
		local errornode = {
			'error:',
			subject,
			string.rep("_", position) .. "^"
		}
		print(unpack(table.concat(errornode, "\n")))
		table.insert(captures, errornode)
		return position, captures
	end
	return position, captures
end
d = lpeg.Cmt(lpeg.P (grammar) / io.write, verify)
--]]


---
local function format (input)
    -- DEBUG = true
    -- IN_PLACE = true

    local function filter (input)
        local filtered, err = css:match(input)
        if not filtered then
            io.stderr:write(("could not filter: %s\n"):format(err))
        end
        return filtered
    end

    local filtered, err = filter(input)
    return filtered, err
end

return format

--[[
local io = require'enhance.io'

d = P(css)/io.write

aa = d:match (io.loaddata(assert(arg[1])))
print(aa)
io.print_r(aa)

for k,v in pairs(aa) do
  print(k,v)
end
--]]
