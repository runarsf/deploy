#!/usr/bin/env bash
# saner programming env: these switches turn some bugs into errors
set -o errexit
set -o pipefail
set -o noclobber
#set -o nounset
#set -o xtrace

# TODO: replace $sdir with these
#__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
#__base="$(basename ${__file} .sh)"

# FIXME: Quote and bracket $EUID and $? (?)
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    # sudo "$0" "-${arg}"
    exit $?
fi

# FIXME: Quote and bracket line 1 and $REPLY
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
# FIXME: Quote variable
source ${sdir}/lib/colours.sh

deployConfigs() {
  # FIXME: File permissions can get set to root only
  now="$(date '+%d%m%y-%H%M%S')"
  #(set -x; mkdir ${sdir}/backup/${now})
  # FIXME: Quote variable
  cd ${dotfiles}
  for f in * .*; do
    if ! [[ "$f" =~ ^(\.|\.\.|\.git|\.gitignore|README\.md|deploy|deploy*\.json|\.travis\.yml|\.sharenix\.json)$ ]]; then
      if [[ "$f" == "root" ]]; then # could also run for-loop on ./root folder to get all files instead of /*
        (set -x; eval "cp --recursive --symbolic-link --verbose --update ${backup} ${dotfiles}/${f}/* /")
        # FIXME: Bracket variable
      elif [[ -d "$f" ]]; then
        # FIXME: Quote variable
        (set -x; eval "cp --recursive --symbolic-link --verbose --update ${backup} ${dotfiles}/${f} ${HOME}/")
      else
        # FIXME: Quote variable
        (set -x; eval "cp --symbolic-link --verbose --update ${backup} ${dotfiles}/${f} ${HOME}/${f}")
      fi
    fi
  done
}

#FIXME: QUOTE ALL THE VARIABLES

installPackages() {
  # If jq doesn't exist; download it.
  # Set the jq version to use as $jq.
  command -v jq >/dev/null 2>&1 \
    && jq='jq' \
    || jq="${sdir}/backup/jq" \
    && [ ! -f ${sdir}/backup/jq ] \
    && curl --location https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 --output ${sdir}/backup/jq \
    && chmod +x ${sdir}/backup/jq

  # TODO: Add support for package-specific pre/-suffix
  # TODO: Remove need for spaces in pre/-suffix
  update=$(${jq} --raw-output ".update // empty" ${config})
  prefix=$(${jq} --raw-output ".prefix // empty" ${config})
  suffix=$(${jq} --raw-output ".suffix // empty" ${config})

  packages=$(${jq} --raw-output ".packages | .[] | .package" ${config})
  prefixes=$(${jq} --raw-output ".packages | .[] | .prefix" ${config})
  suffixes=$(${jq} --raw-output ".packages | .[] | .suffix" ${config})
  csv=$(paste <(echo "$packages") <(echo "$prefixes") <(echo "$suffixes") --delimiters ',')
  #[ -z "$prefix" ] && unset prefix
  #[ -z "$suffix" ] && unset suffix
  # One-package-per-line parsing
  #while read --raw-output package; do
    #(set -x; ${prefix}${package}${suffix})
  #done <<< ${packages}

  (set -x; ${update})
  while IFS=, read -r pkg pre suf; do
    [[ "${pre}" = "null" ]] && pre=${prefix}
    [[ "${suf}" = "null" ]] && suf=${suffix}
    (set -x; ${pre} ${pkg} ${suf})
  done <<< ${csv}
}

# Args:
#  -d:, --dotfiles: - dotfiles directory absolute path
#  -p:, --packages: - deploy.json file absolute path
#  -n, --no-backup - disable backup
POSITIONAL=()
deployConfigs=false installPackages=false backup='--backup=simple --suffix=".${now}"'
while [[ $# -gt 0 ]]; do
  case "${1}" in
    -d|--dotfiles)
      dotfiles=$(readlink --canonicalize "$2")
      dotfiles=${dotfiles%/}
      if ! [[ -d "${dotfiles}" ]]; then
        echo "${dotfiles}: No such directory."
        exit 1
      fi
      deployConfigs=true
      # dir="$(dirname "${sdir}")" # get parent directory
      # dir=${dir%/} # remove trailing slash
      shift # past argument
      shift # past value
      ;;
    -p|--packages)
      config=$(readlink --canonicalize "$2")
      if [[ -d "${dotfiles}" ]] && ! [[ "${config}" == *\/* ]] && [[ -f "${dotfiles}/${config}" ]]; then
        config="${dotfiles}/${config}"
      elif ! [[ -f "${config}" ]]; then
        echo "${config}: No such file."
        exit 1
      fi
      installPackages=true
      shift # past argument
      shift # past value
      ;;
    -n|--no-backup)
      backup=''
      shift # past argument
      ;;
    -e|--echo)
      [ ! -z "$2" ] && echo "$2" \
        || echo "No value"
      shift
      shift
      ;;
    *) # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ -n "${1}" ]]; then
    echo "Untracked argument:"
    echo "$1"
fi

# Deploy configs first, then install packages
[ "$deployConfigs" = true ] && deployConfigs
[ "$installPackages" = true ] && installPackages
