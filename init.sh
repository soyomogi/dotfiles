GITDIR=$HOME/git/dotfiles
# bash
rm $HOME/.bashrc
ln -s $GITDIR/.bashrc $HOME/.bashrc
rm $HOME/.bash_profile
ln -s $GITDIR/.bash_profile $HOME/.bash_profile

# zsh
rm $HOME/.zshrc
ln -s $GITDIR/.zshrc $HOME/.zshrc

# vim
rm $HOME/.vimrc
ln -s $GITDIR/.vimrc $HOME/.vimrc
mkdir -p $HOME/.vim/colors
if [ ! -e $HOME/.vim/colors/molokai.vim ]; then
  curl https://raw.githubusercontent.com/tomasr/molokai/master/colors/molokai.vim >$HOME/.vim/colors/molokai.vim
fi
if [ ! -e $HOME/.vim/colors/fairyfloss.vim ]; then
  curl https://raw.githubusercontent.com/tssm/fairyfloss.vim/master/colors/fairyfloss.vim >$HOME/.vim/colors/fairyfloss.vim
fi

# neovim
rm $HOME/.config/nvim
ln -s $GITDIR/.config/nvim $HOME/nvim

# other
rm $HOME/.screenrc
ln -s $GITDIR/.screenrc $HOME/.screenrc
rm $HOME/.tmux.conf
ln -s $GITDIR/.tmux.conf $HOME/.tmux.conf
