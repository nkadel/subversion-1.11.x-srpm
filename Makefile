#
# Build mock and local RPM versions of python modules
#

# Assure that sorting is case sensitive
LANG=C

# Ignore ownership and group,
RSYNCOPTS=-a --no-owner --no-group
# Skip existing files to avoid binary churn in yum repos
RSYNCSAFEOPTS=$(RSYNCOPTS) --ignore-existing 

# "mock" configurations to build with, activate only as needed
MOCKS+=fedora-30-x86_64
MOCKS+=fedora-29-x86_64
MOCKS+=epel-7-x86_64
# Some RHEL dependencies are supplied locally in py2packrepo

# Local yum compatible RPM repository
REPOBASEDIR="`/bin/pwd | xargs dirname`/py2packrepo"

# Deduce local package names and .spec files, for universe Makefile use
SPEC := `ls *.spec | head -1`
PKGNAME := "`ls *.spec | head -1 | sed 's/.spec$$//g'`"

# Needed for yum repo updates
all:: /usr/bin/createrepo
all:: $(MOCKS)

srpm:: FORCE
	@echo "Building $(SPEC) SRPM"
	rm -rf rpmbuild
	rpmbuild --define '_topdir $(PWD)/rpmbuild' \
		--define '_sourcedir $(PWD)' \
		-bs $(SPEC) --nodeps

# Needed for python27 compatible compilation
build:: srpm FORCE
	rpmbuild --define '_topdir $(PWD)/rpmbuild' \
		--rebuild rpmbuild/SRPMS/*.src.rpm

$(MOCKS):: srpm FORCE
	@if [ -e $@ -a -n "`find $@ -name \*.rpm`" ]; then \
		echo "	Skipping RPM populated $@"; \
	else \
		echo "Storing " rpmbuild/SRPMS/*.src.rpm "as $@.src.rpm"; \
		install rpmbuild/SRPMS/*.src.rpm $@.src.rpm; \
		echo "Building $@.src.rpm in $@"; \
		rm -rf $@; \
		mock -q -r $@ \
		     --resultdir=$(PWD)/$@ \
		     $@.src.rpm; \
	fi

mock:: $(MOCKS)

clean::
	rm -rf rpmbuild
	rm -rf */
	rm -f *.rpm
	rm -f *~
	rm -f *.out

realclean distclean:: clean

FORCE:
