

from std/math import `^`
from std/strformat import `&`, formatValue
from std/strutils import parseInt
from std/times import Duration, inNanoseconds





const
    nanoDigits: uint = 9
    nano: uint64 = 10'u64 ^ cast[uint64](nanoDigits)
    defaultSigFigs: uint = 5



func formatFloat*(x: float, sigFigs: uint): string =
    formatValue(result, x, &".{sigFigs}g")




func formatMonoTime*(x: Duration; sigFigs = defaultSigFigs): string =


    let nanoseconds: int64 = inNanoseconds(x)
    doAssert(nanoSeconds >= 0, "'x' must be a non-negative Duration")

    let asString: string = $nanoseconds
    let strLen: uint = cast[uint](asString.len)

    if strLen > sigFigs:

        let simpleNanoseconds: int = parseInt(asString[0 ..< sigFigs])
        let simpleSeconds: float = (
                                    simpleNanoseconds /
                                    cast[int](
                                              10'u ^ (
                                                      nanoDigits +
                                                      sigFigs -
                                                      strLen
                                                     )
                                             )
                                   )

        formatFloat(simpleSeconds, sigFigs)

    else:

        let seconds: float = cast[int](nanoseconds) / cast[int](nano)

        formatFloat(seconds, sigFigs)
