# Bashrc

### ⚠️ WARNING ⚠️

#### This bashrc is opinionated and not made for a wide audience. While it provides a handful of powerful utilities, it is highly recommended to read this document fully before use, especially the [Summary of dangerous features](#summary-of-dangerous-features) section. As an example, `rf` can run `sudo rm -rf --`, so please be careful. I do not provide any warranty for any damage this program may cause.

## Sections

* [Installation](#installation)
* [Configuration](#configuration)
* [Summary of dangerous features](#summary-of-dangerous-features)
* [Basic utilities](#basic-utilities)
* [File and directory management](#file-and-directory-management)
* [System and package management](#system-and-package-management)
* [Git and development](#git-and-development)
* [Networking and file transfer](#networking-and-file-transfer)
* [Session and media](#session-and-media)
* [Android ADB utilities](#android-adb-utilities)
* [Bashrc synchronization](#bashrc-synchronization)

## Installation

This bashrc is intended for Bash on GNU/Linux and Android with Termux.

To install this bashrc, I highly recommend backing up your existing configuration first. You can do this by running `mv ~/.bashrc ~/.bashrc.bak`.

After backing up your old file, copy the new `.bashrc` from this cloned repository to `~/.bashrc`. For the changes to take effect, open a new terminal or run `source ~/.bashrc` in your current session.

## Configuration

This bashrc is designed to be customized without modifying the main `.bashrc` file, which makes it easier to update in the future.

Your personal aliases, functions, and settings should be placed in the `~/.config/bashrc/` directory. Any file ending with a `.sh` extension inside this directory, including subdirectories, will be automatically loaded when you start a new interactive shell. For example, you can place custom aliases in `~/.config/bashrc/aliases.sh`. These files load before the main aliases and functions, so matching definitions later in `.bashrc` take precedence.

For environment variables that should be available outside interactive shells, use your login configuration, such as `~/.profile`.

On its first run, the bashrc will automatically create a configuration file at `~/.config/bashrc/config.sh` if it does not already exist. This file contains several key variables:

* `skip_deps_check`: Set this to `false` to enable startup checks for common dependencies. Defaults to `true`.
* `remote_server`: Defines the server address for the `push` and `pull` commands. The format must include a port, such as `user@hostname:22`.
* `remote_destination`: Specifies an existing directory on the remote server where uploaded files will be stored.

You can also set `ps1_color`, `ps1_color_error`, `ps1_color_root`, and `ps1_color_root_error` to customize the prompt's ANSI color codes. Run `rel` after editing configuration files.

The shell uses `umask 077`, so newly created files and directories are private to your user by default. Command history is stored in `~/.history` and appended after each command.

## Summary of dangerous features

Here is a non-exhaustive list of features you may want to be aware of before anything tragic happens.

* `rf <path>`: This forcefully and recursively deletes files and directories, using `sudo` when automatic sudo is enabled.
* `clean`: This script deletes numerous files and directories from your system, including package manager caches and temporary files. It could potentially remove data you intended to keep.
* `adbsync <folder>`: This command synchronizes a local folder from an Android device. It will delete any files in the local destination directory that do not exist on the source device.
* `own [path...]`: This command recursively changes ownership, using `sudo` when available. Running this on system directories will likely break your system.
* `ren <pattern> <replacement> -r`: This batch rename command, especially with the recursive `-r` flag, can incorrectly rename thousands of files if the pattern is poorly constructed. It can also overwrite data if multiple files are renamed to have the same filename.
* `g`: This interactive git helper has destructive options. The `d` option resets hard to the previous commit, and the `P` option force-pushes.
* Automatic `sudo`: Many system management commands like `pacman`, `apt`, `mount`, and `passwd` can be automatically prefixed with `sudo`.
* `reboot` and `shutdown`: These aliases immediately restart or shut down the system. Unsaved work could be lost.

## Basic utilities

This table lists simple aliases and functions for common, everyday commands.

| Command | Description |
| --- | --- |
| `..`, `...`, etc. | Navigates up the directory tree, up to eight levels. |
| `c` | Clears the terminal screen. |
| `n` | Opens the nano text editor. |
| `rel` | Reloads the `~/.bashrc` file in the current shell. |
| `brc` | Opens `~/.bashrc` in nano and reloads it upon closing. |
| `ca <expression>` | A command-line calculator. Example: `ca 10 / 3`. |
| `clip` | Copies piped input to the clipboard using OSC 52, if supported by the terminal. |

## File and directory management

These are tools for creating, deleting, viewing, and modifying files and directories. This section covers simple shortcuts in a table, followed by batch renaming.

| Command | Description |
| --- | --- |
| `ls`, `l`, `sl` | Lists files by extension, with directories first and automatic colors. |
| `la` | Lists files, including hidden ones, except `.` and `..`. |
| `ll` | Provides a long listing format, including hidden files. |
| `md <name>` | Creates a new directory. |
| `mp <path>` | Creates a directory and any necessary parent directories. |
| `rf <path>` | Forcefully and recursively deletes files and directories, using automatic `sudo`. |
| `rd <path>` | Deletes files or empty directories, using automatic `sudo`. |
| `pwd [path]` | Resolves a file or directory to an absolute path, following symlinks. Defaults to the current directory. |
| `sz [path...]` | Displays apparent sizes of files and directories. |
| `own [path...]` | Recursively changes ownership to the current user and same-named group. Defaults to the current directory. |
| `w [file...]` | Makes files executable. Defaults to `*.sh` and `*.exe`; `w all` targets all non-hidden entries. |
| `catw <file>` | Displays file content, word-wrapped to the terminal width. |

### Batch renaming: ren

The `ren <pattern> <replacement> [-r]` command is a powerful utility for renaming multiple files and directories at once.

It uses extended regular expressions through `sed` to replace text in paths. By default, it scans the current directory, excluding hidden paths. The `-r` flag includes subdirectories.

## System and package management

These commands are for system administration, monitoring, and maintenance.

Outside Android, selected commands use `sudo` automatically when it is installed and the current user is non-root and belongs to the `sudo` or `wheel` group. These include `pacman`, `apt`, `dnf`, `docker`, `mount`, `useradd`, and `gparted`.

| Command | Description |
| --- | --- |
| `reboot` | Reboots the system and exits the current shell. |
| `shutdown` | Shuts down the system immediately and exits the shell. |
| `disk` | Shows usage and free space for ext4 and btrfs filesystems, or `/sdcard` on Android. |

### System cleaning: clean

The `clean` command removes caches, temporary files, selected logs and histories, empties Trash, removes unused packages, and vacuums the systemd journal. I highly recommend previewing its selections with `clean -n` before using it.

A JSON configuration is required. Set `clean_config='{}'` in `~/.config/bashrc/config.sh` and run `rel` for public rules only. The script requires Python 3.8+ on Linux and downloads automatically if missing.

Use `-v` for details, `-d` to also prune unused Docker data without volumes, and `-p` to remove generated artifacts from inactive projects in configured locations. `--age DAYS` overrides age-controlled thresholds except journald; unconditional cleanup is unchanged. See `clean --help` for all options.

### Smart package installer: i

The `i [package...]` function is a smart package installer that acts as a wrapper for `pacman` and `apt`. It can suggest correctly named packages if a given package name is not found. For example, on an Arch-based system, `i rg` can suggest installing the `ripgrep` package.

Run without arguments to update packages using `yay`, `pacman`, or `apt`. `i -f` or `i --force` automatically answers yes to update prompts. On pacman systems, `_syncdb` refreshes the command-to-package lookup database.

## Git and development

These are tools to assist with version control and general coding tasks.

| Alias | Description |
| --- | --- |
| `cdiff`, `wdiff`, `ldiff` | Compare two files using git's diff engine (character, word, or line). |
| `cts` | Removes trailing whitespace from files in place using `sed`. |
| `venv` | A shortcut for `source .venv/bin/activate` to activate a Python virtual environment. |

### Git clone wrapper: clone

The `clone` command accepts an HTTP(S) URL, a `git@host:path` SSH URL, `user repo`, `user/repo`, or an existing local repository path. GitHub shortcuts use SSH. Clones default to `--depth 1`; an optional destination can follow a URL or GitHub source.

If the destination or supplied local directory already exists, it attempts `git pull`. For new clones, use `-d`/`--depth` (`0` for full history), `-b`/`--branch`, or `-c`/`--commit` (uses full history). `clone --help` shows the syntax.

### Interactive git helper: g (deprecated)

The `g` command launches an interactive, menu-driven helper for common git operations. It provides a simple text-based interface for initializing a repository, committing changes, pushing, pulling, amending commits, and more. Push and pull actions target `origin main`.

In an existing repository, an empty menu choice commits changes and pushes. You can also pass choices directly, such as `g cp` to commit and push.

### LLM context helpers: file2prompt and prompt2file

These two utilities are designed to streamline interaction with large language models (LLMs).

* `file2prompt [path...]` or `f2p`: Collects text files into named code blocks using a fixed exclusion list, not `.gitignore`. It defaults to the current directory. The result is copied when a supported clipboard tool is available and output is a terminal; otherwise it is printed. It attempts to mask secret-like values by default; `--no-hash` or `-nh` disables this.

* `prompt2file [file]` or `p2f`: Parses named code blocks from a text file and writes to their specified paths, creating missing parent directories for relative paths and prompting before overwriting existing files. With no input file, it opens `$EDITOR` for you to enter the text.

## Networking and file transfer

These utilities are for inspecting network information and transferring files to a remote server.

| Command | Description |
| --- | --- |
| `myip` | Displays local IPv4 addresses and the public IPv4 address. |
| `ports` | Shows listening ports and processes, highlighting non-private bindings in red. |

### Remote file transfer: push and pull

These functions enable simple file transfers between your local machine and a remote server. They require the `remote_server` and `remote_destination` variables to be set in your bashrc configuration.

* `push <file/dir...>`: Transfers files or directories to the configured remote server using `scp` and records their names for `pull`. It can also accept piped input, which is uploaded as `pipe.txt`.

* `pull [destination]`: Downloads the most recent set of uploaded files. The default destination is `/sdcard/Download/` when that directory exists, otherwise the current directory. Piped uploads are printed to standard output instead.

## Session and media

This section covers utilities for managing terminal sessions and media files.

### Screen session manager: s

The `s` command provides an interactive menu that lists all running `screen` sessions. It simplifies re-attaching to both attached and detached sessions by allowing you to select one from a numbered list, avoiding the need to manually type `screen -rd <pid>`.

### Media utilities

| Command | Description |
| --- | --- |
| `streaminfo <file>` | Displays technical information about the streams in a media file using `ffprobe`. |
| `burnsubs [options] <video> <subs> [output]` | Adds a selectable subtitle track using `ffmpeg`, without re-encoding video or audio. |

For `burnsubs`, the two input files can be given in either order; the file using less disk space is treated as subtitles. `-r` replaces existing subtitle tracks. `-l` and `-n` set the language and name of the first output subtitle track. Without an output path, it writes `<name>-subbed.<ext>` in the current directory.

## Android ADB utilities

These functions are designed to work with an Android device connected via the Android Debug Bridge (ADB).

### Folder synchronization: adbsync

The `adbsync <folder> [jobs]` command performs one-way synchronization from an Android device's `/sdcard/` directory to a local folder. It pulls files missing locally and deletes local files absent from the device. Existing local files are not checked for changes; use `adbcheck` to verify them.

The destination must be a relative path. The optional `jobs` argument controls parallel transfers and defaults to 4.

### File integrity check: adbcheck

The `adbcheck <folder>` command compares MD5 hashes of existing local files against their counterparts on a connected Android device. It deletes mismatched local files before attempting to download replacements. Use `adbsync` to fetch files missing locally.

## Bashrc synchronization

These functions synchronize public files with `ThomasBaruzier/bashrc` and private configuration with `ThomasBaruzier/bashrc-private` on GitHub over SSH.

| Command | Description |
| --- | --- |
| `ubrc` | Overwrites `~/.bashrc` and `~/.config/bashrc/clean.py` with public repository versions. |
| `pbrc` | Commits and pushes the public bashrc files. |
| `uconf` | Updates private configuration in `~/.config/bashrc/`. |
| `pconf` | Commits and pushes top-level `.sh` files in `~/.config/bashrc/`. |

Run `rel` after updating to load the changes into the current shell.
