nginx_version ?= 1.14.0

all:
	flavors=$$(jq -er '.flavors[].name' flavors.json) && \
	for f in $$flavors; do make flavor=$$f image; done

image:
	modules=$$(jq -er '.flavors[] | select(.name == "$(flavor)") | .modules | join(",")' flavors.json) && \
	docker build -t tsuru/nginx-$(flavor):$(nginx_version) --build-arg nginx_version=$(nginx_version) --build-arg modules="$$modules" .

.PHONY: all flavor
