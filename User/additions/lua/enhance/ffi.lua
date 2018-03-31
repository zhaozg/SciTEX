local ffi = require'ffi'
require 'enhance.io'

ffi.include = function (incfile,stack)
	local d = debug.getinfo(stack or 2)
	local p = d.source --  @e:\work\luaapps\PBOC\lib\HSM\Driver.lua
	p = string.sub(p,2,-1)
	p = string.gsub(p,"\\",'/')

	local s, e = nil,0
	repeat  
		s = e
		e = string.find(p,'/', s+1)
	until e==nil
	
	p1 = s and (p:sub(1,s)..incfile) or incfile
	local c = io.loaddata(p1)
	if (c) then
		ffi.cdef(c)
	end
	return c
end

ffi.load = function(path)
	if(ffi.os=="Linux") then
	    return string.gsub(path, "%..-$",".so")
	elseif (ffi.os=="Windows") then
	    return string.gsub(path, "%..-$",".dll")
	else
	    assert(nil,"not support "..ffi.os)
	end
end

ffi.ntohl = ffi.abi("le") and bit.bswap or function(x) return x end
ffi.ntohs = ffi.abi("le") and function(x) return bit.bor(bit.lshift(bit.band(x,0xFF),8) ,bit.rshift(bit.band(x,0xFF00),8))   end  or function(x) return x end

return ffi
