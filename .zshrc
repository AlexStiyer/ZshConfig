### Alex's 'Wombo Theme' for Zsh  ########################
# Requirements:
# - Zsh
# - A Nerd Font (I like https://www.programmingfonts.org/#hack)
# - Zap Plugin Manager (https://github.com/zap-zsh)

# Symbol Glossary
# ◁ - Unstaged Changes in Repo
# ▶ - Staged Changes in Repo
# ! - Untracked Files in Repo
# 
# Troubleshooting:
#
# Q: My Directory Text Looks Weird
# A: Terminal must treat ANCI bold as bold and not "bright" for best experience.
#    If this is not possible, remove the %B and %b from the PS1 string
########################################################### 

##Options
setopt prompt_subst

### Zap Plugins
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"
plug "zsh-users/zsh-autosuggestions"
plug "zap-zsh/supercharge"
plug "zsh-users/zsh-syntax-highlighting"
plug "zsh-users/zsh-history-substring-search"

### Load and initialise completion system
autoload -Uz compinit
compinit

### Keybinds
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

### Alias
alias reload='source ~/.zshrc'
alias gs='cd ~/src'

### Prompt
# Using vcs_info but specifically check-for-changes may slow down prompt in very large repos. 
# If you experience this consider disabling this for specific directories
autoload -Uz vcs_info
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '◁'
zstyle ':vcs_info:*' stagedstr '▶'
zstyle ':vcs_info:*' actionformats '%u%c %R/(%a|%m)%S%'
zstyle ':vcs_info:*' formats '%m %u%c %b'
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked git-st

# Show special the marker if there are any untracked files in repo append to vcs_info %c token
+vi-git-untracked(){
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
        git status --porcelain | grep -q '^?? ' 2> /dev/null ; then
        hook_com[staged]+='!'
    fi
}

# Get the number of commits ahead and behind current branch is to HEAD append to vcs_info %m token
function +vi-git-st() {
    local ahead behind
    local -a gitstatus

    # Exit early in case the worktree is on a detached HEAD
    git rev-parse ${hook_com[branch]}@{upstream} >/dev/null 2>&1 || return 0

    local -a ahead_and_behind=(
        $(git rev-list --left-right --count HEAD...${hook_com[branch]}@{upstream} 2>/dev/null)
    )

    ahead=${ahead_and_behind[1]}
    behind=${ahead_and_behind[2]}

    (( $ahead )) && gitstatus+=( "+${ahead}" )
    (( $behind )) && gitstatus+=( "-${behind}" )

    hook_com[misc]+=${(j:/:)gitstatus}
}

# Run VCS info every time the prompt is created
precmd() { vcs_info }

# Only verified on Mac, Possible in Linux, Good luck in Windows
get_battery(){
    echo $(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
}

# Using Random Color for fun, set a static color here to prevent behaviour
PS_COLOR=$((1 + $RANDOM % 255))
RIGHT_ARROW=$'\uE0B0'
THN=$(echo "%F{$PS_COLOR}%K{black}")
FAT=$(echo "%F{black}%K{$PS_COLOR}")
REST='%K{reset_color}'
PS1=$'${THN} $(get_battery)%% ${FAT}${RIGHT_ARROW} %B%2~%b ${THN}${REST}${RIGHT_ARROW}${REST} '
RPROMPT=$'%F{magenta}${vcs_info_msg_0_}  %F{white}%*'

### Exports
