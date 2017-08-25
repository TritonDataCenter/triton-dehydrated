SCRIPT=		deps/dehydrated/dehydrated
ARCHIVE=	dehydrated.tar.gz

.PHONY: archive
archive: $(ARCHIVE)

$(ARCHIVE): $(SCRIPT)
	find . -type f \
	    -not -path '*/.git/*' \
	    -not -name '.git*' \
	    -not -name '.travis.yml' | \
	        xargs tar -czf "$@"

$(SCRIPT):
	git submodule init && git submodule update
