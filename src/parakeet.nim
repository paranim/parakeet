import nimgl/glfw
import core

proc keyProc(window: GLFWWindow, key: int32, scancode: int32,
             action: int32, mods: int32): void {.cdecl.} =
  if action == GLFWPress:
    if key == GLFWKey.ESCAPE:
      window.setWindowShouldClose(true)
    else:
      keyDown(key)
  elif action == GLFW_RELEASE:
    keyUp(key)

proc mouseButtonProc(window: GLFWWindow, button: int32, action: int32, mods: int32): void {.cdecl.} =
  if action == GLFWPress:
    mouseButton(button)

proc mousePositionProc(window: GLFWWindow, xpos: float64, ypos: float64): void {.cdecl.} =
  mousePosition(xpos, ypos)

proc resizeProc(window: GLFWWindow, width: int32, height: int32): void {.cdecl.} =
  resizeWindow(width, height)

when isMainModule:
  assert glfwInit()

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

  discard w.setKeyCallback(keyProc)
  discard w.setMouseButtonCallback(mouseButtonProc)
  discard w.setCursorPosCallback(mousePositionProc)
  discard w.setFramebufferSizeCallback(resizeProc)
  var width, height: int32
  w.getFramebufferSize(width.addr, height.addr)
  w.resizeProc(width, height)

  var game = Game()
  game.init()

  while not w.windowShouldClose:
    let ts = glfwGetTime()
    game.deltaTime = ts - game.totalTime
    game.totalTime = ts
    game.tick()
    w.swapBuffers()
    glfwPollEvents()

  w.destroyWindow()
  glfwTerminate()
