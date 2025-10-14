#!/bin/bash
scp ~/.screenrc ~/.vimrc $@:
scp -r ~/.vim/ $@:
