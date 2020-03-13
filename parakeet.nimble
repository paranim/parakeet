# Package

version       = "0.1.0"
srcDir        = "src"
bin           = @["parakeet"]



# Dependencies

requires "nim >= 1.0.4"
requires "paranim >= 0.3.0"
requires "pararules >= 0.2.0"
requires "stb_image >= 2.5"

when not defined(release):
  requires "paravim >= 0.2.0"
