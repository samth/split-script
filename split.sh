#!/bin/bash

# Replace with the following if you don't have a local clone (but a
# local clone will be much faster)
# HISTORY_SRC=git://github.com/samth/plt-history
HISTORY_SRC=$HOME/work/plt-history

NAME=$1

TMPDIR=/tmp/slice_$NAME

curl -s "https://api.github.com/repos/racket/$NAME" | grep "Not Found"

if [ $? -eq 0 ]; then
    echo "Repository racket/$NAME doesn't yet exist"
else
    echo "Repository racket/$NAME already exists, exiting"
    exit 1
fi
    

echo "Installing git-slice"

raco pkg install --skip-installed --deps search-auto git-slice

echo "Using temporary directory $TMPDIR"

rm -rf $TMPDIR
mkdir -p $TMPDIR

# Create the repository
git clone $HISTORY_SRC chop_$NAME
cd chop_$NAME
sh ./graft.sh

echo "Grafted"

# create this here for synchronization
hub create racket/$NAME || exit 1

if [ -z $2 ]; then
    if [ -d pkgs/$NAME-pkgs ]; then
        PTH=pkgs/$NAME-pkgs
    else
        PTH=pkgs/$NAME
    fi
else
    PTH=$2
fi

if [ -d $PTH ] ; then
    echo "Splitting $PTH to repository $NAME"
else
    echo "Path $PTH does not exist!"
    exit 1
fi

# Slice the repository
racket -l git-slice/compute $PTH $TMPDIR
racket -l git-slice/filter $TMPDIR
rm .git/info/grafts
racket -l git-slice/chop $TMPDIR

echo "Sliced!"

# Remove extra directories
git mv $PTH/* .
git commit -m "Remove extra directories."

echo "Directories removed"

# Create the github repository
hub remote add -p racket/$NAME
hub push racket master

echo "Repository created and pushed"
