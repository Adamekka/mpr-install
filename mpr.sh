#!/bin/bash
# Stuff for nicer output
bold=$(tput bold)
normal=$(tput sgr0)
red="\033[0;31m"
yellow="\033[1;33m"
nc="\033[0m" # No Color

version=1.4

###########
#FUNCTIONS#
###########


check_dependencies () {
    dependencies=(cat curl git jq make makedeb wget)
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
    latestVersion=$(curl -s https://raw.githubusercontent.com/Adamekka/mpr-install/main/version.txt)
}

mpr_update () {
    printf "Checking for update...\n"
    wget -q --spider https://google.com
    if [ $? -eq 0 ]
    then
        check_versions
        printf "Your version is: $version\n"
        printf "Latest version is: $latestVersion\n"
        if [[ $version == $latestVersion ]]
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
    else
        printf "${yellow}Warning:${nc} You are offline, unable to check for updates\n"
    fi
}

mpr_update_minimal () {
    printf "Checking for update...\n"
    wget -q --spider https://google.com
    if [ $? -eq 0 ]
    then
        check_versions
        if [[ $version != $latestVersion ]]
        then
            printf "A newer version is available\n"
            printf "Please run ${bold}mpr selfupdate${normal} to update\n"
        else
            printf "You are up to date!\n"
        fi
    else
        printf "${yellow}Warning:${nc} You are offline, unable to check for updates\n"
    fi
    
}

install_package () {
    printf "${bold}$1 not available in APT\n${normal}"
    printf "${bold}Checking if $1 is available in MPR...${normal}\n"
    mprPackageExistence=$(curl -o /dev/null -s -w "%{http_code}\n" https://mpr.makedeb.org/packages/$1)
    if [[ $mprPackageExistence == 200 ]]
    then
        printf "${bold}$1 available in MPR!${normal}\n"
        git clone "https://mpr.makedeb.org/$1.git" "/home/$USER/.cache/mpr/$1"
        cd /home/$USER/.cache/mpr/$1
        makedeb -s -i
        save_package_info "$1"
    else
        printf "${bold}$1 not available in APT and MPR!${normal}\n"
    fi
}

mpr_packages_update () {
    outdatedPackages=("$@")
    for i in ${outdatedPackages[@]}
    do
        printf "${yellow}Updating $i...${nc}\n"
        rm -rf /home/$USER/.cache/mpr/$i
        git clone "https://mpr.makedeb.org/$i.git" "/home/$USER/.cache/mpr/$i"
        cd /home/$USER/.cache/mpr/$i
        makedeb -s -i
        save_package_info "$i"
    done
}

mpr_packages_update_check () {
    printf "${bold}Checking for updates for packages from MPR...${normal}\n"
    packages+=($(ls ~/.local/share/mpr/list/))
    userHasOutdatedPackage=false
    for i in ${packages[@]}
    do
        pkgLatestVersion=$(curl -s -X GET "https://mpr.makedeb.org/rpc?v=5&type=info&arg=$i" | jq | grep "Version" | cut -d ':' -f 2 | cut -c3- | rev | cut -c2- | rev)
        pkgVersion=$(cat ~/.local/share/mpr/list/$i | grep "Version:" | cut -d ':' -f 2 | cut -c2-)
        printf "${bold}$i${normal}\n"
        printf "Installed version: $pkgVersion\n"
        printf "Latest version: $pkgLatestVersion\n"
        if [[ $pkgVersion == $pkgLatestVersion ]]
        then
            printf "${bold}$i${normal} is up to date!\n"
        else
            printf "${bold}$i${normal} is outdated!\n"
            outdatedPackages+=($i)
            userHasOutdatedPackage=true
        fi
    done
    if [[ $userHasOutdatedPackage == false ]]
    then
        printf "${bold}All packages up to date!${normal}\n"
    else
        printf "${bold}${yellow}Outdated packages are:\n${outdatedPackages[*]}${nc}${normal}\n"
        mpr_packages_update "${outdatedPackages[@]}"
    fi
}

save_package_info () {
    if [ ! -d ~/.local/share/mpr/list/ ]
    then
        if [ ! -d ~/.local/share/mpr/ ]
        then    
            mkdir ~/.local/share/mpr
        fi
        mkdir -p ~/.local/share/mpr/list
    fi
    pkgInfo=$(dpkg -s $1)
    echo "$pkgInfo" > ~/.local/share/mpr/list/$1
}

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
    if [ ! -f ~/.local/share/mpr/date ]
    then
        if [ ! -d ~/.local/share/mpr/ ]
        then    
            mkdir ~/.local/share/mpr
        fi
        touch ~/.local/share/mpr/date
    fi
    lastUpdateCheck=$(cat ~/.local/share/mpr/date)
    today=$(date +%Y%m%d)
    echo "$today" > ~/.local/share/mpr/date
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
arguments=${@:2} # puts arguments to array

case $1 in
    install | -S | --sync ) 
    for i in ${arguments[@]}
    do
        printf "${bold}Trying to find $i...${normal}\n"
        aptPackageExistence=$(apt-cache -qq show $i)
        if [ ! -z "$aptPackageExistence" ]
        then
            printf "${bold}$i available in APT!${normal}\n"
            sudo apt install $i   
        elif [ ! -z "$i" ]
        then
            install_package "$i"
        else
            printf "${red}Error:${nc} You have to enter package name\n"
            printf "Example: mpr install ${bold}<packagename>${normal}\n"
        fi
        printf "\n"
    done
    ;;
    update | -Sy )
    sudo apt update
    ;;
    upgrade | -Su )
    sudo apt upgrade
    mpr_packages_update_check
    ;;
    -Suy | -Syu )
    sudo apt update && sudo apt upgrade
    mpr_packages_update_check
    ;;
    remove | uninstall | -R | --remove)
    sudo apt remove $arguments
    for i in ${arguments[@]}
    do
        pkgPath=$(which $i)
        if [[ $pkgPath != /usr/bin/$i && -f ~/.local/share/mpr/list/$i ]]
        then
            rm ~/.local/share/mpr/list/$i
        fi
    done
    ;;
    autoremove )
    sudo apt autoremove
    ;;
    list | -Q | --query)
    apt list
    ;;
    info )
    apt info $arguments
    ;;
    search )
    for i in ${arguments[@]}
    do
        printf "${bold}Searching for $i...${normal}\n"
        printf "${yellow}APT search result${normal}\n"
        apt search $i
        printf "${yellow}MPR search result${normal}\n"
        curl -s "https://mpr.makedeb.org/rpc?v=5&type=info&arg=$i" | jq
    done
    ;;
    version | selfupdate | -V | --version )
    mpr_update
    ;;
    * )
    help_page
    ;;
esac
