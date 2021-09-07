import strformat, sequtils, macros, unicode, sugar, sinim
export sugar


proc dataAddr*[T: string|seq|array|openarray|cstring](a: T): auto =
  ## same as C++ `data` that works with std::string, std::vector etc
  ## Note: safe to use when a.len == 0 but whether the result is nil or not is implementation defined
  when T is string|seq|openarray:
    if a.len == 0: nil
    else: (a[0].unsafeAddr)
  elif T is array:
    when a.len > 0: a.unsafeAddr
    else: nil
  elif T is cstring:
    cast[pointer](a)
  else: {.error.}


proc del*[T](a: var seq[T], item: T) =
  let i = a.find(item)
  if i != -1: a.del i
proc delete*[T](a: var seq[T], item: T) =
  let i = a.find(item)
  if i != -1: a.delete i


proc fieldName(a: NimNode): string =
  a.expectKind nnkIdentDefs
  if a[0].kind == nnkPostfix:
    a[0][1].strVal
  else:
    a[0].strVal

proc genFieldBind(a: NimNode, x: NimNode): NimNode =
  a.expectKind nnkIdentDefs
  let name = ident a.fieldName
  if a[1].kind == nnkProcTy:
    return quote do:
      template `name`(args: varargs[untyped]): untyped {.used.} =
        `x`.`name`(args)
  else:
    return quote do:
      template `name`: untyped {.used.} =
        `x`.`name`

proc getAllIdentDefs(x: NimNode): seq[NimNode]

proc getWhenIdentDefs(x: NimNode): seq[NimNode] =
  x.expectKind nnkRecWhen
  for branch in x:
    result &= getAllIdentDefs(branch[1])

proc getAllIdentDefs(x: NimNode): seq[NimNode] =
  for n in x:
    if n.kind == nnkIdentDefs:
      result &= n
    elif n.kind == nnkRecWhen:
      result &= getWhenIdentDefs(n)
    elif n.kind in {nnkRecCase, nnkRecList, nnkOfBranch, nnkElse}:
      result &= getAllIdentDefs(n)

proc fields(a: NimNode): seq[NimNode] =
  a.expectKind {nnkObjectTy, nnkTupleTy}
  if a.kind == nnkObjectTy:
    if a[1].kind == nnkOfInherit:
      for b in a[1]:
        result &= b.getImpl[2].fields
    result &= a[2].getAllIdentDefs.deduplicate
  else:
    result &= a.getAllIdentDefs.deduplicate

proc createInner(x: NimNode, excl: openarray[string] = @[]): seq[NimNode] =
  var t = getTypeImpl(x)
  while t.kind == nnkRefTy:
    t = getTypeImpl(t[0])
  t.expectKind {nnkObjectTy, nnkTupleTy}
  for field in t.fields:
    if field.fieldName notin excl:
      result &= genFieldBind(field, x)

proc withImpl(x: NimNode, body: NimNode, excl: openarray[string] = @[]): NimNode =
  result = newStmtList()
  if x.kind == nnkTupleConstr:
    for y in x:
      result &= createInner(y, excl)
  else:
    result &= createInner(x, excl)
  result &= body

macro withExcl*(x: typed, excl: static[openarray[string]], body: untyped): untyped =
  nnkBlockStmt.newTree(newEmptyNode(), withImpl(x, body, excl))

macro with*(x: untyped, body: untyped): untyped =
  ## allows you to put all the fields of an object or tuple into the
  ## scope of the block that is passed in. This is useful in instances where you
  ## take in an object to a procedure that only does work on this object, for
  ## example an initialiser or what would normally be seen as a method in a
  ## object oriented approach.
  ## 
  ## can be called using pragma or block syntax
  runnableExamples:
    type
      A = object of RootObj
        a: int
      B = object of A
        b: float
    
    proc f(): B {.with: result.} =
      a = 10
      b = 1.0
    
    let v = f()
    with v:
      echo a, ", ", b
  
  if body.kind in {nnkProcDef, nnkFuncDef, nnkTemplateDef}:
    let body = body.asRoutine

    var excl: seq[string]
    if body.hasName: excl &= body.name
    excl &= body.args.map(a => a.name)
    let exclLit = excl.newArrayLit
    
    let r = body.impl
    var res = body
    res.impl = (quote do: withExcl `x`, `exclLit`, `r`)
    result = body.NimNode
  else:
    return quote do:
      withExcl `x`, [], `body`

macro with*(body: untyped): untyped =
  ## with that captures first proc argument
  runnableExamples:
    type A = object
      a: int

    proc f(v: var A) {.with.} =
      a = 10
  
  let body = body.asRoutine
  if body.args.len == 0:
    let prc = case body.kind
      of nnkFuncDef: "func"
      of nnkTemplateDef: "template"
      else: "proc"
    let hint =
      if body.returnType.kind != nnkEmpty: "\ndid you mean `with: result`?"
      else: ""
    error(&"at least one {prc} argument is required{hint}", body.NimNode[3])
  let x = body.args[0].nameNode
  return quote do:
    with `x`, `body`


proc findBy*[T](a: openarray[T], f: proc(a: T): bool): int =
  result = -1
  for i, b in a:
    if f(b): return i
