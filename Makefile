serve:
	docker run --rm -v "$(shell pwd):/usr/share/blog" -p 1313:1313 monachus/hugo:v0.54.0-3 hugo server --bind=0.0.0.0 -D --verbose

deploy:
	./bin/deploy
