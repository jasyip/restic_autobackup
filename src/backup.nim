

from std/logging import
                        ConsoleLogger, newConsoleLogger, addHandler,
                        info, notice, warn,
                        lvlAll, lvlNotice
from std/monotimes import getMonoTime, `-`, MonoTime
from std/options import some
from std/os import `/`, parentDir, removeFile
from std/osproc import startProcess, waitForExit, poParentStreams, poUsePath
from std/sequtils import concat
from std/streams import openFileStream, close, FileStream
from std/strformat import `&`
from std/times import cpuTime
from std/tempfiles import genTempPath


import argparse


from private/format import formatFloat, formatMonoTime
from private/search import exclusions
from private/parse import parseConfig













template info: auto = instantiationInfo(fullPaths = true)


const
    defaultCfgFile : string = "/usr/local/share/restic_autobackup/backup.cfg"


















proc main =

    var p = newParser:
        help("An executable to be called regularly to backup a good amount of flexible files through restic. Flexible configuration.")
        option("-f", "--config-file", default=some(defaultCfgFile), help="A configuration file to be parsed.")
        flag("-n", "--dry-run", help="Print the command of execution instead.")
        flag("-d", "--debug", help="Print debugging statements to stdout")

    var
        cfgFile: string
        dryRun: bool
        logger: ConsoleLogger

    try:
        let opts = p.parse()

        cfgFile = opts.configFile
        dryRun = opts.dryRun
        logger = newConsoleLogger(if opts.debug: lvlNotice else: lvlAll, useStdErr = true)
        addHandler(logger)


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

    let args: seq[string] = concat(
                                   @["backup"],
                                   resticOptions,
                                   @["--files-from-raw"], baseDirs,
                                   @["--exclude-file", specialFilesPath],
                                  )


    var resticProcess = startProcess(
                                     "restic", args = args,
                                     options = {poParentStreams, poUsePath},
                                    )
    let code = resticProcess.waitForExit()

    removeFile(specialFilesPath)

    if code != 0:
        info &"restic returned status code {code}"

    quit code









when isMainModule:
    main()
