FONTDIR := /Library/Fonts
BREW := $(shell which brew &> /dev/null || echo brew)
INSTALLTARGETS := $(filter-out zsh ssh-askpass,$(subst vim,macvim,$(PKGS))) the_silver_searcher lua llvm cmake powerline-go
TARGETPKGS = $(filter-out $(shell brew list),$(INSTALLPKGS))
PKGUPDATE := brew-update
MACVIM_APP := /Applications/MacVim.app
SUDOERSDIR := /private/etc/sudoers.d/
PIPINSTALL := $(shell command -v pip &> /dev/null || echo pip)
TARGET_POWERLINE_GO := # installed by brew

$(BREW):
	-xcode-select --install
	sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
	/usr/bin/ruby -e "`curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install`"
	brew update
	brew tap caskroom/fonts

$(filter-out macvim,$(INSTALLPKGS)): $(BREW)
	brew install $@

$(TARGET_CASK_PKGS): install-cask-pkgs

install-pkgs:
	brew install $(TARGETPKGS)

install-cask-pkgs:
	brew cask install $(TARGET_CASK_PKGS)

install: $(MACVIM_APP)/Contents/

$(or $(shell readlink $(MACVIM_APP)/Contents),$(MACVIM_APP)/Contents)/: $(MACVIM_APP)/ $(filter macvim,$(TARGETPKGS))
	sudo ln -Fs $$(find /usr/local -name "MacVim.app")/Contents /Applications/MacVim.app/Contents
	sudo touch $@

$(MACVIM_APP)/:
	mkdir $@

brew-update:
	brew update
	-@[ -n "$$(brew outdated)" ] && brew upgrade && \
		sudo ln -Fs $$(find /usr/local -name "MacVim.app")/Contents /Applications/MacVim.app/Contents

update: brew-update

.PHONY: $(BREW) $(PIPINSTALL) brew-update install-cask-pkgs $(TARGET_CASK_PKGS)
