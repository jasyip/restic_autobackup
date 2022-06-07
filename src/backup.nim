

from std/monotimes import getMonoTime, `-`, MonoTime
from std/options import some
from std/os import `/`, parentDir, removeFile, getEnv, quoteShellCommand
from std/osproc import startProcess, waitForExit, poParentStreams, poUsePath
from std/sequtils import concat
from std/streams import openFileStream, close, FileStream
from std/strformat import `&`
from std/strutils import isEmptyOrWhitespace, join
from std/times import cpuTime, Duration, inNanoseconds
from std/tempfiles import genTempPath


import argparse
import chronicles


# from private/format import formatFloat, formatMonoTime
from private/search import exclusions
from private/parse import parseConfig















const
    defaultCfgPath: string = "/usr/local/share/restic_autobackup/backup.cfg"
    cfgPathEnvKey : string = "RESTIC_AUTOBACKUP_CFG_PATH"

logStream userFriendly[textblocks[NoTimestamps, stderr]]
publicLogScope:
    stream = userFriendly














proc parseMonoTime(duration: Duration): BiggestFloat =
    toBiggestFloat(duration.inNanoseconds) / 1e9'f64




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
                       notice(
                              &"Using {cfgPathEnvKey} environmental variable",
                              cfgPathEnvValue = &"'{cfgPathEnvValue}'",
                             )
                       cfgPathEnvValue
                   else:
                       defaultCfgPath
                  )
        dryRun = opts.dryRun

    except ShortCircuit as e:
        if e.flag == "argparse_help":
            echo p.help
            quit 1

    except UsageError as e:
        fatal "Usage Error", message=getCurrentExceptionMsg()
        quit 1

    debug(
          "Parsed command line arguments",
          cfgFile = cfgFile,
          dryRun = dryRun,
         )


    var cfgFileStream: FileStream
    try:
        cfgFileStream = openFileStream(cfgFile)
    except IOError:
        fatal(
              "Unreadable/invalid/non-existent configuration file",
              file = cfgFile,
             )
        quit 1

    let (baseDirs, resticOptions) = parseConfig(cfgFileStream, cfgFile)

    debug "Options parsed", options = resticOptions

    if baseDirs.len == 0:
        error "No directories to search were found in configuration file"
        quit 1

    info "Analyzing files", baseDirs = baseDirs

    let specialFilesPath: string = genTempPath("", "",)

    debug "Temporary file to hold exclusions", path = specialFilesPath

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
             "Traversal statistics",
             exclusionCount = exclusionCount,
             cpuSeconds = endCpuTime - startCpuTime,
             seconds = parseMonoTime(endMonoTime - startMonoTime),
            )

    info "Now executing restic command..."

    let
        workingDir: string = cfgFile.parentDir
        args: seq[string] = concat(
                                   @["backup"],
                                   resticOptions,
                                   @["--exclude-file", specialFilesPath],
                                   (
                                   if "--exclude-caches" in resticOptions:
                                       @[]
                                   else:
                                       @["--exclude-caches"]
                                   ),
                                   baseDirs,
                                  )

    var exitCode: int = 0


    if dryRun:
        notice(
               "Would execute",
               workingDir = workingDir,
               cmd = "restic" & " " & quoteShellCommand(args),
              )

    else:
        debug(
              "Executing",
              workingDir = workingDir,
              cmd = "restic" & " " & quoteShellCommand(args),
             )
        var resticProcess = startProcess(
                                         "restic", args = args,
                                         options = {poParentStreams, poUsePath},
                                         workingDir = workingDir,
                                        )
        exitCode = resticProcess.waitForExit()
        debug "Finished executing"

    removeFile(specialFilesPath)
    debug "Removed temporary file", path = specialFilesPath

    if exitCode != 0:
        info "Restic returned", code=exitCode

    quit exitCode









when isMainModule:
    main()
