PKGM ?= $(shell which dnf 2> /dev/null || echo yum)
PKGS := $(subst ssh-askpass,openssh-askpass,\
	$(PKGS)))
PKGS += git \
	vim-X11 \
	automake \
	gcc \
	gcc-c++ \
	kernel-devel \
	python-devel \
	python-pip \
	python-psutil \
	python-argparse \
	pylint \
	clang \
	cmake \
	the_silver_searcher
PKGS += $(or $(shell $(PKGM) list -q python3-devel | tail -n -1 | cut -d' ' -f1),python2-devel)
INSTALLTARGETS := $(PKGS)
TARGETPKGS := $(filter-out $(shell rpm -qa --qf '%{NAME} '),$(INSTALLTARGETS))

$(INSTALLPKGS):
	sudo $(PKGM) -y install $@

install-pkgs:
	sudo $(PKGM) -y install $(TARGETPKGS)

dnf-update:
	sudo $(PKGM) -y upgrade $(INSTALLPKGS)

update: dnf-update

.PHONY: dnf-update
