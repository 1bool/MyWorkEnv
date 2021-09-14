#!/bin/bash

set -e

if [ "$(uname -o)" = Msys ]; then
	DIST=msys
elif [ "$(uname -s)" = Darwin ]; then
	DIST=mac
elif [ -r /etc/os-release ]; then
	source /etc/os-release
	DIST=$ID
elif [ -r /etc/system-release ]; then
	DIST=$(cat /etc/system-release | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
fi
export DIST

PKGS="make git curl bc"
case "$DIST" in
	fedora|centos|redhat)
		if command -v yum; then
			PKGM=yum
		else
			PKGM=dnf
		fi
		export PKGM
		if [ ${DIST} = centos ]; then
			PKGS+=" epel-release"
		fi
		sudo $PKGM -y install $PKGS
		;;
	ubuntu|debian|deepin)
		sudo apt-get update
		sudo apt-get -y install $PKGS grep vim-scripts vim-addon-manager
		;;
	msys)
		pacman -Sy --noconfirm --needed pacman
		pacman -Sy --noconfirm --needed
		pacman -Syu --noconfirm --needed
		pacman -S --noconfirm --needed $PKGS
		;;
	mac)
		xcode-select --install || :
		/usr/bin/ruby -e "`curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install`"
		brew update
		brew install $PKGS
		;;
esac

cd $(dirname $0)
touch dotfiles/* vim/*

make install
