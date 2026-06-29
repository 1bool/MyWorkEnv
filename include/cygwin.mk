PKGS += mintty man-pages-posix unzip diffutils python-pip
PKGS += gcc cmake libcrypt-devel # for ycm compiling
PYMS += mintty-colors
INSTALLTARGETS := $(subst ack,perl-ack,\
		  $(filter-out clang ssh-askpass,$(PKGS)))
TARGETPKGS = $(filter-out $(shell pacman -Qsq),$(INSTALLPKGS))
FONTS :=

$(TARGET_POWERLINE_GO): | $(HOME)/.local/bin/
	curl -LSso $@ https://github.com/justjanne/powerline-go/releases/latest/download/powerline-go-windows-amd64.exe || rm -f $@
	chmod a+x $@

$(INSTALLPKGS):
	pacman -S --noconfirm --needed $@

install-pkgs:
	pacman -S --noconfirm --needed $(TARGETPKGS)

pacman-update:
	pacman -Sy --noconfirm
	pacman -Su --noconfirm --needed $(INSTALLPKGS)

update: pacman-update # powerline-go-update