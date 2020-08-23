DESTFILES += /usr/bin/vi
PKGS += mintty man-pages-posix unzip diffutils python2 python-pip
# PKGS += mingw-w64-x86_64-go # for powerline-go
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

# ifeq ($(MSYSTEM_CARCH),x86_64)
# YCMURL := ftp://w1ball.f3322.net:2102/YouCompleteMe-w64-2016-9-23.rar
# UNPAK := unrar x -idq
# else
# YCMURL := https://bitbucket.org/Alexander-Shukaev/vim-youcompleteme-for-windows/downloads/vim-ycm-733de48-windows-x86.zip
# UNPAK := unzip -q
# endif
#
# $(VIMDIR)/plugged/YouCompleteMe/: $(TARGETPKGS) /tmp/$(notdir $(YCMURL))
#     mkdir -p $(PLUGGED)
#     cd $(PLUGGED); $(UNPAK) /tmp/$(notdir $(YCMURL))
#     @if [ ! -e $@ ]; then mv $(basename $@)/vim-ycm-windows $@; fi
#     touch $@
#
# /tmp/$(notdir $(YCMURL)):
#     curl -C - -LSo /tmp/$(notdir $(YCMURL)).part $(YCMURL)
#     mv /tmp/$(notdir $(YCMURL)).part $@

pacman-update:
	pacman -Sy --noconfirm
	pacman -Su --noconfirm --needed $(INSTALLPKGS)

# powerline-go-install powerline-go-update:
#     go get -u github.com/justjanne/powerline-go

# install: powerline-go-install
update: pacman-update # powerline-go-update

# install: $(VIMDIR)/plugged/YouCompleteMe/
