#!/bin/bash
set -e
# saner programming env: these switches turn some bugs into errors
#set -o errexit -o pipefail -o noclobber -o nounset
set -o errexit -o pipefail -o noclobber

if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    # sudo "$0" "-${arg}"
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

# Libraries
source ${sdir}/lib/colours.sh

configs() {
  # FIXME: File permissions can get set to root only
  now="$(date '+%d%m%y-%H%M%S')"
  #(set -x; mkdir ${sdir}/backup/${now})
  cd ${dotfiles}
  for f in * .*; do
    if ! [[ "$f" =~ ^(\.|\.\.|\.git|\.gitignore|README\.md|deploy|deploy\.json)$ ]]; then
      if [[ "$f" == "root" ]]; then # could also run for-loop on ./root folder to get all files instead of /*
        (set -x; cp -rsvu --backup=simple --suffix=".${now}" ${dotfiles}/${f}/* /)
      elif [[ -d "$f" ]]; then
        (set -x; cp -rsvu --backup=simple --suffix=".${now}" ${dotfiles}/${f} ${HOME}/)
      else
        (set -x; cp -svu --backup=simple --suffix=".${now}" ${dotfiles}/${f} ${HOME}/${f})
      fi
    fi
  done
}

install() {
  command -v jq >/dev/null 2>&1 \
    && jq='jq' \
    || jq="${sdir}/backup/jq" \
    && [ ! -f ${sdir}/backup/jq ] \
    && curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 --output ${sdir}/backup/jq \
    && chmod +x ${sdir}/backup/jq

  packages=$(${jq} -r ".packages | .[] | .package" ${config})
  prefix=$(${jq} -r ".prefix" ${config})
  [ -z "$prefix" ] && unset prefix
  suffix=$(${jq} -r ".suffix" ${config})
  [ -z "$suffix" ] && unset suffix
  while read -r package; do
    (set -x; ${prefix}${package}${suffix})
  done <<< ${packages}
}

# Args:
#  -d:, --dotfiles: - dotfiles directory absolute path
#  -p:, --packages: - deploy.json file absolute path
#  -n, --no-backup - disable backup
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dotfiles)
      # TODO: Allow relative path name by converting relative to full
      dotfiles=${2%/}
      if ! [[ -d "${dotfiles}" ]]; then
        echo "${dotfiles}: No such directory."
        exit 1
      fi
      configs
      # dir="$(dirname "${sdir}")" # get parent directory
      # dir=${dir%/} # remove trailing slash
      shift # past argument
      shift # past value
      ;;
    -p|--packages)
      config="$2"
      if [[ -d "${dotfiles}" ]] && ! [[ "${config}" == *\/* ]] && [ -f "${dotfiles}/${config}" ]; then
        config="${dotfiles}/${config}"
      elif ! [[ -f "${config}" ]]; then
        echo "${config}: No such file."
        exit 1
      fi
      install
      shift # past argument
      shift # past value
      ;;
    -e|--echo)
      [ ! -z "$2" ] && echo "$2" \
        || echo "No value"
      shift
      shift
      ;;
    -n|--no-backup)
      backup=n
      shift # past argument
      ;;
    *) # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ -n $1 ]]; then
    echo "Untracked argument:"
    echo "$1"
fi
