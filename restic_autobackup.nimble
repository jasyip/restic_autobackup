mode = ScriptMode.Verbose

version = "0.2.0"
author = "Jason Yip"
description = "Passes only the necessary file paths to backup for restic"
license = "GPL-2.0"
bin = @["backup"]
srcDir = "src"
binDir = "bin"
skipDirs = @["tests"]




requires "regex >= 0.19.0"
requires "argparse >= 3.0.0"
requires "chronicles >= 0.10.2"
when not defined(release):
    requires "unittest2 >= 0.0.4"
