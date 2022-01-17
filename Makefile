-include /etc/os-release
SHELL := bash -e
PIP ?= $(or $(shell command -v pip),$(shell command -v pip3),$(shell command -v pip2),pip)
OSTYPE := $(shell echo $$OSTYPE)
OSTYPESIMP := $(subst linux-gnu,linux,$(subst msys,windows,$(OSTYPE)))
MSYS := $(if $(findstring msys,$(OSTYPE)),1)
WSL := $(if $(findstring icrosoft,$(shell uname -r)),1)
PLATFORM := $(if $(findstring linux-gnu,$(OSTYPE)),$(shell echo $(ID_LIKE) | tr ' ' '_'),$(or $(findstring darwin,$(OSTYPE)),$(OSTYPE)))
DOTFILES := vimrc vimrc.local gvimrc gvimrc.local screenrc tmux.conf bashrc profile pylintrc dircolors zprofile zshrc quiltrc profile.local
DOTFILES += $(if $(MSYS),minttyrc)
DOTFILES += ctags.d/custom.ctags
DESTFILES := $(addprefix $(HOME)/.,$(DOTFILES)) $(addprefix $(HOME)/.local/,$(wildcard bin/*))
VIMDIR := $(HOME)/.vim
AUTOLOADDIR := $(VIMDIR)/autoload
PLUGINRC := $(VIMDIR)/pluginrc.vim
PKGS := coreutils tmux curl wget vim ssh-askpass zsh ctags
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
				   Inconsolata \
				   Iosevka \
				   Lilex \
				   Monofur \
				   Mononoki \
				   SourceCodePro \
				   VictorMono
NERD_FONT_DIR ?= $(FONTDIR)/NerdFonts/
PYMS := powerline $(if $(MSYS),,psutil) pylint
INSTALLPYMS = $(filter-out $(shell $(PIP) list --format freeze | cut -d'=' -f1),$(subst powerline,powerline-status,$(PYMS)))
# PKGS += golang-go # for powerline-go update
TARGET_POWERLINE_GO := $(if $(findstring x86_64,$(shell uname -m)),$(HOME)/.local/bin/powerline-go) # 64bit only

all: install


vpath %.ttf

install-pyms: $(TARGETPKGS) $(PIPINSTALL)
	$(PIP) install $(if $(shell $(PIP) install --help | fgrep -e '--user'),--user,--prefix ~/.local) $(INSTALLPYMS)

INSTALLPKGS = $(filter-out $(INSTALLPYMS),$(INSTALLTARGETS))

$(PIPINSTALL):
	curl 'https://bootstrap.pypa.io/get-pip.py' -o /tmp/get-pip.py
	python /tmp/get-pip.py --user

dotfiles/dircolors: | LS_COLORS/LS_COLORS
	ln -f $| $@

LS_COLORS/LS_COLORS:
	git clone --depth 1 -b $(BRANCH) https://github.com/trapd00r/LS_COLORS.git $(dir $@)

$(SUDOERSFILE):
	sudo sh -c 'echo "$(LOGNAME) ALL=(ALL) NOPASSWD: ALL" > $@'
	sudo chmod 0440 $@

update-LS_COLORS:
	@echo "Checking if $(@:update-%=%) needs update..."
	@cd $(@:update-%=%) && git fetch --depth 1 && \
		if [ $$(git rev-list HEAD...origin/$(BRANCH) --count) -gt 0 ]; then \
		git reset --hard origin/$(BRANCH); fi

snippets/powerline.tmux.conf: $(filter powerline-status,$(INSTALLPYMS)) $(HOME)/.tmux/plugins/tpm/
	echo source \"$$($(PIP) show powerline-status | fgrep Location | cut -d" " -f2)/powerline/bindings/tmux/powerline.conf\" > $@

$(HOME)/.tmux/plugins/tpm/:
	git clone --depth 1 https://github.com/tmux-plugins/tpm $@

snippets/tpm.tmux.conf:
	echo "run -b '~/.tmux/plugins/tpm/tpm'" > $@

$(TARGET_POWERLINE_GO): | $(HOME)/.local/bin/
	curl -LSso $@ https://github.com/justjanne/powerline-go/releases/latest/download/powerline-go-$(OSTYPESIMP)-amd64 || rm -f $@
	chmod a+x $@

$(HOME)/.local/bin/:
	install -m 0755 -d $@

$(HOME)/.local/bin/%: bin/% | $(HOME)/.local/bin/
	install -m 0755 $< $@

fonts/nerd-fonts/:
	git clone --depth 1 -b master https://github.com/ryanoasis/nerd-fonts.git $@

$(FONTDIR)/ /tmp/vim/:
	mkdir -p $@

$(NERD_FONT_DIR): fonts/nerd-fonts/
	mkdir -p $@
	@for NERD_FONT_NAME in $(NERD_FONT_NAMES); do \
		fonts/nerd-fonts/install.sh -sL "$$NERD_FONT_NAME" | sort | uniq | while read -r NERD_FONT_FILE; do \
		find fonts/nerd-fonts/ -name "$$(basename "$$NERD_FONT_FILE")" -type f -print0 | xargs -0 -n1 -I % cp -v "%" "$@/"; done; done
	touch $@

nerd-update: fonts/nerd-fonts/
	@echo "Checking if $< is up to date..."
	@cd $< && \
		git fetch --depth 1 && \
		if [ "$$(git rev-list HEAD...origin/$(BRANCH) --count)" -gt 0 ]; then \
		git reset --hard origin/$(BRANCH); \
		for NERD_FONT_NAME in $(NERD_FONT_NAMES); do \
		fonts/nerd-fonts/install.sh -sL "$$NERD_FONT_NAME" | sort | uniq | while read -r NERD_FONT_FILE; \
		do find fonts/nerd-fonts/ -name "$$(basename "$$NERD_FONT_FILE")" -type f -print0 | xargs -0 -n1 -I % cp -v "%" "$(NERD_FONT_DIR)/"; done; done; touch $(NERD_FONT_DIR) .fonts_updated; fi

$(FONTS): $(NERD_FONT_DIR)
	fc-cache -vf "$(FONTDIR)"
	touch $@

fonts-update: nerd-update
	@if [ -f .fonts_updated ]; then \
		fc-cache -vf "$(FONTDIR)" && rm -f .fonts_updated; fi

include include/$(PLATFORM).mk



ifneq ($(ID_LIKE),debian)
PLUGGED := $(VIMDIR)/plugged
PKGS += ack

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

$(HOME)/.vimrc: $(if $(MSYS),,set-tmpfiles.vimrc) local.vimrc
$(HOME)/.gvimrc: local.gvimrc
$(HOME)/.bashrc: local.bashrc
$(HOME)/.zshrc: local.zshrc
$(HOME)/.profile: local.profile
$(HOME)/.zprofile: local.zprofile
$(HOME)/.tmux.conf: \
	$(if $(filter $(UBUNTU_VER),16.04),vi-style-2.1.tmux.conf,vi-style.tmux.conf) \
	$(if $(filter powerline,$(PYMS)),powerline.tmux.conf) \
	tpm.tmux.conf

$(HOME)/.ctags.d/custom.ctags: dotfiles/ctags.d/custom.ctags
	mkdir -p $(dir $@)
	ln -f $< $@

.SECONDEXPANSION:
$(HOME)/.%: % $$(wildcard snippets/$$(OSTYPE)$$(@F)) $$(wildcard snippets/$$(ID_LIKE)$$(@F)) $$(if $$(WSL),$$(wildcard snippets/WSL$$(@F)))
	@if [ -h $@ ] || [[ -f $@ && "$$(stat -c %h -- $@ 2> /dev/null)" -gt 1 ]]; then rm -f $@; fi
	@if [ "$(@F)" = ".$(notdir $^)" ]; then \
		echo "ln -f $< $@"; \
		ln -f $< $@; else \
		echo "cat $^ > $@"; \
		cat $^ > $@; fi

$(HOME)/%.local:
	touch $@

$(TARGETPKGS): install-pkgs

ifneq ($(wildcard $(HOME)/.bash_profile),)
DESTFILES += del-bash_profile
endif

del-bash_profile:
	mv -iv $(HOME)/.bash_profile $(HOME)/.bash_profile.old

$(INSTALLPYMS): install-pyms

install: $(if $(MSYS),,$(SUDOERSFILE))
install: $(DESTFILES) $(TARGETPKGS) $(PKGPLUGINTARGETS) $(PLUGINRC) $(PLUGGED) $(INSTALLPYMS) $(FONTS)
install: | /tmp/vim/
install: $(TARGET_POWERLINE_GO)

update: install update-LS_COLORS vimplug-update $(if $(MSYS),,fonts-update)

uninstall:
	-rm -fr $(DESTFILES) $(GITTARGETS) $(PLUGINRC) $(PLUGGED) $(BUNDLE) $(AUTOLOADDIR)/plug.vim $(FONTS)

.PHONY: all install install-pkgs install-pyms uninstall update del-bash_profile \
	vimplug-update fonts-update nerd-update \
	$(PKGS) $(PYMS)
