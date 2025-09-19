setopt nopromptbang prompt{cr,percent,sp,subst}

zstyle ':zim:duration-info' threshold 0.5
zstyle ':zim:duration-info' format '%.4d s'

autoload -Uz add-zsh-hook
add-zsh-hook preexec duration-info-preexec
add-zsh-hook precmd duration-info-precmd

RPS1='${duration_info}%'

# Add a subtle first line, keep original prompt content on second line.
# Idempotent and only for interactive shells.
if [[ $- == *i* ]]; then
  typeset -g __AMI_PROMPT_DECORATED
  if [[ $__AMI_PROMPT_DECORATED != 1 ]]; then
    local _orig_prompt="$PROMPT"
    # First line = original prompt (unchanged)
    # Second line = ultra-short input indicator
    PROMPT="${_orig_prompt}"$''"%(?.%F{green}❯%f.%F{red}❯%f) "
    __AMI_PROMPT_DECORATED=1
  fi
fi
