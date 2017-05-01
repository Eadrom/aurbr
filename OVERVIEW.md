Need some config files:
/etc/aurbr/package.list - this is a list of package names that AURBR needs to keep in the repo
/etc/aurbr/settings.conf - this is a list of tunable bits, GPG key location, path to package database, path to repositories, package build time database location/connection information, etc
A systemd timer to run the AURBR maintenance program outlined below.
A systemd timer to check every 2-4 weeks if Let's Encrypt TLS certificate needs to be refreshed and restart nginx if the cert is refreshed

Sample build test command:
$> pacaur --silent --needed --noedit --noconfirm -m s3fs-fuse-git neofetch arch-audit aurvote rar dropbox-cli dpkg x264-git
List all built packages:
$> ls ~/.cache/pacaur/*/*.pkg.tar.xz

Once a day (midnight?), need to check which packages need to be updated, spin up build slaves, build the packages, import the new packages into the package db and remove the old packages from the pkg db.

Check which packages need to be updated:

1. Compare packages in config list to what is in repo.  If there are any packages not in the package list but still in the repo, need to repo-remove those packages and delete the package and signature files
*  Next, run `pacaur -k $REPO_PACKAGES_LIST` and build list of which packages need to be re-built
*  Look up the package name in the build time database and build a dictionary of name:time
*  If the aggregate build time is over one hour (55 minutes?), split the packages into two time-equal lists.
*  Kick off the build progress below and pass a list to each build slave

Build process:

1. Generate an SSH key-pair to use for this build
*  Using DO API, create an instance with the new keypair used to authenticate root
*  Use a series of SSH commands to provision host for LXC (install lxc, configure lxc network, etc)
*  Copy lxc-setup.sh to build slaves
*  Run `lxc-setup.sh archlinux current builder` to create a build container
*  Via SSH from the repo master, execute `pacaur --silent --needed --noedit --noconfirm -m $PKGNAME` on the container; need to time this and store that value 
*  Built packages are stored in:
  * $LXC_ROOT/$CONTAINER_NAME/rootfs/home/$USER/.cache/pacaur/$PACKAGE_NAME/$PACKAGENAME-*.pkg.tar.xz
*  Note that there may be additional packages created via split PKGBUILD's, so I'll need a way to detect those (parse PKGBUILD?) and grab all of the built packages

Sign and Update Repo:
1.  SCP all the built packages from the build slaves into a staging directory on the repo mater.  The number of built packages retrieved should equal the number of packages sent to the builders.
2.  GPG sign new packages
3.  Copy the new packages into their $arch specific repository directories
4.  Use `repo-add /path/to/pkg.db /path/to/$arch/*.pkg.tar.xz` to add new packages to repo db
5.  Use `repo-remove /path/to/pkg.db /path/to/$arch/{$PKG_NAMES}-*.pkg.tar.xz` to remove old versions of packages
6.  Use DO API to destroy build slave machines
