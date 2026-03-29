HUGO_VERSION=0.147.9
JUNI_VERSION=snapshot
REGISTRY?=ghcr.io
IMAGE_NAME?=k-phoen/blog
GEMINI_IMAGE_NAME?=k-phoen/blog-gemini
IMAGE_VERSION?=latest

.PHONY: serve
serve: bin/hugo
	./bin/hugo server --noBuildLock --buildDrafts --buildFuture

.PHONY: build
build: gemini-convert
	docker build --file Dockerfile.http --build-arg HUGO_VERSION=${HUGO_VERSION} -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION} .
	docker build --file Dockerfile.gemini --build-arg JUNI_VERSION=${JUNI_VERSION} -t ${REGISTRY}/${GEMINI_IMAGE_NAME}:${IMAGE_VERSION} .

.PHONY: push
push:
	docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION}
	docker push ${REGISTRY}/${GEMINI_IMAGE_NAME}:${IMAGE_VERSION}

.PHONY: preview
preview:
	docker run --rm -p 8080:8080 ${REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION}

.PHONY: preview-gemini
preview-gemini:
	docker run --rm -it -v $(shell pwd):/tls -e JUNI_LOG_LEVE=debug -e JUNI_LOG_FORMAT=console -e JUNI_KEY_FILE=/tls/key.pem -e JUNI_CERT_FILE=/tls/cert.pem -p 1965:1965 ${REGISTRY}/${GEMINI_IMAGE_NAME}:${IMAGE_VERSION}

bin/hugo:
	wget https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/hugo_$(HUGO_VERSION)_linux-amd64.tar.gz
	tar -xzvf hugo_$(HUGO_VERSION)_linux-amd64.tar.gz hugo
	mv hugo bin/hugo
	chmod u+x bin/hugo
	rm hugo_$(HUGO_VERSION)_linux-amd64.tar.gz

.PHONY: gemini-convert
gemini-convert:
	docker run --rm --user $(shell id -u) -v $(shell pwd)/:/blog kphoen/juni-md2gemtext:${JUNI_VERSION} --flavor=hugo --output-dir=/blog/converted /blog/content/posts
