HUGO_VERSION=0.111.2

serve: bin/hugo
	./bin/hugo server --noBuildLock --buildDrafts --verbose

deploy:
	./bin/deploy

bin/hugo:
	wget https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/hugo_$(HUGO_VERSION)_linux-amd64.tar.gz
	tar -xzvf hugo_$(HUGO_VERSION)_linux-amd64.tar.gz hugo
	mv hugo bin/hugo
	chmod u+x bin/hugo
	rm hugo_$(HUGO_VERSION)_linux-amd64.tar.gz