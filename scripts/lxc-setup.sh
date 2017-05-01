#!/usr/bin/env bash

# $1 = distro to build
# $2 = release of distro to build
# $3 = name of container

SETUP_DISTRO="$1"
SETUP_RELEASE="$2"
SETUP_NAME="$3"

if [ "$1" == "help" ] || [ "$SETUP_DISTRO" == "" ] || [ "$SETUP_RELEASE" == "" ] || [ "$SETUP_NAME" == "" ] ; then
    echo "USAGE:"
    echo "lxc-setup.sh DISTRO RELEASE CONTAINER_NAME"
    echo ""
    exit
fi

echo "Creating container..."
sudo lxc-create -t download -n "$SETUP_NAME" -- -d "$SETUP_DISTRO" -r "$SETUP_RELEASE" -a amd64
echo -e "...complete.\n"

echo "Configuring AppArmor for new container..."
echo "lxc.aa_allow_incomplete = 1" | sudo tee --append /run/shm/scratch/lxc/"$SETUP_NAME"/config > /dev/null
echo -e "...complete.\n"

echo "Booting container..."
sudo lxc-start -n "$SETUP_NAME" -d
sleep 5
echo -e "...complete.\n"

echo "Configuring container..."
#    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'sudo -i -u user bash -c ""'
if [ "$SETUP_DISTRO" == "ubuntu" ] ; then
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'apt-get update'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'apt-get install -y openssh-server'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'useradd -m -U -s /bin/bash -G sudo user'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'echo user:pass | sudo chpasswd'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'echo "user ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers'
fi

if [ "$SETUP_DISTRO" == "archlinux" ] ; then
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'pacman --noconfirm -Syu'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'pacman --noconfirm -S git wget openssh sudo base-devel'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'useradd -m -U -s /bin/bash -G wheel user'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'systemctl enable sshd'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'systemctl start sshd'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'echo user:pass | sudo chpasswd'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'echo "user ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'sudo -i -u user bash -c "git clone https://aur.archlinux.org/cower.git --depth 1"'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'sudo -i -u user bash -c "gpg --recv-keys --keyserver hkp://pgp.mit.edu 1EB2638FF56C0C53"'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'sudo -i -u user bash -c "cd ~/cower ; makepkg -s --noconfirm"'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'sudo -i -u user bash -c "sudo pacman -U ~/cower/cower-*.pkg.tar.xz --noconfirm"'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'sudo -i -u user bash -c "git clone https://aur.archlinux.org/pacaur.git --depth 1"'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'sudo -i -u user bash -c "cd ~/pacaur ; makepkg -s --noconfirm"'
    sudo lxc-attach -n "$SETUP_NAME" -- bash -c 'sudo -i -u user bash -c "sudo pacman -U ~/pacaur/pacaur-*.pkg.tar.xz --noconfirm"'

    echo -e "\nTo clone PKGBUILD's, use the following command:"
    echo -e "$> sudo lxc-attach -n $SETUP_NAME -- bash -c 'sudo -i -u user bash -c \"git clone https://aur.archlinux.org/\$PACKAGE_NAME.git --depth 1\"'\n"

    echo -e "To build packages from a PKGBUILD, use the following command:"
    echo -e "$> sudo lxc-attach -n $SETUP_NAME -- bash -c 'sudo -i -u user bash -c \"cd ~/\$PACKAGE_NAME ; makepkg -s --noconfirm\"'\n"

    echo -e "To install packages built from a PKGBUILD, use the following command:"
    echo -e "$> sudo lxc-attach -n $SETUP_NAME -- bash -c 'sudo -i -u user bash -c \"sudo pacman -U ~/\$PACKAGE_NAME/\$PACKAGE_NAME-*.pkg.tar.xz\"'\n"

    echo -e "To install packages from the AUR, use the following command:"
    echo -e "$> sudo lxc-attach -n $SETUP_NAME -- bash -c 'sudo -i -u user bash -c \"pacaur -S \$PACKAGE_NAME --noconfirm --noedit\"'\n"

fi

echo -e "...complete.\n"

echo "Container IP address:"
sudo lxc-ls --fancy | grep "NAME"
sudo lxc-ls --fancy | grep "$SETUP_NAME"

echo -e "\nContainer login:          user"
echo -e "Container user password:  pass\n"
echo -e "To run commands as 'user' with sudo privileges, use the following command:"
echo -e "$> sudo lxc-attach -n $SETUP_NAME -- bash -c 'sudo -i -u user bash -c \"\$COMMAND\"'\n"

echo -e "Setup complete."
