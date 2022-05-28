

from std/logging import
                        newConsoleLogger, addHandler,
                        info, notice, warn,
                        lvlAll, lvlNotice
from std/monotimes import getMonoTime, `-`, MonoTime
from std/os import `/`, parentDir, removeFile
from std/osproc import startProcess, waitForExit, poParentStreams, poUsePath
from std/sequtils import concat
from std/streams import openFileStream, close, FileStream
from std/strformat import `&`
from std/times import cpuTime
from std/tempfiles import genTempPath



from private/format import cpuTimePrint, monoTimePrint
from private/search import getSpecialFiles
from private/parse import parseConfig











template info: auto = instantiationInfo(fullPaths = true)


const
    shareDir: string = info.fileName.parentDir.parentDir / "share"
    cfgFile : string = shareDir / "restic.cfg"


















proc main =

    var logger = newConsoleLogger(when defined(release): lvlNotice else: lvlAll)
    addHandler(logger)


    var cfgFileStream: FileStream = openFileStream(cfgFile)
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

        let fileCount: uint = getSpecialFiles(strm, baseDirs)

        let
            endCpuTime  : float    = cpuTime()
            endMonoTime : MonoTime = getMonoTime()

        info(
             &"Added {fileCount} dirs/files" & " " &
             &"in {cpuTimePrint(endCpuTime - startCpuTime)} CPU seconds" & " and " &
             &"{monoTimePrint(endMonoTime - startMonoTime)} seconds" & " " &
              "for restic."
            )

    info "Now executing restic command..."

    let args: seq[string] = concat(
                                   @["backup"],
                                   resticOptions,
                                   @["--files-from-raw", specialFilesPath],
                                  )


    var resticProcess = startProcess(
                                     "restic", args = args,
                                     options = {poParentStreams, poUsePath},
                                     workingDir = shareDir,
                                    )
    let code = resticProcess.waitForExit()

    removeFile(specialFilesPath)

    if code != 0:
        info &"restic returned status code {code}"

    quit code









when isMainModule:
    main()
