FONTDIR := $(HOME)/Library/Fonts
BREW := $(shell which brew &> /dev/null || echo brew)
PKGS := $(subst vim,macvim,$(PKGS)) the_silver_searcher thefuck lua llvm
INSTALLTARGETS := $(filter-out python-setuptools,$(PKGS))
TARGETPKGS = $(filter-out $(shell brew cask list),$(filter-out $(shell brew list),$(INSTALLPKGS)))
PKGUPDATE := brew-update
MACVIM_APP := /Applications/MacVim.app

$(EZINSTALL):
	xcode-select --install

$(BREW):
	-xcode-select --install
	sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
	/usr/bin/ruby -e "`curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install`"
	brew update

$(filter-out macvim,$(INSTALLPKGS)): $(BREW)
	brew install $@

install-pkgs:
	brew install $(TARGETPKGS)

install: $(MACVIM_APP)/Contents/

$(MACVIM_APP)/Contents/: $(MACVIM_APP)/ $(filter macvim,$(TARGETPKGS))
	ln -Fs $$(find /usr/local -name "MacVim.app")/Contents /Applications/MacVim.app/
	touch $@

$(MACVIM_APP)/:
	mkdir $@

brew-update:
	brew update
	-brew upgrade
	ln -Fs $(find /usr/local -name "MacVim.app")/Contents /Applications/MacVim.app/

update: brew-update

.PHONY: $(BREW) brew-update
