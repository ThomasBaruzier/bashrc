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

# cleaning
clean() (
  command -v python3 >/dev/null 2>&1 || {
    printf 'clean requires python3\n' >&2
    return 1
  }

  command python3 - "${DEVICE:-desktop}" "${sudo:-}" "$@" <<'PY'
import argparse
import bisect
import fnmatch
import json
import os
import re
import shlex
import shutil
import stat
import subprocess
import sys
import time
import traceback

if sys.version_info < (3, 8):
  sys.exit("clean requires Python 3.8+")

try:
  import tomllib
except ImportError:
  tomllib = None

# arguments
device, sudo = sys.argv[1:3]
parser = argparse.ArgumentParser(prog="clean")
parser.add_argument("-d", "--docker", action="store_true",
                    help="also prune local Docker objects, excluding volumes")
parser.add_argument("-p", "--projects", action="store_true",
                    help="also clean projects inactive for 30 days")
parser.add_argument("-n", "--dry-run", action="store_true",
                    help="preview without cleaning")
args = parser.parse_args(sys.argv[3:])

home = os.path.realpath(os.path.expanduser("~"))
priv = [sudo] if sudo and os.geteuid() and device != "phone" else []
errors = {"command": 0, "file": 0}
reported = set()
colored = sys.stdout.isatty() and "NO_COLOR" not in os.environ
started = time.time()
cutoff = started - 30 * 86400
interrupted = False
aborted = False

# output
def within(path, root):
  return path == root or path.startswith(root.rstrip("/") + "/")

def overlaps(left, right):
  return within(left, right) or within(right, left)

def display(value):
  if value == home:
    return "~"
  return "~" + value[len(home):] if value.startswith(home + "/") else value

def log(chip, action, value, reason=""):
  value = str(value)
  if action == "SKIP":
    key = (chip, value, reason)
    if key in reported:
      return
    reported.add(key)
  label = action
  if args.dry_run and action in ("RUN", "REMOVE"):
    label = "WOULD " + action
  code = {"SKIP": 34, "RUN": 32, "REMOVE": 31, "ERROR": 31}.get(action)
  if colored and code:
    label = f"\033[{code}m{label}\033[0m"
  suffix = f" ({reason})" if reason else ""
  print(f"{'[' + chip + ']':<9} {label}: {display(value)}{suffix}", flush=True)

def failure(chip, value, reason, kind="command"):
  errors[kind] += 1
  lines = str(reason).strip().splitlines()
  log(chip, "ERROR", value, lines[0] if lines else "operation failed")
  for line in lines[1:13]:
    print("          " + line, flush=True)
  if len(lines) > 13:
    print(f"          ... {len(lines) - 13} more diagnostic lines", flush=True)

def available(name):
  return shutil.which(name) is not None

# commands
class CommandError(Exception):
  def __init__(self, command, message):
    self.command = shlex.join(command)
    super().__init__(message)

def query(command, env=None, binary=False):
  options = {} if binary else {"text": True, "errors": "surrogateescape"}
  try:
    return subprocess.run(
      command, cwd=home, env=env, capture_output=True, **options
    )
  except OSError as exc:
    raise CommandError(command, str(exc)) from exc

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
    result = query(command)
    message = (result.stderr + result.stdout).strip()
    if result.returncode and not (
      empty_screen and "No Sockets found" in message
    ):
      failure(chip, shlex.join(command),
              f"exit {result.returncode}" + (f"\n{message}" if message else ""))
  except CommandError as exc:
    failure(chip, exc.command, exc)

def section(chip, function):
  try:
    function()
  except CommandError as exc:
    failure(chip, exc.command, exc)
  except OSError as exc:
    failure(chip, exc.filename or "filesystem operation", exc, "file")

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

# filesystem worker
shared = r'''
import fnmatch
import json
import os
import re
import stat
import sys

def inside(path, root):
  return path == root or path.startswith(root.rstrip("/") + "/")

def mount_table():
  result = {}
  with open("/proc/self/mountinfo") as stream:
    for line in stream:
      fields = line.split()
      separator = fields.index("-")
      def decode(value):
        return re.sub(r"\\([0-7]{3})",
          lambda match: chr(int(match[1], 8)), value)
      path = decode(fields[4])
      result[path] = {
        "id": fields[0],
        "dev": fields[2],
        "root": decode(fields[3]),
        "type": fields[separator + 1]
      }
  return result

def containing(path, table):
  roots = [root for root in table if inside(path, root)]
  return table[max(roots, key=len)] if roots else None

def remote(item):
  return item["type"] in {
    "nfs", "nfs4", "cifs", "smb3", "9p", "ceph", "afs", "autofs"
  } or item["type"].startswith("fuse")

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

def clean_files(cfg, emit):
  failed = set()

  def error(path, exc):
    if path not in failed:
      failed.add(path)
      emit("ERROR", path, str(exc))

  try:
    initial = mount_table()
  except OSError as exc:
    error("/proc/self/mountinfo", exc)
    return

  for job in cfg["jobs"]:
    root = job["path"]
    reason = invalid_root(root, cfg, initial)
    if reason:
      emit("SKIP", root, reason)
      continue

    try:
      identity = os.lstat(root)
    except FileNotFoundError:
      continue
    except OSError as exc:
      error(root, exc)
      continue

    excludes = cfg["preserve"] + job.get("exclude", [])
    threshold = cfg["now"] - job["days"] * 86400
    points = initial

    def excluded(path):
      if any(inside(path, parent) for parent in excludes):
        return True
      first = os.path.relpath(path, root).split(os.sep, 1)[0]
      return any(fnmatch.fnmatchcase(first, pattern)
                 for pattern in job.get("exclude_names", []))

    def eligible(path, info):
      stamp = info.st_mtime
      if job.get("access", True):
        stamp = max(stamp, info.st_atime)
      if job["days"] and stamp >= threshold:
        return False
      patterns = job.get("patterns", [])
      return not patterns or any(
        fnmatch.fnmatchcase(os.path.basename(path), pattern)
        for pattern in patterns
      )

    def plan(path, top=False):
      if excluded(path):
        return False, None
      if not top and path in points:
        emit("SKIP", path, "nested mount")
        return False, None

      try:
        info = os.lstat(path)
        mode = info.st_mode
        if stat.S_ISLNK(mode):
          good = not top and job.get("links", True) and eligible(path, info)
          return good, (path, False) if good else None
        if stat.S_ISREG(mode):
          good = eligible(path, info)
          return good, (path, False) if good else None
        if not stat.S_ISDIR(mode):
          return False, None

        with os.scandir(path) as stream:
          children = sorted(entry.path for entry in stream)

        if top and not children and job.get("keep", True):
          return False, None

        complete = True
        nodes = []
        for child in children:
          good, node = plan(child)
          complete = complete and good
          if node is not None:
            nodes.append(node)

        old = not job["days"] or info.st_mtime < threshold
        if complete and job.get("directories", True) and (children or old):
          return True, (path, top and job.get("keep", True))
        return False, nodes or None

      except FileNotFoundError:
        return False, None
      except OSError as exc:
        error(path, exc)
        return False, None

    def selections(node):
      if node is None:
        return
      if isinstance(node, tuple):
        yield node
      else:
        for child in node:
          yield from selections(child)

    def remove(path, keep=False):
      if excluded(path):
        return False
      if path != root and path in points:
        emit("SKIP", path, "nested mount")
        return False

      try:
        info = os.lstat(path)
        mode = info.st_mode
        if stat.S_ISREG(mode) or stat.S_ISLNK(mode):
          if stat.S_ISLNK(mode) and not job.get("links", True):
            return False
          if not eligible(path, info):
            emit("SKIP", path, "no longer eligible")
            return False
          os.unlink(path)
          return True
        if not stat.S_ISDIR(mode):
          return False
        if os.path.realpath(path) != path:
          emit("SKIP", path, "symlinked directory")
          return False

        with os.scandir(path) as stream:
          children = [entry.path for entry in stream]

        if not children and job["days"] and info.st_mtime >= threshold:
          return False

        complete = True
        for child in children:
          if not remove(child):
            complete = False
        if complete and not keep:
          os.rmdir(path)
        return complete

      except FileNotFoundError:
        return True
      except OSError as exc:
        error(path, exc)
        return False

    if excluded(root):
      emit("SKIP", root, "protected path")
      continue

    _, selection = plan(root, True)

    if not cfg["dry"]:
      try:
        points = mount_table()
        current = os.lstat(root)
      except FileNotFoundError:
        continue
      except OSError as exc:
        error(root, exc)
        continue

      relevant = {
        path for path in set(initial) | set(points)
        if inside(root, path) or inside(path, root)
      }
      if any(initial.get(path) != points.get(path) for path in relevant):
        emit("SKIP", root, "mount layout changed")
        continue
      if (identity.st_dev, identity.st_ino) != (
        current.st_dev, current.st_ino
      ) or os.path.realpath(root) != root:
        emit("SKIP", root, "cleanup root changed")
        continue

    for path, keep in selections(selection):
      emit("REMOVE", path, "contents" if keep else "")
      if not cfg["dry"]:
        remove(path, keep)
'''

namespace = {}
exec(shared, namespace)
mount_table = namespace["mount_table"]
containing = namespace["containing"]
remote = namespace["remote"]
invalid_root = namespace["invalid_root"]
clean_files = namespace["clean_files"]

# configured paths
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
      failure("CACHE", exc.command, exc)

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
      gopaths = [
        os.path.normpath(path)
        for path in values["GOPATH"].split(os.pathsep)
        if os.path.isabs(path)
      ]
      gobin = os.path.normpath(values["GOBIN"]) \
        if os.path.isabs(values["GOBIN"]) else ""
      go_caches = [
        os.path.normpath(values[name]) if os.path.isabs(values[name])
        else values[name]
        for name in ("GOCACHE", "GOMODCACHE")
      ]
    except CommandError as exc:
      failure("CACHE", exc.command, exc)
    except ValueError as exc:
      failure("CACHE", shlex.join(command), exc)

  preserve = [
    root + "/" + name
    for root in cache_roots
    for name in (
      "torch", "torch_extensions", "huggingface", "jellyfin",
      "pqcrypt", "docker", "buildx", "buildkit", "containers"
    )
  ]
  preserve += [
    docker_config, home + "/.docker",
    data + "/nano", home + "/.Xauthority",
    home + "/.ICEauthority", home + "/.pulse-cookie"
  ]
  if gobin:
    preserve.append(gobin)
  for name in (
    "XAUTHORITY", "ICEAUTHORITY", "XDG_RUNTIME_DIR",
    "HF_HOME", "TORCH_HOME", "TORCH_EXTENSIONS_DIR"
  ):
    value = os.environ.get(name, "")
    if os.path.isabs(value):
      preserve.append(os.path.normpath(value))

  installations = list(dict.fromkeys([
    config, data, state, cargo, rustup, gradle, bun, esp, nvm, npm,
    docker_config, home + "/.docker", home + "/.nvm", home + "/.npm",
    home + "/.ssh", home + "/.gnupg", home + "/.mozilla",
    home + "/.steam", home + "/.android", home + "/.codex",
    home + "/.gemini", home + "/.claude", home + "/.pi",
    home + "/.triton", home + "/.nv", home + "/.vscode",
    home + "/.vscode-oss", home + "/.vscode-oss-shared",
    home + "/.vscode-server", home + "/.vscode-server-insiders",
    home + "/.cursor", home + "/.cursor-server"
  ] + gopaths))

  base_cfg = {
    "home": home, "preserve": preserve, "installations": installations,
    "now": started, "dry": args.dry_run
  }

# space
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
      "print(json.dumps([s.f_fsid,s.f_bavail*s.f_frsize]))",
      path
    ]
    output = checked(command)
    try:
      values = json.loads(output)
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
    key = (item["type"], identity)
    space.setdefault(key, (root, available_bytes))
  except CommandError as exc:
    space_failed.add(root)
    failure("SYSTEM", exc.command, exc)
  except OSError as exc:
    space_failed.add(root)
    failure("SYSTEM", root, f"cannot measure free space: {exc}", "file")

# filesystem jobs
def job(path, days=0, **options):
  return dict(path=os.path.abspath(path), days=days, **options)

def stop_worker(process):
  if process.poll() is not None:
    return
  try:
    process.terminate()
  except ProcessLookupError:
    return
  try:
    process.wait(timeout=3)
  except subprocess.TimeoutExpired:
    try:
      process.kill()
    except ProcessLookupError:
      pass
    process.wait()

def files(chip, jobs, elevated=False):
  unique = {}
  current = mount_table()

  for item in jobs:
    path = item["path"]
    reason = invalid_root(path, base_cfg, current)
    if reason:
      log(chip, "SKIP", path, reason)
      continue
    try:
      os.lstat(path)
    except FileNotFoundError:
      continue
    except PermissionError:
      pass
    except OSError as exc:
      failure(chip, path, exc, "file")
      continue

    if path in unique and unique[path] != item:
      raise ValueError(f"conflicting cleanup rules: {path}")
    unique[path] = dict(item)
    remember(path, current)

  selected = sorted(unique.values(), key=lambda item: item["path"])
  for item in selected:
    item["exclude"] = list(item.get("exclude", [])) + [
      other["path"] for other in selected
      if other is not item and within(other["path"], item["path"])
    ]

  if not selected:
    return

  cfg = dict(base_cfg, jobs=selected)

  def emit(action, path, reason=""):
    if action == "ERROR":
      failure(chip, path, reason, "file")
    else:
      log(chip, action, path, reason)

  if not elevated or not priv:
    clean_files(cfg, emit)
    return

  driver = '''
try:
  clean_files(json.load(sys.stdin),
    lambda action, path, reason="":
      print(json.dumps([action, path, reason]), flush=True))
except KeyboardInterrupt:
  sys.exit(130)
'''
  command = priv + [sys.executable, "-I", "-c", shared + driver]
  try:
    process = subprocess.Popen(
      command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True
    )
  except OSError as exc:
    raise CommandError(priv + [sys.executable], str(exc)) from exc

  try:
    try:
      process.stdin.write(json.dumps(cfg))
      process.stdin.close()
    except BrokenPipeError:
      pass
    for line in process.stdout:
      emit(*json.loads(line))
    status = process.wait()
  finally:
    stop_worker(process)
    if process.stdin and not process.stdin.closed:
      try:
        process.stdin.close()
      except BrokenPipeError:
        pass
    if process.stdout:
      process.stdout.close()

  if status in (130, -2):
    raise KeyboardInterrupt
  if status:
    failure(chip, "filesystem worker", f"exit {status}")

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
  home_fs = containing(home, mounts)
  if not home_fs or remote(home_fs):
    log("PROJECT", "SKIP", home, "unknown or network filesystem")
    return

  blocked = {
    path: reason
    for path, item in mounts.items()
    if path != home and within(path, home)
    for reason in [storage_reason(path, item)]
    if reason
  }
  excluded = installations + cache_roots + preserve + [
    uv_cache, home + "/bin", home + "/.local/bin", home + "/.local/lib"
  ]
  excluded += [path for path in go_caches if os.path.isabs(path)]

  if any(within(home, root) for root in excluded):
    log("PROJECT", "SKIP", home, "configured installation/cache root covers home")
    return

  active = set()
  for name in os.listdir("/proc"):
    if not name.isdigit():
      continue
    for leaf in ("cwd", "exe"):
      try:
        path = os.readlink(f"/proc/{name}/{leaf}")
        if path.endswith(" (deleted)"):
          path = path[:-10]
        if os.path.isabs(path):
          active.add(path)
      except OSError:
        pass

  value = os.environ.get("VIRTUAL_ENV", "")
  if os.path.isabs(value):
    active.add(os.path.normpath(value))

  def omitted(path):
    return any(within(path, root) for root in excluded)

  def stamp(path):
    info = os.lstat(path)
    return max(info.st_mtime, info.st_ctime)

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

  # metadata
  def metadata_info(path, optional=False, directory=False, either=False,
                    ancestor=False):
    path = os.path.abspath(path)
    item = containing(path, mounts)
    if not item or remote(item):
      raise ValueError(f"metadata on unsupported storage: {display(path)}")
    if any(within(path, root) for root in blocked):
      raise ValueError(f"metadata on excluded storage: {display(path)}")
    if not ancestor and item["id"] != home_fs["id"] and not within(path, home):
      root = max((root for root in mounts if within(path, root)), key=len)
      if storage_reason(root, item):
        raise ValueError(f"metadata on excluded storage: {display(path)}")

    current = "/"
    info = None
    parts = path.strip("/").split("/") if path != "/" else []
    for index, part in enumerate(parts):
      current = os.path.join(current, part)
      try:
        info = os.lstat(current)
      except FileNotFoundError:
        if optional:
          return None
        raise
      if stat.S_ISLNK(info.st_mode):
        raise ValueError(f"symlinked metadata: {display(current)}")
      if index < len(parts) - 1 and not stat.S_ISDIR(info.st_mode):
        raise ValueError(f"invalid metadata path: {display(current)}")

    if info is None:
      info = os.lstat("/")
    regular = stat.S_ISREG(info.st_mode)
    is_directory = stat.S_ISDIR(info.st_mode)
    valid = (regular or is_directory) if either else (
      is_directory if directory else regular
    )
    if not valid:
      raise ValueError(f"unsupported metadata type: {display(path)}")
    return info

  def read_text(path, ancestor=False):
    metadata_info(path, ancestor=ancestor)
    with open(path, encoding="utf-8") as stream:
      return stream.read()

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

  toml_cache = {}

  def read_toml(path, ancestor=False):
    if not tomllib:
      raise ValueError("Cargo inspection requires Python 3.11+")
    if path not in toml_cache:
      toml_cache[path] = tomllib.loads(read_text(path, ancestor=ancestor))
    return mapping(toml_cache[path], display(path))

  # workspace layout
  def layout(directory, group, kind, names, members):
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
        if metadata_info(path, optional=True, ancestor=ancestor) is None:
          continue
        parsed = read_toml(path, ancestor=ancestor)
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
          lambda match: match[1] if match[1] is not None else " ",
          text
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
  repositories = {}
  tracking = {}

  def git_marker(directory):
    marker = directory.rstrip("/") + "/.git"
    ancestor = within(home, directory)
    info = metadata_info(
      marker, optional=True, either=True, ancestor=ancestor
    )
    if info is None:
      return None
    if stat.S_ISDIR(info.st_mode):
      return marker
    text = read_text(marker, ancestor=ancestor).strip()
    if not text.startswith("gitdir: "):
      raise ValueError(f"unrecognized Git directory: {display(marker)}")
    target = os.path.normpath(os.path.join(directory, text[8:]))
    metadata_info(target, directory=True)
    return target

  def repository_for(directory):
    visited = []
    current = directory
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

  def git_recent(repository):
    if repository is None:
      return False
    gitdir = repository[1]
    for leaf in ("HEAD", "index", "FETCH_HEAD", "ORIG_HEAD",
                 "packed-refs", "logs/HEAD"):
      info = metadata_info(gitdir + "/" + leaf, optional=True)
      if info is not None and max(info.st_mtime, info.st_ctime) >= cutoff:
        return True
    common = gitdir + "/commondir"
    if metadata_info(common, optional=True) is not None:
      target = os.path.normpath(os.path.join(gitdir, read_text(common).strip()))
      metadata_info(target, directory=True)
    return False

  git_env = dict(os.environ, GIT_OPTIONAL_LOCKS="0", LC_ALL="C")
  for name in (
    "GIT_DIR", "GIT_WORK_TREE", "GIT_COMMON_DIR", "GIT_INDEX_FILE",
    "GIT_CEILING_DIRECTORIES"
  ):
    git_env.pop(name, None)

  def tracked(path, repository):
    if repository is None:
      return ""
    root = repository[0]
    if root not in tracking:
      if not available("git"):
        return "Git unavailable"
      result = query(
        ["git", "-C", root, "ls-files", "-z"], git_env, binary=True
      )
      tracking[root] = sorted(
        os.fsdecode(name) for name in result.stdout.split(b"\0") if name
      ) if result.returncode == 0 else None

    names = tracking[root]
    if names is None:
      return "cannot determine Git tracking"

    relative = os.path.relpath(path, root)
    index = bisect.bisect_left(names, relative)
    if index < len(names) and names[index] == relative:
      return "contains tracked files"

    prefix = relative + "/"
    index = bisect.bisect_left(names, prefix)
    if index < len(names) and names[index].startswith(prefix):
      return "contains tracked files"
    return ""

  # artifact discovery
  python_artifacts = {
    "__pycache__", ".pytest_cache", ".mypy_cache",
    ".ruff_cache", ".hypothesis", ".tox", ".nox"
  }
  node_artifacts = {
    "node_modules", ".next", ".nuxt", ".output",
    ".turbo", ".parcel-cache", ".svelte-kit"
  }

  def artifact_activity(root):
    if any(within(point, root) for point in mounts):
      return "artifact contains a mount"
    if any(within(path, root) for path in preserve):
      return "artifact contains protected data"

    pending = [root]
    while pending:
      directory = pending.pop()
      if stamp(directory) >= cutoff:
        return "activity within 30 days"
      with os.scandir(directory) as stream:
        for entry in stream:
          if entry.name == ".git":
            return "artifact contains a repository"
          if stamp(entry.path) >= cutoff:
            return "activity within 30 days"
          if entry.is_dir(follow_symlinks=False):
            pending.append(entry.path)
    return ""

  def inspect(group):
    if any(within(path, group) for path in active):
      return [], "currently in use"
    if stamp(group) >= cutoff:
      return [], "activity within 30 days"

    inherited = repository_for(group)
    candidates = []
    metadata = []
    members = []
    symlinks = []
    skipped = []
    visited = set()
    pending = [(group, inherited, False, False)]

    while pending:
      directory, repository, node_project, python_project = pending.pop()
      visited.add(directory)
      if stamp(directory) >= cutoff:
        return [], "activity within 30 days"

      with os.scandir(directory) as stream:
        entries = sorted(stream, key=lambda entry: entry.name)
      names = {entry.name for entry in entries}
      eligible_entries = []

      for entry in entries:
        if entry.name == ".git":
          continue
        if entry.path in blocked:
          log("PROJECT", "SKIP", entry.path, blocked[entry.path])
          skipped.append(entry.path)
          continue
        if omitted(entry.path):
          skipped.append(entry.path)
          continue
        if stamp(entry.path) >= cutoff:
          return [], "activity within 30 days"
        eligible_entries.append(entry)

      if ".git" in names:
        marker = git_marker(directory)
        if marker is None:
          raise ValueError("Git metadata disappeared during inspection")
        repository = (directory, marker)
        repositories[directory] = repository
        if git_recent(repository):
          return [], "activity within 30 days"

      kind = kinds(names)
      node_project = node_project or kind["node"]
      python_project = python_project or kind["python"]
      if any(kind.values()) or names & {
        "pnpm-workspace.yaml", "pnpm-workspace.yml"
      }:
        metadata.append((directory, kind, names))

      for entry in eligible_entries:
        path, name = entry.path, entry.name
        if entry.is_symlink():
          symlinks.append(path)
          continue
        if not entry.is_dir(follow_symlinks=False):
          if python_project and name.endswith((".pyc", ".pyo")) \
              and entry.is_file(follow_symlinks=False):
            candidates.append((path, repository))
          continue

        artifact = (
          python_project and name in python_artifacts
          or node_project and name in node_artifacts
          or node_project and os.path.basename(directory) == ".angular"
            and name == "cache"
          or name == "target" and (kind["rust"] or kind["maven"])
          or kind["gradle"] and name in (".gradle", "build")
          or kind["dotnet"] and name in ("bin", "obj")
        )

        if not artifact and name in (".venv", "venv"):
          artifact = metadata_info(
            path + "/pyvenv.cfg", optional=True
          ) is not None

        if not artifact and (kind["cmake"] or kind["make"]) and (
          name in ("build", "_build") or name.startswith("cmake-build-")
        ):
          artifact = (
            metadata_info(path + "/CMakeCache.txt", optional=True) is not None
            and metadata_info(
              path + "/CMakeFiles", optional=True, directory=True
            ) is not None
          )

        if artifact:
          reason = artifact_activity(path)
          if reason:
            return [], reason
          candidates.append((path, repository))
        else:
          pending.append((path, repository, node_project, python_project))

    if not candidates:
      return [], ""
    if skipped:
      return [], "incomplete project activity scan"

    for directory, kind, names in metadata:
      reason = layout(directory, group, kind, names, members)
      if reason:
        return [], reason

    for member in members:
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

  pending = [home]
  while pending:
    directory = pending.pop()
    try:
      with os.scandir(directory) as stream:
        entries = sorted(stream, key=lambda entry: entry.name)
      names = {entry.name for entry in entries}

      if directory != home and (
        ".git" in names or any(kinds(names).values())
        or names & {"pnpm-workspace.yaml", "pnpm-workspace.yml"}
      ):
        candidates, reason = inspect(directory)
        if reason:
          log("PROJECT", "SKIP", directory, reason)
          continue

        group_jobs = []
        for path, repository in candidates:
          reason = tracked(path, repository)
          if reason:
            log("PROJECT", "SKIP", path, reason)
          else:
            group_jobs.append(job(path, keep=False))

        if group_jobs:
          if mount_table() != mounts:
            log("PROJECT", "SKIP", "remaining projects", "mount layout changed")
            return
          files("PROJECT", group_jobs)
        continue

      for entry in entries:
        if entry.path in blocked:
          log("PROJECT", "SKIP", entry.path, blocked[entry.path])
          continue
        if omitted(entry.path) or entry.name in {
          ".git", "node_modules", ".venv", "venv"
        }:
          continue
        if entry.is_dir(follow_symlinks=False):
          pending.append(entry.path)

    except ValueError as exc:
      log("PROJECT", "SKIP", directory, str(exc))
    except CommandError as exc:
      failure("PROJECT", exc.command, exc)
    except OSError as exc:
      failure("PROJECT", exc.filename or directory, exc, "file")

# user caches
def user_caches():
  external = []
  if available("uv"):
    external.append((
      [uv_cache], ["uv", "--cache-dir", uv_cache, "cache", "clean"]
    ))
  if go_caches:
    external.append((
      go_caches,
      [
        "env", "GOTOOLCHAIN=local",
        "GOCACHE=" + go_caches[0], "GOMODCACHE=" + go_caches[1],
        "go", "clean", "-cache", "-testcache", "-modcache"
      ]
    ))

  accepted = []
  owned = []
  rejected = []
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
      rejected.extend(
        os.path.normpath(path) for path in paths if os.path.isabs(path)
      )
    else:
      accepted.append((paths, command))
      owned.extend(paths)

  jobs = [
    job(root, 1, exclude=installations + owned + [
      path for path in rejected if path != root and within(path, root)
    ])
    for root in cache_roots if root not in rejected
  ]
  for root in cache_roots:
    if root in rejected:
      log("CACHE", "SKIP", root, "external cache cleanup rejected")

  targets = [
    cargo + "/git", cargo + "/registry",
    rustup + "/downloads", rustup + "/tmp",
    npm + "/_cacache", npm + "/_logs", npm + "/_npx",
    bun + "/install/cache",
    gradle + "/caches", gradle + "/wrapper/dists",
    esp + "/dist", nvm + "/.cache", home + "/.nvm/.cache",
    home + "/.nv/ComputeCache", home + "/.nv/GLCache",
    setting("TRITON_CACHE_DIR", home + "/.triton/cache"),
    data + "/Trash/files", data + "/Trash/info",
    home + "/.copilot/logs",
    home + "/.vscode-server/data/logs",
    home + "/.vscode-server-insiders/data/logs"
  ]
  jobs += [job(path) for path in dict.fromkeys(targets)]
  jobs.append(job(gradle + "/daemon", patterns=["daemon-*.out.log"],
                  directories=False, links=False))

  editors = ("Code", "Code - OSS", "VSCodium", "Cursor", "Antigravity")
  applications = editors + ("Signal", "Claude", "heroic")
  leaves = (
    "Cache", "Code Cache", "GPUCache", "CachedData",
    "CachedExtensionVSIXs", "DawnCache",
    "DawnWebGPUCache", "DawnGraphiteCache"
  )
  jobs += [
    job(f"{config}/{app}/{leaf}", 1)
    for app in applications for leaf in leaves
  ]
  jobs += [job(f"{config}/{editor}/logs", 1) for editor in editors]

  for browser in ("chromium", "google-chrome"):
    root = config + "/" + browser
    if invalid_root(root, base_cfg, current):
      continue
    try:
      with os.scandir(root) as stream:
        for entry in stream:
          if entry.path in current:
            continue
          if (entry.name == "Default" or entry.name.startswith("Profile ")) \
              and entry.is_dir(follow_symlinks=False):
            jobs += [
              job(entry.path + "/" + leaf, 1)
              for leaf in ("Cache", "Code Cache", "GPUCache")
            ]
    except FileNotFoundError:
      pass

  small = [
    home + "/" + name for name in (
      ".lesshst", ".viminfo", ".python_history", ".node_repl_history",
      ".gnuplot_history", ".sudo_as_admin_successful", ".wget-hsts"
    )
  ]
  small += [
    home + "/.ssh/known_hosts.old",
    state + "/lesshst", state + "/gnuplot_history",
    data + "/recently-used.xbel",
    npm + "/_update-notifier-last-checked"
  ]
  jobs += [job(path) for path in small]

  for item in jobs:
    item["exclude"] = list(item.get("exclude", [])) + owned

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
    roots = [(prefix + "/tmp", 1)] if os.path.isabs(prefix) else []
  else:
    roots = [("/tmp", 1), ("/var/tmp", 7)]

  names = [
    ".X11-unix", ".X[0-9]*-lock", ".ICE-unix", ".XIM-unix", ".font-unix",
    "ssh-*", "gpg-*", "systemd*", "tmux-*", "screen-*", "pulse-*",
    "dbus-*", "xauth_*", "serverauth.*", "*.lock"
  ]
  files("TEMP", [
    job(path, days, links=False, exclude_names=names)
    for path, days in roots
  ], elevated=True)

# logs
def logs():
  if device in ("phone", "chroot"):
    return
  files("LOG", [
    job("/var/log", 7, access=False, directories=False, links=False,
        exclude=["/var/log/journal", "/var/log/audit"],
        patterns=["*.gz", "*.xz", "*.zst", "*.[0-9]", "*.[0-9][0-9]", "*.old"]),
    job("/var/lib/systemd/coredump", patterns=["core.*"],
        directories=False, links=False),
    job("/var/crash", directories=False, links=False)
  ], elevated=True)

  if available("journalctl") and os.path.isdir("/run/systemd/system"):
    remember("/var/log/journal")
    run("JOURNAL", priv + [
      "journalctl", "--rotate", "--vacuum-size=50M", "--vacuum-time=7d"
    ])

# docker
def docker():
  if not available("docker"):
    log("DOCKER", "SKIP", "docker", "not installed")
    return

  user_command = ["docker", "--config", docker_config]
  requested_context = os.environ.get("DOCKER_CONTEXT", "")
  requested_host = os.environ.get("DOCKER_HOST", "")
  context = ""

  if requested_context:
    context = requested_context
  elif not requested_host:
    context = checked(user_command + ["context", "show"])

  if context:
    endpoint = checked(user_command + [
      "context", "inspect", context,
      "--format", "{{.Endpoints.docker.Host}}"
    ])
    selection = ["--context", context]
  else:
    endpoint = requested_host
    selection = ["--host", endpoint]

  if not endpoint.startswith("unix://"):
    log("DOCKER", "SKIP", endpoint, "remote or unsupported Docker endpoint")
    return

  command = priv + [
    "env", "-u", "DOCKER_HOST", "-u", "DOCKER_CONTEXT",
    "LC_ALL=C", "NO_COLOR=1",
    "docker", "--config", docker_config
  ] + selection

  info_command = command + ["info", "--format", "{{.DockerRootDir}}"]
  root = checked(info_command)
  if not os.path.isabs(root) or "\n" in root:
    failure("DOCKER", shlex.join(info_command), "invalid DockerRootDir")
    return

  remember(root)
  remember("/var/lib/containerd")

  # builder inspection
  builder_name = ""
  builder_reason = ""
  if query(command + ["buildx", "version"]).returncode == 0:
    inspect_command = command + ["buildx", "inspect"]
    result = query(inspect_command)
    if result.returncode:
      failure("DOCKER", shlex.join(inspect_command),
              result.stderr.strip() or result.stdout.strip()
              or f"exit {result.returncode}")
    else:
      header = {}
      nodes = []
      in_nodes = False
      node_indent = None
      for line in result.stdout.splitlines():
        line = line.expandtabs()
        text = line.strip()
        indent = len(line) - len(line.lstrip())
        if text == "Nodes:":
          in_nodes = True
          continue
        match = re.match(r"^(Name|Driver|Endpoint|Status):\s*(.*)$", text)
        if not match:
          continue
        key, value = match.groups()
        if not in_nodes:
          header[key] = value
          continue
        if node_indent is None:
          if key != "Name":
            continue
          node_indent = indent
        if indent != node_indent:
          continue
        if key == "Name":
          nodes.append({"Name": value})
        elif nodes:
          nodes[-1][key] = value

      name = header.get("Name", "")
      driver = header.get("Driver", "")
      allowed = {endpoint}
      if context:
        allowed.add(context)

      if not name or not driver:
        builder_reason = "unrecognized Buildx inspection output"
      elif driver == "docker":
        pass
      elif driver != "docker-container" or not nodes:
        builder_reason = "builder locality not established"
      elif any(node.get("Endpoint") not in allowed for node in nodes):
        builder_reason = "builder uses another endpoint"
      elif any(node.get("Status", "").lower() != "running" for node in nodes):
        builder_reason = "builder not running"
      else:
        builder_name = name

      if builder_reason:
        log("DOCKER", "SKIP", name or "selected Buildx builder", builder_reason)

  run("DOCKER", command + ["system", "prune", "-af"],
      f"{context or 'explicit endpoint'}; {endpoint}")
  run("DOCKER", command + ["builder", "prune", "-af"])

  if builder_name:
    run("DOCKER", command + [
      "buildx", "--builder", builder_name, "prune", "-af"
    ])

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
                "no valid absolute cache directories returned")
      else:
        suffixes = (
          "", ".zst", ".xz", ".gz", ".bz2",
          ".lrz", ".lzo", ".Z", ".lz4", ".lz"
        )
        patterns = [
          "*.pkg.tar" + suffix + signature
          for suffix in suffixes
          for signature in ("", ".sig")
        ]
        files("PACKAGE", [
          job(path, patterns=patterns, directories=False, links=False)
          for path in dict.fromkeys(paths)
        ], elevated=True)
    else:
      failure("PACKAGE", "package cache cleanup",
              "neither paccache nor pacman-conf is available")

    result = query(["pacman", "-Qdtq"])
    if result.returncode == 0 and result.stdout.strip():
      run("PACKAGE", priv + [
        "pacman", "-Rns", "--noconfirm", *result.stdout.split()
      ])
    elif result.stderr.strip():
      failure("PACKAGE", "pacman -Qdtq", result.stderr.strip())

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
    run("PACKAGE", priv + [
      "flatpak", "uninstall", "--system", "--unused", "-y"
    ])

# execution
try:
  resolve_paths()
  remember("/")
  remember(home)

  if args.projects:
    section("PROJECT", projects)
  section("CACHE", user_caches)
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
  print()
  log("SYSTEM", "SKIP", "remaining cleanup", "interrupted")
except CommandError as exc:
  aborted = True
  failure("SYSTEM", exc.command, exc)
except OSError as exc:
  aborted = True
  failure("SYSTEM", exc.filename or "initialization", exc, "file")
except Exception as exc:
  aborted = True
  failure("SYSTEM", "cleanup aborted", f"{type(exc).__name__}: {exc}")
  traceback.print_exc()

# summary
freed = 0
space_partial = bool(space_failed)

if not args.dry_run:
  for key, (path, before) in space.items():
    try:
      identity, after = space_sample(path)
      if identity != key[1]:
        space_partial = True
        failure("SYSTEM", path, "filesystem identity changed", "file")
      else:
        freed += after - before
    except CommandError as exc:
      space_partial = True
      failure("SYSTEM", exc.command, exc)
    except OSError as exc:
      space_partial = True
      failure("SYSTEM", path, f"cannot measure free space: {exc}", "file")
    except KeyboardInterrupt:
      interrupted = True
      space_partial = True
      break

def size(value):
  sign = "-" if value < 0 else ""
  value = abs(value)
  for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
    if value < 1024 or unit == "TiB":
      return sign + f"{value:.1f}".rstrip("0").rstrip(".") + unit
    value /= 1024

scopes = ["generic"]
if args.docker:
  scopes.append("docker")
if args.projects:
  scopes.append("project")

commands, paths = errors["command"], errors["file"]
suffix = " (interrupted)" if interrupted else " (aborted)" if aborted else ""
print()
print(("Would clean " if args.dry_run else "Cleaned ")
      + " + ".join(scopes) + " caches" + suffix)
print(f"Errors: {commands} command{'s' if commands != 1 else ''}"
      f" + {paths} file{'s' if paths != 1 else ''}")
print("Freed space: " + (
  "0B (dry run)" if args.dry_run else
  size(freed) + (" (partial)" if space_partial else "")
))
sys.exit(130 if interrupted else int(bool(commands or paths or aborted)))
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
