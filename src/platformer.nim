import nimgl/[glfw, opengl]
import stb_image/read as stbi
import sequtils
import glm

converter toSeqUint8(s: string): seq[uint8] = cast[seq[uint8]](s)

proc toString(str: seq[char]): string =
  result = newStringOfCap(len(str))
  for ch in str:
    add(result, ch)

proc keyProc(window: GLFWWindow, key: int32, scancode: int32,
             action: int32, mods: int32): void {.cdecl.} =
  if key == GLFWKey.ESCAPE and action == GLFWPress:
    window.setWindowShouldClose(true)

type
  Game = ref object
    texCount: Natural

const twoDVertexShader =
  """
  #version 410
  uniform mat3 u_matrix;
  in vec2 a_position;
  void main()
  {
    gl_Position = (vec4(((u_matrix * (vec3(a_position, 1))).xy), 0, 1));
  }
  """

const twoDFragmentShader =
  """
  #version 410
  precision mediump float;
  uniform vec4 u_color;
  out vec4 o_color;
  void main()
  {
    o_color = u_color;
  }
  """

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

proc checkShaderStatus(shader: GLuint) =
  var params: GLint
  glGetShaderiv(shader, GL_COMPILE_STATUS, params.addr);
  if params != GL_TRUE.ord:
    var
      length: GLsizei
      message = newSeq[char](1024)
    glGetShaderInfoLog(shader, 1024, length.addr, message[0].addr)
    raise newException(Exception, toString(message))

proc createShader(shaderType: GLenum, source: string) : GLuint =
  result = glCreateShader(shaderType)
  var sourceC = cstring(source)
  glShaderSource(result, 1'i32, sourceC.addr, nil)
  glCompileShader(result)
  checkShaderStatus(result)

proc checkProgramStatus(program: GLuint) =
  var params: GLint
  glGetProgramiv(program, GL_LINK_STATUS, params.addr);
  if params != GL_TRUE.ord:
    var
      length: GLsizei
      message = newSeq[char](1024)
    glGetProgramInfoLog(program, 1024, length.addr, message[0].addr)
    raise newException(Exception, toString(message))

proc createProgram(vSource: string, fSource: string) : GLuint =
  var vShader = createShader(GL_VERTEX_SHADER, vSource)
  var fShader = createShader(GL_FRAGMENT_SHADER, fSource)
  result = glCreateProgram()
  glAttachShader(result, vShader)
  glAttachShader(result, fShader)
  glLinkProgram(result)
  checkProgramStatus(result)

type
  Attribute = object
    data: seq[cfloat]
    size: GLint

proc setArrayBuffer(program: GLuint, buffer: GLuint, attribName: string, attr: Attribute): GLsizei =
  result = GLsizei(attr.data.len / attr.size)
  var attribLocation = GLuint(glGetAttribLocation(program, cstring(attribName)))
  var previousBuffer: GLint
  glGetIntegerv(GL_ARRAY_BUFFER_BINDING, previousBuffer.addr)
  glBindBuffer(GL_ARRAY_BUFFER, buffer)
  glBufferData(GL_ARRAY_BUFFER, cint(cfloat.sizeof * attr.data.len), attr.data[0].unsafeAddr, GL_STATIC_DRAW)
  glEnableVertexAttribArray(attribLocation)
  glVertexAttribPointer(attribLocation, attr.size, EGL_FLOAT, false, GLsizei(cfloat.sizeof * attr.size), nil)
  #glBindBuffer(GL_ARRAY_BUFFER, GLuint(previousBuffer))

type
  Opts = object
    mipLevel: GLint
    internalFmt: GLenum
    width: GLsizei
    height: GLsizei
    border: GLint
    srcFmt: GLenum
    srcType: GLenum

proc createTexture(game: Game, uniLoc: GLint, data: seq[uint8], opts: Opts, params: seq[(GLenum, GLenum)]): GLint =
  game.texCount += 1
  let unit = game.texCount - 1
  var texture: GLuint
  glGenTextures(1, texture.addr)
  glActiveTexture(GLenum(GL_TEXTURE0.ord + unit))
  glBindTexture(GL_TEXTURE_2D, texture)
  for (paramName, paramVal) in params:
    glTexParameteri(GL_TEXTURE_2D, paramName, GLint(paramVal))
  # TODO: alignment
  glTexImage2D(GL_TEXTURE_2D, opts.mipLevel, GLint(opts.internalFmt), opts.width, opts.height, opts.border, opts.srcFmt, opts.srcType, data[0].unsafeAddr)
  # TODO: mipmap
  GLint(unit)

proc identityMatrix(): Mat3x3[cfloat] =
  mat3x3(
    vec3(1f, 0f, 0f),
    vec3(0f, 1f, 0f),
    vec3(0f, 0f, 1f)
  )

proc projectionMatrix(width: cfloat, height: cfloat): Mat3x3[cfloat] =
  mat3x3(
    #vec3(2f / width, 0f, 0f),
    #vec3(0f, -2f / height, 0f),
    #vec3(-1f, 1f, 1f)
    vec3(2f / width, 0f, -1f),
    vec3(0f, -2f / height, 1f),
    vec3(0f, 0f, 1f)
  )

proc translationMatrix(x: cfloat, y: cfloat): Mat3x3[cfloat] =
  mat3x3(
    #vec3(1f, 0f, 0f),
    #vec3(0f, 1f, 0f),
    #vec3(x, y, 1f)
    vec3(1f, 0f, x),
    vec3(0f, 1f, y),
    vec3(0f, 0f, 1f)
  )

proc scalingMatrix(x: cfloat, y: cfloat): Mat3x3[cfloat] =
  mat3x3(
    vec3(x, 0f, 0f),
    vec3(0f, y, 0f),
    vec3(0f, 0f, 1f)
  )

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

  let game = Game(texCount: 0)

  let program = createProgram(twoDVertexShader, twoDFragmentShader)
  glUseProgram(program)
  var vao: GLuint
  glGenVertexArrays(1, vao.addr)
  glBindVertexArray(vao)

  var positionBuf: GLuint
  glGenBuffers(1, positionBuf.addr)
  let drawCount = setArrayBuffer(program, positionBuf, "a_position", Attribute(data: rect, size: 2))

  let matrixUni = glGetUniformLocation(program, "u_matrix")
  var matrix =
    (scalingMatrix(50f, 50f) *
     (translationMatrix(0f, 0f) *
      (projectionMatrix(800f, 600f) *
       identityMatrix())))
  glUniformMatrix3fv(matrixUni, 1, false, matrix.caddr)

  let colorUni = glGetUniformLocation(program, "u_color")
  var color = vec4(1f, 0f, 0f, 1)
  glUniform4fv(colorUni, 1, color.caddr)

#[
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

  var textureMatrixUni = glGetUniformLocation(program, "u_texture_matrix")
  var textureMatrix = identityMatrix()
  glUniformMatrix3fv(textureMatrixUni, 1, false, textureMatrix.caddr)

  var matrixUni = glGetUniformLocation(program, "u_matrix")
  var matrix =
    identityMatrix() *
    projectionMatrix(800f, 600f) *
    translationMatrix(0f, 0f) *
    scalingMatrix(cfloat(width), cfloat(height))
  var matrix2 = mat3(
    vec3(7f / 40f, 0f, -1f),
    vec3(0f, -1f / 3f, 1f),
    vec3(0f, 0f, 1f)
  )
  echo matrix2
  glUniformMatrix3fv(matrixUni, 1, false, matrix2.caddr)
]#

  while not w.windowShouldClose:
    glViewport(0, 0, 800, 600)
    glClearColor(173/255, 216/255, 230/255, 1f)
    glClear(GL_COLOR_BUFFER_BIT)

    #glUniform1i(imageUni, unit)
    glDrawArrays(GL_TRIANGLES, 0, drawCount)

    w.swapBuffers()
    glfwPollEvents()

  w.destroyWindow()
  glfwTerminate()

main()
