import nimgl/opengl
from nimgl/glfw import GLFWKey
import stb_image/read as stbi
import paranim/gl, paranim/gl/entities
import pararules
import sets
from math import `mod`

type
  Game* = object of RootGame
    deltaTime*: float
    totalTime*: float
  Id = enum
    Global, Player
  Attr = enum
    DeltaTime, TotalTime,
    WindowWidth, WindowHeight,
    WorldWidth, WorldHeight,
    PressedKeys, MouseClick, MouseX, MouseY,
    X, Y, Width, Height,
    XVelocity, YVelocity, XChange, YChange,
    CanJump, ImageIndex, Direction,
  DirectionName = enum
    Left, Right
  IntSet = HashSet[int]

schema Fact(Id, Attr):
  DeltaTime: float
  TotalTime: float
  WindowWidth: int
  WindowHeight: int
  WorldWidth: int
  WorldHeight: int
  PressedKeys: IntSet
  MouseClick: int
  MouseX: float
  MouseY: float
  X: float
  Y: float
  Width: float
  Height: float
  XVelocity: float
  YVelocity: float
  XChange: float
  YChange: float
  CanJump: bool
  ImageIndex: int
  Direction: DirectionName

const
  images = [
    staticRead("assets/player_walk1.png"),
    staticRead("assets/player_walk2.png"),
    staticRead("assets/player_walk3.png")
  ]
  gravity = 250
  deceleration = 0.9
  damping = 0.5
  maxVelocity = 1000f
  maxJumpVelocity = float(maxVelocity * 4)
  animationSecs = 0.2

var
  imageEntities: array[3, ImageEntity]

proc decelerate(velocity: float): float =
  let v = velocity * deceleration
  if abs(v) < damping: 0f else: v

var (session, rules) =
  initSessionWithRules(Fact):
    # getters
    rule getWindow(Fact):
      what:
        (Global, WindowWidth, windowWidth)
        (Global, WindowHeight, windowHeight)
    rule getWorld(Fact):
      what:
        (Global, WorldWidth, worldWidth)
        (Global, WorldHeight, worldHeight)
    rule getKeys(Fact):
      what:
        (Global, PressedKeys, keys)
    rule getPlayer(Fact):
      what:
        (Player, X, x)
        (Player, Y, y)
        (Player, Width, width)
        (Player, Height, height)
        (Player, ImageIndex, imageIndex)
        (Player, Direction, direction)
    # enable and perform jumping
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
    # move the player's x,y position and animate
    rule movePlayer(Fact):
      what:
        (Global, DeltaTime, dt)
        (Global, PressedKeys, keys, then = false)
        (Player, X, x, then = false)
        (Player, Y, y, then = false)
        (Player, XVelocity, xv, then = false)
        (Player, YVelocity, yv, then = false)
      then:
        var xvNew =
          if keys.contains(int(GLFWKey.Left)):
            -1 * maxVelocity
          elif keys.contains(int(GLFWKey.Right)):
            maxVelocity
          else:
            xv
        var yvNew = yv + gravity
        let xChange = xvNew * dt
        let yChange = yvNew * dt
        session.insert(Player, XVelocity, decelerate(xvNew))
        session.insert(Player, YVelocity, decelerate(yvNew))
        session.insert(Player, XChange, xChange)
        session.insert(Player, YChange, yChange)
        session.insert(Player, X, x + xChange)
        session.insert(Player, Y, y + yChange)
    rule animatePlayer(Fact):
      what:
        (Global, TotalTime, tt)
        (Player, XVelocity, xv)
        (Player, YVelocity, yv)
      cond:
        xv != 0
        yv == 0
      then:
        let cycleTime = tt mod (animationSecs * images.len)
        let index = int(cycleTime / animationSecs)
        session.insert(Player, ImageIndex, index)
        session.insert(Player, Direction, if xv > 0: Right else: Left)
    # prevent going through walls
    rule preventMoveLeft(Fact):
      what:
        (Player, X, x)
        (Player, XChange, xChange)
      cond:
        x < 0
      then:
        let oldX = x - xChange
        let leftEdge = 0f
        session.insert(Player, X, max(oldX, leftEdge))
        session.insert(Player, XVelocity, 0f)
    rule preventMoveRight(Fact):
      what:
        (Global, WorldWidth, worldWidth)
        (Player, X, x)
        (Player, Width, width)
        (Player, XChange, xChange)
      cond:
        x > float(worldWidth) - width
      then:
        let oldX = x - xChange
        let rightEdge = float(worldWidth) - width
        session.insert(Player, X, min(oldX, rightEdge))
        session.insert(Player, XVelocity, 0f)
    rule preventMoveDown(Fact):
      what:
        (Global, WorldHeight, worldHeight)
        (Player, Y, y)
        (Player, Height, height)
        (Player, YChange, yChange)
      cond:
        y > float(worldHeight) - height
      then:
        let oldY = y - yChange
        let bottomEdge = float(worldHeight) - height
        session.insert(Player, Y, min(oldY, bottomEdge))
        session.insert(Player, YVelocity, 0f)
        session.insert(Player, CanJump, true)

proc onKeyPress*(key: int) =
  var (keys) = session.query(rules.getKeys)
  keys.incl(key)
  session.insert(Global, PressedKeys, keys)

proc onKeyRelease*(key: int) =
  var (keys) = session.query(rules.getKeys)
  keys.excl(key)
  session.insert(Global, PressedKeys, keys)

proc onMouseClick*(button: int) =
  session.insert(Global, MouseClick, button)

proc onMouseMove*(xpos: float, ypos: float) =
  session.insert(Global, MouseX, xpos)
  session.insert(Global, MouseY, ypos)

proc onWindowResize*(windowWidth: int, windowHeight: int, worldWidth: int, worldHeight: int) =
  if windowWidth == 0 or windowHeight == 0:
    return
  session.insert(Global, WindowWidth, windowWidth)
  session.insert(Global, WindowHeight, windowHeight)
  session.insert(Global, WorldWidth, worldWidth)
  session.insert(Global, WorldHeight, worldHeight)

proc init*(game: var Game) =
  # opengl
  doAssert glInit()
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  # load images
  var
    width, height, channels: int
    data: seq[uint8]
  for i in 0 ..< images.len:
    data = stbi.loadFromMemory(cast[seq[uint8]](images[i]), width, height, channels, stbi.RGBA)
    let uncompiledImage = initImageEntity(data, width, height)
    imageEntities[i] = compile(game, uncompiledImage)

  # set initial values
  session.insert(Global, PressedKeys, initHashSet[int]())
  session.insert(Player, X, 0f)
  session.insert(Player, Y, 0f)
  session.insert(Player, Width, float(width))
  session.insert(Player, Height, float(height))
  session.insert(Player, XVelocity, 0f)
  session.insert(Player, YVelocity, 0f)
  session.insert(Player, CanJump, false)
  session.insert(Player, ImageIndex, 0)
  session.insert(Player, Direction, Right)

proc tick*(game: Game) =
  session.insert(Global, DeltaTime, game.deltaTime)
  session.insert(Global, TotalTime, game.totalTime)

  let (windowWidth, windowHeight) = session.query(rules.getWindow)
  let (worldWidth, worldHeight) = session.query(rules.getWorld)
  let player = session.query(rules.getPlayer)

  glClearColor(173/255, 216/255, 230/255, 1f)
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0, 0, int32(windowWidth), int32(windowHeight))

  let x =
    if player.direction == Right:
      player.x
    else:
      player.x + player.width
  let width =
    if player.direction == Right:
      player.width
    else:
      player.width * -1

  var image = imageEntities[player.imageIndex]
  image.project(float(worldWidth), float(worldHeight))
  image.translate(x, player.y)
  image.scale(width, player.height)
  render(game, image)

