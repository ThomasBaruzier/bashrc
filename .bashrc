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

# bashrc home
bashrc_home="$HOME/.config/bashrc"
[ -d "$bashrc_home" ] || mkdir -p "$bashrc_home"

# bashrc config
[ ! -f "$bashrc_home/config.sh" ] && \
echo $'#\n# config.sh\n#\n\nps1_color=32\nskip_deps_check=true' \
> "$bashrc_home/config.sh"
mapfile -t configs < <(find "$bashrc_home" -name "*.sh")
for config in "${configs[@]}"; do source "$config"; done

# system info
platform=$(uname -o)
if [ -x /bin/sudo ] && [ "$platform" != 'Android' ] && \
  groups | grep -qE "\b(sudo|wheel)\b"; then
  sudo=sudo
else
  unset sudo
fi

# path utilis
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'
alias ........='cd ../../../../../../..'
alias .........='cd ../../../../../../../..'

# ls aliases
ls="ls --color=auto --group-directories-first -t -X"
alias la='ls -A --color=auto --group-directories-first -t -X'
alias ll='ls -la --color=auto --group-directories-first -t -X'
alias l="$ls"; alias ls="$ls"; alias sl="$ls"

# basic aliases
alias c='clear'
alias n='nano'
alias md='mkdir'
alias rf="$sudo rm -rf"
alias rd="$sudo rm -d"
alias brc='nano ~/.bashrc; source ~/.bashrc'
alias rel='[ -f ~/.profile ] && source ~/.profile; [ -f ~/.bashrc ] && source ~/.bashrc'

# auto sudo
alias sudo='sudo -EH'
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

# colors
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

# status functions
error() { echo -e "\033[31mERROR: $@\033[0m"; }
warn() { echo -e "\033[33mWARNING: $@\033[0m"; }
success() { echo -e "\033[32mSUCCESS: $@\033[0m"; }
info() { echo -e "\033[34mINFO: $@\033[0m"; }

# basic functions
ca() { bc <<< "scale=3;$*"; }
pp() { cat "$1" | fold -sw "$COLUMNS"; }

# fancy PS1
getPS1() {
  id=$(ls -id /)
  [ -n "${ps1_color//[^0-9]}" ] && ps1_color="${ps1_color//[^0-9]}" || ps1_color=32
  if [ "${id//[^0-9]}" != 2 ] && [ "$platform" = 'GNU/Linux' ]; then
    if [ "${EUID}" = 0 ]; then # chroot root
      PS1="\[\033[1;31m\]chroot\$([[ \$? != 0 ]] && echo \"\[\033[0;31m\]\" || echo \"\[\033[0m\]\"):\[\033[1;${ps1_color}m\]\w\[\033[0m\] "
    else                       # chroot user
      PS1="\[\033[1;34m\]chroot\$([[ \$? != 0 ]] && echo \"\[\033[0;31m\]\" || echo \"\[\033[0m\]\"):\[\033[1;${ps1_color}m\]\w\[\033[0m\] "
    fi
  elif [ -z "$SSH_CLIENT" ]; then
    if [ "${EUID}" = 0 ]; then # local root
      PS1="\$([[ \$? != 0 ]] && echo \"\[\033[35m\]\" || echo \"\[\033[31m\]\")\w\[\033[0m\] "
    else                       # local user
      PS1="\$([[ \$? != 0 ]] && echo \"\[\033[35m\]\" || echo \"\[\033[${ps1_color}m\]\")\w\[\033[0m\] "
    fi
  elif [ "${EUID}" = 0 ]; then # ssh root
    PS1="\[\033[1;31m\]\h\$([[ \$? != 0 ]] && echo \"\[\033[0;31m\]\" || echo \"\[\033[0m\]\"):\[\033[1;${ps1_color}m\]\w\[\033[0m\] "
  else                         # ssh user
    PS1="\[\033[1;34m\]\h\$([[ \$? != 0 ]] && echo \"\[\033[0;31m\]\" || echo \"\[\033[0m\]\"):\[\033[1;${ps1_color}m\]\w\[\033[0m\] "
  fi
} && getPS1

# path and configs
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.cargo/bin" ] && PATH="$HOME/.cargo/bin:$PATH"
[ -f "$bashrc_home/addons.sh" ] && source "$bashrc_home/addons.sh"
[ -f ~/.profile ] && ! grep -q '\.bashrc' ~/.profile && source ~/.profile

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
    success "~/.bashrc has been updated!"
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
  [ -z "$commit_name" ] && commit_name='update'
  echo

  mkdir -p ~/.cache
  rm -rf ~/.cache/bashrc
  clone thomasbaruzier bashrc ~/.cache/bashrc
  cp ~/.bashrc ~/.cache/bashrc/.bashrc
  git -C ~/.cache/bashrc add .bashrc
  git -C ~/.cache/bashrc commit -m "$commit_name"
  git -C ~/.cache/bashrc push

  if [ "$?" = 0 ]; then
    success '~/.bashrc has been pushed!'
  else
    error 'Failed to push ~/.bashrc'
  fi

  rm -rf ~/.cache/bashrc
  echo
}

# push pull config error
pp_config() {
  if [ -z "$remote_server" ] || [ -z "$remote_destination" ]; then
    echo -n 'Error: please configure \$remote_server and'
    echo "\$remote_destination in '$bashrc_home/config.sh'"
    return 1
  fi

  remote_port="${remote_server##*:}"
  remote_address="${remote_server%:*}"
  return 0
}

# push files to remote
push() {
  pp_config || return 1
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
  pp_config || return 1
  local path=() files=() dest='.'
  local latest="$remote_destination/latest-upload.txt"

  [ -d '/sdcard/Download/' ] && dest='/sdcard/Download/'
  [ -n "$1" ] && dest="$1"
  mapfile -t files < <(ssh "$remote_address" -p "$remote_port" cat "$latest")
  [ -z "$files" ] && echo "Error: No recent uploads found." && return 1

  if [ "${files[0]}" = "pipe.txt" ]; then
    ssh "$remote_address" -p "$remote_port" cat "$remote_destination/pipe.txt"
  else
    for i in "${files[@]}"; do
      path+=("$remote_address:$remote_destination/$i")
    done
    scp -r -P "$remote_port" "${path[@]}" "$dest"
  fi
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
        if [ "$platform" = 'Android' ]; then
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
    readarray -t paths <<< $($sudo find .)
  else
    local paths=()
    for arg in "$@"; do
      readarray -t found_paths <<< $($sudo find "$arg")
      paths+=("${found_paths[@]}")
    done
  fi
  $sudo chown "$USER" "${paths[@]}"
}

# chmod helper
w() {
  # make executable
  if [ -z "$1" ]; then
    chmod +x *.sh *.exe 2>/dev/null
  elif [ "$1" = 'all' ]; then
    chmod +x * 2>/dev/null
  else
    chmod +x "$@" 2>/dev/null
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
    $sudo du -bhsc "$@" | sort -h
  elif [ -n "$1" ]; then
    $sudo du -bhs "$@" | awk '{print $1}'
  else
    $sudo du -bhsc .[^.]* * 2>/dev/null | sort -h
  fi
}

# cleaning (opinionated)
clean() {
  disk
  mkdir -p ~/.cache-bkp
  [ -d ~/.cache/torch ] && mv ~/.cache/torch ~/.cache-bkp
  [ -d ~/.cache/torch_extensions ] && mv ~/.cache/torch_extensions ~/.cache-bkp
  [ -d ~/.cache/huggingface ] && mv ~/.cache/huggingface ~/.cache-bkp
  [ -d ~/.cache/jellyfin ] && mv ~/.cache/jellyfin ~/.cache-bkp

  if [ -n "$SSH_CLIENT" ]; then # ssh, server assumed
    $sudo rm -rf /tmp/* /var/cache/* ~/.cache/* ~/.local/share/Trash/ /var/lib/systemd/coredump/* ~/.bash_logout ~/.viminfo ~/.lesshst ~/.wget-hsts ~/.python_history ~/.sudo_as_admin_successful ~/.Xauthority 2>/dev/null
  elif [ "$platform" = Android ]; then # android, forbid sudo and system paths
    rm -rf ~/.cache/* ~/.bash_logout ~/.viminfo ~/.lesshst ~/.wget-hsts ~/.python_history ~/.sudo_as_admin_successful ~/.Xauthority 2>/dev/null
  else # assuming local desktop
    $sudo rm -rf /tmp/* /var/log/* /var/cache/* ~/.cache/* ~/.local/share/Trash/ /var/lib/systemd/coredump/* ~/.bash_logout ~/.viminfo ~/.lesshst ~/.wget-hsts ~/.python_history ~/.sudo_as_admin_successful ~/.Xauthority 2>/dev/null
  fi

  mv ~/.cache-bkp/* ~/.cache/ 2>/dev/null
  $sudo rm -rf ~/.cache-bkp

  if pacman -V >/dev/null 2>&1; then
    $sudo mkdir -p /var/cache/pacman/pkg/
    $sudo pacman -Sc --noconfirm  >/dev/null
    while [[ -n $(pacman -Qdtq) ]]; do
      $sudo pacman -Rcns $(pacman -Qdtq) --noconfirm >/dev/null
    done
  fi
  if yay -V >/dev/null 2>&1; then $sudo yay -Sc --noconfirm >/dev/null; fi
  if apt -v >/dev/null 2>&1; then
    [ "$platform" = Android ] || $sudo mkdir -p /var/cache/apt/archives/partial
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
  [ "$platform" = 'Android' ] || local info=$(df -h | grep -E '/$')
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

HISTSIZE=100000 # in memory
HISTFILESIZE=1000000 # in disk
HISTCONTROL=ignoredups # ignore redundant and remove duplicates
HISTIGNORE="reboot*:shutdown*:shush*"
unset HISTTIMEFORMAT # no time format
shopt -s cmdhist # no command separation
shopt -s histappend # append to history instead of overwrite
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

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
    error 'Syntax error. Usage: clone <url> or clone <username> <repository>'
    return 1
  fi

  shift
  if [ -n "$1" ] && [ "${1:0:1}" != '-' ]; then
    local path="$1"
    shift
  else
    local path="${url##*/}"; path="${path%.git}"
  fi

  local name="${path##*/}"
  local depth=1

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
  local screens=$(screen -ls)
  readarray -t screens <<< $(grep -Po '[0-9]+\..+(?=\(Detached\))' <<< "$screens")
  [ -z "$screens" ] && error 'No detached screens found' && return 1
  if [ -z "$1" ]; then
    echo -e "\n\e[34mSCREENS:\e[0m"
    for ((i=1; i < "${#screens[@]}+1"; i++)); do
      screen="${screens[i-1]//\\/\/}"
      echo "$i - ${screen/\./ - }"
    done
    read -p $'\nChoice (d=detach all, default=1): ' answer
    [ -z "$answer" ] && answer=1
  else
    echo
    answer="$1"
  fi
  if [ "$answer" = d ]; then
    mapfile -t to_detach < <(screen -ls | grep -F '(Attached)' | cut -f2)
    if [ -n "$to_detach" ]; then
      for screen in "${to_detach[@]}"; do
        screen -d "$screen"
      done
    else
      echo $'Nothing found to detach.\n'
    fi
  else
    local id=$(grep -Po '^[0-9]+' <<< "${screens[answer-1]}")
    [ -z "$id" ] && echo -e 'No screens found' && return
    screen -r "$id"
    echo
  fi
}

##############
# TORRENTING #
##############

addtrackers() {
  local magnet_link="$1"
  local trackers=$(curl -s 'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt')
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
  output='.'
  replace_subs=false
  sub_lang='en'
  sub_name="$USER's subtitles"

  usage=$'\nUsage: burnsubs -i <input> -s <sub> -o <output> [-l <lang>] [-n <name>] [-r]\n'
  usage+=$'  -i, --input      Input video file\n'
  usage+=$'  -s, --sub        Subtitle file to burn\n'
  usage+=$'  -o, --output     Output video file path\n'
  usage+="  -l, --language   Subtitle language (default: $sub_lang)"$'\n'
  usage+="  -n, --name       Subtitle name (default: $sub_name)"$'\n'
  usage+=$'  -r, --replace    Replace all existing subtitles with the new one\n'
  usage+=$'  -h, --help       Display this help and exit\n'

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -i|--input) input="$2"; shift 2;;
      -s|--sub) sub_file="$2"; shift 2;;
      -o|--output) output="$2"; shift 2;;
      -l|--language) sub_lang="$2"; shift 2;;
      -n|--name) sub_name="$2"; shift 2;;
      -r|--replace) replace_subs=true; shift;;
      -h|--help) echo "$usage"; return 1;;
      *) echo "Invalid argument: $1"; echo "$usage"; return 1;;
    esac
  done

  if [ -z "$input" ] || [ -z "$output" ] || [ -z "$sub_file" ]; then
    echo
    error 'Missing required arguments.'
    echo "$usage"
    return 1
  fi

  if [ -d "$output" ]; then
    new_title=$(basename "$input" | sed -e 's/\.[^.]*$//')
    output="$output/$new_title.${input##*.}"
  fi

  [ "$sub_lang" = 'en' ] && sub_lang=eng
  [ "${input##*.}" = "mkv" ] && sub_codec='srt' || sub_codec='mov_text'

  ffmpeg_command=(ffmpeg -loglevel warning -hide_banner -stats \
    -sub_charenc UTF-8 -i "$input" -i "$sub_file" \
    -map 0:v -map 0:a -c:v copy -c:a copy \
    -metadata:s:s:0 language="$sub_lang" \
    -metadata:s:s:0 handler_name="$sub_name")

  if [ "$replace_subs" = true ]; then
    ffmpeg_command+=(-map 1:s -c:s "$sub_codec")
  else
    ffmpeg_command+=(-map 0:s? -map 1:s -c:s "$sub_codec")
  fi

  "${ffmpeg_command[@]}" "$output"

  if [ "$?" = 0 ]; then
    echo -e "\e[34mSubtitles successfully burnt! (Saved at: $output)\e[0m"
  else
    echo -e "\e[31mError burning subtitles into the video! ($input)\e[0m"
    return 1
  fi
}

##########
# CODING #
##########

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

alias f2p='file2prompt'
file2prompt() {
  readarray -t files <<< $(find "$@" -type f -not -path '*/.*')
  readarray -t files <<< $(
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
      "$next" =~ ^'```'[a-z]*$ && (
      "$line" =~ ^\#*\ ?\`([^\`]+)\`:?$ ||
      "$line" =~ ^\#*\ ?\*+([^\*]+)\*+:?$ )
      && -n "${line//[^a-zA-Z0-9]}"
    ]]; then
      filename="${BASH_REMATCH[1]}"
      unset code
      continue
    fi

    [ -z "$filename" ] && continue
    [[ ! "$next" =~ ^'```'$ ]] && code+=$'\n'"$next" && continue
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
    echo "${code:1}" > "$filename"
    unset filename code
  done

  [ -z "$filenames" ] && echo 'No files found' && return 1
  return 0
}
