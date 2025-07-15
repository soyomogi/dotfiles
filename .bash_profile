# git
function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/[\1]/'
}

# prompt
function promps {
  local BLUE="\[\e[1;34m\]"
  local RED="\[\e[1;31m\]"
  local GREEN="\[\e[1;32m\]"
  local WHITE="\[\e[00m\]"
  local GRAY="\[\e[1;37m\]"
  local CYAN="\[\e[1;36m\]"
  local YELLOW="\[\e[1;33m\]"
  local PURPLE="\[\e[1;35m\]"
  propms_color=${GRAY}

  if [[ $(hostname) =~ ^.*01.*$ ]]; then
    propms_color=${PURPLE}
  fi
  if [[ $(hostname) =~ ^.*02.*$ ]]; then
    propms_color=${YELLOW}
  fi
  if [[ $(hostname) =~ ^.*03.*$ ]]; then
    propms_color=${BLUE}
  fi
  if [[ $(hostname) =~ ^.*prod.*$ ]]; then
    propms_color=${RED}
  fi
  if [[ $(hostname) =~ ^.*cyan.*$ ]]; then
    propms_color=${CYAN}
  fi
  if [[ $(hostname) =~ ^.*local.*$ ]]; then
    propms_color=${GREEN}
  fi

  # PS1
  PS1="[${BLUE}\u${WHITE}@${propms_color}\h${WHITE}:${YELLOW}\w${WHITE}]${PURPLE}\$(parse_git_branch)${WHITE}$ "
}
promps

# screen デタッチした場合にもssh agent forwardingを有効にする
AUTH_SOCK="$HOME/.ssh/.ssh-auth-sock"
if [ -S "$AUTH_SOCK" ]; then
    export SSH_AUTH_SOCK=$AUTH_SOCK
elif [ ! -S "$SSH_AUTH_SOCK" ]; then
    export SSH_AUTH_SOCK=$AUTH_SOCK
elif [ ! -L "$SSH_AUTH_SOCK" ]; then
    ln -snf "$SSH_AUTH_SOCK" $AUTH_SOCK && export SSH_AUTH_SOCK=$AUTH_SOCK
fi

# lscolor
export LSCOLORS=gxfxcxdxbxegedabagacad
alias ls='ls -G'

# .bashrc
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
