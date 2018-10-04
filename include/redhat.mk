PKGS += git \
	vim-enhanced \
	vim-X11 \
	automake \
	gcc \
	gcc-c++ \
	kernel-devel \
	python-devel \
	python-psutil \
	python-argparse \
	pylint \
	wqy-zenhei-fonts
PKGS += $(if $(shell fgrep ' 6.' /etc/redhat-release),\
	python34-devel,\
	python3-devel \
	wqy-bitmap-fonts \
	wqy-unibit-fonts)
INSTALLTARGETS := $(PKGS)
TARGETPKGS := $(filter-out $(shell rpm -qa --qf '%{NAME} '),$(INSTALLPKGS))
PKGM ?= $(shell which dnf 2> /dev/null || echo yum)
PKGUPDATE := dnf-update

$(INSTALLPKGS):
	sudo $(PKGM) -y install $@

install-pkgs:
ifneq ($(TARGETPKGS),)
	sudo $(PKGM) -y install $(TARGETPKGS)
endif

dnf-update:
	sudo $(PKGM) -y upgrade $(INSTALLPKGS)

update: dnf-update
