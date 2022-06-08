
import chronicles

logStream userFriendly[textblocks[NoTimestamps, stderr]]
publicLogScope:
    stream = userFriendly
