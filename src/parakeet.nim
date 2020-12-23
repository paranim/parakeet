import nimgl/glfw
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

var density: int

proc cursorPosCallback(window: GLFWWindow, xpos: float64, ypos: float64) {.cdecl.} =
  when defined(paravim):
    if not focusOnGame:
      paravim.cursorPosCallback(window, xpos, ypos)
      return
  onMouseMove(xpos * density.float, ypos * density.float)

proc frameSizeCallback(window: GLFWWindow, width: int32, height: int32) {.cdecl.} =
  when defined(paravim):
    paravim.frameSizeCallback(window, width, height)
  onWindowResize(width, height, int(width / density), int(height / density))

proc scrollCallback(window: GLFWWindow, xoffset: float64, yoffset: float64) {.cdecl.} =
  when defined(paravim):
    if not focusOnGame:
      paravim.scrollCallback(window, xoffset, yoffset)

when isMainModule:
  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)

  let w: GLFWWindow = glfwCreateWindow(1024, 768, "Parakeet")
  if w == nil:
    quit(-1)

  w.makeContextCurrent()
  glfwSwapInterval(1)

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

  var game = Game()
  when defined(paravim):
    paravim.init(game, w)
  game.init()

  game.totalTime = glfwGetTime()

  while not w.windowShouldClose:
    let ts = glfwGetTime()
    game.deltaTime = ts - game.totalTime
    game.totalTime = ts
    game.tick()
    when defined(paravim):
      if not focusOnGame:
        discard paravim.tick(game)
    w.swapBuffers()
    glfwPollEvents()

  w.destroyWindow()
  glfwTerminate()
