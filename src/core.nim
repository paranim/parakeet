import nimgl/opengl
import stb_image/read as stbi
import glm
import paranim/gl, paranim/gl/utils, paranim/gl/entities2d, paranim/primitives2d
import tables

type
  Game* = object of RootGame

converter toSeqUint8(s: string): seq[uint8] = cast[seq[uint8]](s)

const playerWalk1 = staticRead("assets/player_walk1.png")
const playerWalk2 = staticRead("assets/player_walk2.png")
const playerWalk3 = staticRead("assets/player_walk3.png")

var image: ImageEntity

proc init*(game: var Game) =
  assert glInit()

  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  glDisable(GL_CULL_FACE)
  glDisable(GL_DEPTH_TEST)

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

proc tick*(game: Game) =
  glClearColor(173/255, 216/255, 230/255, 1f)
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0, 0, 800, 600)

  glDrawArrays(GL_TRIANGLES, 0, image.drawCount)

