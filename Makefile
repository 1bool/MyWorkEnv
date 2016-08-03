RCFILES = vimrc gvimrc screenrc tmux.conf bashrc bash_profile pylintrc
DESTFILES = $(addprefix $(HOME)/.,$(RCFILES)) $(LOCALDIR)/$(PLCONF)
VIMDIR = $(HOME)/.vim
AUTOLOADDIR = $(VIMDIR)/autoload
PLUGINRC = $(VIMDIR)/pluginrc.vim
ifeq ($(shell uname -s),Darwin)
DIST = mac
else
DIST = $(shell . /etc/os-release 2> /dev/null && echo $$ID)
endif
ifeq ($(DIST),)
DIST = $(shell cat /etc/system-release | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
endif
PKGS = coreutils tmux
LOCALDIR = $(HOME)/.local/share
PLCONF = powerline/bindings/tmux/powerline.conf
ifeq ($(shell which easy_install 2> /dev/null),)
EZINSTALL = python-setuptools
endif

all: install


ifneq ($(filter $(DIST),ubuntu debian),)
VER = $(shell . /etc/os-release 2> /dev/null && echo $$VERSION_ID)
BUNDLE = $(VIMDIR)/bundle
PRCFILE = pathogenrc.vim
PKGS += exuberant-ctags \
	vim-gnome \
	vim-addon-manager \
	vim-scripts \
	fonts-wqy-zenhei \
	silversearcher-ag \
	pylint \
	fontconfig \
	python-psutil
GITPLUGINS = $(shell grep '^[[:blank:]]*Plug ' plugrc.vim | cut -d\' -f2)
ifeq ($(VER),16.04)
PKGS += powerline
GITPLUGINS += pathogen
else
DESTFILES += $(VIMDIR)/autoload/pathogen.vim
endif
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
PKGS += $(PLUGINPKGS)
TARGETPKGS = $(filter-out $(shell dpkg --get-selections \
			 | grep -v deinstall | cut -f1),$(PKGS))
PKGPLUGINTARGETS = $(filter-out $(shell vam -q status $(PKGPLUGINS) 2> /dev/null | \
				   grep installed | cut -f1),$(PKGPLUGINS))
PKGTOGIT = $(subst youcompleteme,YouCompleteMe,\
		   $(subst nerd-commenter,nerdcommenter,\
		   $(subst alternate,a,\
		   $(VAMLIST))))
GITTARGETS = $(addprefix $(BUNDLE)/,$(filter-out \
			 $(addsuffix .vim,$(PKGTOGIT)),$(filter-out \
			 $(addprefix %,$(PKGTOGIT)),$(notdir $(GITPLUGINS)))))
ifneq ($(TARGETPKGS),)
PKGTARGETS=pkgtargets
endif

$(VIMDIR):
	mkdir -p $(VIMDIR)

$(PKGTARGETS):
	sudo apt-get -y install $(TARGETPKGS)

$(PKGPLUGINTARGETS): $(VIMDIR) $(PKGTARGETS)
	vam install $@

$(BUNDLE)/%:
	git clone https://github.com/$(filter %/$(notdir $@),$(GITPLUGINS)).git $@
	@if [ -d $@/doc ]; then \
		vim +Helptags $@/doc +qall; fi

$(LOCALDIR)/$(PLCONF):
	mkdir -p $(dir $@)
	ln -sf /usr/share/$(PLCONF) $@

$(EZINSTALL):
	sudo apt-get -y install $@

$(VIMDIR)/autoload/pathogen.vim:
	mkdir -p $(dir $@)
	curl -LSso $@ https://tpo.pe/pathogen.vim

update: install
	sudo apt-get -y update
	sudo apt-get -y upgrade $(PKGS)
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
BREW = $(shell which brew &> /dev/null || echo brew)
PKGS += macvim the_silver_searcher
PKGTARGETS = $(filter-out $(shell brew list),$(PKGS))
PKGUPDATE = brew-update

$(EZINSTALL):
	xcode-select --install

$(BREW):
	-xcode-select --install
	/usr/bin/ruby -e "`curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install`"
	brew update

$(PKGTARGETS): $(BREW)
	@if [ $@ = macvim ]; then \
		brew install $@ --with-lua --with-override-system-vim; \
		brew linkapps macvim; \
	else \
		brew install $@; fi

$(PYLINT): $(EZINSTALL)
	easy_install --user $@

brew-update:
	brew update
	-brew upgrade

.PHONY: $(BREW) brew-update
endif

ifneq ($(filter $(DIST),fedora centos redhat),)
PKGS += vim-enhanced \
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
TARGETPKGS = $(filter-out $(shell rpm -qa --qf '%{NAME} '),$(PKGS))
ifneq ($(TARGETPKGS),)
PKGTARGETS=pkgtargets
endif
DNF = $(shell which dnf 2> /dev/null || echo yum)
PKGUPDATE = dnf-update

$(EZINSTALL):
	sudo $(DNF) -y install $@

$(PKGTARGETS):
	sudo $(DNF) -y install $(TARGETPKGS)

dnf-update:
	sudo $(DNF) -y upgrade $(PKGS)
endif

$(LOCALDIR)/$(PLCONF): $(PYMS)
	mkdir -p $(dir $@)
	ln -sf `echo 'import sys; print [x for x in sys.path if "powerline_status" in x][0]' \
		| python`/$(PLCONF) $@

update: install $(PKGUPDATE)
	vim +PlugUpgrade +PlugUpdate +qall

.PHONY: $(EZINSTALL) $(PKGUPDATE)
endif



ifeq ($(filter powerline,$(PKGS)),)
ifeq ($(shell echo 'import sys; print [x for x in sys.path if "powerline_status" in x][0]' | python 2> /dev/null),)
PYMS += powerline-status
endif
endif
ifeq ($(filter python-psutil,$(PKGS)),)
ifeq ($(shell echo 'import sys; print [x for x in sys.path if "psutil" in x][0]' | python 2> /dev/null),)
PYMS += psutil
endif
endif
ifeq ($(filter pylint,$(PKGS)),)
ifeq ($(shell echo 'import sys; print [x for x in sys.path if "pylint" in x][0]' | python 2> /dev/null),)
PYMS += pylint
endif
endif

$(PYMS): $(EZINSTALL) $(PKGTARGETS)
	easy_install --user $@

$(HOME)/.%: %
	ln -nfv $(abspath $<) $@ || cp -fv  $< $@

$(PLUGINRC): $(PRCFILE)
	mkdir -p $(dir $(PLUGINRC))
	ln -nfv $(abspath $(PRCFILE)) $@ || cp -fv $(PRCFILE) $@

powerline-fonts/:
	git clone https://github.com/powerline/fonts.git $@

.pl_fonts_installed: powerline-fonts/
	powerline-fonts/install.sh && touch $@

install: $(DESTFILES) $(PKGTARGETS) $(PKGPLUGINTARGETS) $(GITTARGETS) $(PLUGINRC) $(PLUGGED) $(PYMS) .pl_fonts_installed

uninstall:
	-rm -fr $(DESTFILES) $(GITTARGETS) $(PLUGINRC) $(PLUGGED) $(BUNDLE) $(AUTOLOADDIR)/plug.vim \
		powerline-fonts .pl_fonts_installed

.PHONY: all install uninstall update $(PKGTARGETS) $(PYMS)
