import nimgl/opengl
import stb_image/read as stbi
import paranim/gl, paranim/gl/entities2d
import pararules

type
  Game* = object of RootGame

converter toSeqUint8(s: string): seq[uint8] = cast[seq[uint8]](s)

const playerWalk1 = staticRead("assets/player_walk1.png")
const playerWalk2 = staticRead("assets/player_walk2.png")
const playerWalk3 = staticRead("assets/player_walk3.png")

type
  Id = enum
    Window, Player
  Attr = enum
    X, Y, Width, Height

schema Fact(Id, Attr):
  X: cfloat
  Y: cfloat
  Width: cfloat
  Height: cfloat

let rules =
  ruleset:
    rule windowResized(Fact):
      what:
        (Window, Width, width)
        (Window, Height, height)
      then:
        echo width, " ", height

let session = newSession(Fact)

for r in rules.fields:
  session.add(r)

var image: ImageEntity

proc resizeWindow*(width: cfloat, height: cfloat) =
  session.insert(Window, Width, width)
  session.insert(Window, Height, height)

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
  var uncompiledImage = initImageEntity(data, width, height)

  uncompiledImage.project(800f, 600f)
  uncompiledImage.translate(0f, 0f)
  uncompiledImage.scale(cfloat(width), cfloat(height))

  image = compile(game, uncompiledImage)

proc tick*(game: Game) =
  glClearColor(173/255, 216/255, 230/255, 1f)
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0, 0, 800, 600)
  render(game, image)

