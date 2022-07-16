#!/bin/bash
# Stuff for nicer output
bold=$(tput bold)
normal=$(tput sgr0)
red="\033[0;31m"
nc="\033[0m" # No Color

###########
#FUNCTIONS#
###########


check_dependencies () {
    dependencies=(cat curl git make makedeb wget)
    isUserMissingDependencies=false
    for i in ${dependencies[@]}
    do
        dependencyPath=$(which $i)
        if [[ $dependencyPath != /usr/bin/$i ]]
        then
            printf "$i missing\n"
            missingDependencies+=($i)
            isUserMissingDependencies=true
        fi
    done
    if [[ $isUserMissingDependencies == true ]]
    then
        printf "${red}Error:${nc} Please install missing dependencies\n"
        printf "${bold}Missing dependencies are:\n${missingDependencies[*]}${normal}\n"
        exit 1
    fi
}

check_versions () {
    currentVersion=$(cat /usr/bin/mpr-install/version)
    latestVersion=$(curl -s https://raw.githubusercontent.com/Adamekka/mpr-install/main/version.txt)
}

mpr_update () {
    check_versions
    printf "Your version is: $currentVersion\n"
    printf "Latest version is: $latestVersion\n"
    if [[ $currentVersion == $latestVersion ]]
    then
        printf "You have the latest version!\n"
    else
        printf "A newer version is available!\n"
        read -p "Do you want to update to version $latestVersion? [y/n]: " yn

        case $yn in
            [yY] ) printf "Updating...\n"
                git clone https://github.com/Adamekka/mpr-install
                cd mpr-install/
                sudo make install
                cd .. && rm -f -r mpr-install;;
            [nN] ) printf "Update denied\n";;
            * ) printf "${red}Error:${nc} bad response\n"
                printf "Type [y] for update and [n] for not update\n";;
        esac
    fi
}

mpr_update_minimal () {
    printf "Checking for update...\n"
    check_versions
    wget -q --spider https://google.com
    if [[ $currentVersion != $latestVersion ]]
    then
        printf "A newer version is available\n"
        printf "Please run ${bold}mpr selfupdate${normal} to update\n"
    else
        printf "You are up to date!\n"
    fi
}

install_package () {
    printf "Package not available in APT\n"
    printf "Checking if package is available in MPR...\n"
    mprPackageExistence=$(git ls-remote --exit-code https://mpr.makedeb.org/$1.git)
    if [[ $mprPackageExistence > 0 ]]
    then
        printf "Package exists!\n"
        printf "Downloading: $1\n"
        git clone "https://mpr.makedeb.org/$1.git"
        cd $1/
        makedeb -s -i
    else
        printf "Package not available in MPR\n"
    fi
}

#check_internet () {
#    if [[ $internetConnectivity != 0 ]]
#    then
#        printf "${red}Error:${nc} No internet connection available\n"
#        exit 0
#    fi
#}

help_page () {
    echo " _ __ ___  _ __  _ __ "
    echo "|  _   _ \|  _ \|  __|"
    echo "| | | | | | |_) | |   "
    echo "|_| |_| |_|  __/|_|   "
    echo "          |_|         "  
    echo
    echo ${bold}
    echo "Syntax: mpr <COMMAND> [PACKAGES]"
    echo
    echo "commands:"
    echo
    echo " install${normal} or ${bold}-S${normal} or ${bold}--sync${normal}                  Install a package"
    echo " ${bold}update${normal} or ${bold}-Sy${normal}                            Update the APT and MPR cache"
    echo " ${bold}upgrade${normal} or ${bold}-Su${normal}                           Upgrade all installed packages"
    echo " ${bold}-Syu${normal} or ${bold}-Suy${normal}                             Update both caches and upgrade all installed packages"
    echo " ${bold}remove${normal} or ${bold}uninstall${normal} or ${bold}-R${normal} or ${bold}--remove${normal}    Remove a package"
    echo " ${bold}autoremove${normal}                               Remove auto-installed deps which are no longer required"
    echo " ${bold}list${normal} or ${bold}-Q${normal} or ${bold}--query${normal}                    List installed packages"
    echo " ${bold}info${normal}                                     Show package information"
    echo " ${bold}search${normal}                                   Search for packages"
    # add clone - Clone a package from the MPR
    echo " ${bold}version${normal} or ${bold}selfupdate${normal} or ${bold}-V${normal} or ${bold}--version${normal} Shows version and checks for update"
    echo " ${bold}*${normal}                                        Shows help page"
    echo
    echo "mpr checks for update automatically once a day"
    printf "mpr supports both Debian and Arch syntax\n\n"
}

check_date () {
    if [ ! -f ~/.config/mpr-install/date ]
    then
        mkdir -p ~/.config/mpr-install
        touch ~/.config/mpr-install/date
    fi
    lastUpdateCheck=$(cat ~/.config/mpr-install/date)
    today=$(date +%Y%m%d)
    echo "$today" > ~/.config/mpr-install/date
    if [[ $today != $lastUpdateCheck ]]
    then
        mpr_update_minimal
    fi
}

#######
#START#
#######


check_dependencies
check_date

case $1 in
    install | -S | --sync ) #check_internet
    aptPackageExistence=$(apt-cache -qq show $2)
    if [ ! -z "$aptPackageExistence" ]
    then
        printf "Package available in APT!\n"
        sudo apt install $2    
    elif [ ! -z "$2" ]
    then
        install_package "$2"
    else
        printf "${red}Error:${nc} You have to enter package name\n"
        printf "Example: mpr install ${bold}<packagename>${normal}\n"
    fi
    ;;
    update | -Sy ) #check_internet
    sudo apt update
    ;;
    upgrade | -Su ) #check_internet
    sudo apt upgrade
    ;;
    -Suy | -Syu ) #check_internet
    sudo apt update && sudo apt upgrade
    ;;
    remove | uninstall | -R | --remove) sudo apt remove $2
    ;;
    autoremove ) sudo apt autoremove
    ;;
    list | -Q | --query) apt list
    ;;
    info ) apt info $2
    ;;
    search ) apt search $2
    ;;
    version | selfupdate | -V | --version ) mpr_update
    ;;
    * ) help_page
    ;;
esac