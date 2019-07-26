nginx_version ?= 1.16.0
cached_layers ?= true

all:
	flavors=$$(jq -er '.flavors[].name' flavors.json) && \
	for f in $$flavors; do make flavor=$$f image; done

image:
	modules=$$(jq -er '.flavors[] | select(.name == "$(flavor)") | .modules | join(",")' flavors.json) && \
	docker build -t tsuru/nginx-$(flavor):$(nginx_version) $$(if [ "$(cached_layers)" = "false" ]; then echo "--no-cache"; fi) --build-arg nginx_version=$(nginx_version) --build-arg modules="$$modules" .

test: image
	@docker rm -f test-tsuru-nginx-$(flavor)-$(nginx_version) || true
	@docker create -p 8888:8080 --name test-tsuru-nginx-$(flavor)-$(nginx_version) tsuru/nginx-$(flavor):$(nginx_version) bash -c " \
	openssl req -x509 -newkey rsa:4096 -nodes -subj '/CN=localhost' -keyout /etc/nginx/key.pem -out /etc/nginx/cert.pem -days 365; \
	nginx -c /etc/nginx/nginx-$(flavor).conf"
	@docker cp $$PWD/test/nginx-$(flavor).conf test-tsuru-nginx-$(flavor)-$(nginx_version):/etc/nginx/
	@MS_RULES_DIR=$$(mktemp -d); curl https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended -o $$MS_RULES_DIR/modsecurity_rules.conf; \
	curl https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping -o $$MS_RULES_DIR/unicode.mapping; \
	docker cp $$MS_RULES_DIR/modsecurity_rules.conf test-tsuru-nginx-$(flavor)-$(nginx_version):/etc/nginx; \
	docker cp $$MS_RULES_DIR/unicode.mapping test-tsuru-nginx-$(flavor)-$(nginx_version):/etc/nginx; \
	rm -r $$MS_RULES_DIR || rm -r $$MS_RULES_DIR
	@docker start test-tsuru-nginx-$(flavor)-$(nginx_version) && sleep 3
	@if [ "$$(curl http://localhost:8888)" != "nginx config check ok" ]; then \
		$$(docker logs test-tsuru-nginx-$(flavor)-$(nginx_version)); \
		@docker rm -f test-tsuru-nginx-$(flavor)-$(nginx_version) || true \
		exit 1; \
	fi
	@docker rm -f test-tsuru-nginx-$(flavor)-$(nginx_version) || true; \

.PHONY: all flavor test
