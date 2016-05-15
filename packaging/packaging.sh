#!/bin/bash

VERSION="0.1"

rm -rf debian
mkdir debian
cd debian
ln -s ../../filefinder-$VERSION.tar.gz filefinder_$VERSION.orig.tar.gz
tar xf filefinder_$VERSION.orig.tar.gz
cd filefinder-$VERSION
cp -r ../../../debian/ .
debuild -us -uc
