import staticglfw #nimgl/glfw
import core

when defined(paravim):
  from paravim import nil
  var focusOnGame = true

proc keyCallback(window: Window, key: int32, scancode: int32, action: int32, mods: int32) {.cdecl.} =
  when defined(paravim):
    if action == PRESS and key == GLFWKey.Escape and paravim.isNormalMode():
      focusOnGame = not focusOnGame
      return
    else:
      if not focusOnGame:
        paravim.keyCallback(window, key, scancode, action, mods)
        return
  if action == PRESS:
    onKeyPress(key)
  elif action == RELEASE:
    onKeyRelease(key)

proc charCallback(window: Window, codepoint: uint32) {.cdecl.} =
  when defined(paravim):
    if not focusOnGame:
      paravim.charCallback(window, codepoint)
      return

proc mouseButtonCallback(window: Window, button: int32, action: int32, mods: int32) {.cdecl.} =
  when defined(paravim):
    if not focusOnGame:
      paravim.mouseButtonCallback(window, button, action, mods)
      return
  if action == Press:
    onMouseClick(button)

proc cursorPosCallback(window: Window, xpos: float64, ypos: float64) {.cdecl.} =
  when defined(paravim):
    if not focusOnGame:
      paravim.cursorPosCallback(window, xpos, ypos)
      return
  onMouseMove(xpos, ypos)

var density: int

proc frameSizeCallback(window: Window, width: int32, height: int32) {.cdecl.} =
  when defined(paravim):
    paravim.frameSizeCallback(window, width, height)
  onWindowResize(width, height, int(width / density), int(height / density))

proc scrollCallback(window: Window, xoffset: float64, yoffset: float64) {.cdecl.} =
  when defined(paravim):
    if not focusOnGame:
      paravim.scrollCallback(window, xoffset, yoffset)

when defined(emscripten):
  proc emscripten_set_main_loop(f: proc() {.cdecl.}, a: cint, b: bool) {.importc.}

var
  game: Game
  w: Window

proc mainLoop() {.cdecl.} =
  let ts = getTime()
  game.deltaTime = ts - game.totalTime
  game.totalTime = ts
  game.tick()
  when defined(paravim):
    if not focusOnGame:
      discard paravim.tick(game)
  w.swapBuffers()
  pollEvents()

when isMainModule:
  doAssert init() == 1

  windowHint(CONTEXT_VERSION_MAJOR, 3)
  windowHint(CONTEXT_VERSION_MINOR, 3)
  windowHint(OPENGL_FORWARD_COMPAT, TRUE) # Used for Mac
  windowHint(OPENGL_PROFILE, OPENGL_CORE_PROFILE)
  windowHint(RESIZABLE, TRUE)

  w = createWindow(1024, 768, "Parakeet", nil, nil)
  if w == nil:
    quit(-1)

  w.makeContextCurrent()
  swapInterval(1)

  discard w.setKeyCallback(keyCallback)
  discard w.setCharCallback(charCallback)
  discard w.setMouseButtonCallback(mouseButtonCallback)
  discard w.setCursorPosCallback(cursorPosCallback)
  discard w.setFramebufferSizeCallback(frameSizeCallback)
  discard w.setScrollCallback(scrollCallback)

  var width, height: int32
  w.getFramebufferSize(width.addr, height.addr)

  var windowWidth, windowHeight: int32
  w.getWindowSize(windowWidth.addr, windowHeight.addr)

  density = max(1, int(width / windowWidth))
  w.frameSizeCallback(width, height)

  game = Game()
  when defined(paravim):
    paravim.init(game, w)
  game.init()

  game.totalTime = getTime()

  when defined(emscripten):
    emscripten_set_main_loop(mainLoop, 0, true)
  else:
    while w.windowShouldClose == 0:
      mainLoop()
    w.destroyWindow()
    terminate()
