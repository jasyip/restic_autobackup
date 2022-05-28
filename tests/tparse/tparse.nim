


import unittest2

from std/os import normalizePathEnd
from std/sets import HashSet, toHashSet, initHashSet, items, `==`, incl
from std/streams import newStringStream, StringStream
from std/strutils import dedent
from std/sugar import collect

from ../../src/private/parse import parseConfig






type TestCase = tuple[
                      name: string,
                      content: string,
                      baseDirs: seq[string],
                      resticOptions: seq[string],
                     ]
type TestResult = tuple[
                        input: TestCase,
                        baseDirs: seq[string],
                        resticOptions: seq[string],
                       ]




proc hashBaseDirs(baseDirs: openarray[string]): HashSet[string] =
    collect(initHashSet()):
        for baseDir in baseDirs:
            {baseDir.normalizePathEnd}




let data = collect(initHashSet()):
    for param in [
                  (
                   "simple valid",
                   """
                   [Directories to Filter Caches]

                   /opt/
                   /home/

                   [Restic Options]

                   --exclude-caches
                   --exclude-file="backup_exclude"
                   --files-from="backup_include"

                   """,
                   @["/opt", "/home",],
                   @[
                    "--exclude-caches",
                    "--exclude-file", "backup_exclude",
                    "--files-from", "backup_include",
                   ],
                  ),

                  (
                   "weird options but valid",
                   """
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
                   @["/opt", "/home",],
                   @[
                    "a", "-b", "--c", "d", "e", "--f", "g",
                   ],
                  ),
                 ]:
        {cast[TestCase](param)}


proc process(input: TestCase): TestResult =

    let (name, content, _, _) = input
    var stream: StringStream = newStringStream(content.dedent)
    let (baseDirsResults, resticOptionsResults) = parseConfig(stream, name)
    result.input = input
    result.baseDirs = baseDirsResults
    result.resticOptions = resticOptionsResults


proc `in`(caseResult: TestResult; caseInput: TestCase): bool =
    result = (
      caseResult.input.baseDirs.hashBaseDirs == caseInput.baseDirs.hashBaseDirs and
      caseResult.input.resticOptions.toHashSet == caseInput.resticOptions.toHashSet
    )





test "true positives":

    for input in data.items:
        let caseResult = process(input)
        check caseResult in input

