#if defined(_WIN32) && defined(_MSC_VER)
#pragma warning(disable: 4505)
#endif

#include "../src/lua-compat-5.3/c-api/compat-5.3.h"
#include "scite_lua_win.h"
#undef lua_pushglobaltable

#include "LuaExtension.cxx"
