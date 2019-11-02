SHELL := bash -e
OS := $(if $(shell fgrep 'Microsoft@Microsoft.com' /proc/version 2> /dev/null),WSL,$(patsubst MSYS_NT%,MSYS_NT,$(shell uname -s)))
DIST := $(strip $(if $(findstring Darwin,$(OS)),mac,\
	$(if $(findstring MSYS_NT,$(OS)),msys,\
	$(if $(wildcard /etc/os-release),$(shell . /etc/os-release 2> /dev/null && echo $$ID),\
	$(shell cat /etc/system-release | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')))))
DIST_FAMILY := $(strip $(if $(filter mac msys,$(DIST)),$(DIST),\
	$(if $(wildcard /etc/os-release),$(shell . /etc/os-release 2> /dev/null && echo $$ID_LIKE))))
DOTFILES := vimrc vimrc.local gvimrc gvimrc.local screenrc tmux.conf bashrc profile pylintrc dircolors
DOTFILES += $(if $(filter $(OS),WSL MSYS_NT),minttyrc)
DESTFILES := $(addprefix $(HOME)/.,$(DOTFILES)) $(addprefix $(HOME)/.local/,$(wildcard bin/*))
VIMDIR := $(HOME)/.vim
AUTOLOADDIR := $(VIMDIR)/autoload
PLUGINRC := $(VIMDIR)/pluginrc.vim
PKGS := coreutils tmux curl wget vim ssh-askpass
LOCALDIR := $(HOME)/.local/share
FONTDIR := $(if $(findstring mac,$(DIST)),$(HOME)/Library/Fonts,$(HOME)/.local/share/fonts)
FONTS := $(if $(filter $(DIST),msys),,.fonts_installed)
BRANCH := master
VPATH := dotfiles:snippets
SUDOERSDIR := /etc/sudoers.d/
SUDOERSFILE := $(if $(LOGNAME),$(SUDOERSDIR)/nopass_for_$(LOGNAME),)
NERD_FONT_NAMES ?= IBMPlexMono \
				   DaddyTimeMono \
				   FantasqueSansMono \
				   Go-Mono \
				   CodeNewRoman \
				   FiraCode \
				   Hack \
				   Iosevka \
				   Monofur \
				   Mononoki \
				   SourceCodePro
NERD_FONT_DIR ?= $(FONTDIR)/NerdFonts/
POWERLINE_FONT_NAMES ?= $(if $(findstring mac,$(DIST)),Consolas) SymbolNeu
POWERLINE_FONT_DIR ?= $(FONTDIR)/PowerlineFonts/
PYMS := powerline $(if $(filter $(OS),msys),psutil) pylint
INSTALLPYMS = $(subst powerline,powerline-status,$(foreach m,$(PYMS),$(shell python -c "import $(m)" 2> /dev/null || echo $(m))))

all: install


ifeq ($(DIST_FAMILY),debian)
include include/ubuntu.mk
else
PLUGGED := $(VIMDIR)/plugged
PKGS += ctags cmake ack
SEOUL256 := $(PLUGGED)/vim-airline-themes/autoload/airline/themes/seoul256.vim

$(AUTOLOADDIR)/plug.vim:
	curl -fLo $@ --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

$(PLUGGED): $(AUTOLOADDIR)/plug.vim $(PLUGINRC)
	vim +PlugInstall +qall
	@touch $(PLUGGED)


ifeq ($(DIST),mac)
include include/mac.mk
endif
ifeq ($(DIST_FAMILY),rhel fedora)
include include/redhat.mk
endif
ifeq ($(DIST),msys)
include include/msys.mk
endif
vimplug-update:
	vim +PlugUpgrade +PlugUpdate +qall

.SECONDEXPANSION:
$(PLUGINRC): vim/plugrc.vim $$(wildcard snippets/$$(OS).$$(@F) snippets/$$(DIST).$$(@F))
	mkdir -p $(dir $(PLUGINRC))
	@echo 'let g:plug_window = "vertical botright new"' > $@
	@echo 'call plug#begin()' >> $@
	cat $^ >> $@
	@echo 'call plug#end()' >> $@
endif


vpath %.ttf


$(PIPINSTALL):
	curl 'https://bootstrap.pypa.io/get-pip.py' -o /tmp/get-pip.py
	python /tmp/get-pip.py --user

$(INSTALLPYMS): install-pyms

install-pyms: $(TARGETPKGS) $(PIPINSTALL)
	pip install $(if $(shell pip install --help | fgrep -e '--user'),--user,--prefix ~/.local) $(INSTALLPYMS)

INSTALLPKGS := $(filter-out $(INSTALLPYMS),$(INSTALLTARGETS))

$(HOME)/%vimrc.local:
	touch $@

$(HOME)/.vimrc: $(if $(filter-out MSYS_NT,$(OS)),set-tmpfiles.vimrc)
$(HOME)/.profile: $(if $(filter $(OS),WSL MSYS_NT Darwin),auto-ssh-agent.profile)
$(HOME)/.tmux.conf: \
	$(if $(findstring 16.04,$(UBUNTU_VER)),vi-style-2.1.tmux.conf,vi-style.tmux.conf) \
	$(if $(filter powerline,$(INSTALLTARGETS)),$(if \
	$(filter debian,$(DIST_FAMILY)),debian.tmux.conf), pym-powerline.tmux.conf)

dotfiles/dircolors: | LS_COLORS/LS_COLORS
	ln -f $| $@

LS_COLORS/LS_COLORS:
	git clone -b $(BRANCH) https://github.com/trapd00r/LS_COLORS.git $(dir $@)

$(SUDOERSFILE):
	sudo sh -c 'echo "$(LOGNAME) ALL=(ALL) NOPASSWD: ALL" > $@'
	sudo chmod 0440 $@

update-LS_COLORS:
	cd $(@:update-%=%) && git pull origin $(BRANCH)

$(SEOUL256): | $(or $(filter %airline-themes,$(PKGPLUGINTARGETS) $(GITTARGETS)),$(PLUGGED))
	wget -cP $(@D) https://gist.github.com/jbkopecky/a2f66baa8519747b388f2a1617159c07/raw/f73313795a9b3135ea23735b3e6d4a1969da3cfe/seoul256.vim
 
snippets/pym-powerline.tmux.conf: $(filter powerline-status,$(INSTALLPYMS))
	echo source \"$$(pip show powerline-status | fgrep Location | cut -d" " -f2)/powerline/bindings/tmux/powerline.conf\" > $@

.SECONDEXPANSION:
$(HOME)/.%: $$(wildcard snippets/$$(OS)$$(@F)) $$(wildcard snippets/$$(DIST_FAMILY)$$(@F)) $$(wildcard snippets/$$(DIST)$$(@F)) %
	@if [ -h $@ ] || [[ -f $@ && "$$(stat -c %h -- $@ 2> /dev/null)" -gt 1 ]]; then rm -f $@; fi
	@if [ "$(@F)" = ".$(notdir $^)" ]; then \
		echo "ln -f $< $@"; \
		ln -f $< $@; else \
		echo "cat $^ > $@"; \
		cat $^ > $@; fi

$(HOME)/.local/bin/:
	install -m 0755 -d $@

$(HOME)/.local/bin/%: bin/% | $(HOME)/.local/bin/
	install -m 0755 $< $@

fonts/powerline-fonts/:
	git clone -b master https://github.com/powerline/fonts.git $@

fonts/nerd-fonts/:
	git clone --depth 1 -b master https://github.com/ryanoasis/nerd-fonts.git $@

$(FONTDIR)/:
	mkdir -p $@

$(POWERLINE_FONT_DIR): fonts/powerline-fonts/
	mkdir -p $@
	@for DIR in $(POWERLINE_FONT_NAMES); do \
		cp -v fonts/powerline-fonts/"$$DIR"/*.?tf $@; done
	touch $@

powerline-update: fonts/powerline-fonts/
	@echo "Checking if $< is up to date..."
	@if ! LANGUAGE=en.US_UTF-8 git -C $< pull origin master | tail -1 | fgrep 'Already up'; then \
		for DIR in $(POWERLINE_FONT_NAMES); do \
		cp -v fonts/powerline-fonts/"$$DIR"/*.?tf $@; \
		done; touch $(POWERLINE_FONT_DIR) .fonts_updated; fi

$(NERD_FONT_DIR): fonts/nerd-fonts/
	mkdir -p $@
	@for NERD_FONT_NAME in $(NERD_FONT_NAMES); do \
		fonts/nerd-fonts/install.sh -sL "$$NERD_FONT_NAME" | sort | uniq | while read -r NERD_FONT_FILE; do \
		find fonts/nerd-fonts/ -name "$$(basename "$$NERD_FONT_FILE")" -type f -print0 | xargs -0 -n1 -I % cp -v "%" "$@/"; done; done
	touch $@

nerd-update: fonts/nerd-fonts/
	@echo "Checking if $< is up to date..."
	@if ! LANGUAGE=en.US_UTF-8 git -C $< pull origin master | fgrep 'Already up'; then \
		for NERD_FONT_NAME in $(NERD_FONT_NAMES); do \
		fonts/nerd-fonts/install.sh -sL "$$NERD_FONT_NAME" | sort | uniq | while read -r NERD_FONT_FILE; \
		do find fonts/nerd-fonts/ -name "$$(basename "$$NERD_FONT_FILE")" -type f -print0 | xargs -0 -n1 -I % cp -v "%" "$(NERD_FONT_DIR)/"; done; done; touch $(NERD_FONT_DIR) .fonts_updated; fi

$(FONTS): $(POWERLINE_FONT_DIR) $(NERD_FONT_DIR)
	fc-cache -vf "$(FONTDIR)"
	touch $@

fonts-update: nerd-update powerline-update
	@if [ -f .fonts_updated ]; then \
		fc-cache -vf "$(FONTDIR)" && rm -f .fonts_updated; fi

$(TARGETPKGS): install-pkgs

ifneq ($(wildcard $(HOME)/.bash_profile),)
DESTFILES += del-bash_profile
endif

del-bash_profile:
	mv -iv $(HOME)/.bash_profile $(HOME)/.bash_profile.old

install: $(SUDOERSFILE)
install: $(DESTFILES) $(TARGETPKGS) $(PKGPLUGINTARGETS) $(PLUGINRC) $(PLUGGED) $(INSTALLPYMS) $(FONTS)
install: $(SEOUL256)

update: install update-LS_COLORS vimplug-update $(if $(findstring msys,$(DIST)),,fonts-update)

uninstall:
	-rm -fr $(DESTFILES) $(GITTARGETS) $(PLUGINRC) $(PLUGGED) $(BUNDLE) $(AUTOLOADDIR)/plug.vim $(FONTS)

.PHONY: all install install-pkgs install-pyms uninstall update del-bash_profile \
	vimplug-update fonts-update nerd-update powerline-update \
	$(PKGS) $(PYMS)
