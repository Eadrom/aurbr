# AUR Binary Repository

AURBR builds a selection of the most commonly built and most popular AUR packages and makes them available in signed binary packages.  AURBR is pronounced like the word "arbor".  AURBR is still in extremely early development.

### IMPORTANT:
AURBR packages are NOT official Arch Linux packages.  Do not contact the Arch Linux project if you are having problems with a package installed from AURBR.  If you are having a problem with a package installed from AURBR, first try removing the package and building it yourself via makepkg.  If you are still having problems, consult the package's AUR page.

To check if a package you installed is an AURBR package, run the following command:
`$> pacman -Sl aurbr | grep $PACKAGE_NAME`

##### Note:
AURBR is currently under development.  There is not an active repository available at this time.  If you add the repository below, at best, nothing will happen and at worst, your pacman tasks could fail due to a 404 on a configured repo.

###### Installation
To configure your system to use AURBR packages:

1.  Add the following key to your pacman keyring:
  * Fetch the key:  `$> pacman-key -r $keyID`
  * Verify the key:  `$> pacman-key -f $keyID`
  * Locally sign the key:  `$> pacman-key --lsign-key $keyID`

2.  Add the following to the end of your `/etc/pacman.conf`:
```
[aurbr]
Server = https://aurbr.1geek4solutions.com/$arch
```

3.  Update your local package database:
`$> sudo pacman -Sy`

You can now install AURBR packages using `pacman`.  AURBR packages do not require an AUR helper to be installed on the system to install or upgrade packages or check for updates.  If a package included in AURBR has dependencies on another AUR package, those dependent packages will also be included in AURBR.  All package maintainence tasks can be accomplished using pacman just as you would with official Arch Linux packages.
