#!/bin/bash

rm lgallard.github.io/ -rf
bundle exec jekyll build -t --incremental
git clone https://github.com/lgallard/lgallard.github.io.git
cp -r _site/* lgallard.github.io/
cd lgallard.github.io/
git add --all
git commit -m "`date`"
git push https://$GITTOKEN@github.com/lgallard/lgallard.github.io.git
cd ..
