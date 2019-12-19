#!/usr/bin/env bash

set -e
set -u

sudo apt-get update && sudo apt-get install -y rsync ssh git

git config --global push.default simple
git config --global user.name "CircleCI"
git config --global user.email "<>"
mkdir ~/.ssh && echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config

dub build -b ddox
mv docs ../

git checkout gh-pages
rm -r *
mv ../docs/* ./
git add -A --force .
git diff-index --quiet HEAD || git commit -m "[skip ci] Update docs"
git push origin gh-pages
