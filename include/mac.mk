FONTDIR := $(HOME)/Library/Fonts
BREW := $(shell which brew &> /dev/null || echo brew)
PKGS += macvim the_silver_searcher thefuck lua llvm
INSTALLTARGETS := $(filter-out python-setuptools,$(PKGS))
TARGETPKGS = $(filter-out $(shell brew cask list),$(filter-out $(shell brew list),$(INSTALLPKGS)))
PKGUPDATE := brew-update

$(EZINSTALL):
	xcode-select --install

$(BREW):
	-xcode-select --install
	sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
	/usr/bin/ruby -e "`curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install`"
	brew update

$(filter-out macvim,$(INSTALLPKGS)): $(BREW)
	brew install $@

macvim: $(BREW)
	brew cask install $@

install-pkgs: $(filter macvim,$(TARGETPKGS))
	brew install $(filter-out macvim,$(TARGETPKGS))

brew-update:
	brew update
	-brew upgrade

update: brew-update

.PHONY: $(BREW) brew-update
