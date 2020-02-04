import nimgl/opengl
from nimgl/glfw import GLFWKey
import stb_image/read as stbi
import paranim/gl, paranim/gl/entities2d
import pararules
import sets

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
const maxVelocity = 1000f
const maxJumpVelocity = float(maxVelocity * 8)

type
  Id = enum
    Global, Player
  Attr = enum
    DeltaTime, WindowWidth, WindowHeight,
    PressedKeys, MouseClick, MousePosition,
    X, Y, Width, Height,
    XVelocity, YVelocity
    CanJump,
  IntSet = HashSet[int]
  XYTuple = tuple[x: float, y: float]

schema Fact(Id, Attr):
  DeltaTime: float
  WindowWidth: int
  WindowHeight: int
  PressedKeys: IntSet
  MouseClick: int
  MousePosition: XYTuple
  X: float
  Y: float
  Width: float
  Height: float
  XVelocity: float
  YVelocity: float
  CanJump: bool

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
    rule getKeys(Fact):
      what:
        (Global, PressedKeys, keys)
    rule getPlayer(Fact):
      what:
        (Player, X, x)
        (Player, Y, y)
        (Player, Width, width)
        (Player, Height, height)
    rule allowJump(Fact):
      what:
        (Global, WindowHeight, windowHeight)
        (Player, Height, height)
        (Player, Y, y)
        (Player, CanJump, canJump, then = false)
      cond:
        y > float(windowHeight) - height
        not canJump
      then:
        session.insert(Player, CanJump, true)
    rule doJump(Fact):
      what:
        (Global, PressedKeys, keys)
        (Player, CanJump, canJump, then = false)
      cond:
        keys.contains(int(GLFWKey.Up))
        canJump
      then:
        session.insert(Player, CanJump, false)
        session.insert(Player, YVelocity, -1 * maxJumpVelocity)
    rule movePlayer(Fact):
      what:
        (Global, DeltaTime, dt)
        (Global, PressedKeys, keys, then = false)
        (Player, X, x, then = false)
        (Player, Y, y, then = false)
        (Player, XVelocity, xv, then = false)
        (Player, YVelocity, yv, then = false)
      then:
        xv =
          if keys.contains(int(GLFWKey.Left)):
            -1 * maxVelocity
          elif keys.contains(int(GLFWKey.Right)):
            maxVelocity
          else:
            xv
        yv = yv + gravity
        let xChange = xv * dt
        let yChange = yv * dt
        session.insert(Player, XVelocity, decelerate(xv))
        session.insert(Player, YVelocity, decelerate(yv))
        session.insert(Player, X, x + xChange)
        session.insert(Player, Y, y + yChange)
    rule preventMoveLeft(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Player, X, x)
      cond:
        x < 0
      then:
        session.insert(Player, X, 0f)
        session.insert(Player, XVelocity, 0f)
    rule preventMoveRight(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Player, X, x)
        (Player, Width, width)
      cond:
        x > float(windowWidth) - width
      then:
        session.insert(Player, X, float(windowWidth) - width)
        session.insert(Player, XVelocity, 0f)
    rule preventMoveDown(Fact):
      what:
        (Global, WindowHeight, windowHeight)
        (Player, Y, y)
        (Player, Height, height)
      cond:
        y > float(windowHeight) - height
      then:
        session.insert(Player, Y, float(windowHeight) - height)
        session.insert(Player, YVelocity, 0f)

let session = initSession(Fact)

for r in rules.fields:
  session.add(r)

proc keyDown*(key: int) =
  var (keys) = session.query(rules.getKeys)
  keys.incl(key)
  session.insert(Global, PressedKeys, keys)

proc keyUp*(key: int) =
  var (keys) = session.query(rules.getKeys)
  keys.excl(key)
  session.insert(Global, PressedKeys, keys)

proc mouseButton*(button: int) =
  session.insert(Global, MouseClick, button)

proc mousePosition*(xpos: float, ypos: float) =
  session.insert(Global, MousePosition, (xpos, ypos))

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
  session.insert(Global, PressedKeys, initHashSet[int]())
  session.insert(Player, CanJump, false)

proc tick*(game: Game) =
  let (windowWidth, windowHeight) = session.query(rules.getWindow)
  let (x, y, width, height) = session.query(rules.getPlayer)

  glClearColor(173/255, 216/255, 230/255, 1f)
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0, 0, int32(windowWidth), int32(windowHeight))

  var image = game.image
  image.project(float(windowWidth), float(windowHeight))
  image.translate(x, y)
  image.scale(width, height)
  render(game, image)

  session.insert(Global, DeltaTime, game.deltaTime)

