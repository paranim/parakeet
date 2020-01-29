import nimgl/[glfw, opengl]
import stb_image/read as stbi
import glm
import paranim/gl, paranim/gl/utils, paranim/gl/entities2d, paranim/primitives2d
import tables

when not defined(release):
  import hotcodereloading

converter toSeqUint8(s: string): seq[uint8] = cast[seq[uint8]](s)

proc keyProc(window: GLFWWindow, key: int32, scancode: int32,
             action: int32, mods: int32): void {.cdecl.} =
  if key == GLFWKey.ESCAPE and action == GLFWPress:
    window.setWindowShouldClose(true)

  when not defined(release):
    if key == GLFWKey.ENTER and action == GLFWPress:
      performCodeReload()

const playerWalk1 = staticRead("assets/player_walk1.png")
const playerWalk2 = staticRead("assets/player_walk2.png")
const playerWalk3 = staticRead("assets/player_walk3.png")

var image: ImageEntity

proc init*(): GLFWWindow =
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

  assert glInit()

  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  glDisable(GL_CULL_FACE)
  glDisable(GL_DEPTH_TEST)

  var game = Game(texCount: 0)

  var
    width, height, channels: int
    data: seq[uint8]
  data = stbi.loadFromMemory(playerWalk1, width, height, channels, stbi.Default)
  let uncompiledImage = initImageEntity(game, data, width, height)

  image = compile(game, uncompiledImage)

  var imageUni = glGetUniformLocation(image.program, "u_image")
  let unit = createTexture(game, imageUni, uncompiledImage.textureUniforms["u_image"])
  glUniform1i(imageUni, unit)

  var textureMatrixUni = glGetUniformLocation(image.program, "u_texture_matrix")
  var textureMatrix = identityMatrix()
  glUniformMatrix3fv(textureMatrixUni, 1, false, textureMatrix.caddr)

  var matrixUni = glGetUniformLocation(image.program, "u_matrix")
  var matrix = (
    scalingMatrix(cfloat(width), cfloat(height)) *
    translationMatrix(0f, 0f) *
    projectionMatrix(800f, 600f) *
    identityMatrix()
  ).transpose()
  glUniformMatrix3fv(matrixUni, 1, false, matrix.caddr)

  w

proc run*(w: GLFWWindow): bool =
  not w.windowShouldClose

proc update*(w: GLFWWindow) =
  glClearColor(173/255, 216/255, 230/255, 1f)
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0, 0, 800, 600)

  glDrawArrays(GL_TRIANGLES, 0, image.drawCount)

  w.swapBuffers()
  glfwPollEvents()

proc destroy*(w: GLFWWindow) =
  w.destroyWindow()
  glfwTerminate()

