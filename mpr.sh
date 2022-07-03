#!/bin/sh
read -p "Enter package name: " pkgname
echo Downloading: $pkgname\n
git clone "https://mpr.makedeb.org/$pkgname.git"
cd $pkgname/
makedeb -s -i
