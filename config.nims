switch("path", "$projectDir/../src")


when defined(release):
    switch("define", "danger")
else:
    switch("debugger", "native")

