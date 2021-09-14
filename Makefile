TARGETS := $(TARGET_POWERLINE_GO) zsh

-include /etc/os-release
SHELL := bash -e
OSTYPE := $(shell echo $$OSTYPE)
OSTYPESIMP := $(subst linux-gnu,linux,$(subst msys,windows,$(OSTYPE)))
MSYS := $(if $(findstring msys,$(OSTYPE)),1)
WSL := $(if $(findstring Microsoft,$(shell uname -r)),1)
PLATFORM := $(if $(findstring linux-gnu,$(OSTYPE)),$(ID_LIKE),$(or $(findstring darwin,$(OSTYPE)),$(OSTYPE)))
DOTFILES := vimrc vimrc.local gvimrc gvimrc.local screenrc tmux.conf bashrc profile pylintrc dircolors zprofile zshrc
DOTFILES += $(if $(MSYS),minttyrc)
DESTFILES := $(addprefix $(HOME)/.,$(DOTFILES)) $(addprefix $(HOME)/.local/,$(wildcard bin/*))
VIMDIR := $(HOME)/.vim
AUTOLOADDIR := $(VIMDIR)/autoload
PLUGINRC := $(VIMDIR)/pluginrc.vim
PKGS := coreutils tmux curl wget vim ssh-askpass zsh
LOCALDIR := $(HOME)/.local/share
FONTDIR ?= $(HOME)/.local/share/fonts
FONTS := $(if $(MSYS),,.fonts_installed)
BRANCH := master
VPATH := dotfiles:snippets
SUDOERSDIR := /etc/sudoers.d/
SUDOERSFILE := $(if $(LOGNAME),$(SUDOERSDIR)/nopass_for_$(LOGNAME),)
NERD_FONT_NAMES ?= Agave \
				   CascadiaCode \
				   CodeNewRoman \
				   FantasqueSansMono \
				   FiraCode \
				   Go-Mono \
				   Hack \
				   Hasklig \
				   Iosevka \
				   Monofur \
				   Mononoki \
				   SourceCodePro \
				   VictorMono
NERD_FONT_DIR ?= $(FONTDIR)/NerdFonts/
POWERLINE_FONT_NAMES ?= SymbolNeu
POWERLINE_FONT_DIR ?= $(FONTDIR)/PowerlineFonts/
PYMS := powerline $(if $(MSYS),,psutil) pylint
INSTALLPYMS = $(subst powerline,powerline-status,$(foreach m,$(PYMS),$(shell python -c "import $(m)" 2> /dev/null || echo $(m))))
# PKGS += golang-go # for powerline-go update
TARGET_POWERLINE_GO := $(if $(findstring x86_64,$(shell uname -m)),$(HOME)/.local/bin/powerline-go) # 64bit only
PIP ?= $(or $(shell command -v pip),$(shell command -v pip3),$(shell command -v pip2),pip)

all: install


vpath %.ttf

$(INSTALLPYMS): install-pyms

install-pyms: $(TARGETPKGS) $(PIPINSTALL)
	$(PIP) install $(if $(shell $(PIP) install --help | fgrep -e '--user'),--user,--prefix ~/.local) $(INSTALLPYMS)

INSTALLPKGS := $(filter-out $(INSTALLPYMS),$(INSTALLTARGETS))

$(PIPINSTALL):
	curl 'https://bootstrap.pypa.io/get-pip.py' -o /tmp/get-pip.py
	python /tmp/get-pip.py --user

$(HOME)/%vimrc.local:
	touch $@

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
 
snippets/powerline.tmux.conf: $(filter powerline-status,$(INSTALLPYMS)) $(HOME)/.tmux/plugins/tpm/
	echo source \"$$($(PIP) show powerline-status | fgrep Location | cut -d" " -f2)/powerline/bindings/tmux/powerline.conf\" > $@

$(HOME)/.tmux/plugins/tpm/:
	git clone https://github.com/tmux-plugins/tpm $@

snippets/tpm.tmux.conf:
	echo "run -b '~/.tmux/plugins/tpm/tpm'" > $@

$(TARGET_POWERLINE_GO): | $(HOME)/.local/bin/
	curl -LSso $@ https://github.com/justjanne/powerline-go/releases/download/v1.17.0/powerline-go-$(OSTYPESIMP)-amd64 || rm -f $@
	chmod a+x $@

$(HOME)/.local/bin/:
	install -m 0755 -d $@

$(HOME)/.local/bin/%: bin/% | $(HOME)/.local/bin/
	install -m 0755 $< $@

fonts/powerline-fonts/:
	git clone --depth 1 -b master https://github.com/powerline/fonts.git $@

fonts/nerd-fonts/:
	git clone --depth 1 -b master https://github.com/ryanoasis/nerd-fonts.git $@

$(FONTDIR)/ /tmp/vim/:
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

include include/$(PLATFORM).mk



ifneq ($(ID_LIKE),debian)
PLUGGED := $(VIMDIR)/plugged
PKGS += ctags ack
SEOUL256 := $(PLUGGED)/vim-airline-themes/autoload/airline/themes/seoul256.vim

$(AUTOLOADDIR)/plug.vim:
	curl -fLo $@ --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

$(PLUGGED): $(AUTOLOADDIR)/plug.vim $(PLUGINRC)
	vim +PlugInstall +qall
	@touch $(PLUGGED)

vimplug-update:
	vim +PlugUpgrade +PlugUpdate +qall

.SECONDEXPANSION:
$(PLUGINRC): vim/plugrc.vim $$(wildcard snippets/$$(OSTYPE).$$(@F))
	mkdir -p $(dir $(PLUGINRC))
	@echo 'let g:plug_window = "vertical botright new"' > $@
	@echo 'call plug#begin()' >> $@
	cat $^ >> $@
	@echo 'call plug#end()' >> $@
endif

$(HOME)/.vimrc: $(if $(MSYS),,set-tmpfiles.vimrc)
$(HOME)/.tmux.conf: \
	$(if $(filter $(UBUNTU_VER),16.04),vi-style-2.1.tmux.conf,vi-style.tmux.conf) \
	$(if $(filter powerline,$(PYMS)),powerline.tmux.conf) \
	tpm.tmux.conf

.SECONDEXPANSION:
$(HOME)/.%: $$(wildcard snippets/$$(OSTYPE)$$(@F)) $$(wildcard snippets/$$(ID_LIKE)$$(@F)) % $$(if $$(WSL),$$(wildcard snippets/WSL$$(@F)))
	@if [ -h $@ ] || [[ -f $@ && "$$(stat -c %h -- $@ 2> /dev/null)" -gt 1 ]]; then rm -f $@; fi
	@if [ "$(@F)" = ".$(notdir $^)" ]; then \
		echo "ln -f $< $@"; \
		ln -f $< $@; else \
		echo "cat $^ > $@"; \
		cat $^ > $@; fi

$(TARGETPKGS): install-pkgs

ifneq ($(wildcard $(HOME)/.bash_profile),)
DESTFILES += del-bash_profile
endif

del-bash_profile:
	mv -iv $(HOME)/.bash_profile $(HOME)/.bash_profile.old

install: $(if $(MSYS),,$(SUDOERSFILE))
install: $(DESTFILES) $(TARGETPKGS) $(PKGPLUGINTARGETS) $(PLUGINRC) $(PLUGGED) $(INSTALLPYMS) $(FONTS)
install: $(SEOUL256)
install: | /tmp/vim/
install: $(TARGET_POWERLINE_GO)

update: install update-LS_COLORS vimplug-update $(if $(MSYS),,fonts-update)

uninstall:
	-rm -fr $(DESTFILES) $(GITTARGETS) $(PLUGINRC) $(PLUGGED) $(BUNDLE) $(AUTOLOADDIR)/plug.vim $(FONTS)

.PHONY: all install install-pkgs install-pyms uninstall update del-bash_profile \
	vimplug-update fonts-update nerd-update powerline-update \
	$(PKGS) $(PYMS)
