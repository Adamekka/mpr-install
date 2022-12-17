#!/bin/bash
# Stuff for nicer output
bold=$(tput bold)
normal=$(tput sgr0)
red="\033[0;31m"
yellow="\033[1;33m"
nc="\033[0m" # No Color

# Global variables
version=1.6
otherPackageManagers=(flatpak)

###########
#FUNCTIONS#
###########


check_dependencies () {
    dependencies=(curl git jq make makedeb)
    isUserMissingDependencies=false
    for i in "${dependencies[@]}"
    do
        dependencyPath=$(which "$i")
        if [ -z "$dependencyPath" ]
        then
            printf "%s, missing\n" "$i"
            missingDependencies+=("$i")
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
    printf "Checking for MPR updates...\n"
    internetConnectivity=$(ping -c 1 1.1.1.1)
    if [ -n "$internetConnectivity" ]
    then
        check_versions
        printf "Your version is: $version\n"
        printf "Latest version is: $latestVersion\n"
        if [[ "$version" == "$latestVersion" ]]
        then
            printf "You have the latest version!\n"
        else
            printf "A newer version is available!\n"
            read -rp "Do you want to update to version $latestVersion? [y/n]: " yn

            case $yn in
                [yY] ) printf "Updating...\n"
                    git clone https://github.com/Adamekka/mpr-install
                    cd mpr-install/ || printf "${red}Error:${nc} Something went wrong\n"
                    sudo make install
                    cd .. && rm -f -r mpr-install;;
                [nN] ) printf "Update denied\n";;
                * ) printf "${red}Error:${nc} bad response\n"
                    printf "Type [y] for confirm and [n] for deny\n";;
            esac
        fi
    else
        printf "${yellow}Warning:${nc} You are offline, unable to check for updates\n"
    fi
}

mpr_update_minimal () {
    printf "Checking for MPR updates...\n"
    internetConnectivity=$(ping -c 1 1.1.1.1)
    if [ -n "$internetConnectivity" ]
    then
        check_versions
        if [[ "$version" != "$latestVersion" ]]
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
    mprPackageExistence=$(curl -o /dev/null -s -w "%{http_code}\n" https://mpr.makedeb.org/packages/"$1")
    if [[ $mprPackageExistence -lt 300 ]]
    then
        printf "${bold}$1 available in MPR!${normal}\n"
        git clone "https://mpr.makedeb.org/$1.git" "$HOME/.cache/mpr/$1"
        cd "$HOME"/.cache/mpr/"$1" || printf "${red}Error:${nc} Something went wrong\n"
        makedeb -s -i
        save_package_info "$1"
    else
        printf "${bold}${red}Error:${nc} $1 not available in APT and MPR!${normal}\n"
    fi
}

mpr_packages_update () {
    outdatedPackages=("$@")
    for i in "${outdatedPackages[@]}"
    do
        printf "${yellow}Updating $i...${nc}\n"
        rm -rf "$HOME"/.cache/mpr/"$i"
        git clone "https://mpr.makedeb.org/$i.git" "$HOME/.cache/mpr/$i"
        cd "$HOME"/.cache/mpr/"$i" || printf "${red}Error:${nc} Something went wrong\n"
        makedeb -s -i
        save_package_info "$i"
    done
}

mpr_packages_update_check () {
    printf "${bold}Checking for updates for packages from MPR...${normal}\n"
    internetConnectivity=$(ping -c 1 1.1.1.1)
    if [ -n "$internetConnectivity" ]
    then
        packages+=($(ls ~/.local/share/mpr/list/))
        userHasOutdatedPackage=false
        for i in "${packages[@]}"
        do
            pkgLatestVersion=$(curl -s -X GET "https://mpr.makedeb.org/rpc?v=5&type=info&arg=$i" | jq -r ".results[].Version")
            pkgVersion=$(cat ~/.local/share/mpr/list/$i | grep "Version:" | cut -d ':' -f 2 | cut -c2-)
            printf "${bold}$i${normal}\n"
            printf "Installed version: $pkgVersion\n"
            printf "Latest version: $pkgLatestVersion\n"
            if [[ "$pkgVersion" == "$pkgLatestVersion" ]]
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
            printf "${bold}All packages are up to date!${normal}\n"
        else
            printf "${bold}${yellow}Outdated packages are:\n${outdatedPackages[*]}${nc}${normal}\n"
            mpr_packages_update "${outdatedPackages[@]}"
        fi
    else
        printf "${yellow}Warning:${nc} You are offline, unable to check for updates\n"
    fi
}

save_package_info () {
    if [ ! -d ~/.local/share/mpr/list/ ]
    then
        mkdir -p ~/.local/share/mpr/list
    fi
    pkgInfo=$(dpkg -s "$1")
    echo "$pkgInfo" > ~/.local/share/mpr/list/"$1"
}

help_page () {
    echo " _ __ ___  _ __  _ __ "
    echo "|  _   _ \|  _ \|  __|"
    echo "| | | | | | |_) | |   "
    echo "|_| |_| |_|  __/|_|   "
    echo "          |_|         "
    echo
    echo "${bold}"
    echo "Syntax: mpr <COMMAND> [PACKAGES]"
    echo
    echo "commands:"
    echo
    echo " install${normal} or ${bold}-S${normal} or ${bold}--sync${normal}                  Install a package"
    echo " ${bold}update${normal} or ${bold}-Sy${normal}                            Update the APT cache"
    echo " ${bold}upgrade${normal} or ${bold}-Su${normal}                           Upgrade all installed packages"
    echo " ${bold}-Syu${normal} or ${bold}-Suy${normal}                             Update both caches and upgrade all installed packages"
    echo " ${bold}remove${normal} or ${bold}uninstall${normal} or ${bold}-R${normal} or ${bold}--remove${normal}    Remove a package"
    echo " ${bold}autoremove${normal}                               Remove auto-installed deps which are no longer required"
    echo " ${bold}list${normal} or ${bold}-Q${normal} or ${bold}--query${normal}                    List installed packages"
    echo " ${bold}show${normal} or ${bold}info${normal}                             Show package information"
    echo " ${bold}search${normal}                                   Search for packages"
    # add clone - Clone a package from the MPR
    echo " ${bold}createconfig${normal}                             Creates and updates config"
    echo " ${bold}version${normal} or ${bold}selfupdate${normal} or ${bold}-V${normal} or ${bold}--version${normal} Shows version and checks for update"
    echo " ${bold}*${normal}                                        Shows help page"
    echo
    echo "mpr checks for update automatically once a day"
    printf "mpr supports both APT and Pacman syntax\n\n"
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
    if [[ "$today" != "$lastUpdateCheck" ]]
    then
        mpr_update_minimal
    fi
}

create_config () {
    if [ -f ~/.config/mpr/config.json ]
    then
        read -rp "Do you want to recreate config file? [y/n]: " yn
    else
        yn=y
    fi
    case $yn in
        [yY] )
            printf "Creating config...\n"
            if [ ! -f ~/.config/mpr/config.json ]
            then
                if [ ! -d ~/.config/mpr/ ]
                then
                    mkdir -p ~/.config/mpr
                fi
                touch ~/.config/mpr/config.json
            fi
            if [ -n "$(which nala)" ]
            then
                printf "What package manager should mpr use?\n"
                select opt in "Nala (recommended)" "APT"
                do
                    case $opt in
                        "Nala (recommended)" )
                            packageManager=nala
                            printf "Package manager set to ${bold}Nala${normal}\n"
                            break
                        ;;
                        "APT" )
                            packageManager=apt
                            printf "Package manager set to ${bold}APT${normal}\n"
                            break
                        ;;
                        * )
                            printf "${red}Error:${nc} bad response\n"
                            packageManager=nala
                            printf "Package manager set to ${bold}Nala${normal}\n"
                            break
                        ;;
                    esac
                done
            else
                packageManager=apt
                printf "Package manager set to ${bold}APT${normal}\n"
            fi
            for i in "${otherPackageManagers[@]}"
            do
                if [ -n "$(which "$i")" ]
                then
                    printf "Should mpr also update ${bold}$i${normal} packages?\n"
                    select opt in "Yes" "No"
                    do
                        case $opt in
                            "Yes" )
                                eval "update$i=true"
                                printf "$i packages ${bold}will${normal} be updated\n"
                                break
                            ;;
                            "No" )
                                eval "update$i=false"
                                printf "$i packages ${bold}won't${normal} be updated\n"
                                break
                            ;;
                        esac
                    done
                else
                    eval "use$i=false"
                    printf "$i isn't installed on system, so it's packages ${bold}won't${normal} be updated\n"
                fi
            done
            configJson=$(jq -n \
            --arg packageManager "$packageManager" \
            --arg updateFlatpakPackages "$updateflatpak" \
            '$ARGS.named')
            echo "$configJson" > ~/.config/mpr/config.json
        ;;
        [nN] )
            printf "Denied\n"
        ;;
        * )
            printf "${red}Error:${nc} bad response\n"
            printf "Type [y] for confirm and [n] for deny\n"
        ;;
    esac
}

read_config () {
    if [ ! -f ~/.config/mpr/config.json ]
    then
        printf "${red}${bold}Error:${nc} No config file${normal}\n"
        create_config
    fi
    packageManager=$(cat ~/.config/mpr/config.json | jq -r ".packageManager")
    for i in "${otherPackageManagers[@]}"
    do
        if [[ $(cat ~/.config/mpr/config.json | jq -r ".use$i") == "true" ]]
        then
            eval "use$i=true"
        else
            eval "use$i=false"
        fi
    done
}

#######
#START#
#######


check_dependencies
check_date
arguments=${@:2} # puts arguments to array
read_config

case $1 in
    install | -S | --sync )
        for i in "${arguments[@]}"
        do
            printf "${bold}Trying to find $i...${normal}\n"
            aptPackageExistence=$(apt-cache -qq show "$i")
            if [ -n "$aptPackageExistence" ]
            then
                printf "${bold}$i available in APT!${normal}\n"
                sudo "$packageManager" install "$i"
            elif [ -n "$i" ]
            then
                install_package "$i"
            fi
            printf "\n"
        done
    ;;
    update | -Sy )
        sudo "$packageManager" update
    ;;
    upgrade | -Su )
        sudo "$packageManager" upgrade
        mpr_packages_update_check
        sudo flatpak update
    ;;
    -Suy | -Syu )
        if [[ $packageManager == "apt" ]]
        then
            sudo apt update
        fi
        sudo "$packageManager" upgrade
        mpr_packages_update_check
        sudo flatpak update
    ;;
    remove | uninstall | -R | --remove)
        sudo apt remove "$arguments"
        for i in "${arguments[@]}"
        do
            pkgPath=$(which "$i")
            if [[ $pkgPath != /usr/bin/$i && -f ~/.local/share/mpr/list/$i ]]
            then
                rm ~/.local/share/mpr/list/"$i"
            fi
        done
    ;;
    autoremove )
        sudo "$packageManager" autoremove
    ;;
    list | -Q | --query)
        $packageManager list
    ;;
    show | info )
        $packageManager show "$arguments"
    ;;
    search )
        for i in "${arguments[@]}"
        do
            printf "${bold}Searching for $i...${normal}\n"
            printf "${yellow}APT search result${normal}\n"
            $packageManager search "$i"
            printf "${yellow}MPR search result${normal}\n"
            curl -s "https://mpr.makedeb.org/rpc?v=5&type=info&arg=$i" | jq
        done
    ;;
    version | selfupdate | -V | --version )
        mpr_update
    ;;
    createconfig )
        create_config
    ;;
    * )
        help_page
    ;;
esac
