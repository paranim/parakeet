import paranim/glfw
import core

when defined(paravim):
  from paravim import nil
  var focusOnGame = true

proc keyCallback(window: GLFWWindow, key: int32, scancode: int32, action: int32, mods: int32) {.cdecl.} =
  when defined(paravim):
    if action == GLFW_PRESS and key == GLFWKey.Escape and paravim.isNormalMode():
      focusOnGame = not focusOnGame
      return
    else:
      if not focusOnGame:
        paravim.keyCallback(window, key, scancode, action, mods)
        return
  if action == GLFW_PRESS:
    onKeyPress(key)
  elif action == GLFW_RELEASE:
    onKeyRelease(key)

proc charCallback(window: GLFWWindow, codepoint: uint32) {.cdecl.} =
  when defined(paravim):
    if not focusOnGame:
      paravim.charCallback(window, codepoint)
      return

proc mouseButtonCallback(window: GLFWWindow, button: int32, action: int32, mods: int32) {.cdecl.} =
  when defined(paravim):
    if not focusOnGame:
      paravim.mouseButtonCallback(window, button, action, mods)
      return
  if action == GLFWPress:
    onMouseClick(button)

proc cursorPosCallback(window: GLFWWindow, xpos: float64, ypos: float64) {.cdecl.} =
  when defined(paravim):
    if not focusOnGame:
      paravim.cursorPosCallback(window, xpos, ypos)
      return
  onMouseMove(xpos, ypos)

var density: int

proc frameSizeCallback(window: GLFWWindow, width: int32, height: int32) {.cdecl.} =
  when defined(paravim):
    paravim.frameSizeCallback(window, width, height)
  onWindowResize(width, height, int(width / density), int(height / density))

proc scrollCallback(window: GLFWWindow, xoffset: float64, yoffset: float64) {.cdecl.} =
  when defined(paravim):
    if not focusOnGame:
      paravim.scrollCallback(window, xoffset, yoffset)

when defined(emscripten):
  proc emscripten_set_main_loop(f: proc() {.cdecl.}, a: cint, b: bool) {.importc.}
  proc emscripten_get_canvas_element_size(target: cstring, width: ptr cint, height: ptr cint): cint {.importc.}

var
  game: Game
  window: GLFWWindow

proc mainLoop() {.cdecl.} =
  let ts = glfwGetTime()
  game.deltaTime = ts - game.totalTime
  game.totalTime = ts
  when defined(emscripten):
    var width, height: cint
    if emscripten_get_canvas_element_size("#canvas", width.addr, height.addr) >= 0:
      window.frameSizeCallback(width, height)
    try:
      game.tick()
    except Exception as ex:
      echo ex.msg
  else:
    game.tick()
  when defined(paravim):
    if not focusOnGame:
      discard paravim.tick(game)
  window.swapBuffers()
  glfwPollEvents()

when isMainModule:
  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)

  window = glfwCreateWindow(1024, 768, "Parakeet")
  if window == nil:
    quit(-1)

  window.makeContextCurrent()
  glfwSwapInterval(1)

  discard window.setKeyCallback(keyCallback)
  discard window.setCharCallback(charCallback)
  discard window.setMouseButtonCallback(mouseButtonCallback)
  discard window.setCursorPosCallback(cursorPosCallback)
  discard window.setFramebufferSizeCallback(frameSizeCallback)
  discard window.setScrollCallback(scrollCallback)

  var width, height: int32
  window.getFramebufferSize(width.addr, height.addr)

  var windowWidth, windowHeight: int32
  window.getWindowSize(windowWidth.addr, windowHeight.addr)

  density = max(1, int(width / windowWidth))
  window.frameSizeCallback(width, height)

  when defined(paravim):
    paravim.init(game, window)
  game.init()

  game.totalTime = glfwGetTime()

  when defined(emscripten):
    emscripten_set_main_loop(mainLoop, 0, true)
  else:
    while not window.windowShouldClose:
      mainLoop()

  window.destroyWindow()
  glfwTerminate()
