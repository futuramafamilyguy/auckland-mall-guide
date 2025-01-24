#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
else
    echo "no .env file"
    exit 1
fi

if [ -z "$DOMAIN" ]; then
    echo "DOMAIN env var not set in .env"
    exit 1
fi

load() {
    docker compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d $DOMAIN -d www.$DOMAIN -d api.$DOMAIN --agree-tos --non-interactive --email $EMAIL
    docker compose restart nginx
}

renew() {
    docker compose run --rm certbot renew
}

delete() {
    docker compose run --rm certbot delete --cert-name $DOMAIN
}

if [ "$1" == "load" ]; then
    load
elif [ "$1" == "renew" ]; then
    renew
elif [ "$1" == "delete" ]; then
    delete
fi
