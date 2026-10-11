#
# ~/.bashrc
#

## INIT

# permissions
umask 077

# locale
if [[ -z ${LANG:-} && -r /etc/locale.conf ]]; then
  . /etc/locale.conf
  export LANG
fi

# interactive shell
[[ "$-" == *i* ]] || return

# beam cursor
printf '\e[6 q'

# zoxide
[ -f "$PREFIX/bin/zoxide" ] && alias cd='z' && eval "$(zoxide init bash)"

# status functions
unset -f error warn success info
error() { echo $'\033[31mERROR: '"$*"$'\033[0m' >&2; }
warn() { echo $'\033[33mWARNING: '"$*"$'\033[0m' >&2; }
success() { echo $'\033[32mSUCCESS: '"$*"$'\033[0m' >&2; }
info() { echo $'\033[34mINFO: '"$*"$'\033[0m' >&2; }

## HOST CONTEXT

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

## PRIVATE CONFIG

# bashrc home
bashrc_home="$HOME/.config/bashrc"
[ -d "$bashrc_home" ] || mkdir -p "$bashrc_home"

# bashrc config
[ ! -f "$bashrc_home/config.sh" ] && \
echo $'#\n# config.sh\n#\n\nskip_deps_check=true\nremote_server=\nremote_destination=' \
  > "$bashrc_home/config.sh"
mapfile -t configs < <(find "$bashrc_home" -name "*.sh")
for config in "${configs[@]}"; do source "$config"; done

## SHELL SHORTCUTS

# parent directories
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

# basic functions
ca() { bc <<< "scale=5;$*"; }
catw() { cat "$1" | fold -sw "$COLUMNS"; }
clip() { printf '\033]52;c;%s\a' "$(base64 | tr -d '\r\n')" > /dev/tty; }

## ENVIRONMENT

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

## APPEARANCE

export \
LESS_TERMCAP_mb=$'\E[01;31m' \
LESS_TERMCAP_md=$'\E[01;38;5;74m' \
LESS_TERMCAP_me=$'\E[0m' \
LESS_TERMCAP_se=$'\E[0m' \
LESS_TERMCAP_so=$'\E[38;5;246m' \
LESS_TERMCAP_ue=$'\E[0m' \
LESS_TERMCAP_us=$'\E[04;38;5;146m' \
GTK_THEME='Adwaita:dark'
alias grep="grep --color=auto"
alias tree="tree -C"
alias dmesg='dmesg --color'

## PROMPT

# device colors
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

# default colors
[ -z "$ps1_color" ] && ps1_color='32'
[ -z "$ps1_color_error" ] && ps1_color_error='35'
[ -z "$ps1_color_root" ] && ps1_color_root='31'
[ -z "$ps1_color_root_error" ] && ps1_color_root_error='35'

# prompt format
_getps1() {
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
_getps1

## CONFIG SYNC

# public files
_bashrc_files() {
  printf '%s\n' '.bashrc .bashrc' 'scripts/clean.py .config/bashrc/clean.py'
}

# script download
_bashrc_script() {
  local remote local_path
  while read -r remote local_path; do
    [[ $remote == "scripts/$1" ]] || continue
    [[ -f "$HOME/$local_path" ]] && return 0
    curl -fLsS "https://raw.githubusercontent.com/ThomasBaruzier/bashrc/main/$remote" \
      -o "$HOME/$local_path.tmp" && mv "$HOME/$local_path.tmp" "$HOME/$local_path"
    return $?
  done < <(_bashrc_files)
  return 1
}

# update bashrc
ubrc() {
  local remote local_path
  mkdir -p ~/.cache
  rm -rf ~/.cache/bashrc
  clone thomasbaruzier bashrc ~/.cache/bashrc || return

  while read -r remote local_path; do
    mkdir -p "$(dirname "$HOME/$local_path")"
    cp "$HOME/.cache/bashrc/$remote" "$HOME/$local_path" || return
  done < <(_bashrc_files)

  rm -rf ~/.cache/bashrc
  success 'Public bashrc files updated'
}

# upload bashrc
pbrc() {
  echo
  local commit_name remote local_path
  read -p 'Commit name: ' commit_name
  [ -z "$commit_name" ] && commit_name='other: automatic commit'
  echo

  mkdir -p ~/.cache
  rm -rf ~/.cache/bashrc
  clone thomasbaruzier bashrc ~/.cache/bashrc || return
  while read -r remote local_path; do
    mkdir -p "$(dirname "$HOME/.cache/bashrc/$remote")"
    cp "$HOME/$local_path" "$HOME/.cache/bashrc/$remote" || return
    git -C ~/.cache/bashrc add -- "$remote" || return
  done < <(_bashrc_files)
  git -C ~/.cache/bashrc commit -m "$commit_name" || return
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
  if [ -d "$bashrc_home/.git" ]; then
    git -C "$bashrc_home" pull || return
  else
    git -C "$bashrc_home" init || return
    git -C "$bashrc_home" remote add origin 'git@github.com:ThomasBaruzier/bashrc-private.git'
    git -C "$bashrc_home" fetch origin || return
    git -C "$bashrc_home" checkout -b main --track origin/main || return
  fi

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
  ubrc || return
  uconf || return
  [ -z "$sudo" ] && return
  sudo cp ~/.bashrc /root/
  sudo cp -r ~/.config/bashrc /root/.config/
}

## FILE TRANSFERS

# file upload
push() {
  _push_pull_errors || return 1
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

# file download
pull() {
  _push_pull_errors || return 1
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

# transfer settings
_push_pull_errors() {
  if [ -z "$remote_server" ] || [ -z "$remote_destination" ]; then
    error 'No `remote_server`/`remote_destination` in '"'$bashrc_home/config.sh'"
    return 1
  fi

  remote_port="${remote_server##*:}"
  remote_address="${remote_server%:*}"
  return 0
}

## PACKAGES

# package updates
_update_packages() {
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
    _update_packages "$1"
    return
  fi

  # for pacman
  if pacman -V >/dev/null 2>&1; then
    local installer=pacman

    # package lookup
    [ -f "$bashrc_home/pacman.db" ] || _syncdb
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

    # package lookup
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

    # package choices
    if [ -n "$fixedPackages" ]; then
      echo -e "\e[1m\e[34m::\e[0m\e[1m Fixable\e[0m"
      for ((i=0; i < "${#fixedPackages[@]}"; i++)); do
        echo "${fixedPackages[i]} -> ${fixedNames[i]}"
      done
      echo -e "\n\e[34m1.\e[0m Install found + fixable"
      echo -e "\e[34m2.\e[0m Install found"
      echo -e "\e[34m3.\e[0m Cancel\n"
      read -e -p "> Choice (default=1): " answer

      # selected packages
      case "$answer" in
        3) echo && return;;
        2) packages=(${good[@]});;
        *) packages=(${good[@]} ${fixedNames[@]});;
      esac
    fi

  # selected packages
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

# database parser
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

  // database records
  reti = regcomp(&regex, "^usr/bin/[[:alnum:]]+$", REG_EXTENDED);
  while (fgets(line, sizeof(line), file)) {
    line[strcspn(line, "\n")] = 0;

    // package name
    if (strstr(line, "%NAME%")) {
      fgets(line, sizeof(line), file);
      line[strcspn(line, "\n")] = 0;
      printf("\n%s", line);
    }

    // binary match
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

# update db
_syncdb() {
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

    # parser cleanup
    $sudo rm -rf ~/.cache/extract.exe ~/.cache/extract.c ~/.cache/pacman.db.temp
    local size=$(du -h "$bashrc_home/pacman.db" | awk '{print $1}')
    echo -e "\e[1m\e[34m::\e[0m\e[1m Done - $bashrc_home/pacman.db - $size\e[0m"
  else
    error 'Not using pacman'
    return 1
  fi
}

## FILE UTILITIES

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

## CLEANUP

# cleanup command
clean() {
  _bashrc_script clean.py || return
  python3 -I "$bashrc_home/clean.py" \
    "${DEVICE:-desktop}" "${sudo:-}" "${clean_config-}" "$@"
}

## DISK USAGE

# disk space
disk() (
  set -o pipefail
  local -a options=(-t ext4 -t btrfs)
  [[ ${DEVICE:-} == phone ]] && options=(/sdcard)

  LC_ALL=C command df -B1 --output=source,size,used,avail "${options[@]}" |
    LC_ALL=C awk '
      function size(n, unit) {
        split("B kB MB GB", units)
        for (unit = 1; n >= 999.5 && unit < 4; unit++) n /= 1000
        if (unit == 1) return sprintf("%.0fB", n)
        if (unit == 4) return sprintf("%.2fGB", n)
        n = sprintf("%.3g", n) + 0
        return sprintf("%.*f%s", n < 10 ? 2 : n < 100 ? 1 : 0, n, units[unit])
      }
      NR > 1 && NF == 4 && $2 > 0 && !seen[$1]++ {
        device = $1
        sub(/^.*\//, "", device)
        printf "%s: %s / %s (%.1f%%, %s free)\n",
          device, size($3), size($2), 100 * $3 / $2, size($4)
      }
    '
)

## DEPENDENCIES

# package inventory
_check_deps() {
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
  _check_deps \
    grep sed tar nano bc jq curl gzip \
    gcc/build-essential/base-devel \
    git file pv 7zip lsof screen net-tools
fi

## HISTORY

_filter_long_history() {
  local history_output="$(history 1)"
  read -r hist_num command_string <<< "$history_output"
  if (( "${#command_string}" > 2000 )); then
    history -d "$hist_num"
  fi
}

# history storage
export HISTSIZE=10000000
export HISTFILESIZE=10000000
export HISTIGNORE="$HISTIGNORE:reboot*:shutdown*:shush*"
export HISTFILE=~/.history

# history format
unset HISTTIMEFORMAT
shopt -s cmdhist
shopt -s histappend
PROMPT_COMMAND="_filter_long_history; history -a; $PROMPT_COMMAND"

## GIT

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

  # repository source
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

  # clone destination
  if [ -n "$url" ]; then
    if [ -n "$1" ] && [ "${1:0:1}" != '-' ]; then
      path="$1"; shift
    else
      path="${url##*/}"; path="${path%.git}"
    fi
  fi

  name="${path%/}"; name="${name##*/}"

  # clone options
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -d|--depth) depth="$2"; shift; shift;;
      -b|--branch) branch="$2"; shift; shift;;
      -c|--commit) commit="$2"; depth=0; shift; shift;;
      *) error "Unknown option: $1"; return 1;;
    esac
  done

  if [ -d "$path" ]; then
    # repository update
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
    # repository clone
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

## FILE RENAMING

# rename paths
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

## NETWORKING

# ip addresses
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

# listening sockets
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

## SCREEN SESSIONS

# session selection
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

## MEDIA

# stream information
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

# subtitle muxing
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

## DEVELOPMENT

alias cts='sed "s:\s*$::g" -i '
alias venv='source .venv/bin/activate'

## PROMPT FILES

# file prompt
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

# prompt extraction
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

  _p2f_write() {
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
        _p2f_write

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
        _p2f_write
        unset filename code is_markdown
      else
        code+="$line"$'\n'
      fi
    fi
  done

  _p2f_write

  [ -n "$temp_file" ] && rm -f "$temp_file"

  [ -z "$filenames" ] && echo 'No files found' && return 1
  while [ -n "$2" ]; do
    eval "$2" "${filenames[@]}"
    shift
  done
  return 0
}

## ANDROID

_check_adb() {
  if ! adb devices | grep -qE $'^[0-9a-f]{8,}\t+device$'; then
    error "No ADB device detected"
    return 1
  fi
}

# device mirroring
adbsync() {
  local out="$1"
  local jobs="${2:-4}"

  [ "${out::1}" = '/' ] && \
  echo 'Please only use relative paths' && return 1
  while [ "${out: -1}" = '/' ]; do out="${out%/}"; done
  [ -z "$out" ] && echo "Usage: adbsync <folder> [jobs]" && return 1

  _check_adb || return 1
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

# checksum repair
adbcheck() {
  local jobs=8
  local batch_size=64
  local out="$1"

  while [ "${out: -1}" = '/' ]; do out="${out%/}"; done
  [ -z "$out" ] && echo "Usage: adbcheck <folder>" && return 1

  _check_adb || return 1
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
