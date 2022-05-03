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
requires "paranim >= 0.12.0"
requires "pararules >= 1.0.0"
requires "stb_image >= 2.5"

# Dev Dependencies

requires "paravim >= 0.18.3"
