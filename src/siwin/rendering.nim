import math, strformat
import color, geometry, image

type Renderer* = object
  data*: Picture
  area*: Rect2i

proc render*(a: Picture): Renderer =
  ## создаёт отрисовщик для изображения
  result.data = a
  result.area = rect(0.vec2, size= a.size - 1)

proc size*(a: Renderer): Vec2i = a.data.size

proc `[]`*(a: Renderer; x, y: int): var Color =
  when not defined(release):
    if vec2(x, y) notin a.area:
      raise IndexDefect.newException(&"index is out of bounds, {vec2(x, y)} notin {a.area}")
  a.data[x, y]
proc `[]=`*(a: Renderer; x, y: int, c: Color) =
  when not defined(release):
    if vec2(x, y) notin a.area:
      raise IndexDefect.newException(&"index is out of bounds, {vec2(x, y)} notin {a.area}")
  a.data[x, y] = c

proc `[]`*(a: Renderer, i: Vec2i): var Color = a[i.x, i.y]
proc `[]=`*(a: Renderer, i: Vec2i, v: Color) = a[i.x, i.y] = v

proc pixel*(a: Renderer, x, y: int; c: Color) =
  ## рисует один пиксель. неэффективна для рисования нескольких пикселей
  if (x, y) notin a.area: return
  if c.a == 255:
    a[x, y] = c
  else:
    a[x, y].blend = c

proc clear*(a: Renderer, c: Color) =
  ## очищает всю область рисования, может устанавливать прозрачный цвет
  if a.area == rect(0, 0, a.size.x - 1, a.size.y - 1):
    for v in a.data:
      v = c
  else:
    for p in a.area:
      a[p] = c

proc fill*(a: Renderer, c: Color) =
  ## заливает всю область рисования
  if c.a == 255: a.clear c
  else:
    for (x, y) in a.area:
      a[x, y].blend = c

proc linef*(a: Renderer, r: Rect2i, c: Color) =
  ## быстро рисует линию, БЕЗ сглаживания
  if c.a == 0: return
  var r = r

  proc mix(a: var Color) =
    if c.a == 255: a = c
    else: a.blend = c
  
  if r.h == 0: # горизонтальная линия
    sort r.a.x, r.b.x
    r.X = r.X & a.area.X
    if r notin a.area: return
    
    for i in r.X:
      mix a[i, r.y]
  elif r.w == 0: # вертикальная линия
    sort r.a.y, r.b.y
    r.Y = r.Y & a.area.Y
    if r notin a.area: return
    
    for i in r.Y:
      mix a[r.x, i]
  else:
    if r.w < 0: swap r.a, r.b
    var dx = r.w / r.h # x = y * dx
    var dy = r.h / r.w # y = x * dy

    if r.x < a.area.x:
      r.y = r.y + ((a.area.x - r.x).float * dy).round.int
      r.x = a.area.x
    if r.y < a.area.y:
      r.x = r.x + ((a.area.y - r.y).float * dx).round.int
      r.y = a.area.y
    if r.b.x > a.area.b.x:
      r.b.y = r.b.y + ((a.area.b.x - r.b.x).float * dy).round.int
      r.b.x = a.area.b.x
    if r.b.y > a.area.b.y:
      r.b.x = r.b.x + ((a.area.b.y - r.b.y).float * dx).round.int
      r.b.y = a.area.b.y
    if r.b.y < a.area.y:
      r.b.x = r.b.x + ((a.area.y - r.b.y).float * dx).round.int
      r.b.y = a.area.y

    dx = r.w / r.h
    dy = r.h / r.w

    if abs(dx) >= abs(dy):
      for i in 0..r.w:
        mix a[r.x + i, r.y + (i.float * dy).round.int]
    else:
      if r.h < 0: swap r.a, r.b
      for i in 0..r.h:
        mix a[r.x + (i.float * dx).round.int, r.y + i]

proc linef*(a: Renderer; p1, p2: Vec2i; c: Color) =
  a.linef((p1, p2), c)

proc line*(a: Renderer, r: Rect2f, c: Color, w: float = 1) =
  ## рисует линию
  ## w: толщина
  ## TODO
  discard

proc line*(a: Renderer; p1, p2: Vec2f; c: Color; w: float = 1) =
  a.line((p1, p2), c, w)
proc line*(a: Renderer; p1, p2: Vec2i; c: Color; w: float = 1) =
  a.line(vec2f p1, vec2f p2, c, w)
proc line*(a: Renderer, r: Rect2i, c: Color, w: float = 1) =
  a.line(rect2f r, c, w)

proc rect*(a: Renderer, r: Rect2i, c: Color) =
  let r = sorted r
  a.line (r.a, vec2(r.b.x, r.y)), c
  if r.h > 0:
    a.line (vec2(r.x, r.b.y), r.b), c
    if r.h > 1:
      a.line rect(r.x, r.y + 1, r.x, r.b.y - 1), c
      a.line rect(r.b.x, r.y + 1, r.b.x, r.b.y - 1), c

proc rect*(a: Renderer; p1, p2: Vec2i; c: Color) =
  a.rect((p1, p2), c)

proc justFillRect*(a: Renderer; r: Rect2i; c: Color) =
  ## заливает прямоугольник без обработки входных параметров
  if c.a == 255:
    for p in r:
      a[p] = c
  else:
    for p in r:
      a[p].blend = c

proc fillRect*(a: Renderer, p: Rect2i, c: Color) =
  a.justFillRect(p & a.area, c)
  
proc fillRect*(a: Renderer; p1, p2: Vec2i; c: Color) =
  a.fillRect((p1, p2), c)

proc image*(a: Renderer, b: Picture, r: Rect2i, srcp: Vec2i = (0, 0), transparent: bool = false) =
  ## рисует изображение
  ##* не масштабирует
  var (r, srcp) = (r, srcp)

  let z = r.a &: 0
  r.b += z
  srcp -= z
  
  let srcz = srcp &: 0
  r.b += srcz
  r.a -= srcz
  srcp :&= 0
  
  if r.b !< a.area.b: return
  if srcp !<= b.size: return
  r = r & a.area &: (r.a + b.size - 1 - srcp)
  
  if transparent:
    for p in 0.vec2..r.size:
      a[r.a + p].blend = b[srcp + p]
  else:
    for p in 0.vec2..r.size:
      a[r.a + p] = b[srcp + p]

proc image*(a: Renderer, b: Picture, pos: Vec2i, srcp: Vec2i = (0, 0), transparent: bool = false) =
  a.image(b, pos..<(pos + b.size), srcp, transparent)
