
from std/deques import initDeque, addLast, popLast, len, Deque
from std/os import parentDir, dirExists, walkDir, lastPathPart, pcDir, pcLinkToDir
from std/streams import write, FileStream
from std/strformat import `&`

from regex import re, contains




const cacheRegex = re"\b[cC]ache|CACHE\b"





proc addToStream(strm: FileStream; added: var uint; path: string) =
    if added > 0:
        strm.write("\0")

    added += 1

    strm.write(path)




proc getSpecialFiles*(strm: FileStream; baseDirs: openarray[string]): uint = 



    template addPath(path: string) = addToStream(strm, result, path)

    for baseDir in baseDirs:

        if not dirExists(baseDir):
            raise newException(OSError, &"'{baseDir}' could not be accessed")

    for baseDir in baseDirs:

        var stack: Deque[string] = initDeque[string]()
        stack.addLast(baseDir)

        while stack.len > 0:
            let curDir: string = stack.popLast()
            if not contains(curDir.lastPathPart, cacheRegex):
                # Keep traversing
                addPath curDir


                for kind, nextPath in walkDir(curDir):
                    if kind == pcDir:
                        stack.addLast(nextPath)
                    elif kind != pcLinkToDir:
                        addPath nextPath
