ARG nginx_version=1.16.1
FROM nginx:${nginx_version} AS build

SHELL ["/bin/bash", "-c"]

RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-suggests \
       libluajit-5.1-dev libpam0g-dev zlib1g-dev libpcre3-dev \
       libexpat1-dev git curl build-essential libxml2 libxslt1.1 libxslt1-dev autoconf libtool libssl-dev

ARG modsecurity_version=v3.0.3
RUN set -x \
    && git clone --depth 1 -b ${modsecurity_version} https://github.com/SpiderLabs/ModSecurity.git /usr/local/src/modsecurity \
    && cd /usr/local/src/modsecurity \
    && git submodule init \
    && git submodule update \
    && ./build.sh \
    && ./configure --prefix=/usr/local \
    && make \
    && make install

ARG owasp_modsecurity_crs_version=v3.1.0
RUN set -x \
    && nginx_modsecurity_conf_dir="/usr/local/etc/modsecurity" \
    && mkdir -p ${nginx_modsecurity_conf_dir} \
    && cd ${nginx_modsecurity_conf_dir} \
    && curl -fSL "https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/${owasp_modsecurity_crs_version}.tar.gz" \
    |  tar -xvzf - \
    && mv owasp-modsecurity-crs{-${owasp_modsecurity_crs_version#v},} \
    && cd -

RUN set -x \
    && curl -sS https://openresty.org/package/pubkey.gpg | apt-key add - \
    && echo 'deb http://openresty.org/package/debian stretch openresty' | tee -a /etc/apt/sources.list.d/openresty.list \
    && apt-get update \
    && apt-get install -y --no-install-suggests openresty \
    && cd /usr/local/openresty \
    && cp -vr ./luajit/* /usr/local/ \
    && rm -d /usr/local/share/lua/5.1 \
    && ln -sf /usr/local/lib/lua/5.1 /usr/local/share/lua/ \
    && cp -vr ./lualib/* /usr/local/lib/lua/5.1

ENV LUAJIT_LIB=/usr/local/lib \
    LUAJIT_INC=/usr/local/include/luajit-2.1

ARG modules
RUN set -x \
    && nginx_version=$(echo ${NGINX_VERSION} | sed 's/-.*//g') \
    && curl -fSL "https://nginx.org/download/nginx-${nginx_version}.tar.gz" \
    |  tar -C /usr/local/src -xzvf- \
    && ln -s /usr/local/src/nginx-${nginx_version} /usr/local/src/nginx \
    && cd /usr/local/src/nginx \
    && configure_args=$(nginx -V 2>&1 | grep "configure arguments:" | awk -F 'configure arguments:' '{print $2}'); \
    IFS=','; \
    for module in ${modules}; do \
        module_repo=$(echo $module | sed -E 's@^(((https?|git)://)?[^:]+).*@\1@g'); \
        module_tag=$(echo $module | sed -E 's@^(((https?|git)://)?[^:]+):?([^:/]*)@\4@g'); \
        dirname=$(echo "${module_repo}" | sed -E 's@^.*/|\..*$@@g'); \
        git clone "${module_repo}"; \
        cd ${dirname}; \
        git fetch --tags; \
        if [ -n "${module_tag}" ]; then \
            if [[ "${module_tag}" =~ ^(pr-[0-9]+.*)$ ]]; then \
                pr_numbers="${BASH_REMATCH[1]//pr-/}"; \
                IFS=';'; \
                for pr_number in ${pr_numbers}; do \
                    git fetch origin "pull/${pr_number}/head:pr-${pr_number}"; \
                    git merge --no-commit pr-${pr_number} master; \
                done; \
                IFS=','; \
            else \
                git checkout "${module_tag}"; \
           fi; \
        fi; \
        cd ..; \
        configure_args="${configure_args} --add-dynamic-module=./${dirname}"; \
    done; unset IFS \
    && eval ./configure ${configure_args} \
    && make modules \
    && cp -v objs/*.so /usr/lib/nginx/modules/

RUN set -x \
    && strip --strip-unneeded /usr/local/bin/* /usr/local/lib/*.a /usr/local/lib/*.so* /usr/lib/nginx/modules/*.so

FROM nginx:${nginx_version}

COPY --from=build /usr/local/bin      /usr/local/bin
COPY --from=build /usr/local/include  /usr/local/include
COPY --from=build /usr/local/lib      /usr/local/lib
COPY --from=build /usr/local/etc      /usr/local/etc
COPY --from=build /usr/local/share    /usr/local/share
COPY --from=build /usr/lib/nginx/modules /usr/lib/nginx/modules

ENV LUAJIT_LIB=/usr/local/lib \
    LUAJIT_INC=/usr/local/include/luajit-2.1

RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-suggests \
      ca-certificates \
      curl \
      dnsutils \
      iputils-ping \
      libcurl4-openssl-dev \
      libyajl-dev \
      libxml2 \
      lua5.1-dev \
      net-tools \
      procps \
      tcpdump \
      rsync \
      vim-tiny \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ldconfig -v \
    && ls /etc/nginx/modules/*.so | grep -v debug \
    |  xargs -I{} sh -c 'echo "load_module {};" | tee -a  /etc/nginx/modules/all.conf' \
    && sed -i -E 's|listen\s+80|&80|g' /etc/nginx/conf.d/default.conf \
    && ln -sf /dev/stdout /var/log/modsec_audit.log \
    && touch /var/run/nginx.pid \
    && mkdir -p /var/cache/nginx \
    && mkdir -p /var/cache/cache-heater \
    && chown -R nginx:nginx /etc/nginx /var/log/nginx /var/cache/nginx /var/run/nginx.pid /var/log/modsec_audit.log /var/cache/cache-heater

EXPOSE 8080 8443

USER nginx

WORKDIR /etc/nginx
