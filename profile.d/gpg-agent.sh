# gpg-agent.sh : gpg-agent config
# see gpg-agent(1)

# Set GPG_TTY to the tty on stdin
if GPG_TTY="$(tty)"
then export GPG_TTY
else unset  GPG_TTY
fi

# Refresh gpg-agent
gpg-connect-agent updatestartuptty /bye 1> /dev/null 2>&1

# Configure SSH to use gpg-agent
if ! test -S "${SSH_AUTH_SOCK-}"
then
  unset SSH_AGENT_PID
  if test "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne "$$"
  then
    if SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    then export SSH_AUTH_SOCK
    else unset  SSH_AUTH_SOCK
    fi
  fi
fi

# vi:ft=sh
