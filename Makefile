SHELL := bash
OS := $(if $(shell fgrep 'Microsoft@Microsoft.com' /proc/version 2> /dev/null),WSL,$(patsubst MSYS_NT%,MSYS_NT,$(shell uname -s)))
DIST := $(strip $(if $(findstring Darwin,$(OS)),mac,\
	$(if $(findstring MSYS_NT,$(OS)),msys,\
	$(if $(wildcard /etc/os-release),$(shell . /etc/os-release 2> /dev/null && echo $$ID),\
	$(shell cat /etc/system-release | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')))))
DOTFILES := vimrc vimrc.local gvimrc gvimrc.local screenrc tmux.conf bashrc profile pylintrc dircolors
DESTFILES := $(addprefix $(HOME)/.,$(DOTFILES)) $(addprefix $(HOME)/.local/,$(wildcard bin/*))
VIMDIR := $(HOME)/.vim
AUTOLOADDIR := $(VIMDIR)/autoload
PLUGINRC := $(VIMDIR)/pluginrc.vim
PKGS := coreutils tmux curl python-setuptools wget vim
LOCALDIR := $(HOME)/.local/share
FONTDIR := $(if $(findstring mac,$(DIST)),$(HOME)/Library/Fonts,$(HOME)/.local/share/fonts)
FONTS := $(if $(filter $(DIST),msys),,.fonts_installed)
BRANCH := master
VPATH := dotfiles:snippets
SUDOERSDIR := /etc/sudoers.d/
SUDOERSFILE := $(if $(LOGNAME),$(SUDOERSDIR)/nopass_for_$(LOGNAME),)
NERD_FONT_NAMES ?= Go-Mono FiraCode CodeNewRoman Hack Iosevka Monofur Mononoki Monoid SourceCodePro
NERD_FONT_DIR ?= $(FONTDIR)/NerdFonts/
POWERLINE_FONT_NAMES ?= $(if $(findstring mac,$(DIST)),Consolas) SymbolNeu
POWERLINE_FONT_DIR ?= $(FONTDIR)/PowerlineFonts/

all: install


ifneq ($(filter $(DIST),ubuntu debian deepin),)
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
ifneq ($(filter $(DIST),fedora centos redhat),)
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


S_INPUT_FONTS := $(shell find fonts/InputMono -name *.ttf -type f)
S_INPUT_FONTDIRS := $(dir $(S_INPUT_FONTS))
INPUT_FONT_DIR := $(FONTDIR)/InputFonts
INPUT_FONTS := $(filter-out $(wildcard $(FONTDIR)/*.ttf), \
	      $(addprefix $(INPUT_FONT_DIR)/,$(notdir $(S_INPUT_FONTS))))

vpath %.ttf $(S_INPUT_FONTDIRS)

ifeq ($(shell echo 'import sys; print([x for x in sys.path if "powerline_status" in x][0])' | python 2> /dev/null),)
PYMS += $(if $(filter powerline,$(INSTALLTARGETS)),,powerline-status)
endif
ifeq ($(shell echo 'import sys; print([x for x in sys.path if "psutil" in x][0])' | python 2> /dev/null),)
PYMS += $(if $(filter python-psutil,$(INSTALLTARGETS)),,$(if $(filter $(DIST),msys),,psutil))
endif
ifeq ($(shell echo 'import sys; print([x for x in sys.path if "pylint" in x][0])' | python 2> /dev/null),)
PYMS += $(if $(filter pylint,$(INSTALLTARGETS)),,pylint)
endif

$(PYMS): $(EZINSTALL) $(TARGETPKGS)
	mkdir -p ~/.local/lib/python$$(python -V 2>&1 | cut -d' ' -f2 | cut -d'.' -f-2)/site-packages
	easy_install $(if $(shell easy_install --help | fgrep -e '--user'),--user,--prefix ~/.local) $@

INSTALLPKGS := $(filter-out $(PYMS),$(INSTALLTARGETS))

$(HOME)/%vimrc.local:
	touch $@

$(HOME)/.vimrc: $(if $(filter-out MSYS_NT,$(OS)),set-tmpfiles.vimrc)
$(HOME)/.profile: $(if $(filter $(OS),WSL MSYS_NT),auto-ssh-agent.profile)
$(HOME)/.tmux.conf: \
	$(if $(findstring 16.04,$(UBUNTU_VER)),vi-style-2.1.tmux.conf,vi-style.tmux.conf) \
	$(if $(filter powerline,$(INSTALLTARGETS)),$(if \
	$(filter ubuntu debian deepin,$(DIST)),ubuntu.tmux.conf), pym-powerline.tmux.conf)

dotfiles/dircolors: LS_COLORS/LS_COLORS
	ln -f $< $@

LS_COLORS/LS_COLORS:
	git clone -b $(BRANCH) https://github.com/trapd00r/LS_COLORS.git $(dir $@)

$(SUDOERSFILE):
	sudo sh -c 'echo "$(LOGNAME) ALL=(ALL) NOPASSWD: ALL" > $@'
	sudo chmod 0440 $@

update-LS_COLORS:
	git -C $(@:update-%=%) pull origin $(BRANCH)

$(SEOUL256): | $(or $(filter %airline-themes,$(PKGPLUGINTARGETS) $(GITTARGETS)),$(PLUGGED))
	wget -P $(@D) https://gist.github.com/jbkopecky/a2f66baa8519747b388f2a1617159c07/raw/f73313795a9b3135ea23735b3e6d4a1969da3cfe/seoul256.vim
 
snippets/pym-powerline.tmux.conf: $(filter powerline-status,$(PYMS))
	echo source \"$$(echo 'import sys; print([x for x in sys.path if "powerline_status" in x][0])' \
		| python)/powerline/bindings/tmux/powerline.conf\" > $@

.SECONDEXPANSION:
$(HOME)/.%: $$(wildcard snippets/$$(OS)$$(@F)) $$(wildcard snippets/$$(DIST)$$(@F)) %
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

$(FONTDIR)/ $(INPUT_FONT_DIR)/:
	mkdir -p $@

$(INPUT_FONT_DIR)/%.ttf: %.ttf | $(INPUT_FONT_DIR)/
	install -m 0644 $< $@

$(INPUT_FONTS): $(TARGETPKGS)

$(POWERLINE_FONT_DIR): fonts/powerline-fonts/
	mkdir -p $@
	@for DIR in $(POWERLINE_FONT_NAMES); do \
		cp -v fonts/powerline-fonts/"$$DIR"/*.?tf $@; done

powerline-update: fonts/powerline-fonts/
	@if ! LANGUAGE=en.US_UTF-8 git -C $< pull origin master | tail -1 | fgrep 'Already up'; then \
		for DIR in $(POWERLINE_FONT_NAMES); do \
		cp -v fonts/powerline-fonts/"$$DIR"/*.?tf $@; \
		done; fi

$(NERD_FONT_DIR): fonts/nerd-fonts/
	mkdir -p $@
	@for NERD_FONT_NAME in $(NERD_FONT_NAMES); do \
		fonts/nerd-fonts/install.sh -sL "$$NERD_FONT_NAME" | sort | uniq | while read -r NERD_FONT_FILE; do \
		find fonts/nerd-fonts/ -name "$$(basename "$$NERD_FONT_FILE")" -type f -print0 | xargs -0 -n1 -I % cp -v "%" "$@/"; done; done

nerd-update: fonts/nerd-fonts/
	@if ! LANGUAGE=en.US_UTF-8 git -C $< pull origin master | tail -1 | fgrep 'Already up'; then \
		for NERD_FONT_NAME in $(NERD_FONT_NAMES); do \
		fonts/nerd-fonts/install.sh -sL "$$NERD_FONT_NAME" | sort | uniq | while read -r NERD_FONT_FILE; \
		do find fonts/nerd-fonts/ -name "$$(basename "$$NERD_FONT_FILE")" -type f -print0 | xargs -0 -n1 -I % cp -v "%" "$@/"; done; done; fi

$(FONTS): $(INPUT_FONTS) $(POWERLINE_FONT_DIR) $(NERD_FONT_DIR)
	fc-cache -vf "$(FONTDIR)"
	touch $@

fonts-update: nerd-update powerline-update

$(TARGETPKGS): install-pkgs

ifneq ($(wildcard $(HOME)/.bash_profile),)
DESTFILES += del-bash_profile
endif

del-bash_profile:
	mv -iv $(HOME)/.bash_profile $(HOME)/.bash_profile.old

install: $(SUDOERSFILE)
install: $(DESTFILES) $(TARGETPKGS) $(PKGPLUGINTARGETS) $(PLUGINRC) $(PLUGGED) $(PYMS) $(FONTS)
install: $(SEOUL256)

update: install update-LS_COLORS vimplug-update $(if $(findstring msys,$(DIST)),,fonts-update)

uninstall:
	-rm -fr $(DESTFILES) $(GITTARGETS) $(PLUGINRC) $(PLUGGED) $(BUNDLE) $(AUTOLOADDIR)/plug.vim $(FONTS)

.PHONY: all install install-pkgs uninstall update del-bash_profile \
	vimplug-update fonts-update nerd-update powerline-update \
	$(PKGS) $(PYMS) $(EZINSTALL)
