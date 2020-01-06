import nimgl/[glfw, opengl]
import stb_image/read as stbi
import glm
import paranim/gl, paranim/gl/utils, paranim/math

converter toSeqUint8(s: string): seq[uint8] = cast[seq[uint8]](s)

proc keyProc(window: GLFWWindow, key: int32, scancode: int32,
             action: int32, mods: int32): void {.cdecl.} =
  if key == GLFWKey.ESCAPE and action == GLFWPress:
    window.setWindowShouldClose(true)

const imageVertexShader =
  """
  #version 410
  uniform mat3 u_matrix;
  uniform mat3 u_texture_matrix;
  in vec2 a_position;
  out vec2 v_tex_coord;
  void main()
  {
    gl_Position = (vec4(((u_matrix * (vec3(a_position, 1))).xy), 0, 1));
    v_tex_coord = ((u_texture_matrix * (vec3(a_position, 1))).xy);
  }
  """

const imageFragmentShader =
  """
  #version 410
  precision mediump float;
  uniform sampler2D u_image;
  in vec2 v_tex_coord;
  out vec4 o_color;
  void main()
  {
    o_color = (texture(u_image, v_tex_coord));
  }
  """

const playerWalk1 = staticRead("assets/player_walk1.png")
const playerWalk2 = staticRead("assets/player_walk2.png")
const playerWalk3 = staticRead("assets/player_walk3.png")

const rect =
  @[0f, 0f,
    1f, 0f,
    0f, 1f,
    0f, 1f,
    1f, 0f,
    1f, 1f]

proc main() =
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

  let program = createProgram(imageVertexShader, imageFragmentShader)
  glUseProgram(program)
  var vao: GLuint
  glGenVertexArrays(1, vao.addr)
  glBindVertexArray(vao)

  var positionBuf: GLuint
  glGenBuffers(1, positionBuf.addr)
  let drawCount = setArrayBuffer(program, positionBuf, "a_position", Attribute(data: rect, size: 2))

  var
    width, height, channels: int
    data: seq[uint8]
  data = stbi.loadFromMemory(playerWalk1, width, height, channels, stbi.Default)

  var imageUni = glGetUniformLocation(program, "u_image")
  let opts = Opts(
    mipLevel: 0,
    internalFmt: GL_RGBA,
    width: GLsizei(width),
    height: GLsizei(height),
    border: 0,
    srcFmt: GL_RGBA,
    srcType: GL_UNSIGNED_BYTE
  )
  let params = @[
    (GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE),
    (GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE),
    (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
    (GL_TEXTURE_MAG_FILTER, GL_NEAREST)
  ]
  let unit = createTexture(game, imageUni, data, opts, params)
  glUniform1i(imageUni, unit)

  var textureMatrixUni = glGetUniformLocation(program, "u_texture_matrix")
  var textureMatrix = identityMatrix()
  glUniformMatrix3fv(textureMatrixUni, 1, false, textureMatrix.caddr)

  var matrixUni = glGetUniformLocation(program, "u_matrix")
  var matrix = (
    scalingMatrix(cfloat(width), cfloat(height)) *
    translationMatrix(0f, 0f) *
    projectionMatrix(800f, 600f) *
    identityMatrix()
  ).transpose()
  glUniformMatrix3fv(matrixUni, 1, false, matrix.caddr)

  while not w.windowShouldClose:
    glClearColor(173/255, 216/255, 230/255, 1f)
    glClear(GL_COLOR_BUFFER_BIT)
    glViewport(0, 0, 800, 600)

    glDrawArrays(GL_TRIANGLES, 0, drawCount)

    w.swapBuffers()
    glfwPollEvents()

  w.destroyWindow()
  glfwTerminate()

main()
