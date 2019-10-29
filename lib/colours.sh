#!/bin/sh
# 16 colors - as seen here: https://misc.flogisoft.com/bash/tip_colors_and_formatting
# E_ - Effect
# R_ - Reset
# C_ - Color
# B_ - Background

export RESET=$'\e[0;39m'

export E_BOLD=$'\e[1m'
export E_DIM=$'\e[2m'
export E_UNDERLINE=$'\e[4m'
export E_BLINK=$'\e[5m'
export E_INVERT=$'\e[7m'
export E_HIDDEN=$'\e[8m'

export R_NORMAL=$'\e[0m'
export R_BOLD=$'\e[21m'
export R_DIM=$'\e[22m'
export R_UNDERLINE=$'\e[24m'
export R_BLINK=$'\e[25m'
export R_INVERT=$'\e[27m'
export R_HIDDEN=$'\e[28m'

export C_DEFAULT=$'\e[19m'
export C_BLACK=$'\e[30m'
export C_RED=$'\e[31m'
export C_GREEN=$'\e[32m'
export C_YELLOW=$'\e[33m'
export C_BLUE=$'\e[34m'
export C_MAGENTA=$'\e[35m'
export C_CYAN=$'\e[36m'
export C_LGRAY=$'\e[37m'
export C_DGRAY=$'\e[90m'
export C_LRED=$'\e[91m'
export C_LGREEN=$'\e[92m'
export C_LYELLOW=$'\e[93m'
export C_LBLUE=$'\e[94m'
export C_LMAGENTA=$'\e[95m'
export C_LCYAN=$'\e[96m'
export C_WHITE=$'\e[97m'

export B_DEFAULT=$'\e[49m'
export B_BLACK=$'\e[40m'
export B_RED=$'\e[41m'
export B_GREEN=$'\e[42m'
export B_YELLOW=$'\e[43m'
export B_BLUE=$'\e[44m'
export B_MAGENTA=$'\e[45m'
export B_CYAN=$'\e[46m'
export B_LGRAY=$'\e[47m'
export B_DGRAY=$'\e[100m'
export B_LRED=$'\e[101m'
export B_LGREEN=$'\e[102m'
export B_LYELLOW=$'\e[103m'
export B_LBLUE=$'\e[104m'
export B_LMAGENTA=$'\e[105m'
export B_LCYAN=$'\e[106m'
export B_WHITE=$'\e[106m'

# Stop sourcing
if [ -n "$ZSH_EVAL_CONTEXT" ]; then
  case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
  [ "$(cd $(dirname -- $0) && pwd -P)/$(basename -- $0)" != "$(cd $(dirname -- ${.sh.file}) && pwd -P)/$(basename -- ${.sh.file})" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
  (return 0 2>/dev/null) && sourced=1
else # All other shells: examine $0 for known shell binary filenames
  # Detects `sh` and `dash`; add additional shell filenames as needed.
  case ${0##*/} in sh|dash) sourced=1;; esac
fi

[ "$sourced" = 1 ] && return 0
echo 'Script was not sourced, continuing.'
