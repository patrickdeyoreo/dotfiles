## 10-overrides.sh : shell builtin overrides


## Construct self-referential aliases from a template
## alias -R variable template [alias ... ]

alias() {
  trap "$(
  : "$(trap -p ERR)";     printf '%s\n' "${_:-trap - ERR}"
  : "$(trap -p RETURN)";  printf '%s\n' "${_:-trap - RETURN}"
  )" RETURN

  trap '{ cat >&2; return 2; } <<\@HELP
alias: alias [-p] [name[=value] ... ]
       alias  -R  variable template [alias ... ]
@HELP
' ERR

  if [[ $1 = -R ]]; then
    shift
    set -- "${@/%/=$2}" "$1"
    shift
    shift
    while (( $# > 1 )); do
      set -- "${1%%=*}" "${1#*=}" "${@:2}"
      : "$( { { alias "$1" 2>/dev/null || printf '%s' "$1" 1>&2
            } | sed 's/^[^=]*='"'"'\(.*\)'"'"'$/\1/' 2>/dev/null
          } 2>&1)"
      builtin alias "$1"="${2//"${!#}"/$_}"
      shift
      shift
    done
  else
    builtin alias "$@"
  fi
} && declare -ft alias



## Make the specified directories, then cd into the last one
## mkcd [options] directory ...
mkcd() {
  trap "$(
  : "$(trap -p ERR)";     printf '%s\n' "${_:-trap - ERR}"
  : "$(trap -p RETURN)";  printf '%s\n' "${_:-trap - RETURN}"
  )" RETURN

  trap '{ cat >&2; return 2; } <<\@HELP
mkcd: mkcd [options] directory ...
@HELP' ERR

  mkdir "$@"
  cd -- "${!#}"
} && declare -ft mkcd



## cd into a directory and print its contents
## cdls [options] directory
cdls() {
  trap "$(
  : "$(trap -p ERR)";     printf '%s\n' "${_:-trap - ERR}"
  : "$(trap -p RETURN)";  printf '%s\n' "${_:-trap - RETURN}"
  )" RETURN

  trap '{ cat >&2; return 2; } <<\@HELP
cdls: cdls [options] directory
@HELP' ERR
  cd "${@##!(-@(L|P|e|@))/}" && ls "${@/%%-!(-!(L|P|e|@))/}"
} && declare -ft cdls



## cd upward by "height" (or to root directory, whichever comes first)
## up [options] [height]
up() {
  if (($# == 0)); then
    cd ..
  elif [[ ${@/%!(--help)/} = *-* ]]; then
    printf 'up: up [options] [height]\n'
  elif [[ ${!#} = -* ]]; then
    cd "$@" ..
  elif set -- "${PWD//'/'+([^'/'])/../}" "$@"   \
    && [[ "$1" =~ ${1//'/'//(}${1//'../'/)} ]]  \
    && shift                                    \
    && ((_ = ${!#},  ++_ > 0)) 2> /dev/null
  then
    cd "${@:1:$# ? ($# - 1) : 0}" "${BASH_REMATCH[(-_ % ${#BASH_REMATCH[@]})]}"
  else
    printf 'up: %s: invalid expression\n' "${!#@Q}" >&2
    return 2
  fi
} && declare -ft up