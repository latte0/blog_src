#!/usr/bin/env bash
set -e
rsync -a --exclude ".*" --delete-after _site/ _deploy
