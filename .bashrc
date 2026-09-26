#
# ~/.bashrc
#

##########
# BASICS #
##########

# if running non interactively
[[ "$-" == *i* ]] || return

# beam cursor
printf '\e[6 q'

# strict security
umask 077

# zoxide
[ -f "$PREFIX/bin/zoxide" ] && alias cd='z' && eval "$(zoxide init bash)"

# status functions
unset -f error warn success info
error() { echo $'\033[31mERROR: '"$*"$'\033[0m' >&2; }
warn() { echo $'\033[33mWARNING: '"$*"$'\033[0m' >&2; }
success() { echo $'\033[32mSUCCESS: '"$*"$'\033[0m' >&2; }
info() { echo $'\033[34mINFO: '"$*"$'\033[0m' >&2; }

##################
# IDENTIFICATION #
##################

# platform
USER=$(command id -un)
IFS=' ' read -r ARCH PLATFORM < <(command uname -mo)
export USER PLATFORM ARCH

# device
DEVICE=desktop
if [[ "$PLATFORM" == Android ]]; then
  DEVICE=phone
elif command -v systemd-detect-virt >/dev/null 2>&1 &&
  command systemd-detect-virt --chroot --quiet 2>/dev/null; then
  DEVICE=chroot
else
  for _supply in /sys/class/power_supply/*; do
    [[ -r "$_supply/type" ]] || continue

    IFS= read -r _supply_type < "$_supply/type" || continue
    [[ "$_supply_type" == Battery ]] || continue

    _supply_scope=
    if [[ -r "$_supply/scope" ]]; then
      IFS= read -r _supply_scope < "$_supply/scope"
    fi
    [[ "$_supply_scope" == Device ]] && continue

    DEVICE=laptop
    break
  done
fi

export DEVICE
unset _supply _supply_type _supply_scope

# auto sudo
unset sudo
if [[ "$PLATFORM" != Android ]] &&
   (( EUID != 0 )) &&
   type -P sudo >/dev/null 2>&1; then
  case " $(command id -nG) " in
    *" sudo "*|*" wheel "*) sudo=sudo ;;
  esac
fi

##########
# CONFIG #
##########

# bashrc home
bashrc_home="$HOME/.config/bashrc"
[ -d "$bashrc_home" ] || mkdir -p "$bashrc_home"

# bashrc config
[ ! -f "$bashrc_home/config.sh" ] && \
echo $'#\n# config.sh\n#\n\nskip_deps_check=true\nremote_server=\nremote_destination=' \
  > "$bashrc_home/config.sh"
mapfile -t configs < <(find "$bashrc_home" -name "*.sh")
for config in "${configs[@]}"; do source "$config"; done

###########
# ALIASES #
###########

# path utilis
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'
alias ........='cd ../../../../../../..'
alias .........='cd ../../../../../../../..'

# basic aliases
alias c='clear'
alias n='nano'
alias md='mkdir --'
alias mp='mkdir -p --'
alias rf="$sudo rm -rf --"
alias rd="$sudo rm -d --"

# ls aliases
ls="ls --color=auto --group-directories-first -t -X"
alias la='ls -A --color=auto --group-directories-first -t -X'
alias ll='ls -la --color=auto --group-directories-first -t -X'
alias l="$ls"; alias ls="$ls"; alias sl="$ls"

# reload utils
alias brc='[ -f ~/.bashrc ] && nano ~/.bashrc && source ~/.bashrc'
alias rel='[ -f ~/.bashrc ] && source ~/.bashrc'

# diff utils
alias cdiff='git diff --no-index --word-diff --word-diff-regex=.'
alias wdiff='git diff --no-index --word-diff'
alias ldiff='git diff --no-index'

# auto sudo
[ "$DEVICE" != 'phone' ] && alias sudo='sudo -EH'
alias reboot="$sudo reboot && exit"
alias shutdown="$sudo shutdown now && exit"
alias pacman="$sudo pacman"
alias apt="$sudo apt"
alias dnf="$sudo dnf"
alias docker="$sudo docker"
alias mount="$sudo mount"
alias umount="$sudo umount"
alias fdisk="$sudo fdisk"
alias useradd="$sudo useradd"
alias userdel="$sudo userdel"
alias groupadd="$sudo groupadd"
alias groupdel="$sudo groupdel"
alias visudo="$sudo EDITOR=nano visudo"
alias passwd="$sudo passwd"
alias arch-chroot="$sudo arch-chroot"
alias gparted="$sudo gparted"
alias btop='$sudo btop --force-utf'

# basic functions
ca() { bc <<< "scale=5;$*"; }
catw() { cat "$1" | fold -sw "$COLUMNS"; }

###########
# EXPORTS #
###########

# general purpose
export EDITOR='nano'
export TERM='xterm'
export MAKEFLAGS="-j$(nproc)"
export GOPATH="$HOME/.cache/go"
export XDG_CONFIG_HOME="$HOME/.config"

# path
[ -d "$HOME/bin" ] && export PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
[ -d "/usr/sbin" ] && export PATH="$PATH:/usr/sbin"
[ -d "/usr/local/sbin" ] && export PATH="$PATH:/usr/local/sbin"
[ -d "/sbin" ] && export PATH="$PATH:/sbin"

##########
# COLORS #
##########

export \
LESS_TERMCAP_mb=$'\E[01;31m' \
LESS_TERMCAP_md=$'\E[01;38;5;74m' \
LESS_TERMCAP_me=$'\E[0m' \
LESS_TERMCAP_se=$'\E[0m' \
LESS_TERMCAP_so=$'\E[38;5;246m' \
LESS_TERMCAP_ue=$'\E[0m' \
LESS_TERMCAP_us=$'\E[04;38;5;146m' \
GTK_THEME='Adwaita:dark'
alias dir="dir --color=auto"
alias grep="grep --color=auto"
alias tree="tree -C"
alias dmesg='dmesg --color'

#######
# PS1 #
#######

# PS1 per-device colors
if [ -z "$ps1_color" ]; then
  if [ -n "$SSH_CLIENT" ]; then
    ps1_color='32'
  elif [ "$ARCH" = 'x86_64' ]; then
    [ "$DEVICE" = 'desktop' ] && ps1_color='36'
    [ "$DEVICE" = 'laptop' ] && ps1_color='32'
  elif [ "$ARCH" = 'aarch64' ]; then
    [ "$DEVICE" = 'desktop' ] && ps1_color='33'
    [ "$DEVICE" = 'phone' ] && ps1_color='32'
  fi
fi

# PS1 default colors
[ -z "$ps1_color" ] && ps1_color='32'
[ -z "$ps1_color_error" ] && ps1_color_error='35'
[ -z "$ps1_color_root" ] && ps1_color_root='31'
[ -z "$ps1_color_root_error" ] && ps1_color_root_error='35'

# PS1 format
getPS1() {
  if [ "$DEVICE" = 'chroot' ] && [ "$PLATFORM" = 'GNU/Linux' ]; then
    if [ "$EUID" = 0 ]; then   # chroot root
      PS1="\[\033[31m\]chroot\$([[ \$? != 0 ]] && echo \"\[\033[${ps1_color_root_error}m\]\" || echo \"\[\033[0m\]\"):\[\033[${ps1_color_root}m\]\w\[\033[0m\] "
    else                       # chroot user
      PS1="\[\033[34m\]chroot\$([[ \$? != 0 ]] && echo \"\[\033[${ps1_color_error}m\]\" || echo \"\[\033[0m\]\"):\[\033[${ps1_color}m\]\w\[\033[0m\] "
    fi
  elif [ -z "$SSH_CLIENT" ]; then
    if [ "$EUID" = 0 ]; then   # local root
      PS1="\$([[ \$? != 0 ]] && echo \"\[\033[${ps1_color_root_error}m\]\" || echo \"\[\033[${ps1_color_root}m\]\")\w\[\033[0m\] "
    else                       # local user
      PS1="\$([[ \$? != 0 ]] && echo \"\[\033[${ps1_color_error}m\]\" || echo \"\[\033[${ps1_color}m\]\")\w\[\033[0m\] "
    fi
  elif [ "$EUID" = 0 ]; then   # ssh root
    PS1="\[\033[31m\]\h\$([[ \$? != 0 ]] && echo \"\[\033[${ps1_color_root_error}m\]\" || echo \"\[\033[0m\]\"):\[\033[${ps1_color_root}m\]\w\[\033[0m\] "
  else                         # ssh user
    PS1="\[\033[34m\]\h\$([[ \$? != 0 ]] && echo \"\[\033[${ps1_color_error}m\]\" || echo \"\[\033[0m\]\"):\[\033[${ps1_color}m\]\w\[\033[0m\] "
  fi
}
getPS1

########
# SYNC #
########

# update bashrc
ubrc() {
  echo
  mkdir -p ~/.cache
  rm -rf ~/.cache/bashrc
  clone thomasbaruzier bashrc ~/.cache/bashrc

  if [ -s ~/.cache/bashrc/.bashrc ]; then
    mv ~/.cache/bashrc/.bashrc ~/.bashrc
    success 'The bashrc has been updated!'
  else
    error 'Failed to download the update'
  fi

  rm -rf ~/.cache/bashrc
  echo
}

# upload bashrc
pbrc() {
  echo
  local commit_name
  read -p 'Commit name: ' commit_name
  [ -z "$commit_name" ] && commit_name='other: automatic commit'
  echo

  mkdir -p ~/.cache
  rm -rf ~/.cache/bashrc
  clone thomasbaruzier bashrc ~/.cache/bashrc
  cp ~/.bashrc ~/.cache/bashrc/.bashrc
  git -C ~/.cache/bashrc add .bashrc
  git -C ~/.cache/bashrc commit -m "$commit_name"
  git -C ~/.cache/bashrc push

  if [ "$?" = 0 ]; then
    success 'The bashrc has been pushed!'
  else
    error 'Failed to push ~/.bashrc'
  fi

  rm -rf ~/.cache/bashrc
  echo
}

# update private config
uconf() {
  echo
  mkdir -p ~/.config/bashrc/
  [ ! -d ~/.config/bashrc/.git ] && rm -rf ~/.config/bashrc/
  clone 'git@github.com:ThomasBaruzier/bashrc-private.git' ~/.config/bashrc/

  if [ "$?" = 0 ]; then
    success 'Private bashrc config has been updated!'
  else
    error 'Failed to download the update'
  fi
  echo
}

# upload private conf
pconf() {
  echo
  local commit_name
  read -p 'Commit name: ' commit_name
  [ -z "$commit_name" ] && commit_name='other: automatic commit'
  echo

  mkdir -p ~/.config/bashrc/
  clone 'git@github.com:ThomasBaruzier/bashrc-private.git' ~/.config/bashrc/
  git -C ~/.config/bashrc add ~/.config/bashrc/*.sh
  git -C ~/.config/bashrc commit -m "$commit_name"
  git -C ~/.config/bashrc push

  if [ "$?" = 0 ]; then
    success 'The bashrc has been pushed!'
  else
    error 'Failed to push ~/.bashrc'
  fi
  echo
}

# update everything
u() {
  ubrc
  uconf
  [ -z "$sudo" ] && return
  sudo cp ~/.bashrc /root/
  sudo cp -r ~/.config/bashrc /root/.config/
}

# push files to remote
push() {
  push_pull_errors || return 1
  local files=() basenames=() x
  mkdir -p ~/.cache

  if [ -p /dev/stdin ]; then
    cat > ~/.cache/pipe.txt
    files+=("$(readlink -f ~/.cache/pipe.txt)")
    basenames+=("pipe.txt")
  elif [ -z "$1" ]; then
    echo "No input." && return 1
  else
    for i in "$@"; do
      [ ! -e "$i" ] && echo "Skipping '$i': invalid path." && return 1
      if [ -d "$i" ]; then
        read -p "Warning: '$i' is a directory. Continue? (y/n) " x
        [ "$x" != 'y' ] && return 1
      fi
      files+=("$(readlink -f "$i")")
    done
    mapfile -t files < <(printf '%s\n' "${files[@]}" | awk '!seen[$0]++')
    for i in "${files[@]}"; do
      basenames+=("$(basename "$i")")
    done
  fi

  printf '%s\n' "${basenames[@]}" > ~/.cache/latest-upload.txt
  scp -P "$remote_port" -r ~/.cache/latest-upload.txt \
    "${files[@]}" "$remote_address:$remote_destination"
  rm -f ~/.cache/latest-upload.txt
}

# pull files from remote
pull() {
  push_pull_errors || return 1
  local path=() files=() dest='.'
  local latest="$remote_destination/latest-upload.txt"

  [ -d '/sdcard/Download/' ] && dest='/sdcard/Download/'
  [ -n "$1" ] && dest="$1"
  mapfile -t files < <(ssh "$remote_address" -p "$remote_port" cat "$latest")
  [ -z "$files" ] && error "No recent uploads found." && return 1

  if [ "${files[0]}" = "pipe.txt" ]; then
    ssh "$remote_address" -p "$remote_port" cat "$remote_destination/pipe.txt"
  else
    for i in "${files[@]}"; do
      path+=("$remote_address:$remote_destination/$i")
    done
    scp -r -P "$remote_port" "${path[@]}" "$dest"
  fi
}

# handle errors
push_pull_errors() {
  if [ -z "$remote_server" ] || [ -z "$remote_destination" ]; then
    error 'No `remote_server`/`remote_destination` in '"'$bashrc_home/config.sh'"
    return 1
  fi

  remote_port="${remote_server##*:}"
  remote_address="${remote_server%:*}"
  return 0
}

############
# PACKAGES #
############

# helper for i()
update_packages() {
  if yay -V &>/dev/null; then
    rm -rf ~/.cache/yay/
    update_cmds=("yay -Syu --devel")
  elif pacman -V &>/dev/null; then
    update_cmds=("$sudo pacman -Syu")
  elif apt -v &>/dev/null; then
    update_cmds=("$sudo apt update" "$sudo apt upgrade")
  else
    echo "No supported package manager found (yay, pacman, apt)."
    return 1
  fi

  if [ "$1" == '-f' ] || [ "$1" == '--force' ]; then
    for cmd in "${update_cmds[@]}"; do yes | eval "$cmd"; done
  else
    for cmd in "${update_cmds[@]}"; do eval "$cmd"; done
  fi
  echo
}

# package installer
i() {
  # init
  unset packages
  local name good bad fixedPackages fixedNames
  if [ -z "$1" ] || [[ "$1" == '-f' || "$1" == '--force' ]]; then
    update_packages "$1"
    return
  fi

  # for pacman
  if pacman -V >/dev/null 2>&1; then
    local installer=pacman

    # determine packages status
    [ -f "$bashrc_home/pacman.db" ] || syncdb
    for package in "$@"; do
      if grep -qE "^$package(:|$)" < "$bashrc_home/pacman.db"; then
        # existing
        good+=("$package")
      else
        name=$(grep -E ":usr/bin/$package(:|$)" "$bashrc_home/pacman.db")
        name="${name%%:*}"
        if [[ -n "$name" && "$name" != "$package" ]]; then
          # fixable
          fixedPackages+=("$package")
          fixedNames+=("$name")
        else
          # non existing
          bad+=("$package")
        fi
      fi
    done

  # for apt
  elif apt -v >/dev/null 2>&1; then
    local installer=apt

    # determine packages status
    for package in "$@"; do
      if [[ -n $(apt-cache search --names-only "^$package\$") ]]; then
        # existing
        good+=("$package")
      else
        if [ "$DEVICE" = 'phone' ]; then
          search=$("$PREFIX"/libexec/termux/command-not-found "$package" 2>&1)
        else
          search=$(/usr/lib/command-not-found "$package" 2>&1)
        fi
        if [[ "$search" =~ 'not found, did you mean:'|'command not found' ]]; then
          # non existing
          bad+=("$package")
        elif [[ "$search" =~ 'not found, but can be installed with:'|'Install it by executing:' ]]; then
          # fixable
          fixedPackages+=("$package")
          fixedNames+=("$(grep -Po '(apt|pkg) install \K[^ ]+' <<< $search | head -n 1)")
        fi
      fi
    done

  fi

  if [[ -n "$fixedPackages" || -n "$bad" ]]; then

    # print results
    echo
    [ -n "$good" ] && echo -e "\e[1m\e[34m::\e[0m\e[1m Found\e[0m\n${good[@]}\n"
    [ -n "$bad" ] && echo -e "\e[1m\e[34m::\e[0m\e[1m Not found\e[0m\n${bad[@]}\n"

    # print fixable and prompt for action
    if [ -n "$fixedPackages" ]; then
      echo -e "\e[1m\e[34m::\e[0m\e[1m Fixable\e[0m"
      for ((i=0; i < "${#fixedPackages[@]}"; i++)); do
        echo "${fixedPackages[i]} -> ${fixedNames[i]}"
      done
      echo -e "\n\e[34m1.\e[0m Install found + fixable"
      echo -e "\e[34m2.\e[0m Install found"
      echo -e "\e[34m3.\e[0m Cancel\n"
      read -e -p "> Choice (default=1): " answer

      # build package list
      case "$answer" in
        3) echo && return;;
        2) packages=(${good[@]});;
        *) packages=(${good[@]} ${fixedNames[@]});;
      esac
    fi

  # build package list
  elif [ -n "$good" ]; then
    packages=(${good[@]})
  fi

  # install
  if [ -n "$packages" ]; then
    echo
    [ "$installer" = 'pacman' ] && $sudo pacman -Sy "${packages[@]}"
    [ "$installer" = 'apt' ] && $sudo apt update && $sudo apt install "${packages[@]}" --no-install-recommends --no-install-suggests
    echo
  fi
}

############# code for syncdb() #############
read -r -d '' code << "EOF"
#include <stdio.h>
#include <string.h>
#include <regex.h>

int main() {
  // variables
  FILE *file = fopen("$HOME/.cache/pacman.db.temp", "r");
  char line[1024*512];
  regex_t regex;
  int reti;

  // read the file line by line
  reti = regcomp(&regex, "^usr/bin/[[:alnum:]]+$", REG_EXTENDED);
  while (fgets(line, sizeof(line), file)) {
    line[strcspn(line, "\n")] = 0;

    // check if name match
    if (strstr(line, "%NAME%")) {
      fgets(line, sizeof(line), file);
      line[strcspn(line, "\n")] = 0;
      printf("\n%s", line);
    }

    // check if bin match
    reti = regexec(&regex, line, 0, NULL, 0);
    if (!reti) {
      printf(":%s", line);
    }
  }

  regfree(&regex);
  fclose(file);
  return 0;
}
EOF
################ end of code ################

# update db
syncdb() {
  if pacman -V >/dev/null 2>&1; then
    echo
    $sudo pacman -Fy
    mkdir -p ~/.config ~/.cache
    rm -f ~/.cache/pacman.db.temp
    local files=($(find /var/lib/pacman/sync/ -name *.files))

    # files extraction
    echo -e "\e[1m\e[34m::\e[0m\e[1m Extracting files...\e[0m"
    for file in "${files[@]}"; do
      echo " extracting $file"
      gzip -cd < "$file" >> ~/.cache/pacman.db.temp
    done

    # c code execution
    echo "$code" | sed "s:\$HOME:$HOME:g" > ~/.cache/extract.c
    gcc ~/.cache/extract.c -o ~/.cache/extract.exe
    ~/.cache/extract.exe | sort > "$bashrc_home/pacman.db"

    # finishing
    $sudo rm -rf ~/.cache/extract.exe ~/.cache/extract.c ~/.cache/pacman.db.temp
    local size=$(du -h "$bashrc_home/pacman.db" | awk '{print $1}')
    echo -e "\e[1m\e[34m::\e[0m\e[1m Done - $bashrc_home/pacman.db - $size\e[0m"
  else
    error 'Not using pacman'
    return 1
  fi
}

##########
# SYSTEM #
##########

# permission helper
own() {
  if [ -n "$1" ] && [ ! -e "$1" ]; then
    error 'Invalid path'
    return 1
  elif [ -z "$1" ]; then
    paths=(".")
  else
    paths=("$@")
  fi

  if [ "$sudo" = sudo ] || [ -x "$PREFIX/bin/sudo" ]; then
    sudo find "${paths[@]}" -exec chown "$USER:$USER" {} +
  else
    warn 'No root permissions. Trying anyways.'
    find "${paths[@]}" -exec chown "$USER:$USER" {} +
  fi
}

# chmod helper
w() {
  if [ -z "$1" ]; then
    chmod +x -- *.sh *.exe 2>/dev/null
  elif [ "$1" = 'all' ]; then
    chmod +x -- * 2>/dev/null
  else
    chmod +x -- "$@" 2>/dev/null
  fi
  ls
}

# get paths
pwd() {
  [ -z "$1" ] && local path='.' || local path="$1"
  [ ! -e "$path" ] && echo -e '\e[33mWARNING: Invalid path\e[0m'
  readlink -f "$path"
}

# get sizes
sz() {
  if [ -n "$2" ]; then
    $sudo du -bhsc -- "$@" | sort -h
  elif [ -n "$1" ]; then
    $sudo du -bhs -- "$@" | awk '{print $1}'
  else
    $sudo du -bhsc -- .[^.]* * 2>/dev/null | sort -h
  fi
}

clean() (
  command -v python3 >/dev/null 2>&1 || {
    printf 'clean requires python3\n' >&2
    return 1
  }

  command python3 - \
    "${DEVICE:-desktop}" "${sudo:-}" "${clean_config-}" "$@" <<'PY'
import argparse
import bisect
import collections
import errno
import fnmatch
import json
import os
import re
import selectors
import shlex
import shutil
import signal
import stat
import subprocess
import sys
import time
import traceback

# requirements
if sys.version_info < (3, 8):
  sys.exit("clean requires Python 3.8+")
if not all(hasattr(os, name) for name in ("O_PATH", "O_NOFOLLOW", "O_DIRECTORY")):
  sys.exit("clean requires Linux O_PATH and no-follow directory operations")
if not {os.open, os.stat, os.unlink, os.rmdir} <= os.supports_dir_fd:
  sys.exit("clean requires descriptor-relative filesystem operations")
if os.scandir not in os.supports_fd:
  sys.exit("clean requires descriptor-based directory enumeration")

try:
  import tomllib
except ImportError:
  tomllib = None

device, sudo, raw_config = sys.argv[1:4]

# cli args
def age_days(value):
  try:
    value = int(value)
  except ValueError:
    raise argparse.ArgumentTypeError("age must be a nonnegative integer")
  if value < 0:
    raise argparse.ArgumentTypeError("age must be a nonnegative integer")
  return value

parser = argparse.ArgumentParser(prog="clean")
parser.add_argument(
  "-d", "--docker", action="store_true",
  help="prune the selected Unix-socket Docker daemon; no volumes"
)
parser.add_argument(
  "-p", "--projects", action="store_true",
  help="clean inactive projects in configured locations"
)
parser.add_argument(
  "-n", "--dry-run", action="store_true",
  help="preview selections; implies verbose"
)
parser.add_argument(
  "-v", "--verbose", action="store_true",
  help="show scan, skip, remove and run actions"
)
parser.add_argument(
  "--age", type=age_days, metavar="DAYS",
  help="override age-controlled thresholds except journald; "
       "unconditional cleanup is unchanged"
)
age_settings = {
  "cache": (1, "user/application caches and editor logs"),
  "tmp": (1, "/tmp or Termux temporary files"),
  "var-tmp": (7, "/var/tmp files"),
  "log": (7, "rotated system and application logs"),
  "project": (30, "project inactivity; does not enable --projects")
}
for name, (default, description) in age_settings.items():
  parser.add_argument(
    "--" + name + "-age", type=age_days, metavar="DAYS",
    help=f"{description} (default: {default}; 0 disables age)"
  )
parser.add_argument(
  "--journal-age", type=age_days, default=7, metavar="DAYS",
  help="journal threshold (default: 7; minimum: 1); "
       "independent of --age, with a 50 MiB size cap"
)
args = parser.parse_args(sys.argv[4:])
args.verbose = args.verbose or args.dry_run
for name, (default, _) in age_settings.items():
  attribute = name.replace("-", "_") + "_age"
  if getattr(args, attribute) is None:
    setattr(args, attribute, args.age if args.age is not None else default)
args.journal_age = max(1, args.journal_age)

# runtime state
home = os.path.realpath(os.path.expanduser("~"))
priv = [sudo, "-n"] if sudo and os.geteuid() and device != "phone" else []
started = time.time()
cutoff = started - args.project_age * 86400
colored = sys.stdout.isatty() and "NO_COLOR" not in os.environ
errors = collections.Counter()
skips = collections.Counter()
reported = set()
file_bytes = 0
interrupted = aborted = incomplete = False

def within(path, root):
  return path == root or path.startswith(root.rstrip("/") + "/")

def overlaps(left, right):
  return within(left, right) or within(right, left)

def display(value):
  if value == home:
    return "~"
  return "~" + value[len(home):] if value.startswith(home + "/") else value

# output
def skip_category(reason):
  text = reason.lower()
  if "permission denied" in text:
    return "permission"
  if any(word in text for word in (
    "activity within", "no longer eligible", "changed", "disappeared"
  )):
    return "recent"
  if "currently in use" in text:
    return "active"
  if any(word in text for word in (
    "filesystem", "storage", "mount", "remote", "endpoint"
  )):
    return "storage"
  if "tracked" in text or "protected" in text:
    return "protected"
  if "not installed" in text or "daemon unavailable" in text:
    return "unavailable"
  return "metadata" if "metadata" in text else "unsupported"

def log(chip, action, value, reason="", category=None):
  value = str(value)
  if action == "SKIP":
    key = (chip, value, reason)
    if key in reported:
      return
    reported.add(key)
    skips[category or skip_category(reason)] += 1
  if action != "ERROR" and not args.verbose:
    return
  label = "WOULD " + action \
    if args.dry_run and action in ("RUN", "REMOVE") else action
  label = f"[{label}]"
  padded = f"{label:<14}"
  code = {
    "SCAN": 36, "SKIP": 34, "RUN": 32, "REMOVE": 31, "ERROR": 31
  }.get(action)
  if colored and code:
    padded = f"\033[{code}m{label}\033[0m" + " " * max(0, 14 - len(label))
  suffix = f" ({reason})" if reason else ""
  print(f"{'[' + chip + ']':<10} {padded} {display(value)}{suffix}", flush=True)

def failure(chip, value, reason, kind=None):
  if kind is None:
    number = getattr(reason, "errno", None)
    kind = "permission" if number in (errno.EACCES, errno.EPERM) \
      else "filesystem" if isinstance(reason, OSError) else "command"
  errors[kind] += 1
  lines = str(reason).strip().splitlines()
  log(chip, "ERROR", value, lines[0] if lines else "operation failed")
  for line in lines[1:13]:
    print(" " * 26 + line, flush=True)
  if len(lines) > 13:
    print(" " * 26 + f"... {len(lines) - 13} more diagnostic lines", flush=True)

def available(name):
  return shutil.which(name) is not None

# commands
class CommandError(Exception):
  def __init__(self, command, message):
    self.command = shlex.join(command)
    super().__init__(message)

def stop_owned(process):
  def signal_group(number):
    try:
      os.killpg(process.pid, number)
      return True
    except ProcessLookupError:
      return False
    except PermissionError as exc:
      if number:
        print(
          f"clean: cannot signal process group {process.pid}: {exc}",
          file=sys.stderr, flush=True
        )
      return True

  alive = True
  try:
    alive = signal_group(signal.SIGTERM)
    deadline = time.monotonic() + 3
    while alive:
      remaining = deadline - time.monotonic()
      if remaining <= 0:
        break
      time.sleep(min(0.1, remaining))
      alive = signal_group(0)
  finally:
    if alive:
      signal_group(signal.SIGKILL)
    try:
      process.wait(timeout=3)
    except subprocess.TimeoutExpired:
      print(
        f"clean: process {process.pid} has not exited after cancellation",
        file=sys.stderr, flush=True
      )

def capture(command, env=None, binary=False, input_text=None,
            timeout=30, limit=8 * 1024 * 1024, tail=False,
            on_stdout=None):
  process = None
  selector = selectors.DefaultSelector()
  buffers = {"out": bytearray(), "err": bytearray()}
  pending = memoryview(input_text.encode()) if input_text is not None else None
  offset = total = 0
  deadline = time.monotonic() + timeout if timeout is not None else None

  def deliver_stdout(final=False):
    buffer = buffers["out"]
    consumed = 0
    while True:
      end = buffer.find(b"\n", consumed)
      if end < 0:
        break
      if end - consumed > 1024 * 1024:
        raise CommandError(command, "worker record exceeded 1 MiB")
      on_stdout(bytes(buffer[consumed:end]))
      consumed = end + 1
    if consumed:
      del buffer[:consumed]
    if len(buffer) > 1024 * 1024:
      raise CommandError(command, "worker record exceeded 1 MiB")
    if final and buffer:
      on_stdout(bytes(buffer))
      buffer.clear()

  try:
    process = subprocess.Popen(
      command, cwd=home, env=env, start_new_session=True,
      stdin=subprocess.PIPE if pending is not None else subprocess.DEVNULL,
      stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    for stream, key in ((process.stdout, "out"), (process.stderr, "err")):
      os.set_blocking(stream.fileno(), False)
      selector.register(stream, selectors.EVENT_READ, key)
    if pending is not None:
      if len(pending):
        os.set_blocking(process.stdin.fileno(), False)
        selector.register(process.stdin, selectors.EVENT_WRITE, "in")
      else:
        process.stdin.close()

    while selector.get_map():
      remaining = None if deadline is None else deadline - time.monotonic()
      if remaining is not None and remaining <= 0:
        raise CommandError(command, f"query exceeded {timeout:g}s")
      for key, _ in selector.select(
        0.25 if remaining is None else min(0.25, remaining)
      ):
        stream, name = key.fileobj, key.data
        if name == "in":
          try:
            offset += os.write(stream.fileno(), pending[offset:offset + 65536])
          except BlockingIOError:
            continue
          except BrokenPipeError:
            offset = len(pending)
          if offset == len(pending):
            selector.unregister(stream)
            stream.close()
          continue

        try:
          block = os.read(stream.fileno(), 65536)
        except BlockingIOError:
          continue
        if not block:
          if name == "out" and on_stdout is not None:
            deliver_stdout(final=True)
          selector.unregister(stream)
          stream.close()
          continue
        if name == "out" and on_stdout is not None:
          buffers["out"].extend(block)
          deliver_stdout()
          continue

        total += len(block)
        buffers[name].extend(block)
        if tail:
          if len(buffers[name]) > limit:
            del buffers[name][:-limit]
        elif total > limit:
          raise CommandError(command, f"query output exceeded {limit} bytes")

    remaining = None if deadline is None else max(0, deadline - time.monotonic())
    try:
      status = process.wait(timeout=remaining)
    except subprocess.TimeoutExpired:
      raise CommandError(command, f"query exceeded {timeout:g}s")

    output, diagnostics = bytes(buffers["out"]), bytes(buffers["err"])
    if not binary:
      output = output.decode(errors="surrogateescape")
      diagnostics = diagnostics.decode(errors="surrogateescape")
    return subprocess.CompletedProcess(command, status, output, diagnostics)
  except OSError as exc:
    if process is not None:
      stop_owned(process)
    raise CommandError(command, str(exc)) from exc
  except BaseException:
    if process is not None:
      stop_owned(process)
    raise
  finally:
    selector.close()
    if process is not None:
      for stream in (process.stdin, process.stdout, process.stderr):
        if stream is not None and not stream.closed:
          stream.close()

def query(command, env=None, binary=False, timeout=30):
  return capture(command, env=env, binary=binary, timeout=timeout)

def checked(command, env=None):
  result = query(command, env)
  if result.returncode:
    raise CommandError(
      command, result.stderr.strip() or result.stdout.strip()
      or f"exit {result.returncode}"
    )
  return result.stdout.strip()

def run(chip, command, reason="", empty_screen=False):
  log(chip, "RUN", shlex.join(command), reason)
  if args.dry_run:
    return
  try:
    result = capture(command, timeout=None, limit=128 * 1024, tail=True)
    message = (result.stderr + result.stdout).strip()
    if result.returncode and not (
      empty_screen and "No Sockets found" in message
    ):
      failure(
        chip, shlex.join(command),
        f"exit {result.returncode}" + (f"\n{message}" if message else ""),
        "command"
      )
  except CommandError as exc:
    failure(chip, exc.command, exc, "command")

# paths
def setting(name, fallback):
  value = os.environ.get(name, "")
  return os.path.normpath(value if os.path.isabs(value) else fallback)

cache = setting("XDG_CACHE_HOME", home + "/.cache")
config = setting("XDG_CONFIG_HOME", home + "/.config")
data = setting("XDG_DATA_HOME", home + "/.local/share")
state = setting("XDG_STATE_HOME", home + "/.local/state")
cargo = setting("CARGO_HOME", home + "/.cargo")
rustup = setting("RUSTUP_HOME", home + "/.rustup")
gradle = setting("GRADLE_USER_HOME", home + "/.gradle")
bun = setting("BUN_INSTALL", home + "/.bun")
esp = setting("IDF_TOOLS_PATH", home + "/.espressif")
nvm = setting("NVM_DIR", config + "/nvm")
npm = setting("npm_config_cache", home + "/.npm")
uv_cache = setting("UV_CACHE_DIR", cache + "/uv")
docker_config = setting("DOCKER_CONFIG", home + "/.docker")
triton_cache = setting("TRITON_CACHE_DIR", home + "/.triton/cache")
cache_roots = sorted({cache, home + "/.cache"})
gopaths = [
  os.path.normpath(path)
  for path in os.environ.get("GOPATH", home + "/go").split(os.pathsep)
  if os.path.isabs(path)
]
gobin = os.environ.get("GOBIN", "")
gobin = os.path.normpath(gobin) if os.path.isabs(gobin) else ""
go_caches = []
mounts = {}
preserve = []
installations = []
base_cfg = {}
space = {}
space_failed = set()

def job(path, days=0, **options):
  return dict(path=os.path.abspath(path), days=days, **options)

def unique_jobs(jobs):
  result = {}
  for item in jobs:
    path = item["path"]
    if path in result and result[path] != item:
      raise ValueError(f"conflicting cleanup rules: {path}")
    result[path] = dict(item)
  return sorted(result.values(), key=lambda item: item["path"])

# policy
def parse_policy(text):
  if not text.strip():
    raise ValueError(
      "clean_config is missing or empty; load config.sh, "
      "or explicitly set clean_config='{}' for public rules only"
    )

  def pairs(items):
    result = {}
    for key, value in items:
      if key in result:
        raise ValueError(f"duplicate configuration key: {key}")
      result[key] = value
    return result

  def invalid_constant(value):
    raise ValueError(f"invalid JSON constant: {value}")

  def fields(value, allowed, label, required=()):
    if not isinstance(value, dict):
      raise ValueError(f"{label}: expected an object")
    unknown, missing = set(value) - set(allowed), set(required) - set(value)
    if unknown:
      raise ValueError(f"{label}: unknown fields: {', '.join(sorted(unknown))}")
    if missing:
      raise ValueError(f"{label}: missing fields: {', '.join(sorted(missing))}")

  def strings(value, label):
    if not isinstance(value, list) or any(
      not isinstance(item, str) for item in value
    ):
      raise ValueError(f"{label}: expected a list of strings")
    return value

  def relative(value):
    if not value or "\0" in value or os.path.isabs(value) \
        or ".." in value.split("/"):
      raise ValueError(f"invalid relative path: {value!r}")
    value = os.path.normpath(value)
    if value == ".":
      raise ValueError("paths must name a child, not the entire base")
    return value

  roots = {
    "home": home, "cache": cache, "config": config, "data": data, "state": state
  }

  def base(name):
    if not isinstance(name, str) or name not in roots:
      raise ValueError(f"unknown path base: {name!r}")
    return roots[name]

  policy = json.loads(
    text, object_pairs_hook=pairs, parse_constant=invalid_constant
  )
  fields(policy, ("projects", "preserve", "electron", "vscode", "rules"),
         "clean_config")

  project = policy.get("projects", {})
  fields(project, ("auto", "roots"), "projects")
  automatic = project.get("auto", False)
  if type(automatic) is not bool:
    raise ValueError("projects.auto must be true or false")
  project_roots = [
    os.path.join(home, relative(path))
    for path in strings(project.get("roots", []), "projects.roots")
  ]

  protected = []
  saved = policy.get("preserve", {})
  fields(saved, roots, "preserve")
  for name, paths in saved.items():
    parents = cache_roots if name == "cache" else [base(name)]
    for path in strings(paths, "preserve." + name):
      path = relative(path)
      protected.extend(os.path.join(parent, path) for parent in parents)

  jobs = []
  leaves = (
    "Cache", "Code Cache", "GPUCache", "CachedData",
    "CachedExtensionVSIXs", "DawnCache", "DawnWebGPUCache", "DawnGraphiteCache"
  )
  for recipe in ("electron", "vscode"):
    for app in strings(policy.get(recipe, []), recipe):
      if relative(app) != app or "/" in app:
        raise ValueError(f"{recipe}: expected an application directory name")
      selected = leaves + (("logs",) if recipe == "vscode" else ())
      jobs.extend(
        job(os.path.join(config, app, leaf), args.cache_age, directory_root=True)
        for leaf in selected
      )

  rules = policy.get("rules", [])
  if not isinstance(rules, list):
    raise ValueError("rules must be a list")
  required = ("base", "paths", "kind", "age")
  for index, rule in enumerate(rules, 1):
    label = f"rule {index}"
    fields(rule, required + ("glob", "regex"), label, required)
    parent = base(rule["base"])
    paths = strings(rule["paths"], label + ".paths")
    if not paths:
      raise ValueError(f"{label}: paths must not be empty")
    kind, age = rule["kind"], rule["age"]
    if kind not in ("contents", "files"):
      raise ValueError(f"{label}: kind must be contents or files")
    if type(age) is int and age == 0:
      days = 0
    elif isinstance(age, str) and age in ("cache", "log"):
      days = getattr(args, age + "_age")
    else:
      raise ValueError(f"{label}: age must be cache, log or numeric 0")

    options = {"directory_root": True}
    if age == "log":
      options["access"] = False
    selectors = set(rule) & {"glob", "regex"}
    if kind == "contents":
      if selectors:
        raise ValueError(f"{label}: contents cannot have a file selector")
    else:
      if len(selectors) != 1:
        raise ValueError(f"{label}: files requires exactly one glob or regex")
      selector = next(iter(selectors))
      value = rule[selector]
      if not isinstance(value, str) or not value or "\0" in value:
        raise ValueError(f"{label}: invalid filename selector")
      options.update(recursive=False, directories=False, links=False)
      if selector == "glob":
        if "/" in value:
          raise ValueError(f"{label}: glob must match a filename")
        options["patterns"] = [value]
      else:
        try:
          re.compile(value)
        except re.error as exc:
          raise ValueError(f"{label}: invalid regex: {exc}") from exc
        options["name_regex"] = value

    jobs.extend(
      job(os.path.join(parent, relative(path)), days, **options)
      for path in paths
    )

  return (
    list(dict.fromkeys(protected)), automatic,
    sorted(set(project_roots)), unique_jobs(jobs)
  )

try:
  private_preserve, project_auto, project_roots, private_jobs = \
    parse_policy(raw_config)
except ValueError as exc:
  sys.exit(f"clean: invalid configuration: {exc}")

# filesystem engine
shared = r'''
import errno
import fnmatch
import json
import os
import re
import stat
import sys
import time

# scan state
class Changed(Exception):
  pass

class MountLayoutChanged(Changed):
  pass

class Limit(Exception):
  def __init__(self, reason, path=None):
    self.path = path
    super().__init__(reason)

class Budget:
  def __init__(self, deadline=None, seconds=120):
    self.seconds = seconds
    self.deadline = deadline if deadline is not None \
      else time.monotonic() + seconds
    self.path = None

  def fail(self, reason):
    raise Limit(reason, self.path)

  def check(self, path=None):
    if path is not None:
      self.path = path
    if time.monotonic() >= self.deadline:
      self.fail(f"{self.seconds // 60}-minute scan limit reached")

  def entry(self, depth=0, path=None):
    self.check(path)
    if depth > 96:
      self.fail("scan depth limit reached")

class Node:
  __slots__ = ("name", "sig", "children", "bytes", "whole", "keep")

  def __init__(self, name, sig):
    self.name = name
    self.sig = sig
    self.children = None
    self.bytes = None
    self.whole = False
    self.keep = False

# filesystem helpers
def inside(path, root):
  return path == root or path.startswith(root.rstrip("/") + "/")

def signature(info):
  return [
    info.st_dev, info.st_ino, info.st_mode, info.st_nlink,
    info.st_size, info.st_mtime_ns, info.st_ctime_ns
  ]

def contextual_error(exc, path):
  filename = getattr(exc, "filename", None)
  if isinstance(filename, (str, bytes)) and os.path.isabs(filename):
    path = filename
  return OSError(exc.errno, exc.strerror or str(exc), path)

# mounts
def mount_table():
  result = {}
  with open("/proc/self/mountinfo") as stream:
    for line in stream:
      fields = line.split()
      separator = fields.index("-")
      def decode(value):
        return re.sub(r"\\([0-7]{3})",
          lambda match: chr(int(match[1], 8)), value)
      result[decode(fields[4])] = {
        "id": fields[0], "dev": fields[2],
        "root": decode(fields[3]), "type": fields[separator + 1]
      }
  return result

def containing(path, table):
  path = "/" + os.path.normpath(path).lstrip("/")
  while True:
    if path in table:
      return table[path]
    if path == "/":
      return None
    path = os.path.dirname(path)

def remote(item):
  return item["type"] in {
    "nfs", "nfs4", "cifs", "smb3", "9p", "ceph", "afs", "autofs"
  } or item["type"].startswith("fuse")

def expected_mount(path, table):
  item = containing(path, table)
  if item is None:
    raise Changed("mount information unavailable")
  if remote(item):
    raise Changed("network, autofs or FUSE filesystem")
  return item["id"]

def mount_id(fd):
  with open(f"/proc/self/fdinfo/{fd}") as stream:
    for line in stream:
      if line.startswith("mnt_id:"):
        return line.split()[1]
  raise OSError("descriptor mount identity unavailable")

def check_mount(fd, path, table):
  if mount_id(fd) != expected_mount(path, table):
    raise Changed("mount identity changed")

# descriptors
def open_component(name, flags, parent=None):
  try:
    return os.open(name, flags | os.O_NOFOLLOW, dir_fd=parent)
  except OSError as exc:
    if exc.errno in (errno.ELOOP, errno.ENOTDIR):
      raise Changed("symlinked or changed path component") from exc
    raise

def anchor(path, table):
  path = os.path.normpath(path)
  if not os.path.isabs(path):
    raise ValueError("descriptor paths must be absolute")
  expected_mount("/", table)
  fd = open_component("/", os.O_PATH | os.O_DIRECTORY)
  current = "/"
  try:
    check_mount(fd, current, table)
    for part in path.strip("/").split("/"):
      if not part:
        continue
      current = os.path.join(current, part)
      expected_mount(current, table)
      child = open_component(part, os.O_PATH | os.O_DIRECTORY, fd)
      os.close(fd)
      fd = child
      check_mount(fd, current, table)
    return fd
  except BaseException as exc:
    os.close(fd)
    if isinstance(exc, OSError):
      raise contextual_error(exc, current) from exc
    raise

def parent_fd(path, table):
  return anchor(os.path.dirname(path), table)

def checked_stat_at(parent, name, path, table, observed=None):
  expected_mount(path, table)
  fd = None
  try:
    fd = open_component(name, os.O_PATH, parent)
    check_mount(fd, path, table)
    value = os.fstat(fd)
    if observed is not None and signature(value) != signature(observed):
      raise Changed("entry changed during mount verification")
    return value
  except OSError as exc:
    raise contextual_error(exc, path) from exc
  finally:
    if fd is not None:
      os.close(fd)

def safe_stat(path, table):
  if path == "/":
    fd = anchor(path, table)
    try:
      return os.fstat(fd)
    finally:
      os.close(fd)
  parent = parent_fd(path, table)
  try:
    return checked_stat_at(parent, os.path.basename(path), path, table)
  finally:
    os.close(parent)

def check_link(parent, name, fd, path):
  try:
    current = os.stat(name, dir_fd=parent, follow_symlinks=False)
    if signature(current)[:3] != signature(os.fstat(fd))[:3]:
      raise Changed("ancestor replaced during inspection")
  except FileNotFoundError as exc:
    raise Changed("ancestor disappeared during inspection") from exc
  except OSError as exc:
    raise contextual_error(exc, path) from exc

# directories
class Directory:
  def __init__(self, path, table, budget, parent=None, expected=None):
    self.path, self.table, self.budget = path, table, budget
    self.parent = parent
    self.name = os.path.basename(path)
    self.fd = None
    budget.check(path)
    try:
      if parent is None:
        base = anchor(path, table)
        try:
          self.fd = open_component(".", os.O_RDONLY | os.O_DIRECTORY, base)
        finally:
          os.close(base)
      else:
        expected_mount(path, table)
        self.fd = open_component(
          self.name, os.O_RDONLY | os.O_DIRECTORY, parent.fd
        )
      check_mount(self.fd, path, table)
      self.info = os.fstat(self.fd)
      self.sig = signature(self.info)
      if expected is not None and self.sig != signature(expected):
        raise Changed("directory changed before inspection")
    except BaseException as exc:
      if self.fd is not None:
        os.close(self.fd)
        self.fd = None
      if isinstance(exc, OSError):
        raise contextual_error(exc, path) from exc
      raise

  def __enter__(self):
    return self

  def __exit__(self, kind, value, tb):
    try:
      if kind is None and self.parent is not None:
        check_link(self.parent.fd, self.name, self.fd, self.path)
    finally:
      os.close(self.fd)

  def unchanged(self):
    self.budget.check(self.path)
    if signature(os.fstat(self.fd)) != self.sig:
      raise Changed("directory changed during inventory")

  def scan(self, entries=False):
    self.unchanged()
    try:
      result = []
      with os.scandir(self.fd) as stream:
        for entry in stream:
          self.budget.check(self.path)
          result.append(entry if entries else entry.name)
      self.unchanged()
      if entries:
        result.sort(key=lambda entry: entry.name)
      else:
        result.sort()
      self.budget.check(self.path)
      return result
    except OSError as exc:
      raise contextual_error(exc, self.path) from exc

  def stat(self, name):
    path = os.path.join(self.path, name)
    self.budget.check(path)
    try:
      value = os.stat(name, dir_fd=self.fd, follow_symlinks=False)
      if not stat.S_ISDIR(value.st_mode):
        if path in self.table:
          raise Changed("mounted file")
        if value.st_dev != self.info.st_dev:
          value = checked_stat_at(self.fd, name, path, self.table, value)
      return value
    except OSError as exc:
      raise contextual_error(exc, path) from exc

def read_directory(path, table, budget):
  with Directory(path, table, budget) as directory:
    return directory.scan()

# metadata reads
def read_at(parent, name, path, table, budget, maximum=1024 * 1024):
  budget.check(path)
  expected_mount(path, table)
  fd = None
  try:
    fd = open_component(name, os.O_RDONLY | os.O_NONBLOCK, parent)
    check_mount(fd, path, table)
    before = os.fstat(fd)
    if not stat.S_ISREG(before.st_mode):
      raise Changed("metadata is not a regular file")
    if before.st_size > maximum:
      budget.fail("metadata file exceeds 1 MiB")
    parts, size = [], 0
    while True:
      budget.check(path)
      block = os.read(fd, min(65536, maximum + 1 - size))
      if not block:
        break
      parts.append(block)
      size += len(block)
      if size > maximum:
        budget.fail("metadata file exceeds 1 MiB")
    if signature(os.fstat(fd)) != signature(before):
      raise Changed("metadata changed during reading")
    return b"".join(parts).decode("utf-8")
  except OSError as exc:
    raise contextual_error(exc, path) from exc
  finally:
    if fd is not None:
      os.close(fd)

def read_regular(path, table, budget, maximum=1024 * 1024):
  parent = parent_fd(path, table)
  try:
    return read_at(parent, os.path.basename(path), path, table, budget, maximum)
  finally:
    os.close(parent)

# validation
class PathCursor:
  def __init__(self, table, budget):
    self.table, self.budget = table, budget
    self.parts = []
    self.fds = [anchor("/", table)]

  def __enter__(self):
    return self

  def pop(self, validate=True):
    fd = self.fds.pop()
    name = self.parts.pop()
    path = "/" + "/".join(self.parts + [name])
    try:
      if validate:
        check_link(self.fds[-1], name, fd, path)
    finally:
      os.close(fd)

  def __exit__(self, kind, value, tb):
    try:
      while self.parts:
        self.pop(validate=kind is None)
    finally:
      while self.fds:
        os.close(self.fds.pop())

  def directory(self, path):
    parts = [part for part in path.split("/") if part]
    common = 0
    while common < min(len(parts), len(self.parts)) \
        and parts[common] == self.parts[common]:
      common += 1
    while len(self.parts) > common:
      self.pop()
    for name in parts[common:]:
      current = "/" + "/".join(self.parts + [name])
      self.budget.check(current)
      expected_mount(current, self.table)
      try:
        fd = open_component(name, os.O_PATH | os.O_DIRECTORY, self.fds[-1])
      except OSError as exc:
        raise contextual_error(exc, current) from exc
      try:
        check_mount(fd, current, self.table)
      except BaseException:
        os.close(fd)
        raise
      self.parts.append(name)
      self.fds.append(fd)
    return self.fds[-1]

def guards_match(guards, table, budget):
  if not guards:
    return True
  groups = {}
  for path, expected in guards.items():
    budget.check(path)
    groups.setdefault(os.path.dirname(path), []).append((path, expected))
  parents = list(groups)
  budget.check()
  parents.sort(key=lambda path: path.split("/"))
  budget.check()

  with PathCursor(table, budget) as cursor:
    for parent in parents:
      budget.check(parent)
      try:
        fd = cursor.directory(parent)
      except FileNotFoundError:
        if any(expected is not None for _, expected in groups[parent]):
          return False
        continue
      parent_dev = os.fstat(fd).st_dev
      for path, expected in groups[parent]:
        budget.check(path)
        try:
          if path == "/":
            value = os.fstat(fd)
          else:
            name = os.path.basename(path)
            value = os.stat(name, dir_fd=fd, follow_symlinks=False)
            if path in table or value.st_dev != parent_dev:
              value = checked_stat_at(fd, name, path, table, value)
          current = signature(value)
        except FileNotFoundError:
          current = None
        except OSError as exc:
          raise contextual_error(exc, path) from exc
        if current != expected:
          return False
  return True

def invalid_root(path, cfg, table, external=False):
  if not os.path.isabs(path) or path == "/" or inside(cfg["home"], path):
    return "invalid cleanup root"
  if any(inside(path, root) for root in cfg["preserve"]):
    return "protected path"
  item = containing(path, table)
  if item is None:
    return "mount information unavailable"
  if remote(item):
    return "network, autofs or FUSE filesystem"
  if external:
    if any(inside(root, path) for root in cfg["preserve"]):
      return "contains protected paths"
    if any(root != path and inside(root, path) for root in table):
      return "contains nested mounts"
    if any(inside(root, path) for root in cfg["installations"]):
      return "contains an installation or state root"
    if os.path.realpath(path) != path:
      return "symlinked path or ancestor"
  return ""

# file cleanup
def clean_files(cfg, emit):
  budget = Budget(cfg.get("deadline"), cfg.get("seconds", 120))
  failed, counted = set(), set()
  expected_layout = cfg.get("expected_mounts")

  def check_layout(table):
    if expected_layout is not None and table != expected_layout:
      raise MountLayoutChanged("mount layout changed")

  def error(path, exc):
    if path not in failed:
      failed.add(path)
      emit("ERROR", path, str(exc), getattr(exc, "errno", None))

  def account(node, size):
    key = tuple(node.sig[:2])
    if key not in counted:
      counted.add(key)
      emit("BYTES", size)

  for job in cfg["jobs"]:
    root, parent = job["path"], None
    plan = describe = estimate = remove = selection = None
    try:
      budget.check(root)
      initial = mount_table()
      check_layout(initial)
      reason = invalid_root(root, cfg, initial)
      if reason:
        emit("SKIP", root, reason)
        continue
      if not guards_match(cfg.get("guards", {}), initial, budget):
        emit("SKIP", root, "Git metadata changed since project inspection")
        continue

      parent = parent_fd(root, initial)
      name = os.path.basename(root)
      identity = os.stat(name, dir_fd=parent, follow_symlinks=False)
      if stat.S_ISLNK(identity.st_mode):
        emit("SKIP", root, "symlinked cleanup root")
        continue
      if job.get("directory_root") and not stat.S_ISDIR(identity.st_mode):
        emit("SKIP", root, "expected a directory")
        continue
      if not stat.S_ISDIR(identity.st_mode) and root in initial:
        emit("SKIP", root, "mounted file")
        continue

      root_mount = expected_mount(root, initial)
      excludes = cfg["preserve"] + job.get("exclude", [])
      exclude_names = job.get("exclude_names", [])
      threshold = cfg["now"] - job["days"] * 86400
      patterns = job.get("patterns", [])
      expression = job.get("name_regex")
      matcher = re.compile(expression).fullmatch if expression else None

      def excluded(path):
        if any(inside(path, item) for item in excludes):
          return True
        if exclude_names:
          first = os.path.relpath(path, root).split(os.sep, 1)[0]
          return any(fnmatch.fnmatchcase(first, pattern)
                     for pattern in exclude_names)
        return False

      def eligible(path, info):
        stamp = max(info.st_mtime, info.st_atime) \
          if job.get("access", True) else info.st_mtime
        if job["days"] and stamp >= threshold:
          return False
        basename = os.path.basename(path)
        if patterns and not any(
          fnmatch.fnmatchcase(basename, pattern) for pattern in patterns
        ):
          return False
        return matcher is None or matcher(basename) is not None

      # selection
      def plan(fd, entry, path, top=False, depth=0, frozen=None):
        budget.entry(depth, path)
        if excluded(path):
          if frozen is not None:
            raise Changed("project artifact overlaps protected data")
          return False, None
        if not top and path in initial:
          if frozen is not None:
            raise Changed("project artifact contains a mount")
          emit("SKIP", path, "nested mount")
          return False, None

        info = os.stat(entry, dir_fd=fd, follow_symlinks=False)
        sig = signature(info)
        if frozen is not None and frozen.sig != sig:
          raise Changed("project artifact changed since inspection")
        mode = info.st_mode

        if stat.S_ISREG(mode) or stat.S_ISLNK(mode):
          allowed = stat.S_ISREG(mode) or (
            not top and job.get("links", True)
          )
          if not allowed or not eligible(path, info):
            if frozen is not None:
              raise Changed("project artifact no longer eligible")
            return False, None
          if info.st_dev != identity.st_dev:
            if frozen is not None:
              raise Changed("project artifact filesystem changed")
            emit("SKIP", path, "filesystem boundary")
            return False, None
          node = frozen if frozen is not None else Node(entry, sig)
          node.bytes = info.st_blocks * 512 if stat.S_ISREG(mode) else None
          return True, node

        if not stat.S_ISDIR(mode):
          if frozen is not None:
            raise Changed("project artifact contains a special file")
          return False, None
        if not top and not job.get("recursive", True):
          return False, None

        child_fd = open_component(entry, os.O_RDONLY | os.O_DIRECTORY, fd)
        try:
          if signature(os.fstat(child_fd)) != sig:
            raise Changed("directory changed during planning")
          if mount_id(child_fd) != root_mount:
            if frozen is not None:
              raise Changed("project artifact mount changed")
            emit("SKIP", path, "nested or changed mount")
            return False, None

          names = []
          with os.scandir(child_fd) as stream:
            for child in stream:
              budget.check(path)
              names.append(child.name)
          budget.check(path)
          names.sort()
          budget.check(path)

          if frozen is not None:
            children = frozen.children
            if children is None or len(names) != len(children) or any(
              name != child.name for name, child in zip(names, children)
            ):
              raise Changed("project artifact entries changed since inspection")
          else:
            children = []

          complete = True
          for index, child_name in enumerate(names):
            child_path = os.path.join(path, child_name)
            try:
              good, child = plan(
                child_fd, child_name, child_path, depth=depth + 1,
                frozen=children[index] if frozen is not None else None
              )
            except FileNotFoundError:
              raise Changed("entry disappeared during planning")
            except OSError as exc:
              if frozen is not None:
                raise contextual_error(exc, child_path) from exc
              error(child_path, contextual_error(exc, child_path))
              good, child = False, None
            complete = complete and good
            if frozen is None and child is not None:
              children.append(child)

          if signature(os.fstat(child_fd)) != sig:
            raise Changed("directory changed during planning")
        finally:
          os.close(child_fd)

        keep = top and job.get("keep", True)
        old = not job["days"] or info.st_mtime < threshold
        whole = complete and job.get("directories", True) and (bool(names) or old)
        if frozen is not None and not whole:
          raise Changed("project artifact could not be fully validated")
        if not children and (keep or not whole):
          return False, None
        node = frozen if frozen is not None else Node(entry, sig)
        node.children, node.whole, node.keep = children, whole, keep
        return whole, node

      # preview
      def describe(node, path):
        budget.check(path)
        if node.children is None:
          emit("REMOVE", path, "")
        elif node.whole:
          emit("REMOVE", path, "contents" if node.keep else "")
        else:
          for child in node.children:
            describe(child, os.path.join(path, child.name))

      def estimate(node, path):
        budget.check(path)
        if node.children is not None:
          for child in node.children:
            estimate(child, os.path.join(path, child.name))
        elif node.bytes is not None:
          account(node, node.bytes)

      # removal
      def remove(fd, node, path):
        entry = node.name
        budget.check(path)
        try:
          info = os.stat(entry, dir_fd=fd, follow_symlinks=False)
          if signature(info) != node.sig:
            emit("SKIP", path, "changed since selection")
            return False

          if node.children is None:
            if not eligible(path, info):
              emit("SKIP", path, "no longer eligible")
              return False
            os.unlink(entry, dir_fd=fd)
            if stat.S_ISREG(info.st_mode):
              account(node, info.st_blocks * 512)
            return True

          child_fd = open_component(entry, os.O_RDONLY | os.O_DIRECTORY, fd)
          try:
            if signature(os.fstat(child_fd)) != node.sig:
              emit("SKIP", path, "directory changed since selection")
              return False
            if mount_id(child_fd) != root_mount:
              emit("SKIP", path, "mount changed since selection")
              return False

            complete = True
            for child in node.children:
              if not remove(child_fd, child, os.path.join(path, child.name)):
                complete = False
            if not complete or not node.whole:
              return False
            if node.keep:
              return True

            current = os.stat(entry, dir_fd=fd, follow_symlinks=False)
            if signature(current)[:3] != node.sig[:3]:
              emit("SKIP", path, "directory replaced during removal")
              return False
            try:
              os.rmdir(entry, dir_fd=fd)
            except OSError as exc:
              if exc.errno in (errno.ENOTEMPTY, errno.EEXIST):
                emit("SKIP", path, "directory gained or retained entries")
                return False
              raise
            return True
          finally:
            os.close(child_fd)
        except FileNotFoundError:
          emit("SKIP", path, "entry disappeared")
          return False
        except Changed as exc:
          emit("SKIP", path, str(exc))
          return False
        except OSError as exc:
          error(path, contextual_error(exc, path))
          return False

      # final checks
      _, selection = plan(parent, name, root, True, frozen=job.get("snapshot"))
      if selection is None:
        continue

      current = mount_table()
      check_layout(current)
      relevant = {
        path for path in set(initial) | set(current)
        if inside(root, path) or inside(path, root)
      }
      if any(initial.get(path) != current.get(path) for path in relevant):
        raise Changed("mount layout changed")
      if not guards_match(cfg.get("guards", {}), current, budget):
        raise Changed("Git metadata changed since project inspection")

      fresh_parent = parent_fd(root, current)
      try:
        if signature(os.fstat(fresh_parent))[:2] != \
            signature(os.fstat(parent))[:2]:
          raise Changed("cleanup ancestor replaced during planning")
      finally:
        os.close(fresh_parent)

      describe(selection, root)
      if cfg["dry"]:
        estimate(selection, root)
      else:
        remove(parent, selection, root)
      if expected_layout is not None:
        check_layout(mount_table())

    except MountLayoutChanged:
      raise
    except FileNotFoundError:
      continue
    except Changed as exc:
      if expected_layout is not None:
        check_layout(mount_table())
      emit("SKIP", root, str(exc))
    except Limit as exc:
      if expected_layout is not None:
        raise
      emit("ERROR", exc.path or root, "limit: " + str(exc), None)
      return
    except OSError as exc:
      error(root, contextual_error(exc, root))
    finally:
      plan = describe = estimate = remove = selection = None
      if parent is not None:
        os.close(parent)
'''

namespace = {}
exec(shared, namespace)
for name in (
  "Changed", "MountLayoutChanged", "Limit", "Budget", "Node", "Directory",
  "signature", "mount_table", "containing", "remote", "safe_stat",
  "read_directory", "read_regular", "read_at", "contextual_error",
  "invalid_root", "guards_match", "clean_files"
):
  globals()[name] = namespace[name]

# section handling
def section(chip, function):
  try:
    function()
  except Limit as exc:
    failure(chip, exc.path or "inventory", exc, "limit")
  except Changed as exc:
    log(chip, "SKIP", "inspection", str(exc))
  except CommandError as exc:
    failure(chip, exc.command, exc, "command")
  except OSError as exc:
    failure(chip, exc.filename or "filesystem operation", exc)

# path resolution
def resolve_paths():
  global mounts, npm, go_caches, gopaths, gobin
  global preserve, installations, base_cfg
  mounts = mount_table()

  if "npm_config_cache" not in os.environ and available("npm"):
    try:
      value = checked(["npm", "config", "get", "cache"])
      if os.path.isabs(value):
        npm = os.path.normpath(value)
    except CommandError as exc:
      failure("CACHE", exc.command, exc, "command")

  if available("go"):
    command = [
      "env", "GOTOOLCHAIN=local", "go", "env", "-json",
      "GOCACHE", "GOMODCACHE", "GOPATH", "GOBIN"
    ]
    try:
      values = json.loads(checked(command))
      if not isinstance(values, dict) or any(
        not isinstance(values.get(name), str)
        for name in ("GOCACHE", "GOMODCACHE", "GOPATH", "GOBIN")
      ):
        raise ValueError("unrecognized Go environment")
      if any("\0" in values[name] for name in (
        "GOCACHE", "GOMODCACHE", "GOPATH", "GOBIN"
      )):
        raise ValueError("invalid Go path")
      if values["GOCACHE"] != "off" and not os.path.isabs(values["GOCACHE"]):
        raise ValueError("GOCACHE is neither an absolute path nor off")
      if not os.path.isabs(values["GOMODCACHE"]):
        raise ValueError("GOMODCACHE is not an absolute path")
      paths = values["GOPATH"].split(os.pathsep)
      if any(not os.path.isabs(path) for path in paths):
        raise ValueError("GOPATH contains a non-absolute or empty path")
      if values["GOBIN"] and not os.path.isabs(values["GOBIN"]):
        raise ValueError("GOBIN is not an absolute path")

      gopaths = [os.path.normpath(path) for path in paths]
      gobin = os.path.normpath(values["GOBIN"]) if values["GOBIN"] else ""
      go_caches = [
        os.path.normpath(values[name]) if os.path.isabs(values[name])
        else values[name]
        for name in ("GOCACHE", "GOMODCACHE")
      ]
    except CommandError as exc:
      failure("CACHE", exc.command, exc, "command")
    except ValueError as exc:
      failure("CACHE", shlex.join(command), exc, "metadata")

  preserve = [
    root + "/" + name
    for root in cache_roots
    for name in ("docker", "buildx", "buildkit", "containers")
  ] + [
    docker_config, home + "/.docker", data + "/nano",
    home + "/.Xauthority", home + "/.ICEauthority", home + "/.pulse-cookie"
  ] + private_preserve
  if gobin:
    preserve.append(gobin)
  for name in (
    "XAUTHORITY", "ICEAUTHORITY", "XDG_RUNTIME_DIR",
    "HF_HOME", "TORCH_HOME", "TORCH_EXTENSIONS_DIR"
  ):
    value = os.environ.get(name, "")
    if os.path.isabs(value):
      preserve.append(os.path.normpath(value))
  preserve = list(dict.fromkeys(preserve))

  installations = list(dict.fromkeys([
    config, data, state, cargo, rustup, gradle, bun, esp, nvm, npm, docker_config
  ] + [
    home + "/" + name for name in (
      ".docker", ".nvm", ".npm", ".ssh", ".gnupg",
      ".mozilla", ".android", ".triton", ".nv"
    )
  ] + gopaths))
  base_cfg = {
    "home": home, "preserve": preserve, "installations": installations,
    "now": started, "dry": args.dry_run
  }

# space measurements
def space_sample(path):
  try:
    info = os.statvfs(path)
    return info.f_fsid, info.f_bavail * info.f_frsize
  except PermissionError:
    if not priv:
      raise
    command = priv + [
      sys.executable, "-I", "-c",
      "import json,os,sys; s=os.statvfs(sys.argv[1]); "
      "print(json.dumps([s.f_fsid,s.f_bavail*s.f_frsize]))", path
    ]
    try:
      values = json.loads(checked(command))
      if not isinstance(values, list) or len(values) != 2 \
          or any(type(value) is not int for value in values):
        raise ValueError("invalid filesystem measurement")
      return tuple(values)
    except ValueError as exc:
      raise CommandError(command, str(exc)) from exc

def remember(path, table=None):
  if args.dry_run:
    return
  table = mounts if table is None else table
  item = containing(path, table)
  if not item or remote(item) or item["type"] in {
    "tmpfs", "devtmpfs", "proc", "sysfs", "overlay"
  }:
    return
  root = max((root for root in table if within(path, root)), key=len)
  if root in space_failed or any(value[0] == root for value in space.values()):
    return
  try:
    identity, available_bytes = space_sample(root)
    space.setdefault((item["type"], identity), (root, available_bytes))
  except (CommandError, OSError) as exc:
    space_failed.add(root)
    failure("SYSTEM", root, f"cannot measure free space: {exc}", "measurement")

# filesystem jobs
def files(chip, jobs, elevated=False, deadline=None, guards=None,
          seconds=120, expected_mounts=None):
  selected = unique_jobs(jobs)
  if not selected:
    return
  if deadline is None:
    deadline = time.monotonic() + seconds
  budget = Budget(deadline, seconds)
  budget.check(selected[0]["path"])
  current = mount_table()
  if expected_mounts is not None and current != expected_mounts:
    raise MountLayoutChanged("mount layout changed")

  ordered = sorted(selected, key=lambda item: item["path"].split("/"))
  budget.check()
  stack = []
  for item in ordered:
    budget.check(item["path"])
    item["exclude"] = list(item.get("exclude", []))
    while stack and not within(item["path"], stack[-1]["path"]):
      stack.pop()
    if stack:
      stack[-1]["exclude"].append(item["path"])
    stack.append(item)
  for item in selected:
    budget.check(item["path"])
    if not invalid_root(item["path"], base_cfg, current):
      remember(item["path"], current)

  cfg = dict(
    base_cfg, jobs=selected, deadline=deadline,
    seconds=seconds, guards=guards or {}
  )
  if expected_mounts is not None:
    cfg["expected_mounts"] = expected_mounts

  def emit(action, path, reason="", error_number=None):
    global file_bytes
    if action == "BYTES":
      file_bytes += int(path)
    elif action == "ERROR":
      if reason.startswith("limit: "):
        kind, reason = "limit", reason[len("limit: "):]
      else:
        kind = "permission" if error_number in (errno.EACCES, errno.EPERM) \
          else "filesystem"
      failure(chip, path, reason, kind)
    else:
      log(chip, action, path, reason)

  if not elevated or not priv:
    clean_files(cfg, emit)
    return

  # elevated worker
  driver = '''
pending_bytes = 0

def flush_bytes():
  global pending_bytes
  if pending_bytes:
    print(json.dumps(["BYTES", pending_bytes, "", None]), flush=True)
    pending_bytes = 0

def emit(action, path, reason="", error_number=None):
  global pending_bytes
  if action == "BYTES":
    pending_bytes += int(path)
    if pending_bytes >= 1024 * 1024:
      flush_bytes()
  else:
    flush_bytes()
    print(json.dumps([action, path, reason, error_number]), flush=True)

try:
  clean_files(json.load(sys.stdin), emit)
except KeyboardInterrupt:
  sys.exit(130)
finally:
  flush_bytes()
'''
  command = priv + [sys.executable, "-I", "-c", shared + driver]
  label = priv + [sys.executable, "-I", "-c", "<filesystem worker>"]

  def receive(line):
    try:
      record = json.loads(line)
      if not isinstance(record, list) or len(record) != 4:
        raise ValueError("invalid worker record")
      action, value, reason, number = record
      if action == "BYTES":
        if type(value) is not int or value < 0 \
            or reason != "" or number is not None:
          raise ValueError("invalid allocation record")
      elif action in ("SCAN", "SKIP", "REMOVE", "ERROR"):
        if not isinstance(value, str) or not isinstance(reason, str):
          raise ValueError("invalid action record")
        if number is not None and type(number) is not int:
          raise ValueError("invalid error number")
      else:
        raise ValueError("unknown worker action")
    except (ValueError, TypeError) as exc:
      raise CommandError(label, "invalid filesystem-worker output") from exc
    emit(*record)

  try:
    result = capture(
      command, input_text=json.dumps(cfg),
      timeout=max(1, deadline - time.monotonic() + 10),
      limit=128 * 1024, tail=True, on_stdout=receive
    )
  except CommandError as exc:
    raise CommandError(label, str(exc)) from exc
  if result.returncode:
    raise CommandError(label, result.stderr.strip() or f"exit {result.returncode}")

# public cache rules
def public_jobs():
  directories = [
    (cargo, "git"), (cargo, "registry"),
    (rustup, "downloads"), (rustup, "tmp"),
    (npm, "_cacache"), (npm, "_logs"), (npm, "_npx"),
    (bun, "install/cache"),
    (gradle, "caches"), (gradle, "wrapper/dists"),
    (esp, "dist"), (nvm, ".cache"), (home, ".nvm/.cache"),
    (home, ".nv/ComputeCache"), (home, ".nv/GLCache"),
    (triton_cache, ""), (data, "Trash/files"), (data, "Trash/info")
  ]
  small = [
    (home, ".lesshst"), (home, ".viminfo"),
    (home, ".python_history"), (home, ".node_repl_history"),
    (home, ".gnuplot_history"), (home, ".sudo_as_admin_successful"),
    (home, ".wget-hsts"), (home, ".ssh/known_hosts.old"),
    (state, "lesshst"), (state, "gnuplot_history"),
    (data, "recently-used.xbel"), (npm, "_update-notifier-last-checked")
  ]
  return [
    job(os.path.join(root, path), directory_root=True)
    for root, path in directories
  ] + [
    job(gradle + "/daemon", patterns=["daemon-*.out.log"],
        directories=False, links=False, directory_root=True)
  ] + [
    job(os.path.join(root, path)) for root, path in small
  ]

# browser caches
def browser_jobs(table):
  jobs, budget = [], Budget()
  for browser in ("chromium", "google-chrome"):
    root = config + "/" + browser
    reason = invalid_root(root, base_cfg, table)
    if reason:
      log("CACHE", "SKIP", root, reason)
      continue
    try:
      with Directory(root, table, budget) as directory:
        for entry in directory.scan(entries=True):
          name = entry.name
          path = os.path.join(root, name)
          budget.check(path)
          if name != "Default" and not name.startswith("Profile "):
            continue
          if path in table or not entry.is_dir(follow_symlinks=False):
            continue
          if not stat.S_ISDIR(directory.stat(name).st_mode):
            continue
          jobs.extend(
            job(path + "/" + leaf, args.cache_age, directory_root=True)
            for leaf in ("Cache", "Code Cache", "GPUCache")
          )
    except FileNotFoundError:
      pass
    except Changed as exc:
      log("CACHE", "SKIP", root, str(exc))
    except OSError as exc:
      failure("CACHE", root, exc)
  return jobs

# cache planning
def cache_plan():
  external = []
  if available("uv"):
    external.append((
      [uv_cache], ["uv", "--cache-dir", uv_cache, "cache", "clean"]
    ))
  if go_caches:
    external.append((
      [path for path in go_caches if os.path.isabs(path)],
      ["env", "GOTOOLCHAIN=local",
       "GOCACHE=" + go_caches[0], "GOMODCACHE=" + go_caches[1],
       "go", "clean", "-cache", "-testcache", "-modcache"]
    ))

  reserved = sorted({
    os.path.normpath(path)
    for paths, _ in external for path in paths
  })
  for item in private_jobs:
    if any(overlaps(item["path"], root) for root in reserved):
      raise ValueError(
        f"private rule overlaps a reserved tool cache: {item['path']}"
      )

  accepted, owned = [], []
  current = mount_table()
  for paths, command in external:
    reason = next((
      value for path in paths
      for value in [invalid_root(path, base_cfg, current, external=True)]
      if value
    ), "")
    if not reason:
      for index, path in enumerate(paths):
        if any(overlaps(path, other) for other in owned + paths[:index]):
          reason = "overlapping external cache roots"
          break
    if reason:
      log("CACHE", "SKIP", shlex.join(command), reason)
    else:
      accepted.append((paths, command))
      owned.extend(paths)

  jobs = unique_jobs([
    job(root, args.cache_age, directory_root=True, exclude=installations)
    for root in cache_roots
  ] + public_jobs() + private_jobs + browser_jobs(current))
  selected = []
  for item in jobs:
    if any(within(item["path"], root) for root in reserved):
      log("CACHE", "SKIP", item["path"], "reserved tool-managed cache")
      continue
    item["exclude"] = list(item.get("exclude", [])) + reserved
    selected.append(item)
  return selected, accepted

# cache cleanup
def user_caches(plan):
  jobs, accepted = plan
  files("CACHE", jobs)
  for paths, command in accepted:
    current = mount_table()
    reason = next((
      value for path in paths
      for value in [invalid_root(path, base_cfg, current, external=True)]
      if value
    ), "")
    if reason:
      log("CACHE", "SKIP", shlex.join(command), reason)
      continue
    for path in paths:
      remember(path, current)
    run("CACHE", command)

# temporary files
def temporary():
  if device == "chroot":
    return
  if device == "phone":
    prefix = os.environ.get("PREFIX", "").rstrip("/")
    roots = [(prefix + "/tmp", args.tmp_age)] if os.path.isabs(prefix) else []
  else:
    roots = [("/tmp", args.tmp_age), ("/var/tmp", args.var_tmp_age)]
  names = [
    ".X11-unix", ".X[0-9]*-lock", ".ICE-unix", ".XIM-unix", ".font-unix",
    "ssh-*", "gpg-*", "systemd*", "tmux-*", "screen-*", "pulse-*",
    "dbus-*", "xauth_*", "serverauth.*", "*.lock"
  ]
  files("TEMP", [
    job(path, days, links=False, exclude_names=names, directory_root=True)
    for path, days in roots
  ], elevated=True)

# logs
def logs():
  if device in ("phone", "chroot"):
    return
  files("LOG", [
    job("/var/log", args.log_age,
        access=False, directories=False, links=False, directory_root=True,
        exclude=["/var/log/journal", "/var/log/audit"],
        patterns=["*.gz", "*.xz", "*.zst", "*.[0-9]", "*.[0-9][0-9]", "*.old"]),
    job("/var/lib/systemd/coredump", patterns=["core.*"],
        directories=False, links=False, directory_root=True),
    job("/var/crash", directories=False, links=False, directory_root=True)
  ], elevated=True)
  if available("journalctl") and os.path.isdir("/run/systemd/system"):
    remember("/var/log/journal")
    run("JOURNAL", priv + [
      "journalctl", "--rotate", "--vacuum-size=50M",
      f"--vacuum-time={args.journal_age}d"
    ])

# project storage
rotation = {}

def nonrotating(dev, seen=None):
  if dev in rotation:
    return rotation[dev]
  seen = set() if seen is None else seen
  path = os.path.realpath("/sys/dev/block/" + dev)
  if path in seen or not os.path.exists(path):
    return False
  seen.add(path)
  try:
    if os.path.basename(path).startswith(("loop", "nbd", "rbd")):
      answer = False
    else:
      children = []
      directory = path + "/slaves"
      if os.path.isdir(directory):
        for name in os.listdir(directory):
          with open(directory + "/" + name + "/dev") as stream:
            children.append(stream.read().strip())
      if children:
        answer = all(nonrotating(child, seen.copy()) for child in children)
      else:
        if os.path.exists(path + "/partition"):
          path = os.path.dirname(path)
        with open(path + "/queue/rotational") as stream:
          answer = stream.read().strip() == "0"
    rotation[dev] = answer
  except OSError:
    rotation[dev] = False
  return rotation[dev]

def storage_reason(path, item):
  if remote(item):
    return "network, autofs or FUSE mount"
  if item["type"] not in {
    "ext2", "ext3", "ext4", "xfs", "f2fs", "vfat", "exfat", "ntfs3"
  }:
    return "unclassified filesystem crossing"
  if item["root"] != "/":
    return "subtree/bind mount"
  aliases = [
    other for other, value in mounts.items()
    if value["dev"] == item["dev"] and value["root"] == item["root"]
  ]
  if min(aliases, key=lambda value: (len(value), value)) != path:
    return "duplicate/bind mount"
  return "" if nonrotating(item["dev"]) \
    else "rotational or unknown backing storage"

# projects
def projects():
  if not project_auto and not project_roots:
    log("PROJECTS", "SKIP", "discovery", "no project roots configured")
    return
  if mount_table() != mounts:
    log("PROJECTS", "SKIP", "discovery", "mount layout changed")
    return

  budget = Budget(seconds=300)
  home_fs = containing(home, mounts)
  if not home_fs or remote(home_fs):
    log("PROJECTS", "SKIP", home, "unknown or network filesystem")
    return
  blocked = {
    path: reason
    for path, item in mounts.items()
    if path != home and within(path, home)
    for reason in [storage_reason(path, item)]
    if reason
  }
  excluded = list(dict.fromkeys(
    installations + cache_roots + preserve + [
      uv_cache, home + "/bin", home + "/.local/bin", home + "/.local/lib"
    ] + [path for path in go_caches if os.path.isabs(path)]
  ))
  pruned_names = {".git", "node_modules", ".venv", "venv"}
  workspace_names = {
    "pnpm-workspace.yaml", "pnpm-workspace.yml",
    "settings.gradle", "settings.gradle.kts"
  }
  recent_reason = f"activity within {args.project_age} days"
  open_dirs = {}

  class ProjectSkip(Exception):
    pass

  def check_layout():
    budget.check()
    if mount_table() != mounts:
      raise MountLayoutChanged("mount layout changed")

  def permission_skip(path, exc):
    global incomplete
    incomplete = True
    log("PROJECTS", "SKIP", path,
        "permission denied: " + display(exc.filename or path), "permission")

  def boundary(path):
    for root, reason in blocked.items():
      if within(path, root):
        return reason
    return "protected runtime or data path" \
      if any(within(path, root) for root in excluded) else ""

  def info(path):
    budget.check(path)
    if path in open_dirs:
      return os.fstat(open_dirs[path].fd)
    parent = open_dirs.get(os.path.dirname(path))
    return parent.stat(os.path.basename(path)) if parent else safe_stat(path, mounts)

  def names_at(path):
    return read_directory(path, mounts, budget)

  def recent_info(value):
    return args.project_age and max(value.st_mtime, value.st_ctime) >= cutoff

  # git layouts
  def git_layout(names):
    if "HEAD" not in names:
      return False
    return (
      "objects" in names and "refs" in names
      or "commondir" in names and "gitdir" in names
      or "config" in names and any(
        name in names for name in ("objects", "refs", "packed-refs", "index")
      )
    )

  # project markers
  def kinds(names):
    return {
      "rust": "Cargo.toml" in names,
      "node": "package.json" in names,
      "python": bool(names & {"pyproject.toml", "setup.py", "setup.cfg"})
        or any(fnmatch.fnmatchcase(name, "requirements*.txt") for name in names),
      "gradle": bool(names & {
        "build.gradle", "build.gradle.kts",
        "settings.gradle", "settings.gradle.kts"
      }),
      "maven": "pom.xml" in names,
      "cmake": "CMakeLists.txt" in names,
      "make": bool(names & {"Makefile", "makefile", "GNUmakefile"}),
      "dotnet": any(name.endswith((".csproj", ".fsproj", ".vbproj"))
                    for name in names)
    }

  def group_marker(names):
    return (
      git_layout(names) or ".git" in names or any(kinds(names).values())
      or bool(names & {"pnpm-workspace.yaml", "pnpm-workspace.yml"})
    )

  # discovery roots
  candidates = set(project_roots)
  ancestor_markers = {}
  if project_auto:
    home_names = set(names_at(home))
    ancestor_markers[home] = group_marker(home_names)
    candidates.update(
      os.path.join(home, name) for name in home_names if not name.startswith(".")
    )

  roots = []
  for path in sorted(candidates, key=lambda value: (len(value), value)):
    budget.check(path)
    if any(within(path, root) for root in roots):
      continue
    reason = boundary(path)
    parts = os.path.relpath(path, home).split(os.sep)
    if not reason and any(part in pruned_names for part in parts):
      reason = "dependency or Git-internal discovery root"
    if reason:
      log("PROJECTS", "SKIP", path, reason)
      continue
    try:
      value = info(path)
      if not stat.S_ISDIR(value.st_mode):
        if path in project_roots or stat.S_ISLNK(value.st_mode):
          log("PROJECTS", "SKIP", path, "not a real project directory")
        continue

      parent = os.path.dirname(path)
      while within(parent, home):
        budget.check(parent)
        if parent not in ancestor_markers:
          ancestor_markers[parent] = group_marker(set(names_at(parent)))
        if ancestor_markers[parent]:
          reason = "possible project/workspace ancestor outside selected root: " \
            + display(parent)
          break
        if parent == home:
          break
        parent = os.path.dirname(parent)
      if reason:
        log("PROJECTS", "SKIP", path, reason, "metadata")
      else:
        roots.append(path)
    except FileNotFoundError:
      continue
    except Changed as exc:
      log("PROJECTS", "SKIP", path, str(exc))
    except PermissionError as exc:
      permission_skip(path, exc)

  if not roots:
    log("PROJECTS", "SKIP", "discovery", "no eligible project roots")
    return

  # active processes
  def active_paths():
    result = set()
    with os.scandir("/proc") as stream:
      for entry in stream:
        budget.check("/proc")
        if not entry.name.isdigit():
          continue
        for leaf in ("cwd", "exe"):
          try:
            path = os.readlink(entry.path + "/" + leaf)
            if path.endswith(" (deleted)"):
              path = path[:-10]
            if os.path.isabs(path):
              result.add(path)
          except OSError:
            pass
    value = os.environ.get("VIRTUAL_ENV", "")
    if os.path.isabs(value):
      result.add(os.path.normpath(value))
    return result

  active = active_paths()
  watch, git_guards = {}, {}
  repositories, tracking, git_activity = {}, {}, {}
  toml_cache, cargo_configs = {}, {}
  git_storage = set()
  group_state = (
    watch, git_guards, repositories, tracking,
    git_activity, toml_cache, cargo_configs, git_storage
  )

  # group metadata
  def clear_group():
    for value in group_state:
      value.clear()

  def record(path, value):
    stamp = signature(value) if value is not None else None
    if path in watch and watch[path] != stamp:
      raise Changed("project metadata changed during inspection")
    watch[path] = stamp
    return value

  def observed(path, optional=False):
    try:
      value = info(path)
    except FileNotFoundError:
      if not optional:
        raise
      value = None
    return record(path, value)

  def metadata_storage(path, ancestor=False):
    budget.check(path)
    item = containing(path, mounts)
    if not item or remote(item):
      raise ValueError(f"metadata on unsupported storage: {display(path)}")
    if any(within(path, root) for root in blocked):
      raise ValueError(f"metadata on excluded storage: {display(path)}")
    if not ancestor and item["id"] != home_fs["id"] and not within(path, home):
      root = max((root for root in mounts if within(path, root)), key=len)
      if storage_reason(root, item):
        raise ValueError(f"metadata on excluded storage: {display(path)}")

  def metadata_info(path, optional=False, directory=False, either=False,
                    ancestor=False):
    path = os.path.abspath(path)
    metadata_storage(path, ancestor)
    value = observed(path, optional=optional)
    if value is None:
      return None
    regular = stat.S_ISREG(value.st_mode)
    is_directory = stat.S_ISDIR(value.st_mode)
    valid = (regular or is_directory) if either else (
      is_directory if directory else regular
    )
    if not valid:
      raise ValueError(f"unsupported or symlinked metadata: {display(path)}")
    return value

  def read_text(path, ancestor=False):
    metadata_info(path, ancestor=ancestor)
    parent = open_dirs.get(os.path.dirname(path))
    result = read_at(
      parent.fd, os.path.basename(path), path, mounts, budget
    ) if parent else read_regular(path, mounts, budget)
    observed(path)
    return result

  def mapping(value, label):
    if not isinstance(value, dict):
      raise ValueError(f"{label}: expected a table/object")
    return value

  def strings(value, label):
    if not isinstance(value, list) or any(
      not isinstance(item, str) for item in value
    ):
      raise ValueError(f"{label}: expected a list of strings")
    return value

  def string(value, label):
    if not isinstance(value, str):
      raise ValueError(f"{label}: expected a string")
    return value

  def read_toml(path, ancestor=False):
    if not tomllib:
      raise ValueError("Cargo inspection requires Python 3.11+")
    if path not in toml_cache:
      toml_cache[path] = tomllib.loads(read_text(path, ancestor=ancestor))
    return mapping(toml_cache[path], display(path))

  def cargo_config(path, ancestor):
    path = os.path.abspath(path)
    metadata_storage(path, ancestor)
    if path not in cargo_configs:
      value = metadata_info(path, optional=True, ancestor=ancestor)
      cargo_configs[path] = None if value is None \
        else read_toml(path, ancestor=ancestor)
    return cargo_configs[path]

  # workspace layouts
  def layout(directory, group, kind, names, members):
    budget.check(directory)
    if names & {"pnpm-workspace.yaml", "pnpm-workspace.yml"}:
      return "pnpm workspace layout not resolved"

    if kind["rust"]:
      if any(os.environ.get(name) for name in (
        "CARGO_TARGET_DIR", "CARGO_BUILD_TARGET_DIR", "CARGO_BUILD_BUILD_DIR"
      )):
        return "custom Cargo output location"
      paths = {cargo + "/config": False, cargo + "/config.toml": False}
      parent = directory
      while True:
        ancestor = within(home, parent)
        for name in ("config", "config.toml"):
          paths[parent.rstrip("/") + "/.cargo/" + name] = ancestor
        if parent == "/":
          break
        parent = os.path.dirname(parent)
      for path, ancestor in sorted(paths.items()):
        parsed = cargo_config(path, ancestor)
        if parsed is None:
          continue
        if "include" in parsed:
          return "indirect Cargo configuration"
        build = mapping(parsed.get("build", {}), "Cargo build configuration")
        if "target-dir" in build or "build-dir" in build:
          return "custom Cargo output location"

      manifest = read_toml(directory + "/Cargo.toml")
      package = mapping(manifest.get("package", {}), "Cargo package")
      declared = package.get("workspace")
      if declared is not None:
        members.append(os.path.normpath(os.path.join(
          directory, string(declared, "Cargo package.workspace")
        )))
      workspace = mapping(manifest.get("workspace", {}), "Cargo workspace")
      for pattern in strings(workspace.get("members", []), "Cargo members"):
        members.append(os.path.normpath(os.path.join(directory, pattern)))
      if workspace:
        targets = mapping(manifest.get("target", {}), "Cargo targets")
        tables = [workspace, manifest] + [
          mapping(value, "Cargo target") for value in targets.values()
        ]
        for table in tables:
          for key in ("dependencies", "dev-dependencies", "build-dependencies"):
            dependencies = mapping(table.get(key, {}), "Cargo " + key)
            for dependency in dependencies.values():
              if isinstance(dependency, str):
                continue
              dependency = mapping(dependency, "Cargo dependency")
              if "path" in dependency:
                target = os.path.normpath(os.path.join(
                  directory, string(dependency["path"], "Cargo dependency path")
                ))
                if not within(target, group):
                  return "external Cargo workspace dependency"

    if kind["node"]:
      package = mapping(
        json.loads(read_text(directory + "/package.json")), "package.json"
      )
      patterns = package.get("workspaces", [])
      if isinstance(patterns, dict):
        patterns = patterns.get("packages", [])
      for pattern in strings(patterns, "Node workspaces"):
        if not pattern.startswith("!"):
          if "{" in pattern or "}" in pattern:
            return "workspace pattern not resolved"
          members.append(os.path.normpath(os.path.join(directory, pattern)))

    if kind["gradle"]:
      for name in ("settings.gradle", "settings.gradle.kts"):
        if name not in names:
          continue
        text = read_text(directory + "/" + name)
        text = re.sub(
          r"""("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')|//[^\n]*|/\*[\s\S]*?\*/""",
          lambda match: match[1] if match[1] is not None else " ", text
        )
        if re.search(r"\b(projectDir|includeBuild|evaluate|apply)\b", text):
          return "custom Gradle workspace layout"
        for match in re.finditer(r"\binclude\b\s*(\([^)]*\)|[^\n;]+)", text):
          clause = match[1]
          literals = re.findall(r"""["']([^"']*)["']""", clause)
          remaining = re.sub(r"""["'][^"']*["']""", "", clause)
          if not literals or remaining.strip(" \t\r\n(),"):
            return "dynamic Gradle workspace layout"
          for member in literals:
            if "$" in member or "\\" in member:
              return "dynamic Gradle workspace layout"
            members.append(os.path.normpath(os.path.join(
              directory, member.lstrip(":").replace(":", "/")
            )))
    if any(not within(member, group) for member in members):
      return "workspace outside scanned group"
    return ""

  # git ownership
  def git_info(path, storage=False, **options):
    path = os.path.abspath(path)
    value = metadata_info(path, **options)
    git_guards[path] = watch[path]
    if storage and value is not None and stat.S_ISDIR(value.st_mode):
      git_storage.add(path)
    return value

  def git_marker(directory):
    marker = directory.rstrip("/") + "/.git"
    ancestor = within(home, directory)
    value = git_info(
      marker, optional=True, either=True, ancestor=ancestor, storage=True
    )
    if value is None:
      return None
    if stat.S_ISDIR(value.st_mode):
      return marker
    text = read_text(marker, ancestor=ancestor).strip()
    if not text.startswith("gitdir: ") or not text[8:]:
      raise ValueError(f"unrecognized Git directory: {display(marker)}")
    target = os.path.normpath(os.path.join(directory, text[8:]))
    git_info(target, directory=True, storage=True)
    return target

  def repository_for(directory):
    visited, current = [], directory
    while True:
      if current in repositories:
        answer = repositories[current]
        break
      visited.append(current)
      marker = git_marker(current)
      if marker is not None:
        answer = (current, marker)
        break
      if current == "/":
        answer = None
        break
      current = os.path.dirname(current)
    for path in visited:
      repositories[path] = answer
    return answer

  # git activity
  def git_recent(repository):
    if repository is None:
      return False
    gitdir = repository[1]
    if gitdir in git_activity:
      return git_activity[gitdir]

    recent = False
    for leaf in (
      "HEAD", "index", "FETCH_HEAD", "ORIG_HEAD", "packed-refs",
      "logs/HEAD", "commondir", "config", "config.worktree"
    ):
      value = git_info(gitdir + "/" + leaf, optional=True)
      if value is not None and recent_info(value):
        recent = True

    common = gitdir + "/commondir"
    if watch.get(common) is not None:
      declared = read_text(common).strip()
      if not declared:
        raise ValueError("empty Git common-directory metadata")
      target = os.path.normpath(os.path.join(gitdir, declared))
      git_info(target, directory=True, storage=True)
      if target != gitdir:
        for leaf in ("config", "config.worktree"):
          value = git_info(target + "/" + leaf, optional=True)
          if value is not None and recent_info(value):
            recent = True

    git_activity[gitdir] = recent
    return recent

  # git tracking
  git_env = dict(os.environ, GIT_OPTIONAL_LOCKS="0", LC_ALL="C")
  for name in (
    "GIT_DIR", "GIT_WORK_TREE", "GIT_COMMON_DIR", "GIT_INDEX_FILE",
    "GIT_CEILING_DIRECTORIES"
  ):
    git_env.pop(name, None)

  def git_query(command, root, binary=False):
    budget.check(root)
    return query(
      command, git_env, binary=binary,
      timeout=max(0.1, min(30, budget.deadline - time.monotonic()))
    )

  def load_tracking(repository):
    root, gitdir = repository
    if not available("git"):
      return None, "Git unavailable"

    command = ["git", "-C", root, "-c", "core.fsmonitor=false"]
    result = git_query(
      command + ["rev-parse", "--show-toplevel", "--absolute-git-dir"], root
    )
    if result.returncode:
      return None, "cannot verify Git worktree metadata"

    paths = result.stdout.splitlines()
    if len(paths) != 2 or any(
      not os.path.isabs(path) or "\0" in path for path in paths
    ):
      return None, "unrecognized Git worktree metadata"
    actual_root, actual_gitdir = map(os.path.normpath, paths)
    if actual_root != root or actual_gitdir != gitdir:
      return None, "unsupported Git worktree or metadata mapping"

    result = git_query(
      command + [
        "--git-dir=" + gitdir, "--work-tree=" + root,
        "ls-files", "--full-name", "-z"
      ],
      root, binary=True
    )
    if result.returncode:
      return None, "cannot determine Git tracking"
    if result.stdout and not result.stdout.endswith(b"\0"):
      return None, "incomplete Git tracking metadata"

    names = [
      os.fsdecode(name) for name in result.stdout.split(b"\0") if name
    ]
    budget.check(root)
    names.sort()
    budget.check(root)
    return names, ""

  def tracked(path, repository):
    if repository is None:
      return ""
    root = repository[0]
    if root not in tracking:
      tracking[root] = load_tracking(repository)
    names, reason = tracking[root]
    if reason:
      return reason

    relative = os.path.relpath(path, root)
    index = bisect.bisect_left(names, relative)
    if index < len(names) and names[index] == relative:
      return "contains tracked files"
    prefix = relative + "/"
    index = bisect.bisect_left(names, prefix)
    if index < len(names) and names[index].startswith(prefix):
      return "contains tracked files"
    return ""

  # artifact inventory
  python_artifacts = {
    "__pycache__", ".pytest_cache", ".mypy_cache",
    ".ruff_cache", ".hypothesis", ".tox", ".nox"
  }
  node_artifacts = {
    "node_modules", ".next", ".nuxt", ".output",
    ".turbo", ".parcel-cache", ".svelte-kit"
  }

  def artifact_snapshot(parent, name, value, retain=True):
    root = os.path.join(parent.path, name)
    if any(within(point, root) for point in mounts):
      raise ProjectSkip("artifact contains a mount")
    if any(overlaps(root, path) for path in excluded):
      raise ProjectSkip("artifact overlaps protected data or a runtime root")

    def visit(parent, name, value, depth):
      path = os.path.join(parent.path, name)
      budget.entry(depth, path)
      if recent_info(value):
        raise ProjectSkip(recent_reason)
      node = Node(name, signature(value)) if retain else None

      if stat.S_ISDIR(value.st_mode):
        with Directory(path, mounts, budget, parent, value) as directory:
          names = directory.scan()
          if ".git" in names:
            raise ProjectSkip("artifact contains a repository")
          if git_layout(names):
            raise ProjectSkip("artifact contains protected Git metadata")
          children = [] if retain else None
          for child_name in names:
            child = visit(
              directory, child_name, directory.stat(child_name), depth + 1
            )
            if retain:
              children.append(child)
          directory.unchanged()
        if retain:
          node.children = children
          node.whole = True
      elif stat.S_ISREG(value.st_mode) or stat.S_ISLNK(value.st_mode):
        if retain:
          node.bytes = value.st_blocks * 512 \
            if stat.S_ISREG(value.st_mode) else None
      else:
        raise ProjectSkip("artifact contains a socket or special file")
      return node

    try:
      return visit(parent, name, value, 0)
    finally:
      visit = None

  # project inspection
  def inspect(group_dir, scope, initial_names, initial_set):
    group = group_dir.path
    if any(within(path, group) for path in active):
      return [], "currently in use"
    if recent_info(observed(group)):
      return [], recent_reason
    inherited = repository_for(group)
    if inherited and not within(inherited[0], scope):
      return [], "repository extends outside selected root"
    if git_recent(inherited):
      return [], recent_reason

    candidates, metadata, members = [], [], []
    symlinks, visited = [], set()
    incomplete_scan = False

    def candidate(directory, name, value, repository):
      path = os.path.join(directory.path, name)
      reason = tracked(path, repository)
      snapshot = artifact_snapshot(directory, name, value, retain=not reason)
      candidates.append((path, snapshot, reason))

    def walk(directory, repository, node_project, python_project,
             depth=0, names=None, name_set=None):
      nonlocal incomplete_scan
      path = directory.path
      budget.entry(depth, path)
      directory.unchanged()
      visited.add(path)
      if recent_info(record(path, directory.info)):
        raise ProjectSkip(recent_reason)
      if names is None:
        names = directory.scan()
        name_set = set(names)
      budget.check(path)
      if git_layout(name_set):
        raise ProjectSkip("project contains protected Git metadata")

      kind = kinds(name_set)
      node_project = node_project or kind["node"]
      python_project = python_project or kind["python"]

      actionable = []
      for name in names:
        if name == ".git":
          continue
        child_path = os.path.join(path, name)
        budget.check(child_path)
        reason = boundary(child_path)
        if reason:
          incomplete_scan = True
          if child_path in blocked:
            log("PROJECTS", "SKIP", child_path, reason)
          continue
        value = record(child_path, directory.stat(name))
        if recent_info(value):
          raise ProjectSkip(recent_reason)
        mode = value.st_mode
        if stat.S_ISLNK(mode):
          symlinks.append(child_path)
        elif stat.S_ISDIR(mode) or (
          python_project and name.endswith((".pyc", ".pyo"))
          and stat.S_ISREG(mode)
        ):
          actionable.append((name, value))

      if ".git" in name_set:
        marker = git_marker(path)
        if marker is None:
          raise Changed("Git metadata disappeared during inspection")
        repository = (path, marker)
        repositories[path] = repository
        if git_recent(repository):
          raise ProjectSkip(recent_reason)

      if any(kind.values()) or name_set & {
        "pnpm-workspace.yaml", "pnpm-workspace.yml"
      }:
        metadata.append((path, kind, name_set & workspace_names))

      for name, value in actionable:
        child_path = os.path.join(path, name)
        budget.check(child_path)
        if not stat.S_ISDIR(value.st_mode):
          candidate(directory, name, value, repository)
          continue
        artifact = (
          python_project and name in python_artifacts
          or node_project and name in node_artifacts
          or node_project and os.path.basename(path) == ".angular"
            and name == "cache"
          or name == "target" and (kind["rust"] or kind["maven"])
          or kind["gradle"] and name in (".gradle", "build")
          or kind["dotnet"] and name in ("bin", "obj")
        )
        if not artifact and name in (".venv", "venv"):
          artifact = metadata_info(
            child_path + "/pyvenv.cfg", optional=True
          ) is not None
        if not artifact and (kind["cmake"] or kind["make"]) and (
          name in ("build", "_build") or name.startswith("cmake-build-")
        ):
          artifact = (
            metadata_info(child_path + "/CMakeCache.txt", optional=True) is not None
            and metadata_info(
              child_path + "/CMakeFiles", optional=True, directory=True
            ) is not None
          )
        if artifact:
          candidate(directory, name, value, repository)
        else:
          with Directory(child_path, mounts, budget, directory, value) as child:
            open_dirs[child_path] = child
            try:
              walk(child, repository, node_project, python_project, depth + 1)
            finally:
              open_dirs.pop(child_path, None)
      directory.unchanged()

    try:
      walk(
        group_dir, inherited, False, False,
        names=initial_names, name_set=initial_set
      )
      if not candidates:
        return [], ""
      if incomplete_scan:
        return [], "incomplete project activity scan"
      for directory, kind, names in metadata:
        reason = layout(directory, group, kind, names, members)
        if reason:
          return [], reason

      for member in members:
        budget.check(member)
        wildcard = re.search(r"[*?\[]", member)
        if wildcard:
          prefix = member[:wildcard.start()].rsplit("/", 1)[0] or "/"
          if any(overlaps(path, prefix) for path in symlinks):
            return [], "workspace member not inspected"
          if not any(fnmatch.fnmatchcase(path, member) for path in visited):
            return [], "workspace members not resolved"
        elif member not in visited:
          return [], "workspace member not inspected"
      return candidates, ""
    except ProjectSkip as exc:
      return [], str(exc)
    finally:
      walk = candidate = None

  # project cleanup
  def process_group(directory, scope, names, name_set):
    nonlocal active
    clear_group()
    try:
      candidates, reason = inspect(directory, scope, names, name_set)
      if reason:
        log("PROJECTS", "SKIP", directory.path, reason)
        return

      protected_git = sorted(git_storage)
      exclusions = excluded + protected_git
      group_jobs = []
      for path, snapshot, reason in candidates:
        budget.check(path)
        if any(overlaps(path, root) for root in protected_git):
          reason = "artifact overlaps protected Git metadata"
        if reason:
          log("PROJECTS", "SKIP", path, reason)
        else:
          group_jobs.append(
            job(path, keep=False, exclude=exclusions, snapshot=snapshot)
          )
      if not group_jobs:
        return

      check_layout()
      if not guards_match(watch, mounts, budget):
        log("PROJECTS", "SKIP", directory.path, "project changed during inspection")
        return
      active = active_paths()
      if any(within(path, directory.path) for path in active):
        log("PROJECTS", "SKIP", directory.path, "currently in use")
        return

      budget.check(directory.path)
      files(
        "PROJECTS", group_jobs, deadline=budget.deadline,
        guards=git_guards, seconds=300, expected_mounts=mounts
      )
      check_layout()
    finally:
      clear_group()

  # project discovery
  def discover(path, scope, depth=0, parent=None, expected=None):
    try:
      budget.entry(depth, path)
      reason = boundary(path)
      if reason:
        log("PROJECTS", "SKIP", path, reason)
        return

      with Directory(path, mounts, budget, parent, expected) as directory:
        open_dirs[path] = directory
        try:
          entries = directory.scan(entries=True)
          name_set = {entry.name for entry in entries}
          budget.check(path)
          if git_layout(name_set):
            log("PROJECTS", "SKIP", path, "protected Git metadata")
            return
          if group_marker(name_set):
            names = [entry.name for entry in entries]
            del entries
            process_group(directory, scope, names, name_set)
            return

          for entry in entries:
            name = entry.name
            child_path = os.path.join(path, name)
            budget.check(child_path)
            reason = boundary(child_path)
            if reason:
              if child_path in blocked:
                log("PROJECTS", "SKIP", child_path, reason)
              continue
            if name in pruned_names:
              continue
            try:
              is_directory = entry.is_dir(follow_symlinks=False)
            except OSError as exc:
              raise contextual_error(exc, child_path) from exc
            if not is_directory:
              continue
            value = directory.stat(name)
            if stat.S_ISDIR(value.st_mode):
              discover(child_path, scope, depth + 1, directory, value)
        finally:
          open_dirs.pop(path, None)

    except MountLayoutChanged:
      raise
    except Changed as exc:
      check_layout()
      log("PROJECTS", "SKIP", path, str(exc))
    except ValueError as exc:
      log("PROJECTS", "SKIP", path, str(exc), "metadata")
    except PermissionError as exc:
      permission_skip(path, exc)
    except FileNotFoundError as exc:
      log(
        "PROJECTS", "SKIP", path,
        "path or Git metadata unavailable: " + display(exc.filename or path),
        "metadata"
      )
    except CommandError as exc:
      failure("PROJECTS", exc.command, exc, "command")
    except OSError as exc:
      failure("PROJECTS", exc.filename or path, exc)

  try:
    for root in sorted(roots):
      budget.check(root)
      check_layout()
      log("PROJECTS", "SCAN", root)
      discover(root, root)
  except MountLayoutChanged as exc:
    log("PROJECTS", "SKIP", "remaining projects", str(exc))
  finally:
    discover = None
    clear_group()

# docker
def docker():
  if not available("docker"):
    log("DOCKER", "SKIP", "docker", "not installed")
    return
  user_command = ["docker", "--config", docker_config]
  context = os.environ.get("DOCKER_CONTEXT", "")
  requested_host = os.environ.get("DOCKER_HOST", "")
  if not context and not requested_host:
    context = checked(user_command + ["context", "show"])
  endpoint = checked(user_command + [
    "context", "inspect", context, "--format", "{{.Endpoints.docker.Host}}"
  ]) if context else requested_host
  if not endpoint.startswith("unix://"):
    log("DOCKER", "SKIP", endpoint, "remote or unsupported Docker endpoint")
    return

  socket_path = endpoint[len("unix://"):]
  if not os.path.isabs(socket_path):
    failure("DOCKER", endpoint, "invalid local socket path", "metadata")
    return
  try:
    socket_info = os.stat(socket_path)
  except FileNotFoundError:
    log("DOCKER", "SKIP", endpoint, "daemon unavailable; socket absent")
    return
  if not stat.S_ISSOCK(socket_info.st_mode):
    failure("DOCKER", endpoint, "endpoint is not a Unix socket", "metadata")
    return

  command = priv + [
    "env", "-u", "DOCKER_HOST", "-u", "DOCKER_CONTEXT",
    "LC_ALL=C", "NO_COLOR=1",
    "docker", "--config", docker_config, "--host", endpoint
  ]
  info_command = command + ["info", "--format", "{{.DockerRootDir}}"]
  root = checked(info_command)
  if not os.path.isabs(root) or "\n" in root:
    failure("DOCKER", shlex.join(info_command), "invalid DockerRootDir", "metadata")
    return
  remember(root)
  remember("/var/lib/containerd")
  run(
    "DOCKER", command + ["system", "prune", "-af"],
    f"{context or 'explicit endpoint'}; {endpoint}; no volumes"
  )

# packages
def packages():
  for path in ("/usr", "/opt", "/var"):
    remember(path)
  if available("pacman"):
    if available("paccache"):
      if available("pacman-conf"):
        for path in checked(["pacman-conf", "CacheDir"]).splitlines():
          if os.path.isabs(path):
            remember(os.path.normpath(path))
      else:
        remember("/var/cache/pacman/pkg")
      run("PACKAGE", priv + ["paccache", "-rk0"])
    elif available("pacman-conf"):
      paths = [
        os.path.normpath(path)
        for path in checked(["pacman-conf", "CacheDir"]).splitlines()
        if path.strip()
      ]
      if not paths or any(not os.path.isabs(path) for path in paths):
        failure("PACKAGE", "pacman-conf CacheDir",
                "no valid absolute cache directories returned", "metadata")
      else:
        suffixes = (
          "", ".zst", ".xz", ".gz", ".bz2", ".lrz", ".lzo", ".Z", ".lz4", ".lz"
        )
        patterns = [
          "*.pkg.tar" + suffix + extension
          for suffix in suffixes for extension in ("", ".sig")
        ]
        files("PACKAGE", [
          job(path, patterns=patterns, directories=False, links=False,
              directory_root=True)
          for path in dict.fromkeys(paths)
        ], elevated=True)
    else:
      failure("PACKAGE", "package cache cleanup",
              "neither paccache nor pacman-conf is available", "command")

    result = query(["pacman", "-Qdtq"])
    if result.returncode == 0 and result.stdout.strip():
      run("PACKAGE", priv + [
        "pacman", "-Rns", "--noconfirm", *result.stdout.split()
      ])
    elif result.stderr.strip():
      failure("PACKAGE", "pacman -Qdtq", result.stderr.strip(), "command")

  elif available("apt-get"):
    if device == "phone":
      prefix = os.environ.get("PREFIX", "")
      if os.path.isabs(prefix):
        remember(prefix + "/var/cache/apt")
    else:
      remember("/var/cache/apt")
    run("PACKAGE", priv + ["apt-get", "clean"])
    run("PACKAGE", priv + ["apt-get", "autoremove", "--purge", "-y"])
  elif available("dnf"):
    remember("/var/cache/dnf")
    run("PACKAGE", priv + ["dnf", "clean", "all"])
    run("PACKAGE", priv + ["dnf", "autoremove", "-y"])

  if device not in ("phone", "chroot") and available("flatpak"):
    remember(data + "/flatpak")
    remember("/var/lib/flatpak")
    run("PACKAGE", ["flatpak", "uninstall", "--user", "--unused", "-y"])
    run("PACKAGE", priv + ["flatpak", "uninstall", "--system", "--unused", "-y"])

# execution
try:
  resolve_paths()
  plan = cache_plan()
  remember("/")
  remember(home)

  if args.projects:
    section("PROJECTS", projects)
  section("CACHE", lambda: user_caches(plan))
  section("TEMP", temporary)
  section("LOG", logs)
  if available("screen"):
    section("SESSION", lambda: run(
      "SESSION", ["env", "LC_ALL=C", "screen", "-wipe"], empty_screen=True
    ))
  if args.docker:
    section("DOCKER", docker)
  section("PACKAGE", packages)

except KeyboardInterrupt:
  interrupted = True
except Limit as exc:
  aborted = True
  failure("SYSTEM", exc.path or "inventory", exc, "limit")
except Changed as exc:
  aborted = True
  failure("SYSTEM", "initialization changed", exc, "filesystem")
except CommandError as exc:
  aborted = True
  failure("SYSTEM", exc.command, exc, "command")
except OSError as exc:
  aborted = True
  failure("SYSTEM", exc.filename or "initialization", exc)
except ValueError as exc:
  aborted = True
  failure("SYSTEM", "cleanup aborted", exc, "configuration")
except Exception as exc:
  aborted = True
  failure("SYSTEM", "cleanup aborted", f"{type(exc).__name__}: {exc}", "internal")
  traceback.print_exc()

# final measurements
disk_change = 0
space_partial = bool(space_failed)
if not args.dry_run:
  for key, (path, before) in space.items():
    try:
      identity, after = space_sample(path)
      if identity != key[1]:
        space_partial = True
        failure("SYSTEM", path, "filesystem identity changed", "measurement")
      else:
        disk_change += after - before
    except (CommandError, OSError) as exc:
      space_partial = True
      failure("SYSTEM", path, f"cannot measure free space: {exc}", "measurement")
    except KeyboardInterrupt:
      interrupted = space_partial = True
      break

# summary
def size(value):
  sign = "-" if value < 0 else ""
  value = abs(value)
  for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
    if value < 1024 or unit == "TiB":
      return sign + f"{value:.1f}".rstrip("0").rstrip(".") + unit
    value /= 1024

def counts(counter, order):
  names = list(order) + sorted(set(counter) - set(order))
  return " + ".join(f"{counter[name]} {name}" for name in names if counter[name])

if args.verbose:
  print()
if interrupted:
  print("Interrupted")
elif aborted:
  print("Aborted")
if skips:
  print("Skipped: " + counts(skips, (
    "permission", "storage", "active", "recent",
    "protected", "metadata", "unavailable", "unsupported"
  )))
if errors:
  print("Errors: " + counts(errors, (
    "configuration", "limit", "permission", "filesystem",
    "command", "metadata", "measurement", "internal"
  )))
action = "selected" if args.dry_run else "unlinked"
partial = " (partial)" if errors or interrupted or aborted or incomplete else ""
print(f"File allocation {action}: ~{size(file_bytes)}{partial}")
if not args.dry_run:
  sign = "+" if disk_change >= 0 else ""
  print("Disk free change: " + sign + size(disk_change)
        + (" (partial)" if space_partial else ""))

sys.exit(130 if interrupted else int(bool(errors or aborted or incomplete)))
PY
)

# disk space
disk() {
  # extract data
  unset info
  [ "$DEVICE" = 'phone' ] || local info=$(df -h | grep -E '/$')
  [ -z "$info" ] && info=$(df -h | sort -hk2 | tail -n 1)
  [ -z "$info" ] && error 'Disk info not found' && return 1
  local total=$(awk '{print $2}' <<< "$info")
  local used=$(awk '{print $3}' <<< "$info")
  local avail=$(awk '{print $4}' <<< "$info")
  local percent=$(awk '{print $5}' <<< "$info")

  # print data
  echo "Disk usage: $used/$total ($percent, $avail free)"
}

# dependency checker
check_deps() {
  if [ -z "$PACKAGES" ]; then
    if dpkg-query --version >/dev/null 2>&1; then
      readarray -t packages <<< $(dpkg-query -W -f='${Package}\n')
    elif pacman -V >/dev/null 2>&1; then
      readarray -t packages <<< $(pacman -Qq)
    else
      warn "The system does not have dpkg or pacman intalled, proceeding without dependency checks."
      return
    fi
  else
    return
  fi

  if [ -n "$packages" ] && [ -z "$PACKAGES" ]; then
    export PACKAGES=("${packages[@]}")
  fi

  unset missing
  for dependency in "$@"; do
    unset found
    IFS="/" read -ra dependencies <<< "$dependency"
    for dep in "${dependencies[@]}"; do
      for package in "${packages[@]}"; do
        if [ "$package" = "$dep" ]; then
          found=true
          break 2
        fi
      done
    done
    [ -z "$found" ] && missing+=("$dependency")
  done

  if [ -n "$missing" ]; then
    warn "Missing dependencies: ${missing[@]}"
  fi
}

if [ -z "$skip_deps_check" ] || [ "$skip_deps_check" = false ]; then
  check_deps \
    grep sed tar nano bc jq curl gzip \
    gcc/build-essential/base-devel \
    git file pv 7zip lsof screen net-tools
fi

###########
# HISTORY #
###########

filter_long_history() {
  local history_output="$(history 1)"
  read -r hist_num command_string <<< "$history_output"
  if (( "${#command_string}" > 2000 )); then
    history -d "$hist_num"
  fi
}

export HISTSIZE=10000000 # unlimited history
export HISTFILESIZE=10000000 # unlimited history
export HISTIGNORE="$HISTIGNORE:reboot*:shutdown*:shush*"
export HISTFILE=~/.history # prevent bash_history reset
unset HISTTIMEFORMAT # no time format
shopt -s cmdhist # no command separation
shopt -s histappend # append to history instead of overwrite
PROMPT_COMMAND="filter_long_history; history -a; $PROMPT_COMMAND"

#######
# GIT #
#######

clone() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage: clone (<url> | <user> <repo> | <path>) [dest] [options]'
    echo '  -d, --depth: Depth of clone (0 for full)'
    echo '  -b, --branch: Branch to clone'
    echo '  -c, --commit: Commit to checkout'
    echo 'Default: --depth 1'
    return
  fi

  local url path name depth=1 branch commit output

  # Parse input: existing directory or URL/repo
  if [ -d "$1" ]; then
    path="$1"; shift
  elif [[ "$1" =~ ^(https?://|git@) ]]; then
    url="$1"; shift
  elif [[ "$1" = */* ]]; then
    url="git@github.com:$1.git"; shift
  elif [ -n "$2" ] && [ "${2:0:1}" != '-' ]; then
    url="git@github.com:$1/$2.git"; shift; shift
  else
    error 'Invalid syntax. See: clone --help'
    return 1
  fi

  # Parse destination (only for clone mode)
  if [ -n "$url" ]; then
    if [ -n "$1" ] && [ "${1:0:1}" != '-' ]; then
      path="$1"; shift
    else
      path="${url##*/}"; path="${path%.git}"
    fi
  fi

  name="${path%/}"; name="${name##*/}"

  # Parse options
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -d|--depth) depth="$2"; shift; shift;;
      -b|--branch) branch="$2"; shift; shift;;
      -c|--commit) commit="$2"; depth=0; shift; shift;;
      *) error "Unknown option: $1"; return 1;;
    esac
  done

  if [ -d "$path" ]; then
    # Pull existing repo
    [ -n "$commit" ] \
    && [ "$(git -C "$path" rev-parse HEAD)" = "$commit" ] && return

    output=$(git -C "$path" pull 2>&1)

    if [ "$?" != 0 ]; then
      echo "$output"
      error "Failed to pull $name"
      return 1
    fi

    [[ "$output" = *"Already up to date."* ]] \
    && info "No update for $name" || success "Updated $name"
  else
    # Clone new repo
    info "Cloning $name..."

    local opts=""
    [ "$depth" != 0 ] && opts="--depth $depth"
    [ -n "$branch" ] && opts="$opts --branch $branch"

    if ! git clone "$url" "$path" $opts; then
      error "Failed to clone $name"
      return 1
    fi

    [ -n "$commit" ] && git -C "$path" checkout "$commit" --quiet
    success "Cloned $name"
  fi
}

# git helper
g() {
  # menu
  if [[ -z "$1" ]]; then
    echo
    if [[ ! -d "$(git rev-parse --git-dir 2>/dev/null)" ]]; then
      local flag='true'
      echo -e "\e[35m> No repo found\e[0m\n\e[34m"
      echo '[i] - init'
      echo '[s] - setup'
      echo '[c] - clone'
      echo -e "\n\e[31m[e] - exit\e[0m\n"
    else
      url="$(git config --get remote.origin.url)"
      url="${url/https:\/\/github\.com\//}"
      url="${url/.git/}"
      echo -e "\e[35m> $url\e[0m\n"
      git status
      echo -e '\e[32m'
      echo '[c] - commit current'
      echo '[C] - commit all'
      echo '[r] - rename commit'
      echo '[d] - delete commit'
      echo -e '\e[34m'
      echo '[p] - push'
      echo '[P] - push -f'
      echo '[l] - pull'
      echo '[L] - pull -f'
      echo -e '\e[33m'
      echo '[b] - edit branch'
      echo '[o] - checkout'
      echo '[u] - edit url'
      echo '[h] - history'
      echo -e '\e[31m'
      echo '[e] - exit'
      echo -e '\e[0m'
    fi
    read -p 'Choice: ' choice
    if [[ -z "$choice" ]]; then
      choice='cp'
    fi
  else
    choice="$1"
  fi

  # execute commands
  for ((i=0; i < "${#choice[0]}"; i++)); do

    echo
    case "${choice:i:1}" in

      i) git init; git branch -m main;;
      s) git config --global init.defaultBranch main
         git init; git branch -m main
         read -p 'url: ' url
         [ -n "$url" ] && git remote add origin "$url"
         read -p 'gitignore: ' gitignore
         [ -n "$gitignore" ] && echo -e "${gitignore// /\\n}" > .gitignore
         read -p "files to add: " toAdd
         [ -n "$toAdd" ] && git add "$toAdd"
         git commit -m '[+] Initial commit'
         read -p "push ? " push
         [ "$push" == 'y' ] && git push origin main;;

      c) if [ "$flag" = 'true' ]; then
           read -p 'Link or Author/Repo ? ' repo
           if [ "${repo:0:4}" = 'http' ]; then
             clone "$repo"
           else
             clone "${repo%/*}" "${repo#*/}"
           fi
         else
           read -p 'commit name ? ' commit
           [ -n "$commit" ] && git commit -am "$commit" \
           || git commit -am '[~] Update'
         fi;;
      C) read -p 'commit name ? ' commit
         git add *
         [ -n "$commit" ] && git commit -m "$commit" \
         || git commit -m '[~] Update';;

      p) git push origin main;;
      P) git push origin main -f;;
      l) git pull origin main;;
      L) read -p 'rebase ? ' choice
         [ "$choice" = 'y' ] \
         && git commit -am 'before rebase' \
         && git pull origin main --rebase;;
      r) read -p 'commit new name ? ' commit
         [ -n "$commit" ] && git commit --amend -m "$commit";;
      d) read -p 'delete last commit ? ' choice
         [ "$choice" == 'y' ] && git reset --hard HEAD^;;
      u) read -p 'url ? ' url
         [ -n "$url" ] && git remote set-url origin "$url";;
      b) read -p 'branch ? ' branch
         [ -n "$branch" ] && git branch -m "$branch";;
      o) git checkout
         read -p 'file ? ' file
         [ -n "$file" ] && git checkout "$file";;
      h) git reflog;;
      e) return;;
      *) error "Invalid input '${choice:i:1}'\n"; return 1;;

    esac

  done
  echo
}

#########
# FILES #
#########

ren() {
  local depth="-maxdepth 1"
  local pattern=""
  local replacement=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -r) depth=""; shift;;
      *)if [ -z "$pattern" ]; then
           pattern="$1"
        elif [ -z "$replacement" ]; then
          replacement="$1"
        fi; shift;;
    esac
  done

  [ -z "$pattern" ] && echo 'No patterns' && return 1

  mapfile -t files < <(find . $depth -not -path '*/\.*')
  mapfile -t renamed < <(
    printf '%s\n' "${files[@]}" | sed -E "s:$pattern:$replacement:g"
  )

  for i in "${!files[@]}"; do
    [ ! -e "${files[i]}" ] && continue
    [ "${files[i]}" = "${renamed[i]}" ] && continue
    mv "${files[i]}" "${renamed[i]}" 2>/dev/null && \
    echo "Renamed: ${files[i]} -> ${renamed[i]}" || \
    echo "Failed to rename: ${files[i]}"
  done
}

##############
# NETWORKING #
##############

myip() {
  local private_ips=$(ip -4 -o addr show | \
    awk '{print $4}' | \
    cut -d/ -f1 | \
    grep -v '127.0.0.1' | \
    sort -u | \
    xargs | \
    sed 's/ / - /g')

  echo -e "PRIVATE: \e[34m${private_ips:-None}\e[0m"

  local public_ip
  public_ip=$(curl -s -4 --max-time 5 ip.3z.ee 2>/dev/null)

  [[ "$public_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
    public_ip='Request Failed'

  echo -e "PUBLIC:  \e[34m$public_ip\e[0m"
}

ports() {
  local entries
  entries=$($sudo ss -tulnpH | awk '{
    addr = $5
    match(addr, /:[0-9]+$/)
    port = substr(addr, RSTART + 1)
    ip = substr(addr, 1, RSTART - 1)

    gsub(/[\[\]]/, "", ip)
    sub(/%.*/, "", ip)
    sub(/^::ffff:/, "", ip)

    type = (ip ~ /:/ || ip == "*") ? "IPv6" : "IPv4"
    if (ip == "0.0.0.0" || ip == "::" || ip == "*" || ip == "") ip = "*"

    svc = "-"
    if (match($0, /"[^"]+"/)) {
      svc = substr($0, RSTART + 1, RLENGTH - 2)
      if (length(svc) > 9) svc = substr(svc, 1, 9)
    }

    proto = toupper($1); sub(/6$/, "", proto)
    print svc, type, proto, ip, port
  }' OFS='\t' | sort -t$'\t' -k5,5n -u)

  [[ -z "$entries" ]] && { echo "No opened ports"; return; }

  while IFS=$'\t' read -r s t n i p; do
    if [[ $i == 127.* || $i == ::1 || $i == 192.168.* || $i == 10.* ||
          $i == 172.1[6-9].* || $i == 172.2[0-9].* || $i == 172.3[0-1].* ||
          $i == 169.254.* || $i == fe80* || $i == fd* || $i == fc* ]]; then
      printf "%-18s %-6s %-5s %-7s %s\n" "$s" "$t" "$n" "$p" "$i"
    else
      printf "\e[31m%-18s %-6s %-5s %-7s %s\e[0m\n" "$s" "$t" "$n" "$p" "$i"
    fi
  done <<< "$entries"
}

##########
# SCREEN #
##########

s() {
  local attached detached selected
  local screens=$(screen -ls)

  readarray -t attached <<< $(grep -Po '[0-9]+\..+(?=\(Attached\))' <<< "$screens")
  readarray -t detached <<< $(grep -Po '[0-9]+\..+(?=\(Detached\))' <<< "$screens")

  [ -z "$attached$detached" ] && error "No screens found" && return 1

  if [ -n "$attached" ]; then
    echo $'\nAttached screens:'
    for ((i=1; i <= "${#attached[@]}"; i++)); do
      screen="${attached[i-1]//\\/\/}"
      echo "$i - ${screen#*.}"
    done
  else
    unset attached
  fi

  if [ -n "$detached" ]; then
    echo $'\nDetached screens:'
    for ((i=1; i <= "${#detached[@]}"; i++)); do
      screen="${detached[i-1]//\\/\/}"
      echo "$((i+${#attached[@]})) - ${screen#*.}"
    done
  else
    unset detached
  fi

  read -p $'\nChoice (default=1): ' answer || { echo; return 0; }
  [ -z "$answer" ] && answer=1

  if [[ "$answer" =~ ^[0-9]+$ ]]; then
    if (( "$answer" <= "${#attached[@]}" )); then
      selected="${attached[answer-1]}"
    else
      selected="${detached[answer-${#attached[@]}-1]}"
    fi

    local id=$(echo "$selected" | grep -Po '^[0-9]+')
    if [ -n "$id" ]; then
      screen -rd "$id"
    else
      error "Could not extract screen ID"
      return 1
    fi
  else
    error "Invalid choice"
    return 1
  fi
  echo
}

############
# TORRENTS #
############

addtrackers() {
  local magnet_link="$1"
  local trackers=$(curl -s 'https://raw.githubusercontent.com/ngosang/trackerslist/refs/heads/master/trackers_all.txt')
  local new_trackers=$(sed -z 's:\n\n:\&tr=:g' <<< "${trackers%*}")
  local new_magnet_link="${magnet_link}&tr=${new_trackers}"
  echo $'\n'"$new_magnet_link"$'\n'
}

streaminfo() {
  ffprobe -show_entries stream=index,codec_type:stream_tags=language -of compact "$1" 2>&1 | {
    while read line; do
      if echo "$line" | grep -q -i "stream #"; then
        echo "$line"
      fi
    done
    while read -d $'\x0D' line; do
      if echo "$line" | grep -q "time="; then
        echo "$line" | awk '{ printf "%s\r", $8 }'
      fi
    done
  }
}

burnsubs() {
  local sub_lang='en'
  local sub_name='Subtitles'
  local replace_subs='false'
  local cmd='' filename='' output='' files=()

   usage=$'\nUsage: burnsubs [options] [file1] [file2] [output_file]\n'
  usage+=$'  file1, file2     Video file and subtitle file (order doesn\'t matter)\n'
  usage+=$'  output_file      Optional output video file path\n'
  usage+=$'Options:\n'
  usage+=$'  -r, --replace    Replace all existing subtitles with the new one\n'
  usage+=$'  -l, --lang       Set subtitle language (default: en)\n'
  usage+=$'  -n, --name       Set subtitle track name (default: username\'s subtitles)\n'
  usage+=$'  -h, --help       Display this help and exit\n'

  while [ "$#" != 0 ]; do
    case "$1" in
      -r|--replace) replace_subs=true; shift;;
      -l|--lang) sub_lang="$2"; shift 2;;
      -n|--name) sub_name="$2"; shift 2;;
      -h|--help) echo "$usage"; return 0;;
      -*) echo "Unknown option: $1"; echo "$usage"; return 1;;
      *)
        if [ -f "$1" ] || [ "$#" = 1 ]; then
          files+=("$1")
        else
          echo "Error: File not found: $1"
          return 1
        fi
        shift;;
    esac
  done

  if [ "${#files[@]}" -lt 2 ]; then
    echo "Error: Need at least two files (video and subtitle)"
    echo "$usage"
    return 1
  fi

  file1="${files[0]}"
  file2="${files[1]}"
  size1=$(du -k "$file1")
  size2=$(du -k "$file2")

  if [ "${size1%%$'\t'*}" -lt "${size2%%$'\t'*}" ]; then
    sub_file="$file1"
    input="$file2"
  else
    input="$file1"
    sub_file="$file2"
  fi

  [ "${#files[@]}" -gt 2 ] && output="${files[2]}"
  [ -d "$output" ] && filename="$output/${input##*/}"
  [ -z "$output" ] && filename="${input##*/}"

  if [ -n "$filename" ]; then
    ext="${filename##*.}"
    name="${filename%.*}"
    output="${name}-subbed.${ext}"
  fi

  [ "$sub_lang" = 'en' ] && sub_lang=eng
  [ "${input##*.}" = "mkv" ] && sub_codec='srt' || sub_codec='mov_text'

  ffmpeg_command=(
    ffmpeg -loglevel warning -hide_banner -stats \
      -i "$input" -sub_charenc UTF-8 -i "$sub_file" \
      -map 0:v -map 0:a -c:v copy -c:a copy \
      -metadata:s:s:0 language="$sub_lang" \
      -metadata:s:s:0 handler_name="$sub_name"
  )

  if [ "$replace_subs" = true ]; then
    ffmpeg_command+=(-map 1:s -c:s "$sub_codec")
  else
    ffmpeg_command+=(-map 0:s? -map 1:s -c:s "$sub_codec")
  fi

  echo $'\n\e[34mVideo:\e[0m   '"${input}"
  echo $'\e[34mSubs:\e[0m    '"${sub_file}"
  echo $'\e[34mOutput:\e[0m  '"${output}"
  echo $'\n\e[35m'"${ffmpeg_command[@]}" "$output"$'\e[0m\n'
  "${ffmpeg_command[@]}" "$output"

  if [ "$?" = 0 ]; then
    echo -e "\n\e[32mSubtitles successfully burnt at ${output}\e[0m\n"
  else
    echo -e "\n\e[31mError burning subtitles into the video!\e[0m\n"
    return 1
  fi
}

##########
# CODING #
##########

mk() {
  [ ! -f [Mm]akefile ] && echo 'No Makefile' && return 1
  make fclean || make clean
  make -j || return 1
  make clean || true
}

alias b='mk && echo --- && eval "$(find . -maxdepth 1 -executable -type f | head -n1)"'
alias val='mk && echo --- && valgrind --track-origins=yes $(find . -maxdepth 1 -executable -type f | head -n 1)'

alias cts='sed "s:\s*$::g" -i '
alias venv='source .venv/bin/activate'

snm() {
  [ -n "$1" ] && bins=("$@") || bins=($(find -maxdepth 1 -executable -type f))
  [ -z "$bins" ] && error 'No binary found' && return 1
  for bin in "${bins[@]}"; do
    mapfile -t libs <<< $(nm "$bin" | grep -Po " U \K[^@]+" --color=never)
    echo -e "\n\e[34m$bin (${#libs[@]})\e[0m"
    [ -n "$libs" ] && \
    printf '%s\n' "${libs[@]}" || echo 'No libraries found'
  done
  echo
}

ascii() {
  echo '32. '"'"' '"'"'	44. ,	56. 8	68. D	80. P	92. \	104. h	116. t'
  echo '33. !	45. -	57. 9	69. E	81. Q	93. ]	105. i	117. u'
  echo '34. "	46. .	58. :	70. F	82. R	94. ^	106. j	118. v'
  echo '35. #	47. /	59. ;	71. G	83. S	95. _	107. k	119. w'
  echo '36. $	48. 0	60. <	72. H	84. T	96. `	108. l	120. x'
  echo '37. %	49. 1	61. =	73. I	85. U	97. a	109. m	121. y'
  echo '38. &	50. 2	62. >	74. J	86. V	98. b	110. n	122. z'
  echo '39. '"'"'	51. 3	63. ?	75. K	87. W	99. c	111. o	123. {'
  echo '40. (	52. 4	64. @	76. L	88. X	100. d	112. p	124. |'
  echo '41. )	53. 5	65. A	77. M	89. Y	101. e	113. q	125. }'
  echo '42. *	54. 6	66. B	78. N	90. Z	102. f	114. r	126. ~'
  echo '43. +	55. 7	67. C	79. O	91. [	103. g	115. s'
}

alias f2p='file2prompt'
file2prompt() {
  local files=() prompt="" result="" copy_cmd="" hash_secrets=1 find_args=()
  local path dp ext content block arg

  for arg in "$@"; do
    if [ "$arg" = "--no-hash" ] || [ "$arg" = "-nh" ]; then
      hash_secrets=0
    else
      find_args+=("$arg")
    fi
  done

  readarray -t files < <(
    find "${find_args[@]}" \
      -type d \( \
        -name '.git' -o \
        -name 'node_modules' -o \
        -name 'venv' -o \
        -name '__pycache__' -o \
        -name 'dist' -o \
        -name '.next' \
      \) -prune -o \
      -type f \( \
        -name 'package-lock.json' -o \
        -name 'pnpm-lock.yaml' -o \
        -name 'Cargo.lock' -o \
        -name 'bun.lock' -o \
        -name 'go.sum' -o \
        -name 'uv.lock' -o \
        -name 'LICENSE' -o \
        -name '*.min.js' -o \
        -name '*.min.css' \
      \) -prune -o \
      -type f -print
  )
  [ ${#files[@]} -eq 0 ] && return 1

  readarray -t files < <(
    printf "%s\0" "${files[@]}" |
      xargs -0 file --mime-type 2>/dev/null |
      grep -E 'text/|application/(javascript|json|x-ndjson|x-wine-extension-ini|x-yaml|xml|toml)' |
      sed 's/: [^:]*$//' |
      awk '!seen[$0]++'
  )
  [ ${#files[@]} -eq 0 ] && return 1

  echo "Files included:" >&2
  wc -lc "${files[@]}" | sort -n >&2

  for path in "${files[@]}"; do
    dp="${path#./}"
    ext="${dp##*.}"
    [ "$ext" = "$dp" ] && ext=""
    content=$(cat "$path" 2>/dev/null)
    printf -v block '\n`%s`:\n```%s\n%s\n```\n' "$dp" "$ext" "$content"
    prompt+="$block"
  done

  if [ "$hash_secrets" -eq 1 ]; then
    result=$(
      printf "%s" "$prompt" | awk -v salt="$(od -vAn -N8 -tx1 </dev/urandom 2>/dev/null | tr -d ' \n')" '
        BEGIN {
          L2 = log(2)
          for (i = 0; i < 256; i++) {
            _ord[sprintf("%c", i)] = i
          }
        }
        function djb2(s, seed,    h, j) {
          h = 5381 + seed
          for (j = 1; j <= length(s); j++) {
            h = (h * 33 + _ord[substr(s, j, 1)]) % 2147483647
          }
          return h
        }
        function make_hash(s,    hex, sd) {
          hex = "hash:"
          for (sd = 0; length(hex) < length(s); sd++) {
            hex = hex sprintf("%08x", djb2(salt s, sd))
          }
          return substr(hex, 1, length(s))
        }
        function safe(w,    lw) {
          lw = tolower(w)
          if (w ~ /^[a-z]+$/ || w ~ /^[A-Z]+$/)                          return 1
          if (w ~ /^[a-zA-Z]+$/ && w !~ /[A-Z][A-Z][A-Z]/)               return 1
          if (w ~ /^[a-zA-Z_]+$/ && w ~ /_/)                             return 1
          if (w ~ /^\//)                                                 return 1
          if (lw ~ /\.(com|org|net|io|dev|[jt]s|py|go|rs|sh|md)$/)       return 1
          if (lw ~ /\.(txt|json|ya?ml|toml|conf|cfg|ini|xml|html|css)$/) return 1
          return 0
        }
        function pool(w, len,    j, ch, lo, up, dg, sp) {
          for (j = 1; j <= len; j++) {
            ch = substr(w, j, 1)
            if      (ch ~ /[a-z]/) lo = 1
            else if (ch ~ /[A-Z]/) up = 1
            else if (ch ~ /[0-9]/) dg = 1
            else                   sp = 1
          }
          if (w ~ /^[A-Fa-f0-9-]+$/)  return 16
          if (!up && !sp && lo && dg) return 36
          if (!lo && !sp && up && dg) return 36
          if (lo && up && dg && !sp)  return 62
          if (sp)                     return 64
          if (lo && up)               return 52
          return 64
        }
        function entropy(w, len,    j, ct, x, e, p) {
          split("", ct)
          for (j = 1; j <= len; j++) {
            ct[substr(w, j, 1)]++
          }
          e = 0
          for (x in ct) {
            p = ct[x] / len
            e -= p * log(p) / L2
          }
          return e
        }
        function transitions(w, len,    j, ch, cl, pv, tr, has, cnt, nc, x) {
          split("", has); split("", cnt); tr = 0; pv = 0
          for (j = 1; j <= len; j++) {
            ch = substr(w, j, 1)
            cl = (ch ~ /[a-z]/) ? 1 : (ch ~ /[A-Z]/) ? 2 : (ch ~ /[0-9]/) ? 3 : 4
            has[cl] = 1; cnt[cl]++
            if (j > 1 && cl != pv) tr++
            pv = cl
          }
          nc = 0
          for (x in has) {
            if (cnt[x] >= 2) nc++
          }
          if (nc >= 3 && tr / (len - 1) >= 0.45) return 1
          if (nc >= 2 && tr / (len - 1) >= 0.70) return 1
          return 0
        }
        function check(w,    len, p, thr) {
          len = length(w)
          if (len < 8 || w in seen) return
          seen[w] = 1
          gsub(/^[^a-zA-Z0-9]+/, "", w)
          gsub(/[^a-zA-Z0-9+\/=_-]+$/, "", w)
          len = length(w)
          if (len < 8 || safe(w)) return
          if (len >= 16) {
            p = pool(w, len)
            thr = (p <= 16) ? 0.85 : (p <= 36) ? 0.70 : 0.75
            if (entropy(w, len) / (log(p) / L2) >= thr) {
              repl[w] = make_hash(w)
              nsec++
            }
          } else if (transitions(w, len)) {
            repl[w] = make_hash(w)
            nsec++
          }
        }
        {
          lines[NR] = $0
          n = split($0, tok, /[[:space:]"'"'"'"`.:;,@(){}\[\]<>|!#$%^&*~\\]+/)
          for (i = 1; i <= n; i++) {
            if (length(tok[i]) < 8) continue
            eq = index(tok[i], "=")
            if (eq > 1 && eq < length(tok[i])) {
              lhs = substr(tok[i], 1, eq - 1)
              if (lhs ~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
                check(substr(tok[i], eq + 1))
                continue
              }
            }
            check(tok[i])
          }
        }
        END {
          if (nsec) printf "Hashed %d secrets\n", nsec > "/dev/stderr"
          for (i = 1; i <= NR; i++) {
            line = lines[i]
            for (s in repl) {
              p = 1
              while ((idx = index(substr(line, p), s)) > 0) {
                p = p + idx - 1
                line = substr(line, 1, p - 1) repl[s] substr(line, p + length(s))
                p += length(repl[s])
              }
            }
            print line
          }
        }
      '
    )
  else
    result="$prompt"
  fi

  if [ -t 1 ]; then
    if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy &>/dev/null; then
      copy_cmd="wl-copy"
    elif [ -n "${DISPLAY:-}" ] && command -v xclip &>/dev/null; then
      copy_cmd="xclip -selection clipboard"
    elif [ -n "${DISPLAY:-}" ] && command -v xsel &>/dev/null; then
      copy_cmd="xsel --clipboard --input"
    elif command -v pbcopy &>/dev/null; then
      copy_cmd="pbcopy"
    fi
  fi

  if [ -n "$copy_cmd" ]; then
    printf "%s" "$result" | $copy_cmd
    echo "Copied $(wc -l <<< "$result") lines (via $copy_cmd)"
  else
    printf "%s\n" "$result"
  fi
}

alias p2f='prompt2file'
prompt2file() {
  unset code filename filenames overwrite is_markdown
  local input_file="$1"
  local temp_file=""

  if [ -z "$input_file" ]; then
    temp_file=$(mktemp)
    ${EDITOR:-nano} "$temp_file"
    input_file="$temp_file"
  fi

  if [ ! -f "$input_file" ]; then
    return 1
  fi

  mapfile -t lines < "$input_file"
  count="${#lines[@]}"

  p2f_write() {
    [ -z "$filename" ] && return 0

    local final_code="$code"
    if [[ "${is_markdown:-}" == true ]]; then
      final_code="${code%\`\`\`*}"
    fi

    echo -n "> $filename"
    local do_write=true
    if [ -f "$filename" ]; then
      if [ "$overwrite" != 'all' ]; then
        read -p $' - ow? \e[s' -N1 answer
        if [ "$answer" == a ]; then
          overwrite='all'
          echo
        elif [ "$answer" != y ]; then
          echo -n $'\e[un\n'
          do_write=false
        else echo; fi
      else
        echo ' - ow'
      fi
    else echo " - ok"; fi

    if ! "$do_write"; then
      return 1
    fi

    filenames+=("$filename")
    if [ -n "${filename//[^\/]}" ] && [ "${filename:0:1}" != '/' ]; then
      mkdir -p "${filename%/*}"
    fi
    printf '%s' "$final_code" > "$filename"
    return 0
  }

  for ((i=0; i < count; i++)); do
    line="${lines[i]}"
    next_line="${lines[i+1]:-}"

    if [[
      "$line" =~ ^[\t#\*\ ]*\`([^\`]+)\`[\t\*\ :]*$ &&
      -n "${line//[^a-zA-Z0-9]}"
    ]]; then
      local potential_filename="${BASH_REMATCH[1]}"
      if [[ "$next_line" =~ ^[\t\ ]*'```'([a-zA-Z]*)[\t\ ]*$ ]]; then
        p2f_write

        filename="$potential_filename"
        local lang="${BASH_REMATCH[1]:-}"
        unset code

        if [[
          "$filename" == *.md || "$filename" == "README" ||
          "$lang" == "md" || "$lang" == "markdown"
        ]]; then is_markdown=true; else is_markdown=false; fi

        i=$((i + 1))
        continue
      fi
    fi

    if [ -n "$filename" ]; then
      if [[
        "${is_markdown:-false}" == false &&
        "$line" =~ ^[\t\ ]*'```'[\t\ ]*$
      ]]; then
        p2f_write
        unset filename code is_markdown
      else
        code+="$line"$'\n'
      fi
    fi
  done

  p2f_write

  [ -n "$temp_file" ] && rm -f "$temp_file"

  [ -z "$filenames" ] && echo 'No files found' && return 1
  while [ -n "$2" ]; do
    eval "$2" "${filenames[@]}"
    shift
  done
  return 0
}

###########
# ANDROID #
###########

check_adb() {
  if ! adb devices | grep -qE $'^[0-9a-f]{8,}\t+device$'; then
    error "No ADB device detected"
    return 1
  fi
}

adbsync() {
  local out="$1"
  local jobs="${2:-4}"

  [ "${out::1}" = '/' ] && \
  echo 'Please only use relative paths' && return 1
  while [ "${out: -1}" = '/' ]; do out="${out%/}"; done
  [ -z "$out" ] && echo "Usage: adbsync <folder> [jobs]" && return 1

  check_adb || return 1
  mkdir -p "$out"
  local tmp=$(mktemp -d)

  info "Generating file lists..."
  find "$out" -type f | sed "s:^$out/::" | sort -u > "$tmp/local"
  adb shell find /sdcard/ -type f | sed "s:^/sdcard/::" |
    sort -u > "$tmp/android"

  if [ ! -s "$tmp/android" ]; then
    error "Failed to retrieve files"
    rm -f "$tmp/android" "$tmp/local"
    return 1
  fi

  comm -23 "$tmp/android" "$tmp/local" > "$tmp/to_pull"
  comm -13 "$tmp/android" "$tmp/local" > "$tmp/to_delete"
  rm -f "$tmp/android" "$tmp/local" pull_errors.txt

  info "Files to pull: $(wc -l < $tmp/to_pull)"
  xargs -d '\n' -r -P "$jobs" -n 1 bash -c '
    input="/sdcard/$2"
    output="$1/$2"
    outdir="$(dirname "$output")"
    [ ! -d "$outdir" ] && mkdir -p "$outdir"
    adb pull -a "$input" "$output" 2>/dev/null
    if [ "$?" = 0 ]; then
      echo -e "\033[35m${input::'"${COLUMNS:-80}"'}\033[0m"
    else
      echo -e "\033[31m$input\033[0m"
      flock -x pull_errors.txt echo "$input" >> pull_errors.txt
      rm -f "$output"
    fi
  ' bash "$out" < "$tmp/to_pull"

  info "Files to delete: $(wc -l < $tmp/to_delete)"
  sed "s:^:$out/:g" "$tmp/to_delete" | xargs -d '\n' -r rm -v --
  find "$out" -type d -empty -delete
  rm -df "$tmp/to_pull" "$tmp/to_delete" "$tmp/"
  info 'Sync finished.'
}

adbcheck() {
  local jobs=8
  local batch_size=64
  local out="$1"

  while [ "${out: -1}" = '/' ]; do out="${out%/}"; done
  [ -z "$out" ] && echo "Usage: adbcheck <folder>" && return 1

  check_adb || return 1
  info "Comparing hashes..."
  rm -f hash_mismatch.txt

  find "$out" -type f | sort -u | sed "s:^$out/::g" |
  xargs -d '\n' -r -P "$jobs" -n "$batch_size" bash -c '
    pc_files=() android_files=()
    for file in "${@:2}"; do
      pc_files+=("$1/$file")
      android_files+=("/sdcard/$file")
    done

    mapfile -t pc_hashes < <(md5sum "${pc_files[@]}")
    mapfile -t android_hashes < <(
      adb shell md5sum $(printf "%q " "${android_files[@]}")
    )

    unset to_log
    file_count="${#pc_files[@]}"
    for ((i=0; i < "$file_count"; i++)); do
      pc_hash="${pc_hashes[i]%% *}"
      pc_file="${pc_hashes[i]#*  }"
      android_hash="${android_hashes[i]%% *}"
      android_file="${android_hashes[i]#*  }"
      if [ "$pc_hash" = "$android_hash" ] && [ -n "$pc_hash" ]; then
        to_log="$pc_file"
      else
        rm -f "$pc_file"
        if adb pull -a "$android_file" "$pc_file" 2>/dev/null; then
          echo -e "\033[32m$pc_file\033[0m"
        else
          echo -e "\033[31m$pc_file\033[0m"
          flock -x hash_mismatch.txt echo "$pc_file" >> hash_mismatch.txt
        fi
      fi
    done

    [ -n "$to_log" ] && \
    echo -e "\033[35m${to_log::'"${COLUMNS:-80}"'}\033[0m"
  ' bash "$out"
  info 'Hash verification finished.'
}
