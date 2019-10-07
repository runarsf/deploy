#!/bin/bash
set -e
#trap 'exit' ERR

debug() {
  echo "Enabling debug mode."
  set -x
  trap 'printf "%3d: " "$LINENO"' DEBUG
}

if [ $EUID != 0 ]; then
  sudo "$0" "-${arg}"
  exit $?
fi

source ./lib/colours.sh

prompt() {
  printf "$1 [y/N]"
  read -p " " -n 1 -r </dev/tty
  printf "\n"
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    return 1
  fi
}

dir="$(dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )")"
prompt "Detected dotfile directory ${dir}. Do you want to change it?" && read -p 'New directory: ' dir && dir=${dir%/}
if ! [[ -d "$dir" ]]; then
  echo 'Not a directory.'
  exit 1
fi

include() {
  echo "loaded library from lib/library.sh" # check out .lib
}

configs() {
  now="$(date '+%d%m%y-%H%M%S')"
  cd ${dir}
  for f in * .*; do
    if ! [[ "$f" =~ ^(\.|\.\.|\.git|\.gitignore|README\.md|deploy|packages\.csv)$ ]]; then
      if [[ "$f" == "root" ]]; then
        echo "R: cp -rsv --backup=simple --suffix=".${now}" ${dir}/${f} /"
        cp -rsv --backup=simple --suffix=".${now}" ${dir}/${f} /
      elif [[ -d "$f" ]]; then
        #echo "cp -rsv --backup=numbered ${dir}/${f} ${HOME}/${f}" # recursively symlink verbose with numbered-backup("~1~")
        echo "D: cp -rsv --backup=simple --suffix=".${now}" ${dir}/${f} ${HOME}/${f}" # recursive symlink verbose fixed-backup("date-time")
        cp -rsv --backup=simple --suffix=".${now}" ${dir}/${f} ${HOME}/${f}
      else
        echo "F: cp -sv --backup=simple --suffix=".${now}" ${dir}/${f} ${HOME}/${f}"
        cp -sv --backup=simple --suffix=".${now}" ${dir}/${f} ${HOME}/${f}
      fi
    fi
  done
}

configs
