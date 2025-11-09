# Bashrc

### ⚠️ WARNING ⚠️

#### This bashrc is opinionated and not made for a wide audience. While it provides a handful of powerful utilities, it is highly recommended to read this document fully before use, especially the [Summary of dangerous features](#summary-of-dangerous-features) section. As an example, I use `rf` for `sudo rm -rf --`, so please be careful. I do not provide any warranty for any damage this program may cause.

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

To install this bashrc, I highly recommend to first back up your existing configuration. You can do this by running `mv ~/.bashrc ~/.bashrc.bak`.

After backing up your old file, copy the new `.bashrc` from this cloned repository into your home directory. For the changes to take effect, you will need to reload your shell. You can either open a new terminal or run the command `source ~/.bashrc` in your current session.

## Configuration

This bashrc is designed to be customized without modifying the main `.bashrc` file, which makes it easier to update in the future.

Your personal aliases, functions, and settings should be placed in the `~/.config/bashrc/` directory. Any file ending with a `.sh` extension inside this directory will be automatically loaded when you start a new shell. For example, you can move your existing custom aliases into a new file like `~/.config/bashrc/aliases.sh`.

For environment variables that should be available to all programs, the standard practice is to define them in `~/.profile`, which is loaded once at login.

On its first run, the bashrc will automatically create a configuration file at `~/.config/bashrc/config.sh` if it does not already exist. This file contains several key variables:

* `skip_deps_check`: Set this to `true` to disable the automatic dependency check that runs when the shell starts.
* `remote_server`: Defines the server address for the `push` and `pull` commands. The format should be `user@hostname` or `user@hostname:port`.
* `remote_destination`: Specifies the absolute path on the remote server where files transferred with the `push` command will be stored.

## Summary of dangerous features

Here is a non exhaustive list of features you may want to be aware of before anything tragic happens.

* `rf <path>`: This is an alias for `sudo rm -rf --`. It will forcefully and recursively delete files and directories with root privileges.
* `clean`: This script deletes numerous files and directories from your system, including package manager caches and temporary files. It could potentially remove data you intended to keep.
* `adbsync <folder>`: This command synchronizes a local folder from an android device. It will delete any files in the local destination directory that do not exist on the source device.
* `own [path...]`: This command uses `sudo` to change the ownership of files. Running this on system directories will likely break your system.
* `ren <pattern> <replacement> -r`: This batch rename command, especially with the recursive `-r` flag, can incorrectly rename thousands of files if the pattern is poorly constructed. It can also overwrite data if multiple files are renamed to have the same filename.
* `g`: This interactive git helper has destructive options. The `d` option deletes the last commit, and the `P` option force-pushes.
* Automatic `sudo`: Many system management commands like `pacman`, `apt`, and `mount` are automatically prefixed with `sudo`.
* `reboot` and `shutdown`: These aliases immediately restart or shut down the system. Unsaved work could be lost.

## Basic utilities

This table lists simple aliases for common, everyday commands.

| Alias | Description |
| --- | --- |
| `..`, `...`, etc. | Navigates up the directory tree, up to nine levels. |
| `c` | Clears the terminal screen. |
| `n` | Opens the nano text editor. |
| `rel` | Reloads the `~/.bashrc` file in the current shell. |
| `brc` | Opens `~/.bashrc` in nano and reloads it upon closing. |
| `ca <expression>` | A command-line calculator. Example: `ca 10 / 3`. |
| `ascii` | Prints a reference table of ASCII characters. |

## File and directory management

These are tools for creating, deleting, viewing, and modifying files and directories. This section covers simple aliases in a table, followed by more detailed explanations of advanced utilities.

| Alias | Description |
| --- | --- |
| `ls`, `l`, `sl` | A customized `ls` that sorts by time with directories first. |
| `la` | Lists all files, including hidden ones. |
| `ll` | Provides a long listing format for all files. |
| `md <name>` | Creates a new directory. |
| `mp <path>` | Creates a directory and any necessary parent directories. |
| `rf <path>` | Forcefully and recursively deletes files with `sudo` (be careful!).  |
| `rd <path>` | Deletes empty directories with `sudo`. |
| `pwd [path]` | Prints the full, absolute path of a file or directory. |
| `sz [path...]` | Displays the total size of specified files or directories. |
| `own [path...]` | Changes the ownership of files to the current user. |
| `w [file...]` | Makes files executable. `w all` targets all files. |
| `catw <file>` | Displays file content, word-wrapped to the terminal width. |

### Intelligent runner: r (deprecated)

The `r [file]` command is a shortcut to execute files.

When run without an argument, it re-runs the last file that was executed. If a file path is provided, it runs that new file and remembers it for the next time `r` is called. The command uses an intelligent helper that automatically determines how to handle the file. It can run shell and python scripts, compile and run C files, execute binaries, and extract a wide variety of archive formats.

### Batch renaming: ren

The `ren <pattern> <replacement> [-r]` command is a powerful utility for renaming multiple files at once.

It uses `sed` for pattern matching, allowing you to use regular expressions to find and replace parts of filenames. The `-r` flag enables recursive operation, applying the renaming logic to all files in all subdirectories.

## System and package management

These commands are for system administration, monitoring, and maintenance.

Many common administrative commands such as `pacman`, `apt`, `mount`, `useradd`, and `gparted` are automatically prefixed with `sudo` to simplify system management.

| Command | Description |
| --- | --- |
| `reboot` | Reboots the system and exits the current shell. |
| `shutdown` | Shuts down the system immediately and exits the shell. |
| `disk` | Displays a summary of disk space usage. |

### System cleaning: clean

The `clean` command is an opinionated script that frees up disk space. I highly recommend you to look what files it is about to delete before using this feature, some of them may be important to you. It performs several actions, including removing temporary files, clearing package manager caches for `pacman`, `apt`, `yay`, and `flatpak`, uninstalling orphaned packages, and vacuuming systemd journal logs to a smaller size.

### Smart package installer: i

The `i [package...]` function is a smart package installer that acts as a wrapper for `pacman` and `apt`. Its main feature is its ability to suggest correctly named packages if a given package name is not found. For example, on an Arch-based system, `i rg` will suggest installing the `ripgrep` package. If run without any arguments, it updates all system packages.

## Git and development

These are tools to assist with version control, compiling, debugging, and general coding tasks.

| Alias | Description |
| --- | --- |
| `cdiff`, `wdiff`, `ldiff` | Compare two files using git's diff engine (character, word, or line). |
| `mk` | A build shortcut that runs `make fclean`, `make -j`, and `make clean`. |
| `b` | Builds a project with `mk` and then runs the first binary it finds. |
| `val` | Builds with `mk` and runs the first binary under `valgrind`. |
| `snm [binary...]` | Shows dynamic library dependencies for one or more executables. |
| `cts` | An alias to a `sed` command that removes trailing whitespace from files. |
| `venv` | A shortcut for `source .venv/bin/activate` to activate a python venv. |

### Git clone wrapper: clone

The `clone <url | user repo> [options]` command is a wrapper for `git clone` that defaults to a shallow clone (`--depth 1`) for faster downloads. It supports a simplified syntax for GitHub repositories, such as `clone user repo`. If the destination directory already exists, it will attempt to run `git pull` to get updates instead of failing.

### Interactive git helper: g

The `g` command launches an interactive, menu-driven helper for performing the most common git operations. It provides a simple text-based interface for initializing a repository, committing changes, pushing, pulling, amending commits, and more, which is useful when you don't want to remember the specific git commands.

### LLM context helpers: file2prompt and prompt2file

These two utilities are designed to streamline interaction with large language models (LLMs).

* `file2prompt` or `f2p`: This command scans specified paths for text-based files, concatenates their contents into a single formatted block, and copies the result to the clipboard. This makes it easy to provide code and other context to an LLM.

* `prompt2file` or `p2f`: This is the inverse of `file2prompt`. It parses a text file (such as a response from an LLM) that contains code blocks with filenames, and it automatically creates the specified files and directory structures on your filesystem.

## Networking and file transfer

These utilities are for inspecting network information and transferring files to a remote server.

| Command | Description |
| --- | --- |
| `myip` | Displays your local private IP address and your public IP address. |
| `ports` | Lists all currently listening network ports on the system. |

### Remote file transfer: push and pull

These functions enable simple file transfers between your local machine and a remote server. They require the `remote_server` and `remote_destination` variables to be set in your bashrc configuration.

* `push <file/dir...>`: This command transfers one or more files or directories to the pre-configured remote server using `scp`. It can also accept piped input, allowing you to send the output of another command directly to a remote file.

* `pull [destination]`: This command downloads the most recent set of files that were uploaded using the `push` command. Files are saved to the specified local destination directory, or to the current directory by default.

## Session and media

This section covers utilities for managing terminal sessions and media files.

### Screen session manager: s

The `s` command provides an interactive menu that lists all running `screen` sessions. It simplifies re-attaching to both attached and detached sessions by allowing you to select one from a numbered list, avoiding the need to manually type `screen -rd <pid>`.

### Media and torrent utilities

| Command | Description |
| --- | --- |
| `addtrackers <magnet>` | Appends an up-to-date list of public trackers to a torrent magnet link. |
| `streaminfo <file>` | Displays technical information about the streams in a media file. |
| `burnsubs <video> <subs>` | A wrapper for `ffmpeg` that embeds a subtitle file into a video file. |

## Android ADB utilities

These functions are designed to work with an android device connected via the android debug bridge (ADB).

### Folder synchronization: adbsync

The `adbsync <folder>` command performs an efficient, one-way synchronization from an android device's `/sdcard/` directory to a local folder. It pulls any new or modified files from the device and deletes any local files that no longer exist on the device, keeping the local folder an exact mirror of the source.

### File integrity check: adbcheck

The `adbcheck <folder>` command verifies the integrity of files in a local folder against their counterparts on a connected android device. It compares the md5 hashes of each file and automatically re-downloads any files from the device that are mismatched or corrupted, ensuring the local copy is not damaged.

## Bashrc synchronization

These functions manage the bashrc and its configuration by synchronizing them with a git repository.

| Command | Description |
| --- | --- |
| `ubrc` | Updates the local `~/.bashrc` by pulling from its git repository. |
| `pbrc` | Pushes the local `~/.bashrc` to its git repository. |
| `uconf` | Updates the private bashrc configuration from its own repository. |
| `pconf` | Pushes the private bashrc configuration to its repository. |
| `u` | A shortcut that runs both `ubrc` and `uconf` to update everything. |
