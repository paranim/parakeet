import nimgl/opengl
import stb_image/read as stbi
import paranim/gl, paranim/gl/entities2d
import pararules

type
  Game* = object of RootGame
    deltaTime*: float64
    totalTime*: float64
    image: ImageEntity

converter toSeqUint8(s: string): seq[uint8] = cast[seq[uint8]](s)

const playerWalk1 = staticRead("assets/player_walk1.png")
const playerWalk2 = staticRead("assets/player_walk2.png")
const playerWalk3 = staticRead("assets/player_walk3.png")

type
  Id = enum
    Global, Player
  Attr = enum
    DeltaTime, WindowWidth, WindowHeight,
    X, Y, Width, Height

schema Fact(Id, Attr):
  DeltaTime: float64
  WindowWidth: int32
  WindowHeight: int32
  X: cfloat
  Y: cfloat
  Width: cfloat
  Height: cfloat

let rules =
  ruleset:
    rule getWindow(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Global, WindowHeight, windowHeight)
    rule getPlayer(Fact):
      what:
        (Player, X, x)
        (Player, Y, y)
        (Player, Width, width)
        (Player, Height, height)

let session = newSession(Fact)

for r in rules.fields:
  session.add(r)

proc resizeWindow*(width: int32, height: int32) =
  session.insert(Global, WindowWidth, width)
  session.insert(Global, WindowHeight, height)

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

  game.image = compile(game, uncompiledImage)

  session.insert(Player, X, 0f)
  session.insert(Player, Y, 0f)
  session.insert(Player, Width, cfloat(width))
  session.insert(Player, Height, cfloat(height))

proc tick*(game: Game) =
  let (windowWidth, windowHeight) = session.get(rules.getWindow, session.find(rules.getWindow))
  let (x, y, width, height) = session.get(rules.getPlayer, session.find(rules.getPlayer))

  glClearColor(173/255, 216/255, 230/255, 1f)
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0, 0, windowWidth, windowHeight)

  var image = game.image
  image.project(cfloat(windowWidth), cfloat(windowHeight))
  image.translate(x, y)
  image.scale(width, height)
  render(game, image)

  session.insert(Global, DeltaTime, game.deltaTime)

