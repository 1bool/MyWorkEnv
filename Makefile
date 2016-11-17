DIST ?= $(if $(filter Darwin,$(shell uname -s)),mac,\
	$(if $(filter Msys,$(shell uname -o)),msys,\
	$(if $(wildcard /etc/os-release),$(shell . /etc/os-release 2> /dev/null && echo $$ID),\
	$(shell cat /etc/system-release | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]'))))
RCFILES = vimrc gvimrc screenrc tmux.conf bashrc bash_profile pylintrc
DESTFILES = $(addprefix $(HOME)/.,$(RCFILES)) $(LOCALDIR)/$(PLCONF)
VIMDIR = $(HOME)/.vim
AUTOLOADDIR = $(VIMDIR)/autoload
PLUGINRC = $(VIMDIR)/pluginrc.vim
PKGS := coreutils tmux
LOCALDIR = $(HOME)/.local/share
PLCONF = powerline/bindings/tmux/powerline.conf
ifeq ($(shell which easy_install 2> /dev/null),)
EZINSTALL = python-setuptools
endif
FONTDIR = $(HOME)/.local/share/fonts
FONTS = .fonts_installed

all: install


ifneq ($(filter $(DIST),ubuntu debian),)
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
	powerline
INSTALLPKGS = $(filter $(shell apt-cache search --names-only '.*' | cut -d' ' -f1),$(PKGS))
GITPLUGINS = $(filter-out %/vim-ycm-windows,$(shell grep '^[[:blank:]]*Plug ' plugrc.vim | cut -d\' -f2)) pathogen
GITTOPKG = $(shell echo $(subst nerdcommenter,nerd-commenter,\
		   $(basename $(notdir $(subst a.vim,alternate.vim,$(GITPLUGINS))))) \
		   | tr [:upper:] [:lower:])
VIMPKGS = $(shell apt-cache search --names-only '^vim-' | cut -d' ' -f1)
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
			 $(addsuffix .vim,$(PKGTOGIT)),$(filter-out \
			 $(addprefix %,$(PKGTOGIT)),$(notdir $(GITPLUGINS)))))

$(VIMDIR):
	mkdir -p $(VIMDIR)

pkgtargets:
	sudo apt-get -y install $(TARGETPKGS)

$(PKGPLUGINTARGETS): $(VIMDIR) $(TARGETPKGS)
	vam install $@

$(BUNDLE)/%:
	git clone https://github.com/$(filter %/$(notdir $@),$(GITPLUGINS)).git $@
	@if [ -d $@/doc ]; then \
		vim +Helptags $@/doc +qall; fi

$(EZINSTALL):
	sudo apt-get -y install $@

$(VIMDIR)/autoload/pathogen.vim:
	mkdir -p $(dir $@)
	curl -LSso $@ https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim

update: install
	sudo apt-get -y update
	sudo apt-get -y upgrade $(TARGETPKGS)
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

ifneq ($(filter $(DIST),mac),)
FONTDIR := $(HOME)/Library/Fonts
BREW = $(shell which brew &> /dev/null || echo brew)
PKGS += macvim the_silver_searcher
INSTALLPKGS = $(PKGS)
TARGETPKGS = $(filter-out $(shell brew list),$(INSTALLPKGS))
PKGUPDATE = brew-update

$(EZINSTALL):
	xcode-select --install

$(BREW):
	-xcode-select --install
	/usr/bin/ruby -e "`curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install`"
	brew update

$(TARGETPKGS): $(BREW)
	@if [ $@ = macvim ]; then \
		brew install $@ --with-lua --with-override-system-vim; \
		brew linkapps macvim; \
	else \
		brew install $@; fi

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
	python3-devel \
	python-psutil \
	pylint \
	wqy-bitmap-fonts \
	wqy-unibit-fonts \
	wqy-zenhei-fonts
INSTALLPKGS = $(PKGS)
TARGETPKGS = $(filter-out $(shell rpm -qa --qf '%{NAME} '),$(INSTALLPKGS))
PKGM ?= $(shell which dnf 2> /dev/null || echo yum)
PKGUPDATE = dnf-update

$(EZINSTALL):
	sudo $(PKGM) -y install $@

pkgtargets:
	sudo $(PKGM) -y install $(TARGETPKGS)

dnf-update:
	sudo $(PKGM) -y upgrade $(INSTALLPKGS)

update: dnf-update
endif

ifneq ($(filter $(DIST),msys),)
DESTFILES += $(HOME)/.minttyrc /usr/bin/vi
PKGS += man-pages-posix unzip diffutils gcc
INSTALLPKGS = $(subst tmux,tmux-git,$(subst ack,perl-ack,$(PKGS)))
TARGETPKGS = $(filter-out $(shell pacman -Qsq),$(INSTALLPKGS))
FONTS :=
ifeq ($(MSYSTEM_CARCH),x86_64)
YCMURL = https://bitbucket.org/Alexander-Shukaev/vim-youcompleteme-for-windows/downloads/vim-ycm-733de48-windows-x64.zip
else
YCMURL = https://bitbucket.org/Alexander-Shukaev/vim-youcompleteme-for-windows/downloads/vim-ycm-733de48-windows-x86.zip
endif

$(EZINSTALL):
	pacman -S --noconfirm python3-setuptools

pkgtargets:
	pacman -S --noconfirm --needed $(TARGETPKGS)

/usr/bin/vi:
	ln -s vim $@

$(VIMDIR)/plugged/vim-ycm-windows/: $(TARGETPKGS)
	curl -LSo /tmp/$(notdir $(YCMURL)) $(YCMURL)
	cd /tmp; unzip -q /tmp/$(notdir $(YCMURL))
	mkdir -p $(PLUGGED)
	mv /tmp/$(basename $(notdir $(YCMURL))) $@
	rm /tmp/$(notdir $(YCMURL))

pacman-update:
	pacman -Su --noconfirm --needed $(INSTALLPKGS)

update: pacman-update

install: $(VIMDIR)/plugged/vim-ycm-windows/
endif

update: install
	vim +PlugUpgrade +PlugUpdate +qall
endif



INPUTFONTS = $(shell find fonts/InputMono -name *.ttf -type f)
FONTDIRS = $(dir $(INPUTFONTS))
TARGETFONTS = $(filter-out $(wildcard $(FONTDIR)/*.ttf), \
	      $(addprefix $(FONTDIR)/,$(notdir $(INPUTFONTS))))

vpath %.ttf $(FONTDIRS)

ifeq ($(filter powerline,$(INSTALLPKGS)),)
ifeq ($(shell echo 'import sys; print([x for x in sys.path if "powerline_status" in x][0])' | python 2> /dev/null),)
PYMS += powerline-status
endif
$(LOCALDIR)/$(PLCONF): $(PYMS)
	mkdir -p $(dir $@)
ifeq ($(filter $(DIST),msys),)
	ln -sf `echo 'import sys; print([x for x in sys.path if "powerline_status" in x][0])' \
		| python`/$(PLCONF) $@
else
	touch $@
endif
else

$(LOCALDIR)/$(PLCONF):
	mkdir -p $(dir $@)
	ln -sf /usr/share/$(PLCONF) $@

endif
ifeq ($(filter python-psutil,$(INSTALLPKGS)),)
ifeq ($(shell echo 'import sys; print([x for x in sys.path if "psutil" in x][0])' | python 2> /dev/null),)
ifeq ($(filter $(DIST),msys),)
PYMS += psutil
endif
endif
endif
ifeq ($(filter pylint,$(INSTALLPKGS)),)
ifeq ($(shell echo 'import sys; print([x for x in sys.path if "pylint" in x][0])' | python 2> /dev/null),)
PYMS += pylint
endif
endif

$(PYMS): $(EZINSTALL) $(TARGETPKGS)
	easy_install --user $@

$(HOME)/.%: %
	ln -nfv $(abspath $<) $@ || cp -fv  $< $@

$(PLUGINRC): $(PRCFILE)
	mkdir -p $(dir $(PLUGINRC))
	ln -nfv $(abspath $(PRCFILE)) $@ || cp -fv $(PRCFILE) $@

fonts/powerline-fonts/:
	git clone https://github.com/powerline/fonts.git $@

$(FONTDIR)/%.ttf: %.ttf
	install -D $< $@

$(TARGETPKGS): pkgtargets

$(TARGETFONTS): $(TARGETPKGS)

.fonts_installed: fonts/powerline-fonts/ $(TARGETFONTS)
	fonts/powerline-fonts/install.sh && touch $@

install: $(DESTFILES) $(TARGETPKGS) $(PKGPLUGINTARGETS) $(GITTARGETS) $(PLUGINRC) $(PLUGGED) $(PYMS) $(FONTS)

uninstall:
	-rm -fr $(DESTFILES) $(GITTARGETS) $(PLUGINRC) $(PLUGGED) $(BUNDLE) $(AUTOLOADDIR)/plug.vim $(FONTS)

.PHONY: all install uninstall update pkgtargets $(TARGETPKGS) $(PYMS) $(EZINSTALL)
