import nimgl/glfw
import core

proc keyCallback(window: GLFWWindow, key: int32, scancode: int32, action: int32, mods: int32) {.cdecl.} =
  if action == GLFW_PRESS:
    if key == GLFWKey.Escape:
      window.setWindowShouldClose(true)
    else:
      onKeyPress(key)
  elif action == GLFW_RELEASE:
    onKeyRelease(key)

proc mouseButtonCallback(window: GLFWWindow, button: int32, action: int32, mods: int32) {.cdecl.} =
  if action == GLFWPress:
    onMouseClick(button)

proc cursorPosCallback(window: GLFWWindow, xpos: float64, ypos: float64) {.cdecl.} =
  onMouseMove(xpos, ypos)

proc frameSizeCallback(window: GLFWWindow, width: int32, height: int32) {.cdecl.} =
  onWindowResize(width, height)

when isMainModule:
  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 4)
  glfwWindowHint(GLFWContextVersionMinor, 1)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)

  let w: GLFWWindow = glfwCreateWindow(800, 600, "Parakeet")
  if w == nil:
    quit(-1)

  w.makeContextCurrent()
  glfwSwapInterval(1)

  discard w.setKeyCallback(keyCallback)
  discard w.setMouseButtonCallback(mouseButtonCallback)
  discard w.setCursorPosCallback(cursorPosCallback)
  discard w.setFramebufferSizeCallback(frameSizeCallback)
  var width, height: int32
  w.getFramebufferSize(width.addr, height.addr)
  w.frameSizeCallback(width, height)

  var game = Game()
  game.init()

  game.totalTime = glfwGetTime()

  while not w.windowShouldClose:
    let ts = glfwGetTime()
    game.deltaTime = ts - game.totalTime
    game.totalTime = ts
    game.tick()
    w.swapBuffers()
    glfwPollEvents()

  w.destroyWindow()
  glfwTerminate()
