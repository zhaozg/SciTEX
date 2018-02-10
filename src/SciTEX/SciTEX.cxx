extern "C" {
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}
#include <windows.h>
#include <shlwapi.h>
#include <WinUser.h>

struct W2MB
{
  W2MB(const wchar_t *src, int cp)
    : buffer(0)
  {
    int len = ::WideCharToMultiByte(cp, 0, src, -1, 0, 0, 0, 0);
    if (len)
    {
      buffer = new char[len];
      len = ::WideCharToMultiByte(cp, 0, src, -1, buffer, len, 0, 0);
    }
  }
  ~W2MB()
  {
    delete[] buffer;
  }
  const char *c_str() const
  {
    return buffer;
  }
private:
  char *buffer;
};

struct MB2W
{
  MB2W(const char *src, int cp)
    : buffer(0)
  {
    int len = ::MultiByteToWideChar(cp, 0, src, -1, 0, 0);
    if (len)
    {
      buffer = new wchar_t[len];
      len = ::MultiByteToWideChar(cp, 0, src, -1, buffer, len);
    }
  }
  ~MB2W()
  {
    delete[] buffer;
  }
  const wchar_t *c_str() const
  {
    return buffer;
  }
private:
  wchar_t *buffer;
};

static int internalConv(lua_State *L, bool toUTF8)
{
  bool success = false;
  if (lua_isstring(L, 1))
  {
    size_t len;
    const char *src = lua_tolstring(L, 1, &len);
    ptrdiff_t cp = luaL_optinteger(L, 2, CP_ACP);
    MB2W wc(src, toUTF8 ? cp : CP_UTF8);
    if (wc.c_str())
    {
      W2MB nc(wc.c_str(), toUTF8 ? CP_UTF8 : cp);
      if (nc.c_str())
      {
        lua_pushstring(L, nc.c_str());
        success = true;
      }
    }
  }
  if (!success)
    lua_pushnil(L);
  return 1;
}


int internalConv( lua_State *L, bool toUTF8 );
static int to_utf8( lua_State* L )
{
  return internalConv( L, true );
}

static int from_utf8( lua_State* L )
{
  return internalConv( L, false );
}


static luaL_Reg str_lib[] = {
  {"to_utf8",  to_utf8},
  {"from_utf8",  from_utf8},
  {NULL, NULL},
};

extern "C" {
  int luaopen_gui(lua_State *L);
  int luaopen_lfs (lua_State *L);
  int luaopen_lpeg (lua_State *L);
  int luaopen_spell(lua_State* L);
  int luaopen_winapi(lua_State *L);
  int luaopen_htmltidy(lua_State *L);  
}
extern "C"
LUA_API int luaopen_SciTEX(lua_State*L) {

  // Get package.preload so we can store builtins in it.
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "preload");
  lua_remove(L, -2); // Remove package

  lua_pushcfunction(L, luaopen_gui);
  lua_setfield(L, -2, "gui");

  lua_pushcfunction(L, luaopen_lpeg);
  lua_setfield(L, -2, "lpeg");

  lua_pushcfunction(L, luaopen_lfs);
  lua_setfield(L, -2, "lfs");
/*
  lua_pushcfunction(L, luaopen_spell);
  lua_setfield(L, -2, "spell");

  lua_pushcfunction(L, luaopen_htmltidy);
  lua_setfield(L, -2, "htmltidy");

  lua_pushcfunction(L, luaopen_winapi);
  lua_setfield(L, -2, "winapi");
*/
  luaL_register(L,"string", str_lib);
  lua_pop(L, 1);
 
  return 0;
}
