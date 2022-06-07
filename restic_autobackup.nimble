mode = ScriptMode.Verbose

version = "0.2.0"
author = "Jason Yip"
description = "Passes only the necessary file paths to backup for restic"
license = "GPL-2.0"
bin = @["backup"]
srcDir = "src"
binDir = "bin"
skipDirs = @["tests"]




requires "regex"
requires "argparse"
requires "chronicles"
when not defined(release):
    requires "unittest2"
