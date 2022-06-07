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

This must be done with root privileges, the nature of this program is meant to be a system administrator utility.
Only backing up your `$HOME` using with this program would defeat the purpose.

Either `git clone https://github.com/jasyip/restic_autobackup.git && cd restic_autobackup` or download and unzip/extract a release in a system-wide location.

Install [**Nimble**](https://nim-lang.org/install.html) in a system-wide location.

To ensure it is installed in a system-wide location, I recommend writing
```sh
export NIMBLE_DIR='/opt/nimble'
```
to `/etc/profile.d/nimble.sh`, as it defaults to inside your `$HOME`.

```sh
nimble install
```

while in the cloned git repository/release.



## Configuration

**TODO**

