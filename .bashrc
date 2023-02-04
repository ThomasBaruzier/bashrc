#
# ~/.bashrc
#

##########
# BASICS #
##########

# beam cursor
printf '\e[6 q'

# path utilis
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'

up() {
  if [[ "$1" = '-h' || "$1" = '--help' ]]; then
    echo 'Usage : up <number>'
    echo 'Desc : Go up n directories'
    return
  fi
  local num_levels="$1"
  [[ -z "$num_levels" ]] && num_levels=1
  local levels=""
  for ((i=0; i < num_levels; i++)); do
    levels="../$levels"
  done
  cd $levels
}

# basic aliases
alias c='clear'
alias e='logout; exit'
alias md='mkdir'
alias rf='sudo rm -rf'
alias brc='nano ~/.bashrc; source ~/.bashrc'
alias rel='[ -f ~/.bashrc ] && source ~/.bashrc; [ -f ~/.profile ] && source ~/.profile'

# basic functions
ca() { bc <<< "scale=3;$*"; }
sz() { du -sh "$1"; }
cs() { cd "$1" && ls; }
print() { cat "$1" | fold -sw "$COLUMNS"; }
pwd() { [ -z "$1" ] && local path='.' || local path="$1"; readlink -f "$path"; }
own() { [ -z "$1" ] && local path='.' || local path=($@); sudo chown "$USER:$USER" "${path[@]}"; }

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


############
# PACKAGES #
############

# update
u() {
  if [[ "$1" = '-h' || "$1" = '--help' ]]; then
    echo 'Usage : u'
    echo 'Desc : Update and upgrade packages'
    return
  fi
  if pacman -V >/dev/null 2>&1; then
    sudo pacman -Syu
  elif apt -v >/dev/null 2>&1; then
    sudo apt update && sudo apt upgrade
  fi
}

# install
i() {

  # help
  if [[ "$1" = '-h' || "$1" = '--help' ]]; then
    echo 'Usage : i <packages>'
    echo 'Desc : Install packages'
    echo 'Note : Upgrades packages if no argument is provided'
    return
  fi

  # init
  unset packages
  local name good bad fixedPackages fixedNames
  [ -z "$1" ] && echo && u && echo && return

  # for pacman
  if pacman -V >/dev/null 2>&1; then

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
      sudo pacman -Syu "${packages[@]}"
      echo
    fi

  # for apt
  elif apt -v >/dev/null 2>&1; then

    # determine packages status
    for package in "$@"; do
      if apt-file search -q "$package"; then
        good+=("$package")
      else
        name=$(apt-file search "$package" | awk '{print $1}')
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

  fi

}

############# code for syncdb() #############
read -r -d '' code << "EOF"
#include <stdio.h>
#include <string.h>
#include <regex.h>

int main() {

  // variables
  FILE *file = fopen("/home/tyra/.cache/pacman.db.temp", "r");
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
  if [[ "$1" = '-h' || "$1" = '--help' ]]; then
    echo 'Usage : syncdb'
    echo 'Desc : Update package/executable db'
    return
  fi

  if pacman -V >/dev/null 2>&1; then

    # init
    sudo pacman -Fy
    mkdir -p ~/.config ~/.cache
    rm -f ~/.cache/pacman.db.temp
    files=($(find /var/lib/pacman/sync/ -name *.files))

    # files extraction
    echo -e "\e[1m\e[34m::\e[0m\e[1m Extracting files...\e[0m"
    for file in "${files[@]}"; do
      echo " extracting $file"
      sudo gzip -cd < "$file" >> ~/.cache/pacman.db.temp
    done

    # c code execution
    echo "$code" > ~/.cache/extract.c
    gcc ~/.cache/extract.c -o ~/.cache/extract.exe
    ~/.cache/extract.exe | sort > ~/.config/pacman.db

    # finishing
    sudo rm -rf ~/.cache/extract.exe ~/.cache/extract.c ~/.cache/pacman.db.temp
    echo -e "\e[1m\e[34m::\e[0m\e[1m Done - ~/.config/pacman.db - $(du -h ~/.config/pacman.db | awk '{print $1}')\e[0m"

  else
    echo "Command available for the pacman package manager only."
  fi

}

##########
# SYSTEM #
##########

# cleaning
clean() {

  # help
  if [[ "$1" = '-h' || "$1" = '--help' ]]; then
    echo 'Usage : clean'
    echo 'Desc : Clean useless data'
    return
  fi

  disk
  sudo rm -rf /tmp/* /var/cache/ ~/.cache/* ~/.bash_logout ~/.viminfo ~/.lesshst ~/.wget-hsts ~/.python_history ~/.sudo_as_admin_successful 2>/dev/null
  if pacman -V >/dev/null 2>&1; then
    sudo mkdir -p /var/cache/pacman/pkg/
    sudo pacman -Sc --noconfirm >/dev/null
    while [[ -n $(pacman -Qdtq) ]]; do
      sudo pacman -Rcns $(pacman -Qdtq) --noconfirm >/dev/null
    done
  fi
  if yay -V >/dev/null 2>&1; then sudo yay -Sc --noconfirm >/dev/null; fi
  if apt -v >/dev/null 2>&1; then sudo apt autoremove >/dev/null 2>&1; fi
  if journalctl --version >/dev/null 2>&1; then sudo journalctl --vacuum-size=50M >/dev/null 2>&1; fi
  if flatpak --version >/dev/null 2>&1; then sudo flatpak uninstall --unused >/dev/null; fi
  disk

}

# disk space
disk() {

  # help
  if [[ "$1" = '-h' || "$1" = '--help' ]]; then
    echo 'Usage : disk'
    echo 'Desc : Show available storage'
    return
  fi

  # extract data
  local info=$(df -h | grep -E '/$')
  local total=$(awk '{print $2}' <<< "$info")
  local used=$(awk '{print $3}' <<< "$info")
  local avail=$(awk '{print $4}' <<< "$info")
  local percent=$(awk '{print $5}' <<< "$info")

  # print data
  echo "Disk usage : $used/$total ($percent, $avail free)"

}

# chmod helper
w() {

  # help
  if [[ "$1" = '-h' || "$1" = '--help' ]]; then
    echo 'Usage : w [files|all]'
    echo 'Desc : Make files executable'
    echo 'Defaults : *.sh, *.py'
    return
  fi

  # make executable
  if [ -z "$1" ]; then
    chmod +x *.sh *.py 2>/dev/null
  elif [ "$1" = 'all' ]; then
    chmod +x * 2>/dev/null
  else
    chmod +x "$@" 2>/dev/null
  fi
  ls

}

#######
# GIT #
#######

# clone utils
clone() {

  # help
  if [[ "$1" = '-h' || "$1" = '--help' ]]; then
    echo 'Usage : clone <user> <repo> [folder]'
    echo 'Desc : Clone github repos'
    echo 'Default : --depth 1'
    return
  fi

  [[ -z "$1" || -z "$2" ]] && echo -e "\n\e[31mERROR : No input\e[0m\n"
  [ -n "$3" ] && local output="$3"
  [ -z "$3" ] && local output="$2"
  git clone "https://github.com/$1/$2" --depth 1 "$output"

}

# git helper
g() {

  # help
  if [[ "$1" = '-h' || "$1" = '--help' ]]; then
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
      echo '[f] - push -f'
      echo '[P] - pull'
      echo '[F] - pull -f'
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
         git commit -m 'initial commit'
         read -p "push ? " push
         [ "$push" == 'y' ] && git push origin main;;

      c) if [ "$flag" = 'true' ]; then
           read -p 'Author ? ' author
           read -p "Repo's name ? " repo
           clone "$author" "$repo"
         else
           read -p 'commit name ? ' commit
           [ -n "$commit" ] && git commit -am "$commit" \
           || git commit -am 'update'
         fi;;
      C) read -p 'commit name ? ' commit
         git add *
         [ -n "$commit" ] && git commit -m "$commit" \
         || git commit -m 'update';;

      p) git push origin main;;
      f) git push origin main -f;;
      P) git pull origin main;;
      F) read -p 'rebase ? ' choice
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
      *) echo -e "\e[31mERROR : Invalid input '${choice:i:1}'\e[0m\n"
         return;;

    esac

  done
  echo
}

#################
# File launcher #
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
  [ $(head -c 3 "$path") = '#!/' ] && local header=$(head -n 1 "$path")
  [ "$header" = '#!/bin/bash' ] && ext='sh'
  [ "$header" = '#!/bin/sh' ] && ext='sh'
  [ "$header" = '#!/bin/python' ] && ext='py'

  # launcher
  case "$ext" in
    sh|bash) chmod +x "$path" && "$path" "${@:3}";;
    c) gcc "$path" -o "$dir/$name.exe" -lm \
       && (sleep 0.5 && rm -f "$dir/$name.exe" &) \
       && "$dir/$name.exe" "${@:3}";;
    exe|out) "$path" "${@:3}";;
    py) python3 "$path" "${@:3}";;
    jar) java -jar "$path" "${@:3}";;
    tar.gz) (($(du -m "$path" | cut -f -1) > 10)) \
            && pv "$path" | tar x || tar xf "$path";;
    7z|bz2|bzip2|tbz2|tbz|gz|gzip|tgz|tar|wim|swm|esd|xz|txz|zip|zipx|jar|xpi|odt|ods|docx|xlsx|epub|apm|ar|a|deb|lib|arj|cab|chm|chw|chi|chq|msi|msp|doc|xls|ppt|cpio|cramfs|dmg|ext|ext2|ext3|ext4|img|fat|img|hfs|hfsx|hxs|hxi|hxr|hxq|hxw|lit|ihex|iso|img|lzma|mbr|mslz|mub|nsis|ntfs|img|mbr|rar|r00|ppmd|qcow|qcow2|qcow2c|001|002|squashfs|udf|iso|img|scap|uefif|vdi|vhd|vmdk|xar|pkg|z|taz)
      7z x "$path";;
    *) echo -e "\e[31mERROR : File type isn't supported\e[0m";;
  esac

}

r() {

  # help
  if [[ "$1" = '-h' || "$1" = '--help' ]]; then
    echo 'Usage : r [file]'
    echo 'Desc : File launcher'
    echo 'Default : last launched file'
    return
  fi

  # init
  mkdir -p ~/.cache/last
  if [ -f "/home/$USER/.cache/last/script" ]; then
    local last=$(cat ~/.cache/last/script)
  else
    local last
  fi

  [ -n "$1" ] && last=$(readlink -f "$1")
  if [ -f "$last" ]; then
    echo "$last" > ~/.cache/last/script
    run "$last" "$@"
  else
    echo "File doesn't exist (${last/\/home\/$USER/\~})"
  fi

}

#######
# ADB #
#######

alias packages="adb shell pm list packages | awk  -F : '{print \$2}'"
alias upackages="adb shell pm list packages -u | awk  -F : '{print \$2}'"
unins() { adb shell pm uninstall --user 0 "$@"; }
reins() { adb shell cmd package install-existing "$@"; }
