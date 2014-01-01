#!/bin/zsh

./make.sh

scp -r . ryujin:/srv/ac-get.darkdna.net/

notify-send "Deployed." "Deploy Successful."