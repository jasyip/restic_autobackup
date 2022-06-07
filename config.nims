switch("path", "$projectDir/../src")


when defined(release):
    switch("define", "danger")
    switch("define", "chronicles_disable_thread_id")
    switch("define", "chronicles_indent=4")
else:
    switch("debugger", "native")

