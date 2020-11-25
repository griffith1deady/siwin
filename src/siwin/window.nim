import times, os, strformat
import with
import image
when defined(linux):
  import libx11 as x
when defined(windows):
  import libwinapi
  type Color = image.Color

type
  MouseButton* {.pure.} = enum
    left right middle forward backward
  Mouse* = tuple
    position: tuple[x, y: int]
    pressed: array[MouseButton.left..MouseButton.backward, bool]
  Key* {.pure.} = enum
    unknown = -1
    a = 0, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z,
    n0, n1, n2, n3, n4, n5, n6, n7, n8, n9,
    escape, lcontrol, lshift, lalt, lsystem, rcontrol, rshift, ralt, rsystem, menu, lbracket, rbracket,
    semicolon, comma, dot, quote, slash, backslash, tilde, equal, minus, space, enter, backspace, tab,
    pageUp, pageDown, End, home, insert, del, add, subtract, multiply, divide, left, right, up, down,
    numpad0, numpad1, numpad2, numpad3, numpad4, numpad5, numpad6, numpad7, numpad8, numpad9,
    f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15, pause
  Keyboard* = tuple
    pressed: array[Key.a..Key.pause, bool]
    
  Cursor* {.pure.} = enum
    arrow arrowUp
    hand
    sizeAll sizeHorisontal sizeVertical

  Window* = object
    m_data: ArrayPtr[Color]
    m_size: tuple[x, y: int]

    onClose*:       proc(e: CloseEvent)
    
    onRender*:      proc(e: RenderEvent)
    onFocus*:       proc(e: FocusEvent)
    onTick*:        proc(e: TickEvent)
    onResize*:      proc(e: ResizeEvent)
    onWindowMove*:  proc(e: WindowMoveEvent)

    mouse*: Mouse # состояние мыши
    onMouseMove*:   proc(e: MouseMoveEvent)
    onMouseLeave*:  proc(e: MouseMoveEvent)
    onMouseEnter*:  proc(e: MouseMoveEvent)
    onMouseDown*:   proc(e: MouseButtonEvent)
    onMouseUp*:     proc(e: MouseButtonEvent)
    onClick*:       proc(e: ClickEvent)
    onDoubleClick*: proc(e: ClickEvent)
    onScroll*:      proc(e: ScrollEvent)

    keyboard*: Keyboard # состояние клавиатуры
    onKeydown*:     proc(e: KeyEvent)
    onKeyup*:       proc(e: KeyEvent)
    onTextEnter*:   proc(e: TextEnterEvent)

    when defined(linux):
      screen: cint
      xwin: x.Window
      gc: x.GC
      gcv: x.XGCValues
      ximg: x.PXImage
      xicon: x.Pixmap
      xiconMask: x.Pixmap
      xinContext: x.XIC
      xinMethod: x.XIM

      xcursor: x.Cursor
      curCursor: Cursor
      clicking: array[MouseButton.left..MouseButton.backward, bool]

      m_isOpen: bool
      m_hasFocus: bool
      m_isFullscreen: bool

      waitForReDraw: bool

      m_pos: tuple[x, y: int]

    elif defined(windows):
      handle: HWnd
      wimage: HBitmap
      hdc: HDC
      
      wcursor: HCursor
      curCursor: Cursor
      wicon: HIcon

      m_hasFocus: bool
      m_isOpen: bool
      m_isFullscreen: bool

  CloseEvent* = tuple

  RenderEvent* = tuple
    data: ArrayPtr[Color]
    size: tuple[x, y: int]
  ResizeEvent* = tuple
    oldSize, size: tuple[x, y: int]
  WindowMoveEvent* = tuple
    olsPositin, position: tuple[x, y: int]

  MouseMoveEvent* = tuple
    mouse: Mouse
    oldPosition, position: tuple[x, y: int]
  MouseButtonEvent* = tuple
    mouse: Mouse
    button: MouseButton
    pressed: bool
  ClickEvent* = tuple
    mouse: Mouse
    button: MouseButton
    doubleClick: bool
  ScrollEvent* = tuple
    mouse: Mouse
    delta: float ## 1: scroll down, -1: scroll up

  FocusEvent* = tuple
    focused: bool

  TickEvent* = tuple
    mouse: Mouse
    keyboard: Keyboard
    deltaTime: Duration

  KeyEvent* = tuple
    keyboard: Keyboard
    key: Key
    pressed: bool
    alt, control, shift, system: bool
  TextEnterEvent* = tuple
    keyboard: Keyboard
    text: string # строка, т.к. введённый символ может быть закодирован в unicode

  Screen* = object
    when defined(linux):
      id: cint
      xid: PScreen


when defined(linux):
  proc xkeyToKey(sym: KeySym): Key =
    case sym
    of XK_shiftL:       Key.lshift
    of XK_shiftR:       Key.rshift
    of XK_controlL:     Key.lcontrol
    of XK_controlR:     Key.rcontrol
    of XK_altL:         Key.lalt
    of XK_altR:         Key.ralt
    of XK_superL:       Key.lsystem
    of XK_superR:       Key.rsystem
    of XK_menu:         Key.menu
    of XK_escape:       Key.escape
    of XK_semicolon:    Key.semicolon
    of XK_slash:        Key.slash
    of XK_equal:        Key.equal
    of XK_minus:        Key.minus
    of XK_bracketleft:  Key.lbracket
    of XK_bracketright: Key.rbracket
    of XK_comma:        Key.comma
    of XK_period:       Key.dot
    of XK_apostrophe:   Key.quote
    of XK_backslash:    Key.backslash
    of XK_grave:        Key.tilde
    of XK_space:        Key.space
    of XK_return:       Key.enter
    of XK_kpEnter:      Key.enter
    of XK_backspace:    Key.backspace
    of XK_tab:          Key.tab
    of XK_prior:        Key.page_up
    of XK_next:         Key.page_down
    of XK_end:          Key.End
    of XK_home:         Key.home
    of XK_insert:       Key.insert
    of XK_delete:       Key.del
    of XK_kpAdd:        Key.add
    of XK_kpSubtract:   Key.subtract
    of XK_kpMultiply:   Key.multiply
    of XK_kpDivide:     Key.divide
    of XK_pause:        Key.pause
    of XK_f1:           Key.f1
    of XK_f2:           Key.f2
    of XK_f3:           Key.f3
    of XK_f4:           Key.f4
    of XK_f5:           Key.f5
    of XK_f6:           Key.f6
    of XK_f7:           Key.f7
    of XK_f8:           Key.f8
    of XK_f9:           Key.f9
    of XK_f10:          Key.f10
    of XK_f11:          Key.f11
    of XK_f12:          Key.f12
    of XK_f13:          Key.f13
    of XK_f14:          Key.f14
    of XK_f15:          Key.f15
    of XK_left:         Key.left
    of XK_right:        Key.right
    of XK_up:           Key.up
    of XK_down:         Key.down
    of XK_kpInsert:     Key.numpad0
    of XK_kpEnd:        Key.numpad1
    of XK_kpDown:       Key.numpad2
    of XK_kpPagedown:   Key.numpad3
    of XK_kpLeft:       Key.numpad4
    of XK_kpBegin:      Key.numpad5
    of XK_kpRight:      Key.numpad6
    of XK_kpHome:       Key.numpad7
    of XK_kpUp:         Key.numpad8
    of XK_kpPageup:     Key.numpad9
    of XK_a:            Key.a
    of XK_b:            Key.b
    of XK_c:            Key.c
    of XK_d:            Key.d
    of XK_e:            Key.r
    of XK_f:            Key.f
    of XK_g:            Key.g
    of XK_h:            Key.h
    of XK_i:            Key.i
    of XK_j:            Key.j
    of XK_k:            Key.k
    of XK_l:            Key.l
    of XK_m:            Key.m
    of XK_n:            Key.n
    of XK_o:            Key.o
    of XK_p:            Key.p
    of XK_q:            Key.q
    of XK_r:            Key.r
    of XK_s:            Key.s
    of XK_t:            Key.t
    of XK_u:            Key.u
    of XK_v:            Key.v
    of XK_w:            Key.w
    of XK_x:            Key.x
    of XK_y:            Key.y
    of XK_z:            Key.z
    of XK_0:            Key.n0
    of XK_1:            Key.n1
    of XK_2:            Key.n2
    of XK_3:            Key.n3
    of XK_4:            Key.n4
    of XK_5:            Key.n5
    of XK_6:            Key.n6
    of XK_7:            Key.n7
    of XK_8:            Key.n8
    of XK_9:            Key.n9
    else:               Key.unknown

  template d: x.PDisplay = x.display

  proc malloc(a: culong): pointer {.importc.}

  proc getScreenCount*(): int = x.connected:
    result = display.ScreenCount.int
  template screenCount*: int = getScreenCount()

  proc `=destroy`(a: var Screen) =
    disconnect()
  {.experimental: "callOperator".}
  proc `()`*(a: Screen, n: int): Screen = with result:
    connect()
    if n notin 0..<screenCount: raise IndexDefect.newException(&"screen {n} is not exist")
    id = n.cint
    xid = d.ScreenOfDisplay(id)
  proc defaultScreen*(): Screen = x.connected:
    result = Screen()(d.DefaultScreen.int)
  let screen*: Screen = defaultScreen()
  proc n*(a: Screen): int = a.id.int

  proc size*(a: Screen): tuple[x, y: int] =
    result = (a.xid.width.int, a.xid.height.int)
  
  proc rootWindow(a: Screen): x.Window {.used.} = a.xid.root

elif defined(windows):
  proc wkeyToKey(key: WParam, flags: LParam): Key =
    case key
    of VK_shift:
      let lshift = MapVirtualKeyW(VK_shift, MAPVK_VK_TO_VSC)
      let scancode = flags and ((0xFF shl 16) shr 16)
      if scancode == lshift: Key.lshift else: Key.rshift
    of VK_menu:
      if (flags and KF_EXTENDED) != 0: Key.ralt else: Key.lalt
    of VK_control:
      if (flags and KF_EXTENDED) != 0: Key.rcontrol else: Key.lcontrol
    of VK_lwin:         Key.lsystem
    of VK_rwin:         Key.rsystem
    of VK_apps:         Key.menu
    of VK_escape:       Key.escape
    of VK_oem1:         Key.semicolon
    of VK_oem2:         Key.slash
    of VK_oem_plus:     Key.equal
    of VK_oem_minus:    Key.minus
    of VK_oem4:         Key.lbracket
    of VK_oem6:         Key.rbracket
    of VK_oem_comma:    Key.comma
    of VK_oem_period:   Key.dot
    of VK_oem7:         Key.quote
    of VK_oem5:         Key.backslash
    of VK_oem3:         Key.tilde
    of VK_space:        Key.space
    of VK_return:       Key.enter
    of VK_back:         Key.backspace
    of VK_tab:          Key.tab
    of VK_prior:        Key.page_up
    of VK_next:         Key.page_down
    of VK_end:          Key.End
    of VK_home:         Key.home
    of VK_insert:       Key.insert
    of VK_delete:       Key.del
    of VK_add:          Key.add
    of VK_subtract:     Key.subtract
    of VK_multiply:     Key.multiply
    of VK_divide:       Key.divide
    of VK_pause:        Key.pause
    of VK_f1:           Key.f1
    of VK_f2:           Key.f2
    of VK_f3:           Key.f3
    of VK_f4:           Key.f4
    of VK_f5:           Key.f5
    of VK_f6:           Key.f6
    of VK_f7:           Key.f7
    of VK_f8:           Key.f8
    of VK_f9:           Key.f9
    of VK_f10:          Key.f10
    of VK_f11:          Key.f11
    of VK_f12:          Key.f12
    of VK_f13:          Key.f13
    of VK_f14:          Key.f14
    of VK_f15:          Key.f15
    of VK_left:         Key.left
    of VK_right:        Key.right
    of VK_up:           Key.up
    of VK_down:         Key.down
    of VK_numpad0:      Key.numpad0
    of VK_numpad1:      Key.numpad1
    of VK_numpad2:      Key.numpad2
    of VK_numpad3:      Key.numpad3
    of VK_numpad4:      Key.numpad4
    of VK_numpad5:      Key.numpad5
    of VK_numpad6:      Key.numpad6
    of VK_numpad7:      Key.numpad7
    of VK_numpad8:      Key.numpad8
    of VK_numpad9:      Key.numpad9
    of 'A'.ord:         Key.a
    of 'B'.ord:         Key.b
    of 'C'.ord:         Key.c
    of 'D'.ord:         Key.d
    of 'E'.ord:         Key.r
    of 'F'.ord:         Key.f
    of 'G'.ord:         Key.g
    of 'H'.ord:         Key.h
    of 'I'.ord:         Key.i
    of 'J'.ord:         Key.j
    of 'K'.ord:         Key.k
    of 'L'.ord:         Key.l
    of 'M'.ord:         Key.m
    of 'N'.ord:         Key.n
    of 'O'.ord:         Key.o
    of 'P'.ord:         Key.p
    of 'Q'.ord:         Key.q
    of 'R'.ord:         Key.r
    of 'S'.ord:         Key.s
    of 'T'.ord:         Key.t
    of 'U'.ord:         Key.u
    of 'V'.ord:         Key.v
    of 'W'.ord:         Key.w
    of 'X'.ord:         Key.x
    of 'Y'.ord:         Key.y
    of 'Z'.ord:         Key.z
    of '0'.ord:         Key.n0
    of '1'.ord:         Key.n1
    of '2'.ord:         Key.n2
    of '3'.ord:         Key.n3
    of '4'.ord:         Key.n4
    of '5'.ord:         Key.n5
    of '6'.ord:         Key.n6
    of '7'.ord:         Key.n7
    of '8'.ord:         Key.n8
    of '9'.ord:         Key.n9
    else:               Key.unknown



when defined(linux):  
  proc `=destroy`*(a: var Window) = with a:
    if ximg != nil: xcheck XDestroyImage(ximg)
    if gc != nil: xcheck d.XFreeGC(gc)
    if xinContext != nil: XDestroyIC(xinContext)
    if xinMethod != nil: xcheck XCloseIM(xinMethod)
    if xcursor != 0: xcheck d.XFreeCursor(xcursor)
    if xicon != 0: xcheck d.XFreePixmap(xicon)
    if xiconMask != 0: xcheck d.XFreePixmap(xiconMask)
    if xwin != 0: xcheck d.XDestroyWindow(xwin)
    x.disconnect()

  proc newWindowImpl(w, h: int): Window = with result:
    x.connect()
    screen = d.DefaultScreen
    m_size = (w, h)
    xwin = d.XCreateSimpleWindow(d.DefaultRootWindow, 0, 0, w.cuint, h.cuint, 0, 0, d.BlackPixel(screen))
    doassert xwin != 0
    xcheck d.XSelectInput(xwin, 
      x.ExposureMask or x.KeyPressMask or x.KeyReleaseMask or x.PointerMotionMask or x.ButtonPressMask or
      x.ButtonReleaseMask or x.StructureNotifyMask or x.EnterWindowMask or x.LeaveWindowMask
    )
    xcheck d.XMapWindow xwin
    gc = d.XCreateGC(xwin, x.GCForeground or x.GCBackground, gcv.addr)

    xcheck d.XSetWMProtocols(xwin, x.patom(x.WM_DELETE_WINDOW), 1)

    xinMethod = d.XOpenIM(nil, nil, nil)
    if xinMethod != nil:
      xinContext = xinMethod.XCreateIC(
        x.XNClientWindow, xwin, x.XNFocusWindow, xwin, x.XNInputStyle, x.XIMPreeditNothing or x.XIMStatusNothing, nil
      )
    
    m_data = ArrayPtr[Color](cast[ptr Color](malloc(culong Color.sizeof * w * h)))
    ximg = d.XCreateImage(d.DefaultVisual(screen), d.DefaultDepth(screen).cuint, ZPixmap, 0, cast[cstring](cast[ptr Color](m_data)),
      w.cuint, h.cuint, 32, 0
    )
    doassert ximg != nil

    m_isOpen = true
    m_hasFocus = true
    m_isFullscreen = false

    waitForReDraw = true
    curCursor = arrow
  
  proc `title=`*(a: Window, title: string) = with a:
    let useUtf8 = x.atom(UTF8_STRING)
    xcheck d.XChangeProperty(xwin, x.atom(NET_WM_NAME), useUtf8, 8, PropModeReplace, title, title.len.cint)
    xcheck d.XChangeProperty(xwin, x.atom(NET_WM_ICON_NAME), useUtf8, 8, PropModeReplace, title, title.len.cint)

    d.Xutf8SetWMProperties(a.xwin, title, title, nil, 0, nil, nil, nil)
  
  proc opened*(a: Window): bool = a.m_isOpen
  proc close*(a: Window) = with a:
    var e: XEvent
    e.xclient.theType      = ClientMessage
    e.xclient.window       = xwin
    e.xclient.message_type = x.atom(WM_PROTOCOLS)
    e.xclient.format       = 32
    e.xclient.data.l[0]    = x.atom(WM_DELETE_WINDOW).clong
    e.xclient.data.l[1]    = CurrentTime
    xcheck d.XSendEvent(xwin, 0, NoEventMask, e.addr)

  proc updateGeometry(a: var Window) = with a:
    let (_, x, y, w, h, _, _) = xwin.getGeometry()
    m_pos = (x.int, y.int)
    m_size = (w.int, h.int)

    xcheck XDestroyImage ximg
    m_data = ArrayPtr[Color](cast[ptr Color](malloc(culong Color.sizeof * w.int * h.int)))
    ximg = d.XCreateImage(
      d.DefaultVisual(screen), d.DefaultDepth(screen).cuint, ZPixmap, 0, cast[cstring](cast[ptr Color](m_data)),
      w, h, 32, 0
    )
    doassert ximg != nil
    waitForReDraw = true
  
  proc fullscreen*(a: Window): bool = a.m_isFullscreen
  proc `fullscreen=`*(a: var Window, v: bool) = with a:
    if a.fullscreen == v: return

    var xwa: x.XWindowAttributes
    xcheck d.XGetWindowAttributes(xwin, xwa.addr)
    
    var e: XEvent
    e.xclient.theType      = ClientMessage
    e.xclient.message_type = x.atom(NET_WM_STATE, true)
    e.xclient.display      = d
    e.xclient.window       = xwin
    e.xclient.format       = 32
    e.xclient.data.l[0]    = 2 #* 2 - переключить, 1 - добавить, 0 - убрать
    e.xclient.data.l[1]    = x.atom(NET_WM_STATE_FULLSCREEN).clong
    e.xclient.data.l[2]    = 0
    e.xclient.data.l[3]    = 0
    e.xclient.data.l[4]    = 0
    xcheck d.XSendEvent(xwa.root, 0, SubstructureNotifyMask or SubstructureRedirectMask, e.addr)
  
    m_isFullscreen = v
  
  proc position*(a: Window): tuple[x, y: int] = with a:
    let (_, x, y, _, _, _, _) = xwin.getGeometry()
    return (x.int, y.int)
  proc `position=`*(a: var Window, p: tuple[x, y: int]) = with a:
    xcheck d.XMoveWindow(xwin, p.x.cint, p.y.cint)
    m_pos = p
  proc size*(a: Window): tuple[x, y: int] = a.m_size
  proc `size=`*(a: var Window, size: tuple[x, y: int]) = with a:
    xcheck d.XResizeWindow(xwin, size.x.cuint, size.y.cuint)
    a.updateGeometry()

  proc `cursor=`*(a: var Window, kind: Cursor) = with a:
    if kind == curCursor: return
    if xcursor != 0: xcheck d.XFreeCursor(xcursor)
    case kind
    of Cursor.arrow:          xcursor = d.XCreateFontCursor(XC_left_ptr)
    of Cursor.arrowUp:        xcursor = d.XCreateFontCursor(XC_center_ptr)
    of Cursor.hand:           xcursor = d.XCreateFontCursor(XC_hand1)
    of Cursor.sizeAll:        xcursor = d.XCreateFontCursor(XC_fleur)
    of Cursor.sizeVertical:   xcursor = d.XCreateFontCursor(XC_sb_v_double_arrow)
    of Cursor.sizeHorisontal: xcursor = d.XCreateFontCursor(XC_sb_h_double_arrow)
    xcheck d.XDefineCursor(xwin, xcursor)
    xcheck d.XSync(0)
    curCursor = kind

  proc newPixmap(img: Picture, a: Window): x.Pixmap = with a:
    var ddata = cast[ptr Color](malloc(culong Color.sizeof * img.size.x * img.size.y))
    copyMem(ddata, cast[ptr Color](img.data), Color.sizeof * img.size.x * img.size.y)
    result = d.XCreatePixmap(xwin, img.size.x.cuint, img.size.y.cuint, d.DefaultDepth(screen).cuint)
    
    var gcv2: XGCValues
    let gc2 = d.XCreateGC(xwin, x.GCForeground or x.GCBackground, gcv2.addr)

    let image = d.XCreateImage(
      d.DefaultVisual(screen), d.DefaultDepth(screen).cuint, ZPixmap, 0, cast[cstring](cast[ptr Color](ddata)),
      img.size.x.cuint, img.size.y.cuint, 32, 0
    )
    xcheckStatus d.XPutImage(result, gc2, image, 0, 0, 0, 0, img.size.x.cuint, img.size.y.cuint)
    xcheck XDestroyImage(image)
    xcheck d.XFreeGC(gc2)

  proc `icon=`*(a: var Window, img: Picture) = with a:
    if xicon != 0: xcheck d.XFreePixmap(xicon)
    if xiconMask != 0: xcheck d.XFreePixmap(xiconMask)

    xicon = newPixmap(img, a)

    var mask = newImage(img.size.x, img.size.y)
    for i in 0..<(img.size.x * img.size.y):
      mask.data[i] = if img.data[i].a > 127: color(0, 0, 0) else: color(255, 255, 255)
    xiconMask = newPixmap(mask, a)

    var wmh = XAllocWMHints()
    wmh.flags = IconPixmapHint or IconMaskHint
    wmh.icon_pixmap = xicon
    wmh.icon_mask   = xiconMask
    xcheck d.XSetWMHints(xwin, wmh)
    xcheck XFree(wmh)
  proc `icon=`*(a: var Window, _: nil.typeof) = with a:
    if xicon != 0: xcheck d.XFreePixmap(xicon)
    if xiconMask != 0: xcheck d.XFreePixmap(xiconMask)
    xicon = 0
    xiconMask = 0
    var wmh = XAllocWMHints()
    wmh.flags = IconPixmapHint or IconMaskHint
    wmh.icon_pixmap = xicon
    wmh.icon_mask   = xiconMask
    xcheck d.XSetWMHints(xwin, wmh)
    xcheck XFree(wmh)

  proc redraw*(a: var Window) = a.waitForReDraw = true
  proc displayImpl(a: var Window) = with a:
    xcheckStatus d.XPutImage(xwin, gc, ximg, 0, 0, 0, 0, m_size.x.cuint, m_size.y.cuint)
  
  proc run*(a: var Window) = with a:
    template push_event(event, args) =
      when args is tuple: 
        if a.event != nil: a.event(args)
      else:
        if a.event != nil: a.event((args,))
    
    var ev: XEvent

    template button: MouseButton =
      case ev.xbutton.button
      of 1: MouseButton.left
      of 2: MouseButton.middle
      of 3: MouseButton.right
      of 8: MouseButton.backward
      of 9: MouseButton.forward
      else: MouseButton.left
    template scrollDelta: float =
      case ev.xbutton.button
      of 4: -1
      of 5: 1
      else: 0
    template isScroll: bool = ev.xbutton.button.int in 4..7

    var lastClickTime: times.Time
    var lastTickTime = getTime()
    
    while m_isOpen:
      var catched = false

      proc checkEvent(_: PDisplay, event: PXEvent, userData: XPointer): XBool {.cdecl.} =
        return if event.xany.window == (x.Window)(cast[int](userData)): 1 else: 0
      while d.XCheckIfEvent(ev.addr, checkEvent, cast[XPointer](xwin)) == 1:
        catched = true

        case ev.theType
        of Expose:
          if ev.xexpose.width != m_size.x or ev.xexpose.height != m_size.y:
            let osize = m_size
            a.updateGeometry()
            push_event onResize, (osize, m_size)
          redraw a
        of ClientMessage:
          if ev.xclient.data.l[0] == (clong)x.atom(WM_DELETE_WINDOW, false):
            m_isOpen         = false;
            m_isFullscreen   = false;
            m_hasFocus       = false;
            waitForReDraw   = false;
            push_event onClose, ()
          
        of ConfigureNotify:
          if ev.xconfigure.width != m_size.x or ev.xconfigure.height != m_size.y:
            let osize = m_size
            a.updateGeometry()
            push_event on_resize, (osize, m_size)
          if ev.xconfigure.x.int != m_pos.x or ev.xconfigure.y.int != m_pos.y:
            let oldPos = m_pos
            m_pos = (ev.xconfigure.x.int, ev.xconfigure.y.int)
            push_event onWindowMove, (oldPos, m_pos)

        of MotionNotify:
          let oldPos = mouse.position
          mouse.position = (ev.xmotion.x.int, ev.xmotion.y.int)
          for v in clicking.mitems: v = false
          push_event onMouseMove, (mouse, oldPos, mouse.position)

        of ButtonPress:
          if not isScroll:
            mouse.pressed[button] = true
            clicking[button] = true
            push_event onMouseDown, (mouse, button, true)
          elif scrollDelta != 0: push_event onScroll, (mouse, scrollDelta)
        of ButtonRelease:
          if not isScroll:
            let nows = getTime()
            mouse.pressed[button] = false
            
            if clicking[button]:
              if (nows - lastClickTime).inMilliseconds < 200: push_event onDoubleClick, (mouse, button, true)
              else: push_event onClick, (mouse, button, false)

            mouse.pressed[button] = false
            lastClickTime = nows
            push_event onMouseUp, (mouse, button, false)

        of LeaveNotify:
          push_event onMouseLeave, (mouse, mouse.position, (ev.xcrossing.x.int, ev.xcrossing.y.int))
        of EnterNotify:
          push_event onMouseEnter, (mouse, mouse.position, (ev.xcrossing.x.int, ev.xcrossing.y.int))

        of FocusIn:
          m_hasFocus = true
          if xinContext != nil: XSetICFocus xinContext
          push_event onFocus, (true)
        of FocusOut:
          m_hasFocus = false
          if xinContext != nil: XSetICFocus xinContext
          push_event onFocus, (false)
        
        of KeyPress:
          var key = Key.unknown
          block:
            var i = 0
            while i < 4 and key == Key.unknown:
              key = xkeyToKey(XLookupKeysym(ev.xkey.addr, i.cint))
              inc i
          if key != Key.unknown:
            keyboard.pressed[key] = true
            template mk(a): bool = (ev.xkey.state and a).bool
            push_event onKeydown, (keyboard, key, true, mk Mod1Mask, mk ControlMask, mk ShiftMask, mk Mod4Mask)
          
          if xinContext != nil:
            var status: Status
            var buffer: array[16, char]
            let length = Xutf8LookupString(xinContext, ev.xkey.addr, cast[cstring](buffer.addr), buffer.sizeof.cint, nil, status.addr)

            proc toString(str: openArray[char]): string =
              result = newStringOfCap(len(str))
              for ch in str:
                result.add ch

            if length > 0:
              push_event onTextEnter, (keyboard, buffer.toString())
        
        of KeyRelease:
          var key = Key.unknown
          block:
            var i = 0
            while i < 4 and key == Key.unknown:
              key = xkeyToKey(XLookupKeysym(ev.xkey.addr, i.cint))
              inc i
          if key != Key.unknown:
            keyboard.pressed[key] = false
            template mk(a): bool = (ev.xkey.state and a).bool
            push_event onKeyup, (keyboard, key, false, mk Mod1Mask, mk ControlMask, mk ShiftMask, mk Mod4Mask)

        else: discard

      if not catched: sleep(2) # не так быстро!

      let nows = getTime()
      push_event onTick, (mouse, keyboard, nows - lastTickTime)
      lastTickTime = nows

      if waitForReDraw:
        waitForReDraw = false
        push_event on_render, (m_data, m_size)
        a.displayImpl()
  
  proc systemHandle*(a: Window): x.Window = a.xwin



elif defined(windows):
  proc poolEvent(a: var Window, message: Uint, wParam: WParam, lParam: LParam): LResult

  proc wndProc(handle: HWnd, message: Uint, wParam: WParam, lParam: LParam): LResult {.stdcall.} =
    let win = if handle != 0: cast[ptr Window](GetWindowLongPtr(handle, GWLP_USERDATA)) else: nil
    if win != nil: return win[].poolEvent(message, wParam, lParam)

    if message == WM_CLOSE: return 0
    if (message == WM_SYSCOMMAND) and (wParam == SC_KEYMENU): return 0
    return DefWindowProc(handle, message, wParam, lParam)

  const wClassName = "win64app"
  block winapiInit:
    var wcex: WNDCLASSEX
    wcex.cbSize        = WNDCLASSEX.sizeof.int32
    wcex.style         = CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
    wcex.lpfnWndProc   = wndProc
    wcex.cbClsExtra    = 0
    wcex.cbWndExtra    = 0
    wcex.hInstance     = hInstance
    wcex.hCursor       = LoadCursor(0, IDC_ARROW)
    wcex.hbrBackground = 0
    wcex.lpszMenuName  = nil
    wcex.lpszClassName = wClassName
    wcex.hIconSm       = 0
    winassert RegisterClassEx(wcex) != 0
  
  proc size*(a: Window): tuple[x, y: int] = a.m_size
  proc `size=`*(a: var Window, size: tuple[x, y: int]) = with a:
    let rcClient = handle.clientRect
    var rcWind = handle.windowRect
    let borderx = (rcWind.right - rcWind.left) - rcClient.right
    let bordery = (rcWind.bottom - rcWind.top) - rcClient.bottom
    MoveWindow(handle, rcWind.left, rcWind.top, (size.x + borderx).int32, (size.y + bordery).int32, True)

    m_size = size
  
  proc `=destroy`*(a: var Window) = with a:
    DeleteDC hdc
    DeleteObject wimage

  proc newWindowImpl(w, h: int): Window = with result:
    handle = CreateWindow(wClassName, "", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 
                          w.int32, h.int32, 0, 0, hInstance, nil)
    winassert handle != 0
    m_hasFocus = true
    m_isOpen = true
    m_isFullscreen = false
    curCursor = arrow
    wcursor = LoadCursor(0, IDC_ARROW)
    discard handle.SetWindowLongPtrW(GWLP_USERDATA, cast[LONG_PTR](result.addr))
    handle.trackMouseEvent(TME_HOVER)
    result.size = (w, h)

    var bmi = BITMAPINFO(bmiHeader: BITMAPINFOHEADER(biSize: BITMAPINFOHEADER.sizeof.int32, biWidth: w.LONG, biHeight: -h.LONG,
                         biPlanes: 1, biBitCount: 32, biCompression: BI_RGB, biSizeImage: 0, biXPelsPerMeter: 0, biYPelsPerMeter: 0, biClrUsed: 0, biClrImportant: 0));
    wimage  = CreateDIBSection(0, &bmi, DIB_RGB_COLORS, cast[ptr pointer](&m_data), 0, 0)
    hdc     = CreateCompatibleDC(0)
    winassert wimage != 0
    winassert hdc != 0
    discard hdc.SelectObject(wimage)

  proc `title=`*(a: Window, title: string) = with a:
    handle.SetWindowText(title)

  proc opened*(a: Window): bool = a.m_isOpen
  proc close*(a: Window) = with a:
    if m_isOpen: handle.SendMessage(WM_CLOSE, 0, 0)
    
  proc updateGeometry(a: var Window) = with a:
    let rect = handle.clientRect
    m_size = (rect.right.int, rect.bottom.int)

    DeleteDC hdc
    DeleteObject wimage

    var bmi = BitmapInfo(bmiHeader: BitmapInfoHeader(biSize: BitmapInfoHeader.sizeof.int32, biWidth: m_size.x.LONG, biHeight: -m_size.y.LONG,
                         biPlanes: 1, biBitCount: 32, biCompression: BI_RGB, biSizeImage: 0, biXPelsPerMeter: 0, biYPelsPerMeter: 0, biClrUsed: 0, biClrImportant: 0));
    wimage  = CreateDIBSection(0, &bmi, DIB_RGB_COLORS, cast[ptr pointer](&m_data), 0, 0)
    hdc     = CreateCompatibleDC(0)
    winassert wimage != 0
    winassert hdc != 0
    let old = hdc.SelectObject(wimage)
    if old != 0: discard DeleteObject old

  proc fullscreen*(a: Window): bool = a.m_isFullscreen
  proc `fullscreen=`*(a: var Window, v: bool) = with a:
    if m_isFullscreen == v: return
    if v:
      discard handle.SetWindowLongPtr(GWL_STYLE, WS_VISIBLE)
      discard handle.ShowWindow(SW_MAXIMIZE)
    else:
      discard handle.ShowWindow(SW_SHOWNORMAL)
      discard handle.SetWindowLongPtr(GWL_STYLE, WS_VISIBLE or WS_OVERLAPPEDWINDOW)
    
  proc position*(a: Window): tuple[x, y: int] = with a:
    let r = handle.clientRect
    return (r.left.int, r.top.int)
  proc `position=`*(a: var Window, v: tuple[x, y: int]) = with a:
    handle.SetWindowPos(0, v.x.int32, v.y.int32, 0, 0, SWP_NOSIZE)
    
  proc `cursor=`*(a: var Window, kind: Cursor) = with a:
    if kind == curCursor: return
    var cu: HCursor = 0
    case kind
    of Cursor.arrow:          cu = LoadCursor(0, IDC_ARROW)
    of Cursor.arrowUp:        cu = LoadCursor(0, IDC_SIZEALL)
    of Cursor.hand:           cu = LoadCursor(0, IDC_HAND)
    of Cursor.sizeAll:        cu = LoadCursor(0, IDC_SIZEWE)
    of Cursor.sizeVertical:   cu = LoadCursor(0, IDC_SIZENS)
    of Cursor.sizeHorisontal: cu = LoadCursor(0, IDC_UPARROW)
    if cu != 0:
      SetCursor cu
      wcursor = cu
    curCursor = kind
  
  proc `icon=`*(a: var Window, img: Picture) = with a:
    if wicon != 0: DestroyIcon wicon
    wicon = CreateIcon(hInstance, img.size.x.int32, img.size.y.int32, 1, 32, nil, cast[ptr Byte](img.data))
    if wicon != 0:
      handle.SendMessageW(WM_SETICON, ICON_BIG, wicon)
      handle.SendMessageW(WM_SETICON, ICON_SMALL, wicon)
  proc `icon=`*(a: var Window, _: nil.typeof) = with a:
    if wicon != 0: DestroyIcon wicon
    handle.SendMessageW(WM_SETICON, ICON_BIG, 0)
    handle.SendMessageW(WM_SETICON, ICON_SMALL, 0)
    
  proc redraw*(a: var Window) = with a:
    var cr = handle.clientRect
    handle.InvalidateRect(&cr, false)
  proc displayImpl(a: var Window) = with a:
    var ps: PAINTSTRUCT
    handle.BeginPaint(&ps)
    let hhdc = handle.GetDC()
    let rect = handle.clientRect

    BitBlt(hhdc, 0, 0, rect.right, rect.bottom, hdc, 0, 0, SRCCOPY)
    handle.ReleaseDC(hhdc)
    handle.EndPaint(&ps)

  proc run*(a: var Window) = with a:
    var lastTickTime = getTime()
    handle.ShowWindow(SW_SHOW)
    handle.UpdateWindow()
    var msg: Msg
    while m_isOpen:
      var catched = false
      while PeekMessage(&msg, 0, 0, 0, PM_REMOVE):
        catched = true
        TranslateMessage(&msg)
        DispatchMessage(&msg)

      if not catched: sleep(2) # не так быстро!
      
      let nows = getTime()
      if a.onTick != nil: onTick (mouse, keyboard, nows - lastTickTime)
      lastTickTime = nows

  proc poolEvent(a: var Window, message: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT = with a:
    discard

  proc systemHandle*(a: Window): HWnd = a.handle
else:
  {.error: "current OS is not supported".}



proc newWindow*(w: int = 1280, h: int = 720, title: string = ""): Window =
  result = newWindowImpl(w, h)
  result.title = title

template w*(a: Screen): int = a.size.x
template h*(a: Screen): int = a.size.y

converter toPicture*(a: Window): Picture = Picture(size: a.m_size, data: a.m_data)
