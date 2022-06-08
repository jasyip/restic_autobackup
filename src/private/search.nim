
from std/cpuinfo import countProcessors

from std/locks import
                      initLock, acquire, release, deinitLock, Lock,
                      initCond, wait, broadcast, deinitCond, Cond

from std/os import parentDir, dirExists, walkDir, lastPathPart, pcDir, pcLinkToDir
from std/sequtils import toSeq
from std/strformat import `&`

from regex import re, contains
from faststreams/outputs import OutputStream, write


import ./logging




const cacheRegex = re"\b[cC]ache|CACHE\b"











type ThreadArg = object
    ind                  :     uint
    dir                  :     string
    availableThreadInds  : ptr seq[uint]    # thread management
    exclusionCount       : ptr uint         # thread management
    stream               :     OutputStream # stream
    streamLock           : ptr Lock
    threadManagementLock : ptr Lock
    threadManagementCond : ptr Cond




proc addToStream(strm: OutputStream; added: var uint; path: string) =
    if added > 0:
        strm.write("\n")

    added += 1

    strm.write(path)




proc searchDirectory(arg: ThreadArg) {. thread .} =


    acquire arg.threadManagementLock[]
    debug(
          "Starting directory search",
          dir = arg.dir,
          threadInd = arg.ind,
          availableThreadInds = arg.availableThreadInds[]
         )
    release arg.threadManagementLock[]

    var exclusionCount: uint = 0

    proc makeAvailable =

        acquire arg.threadManagementLock[]

        arg.availableThreadInds[].add arg.ind

        debug(
              "Finished searching directory",
              dir = arg.dir,
              numAddedExclusions = exclusionCount,
              threadInd = arg.ind,
              availableThreadInds = arg.availableThreadInds[]
             )
        arg.exclusionCount[] += exclusionCount


        broadcast arg.threadManagementCond[]
        release arg.threadManagementLock[]


    onThreadDestruction makeAvailable


    if not dirExists(arg.dir):
        raise newException(OSError, &"'{arg.dir}' may be nonexistent/inaccessible")


    proc addPath(path: string) =
        acquire arg.streamLock[]
        addToStream(arg.stream, exclusionCount, path)
        release arg.streamLock[]

    proc shouldExclude(curDir: string): bool = contains(curDir.lastPathPart, cacheRegex)

    var stack: seq[string] = @[arg.dir]

    while stack.len > 0:
        let curDir: string = stack.pop
        if curDir.shouldExclude:
            # Keep traversing
            addPath curDir
        else:

            for kind, nextPath in walkDir(curDir):
                if kind == pcDir:
                    stack.add nextPath
                elif kind != pcLinkToDir and curDir.shouldExclude:
                    addPath nextPath




proc exclusions*(stream: OutputStream; baseDirs: openarray[string]): uint = 

    if baseDirs.len == 0: return 0

    let nThreads: uint = min(cast[uint](baseDirs.len), max(cast[uint](countProcessors()), 1'u))
    var
        threads: seq[Thread[ThreadArg]] = newSeq[Thread[ThreadArg]](nThreads)
        availableThreadInds: seq[uint] = toSeq(0'u ..< nThreads)
        streamLock: Lock
        threadManagementLock: Lock
        threadManagementCond: Cond

    initLock streamLock
    initLock threadManagementLock
    initCond threadManagementCond



    var curDirInd: uint = 0


    while curDirInd < cast[uint](baseDirs.len):

        acquire threadManagementLock
        while availableThreadInds.len == 0:
            wait(threadManagementCond, threadManagementLock)

        # Use an available thread
        let threadInd: uint = availableThreadInds.pop
        release threadManagementLock

        let arg = ThreadArg(
                            ind: threadInd,
                            dir: baseDirs[curDirInd],
                            availableThreadInds: addr availableThreadInds,
                            stream: stream,
                            exclusionCount: addr result,
                            streamLock: addr streamLock,
                            threadManagementLock: addr threadManagementLock,
                            threadManagementCond: addr threadManagementCond,
                           )
        createThread(threads[threadInd], searchDirectory, arg)

        curDirInd.inc

    for i, thread in threads.mpairs:
        debug(
              "Thread follow-up",
              threadInd = i,
              stillRunning = thread.running,
             )
        joinThread thread


    deinitLock streamLock
    deinitLock threadManagementLock
    deinitCond threadManagementCond

    debug(
          "Thread Management",
          nThreads = nThreads,
          availableThreadIndsLen = availableThreadInds.len,
          availableThreadInds = availableThreadInds,
         )

