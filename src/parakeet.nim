import nimgl/glfw
import core

when not defined(release):
  from paravim import nil
  var focusOnGame = true

proc keyCallback(window: GLFWWindow, key: int32, scancode: int32, action: int32, mods: int32) {.cdecl.} =
  when not defined(release):
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
  when not defined(release):
    if not focusOnGame:
      paravim.charCallback(window, codepoint)
      return

proc mouseButtonCallback(window: GLFWWindow, button: int32, action: int32, mods: int32) {.cdecl.} =
  when not defined(release):
    if not focusOnGame:
      paravim.mouseButtonCallback(window, button, action, mods)
      return
  if action == GLFWPress:
    onMouseClick(button)

proc cursorPosCallback(window: GLFWWindow, xpos: float64, ypos: float64) {.cdecl.} =
  when not defined(release):
    if not focusOnGame:
      paravim.cursorPosCallback(window, xpos, ypos)
      return
  onMouseMove(xpos, ypos)

proc frameSizeCallback(window: GLFWWindow, width: int32, height: int32) {.cdecl.} =
  when not defined(release):
    paravim.frameSizeCallback(window, width, height)
  onWindowResize(width, height)

when isMainModule:
  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 4)
  glfwWindowHint(GLFWContextVersionMinor, 1)
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

  var width, height: int32
  w.getFramebufferSize(width.addr, height.addr)
  w.frameSizeCallback(width, height)

  var game = Game()
  when not defined(release):
    paravim.init(game, w)
  game.init()

  game.totalTime = glfwGetTime()

  while not w.windowShouldClose:
    let ts = glfwGetTime()
    game.deltaTime = ts - game.totalTime
    game.totalTime = ts
    game.tick()
    when not defined(release):
      if not focusOnGame:
        paravim.tick(game)
    w.swapBuffers()
    glfwPollEvents()

  w.destroyWindow()
  glfwTerminate()
