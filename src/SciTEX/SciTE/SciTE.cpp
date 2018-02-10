#include <Windows.h>

static WNDPROC old_scite_proc = NULL, old_scintilla_proc = NULL, old_content_proc = NULL;
static lua_State *sL = NULL;

CWindow* hWndSCiTE = NULL;
CWindow *hWndScintilla = NULL;
CPaneContainer *hWndExtra = NULL;
CWindow *hWndContent = NULL;

CSplitterWindow *hWndSplitter = NULL;
static bool bLockResize = false;

BOOL CALLBACK CheckSciteWindow(HWND  hwnd, LPARAM  lParam)
{
  wchar_t buff[120];
  GetClassName(hwnd,buff,sizeof(buff));	
  if (wcscmp(buff,L"SciTEWindow") == 0) {
    *(HWND *)lParam = hwnd;
    return FALSE;
  }
  return TRUE;
}

BOOL CALLBACK CheckContainerWindow(HWND  hwnd, LPARAM  lParam)
{
  wchar_t buff[120];
  GetClassName(hwnd,buff,sizeof(buff));	
  if (wcscmp(buff,L"SciTEWindowContent") == 0) {
    *(HWND *)lParam = hwnd;
    return FALSE;
  }
  return TRUE;
}

// show a message on the SciTE output window
void OutputMessage(lua_State *L)
{
  if (lua_isstring(L,-1)) {
    size_t len;
    const char *msg = lua_tolstring(L,-1,&len);
    char *buff = new char[len+2];
    strncpy(buff,msg,len);
    buff[len] = '\n';
    buff[len+1] = '\0';
    lua_pop(L,1);
    if (lua_checkstack(L,3)) {
      lua_getglobal(L,"output");
      lua_getfield(L,-1,"AddText");
      lua_insert(L,-2);
      lua_pushstring(L,buff);
      lua_pcall(L,2,0,0);
    }
    delete[] buff;
  }
}

static int call_named_function(lua_State* L, const char *name, int arg)
{
  int ret = 0;
  lua_getglobal(L,name);
  if (lua_isfunction(L,-1)) {
    lua_pushinteger(L,arg);
    if (lua_pcall(L,1,1,0)) {
      OutputMessage(L);
    } else {
      ret = lua_toboolean(L,-1);
      lua_pop(L,1);
    }
  }
  lua_pop(L,1);
  return ret;
}

// we subclass the main SciTE window proc mostly because we need to track whether
// SciTE is the active app or not, so that toolwindows can be hidden.
static LRESULT SciTEWndProc(HWND hwnd, UINT iMessage, WPARAM wParam, LPARAM lParam)
{
#if 0

  else if (iMessage == WM_CLOSE) {
    call_named_function(sL,"OnClosing",0);
  } else if (iMessage == WM_COMMAND) {
    if (sL && call_named_function(sL,"OnCommand",LOWORD(wParam))) return TRUE;
  } 
#endif

  return CallWindowProc(old_scite_proc,hwnd,iMessage,wParam,lParam);
}

// we are interested in any attempts to resize the main code pane, because we
// may wish to place our own pane on the left.

static LRESULT ScintillaWndProc(HWND hwnd, UINT iMessage, WPARAM wParam, LPARAM lParam)
{
  if (iMessage == WM_SIZE && !bLockResize) {
    CRect rect;
    hWndContent->GetWindowRect(&rect);

    bLockResize = true;
    BOOL r = SendMessage(hWndSplitter->m_hWnd,iMessage,wParam,lParam);
    r = hWndSplitter->ResizeClient(rect.Width(),HIWORD(lParam));
    bLockResize = false;
  }
  
  if(0
    && iMessage!=WM_MOUSEFIRST 
    && iMessage!=WM_MOUSELEAVE 
    && iMessage!=WM_IME_SETCONTEXT
    && iMessage!=WM_IME_NOTIFY
    && iMessage!=WM_SETCURSOR
    && iMessage!=WM_PAINT
    && iMessage!=WM_KEYUP
    && iMessage!=WM_KEYFIRST
    && iMessage!=WM_NCMOUSEMOVE
    && iMessage!=WM_NCMOUSELEAVE
    && iMessage!=WM_GETICON
    && iMessage!=WM_ENTERIDLE
    && iMessage!=WM_GETMINMAXINFO
    && iMessage!=WM_MOVE
    && iMessage!=WM_MOVING
    && iMessage!=WM_ENTERSIZEMOVE
    && iMessage!=WM_EXITSIZEMOVE
    //&& iMessage!=WM_SIZE
    && iMessage!=WM_NCCALCSIZE
    //&& iMessage!=WM_SIZING
    && iMessage!=WM_NCCALCSIZE
    && iMessage!=WM_NCCALCSIZE
    && iMessage!=WM_PRINTCLIENT
    && iMessage!=WM_SETTEXT
    && iMessage!=0xae
    && iMessage!=0x93 && iMessage!=0x92 && iMessage!=0x91 && iMessage!=0x94
    && iMessage!=WM_ERASEBKGND
    && iMessage!=WM_NCHITTEST
    && iMessage!=WM_NCACTIVATE
    && iMessage!=WM_MENUSELECT
    && iMessage!=WM_NCPAINT
    && iMessage!=WM_UNINITMENUPOPUP
    && iMessage!=WM_CAPTURECHANGED
    && iMessage!=WM_MENUSELECT
    && iMessage!=WM_EXITMENULOOP
    && iMessage!=WM_WINDOWPOSCHANGING
    && iMessage!=WM_WINDOWPOSCHANGED
    && iMessage!=WM_ACTIVATEAPP
    && iMessage!=WM_ACTIVATE
    && iMessage!=WM_COMMAND
    && iMessage!=WM_NCLBUTTONDOWN
    && iMessage!=WM_SYSCOMMAND
    && iMessage!=WM_ENTERMENULOOP
    && iMessage!=WM_INITMENU
    && iMessage!=WM_INITMENUPOPUP
    && iMessage!=WM_INITMENUPOPUP
    && iMessage!=WM_COMMAND
    && iMessage!=WM_PARENTNOTIFY
    && iMessage!=WM_MOUSEACTIVATE
    && iMessage!=WM_NOTIFY
    && iMessage!=WM_CHILDACTIVATE
    && iMessage!=WM_LBUTTONDOWN
    && iMessage!=WM_SETFOCUS
    && iMessage!=WM_CHAR
    && iMessage!=WM_TIMER
    && iMessage!=WM_KILLFOCUS) {
      char buf[MAX_PATH] = {0};
      strcpy(buf,TranslateWMessage(iMessage));
      buf[strlen(buf)]='\n';
      OutputDebugStringA(buf);
  }
  return CallWindowProc(old_scintilla_proc,hwnd,iMessage,wParam,lParam);
}

// the content pane contains the two Scintilla windows (editor and output).
// This subclass prevents SciTE from forcing its dragger cursor onto our left pane.
static LRESULT ContentWndProc(HWND hwnd, UINT iMessage, WPARAM wParam, LPARAM lParam)
{
  if (iMessage == WM_SETCURSOR) {
    CPoint ptCursor;
    GetCursorPos(&ptCursor);
    hWndExtra->ScreenToClient(&ptCursor);
    CRect rect;
    hWndExtra->GetClientRect(&rect);
    if (rect.PtInRect(ptCursor)) {
      return DefWindowProc(hWndSCiTE->m_hWnd,iMessage,wParam,lParam);
    }
  }
  return CallWindowProc(old_content_proc,hwnd,iMessage,wParam,lParam);
}

static WNDPROC subclass(HWND hwnd, LONG_PTR newproc)
{
  WNDPROC old = reinterpret_cast<WNDPROC>(GetWindowLongPtr(hwnd, GWLP_WNDPROC));
  SetWindowLongPtr(hwnd, GWLP_WNDPROC, newproc);
  
  return old;
}

void subclass_scite_window ()
{
  static bool subclassed = false;
  if (!subclassed) {  // to prevent a recursion
    old_scite_proc     = subclass(hWndSCiTE->m_hWnd,   (long)SciTEWndProc);
    old_content_proc   = subclass(hWndContent->m_hWnd, (long)ContentWndProc);
    old_scintilla_proc = subclass(hWndScintilla->m_hWnd,    (long)ScintillaWndProc);
    subclassed = true;
  }
}


 CSplitterWindow* SetupSciTEX(lua_State*L) {
   if (hWndSCiTE==NULL) {
     HWND hSciTE, hContent, hCode;
     EnumWindows(CheckSciteWindow,(long)&hSciTE);
     //if(EnumThreadWindows(GetCurrentThreadId(),CheckSciteWindow,(long)&hSciTE))
     if(hSciTE){
       hWndSCiTE = new CWindow(hSciTE);
       EnumChildWindows(hSciTE,CheckContainerWindow,(long)&hContent);
       if(hContent)
       {
         // the first child of the content pane is the editor pane.
         if (hContent != NULL) {
           hWndContent = new CWindow(hContent);
           hCode = GetWindow(hContent,GW_CHILD);
           if (hCode != NULL) {
             hWndScintilla = new CWindow(hCode);		
             subclass_scite_window();
           }
         }
       }
     }
   }
  if (hWndExtra==NULL && 1) {
    CRect rcVert;
    hWndContent->GetClientRect(&rcVert);

    hWndSplitter = new CSplitterWindow();
    hWndSplitter->Create(hWndContent->m_hWnd,&rcVert,NULL, 
      WS_VISIBLE | WS_CHILD | WS_CLIPSIBLINGS | WS_CLIPCHILDREN);
    hWndSplitter->m_cxySplitBar = 5;
    hWndSplitter->m_cxyMin = 35; // minimum size
    //hWndSplitter->SetSplitterPos(85); // from left
    hWndSplitter->m_bFullDrag = false; // ghost bar enabled

    CPaneContainer* extra = new CPaneContainer();
    extra->Create(hWndSplitter->m_hWnd, L"", WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | WS_CLIPCHILDREN);

    hWndScintilla->SetParent(hWndContent->m_hWnd);
    //hWndSplitter->SetSplitterPanes(extra->m_hWnd,hWndSplitter->m_hWnd);
    hWndSplitter->SetSplitterPane(0, extra->m_hWnd);
    hWndSplitter->SetSplitterPane(1, hWndScintilla->m_hWnd);

    hWndExtra = extra;

    if (old_scite_proc == NULL 
      ||old_scintilla_proc == NULL 
      ||old_content_proc == NULL) {
        hWndSCiTE->MessageBox(L"Cannot subclass SciTE Window");
        return NULL;
    }
  }
  sL = L;
  return hWndSplitter;
}
