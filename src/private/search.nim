
from std/cpuinfo import countProcessors
from std/deques import initDeque, toDeque, addLast, popLast, len, Deque

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





proc addToStream(strm: OutputStream; added: var uint; path: string) =
    if added > 0:
        strm.write("\n")

    added += 1

    strm.write(path)






type ThreadArg = object
    ind: uint
    dir: string
    availableThreadInds: ptr Deque[uint]
    exclusionCount: ptr uint
    stream: OutputStream
    streamLock: ptr Lock
    threadManagementLock: ptr Lock
    threadManagementCond: ptr Cond 



proc searchDirectory(arg: ThreadArg) {. thread .} =

    proc makeAvailable =

        acquire arg.threadManagementLock[]

        arg.availableThreadInds[].addLast arg.ind

        broadcast arg.threadManagementCond[]
        release arg.threadManagementLock[]


    onThreadDestruction makeAvailable


    if not dirExists(arg.dir):
        raise newException(OSError, &"'{arg.dir}' may be nonexistent/inaccessible")


    template addPath(path: string) =
        acquire arg.streamLock[]
        addToStream(arg.stream, arg.exclusionCount[], path)
        release arg.streamLock[]

    proc shouldExclude(curDir: string): bool = contains(curDir.lastPathPart, cacheRegex)

    var stack: Deque[string] = initDeque[string]()
    stack.addLast(arg.dir)

    while stack.len > 0:
        let curDir: string = stack.popLast()
        if curDir.shouldExclude:
            # Keep traversing
            addPath curDir
        else:

            for kind, nextPath in walkDir(curDir):
                if kind == pcDir:
                    stack.addLast(nextPath)
                elif kind != pcLinkToDir and curDir.shouldExclude:
                    addPath nextPath


proc exclusions*(stream: OutputStream; baseDirs: openarray[string]): uint = 

    if baseDirs.len == 0: return 0

    let nThreads: uint = min(cast[uint](baseDirs.len), max(cast[uint](countProcessors()), 1'u))
    var
        threads: seq[Thread[ThreadArg]] = newSeq[Thread[ThreadArg]](nThreads)
        availableThreadInds: Deque[uint] = toSeq(0'u ..< nThreads).toDeque
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
        let threadInd: uint = availableThreadInds.popLast
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

    for thread in threads.mitems:
        joinThread thread

    debug "Thread Management", nThreads = nThreads, threads = threads, availableThreadInds = availableThreadInds


    deinitLock streamLock
    deinitLock threadManagementLock
    deinitCond threadManagementCond


