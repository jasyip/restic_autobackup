version = "1.0.0a"
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
requires "faststreams >= 0.3.0"

when not defined(release):
    requires "unittest2 >= 0.0.4"
    requires "nimarchive >= 0.5.4"
