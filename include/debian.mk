APT_STAMP := '/var/lib/apt/periodic/update-success-stamp'
BUNDLE := $(VIMDIR)/bundle
PRCFILE := vim/pathogenrc.vim
PKGS += git \
	exuberant-ctags \
	vim-gtk \
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
	tmux-plugin-manager \
	xsel
# PKGS += dconf-cli # for Gogh
INSTALLTARGETS := $(filter $(shell apt-cache search --names-only '.*' | cut -d' ' -f1),$(PKGS))
GITPLUGINS := $(shell grep -E '^[[:blank:]]*Plug[[:blank:]]+' vim/plugrc.vim $(wildcard snippets/$(OSTYPE).pluginrc.vim) | cut -d\' -f2) pathogen
GITTOPKG := $(shell echo $(subst nerdcommenter,nerd-commenter,\
		   $(basename $(notdir $(subst a.vim,alternate.vim,$(GITPLUGINS))))) \
		   | tr [:upper:] [:lower:])
# vim-youcompleteme fail to work in 16.04
VIMPKGS := $(if $(findstring 16.04,$(VERSION_ID)),$(filter-out vim-youcompleteme,$(shell apt-cache search --names-only '^vim-' | cut -d' ' -f1)),$(shell apt-cache search --names-only '^vim-' | cut -d' ' -f1))
# vim-youcompleteme compilation dependencies
INSTALLTARGETS += $(if $(findstring 16.04,$(VERSION_ID)),python-dev python3-dev g++ gcc clang cmake)
INSTALLTARGETS += $(if $(findstring 20.04,$(VERSION_ID)),python-is-python3)
PLUGINPKGS := $(filter $(addprefix %,$(GITTOPKG)),$(VIMPKGS))
VAMLIST := $(if $(and $(shell dpkg --get-selections | fgrep vim-scripts),\
		  $(shell dpkg --get-selections | fgrep vim-addon-manager)),\
		  $(shell vam list),$(error "vim-scripts or vim-addon-manager not installed")) \
		  $(VIMPKGS:vim-%=%)
PKGPLUGINS := $(filter $(GITTOPKG:vim-%=%),$(VAMLIST))
INSTALLTARGETS += $(PLUGINPKGS)
TARGETPKGS = $(filter-out $(shell dpkg --get-selections | cut -f1 | cut -d':' -f1),\
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

$(VIMDIR)/:
	mkdir -p $(VIMDIR)

$(PLUGINRC): $(PRCFILE)
	mkdir -p $(dir $(PLUGINRC))
	ln -nfv $(abspath $(PRCFILE)) $@ || cp -fv $(PRCFILE) $@

powerline: $(APT_STAMP)
	sudo apt-get -y install $@
ifneq ($(WSL),1)
	systemctl --user enable powerline-daemon
	systemctl --user start powerline-daemon
endif

$(filter-out powerline,$(INSTALLPKGS)): $(APT_STAMP)
	sudo apt-get -y install $@

install-pkgs: $(APT_STAMP)
ifneq ($(TARGETPKGS),)
	sudo apt-get -y install $(TARGETPKGS)
endif

$(sort $(PKGPLUGINTARGETS)): | $(VIMDIR)/
	vam install $@

$(BUNDLE)/YCM-Generator/ update-$(BUNDLE)/YCM-Generator: BRANCH := stable

$(BUNDLE)/%/:
	git clone -b $(BRANCH) https://github.com/$(filter %/$(notdir $(@:/=)),$(GITPLUGINS)).git $@
	@if [ -d $@/doc ]; then \
		vim +Helptags $@/doc/*.txt +qall; fi

$(BUNDLE)/YouCompleteMe/: | $(filter git cmake clang python,$(TARGETPKGS))
	git clone -b master https://github.com/$(filter %/$(notdir $(@:/=)),$(GITPLUGINS)).git $@
	cd $@ && git submodule update --init --recursive
	cd $@ && ./install.py --clang-completer
	@if [ -d $@/doc ]; then \
		vim +Helptags $@/doc/*.txt +qall; fi

# $(BUNDLE)/color_coded/: | $(TARGETPKGS)
	# git clone -b master https://github.com/$(filter %/$(notdir $(@:/=)),$(GITPLUGINS)).git $@
	# cd $@ && rm -f CMakeCache.txt && cmake . && make && make install
	# @if [ -d $@/doc ]; then \
		# vim +Helptags $@/doc/*.txt +qall; fi
 
snippets/powerline.tmux.conf: $(filter powerline-status,$(INSTALLPYMS))
	echo 'source /usr/share/powerline/bindings/tmux/powerline.conf' > $@

snippets/tpm.tmux.conf:
	echo "run -b '/usr/share/tmux-plugin-manager/tpm'" > $@

$(APT_STAMP):
	sudo apt-get update

$(VIMDIR)/autoload/pathogen.vim:
	mkdir -p $(dir $@)
	curl -LSso $@ https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim

update: apt-update

apt-update:
	sudo apt-get -y update
	sudo apt-get -y install $(INSTALLTARGETS)

$(UPDATE-GITTARGETS):
	@echo Updating $(@:update-%=%)
	@cd $(@:update-%=%) && \
		git fetch --depth 1 && \
		if [ "$$(git rev-list HEAD...origin/$(BRANCH) --count)" -gt 0 ]; then \
		git reset --hard origin/$(BRANCH) && \
		if [ -d doc ]; then vim +Helptags doc/*.txt +qall; fi; fi

vimplug-update: $(UPDATE-GITTARGETS)

install: $(addsuffix /,$(GITTARGETS))

.PHONY: $(PKGPLUGINS) $(PKGPLUGINTARGETS)
