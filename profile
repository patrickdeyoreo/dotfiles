## ~/.profile : login shell initialization script
## see sh(1), bash(1), dash(1), ...


## Import environment from systemd instance
eval export $(systemctl --user show-environment 2>/dev/null)


## Initialize the terminal
if test -t 0 && command -v tput 1>/dev/null; then
  tput init
fi


## Set file creation mode mask
if test "${UID:-"$(id -u)"}" -eq 0; then
  umask 0002
else
  umask 0022
fi


## Prepend my executable paths
for _ in  "${HOME-}/.local/bin" "${HOME-}/bin"; do
  if test -d "$_"; then
    case ":${PATH-}:" in
      *":$_:"*)
        ;;
      *)
        PATH="$_${PATH:+":${PATH-}"}"
        ;;
    esac
  fi
done
export PATH


## Load additional config
if test -d "${1:-"${HOME-}/.profile.d"}"; then
  for _ in "${1:-"${HOME-}/.profile.d"}"/*.sh; do
    if test -f "$_" && test -r "$_"; then
      . "$_"
    fi
  done 1>/dev/null
fi


## Termcap should be dead; kill it
unset -v TERMCAP

## Man is much better at figuring this out than we are
unset -v MANPATH
