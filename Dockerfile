#########
# BUILD #
#########

ARG HUGO_VERSION

FROM ghcr.io/gohugoio/hugo:v${HUGO_VERSION} AS build

COPY . /project

USER root:root

RUN hugo --minify --gc

###########
# RUNTIME #
###########
FROM nginxinc/nginx-unprivileged:1.29.0-alpine3.22

COPY build/nginx/blog.kevingomez.fr.conf /etc/nginx/conf.d/default.conf
COPY build/nginx/www.kevingomez.fr.conf /etc/nginx/conf.d/www.kevingomez.fr.conf

COPY --from=build /project/public /opt/blog
COPY --from=build /project/www /opt/www
