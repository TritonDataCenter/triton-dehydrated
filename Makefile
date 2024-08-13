# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Copyright 2021 Joyent, Inc.
# Copyright 2024 MNX Cloud, Inc.

SCRIPT=		deps/dehydrated/dehydrated
ARCHIVE=	dehydrated.tar.gz
VERSION=	$(shell git tag --sort=taggerdate | tail -1)

# Prevent macOS from putting resource forks in the tar
export COPYFILE_DISABLE=true

.PHONY: archive patch release subclean
archive: $(ARCHIVE)

release: clean .version $(ARCHIVE)
	hub release create -d -a $(ARCHIVE) $(VERSION)

.version: $(SCRIPT) dehydrated
	echo "$(VERSION)" > $@
	git rev-parse HEAD 2>/dev/null >> $@

$(ARCHIVE): clean $(SCRIPT) patch .version
	find . -type f \
	    -not -path '*/.git/*' \
	    -not -path '*/PATCHES/*' \
	    -not -name '.git*' \
	    -not -name '.travis.yml' \
	    -not -name 'Makefile' \
	    -not -name '$(ARCHIVE)' | \
	        xargs tar -czf "$@"

$(SCRIPT):
	git submodule init && git submodule update

# This is a temporary hack to work around an upstream bug. We want a better
# way to handle this.
# https://github.com/dehydrated-io/dehydrated/issues/910
patch: $(SCRIPT)
	patch -p1 $< < PATCHES/000-fix-hexdump-check.patch

subclean:
	git submodule foreach --recursive git reset --hard

clean: subclean
	rm -rf .version $(ARCHIVE) accounts certs || true
