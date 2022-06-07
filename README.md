# [restic_autobackup](https://github.com/jasyip/restic_autobackup.git)
*An executable to be called regularly to backup a good amount of flexible files through restic. Made with Nim.*

---

If you want to use [**restic**](https://restic.net/) to backup your system, you will stumble upon
the fact that you must provide specific paths to backup and you might not know what you want to backup and what shouldn't be backed up.

This program will call restic with options that would backup as much import host-independent data as possible.
It also excludes caches in certain directores you can specify, such as `/home` and `/opt` to save bandwidth.



## TOC

- [Installation](#installation)
- [Configuration](#configuration)

---


## Installation

Install Nimble, then run

```sh
nimble install
```

while in the cloned git repository/release.

Unfortunately, there will be some necessary tweaking to ensure that it is installed with root privileges. More guidance to come.


## Configuration

**TODO**

