# the different stages of this Dockerfile are meant to be built into separate images
# https://docs.docker.com/compose/compose-file/#target

ARG PHP_VERSION=7.2
ARG NGINX_VERSION=1.15
ARG LARAVEL_VERSION=5.7

### NGINX
FROM nginx:${NGINX_VERSION}-alpine AS docker_nginx

COPY docker/nginx/conf.d /etc/nginx/conf.d/
COPY public /srv/app/public/

### PHP
FROM php:${PHP_VERSION}-fpm-alpine AS docker_php

RUN apk add --no-cache --virtual .persistent-deps \
		git \
		icu-libs \
		zlib \
		file \
		gettext \
		postgresql-dev \
		acl \
		libzip

RUN set -eux \
	&& apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		icu-dev \
		libzip-dev \
		zlib-dev \
	&& docker-php-ext-configure zip --with-libzip \
	&& docker-php-ext-install \
		intl \
		pdo \
        pdo_mysql \
		zip \
	&& pecl install \
	&& apk del .build-deps

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-app-entrypoint
RUN chmod +x /usr/local/bin/docker-app-entrypoint

WORKDIR /srv/app
ENTRYPOINT ["docker-app-entrypoint"]
CMD ["php-fpm"]

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER 1

# Use prestissimo to speed up builds
RUN composer global require "hirak/prestissimo:^0.3" --prefer-dist --no-progress --no-suggest --optimize-autoloader --classmap-authoritative  --no-interaction

# Download the laravel skeleton and leverage Docker cache layers
RUN composer create-project "laravel/laravel=${LARAVEL_VERSION}" . --prefer-dist --no-dev --no-progress --no-scripts --no-plugins --no-interaction

###> recipes ###
###< recipes ###

COPY . .

RUN composer install --prefer-dist --no-dev --no-scripts --no-progress --no-suggest --classmap-authoritative --no-interaction
