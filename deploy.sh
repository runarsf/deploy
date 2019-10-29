#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o noclobber
#set -o nounset
#set -o xtrace

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

elevate() {
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
	${C_GREEN}Usage:${RESET} ${C_BLUE}deploy${RESET} [${C_RED}options${RESET}] [${C_RED}commands${RESET}]

	${C_GREEN}Options:${RESET}
	  -d${C_LGRAY},${RESET} --dotfiles <${C_RED}directory${RESET}>  Dotfiles directory.
	  -p${C_LGRAY},${RESET} --packages <${C_RED}file${RESET}>       Package candidate file.
	  -n${C_LGRAY},${RESET} --no-backup             Disable backup.

	${C_GREEN}Commands:${RESET}
	  full                        Install packages and deploy configs.
	  packages                    Install packages.
	  configs                     Deploy configs.

	${C_GREEN}Examples:${C_YELLOW}
	  deploy -p ../deploy.json packages
	  deploy -d ../ configs
	  deploy --dotfiles ../ --packages ../deploy.json full
	${RESET}
	EOMAN
}

deployConfigs() {
  now="$(date '+%d%m%y-%H%M%S')"
  cd ${dotfiles}
  for f in * .*; do
    if ! [[ "$f" =~ ^(\.|\.\.|\.git|\.gitignore|README\.md|deploy|deploy*\.json|\.travis\.yml|\.sharenix\.json)$ ]]; then
      if test "${f}" = "root"; then # could also run for-loop on ./root folder to get all files instead of /*
        (set -x; eval "cp --recursive --symbolic-link --verbose --update ${backup} ${dotfiles}/${f}/* /")
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
  command -v jq >/dev/null 2>&1 \
    && jq='jq' \
    || jq="${__dir}/build/jq" \
    && test ! -f "${__dir}/build/jq" \
    && curl --location https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 --output "${__dir}/build/jq" \
    && chmod +x "${__dir}/build/jq"

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

test "${#}" -lt "1" && "${0}" --help
POSITIONAL=()
requireSudo='false' deployConfigs='false' installPackages='false' backup='--backup=simple --suffix=".${now}"'
# shift twice for arguments that takes a value
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
      shift;shift;;
    -p|--packages)
      config=$(readlink --canonicalize "$2")
      if test -d "${dotfiles}" && ! [[ "${config}" == *\/* ]] && test -f "${dotfiles}/${config}"; then
        config="${dotfiles}/${config}"
      elif test ! -f "${config}"; then
        echo "${config}: No such file."
        exit 1
      fi
      shift;shift;;
    -n|--no-backup)
      backup=''
      shift;;
    packages)
      requireSudo='true'
      installPackages='true'
      shift;;
    configs)
      deployConfigs='true'
      shift;;
    *) # unknown option
      POSITIONAL+=("${1}") # save it in an array for later
      shift;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if test -n "${1}"; then
    echo "Unrecognized option: ${1}"
    "${0}" --help
    exit 1
fi

# Deploy configs first, then install packages
test "${requireSudo}" = "true" && elevate
test "${deployConfigs}" = "true" && deployConfigs
test "${installPackages}" = "true" && installPackages
