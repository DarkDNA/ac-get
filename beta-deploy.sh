#!/bin/zsh

./make.sh

scp -r . ryujin:/srv/ac-get.darkdna.net/beta/

notify-send "Deployed." "Deploy Successful."