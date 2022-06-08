
from std/cpuinfo import countProcessors

from std/locks import
                      initLock, acquire, release, deinitLock, Lock,
                      initCond, wait, broadcast, deinitCond, Cond

from std/os import parentDir, dirExists, walkDir, lastPathPart, pcDir, pcLinkToDir
from std/sequtils import toSeq
from std/strformat import `&`
from std/sugar import `=>`
from std/times import cpuTime

from regex import re, contains, Regex
from faststreams/outputs import OutputStream, write


import ./logging





const
    rabShowStats  {. booldefine .}: bool   = true
    cacheRegexStr {. strdefine  .}: string = r"\b[cC]ache|CACHE\b"
    cacheRegex: Regex = re(cacheRegexStr)








type
    ThreadArgRoot {. inheritable .} = object
        ind                  :     uint
        dir                  :     string
        availableThreadInds  : ptr seq[uint]    # thread management
        stream               :     OutputStream # stream
        streamLock           : ptr Lock
        threadManagementLock : ptr Lock
        threadManagementCond : ptr Cond

    ExtraArgRoot {. inheritable .} = object
    ExtraArgMinimal = object of ExtraArgRoot
        firstAdd: bool

    ReturnRoot* {. inheritable .} = object



    SearchStats* = object
        cpuSeconds    * : float
        exclusionCount* : uint

    ThreadArgStats = object of ThreadArgRoot
        stats: ptr SearchStats
    ExtraArgStats = object of ExtraArgRoot
        startCpuTime: float
        endCpuTime: float
        exclusionCount: uint

    ReturnStats = object of ReturnRoot
        stats: SearchStats






proc threadStart(arg: ThreadArgRoot) =
    acquire arg.threadManagementLock[]
    debug(
          "Starting directory search",
          dir = arg.dir,
          threadInd = arg.ind,
          availableThreadInds = arg.availableThreadInds[]
         )
    release arg.threadManagementLock[]



method makeAvailableLog(arg: ThreadArgRoot; extraArgs: ExtraArgRoot) {. base .} = discard
method makeAvailableLog(arg: ThreadArgRoot; extraArgs: ExtraArgMinimal) =
    procCall makeAvailableLog(ThreadArgRoot(arg), ExtraArgRoot(extraArgs))
    debug(
          "Finished searching directory",
          dir = arg.dir,
          addedAnything = not extraArgs.firstAdd,
          threadInd = arg.ind,
          availableThreadInds = arg.availableThreadInds[],
         )

method makeAvailableLog(arg: ThreadArgStats; extraArgs: ExtraArgStats) =
    procCall makeAvailableLog(ThreadArgRoot(arg), ExtraArgRoot(extraArgs))

    let cpuDelta: float = max(extraArgs.endCpuTime - extraArgs.startCpuTime, 0.0)
    debug(
          "Finished searching directory",
          dir = arg.dir,
          cpuSeconds = cpuDelta,
          numAddedExclusions = extraArgs.exclusionCount,
          threadInd = arg.ind,
          availableThreadInds = arg.availableThreadInds[],
         )

    arg.stats[].cpuSeconds += cpuDelta
    arg.stats[].exclusionCount += extraArgs.exclusionCount


proc makeAvailable(arg: ThreadArgRoot; extraArgs: ExtraArgRoot) =

    proc destructor =
        acquire arg.threadManagementLock[]
        arg.availableThreadInds[].add(arg.ind)
        makeAvailableLog(arg, extraArgs)
        broadcast arg.threadManagementCond[]
        release arg.threadManagementLock[]

    onThreadDestruction(destructor)



method initExtraArgs(_: ThreadArgRoot): ExtraArgRoot {. base .} =
    ExtraArgMinimal(firstAdd: true)

method initExtraArgs(_: ThreadArgStats): ExtraArgRoot =
    ExtraArgStats(
                  startCpuTime: 0.0,
                  endCpuTime: 0.0,
                  exclusionCount: 0,
                 )


method searchStart(_: var ExtraArgRoot) {. base .} = discard
method searchStart(extraArgs: var ExtraArgStats) =
    procCall searchStart(ExtraArgRoot(extraArgs))
    extraArgs.startCpuTime = cpuTime()


method addToStream(strm: OutputStream; extraArgs: var ExtraArgRoot; path: string) {. base .} =
    strm.write(path)
method addToStream(strm: OutputStream; extraArgs: var ExtraArgMinimal; path: string) =
    if extraArgs.firstAdd:
        extraArgs.firstAdd = false
    else
        strm.write("\n")

    procCall addToStream(strm, ExtraArgRoot(extraArgs), path)

method addToStream(strm: OutputStream; extraArgs: var ExtraArgStats; path: string) =
    if extraArgs.exclusionCount > 0:
        strm.write("\n")
    extraArgs.exclusionCount += 1

    procCall addToStream(strm, ExtraArgRoot(extraArgs), path)


method searchEnd(_: var ExtraArgRoot) {. base .} = discard
method searchEnd(extraArgs: var ExtraArgStats) =
    procCall searchEnd(ExtraArgRoot(extraArgs))
    extraArgs.endCpuTime = cpuTime()






proc searchDirectory(arg: ThreadArgRoot) {. thread .} =

    threadStart(arg)

    var extraArgs: ExtraArgRoot = initExtraArgs(arg)

    makeAvailable(arg, extraArgs)



    searchStart(extraArgs)

    if not dirExists(arg.dir):
        raise newException(OSError, &"'{arg.dir}' may be nonexistent/inaccessible")


    proc addPath(path: string) =
        acquire arg.streamLock[]
        addToStream(arg.stream, extraArgs, path)
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

    searchEnd(extraArgs)








method initThreadArg(
                     ind: uint;
                     dir: string;
                     availableThreadInds: ptr seq[uint];
                     stream: OutputStream;
                     streamLock: ptr Lock;
                     threadManagementLock: ptr Lock;
                     threadManagementCond: ptr Cond;
                     returnObj: ReturnRoot
                    ): ThreadArgRoot {. base .} =
    ThreadArgRoot(
                  ind: ind,
                  dir: dir,
                  availableThreadInds: availableThreadInds,
                  stream: stream,
                  streamLock: streamLock,
                  threadManagementLock: threadManagementLock,
                  threadManagementCond: threadManagementCond,
                 )

method initThreadArg(
                     ind: uint;
                     dir: string;
                     availableThreadInds: ptr seq[uint];
                     stream: OutputStream;
                     streamLock: ptr Lock;
                     threadManagementLock: ptr Lock;
                     threadManagementCond: ptr Cond;
                     returnObj: ReturnStats
                    ): ThreadArgRoot =
    ThreadArgStats(
                   ind: ind,
                   dir: dir,
                   availableThreadInds: availableThreadInds,
                   stream: stream,
                   streamLock: streamLock,
                   threadManagementLock: threadManagementLock,
                   threadManagementCond: threadManagementCond,
                   stats: addr returnObj.stats,
                 )

method zeroResults(returnObj: var ReturnRoot) {. base .}
method zeroResults(returnObj: var ReturnStats) {. base .} =
    returnObj = ReturnStats(stats: SearchStats(cpuSeconds: 0.0, exclusionCount: 0))



proc internalExclusionsProc(stream: OutputStream; baseDirs: openarray[string], returnObj: var ReturnRoot) = 

    if baseDirs.len == 0:
        zeroResults(returnObj)
        return

    let nThreads: uint = min(cast[uint](baseDirs.len), max(cast[uint](countProcessors()), 1'u))
    var availableThreadInds: seq[uint] = toSeq(0'u ..< nThreads)

    block:
        var
            threads: seq[Thread[ThreadArgRoot]] = newSeq[Thread[ThreadArgRoot]](nThreads)
            streamLock: Lock
            threadManagementLock: Lock
            threadManagementCond: Cond

        initLock streamLock
        initLock threadManagementLock
        initCond threadManagementCond


        for i in 0'u ..< cast[uint](baseDirs.len):

            acquire threadManagementLock
            while availableThreadInds.len == 0:
                threadManagementCond.wait(threadManagementLock)

            # Use an available thread
            let threadInd: uint = availableThreadInds.pop
            release threadManagementLock

            let arg = initThreadArg(
                                    ind = threadInd,
                                    dir = baseDirs[i],
                                    availableThreadInds = addr availableThreadInds,
                                    stream = stream,
                                    streamLock = addr streamLock,
                                    threadManagementLock = addr threadManagementLock,
                                    threadManagementCond = addr threadManagementCond,
                                    returnObj = stats,
                                   )
            createThread(threads[threadInd], searchDirectory, arg)


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
          nThreads,
          availableThreadIndsLen = availableThreadInds.len,
          availableThreadInds,
         )



proc exclusions*(stream: OutputStream; baseDirs: openarray[string]) = 

    var returnObj: ReturnRoot
    internalExclusionsProc(stream, baseDirs, returnObj)


proc exclusionsWStats*(stream: OutputStream; baseDirs: openarray[string]): SearchStats = 

    var returnObj: ReturnStats
    internalExclusionsProc(stream, baseDirs, returnObj)
    return returnObj.stats
