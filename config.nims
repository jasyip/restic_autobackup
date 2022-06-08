switch("path", "$projectDir/../src")


when defined(release):
    switch("define", "danger")
    switch("define", "chronicles_disable_thread_id")
    switch("define", "chronicles_log_level:NOTICE")
    switch("define", "rabShowStats:off")
else:
    switch("debugger", "native")

switch("define", "chronicles_indent=4")

switch("threads", "on")
switch("multimethods", "on")
