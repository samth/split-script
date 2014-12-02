#!/bin/bash

# Replace with the following if you don't have a local clone (but a
# local clone will be much faster)
# HISTORY_SRC=git://github.com/samth/plt-history
HISTORY_SRC=$HOME/work/plt-history

NAME=$1

TMPDIR=/tmp/slice_$NAME

cd chop_$NAME

curl -s "https://api.github.com/repos/racket/$NAME" | grep "Not Found"

if [ $? -eq 0 ]; then
    echo "Repository racket/$NAME doesn't yet exist"
    hub create racket/$NAME 
else
    echo "Repository racket/$NAME already exists"
fi
    

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
