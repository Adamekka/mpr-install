# mpr-install
A faster and nicer way to install packages from mpr (makedeb package repository).<br />
You can install things, that are only on Flatpak and Snap and not on apt, like btop and Discord.

## Dependencies

* cat
* curl
* git
* make
* makedeb
* wget

## Setup and run guide

1. Clone this repo:
```
git clone https://github.com/Adamekka/mpr-install
```
2. Go to mpr-install folder:
```
cd mpr-install/
```
3. Run "sudo make install" to install this script to your system:
```
sudo make install
```
4. Run "mpr" to start script:
```
mpr
```
5. Insert package name you would like to install and done:<br />
![image](https://user-images.githubusercontent.com/68786400/177309057-252afe1d-da57-4fc9-b11d-bd8e9ee01138.png)

6. (optional) Remove "mpr-install" folder, that you cloned to your home folder:
```
cd .. && rm -f -r mpr-install
```

## Updating

1. If you want to check for updates, run "mpr-update":
```
mpr-update
```
## Known issues

1. You do not have permission for the directory $BUILDDIR:
![image](https://user-images.githubusercontent.com/68786400/177850543-a921acda-5d70-4459-91e2-6e452542fd63.png)

Fix: Delete folder that it created previously.<br />
For example downloading "btop" failed for me, so I had to "rm -rf btop/" and run "mpr" again.
```
rm -rf PackageThatItFailedToDownload/
```
