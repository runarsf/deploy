#!/bin/bash
set -e

# DEBUG
#set -x # show all commands being executed
#trap 'printf "%3d: " "$LINENO"' DEBUG # show line numbers
#trap 'echo "# $BASH_COMMAND"' DEBUG # best looking debug
#set -o xtrace
#(set -x; command) # create a subshell that will debug only one command

if [ $EUID != 0 ]; then
  sudo "$0" "-${arg}"
  exit $?
fi

prompt() {
  printf "$1 [y/N]"
  read -p " " -n 1 -r </dev/tty
  printf "\n"
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    return 1
  fi
}

sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
dir="$(dirname "${sdir}")"
prompt "Detected dotfile directory ${dir}. Do you want to change it?" && read -p 'New directory: ' dir && dir=${dir%/}
if ! [[ -d "${dir}" ]]; then
  echo 'Not a directory.'
  exit 1
fi

include() {
  echo "Loading ${sdir}/lib/${1}"
  source ${sdir}/lib/${1}
}
include colours.sh

configs() {
  now="$(date '+%d%m%y-%H%M%S')"
  (set -x; mkdir $sdir/backup/$now)
  cd ${dir}
  for f in * .*; do
    if ! [[ "$f" =~ ^(\.|\.\.|\.git|\.gitignore|README\.md|deploy|packages\.csv)$ ]]; then
      if [[ "$f" == "root" ]]; then # could also run for-loop on ./root folder to get all files instead of /*
        (set -x; cp -rsvu --backup=simple --suffix=".${now}" ${dir}/${f}/* /)
      elif [[ -d "$f" ]]; then
        (set -x; cp -rsvu --backup=simple --suffix=".${now}" ${dir}/${f} ${HOME}/)
      else
        (set -x; cp -svu --backup=simple --suffix=".${now}" ${dir}/${f} ${HOME}/${f})
      fi
    fi
  done
}

install() {
  pkg="${dir}/packages.csv"
  if [[ -f "${pkg}" ]]; then
    prompt "Detected package database ${pkg}. Do you want to change it?" && read -p 'New package database: ' pkg && pkg=${pkg%/}
  else
    prompt "Could not detect package database, please enter a valid location."; read -p 'New package database: ' pkg && pkg=${pkg%/}
  fi
  if ! [[ -f "${pkg}" ]]; then
    echo 'Not a valid file.'
    exit 1
  fi

  while IFS=, read -r package prefix suffix; do
    [ "$package" = "package" ] && continue
    (set -x; ${prefix}${package}$(${suffix}))
  done < $pkg
}

install
