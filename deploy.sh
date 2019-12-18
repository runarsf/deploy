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
	  -e${C_LGRAY},${RESET} --ignore-error          Don't exit script on error.
	  -v${C_LGRAY},${RESET} --verbose               Enable some verbose features.

	${C_GREEN}Examples:${C_YELLOW}
	  deploy --packages ../deploy.json
	  deploy -d ../
	  deploy --dotfiles ../ --packages ../deploy.json
	${RESET}
	EOMAN
}

deployConfigs() {
  now="$(date '+%d%m%y-%H%M%S')"
  cd "${dotfiles}"
  for f in * .*; do
    if ! [[ "$f" =~ ^(\.|\.\.|\.git|\.gitignore|README\.md|deploy.*\.json|deploy.*\.ini|\.travis\.yml|\.sharenix\.json|Dockerfile)$ ]]; then
      if test "${f}" = "root"; then # could also run for-loop on ./root folder to get all files instead of /*
        (test -n "${verbose}" && set -x; eval "sudo cp --recursive --symbolic-link --verbose --update ${backup} ${dotfiles}/${f}/* /")
      elif test -d "${f}"; then
        (test -n "${verbose}" && set -x; eval "cp --recursive --symbolic-link --verbose --update ${backup} ${dotfiles}/${f} ${HOME}/")
      else
        (test -n "${verbose}" && set -x; eval "cp --symbolic-link --verbose --update ${backup} ${dotfiles}/${f} ${HOME}/${f}")
      fi
    fi
  done
}

installPackages() {
  declare -g packages=()
  # Automatically trims leading whitespace (which is good)
  while IFS='' read line; do
    if [[ "${line}" == \;* ]] || test -z "${line}" -o "${line}" = " " || (test -z "${section}" && ! [[ "${line}" == \[*] ]]); then # Ignore comments and lines before the first section
      test -n "${verbose}" && echo "Comment: ${line}"
      continue
    elif [[ "${line}" == \[*] ]]; then # Set section
      section=$(sed 's/^\[\(.*\)\]/\1/' <<< "${line}") # Extract section name from section string
      test -n "${verbose}" && echo "Section: ${line} (${section})"
    elif [[ "${line}" == *=* ]]; then
      while IFS='=' read var val; do
        test -n "${verbose}" && echo "Var: ${line} (Var:${var} Val:${val} Section:${section})"
        declare "$var[$section]=$val"
      done <<< "${line}"
    else #elif [[ "${line}" == *\ * ]]; then
      test -n "${verbose}" && echo "Package: ${line}"
      packages+=( "${line}" )
    fi
  done < "${config}"

  export DEBIAN_FRONTEND=noninteractive
  for index in ${!packages[@]}; do
    if [[ "${packages[$index]}" == *\ * ]]; then
      test -n "${verbose}" && echo "${packages[$index]}"
      echo "${packages[$index]}"
    else
      test -n "${verbose}" && echo "${prefix[settings]} ${packages[$index]} ${suffix[settings]}"
      echo "${prefix[settings]} ${packages[$index]} ${suffix[settings]}"
    fi
  done
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
    -e|--ignore-error)
      ignoreError='true'
      shift;;
    -v|--verbose)
      verbose='true'
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

test -n "${ignoreError}"     && set +o errexit
test -n "${requireSudo}"     && elevate
test -n "${deployConfigs}"   && deployConfigs
test -n "${installPackages}" && installPackages
