# mpr-install
A complete MPR helper
## Trello

https://trello.com/b/0PaxQ7HH/mpr-install

## Dependencies

* curl
* git
* jq
* make
* makedeb
* nala (optional) - https://gitlab.com/volian/nala

## Install

1. Clone this repo:
```
git clone https://github.com/Adamekka/mpr-install
```
2. Go to ```mpr-install``` folder:
```
cd mpr-install/
```
3. Run ```sudo make install``` to install this script to your system:
```
sudo make install
```
4. (optional) Remove ```mpr-install``` folder, that you cloned to your home folder:
```
cd .. && rm -rf mpr-install
```

## Usage

![image](https://user-images.githubusercontent.com/68786400/179354119-6d7fbbb1-c8fc-4f4e-b7ac-bfeb4096b8a3.png)

## Config

##### Config is created automatically using 
```
mpr createconfig
```

You can find it in
```
~/.config/mpr/config.json
```
The only available options are ```apt``` and ```nala```.
It is case sensitive.
If you set it to another value, then the script won't work properly.

## Uninstall

```
sudo rm /usr/bin/mpr
```

## Known issues

1. You do not have permission for the directory $BUILDDIR:
![image](https://user-images.githubusercontent.com/68786400/177850543-a921acda-5d70-4459-91e2-6e452542fd63.png)

Fix: Delete folder that it created previously.<br />
For example downloading  ```btop``` failed for me, so I had to  ```rm -rf btop/``` and run ```mpr install btop``` again.
```
rm -rf PackageThatItFailedToDownload/
```
## Buy me a coffee :)))

https://paypal.me/retardant
