nginx_version ?= 1.14.2
cached_layers ?= true

all:
	flavors=$$(jq -er '.flavors[].name' flavors.json) && \
	for f in $$flavors; do make flavor=$$f image; done

image:
	modules=$$(jq -er '.flavors[] | select(.name == "$(flavor)") | .modules | join(",")' flavors.json) && \
	docker build -t tsuru/nginx-$(flavor):$(nginx_version) $$(if [ "$(cached_layers)" = "false" ]; then echo "--no-cache"; fi) --build-arg nginx_version=$(nginx_version) --build-arg modules="$$modules" .

.PHONY: all flavor
