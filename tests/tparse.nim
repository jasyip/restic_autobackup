



from std/os import normalizePathEnd
from std/sets import OrderedSet, toOrderedSet, initOrderedSet, `==`, incl
from std/streams import newStringStream, StringStream
from std/strutils import dedent
from std/sugar import collect

import unittest2

from private/parse import parseConfig










func normalizePaths(baseDirs: openarray[string]): OrderedSet[string] =
    collect(initOrderedSet):
        for baseDir in baseDirs:
            { baseDir.normalizePathEnd }


proc processValidInput(content: string; baseDirs, resticOptions: seq[string]) =

    var stream: StringStream = newStringStream(content.dedent)
    let parseOutput: tuple[
                           baseDirs: seq[string],
                           resticOptions: seq[string],
                          ] = parseConfig(stream)

    var
        expectedBaseDirs = baseDirs.normalizePaths
        actualBaseDirs = parseOutput.baseDirs.normalizePaths

    check(expectedBaseDirs == actualBaseDirs)

    var
        expectedResticOptions = resticOptions.toOrderedSet
        actualResticOptions = parseOutput.resticOptions.toOrderedSet

    check(expectedResticOptions == actualResticOptions)


proc processInvalidInput(content: string) =

    var stream: StringStream = newStringStream(content.dedent)
    expect (ValueError):
        discard parseConfig(stream)




suite "test valid configuration parsing":


    test "simple valid":

        processValidInput(
                          content = """
                                    [Directories to Filter Caches]

                                    /opt/
                                    /home/

                                    [Restic Options]

                                    --exclude-caches
                                    --exclude-file="backup_exclude"
                                    --files-from="backup_include"

                                    """,
                          baseDirs = @["/opt", "/home",],
                          resticOptions = @[
                                            "--exclude-caches",
                                            "--exclude-file", "backup_exclude",
                                            "--files-from", "backup_include",
                                           ],
                         )



    test "complex valid":

        processValidInput(
                          content = """
                                    [Directories to Filter Caches]

                                    /opt/
                                    /home/

                                    [Restic Options]

                                    a
                                    -b
                                    --c
                                    d=e
                                    --f=g

                                    """,
                          baseDirs = @["/opt", "/home",],
                          resticOptions = @["a", "-b", "--c", "d", "e", "--f", "g",],
                         )



suite "test invalid configuration parsing":


    test "key-value pairs in 'Directories to Filter Caches' section":

        processInvalidInput(
                            content = """
                                      [Directories to Filter Caches]

                                      /opt/
                                      /home/ = 3

                                      [Restic Options]

                                      --exclude-caches

                                      """
                           )

