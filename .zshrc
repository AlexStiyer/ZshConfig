### Alex's 'Wombo Theme' for Zsh ##########################
# Requirements:
# - Zsh,
# - a Nerd Font (I use HackFont)
# - Zap plugin manager
#
# Git Configs:
#   For a fast git prompt, I recommend caching the untracked-file scan:
#     git config --global core.untrackedCache true
#
# Git prompt (right side):
#   ◁  = unstaged changes
#   ▶  = staged changes
#   !  = untracked files
#   +N = commits ahead of upstream
#   -N = commits behind upstream
############################################################

### Plugins
# supercharge already runs compinit and sets history/completion options.
# syntax-highlighting must load before history-substring-search.
[[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ]] &&
    source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

plug "zsh-users/zsh-autosuggestions"
plug "zap-zsh/supercharge"
plug "zsh-users/zsh-syntax-highlighting"
plug "zsh-users/zsh-history-substring-search"

### Options
setopt prompt_subst
export ZSHRC=~/.zshrc    # used by supercharge's Ctrl-X reload binding

### Keybinds (both normal and application cursor-key modes)
bindkey '^[[A' history-substring-search-up
bindkey '^[OA' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[OB' history-substring-search-down

### Aliases
alias reload='source ~/.zshrc'
alias gs='cd ~/src'


############################################################
# Git Prompt
############################################################

# Parses `git status --porcelain=v2 --branch` on stdin into GIT_PROMPT,
# e.g. "master", "◁ master", "◁▶! +3/-1 master".
git_prompt_parse() {
    GIT_PROMPT=""

    local line xy branch symbols ahead_behind
    local -i staged=0 unstaged=0 untracked=0 ahead=0 behind=0

    while IFS= read -r line; do
        case $line in
            '# branch.head '*)
                branch=${line#'# branch.head '}
                ;;
            '# branch.ab '*)
                [[ $line =~ '\+([0-9]+) -([0-9]+)$' ]] &&
                    ahead=$match[1] behind=$match[2]
                ;;
            # Ordinary (1) or rename/copy (2): XY = index/worktree state
            [12]' '*)
                xy=${line[3,4]}
                [[ $xy[1] != . ]] && staged=1
                [[ $xy[2] != . ]] && unstaged=1
                ;;
            'u '*)  staged=1 unstaged=1 ;;
            '? '*)  untracked=1 ;;
        esac
    done

    # Not inside a Git worktree.
    [[ -z $branch ]] && return

    (( unstaged ))  && symbols+='◁'
    (( staged ))    && symbols+='▶'
    (( untracked )) && symbols+='!'

    (( ahead ))  && ahead_behind="+$ahead"
    (( behind )) && ahead_behind+="${ahead_behind:+/}-$behind"

    GIT_PROMPT="${symbols:+$symbols }${ahead_behind:+$ahead_behind }$branch"
}

# The prompt draws immediately; git status runs in the background and
# git_prompt_done redraws the prompt once its output is ready (zle -F).
typeset -g GIT_PROMPT_FD GIT_PROMPT_DIR

git_prompt_start() {
    # Cancel a job still running from the previous prompt.
    if [[ -n $GIT_PROMPT_FD ]]; then
        zle -F $GIT_PROMPT_FD
        exec {GIT_PROMPT_FD}<&-
        GIT_PROMPT_FD=
    fi

    # New directory: don't show the previous repo's status while waiting.
    [[ $PWD != $GIT_PROMPT_DIR ]] && GIT_PROMPT="" GIT_PROMPT_DIR=$PWD

    # Skip spawning git when no .git exists up the tree (unless $GIT_DIR is set).
    local dir=$PWD
    while [[ -z $GIT_DIR && ! -e $dir/.git ]]; do
        [[ $dir == / ]] && { GIT_PROMPT=""; return }
        dir=${dir:h}
    done

    exec {GIT_PROMPT_FD}< <(git --no-optional-locks status --porcelain=v2 --branch 2>/dev/null)
    zle -F -w $GIT_PROMPT_FD git_prompt_done
}

git_prompt_done() {
    zle -F $GIT_PROMPT_FD
    git_prompt_parse <&$GIT_PROMPT_FD
    exec {GIT_PROMPT_FD}<&-
    GIT_PROMPT_FD=
    wombo_rprompt
    zle reset-prompt
}
zle -N git_prompt_done


############################################################
# Prompt
############################################################

PS_COLOR=$(( 17 + RANDOM % 215 ))    # 17-231: skips black and the grey ramp
RIGHT_ARROW=$''

THN="%F{$PS_COLOR}%K{black}"
FAT="%F{black}%K{$PS_COLOR}"

PS1='${THN} ${BATTERY}%% ${FAT}${RIGHT_ARROW} %B%2~%b ${THN}%k${RIGHT_ARROW}%f '

zmodload zsh/datetime
typeset -i BATTERY_CHECKED=0

wombo_precmd() {
    # Battery level changes slowly; refresh at most once a minute.
    if (( EPOCHSECONDS - BATTERY_CHECKED >= 60 )); then
        [[ $(pmset -g batt) =~ '([0-9]+)%' ]] && BATTERY=$match[1]
        BATTERY_CHECKED=$EPOCHSECONDS
    fi

    git_prompt_start
    wombo_rprompt
}

wombo_rprompt() {
    RPROMPT="%F{white}%*%f"
    [[ -n $GIT_PROMPT ]] && RPROMPT="%F{magenta}$GIT_PROMPT  $RPROMPT"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd wombo_precmd
