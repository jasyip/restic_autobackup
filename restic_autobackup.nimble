version = "0.2.0"
author = "Jason Yip"
description = "Passes only the necessary file paths to backup for restic"
license = "GPL-2.0"
bin = @["backup"]
srcDir = "src"
binDir = "bin"




requires "regex"
requires "argparse"
requires "chronicles"
