DESTFILES += $(HOME)/.minttyrc /usr/bin/vi
PKGS += man-pages-posix unzip diffutils gcc unrar python2
INSTALLTARGETS = $(subst ack,perl-ack,\
	      $(subst python-setuptools,python3-setuptools,\
		  $(subst clang,clang-svn,$(PKGS))))
TARGETPKGS = $(filter-out $(shell pacman -Qsq),$(INSTALLPKGS))
FONTS :=

$(INSTALLPKGS):
	pacman -S --noconfirm --needed $@

install-pkgs:
	pacman -S --noconfirm --needed $(TARGETPKGS)

/usr/bin/vi:
	ln -s vim $@

# ifeq ($(MSYSTEM_CARCH),x86_64)
# YCMURL = ftp://w1ball.f3322.net:2102/YouCompleteMe-w64-2016-9-23.rar
# UNPAK = unrar x -idq
# else
# YCMURL = https://bitbucket.org/Alexander-Shukaev/vim-youcompleteme-for-windows/downloads/vim-ycm-733de48-windows-x86.zip
# UNPAK = unzip -q
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
	pacman -Su --noconfirm --needed $(INSTALLPKGS)

update: pacman-update

# install: $(VIMDIR)/plugged/YouCompleteMe/
