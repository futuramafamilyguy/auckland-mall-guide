#!/bin/bash

CERT=/etc/nginx/ssl/live/$DOMAIN/fullchain.pem
KEY=/etc/nginx/ssl/live/$DOMAIN/privkey.pem

if [[ -f /$CERT && -f $KEY ]]; then
	echo 'loading live config'
	envsubst '${SERVER_URL} ${CLIENT_URL} ${DOMAIN}' < /etc/nginx/conf.d/default.template > /etc/nginx/conf.d/default.conf
	if [ -f /etc/nginx/conf.d/certbot.conf ]; then
		rm /etc/nginx/conf.d/certbot.conf
	fi
else
	echo 'loading http-01 challenge config'
	envsubst '${DOMAIN}' < /etc/nginx/conf.d/certbot.template > /etc/nginx/conf.d/certbot.conf
	if [ -f /etc/nginx/conf.d/default.conf ]; then
		rm /etc/nginx/conf.d/default.conf
	fi
fi

nginx -g 'daemon off;'
