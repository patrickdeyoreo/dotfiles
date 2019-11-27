# ~/.profile: login shell initialization script
# see sh(1), bash(1), dash(1), ...

# Import user environment from systemd
import_systemd_user_env()
{
    local envblacklist=''
    while read -r REPLY
    do
        case "${REPLY%%=*}" in
            *[![:alnum:]_]*)
              ;;
            DBUS_SESSION_BUS_ADDRESS|DISPLAY|TERM|TMPDIR|XTERM_VERSION)
              ;;
            ?*)
              eval '
              if test -z "${'"${REPLY%%=*}"'+_}"
              then
                export '"${REPLY}"'
              fi'
              ;;
        esac
    done
} << EOF
$(systemctl --user show-environment 2>/dev/null)
EOF

## Import environment
import_systemd_user_env

# Initialize terminal
if test -t 0 && command -v tput 1>/dev/null
then
    tput init
fi


# Set file creation mode mask
if test "${UID:-"$(id -u)"}" -eq 0
then
    umask 0002
else
    umask 0022
fi


# Prepend executable paths
for _ in  "${HOME-}/.local/bin" "${HOME-}/.bin" "${HOME-}/bin"
do
    if test -d "$_"
    then
        case ":${PATH-}:" in
            *":$_:"*)
                ;;
            *)  export PATH="${_}${PATH:+:${PATH}}"
                ;;
        esac
    fi
done


# Load additional profile config
# shellcheck disable=SC1090
if test -d "${HOME-}/.profile.d"
then
    for _ in "${HOME-}/.profile.d"/*.sh
    do
        if test -f "$_" && test -r "$_"
        then
            . "$_"
        fi
    done
fi


# Import environment from systemd
import_systemd_user_env()
{
    local REPLY || return 0

    while read -r REPLY
    do
        case "${REPLY%%=*}" in
            [0-9]*|*[!A-Za-z0-9_]*)
                ;;
            *)  eval 'test -n "${'"${REPLY%%=*}"'+_}" || export '"${REPLY}"
                ;;
        esac
    done
} << EOF
$(systemctl --user show-environment 2>/dev/null)
EOF


# Import systemd environment
import_systemd_user_env


## Termcap should be dead; kill it
unset -v TERMCAP


## Man is much better at figuring this out than we are
unset -v MANPATH


# vi:ft=sh
