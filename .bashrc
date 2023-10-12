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

# system info
platform=$(uname -o)
if [ -x /bin/sudo ] && groups | grep -qE "\b(sudo|wheel)\b"; then
  sudo=sudo
else
  unset sudo
fi

# fancy PS1
getPS1() {
  id=$(ls -id /)
  if [ "${id//[^0-9]/}" != 2 ] && [ "$platform" = 'GNU/Linux' ]; then
    if [ "${EUID}" = 0 ]; then # chroot root
      PS1="\[\033[1;31m\]chroot\$([[ \$? != 0 ]] && echo \"\[\033[0;31m\]\" || echo \"\[\033[0m\]\"):\[\033[1;32m\]\w\[\033[0m\] "
    else                       # chroot user
      PS1="\[\033[1;34m\]chroot\$([[ \$? != 0 ]] && echo \"\[\033[0;31m\]\" || echo \"\[\033[0m\]\"):\[\033[1;32m\]\w\[\033[0m\] "
    fi
  elif [ -z "$SSH_CLIENT" ]; then
    if [ "${EUID}" = 0 ]; then # ssh root
      PS1="\$([[ \$? != 0 ]] && echo \"\[\033[35m\]\" || echo \"\[\033[31m\]\")\w\[\033[0m\] "
    else                       # ssh user
      PS1="\$([[ \$? != 0 ]] && echo \"\[\033[35m\]\" || echo \"\[\033[32m\]\")\w\[\033[0m\] "
    fi
  elif [ "${EUID}" = 0 ]; then # local root
    PS1="\[\033[1;31m\]\h\$([[ \$? != 0 ]] && echo \"\[\033[0;31m\]\" || echo \"\[\033[0m\]\"):\[\033[1;32m\]\w\[\033[0m\] "
  else                         # local user
    PS1="\[\033[1;34m\]\h\$([[ \$? != 0 ]] && echo \"\[\033[0;31m\]\" || echo \"\[\033[0m\]\"):\[\033[1;32m\]\w\[\033[0m\] "
  fi
} && getPS1

# path utilis
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'

# ls aliases
ls="ls --color=auto --group-directories-first -t -X"
alias la='ls -A --color=auto --group-directories-first -t -X'
alias ll='ls -la --color=auto --group-directories-first -t -X'
alias l="$ls"; alias ls="$ls"; alias sl="$ls"

# basic aliases
alias c='clear'
alias md='mkdir'
alias rf="$sudo rm -rf"
alias rd="$sudo rm -d"
alias brc='nano ~/.bashrc; source ~/.bashrc'
alias rel='[ -f ~/.profile ] && source ~/.profile; [ -f ~/.bashrc ] && source ~/.bashrc'

# auto sudo
alias reboot="$sudo reboot"
alias shutdown="$sudo shutdown now"
alias pacman="$sudo pacman"
alias apt="$sudo apt"
alias mount="$sudo mount"
alias umount="$sudo umount"
alias docker="$sudo docker"
alias fdisk="$sudo fdisk"
alias useradd="$sudo useradd"
alias userdel="$sudo userdel"
alias groupadd="$sudo groupadd"
alias groupdel="$sudo groupdel"
alias visudo="$sudo EDITOR=nano visudo"
alias passwd="$sudo passwd"

# status functions
error() { echo -e "\033[31mERROR: $@\033[0m"; }
warn() { echo -e "\033[33mWARNING: $@\033[0m"; }
success() { echo -e "\033[32mSUCCESS: $@\033[0m"; }
info() { echo -e "\033[34mINFO: $@\033[0m"; }

# basic functions
ca() { bc <<< "scale=3;$*"; }
cs() { cd "$1" && ls; }
print() { cat "$1" | fold -sw "$COLUMNS"; }

# list all helps documented in bashrc
help() {
  while read -r line; do
    if [[ "$line" =~ ^[^\ ]+\(\) ]]; then
      echo -ne "\n\e[32m${BASH_REMATCH::-2}\e[0m"
    elif [[ "$line" =~ "echo ""'Desc : "[^"'"]+ ]]; then
      echo -ne "\e[32m : \e[0m${BASH_REMATCH:13}"
    fi
  done < ~/.bashrc
  echo -e '\n'
}

# colors
export \
LESS_TERMCAP_mb=$'\E[01;31m' \
LESS_TERMCAP_md=$'\E[01;38;5;74m' \
LESS_TERMCAP_me=$'\E[0m' \
LESS_TERMCAP_se=$'\E[0m' \
LESS_TERMCAP_so=$'\E[38;5;246m' \
LESS_TERMCAP_ue=$'\E[0m' \
LESS_TERMCAP_us=$'\E[04;38;5;146m'
alias dir="dir --color=auto"
alias grep="grep --color=auto"
alias dmesg='dmesg --color'

# path and configs
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.cargo/bin" ] && PATH="$HOME/.cargo/bin:$PATH"
[ -f ~/.profile ] && [ -z "$(grep '.bashrc' ~/.profile)" ] && source ~/.profile
[ -f ~/.addons ] && source ~/.addons

# update/push bashrc
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

pbrc() {
  echo
  local commit_name
  read -p 'Commit name: ' commit_name
  [ -z "$commit" ] && commit_name='update'
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

############
# PACKAGES #
############

# update
update_packages() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage : u'
    echo 'Desc : Update and upgrade packages'
    echo 'Note : Please use `i` with no arguments instead'
    return
  fi
  echo
  if pacman -V >/dev/null 2>&1; then
    $sudo pacman -Syu
  elif apt -v >/dev/null 2>&1; then
    $sudo apt update && $sudo apt upgrade
  fi
  echo
}

# install
i() {
  # help
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage : i <packages>'
    echo 'Desc : Install packages'
    echo 'Note : Upgrades packages if no argument is provided'
    return
  fi

  # init
  unset packages
  local name good bad fixedPackages fixedNames
  [ -z "$1" ] && update_packages && return

  # for pacman
  if pacman -V >/dev/null 2>&1; then
    local installer=pacman

    # determine packages status
    [ -f "$HOME/.config/pacman.db" ] || syncdb
    for package in "$@"; do
      if grep -qE "^$package(:|$)" < "$HOME/.config/pacman.db"; then
        # existing
        good+=("$package")
      else
        name=$(grep -E ":usr/bin/$package(:|$)" "$HOME/.config/pacman.db")
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
      read -e -p "> Choice (default=1) : " answer

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

# actualize db
syncdb() {
  # help
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage : syncdb'
    echo 'Desc : Update package/executable db'
    return
  fi

  if pacman -V >/dev/null 2>&1; then

    # init
    echo
    $sudo pacman -Fy
    mkdir -p ~/.config ~/.cache
    rm -f ~/.cache/pacman.db.temp
    files=($(find /var/lib/pacman/sync/ -name *.files))

    # files extraction
    echo -e "\e[1m\e[34m::\e[0m\e[1m Extracting files...\e[0m"
    for file in "${files[@]}"; do
      echo " extracting $file"
      $sudo gzip -cd < "$file" >> ~/.cache/pacman.db.temp
    done

    # c code execution
    echo "$code" | sed "s:\$HOME:$HOME:g" > ~/.cache/extract.c
    gcc ~/.cache/extract.c -o ~/.cache/extract.exe
    ~/.cache/extract.exe | sort > ~/.config/pacman.db

    # finishing
    $sudo rm -rf ~/.cache/extract.exe ~/.cache/extract.c ~/.cache/pacman.db.temp
    echo -e "\e[1m\e[34m::\e[0m\e[1m Done - ~/.config/pacman.db - $(du -h ~/.config/pacman.db | awk '{print $1}')\e[0m"

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
  sudo chown "$USER" "${paths[@]}"
}

# chmod helper
w() {
  # help
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage : w [<custom>|all]'
    echo 'Desc : Make files executable'
    echo "Default custom value : '*.sh *.exe'"
    return
  fi

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

# cleaning
clean() {
  # help
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage : clean'
    echo 'Desc : Clean useless data'
    return
  fi

  disk
  mkdir -p ~/.cache-bkp
  [ -d ~/.cache/torch ] && mv ~/.cache/torch ~/.cache-bkp
  [ -d ~/.cache/huggingface ] && mv ~/.cache/huggingface ~/.cache-bkp

  if [ -n "$SSH_CLIENT" ]; then # ssh, server assumed
    $sudo rm -rf /tmp/* /var/cache/* ~/.cache/* /var/lib/systemd/coredump/* ~/.bash_logout ~/.viminfo ~/.lesshst ~/.wget-hsts ~/.python_history ~/.sudo_as_admin_successful ~/.Xauthority 2>/dev/null
  elif [ "$platform" = Android ]; then # android, forbid sudo and system paths
    rm -rf ~/.cache/* ~/.bash_logout ~/.viminfo ~/.lesshst ~/.wget-hsts ~/.python_history ~/.sudo_as_admin_successful ~/.Xauthority 2>/dev/null
  else # assuming local desktop
    $sudo rm -rf /tmp/* /var/log/* /var/cache/* ~/.cache/* /var/lib/systemd/coredump/* ~/.bash_logout ~/.viminfo ~/.lesshst ~/.wget-hsts ~/.python_history ~/.sudo_as_admin_successful ~/.Xauthority 2>/dev/null
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
  # help
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage : disk'
    echo 'Desc : Show available storage'
    return
  fi

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
  echo "Disk usage : $used/$total ($percent, $avail free)"
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

check_deps grep sed tar nano bc jq curl gzip gcc/build-essential/base-devel git file pv p7zip lsof screen net-tools

###########
# HISTORY #
###########

HISTSIZE=1000 # save 1,000 lines of history in memory
HISTFILESIZE=1000000 # save 1,000,000 lines of history to disk
HISTTIMEFORMAT='[%F %T] ' # set time format
shopt -s cmdhist # multiple commands on one line show up as a single line

#HISTCONTROL=ignoredups,erasedups # ignore redundant and remove duplicates
#shopt -s histappend # append to history instead of overwrite

#IGNORE="?:??:???:????:clear:history*:reboot:shutdown"
#trim_history() {
#  local hist_file="$HOME/.bash_history"
#  local temp_file="$HOME/.cache/trimmed_history"
#
#  mkdir -p ~/.cache
#  awk -F '\t' -v IGNORE="$IGNORE" '$3 !~ IGNORE' "$hist_file" > "$temp_file"
#  awk '{$1=++c} 1' "$temp_file" > "$hist_file"
#  rm -f "$temp_file"
#}
#trap trim_history EXIT

#######
# GIT #
#######

clone() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage : clone (<url> | <user> <repo>) [folder] [options]'
    echo '  -d, --depth: Depth of clone'
    echo '  -b, --branch: Branch to clone'
    echo '  -c, --commit: Commit to checkout'
    echo 'Desc : Clone github repos'
    echo 'Default : --depth 1'
    return
  fi

  if [ "${1:0:8}" = 'https://' ] || [ "${1:0:7}" = 'http://' ]; then
    local url="$1"
  elif [ -n "$2" ]; then
    local url="https://github.com/$1/$2.git"
    shift
  else
    error 'Synthax error. Use clone --help for more information'
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
  # help
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage : g [options]'
    echo 'Desc : Git helper'
    echo 'Default : commit + push'
    return
  fi

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
    read -p 'Choice : ' choice
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
         read -p 'url : ' url
         [ -n "$url" ] && git remote add origin "$url"
         read -p 'gitignore : ' gitignore
         [ -n "$gitignore" ] && echo -e "${gitignore// /\\n}" > .gitignore
         read -p "files to add : " toAdd
         [ -n "$toAdd" ] && git add "$toAdd"
         git commit -m '[+] Initial commit.'
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
           || git commit -am '[~] Update.'
         fi;;
      C) read -p 'commit name ? ' commit
         git add *
         [ -n "$commit" ] && git commit -m "$commit" \
         || git commit -m '[~] Update.';;

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

#################
# FILE LAUNCHER #
#################

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
    tar.gz) (($(du -m "$path" | cut -f -1) > 10)) \
            && pv "$path" | tar x || tar xf "$path";;
    7z|bz2|bzip2|tbz2|tbz|gz|gzip|tgz|tar|wim|swm|esd|xz|txz|zip|zipx|dmg|img|fat|img|hfs|iso|lzma|mbr|ntfs|rar|qcow|qcow2|qcow2c|001|002|squashfs|udf|scap|uefif|vdi|vhd|vmdk|xar|pkg|z|taz)
      7z x "$path";;
    *) error "File type isn't supported"; return 1;;
  esac
}

r() {
  # help
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage : r [file]'
    echo 'Desc : File launcher'
    echo 'Default : last launched file'
    return
  fi

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
    last=${last/$HOME/\~}
    error "File is empty or doesn't exist $last"
    return 1
  fi
}

##############
# NETWORKING #
##############

myip() {
  # help
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage : myip'
    echo 'Desc : Show public and private IP'
  fi

  local private_ips=$(
    ifconfig 2>/dev/null | \
    grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
    grep -ve '^255\.' -e '\.255$' -e '127.0.0.1' | \
    sort -u | tr '\n' ' '
  )

  private_ips="${private_ips:: -1}"
  private_ips="${private_ips// / - }"
  echo -e "PRIVATE: \e[34m$private_ips\e[0m"

  public_ip=$(curl -s --max-time 5 ip.3z.ee)
  grep -qE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' <<< "$public_ip" || public_ip='Request Failed'
  echo -e "PUBLIC:  \e[34m$public_ip\e[0m"
}

ports() {
  # help
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage : ports'
    echo 'Desc : Show opened ports'
  fi

  local entries=$($sudo lsof -i -P -n | grep LISTEN | awk '{print $1"\t\t"$5"\t"$8"\t"$9}' 2>/dev/null)
  if [ -n "$entries" ]; then
    echo -e "\e[35mSERVICE\t\tTYPE\tNODE\tIP:PORT\e[0m"
    echo "$entries"
  else
    echo "No opened ports"
  fi
}

furl() {
  # help
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage : furl <url>'
    echo 'Desc : Find the last redirect of a url'
  fi

  echo
  wget -S --spider "$1" 2>&1 | sed -En 's/^--[[:digit:]: -]{19}--  https?:\/\/(.*)/> \1\n/p'
}

###########
# ANDROID #
###########

# broken
#adb() {
#  # help
#  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
#    echo 'Usage : adb [p|packages|u|upackages|i|install|unins|reins|pull|any adb arg]'
#    echo 'Desc : ADB helper'
#    echo 'Note : Use one option at a time'
#    return
#  fi
#
#  case "$1" in
#    p|packages)
#      packages=$(adb shell pm list packages | awk  -F : '{print $2}')
#      [ -n "$2" ] && echo "$packages" | grep "$2" --color=never || echo "$packages";;
#    u|upackages) packages=$(sort <(adb shell pm list packages) <(adb shell pm list packages -u) | uniq -u | awk  -F : '{print $2}')
#      [ -n "$2" ] && echo "$packages" | grep "$2" --color=never || echo "$packages";;
#    i|install) adb install "${@:2}";;
#    unins) adb shell pm uninstall --user 0 "${@:2}";;
#    reins) adb shell cmd package install-existing "${@:2}";;
#    pull) adb pull $(adb shell pm path "$2" | awk -F : '{print $2}');;
#    *) eval "/usr/bin/adb $@";;
#  esac
#}

dapk() { apktool d "$1" "$1"; }
capk() { apktool b "$1"; }
sign() { jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore ~/.android/debug.keystore "$1" androiddebugkey -storepass android; }

##########
# SCREEN #
##########

s() {
  # help
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo 'Usage : scr <number>'
    echo 'Desc : Screen helper'
    echo 'Default : Display menu'
    return
  fi

  local screens=$(screen -ls)
  readarray -t screens <<< $(grep -Po '[0-9]+\..+(?=\(Detached\))' <<< "$screens" | sed -E 's:([0-9]+)\.:\1 - :g')
  [ -z "$screens" ] && error 'No detached screens found' && return 1
  if [ -z "$1" ]; then
    echo -e "\n\e[34mSCREENS :\e[0m"
    for ((i=1; i < "${#screens[@]}+1"; i++)); do
      echo "$i - ${screens[i-1]//\\/\/}"
    done
    read -p $'\nChoice (default=1) : ' answer
    [ -z "$answer" ] && answer=1
  else
    echo
    answer="$1"
  fi
  local id=$(grep -Po '^[0-9]+' <<< "${screens[answer-1]}")
  [ -z "$id" ] && echo -e 'No screens found' && return
  screen -r "$id"
  echo
}

##############
# Torrenting #
##############

addtrackers() {
  local magnet_link="$1"
  local trackers=(
    "udp://tracker.opentrackr.org:1337/announce"
    "udp://opentracker.i2p.rocks:6969/announce"
    "https://opentracker.i2p.rocks:443/announce"
    "udp://tracker.openbittorrent.com:6969/announce"
    "http://tracker.openbittorrent.com:80/announce"
    "udp://9.rarbg.com:2810/announce"
    "udp://open.demonii.com:1337/announce"
    "udp://exodus.desync.com:6969/announce"
    "udp://open.stealth.si:80/announce"
    "udp://tracker.torrent.eu.org:451/announce"
    "udp://tracker.moeking.me:6969/announce"
    "udp://tracker.bitsearch.to:1337/announce"
    "udp://tracker1.bt.moack.co.kr:80/announce"
    "udp://tracker.tiny-vps.com:6969/announce"
    "udp://tracker.theoks.net:6969/announce"
    "udp://p4p.arenabg.com:1337/announce"
    "udp://movies.zsw.ca:6969/announce"
    "udp://explodie.org:6969/announce"
    "https://tracker.tamersunion.org:443/announce"
    "https://tracker.moeblog.cn:443/announce"
  )
  local new_trackers=$(echo "${trackers[*]}" | tr ' ' ',')
  local new_magnet_link="${magnet_link}&tr=${new_trackers}"
  echo "$new_magnet_link"
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
