T= SciTEX

# Lua includes and lib
LUA_INC= ..\luajit\src
LUA_LIB= ..\luajit\src\lua51.lib

# Openssl include and lib
OPENSSL_INC=
OPENSSL_LIB=

LIBNAME= $T.dll

# Compilation directives
WARN= /O2
INCS= /I$(LUA_INC) /I$(OPENSSL_INC) /Ideps
CFLAGS= /MT /DUNICODE $(WARN) $(INCS)
CC= cl


OBJS=SciTEX.obj gui\gui_ext.obj gui\yawl\twl.obj gui\yawl\twl_cntrls.obj \
gui\yawl\twl_data.obj gui\yawl\twl_dialogs.obj gui\yawl\twl_ini.obj \
gui\yawl\twl_layout.obj gui\yawl\twl_menu.obj gui\yawl\twl_modal.obj \
gui\yawl\twl_splitter.obj gui\yawl\twl_toolbar.obj \
lpeg\lpcap.obj lpeg\lpcode.obj lpeg\lpprint.obj lpeg\lptree.obj lpeg\lpvm.obj\
lfs\src\lfs.obj 

LIBS=ws2_32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib \
advapi32.lib Comctl32.lib shell32.lib

lib: $T.dll

.cxx.obj:
	$(CC) /nologo /c /DLUA_BUILD_AS_DLL /DLUA_LIB /Fo$@ $(CFLAGS) $<

.cpp.obj:
	$(CC) /nologo /c /DLUA_BUILD_AS_DLL /DLUA_LIB /Fo$@ $(CFLAGS) $<

.c.obj:
	$(CC) /nologo /c /DLUA_BUILD_AS_DLL /DLUA_LIB /Fo$@ $(CFLAGS) $<

$T.dll: $(OBJS)
	link /DLL /out:$T.dll $(OBJS) $(LUA_LIB) $(OPENSSL_LIB) $(LIBS)
	IF EXIST $T.dll.manifest mt -manifest $T.dll.manifest -outputresource:$T.dll;2

install: $T.dll
	IF NOT EXIST $(LUA_LIBDIR) mkdir $(LUA_LIBDIR)
	copy $T.dll $(LUA_LIBDIR)

clean:
	del $T.dll $(OBJS) $T.lib $T.exp
	IF EXIST $T.dll.manifest del $T.dll.manifest