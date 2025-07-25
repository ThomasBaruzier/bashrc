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

# zoxide
[ -f "$PREFIX/bin/zoxide" ] && alias cd='z' && eval "$(zoxide init bash)"

# status functions
unset -f error warn success info
error() { echo $'\033[31mERROR: '"$*"$'\033[0m'; }
warn() { echo $'\033[33mWARNING: '"$*"$'\033[0m'; }
success() { echo $'\033[32mSUCCESS: '"$*"$'\033[0m'; }
info() { echo $'\033[34mINFO: '"$*"$'\033[0m'; }

##################
# IDENTIFICATION #
##################

# system info
export USER="$(whoami)"
export PLATFORM="$(uname -o)"
export ARCH="$(uname -m)"

# system type
for i in /sys/class/power_supply/*; do
  [ "${i: -1}" = '*' ] && \
  export DEVICE=desktop || export DEVICE=laptop
  break;
done

# detect chroot
root_fs_id=$(ls -id /)
[ "${root_fs_id//[^0-9]}" != 2 ] && export DEVICE=chroot

# detect sudo
if [ "$PLATFORM" != 'Android' ]; then
  if [ -x /bin/sudo ] && groups | grep -qE "\b(sudo|wheel)\b"; then
    sudo=sudo
  else
    unset sudo
  fi
else
  DEVICE=phone
  unset sudo
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
alias btop='$sudo btop --utf-force'

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
    [ "$installer" = 'apt' ] && $sudo apt update && $sudo apt install "${packages[@]}"
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

# cleaning (opinionated)
clean() {
  disk

  exceptions=(
    "$HOME/.cache/torch"
    "$HOME/.cache/torch_extensions"
    "$HOME/.cache/huggingface"
    "$HOME/.cache/jellyfin"
    "/tmp/systemd*"
    "/var/log/journal"
  )

  common_paths=(
    "$HOME/.cache"
    "$HOME/.bash_logout"
    "$HOME/.viminfo"
    "$HOME/.lesshst"
    "$HOME/.wget-hsts"
    "$HOME/.python_history"
    "$HOME/.sudo_as_admin_successful"
    "$HOME/.Xauthority"
    "$HOME/.local/share/Trash"
    "$HOME/.docker"
    "$HOME/.spotdl"
    "$HOME/.cargo"
    "$HOME/.npm"
    "$HOME/.nv"
    "$HOME/.pki"
    "$HOME/.mc"
    "$HOME/.gradle"
    "$HOME/.java"
    "$HOME/.fltk"
    "$HOME/.openjfx"
    "$HOME/.vscode-oss"
    "$HOME/.steampid"
    "$HOME/.steampath"
    "$HOME/.nvidia-settings-rc"
    "$HOME/.pulse-cookie"
  )

  ssh_paths=(
    "/tmp"
    "/var/cache"
    "/var/lib/systemd/coredump"
  )

  desktop_paths=(
    "/tmp"
    "/var/log"
    "/var/cache"
    "/var/lib/systemd/coredump"
  )

  phone_paths=()

  find_args=()
  for exc in "${exceptions[@]}"; do
    find_args+=(-not -path "$exc")
  done

  if [ -n "$SSH_CLIENT" ]; then # ssh, server assumed
    $sudo find "${ssh_paths[@]}" "${common_paths[@]}" "${find_args[@]}" -type f -delete 2>/dev/null
    $sudo find "${ssh_paths[@]}" "${common_paths[@]}" "${find_args[@]}" -type d -empty -delete 2>/dev/null
  elif [ "$DEVICE" = 'phone' ]; then # android, forbid sudo and system paths
    find "${phone_paths[@]}" "${common_paths[@]}" "${find_args[@]}" -type f -delete 2>/dev/null
    find "${phone_paths[@]}" "${common_paths[@]}" "${find_args[@]}" -type d -empty -delete 2>/dev/null
  else # assuming local desktop
    $sudo find "${desktop_paths[@]}" "${common_paths[@]}" "${find_args[@]}" -type f -delete 2>/dev/null
    $sudo find "${desktop_paths[@]}" "${common_paths[@]}" "${find_args[@]}" -type d -empty -delete 2>/dev/null
  fi

  if pacman -V >/dev/null 2>&1; then
    $sudo mkdir -p /var/cache/pacman/pkg/
    $sudo pacman -Sc --noconfirm  >/dev/null
    while [[ -n $(pacman -Qdtq) ]]; do
      $sudo pacman -Rcns $(pacman -Qdtq) --noconfirm >/dev/null
    done
  fi
  if yay -V >/dev/null 2>&1; then $sudo yay -Sc --noconfirm >/dev/null; fi
  if apt -v >/dev/null 2>&1; then
    [ "$DEVICE" = 'phone' ] || $sudo mkdir -p /var/cache/apt/archives/partial
    $sudo apt autoremove -y >/dev/null 2>&1
  fi
  if journalctl --version >/dev/null 2>&1; then $sudo journalctl --vacuum-size=50M >/dev/null 2>&1; fi
  if flatpak --version >/dev/null 2>&1; then $sudo flatpak uninstall --unused >/dev/null; fi
  disk
}

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
    echo 'Usage: clone (<url> | <user> <repo>) [folder] [options]'
    echo '  -d, --depth: Depth of clone'
    echo '  -b, --branch: Branch to clone'
    echo '  -c, --commit: Commit to checkout'
    echo 'Desc: Clone github repos'
    echo 'Default: --depth 1'
    return
  fi

  if [[ "$1" =~ ^(https?://|git@) ]]; then
    local url="$1"
  elif [ -n "$2" ]; then
    local url="https://github.com/$1/$2.git"
    shift
  else
    error 'Syntax error. Usage: clone <url> or clone <USER> <repository>'
    return 1
  fi

  shift
  if [ -n "$1" ] && [ "${1:0:1}" != '-' ]; then
    local path="$1"
    shift
  else
    local path="${url##*/}"; path="${path%.git}"
  fi

  local depth=1
  local name="${path%/}"; name="${name##*/}"

  # Parse CLI arguments
  while [[ "$#" -gt 0 ]]; do
    local key="$1"
    local arg="$2"
    case "$1" in
      -d|--depth) depth="$arg"; shift; shift;;
      -b|--branch) local branch="$arg"; shift; shift;;
      -c|--commit) local commit="$arg"; depth=full; shift; shift;;
      *) error "Unknown option: $key"; return 1;;
    esac
  done

  [ -n "$branch" ] && branch="--branch $branch"
  [ "$depth" = full ] && unset depth || depth="--depth $depth"

  if [ -d "$path" ]; then
    # Check for updates if already cloned
    if [ -n "$commit" ]; then
      [ $(git -C "$path" rev-parse HEAD) = "$commit" ] && return
    fi

    local output=$(git -C "$path" pull 2>&1)

    if [ "$?" != 0 ]; then
      echo "$output"
      error "Failed to pull $name"
      return 1
    fi

    if [[ "$output" = *"Already up to date."* ]]; then
      info "No update available for $name"
      return
    else
      success "Updated $name"
    fi
  else
    # Clone if not already done
    info "Cloning $name..."
    git clone "$url" "$path" $depth $branch

    if [ "$?" != 0 ]; then
      error "Failed to clone $name"
      return 1
    fi

    success "Cloned $name"
  fi

  # Checkout commit if instructed to
  if [ -n "$commit" ]; then
    local output=$(git -C "$path" checkout "$commit" 2>&1)
    if [ "$?" != 0 ]; then
      echo "$output"
      error "Failed to checked out commit $commit for $name"
      return 1
    fi
    success "Checked out commit $commit"
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

run() {
  # init
  local path="$1"
  local dir="${path%/*}"
  local file="${path##*/}"
  local name="${file%%.*}"
  [[ "$file" =~  '.' ]] && local ext="${file#*.}"
  cd "$dir"

  # detect ext based on header
  fileinfo=$(file "$path")
  if [[ "$fileinfo" = *'shell script'* ]]; then
    ext='sh'
  elif [[ "$fileinfo" = *'python script'* || "$fileinfo" = *'Python script'* ]]; then
    ext='py'
  elif [[ "$fileinfo" = *'executable'* ]]; then
    ext='exe'
  fi

  # launcher
  case "$ext" in
    sh|bash) chmod +x "$path" && "$path" "${@:3}";;
    c) gcc "$path" -o "$dir/$name.exe" -lm \
       && (sleep 0.5 && rm -f "$dir/$name.exe" &) \
       && "$dir/$name.exe" "${@:3}";;
    exe|out) "$path" "${@:3}";;
    py) python "$path" "${@:3}";;
    jar) java -jar "$path" "${@:3}";;
    tar.gz|tgz|tar.xz|txz) (($(du -m "$path" | cut -f -1) > 10)) \
            && pv "$path" | tar x || tar xf "$path";;
    7z|bz2|bzip2|tbz2|tbz|gz|gzip|tgz|tar|wim|swm|esd|xz|txz|zip|zipx|dmg|img|fat|img|hfs|iso|lzma|mbr|ntfs|rar|qcow|qcow2|qcow2c|001|002|squashfs|udf|scap|uefif|vdi|vhd|vmdk|xar|pkg|z|taz)
      7z x "$path";;
    *) error "File type isn't supported"; return 1;;
  esac
}

r() {
  # init
  mkdir -p ~/.cache/last
  if [ -f ~/.cache/last/script ]; then
    local last=$(cat ~/.cache/last/script)
  else
    local last
  fi

  [ -n "$1" ] && last=$(readlink -f "$1")
  if [ -s "$last" ]; then
    echo "$last" > ~/.cache/last/script
    run "$last" "$@"
  else
    [ -n "$last" ] && last="($last)"
    last="${last/$HOME/\~}"
    error "File is empty or doesn't exist $last"
    return 1
  fi
}

##############
# NETWORKING #
##############

myip() {
  local private_ips=$(
    ifconfig 2>/dev/null | \
    grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
    grep -ve '^255\.' -e '\.255$' -e '127.0.0.1' | \
    sort -u | tr '\n' ' '
  )

  private_ips="${private_ips:: -1}"
  private_ips="${private_ips// / - }"
  echo -e "PRIVATE: \e[34m$private_ips\e[0m"

  public_ip=$(curl -s --max-time 5 ip.3z.ee 2>/dev/null)
  grep -qE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' <<< "$public_ip" || public_ip='Request Failed'
  echo -e "PUBLIC:  \e[34m$public_ip\e[0m"
}

ports() {
  local entries=$(
    $sudo lsof -i -P -n | \
      grep LISTEN | \
      awk '{print $1"\t"$5"\t"$8"\t"$9}' 2>/dev/null | \
      sed -E 's:\:([0-9]+)$:|\1:g' | \
      sort -un -t'|' -k2 | \
      tr '|' ':'
  )

  if [ -n "$entries" ]; then
    printf "\e[35m%-20s %-6s %-6s %-15s\e[0m\n" "SERVICE" "TYPE" "NODE" "IP:PORT"
    echo "$entries" | while read -r service type node address; do
      printf "%-20s %-6s %-6s %-15s\n" "$service" "$type" "$node" "$address"
    done
  else
    echo "No opened ports"
  fi
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
  make fclean
  make -j || return 1
  make clean || true
}

fclean() {
  find . -regex '.*\.\(o\|a\|gcno\|gcda\)' -o -name 'a.out' -delete
  [ -f [Mm]akefile ] && make fclean
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
  readarray -t files < <(
    find "$@" -type f \( \
      -path '*/.*' -o \
      -path '*/node_modules/*' -o \
      -path '*/venv/*' -o \
      -name 'package-lock.json' \
    \) -prune -o -print
  )
  readarray -t files < <(
    file --mime-type "${files[@]}" | \
      grep -e ' text/' \
        -e ' application/javascript' \
        -e ' application/json' \
      | cut -d':' -f1
  )

  [ -z "${files}" ] && echo "No files found" >&2 && return 1
  unset prompt

  for path in "${files[@]}"; do
    local file=$(<"$path")
    [ "${path:0:2}" = './' ] && path="${path:2}"
    while [[ "${file::-1}" = ' ' || "${file::-1}" = $'\n' ]]; do
      file="${file:0:-1}"
    done
    ext="${path: -5}"
    [ -n "${ext//[^.]}" ] && ext="${path##*.}" || unset ext
    prompt+=$'\n`'"${path}"$'`:\n```'"${ext}"$'\n'"${file}"$'\n```\n'
  done

  if [ -n "$WAYLAND_DISPLAY" ] && [ -t 1 ]; then
    lines=$(wc -l <<< "$prompt")
    lines="${lines%% *}"
    wl-copy <<< "$prompt"
    echo "Copied $lines lines into the clipboard"
  else
    echo "$prompt"
  fi
}

alias p2f='prompt2file'
prompt2file() {
  unset code filename filenames overwrite
  mapfile -t lines < "$1"
  count="${#lines[@]}"

  for ((i=1; i < count; i++)); do
    line="${lines[i-1]}"
    next="${lines[i]}"

    if [[
      "$next" =~ ^[\t\ ]*'```'[a-z]*$ && (
      "$line" =~ ^[\t#\*\ ]*\`([a-zA-Z0-9'()'\/\_\.\-]+)\`[\t\*\ :]*$ ||
      "$line" =~ ^[\t#\`\ ]*\*+([a-zA-Z0-9'()'\/\_\.\-]+)\*+[\t\`\ :]*$
      ) && -n "${line//[^a-zA-Z0-9]}"
    ]]; then
      filename="${BASH_REMATCH[1]}"
      unset code
      continue
    fi

    [ -z "$filename" ] && continue
    [[ ! "$next" =~ ^[\t\ ]*'```'$ ]] && code+=$'\n'"$next" && continue
    echo -n "> $filename"

    if [ -f "$filename" ]; then
      if [ "$overwrite" == 'all' ]; then
        echo ' - ow'
      else
        read -p $' - ow? \e[s' -N1 answer
        if [ "$answer" == a ]; then
          overwrite='all'
          echo
        elif [ "$answer" != y ]; then
          echo -n $'\e[un\n'
          unset filename code
          continue
        else echo; fi
      fi
    else echo " - ok"; fi

    filenames+=("$filename")
    if [ -n "${filename//[^\/]}" ] && [ "${filename:0:1}" != '/' ]; then
      mkdir -p "${filename%/*}"
    fi
    echo "${code:1}" > "$filename"
    unset filename code
  done

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
