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
FROM nginx:1.29.0-alpine

COPY build/nginx/default.conf /etc/nginx/conf.d/default.conf

COPY --from=build /project/public /site
