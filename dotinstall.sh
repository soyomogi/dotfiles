#!/bin/bash
scp ~/.bash_profile ~/.screenrc ~/.vimrc $@:
scp -r ~/.vim/ $@:
