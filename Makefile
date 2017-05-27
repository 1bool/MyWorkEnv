SHELL := /bin/bash
DIST ?= $(strip $(if $(filter Darwin,$(shell uname -s)),mac,\
	$(if $(filter Msys,$(shell uname -o)),msys,\
	$(if $(wildcard /etc/os-release),$(shell . /etc/os-release 2> /dev/null && echo $$ID),\
	$(shell cat /etc/system-release | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')))))
RCFILES = vimrc vimrc.local gvimrc gvimrc.local screenrc tmux.conf bashrc profile bash_aliases pylintrc dircolors
DESTFILES = $(addprefix $(HOME)/.,$(RCFILES))
VIMDIR = $(HOME)/.vim
AUTOLOADDIR = $(VIMDIR)/autoload
PLUGINRC = $(VIMDIR)/pluginrc.vim
PKGS := coreutils tmux curl python-setuptools
LOCALDIR = $(HOME)/.local/share
FONTDIR = $(HOME)/.local/share/fonts
FONTS = .fonts_installed

all: install


ifneq ($(filter $(DIST),ubuntu debian deepin),)
ifneq ($(shell fgrep 'Microsoft@Microsoft.com' /proc/version),)
DIST = win
endif
UBUNTU_VER = $(shell . /etc/os-release && echo $$VERSION_ID)
APT_STAMP = '/var/lib/apt/periodic/update-success-stamp'
BUNDLE = $(VIMDIR)/bundle
PRCFILE = pathogenrc.vim
PKGS += git \
	exuberant-ctags \
	vim-gnome \
	vim-addon-manager \
	vim-scripts \
	fonts-wqy-zenhei \
	silversearcher-ag \
	pylint \
	fontconfig \
	python-psutil \
	powerline \
	language-pack-zh-hans
INSTALLPKGS = $(filter $(shell apt-cache search --names-only '.*' | cut -d' ' -f1),$(PKGS))
GITPLUGINS = $(filter-out %/vim-ycm-windows,$(shell grep '^[[:blank:]]*Plug ' plugrc.vim | cut -d\' -f2)) pathogen
GITTOPKG = $(shell echo $(subst nerdcommenter,nerd-commenter,\
		   $(basename $(notdir $(subst a.vim,alternate.vim,$(GITPLUGINS))))) \
		   | tr [:upper:] [:lower:])
ifeq ($(UBUNTU_VER),16.04)
INSTALLPKGS += thefuck
# vim-youcompleteme doesn't work in 16.04
VIMPKGS = $(filter-out vim-youcompleteme,$(shell apt-cache search --names-only '^vim-' | cut -d' ' -f1))
INSTALLPKGS += cmake python-dev python3-dev g++ gcc
else
VIMPKGS = $(shell apt-cache search --names-only '^vim-' | cut -d' ' -f1)
endif
PLUGINPKGS = $(filter $(addprefix %,$(GITTOPKG)),$(VIMPKGS))
VAMLIST = $(basename $(shell apt-cache show vim-scripts | grep '*' \
		  | sed -e 's/_/-/g' -e 's/a.vim/alternate.vim/' \
		  | grep -o '[[:alnum:]-]*\.vim' | tr '[:upper:]' '[:lower:]')) \
		  $(VIMPKGS:vim-%=%)
PKGPLUGINS = $(filter $(GITTOPKG:vim-%=%),$(VAMLIST))
INSTALLPKGS += $(PLUGINPKGS)
TARGETPKGS = $(filter-out $(shell dpkg --get-selections | cut -f1 | cut -d':' -f1),\
	$(INSTALLPKGS))
PKGPLUGINTARGETS = $(filter-out $(shell vam -q status $(PKGPLUGINS) 2> /dev/null | \
				   grep installed | cut -f1),$(PKGPLUGINS))
PKGTOGIT = $(subst youcompleteme,YouCompleteMe,\
		   $(subst nerd-commenter,nerdcommenter,\
		   $(subst alternate,a,\
		   $(VAMLIST))))
ifeq ($(filter pathogen,$(PKGTOGIT)),)
PKGTOGIT += pathogen
DESTFILES += $(VIMDIR)/autoload/pathogen.vim
endif
GITTARGETS = $(addprefix $(BUNDLE)/,$(filter-out \
	     $(PKGTOGIT), $(filter-out \
	     $(addsuffix .vim,$(PKGTOGIT)),$(filter-out \
	     $(addprefix vim-,$(PKGTOGIT)),$(notdir $(GITPLUGINS))))))

$(VIMDIR)/:
	mkdir -p $(VIMDIR)

powerline: $(APT_STAMP)
	sudo apt-get -y install $@
	systemctl --user enable powerline-daemon
	systemctl --user start powerline-daemon

$(filter-out powerline,$(INSTALLPKGS)): $(APT_STAMP)
	sudo apt-get -y install $@

install-pkgs: $(APT_STAMP)
ifneq ($(TARGETPKGS),)
	sudo apt-get -y install $(TARGETPKGS)
endif

$(PKGPLUGINTARGETS): $(TARGETPKGS) | $(VIMDIR)/
	vam install $@

$(BUNDLE)/%:
	git clone https://github.com/$(filter %/$(notdir $@),$(GITPLUGINS)).git $@
	@if [ -d $@/doc ]; then \
		vim +Helptags $@/doc +qall; fi

$(BUNDLE)/YouCompleteMe/: $(TARGETPKGS)
	git clone https://github.com/$(filter %/$(notdir $@),$(GITPLUGINS)).git $@
	cd $@ && git submodule update --init --recursive
	cd $@ && ./install.py --clang-completer
	@if [ -d $@/doc ]; then \
		vim +Helptags $@/doc +qall; fi

$(APT_STAMP):
	sudo apt-get update

$(VIMDIR)/autoload/pathogen.vim:
	mkdir -p $(dir $@)
	curl -LSso $@ https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim

update: apt-update

apt-update:
	sudo apt-get -y update
	sudo apt-get -y upgrade $(INSTALLPKGS)

vimplug-update:
	@for dir in $(GITTARGETS); do \
		echo Updating $$dir; git -C $$dir pull; done

.PHONY: $(PKGPLUGINS) $(PKGPLUGINTARGETS)
else



PLUGGED = $(VIMDIR)/plugged
PRCFILE = plugrc.vim
PKGS += ctags cmake ack

$(AUTOLOADDIR)/plug.vim:
	curl -fLo $@ --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

$(PLUGGED): $(AUTOLOADDIR)/plug.vim $(PLUGINRC)
	vim +PlugInstall +qall
	@touch $(PLUGGED)

ifeq ($(DIST),mac)
FONTDIR := $(HOME)/Library/Fonts
BREW = $(shell which brew &> /dev/null || echo brew)
PKGS += macvim the_silver_searcher thefuck
INSTALLPKGS = $(filter-out python-setuptools,$(PKGS))
TARGETPKGS = $(filter-out $(shell brew cask list),$(filter-out $(shell brew list),$(INSTALLPKGS)))
PKGUPDATE = brew-update

$(EZINSTALL):
	xcode-select --install

$(BREW):
	-xcode-select --install
	sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
	/usr/bin/ruby -e "`curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install`"
	brew update

$(filter-out macvim,$(INSTALLPKGS)): $(BREW)
	brew install $@

macvim: $(BREW)
	brew cask install $@

install-pkgs:
	brew cask install $@
	brew install $(filter-out macvim,$(TARGETPKGS))

brew-update:
	brew update
	-brew upgrade

update: brew-update

.PHONY: $(BREW) brew-update
endif


ifneq ($(filter $(DIST),fedora centos redhat),)
PKGS += git \
	vim-enhanced \
	vim-X11 \
	automake \
	gcc \
	gcc-c++ \
	kernel-devel \
	python-devel \
	python-psutil \
	pylint \
	wqy-zenhei-fonts
PKGS += $(if $(shell fgrep ' 6.' /etc/redhat-release),\
	python34-devel,\
	python3-devel \
	wqy-bitmap-fonts \
	wqy-unibit-fonts)
INSTALLPKGS = $(PKGS)
TARGETPKGS = $(filter-out $(shell rpm -qa --qf '%{NAME} '),$(INSTALLPKGS))
PKGM ?= $(shell which dnf 2> /dev/null || echo yum)
PKGUPDATE = dnf-update

$(INSTALLPKGS):
	sudo $(PKGM) -y install $@

install-pkgs:
ifneq ($(TARGETPKGS),)
	sudo $(PKGM) -y install $(TARGETPKGS)
endif

dnf-update:
	sudo $(PKGM) -y upgrade $(INSTALLPKGS)

update: dnf-update
endif

ifeq ($(DIST),msys)
DESTFILES += $(HOME)/.minttyrc /usr/bin/vi
PKGS += man-pages-posix unzip diffutils gcc unrar
INSTALLPKGS = $(subst tmux,tmux-git, \
	      $(subst ack,perl-ack, \
	      $(subst python-setuptools,python3-setuptools,$(PKGS))))
TARGETPKGS = $(filter-out $(shell pacman -Qsq),$(INSTALLPKGS))
FONTS :=
ifeq ($(MSYSTEM_CARCH),x86_64)
YCMURL = ftp://w1ball.f3322.net:2102/YouCompleteMe-w64-2016-9-23.rar
UNPAK = unrar x -idq
else
YCMURL = https://bitbucket.org/Alexander-Shukaev/vim-youcompleteme-for-windows/downloads/vim-ycm-733de48-windows-x86.zip
UNPAK = unzip -q
endif

$(INSTALLPKGS):
	pacman -S --noconfirm --needed $@

ifneq ($(TARGETPKGS),)
install-pkgs:
	pacman -S --noconfirm --needed $(TARGETPKGS)
endif

/usr/bin/vi:
	ln -s vim $@

$(VIMDIR)/plugged/YouCompleteMe/: $(TARGETPKGS) /tmp/$(notdir $(YCMURL))
	mkdir -p $(PLUGGED)
	cd $(PLUGGED); $(UNPAK) /tmp/$(notdir $(YCMURL))
	@if [ ! -e $@ ]; then mv $(basename $@)/vim-ycm-windows $@; fi
	touch $@

/tmp/$(notdir $(YCMURL)):
	curl -C - -LSo /tmp/$(notdir $(YCMURL)).part $(YCMURL)
	mv /tmp/$(notdir $(YCMURL)).part $@

pacman-update:
	pacman -Su --noconfirm --needed $(INSTALLPKGS)

update: pacman-update

install: $(VIMDIR)/plugged/YouCompleteMe/
endif

vimplug-update:
	vim +PlugUpgrade +PlugUpdate +qall
endif



INPUTFONTS = $(shell find fonts/InputMono -name *.ttf -type f)
FONTDIRS = $(dir $(INPUTFONTS))
TARGETFONTS = $(filter-out $(wildcard $(FONTDIR)/*.ttf), \
	      $(addprefix $(FONTDIR)/,$(notdir $(INPUTFONTS))))

vpath %.ttf $(FONTDIRS)

ifeq ($(shell echo 'import sys; print([x for x in sys.path if "powerline_status" in x][0])' | python 2> /dev/null),)
PYMS += $(if $(filter powerline,$(INSTALLPKGS)),,powerline-status)
endif
ifeq ($(shell echo 'import sys; print([x for x in sys.path if "psutil" in x][0])' | python 2> /dev/null),)
PYMS += $(if $(filter python-psutil,$(INSTALLPKGS)),,$(if $(filter $(DIST),msys),,psutil))
endif
ifeq ($(shell echo 'import sys; print([x for x in sys.path if "pylint" in x][0])' | python 2> /dev/null),)
PYMS += $(if $(filter pylint,$(INSTALLPKGS)),,pylint)
endif

$(PYMS): $(EZINSTALL) $(TARGETPKGS)
	easy_install $(if $(shell easy_install --help | fgrep -e '--user'),--user,--prefix ~/.local) $@

$(HOME)/%vimrc.local:
	touch $@

.SECONDEXPANSION:
$(HOME)/.%: $$(wildcard include/$$(DIST)$$(@F)) %
	@if [ -h $@ ] || [[ -f $@ && "$$(stat -c %h -- $@ 2> /dev/null)" -gt 1 ]]; then rm -f $@; fi
	cat $^ > $@

$(PLUGINRC): $(PRCFILE)
	mkdir -p $(dir $(PLUGINRC))
	ln -nfv $(abspath $(PRCFILE)) $@ || cp -fv $(PRCFILE) $@

fonts/powerline-fonts/:
	git clone https://github.com/powerline/fonts.git $@

$(FONTDIR)/:
	mkdir -p $@

$(FONTDIR)/%.ttf: %.ttf | $(FONTDIR)/
	install $< $@

$(TARGETFONTS): $(TARGETPKGS)

.fonts_installed: fonts/powerline-fonts/ $(TARGETFONTS)
	fonts/powerline-fonts/install.sh && touch $@

fonts-update: fonts/powerline-fonts/
	git -C $< pull
	$</install.sh

$(TARGETPKGS): install-pkgs

ifneq ($(wildcard $(HOME)/.bash_profile),)
DESTFILES += del-bash_profile
endif

del-bash_profile:
	mv -iv $(HOME)/.bash_profile $(HOME)/.bash_profile.old

install: $(DESTFILES) $(TARGETPKGS) $(PKGPLUGINTARGETS) $(GITTARGETS) $(PLUGINRC) $(PLUGGED) $(PYMS) $(FONTS)

update: install vimplug-update $(patsubst %,fonts-update,$(filter-out msys,$(DIST)))

uninstall:
	-rm -fr $(DESTFILES) $(GITTARGETS) $(PLUGINRC) $(PLUGGED) $(BUNDLE) $(AUTOLOADDIR)/plug.vim $(FONTS)

.PHONY: all install install-pkgs uninstall update del-bash_profile vimplug-update fonts-update\
	$(TARGETPKGS) $(PYMS) $(EZINSTALL)
