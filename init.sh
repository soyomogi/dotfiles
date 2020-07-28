GITDIR=$HOME/git/dotfiles
# bash
ln -s $GITDIR/.bashrc $HOME/.bashrc
ln -s $GITDIR/.bash_profile $HOME/.bash_profile

# vim
ln -s $GITDIR/.vimrc $HOME/.vimrc
mkdir -r $HOME/.vim/colors
cd $HOME/.vim/colors wget https://raw.githubusercontent.com/tomasr/molokai/master/colors/molokai.vim

# other
ln -s $GITDIR/.screenrc $HOME/.screenrc
ln -s $GITDIR/.tmux.conf $HOME/.tmux.conf
