# ssh completion
if [ -f `brew --prefix`/etc/bash_completion ]; then
    . `brew --prefix`/etc/bash_completion
fi

# tmux
if [ $SHLVL = 1 ]; then
  tmux
fi
