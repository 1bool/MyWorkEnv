RCFILES = vimrc gvimrc screenrc tmux.conf bashrc bash_profile pylintrc
DESTFILES = $(addprefix $(HOME)/.,$(RCFILES)) $(LOCALDIR)/$(PLCONF)
VIMDIR = $(HOME)/.vim
AUTOLOADDIR = $(VIMDIR)/autoload
PLUGINRC = $(VIMDIR)/pluginrc.vim
ifeq ($(shell uname -s),Darwin)
DIST = mac
else
DIST = $(shell . /etc/os-release && echo $$ID)
endif
PKGS = coreutils tmux
LOCALDIR = $(HOME)/.local/share
PLCONF = powerline/bindings/tmux/powerline.conf

all: install



ifneq ($(filter $(DIST),ubuntu debian),)
BUNDLE = $(VIMDIR)/bundle
PRCFILE = pathogenrc.vim
PKGS += exuberant-ctags\
	powerline \
	vim-gnome \
	vim-addon-manager \
	vim-scripts \
	fonts-wqy-zenhei \
	silversearcher-ag
GITPLUGINS = $(shell grep '^[[:blank:]]*Plug ' plugrc.vim | cut -d\' -f2) pathogen
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
PKGPLUGINTARGETS = $(filter-out $(shell vam -q status $(PKGPLUGINS) | \
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
	sudo apt-get install $(TARGETPKGS)

$(PKGPLUGINTARGETS): $(VIMDIR) $(PKGTARGETS)
	vam install $@

$(BUNDLE)/%:
	git clone https://github.com/$(filter %/$(notdir $@),$(GITPLUGINS)).git $@
	@if [ -d $@/doc ]; then \
		vim +Helptags $@/doc +qall; fi

$(LOCALDIR)/$(PLCONF):
	mkdir -p $(dir $@)
	ln -sf /usr/share/$(PLCONF) $@

update:
	sudo apt-get update
	sudo apt-get upgrade $(PKGS)
	@for dir in $(GITTARGETS); do \
		echo Updating $$dir; git -C $$dir pull; done

install: $(DESTFILES) $(PKGTARGETS) $(PKGPLUGINTARGETS) $(GITTARGETS) $(PLUGINRC)

.PHONY: $(PKGPLUGINS) $(PKGPLUGINTARGETS)
else



PLUGGED = $(VIMDIR)/plugged
PRCFILE = plugrc.vim
PKGS += ctags cmake ack
ifeq ($(shell echo 'import sys; print [x for x in sys.path if "powerline_status" in x][0]' | python 2> /dev/null),)
POWERLINE = powerline-status
endif
ifeq ($(shell echo 'import sys; print [x for x in sys.path if "psutil" in x][0]' | python 2> /dev/null),)
POWERLINE += psutil
endif
ifeq ($(shell command -v easy_install),)
EZINSTALL = python-setuptools
endif

$(AUTOLOADDIR)/plug.vim:
	curl -fLo $@ --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

$(PLUGGED): $(AUTOLOADDIR)/plug.vim $(PLUGINRC)
	vim +PlugInstall +qall
	@touch $(PLUGGED)

$(POWERLINE): $(EZINSTALL)
	easy_install --user $@

$(LOCALDIR)/$(PLCONF): $(POWERLINE)
	mkdir -p $(dir $@)
	ln -sf `echo 'import sys; print [x for x in sys.path if "powerline_status" in x][0]' \
		| python`/$(PLCONF) $@

update:
	vim +PlugUpgrade +PlugUpdate +qall

ifeq ($(DIST),mac)
PKGS += macvim the_silver_searcher
PKGTARGETS = $(filter-out $(shell brew list),$(PKGS))

$(EZINSTALL):
	xcode-select --install

/usr/local/.git/description:
	-xcode-select --install
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew update

$(PKGTARGETS): /usr/local/.git/description
	@if [ $@ = macvim ]; then \
		brew install $@ --with-lua --with-override-system-vim; \
		brew linkapps; \
	else \
		brew install $@; fi
endif

ifneq ($(filter $(DIST),fedora centos redhat),)
PKGS += $(EZINSTALL) \
	vim-X11 \
	automake \
	gcc \
	gcc-c++ \
	kernel-devel \
	python-devel \
	python3-devel \
	wqy-bitmap-fonts \
	wqy-unibit-fonts \
	wqy-zenhei-fonts
TARGETPKGS = $(filter-out $(shell rpm -qa --qf '%{NAME} '),$(PKGS))
ifneq ($(TARGETPKGS),)
PKGTARGETS=pkgtargets
endif
DNF = $(shell command -v dnf || echo yum)

$(PKGTARGETS):
	sudo $(DNF) install $(TARGETPKGS)
endif

install: $(DESTFILES) $(PKGTARGETS) $(POWERLINE) $(PLUGINRC) $(PLUGGED)
.PHONY: $(POWERLINE) $(EZINSTALL)
endif



$(HOME)/.%: %
	ln -nfv $(abspath $<) $@ || cp -fv $(abspath $<) $@

$(PLUGINRC): $(PRCFILE)
	mkdir -p $(dir $(PLUGINRC))
	ln -nfv $(abspath $(PRCFILE)) $@ || cp -fv $(abspath $(PRCFILE)) $@

uninstall:
	-rm -fr $(DESTFILES) $(GITTARGETS) $(PLUGINRC) $(AUTOLOADDIR)/plug.vim

.PHONY: all install uninstall update $(PKGTARGETS)
