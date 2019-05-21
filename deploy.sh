#!/bin/bash

# Import colors
source ./colors.sh

# Set default variables
AURMAN="yay"
GIT="git@github.com:runarsf/dotfiles.git"
WHATIF=false

debug() {
	printf "${E_BOLD}Enabling debug mode.${RESET}\n"
	# Exit immediately if a command exits with a non-zero status.
	set -e
	#trap 'exit' ERR
	set -x
	trap 'printf "%3d: " "$LINENO"' DEBUG
}

helpme() {
	printf "Usage: deploy.sh [args]\n"
	printf " -h        Show this dialog.\n"
	printf " -d        Enable debug mode.\n"
	printf " -a ${C_LGRAY}[opt]${RESET}  Custom AUR manager.\n"
	printf "    ${C_DGRAY}<inf>${RESET}  The manager used to install AUR packages. Needs to be invoked before ${C_BOLD}-p${RESET}.\n"
	printf "    ${C_DGRAY}<def>${RESET}  $AURMAN\n"
	printf " -p        Install packages from packages.csv.\n"
	printf " -g ${C_LGRAY}[opt]${RESET}  Custom dotfiles git repository.\n"
	printf "    ${C_DGRAY}<inf>${RESET}  A git url, either SSH or HTTPS.\n"
	printf "    ${C_DGRAY}<def>${RESET}  $GIT\n"
	printf " -f ${C_LGRAY}[opt]${RESET}  Custom dotfiles folder.\n"
	printf "    ${C_DGRAY}<inf>${RESET}  Full or relative path to a folder.\n"
	printf " -w        Emulates the PowerShell WhatIf flag, display modifications without making any changes.\n"
	printf "\n"
	printf "${C_BOLD}NB!${RESET} Make sure to invoke the arguments in the correct order.\n"
	printf "${C_LGRAY}[opt]${RESET} - The argument requires an option.\n"
	printf "${C_DGRAY}<inf>${RESET} - Information about the option.\n"
	printf "${C_DGRAY}<def>${RESET} - The default option value. If nothing is provided, the default is NULL.\n"
}

packages() {
	while IFS=, read -r package location skip; do
		[ "$package" = "package" ] && continue
		if [ "$skip" = "true" ]; then
			[ "$WHATIF" = false ] && printf "Skipped ${C_CYAN}$package${RESET}.\n"
		else
			if [ "$location" = "pacman" ]; then
				[ "$WHATIF" = true ] && echo "pacman -S $package"
				[ "$WHATIF" = false ] && echo "ACTUALLY pacman -S $package"
			elif [ "$location" = "aur" ]; then
				[ "$WHATIF" = true ] && echo "$AURMAN -S $package"
				[ "$WHATIF" = false ] && echo "ACTUALLY $AURMAN -S $package"
			elif [ "$location" = "custom" ]; then
				echo "custom $package"
			else
				printf "${C_RED}Location ${E_BOLD}$location${RESET}${C_RED} is undefined. Skipping ${C_YELLOW}${E_BOLD}$package${RESET}.\n"
				continue
			fi
			[ "$WHATIF" = false ] && printf "Installed ${C_GREEN}${E_BOLD}$package${RESET} from ${E_BOLD}$location${RESET}.\n"
		fi
	done < packages.csv
}

# Parse arguments
[ "$#" -lt 1 ] && printf "${C_RED}Too ${C_YELLOW}few ${C_RED}arguments!${RESET}\n" && exit 1
while getopts dhpg:a:w option; do
	case "${option}" in
		d) debug;;
		h) helpme;;
		p) packages;;
		a) AURMAN=${OPTARG};;
		g) GIT=${OPTARG};;
		w) WHATIF=true;;
	esac
done
