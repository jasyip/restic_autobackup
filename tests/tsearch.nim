



from std/os import normalizePathEnd, parentDir, `/`, createDir, removeDir
from std/sequtils import map
from std/sets import OrderedSet, toOrderedSet, initOrderedSet, `==`, incl
from std/sugar import collect, `=>`
from std/tempfiles import genTempPath

import unittest2
from nimarchive import extract
from faststreams/inputs import InputStream, memoryInput, read
from faststreams/outputs import OutputStream, memoryOutput
from faststreams/buffers import PageBuffers
from faststreams/textio import readLine

from private/search import exclusions








template info: string = instantiationInfo(fullPaths = true).filename





func normalizePaths(baseDirs: openarray[string]): OrderedSet[string] =
    collect(initOrderedSet):
        for baseDir in baseDirs:
            { baseDir.normalizePathEnd }









suite "test cache location detection":


    let testingPath: string = genTempPath("", "")
    createDir(testingPath)
    defer:
        removeDir(testingPath)

    extract(info.parentDir / "test_data" / "tsearch.tar", testingPath)

    proc processInput(baseDirs: openarray[string], expectedExclusions: openarray[string]) =

        var actualPaths: OrderedSet[string]

        block streams:
            var outputStream: OutputStream = memoryOutput()
            defer:
                outputStream.close()

            let count: uint = exclusions(outputStream, baseDirs.map((dir) => testingPath / dir))

            check count == expectedExclusions.len

            var inputStream: InputStream = memoryInput(outputStream.buffers)
            defer:
                inputStream.close()

            while not inputStream.buffers.eofReached:
                actualPaths.incl(inputStream.readLine.normalizePathEnd)

        let expectedPaths: OrderedSet[string] = expectedExclusions.toOrderedSet

        check actualPaths == expectedPaths



    test "A":
        processInput()


