#!/bin/bash

VERSION="0.3"

rm -rf debs
mkdir debs
cd debs
ln -s ../../filefinder-$VERSION.tar.gz filefinder_$VERSION.orig.tar.gz
tar xf filefinder_$VERSION.orig.tar.gz
cd filefinder-$VERSION
cp -r ../../../debian/ .
debuild -us -uc
