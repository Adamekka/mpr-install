#!/bin/bash
read -p "Enter package name: " pkgname
printf "Checking if package exists...\n"
pkgexistence=$(git ls-remote --exit-code https://mpr.makedeb.org/$pkgname.git)
if [[ $pkgexistence > 0 ]]
then
    printf "Package exists!\n"
    printf "Downloading: $pkgname\n"
    git clone "https://mpr.makedeb.org/$pkgname.git"
    cd $pkgname/
    makedeb -s -i
else
    printf "Package doesn't exist!\n"
fi