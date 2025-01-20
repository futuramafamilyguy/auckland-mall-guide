envsubst '${SERVER_URL} ${CLIENT_URL} ${DOMAIN}' < /etc/nginx/conf.d/default.template > /etc/nginx/conf.d/default.conf
nginx -g 'daemon off;'
