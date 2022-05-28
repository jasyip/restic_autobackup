

from std/math import `^`
from std/strformat import `&`, formatValue
from std/strutils import parseInt
from std/times import Duration, inNanoseconds





const
    nanoDigits: uint = 9
    nano: uint64 = 10'u64 ^ cast[uint64](nanoDigits)




proc cpuTimePrint*(x: float; sigFigs = 5'u): string =

    onFailedAssert(msg):
        raise newException(ValueError, msg)

    doAssert(sigFigs > 0, "'sigFigs' must be positive")

    formatValue(result, x, &".{sigFigs - 1}g")


func monoTimePrint*(x: Duration; sigFigs = 5'u): string =

    onFailedAssert(msg):
        raise newException(ValueError, msg)

    doAssert(sigFigs > 0, "'sigFigs' must be positive")


    let nanoseconds: int64 = inNanoseconds(x)
    doAssert(nanoSeconds >= 0, "'x' must be a non-negative Duration")

    let asString: string = $nanoseconds
    let strLen: uint = cast[uint](asString.len)

    if strLen > sigFigs:

        let simpleNanoseconds: int = parseInt(asString[0 ..< sigFigs])
        let simpleSeconds: float = simpleNanoseconds /
                                   cast[int](
                                             10'u ^ (
                                                     nanoDigits +
                                                     sigFigs -
                                                     strLen
                                                    )
                                            )

        formatValue(result, simpleSeconds, &".{sigFigs - 1}g")

    else:

        let seconds: float = cast[int](nanoseconds) / cast[int](nano)

        formatValue(result, seconds, &".{sigFigs - 1}g")
