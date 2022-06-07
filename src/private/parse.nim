

from std/parsecfg import
                         CfgParser, CfgEvent, 
                         next, open, close,
                         cfgEof, cfgSectionStart, cfgKeyValuePair, cfgOption, cfgError,
                         getLine, getColumn, getFilename
from std/streams import Stream, close, write
from std/strformat import `&`
from std/strutils import cmpIgnoreStyle

import chronicles





type CfgSections = enum
    csDirectories, csOptions, csUnrecognized




func cfgParserPosition(parser: CfgParser): string =
    (
     &"[{parser.getLine},{parser.getColumn}]" & " of " &
     &"'{parser.getFilename}'"
    )

func cfgDetails(event: CfgEvent; parser: CfgParser): string =
    (
      "key-value pair " &
     &"('{event.key}', '{event.value}')" & " at " &
     cfgParserPosition(parser)
    )


proc warnUnrecognizedCfg(event: CfgEvent; parser: CfgParser) =
    warn(
         "Ignoring key-value pair in configuration file",
         key = event.key,
         value = event.value,
         line = parser.getLine,
         column = parser.getColumn,
         filename = parser.getFilename,
        )

func badDirectoryCfg(event: CfgEvent; parser: CfgParser): string =
    &"{cfgDetails(event, parser)} not allowed as a directory to search"



proc parseConfig*(
                  cfgStream: Stream,
                  streamName = "",
                 ):
                 tuple[
                  baseDirs: seq[string],
                  resticOptions: seq[string],
                 ]

                 =

    var
        parser: CfgParser
        curSection: CfgSections = csUnrecognized

    open(parser, cfgStream, streamName)
    defer:
        parser.close()


    while true:

        onFailedAssert(msg):
            raise newException(ValueError, msg)

        let event: CfgEvent = next(parser)

        case event.kind
        of cfgEof: break

        of cfgSectionStart:

            curSection =
                if   cmpIgnoreStyle(event.section, "Directories to Filter Caches") == 0:
                    csDirectories
                elif cmpIgnoreStyle(event.section, "Restic Options") == 0:
                    csOptions
                else:
                    csUnrecognized

        of cfgKeyValuePair:

            case curSection
            of csDirectories:
                doAssert(event.value == "", badDirectoryCfg(event, parser))
                result.baseDirs.add(event.key)
            of csOptions:
                result.resticOptions.add(event.key)
                if event.value != "": result.resticOptions.add(event.value)
            of csUnrecognized:
                warnUnrecognizedCfg(event, parser)

        of cfgOption:

            case curSection
            of csDirectories:
                raiseAssert badDirectoryCfg(event, parser)
            of csOptions:
                result.resticOptions.add(&"--{event.key}")
                if event.value != "": result.resticOptions.add(event.value)
            of csUnrecognized:
                warnUnrecognizedCfg(event, parser)


        of cfgError:
            raiseAssert &"'{event.msg}' at {cfgParserPosition(parser)}"
