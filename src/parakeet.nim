import core

proc main() =
  let w = init()
  while w.run():
    w.update()
  w.destroy()

main()
