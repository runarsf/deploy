#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
#trap 'exit' ERR

# Import colors
source ./colors.sh

debug() {
	printf "${E_BOLD}Enabling debug mode.${RESET}\n"
	set -x
	trap 'printf "%3d: " "$LINENO"' DEBUG
}

helpme() {
	printf "Usage: deploy.sh [args]\n"
	printf " -h        Show this dialog.\n"
	printf " -d        Enable debug mode.\n"
	printf " -g [opt]  Custom dotfiles git repository.\n"
	printf "    <opt>  A git url, either SSH or HTTPS.\n"
	printf "    <def>  git@github.com:runarsf/dotfiles.git\n"
	printf " -f [opt]  Custom dotfiles folder.\n"
	printf "    <inf>  Full or relative path to a folder.\n"
	printf "\n"
	printf "If you provide a custom dotfiles folder or repo with a packages.csv file, the script will attempt to install the defined packages.\n"
	printf "[opt] - The argument requires an option.\n"
	printf "<inf> - Information about the option.\n"
	printf "<def> - The default option value. If nothing is provided, the default is NULL.\n"
}

# Parse arguments
[ "$#" -lt 1 ] && printf "${C_RED}Too ${C_YELLOW}few ${C_RED}arguments!${RESET}\n" && exit 1
while getopts dhg: option; do
	case "${option}" in
		d) debug;;
		h) helpme;;
		g) GIT=${OPTARG};;
	esac
done
