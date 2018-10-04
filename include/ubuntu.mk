UBUNTU_VER := $(shell . /etc/os-release && echo $$VERSION_ID)
APT_STAMP := '/var/lib/apt/periodic/update-success-stamp'
BUNDLE := $(VIMDIR)/bundle
PRCFILE := vim/pathogenrc.vim
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
	language-pack-zh-hans \
	thefuck \
	cmake lua5.2 liblua5.2-dev libncurses5-dev zlib1g-dev # for color_coded
INSTALLTARGETS := $(filter $(shell apt-cache search --names-only '.*' | cut -d' ' -f1),$(PKGS))
GITPLUGINS := $(shell grep -E '^[[:blank:]]*Plug[[:blank:]]+' vim/plugrc.vim $(wildcard snippets/$(OS).pluginrc.vim snippets/$(DIST).pluginrc.vim) | cut -d\' -f2) pathogen
GITTOPKG := $(shell echo $(subst nerdcommenter,nerd-commenter,\
		   $(basename $(notdir $(subst a.vim,alternate.vim,$(GITPLUGINS))))) \
		   | tr [:upper:] [:lower:])
ifeq ($(UBUNTU_VER),16.04)
# vim-youcompleteme fail to work in 16.04
VIMPKGS := $(filter-out vim-youcompleteme,$(shell apt-cache search --names-only '^vim-' | cut -d' ' -f1))
INSTALLTARGETS += cmake python-dev python3-dev g++ gcc
else
VIMPKGS := $(shell apt-cache search --names-only '^vim-' | cut -d' ' -f1)
endif
PLUGINPKGS := $(filter $(addprefix %,$(GITTOPKG)),$(VIMPKGS))
VAMLIST := $(if $(and $(shell dpkg --get-selections | fgrep vim-scripts),\
		  $(shell dpkg --get-selections | fgrep vim-addon-manager)),\
		  $(shell vam list),$(error "vim-scripts or vim-addon-manager not installed")) \
		  $(VIMPKGS:vim-%=%)
PKGPLUGINS := $(filter $(GITTOPKG:vim-%=%),$(VAMLIST))
INSTALLTARGETS += $(PLUGINPKGS)
TARGETPKGS := $(filter-out $(shell dpkg --get-selections | cut -f1 | cut -d':' -f1),\
	$(INSTALLTARGETS))
PKGPLUGINTARGETS := $(filter-out $(shell vam -q status $(PKGPLUGINS) 2> /dev/null | \
				   grep installed | cut -f1),$(PKGPLUGINS))
PKGTOGIT := $(subst youcompleteme,YouCompleteMe,\
		   $(subst nerd-commenter,nerdcommenter,\
		   $(subst alternate,a,\
		   $(VAMLIST))))
ifeq ($(filter pathogen,$(PKGTOGIT)),)
PKGTOGIT += pathogen
DESTFILES += $(VIMDIR)/autoload/pathogen.vim
endif
GITTARGETS := $(addprefix $(BUNDLE)/,$(filter-out \
			 $(PKGTOGIT), $(filter-out \
			 $(addsuffix .vim,$(PKGTOGIT)),$(filter-out \
			 $(addprefix vim-,$(PKGTOGIT)),$(notdir $(GITPLUGINS))))))
UPDATE-GITTARGETS := $(addprefix update-,$(GITTARGETS))
SEOUL256 := $(if $(filter airline-themes,$(GITTARGETS)),$(BUNDLE)/vim-airline-themes,$(VIMDIR))/autoload/airline/themes/seoul256.vim

$(VIMDIR)/:
	mkdir -p $(VIMDIR)

$(PLUGINRC): $(PRCFILE)
	mkdir -p $(dir $(PLUGINRC))
	ln -nfv $(abspath $(PRCFILE)) $@ || cp -fv $(PRCFILE) $@

powerline: $(APT_STAMP)
	sudo apt-get -y install $@
ifneq ($(OS),WSL)
	systemctl --user enable powerline-daemon
	systemctl --user start powerline-daemon
endif

$(filter-out powerline,$(INSTALLPKGS)): $(APT_STAMP)
	sudo apt-get -y install $@

install-pkgs: $(APT_STAMP)
ifneq ($(TARGETPKGS),)
	sudo apt-get -y install $(TARGETPKGS)
endif

$(PKGPLUGINTARGETS): | $(VIMDIR)/
	vam install $@

$(BUNDLE)/YCM-Generator update-$(BUNDLE)/YCM-Generator: BRANCH := stable

$(BUNDLE)/%:
	git clone -b $(BRANCH) https://github.com/$(filter %/$(notdir $@),$(GITPLUGINS)).git $@
	@if [ -d $@/doc ]; then \
		vim +Helptags $@/doc/*.txt +qall; fi

$(BUNDLE)/YouCompleteMe: $(TARGETPKGS)
	git clone -b master https://github.com/$(filter %/$(notdir $@),$(GITPLUGINS)).git $@
	cd $@ && git submodule update --init --recursive
	cd $@ && ./install.py --clang-completer
	@if [ -d $@/doc ]; then \
		vim +Helptags $@/doc/*.txt +qall; fi

$(BUNDLE)/color_coded: $(TARGETPKGS)
	git clone -b master https://github.com/$(filter %/$(notdir $@),$(GITPLUGINS)).git $@
	cd $@ && rm -f CMakeCache.txt && cmake . && make && make install
	@if [ -d $@/doc ]; then \
		vim +Helptags $@/doc/*.txt +qall; fi

$(APT_STAMP):
	sudo apt-get update

$(VIMDIR)/autoload/pathogen.vim:
	mkdir -p $(dir $@)
	curl -LSso $@ https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim

update: apt-update

apt-update:
	sudo apt-get -y update
	sudo apt-get -y install $(INSTALLPKGS)

$(UPDATE-GITTARGETS):
	@echo Updating $(@:update-%=%)
	@if ! LANGUAGE=en.US_UTF-8 git -C $(@:update-%=%) pull origin $(BRANCH) | tail -1 | fgrep 'Already up' \
		&& [ -d $(@:update-%=%)/doc ]; then \
		vim +Helptags $(@:update-%=%)/doc/*.txt +qall; fi

vimplug-update: $(UPDATE-GITTARGETS)

.PHONY: $(PKGPLUGINS) $(PKGPLUGINTARGETS)
