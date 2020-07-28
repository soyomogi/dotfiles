GITDIR=$HOME/git/dotfiles
# bash
ln -s $GITDIR/.bashrc $HOME/.bashrc
ln -s $GITDIR/.bash_profile $HOME/.bash_profile

# vim
ln -s $GITDIR/.vimrc $HOME/.vimrc
mkdir -p $HOME/.vim/colors
if [ ! -e $HOME/.vim/colors/molokai.vim ]; then
  curl https://raw.githubusercontent.com/tomasr/molokai/master/colors/molokai.vim > $HOME/.vim/colors/molokai.vim
fi

# other
ln -s $GITDIR/.screenrc $HOME/.screenrc
ln -s $GITDIR/.tmux.conf $HOME/.tmux.conf
