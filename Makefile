.PHONY: build
build:
	@docker build --rm -f dev-env.Dockerfile -t dev-harbor.asklora.store/library/dev-env:latest .

.PHONY: run
run:
	@docker run --rm \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-it -d dev-harbor.asklora.store/library/dev-env:latest