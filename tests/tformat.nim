


# import einheit
import std/unittest

from std/os import normalizePathEnd
from std/sets import OrderedSet, toOrderedSet, initOrderedSet, `==`, incl
from std/streams import newStringStream, StringStream
from std/strutils import dedent
from std/sugar import collect, `->`

from private/format import formatFloat, formatMonoTime



proc checkValid(formatter: (float) -> string; input: float; expected: string) =
    check formatter(input) == expected


suite "test valid CPU Time printing":

    test "as-is values w/o exponent":
        checkValid(formatFloat, 1.0000, "1.0000")
        checkValid(formatFloat, 9999.9, "9999.9")
        checkValid(formatFloat, 0.90000, "0.90000")
        checkValid(formatFloat, 0.99999, "0.99999")
        checkValid(formatFloat, 0.00010, "0.00010")
        checkValid(formatFloat, 0.00001, "0.00001")

    test "edge-case values w/o exponent":
        checkValid(formatFloat, 0.000004, "0.00000")
        checkValid(formatFloat, 0.000005, "0.00001")
