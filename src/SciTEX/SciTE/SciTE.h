BOOL CALLBACK CheckSciteWindow(HWND  hwnd, LPARAM  lParam);
BOOL CALLBACK CheckContainerWindow(HWND  hwnd, LPARAM  lParam);

void subclass_scite_window ();
void OutputMessage(lua_State *L);

extern CWindow* hWndSCiTE;
extern CWindow *hWndScintilla;
extern CPaneContainer *hWndExtra;
extern CWindow *hWndContent;
CSplitterWindow* SetupSciTEX(lua_State*L);
