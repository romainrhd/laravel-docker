#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

if [ "$1" = 'php-fpm' ] || [ "$1" = 'artisan' ]; then
    # The first time volumes are mounted, the project needs to be recreated
    if [ ! -f composer.json ]; then
        composer create-project "laravel/laravel=$LARAVEL_VERSION" tmp --prefer-dist --no-progress --no-interaction
        cp -Rp tmp/. .
        rm -Rf tmp/
    elif [ "$APP_ENV" != 'prod' ]; then
        # Always try to reinstall deps when not in prod
        composer install --prefer-dist --no-progress --no-suggest --no-interaction
    fi

fi

exec docker-php-entrypoint "$@"