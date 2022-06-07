

from std/monotimes import getMonoTime, `-`, MonoTime
from std/options import some
from std/os import `/`, parentDir, removeFile, getEnv
from std/osproc import startProcess, waitForExit, poParentStreams, poUsePath
from std/sequtils import concat
from std/streams import openFileStream, close, FileStream
from std/strformat import `&`
from std/strutils import isEmptyOrWhitespace, join
from std/times import cpuTime
from std/tempfiles import genTempPath


import argparse
# import chronicles


from private/format import formatFloat, formatMonoTime
from private/search import exclusions
from private/parse import parseConfig















const
    defaultCfgPath: string = "/usr/local/share/restic_autobackup/backup.cfg"
    cfgPathEnvKey : string = "RESTIC_AUTOBACKUP_CFG_PATH"


















proc main =

    let cfgPathEnvValue = getEnv(cfgPathEnvKey)

    var p = newParser:
        help("An executable to be called regularly to backup a good amount of flexible files through restic. Flexible configuration.")
        option("-f", "--config-file", help="A configuration file to be parsed.")
        flag("-n", "--dry-run", help="Print the command of execution instead.")

    var
        cfgFile: string
        dryRun: bool

    try:
        let opts = p.parse()

        cfgFile = (
                   if not opts.configFile.isEmptyOrWhitespace:
                      opts.configFile
                   elif not cfgPathEnvValue.isEmptyOrWhitespace:
                      notice &"Using {cfgPathEnvKey}='{cfgPathEnvValue}' as configuration file path"
                      cfgPathEnvValue
                   else:
                      defaultCfgPath
                  )
        dryRun = opts.dryRun

    except ShortCircuit as e:
        if e.flag == "argparse_help":
            echo p.help
            quit 1



    var cfgFileStream: FileStream
    try:
        cfgFileStream = openFileStream(cfgFile)
    except IOError:
        raise newException(IOError, &"'{cfgFile}' does not exist or cannot be read.")

    let (baseDirs, resticOptions) = parseConfig(cfgFileStream, cfgFile)



    info &"Analyzing files at {baseDirs}."

    let specialFilesPath: string = genTempPath("", "",)

    block:
        var strm: FileStream = openFileStream(specialFilesPath, fmWrite)
        defer:
            strm.close()


        let
            startCpuTime  : float    = cpuTime()
            startMonoTime : MonoTime = getMonoTime()

        let exclusionCount: uint = exclusions(strm, baseDirs)

        let
            endCpuTime  : float    = cpuTime()
            endMonoTime : MonoTime = getMonoTime()

        info(
             &"Noted {exclusionCount} dirs/files to exclude" & " " &
             &"in {formatFloat(endCpuTime - startCpuTime)} CPU seconds" & " and " &
             &"{formatMonoTime(endMonoTime - startMonoTime)} seconds" & " " &
              "for restic."
            )

    info "Now executing restic command..."

    let
        workingDir: string = cfgFile.parentDir
        args: seq[string] = concat(
                                   @["backup"],
                                   resticOptions,
                                   @["--files-from-raw"], baseDirs,
                                   @["--exclude-file", specialFilesPath],
                                  )

    var exitCode: int = 0

    if dryRun:
        echo &"Executing at {workingDir}: " & "restic" & " " & join(args, ",")

    else:
        var resticProcess = startProcess(
                                         "restic", args = args,
                                         options = {poParentStreams, poUsePath},
                                         workingDir = workingDir,
                                        )
        exitCode = resticProcess.waitForExit()

    removeFile(specialFilesPath)

    if exitCode != 0:
        info &"restic returned status code {code}"

    quit exitCode









when isMainModule:
    main()
