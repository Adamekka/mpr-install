#!/bin/bash
currentVersion=$(cat /usr/bin/mpr-install/version)
latestVersion=$(curl -s https://raw.githubusercontent.com/Adamekka/mpr-install/main/version.txt)
printf "RUN THIS ONLY IN YOUR HOME FOLDER!!!\n"
printf "Your version is: $currentVersion\n"
printf "Latest version is: $latestVersion\n"
if [[ $currentVersion == $latestVersion ]]
then
    printf "You have the latest version!\n"
else
    printf "A newer version is available!\n"
    read -p "Do you want to update to version $latestVersion? (y/n): " yn

    case $yn in
        [yY] ) printf "Updating...\n";
            git clone https://github.com/Adamekka/mpr-install;
            cd mpr-install/;
            sudo make install;
            cd .. && rm -f -r mpr-install;;
        [nN] ) printf "Update denied\n";;
        * ) printf "Error: bad response\n";
            printf 'Type "y" for update and "n" for not update\n';;
    esac

fi