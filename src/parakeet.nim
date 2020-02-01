import nimgl/glfw
import core

when not defined(release):
  import hotcodereloading

proc keyProc(window: GLFWWindow, key: int32, scancode: int32,
             action: int32, mods: int32): void {.cdecl.} =
  if key == GLFWKey.ESCAPE and action == GLFWPress:
    window.setWindowShouldClose(true)

  when not defined(release):
    if key == GLFWKey.ENTER and action == GLFWPress:
      performCodeReload()

proc resizeProc(window: GLFWWindow, width: int32, height: int32): void {.cdecl.} =
  resizeWindow(width, height)

when isMainModule:
  assert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 4)
  glfwWindowHint(GLFWContextVersionMinor, 1)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)

  let w: GLFWWindow = glfwCreateWindow(800, 600, "NimGL")
  if w == nil:
    quit(-1)

  discard w.setKeyCallback(keyProc)
  w.makeContextCurrent()

  discard w.setWindowSizeCallback(resizeProc)
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
