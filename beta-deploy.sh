#!/bin/bash

#scp -r . ryujin:/srv/ac-get.darkdna.net/beta/

ssh ryujin "cd /srv/ac-get.darkdna.net/; rm -rf beta/; git clone https://git.darkdna.net/amanda/ac-get.git beta; sed -e 's#/repo#/beta/repo#' -i beta/install.manifest; sed -e 's#darkdna\.net/#darkdna\.net/beta#' -i beta/install.lua"

notify-send "Beta Deploy" "Deploy complete."