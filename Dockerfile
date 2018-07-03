ARG nginx_version=1.14.0

FROM nginx:${nginx_version} as build

RUN apt-get update \
    && apt-get install -y --no-install-suggests \
       libluajit-5.1-dev libpam0g-dev zlib1g-dev libpcre3-dev \
       libexpat1-dev git curl build-essential \
    && export NGINX_RAW_VERSION=$(echo $NGINX_VERSION | sed 's/-.*//g') \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_RAW_VERSION.tar.gz -o nginx.tar.gz \
    && tar -zxC /usr/src -f nginx.tar.gz

ARG modules

RUN export NGINX_RAW_VERSION=$(echo $NGINX_VERSION | sed 's/-.*//g') \
    && cd /usr/src/nginx-$NGINX_RAW_VERSION \
    && configure_args=''; IFS=','; \
    for module in ${modules}; do \
        module_tag=$(echo $module | awk -F: '{if (NF==1) {print ""} else {print $module}}'); \
        module_tag=$(echo $module_tag | awk -F: '{if (NF==2 && $1 ~ /^(https?|git)$/) {print ""} else {print $module_tag}}'); \
        module_tag=$(echo $module_tag | awk -F: '{if (NF==2 && $1 !~ /^(https?|git)$/) {print $2} else {print $module_tag}}'); \
        module_tag=$(echo $module_tag | awk -F: '{if (NF==3) {print $3} else {print $module_tag}}'); \
        module_repo=$(echo $module | awk -F: '{if (NF==2 && $1 ~ /^(https?|git)$/) {print $1":"$2} else {print $module}}'); \
        module_repo=$(echo $module_repo | awk -F: '{if (NF==3) {print $1":"$2} else {print $module_repo}}'); \
        module_repo=$(echo $module_repo | awk -F: '{if (NF==1) {print $1} else {print $module_repo}}'); \
        module_repo=$(echo $module_repo | awk -F: '{if (NF==2 && $1 !~ /^(https?|git)$/) {print $1} else {print $module_repo}}'); \
        dirname=$(echo "${module_repo}" | sed -E 's@^.*/|\..*$@@g'); \
        git clone "${module_repo}"; \
        cd ${dirname}; \
        if [ -n "${module_tag}" ]; then git checkout "${module_tag}"; fi; \
        cd ..; \
        configure_args="${configure_args} --add-dynamic-module=./${dirname}"; \
    done; unset IFS \
    && eval ./configure ${configure_args} \
    && make modules \
    && mkdir /modules \
    && cp $(pwd)/objs/*.so /modules

FROM nginx:${nginx_version}
COPY --from=build /modules/* /etc/nginx/modules/
