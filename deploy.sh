#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o noclobber
#set -o nounset
#set -o xtrace

#on_error() {
#  echo "Deploy failed, exiting."
#  exit 1
#}
#trap on_error ERR

# TODO: replace $sdir with these
#__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
#__base="$(basename ${__file} .sh)"

# FIXME: Sudo check in own function, --help should not require sudo
if test "${EUID}" -ne 0 -a "$#" -gt 0; then
  sudo "${0}" "${@}"
  #sudo "$0" "-${arg}"
  exit ${?}
fi

prompt() {
  printf "${1} [y/N]"
  read -p " " -n 1 -r </dev/tty
  printf "\n"
  if [[ ! "${REPLY}" =~ ^[Yy]$ ]]; then
    return 1
  fi
}

sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Libraries
source ${sdir}/lib/colours.sh

helpme() {
	cat <<-EOMAN
	Usage: deploy [options] [commands]

	Options:
	  -d, --dotfiles <directory>                 Dotfiles directory.
	  -p, --packages <file>                      Package candidate file.

	Commands:
	  packages                                   Install packages.
	  configs                                    Deploy configs.

	Examples:
	  deploy -p ../deploy-ubuntu.json packages
	  deploy -d ../ configs

	EOMAN
}

deployConfigs() {
  now="$(date '+%d%m%y-%H%M%S')"
  cd ${dotfiles}
  for f in * .*; do
    if ! [[ "$f" =~ ^(\.|\.\.|\.git|\.gitignore|README\.md|deploy|deploy*\.json|\.travis\.yml|\.sharenix\.json)$ ]]; then
      if [[ "$f" == "root" ]]; then # could also run for-loop on ./root folder to get all files instead of /*
        (set -x; eval "cp --recursive --symbolic-link --verbose --update ${backup} ${dotfiles}/${f}/* /")
      elif [[ -d "${f}" ]]; then
        (set -x; eval "cp --recursive --symbolic-link --verbose --update ${backup} ${dotfiles}/${f} ${HOME}/")
      else
        (set -x; eval "cp --symbolic-link --verbose --update ${backup} ${dotfiles}/${f} ${HOME}/${f}")
      fi
    fi
  done
}

installPackages() {
  # If jq doesn't exist; download it.
  # Assign the jq executable to $jq.
  command -v jq >/dev/null 2>&1 \
    && jq='jq' \
    || jq="${sdir}/backup/jq" \
    && [ ! -f ${sdir}/backup/jq ] \
    && curl --location https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 --output ${sdir}/backup/jq \
    && chmod +x ${sdir}/backup/jq

  # TODO: Remove need for spaces in pre/-suffix
  update=$(${jq} --raw-output ".update // empty" ${config})
  prefix=$(${jq} --raw-output ".prefix // empty" ${config})
  suffix=$(${jq} --raw-output ".suffix // empty" ${config})

  packages=$(${jq} --raw-output ".packages | .[] | .package" ${config})
  prefixes=$(${jq} --raw-output ".packages | .[] | .prefix" ${config})
  suffixes=$(${jq} --raw-output ".packages | .[] | .suffix" ${config})
  csv=$(paste <(echo "$packages") <(echo "$prefixes") <(echo "$suffixes") --delimiters ',')

  (set -x; ${update})
  while IFS=, read -r pkg pre suf; do
    [[ "${pre}" = "null" ]] && pre=${prefix}
    [[ "${suf}" = "null" ]] && suf=${suffix}
    (set -x; ${pre} ${pkg} ${suf})
  done <<< ${csv}
}

POSITIONAL=()
deployConfigs=false installPackages=false backup='--backup=simple --suffix=".${now}"'
while [[ $# -gt 0 ]]; do
  case "${1}" in
    -h|--help)
      helpme
      shift # past argument
      ;;
    -d|--dotfiles)
      dotfiles=$(readlink --canonicalize "$2")
      dotfiles=${dotfiles%/}
      if ! [[ -d "${dotfiles}" ]]; then
        echo "${dotfiles}: No such directory."
        exit 1
      fi
      deployConfigs=true
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
    echo "Unrecognized option: ${1}"
    "${0}" --help
    exit 1
fi

# Deploy configs first, then install packages
[ "$deployConfigs" = true ] && deployConfigs
[ "$installPackages" = true ] && installPackages