# Package

version       = "0.1.0"
author        = "FIXME"
description   = "FIXME"
license       = "FIXME"
srcDir        = "src"
bin           = @["parakeet"]

task dev, "Run dev version":
  exec "nimble -d:paravim run parakeet"

# Dependencies

requires "nim >= 1.2.6"
requires "paranim >= 0.10.0"
requires "pararules >= 0.14.0"
requires "stb_image >= 2.5"
requires "https://github.com/treeform/staticglfw#d299a0d"
requires "opengl >= 1.2.6"

# Dev Dependencies

requires "paravim >= 0.18.2"
