FROM nginx:1.14.0 as build

RUN apt-get update \
    && apt-get install -y --no-install-suggests \
       zlib1g-dev libpcre3-dev git curl build-essential \
    && export NGINX_RAW_VERSION=$(echo $NGINX_VERSION | sed 's/-.*//g') \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_RAW_VERSION.tar.gz -o nginx.tar.gz \
    && tar -zxC /usr/src -f nginx.tar.gz

ARG modules

RUN export NGINX_RAW_VERSION=$(echo $NGINX_VERSION | sed 's/-.*//g') \
    && cd /usr/src/nginx-$NGINX_RAW_VERSION \
    && configure_args=''; IFS=','; \
    for module in ${modules}; do \
        git clone "${module}"; \
        dirname=$(echo "${module}" | sed -E 's@^.*/|\..*$@@g'); \
        configure_args="${configure_args} --add-dynamic-module=./${dirname}"; \
    done; unset IFS \
    && eval ./configure ${configure_args} \
    && make modules \
    && mkdir /modules \
    && cp $(pwd)/objs/*.so /modules

FROM nginx:1.14.0
COPY --from=build /modules/* /etc/nginx/modules/
