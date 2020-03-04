SCRIPT=		deps/dehydrated/dehydrated
ARCHIVE=	dehydrated.tar.gz

.PHONY: archive
archive: $(ARCHIVE)

.version: $(SCRIPT) dehydrated
	git tag | sort | tail -1 > $@
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
