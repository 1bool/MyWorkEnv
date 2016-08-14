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

PKGS="make git curl"
case "$DIST" in
	fedora|centos|redhat)
		if command -v yum; then
			PKGM=yum
		else
			PKGM=dnf
		fi
		export PKGM
		sudo $PKGM -y install $PKGS
		;;
	ubuntu|debian)
		sudo apt-get -y install $PKGS grep
		;;
	msys)
		pacman -Sy --noconfirm pacman
		pacman -Sy --noconfirm
		pacman -Syu --noconfirm
		pacman -S --noconfirm $PKGS
		;;
	mac)
		xcode-select --install
		/usr/bin/ruby -e "`curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install`"
		brew update
		brew install $PKGS
		;;
esac

make install
