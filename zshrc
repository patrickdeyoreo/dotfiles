# zshrc: zsh initialization script for interactive shells
# Initialization script evaluation order:
# zshenv, zprofile, zshrc, zlogin
# see zsh(1)

# If this is not an interactive shell, abort.
case "$-" in
  (*i*) ;;
  (*) return ;;
esac

# Path to the ohmyzsh installation.
if test -v ZDOTDIR; then
  ZSH="${ZDOTDIR:-${HOME}}/.ohmyzsh"
else
  ZSH="${XDG_CONFIG_HOME:-${HOME}/.config}/ohmyzsh"
fi

# Fallback light/dark guess: GNOME color-scheme (mirrored by many KDE
# setups), else time of day. Only called when the OSC 11 query below gets no
# answer, so the common path never forks gsettings.
_theme_variant_guess() {
  emulate -L zsh
  [[ -n ${THEME_VARIANT-} ]] && return
  local scheme hour
  if (( $+commands[gsettings] )); then
    scheme="$(gsettings get org.gnome.desktop.interface color-scheme 2> /dev/null)"
  fi
  case "${scheme}" in
    (*dark*)  THEME_VARIANT="dark" ;;
    (*light*) THEME_VARIANT="light" ;;
    (*)
      zmodload -F zsh/datetime b:strftime p:EPOCHSECONDS 2> /dev/null
      strftime -s hour '%H' "${EPOCHSECONDS}" 2> /dev/null || hour=0
      if (( hour >= 7 && hour < 19 )); then
        THEME_VARIANT="light"
      else
        THEME_VARIANT="dark"
      fi
      ;;
  esac
  export THEME_VARIANT
}

# Resolve this file's directory (the dotfiles repo) once; %x is only reliable
# while sourcing, but the helpers below also run interactively.
typeset -g _dotfiles_etc="${${(%):-%x}:A:h}"

# Detect the terminal background (light/dark) via OSC 11 and derive color
# settings from it. detect-term-bg.sh is sourced (not executed) so it runs
# in-process; term-bg-sync re-runs detection on demand (bind it to a key or
# call it after toggling your terminal theme). Falls back to THEME_VARIANT.
[[ -r $_dotfiles_etc/scripts/detect-term-bg.sh ]] && source "$_dotfiles_etc/scripts/detect-term-bg.sh"

# Assemble starship's active theme + the background-appropriate palette into a
# cache file and point $STARSHIP_CONFIG at it. starship re-reads it each prompt,
# so a resync makes the prompt follow light/dark without restarting the shell.
_starship_palette() {
  emulate -L zsh
  command -v starship > /dev/null || return
  local name cache theme palette line
  case ${TERM_BACKGROUND:-dark} in
    light) name=catppuccin_latte ;;
    *)     name=catppuccin_mocha ;;
  esac
  theme="$_dotfiles_etc/starship/starship.toml"
  palette="$_dotfiles_etc/starship/palettes/$name.palette.toml"
  [[ -r $theme && -r $palette ]] || return
  cache="${XDG_CACHE_HOME:-$HOME/.cache}/starship.toml"
  # Cache hit: first line already names this palette and the file is newer
  # than both sources -- skip the forks and the rewrite.
  if [[ -r $cache && $cache -nt $theme && $cache -nt $palette ]] \
    && IFS= read -r line < "$cache" 2>/dev/null \
    && [[ $line == "palette = \"$name\"" ]]; then
    export STARSHIP_CONFIG="$cache"
    return
  fi
  mkdir -p "${cache:h}" 2>/dev/null
  {
    print -r -- "palette = \"$name\""
    grep -vE '^palette[[:space:]]*=' "$theme"
    cat "$palette"
  } > "$cache" 2>/dev/null && export STARSHIP_CONFIG="$cache"
}

# Re-source the tmux statusline theme for the current background. Server-global,
# so the last client to resync wins if two are attached in different polarities.
_tmux_theme() {
  emulate -L zsh
  [[ -n $TMUX ]] || return
  tmux set -g @bg "${TERM_BACKGROUND:-dark}" 2>/dev/null
  tmux source-file -F "#{@theme_dir}/tmux-theme.conf" 2>/dev/null
}

# Re-point the dark|light base in the fzf opts arrays so a live theme flip
# reaches fzf too. No-op at startup (the arrays are built further down and
# bake in the current TERM_BACKGROUND); matters on later re-applies.
_fzf_sync_colors() {
  emulate -L zsh
  local want=${TERM_BACKGROUND:-dark} other arr
  [[ $want == light ]] && other=dark || other=light
  for arr in fzf_default_opts fzf_completion_opts fzf_alt_c_opts \
    fzf_ctrl_t_opts fzf_ctrl_r_opts; do
    (( ${(P)+arr} )) || continue
    # both spellings: generated defaults quote the value, fzfrc carries it bare
    eval "${arr}=(\"\${${arr}[@]//--color='${other},/--color='${want},}\")"
    eval "${arr}=(\"\${${arr}[@]//--color=${other},/--color=${want},}\")"
  done
}

# Apply a known background (light|dark) to this shell: export the signal, map
# VIVID_THEME (the lscolors precmd then regenerates LS_COLORS), and refresh
# starship + tmux + fzf. No detection — the caller supplies the variant.
_term_bg_apply() {
  emulate -L zsh
  export TERM_BACKGROUND="$1"
  case $1 in
    light) export VIVID_THEME=cyberdream-light ;;
    *)     export VIVID_THEME=cyberdream ;;
  esac
  _starship_palette
  _tmux_theme
  _fzf_sync_colors
}

term-bg-sync() {
  emulate -L zsh
  local bg
  (( $+functions[detect_term_bg] )) && bg="$(detect_term_bg)"
  if [[ -z ${bg} ]]; then
    _theme_variant_guess
    bg="${THEME_VARIANT:-dark}"
  fi
  _term_bg_apply "${bg}"
}

# Follow set-term-theme live: it writes the active variant to this file; check
# it cheaply each prompt (zsh reads $(<file) without a fork) and re-apply only
# when it *changes* — so a manual terminal tweak isn't clobbered by a stale file.
_term_bg_file="${XDG_CACHE_HOME:-$HOME/.cache}/term-theme.txt"
_term_bg_watch() {
  emulate -L zsh
  local want
  [[ -r $_term_bg_file ]] && want="$(<$_term_bg_file)" || return
  [[ $want == $_term_bg_seen ]] && return
  _term_bg_seen=$want
  [[ -n $want ]] && _term_bg_apply "$want"
}

# Establish this shell's background, and seed the watcher so the first prompt
# doesn't re-apply over it: a fresh shell trusts OSC detection (seed from the
# file, so a stale file can't clobber it); a nested shell seeds from the
# inherited value (so the watcher still catches up if the file moved on).
typeset -g _term_bg_seen=
if [[ -v TERM_BACKGROUND ]]; then
  _tmux_theme
  _term_bg_seen=$TERM_BACKGROUND
else
  term-bg-sync
  [[ -r $_term_bg_file ]] && _term_bg_seen="$(<$_term_bg_file)"
fi
autoload -Uz add-zsh-hook
add-zsh-hook precmd _term_bg_watch
# Zoxide (use 'z' / 'zi')
#
if command -v zoxide > /dev/null; then
  eval "$(zoxide init zsh --cmd z)"
  _zoxide_zi_widget() { zi; zle reset-prompt }
  zle -N _zoxide_zi_widget
fi

# FZF
#
export FZF_COMPLETION_TRIGGER='^s'

if test -f "${XDG_CONFIG_HOME:-${HOME}/.config}"/fzf/fzf.zsh; then
  source "${XDG_CONFIG_HOME:-${HOME}/.config}"/fzf/fzf.zsh
elif command -v fzf > /dev/null; then
  eval "$(fzf --zsh 2> /dev/null)"
fi

if test -f "${XDG_CONFIG_HOME:-${HOME}/.config}/broot/launcher/bash/br"; then
  source "${XDG_CONFIG_HOME:-${HOME}/.config}/broot/launcher/bash/br"
fi

ZSH_THEME=""
DISABLE_AUTO_UPDATE="true"

# export FAST_THEME="q-jmnemonic"
export FAST_THEME="sv-plant"
# export FAST_THEME="zdharma"
# export FAST_THEME="base16"

# VIVID_THEME is selected dynamically near the top of this file from the
# terminal's background color. Uncomment one of these to pin it instead.
# export VIVID_THEME='embark'
# export VIVID_THEME='tokyonight-night'
# export VIVID_THEME='carbonfox'
# export VIVID_THEME='cyberdyne'
# export VIVID_THEME='cyberpunk'
# export VIVID_THEME='cyberdream'
# export VIVID_THEME='cyberdream-light'
# export VIVID_THEME='kanso-pearl'
# export VIVID_THEME='modus-vivendi'
# export VIVID_THEME='poimandres'
# export VIVID_THEME='xcode-dark-hc'

# Path to the ohmyzsh installation.
#
if test -v ZSH && test -d "${ZSH}"; then
  export ZSH
elif test -n "${ZDOTDIR-}" && test -d "${ZDOTDIR}/.ohmyzsh"; then
  export ZSH="${ZDOTDIR}/.ohmyzsh"
elif test -n "${XDG_CONFIG_HOME-}" && test -d "${XDG_CONFIG_HOME}/ohmyzsh"; then
  export ZSH="${XDG_CONFIG_HOME}/ohmyzsh"
elif test -n "${HOME-}" && test -d "${HOME}/.config/ohmyzsh"; then
  export ZSH="${HOME}/.config/ohmyzsh"
elif test -n "${HOME-}" && test -d "${HOME}/.ohmyzsh"; then
  export ZSH="${HOME}/.ohmyzsh"
else
  unset ZSH
fi

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  archlinux
  aws
  brew
  codex
  ctags
  docker
  extract
  fancy-ctrl-z
  fancy-ctrl-q
  firewalld
  lscolors
  gh
  git
  golang
  zsh-history-substring-search
  iterm2
  mkcd
  nmap
  npm
  pass
  pip
  python
  rsync
  shrink-path
  starship
  sudo
  systemd
  terraform
  themes
  tmux
  uv
  venv
  zshaliases
  zshoptions
  zshparam
  keybindings
  globalias-alt
  clipboard-keybindings
  fast-syntax-highlighting
  zsh-interactive-cd
  zsh-autosuggestions
  # zsh-autocomplete
  # zstyles
)

# Login and non-login shells get separate completion-dump caches: their
# $fpath legitimately differs (login mode also runs profile.d), so a
# shared cache invalidates itself whenever the shell type alternates -- a
# full ~900ms compinit rebuild each time. Set before oh-my-zsh loads to
# pre-empt its own shared default.
if [[ -o login ]]; then
  ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump-${HOST}-${ZSH_VERSION}-login"
else
  ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump-${HOST}-${ZSH_VERSION}-nonlogin"
fi

# Load oh-my-zsh
#
if test -v ZSH; then
  if test -f "${ZSH}/oh-my-zsh.sh"; then
    source "${ZSH}/oh-my-zsh.sh"
  fi

  # Set completion keys
  #
  bindkey '^I' expand-or-complete

  # fzf interactive cd
  #
  bindkey '^@' zic-completion

  # zoxide interactive jump
  #
  bindkey '^[z' _zoxide_zi_widget

  # fzf history search: oh-my-zsh's lib/key-bindings.zsh unconditionally
  # rebinds ^R to the builtin incremental search, clobbering the fzf
  # binding set up earlier when fzf.zsh was sourced -- restore it here.
  #
  bindkey '^R' fzf-history-widget

  # zsh-autocomplete: longest common substring matching
  # zstyle ':completion:*:*' matcher-list 'm:{[:lower:]-}={[:upper:]_}' '+r:|[.]=**'

  # zsh-autocomplete: Tab widgets
  # zstyle ':autocomplete:*complete*:*' insert-unambiguous yes
  # zstyle ':autocomplete:*history*:*' insert-unambiguous yes
  # zstyle ':autocomplete:menu-search:*' insert-unambiguous yes

  # zsh-autocomplete: make Tab/ShiftTab cycle completions
  # bindkey              '^I'         menu-complete
  # bindkey "$terminfo[kcbt]" reverse-menu-complete
  # bindkey -M menuselect              '^I'         menu-complete
  # bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete

fi

# Mark 'run-help' for autoloading (-X: load THIS function from fpath on first call)
#
if alias run-help >/dev/null 2>&1; then
  unalias run-help
fi
function run-help() {
  autoload -XUz
}
alias help='run-help'

# Configure less defaults
#
export LESS="${LESS:-"-FiQRSX --mouse"}"

# Configure man pager
#
if test -n "${MANPAGER-}"; then
  export MANPAGER
elif command -v nvim > /dev/null; then
  export MANPAGER='nvim +Man!'
elif command -v vim > /dev/null; then
  export MANPAGER='vim -M +MANPAGER -'
elif command -v bat > /dev/null; then
  export MANPAGER='bat --language=Manpage --paging=auto --decorations=auto --color=auto --style=grid,snip -- -'
fi

# Setup fzf default options
#
export -T FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-}" fzf_default_opts " "
if test -f "${FZF_DEFAULT_OPTS_FILE:-}"; then
  export FZF_DEFAULT_OPTS_FILE
  fzf_default_opts=( "${(f)$(< "${FZF_DEFAULT_OPTS_FILE}")[@]}" )
elif test -f "${XDG_CONFIG_HOME:-${HOME}/.config}/fzf/fzfrc"; then
  export FZF_DEFAULT_OPTS_FILE="${XDG_CONFIG_HOME:-${HOME}/.config}/fzf/fzfrc"
  fzf_default_opts=( "${(f)$(< "${FZF_DEFAULT_OPTS_FILE}")[@]}" )
elif test -f "${XDG_CONFIG_HOME:-${HOME}/.config}/fzfrc"; then
  export FZF_DEFAULT_OPTS_FILE="${XDG_CONFIG_HOME:-${HOME}/.config}/fzfrc"
  fzf_default_opts=( "${(f)$(< "${FZF_DEFAULT_OPTS_FILE}")[@]}" )
elif test -f "${HOME}/.fzfrc"; then
  export FZF_DEFAULT_OPTS_FILE="${HOME}/.fzfrc"
  fzf_default_opts=( "${(f)$(< "${FZF_DEFAULT_OPTS_FILE}")[@]}" )
elif test -z "${FZF_DEFAULT_OPTS}"; then
  fzf_default_opts=(
    '--sort'
    '--cycle'
    '--smart-case'
    '--style='\''default'\'''
    '--layout='\''reverse'\'''
    '--tmux='\''bottom,40%,border-native'\'''
    '--info='\''hidden'\'''
    '--border='\''sharp'\'''
    '--input-border='\''line'\'''
    '--header-border='\''line'\'''
    '--preview-border='\''sharp'\'''
    '--no-list-border'
    "--color='${TERM_BACKGROUND:-dark},fg:5,fg+:1:bold,hl:3,hl+:3:bold,bg:-1,bg+:-1:bold,pointer:2:bold,border:3,query:-1:regular,prompt:2:bold,input-border:3,header:2,header-border:3,footer:6,footer-border:3,info:-1:dim,gutter:-1:bold'"
    '--bind='\''shift-up:first'\'''
    '--bind='\''shift-down:last'\'''
    '--bind='\''alt-left:backward-word'\'''
    '--bind='\''alt-right:forward-word'\'''
    '--bind='\''ctrl-b:page-up'\'''
    '--bind='\''ctrl-f:page-down'\'''
    '--bind='\''ctrl-\\:bg-cancel'\'''
    '--bind='\''ctrl-j:accept-or-print-query'\'''
    '--bind='\''ctrl-s:replace-query'\'''
    '--bind='\''insert:replace-query'\'''
    '--bind='\''ctrl-/:toggle-preview'\'''
    '--bind='\''ctrl-]:jump-accept'\'''
    '--jump-labels='\''1234567890qwertyuiopasdfghjklzxcvbnm'\'''
  )
fi

# Fzf completion opts
export -T FZF_COMPLETION_OPTS="${FZF_COMPLETION_OPTS-}" fzf_completion_opts " "
if test -z "${FZF_COMPLETION_OPTS}"; then
  fzf_completion_opts=(
    "${fzf_default_opts[@]}"
    '--select-1'
    '--exit-0'
    '--filepath-word'
    '--layout='\''reverse-list'\'''
    '--bind='\''ctrl-o:execute-silent(printf %s {} | { pbcopy || wl-copy -n || xclip -sel clipboard -in || xsel --clipboard --input -n; })'\'''
  )
fi

export -T FZF_ALT_C_OPTS="${FZF_ALT_C_OPTS-}" fzf_alt_c_opts " "
if test -z "${FZF_ALT_C_OPTS}"; then
  fzf_alt_c_opts=(
    "${fzf_default_opts[@]}"
    '--no-sort'
    '--filepath-word'
    '--bind='\''ctrl-x:become%"${EDITOR:-nvim}" -- {}%'\'''
    '--bind='\''ctrl-o:execute-silent(printf %s {} | { pbcopy || wl-copy -n || xclip -sel clipboard -in || xsel --clipboard --input -n; })'\'''
  )
fi

export -T FZF_CTRL_T_OPTS="${FZF_CTRL_T_OPTS-}" fzf_ctrl_t_opts " "
if test -z "${FZF_CTRL_T_OPTS}"; then
  fzf_ctrl_t_opts=(
    "${fzf_default_opts[@]}"
    '--no-sort'
    '--filepath-word'
    '--bind='\''ctrl-m:become%open_command -- {}%'\'''
    '--bind='\''ctrl-x:become%"${EDITOR:-nvim}" -- {}%'\'''
    '--bind='\''ctrl-o:execute-silent(printf %s {} | { pbcopy || wl-copy -n || xclip -sel clipboard -in || xsel --clipboard --input -n; })'\'''
  )
fi
export -T FZF_CTRL_R_OPTS="${FZF_CTRL_R_OPTS-}" fzf_ctrl_r_opts " "
if test -z "${FZF_CTRL_R_OPTS}"; then
  fzf_ctrl_r_opts=(
    "${fzf_default_opts[@]}"
    '--filepath-word'
    '--layout='\''reverse-list'\'''
    '--bind='\''ctrl-x:become%zsh -c $@ -- {2..}%'\'''
    '--bind='\''ctrl-o:execute-silent(printf %s {2..} | { pbcopy || wl-copy -n || xclip -sel clipboard -in || xsel --clipboard --input -n; })'\'''
  )
fi

# Load ~/.env
# NOTE: Do this here to reduce exposure to child processes
#
if [[ -f ~/.env && -r ~/.env ]]; then
  emulate sh -c '. ~/.env'
fi

# vi:et:ft=zsh:sts=2:sw=2:ts=8:tw=0
