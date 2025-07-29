HUGO_VERSION=0.147.9
REGISTRY?=ghcr.io
IMAGE_NAME?=k-phoen/blog
IMAGE_VERSION?=latest

.PHONY: serve
serve: bin/hugo
	./bin/hugo server --noBuildLock --buildDrafts --buildFuture

.PHONY: build
build:
	docker build --build-arg HUGO_VERSION=${HUGO_VERSION} -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION} .

.PHONY: push
push:
	docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION}

.PHONY: preview
preview:
	docker run --rm -p 8080:8080 ${REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION}

bin/hugo:
	wget https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/hugo_$(HUGO_VERSION)_linux-amd64.tar.gz
	tar -xzvf hugo_$(HUGO_VERSION)_linux-amd64.tar.gz hugo
	mv hugo bin/hugo
	chmod u+x bin/hugo
	rm hugo_$(HUGO_VERSION)_linux-amd64.tar.gz
