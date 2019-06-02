FONTDIR := $(HOME)/Library/Fonts
BREW := $(shell which brew &> /dev/null || echo brew)
PKGS := $(subst vim,macvim,$(PKGS)) the_silver_searcher thefuck lua llvm
INSTALLTARGETS := $(filter-out python-setuptools,$(PKGS))
TARGETPKGS = $(filter-out $(shell brew list),$(INSTALLPKGS))
PKGUPDATE := brew-update
MACVIM_APP := /Applications/MacVim.app
SUDOERSDIR := /private/etc/sudoers.d/
# brew install font doesn't work for multiple user
# POWERLINE_FONT_PKGS := $(patsubst %-symbolneu-for-powerline,%-powerline-symbols,$(addprefix font-,$(addsuffix -for-powerline,$(shell echo $(POWERLINE_FONT_NAMES) | tr A-Z a-z))))
# NERD_FONT_PKGS := $(addprefix font-,$(addsuffix -nerd-font-mono,$(shell echo $(NERD_FONT_NAMES) | tr A-Z a-z)))
# TARGET_CASK_PKGS := $(filter-out $(shell brew cask list),$(POWERLINE_FONT_PKGS) $(NERD_FONT_PKGS))
# FONTS := $(INPUT_FONTS) $(TARGET_CASK_PKGS)
# POWERLINE_FONT_DIR :=
# NERD_FONT_DIR :=

$(EZINSTALL):
	xcode-select --install

$(BREW):
	-xcode-select --install
	sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
	/usr/bin/ruby -e "`curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install`"
	brew update
	brew tap caskroom/fonts

$(filter-out macvim,$(INSTALLPKGS)): $(BREW)
	brew install $@

$(TARGET_CASK_PKGS): install-cask-pkgs

$(POWERLINE_FONT_PKGS) $(NERD_FONT_PKGS): $(BREW)
	brew cask install $@

install-pkgs:
	brew install $(TARGETPKGS)

install-cask-pkgs:
	brew cask install $(TARGET_CASK_PKGS)

install: $(MACVIM_APP)/Contents/

$(or $(shell readlink $(MACVIM_APP)/Contents),$(MACVIM_APP)/Contents)/: $(MACVIM_APP)/ $(filter macvim,$(TARGETPKGS))
	sudo ln -Fs $$(find /usr/local -name "MacVim.app")/Contents /Applications/MacVim.app/
	sudo touch $@

$(MACVIM_APP)/:
	mkdir $@

brew-update:
	brew update
	-@[ -n "$$(brew outdated)" ] && brew upgrade && \
		sudo ln -Fs $(find /usr/local -name "MacVim.app")/Contents /Applications/MacVim.app/

update: brew-update

.PHONY: $(BREW) brew-update install-cask-pkgs $(TARGET_CASK_PKGS)
