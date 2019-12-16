#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o noclobber
#set -o nounset
#set -o xtrace

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)" # /home/user/deploy
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"                     # /home/user/deploy/deploy.sh
__base="$(basename ${__file} .sh)"                                    # deploy

elevate() {
  echo "${requireSudo}"
  if test "${EUID}" -ne 0 -a "${#}" -gt 0; then
    #sudo "$0" "-${arg}"
    sudo "${0}" "${@}"
    exit ${?}
  fi
}

prompt() {
  printf "${1} [y/N]"
  read -p " " -n 1 -r </dev/tty
  printf "\n"
  if [[ ! "${REPLY}" =~ ^[Yy]$ ]]; then
    return 1
  fi
}

include() {
  if test -f "${__dir}/lib/${1}"; then
    source "${__dir}/lib/${1}"
  elif test -f "${1}"; then
    source "${1}"
  else
    echo "Could not load library ${1}."
    return 0
  fi
}
include "colours.sh"

helpme() {
	cat <<-EOMAN
	${C_GREEN}Usage:${RESET} ${C_BLUE}deploy${RESET} [${C_RED}options${RESET}]

	${C_GREEN}Options:${RESET}
	  -d${C_LGRAY},${RESET} --dotfiles <${C_RED}directory${RESET}>  Dotfiles directory.
	  -p${C_LGRAY},${RESET} --packages <${C_RED}file${RESET}>       Package candidate file.
	  -n${C_LGRAY},${RESET} --no-backup             Disable backup.

	${C_GREEN}Examples:${C_YELLOW}
	  deploy --packages ../deploy.json
	  deploy -d ../
	  deploy --dotfiles ../ --packages ../deploy.json
	${RESET}
	EOMAN
}

deployConfigs() {
  now="$(date '+%d%m%y-%H%M%S')"
  cd ${dotfiles}
  for f in * .*; do
    if ! [[ "$f" =~ ^(\.|\.\.|\.git|\.gitignore|README\.md|deploy|deploy*\.json|\.travis\.yml|\.sharenix\.json|Dockerfile)$ ]]; then
      if test "${f}" = "root"; then # could also run for-loop on ./root folder to get all files instead of /*
        (set -x; eval "sudo cp --recursive --symbolic-link --verbose --update ${backup} ${dotfiles}/${f}/* /")
      elif test -d "${f}"; then
        (set -x; eval "cp --recursive --symbolic-link --verbose --update ${backup} ${dotfiles}/${f} ${HOME}/")
      else
        (set -x; eval "cp --symbolic-link --verbose --update ${backup} ${dotfiles}/${f} ${HOME}/${f}")
      fi
    fi
  done
}

installPackages() {
  export DEBIAN_FRONTEND=noninteractive
  # If jq doesn't exist; download it.
  # Assign the jq executable to $jq.
  #if command -v jq >/dev/null 2>&1; then
  if type 'jq' >/dev/null 2>&1; then
    jq='jq'
  else
    jq="${__dir}/jq"
    if test ! -f "${__dir}/jq"; then
      sudo curl --location https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 --output "${__dir}/jq"
      sudo chmod +x "${__dir}/jq"
    fi
  fi

  update=$(${jq} --raw-output ".update // empty" ${config})
  prefix=$(${jq} --raw-output ".prefix // empty" ${config})
  suffix=$(${jq} --raw-output ".suffix // empty" ${config})

  packages=$(${jq} --raw-output ".packages | .[] | .package" ${config})
  prefixes=$(${jq} --raw-output ".packages | .[] | .prefix" ${config})
  suffixes=$(${jq} --raw-output ".packages | .[] | .suffix" ${config})
  csv=$(paste <(echo "$packages") <(echo "$prefixes") <(echo "$suffixes") --delimiters ',')


  (set -x; export DEBIAN_FRONTEND=noninteractive; ${update})
  while IFS=, read -r pkg pre suf; do
    [[ "${pre}" = "null" ]] && pre=${prefix}
    [[ "${suf}" = "null" ]] && suf=${suffix}
    (set -x; export DEBIAN_FRONTEND=noninteractive; ${pre} ${pkg} ${suf})
  done <<< ${csv}
}

test "${#}" -lt "1" && "${0}" --help
POSITIONAL=()
backup='--backup=simple --suffix=".${now}"'
# shift twice for kwargs, once for args
while [[ $# -gt 0 ]]; do
  case "${1}" in
    -h|--help)
      helpme
      shift;;
    -d|--dotfiles)
      dotfiles=$(readlink --canonicalize "$2")
      dotfiles=${dotfiles%/}
      if test ! -d "${dotfiles}"; then
        echo "${dotfiles}: No such directory."
        exit 1
      fi
      requireSudo='Sudo is required to write files to "/"'
      deployConfigs='true'
      shift;shift;;
    -p|--packages)
      config=$(readlink --canonicalize "$2")
      if ! [[ "${config}" == *\/* ]] && test -d "${dotfiles}" -a -f "${dotfiles}/${config}"; then
        config="${dotfiles}/${config}"
      elif test ! -f "${config}"; then
        echo "${config}: No such file."
        exit 1
      fi
      requireSudo='Sudo is required to install packages.'
      installPackages='true'
      shift;shift;;
    -n|--no-backup)
      backup=''
      shift;;
    *) # unknown option
      POSITIONAL+=("${1}") # save it in an array for later
      shift;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if test -n "${1}"; then
  echo "Unrecognized option: ${1}"
  echo "See '${0} --help' for more info."
  exit 1
fi

test -n "${requireSudo}"     && elevate
test -n "${deployConfigs}"   && deployConfigs
test -n "${installPackages}" && installPackages
