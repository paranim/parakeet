when defined(release):
  switch("app", "gui")
else:
  switch("define", "paravim") # remove this line to disable paravim
