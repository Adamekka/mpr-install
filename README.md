# mpr-install
A faster and nicer way to install packages from mpr (makedeb package repository).

## Dependencies

* cat
* curl
* git
* makedeb

## Setup and run guide

1. Clone this repo:<br />
```
git clone https://github.com/Adamekka/mpr-install
```
2. Go to mpr-install folder:
```
cd mpr-install/
```
2. Run "sudo make install" to install this script to your system:<br />
```
sudo make install
```
3. Run "mpr" to start script:<br />
```
mpr
```
4. Insert package name you would like to install and done:<br /><br />
![image](https://user-images.githubusercontent.com/68786400/177309057-252afe1d-da57-4fc9-b11d-bd8e9ee01138.png)

5. (optional) Remove "mpr-install" folder, that you cloned to your home folder:
```
cd .. && rm -f -r mpr-install
```
<br />
PS: You can install things, that are only on Flatpak and Snap and not on apt, like btop and Discord.
