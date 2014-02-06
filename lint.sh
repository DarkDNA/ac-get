#!/bin/bash

find "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" -name '*.lua' -exec luac -p {} \;
