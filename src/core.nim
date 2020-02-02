import nimgl/opengl
import stb_image/read as stbi
import paranim/gl, paranim/gl/entities2d
import pararules

type
  Game* = object of RootGame
    deltaTime*: float
    totalTime*: float
    image: ImageEntity

converter toSeqUint8(s: string): seq[uint8] = cast[seq[uint8]](s)

const playerWalk1 = staticRead("assets/player_walk1.png")
const playerWalk2 = staticRead("assets/player_walk2.png")
const playerWalk3 = staticRead("assets/player_walk3.png")

const gravity = 500
const deceleration = 0.7
const damping = 0.1

type
  Id = enum
    Global, Player
  Attr = enum
    DeltaTime, WindowWidth, WindowHeight,
    X, Y, Width, Height,
    XVelocity, YVelocity, XChange, YChange

schema Fact(Id, Attr):
  DeltaTime: float
  WindowWidth: int
  WindowHeight: int
  X: float
  Y: float
  Width: float
  Height: float
  XVelocity: float
  YVelocity: float
  XChange: float
  YChange: float

proc decelerate(velocity: float): float =
  let v = velocity * deceleration
  if abs(v) < damping:
    0f
  else:
    v

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
    rule movePlayer(Fact):
      what:
        (Global, DeltaTime, dt)
        (Player, X, x, false)
        (Player, Y, y, false)
        (Player, XVelocity, xv, false)
        (Player, YVelocity, yv, false)
      then:
        let newYv = yv + gravity
        let xChange = xv * dt
        let yChange = newYv * dt
        session.insert(Player, XVelocity, decelerate(xv))
        session.insert(Player, YVelocity, decelerate(newYv))
        session.insert(Player, XChange, xChange)
        session.insert(Player, YChange, yChange)
        session.insert(Player, X, x + xChange)
        session.insert(Player, Y, y + yChange)
    rule preventMoveX(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Player, X, x)
        (Player, Width, width)
        (Player, XChange, xChange)
      cond:
        x < 0 or x > float(windowWidth) - width
      then:
        session.insert(Player, X, x - xChange)
    rule preventMoveY(Fact):
      what:
        (Global, WindowHeight, windowHeight)
        (Player, Y, y)
        (Player, Height, height)
        (Player, YChange, yChange)
      cond:
        y > float(windowHeight) - height
      then:
        session.insert(Player, Y, y - yChange)

let session = newSession(Fact)

for r in rules.fields:
  session.add(r)

proc resizeWindow*(width: int, height: int) =
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
  session.insert(Player, Width, float(width))
  session.insert(Player, Height, float(height))
  session.insert(Player, XVelocity, 0f)
  session.insert(Player, YVelocity, 0f)

proc tick*(game: Game) =
  let (windowWidth, windowHeight) = session.get(rules.getWindow, session.find(rules.getWindow))
  let (x, y, width, height) = session.get(rules.getPlayer, session.find(rules.getPlayer))

  glClearColor(173/255, 216/255, 230/255, 1f)
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0, 0, int32(windowWidth), int32(windowHeight))

  var image = game.image
  image.project(float(windowWidth), float(windowHeight))
  image.translate(x, y)
  image.scale(width, height)
  render(game, image)

  session.insert(Global, DeltaTime, game.deltaTime)

