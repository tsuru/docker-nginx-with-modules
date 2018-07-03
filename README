# Build custom docker image with additional modules

This project contains a Dockerfile that allows you to create a custom docker
image with any number of additional dynamic modules.

## Building

To build a new docker image it's only necessary to provide the `modules` build
argument with a comma separated list of git repository URLs to be included in
the image. Example:

```
git clone https://github.com/tsuru/docker-nginx-with-modules.git
cd docker-nginx-with-modules
docker build --build-arg modules=https://github.com/vozlt/nginx-module-vts.git,https://github.com/openresty/echo-nginx-module.git .
```
