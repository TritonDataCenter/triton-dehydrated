SCRIPT=		deps/dehydrated/dehydrated
ARCHIVE=	dehydrated.tar.gz
VERSION=	$(shell git tag --sort=taggerdate | tail -1)

# Prevent macOS from putting resource forks in the tar
export COPYFILE_DISABLE=true

.PHONY: archive release
archive: $(ARCHIVE)

release: clean .version $(ARCHIVE)
	hub release create -d -a $(ARCHIVE) $(VERSION)

.version: $(SCRIPT) dehydrated
	echo "$(VERSION)" > $@
	git rev-parse HEAD 2>/dev/null >> $@

$(ARCHIVE): $(SCRIPT) .version
	find . -type f \
	    -not -path '*/.git/*' \
	    -not -name '.git*' \
	    -not -name '.travis.yml' \
	    -not -name '$(ARCHIVE)' | \
	        xargs tar -czf "$@"

$(SCRIPT):
	git submodule init && git submodule update

clean:
	rm $(ARCHIVE)
