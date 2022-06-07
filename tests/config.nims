switch("path", "$projectDir/../src")
switch("outdir", "$projectDir/../tests-bin")

switch("define", "debug")

switch("define", "nimUnittestOutputLevel:PRINT_FAILURES")
switch("define", "nimUnittestAbortOnError:on")
switch("define", "nimtestParallel")
switch("threads", "on")
