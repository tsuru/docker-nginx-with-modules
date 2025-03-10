nginx_version ?= stable

DOCKER ?= docker
DOCKER_BUILD_OPTS ?= --platform=linux/amd64

.PHONY: all
all:
	flavors=$$(jq -er '.flavors[].name' flavors.json) && \
	for f in $$flavors; do make flavor=$$f image; done

.PHONY: check-required-vars
check-required-vars:
ifndef flavor
	$(error 'You must defined the flavor variable')
endif

ifndef nginx_version
	$(error 'You must define the nginx_version variable')
endif

.PHONY: image
image: check-required-vars
	modules=$$(jq -er '.flavors[] | select(.name == "$(flavor)") | .modules | join(",")' flavors.json) && \
	lua_modules=$$(jq -er '.flavors[] | select(.name == "$(flavor)") | [ .lua_modules[]? ] | join(",")' flavors.json) && \
	$(DOCKER) build $(DOCKER_BUILD_OPTS) \
		--build-arg nginx_version=$(nginx_version) \
		--build-arg openresty_package_version=${openresty_package_version} \
		--build-arg modules="$$modules" \
		--build-arg lua_modules="$$lua_modules" \
		-t tsuru/nginx-$(flavor):$(nginx_version) .

.PHONY: test
test: check-required-vars
	$(DOCKER) rm -f test-tsuru-nginx-$(flavor)-$(nginx_version) || true
	$(DOCKER) create --name test-tsuru-nginx-$(flavor)-$(nginx_version) tsuru/nginx-$(flavor):$(nginx_version) bash -c " \
	openssl req -x509 -newkey rsa:4096 -nodes -subj '/CN=localhost' -keyout /etc/nginx/key.pem -out /etc/nginx/cert.pem -days 365; \
	nginx -c /etc/nginx/nginx-$(flavor).conf" \

	$(DOCKER) cp ./test/nginx-$(flavor).conf test-tsuru-nginx-$(flavor)-$(nginx_version):/etc/nginx/
	$(DOCKER) cp ./test/nginx-$(flavor).bash test-tsuru-nginx-$(flavor)-$(nginx_version):/bin/test-nginx
	$(DOCKER) cp ./test/jwks.json test-tsuru-nginx-$(flavor)-$(nginx_version):/etc/nginx/

	$(DOCKER) cp $$PWD/test/GeoIP2-Country-Test.mmdb test-tsuru-nginx-$(flavor)-$(nginx_version):/etc/nginx; \

	$(DOCKER) start test-tsuru-nginx-$(flavor)-$(nginx_version) && sleep 3

	$(DOCKER) exec test-tsuru-nginx-$(flavor)-$(nginx_version) sh -c '/bin/test-nginx; exit $$?' || $(DOCKER) logs test-tsuru-nginx-$(flavor)-$(nginx_version)
