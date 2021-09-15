import times, os
import chroma
import image, utils

when defined(linux):
  import strformat, options, sequtils
  import libx11 as x, libglx

when defined(windows):
  import macros, sequtils
  import libwinapi, libwgl


type
  MouseButton* {.pure.} = enum
    left right middle forward backward
  AllMouseButtons* = MouseButton.left..MouseButton.backward
  Mouse* = tuple
    position: tuple[x, y: int]
    pressed: array[AllMouseButtons, bool]

  Key* {.pure.} = enum
    unknown = 0

    a b c d e f g h i j k l m n o p q r s t u v w x y z
    tilde n1 n2 n3 n4 n5 n6 n7 n8 n9 n0 minus equal
    f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15
    lcontrol rcontrol  lshift rshift  lalt ralt  lsystem rsystem  lbracket rbracket
    space escape enter tab backspace menu
    slash dot comma  semicolon quote  backslash

    pageUp pageDown  home End  insert del
    left right up down
    npad0 npad1 npad2 npad3 npad4 npad5 npad6 npad7 npad8 npad9 npadDot
    add subtract multiply divide
    capsLock numLock scrollLock printScreen

    pause

  AllKeysRange* = Key.a..Key.pause
  Keyboard* = tuple
    pressed: set[Key]

  Cursor* {.pure.} = enum
    arrow arrowUp arrowRight
    wait arrowWait
    pointingHand grab
    text cross
    sizeAll sizeHorisontal sizeVertical
    hided

const AllKeys* = {Key.a..Key.pause}

type
  Screen* = object
    when defined(linux):
      id: cint
      handle: PScreen

type
  Window* = object of RootObj
    onClose*:       proc(e: CloseEvent)

    onRender*:      proc(e: RenderEvent)
    onTick*:        proc(e: TickEvent)
    onResize*:      proc(e: ResizeEvent)
    onWindowMove*:  proc(e: WindowMoveEvent)

    onFocusChanged*:      proc(e: FocusEvent)
    onFullscreenChanged*: proc(e: StateChangedEvent)

    mouse*: Mouse
    onMouseMove*:   proc(e: MouseMoveEvent)
    onMouseLeave*:  proc(e: MouseMoveEvent)
    onMouseEnter*:  proc(e: MouseMoveEvent)
    onMouseDown*:   proc(e: MouseButtonEvent)
    onMouseUp*:     proc(e: MouseButtonEvent)
    onClick*:       proc(e: ClickEvent)
    onDoubleClick*: proc(e: ClickEvent)
    onScroll*:      proc(e: ScrollEvent)

    keyboard*: Keyboard
    onKeydown*:     proc(e: KeyEvent)
    onKeyup*:       proc(e: KeyEvent)
    onTextInput*:   proc(e: TextInputEvent)

    m_size: tuple[x, y: int]

    m_isOpen: bool
    m_hasFocus: bool
    m_isFullscreen: bool

    clicking: array[AllMouseButtons, bool]
    
    waitForReDraw: bool
    curCursor: Cursor

    when defined(linux):
      xscr: cint
      xwin: x.Window
      xicon: Pixmap
      xiconMask: Pixmap
      xinContext: XIC
      xinMethod: XIM
      gc: GraphicsContext

      xcursor: x.Cursor

      m_pos: tuple[x, y: int]
      requestedSize: Option[tuple[x, y: int]]

    elif defined(windows):
      handle: HWnd
      wicon: HIcon
      hdc: Hdc
      buffer: tuple[x, y: int; bitmap: HBitmap, hdc: Hdc, pixels: ptr UncheckedArray[tuple[b, g, r, _: uint8]]]

      wcursor: HCursor

  OpenglWindow* = object of Window
    when defined(linux):
      ctx: GlxContext
    
    elif defined(windows):
      ctx: WglContext

  SomeWindow = Window|OpenglWindow


  CloseEvent* = tuple

  RenderEvent* = tuple
  ResizeEvent* = tuple
    oldSize, size: tuple[x, y: int]
    initial: bool # is this initial resizing
  WindowMoveEvent* = tuple
    oldPosition, position: tuple[x, y: int]

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
    position: tuple[x, y: int]
    doubleClick: bool
  ScrollEvent* = tuple
    mouse: Mouse
    delta: float ## 1: scroll down, -1: scroll up

  FocusEvent* = tuple
    focused: bool
  StateChangedEvent* = tuple
    state: bool

  TickEvent* = tuple
    mouse: Mouse
    keyboard: Keyboard
    deltaTime: Duration
  #TODO: FixedTickEvent

  KeyEvent* = tuple
    keyboard: Keyboard
    key: Key
    pressed: bool
    repeated: bool
  TextInputEvent* = tuple
    keyboard: Keyboard
    text: string # one utf-8 encoded letter

when defined(linux):
  proc xkeyToKey(sym: KeySym): Key =
    case sym
    of Xk_shiftL:       Key.lshift
    of Xk_shiftR:       Key.rshift
    of Xk_controlL:     Key.lcontrol
    of Xk_controlR:     Key.rcontrol
    of Xk_altL:         Key.lalt
    of Xk_altR:         Key.ralt
    of Xk_superL:       Key.lsystem
    of Xk_superR:       Key.rsystem
    of Xk_menu:         Key.menu
    of Xk_escape:       Key.escape
    of Xk_semicolon:    Key.semicolon
    of Xk_slash:        Key.slash
    of Xk_equal:        Key.equal
    of Xk_minus:        Key.minus
    of Xk_bracketleft:  Key.lbracket
    of Xk_bracketright: Key.rbracket
    of Xk_comma:        Key.comma
    of Xk_period:       Key.dot
    of Xk_apostrophe:   Key.quote
    of Xk_backslash:    Key.backslash
    of Xk_grave:        Key.tilde
    of Xk_space:        Key.space
    of Xk_return:       Key.enter
    of Xk_kpEnter:      Key.enter
    of Xk_backspace:    Key.backspace
    of Xk_tab:          Key.tab
    of Xk_prior:        Key.page_up
    of Xk_next:         Key.page_down
    of Xk_end:          Key.End
    of Xk_home:         Key.home
    of Xk_insert:       Key.insert
    of Xk_delete:       Key.del
    of Xk_kpAdd:        Key.add
    of Xk_kpSubtract:   Key.subtract
    of Xk_kpMultiply:   Key.multiply
    of Xk_kpDivide:     Key.divide
    of Xk_capsLock:     Key.capsLock
    of Xk_numLock:      Key.numLock
    of Xk_scrollLock:   Key.scrollLock
    of Xk_print:        Key.printScreen
    of Xk_kpSeparator:  Key.npadDot
    of Xk_pause:        Key.pause
    of Xk_f1:           Key.f1
    of Xk_f2:           Key.f2
    of Xk_f3:           Key.f3
    of Xk_f4:           Key.f4
    of Xk_f5:           Key.f5
    of Xk_f6:           Key.f6
    of Xk_f7:           Key.f7
    of Xk_f8:           Key.f8
    of Xk_f9:           Key.f9
    of Xk_f10:          Key.f10
    of Xk_f11:          Key.f11
    of Xk_f12:          Key.f12
    of Xk_f13:          Key.f13
    of Xk_f14:          Key.f14
    of Xk_f15:          Key.f15
    of Xk_left:         Key.left
    of Xk_right:        Key.right
    of Xk_up:           Key.up
    of Xk_down:         Key.down
    of Xk_kpInsert:     Key.npad0
    of Xk_kpEnd:        Key.npad1
    of Xk_kpDown:       Key.npad2
    of Xk_kpPagedown:   Key.npad3
    of Xk_kpLeft:       Key.npad4
    of Xk_kpBegin:      Key.npad5
    of Xk_kpRight:      Key.npad6
    of Xk_kpHome:       Key.npad7
    of Xk_kpUp:         Key.npad8
    of Xk_kpPageup:     Key.npad9
    of Xk_a:            Key.a
    of Xk_b:            Key.b
    of Xk_c:            Key.c
    of Xk_d:            Key.d
    of Xk_e:            Key.r
    of Xk_f:            Key.f
    of Xk_g:            Key.g
    of Xk_h:            Key.h
    of Xk_i:            Key.i
    of Xk_j:            Key.j
    of Xk_k:            Key.k
    of Xk_l:            Key.l
    of Xk_m:            Key.m
    of Xk_n:            Key.n
    of Xk_o:            Key.o
    of Xk_p:            Key.p
    of Xk_q:            Key.q
    of Xk_r:            Key.r
    of Xk_s:            Key.s
    of Xk_t:            Key.t
    of Xk_u:            Key.u
    of Xk_v:            Key.v
    of Xk_w:            Key.w
    of Xk_x:            Key.x
    of Xk_y:            Key.y
    of Xk_z:            Key.z
    of Xk_0:            Key.n0
    of Xk_1:            Key.n1
    of Xk_2:            Key.n2
    of Xk_3:            Key.n3
    of Xk_4:            Key.n4
    of Xk_5:            Key.n5
    of Xk_6:            Key.n6
    of Xk_7:            Key.n7
    of Xk_8:            Key.n8
    of Xk_9:            Key.n9
    else:               Key.unknown

  template d: PDisplay = display

  proc getScreenCount*(): int = d.ScreenCount.int

  proc screen*(n: int): Screen {.with: result.} =
    if n notin 0..<getScreenCount(): raise IndexDefect.newException(&"screen {n} is not exist")
    id = n.cint
    handle = d.ScreenOfDisplay(id)

  proc defaultScreen*(): Screen = screen(d.DefaultScreen.int)
  proc screen*(): Screen = defaultScreen()

  proc n*(a: Screen): int = a.id.int

  proc size*(a: Screen): tuple[x, y: int] {.with.} =
    (handle.width.int, handle.height.int)

elif defined(windows):
  proc wkeyToKey(key: WParam): Key =
    case key
    of Vk_lshift:       Key.lshift
    of Vk_rshift:       Key.rshift
    of Vk_lmenu:        Key.lalt
    of Vk_rmenu:        Key.ralt
    of Vk_lcontrol:     Key.lcontrol
    of Vk_rcontrol:     Key.rcontrol
    of Vk_lwin:         Key.lsystem
    of Vk_rwin:         Key.rsystem
    of Vk_apps:         Key.menu
    of Vk_escape:       Key.escape
    of Vk_oem1:         Key.semicolon
    of Vk_oem2:         Key.slash
    of Vk_oem_plus:     Key.equal
    of Vk_oem_minus:    Key.minus
    of Vk_oem4:         Key.lbracket
    of Vk_oem6:         Key.rbracket
    of Vk_oem_comma:    Key.comma
    of Vk_oem_period:   Key.dot
    of Vk_oem7:         Key.quote
    of Vk_oem5:         Key.backslash
    of Vk_oem3:         Key.tilde
    of Vk_space:        Key.space
    of Vk_return:       Key.enter
    of Vk_back:         Key.backspace
    of Vk_tab:          Key.tab
    of Vk_prior:        Key.page_up
    of Vk_next:         Key.page_down
    of Vk_end:          Key.End
    of Vk_home:         Key.home
    of Vk_insert:       Key.insert
    of Vk_delete:       Key.del
    of Vk_add:          Key.add
    of Vk_subtract:     Key.subtract
    of Vk_multiply:     Key.multiply
    of Vk_divide:       Key.divide
    of Vk_capital:      Key.capsLock
    of Vk_numLock:      Key.numLock
    of Vk_scroll:       Key.scrollLock
    of Vk_snapshot:     Key.printScreen
    of Vk_print:        Key.printScreen
    of Vk_decimal:      Key.npadDot
    of Vk_pause:        Key.pause
    of Vk_f1:           Key.f1
    of Vk_f2:           Key.f2
    of Vk_f3:           Key.f3
    of Vk_f4:           Key.f4
    of Vk_f5:           Key.f5
    of Vk_f6:           Key.f6
    of Vk_f7:           Key.f7
    of Vk_f8:           Key.f8
    of Vk_f9:           Key.f9
    of Vk_f10:          Key.f10
    of Vk_f11:          Key.f11
    of Vk_f12:          Key.f12
    of Vk_f13:          Key.f13
    of Vk_f14:          Key.f14
    of Vk_f15:          Key.f15
    of Vk_left:         Key.left
    of Vk_right:        Key.right
    of Vk_up:           Key.up
    of Vk_down:         Key.down
    of Vk_numpad0:      Key.npad0
    of Vk_numpad1:      Key.npad1
    of Vk_numpad2:      Key.npad2
    of Vk_numpad3:      Key.npad3
    of Vk_numpad4:      Key.npad4
    of Vk_numpad5:      Key.npad5
    of Vk_numpad6:      Key.npad6
    of Vk_numpad7:      Key.npad7
    of Vk_numpad8:      Key.npad8
    of Vk_numpad9:      Key.npad9
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
  
  proc wkeyToKey(key: WParam, flags: LParam): Key =
    let scancode = ((flags and 0xff0000) shr 16).Uint
    case key
    of VK_shift:
      let key = MapVirtualKey(scancode, MAPVK_VSC_TO_VK_EX)
      if key == Vk_lshift: Key.lshift else: Key.rshift
    of VK_menu:
      if (flags and 0x1000000) != 0: Key.ralt else: Key.lalt
    of VK_control:
      if (flags and 0x1000000) != 0: Key.rcontrol else: Key.lcontrol
    else: wkeyToKey(key)

  #TODO: многоэкранность
  proc getScreenCount*(): int = 1

  proc screen*(n: int = 0): Screen = discard
  proc defaultScreen*(): Screen = screen()
  proc n*(a: Screen): int = 0

  proc size*(a: Screen): tuple[x, y: int] {.with: result.} =
    x = GetSystemMetrics(SmCxScreen).int
    y = GetSystemMetrics(SmCyScreen).int

template screenCount*: int = getScreenCount()


when defined(linux):
  proc `=destroy`*(a: var Window) {.with.} =
    if xinContext != nil: destroy xinContext
    if xinMethod != nil: close xinMethod
    if xcursor != 0: destroy xcursor
    if xicon != 0: destroy xicon
    if xiconMask != 0: destroy xiconMask
    destroy xwin

  proc `=destroy`*(a: var OpenglWindow) {.with.} =
    0.makeCurrent nil.GlxContext
    destroy ctx
    `=destroy` a.Window

  proc basicInitWindow(a: var Window; w, h: int; screen: Screen) {.with.} =
    xscr = screen.id
    m_size = (w, h)

    m_isOpen = true
    m_hasFocus = true
    curCursor = arrow

  proc setupWindow(a: var Window, fullscreen: bool) {.with.} =
    xwin.input = [
      ExposureMask, KeyPressMask, KeyReleaseMask, PointerMotionMask, ButtonPressMask,
      ButtonReleaseMask, StructureNotifyMask, EnterWindowMask, LeaveWindowMask, FocusChangeMask
    ]

    m_isFullscreen = fullscreen
    if fullscreen:
      xwin.netWmState = [NetWmStateFullscreen]
      m_size = window.screen().size

    map xwin
    xwin.wmProtocols = [WmDeleteWindow]

    xinMethod = d.XOpenIM(nil, nil, nil)
    if xinMethod != nil:
      xinContext = xinMethod.XCreateIC(
        XNClientWindow, xwin, XNFocusWindow, xwin, XnInputStyle, XimPreeditNothing or XimStatusNothing, nil
      )

  proc initWindow(this: var Window; w, h: int; screen: Screen, fullscreen: bool) =
    this.basicInitWindow w, h, screen
    this.xwin = newSimpleWindow(defaultRootWindow(), 0, 0, w, h, 0, 0, this.xscr.blackPixel)
    this.setupWindow fullscreen

    this.waitForReDraw = true
    this.gc = this.xwin.newGC(GCForeground or GCBackground)

  proc initOpenglWindow(a: var OpenglWindow; w, h: int; screen: Screen, fullscreen: bool) {.with.} =
    a.basicInitWindow w, h, screen

    let root = defaultRootWindow()
    let vi = glxChooseVisual(0, [GlxRgba, GlxDepthSize, 24, GlxDoublebuffer])
    let cmap = d.XCreateColormap(root, vi.visual, AllocNone)
    var swa: XSetWindowAttributes
    swa.colormap = cmap
    xwin = x.newWindow(root, 0, 0, w, h, 0, vi.depth, InputOutput, vi.visual, CwColormap or CwEventMask, swa)

    a.setupWindow fullscreen

    ctx = newGlxContext(vi)
    glxAssert ctx != nil
    xwin.makeCurrent ctx

  template pushEvent(a: Window, event, args) =
    when args is tuple:
      if a.event != nil: a.event(args)
    else:
      if a.event != nil: a.event((args,))

  proc `title=`*(a: Window, title: string) {.with.} =
    ## set window title
    xwin.netWmName = title
    xwin.netWmIconName = title
    d.Xutf8SetWMProperties(xwin, title, title, nil, 0, nil, nil, nil)

  proc opened*(a: Window): bool = a.m_isOpen
  proc close*(a: var Window) {.with.} =
    ## close request
    if not m_isOpen: return
    xwin.send xwin.newClientMessage(WmProtocols, [atom WmDeleteWindow, CurrentTime])
    m_isOpen = false

  proc redraw*(a: var Window) = a.waitForReDraw = true
    ## render request

  proc updateSize(this: var Window, v: tuple[x, y: int]) =
    this.m_size = v
    this.waitForReDraw = true

  proc fullscreen*(a: Window): bool = a.m_isFullscreen
    ## get real fullscreen state of window
  proc `fullscreen=`*(a: var Window, v: bool) {.with.} =
    ## set fullscreen
    ##* this proc is lazy, don't try get size of window after it
    ## track when the fullscreen state will be applied in the onFullscreenChanged event
    if m_isFullscreen == v: return

    xwin.root.send(
      xwin.newClientMessage(NetWmState, [Atom 2, atom NetWmStateFullscreen]), # 2 - switch, 1 - set true, 0 - set false
      SubstructureNotifyMask or SubstructureRedirectMask
    )

  proc position*(a: Window): tuple[x, y: int] = a.xwin.geometry.position
  proc `position=`*(a: var Window, p: tuple[x, y: int]) {.with.} =
    ## move window
    ## do nothing if window is fullscreen
    if m_isFullscreen: return
    xwin.position = p
    m_pos = p

  proc size*(a: Window): tuple[x, y: int] = a.m_size
  proc `size=`*(a: var Window, size: tuple[x, y: int]) {.with.} =
    ## resize window
    ## exit fullscreen if window is fullscreen
    if not a.fullscreen:
      xwin.size = size
      a.updateSize size
    else:
      a.fullscreen = false
      requestedSize = some size

  proc newPixmap(source: Image, window: Window): Pixmap =
    result = newPixmap(source.w, source.h, window.xwin, window.xscr.defaultDepth)
    var image = asXImage(source.data, source.w, source.h)
    result.newGC.put image.addr

  proc `cursor=`*(a: var Window, kind: Cursor) {.with.} =
    ## set cursor font, used when mouse hover window
    if kind == curCursor: return
    if xcursor != 0: destroy xcursor
    case kind
    of Cursor.arrow:          xcursor = cursorFromFont XcLeftPtr
    of Cursor.arrowUp:        xcursor = cursorFromFont XcCenterPtr
    of Cursor.arrowRight:     xcursor = cursorFromFont XcRightPtr
    of Cursor.wait:           xcursor = cursorFromFont XcWatch
    of Cursor.arrowWait:      xcursor = cursorFromFont XcWatch #! no needed cursor
    of Cursor.pointingHand:   xcursor = cursorFromFont XcHand1
    of Cursor.grab:           xcursor = cursorFromFont XcHand2
    of Cursor.text:           xcursor = cursorFromFont XcXterm
    of Cursor.cross:          xcursor = cursorFromFont XcTCross
    of Cursor.sizeAll:        xcursor = cursorFromFont XcFleur
    of Cursor.sizeVertical:   xcursor = cursorFromFont XcSb_v_doubleArrow
    of Cursor.sizeHorisontal: xcursor = cursorFromFont XcSb_h_doubleArrow
    of Cursor.hided:
      var data: array[1, char]
      let blank = display.XCreateBitmapFromData(rootWindow(0), data[0].addr, 1, 1)
      var pass: XColor
      xcursor = x.Cursor display.XCreatePixmapCursor(blank, blank, pass.addr, pass.addr, 0, 0)
      discard display.XFreePixmap blank
    xwin.cursor = xcursor
    syncX()
    curCursor = kind

  proc `icon=`*(a: var Window, image: Image) {.with.} =
    ## set window icon
    if xicon != 0: destroy xicon
    if xiconMask != 0: destroy xiconMask

    xicon = newPixmap(image, a)

    # convert alpha channel to bit mask (semi-transparency is not supported)
    var mask = newImage(image.w, image.h)
    for i in 0..<(image.w * image.h):
      mask.data[i] = if image.data[i].a > 127: rgbx(0, 0, 0, 255) else: rgbx(255, 255, 255, 255)
    xiconMask = newPixmap(mask, a)

    xwin.wmHints = newWmHints(xicon, xiconMask)
  proc `icon=`*(a: var Window, _: nil.typeof) {.with.} =
    ## clear window icon
    if xicon != 0: destroy xicon
    if xiconMask != 0: destroy xiconMask
    xicon = 0.Pixmap
    xiconMask = 0.Pixmap
    xwin.wmHints = newWmHints(xicon, xiconMask)

  proc drawImage*(this: var Window, pixels: openarray[ColorRGBX]) =
    doassert pixels.len == this.size.x * this.size.y, "pixels count must be width * height"
    var ximg = asXImage(pixels, this.size.x, this.size.y)
    this.gc.put ximg.addr

  proc drawImage*(this: var OpenglWindow, pixels: openarray[ColorRGBX]) =
    ## draw image on OpenglWindow is impossible, so this proc do nothing

  proc run*(a: var SomeWindow) {.with.} =
    ## run main loop of window
    template pushEvent(event, args) = a.pushEvent(event, args)

    var ev: XEvent

    template button: MouseButton =
      case ev.xbutton.button
      of 1: MouseButton.left
      of 2: MouseButton.middle
      of 3: MouseButton.right
      of 8: MouseButton.backward
      of 9: MouseButton.forward
      else: MouseButton.left
    template isScroll: bool = ev.xbutton.button.int in 4..7
    template scrollDelta: float =
      case ev.xbutton.button
      of 4: -1
      of 5: 1
      else: 0

    m_pos = xwin.geometry.position
    mouse.position = x.cursor().position
    mouse.position = (mouse.position.x - m_pos.x, mouse.position.y - m_pos.y)
    
    pushEvent onResize, ((0, 0), m_size, true)

    var lastClickTime: times.Time
    var lastTickTime = getTime()

    while m_isOpen:
      var xevents: seq[XEvent]

      proc checkEvent(_: PDisplay, event: PXEvent, userData: XPointer): XBool {.cdecl.} =
        if cast[int](event.xany.window) == cast[int](userData): 1 else: 0
      while d.XCheckIfEvent(ev.addr, checkEvent, cast[XPointer](xwin)) == 1:
        xevents.add ev
      
      let catched = xevents.len > 0

      for ev in xevents.mitems:
        case ev.theType
        of Expose:
          redraw a
        of ClientMessage:
          if ev.xclient.data.l[0] == atom(WmDeleteWindow).clong:
            m_isOpen = false

        of ConfigureNotify:
          if ev.xconfigure.width != m_size.x or ev.xconfigure.height != m_size.y:
            let osize = m_size
            a.updateSize (ev.xconfigure.width.int, ev.xconfigure.height.int)
            pushEvent onResize, (osize, m_size, false)
          if ev.xconfigure.x.int != m_pos.x or ev.xconfigure.y.int != m_pos.y:
            let oldPos = m_pos
            m_pos = (ev.xconfigure.x.int, ev.xconfigure.y.int)
            mouse.position = x.cursor().position
            mouse.position = (mouse.position.x - m_pos.x, mouse.position.y - m_pos.y)
            pushEvent onWindowMove, (oldPos, m_pos)

          let state = xwin.netWmState
          if atom(NetWmStateFullscreen) in state != m_isFullscreen:
            m_isFullscreen = not m_isFullscreen
            pushEvent onFullscreenChanged, (m_isFullscreen)
            if not m_isFullscreen and isSome a.requestedSize:
              a.size = get a.requestedSize
              a.requestedSize = none tuple[x, y: int]

        of MotionNotify:
          let oldPos = mouse.position
          mouse.position = (ev.xmotion.x.int, ev.xmotion.y.int)
          for v in clicking.mitems: v = false
          pushEvent onMouseMove, (mouse, oldPos, mouse.position)

        of ButtonPress:
          if not isScroll:
            mouse.pressed[button] = true
            clicking[button] = true
            pushEvent onMouseDown, (mouse, button, true)
          elif scrollDelta != 0: pushEvent onScroll, (mouse, scrollDelta)
        of ButtonRelease:
          if not isScroll:
            let nows = getTime()
            mouse.pressed[button] = false

            if clicking[button]:
              if (nows - lastClickTime).inMilliseconds < 200: pushEvent onDoubleClick, (mouse, button, mouse.position, true)
              else: pushEvent onClick, (mouse, button, mouse.position, false)

            mouse.pressed[button] = false
            lastClickTime = nows
            pushEvent onMouseUp, (mouse, button, false)

        of LeaveNotify:
          pushEvent onMouseLeave, (mouse, mouse.position, (ev.xcrossing.x.int, ev.xcrossing.y.int))
        of EnterNotify:
          pushEvent onMouseEnter, (mouse, mouse.position, (ev.xcrossing.x.int, ev.xcrossing.y.int))

        of FocusIn:
          m_hasFocus = true
          if xinContext != nil: XSetICFocus xinContext
          pushEvent onFocusChanged, (true)
          
          let keys = queryKeyboardState().mapit(xkeyToKey display.XKeycodeToKeysym(it.cuchar, 0))
          for k in keys: # нажать клавиши, нажатые в системе
            if k == Key.unknown: continue
            keyboard.pressed.incl k
            pushEvent onKeydown, (keyboard, k, false, false)
        of FocusOut:
          m_hasFocus = false
          if xinContext != nil: XUnsetICFocus xinContext
          pushEvent onFocusChanged, (false)

          let pressed = keyboard.pressed
          for k in pressed: # отпустить все клавиши
            keyboard.pressed.excl k
            pushEvent onKeyup, (keyboard, k, false, false)

        of KeyPress:
          var key = Key.unknown
          block:
            var i = 0
            while i < 4 and key == Key.unknown:
              key = xkeyToKey(XLookupKeysym(ev.xkey.addr, i.cint))
              inc i
          if key != Key.unknown:
            let ev = ev
            let repeated = xevents.findBy(proc (a: XEvent): bool =
              a.theType == KeyRelease and a.xkey.keycode == ev.xkey.keycode and a.xkey.time - ev.xkey.time < 2
            ) >= 0
            keyboard.pressed.incl key
            pushEvent onKeydown, (keyboard, key, true, repeated)

          if xinContext != nil and (keyboard.pressed * {lcontrol, rcontrol, lalt, ralt}).len == 0:
            var status: Status
            var buffer: array[16, char]
            let length = Xutf8LookupString(xinContext, ev.xkey.addr, cast[cstring](buffer.addr), buffer.sizeof.cint, nil, status.addr)

            proc toString(str: openArray[char]): string =
              result = newStringOfCap(len(str))
              for ch in str:
                result.add ch

            if length > 0:
              let s = buffer[0..<length].toString()
              if s notin ["\u001B"]:
                pushEvent onTextInput, (keyboard, s)

        of KeyRelease:
          var key = Key.unknown
          block:
            var i = 0
            while i < 4 and key == Key.unknown:
              key = xkeyToKey(XLookupKeysym(ev.xkey.addr, i.cint))
              inc i
          if key != Key.unknown:
            let ev = ev
            let repeated = xevents.findBy(proc (a: XEvent): bool =
              a.theType == KeyPress and a.xkey.keycode == ev.xkey.keycode and a.xkey.time - ev.xkey.time < 2
            ) >= 0
            keyboard.pressed.excl key
            pushEvent onKeyup, (keyboard, key, false, repeated)

        else: discard

        if not m_isOpen: break
      if not m_isOpen: break

      if not catched: sleep(2)

      let nows = getTime()
      pushEvent onTick, (mouse, keyboard, nows - lastTickTime)
      lastTickTime = nows

      if waitForReDraw:
        waitForReDraw = false
        pushEvent on_render, ()
        when a is OpenglWindow:
          xwin.toDrawable.glxSwapBuffers()

      clipboardProcessEvents()

    pushEvent onClose, ()

  proc systemHandle*(a: Window): x.Window = a.xwin
    ## get system handle of window
    ##* result depends on OS or platmofm


elif defined(windows):
  proc poolEvent(a: var SomeWindow, message: Uint, wParam: WParam, lParam: LParam): LResult

  template wndProc(name; t: typedesc) =
    proc name(handle: HWnd, message: Uint, wParam: WParam, lParam: LParam): LResult {.stdcall.} =
      let win = if handle != 0: cast[ptr t](GetWindowLongPtr(handle, GwlpUserData)) else: nil
      
      if win != nil: win[].poolEvent(message, wParam, lParam)
      else:          DefWindowProc(handle, message, wParam, lParam)
  
  wndProc windowProc, Window
  wndProc openglWindowProc, OpenglWindow

  const
    wClassName = "w"
    woClassName = "o"
  
  block winapiInit:
    var wcex = WndClassEx(
      cbSize:        WndClasseX.sizeof.int32,
      style:         CsHRedraw or CsVRedraw or CsDblClks,
      hInstance:     hInstance,
      hCursor:       LoadCursor(0, IdcArrow),
      lpfnWndProc:   windowProc,
      lpszClassName: wClassName,
    )
    RegisterClassEx(&wcex)

    wcex.lpfnWndProc   = openglWindowProc
    wcex.lpszClassName = woClassName
    RegisterClassEx(&wcex)

  proc `=destroy`*(this: var Window) =
    DeleteDC this.hdc
    if this.buffer.pixels != nil:
      DeleteDC this.buffer.hdc
      DeleteObject this.buffer.bitmap
    if this.wicon != 0: DestroyIcon this.wicon
    if this.wcursor != 0: DestroyCursor this.wcursor
  
  proc `=destroy`*(this: var OpenglWindow) =
    if wglGetCurrentContext() == this.ctx:
      wglMakeCurrent(0, 0)
    wglDeleteContext this.ctx
    this.Window.`=destroy`

  template pushEvent(this: SomeWindow, event, args) =
    if this.event != nil:
      this.event(when args is tuple: args else: (args,))

  proc updateSize(this: var Window) =
    let rect = this.handle.clientRect
    let osize = this.m_size
    this.m_size = (rect.right.int, rect.bottom.int)
    if osize == this.m_size: return

    this.pushEvent onResize, (osize, this.m_size, false)

  proc fullscreen*(a: Window): bool = a.m_isFullscreen
  proc `fullscreen=`*(this: var Window, v: bool) =
    if this.m_isFullscreen == v: return
    this.m_isFullscreen = v
    if v:
      this.handle.SetWindowLongPtr(GwlStyle, WsVisible)
      discard this.handle.ShowWindow(SwMaximize)
    else:
      this.handle.ShowWindow(SwShowNormal)
      discard this.handle.SetWindowLongPtr(GwlStyle, WsVisible or WsOverlappedWindow)
    this.updateSize()
    this.pushEvent onFullscreenChanged, (v)

  proc size*(this: Window): tuple[x, y: int] = this.m_size
  proc `size=`*(this: var Window, size: tuple[x, y: int]) =
    this.fullscreen = false
    let rcClient = this.handle.clientRect
    var rcWind = this.handle.windowRect
    let borderx = (rcWind.right - rcWind.left) - rcClient.right
    let bordery = (rcWind.bottom - rcWind.top) - rcClient.bottom
    this.handle.MoveWindow(rcWind.left, rcWind.top, (size.x + borderx).int32, (size.y + bordery).int32, True)
    this.updateSize()

  proc initWindow(this: var Window; w, h: int; screen: Screen, fullscreen: bool, class = wClassName) =
    this.handle = CreateWindow(class, "", WsOverlappedWindow, CwUseDefault, CwUseDefault, w.int32, h.int32, 0, 0, hInstance, nil)
    this.m_hasFocus = true
    this.m_isOpen = true
    this.curCursor = arrow
    this.wcursor = LoadCursor(0, IdcArrow)
    this.handle.SetWindowLongPtrW(GwlpUserData, cast[LongPtr](this.addr))
    this.handle.trackMouseEvent(TmeHover)
    this.size = (w, h)
    this.hdc = this.handle.GetDC
    
    this.fullscreen = fullscreen

  proc initOpenglWindow(this: var OpenglWindow; w, h: int; screen: Screen, fullscreen: bool) =
    this.initWindow w, h, screen, fullscreen, woClassName
    
    this.waitForReDraw = true

    var pfd = PixelFormatDescriptor(
      nSize: WORD PixelFormatDescriptor.sizeof,
      nVersion: 1,
      dwFlags: Pfd_draw_to_window or Pfd_support_opengl or Pfd_double_buffer,
      iPixelType: Pfd_type_rgba,
      cColorBits: 32,
      cDepthBits: 24,
      cStencilBits: 8,
      iLayerType: Pfd_main_plane,
    )
    this.hdc.SetPixelFormat(this.hdc.ChoosePixelFormat(&pfd), &pfd)
    this.ctx = wglCreateContext(this.hdc)
    doassert this.hdc.wglMakeCurrent(this.ctx)


  proc `title=`*(this: Window, title: string) =
    this.handle.SetWindowText(title)

  proc opened*(a: Window): bool = a.m_isOpen
  proc close*(this: var Window) =
    if this.m_isOpen: this.handle.SendMessage(WmClose, 0, 0)

  proc redraw*(this: var Window) =
    var cr = this.handle.clientRect
    this.handle.InvalidateRect(&cr, false)
  
  proc redraw*(a: var OpenglWindow) = a.waitForReDraw = true

  proc position*(this: Window): tuple[x, y: int] =
    let r = this.handle.clientRect
    (r.left.int, r.top.int)
  
  proc `position=`*(this: var Window, v: tuple[x, y: int]) =
    if this.m_isFullscreen: return
    this.handle.SetWindowPos(0, v.x.int32, v.y.int32, 0, 0, SwpNoSize)

  proc `cursor=`*(this: var Window, kind: Cursor) =
    if kind == this.curCursor: return
    if this.wcursor != 0: DestroyCursor this.wcursor
    
    var cu: HCursor = case kind
    of Cursor.arrow:          LoadCursor(0, IdcArrow)
    of Cursor.arrowUp:        LoadCursor(0, IdcUpArrow)
    of Cursor.pointingHand:   LoadCursor(0, IdcHand)
    of Cursor.arrowRight:     LoadCursor(0, IdcArrow) #! no needed cursor
    of Cursor.wait:           LoadCursor(0, IdcWait)
    of Cursor.arrowWait:      LoadCursor(0, IdcAppStarting)
    of Cursor.grab:           LoadCursor(0, IdcHand) #! no needed cursor
    of Cursor.text:           LoadCursor(0, IdcIBeam)
    of Cursor.cross:          LoadCursor(0, IdcCross)
    of Cursor.sizeAll:        LoadCursor(0, IdcSizeAll)
    of Cursor.sizeVertical:   LoadCursor(0, IdcSizens)
    of Cursor.sizeHorisontal: LoadCursor(0, IdcSizewe)
    of Cursor.hided:          LoadCursor(0, IdcNo)
    
    if cu != 0:
      SetCursor cu
      this.wcursor = cu
    this.curCursor = kind

  proc `icon=`*(this: var Window, img: Image) =
    if this.wicon != 0: DestroyIcon this.wicon
    
    var pixels = img.data.mapit((it.b, it.g, it.r, 0'u8))
    this.wicon = CreateIcon(hInstance, img.w.int32, img.h.int32, 1, 32, nil, cast[ptr Byte](pixels.dataAddr))
    this.handle.SendMessageW(WmSetIcon, IconBig, this.wicon)
    this.handle.SendMessageW(WmSetIcon, IconSmall, this.wicon)
  
  proc `icon=`*(this: var Window, _: nil.typeof) =
    # clear icon
    if this.wicon != 0:
      DestroyIcon this.wicon
      this.wicon = 0
    
    this.handle.SendMessageW(WmSetIcon, IconBig, 0)
    this.handle.SendMessageW(WmSetIcon, IconSmall, 0)

  proc drawImage*(this: var Window, pixels: openarray[ColorRGBX]) =
    doassert pixels.len == this.size.x * this.size.y, "pixels count must be width * height"
    if this.size.x * this.size.y == 0: return
    
    if this.size.x != this.buffer.x or this.size.y != this.buffer.y:
      if this.buffer.pixels != nil:
        DeleteDC this.buffer.hdc
        DeleteObject this.buffer.bitmap
      
      this.buffer.x = this.size.x
      this.buffer.y = this.size.y
    
      var bmi = BitmapInfo(
        bmiHeader: BitmapInfoHeader(
          biSize: BitmapInfoHeader.sizeof.int32, biWidth: this.size.x.Long, biHeight: -this.size.y.Long,
          biPlanes: 1, biBitCount: 32, biCompression: Bi_rgb
        )
      )
      this.buffer.bitmap = CreateDibSection(0, &bmi, Dib_rgb_colors, cast[ptr pointer](this.buffer.pixels.addr), 0, 0)
      this.buffer.hdc = CreateCompatibleDC(0)
      this.buffer.hdc.SelectObject this.buffer.bitmap
    
    let rect = this.handle.clientRect
    for i, c in pixels:
      this.buffer.pixels[i] = (c.b, c.g, c.r, 0'u8)
      
    this.hdc.BitBlt(0, 0, rect.right, rect.bottom, this.buffer.hdc, 0, 0, SrcCopy)

  proc drawImage*(this: var OpenglWindow, pixels: openarray[ColorRGBX]) =
    ## draw image on OpenglWindow is impossible, so this proc do nothing

  proc displayImpl(this: var Window) =
    var ps: PaintStruct
    this.handle.BeginPaint(&ps)
    this.pushEvent onRender, ()
    this.handle.EndPaint(&ps)

  proc displayImpl(this: var OpenglWindow) =
    this.pushEvent onRender, ()

  proc run*(a: var Window) {.with.} =
    ## run main loop of window
    handle.ShowWindow(SwShow)
    a.pushEvent onResize, ((0, 0), m_size, true)
    a.waitForRedraw = true

    handle.UpdateWindow()

    var lastTickTime = getTime()
    var msg: Msg
    while m_isOpen:
      var catched = false
      while PeekMessage(&msg, 0, 0, 0, PmRemove):
        catched = true
        TranslateMessage(&msg)
        DispatchMessage(&msg)

        if not m_isOpen: break
      if not m_isOpen: break

      if not catched: sleep(2)

      let nows = getTime()
      if a.onTick != nil: onTick (mouse, keyboard, nows - lastTickTime)
      lastTickTime = nows

  proc poolEvent(a: var SomeWindow, message: Uint, wParam: WParam, lParam: LParam): LResult {.with.} =
    template pushEvent(event, args): untyped =
      a.pushEvent(event, args)

    template button: MouseButton =
      case message
      of WM_lbuttonDown, WM_lbuttonUp, WM_lbuttonDblclk: MouseButton.left
      of WM_rbuttonDown, WM_rbuttonUp, WM_rbuttonDblclk: MouseButton.right
      of WM_mbuttonDown, WM_mbuttonUp, WM_mbuttonDblclk: MouseButton.middle
      of WM_xbuttonDown, WM_xbuttonUp, WM_xbuttonDblclk:
        let button = wParam.GetXButtonWParam()
        case button
        of MkXButton1: MouseButton.backward
        of MkXButton2: MouseButton.forward
        else: MouseButton.left
      else: MouseButton.left

    result = 0

    case message
    of WmPaint:
      let rect = handle.clientRect
      if rect.right != a.m_size.x or rect.bottom != a.m_size.y:
        a.updateSize()
        a.waitForRedraw = true

      if a.m_size.x * a.m_size.y > 0:
        a.displayImpl()
        a.waitForRedraw = false
        when a is OpenglWindow:
          hdc.SwapBuffers

    of WmDestroy:
      pushEvent onClose, ()
      m_isOpen = false
      PostQuitMessage(0)

    of WmMouseMove:
      let opos = a.mouse.position
      a.mouse.position = (lParam.GetX_LParam, lParam.GetY_LParam)
      for v in clicking.mitems: v = false
      pushEvent onMouseMove, (a.mouse, opos, a.mouse.position)

    of WmMouseLeave:
      let npos = (lParam.GetX_LParam, lParam.GetY_LParam)
      pushEvent onMouseLeave, (a.mouse, a.mouse.position, npos)
      handle.trackMouseEvent(TmeHover)

    of WmMouseHover:
      let npos = (lParam.GetX_LParam, lParam.GetY_LParam)
      pushEvent onMouseEnter, (a.mouse, a.mouse.position, npos)
      handle.trackMouseEvent(TmeLeave)

    of WmMouseWheel:
      let delta = if wParam.GetWheelDeltaWParam > 0: -1.0 else: 1.0
      pushEvent onScroll, (a.mouse, delta)

    of WmSetFocus:
      m_hasFocus = true
      pushEvent onFocusChanged, (m_hasFocus)

      let keys = getKeyboardState().mapit(wkeyToKey(it))
      for k in keys: # нажать клавиши, нажатые в системе
        if k == Key.unknown: continue
        a.keyboard.pressed.incl k
        pushEvent onKeydown, (a.keyboard, k, false, false)

    of WmKillFocus:
      m_hasFocus = false
      pushEvent onFocusChanged, (m_hasFocus)
      let pressed = a.keyboard.pressed
      for key in pressed: # отпустить все клавиши
        a.keyboard.pressed.excl key
        pushEvent onKeyup, (a.keyboard, key, false, false)

    of WmLButtonDown, WmRButtonDown, WmMButtonDown, WmXButtonDown:
      handle.SetCapture()
      a.mouse.pressed[button] = true
      clicking[button] = true
      pushEvent onMouseDown, (a.mouse, button, true)

    of WmLButtonUp, WmRButtonUp, WmMButtonUp, WmXButtonUp:
      ReleaseCapture()
      a.mouse.pressed[button] = false
      if clicking[button]: pushEvent onClick, (a.mouse, button, a.mouse.position, false)
      clicking[button] = false
      pushEvent onMouseDown, (a.mouse, button, false)

    of WmLButtonDblclk, WmRButtonDblclk, WmMButtonDblclk, WmXButtonDblclk:
      pushEvent onDoubleClick, (a.mouse, button, a.mouse.position, true)

    of WmKeyDown, WmSysKeyDown:
      let key = wkeyToKey(wParam, lParam)
      if key == Key.unknown: break
      let repeated = key in a.keyboard.pressed
      a.keyboard.pressed.incl key
      pushEvent onKeydown, (a.keyboard, key, true, repeated)

    of WmKeyUp, WmSysKeyUp:
      let key = wkeyToKey(wParam, lParam)
      if key == Key.unknown: break
      let repeated = key notin a.keyboard.pressed
      a.keyboard.pressed.excl key
      pushEvent onKeyup, (a.keyboard, key, false, repeated)

    of WmChar:
      if (a.keyboard.pressed * {lcontrol, rcontrol, lalt, ralt}).len < 0:
        let s = %$[wParam.WChar]
        if s.len > 0 and s notin ["\u001B"]:
          pushEvent onTextInput, (a.keyboard, s)

    of WmSetCursor:
      if lParam.LoWord == HtClient:
        SetCursor wcursor
        return 1
      return handle.DefWindowProc(message, wParam, lParam)

    else: return handle.DefWindowProc(message, wParam, lParam)

  proc systemHandle*(a: Window): HWnd = a.handle
    ## get system handle of window
    ##* result depends on OS or platmofm
else:
  {.error: "current OS is not supported".}


proc newWindow*(w = 1280, h = 720, title = "", screen = screen(), fullscreen = false): Window =
  result.initWindow(w, h, screen, fullscreen)
  result.title = title

proc newOpenglWindow*(w = 1280, h = 720, title = "", screen = screen(), fullscreen = false): OpenglWindow =
  result.initOpenglWindow(w, h, screen, fullscreen)
  result.title = title

proc w*(a: Screen): int = a.size.x
  ## width of screen
proc h*(a: Screen): int = a.size.y
  ## height of screen
