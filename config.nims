switch("path", "$projectDir/../src")


when defined(release):
    switch("define", "danger")
    switch("define", "chronicles_disable_thread_id")
else:
    switch("debugger", "native")

switch("define", "chronicles_indent=4")

switch("threads", "on")
