DESTFILES += /usr/bin/vi
PKGS += mintty man-pages-posix unzip diffutils python2 python-pip
PYMS += mintty-colors
INSTALLTARGETS := $(subst ack,perl-ack,\
		  $(filter-out clang ssh-askpass,$(PKGS)))
TARGETPKGS = $(filter-out $(shell pacman -Qsq),$(INSTALLPKGS))
FONTS :=

$(INSTALLPKGS):
	pacman -S --noconfirm --needed $@

install-pkgs:
	pacman -S --noconfirm --needed $(TARGETPKGS)

/usr/bin/vi:
	ln -s vim $@

pacman-update:
	pacman -Sy --noconfirm
	pacman -Su --noconfirm --needed $(INSTALLPKGS)

update: pacman-update # powerline-go-update

