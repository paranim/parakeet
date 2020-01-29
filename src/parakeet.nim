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

  var game = Game()
  game.init()

  while not w.windowShouldClose:
    game.tick()
    w.swapBuffers()
    glfwPollEvents()

  w.destroyWindow()
  glfwTerminate()
