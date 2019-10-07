#!/bin/bash
set -e
#trap 'exit' ERR

# TODO: deploy files
# TODO: Take backup of linked files
# TODO: Restore backup
# TODO: --include-root to include root folder (default skipped)
# TODO: Write layout documentation# TODO: Write layout documentation.

# Import colors
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $SDIR/colors.sh

# Set default variables
AURMAN="yay"
GIT="git@github.com:runarsf/dotfiles.git"
WHATIF=false
PACKAGEFILE="packages.csv"

debug() {
	printf "${E_BOLD}Enabling debug mode.${RESET}\n"
	set -x
	trap 'printf "%3d: " "$LINENO"' DEBUG
}

notify() {
	[ "$1" = "INFO" ] && printf "${C_BLUE}INFO${RESET}    $2\n" | tee -a $SDIR/run.log
	[ "$1" = "ERR" ] && printf "${C_RED}WARN${RESET}    $2\n" | tee -a $SDIR/run.log
	[ "$1" = "NOOP" ] && printf "${C_GREEN}NOOP${RESET}    $2\n" | tee -a $SDIR/run.log
	[ "$1" = "TIME" ] && printf "${C_MAGENTA}TIME${RESET}    $2\n" | tee -a $SDIR/run.log
	if [ "$1" = "PROMPT" ]; then
		printf "${C_CYAN}PROMPT${RESET}  $2 [y/N]"
		read -p " " -n 1 -r </dev/tty
		printf "\n"
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			return 1
		fi
	fi
}

helpme() {
	printf "Usage: deploy.sh [args]\n"
	printf " -h          Show this dialog.\n"
	printf " -d          Enable debug mode.\n"
	printf " -a   ${C_LGRAY}[opt]${RESET}  Custom AUR manager.\n"
	printf "      ${C_LGRAY}<inf>${RESET}  The manager used to install AUR packages. Needs to be invoked before ${C_BOLD}-p${RESET}.\n"
	printf "      ${C_LGRAY}<def>${RESET}  $AURMAN\n"
	printf " -p          Install packages from packages.csv.\n"
	printf " -g   ${C_LGRAY}[opt]${RESET}  Custom dotfiles git repository.\n"
	printf "      ${C_LGRAY}<inf>${RESET}  A git url, either SSH or HTTPS.\n"
	printf "      ${C_LGRAY}<def>${RESET}  $GIT\n"
	printf " -f   ${C_LGRAY}[opt]${RESET}  Custom packages.csv file.\n"
	printf "      ${C_LGRAY}<inf>${RESET}  Full or relative path to a .csv file.\n"
	printf "      ${C_LGRAY}<def>${RESET}  packages.csv\n"
	printf " -w|n        Emulates the PowerShell WhatIf flag (no-op), display modifications without making any changes.\n"
	printf " -i          Ignore errors.\n"
	printf " -x   ${C_LGRAY}[opt]${RESET}  Execute code from within the script, can be used to run functions.\n"
	printf "      ${C_LGRAY}<inf>${RESET}  Bash code.\n"
	printf "\n"
	printf "${C_BOLD}NB!${RESET} Make sure to invoke the arguments in the correct order.\n"
	printf "The packages in packages.csv will be installed in chronological order.\n"
	printf "If you want to install the AUR manager automatically, make sure it's at the top of your packages.csv file.\n"
	printf "${C_LGRAY}[opt]${RESET} - The argument requires an option.\n"
	printf "${C_LGRAY}<inf>${RESET} - Information about the option.\n"
	printf "${C_LGRAY}<def>${RESET} - The default option value. If nothing is provided, the default is NULL.\n"
}

packages() {
	notify "TIME" $(date +"%d%m%y-%H%M%S")
	while IFS=, read -r package location skip; do
		[ "$package" = "package" ] && continue
		[ ${package:0:1} = "#" ] && skip="true"
		if [ "$skip" = "true" ]; then
			[ "$WHATIF" = false ] && notify "INFO" "Skipped $package."
		else
			if [ "$location" = "pacman" ]; then
				[ "$WHATIF" = true ] && notify "NOOP" "pacman -S $package"
				if [ "$WHATIF" = false ]; then
					pacman -S $package && notify "INFO" "Installed $package from $location." || notify "ERR" "The command 'pacman -S $package' returned a non-zero code: $?"
				fi
			elif [ "$location" = "aur" ]; then
				[ "$WHATIF" = true ] && notify "NOOP" "$AURMAN -S $package"
				if [ "$WHATIF" = false ]; then
					$AURMAN -s $package && notify "INFO" "Installed $package from $location." || notify "ERR" "The command '$AURMAN -s $package' returned a non-zero code: $?"
				fi
			elif [ "$location" = "custom" ]; then
				[ "$WHATIF" = true ] && notify "NOOP" "custom $package"
				if [ "$WHATIF" = false ]; then
					custom $package && notify "INFO" "Installed $package from $location." || notify "ERR" "The command 'custom $package' returned a non-zero code: $?"
				fi
			elif [ "$location" = "zsh-plugin" ]; then
				[ "$WHATIF" = true ] && notify "NOOP" "zshPlugin $package"
				if [ "$WHATIF" = false ]; then
					zshPlugin $package && notify "INFO" "Installed $package from $location." || notify "ERR" "The command 'zshPlugin $package' returned a non-zero code: $?"
				fi
			elif [ "$location" = "zsh-theme" ]; then
				[ "$WHATIF" = true ] && notify "NOOP" "zshTheme $package"
				if [ "$WHATIF" = false ]; then
					zshTheme $package && notify "INFO" "Installed $package from $location." || notify "ERR" "The command 'zshTheme $package' returned a non-zero code: $?"
				fi
			else
				notify "ERR" "Location $location is undefined. Skipping $package."
				continue
			fi
		fi
	done < $PACKAGEFILE
}

custom() {
	if [ "$1" = "oh-my-zsh" ]; then
		if [ ! -d "$HOME/.oh-my-zsh/" ]; then
			{
				{
					sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
				} || {
					sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
				}
			}
		else
			notify "ERR" "oh-my-zsh already installed."
			return 1
		fi
	elif [ "$1" = "vundle" ]; then
		if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
			mkdir -p ~/.vim/bundle
			git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
			vim +PluginInstall +qall
		else
			notify "ERR" "Vundle already installed."
			return 1
		fi
	elif [ "$1" = "fonts" ]; then
		if [ ! -d ~/.fonts ]; then
			git clone https://github.com/runarsf/fonts.git ~/.fonts
			fc-cache -f -v
		elif [ ! -d ~/.fonts/.git ]; then
			git clone https://github.com/runarsf/fonts.git ~/.fontsrepo
			mv ~/.fonts ~/.fontsrepo/.fonts_backup
			mv ~/.fontsrepo ~/.fonts
			mv ~/.fonts/.fonts_backup/*.* ~/.fonts/
			fc-cache -f -v
		else
			notify "ERR" "~/.fonts already exists and is a git repo."
			return 1
		fi
	else
		notify "ERR" "No custom function named $1 defined."
		return 1
	fi
}

zshPlugin() {
	mkdir -p ~/.oh-my-zsh/custom/plugins
	basename=$(basename $1)
	repo=${basename%.*}

	[ ! -d ~/.oh-my-zsh/custom/plugins/$repo ] && git clone $1 ~/.oh-my-zsh/custom/plugins/$repo
	[ -d ~/.oh-my-zsh/custom/plugins/$repo ] && notify "INFO" "zsh-plugin $repo already installed." && return 1
}

zshTheme() {
	mkdir -p ~/.oh-my-zsh/custom/themes
	basename=$(basename $1)
	repo=${basename%.*}

	git clone $1 ../$repo || notify "PROMPT" "$(cd .. && pwd)/$repo already exists. Continue with existing folder?" || return 1
	PASSED=1
	for file in ../$repo/*.zsh-theme; do
		filename="${file##*/}"
		if [ ! -f ~/.oh-my-zsh/custom/themes/$filename ]; then
			echo ln -s $(cd .. && pwd)/$repo/$filename $HOME/.oh-my-zsh/custom/themes/$filename
			PASSED=0
		else
			notify "ERR" "$filename already linked."
		fi
	done
	return $PASSED
}

csvFile() {
	basename=$(basename $GIT)
	repo=${basename%.*}

	[ ! -d ~/git/ ] && mkdir -p ~/git
	git clone $GIT ~/git/$repo
}

tester() {
	echo 'ayy'
}

# Parse arguments
[ "$#" -lt 1 ] && notify "ERR" "${C_RED}Too ${C_YELLOW}few ${C_RED}arguments!${RESET}" && exit 1
while getopts dhpg:a:wnif:x: option; do
	case "${option}" in
		d) debug;;
		h) helpme;;
		p) packages;;
		a) AURMAN=${OPTARG};;
		g) GIT=${OPTARG};;
		w|n) WHATIF=true;;
		x) ${OPTARG};;
		i) set +e;;
		f) PACKAGEFILE=${OPTARG};;
	esac
done
