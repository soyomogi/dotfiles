# ssh completion
if [type "brew" > /dev/null 2>&1]; then
  if [ -f `brew --prefix`/etc/bash_completion ]; then
      . `brew --prefix`/etc/bash_completion
  fi
fi

# tmux
if [type "tmux" > /dev/null 2>&1]; then
  if [ $SHLVL = 1 ]; then
    tmux
  fi
fi
