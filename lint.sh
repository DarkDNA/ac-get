#!/bin/bash

find /var/www/cc.amanda.camnet/ac-get/ -name '*.lua' -exec luac -p {} \;
